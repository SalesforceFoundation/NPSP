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
* @group API
* @group-content ../../ApexDocContent/API.htm
* @description Tests for CallableDispatchService_ERR
*/
@IsTest(IsParallel=true)
private class CallableDispatchService_ERR_TEST {
    /*******************************************************************************************************
    * @description Test Exception class
    ********************************************************************************************************/
    private class TestException extends Exception {}

   /**
    * @description Validates that an Exception is added to the Error Log via Callable API
    */
    @IsTest
    private static void shouldAddAnExceptionErrorToTheErrorObject() {
        UTIL_CustomSettingsFacade.getErrorSettingsForTests(new Error_Settings__c(
            Error_Notifications_On__c = true,
            Error_Notifications_To__c = UserInfo.getUserId(),
            Store_Errors_On__c = true,
            Respect_Duplicate_Rule_Settings__c = true));

        Test.startTest();

        TestException tExc = new TestException('This is a test');

        Map<String, Object> params = new Map<String, Object> {
            CallableDispatchService_ERR.PARAM_DISPATCH_ACTION_TYPE => 'addexception',
            CallableDispatchService_ERR.PARAM_CONTEXT_NAME => 'Test Context',
            CallableDispatchService_ERR.PARAM_EXCEPTION => tExc
        };

        Callable npspApi = (Callable) Type.forName('Callable_API').newInstance();

        Object result = npspApi.call('ERR.DispatchAction', params);

        Test.stopTest();

        List<Error__c> errs = getErrors();

        System.assertEquals (1, errs.size(), '# of Error Records Returned');
        System.assert(true, errs.get(0).Full_Message__c.contains('This is a test'));
    }

   /**
    * @description Validates that an Error Message is added to the Error Log via Callable API
    */
    @IsTest
    private static void shouldAddAnErrorMessageToTheErrorObject() {
        UTIL_CustomSettingsFacade.getErrorSettingsForTests(new Error_Settings__c(
            Error_Notifications_On__c = true,
            Error_Notifications_To__c = UserInfo.getUserId(),
            Store_Errors_On__c = true,
            Respect_Duplicate_Rule_Settings__c = true));

        Test.startTest();

        Map<String, Object> params = new Map<String, Object> {
            CallableDispatchService_ERR.PARAM_DISPATCH_ACTION_TYPE => 'adderror',
            CallableDispatchService_ERR.PARAM_CONTEXT_NAME => 'Test Context',
            CallableDispatchService_ERR.PARAM_MESSAGE => 'Error Message'
        };

        Callable npspApi = (Callable) Type.forName('Callable_API').newInstance();

        Object result = npspApi.call('ERR.DispatchAction', params);

        Test.stopTest();

        List<Error__c> errs = getErrors();

        System.assertEquals (1, errs.size(), '# of Error Records Returned');
        System.assert(true, errs.get(0).Full_Message__c.contains('Error Message'));
    }

    /*******************************************************************************************************
    * @description Unit Tests for adding Record Errors via Callable API
    */
    @IsTest
    private static void shouldAddAndUpdateRecordErrorsInTheErrorObject() {
        List<Account> accs = UTIL_UnitTestData_TEST.createMultipleTestAccounts(7, null);
        insert accs;

        Map<Id, String> errors= new Map<Id, String>();

        for (Account acc :accs) {
            errors.put (acc.Id, 'Error1 for ' + acc.Id);
        }

        Test.startTest();

        Map<String, Object> params = new Map<String, Object> {
            CallableDispatchService_ERR.PARAM_DISPATCH_ACTION_TYPE => 'addrecorderrors',
            CallableDispatchService_ERR.PARAM_CONTEXT_NAME => 'Test Context'
        };

        params.put(CallableDispatchService_ERR.PARAM_SOBJECTS, accs);
        params.put(CallableDispatchService_ERR.PARAM_ERR_MSGS_BY_RECORDID, errors);

        Callable npspApi = (Callable) Type.forName('Callable_API').newInstance();

        Object result = npspApi.call('ERR.DispatchAction', params);

        Map<Id, Error__c> errs = getErrorsByRecordId();

        System.assertEquals (7, errs.size(), '# of Error Records Returned');

        for (Account acc : accs) {
            Error__c err = errs.get(acc.Id);
            System.assertEquals(true, err.Full_Message__c.contains('Error1 for ' + acc.Id), 'Check for Error 1: ' + err.Full_Message__c);
        }

        // Set Second Error to Add
        for (Account acc :accs) {
            errors.put (acc.Id, 'Error2 for ' + acc.Id);
        }

        params.put(CallableDispatchService_ERR.PARAM_ERR_MSGS_BY_RECORDID, errors);

        result = npspApi.call('ERR.DispatchAction', params);

        Test.stopTest();

        errs = getErrorsByRecordId();

        System.assertEquals (7, errs.size(), '# of Error Records Returned');

        for (Account acc : accs) {
            Error__c err = errs.get(acc.Id);
            System.assertEquals(true, err.Full_Message__c.contains('Error1 for ' + acc.Id), 'Check for Error1 After Adding 2nd Error:' + err.Full_Message__c);
            System.assertEquals(true, err.Full_Message__c.contains('Error2 for ' + acc.Id), 'Check for Error:' + err.Full_Message__c);
        }
    }

