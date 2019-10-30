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
* @description Test class for ERR_RecordError_TEST
* @group ErrorHandling
*/
@isTest(isParallel=true)
private class ERR_RecordError_TEST {

    private class TestException extends Exception { }

    /*******************************************************************************************************
    * @description Unit Test of updateFullMessage, existing message is null, additional test for existing
    * is blank.
    */
    @IsTest
    private static void shouldUpdateFullMessageWithExistingNullMessage() {

        Datetime ts = System.now();

        String message = 'foo';

        String expectedMsg = ts.format() + ':\r\n' + message;

        System.assertEquals (expectedMsg, Err_RecordError.updateFullMessage(ts, null, message), 'null existing message, only single message expected');
        System.assertEquals (expectedMsg, Err_RecordError.updateFullMessage(ts, ' ', message), 'null existing message, only single message expected');
    }

    /*******************************************************************************************************
    * @description Unit Test of updateFullMessage, existing message is 'bar'
    */
    @IsTest
    private static void shouldUpdateFullMessageWithExistingMessage() {

        Datetime ts = System.now();

        String message = 'foo';
        String existingMessage = 'bar';

        String expectedMsg = ts.format() + ':\r\n' + message + '\r\n' + '========================================\r\n' + existingMessage;

        System.assertEquals (expectedMsg, Err_RecordError.updateFullMessage(ts, existingMessage, message), 'existing message check');
        }

    /*******************************************************************************************************
    * @description Unit Test for createRecordError and updateRecordError for invalid insert operation
    */
    @IsTest
    private static void shouldCreateAndUpdateDMLRecordErrorsForInvalidInsert() {
        Account acct = new Account();

        Database.SaveResult sr = Database.insert(acct, false);

        Error__c err = ERR_RecordError.createRecordError(sr, 'User', UserInfo.getUserId(), 'Test');

        System.assertEquals('User', err.Object_Type__c, 'Object Type');
        System.assertEquals('Test', err.Context_Type__c, 'Context Type');
        System.assertEquals(true, err.Retry_Pending__c, 'Retry Pending?');
        System.assertEquals(UserInfo.getUserId(), err.Related_Record_ID__c, 'Related Record ID');
        System.assertEquals(true, err.Record_URL__c.contains(UserInfo.getUserId()), 'Record URL');
        System.assertEquals(System.Label.errErrorTypeRequiredFieldMissing, err.Error_Type__c , 'Error Type');
        System.assertNotEquals(null, err.Full_Message__c, 'Full Message');

        // Setup certain values for next test
        err.Retry_Pending__c = false;
        err.Datetime__c = null;
        err.Error_Type__c = null;
        err.Full_Message__c = 'Bar';

        // Update Record Error Test
        err = ERR_RecordError.updateRecordError(err, sr);

        System.assertEquals('User', err.Object_Type__c, 'Object Type');
        System.assertEquals('Test', err.Context_Type__c, 'Context Type');
        System.assertEquals(true, err.Retry_Pending__c, 'Retry Pending?');
        System.assertEquals(UserInfo.getUserId(), err.Related_Record_ID__c, 'Related_Record ID');
        System.assertEquals(true, err.Record_URL__c.contains(UserInfo.getUserId()), 'Record URL');
        System.assertEquals(System.Label.errErrorTypeRequiredFieldMissing, err.Error_Type__c , 'Error Type');
        System.assertNotEquals('Bar', err.Full_Message__c, 'Full Message');
        System.assertEquals(true, err.Full_Message__c.contains('Bar'), 'Full Message');
    }

