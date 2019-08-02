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
* @description Batch Job to recalculate Payment Allocations with errors reprocess Errors , Driven By
*              Error Records with the following characteristics:
*              - Record_Id__c != null
*              - Context_Type__c == 'Payment Allocations Batch'
*              - Retry_Pending__c == true
*/
public class ALLO_UpdPaymentAllocations_ERR_BATCH extends UTIL_AbstractCommon_BATCH {

    private static Allocations_Settings__c allocationsSettings = UTIL_CustomSettingsFacade.getAllocationsSettings();

    private Integer recCnt;
    private DateTime boundary;

    public ALLO_UpdPaymentAllocations_ERR_BATCH() {
        super();
        initialize();
    }

    public ALLO_UpdPaymentAllocations_ERR_BATCH(Integer batchSize) {
        super(batchSize);
        initialize();
    }


    public ALLO_UpdPaymentAllocations_ERR_BATCH(Integer batchSize, String additionalWhereClause) {
        super(batchSize, additionalWhereClause);
        initialize();
    }

    private void initialize() {
        this.recCnt = 0;
        this.boundary = (allocationsSettings != null && allocationsSettings.LastJobStartTimePaymentAllocations__c != null) ?
                        allocationsSettings.LastJobStartTimePaymentAllocations__c : System.now().addYears(-1);}

    /**
     * @description Actual processing occurs in this method
     * @param records The list of records returned for this batch, filtered for any additionalWhere clause added, and including the fields/subqueries configured for this batch
     */
    public override void doExecute(Database.BatchableContext bc, List<SObject>records ) {
        this.recCnt += records.size();
    }

    /**
     * @description Required to set the main object the batch executes against
     */
    public override SObjectType getSObjectType() {
        return Error__c.getSObjectType();
    }

    /**
     * Returns ID by default.  Can be modified to return other fields, and subQueries instead
     * @return String SOQL Query fragment consisting of fields and subqueries to retrieve, part between outer select and from
     */
    public override String getSOQLFullQueryFieldList() {
        return 'Id, ' +
                'Record_Id__c, ' +
                'Retry_Pending__c';
    }

    // TODO: Consider a modular approach to this batch where the data to retrieve could be parameterized for the Process, and the
    //       Implementing class could fulfill the contract to retry and then return success, or update the errors if
    //       additional errors occurred.

    /**
     * @description Returns the where clause for the payment allocations Batch for records that require reprocessing
     * @return String Where Clause for Batch Query
     */
    public override String getWhereClause() {
        return 'Context_Type__c =\'' + ALLO_UpdPaymentAllocations_BATCH.PROCESS_NAME + '\' and Retry_Pending__c = true';
    }

    /**
     * @description Called on completion of the batch job.  If this is running LDV Mode it may be called more than once.  All but the last invocation will
     * have an isComplete value of false.  This method isd similar in nature/roughly equivalent to the finish method of a standard Apex Batch job
     * @param bc BatchableContext
     * @param isComplete boolean value that indicates whether or not this is the final invocation, or will be executing against additional chunks
     */
    public override void doFinish(Database.BatchableContext bc , Boolean isComplete) {
        if (isComplete) {
        }
    }


}
