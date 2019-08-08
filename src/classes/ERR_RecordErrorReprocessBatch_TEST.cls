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
* @description Tests for ERR_RecordErrorReprocessBatch_BASE
* @group ErrorHandling
*/
@IsTest(isParallel=true)
private class ERR_RecordErrorReprocessBatch_TEST {

    /*******************************************************************************************************
    * @description Unit Tests for reprocess error batch class
    */
    @IsTest
    private static void shouldReprocessAndClearRecordErrorsOnSuccess() {
        List<Account> accs = UTIL_UnitTestData_TEST.createMultipleTestAccounts(7, null);
        insert accs;

        ERR_RecordError recordError = new ERR_RecordError(ERR_RecordErrorReprocessBatch_MOCK.PROCESS_NAME);

        Map<String, String> errors= new Map<String, String>();
        Map<String, SObject> sObjects = new Map<String, SObject>();

        for (Account acc :accs) {
            errors.put (acc.Id, 'Error1 for ' + acc.Name);
            sObjects.put(acc.Id, acc);
        }

        recordError.addErrors(errors, sObjects);
        for (Account acc :accs) {
            errors.put (acc.Id, 'Error2 for ' + acc.Name);
        }
        recordError.addErrors(errors, sObjects);
        // Initial creation of error records
        if (recordError.isNewErrorsPresent()) {
            recordError.processErrors();
        }

        Set<Id> mockFixedIds = new Set<Id>();
        for (Integer i=0; i < 3; i++) {
            mockFixedIds.add(accs.get(i).Id);
        }

        Test.startTest();
        ERR_RecordErrorReprocessBatch_MOCK reprocessBatch = new ERR_RecordErrorReprocessBatch_MOCK();

        reprocessBatch.setFixedIds(mockFixedIds);
        Database.executeBatch(reprocessBatch, 200);
        Test.stopTest();

        Map<String, Error__c> errorsByRecordId = getErrorsByRecordId();

        for (Integer i = 0; i < accs.size(); i++) {
            Error__c err = errorsByRecordId.get(accs.get(i).Id);
            Id recId = err.Related_Record_Id__c;
            if (mockFixedIds.contains(recId)) {
                System.assertEquals (false, err.Retry_Pending__c, 'Retry Pending [Error Should be resolved]');
                System.assertEquals (true, err.Full_Message__c.contains(Label.errErrorRecordRetrySuccessful), 'Success Message not present: ' + err.Full_Message__c);
            } else {
                System.assertEquals (true, err.Retry_Pending__c, 'Retry Pending [Error should be Unresolved]');
                System.assertEquals (true, err.Full_Message__c.contains('Mock Error for'), 'Error Message not present');
            }
        }
    }

    /*******************************************************************************************************
    * @description Unit Tests to handle converting invalid Id
    */
    @IsTest
    private static void shouldReturnNullForInvalidId() {
        Id invalidId = ERR_RecordErrorReprocessBatch_BASE.convertToIdFromString('aa');
        System.assertEquals(null, invalidId, 'Id should be null');
    }

    /*******************************************************************************************************
    * @description Unit Tests for Constructors for ERR Reprocess Batch
    */
    @IsTest
    private static void shouldProperlyConstructBatch() {
        DateTime boundary = System.now().addDays(-1);

        ERR_RecordErrorReprocessBatch_MOCK reprocessBatch =  new ERR_RecordErrorReprocessBatch_MOCK(boundary);
        System.assertEquals(boundary, reprocessBatch.boundary, 'Boundary Only Constructor [boundary]');

        reprocessBatch =  new ERR_RecordErrorReprocessBatch_MOCK(150, boundary);
        System.assertEquals(boundary, reprocessBatch.boundary, 'BatchSize and Boundary Constructor [boundary]');
        System.assertEquals(150, reprocessBatch.getBatchSize(), 'BatchSize and Boundary Constructor [batchsize');
    }

    // Helpers
    ////////////

    /**
     * @description Helper method to retrieve all error records into a Map by Salesforce Id
     */
    private static Map<String, Error__c> getErrorsByRecordId() {
        List<Error__c> errs =  [SELECT  Id,
                                        Context_Type__c,
                                        Datetime__c,
                                        Error_Type__c,
                                        Full_Message__c,
                                        Object_Type__c,
                                        Related_Record_Id__c,
                                        Record_URL__c,
                                        Retry_Pending__c
                                FROM Error__c];

        Map<String, Error__c> errsByRecordId = new Map<String, Error__c>();

        for (Error__c err : errs) {
            errsByRecordId.put (err.Related_Record_Id__c, err);
        }

        return errsByRecordId;
    }

}