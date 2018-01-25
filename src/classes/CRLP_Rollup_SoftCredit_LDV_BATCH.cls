/*
    Copyright (c) 2017, Salesforce.org
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Salesforce.org nor the names of
      its contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
    COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
    LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
    ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
    POSSIBILITY OF SUCH DAMAGE.
*/
/**
* @author Salesforce.org
* @date 2017
* @group Rollups
* @group-content ../../ApexDocContent/Rollups2.htm
* @description Soft Credits rollup to the Account and Contacts object using OpportunityContactRole as the base
*  LDV style query. Stateful vars are used to hold rollups of the Account and Contact across multiple batch
*  iterations.
*/
public class CRLP_Rollup_SoftCredit_LDV_BATCH implements Database.Batchable<SObject>, Database.Stateful {

    /**
    * @description Stateful collection of Rollups used to hold Rollups for Contacts and Accounts that
    * span beyond a single batch iteration
    */
    private Map<Id, List<CRLP_Rollup>> statefulRollupsById;

    /** @description The last Parent Id processed by the batch job */
    private Id lastContactIdProcessed;
    private Id lastAccountIdProcessed;

    /** @description Simple counters used to track state */
    private Integer batchIteration = 0;
    private Integer totalRecordsModified = 0;

    /**
    * @description This list is effectively the keyset of statefulRollupsById, but it's used to keep the list of
    * Id's in a specific sequence so that element 0 can be dropped when the 1000th element is added. When dropped,
    * that key is also removed from the statefulRollupsById map. The intent is to keep the heap size for the stateful
    * Map of CRLP_Rollup data limited to avoid a governor limit when dealing with millions of records.
    */
    private List<Id> statefulListOfSavedIds;

    /**
     * @description Map of Opportunity Id's already processed by Account to avoid duplicating a donation amount
     * to the Account when rolling up soft credits by the Contact.AccountId
     */
    private Map<Id,Set<Id>> statefulMapOfOppIdsByAcct;

    /** @description Are there Soft Credits to Contact-Account rollups to execute? */
    private Boolean hasAccountSoftCreditRollups = false;

    /** @description Are there Soft Credits to Contact rollups to execute? */
    private Boolean hasContactSoftCreditRollups = false;

    /** @description Specified list of Summary (Account or Contact) Id's to roll up */
    private List<Id> recordIds;

    /*******************************************************************************************************
    * @description Constructs the class, sets the properties
    */
    public CRLP_Rollup_SoftCredit_LDV_BATCH() {
        this.statefulRollupsById = new Map<Id, List<CRLP_Rollup>>();
        this.statefulMapOfOppIdsByAcct = new Map<Id, Set<Id>>();
        this.statefulListOfSavedIds = new List<Id>();
    }

    /*******************************************************************************************************
    * @description Constructs the class, sets the properties
    */
    public CRLP_Rollup_SoftCredit_LDV_BATCH(List<Id> recordIds) {
        this();
        this.recordIds = recordIds;
    }