    /*******************************************************************************************************
    * @description Unit Tests for adding DML Record Errors via Callable API
    */
    @IsTest
    private static void shouldAddDMLRecordErrorsInTheErrorObject() {
        List<Account> accs = UTIL_UnitTestData_TEST.createMultipleTestAccounts(7, null);
        insert accs;

        List<Database.DeleteResult> des = Database.delete (accs, false);
        des = Database.delete (accs, false);

        Test.startTest();

        Map<String, Object> params = new Map<String, Object> {
            CallableDispatchService_ERR.PARAM_DISPATCH_ACTION_TYPE => 'addrecorddmlerrors',
            CallableDispatchService_ERR.PARAM_CONTEXT_NAME => 'Test Context'
        };

        params.put(CallableDispatchService_ERR.PARAM_DML_RESULTS, des);
        params.put(CallableDispatchService_ERR.PARAM_SOBJECTS, accs);

        Callable npspApi = (Callable) Type.forName('Callable_API').newInstance();

        Object result = npspApi.call('ERR.DispatchAction', params);

        Map<Id, Error__c> errs = getErrorsByRecordId();

        System.assertEquals (7, errs.size(), '# of Errors In System');
    }

    /*******************************************************************************************************
    * @description Unit Tests for clearing Record Errors via Callable API
    */
     @IsTest
    private static void shouldClearRecordErrorsIfPresentInTheErrorObject() {
        List<Account> accs = UTIL_UnitTestData_TEST.createMultipleTestAccounts(7, null);
        insert accs;

        Map<Id, String> errors= new Map<Id, String>();

        for (Account acc :accs) {
            errors.put (acc.Id, 'Error1 for ' + acc.Id);
        }

        Test.startTest();

        Map<String, Object> params = new Map<String, Object> {
            CallableDispatchService_ERR.PARAM_DISPATCH_ACTION_TYPE => 'addrecorderrors',
            CallableDispatchService_ERR.PARAM_CONTEXT_NAME => 'Test Context'
        };

        params.put(CallableDispatchService_ERR.PARAM_SOBJECTS, accs);
        params.put(CallableDispatchService_ERR.PARAM_ERR_MSGS_BY_RECORDID, errors);

        Callable npspApi = (Callable) Type.forName('Callable_API').newInstance();

        Object result = npspApi.call('ERR.DispatchAction', params);

        Map<Id, Error__c> errs = getErrorsByRecordId();

        System.assertEquals (7, errs.size(), '# of Error Records Returned');

        for (Account acc : accs) {
            Error__c err = errs.get(acc.Id);
            System.assertEquals(true, err.Full_Message__c.contains('Error1 for ' + acc.Id), 'Check for Error 1: ' + err.Full_Message__c);
            System.assertEquals (true, err.Retry_Pending__c, 'Set to true when Error should be reprocessed');
        }

        params.clear();
        params.put(CallableDispatchService_ERR.PARAM_DISPATCH_ACTION_TYPE, 'clearrecorderrors');
        params.put(CallableDispatchService_ERR.PARAM_CONTEXT_NAME, 'Test Context');
        params.put(CallableDispatchService_ERR.PARAM_SOBJECTS, accs);
        params.put(CallableDispatchService_ERR.PARAM_MESSAGE, 'All set!');

        result = npspApi.call('ERR.DispatchAction', params);

        errs = getErrorsByRecordId();

        System.assertEquals (7, errs.size(), '# of Error Records Returned');

        for (Account acc : accs) {
            Error__c err = errs.get(acc.Id);
            System.assertEquals(true, err.Full_Message__c.contains('All set!'), 'Check for clear message: ' + err.Full_Message__c);
            System.assertEquals (false, err.Retry_Pending__c, 'Set to false when Error Retry is cleared');
        }
    }

    /**
     * @description Helper method to retrieve all error records
     */
    private static List<Error__c> getErrors() {
        return [SELECT Id,
                Full_Message__c,
                Stack_Trace__c,
                Email_Sent__c,
                Posted_in_Chatter__c,
                Context_Type__c
            FROM Error__c
        ];
    }

    /**
     * @description Helper method to retrieve all error records into a Map by Salesforce Id
     */
    private static Map<Id, Error__c> getErrorsByRecordId() {
        List<Error__c> errs =  [SELECT  Id,
                                        Context_Type__c,
                                        Datetime__c,
                                        Error_Type__c,
                                        Full_Message__c,
                                        Object_Type__c,
                                        Related_Record_ID__c,
                                        Record_URL__c,
                                        Retry_Pending__c
                                FROM Error__c];

        Map<Id, Error__c> errsByRecordId = new Map<Id, Error__c>();

        for (Error__c err : errs) {
            errsByRecordId.put (err.Related_Record_ID__c, err);
        }

        return errsByRecordId;
    }

}