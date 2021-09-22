/*
    Copyright (c) 2021 Salesforce.org
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
* @date 2021
* @group Rollups
* @group-content ../../ApexDocContent/Rollups2.htm
* @description Skew mode queueable job to zero out summary records whose related detail records have been deleted.
*/
public class CRLP_ResetRollupFieldsQueueable implements System.Queueable {

    /** @description The job type for this batch job -- AccountHardCredit, AccountSoftCredit, etc.
     * Currently only supported for GAU jobType.
     */
    private CRLP_RollupProcessingOptions.RollupType jobType;

    /** @description Specified list of Summary (Account, Contact or GAU) Id's to roll up
     * Currently only supported for GAU jobType.
     */
    private List<Id> recordIds;

    /** @description The Summary Object Type this batch job will process
     * Currently only supported for GAU summaryObjectType.
     */
    private SObjectType summaryObjectType;

    public CRLP_ResetRollupFieldsQueueable(List<Id> recordIds) {
        this.jobType = CRLP_RollupProcessingOptions.RollupType.GAU;
        this.summaryObjectType = CRLP_Rollup_SVC.getSummaryObjectType(this.jobType);
        this.recordIds = recordIds;
    }

    /**
     * @description Call clearRollups to zero out the summary record Ids passed to the job.
     * @param qc
     */
    public void execute(QueueableContext qc) {
        try {
            if (recordIds == null) {
                this.recordIds = getParentRecordIds();
            }
            clearRollupFieldValues();
        } catch (Exception ex) {
            ERR_Handler.processError(ex, ERR_Handler_API.Context.CRLP + '.' + this.jobType.name());
        }
    }

    /**
     * @description Clear summary records for records whose associated details have been deleted after a skew mode run.
     */
    private void clearRollupFieldValues() {
        List<SObject> updatedRecords = getUpdatedRecords(getSummaryRecords());
        if (!updatedRecords.isEmpty()) {
            CRLP_RollupProcessor_SVC.updateChangedRecordsWithLogging(
                clearSkewModeFlag(updatedRecords), 
                jobType
            );
        }
    }

    /**
     * @description Get updated summary records.
     * @return List<SObject>
     */
    @TestVisible
    private List<SObject> getUpdatedRecords(List<SObject> parents) {
        CRLP_RollupProcessingOptions.ProcessingOptions options = new CRLP_RollupProcessingOptions.ProcessingOptions();
        options.useRollupDefsByParentIdMap = true;

        CRLP_RollupProcessor processor = new CRLP_RollupProcessor()
            .withRollupType(jobType)
            .withDetailRecords(new List<SObject>())
            .withRelatedRecords(new Map<Id, List<SObject>>())
            .withJobOptions(options);

        List<SObject> updatedRecords = new List<SObject>();
        for (SObject parent : parents) {
            SObject updatedRecord = processor.withSummaryRecord(parent).completeRollupForSingleSummaryRecord(parent);
            if (updatedRecord != null) {
                updatedRecords.add(updatedRecord);
            }
        }
        return updatedRecords;
    }

    /**
     * @description Query summary records by Id.
     * @return List<SObject>
     */
    @TestVisible
    private List<SObject> getSummaryRecords() {
        String query = CRLP_Query_SEL.buildObjectQueryForRollup(summaryObjectType) + ' WHERE Id IN :recordIds';
        List<SObject> parents = Database.query(query);
        return parents;
    }

    /**
     * @description Unconditionally set skew mode flag false.
     * @return List<SObject>
     */
    @TestVisible
    private List<SObject> clearSkewModeFlag(List<SObject> updatedRecords) {
        if ((this.summaryObjectType == Account.SObjectType || this.summaryObjectType == Contact.SObjectType)) {
            for (SObject updatedRecord : updatedRecords) {
                updatedRecord.put(UTIL_Namespace.StrTokenNSPrefix('CustomizableRollups_UseSkewMode__c'), false);
            }
        }
        return updatedRecords;
    }

    /**
     * @description Query parent records to clear.
     * @return List<Id>
     */
    private List<Id> getParentRecordIds() {
        Set<Id> gausWithChildren = getGAUsWithChildren();
        String query = 'SELECT Id FROM ' + UTIL_Namespace.StrTokenNSPrefix('General_Accounting_Unit__c') +
            ' WHERE Id NOT IN :gausWithChildren';

        List<Id> records = new List<Id>();
        for (SObject record : Database.query(query)) {
            records.add((Id) record.get('Id'));
        }
        return records;
    }

    /**
     * @description Query all GAU records with children.
     * @return Set<Id>
     */
    private Set<Id> getGAUsWithChildren() {
        String gauWithNamespace = UTIL_Namespace.StrTokenNSPrefix('General_Accounting_Unit__c');
        String query = 'SELECT ' + gauWithNamespace +
            ' FROM ' + UTIL_Namespace.StrTokenNSPrefix('Allocation__c') +
            ' GROUP BY ' + gauWithNamespace;

        Set<Id> gausWithChildren = new Set<Id>();
        for (AggregateResult result : (List<AggregateResult>) Database.query(query)) {
            gausWithChildren.add((Id) result.get(gauWithNamespace));
        }
        return gausWithChildren;
    }
}