    /*******************************************************************************************************
    * @description Build a query of OpportunityContactRole records sorted by Contact.AccountId, ContactId, OppId
    * @param bc BatchableContext passed by the system call
    * @return database.Querylocator
    */
    public database.Querylocator start(Database.BatchableContext bc) {

        String query;
        String emptyQuery = 'SELECT Id FROM OpportunityContactRole LIMIT 0';
        String pscObjectName = UTIL_Describe.getObjectDescribe(UTIL_Namespace.StrAllNSPrefix('Partial_Soft_Credit__c')).getName();

        // Loop through all the Active Rollup Definitions to determine if there are Soft Credit Rollups
        // definitions for either the Account and/or Contact object
        for (Rollup__mdt r : CRLP_Rollup_SEL.getRollupDefinitions()) {
            // Due to how PartialSoftCredit and Opportunity interact with Rollups, the Detail Object
            // can still be set to Opportunity for some of the PartialSoftCredit rollups. As a result,
            // the only reliable ObjectField to check against is AmountObject since that will always point
            // to the PartialSoftCredit object for these types of rollups.
            if (r.Amount_Object__r.QualifiedApiName == pscObjectName && r.Active__c == true) {
                this.hasAccountSoftCreditRollups = (this.hasAccountSoftCreditRollups || r.Summary_Object__c == 'Account');
                this.hasContactSoftCreditRollups = (this.hasContactSoftCreditRollups || r.Summary_Object__c == 'Contact');
            }
        }

        // If a set of specific Contact or Account Id's was passed, then ONLY roll up to that Object type
        if (this.recordIds != null && !this.recordIds.isEmpty()) {
            if (this.recordIds[0].getSobjectType() == Contact.SObjectType) {
                this.hasAccountSoftCreditRollups = false;
            } else {
                this.hasContactSoftCreditRollups= false;
            }
        }

        if (this.hasContactSoftCreditRollups == false && this.hasAccountSoftCreditRollups == false) {
            // If there are no active rollups for the object type, then force the query to return zero records.
            // This is needed because can't return null as a valid iterator.
            return Database.getQueryLocator(emptyQuery);
        }

        try {

            // Build a query of OpportunityContactRole records as the primary object for this batch job
            List<SObjectType> childObjects = new List<SObjectType>();
            SObjectType detailObjectType = OpportunityContactRole.SObjectType;

            query = CRLP_Query_SEL.getDetailsQuery(detailObjectType, childObjects) + ' WHERE ';

            // If necessary, filter the Detail recodrs by either ContactId or AccountId
            if (this.recordIds != null && this.recordIds.size() > 0) {
                String keyField = SObjectType.OpportunityContactRole.fields.ContactId.getName();
                if (this.hasContactSoftCreditRollups == false) {
                    keyField = 'Contact.AccountId';
                }
                query += keyField + ' IN :recordIds';
            }

            // Filter out primary contacts and set the sort order to Account, Contact, Opp
            query += (query.endsWith(' WHERE ') ? '' : ' AND ') + 'IsPrimary = False ';

            // Note that the ORDER BY here doesn't gaurantee that the records will actually be in this order
            query += ' ORDER BY Contact.AccountId, ContactId, Opportunity.CreatedDate ASC ';

            UTIL_Debug.debug(LoggingLevel.WARN, '>> LDV Batch Query =' + query);

            return Database.getQueryLocator(query);

        } catch (Exception ex) {
            // TODO Not 100% sure we want to keep this, but for now it's needed to capture any unexpected errors in the processing logic
            ex.setMessage(ex.getMessage() + '\n\nQuery:\n' + query);
            ERR_Handler.processError(ex, ERR_Handler_API.Context.CRLP);
        }

        return Database.getQueryLocator(emptyQuery); // return a generic empty data set rather than null
    }

