/*
    Copyright (c) 2018, Salesforce.org
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
* @date 2018
* @group Rollups
* @group-content ../../ApexDocContent/Rollups2.htm
* @description Abstract base class Non-Skew Mode batch rollup operations
*/
public abstract class CRLP_Batch_Base_NonSkew extends CRLP_Batch_Base {

    protected CRLP_Batch_Base_NonSkew() { }

    // These 2 fields are used to check for Contacts or Accounts (both objects have the same fields) that may have
    // non-zero values in these fields even though they have no attached opportunities. In that case, the parents
    // are included in the queries/processing to ensure the values are reset accordingly. Now, the assumption here
    // is that these 2 fields are inclusive of the types of values that might have been incremented at some point
    // when an Opportunity was inserted/updated, but maybe that Opportunity was deleted or the reference changed.
    // There may be some custom rollups that use other fields that this wouldn't know about, or the user may have
    // modified the filters to somehow change those meaning. This is a good 99.9% check though.
    protected List<String> fieldsToCheckForNonZero {
        get {
            if (this.jobType == CRLP_RollupProcessingOptions.RollupType.ContactHardCredit ||
                    this.jobType == CRLP_RollupProcessingOptions.RollupType.AccountHardCredit
                    ) {
                return new List<String>{
                        'npo02__NumberOfClosedOpps__c', 'npo02__NumberOfMembershipOpps__c'
                };
            } else if (this.jobType == CRLP_RollupProcessingOptions.RollupType.ContactSoftCredit) {
                return new List<String>{
                        SObjectType.Contact.fields.Number_of_Soft_Credits__c.getName()
                };
            } else if (this.jobType == CRLP_RollupProcessingOptions.RollupType.GAU) {
                return new List<String>{
                        SObjectType.General_Accounting_Unit__c.fields.Total_Number_of_Allocations__c.getName()
                };
            }
            return new List<String>();
        } private set;
    }

    /*******************************************************************************************************
     * @description Constructs the class - Rollup all records that meet the "Non Skew" criteria
     * @param jobType Defines the type of rollup job
     * @param jobFilter Allows for filtering the rollups on N-Day, Memberships, etc.
     */
    public CRLP_Batch_Base_NonSkew(CRLP_RollupProcessingOptions.RollupType jobType, CRLP_RollupProcessingOptions.RollupTypeFilter jobFilter) {
        super(jobType, jobFilter);
    }

    /*******************************************************************************************************
     * @description Constructs the class - Rollup is for a specific set of Summary Object Id's
     * @param jobType Defines the type of rollup job
     * @param recordIds Specific set of parent record id's to roll up to
     */
    public CRLP_Batch_Base_NonSkew(CRLP_RollupProcessingOptions.RollupType jobType, List<Id> recordIds) {
        super(jobType, recordIds);
    }

    /*******************************************************************************************************
    * @description Query all Summary records for the current type of Rollups based on the defined 'jobType'. Called by
    * the start() method of the individual batch jobs that extend this class.
    * @return database.Querylocator
    */
    public database.Querylocator start(Database.BatchableContext bc) {
        try {
            initializeJobData();

            // Build a query string of the target Summary object.
            String query = CRLP_Query_SEL.buildObjectQueryForRollup(this.summaryObjectType);

            // Fields in the fieldsToCheckForNonZero[] list must always be in the Contact query
            for (String f : fieldsToCheckForNonZero) {
                if (!query.containsIgnoreCase(f)) {
                    query = query.split(' FROM ')[0] + ', ' + f + ' FROM ' + query.split(' FROM ')[1];
                }
            }

            List<String> whereClauses = new List<String>();

            // Add additional query filters as needed
            if (this.recordIds != null && this.recordIds.size() > 0) {
                whereClauses.add('Id IN :recordIds');
            } else {
                // Exclude Accounts or Contacts that will be rolled up in the SkewMode batch job
                String skewClause = CRLP_RollupBatch_SVC.getSkewWhereClause(this.jobType, CRLP_RollupProcessingOptions.BatchJobMode.NonSkewMode);
                if (!String.isEmpty(skewClause)) {
                    whereClauses.add(skewClause);
                }

                Customizable_Rollup_Settings__c customizableRollupSettings = UTIL_CustomSettingsFacade.getCustomizableRollupSettings();

                // Only use the related records filter if not disabled in settings and not running unit tests
                if (customizableRollupSettings.Disable_Related_Records_Filter__c == false && !Test.isRunningTest()) {
                    if (this.jobType == CRLP_RollupProcessingOptions.RollupType.AccountHardCredit) {
                        whereClauses.add('Id IN (SELECT AccountId FROM Opportunity ALLROWS)');
                    } else if (this.jobType == CRLP_RollupProcessingOptions.RollupType.ContactHardCredit) {
                        String contactField = SObjectType.Opportunity.fields.Primary_Contact__c.getName();
                        whereClauses.add('Id IN (SELECT ' + contactField + ' FROM Opportunity ALLROWS)');
                    } else if (this.jobType == CRLP_RollupProcessingOptions.RollupType.ContactSoftCredit) {
                        whereClauses.add('Id IN (SELECT ContactId FROM OpportunityContactRole ALLROWS)');
                    } else if (this.jobType == CRLP_RollupProcessingOptions.RollupType.AccountContactSoftCredit ||
                            this.jobType == CRLP_RollupProcessingOptions.RollupType.AccountSoftCredit ) {
                        // It's not possible to do an inner query on this due to the following Salesforce error:
                        // "The inner select field 'Contact.AccountId' cannot have more than one level of relationships"
                    } else if (this.jobType == CRLP_RollupProcessingOptions.RollupType.RecurringDonations) {
                        whereClauses.add('Id IN (SELECT npe03__Recurring_Donation__c FROM Opportunity ALLROWS)');
                    }
                }
            }

            // TODO DO we need to exclude Organization Donations??

            if (!whereClauses.isEmpty()) {
                query += ' WHERE ' + String.join(whereClauses, ' AND ');
            }

            // If there are no active rollups for the object type, then force the query to return zero records.
            if (hasActiveRollupsForThisJob() == false) {
                // This is needed because can't return null as a valid iterator.
                query += ' LIMIT 0';
            }

            UTIL_Debug.debug(LoggingLevel.WARN, '>> Batch Query =' + query);
            return Database.getQueryLocator(query);

        } catch (Exception ex) {
            ERR_Handler.processError(ex, ERR_Handler_API.Context.CRLP + '.' + this.jobType.name());
            return Database.getQueryLocator([SELECT Id FROM Account LIMIT 0]);
        }
    }

