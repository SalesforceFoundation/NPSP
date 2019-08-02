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
* @group Allocations
* @group-content ../../ApexDocContent/Allocations.htm
* @description Batch Job to update/recalculate Payment Allocations (Main Batch, Driven by Opportunity Object)
*/
public class ALLO_UpdPaymentAllocations_BATCH extends UTIL_AbstractCommon_BATCH {

    public class AlloPaymentAllocationBatchException extends Exception { }

    public static final String PROCESS_NAME = 'Payment Allocations Batch';

    private static Allocations_Settings__c allocationsSettings = UTIL_CustomSettingsFacade.getAllocationsSettings();

    private DateTime jobStart;
    private DateTime boundary;
    private Integer recCnt;
    private Integer reviewCnt;
    private Boolean paymentAllocConfigurationValid;

   /**
     * Constructor (takes no arguments)
     */
     public ALLO_UpdPaymentAllocations_BATCH() {
        super();
        initialize();
    }

    /**
     * Constructor (takes batchSize as parameters)
     * @param  batchSize Controls the number of records that can be processed in a batch
     */
    public ALLO_UpdPaymentAllocations_BATCH(Integer batchSize) {
        super(batchSize);
        initialize();
    }

    /**
     * Constructor (takes batchSize, additionalWhere as parameters)
     * @param  batchSize Controls the number of records that can be processed in a batch
     * @param  additionalWhereClause Any additional whereclause fragment to add to the batch job
     */
    public ALLO_UpdPaymentAllocations_BATCH(Integer batchSize, String additionalWhereClause) {
        super(batchSize, additionalWhereClause);
        initialize();
    }

    /**
     * @description Sets up various tracking/usage variables, and looks up the current boundary timestamp (or defaults it if not already present)
     */
    private void initialize() {
        this.recCnt = 0;
        this.reviewCnt = 0;
        this.boundary = (allocationsSettings != null && allocationsSettings.LastJobStartTimePaymentAllocations__c != null) ?
                        allocationsSettings.LastJobStartTimePaymentAllocations__c : System.now().addYears(-1);

    }

    /**
     * @description Called on Batches start.  Used to capture the jobStart timestamp, and to validate the Payment Allocations configuration
     * @param bc BatchableContext provided by Salesforce
     * @param firstChunk Boolean indicating this is the first execution of the start method.
     */
    public override void onStart(Database.BatchableContext bc, Boolean firstChunk) {
        if (this.jobStart == null) {
            this.jobStart = System.now();
        }
        this.paymentAllocConfigurationValid = validatePaymentAllocationsConfiguration();
    }

    /**
     * @description Validates that Payment Allocations are configured correctly.  Returns false if not correct.  Also logs an error.
     * Returns true, if there are no Payment Allocation configuration Issues
     * @returns Boolean true if Payment Allocations Config is valid, and false otherwise
     */
    private Boolean validatePaymentAllocationsConfiguration() {
        List<String> paCfgProblems = ALLO_AllocationsUtil.validatePaymentAllocationsConfiguration();
        if (paCfgProblems.size() > 0) {
            String errorMsg = System.Label.alloPaymentAllocationBatchConfigError + '\r\n' + String.join(paCfgProblems, '\r\n');
            AlloPaymentAllocationBatchException apabe = new AlloPaymentAllocationBatchException(errorMsg);

            ERR_Handler.processError(apabe, PROCESS_NAME);
        }
        // Valid if no messages added
        return (paCfgProblems.size() == 0);
    }

