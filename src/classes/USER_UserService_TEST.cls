/*
    Copyright (c) 2011, Salesforce.org
    All rights reserved.
    
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
    
    * Redistributions of source code must retain the above copyright
      notice, this List of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this List of conditions and the following disclaimer in the
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
* @group User
* @description Test class for the USER_UserService class.
*/

@isTest
public with sharing class USER_UserService_TEST {
    /*********************************************************************************************************
    * @description Tests if Users are System Administrators.
    * @return void
    **********************************************************************************************************/
    @isTest
    private static void testIsSysAdmin() {
        List<User> newUsers = createUsers();

        Map<Id, Boolean> userIdToIsSysAdmin = USER_UserService.isSysAdmin(newUsers);

        System.assertEquals(true, userIdToIsSysAdmin.get(newUsers[0].Id));
        System.assertEquals(true, userIdToIsSysAdmin.get(newUsers[1].Id));
    }


    /*********************************************************************************************************
    * @description Tests the IsActive status for Users.
    * @return void
    **********************************************************************************************************/
    @isTest
    private static void testIsActiveUser() {
        List<User> newUsers = createUsers();

        Map<Id, Boolean> userIdToIsActive = USER_UserService.isActiveUser(newUsers);

        System.assertEquals(true, userIdToIsActive.get(newUsers[0].Id));
        System.assertEquals(false, userIdToIsActive.get(newUsers[1].Id));
    }


    /*********************************************************************************************************
    * @description Tests the handling of deactivated System Administrators.
    * @return void
    **********************************************************************************************************/
    @isTest
    private static void testDeactivatedSysAdminHandling() {
        List<User> newUsers = createUsers();
        Set<Id> sysAdminIds = new Map<Id, User>(newUsers).keySet();

        UTIL_CustomSettingsFacade.getErrorSettingsForTests(new Error_Settings__c(Error_Notifications_On__c = true, 
            Error_Notifications_To__c = newUsers[1].Id, Store_Errors_On__c = true));
        Error_Settings__c errorSettings = UTIL_CustomSettingsFacade.getErrorSettings();
        Database.insert(errorSettings, true);

        Test.startTest();
        USER_UserService.handleDeactivatedSysAdminFuture(sysAdminIds);
        Test.stopTest();

        Error_Settings__c errorSettingsSysAdmin = UTIL_CustomSettingsFacade.getErrorSettings();
        System.assertEquals(ERR_Notifier.ERROR_NOTIFICATION_RECIPIENT_ALL_SYS_ADMINS, errorSettingsSysAdmin.Error_Notifications_To__c);
    }


    /*********************************************************************************************************
    * @description Tests setting the NPSP Settings Error Notification Recipients to 'All Sys Admins'.
    * @return void
    **********************************************************************************************************/
    @isTest
    private static void testSetErrorNotificationToAllSysAdmins() {
        List<User> newUsers = createUsers();
        Set<Id> sysAdminIds = new Map<Id, User>(newUsers).keySet();

        UTIL_CustomSettingsFacade.getErrorSettingsForTests(new Error_Settings__c(Error_Notifications_On__c = true, 
            Error_Notifications_To__c = newUsers[1].Id, Store_Errors_On__c = true));
        Error_Settings__c errorSettings = UTIL_CustomSettingsFacade.getErrorSettings();
        Database.insert(errorSettings, true);

        Test.startTest();
        USER_UserService.setErrorNotificationToAllSysAdminsForInActiveSysAdmin(sysAdminIds);
        Test.stopTest();

        Error_Settings__c errorSettingsSysAdmin = UTIL_CustomSettingsFacade.getErrorSettings();
        System.assertEquals(ERR_Notifier.ERROR_NOTIFICATION_RECIPIENT_ALL_SYS_ADMINS, errorSettingsSysAdmin.Error_Notifications_To__c);
    }


    /*********************************************************************************************************
    * @description Tests if System Administrator is the owner of Scheduled Jobs and calls the methods that
    *              log an error and send an email.
    * @return void
    **********************************************************************************************************/
    @isTest
    private static void testHandleScheduledJobsSubmittedByInActiveSysAdmin() {
        List<User> newUsers = createUsers();
        Set<Id> sysAdminIds = new Map<Id, User>(newUsers).keySet();

        List<CronTrigger> jobs = [SELECT Id FROM CronTrigger];
        for (CronTrigger eachJob : jobs) {
            System.abortJob(eachJob.Id);
        }

        System.runAs(newUsers[0]) {
            UTIL_MasterSchedulableHelper.setScheduledJobs();
        }

        List<CronTrigger> scheduledJobs = [
            SELECT Id, OwnerId, CronExpression, CronJobDetail.Name, CreatedBy.Name, CreatedBy.IsActive 
            FROM CronTrigger
            WHERE CronJobDetail.JobType = :USER_UserService.JOB_TYPE_SCHEDULED_APEX];

        Test.startTest();
        USER_UserService.handleScheduledJobsSubmittedByInActiveSysAdmin(sysAdminIds);
        Test.stopTest();

        List<Error__c> retrievedErrorAfterEmailSent = getErrors();
        System.assertNotEquals(null, retrievedErrorAfterEmailSent);
        System.assertEquals(true, retrievedErrorAfterEmailSent[0].Email_Sent__c);
    }


    /*********************************************************************************************************
    * @description Tests logging and Error__c and sending an email to the org's System Administrators.
    * @return void
    **********************************************************************************************************/
    @isTest
    private static void testNotifyingSysAdminsAboutInActiveSysAdminUser() {
        Test.startTest();
        USER_UserService.notifySysAdminsAboutInActiveSysAdminUser();
        Test.stopTest();

        List<Error__c> retrievedErrorAfterEmailSent = getErrors();
        System.assertEquals(Label.InactiveScheduledJobsOwnerErrMsg, retrievedErrorAfterEmailSent[0].Full_Message__c);
        System.assertEquals(true, retrievedErrorAfterEmailSent[0].Email_Sent__c);
    }


    /*********************************************************************************************************
    * @description Tests logging and Error__c record.
    * @return void
    **********************************************************************************************************/
    @isTest
    private static void testLoggingInActiveSysAdminError() {
        Test.startTest();
        USER_UserService.logInActiveSysAdminError();
        Test.stopTest();

        List<Error__c> retrievedError = getErrors();
        System.assertEquals(Label.InactiveScheduledJobsOwnerErrMsg, retrievedError[0].Full_Message__c);
    }


    /*********************************************************************************************************
    * @description Tests the sending of the Scheduled Jobs error email to System Administrators.
    * @return void
    **********************************************************************************************************/
    @isTest
    private static void testSendingInActiveSysAdminEmail() {
        Test.startTest();
        USER_UserService.logInActiveSysAdminError();

        USER_UserService.sendInActiveSysAdminEmail();
        Test.stopTest();

        List<Error__c> retrievedErrorAfterEmailSent = getErrors();
        System.assertEquals(true, retrievedErrorAfterEmailSent[0].Email_Sent__c);
    }


    /*********************************************************************************************************
    * @description Utility method to create Users with System Administrator profile and sets their
    *              IsActive status accordingly.
    * @return List containing the newly created Users.
    **********************************************************************************************************/
    public static List<User> createUsers() {
        List<User> newUsers = new List<User>();

        // Create new Users with SysAdmin Profile
        newUsers.add(UTIL_UnitTestData_TEST.createUserWithoutInsert(UTIL_Profile.SYSTEM_ADMINISTRATOR));
        newUsers[0].IsActive = true;
        newUsers.add(UTIL_UnitTestData_TEST.createUserWithoutInsert(UTIL_Profile.SYSTEM_ADMINISTRATOR));
        newUsers[1].IsActive = false;

        insert newUsers;

        return newUsers;
    }

    /*********************************************************************************************************
    * @description Tests lightning experience methods
    * @return void
    **********************************************************************************************************/
    @isTest
    private static void testLEX() {

        if (USER_UserService.isUserRunningLightning()) {
            System.assertEquals(true, USER_UserService.isUserRunningLightning());
        }
        System.assertEquals(false, USER_UserService.isUserRunningMobile());
        System.assertNotEquals(null, USER_UserService.getLightningBaseURL('Test'));
    }

    /*******************************************************************************************************
    * @description Verify system admin has the Customize Application flag set
    */
    @isTest
    private static void isCustomizeApplicationUserReturnsTrueForSystemAdmin() {
        User sysAdmin = UTIL_UnitTestData_TEST.createUser(UTIL_Profile.SYSTEM_ADMINISTRATOR);

        System.runAs(sysAdmin) {
            System.assertEquals(true, USER_UserService.isCustomizeApplicationUser());
        }
    }

    /*******************************************************************************************************
    * @description Verify isCustomizeApplicationUser() returns false for a read-only user 
    * not having Customize Application flag set.
    */
    @isTest
    private static void isCustomizeApplicationUserReturnsFalseWhenReadOnlyUserDoesNotHaveCustomizeAppPermissionSet() {
        User readOnlyUser = UTIL_UnitTestData_TEST.createUser(UTIL_UnitTestData_TEST.PROFILE_READONLY_USER);

        System.runAs(readOnlyUser) {
            System.assertEquals(false, USER_UserService.isCustomizeApplicationUser());
        }
    }

    /*******************************************************************************************************
    * @description Verify isCustomizeApplicationUser() returns true for a read-only user 
    * having Permission Set with the Customize Application flag set.
    */
    @isTest
    private static void isCustomizeApplicationUserReturnsTrueWhenReadOnlyUserHasCustomizeAppPermissionSet() {
        User readOnlyUser = UTIL_UnitTestData_TEST.createUser(UTIL_UnitTestData_TEST.PROFILE_READONLY_USER);
        SYstem.assertNotEquals(null, readOnlyUser.Id);

        assignCustomizeApplicationPermissionSet(readOnlyUser.Id);

        System.runAs(readOnlyUser) {
            System.assertEquals(true, USER_UserService.isCustomizeApplicationUser());
        }
    }

    // Helpers
    //////////////

    /*******************************************************************************************************
    * @description Returns errors
    * @return List<Error__c>
    */
    private static List<Error__c> getErrors() {
        return [
            SELECT Full_Message__c, Email_Sent__c 
            FROM Error__c 
            WHERE Object_Type__c = :USER_UserService.OBJECT_TYPE_USER];
    }

    /*******************************************************************************************************
    * @description Creates and assigns the permission set with Customize Application flag set
    */
    private static void assignCustomizeApplicationPermissionSet(Id userId) {
        final String translationPerm = 'PermissionsManageTranslation';

        // Create a permission set with CustomizeApplication set ensuring other flags
        // on which CustomizeApplication settings depends are set as well
        PermissionSet permission = new PermissionSet(
            Name = 'PermissionTest',
            Label = 'PermissionTest',
            PermissionsManageCustomPermissions = true,
            PermissionsViewRoles = true,
            PermissionsViewSetup = true,
            PermissionsCustomizeApplication = true
        );

        // Dynamically adding translation permission to avoid dependencies. Previously our package failed to deploy
        // to an org without translations enabled, since the field did not exist.
        if (PermissionSet.getSObjectType().getDescribe().fields.getMap().containsKey(translationPerm)) {
            permission.put(translationPerm, true);
        }

        insert permission;

        insert new PermissionSetAssignment(
            AssigneeId = userId,
            PermissionSetId = permission.Id
        );
    }
}