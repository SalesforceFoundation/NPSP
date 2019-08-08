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
* @description Batch Job to Errors from the earlier executions of the Payment Allocation Batch Job
*/
public class ALLO_UpdPaymentAllocations_ERR_BATCH extends ERR_RecordErrorReprocessBatch_BASE {

    private static Allocations_Settings__c allocationsSettings = UTIL_CustomSettingsFacade.getAllocationsSettings();

    /**
     * @description Constructor
     * @param Integer batchSize The batch size the job should be re-executed with if multiple iterations are necessary
     * @param Datetime boundary The point after which Error Records for this process should be ignored because they are
     *        too recent (meaning they happened in the most recent batch execution)
     */
    public ALLO_UpdPaymentAllocations_ERR_BATCH(Integer batchSize, Datetime boundary) {
        super(batchSize, boundary);
    }

    /**
     * @description The Context Type Payment Allocations Batch Record Errors are stored under
     * @return String String representation of the Context Type Payment Allocations Batch Record Errors are stored under
     */
    public override String getContextType() {
        return ALLO_UpdPaymentAllocations_BATCH.PROCESS_NAME;
    }

    /**
     * @description Reprocesses Errors that occurred during the Payment Allocations Batch Execution
     * @param Set<Id> recordIds Set of Opportunity Ids to review and process
     * @param ERR_RecordError recErrs Instance of the ERR_RecordError class, populated by the Base Error Reprocessing Batch Class.
     * @return Set<Id> Any Opportunities that were successfully reprocessed.
     */
    public override Set<Id> reprocessRecords(Set<Id> recordIds, ERR_RecordError recErrs) {
        // We want to disable Allocation Triggers, have a RecordErrors Map to pass in, and do not want to commit and clear any errors
        // as this will be handled by the Error Reprocessing Base Class
        return ALLO_UpdPaymentAllocations_BATCH.processRecords(ALLO_UpdPaymentAllocations_BATCH.PROCESS_NAME, recordIds, recErrs, null, true, false);
    }

}