    /*******************************************************************************************************
    * @description Handle each group of Detail records to roll-up (i.e., LDV mode). A Stateful collection of
    * CRLP_Rollup instances is used to accumulate the rolled up values by Parent Id across multiple calls to this
    * exection() method with more and more detailsRecords for the same parent.
    * @param bc BatchableContext passed by the system call
    * @param scope List of Detail (Allocation or Opportunity) records
    */
    public void execute(Database.BatchableContext bc, List<OpportunityContactRole> detailRecords) {

        // Convert the list of OpportunityContactRole detail records into a list of PartialSoftCredit
        // records complete with the parent Opportunity details (CloseDate, Amount, ec.)
        List<Partial_Soft_Credit__c> pscDetailRecords = buildPartialSoftCreditRecordsFromOCRs(detailRecords);

        this.batchIteration++;

        try {
            // --------------------------------------
            // Contact Soft Credit Rollups
            // --------------------------------------
            if (this.hasContactSoftCreditRollups) {
                // Build the processing options instance for the Account rollup
                CRLP_RollupProcessor_SVC.ProcessingOptions options = createOptionsInstance(Contact.SObjectType);


                // Get all parent records to be processed by this batch iteration
                List<Id> parentIds = CRLP_RollupProcessor_SVC.getParentIdsFromDetailRecords(detailRecords, 'ContactId');
                if (this.lastContactIdProcessed != null) {
                    Set<Id> uniqueParentIds = new Set<Id>(parentIds);
                    if (!uniqueParentIds.contains(this.lastContactIdProcessed)) {
                        parentIds.add(this.lastContactIdProcessed);
                    }
                }
                Id firstParentId = detailRecords[0].ContactId;
                Id lastParentId = detailRecords[detailRecords.size()-1].ContactId;

                String soql = CRLP_Query_SEL.getResultsQuery(options.parentObjType) + ' WHERE Id IN :parentIds ORDER By Id';
                List<SObject> summaryRecords = database.query(soql);

                // Resequence the Parent (Summary) records to be in the exact order of the detail records
                // using the defined parent Id
                summaryRecords = CRLP_RollupProcessor_SVC.resequenceSummaryRecords(parentIds, summaryRecords);


                // Call the method to do the actual rollups. This returns only records that require updating
                List<SObject> updatedRecords = CRLP_RollupProcessor_SVC.startRollupProcess(summaryRecords, pscDetailRecords, options);
                this.lastContactIdProcessed = options.lastParentIdProcessed;

                // Save Rollups collection and the last parent record id processed in stateful vars
                this.statefulRollupsById.put(firstParentId, options.mapOfRollupsByParentId.get(firstParentId));
                this.statefulRollupsById.put(lastParentId, options.mapOfRollupsByParentId.get(lastParentId));
                this.statefulRollupsById.put(this.lastContactIdProcessed, options.mapOfRollupsByParentId.get(this.lastContactIdProcessed));

                // Handle dml on the records to be updated
                CRLP_RollupProcessor_SVC.updateChangedRecordsWithLogging(updatedRecords);
                if (updatedRecords != null) {
                    this.totalRecordsModified += updatedRecords.size();
                }

            }
        } catch (Exception ex) {
            // TODO Not 100% sure we want to keep this, but for now it's needed to capture any unexpected errors in the processing logic
            ex.setMessage(ex.getMessage() + '\n\nRollups State:\n' + CRLP_Debug_UTIL.getCurrentRollupState());
            ERR_Handler.processError(ex, ERR_Handler_API.Context.CRLP);
        }

        try {
            // --------------------------------------
            // Account Soft Credit Rollups
            // --------------------------------------
            if (this.hasAccountSoftCreditRollups) {
                // Build the processing options instance for the Contact rollup
                CRLP_RollupProcessor_SVC.ProcessingOptions options = createOptionsInstance(Account.SObjectType);

                // Get all parent records to be processed by this batch iteration, being sure to include the
                // last parent id processed by the previous batch.
                List<Id> parentIds = CRLP_RollupProcessor_SVC.getParentIdsFromDetailRecords(detailRecords, 'Contact.AccountId');
                if (this.lastAccountIdProcessed != null) {
                    Set<Id> uniqueParentIds = new Set<Id>(parentIds);
                    if (!uniqueParentIds.contains(this.lastAccountIdProcessed)) {
                        parentIds.add(this.lastAccountIdProcessed);
                    }
                }
                Id firstParentId = detailRecords[0].Contact.AccountId;
                Id lastParentId = detailRecords[detailRecords.size()-1].Contact.AccountId;

                // Get the Summary (target) records for the current set of Detail Records
                String soql = CRLP_Query_SEL.getResultsQuery(options.parentObjType) + ' WHERE Id IN :parentIds';

                // Note: The result of this query will not force the currentContactRecordId to the first record in the
                // collection. That is required for the stateful rollups to work. To work around this, we'll manually
                // re-sequence the result to get the needed record first
                List<SObject> summaryRecords = database.query(soql);

                // Resequence the Parent (Summary) records to be in the exact order of the detail records
                // using the defined parent Id
                summaryRecords = CRLP_RollupProcessor_SVC.resequenceSummaryRecords(parentIds, summaryRecords);

                // Call the method to do the actual rollups. This returns only records that require updating
                List<SObject> updatedRecords = CRLP_RollupProcessor_SVC.startRollupProcess(summaryRecords, pscDetailRecords, options);
                this.lastAccountIdProcessed = options.lastParentIdProcessed;

                // Save Rollups collection and the last parent record id processed in stateful vars
                /*for (Id parentId : options.mapOfRollupsByParentId.keySet()) {
                    if (!this.statefulRollupsById.containsKey(parentId)) {
                        this.statefulListOfSavedIds.add(parentId);
                        if (this.statefulListOfSavedIds.size() == 1000) {
                            Id idToPopOffStack = this.statefulListOfSavedIds[0];
                            this.statefulListOfSavedIds.remove(0);
                            this.statefulRollupsById.remove(idToPopOffStack);
                        }
                    }
                    this.statefulRollupsById.put(parentId, options.mapOfRollupsByParentId.get(parentId));
                }*/
                this.statefulRollupsById.put(firstParentId, options.mapOfRollupsByParentId.get(firstParentId));
                this.statefulRollupsById.put(lastParentId, options.mapOfRollupsByParentId.get(lastParentId));
                this.statefulRollupsById.put(this.lastAccountIdProcessed, options.mapOfRollupsByParentId.get(this.lastAccountIdProcessed));

                this.statefulMapOfOppIdsByAcct.put(firstParentId, options.mapOfProcessedOppIdsByAcctId.get(firstParentId));
                this.statefulMapOfOppIdsByAcct.put(lastParentId, options.mapOfProcessedOppIdsByAcctId.get(lastParentId));
                this.statefulMapOfOppIdsByAcct.put(lastAccountIdProcessed, options.mapOfProcessedOppIdsByAcctId.get(lastAccountIdProcessed));


                // Handle dml on the records to be updated
                CRLP_RollupProcessor_SVC.updateChangedRecordsWithLogging(updatedRecords);
                if (updatedRecords != null) {
                    this.totalRecordsModified += updatedRecords.size();
                }
            }

        } catch (Exception ex) {
            // TODO Not 100% sure we want to keep this, but for now it's needed to capture any unexpected errors in the processing logic
            ex.setMessage(ex.getMessage() + '\n\nRollups State:\n' + CRLP_Debug_UTIL.getCurrentRollupState());
            ERR_Handler.processError(ex, ERR_Handler_API.Context.CRLP);
        }
    }

