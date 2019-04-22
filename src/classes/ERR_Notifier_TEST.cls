/*
    Copyright (c) 2017 Salesforce.org
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
* @date 2017
* @group ErrorHandling
* @description Unit tests for ERR_Notifier class
*/
@isTest
private class ERR_Notifier_TEST {

    /**********************************************************************************************
    * @description Test retrieval of System Administrator Users' Emails
    * verify: Emails of System Administrator Users are retrieved
    */
    @IsTest
    private static void shouldMatchSystemAdminEmailList() {
        Test.startTest();
        ERR_Notifier notifierService = new ERR_Notifier();
        Set<String> recipientEmails = new Set<String>(notifierService.getSystemAdminEmails());
        Test.stopTest();

        Set<String> expectedEmails = getSystemAdminEmails();

        System.assertEquals(expectedEmails.size(), recipientEmails.size(), 'Number of emails should match');
        System.assert(expectedEmails.containsAll(recipientEmails), 'Expected and retrieved emails should be the same');
    }

    /**********************************************************************************************
    * @description Confirm that the method to retrieve Error log record pending notification
    * only retrieve records created in the last 48 hours.
    */
    @IsTest
    private static void shouldOnlyRetrieveRecentErrorLogEntries() {

        ERR_Notifier.MAX_AGE_FOR_ERRORS = Datetime.now().addDays(-3);
        ERR_Notifier.MAX_RECORDS = 10;

        List<Error__c> errors = new List<Error__c>();
        // The oldest error will be 80 days old
        Datetime dt = Datetime.now().addDays(80).addHours(-1);
        // Create one error per day for up to 100 total records.
        for (Integer n = 0; n < 100; n++) {
            errors.add(createError(dt));
            dt = dt.addDays(1);
        }
        insert errors;

        Test.startTest();
        ERR_Notifier notifierService = new ERR_Notifier();
        errors = notifierService.getErrorsPendingNotification();
        Test.stopTest();

        System.assertEquals(ERR_Notifier.MAX_RECORDS, errors.size(), 'There should only be ten errors returned.');

        for (Error__c err : errors) {
            System.assert(err.Datetime__c >= ERR_Notifier.MAX_AGE_FOR_ERRORS,
                'All returned errors should be newer than one day');
        }
    }

    /**********************************************************************************************
    * @description Confirm that send error notification process retrieves all errors created
    * that meet the criteria and sends an email for them.
    */
    @IsTest
    private static void shouldSendEmailsToCurrentUser() {
        UTIL_CustomSettingsFacade.getErrorSettingsForTests(new Error_Settings__c(
                Error_Notifications_On__c = True,
                Error_Notifications_To__c = UserInfo.getUserId()
        ));

        List<Error__c> errors = new List<Error__c>();
        for (Integer n = 0; n < 100; n++) {
            errors.add(createError(Datetime.now()));
        }
        insert errors;

        Test.startTest();
        ERR_Notifier.sendErrorNotifications(null);
        Test.stopTest();

        ERR_Notifier notifierService = new ERR_Notifier();
        for (Error__c err : notifierService.getErrorsPendingNotification()) {
            System.assert(err.Email_Sent__c,
                    'All emails pending notification should be marked as having an email sent');
        }
    }

    /**********************************************************************************************
    * @description Verify that if the specified Error Notification User is inactive (or doesn't exist), that the
    * returned list of email recipients consists of all System Admin users
    */
    @IsTest
    private static void shouldReturnAllSystemAdminsEmailsIfErrorUserIsInactive() {
        // Create a System Admin User
        User tempUser = UTIL_UnitTestData_TEST.createUserWithoutInsert(UTIL_Profile.SYSTEM_ADMINISTRATOR);
        tempUser.IsActive = true;
        insert tempUser;

        Id fakeUserId = UTIL_UnitTestData_TEST.mockId(User.SObjectType);
        Error_Settings__c errorSettings = UTIL_CustomSettingsFacade.getErrorSettingsForTests(
            new Error_Settings__c(
                Error_Notifications_On__c = True,
                Error_Notifications_To__c = fakeUserId
            )
        );
        String errorNotifRecipient = errorSettings.Error_Notifications_To__c;

        Set<String> expectedEmails = getSystemAdminEmails();

        Test.startTest();
        ERR_Notifier notifierService = new ERR_Notifier();
        List<String> errorRecipients = notifierService.getErrorEmailRecipients(errorNotifRecipient);
        Test.stopTest();

        System.assert(errorRecipients.size() > 1, 'There should be more than one System Admin user listed');
        System.assert(expectedEmails.containsAll(errorRecipients), 'All System Admins should be set as recipients');
    }

