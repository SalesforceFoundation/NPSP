/*
    Copyright (c) 2014, Salesforce.org
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
* @date 2014
* @description test class for error handling
* @group ErrorHandling
*/
@isTest
private class ERR_Handler_TEST {
    private static final TEST_SObjectGateway.ErrorGateway errorGateway = new TEST_SObjectGateway.ErrorGateway();
    private static final String ERROR_CONTEXT = ERR_Handler_API.Context.STTG.name();

    private static Id chatterGroupId;
    private static StringException testException = new StringException('Test Exception');

    /*******************************************************************************************************
    * @description test setup of error notifications via chatter
    */
    private static void setupWithChatterNotifications() {
        // all these tests are about testing our error handling, so we can't let the assert interfere
        TDTM_TriggerHandler.suppressDebugAssertAfterErrorLogging = true;

        UTIL_CustomSettingsFacade.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c(
            npe01__Account_Processor__c = CAO_Constants.HH_ACCOUNT_PROCESSOR));
        UTIL_CustomSettingsFacade.getHouseholdsSettingsForTests(new npo02__Households_Settings__c (
            npo02__Household_Rules__c = HH_Households.ALL_PROCESSOR, npo02__Enable_Opp_Rollup_Triggers__c = true));

        if (Schema.SObjectType.User.isFeedEnabled()) {
            SObject chatterGroup = (SObject)System.Type.forName('CollaborationGroup').newInstance();
            chatterGroup.put('Name', 'ChatterTestGroup');
            chatterGroup.put('CollaborationType', 'Private');
            insert chatterGroup;

            chatterGroupId = chatterGroup.Id;
        }