    /*******************************************************************************************************
    * @description Unit Test for createRecordError and updateRecordError for invalid undelete operation
    */
    @IsTest
    private static void shouldCreateAndUpdateDMLRecordErrorsForInvalidUndelete() {
        List<Account> accs = UTIL_UnitTestData_TEST.createMultipleTestAccounts(1, null);
        insert accs;

        Database.UndeleteResult udr = Database.undelete(accs[0], false);

        // Create Record Error Test
        Error__c err = ERR_RecordError.createRecordError(udr, 'Account', accs[0].Id, 'Test');

        System.assertEquals('Account', err.Object_Type__c, 'Object Type');
        System.assertEquals('Test', err.Context_Type__c, 'Context Type');
        System.assertEquals(true, err.Retry_Pending__c, 'Retry Pending?');
        System.assertEquals(accs[0].Id, err.Related_Record_ID__c, 'Related Record ID');
        System.assertEquals(true, err.Record_URL__c.contains(accs[0].Id), 'Record URL');
        System.assertEquals(System.Label.errErrorTypeOther, err.Error_Type__c , 'Error Type');
        System.assertNotEquals(null, err.Full_Message__c, 'Full Message');

        // Setup certain values for next test
        err.Retry_Pending__c = false;
        err.Datetime__c = null;
        err.Error_Type__c = null;
        err.Full_Message__c = 'Bar';

        // Update Record Error Test
        err = ERR_RecordError.updateRecordError(err, udr);

        System.assertEquals('Account', err.Object_Type__c, 'Object Type');
        System.assertEquals('Test', err.Context_Type__c, 'Context Type');
        System.assertEquals(true, err.Retry_Pending__c, 'Retry Pending?');
        System.assertEquals(accs[0].Id, err.Related_Record_ID__c, 'Related Record ID');
        System.assertEquals(true, err.Record_URL__c.contains(accs[0].Id), 'Record URL');
        System.assertEquals(System.Label.errErrorTypeOther, err.Error_Type__c , 'Error Type');
        System.assertNotEquals('Bar', err.Full_Message__c, 'Full Message');
        System.assertEquals(true, err.Full_Message__c.contains('Bar'), 'Full Message');
    }


    /*******************************************************************************************************
    * @description Unit Test for createRecordError and updateRecordError for invalid delete operation
    */
    @IsTest
    private static void shouldCreateAndUpdateDMLRecordErrorsForInvalidDelete() {
        List<Account> accs = UTIL_UnitTestData_TEST.createMultipleTestAccounts(1, null);
        insert accs;

        Id accsId = accs[0].Id;

        Database.DeleteResult dr = Database.delete(accs[0], false);
        dr = Database.delete(accs[0], false);

        Error__c err = ERR_RecordError.createRecordError(dr, 'Account', accsId, 'Test');

        System.assertEquals('Account', err.Object_Type__c, 'Object Type');
        System.assertEquals('Test', err.Context_Type__c, 'Context Type');
        System.assertEquals(true, err.Retry_Pending__c, 'Retry Pending?');
        System.assertEquals(accsId, err.Related_Record_ID__c, 'Related Record ID');
        System.assertEquals(true, err.Record_URL__c.contains(accsId), 'Record URL');
        System.assertEquals(System.Label.errErrorTypeOther, err.Error_Type__c , 'Error Type');
        System.assertNotEquals(null, err.Full_Message__c, 'Full Message');

        // Setup certain values for next test
        err.Retry_Pending__c = false;
        err.Datetime__c = null;
        err.Error_Type__c = null;
        err.Full_Message__c = 'Bar';

        // Update Record Error Test
        err = ERR_RecordError.updateRecordError(err, dr);

        System.assertEquals('Account', err.Object_Type__c, 'Object Type');
        System.assertEquals('Test', err.Context_Type__c, 'Context Type');
        System.assertEquals(true, err.Retry_Pending__c, 'Retry Pending?');
        System.assertEquals(accs[0].Id, err.Related_Record_ID__c, 'Related Record ID');
        System.assertEquals(true, err.Record_URL__c.contains(accs[0].Id), 'Record URL');
        System.assertEquals(System.Label.errErrorTypeOther, err.Error_Type__c , 'Error Type');
        System.assertNotEquals('Bar', err.Full_Message__c, 'Full Message');
        System.assertEquals(true, err.Full_Message__c.contains('Bar'), 'Full Message');
    }