    /**
     * @description Actual processing occurs in this method
     * @param bc BatchableContext
     * @param records The list of records returned for this batch, filtered for any additionalWhere clause added, and including the fields/subqueries configured for this batch
     */
    public override void doExecute(Database.BatchableContext bc, List<SObject>records ) {
        this.recCnt += records.size();

        Set<Id> oppIds = addIdsForRecords(new Set<Id>(), records);
        ALLO_AllocationsUtil.RecordsForReview recs = ALLO_AllocationsUtil.determineRecordsRequiringReview(PROCESS_NAME, oppIds, boundary);

        this.reviewCnt += recs.oppsById.size();

        // Disable Allocation Triggers prior to making any DML Updates
        ALLO_AllocationsUtil.disableAllocationTriggers();

        // Will track exclusions across processes
        ALLO_AllocationsUtil.RecordExclusions recExcl = new ALLO_AllocationsUtil.RecordExclusions();

        // Process Opportunity Allocations
        ALLO_AllocationsUtil.AllocationResults allocResults = ALLO_AllocationsUtil.processOpportunityAllocations(recs.oppsById, recs.oppsAllocations, recs.campaignAllocations, recs.recurringDonationAllocations, recExcl);

        // Process Opportunity Allocation Results
        ALLO_AllocationsUtil.processAllocationResults(ALLO_AllocationsUtil.PROCESS_DEF.OPP_ALLOC_UPD, allocResults, recs, recExcl);

        // Process Payment Allocations
        allocResults = ALLO_AllocationsUtil.processPaymentAllocations(recs.oppsById, recs.oppsAllocations, recs.paymentAllocations, recExcl);

        // Process Payment Allocations Results
        ALLO_AllocationsUtil.processAllocationResults(ALLO_AllocationsUtil.PROCESS_DEF.PMT_ALLOC, allocResults, recs, recExcl);

        // Commit all pending errors
        recs.recErrs.processErrors();

        // Enable Allocation Triggers after all updates are complete
        ALLO_AllocationsUtil.enableAllocationTriggers();
    }

    /**
     * @description Takes a set of Ids, and adds additional record Ids to it from the list of records
     * @param Set<Id> ids The set of Ids to add to
     * @param List<SObject> records The records to be added to the Set of Ids
     * @return Set<Id> the updated Set of Ids
     */
    private Set<Id> addIdsForRecords(Set<Id> ids, List<SObject> records) {

        for (SObject rec : records) {
            ids.add(rec.Id);
        }
        return ids;
    }

    /**
     * @description In this case, the main driver will be the Opportunity
     * @return Opportunity's SObjectType
     */
    public override SObjectType getSObjectType() {
        return Opportunity.getSObjectType();
    }

    /**
     * @description Returns Full Query's Field List
     * @return String SOQL Query fragment consisting of fields and subqueries to retrieve, part between outer select and from
     */
    public override String getSOQLFullQueryFieldList() {
        return  'Id, ' +
                'Amount, ' +
                'CloseDate, ' +
                'Name, ' +
                'npe03__Recurring_Donation__c, ' +
                'StageName, ' +
                'LastModifiedDate, ' +
                '(select    Id, ' +
                            'npe01__Payment_Amount__c, ' +
                            'npe01__Payment_Date__c, ' +
                            'npe01__Scheduled_Date__c, ' +
                            'npe01__Written_Off__c, ' +
                            'npe01__Paid__c, ' +
                            'npe01__Opportunity__c, ' +
                            'LastModifiedDate, ' +
                            'Name ' +
                'from npe01__OppPayment__r)';
    }

    /**
     * @description If Payment Allocations Configuration is Invalid, it will short circuit the batch so it does not process any records
     * @return String Where clause
     */
    public override String getWhereClause() {

        return (!this.paymentAllocConfigurationValid) ? 'Name=\'\'' : '';
    }

    /**
     * @description Records the most recent time this job started.  This is set only in the final iteration.
     * @param bc BatchableContext
     * @param isComplete boolean value that indicates whether or not this is the final invocation, or will be executing against additional chunks
     */
    public override void doFinish(Database.BatchableContext bc , Boolean isComplete) {
        if (isComplete) {
            allocationsSettings.LastJobStartTimePaymentAllocations__c = this.jobStart;
            upsert allocationsSettings;

        }
    }

}
