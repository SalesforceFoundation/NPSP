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
* @description Customizable Rollups Batch for non-LDV-type Rollups
*/
public class CRLP_Rollup_BATCH extends CRLP_AbstractRollup_BATCH
        implements Database.Batchable<SObject>, Database.Stateful {

    // These 2 fields are used to check for Contacts or Accounts (both objects have the same fields) that may have
    // non-zero values in these fields even though they have no attached opportunities. In that case, the parents
    // are included in the queries/processing to ensure the values are reset accordingly. Now, the assumption here
    // is that these 2 fields are inclusive of the types of values that might have been incremented at some point
    // when an Opportunity was inserted/updated, but maybe that Opportunity was deleted or the reference changed.
    // There may be some custom rollups that use other fields that this wouldn't know about, or the user may have
    // modified the filters to somehow change those meaning. This is a good 99.9% check though.
    private List<String> fieldsToCheckForNonZero = new List<String>{
            'npo02__NumberOfClosedOpps__c', 'npo02__NumberOfMembershipOpps__c'
    };

    /*******************************************************************************************************
    * @description Constructs the class, sets the properties
    */
    public CRLP_Rollup_BATCH(SObjectType objType) {
        super(objType);
        this.isLdvBatchJob = false;
    }

    public CRLP_Rollup_BATCH(SObjectType objType, CRLP_RollupProcessingOptions.RollupTypeFilter jobTypeFilter) {
        super(objType);
        this.isLdvBatchJob = false;
        this.jobFilter = jobTypeFilter;
    }

    /*******************************************************************************************************
    * @description Constructs the class, sets the properties
    */
    public CRLP_Rollup_BATCH(List<Id> recordIds) {
        super(recordIds);
        this.isLdvBatchJob = false;
    }

    /*******************************************************************************************************
    * @description Query all Summary records for the rollups.
    * @param bc BatchableContext passed by the system call
    * @return database.Querylocator
    */
    public database.Querylocator start(Database.BatchableContext bc) {

        try {
            Integer maxRelatedOppsForNonLDVMode = CRLP_Rollup_SVC.getMaxRelatedOppsForNonLDVMode();
            String fldRelatedOppsCnt = (this.summaryObjectType == Contact.SObjectType ? 'Account.' : '') +
                    UTIL_Namespace.StrAllNSPrefix('Number_of_Opportunities__c');

            // Build a query string of the target Summary object.
            String query = CRLP_Query_SEL.getResultsQuery(this.summaryObjectType);

            // Fields in the fieldsToCheckForNonZero[] list must always be in the Contact query
            if (this.summaryObjectType == Contact.SObjectType) {
                for (String f : fieldsToCheckForNonZero) {
                    if (!query.containsIgnoreCase(f)) {
                        query = query.split(' FROM ')[0] + ', ' + f + ' FROM ' + query.split(' FROM ')[1];
                    }
                }
            }

            query += ' WHERE ' + fldRelatedOppsCnt + ' < :maxRelatedOppsForNonLDVMode';

            // Add additional query filters as needed
            if (this.recordIds != null && this.recordIds.size() > 0) {
                query += ' AND Id IN :recordIds';
            } else if (this.summaryObjectType == Account.SObjectType) {
                // If the Summary Object is the Account, then filter on Accounts that have at least a single
                // Opportunity attached. This is helpful to reduce the overall query size.
                // To handle a scenario where an attached Oppportunity was deleted, but the record not recalculated
                // also include any records where the TotalGifts or TotalMemberships fields are not zero
                query += ' AND (' + fldRelatedOppsCnt + ' > 0' +
                    ' OR npo02__NumberOfClosedOpps__c > 0 OR npo02__NumberOfMembershipOpps__c > 0)';
            }

            // If there are no active rollups for the object type, then force the query to return zero records.
            if (CRLP_Rollup_SVC.hasActiveRollupsForSObject(this.summaryObjectType) == false) {
                // This is needed because can't return null as a valid iterator.
                query += ' LIMIT 0';
            }

            if (this.summaryObjectType == Account.SObjectType) {
                this.jobType = CRLP_RollupProcessingOptions.RollupType.AccountHardCredit;
            } else if (this.summaryObjectType == Contact.SObjectType) {
                this.jobType = CRLP_RollupProcessingOptions.RollupType.ContactHardCredit;
            }
            this.statefulCacheOfRollupsToBeProcessed.put(this.summaryObjectType,
                    CRLP_Rollup_SEL.getRollupDefinitionsToUse(this.jobType, this.jobFilter));

            return Database.getQueryLocator(query);

        } catch (Exception ex) {
            // TODO Not 100% sure we want to keep this, but for now it's needed to capture any unexpected errors in the processing logic
            ex.setMessage(ex.getMessage() + '\n\nRollups State:\n' + CRLP_Debug_UTIL.getCurrentRollupState());
            ERR_Handler.processError(ex, ERR_Handler_API.Context.CRLP);
        }

        return Database.getQueryLocator([SELECT Id FROM Account LIMIT 0]); // return a generic empty data set rather than null
    }

    /*******************************************************************************************************
    * @description Handle each group of Summary records to roll-up.
    * @param bc BatchableContext passed by the system call
    * @param scope List of Summary records
    */
    public void execute(Database.BatchableContext bc, List<SObject> summaryRecords) {

        this.batchIteration++;
        try {

            CRLP_RollupProcessingOptions.ProcessingOptions options = initOptionsInstance();
            options.detailObjType = Opportunity.SObjectType;

            // Get the detail records for the current set of Summary Records
            Boolean includeChildPayments = CRLP_Rollup_SVC.hasActivePaymentRollupsForSObject(this.summaryObjectType);
            List<SObject> detailRecords = CRLP_RollupProcessor_SVC.getDetailOppRecordsForParentRecords(summaryRecords, includeChildPayments, options);

            // Strip out summary records where there are no detail records to process.
            // This is not needed for Accounts because the main query on Account already includes this filter.
            if (this.summaryObjectType == Contact.SObjectType) {

                Set<Id> parentsWithDetails = new Set<Id>(); // which parent records have details

                // The Contact object is always rolling up from Opportunities so no need to use the generic SObject
                List<Opportunity> opps = (List<Opportunity>) detailRecords;
                for (Integer n=0, listSize=opps.size(); n<listSize; n++) {
                    parentsWithDetails.add(opps[n].Primary_Contact__c);
                }

                // These 2 fields have to be included in every query.
                List<SObject> newSummaryRecords = new List<SObject>();
                for (Integer n=0, listSize=summaryRecords.size(); n<listSize; n++) {
                    SObject parentRecord = summaryRecords[n];
                    Boolean processParentRecord = parentsWithDetails.contains(parentRecord.Id);
                    if (!processParentRecord) {
                        // no details, but are the any of these key fields not zero/null?
                        for (String f : fieldsToCheckForNonZero) {
                            if (parentRecord.get(f) != null && (Double) parentRecord.get(f) > 0) {
                                processParentRecord = true;
                                break;
                            }
                        }
                    }
                    if (processParentRecord) {
                        newSummaryRecords.add(parentRecord);
                    }
                }
                summaryRecords = newSummaryRecords;
            }

            // Are there any summary records left to process?
            if (summaryRecords.size() > 0) {
                // Call the method to do the actual rollups. This returns only records that require updating
                List<SObject> updatedRecords = CRLP_RollupProcessor_SVC.startRollupProcess(summaryRecords, detailRecords, options);

                CRLP_RollupProcessor_SVC.updateChangedRecordsWithLogging(updatedRecords);
            }

        } catch (Exception ex) {
            // TODO Not 100% sure we want to keep this, but for now it's needed to capture any unexpected errors in the processing logic
            ex.setMessage(ex.getMessage() + '\n\nRollups State:\n' + CRLP_Debug_UTIL.getCurrentRollupState());
            ERR_Handler.processError(ex, ERR_Handler_API.Context.CRLP);
        }
    }

    /********************************************************************************************************
     * @description nothing to do here
     */
    public void finish(Database.BatchableContext bc) {
    }

}