    /*******************************************************************************************************
    * @description Unit Test for createRecordError and updateRecordError for non DML use case
    */
    @IsTest
    private static void shouldCreateAndUpdateNonDMLRecordError() {

        Error__c err = ERR_RecordError.createRecordError('Test Insert Message', 'NEW', 'User', UserInfo.getUserId(), 'Test');

        System.assertEquals('User', err.Object_Type__c, 'Object Type');
        System.assertEquals('Test', err.Context_Type__c, 'Context Type');
        System.assertEquals(true, err.Retry_Pending__c, 'Retry Pending?');
        System.assertEquals(UserInfo.getUserId(), err.Related_Record_ID__c, 'Related Record ID');
        System.assertEquals(true, err.Record_URL__c.contains(UserInfo.getUserId()), 'Record URL');
        System.assertEquals('NEW', err.Error_Type__c , 'Error Type');
        System.assertNotEquals(null, err.Full_Message__c, 'Full Message');
        System.assertEquals(true, err.Full_Message__c.contains('Test Insert Message'), 'Full Message contains Insert Message');
        // Setup certain values for next test
        err.Retry_Pending__c = false;
        err.Datetime__c = null;
        err.Error_Type__c = null;

        // Update Record Error Test
        err = ERR_RecordError.updateRecordError(err, 'Test Update Message', 'UPD');

        System.assertEquals('User', err.Object_Type__c, 'Object Type');
        System.assertEquals('Test', err.Context_Type__c, 'Context Type');
        System.assertEquals(true, err.Retry_Pending__c, 'Retry Pending?');
        System.assertEquals(UserInfo.getUserId(), err.Related_Record_ID__c, 'Related Record ID');
        System.assertEquals(true, err.Record_URL__c.contains(UserInfo.getUserId()), 'Record URL');
        System.assertEquals('UPD', err.Error_Type__c , 'Error Type');
        System.assertNotEquals(null, err.Full_Message__c, 'Full Message');
        System.assertEquals(true, err.Full_Message__c.contains('Test Insert Message'), 'Full Message contains Insert Message');
        System.assertEquals(true, err.Full_Message__c.contains('Test Update Message'), 'Full Message contains Update Message');
    }

    /*******************************************************************************************************
    * @description Unit Tests for adding Non DML Record Errors via ERR_RecordError class
    */
    @IsTest
    private static void shouldAddNonDMLRecordErrors() {
        List<Account> accs = UTIL_UnitTestData_TEST.createMultipleTestAccounts(7, null);
        insert accs;

        ERR_RecordError recordError = new ERR_RecordError('Test');

        Map<Id, String> errors= new Map<Id, String>();
        Map<Id, SObject> sObjects = new Map<Id, SObject>();

        for (Account acc :accs) {
            errors.put (acc.Id, 'Error1 for ' + acc.Name);
            sObjects.put(acc.Id, acc);
        }

        recordError.addErrors(errors, sObjects);
        for (Account acc :accs) {
            errors.put (acc.Id, 'Error2 for ' + acc.Name);
        }
        recordError.addErrors(errors, sObjects);

        if (recordError.isNewErrorsPresent()) {
            recordError.processErrors();
        }

        recordError.addErrors(errors, sObjects);
        for (Account acc :accs) {
            errors.put (acc.Id, 'Error3 for ' + acc.Name);
        }
        recordError.addErrors(errors, sObjects);
        recordError.processErrors();

        List<Error__c> errs = getErrors();
        System.assertEquals(7, errs.size(), '# of Errors in System');

        Map<Id, Error__c> errsByRecordId = getErrorsByRecordId();

        for (Account acc :accs) {
            Error__c err = errsByRecordId.get(acc.Id);
            System.assertEquals (true, err.Retry_Pending__c, 'Retry Pending?');
            System.assertEquals ('Test', err.Context_Type__c, 'Context Type');
            System.assertEquals (true, err.Full_Message__c.contains(acc.Name), 'Full Message [Name]');
            System.assertEquals (true, err.Full_Message__c.contains('Error1'), 'Full Message [Error1]');
            System.assertEquals (true, err.Full_Message__c.contains('Error2'), 'Full Message [Error2]');
            System.assertEquals (true, err.Full_Message__c.contains('Error3'), 'Full Message [Error3]');
        }
    }