    /********************************************************************************************************
     * @description Called when all processing is complete for the batch job. Since this job is working from the
     * Detail object, there will be one parent record to finish the update for.
     * Log any captured DML errors.
     */
    public void finish(Database.BatchableContext bc) {

        // --------------------------------------
        // Contact Soft Credit Rollups
        // --------------------------------------
        try {
            // Handle the final parent record in the LDV job
            if (this.lastContactIdProcessed != null && this.statefulRollupsById.containsKey(this.lastContactIdProcessed)) {

                // Build the processing options instance
                CRLP_RollupProcessor_SVC.ProcessingOptions options = createOptionsInstance(Contact.SObjectType);

                // Get the Summary (target) records for the final record to be processed
                Set<Id> parentIds = new Set<Id>{ this.lastContactIdProcessed };
                String soql = CRLP_Query_SEL.getResultsQuery(options.parentObjType) + ' WHERE Id IN :parentIds LIMIT 1';
                SObject parent = database.query(soql);

                // Call the method to do the actual rollup on this last remaining record, which is basically
                // just to return the updated record
                SObject updatedRecord = CRLP_RollupProcessor_SVC.completeRollupForParent(parent, new List<SObject>(), options);

                // Handle dml on the records to be updated
                if (updatedRecord != null) {
                    CRLP_RollupProcessor_SVC.updateChangedRecordsWithLogging(new List<SObject>{ updatedRecord });
                    this.totalRecordsModified += 1;
                }
            }

        } catch (Exception ex) {
            // TODO Not 100% sure we want to keep this, but for now it's needed to capture any unexpected errors in the processing logic
            ERR_Handler.processError(ex, ERR_Handler_API.Context.CRLP);
        }

        // --------------------------------------
        // Account Soft Credit Rollups
        // --------------------------------------
        try {
            // Handle the final parent record in the LDV job
            if (this.lastAccountIdProcessed != null && this.statefulRollupsById.containsKey(this.lastAccountIdProcessed)) {

                // Build the processing options instance
                CRLP_RollupProcessor_SVC.ProcessingOptions options = createOptionsInstance(Account.SObjectType);

                // Get the Summary (target) records for the final record to be processed
                Set<Id> parentIds = new Set<Id>{ this.lastAccountIdProcessed };
                String soql = CRLP_Query_SEL.getResultsQuery(options.parentObjType) + ' WHERE Id IN :parentIds LIMIT 1';
                SObject parent = database.query(soql);

                // Call the method to do the actual rollup on this last remaining record, which is basically
                // just to return the updated record
                SObject updatedRecord = CRLP_RollupProcessor_SVC.completeRollupForParent(parent, new List<SObject>(), options);

                // Handle dml on the records to be updated
                if (updatedRecord != null) {
                    CRLP_RollupProcessor_SVC.updateChangedRecordsWithLogging(new List<SObject>{ updatedRecord });
                    this.totalRecordsModified += 1;
                }
            }

        } catch (Exception ex) {
            // TODO Not 100% sure we want to keep this, but for now it's needed to capture any unexpected errors in the processing logic
            ERR_Handler.processError(ex, ERR_Handler_API.Context.CRLP);
        }
    }

