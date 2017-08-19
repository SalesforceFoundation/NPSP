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
* @description Tests for USER_UserService class.
*/

@isTest
public with sharing class USER_UserService_TEST {
	//================================
	// Constants
	//================================
	public static final String SYSTEM_ADMINISTRATOR = 'System Administrator';
	public static final String OBJECT_TYPE_USER = 'User';
	public static final String ERROR_MESSAGE_SCHEDULED_APEX = 'There are scheduled jobs owned by an inactive or frozen user. Review your scheduled jobs and ensure the owner of each one is an active user.';
	public static final String ERROR_NOTIFICATION_RECIPIENT_ALL_SYS_ADMINS = 'All Sys Admins';
	public static final String CONTEXT_TYPE_USER = 'User';
	public static final String JOB_TYPE_SCHEDULED_APEX = '7';
	

	/*********************************************************************************************************
    * @description Tests if modified Users are System Administrators.
    * @return void
    **********************************************************************************************************/
    private static testMethod void testIsSysAdmin() {
    	List<User> newUsers = createUsers();
        
    	Map<Id, Boolean> userIdToIsSysAdmin = USER_UserService.isSysAdmin(newUsers);
    	
    	System.assertEquals(true, userIdToIsSysAdmin.get(newUsers[0].Id));
        System.assertEquals(true, userIdToIsSysAdmin.get(newUsers[1].Id));
    }


    /*********************************************************************************************************
    * @description Tests the IsActive status for Users.
    * @return void
    **********************************************************************************************************/
    private static testMethod void testIsActiveUser() {
        List<User> newUsers = createUsers();
        
    	Map<Id, Boolean> userIdToIsActive = USER_UserService.isActiveUser(newUsers);

    	System.assertEquals(true, userIdToIsActive.get(newUsers[0].Id));
        System.assertEquals(false, userIdToIsActive.get(newUsers[1].Id));
    }


	/*********************************************************************************************************
    * @description Tests the IsFrozen status for Users.
    * @return void
    **********************************************************************************************************/
    private static testMethod void testIsFrozenUser() {
        List<User> newUsers = createUsers();

        // Freeze a User
        List<UserLogin> currentUserLogin = [SELECT IsFrozen, UserId FROM UserLogin WHERE UserId = :newUsers[1].Id];
		currentUserLogin[0].IsFrozen = true;
		Database.update(currentUserLogin, false);

    	Map<Id, Boolean> userIdToIsFrozen = USER_UserService.isFrozenUser(newUsers);
    	List<Boolean> frozenStatuses = userIdToIsFrozen.values();

    	System.assertEquals(false, userIdToIsFrozen.get(newUsers[0].Id));
    	System.assertEquals(true, userIdToIsFrozen.get(newUsers[1].Id));
    }


	/*********************************************************************************************************
    * @description Tests the handling of IsActive/IsFrozen changes for Users.
    * @return void
    **********************************************************************************************************/
    private static testMethod void testApplySysAdminIsActiveIsFrozenStatusChanges() {
		List<User> newUsers = createUsers();
    	Set<Id> sysAdminIds = new Map<Id, User>(newUsers).keySet();

    	// Create and insert an Error_Settings__c record with an IsFrozen User to update via setErrorNotificationToAllSysAdmins accordingly
    	UTIL_CustomSettingsFacade.getErrorSettingsForTests(new Error_Settings__c(Error_Notifications_On__c = true, 
            Error_Notifications_To__c = newUsers[1].Id, Store_Errors_On__c = true));
    	Error_Settings__c errorSettings = UTIL_CustomSettingsFacade.getErrorSettings();
		Database.insert(errorSettings, true);

    	Test.startTest();
        USER_UserService.applySysAdminIsActiveIsFrozenStatusChanges(sysAdminIds);
        Test.stopTest();

        Error_Settings__c errorSettingsSysAdmin = UTIL_CustomSettingsFacade.getErrorSettings();
        System.assertEquals(ERROR_NOTIFICATION_RECIPIENT_ALL_SYS_ADMINS, errorSettingsSysAdmin.Error_Notifications_To__c);        
	}


	/*********************************************************************************************************
    * @description Tests setting the NPSP Settings Error Notification Recipients to All Sys Admins.
    * @return void
    **********************************************************************************************************/
    private static testMethod void testSetErrorNotificationToAllSysAdmins() {
    	List<User> newUsers = createUsers();
    	Set<Id> sysAdminIds = new Map<Id, User>(newUsers).keySet();

    	// Create and insert an Error_Settings__c record with an IsFrozen User to update via setErrorNotificationToAllSysAdmins accordingly
    	UTIL_CustomSettingsFacade.getErrorSettingsForTests(new Error_Settings__c(Error_Notifications_On__c = true, 
            Error_Notifications_To__c = newUsers[1].Id, Store_Errors_On__c = true));
    	Error_Settings__c errorSettings = UTIL_CustomSettingsFacade.getErrorSettings();
		Database.insert(errorSettings, true);
		
		Test.startTest();
        USER_UserService.setErrorNotificationToAllSysAdmins(sysAdminIds);
        Test.stopTest();

        Error_Settings__c errorSettingsSysAdmin = UTIL_CustomSettingsFacade.getErrorSettings();
        System.assertEquals(ERROR_NOTIFICATION_RECIPIENT_ALL_SYS_ADMINS, errorSettingsSysAdmin.Error_Notifications_To__c);
    }


   	/*********************************************************************************************************
    * @description Tests if User is the owner of Scheduled Jobs and calls the methods that logs an error and sends an email.
    * @return void
    **********************************************************************************************************/
    private static testMethod void testHandleScheduledJobsSubmittedByInActiveIsFrozenSysAdmin() {
    	List<User> newUsers = createUsers();
    	Set<Id> sysAdminIds = new Map<Id, User>(newUsers).keySet();

    	Test.startTest();
    	UTIL_MasterSchedulableHelper.setScheduledJobs();
    	List<CronTrigger> scheduledJobs = [SELECT Id, OwnerId, CronExpression, CronJobDetail.Name, CreatedBy.Name, CreatedBy.IsActive 
    										FROM CronTrigger 
    										WHERE CronJobDetail.JobType = :JOB_TYPE_SCHEDULED_APEX];
		
    	USER_UserService.handleScheduledJobsSubmittedByInActiveIsFrozenSysAdmin(sysAdminIds);
    	Test.stopTest();

    	if(!scheduledJobs.isEmpty()) {
    		System.assertEquals(9, scheduledJobs.size());	
    	}
    }
    

    /*********************************************************************************************************
    * @description Tests logging and Error__c and sending and email to System Administrators.
    * @return void
    **********************************************************************************************************/
    private static testMethod void testNotifySysAdminsAboutInActiveIsFrozenSysAdminUser() {
    	Test.startTest();
        USER_UserService.notifySysAdminsAboutInActiveIsFrozenSysAdminUser();
        Test.stopTest();

        List<Error__c> retrievedErrorTypeAfterEmailSent = [SELECT Email_Sent__c FROM Error__c WHERE Object_Type__c = :OBJECT_TYPE_USER];
        System.assertEquals(true, retrievedErrorTypeAfterEmailSent[0].Email_Sent__c);
    }
   
	
	/*********************************************************************************************************
    * @description Tests logging and Error__c record.
    * @return void
    **********************************************************************************************************/
    private static testMethod void testLogInActiveIsFrozenUserError() {
    	Test.startTest();
        USER_UserService.logInActiveIsFrozenUserError();
        Test.stopTest();

        List<Error__c> retrievedErrorType = [SELECT Full_Message__c FROM Error__c WHERE Object_Type__c = :OBJECT_TYPE_USER];
        System.assertEquals(ERROR_MESSAGE_SCHEDULED_APEX, retrievedErrorType[0].Full_Message__c);
    }


	/*********************************************************************************************************
    * @description Tests the sending of the Scheduled Jobs error email to System Administrators.
    * @return void
    **********************************************************************************************************/
    private static testMethod void testSendInActiveFrozenUserEmail() {
    	Test.startTest();
        USER_UserService.logInActiveIsFrozenUserError();
        
        USER_UserService.sendInActiveIsFrozenUserEmail();
        Test.stopTest();

        List<Error__c> retrievedErrorTypeAfterEmailSent = [SELECT Email_Sent__c FROM Error__c WHERE Object_Type__c = :OBJECT_TYPE_USER];
        System.assertEquals(true, retrievedErrorTypeAfterEmailSent[0].Email_Sent__c);
    }


    /*********************************************************************************************************
    * @description Utility method to create Users with System Administrator profile and sets their IsActive status accordingly.
    * @return List containing the newly created Users.
    **********************************************************************************************************/
    private static List<User> createUsers() {
		List<User> newUsers = new List<User>();

        // Create new Users with SysAdmin Profile
        Id sysAdminId = [SELECT Id FROM Profile WHERE Name = :SYSTEM_ADMINISTRATOR][0].Id;
        User newUserA = new User(LastName = 'TestSysAdminUserA', Email = 'test.sysAdminA@email.com', ProfileId = sysAdminId,
                                    isActive = true, UserName = 'test.sysAdminA@email.com',
                                    Alias = 'tu093521', TimeZoneSidKey = 'America/Los_Angeles',
                                    LocaleSidKey = 'en_US', LanguageLocaleKey = 'en_US',
                                    EmailEncodingKey = 'ISO-8859-1');

        User newUserB = new User(LastName = 'TestSysAdminUserB', Email = 'test.sysAdminB@email.com', ProfileId = sysAdminId,
                                    isActive = false, UserName = 'test.sysAdminB@email.com',
                                    Alias = 'tu093522', TimeZoneSidKey = 'America/Los_Angeles',
                                    LocaleSidKey = 'en_US', LanguageLocaleKey = 'en_US',
                                    EmailEncodingKey = 'ISO-8859-1');

        newUsers.add(newUserA);
        newUsers.add(newUserB);
        insert newUsers;

        return newUsers;
	}


} // end class USER_UserService_TEST