    /*******************************************************************************************************
    * @description Unit Tests for adding DML Record Errors via ERR_RecordError class
    */
    @IsTest
    private static void shouldAddDMLRecordErrors() {
        List<Account> accs = UTIL_UnitTestData_TEST.createMultipleTestAccounts(7, null);
        insert accs;

        ERR_RecordError recordError = new ERR_RecordError('Test');

        Map<Id, SObject> sObjects = new Map<Id, SObject>();

        for (Account acc :accs) {
            sObjects.put(acc.Id, acc);
        }

        List<Database.DeleteResult> des = Database.delete (accs, false);
        des = Database.delete (accs, false);

        List<Id> accIds = new List<Id>();

        for (Account acc :accs) {
            sObjects.put(acc.Id, acc);
            accIds.add (acc.Id);
        }
        recordError.addErrors(des, accIds, accs);

        if (recordError.isNewErrorsPresent()) {
            recordError.processErrors();
        }

        List<Error__c> errs = getErrors();
        System.assertEquals(7, errs.size(), '# of Errors in System');

        Map<Id, Error__c> errsByRecordId = getErrorsByRecordId();

        for (Account acc :accs) {
            Error__c err = errsByRecordId.get(acc.Id);
            System.assertEquals (true, err.Retry_Pending__c, 'Retry Pending?');
            System.assertEquals ('Test', err.Context_Type__c, 'Context Type');
            System.assertEquals ('Account', err.Object_Type__c, 'Object Type');
            System.assertEquals (System.Label.errErrorTypeOther, err.Error_Type__c, 'Error Type');
            System.assertEquals (acc.Id, err.Related_Record_ID__c, 'Related Record ID');
            System.assertEquals (true, err.Record_URL__c.contains(acc.Id), 'Record URL');
            // Not asserting contents of Full Error since cannot control DML error text
            System.debug ('Full Error Message: ' + err.Full_Message__c);
        }

        List<Database.UnDeleteResult> udr = Database.undelete(accs, false);
        udr = Database.undelete(accs, false);

        recordError.addErrors(udr, accIds, accs);

        if (recordError.isNewErrorsPresent()) {
            recordError.processErrors();
        }

        errs = getErrors();
        System.assertEquals(7, errs.size(), '# of Errors in System');

        errsByRecordId = getErrorsByRecordId();

        for (Account acc :accs) {
            Error__c err = errsByRecordId.get(acc.Id);
            System.assertEquals (true, err.Retry_Pending__c, 'Retry Pending?');
            System.assertEquals ('Test', err.Context_Type__c, 'Context Type');
            System.assertEquals ('Account', err.Object_Type__c, 'Object Type');
            System.assertEquals (System.Label.errErrorTypeOther, err.Error_Type__c, 'Error Type');
            System.assertEquals (acc.Id, err.Related_Record_ID__c, 'Related Record ID');
            System.assertEquals (true, err.Record_URL__c.contains(acc.Id), 'Record URL');
            // Not asserting contents of Full Error since cannot control DML error text
            System.debug ('Full Error Message: ' + err.Full_Message__c);
            System.assertEquals(true, err.Full_Message__c.contains('==='), 'Full Message contains separator');
        }

        Account acc = new Account();
        Database.SaveResult sr = Database.insert(acc, false);


        recordError.addError (UserInfo.getUserId(), sr, acc);

        if (recordError.isNewErrorsPresent()) {
            recordError.processErrors();
        }

         errsByRecordId = getErrorsByRecordId();

        Error__c err = errsByRecordId.get(UserInfo.getUserId());

        System.assertEquals (true, err.Retry_Pending__c, 'Retry Pending');
        System.assertEquals ('Test', err.Context_Type__c, 'Context Type');
        System.assertEquals ('Account', err.Object_Type__c, 'Object Type');
        System.assertEquals (System.Label.errErrorTypeRequiredFieldMissing, err.Error_Type__c, 'Error Type');
        System.assertEquals (UserInfo.getUserId(), err.Related_Record_ID__c, 'Related Record ID');
        System.assertEquals (true, err.Record_URL__c.contains(UserInfo.getUserId()), 'Record URL');
    }

