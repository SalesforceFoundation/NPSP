/*
    Copyright (c) 2019, Salesforce.org
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
* @date 2019
* @group API
* @group-content ../../ApexDocContent/Rollups2.htm
* @description Handle executing the rollups for a specified set of Sobject data, even if that data is not actually
* commited to the Salesforce database. The parentId refers to the target Account, Contact, GAU or RD record - which
* must exist in the database for the rollup to complete.
*/
public without sharing class CRLP_ApiExecuteRollups {

    private CRLP_RollupProcessingOptions.RollupType rollupType;
    private Id parentId;
    private List<CRLP_Rollup> rollupDefs;
    private Map<Id, Map<SObjectType, List<SObject>>> rollupData;
    private SObject summaryRecord;
    private List<SObject> detailRecords;
    private Map<Id, List<SObject>> relatedRecords;
    private Map<Id, Contact> contactsForParentAccount;
    private Boolean commitToDb = false;

    private SObjectType summaryObjectType;

    public CRLP_ApiExecuteRollups() {}

    public CRLP_ApiExecuteRollups withRollupType(CRLP_RollupProcessingOptions.RollupType rollupType) {
        this.rollupType = rollupType;
        this.summaryObjectType = CRLP_Rollup_SVC.getSummaryObjectType(rollupType);
        return this;
    }
    public CRLP_ApiExecuteRollups withParentId(Id parentId) {
        this.parentId = parentId;
        return this;
    }
    public CRLP_ApiExecuteRollups withRollupDefs(List<CRLP_Rollup> rollupDefs) {
        this.rollupDefs = rollupDefs;
        return this;
    }
    public CRLP_ApiExecuteRollups withRollupData(Map<Id, Map<SObjectType, List<SObject>>> rollupData) {
        this.rollupData = rollupData;
        return this;
    }
    public CRLP_ApiExecuteRollups withCommitToDatabase(Boolean commitToDb) {
        this.commitToDb = commitToDb;
        return this;
    }

    /**
     * @description Use the details passed in the configuration methods to execute rollups and return the updated
     * collection of CRLP_Rollup instances. No DML will occur during this process.
     * @return List<CRLP_Rollup> updated rollup defs
     */
    public List<CRLP_Rollup> executeRollups() {

        String parentQuery = CRLP_Query_SEL.buildObjectQueryForRollup(summaryObjectType) + ' WHERE Id = :parentId LIMIT 1';
        summaryRecord = Database.query(parentQuery);

        // Converts the single Map of rollup data into detail and related objects
        convertRollupDataIntoDetailAndRelatedData(rollupData);

        CRLP_RollupProcessingOptions.ProcessingOptions options = new CRLP_RollupProcessingOptions.ProcessingOptions();
        options.doSummaryObjectComparison = commitToDb;
        options.useRollupDefsByParentIdMap = true;

        CRLP_RollupProcessor processor = new CRLP_RollupProcessor()
                .withRollupType(rollupType)
                .withSummaryRecord(summaryRecord)
                .withRollupDefinitions(rollupDefs)
                .withDetailRecords(detailRecords)
                .withRelatedRecords(relatedRecords)
                .withJobOptions(options);

        List<SObject> updatedRecords = processor.startRollupProcessing();

        if (commitToDb == true && updatedRecords != null) {
            Database.update(updatedRecords);
        }
        return processor.getRollupDefsForParent(parentId);
    }

    /**
     * @description Convert the rollup data received through the API into a format that can be used by the
     * rollup engine. The result is to populate the following properties:
     * - List<SObject> detailRecords (Opportunities, Allocations or AccountSoftCredits depending on Rollup Type)
     * - Map<Id, List<SObject>> relatedRecords (PartialSoftCredits or Payments depending on Rollup Type)
     * @param rollupData Map<Id, Map<SObjectType, List<SObject>>>
     */
    private void convertRollupDataIntoDetailAndRelatedData(Map<Id, Map<SObjectType, List<SObject>>> rollupData) {
        SObjectType detailObjectType = CRLP_Rollup_SVC.getDetailObjectType(rollupType);

        detailRecords = new List<SObject>();
        relatedRecords = new Map<Id, List<SObject>>();

        if (rollupType == CRLP_RollupProcessingOptions.RollupType.AccountContactSoftCredit) {
            getContactIdsForParentAccount();
        }

        for (Id oppId : rollupData.keySet()) {
            Opportunity oppRecord = (Opportunity)rollupData.get(oppId).get(Opportunity.SObjectType)[0];

            if (detailObjectType == Opportunity.SObjectType) {

                // When Opportunity as the Detail Object, the only possible Related object is Payments
                detailRecords.add(oppRecord);
                List<SObject> related = getRelatedRecords(oppRecord, rollupData.get(oppId));
                if (related != null && !related.isEmpty()) {
                    relatedRecords.put(oppId, related);
                }

            } else {

                // WHen the detail object is Allocation, OpportunityContactRole or Account_Soft_Credit__c
                // retrieve those converted records and set as the Detail. There are no related records for these.
                detailRecords.addAll(getRelatedRecords(oppRecord, rollupData.get(oppId)));
            }
        }
    }

    /**
     * @description Convert the Map of child data received into the api to the appropriate set of
     * related records needed for the specified rollup operation.
     * @param oppRecord
     * @param rollupChildData
     * @return List<SObject>
     */
    private List<SObject> getRelatedRecords(Opportunity oppRecord, Map<SObjectType, List<SObject>> rollupChildData) {
        Boolean hasPaymentRollups = CRLP_Rollup_SVC.hasActivePaymentRollupsForSObject(summaryObjectType);

        switch on rollupType {
            when AccountHardCredit, ContactHardCredit {
                if (hasPaymentRollups) {
                    return rollupChildData.get(npe01__OppPayment__c.SObjectType);
                }
            }
            when ContactSoftCredit, AccountContactSoftCredit {
                List<SObject> ocrRecords = rollupChildData.get(OpportunityContactRole.SObjectType);
                List<SObject> partialSoftCreditRecords = rollupChildData.get(Partial_Soft_Credit__c.SObjectType);

                List<Partial_Soft_Credit__c> pscDetailsForRollup = buildPartialSoftCreditRecordsFromOCRs(
                        oppRecord, ocrRecords, partialSoftCreditRecords);

                return pscDetailsForRollup;
            }
            when AccountSoftCredit {
                List<SObject> accountSoftCredits = new List<SObject>();
                if (rollupChildData.get(Account_Soft_Credit__c.SObjectType) != null) {
                    for (Account_Soft_Credit__c accSC : (List<Account_Soft_Credit__c>) rollupChildData.get(Account_Soft_Credit__c.SObjectType)) {
                        if (accSC.Account__c == parentId) {
                            accountSoftCredits.add(accSC);
                        }
                    }
                }

                return accountSoftCredits;
            }
            when GAU {
                // Convert the Related Allocation records in new Allocation records with a foreign key to the Opportunity
                List<SObject> allocations = new List<SObject>();
                if (rollupChildData.get(Allocation__c.SObjectType) != null) {
                    for (Allocation__c alloc : (List<Allocation__c>) rollupChildData.get(Allocation__c.SObjectType)) {
                        if (alloc.General_Accounting_Unit__c == parentId) {
                            Allocation__c newAlloc = alloc.clone(true, true, true, true);
                            newAlloc.Opportunity__r = oppRecord;
                            allocations.add(newAlloc);
                        }
                    }
                }

                return allocations;
            }
        }

        return null;
    }

    /**
     * @description Soft Credit roll-ups work by querying the OCR object as the main object, but sending
     * PartialSoftCredit records as the detail records for the rollups. This is because PSC has a custom field
     * for Amount and generally the rule is that every Donation has an OCR record, but may or may not have a PSC
     * record. This method creates non-committed PartialSoftCredit records where one doesn't already exist to
     * use for the rollups process.
     * @param parentId Summary Record Id (Account or Contact)
     * @param opp Opportunity record
     * @param ocrRecords OpportunityContactRole records for the Opp
     * @param partialSoftCreditRecords PartialSoftCredit records for the Opp
     * @return List<Partial_Soft_Credit__c>
     */
    private List<Partial_Soft_Credit__c> buildPartialSoftCreditRecordsFromOCRs(Opportunity opp,
            List<SObject> ocrRecords, List<SObject> partialSoftCreditRecords) {

        List<Partial_Soft_Credit__c> pscDetailRecords = new List<Partial_Soft_Credit__c>();

        if (ocrRecords == null || ocrRecords.isEmpty()) {
            return pscDetailRecords;
        }

        if (partialSoftCreditRecords == null) {
            partialSoftCreditRecords = new List<SObject>();
        }

        for (OpportunityContactRole ocr : (List<OpportunityContactRole>)ocrRecords) {
            Partial_Soft_Credit__c matchedPSC = matchOrCreatePartialSoftCredit(opp, ocr, partialSoftCreditRecords);
            switch on rollupType {
                when ContactSoftCredit {
                    if (ocr.ContactId == parentId) {
                        pscDetailRecords.add(matchedPSC);
                    }
                }
                when AccountContactSoftCredit {
                    // Is the ContactId is attached to the target (Summary) Parent Account for this rollup
                    if (contactsForParentAccount.containsKey(ocr.ContactId)) {
                        pscDetailRecords.add(matchedPSC);
                    }
                }
            }
        }

        return pscDetailRecords;
    }

    /**
     * @description For the given Opportunity and OpportunityContactRole, either match the OCR to an existing
     * partialSoftCredit record or create a new 'dummy' one that can be used for the Soft Credit Rollup job.
     * @param opp Opportunity
     * @param ocrRecord OpportunityContactRole
     * @param partialSoftCreditRecords PartialSoftCredit records to match against
     * @return Partial_Soft_Credit__c
     */
    private Partial_Soft_Credit__c matchOrCreatePartialSoftCredit(Opportunity opp, OpportunityContactRole ocrRecord,
            List<Partial_Soft_Credit__c> partialSoftCreditRecords) {

        // Find the matching PartialSoftCredit record for the OCR record; if there is one
        Partial_Soft_Credit__c matchedPSC;
        for (Partial_Soft_Credit__c psc : partialSoftCreditRecords) {
            if (psc.Contact__c == ocrRecord.ContactId) {
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
                    /*Contact__r = ocrRecord.Contact, */ // TODO This may need to an additional query to get Contact.AccountId
                    Contact__c = ocrRecord.ContactId,
                    Contact_Role_ID__c = ocrRecord.Id,
                    Role_Name__c = ocrRecord.Role,
                    Amount__c = opp.Amount
            );
            if (UserInfo.isMultiCurrencyOrganization()) {
                matchedPSC.put('CurrencyIsoCode', opp.get('CurrencyIsoCode'));
            }
        }

        return matchedPSC;
    }

    /**
     * @description AccountContactSoftCredits use the AccountId associated with the Contact on the OCR record
     * That may not be visible in data passed through the api. To address this, query the list of Contacts
     * on the target parent account and store those Id's in a map that can be validated against later on.
     */
    private void getContactIdsForParentAccount() {
        contactsForParentAccount = new Map<Id, Contact>([SELECT Id FROM Contact WHERE AccountId = :parentId]);
    }
}