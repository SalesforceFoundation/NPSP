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
* @description Customizable Rollups Batch for non-LDV-type Rollups
*/
public class CRLP_Rollup_BATCH implements Database.Batchable<SObject>, Database.Stateful {

    /** @description The Summary Object Type this batch job will process */
    private SObjectType summaryObjectType;

    /** @description Specified list of Summary (Account, Contact, or GAU) Id's to roll up */
    private List<Id> recordIds;

    /** @description Simple stateful counters used to track state */
    private Integer batchIteration = 0;
    private Integer totalRecordsModified = 0;

    /*******************************************************************************************************
    * @description Constructs the class, sets the properties
    */
    public CRLP_Rollup_BATCH(SObjectType objType) {
        this.summaryObjectType = objType;
    }

    /*******************************************************************************************************
    * @description Constructs the class, sets the properties
    */
    public CRLP_Rollup_BATCH(List<Id> recordIds) {
        this.summaryObjectType = recordIds[0].getSobjectType();
        this.recordIds = recordIds;
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
            String query = CRLP_Query_SEL.getResultsQuery(this.summaryObjectType) +
                    ' WHERE ' + fldRelatedOppsCnt + ' < :maxRelatedOppsForNonLDVMode';

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

            if (CRLP_Rollup_SVC.hasActiveRollupsForSObject(this.summaryObjectType) == false) {
                // If there are no active rollups for the object type, then force the query to return zero records.
                // This is needed because can't return null as a valid iterator.
                query += ' LIMIT 0';
            }

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
            // Get the detail records for the current set of Summary Records
            List<SObject> detailsRecords = CRLP_RollupProcessor_SVC.getDetailRecordsFromParentRecords(summaryRecords);

            // Build the processing options instance
            CRLP_RollupProcessor_SVC.ProcessingOptions options = new CRLP_RollupProcessor_SVC.ProcessingOptions();
            options.mode = CRLP_RollupProcessor_SVC.ProcessingMode.NonLDV;
            options.parentObjType = this.summaryObjectType;
            options.detailObjType = Opportunity.SObjectType;
            if (this.summaryObjectType == Account.SObjectType) {
                options.parentKeyField = SObjectType.Opportunity.fields.AccountId.getName();
            } else if (this.summaryObjectType == Contact.SObjectType) {
                options.parentKeyField = SObjectType.Opportunity.fields.Primary_Contact__c.getName();
            }

            // Call the method to do the actual rollups. This returns only records that require updating
            List<SObject> updatedRecords = CRLP_RollupProcessor_SVC.startRollupProcess(summaryRecords, detailsRecords, options);

            CRLP_RollupProcessor_SVC.updateChangedRecordsWithLogging(updatedRecords);
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