    /*******************************************************************************************************
    * @description Unit Tests for adding Non DML Record Errors via ERR_RecordError class while accounting
    * for existing records by retrieving them.
    */
    @IsTest
    private static void shouldAddNonDMLRecordErrorsWhileRetrievingExistingErrors() {
        List<Account> accs = UTIL_UnitTestData_TEST.createMultipleTestAccounts(7, null);
        insert accs;

        ERR_RecordError recordError = new ERR_RecordError('Test');

        Map<Id, String> errors= new Map<ID, String>();
        Map<Id, SObject> sObjects = new Map<Id, SObject>();

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

        //Switching to a different ERR_RecordError instance to simulate retrievingExistingErrorsFor...
        ERR_RecordError recordError2 = new ERR_RecordError('Test');
        recordError2.retrieveExistingErrorsFor(accs);

        for (Account acc :accs) {
            errors.put (acc.Id, 'Error3 for ' + acc.Name);
        }
        recordError2.addErrors(errors, sObjects);
        // Update of Record Errors
        if (recordError2.isNewErrorsPresent()) {
            recordError2.processErrors();
        }

        List<Error__c> errs = getErrors();
        System.assertEquals(7, errs.size(), '# of Errors should be 7');

        Map<Id, Error__c> errsByRecordId = getErrorsByRecordId();

        for (Account acc : accs) {
            Error__c err = errsByRecordId.get(acc.Id);
            System.assertEquals (true, err.Retry_Pending__c, 'Retry Pending?');
            System.assertEquals ('Test', err.Context_Type__c, 'Context Type');
            System.assertEquals (true, err.Full_Message__c.contains(acc.Name), 'Full Message [Name]');
            System.assertEquals (true, err.Full_Message__c.contains('Error1'), 'Full Message [Error1]');
            System.assertEquals (true, err.Full_Message__c.contains('Error2'), 'Full Message [Error2]');
            System.assertEquals (true, err.Full_Message__c.contains('Error3'), 'Full Message [Error3]');
        }
    }

    /*******************************************************************************************************
    * @description Unit Tests for adding Non DML Record Errors via ERR_RecordError class while accounting
    * for existing records by adding them via "with".
    */
    @IsTest
    private static void shouldAddNonDMLRecordErrorsWithExistingErrors() {
        List<Account> accs = UTIL_UnitTestData_TEST.createMultipleTestAccounts(7, null);
        insert accs;

        ERR_RecordError recordError = new ERR_RecordError('Test');

        Map<Id, String> errors= new Map<Id, String>();
        Map<Id, SObject> sObjects = new Map<Id, SObject>();

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

        List<Error__c> errs = getErrors();

        //Switching to a different ERR_RecordError instance to simulate handling existing errors via "with"
        ERR_RecordError recordError2 = new ERR_RecordError('Test').withExistingErrors(errs);

        for (Account acc :accs) {
            errors.put (acc.Id, 'Error3 for ' + acc.Name);
        }
        recordError2.addErrors(errors, sObjects);
        // Update of Record Errors
        if (recordError2.isNewErrorsPresent()) {
            recordError2.processErrors();
        }

        errs = getErrors();
        System.assertEquals(7, errs.size(), '# of Errors should be 7');

        Map<Id, Error__c> errsByRecordId = getErrorsByRecordId();

        for (Account acc : accs) {
            Error__c err = errsByRecordId.get(acc.Id);
            System.assertEquals (true, err.Retry_Pending__c, 'Retry Pending?');
            System.assertEquals ('Test', err.Context_Type__c, 'Context Type');
            System.assertEquals (true, err.Full_Message__c.contains(acc.Name), 'Full Message [Name]');
            System.assertEquals (true, err.Full_Message__c.contains('Error1'), 'Full Message [Error1]');
            System.assertEquals (true, err.Full_Message__c.contains('Error2'), 'Full Message [Error2]');
            System.assertEquals (true, err.Full_Message__c.contains('Error3'), 'Full Message [Error3]');
        }
    }