    /*******************************************************************************************************
    * @description Handle each group of Summary records to roll-up.
    * @param summaryRecords List of Summary records
    */
    public void execute(Database.BatchableContext bc, List<SObject> summaryRecords) {

        this.batchIteration++;
        try {
            initializeJobData();

            CRLP_RollupProcessingOptions.ProcessingOptions options = buildProcessingOptions();

            // Get the detail records for the current set of Summary Records
            // This could be Opportunity or OCR records
            List<SObject> detailRecords;
            if (jobType == CRLP_RollupProcessingOptions.RollupType.ContactHardCredit ||
                    jobType == CRLP_RollupProcessingOptions.RollupType.AccountHardCredit ||
                    jobType == CRLP_RollupProcessingOptions.RollupType.RecurringDonations) {
                detailRecords = CRLP_RollupProcessor_SVC.getDetailOppRecordsForParentRecords(summaryRecords, hasActivePaymentRollupsForThisJob(), options);

            } else if (jobType == CRLP_RollupProcessingOptions.RollupType.ContactSoftCredit ||
                    jobType == CRLP_RollupProcessingOptions.RollupType.AccountContactSoftCredit ||
                    jobType == CRLP_RollupProcessingOptions.RollupType.AccountSoftCredit) {

                npo02__Households_Settings__c householdSettings = UTIL_CustomSettingsFacade.getHouseholdsSettings();

                String query = CRLP_Query_SEL.buildDetailObjectQueryForRollup(this.detailObjectType, new List<SObjectType>());

                List<String> whereClauses = new List<String>();
                whereClauses.add(this.keyField + ' IN : summaryRecords');

                String addlFilter;
                if (jobType != CRLP_RollupProcessingOptions.RollupType.AccountSoftCredit) {
                    addlFilter = CRLP_Query_SEL.buildCommonQueryFilterOnOpportunity(this.summaryObjectType, Partial_Soft_Credit__c.SObjectType);
                } else {
                    addlFilter = CRLP_Query_SEL.buildCommonQueryFilterOnOpportunity(this.summaryObjectType, this.detailObjectType);
                }
                if (!String.isEmpty(addlFilter)) {
                    whereClauses.add(addlFilter);
                }

                if (jobType != CRLP_RollupProcessingOptions.RollupType.AccountSoftCredit) {
                    if (householdSettings.npo02__Always_Rollup_to_Primary_Contact__c == false) {
                        whereClauses.add('(IsPrimary = False OR Opportunity.Account.npe01__SYSTEMIsIndividual__c = False)');
                    } else {
                        whereClauses.add('IsPrimary = False');
                    }
                }

                if (!whereClauses.isEmpty()) {
                    query += ' WHERE ' + String.join(whereClauses, ' AND ');
                }

                // Note that the ORDER BY here doesn't guarantee that the records will actually be in this order
                query += ' ORDER BY ' + this.keyField;

                String createdDateClause;
                if (jobType != CRLP_RollupProcessingOptions.RollupType.AccountSoftCredit) {
                    createdDateClause = ', Opportunity.CreatedDate ASC ';
                } else {
                    createdDateClause = ', Opportunity__r.CreatedDate ASC ';
                }
                query += createdDateClause;

                UTIL_Debug.debug(LoggingLevel.WARN, '>> OCR Query =' + query);
                // Convert the list of OpportunityContactRole detail records into a list of PartialSoftCredit
                // records complete with the parent Opportunity details (CloseDate, Amount, ec.)
                if (jobType != CRLP_RollupProcessingOptions.RollupType.AccountSoftCredit) {
                    detailRecords = buildPartialSoftCreditRecordsFromOCRs(Database.query(query));
                } else {
                    detailRecords = Database.query(query);
                }
                UTIL_Debug.debug(LoggingLevel.WARN, '>> PSC Detail Record Size =' + detailRecords.size());

            }

            String parentObjectField;
            String parentKeyField = options.parentKeyField;

            // The parentKeyField field may be have dot-notation (ex: Contact__r.AccountId)
            // If this is the case, need to parse out the two components to use
            if (parentKeyField.contains('.')) {
                parentObjectField = parentKeyField.split('\\.')[0];
                parentKeyField = parentKeyField.split('\\.')[1];
            }

            // Strip out summary records where there are no detail records to process.
            Set<Id> parentIdHasDetailRecords = new Set<Id>(); // which parent records have details
            for (Integer n=0, listSize=detailRecords.size(); n<listSize; n++) {
                if (parentObjectField == null) {
                    parentIdHasDetailRecords.add((String)detailRecords[n].get(parentKeyField));
                } else {
                    SObject dtlRecord = detailRecords[n].getSObject(parentObjectField);
                    parentIdHasDetailRecords.add((String)dtlRecord.get(parentKeyField));
                }
            }

            List<SObject> newSummaryRecords = new List<SObject>();
            for (Integer n=0, listSize=summaryRecords.size(); n<listSize; n++) {
                if (parentIdHasDetailRecords.contains(summaryRecords[n].Id)) {
                    newSummaryRecords.add(summaryRecords[n]);
                } else if (this.summaryObjectType == Contact.SObjectType || this.summaryObjectType == Account.SObjectType) {
                    // If the Account and Contact is the Summary record, and there are no detail records, but the object
                    // has a value in any of these key rollup fields, then we need to include it so the values can be
                    // updated (reset) as necessary
                    for (String f : fieldsToCheckForNonZero) {
                        Object val = summaryRecords[n].get(f);
                        if (val != null && val != 0) {
                            newSummaryRecords.add(summaryRecords[n]);
                            break;
                        }
                    }
                }

            }
            summaryRecords = newSummaryRecords;

            // Are there any summary records left to process?
            if (summaryRecords.size() > 0) {

                Map<Id, List<SObject>> paymentsByOpp = new Map<Id, List<SObject>>();
                if (hasActivePaymentRollupsForThisJob() && (this.summaryObjectType == Account.SObjectType || this.summaryObjectType == Contact.SObjectType) && this.detailObjectType != Account_Soft_Credit__c.SObjectType) {
                    paymentsByOpp = CRLP_RollupProcessor_SVC.splitChildRecordsInMapByParentId(detailRecords, 'npe01__OppPayment__r');
                }

                // Call the method to do the actual rollups. This returns only records that require updating
                List<SObject> updatedRecords = CRLP_RollupProcessor_SVC.startRollupProcess(summaryRecords, detailRecords, paymentsByOpp, options);

                // Handle dml on the records to be updated
                if (updatedRecords != null && !updatedRecords.isEmpty()) {
                    CRLP_RollupProcessor_SVC.updateChangedRecordsWithLogging(updatedRecords, this.jobType);
                    this.totalRecordsModified += updatedRecords.size();
                    this.totalCommits++;
                }
            }

        } catch (Exception ex) {
            // TODO Not 100% sure we want to keep this, but for now it's needed to capture any unexpected errors in the processing logic
            ex.setMessage(ex.getMessage() + '\n\nRollups State:\n' + CRLP_Debug_UTIL.getCurrentRollupState());
            ERR_Handler.processError(ex, ERR_Handler_API.Context.CRLP + '.' + this.jobType.name());
        }
    }

    public void finish(Database.BatchableContext bc) {
        // In debug mode, write a summary of the job to the error log
        if (CRLP_Debug_UTIL.isDebuggingEnabled) {
            Error__c logEntry = new Error__c(
                    Context_Type__c = ERR_Handler_API.Context.CRLP.name() + ': ' + this.jobType.name() + ' ' + this.jobMode.name(),
                    Error_Type__c = 'DEBUG LOG',
                    Full_Message__c = ('Total Batch Iterations: ' + this.batchIteration + '\n' +
                            'Total DML Operations: ' + this.totalCommits + '\n' +
                            'Total Records Updates: ' + this.totalRecordsModified + '\n' +
                            'Rollups State:\n' + CRLP_Debug_UTIL.getCurrentRollupState()).left(32768)
            );
            insert logEntry;
        }
    }

    /**
     * @description Instantiate the ProcessingOptions class for Non-Skew Mode batch operations.
     */
    private CRLP_RollupProcessingOptions.ProcessingOptions buildProcessingOptions() {
        CRLP_RollupProcessingOptions.ProcessingOptions options = super.initOptionsInstance();
        options.detailObjType = this.detailObjectType;
        return options;
    }
}