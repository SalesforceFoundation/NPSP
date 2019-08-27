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
* @description Tests for ALLO_UpdPaymentAllocations_BATCH and ALLO_UpdPaymentAllocations_ERR_BATCH
*/
@IsTest
private class ALLO_UpdPaymentAllocations_TEST {
    // TODO: Confirm job ends and Errors are added if Payment Allocations Configuration is not Correct
    @isTest
    private static void incorrectPaymentAllocationsConfigurationLogsErrors() {

UTIL_CustomSettingsFacade.getAllocationsSettingsForTests(
       new Allocations_Settings__c(
              Payment_Allocations_Enabled__c = false,
              Default_Allocations_Enabled__c = false
        )
);

Test.startTest();

Database.executeBatch(new ALLO_UpdPaymentAllocations_BATCH(), TEST_BATCH_SIZE);

Test.stopTest();

// Query Error__c object, assert presence of configuration error for payment allocations batch

        //Database.excecuteBatch(new ALLO_UpdPaymentAllocations_TEST);

    }

    // TODO: Confirm Error Batch is not executed if there are errors in Payment Allocations Configuration
    // TODO: Confirm basic allocation / processing for Opportunities and Payments that need Allocations
                // Make sure One opportunity in test batch has invalid Allocations, and two payments one needing resized allocations, and one needing new allocations
                    // The resize of the payment allocations should still occur, but copying the allocations from the parent for the one without allocations should be skipped
                // Make sure there is an Opportunity with valid allocations, and payments to propogate to
                // Make sure there is an Opportunity with a null/zero amount and Allocations to convert to percent and zero out.  It should also have a Payment with allocations to zero out as well

    // TODO: Method: processRecords
    // Confirm uses existing ERR_RecordError class if passed in
    // Confirm it does/does not commit and clear Errors based on commitAndClearRecordErrors

    // TODO: Batch: ALLO_UpdPaymentAllocations_ERR_BATCH
    // Manually create Error Record for Opportunity configured to run through process successfully.  Execute Error Batch.  Confirm Retry Pending? value for Error record is cleared, etc. after the Allocations were successfully processed by the error Phase of the Batch job


}