   /*******************************************************************************************************
    * @description Unit Tests for setting Retry Pending? to false, and adding a message for individual
    * records
    */
    @IsTest
    private static void shouldClearErrorForEachRecordError() {
        List<Account> accs = UTIL_UnitTestData_TEST.createMultipleTestAccounts(7, null);
        insert accs;

        ERR_RecordError recordError = new ERR_RecordError('Test');

        Map<Id, String> errors= new Map<Id, String>();
        Map<Id, SObject> sObjects = new Map<Id, SObject>();

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

        List<Error__c> errs = getErrors();

        //Switching to a different ERR_RecordError instance to simulate handling existing errors via "with"
        ERR_RecordError recordError2 = new ERR_RecordError('Test').withExistingErrors(errs);


        for (Account acc :accs) {
            recordError2.clearError (acc.Id, 'Error Resolved for ' + acc.Name);
        }

        if (recordError2.isNewErrorsPresent()) {
            recordError2.processErrors();
        }

        errs = getErrors();
        System.assertEquals(7, errs.size(), '# of Errors should be 7');

        Map<Id, Error__c> errsByRecordId = getErrorsByRecordId();

        for (Account acc : accs) {
            Error__c err = errsByRecordId.get(acc.Id);
            System.assertEquals (false, err.Retry_Pending__c, 'Retry Pending?');
            System.assertEquals ('Test', err.Context_Type__c, 'Context Type');
            System.assertEquals (true, err.Full_Message__c.contains(acc.Name), 'Full Message [Name]');
            System.assertEquals (true, err.Full_Message__c.contains('Error Resolved'), 'Full Message [Error Resolved]');
        }
    }

    /*******************************************************************************************************
    * @description Unit Tests for setting Retry Pending? to false, and adding a message for a Set of
    * Records.  The Set of Record Ids is of Type Set<String>
    */
    @IsTest
    private static void shouldClearErrorsStringVariantForRecordErrors() {
        List<Account> accs = UTIL_UnitTestData_TEST.createMultipleTestAccounts(7, null);
        insert accs;

        ERR_RecordError recordError = new ERR_RecordError('Test');

        Map<Id, String> errors= new Map<Id, String>();
        Map<Id, SObject> sObjects = new Map<Id, SObject>();

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

        List<Error__c> errs = getErrors();

        //Switching to a different ERR_RecordError instance to simulate handling existing errors via "with"
        ERR_RecordError recordError2 = new ERR_RecordError('Test').withExistingErrors(errs);
        Set<String> accIds = new Set<String>();

        for (Account acc : accs) {
            accIds.add(acc.Id);
        }

        recordError2.clearErrors (accIds, 'Error Resolved for record');


        if (recordError2.isNewErrorsPresent()) {
            recordError2.processErrors();
        }

        errs = getErrors();
        System.assertEquals(7, errs.size(), '# of Errors should be 7');

        Map<Id, Error__c> errsByRecordId = getErrorsByRecordId();

        for (Account acc : accs) {
            Error__c err = errsByRecordId.get(acc.Id);
            System.assertEquals (false, err.Retry_Pending__c, 'Retry Pending?');
            System.assertEquals ('Test', err.Context_Type__c, 'Context Type');
            System.assertEquals (true, err.Full_Message__c.contains(acc.Name), 'Full Message [Name]');
            System.assertEquals (true, err.Full_Message__c.contains('Error Resolved for record'), 'Full Message [Error Resolved for record]');
        }
    }