    /**********************************************************************************************
    * @description Verify that if the specified Error Notification User is inactive (or doesn't exist), that the
    * generated email includes a note about it.
    */
    @IsTest
    private static void shouldIncludeNoteAboutInactiveNotificationUserInEmail() {
        Id fakeUserId = UTIL_UnitTestData_TEST.mockId(User.SObjectType);
        Error_Settings__c errorSettings = UTIL_CustomSettingsFacade.getErrorSettingsForTests(
            new Error_Settings__c(
                Error_Notifications_On__c = True,
                Error_Notifications_To__c = fakeUserId
            )
        );
        String errorNotifRecipient = errorSettings.Error_Notifications_To__c;

        Test.startTest();
        ERR_Notifier notifierService = new ERR_Notifier();
        List<String> errorRecipients = notifierService.getErrorEmailRecipients(errorNotifRecipient);
        Messaging.SingleEmailMessage emailMessage = notifierService.createEmailMessage(null, new List<Error__c>(), errorRecipients);
        Test.stopTest();

        System.assert(emailMessage.getPlainTextBody().containsIgnoreCase('not an active user'));
        System.assert(emailMessage.getPlainTextBody().containsIgnoreCase(errorNotifRecipient));
    }

    /**********************************************************************************************
    * @description Confirm that send error notification process retrieves all errors created
    * that meet the criteria and sends an email for them.
    */
    @IsTest
    private static void shouldPostEmailsToChatter() {

        if (!Schema.SObjectType.User.isFeedEnabled()) {
            return;
        }

        SObject chatterGroup = (SObject)System.Type.forName('CollaborationGroup').newInstance();
        chatterGroup.put('Name', 'ChatterTestGroup');
        chatterGroup.put('CollaborationType', 'Private');
        insert chatterGroup;

        UTIL_CustomSettingsFacade.getErrorSettingsForTests(new Error_Settings__c(
            Error_Notifications_On__c = True,
            Error_Notifications_To__c = chatterGroup.Id
        ));

        List<Error__c> errors = new List<Error__c>();
        for (Integer n = 0; n < 100; n++) {
            errors.add(createError(Datetime.now()));
        }
        insert errors;

        Test.startTest();
        ERR_Notifier.sendErrorNotifications(null);
        Test.stopTest();

        ERR_Notifier notifierService = new ERR_Notifier();
        for (Error__c err : notifierService.getErrorsPendingNotification()) {
            System.assert(err.Posted_in_Chatter__c,
                    'All emails pending notification should be marked as being posted to chatter');
        }
    }

    // Helpers
    ////////////

    /**********************************************************************************************
    * @description Get System Administrator User emails
    * @return Set<String> Emails
    */
    private static Set<String> getSystemAdminEmails() {
        Set<String> result = new Set<String>();

        for(User usr : [
                SELECT Email
                FROM User
                WHERE Profile.Name = :UTIL_Profile.SYSTEM_ADMINISTRATOR
                AND IsActive = TRUE
        ]) {
            result.add(usr.Email);
        }

        return result;
    }

    /**********************************************************************************************
    * @description Create an instance of an Error__c record
    * @return Error__c instance
    */
    private static Error__c createError(Datetime dt) {
        return new Error__c(
            Error_Type__c = 'TEST',
            Datetime__c = dt,
            Full_Message__c = 'TEST',
            Context_Type__c = 'TEST',
            Stack_Trace__c = 'TEST',
            Posted_in_Chatter__c = False,
            Email_Sent__c = False
        );
    }
}