        UTIL_CustomSettingsFacade.getErrorSettingsForTests(new Error_Settings__c(
            Error_Notifications_On__c = true,
            Error_Notifications_To__c = chatterGroupId,
            Store_Errors_On__c = true,
            Respect_Duplicate_Rule_Settings__c = true
        ));
    }

    /*******************************************************************************************************
    * @description test setup of error notifications via email
    */
    private static void setupWithEmailNotifications() {
        // all these tests are about testing our error handling, so we can't let the assert interfere
        TDTM_TriggerHandler.suppressDebugAssertAfterErrorLogging = true;

        UTIL_CustomSettingsFacade.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c(
            npe01__Account_Processor__c = CAO_Constants.HH_ACCOUNT_PROCESSOR));
        UTIL_CustomSettingsFacade.getHouseholdsSettingsForTests(new npo02__Households_Settings__c (
            npo02__Household_Rules__c = HH_Households.ALL_PROCESSOR, npo02__Enable_Opp_Rollup_Triggers__c = true));

        User user = UTIL_UnitTestData_TEST.CreateNewUserForTests(System.now().getTime() + '@testerson.com');

        UTIL_CustomSettingsFacade.getErrorSettingsForTests(new Error_Settings__c(
            Error_Notifications_On__c = true,
            Error_Notifications_To__c = user.Id,
            Store_Errors_On__c = true,
            Respect_Duplicate_Rule_Settings__c = true
        ));
    }

    /**
     * @description Trigger error notification processing by calling
     * ERR_Handler.processError() and verify that the error was posted to
     * Chatter.
     */
    @IsTest
    private static void errorsStoredInDbTdtmCustomConfigPostToChatter() {
        setupWithChatterNotifications();

        ERR_Handler.processError(testException, ERR_Handler_API.Context.TDTM);

        List<Error__c> errors = errorGateway.getRecords();

        System.assertEquals(1, errors.size());
        UTIL_Debug.debug('****Errors: ' + JSON.serializePretty(errors));

        //Verify error was posted to chatter group
        if(Schema.SObjectType.User.isFeedEnabled()) {
            List<SObject> chatterPosts = Database.query('SELECT Title FROM FeedItem where ParentId = :chatterGroupId');
            System.assertEquals(1, chatterPosts.size());
            System.assertEquals('Salesforce Error', chatterPosts[0].get('Title'));
            for(Error__c error : errors) {
                System.assertEquals(true, error.Posted_in_Chatter__c);
            }
        }
    }

    /**
     * @description Trigger error notification processing by calling
     * ERR_Handler.processError() and verify that the error was emailed
     */
    @IsTest
    private static void errorsStoredInDbTdtmCustomConfigEmailErrors() {
        setupWithEmailNotifications();

        Test.startTest();

        ERR_Handler.processError(testException, ERR_Handler_API.Context.TDTM);

        Test.stopTest();

        List<Error__c> errors = errorGateway.getRecords();
        System.assertEquals(1, errors.size());

        //Verify error was emailed
        for(Error__c error : errors) {
            System.assertEquals(true, error.Email_Sent__c);
            System.assertEquals(ERR_Handler_API.Context.TDTM.name(), error.Context_Type__c);
        }
    }

    @IsTest
    private static void verifyExceptionErrorIsGeneratedButNotStored() {
        Test.startTest();
        ERR_Handler.Errors errors = ERR_Handler.getErrorsOnly(testException, ERR_Handler_API.Context.TDTM);
        Test.stopTest();

        List<Error__c> errorRecords = errorGateway.getRecords();
        System.assertEquals(0, errorRecords.size(), 'There should be no error in the database');

        for(Error__c error : errors.errorRecords) {
            System.assertEquals(ERR_Handler_API.Context.TDTM.name(), error.Context_Type__c,
                'The error context should be set to the passed in context');
            System.assertEquals(testException.getMessage(), error.Full_Message__c,
            'The error full message should be set to exception message');
        }
    }

    /*******************************************************************************************************
    * @description This is the same test called testErrorRecordCreation in the REL_Relationships_TEST class,
    * but using simple insert instead of Database.insert
    */
    @IsTest
    private static void errorStoredInDatabaseFromInsert() {
        setupWithChatterNotifications();

        Contact contact1 = new Contact(FirstName = 'test', LastName = 'testerson1', Title = 'VP1');
        insert contact1;

        npe4__Relationship__c[] relationships = new npe4__Relationship__c[]{
            new npe4__Relationship__c(npe4__contact__c = contact1.id, npe4__Type__c='TestLookupType') };

        try {
            insert relationships;
        } catch (exception ex) {
            ERR_Handler.processError(ex, ERR_Handler_API.Context.REL);
        }
        // assert an error record was created - Required fields are missing: [npe4__Contact__c]
        // from the reciprocal relationship that gets automatically created.
        System.assertEquals(1, [SELECT count() FROM Error__c]);

        //update relationship - this will create the missing npe4__Contact__c field
        relationships[0].npe4__RelatedContact__c = contact1.id;
        Database.SaveResult[] updateResults = Database.update(relationships, false);
        System.assertNotEquals(null, relationships[0].npe4__Contact__c);

        //get errors
        ERR_Handler.Errors errors = ERR_Handler.getErrors(updateResults, (List<SObject>)relationships);
        //we still get an error, because of the Related_Contact_Do_Not_Change validation rule on Relationship
        System.assertEquals(true, errors.errorsExist);
        System.assertEquals(1, errors.errorRecords.size());

        //assert no additional error record was created on update
        System.assertEquals(1, [SELECT count() FROM Error__c]);
    }

    /*******************************************************************************************************
    * @description Confirms that a simple error is created when invoking processError with a String message
    */
    @IsTest
    private static void shouldStoreSimpleErrorMessage() {
        setupWithChatterNotifications();

        ERR_Handler.processError('Test Message', 'Test Context');

        List<Error__c> errs = errorGateway.getRecords();

        System.assertEquals(1, errs.size(), '1 error should be present');
        System.assertEquals(true, errs[0].Full_Message__c.contains('Test Message'), 'Full Message should contain Test Message, Actual: ' + errs[0].Full_Message__c);
        System.assertEquals('Test Context', errs[0].Context_Type__c, 'Error Context Type');
    }

    /*******************************************************************************************************
    * @description Testing that DML changes are properly rolled back in a controller that adheres to our
    * error-handling design, and that the error is properly stored.
    */
    @IsTest
    private static void controllerWithManualRollback() {
        setupWithChatterNotifications();

        ERR_Handler_CTRL_TEST controller = new ERR_Handler_CTRL_TEST();

        Test.startTest();
        controller.withManualRollback();
        Test.stopTest();

        //assert contact record creation was rolled back
        System.assertEquals(0, [SELECT count() FROM Contact]);

        //assert relationship record was not stored
        System.assertEquals(0, [SELECT count() FROM npe4__Relationship__c]);

        //assert an error record was created - Required fields are missing: [npe4__Contact__c]
        System.assertEquals(1, [SELECT count() FROM Error__c]);
    }

    /*******************************************************************************************************
    * @description Test that error email are still sent to other system admins if the assigned user is not active
    */
    @IsTest
    private static void shouldStillSendEmailsForInactiveUser() {
        String un = System.now().getTime() + '@testerson.com';
        User u = UTIL_UnitTestData_TEST.createNewInactiveUserForTests(un);

        UTIL_CustomSettingsFacade.getErrorSettingsForTests(new Error_Settings__c(
            Error_Notifications_On__c = true,
            Error_Notifications_To__c = u.Id,
            Store_Errors_On__c = true,
            Respect_Duplicate_Rule_Settings__c = true
        ));

        Test.startTest();
        ERR_Handler.processError(testException, ERR_Handler_API.Context.TDTM);
        Test.stopTest();

        List<Error__c> errors = errorGateway.getRecords();
        System.assertEquals(1, errors.size());

        //Verify error was NOT emailed
        for (Error__c error : errors) {
            System.assertEquals(true, error.Email_Sent__c);
            System.assertEquals(ERR_Handler_API.Context.TDTM.name(), error.Context_Type__c);
        }
    }

    /**
     * @description Verifies error notification processing.
     * The error message is not displayed on the NPSP Settings page
     */
    @IsTest
    private static void shouldCreateErrorBySendErrorNotification() {
        Test.setCurrentPage(Page.STG_SettingsManager);

        Test.startTest();
        ERR_Handler.sendErrorNotification(testException, ERROR_CONTEXT);
        Test.stopTest();

        List<Error__c> errors = errorGateway.getRecords();
        System.assertEquals(1, errors.size(), 'An error should be generated: ' + errors);
        System.assertEquals(true, errors[0].Email_Sent__c, 'The error should be emailed');

        List<ApexPages.Message> pageMessages = ApexPages.getMessages();
        System.assertEquals(0, pageMessages.size(), 'Error message should not be displayed on the page: ' + pageMessages);
    }

    /**
     * @description Verifies error notification processing.
     * The error message is not displayed on the NPSP Settings page
     */
    @IsTest
    private static void shouldProcessErrorOnlyButNotDisplayItOnPage() {
        Test.setCurrentPage(Page.STG_SettingsManager);

        List<Error__c> errors = new List<Error__c>{
            ERR_Handler.createError(testException, ERROR_CONTEXT)
        };
        System.assertEquals(false, errors[0].Email_Sent__c, 'The error should not have emailed setting on');

        Test.startTest();
        ERR_Handler.processErrorsOnly(errors, ERROR_CONTEXT);
        Test.stopTest();

        errors = errorGateway.getRecords();
        System.assertEquals(1, errors.size(), 'An error should be generated: ' + errors);
        System.assertEquals(true, errors[0].Email_Sent__c, 'The error should be emailed');

        List<ApexPages.Message> pageMessages = ApexPages.getMessages();
        System.assertEquals(0, pageMessages.size(), 'Error message should not be displayed on the page: ' + pageMessages);
    }

    /**
     * @description Verifies error notification processing.
     * The error message is not displayed on the NPSP Settings page
     */
    @IsTest
    private static void shouldProcessErrorResultButNotDisplayItOnPage() {
        Test.setCurrentPage(Page.STG_SettingsManager);

        ERR_Handler.Errors errorResult = new ERR_Handler.Errors();
        errorResult.errorsExist = true;
        errorResult.errorRecords.add(
            ERR_Handler.createError(testException, ERROR_CONTEXT)
        );

        Test.startTest();
        ERR_Handler.processErrorsOnly(errorResult, ERROR_CONTEXT);
        Test.stopTest();

        List<Error__c> errors = errorGateway.getRecords();
        System.assertEquals(1, errors.size(), 'An error should be generated: ' + errors);
        System.assertEquals(true, errors[0].Email_Sent__c, 'The error should be emailed');

        List<ApexPages.Message> pageMessages = ApexPages.getMessages();
        System.assertEquals(0, pageMessages.size(), 'Error message should not be displayed on the page: ' + pageMessages);
    }

    /**
     * @description Verifies error notification processing.
     * The error message is displayed on the NPSP Settings page
     */
    @IsTest
    private static void shouldProcessErrorAndDisplayItOnPage() {
        Test.setCurrentPage(Page.STG_SettingsManager);

        List<Error__c> errors = new List<Error__c>{
            ERR_Handler.createError(testException, ERROR_CONTEXT)
        };
        System.assertEquals(false, errors[0].Email_Sent__c, 'The error should not have emailed setting on');

        Test.startTest();
        ERR_Handler.processErrors(errors, ERROR_CONTEXT);
        Test.stopTest();

        errors = errorGateway.getRecords();
        System.assertEquals(1, errors.size(), 'An error should be generated: ' + errors);
        System.assertEquals(true, errors[0].Email_Sent__c, 'The error should be emailed');

        List<ApexPages.Message> pageMessages = ApexPages.getMessages();
        System.assertEquals(1, pageMessages.size(), 'Error message should be displayed on the page: ' + pageMessages);
    }


}