    /*******************************************************************************************************
    * @description Unit Tests for setting Retry Pending? to false, and adding a message for a Set of
    * Records.  The Set of Record Ids is of Type Set<Id>
    */
    @IsTest
    private static void shouldClearErrorsIdVariantForRecordErrors() {
        List<Account> accs = UTIL_UnitTestData_TEST.createMultipleTestAccounts(7, null);
        insert accs;

        ERR_RecordError recordError = new ERR_RecordError('Test');

        Map<Id, String> errors= new Map<Id, String>();
        Map<Id, SObject> sObjects = new Map<Id, SObject>();

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

        List<Error__c> errs = getErrors();

        //Switching to a different ERR_RecordError instance to simulate handling existing errors via "with"
        ERR_RecordError recordError2 = new ERR_RecordError('Test').withExistingErrors(errs);
        Set<ID> accIds = new Set<Id>();

        for (Account acc : accs) {
            accIds.add(acc.Id);
        }

        recordError2.clearErrors (accIds, 'Error Resolved for record');


        if (recordError2.isNewErrorsPresent()) {
            recordError2.processErrors();
        }

        errs = getErrors();
        System.assertEquals(7, errs.size(), '# of Errors should be 7');

        Map<Id, Error__c> errsByRecordId = getErrorsByRecordId();

        for (Account acc : accs) {
            Error__c err = errsByRecordId.get(acc.Id);
            System.assertEquals (false, err.Retry_Pending__c, 'Retry Pending?');
            System.assertEquals ('Test', err.Context_Type__c, 'Context Type');
            System.assertEquals (true, err.Full_Message__c.contains(acc.Name), 'Full Message [Name]');
            System.assertEquals (true, err.Full_Message__c.contains('Error Resolved for record'), 'Full Message [Error Resolved for record]');
        }
    }

    /*******************************************************************************************************
    * @description Unit Tests to confirm exception behavior when an unsupported DML Type is passed to the Record
    * Error classes.  Only SaveResult, DeleteResult, and UndeleteResult are currently supported.
    */
    @IsTest
    private static void shouldCheckDMLResultForUnsupportedDMLType() {
        Boolean exceptionThrown = false;
        try {
            Boolean err = ERR_RecordError.isDmlResultSuccess(UserInfo.getUserId());
            throw new TestException ('Invalid DML Type Exception Expected but was not thrown.');
        } catch (ERR_RecordError.RecordErrorHandlerException e) {
            System.assertEquals (true, e.getMessage().contains(System.Label.errErrorUnsupportedDMLType), 'Exception Message');
        }
    }

    /*******************************************************************************************************
    * @description Unit Tests to confirm exception behavior when the RecordError class is instantiated with
    * an invalid/missing context type.  Context Type cannot be blank/null as it is required
    */
    @IsTest
    private static void shouldCheckForExceptionOnInvalidContextType() {

        try {
            ERR_RecordError re = new ERR_RecordError('');
            throw new TestException ('Exception for blank Context Type expected but was not not thrown.');
        } catch (ERR_RecordError.RecordErrorHandlerException e) {
            System.assertEquals (true, e.getMessage().contains(System.Label.errErrorNoContext), 'Exception Message');
        }
    }

    // Helpers
    ////////////

    /**
     * @description Helper method to retrieve all error records
     */
    private static List<Error__c> getErrors() {
        return [SELECT  Id,
                        Context_Type__c,
                        Datetime__c,
                        Error_Type__c,
                        Full_Message__c,
                        Object_Type__c,
                        Related_Record_ID__c,
                        Record_URL__c,
                        Retry_Pending__c
            FROM Error__c
        ];
    }
    /**
     * @description Helper method to retrieve all error records into a Map by Salesforce Id
     */
    private static Map<Id, Error__c> getErrorsById() {
        return new Map<Id, Error__c>(
            [SELECT     Id,
                        Context_Type__c,
                        Datetime__c,
                        Error_Type__c,
                        Full_Message__c,
                        Object_Type__c,
                        Related_Record_ID__c,
                        Record_URL__c,
                        Retry_Pending__c
            FROM Error__c
        ]);
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