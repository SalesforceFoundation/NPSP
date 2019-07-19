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

    public static final String PROCESS_NAME = 'Payment Allocations Batch';

    private static Allocations_Settings__c allocationsSettings = UTIL_CustomSettingsFacade.getAllocationsSettings();

    private DateTime jobStart;
    private DateTime boundary;
    private Integer recCnt;
    private Integer reviewCnt;

    public ALLO_UpdPaymentAllocations_BATCH() {
        super();
        initialize();
    }

    public ALLO_UpdPaymentAllocations_BATCH(Integer batchSize) {
        super(batchSize);
        initialize();
    }


    public ALLO_UpdPaymentAllocations_BATCH(Integer batchSize, String additionalWhereClause) {
        super(batchSize, additionalWhereClause);
        initialize();
    }

    private void initialize() {
        this.recCnt = 0;
        this.reviewCnt = 0;
        this.boundary = (allocationsSettings != null && allocationsSettings.LastJobStartTimePaymentAllocations__c != null) ?
                        allocationsSettings.LastJobStartTimePaymentAllocations__c : System.now().addYears(-1);
    }

    /**
     * Overridable method called from the start method for any implementing classes logic just prior to execution of start.  firstChunk will be true
     * if running in non LDV mode, or if it is the first chunk of the batch.  This can be used to trigger logic at the start of the batch, including
     * recording a timestamp for last executed to use in future batches
     * @param bc BatchableContext provided by Salesforce
     * @param firstChunk Boolean indicating this is the first execution of the start method.
     */
    public override void onStart(Database.BatchableContext bc, Boolean firstChunk) {
        if (this.jobStart == null) {
            this.jobStart = System.now();
        }
    }

    /**
     * @description Actual processing occurs in this method
     * @param records The list of records returned for this batch, filtered for any additionalWhere clause added, and including the fields/subqueries configured for this batch
     */
    public override void doExecute(Database.BatchableContext bc, List<SObject>records ) {
        this.recCnt += records.size();

        Set<Id> oppIds = addIdsForRecords(new Set<Id>(), records);




    }


    private Set<Id> addIdsForRecords(Set<Id> ids, List<SObject> records) {

        for (SObject rec : records) {
            ids.add(rec.Id);
        }
        return ids;
    }

    /**
     * @description Required to set the main object the batch executes against
     */
    public override SObjectType getSObjectType() {
        return Opportunity.getSObjectType();
    }

    /**
     * Returns Full Query's Field List
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
     * Overridable test Where Clause to add to the inner query, or non LDV query, if not running in LDV/Chunking mode
     * @return String ''
     */
    public override String getWhereClause() {
        return '';
    }

    /**
     * @description Called on completion of the batch job.  If this is running LDV Mode it may be called more than once.  All but the last invocation will
     * have an isComplete value of false.  This method isd similar in nature/roughly equivalent to the finish method of a standard Apex Batch job
     * @param bc BatchableContext
     * @param isComplete boolean value that indicates whether or not this is the final invocation, or will be executing against additional chunks
     */
    public override void doFinish(Database.BatchableContext bc , Boolean isComplete) {
        if (isComplete) {
            System.debug('Record Count for ' + Opportunity.getSObjectType().getDescribe().getName() + ':' + recCnt);

            allocationsSettings.LastJobStartTimePaymentAllocations__c = this.jobStart;
            upsert allocationsSettings;

        }
    }

}