    /********************************************************************************************************
     * @description Create an instance of the CRLP_RollupProcessor_SVC.ProcessingOptions class to use with the
     * CRLP_RollupProcessor_SVC.startRollupProcess() calls.
     * @return CRLP_RollupProcessor_SVC.ProcessingOptions
     */
    private CRLP_RollupProcessor_SVC.ProcessingOptions createOptionsInstance(SObjectType objType) {
        CRLP_RollupProcessor_SVC.ProcessingOptions options = new CRLP_RollupProcessor_SVC.ProcessingOptions();
        options.mode = CRLP_RollupProcessor_SVC.ProcessingMode.LDV;
        options.parentObjType = objType;
        options.detailObjType = Partial_Soft_Credit__c.SObjectType;
        options.mapOfRollupsByParentId = this.statefulRollupsById;
        options.mapOfProcessedOppIdsByAcctId = this.statefulMapOfOppIdsByAcct;

        if (objType == Account.SObjectType) {
            options.preventDupeOppsInRollup = true;
            options.parentKeyField = SObjectType.Partial_Soft_Credit__c.fields.Contact__c.getName().replace('__c','__r') +
                    '.' + SObjectType.Contact.fields.AccountId.getName();
        } else {
            options.preventDupeOppsInRollup = false;
            options.parentKeyField = SObjectType.Partial_Soft_Credit__c.fields.Contact__c.getName();
        }

        return options;
    }

    /********************************************************************************************************
     * @description Soft Credit roll-ups work by querying the OCR object as the main object, but sending
     * PartialSoftCredit records as the detail records for the rollups. This is because PSC has a custom field
     * for Amount and generally the rule is that every Donation has an OCR record, but may or may not have a PSC
     * record. This method creates non-committed PartialSoftCredit records where one doesn't already exist to
     * use for the rollups process.
     * @param detailRecords List<OpportunityContactRole>
     * @return List<Partial_Soft_Credit__c>
     */
    private List<Partial_Soft_Credit__c> buildPartialSoftCreditRecordsFromOCRs(List<OpportunityContactRole> detailRecords) {
        List<Id> oppIds = CRLP_RollupProcessor_SVC.getParentIdsFromDetailRecords(detailRecords, 'OpportunityId');
        String oppQuery = CRLP_Query_SEL.getDetailsQuery(Opportunity.SObjectType,
                new List<SObjectType>{ OpportunityContactRole.SObjectType, Partial_Soft_Credit__c.SObjectType }) +
                ' WHERE ID IN :oppIds';
        Map<Id, Opportunity> oppsMapById = new Map<Id, Opportunity>((List<Opportunity>)database.query(oppQuery));

        List<Partial_Soft_Credit__c> pscDetailRecords = new List<Partial_Soft_Credit__c>();

        for (OpportunityContactRole ocr : detailRecords) {
            Opportunity opp = oppsMapById.get(ocr.OpportunityId);

            // Find the matching PartialSoftCredit record for the OCR record; if there is one
            Partial_Soft_Credit__c matchedPSC;
            for (Partial_Soft_Credit__c psc : opp.Partial_Soft_Credits__r) {
                if (psc.Contact__c == ocr.ContactId) {
                    matchedPSC = psc.clone(true, true, true, true);
                    matchedPSC.Opportunity__r = opp;
                    break;
                }
            }
            if (matchedPSC == null) {
                // If there is no matched PartialSoftCredit record for this OCR, create a new one (not committed)
                // and set the Amount to the full Amount value from the Opportunity record.
                matchedPSC = new Partial_Soft_Credit__c(
                        Opportunity__c = opp.Id,
                        Opportunity__r = opp,
                        Contact__r = ocr.Contact,
                        Contact__c = ocr.ContactId,
                        Contact_Role_ID__c = ocr.Id,
                        Role_Name__c = ocr.Role,
                        Amount__c = opp.Amount
                );
            }
            pscDetailRecords.add(matchedPSC);
        }

        return pscDetailRecords;
    }
}