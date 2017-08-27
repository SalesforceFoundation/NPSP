/*
    Copyright (c) 2017, Salesforce.org
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
* @group User
* @description Service Class to handle actions on the User object.
*/
public with sharing class USER_UserService {

	//================================
	// Constants
	//================================
	public static final String SYSTEM_ADMINISTRATOR = 'System Administrator';
	public static final String OBJECT_ID_PREFIX_USER = '005';
	public static final String ERROR_NOTIFICATION_RECIPIENT_ALL_SYS_ADMINS = 'All Sys Admins';
	public static final String JOB_TYPE_SCHEDULED_APEX = '7';
	public static final String ERROR_TYPE_SCHEDULED_APEX = 'Scheduled Apex Error';
	public static final String OBJECT_TYPE_USER = 'User';
	public static final String ERROR_MESSAGE_SCHEDULED_APEX = 'There are scheduled jobs owned by an inactive or frozen user. Review your scheduled jobs and ensure the owner of each one is an active user.';
	

	/*********************************************************************************************************
    * @description Determines if each User in the List is a Sys Admin based on ProfileId.
    * @param updatedUsers The users that were modified.
    * @return A Map containing the UserId and Boolean value based on the User's Profile.
    **********************************************************************************************************/
	public static Map<Id, Boolean> isSysAdmin(List<User> updatedUsers) {
		Map<Id, Boolean> userIdToIsSysAdmin = new Map<Id, Boolean>();
		
		// Retrieve the SysAdmin Profile Id
		Id sysAdminId = retrieveSysAdminProfileId();

		// Determine if the User is a SysAdmin
		if(null != updatedUsers && !updatedUsers.isEmpty()) {
			for(User currentUser : updatedUsers) {
				userIdToIsSysAdmin.put(currentUser.Id, sysAdminId == currentUser.ProfileId);
			}
		}

		return userIdToIsSysAdmin;
	}


	/*********************************************************************************************************
    * @description Determines if each User in the List is active based on IsActive field.
    * @param updatedUsers The users that were modified.
    * @return A Map containing the UserId and Boolean value based on the User's IsActive status.
    **********************************************************************************************************/
	public static Map<Id, Boolean> isActiveUser(List<User> updatedUsers) {
		Map<Id, Boolean> userIdToIsActive = new Map<Id, Boolean>();
		
		// Determine if the User isActive
		if(null != updatedUsers && !updatedUsers.isEmpty()) {
			for(User currentUser : updatedUsers) {
				userIdToIsActive.put(currentUser.Id, currentUser.IsActive);
			}
		}

		return userIdToIsActive;
	}


	/*********************************************************************************************************
    * @description Determines if each User in the List is frozen based on IsFrozen field.
    * @param updatedUsers The user(s) that were modified.
    * @return A Map containing the UserId and Boolean value based on the User's IsFrozen status.
    **********************************************************************************************************/
	public static Map<Id, Boolean> isFrozenUser(List<User> updatedUsers) {
		Map<Id, Boolean> userIdToIsFrozen = new Map<Id, Boolean>();

		// Retrieve the UserLogin records for the updatedUsers
		if(null != updatedUsers && !updatedUsers.isEmpty()) {
			List<UserLogin> currentUserLogins = retrieveUserLogins(updatedUsers);

			// Populate the Map with UserId and IsFrozen
			for(UserLogin eachUserLogin : currentUserLogins) {
				userIdToIsFrozen.put(eachUserLogin.UserId, eachUserLogin.IsFrozen);
			}
		}

		return userIdToIsFrozen;
	}
	

	/*********************************************************************************************************
    * @description Handles User changes to IsActive/IsFrozen status by updating the Error Notification Recipients, logging an Error__c, and notifying the org's System Administrators.
    * @param sysAdminUserIds The User Ids that were modified.
    * @return void
    **********************************************************************************************************/
	@future
	public static void applySysAdminIsActiveIsFrozenStatusChangesFuture(Set<Id> sysAdminUserIds) {
		// Sets Error Notification recipient to All Sys Admin for Inactive/Frozen Users
		setErrorNotificationToAllSysAdminsForInActiveFrozenUsers(sysAdminUserIds);

		// Logs an Error and Emails the Sys Admins
		handleScheduledJobsSubmittedByInActiveIsFrozenSysAdmin(sysAdminUserIds);
	}


	/*********************************************************************************************************
    * @description Sets the NPSP Settings Error Notification Recipients to All Sys Admins for Inactive/Frozen.
    * @param sysAdminUserIds The User Ids that were modified.
    * @return void
    **********************************************************************************************************/
	public static void setErrorNotificationToAllSysAdminsForInActiveFrozenUsers(Set<Id> sysAdminUserIds) {
		Error_Settings__c errorSettings = UTIL_CustomSettingsFacade.getErrorSettings();
		
		if(errorSettings.Error_Notifications_To__c.startsWith(OBJECT_ID_PREFIX_USER)) {
			// Check if one of the sysAdminUserIds is the Error Notification recipient
			for(Id currentSysAdminId: sysAdminUserIds) {
				if(errorSettings.Error_Notifications_To__c == currentSysAdminId) {
					// Set Error Notification recipient to All Sys Admin
					errorSettings.Error_Notifications_To__c = ERROR_NOTIFICATION_RECIPIENT_ALL_SYS_ADMINS;
					Database.update(errorSettings, true);
					break;
				}
			}
		}
	}


	/*********************************************************************************************************
    * @description Determines if an Inactive/Frozen User is the owner of the Scheduled Jobs and emails the org's System Administrators.
    * @param sysAdminUserIds The User Ids that were modified.
    * @return void
    **********************************************************************************************************/
	public static void handleScheduledJobsSubmittedByInActiveIsFrozenSysAdmin(Set<Id> sysAdminUserIds) {
		List<CronTrigger> scheduledJobs = retrieveScheduledJobs(sysAdminUserIds);

		for(Id currentSysAdminId : sysAdminUserIds) {
			for(CronTrigger eachScheduledJob : scheduledJobs) {
				if(currentSysAdminId == eachScheduledJob.OwnerId) {
					notifySysAdminsAboutInActiveIsFrozenSysAdminUser();
					return;
				}
			}
		}
	}


	/*********************************************************************************************************
    * @description Logs an Error__c record and emails the org's System Administrators.
    * @return void
    **********************************************************************************************************/
	@testVisible
	private static void notifySysAdminsAboutInActiveIsFrozenSysAdminUser() {
		logInActiveIsFrozenUserError();
		sendInActiveIsFrozenUserEmail();
	}


	/*********************************************************************************************************
    * @description Logs an Error__c record.
    * @return void
    **********************************************************************************************************/
	@testVisible
	private static void logInActiveIsFrozenUserError() {
		Error__c inActiveIsFrozenError = new Error__c(Error_Type__c = ERROR_TYPE_SCHEDULED_APEX,
														Object_Type__c = OBJECT_TYPE_USER,
														Datetime__c = System.now(), 
														Full_Message__c = Label.InactiveFrozenScheduledJobsOwnerErrMsg);

		Database.insert(inActiveIsFrozenError, true);
	}


	/*********************************************************************************************************
    * @description Emails the org's System Administrators.
    * @return void
    **********************************************************************************************************/
	@testVisible
	private static void sendInActiveIsFrozenUserEmail() {
		ERR_Notifier.sendErrorNotifications(ERR_Handler_API.Context.USER.name());
	}


	/*********************************************************************************************************
    * @description Utility method to retrieve the System Adminstrator's ProfileId.
    * @return Id The Id of the System Administrator Profile.
    **********************************************************************************************************/
	private static Id retrieveSysAdminProfileId() {
		Id sysAdminProfileId = null; 

		List<Profile> sysAdminProfile = [SELECT Id FROM Profile WHERE Name = :SYSTEM_ADMINISTRATOR];
		if(!sysAdminProfile.isEmpty()) {
			sysAdminProfileId = sysAdminProfile[0].Id;
		}
		
		return sysAdminProfileId;
	}
	

	/*********************************************************************************************************
    * @description Retrieves the UserLogin records for Users.
    * @param updatedUsers The users that were modified.
    * @return A List containing the UserLogin records.
    **********************************************************************************************************/
	private static List <UserLogin>retrieveUserLogins(List<User> updatedUsers) {
		List<UserLogin> currentUserLogins = new List<UserLogin>();

		currentUserLogins = [SELECT IsFrozen, UserId FROM UserLogin WHERE UserId IN :updatedUsers];

		return currentUserLogins;
	}


	/*********************************************************************************************************
    * @description Retrieves the Scheduled Jobs that are owned by the Users.
    * @param sysAdminUserIds The User Ids that were modified.
    * @return List of Scheduled Jobs.
    **********************************************************************************************************/
	private static List<CronTrigger> retrieveScheduledJobs(Set<Id> sysAdminUserIds) {
		List<CronTrigger> scheduledJobs = new List<CronTrigger>();

		scheduledJobs = [SELECT Id, OwnerId 
							FROM CronTrigger 
							WHERE OwnerId IN :sysAdminUserIds
							AND CronJobDetail.JobType = :JOB_TYPE_SCHEDULED_APEX];

		return scheduledJobs;
	}


} // end class USER_UserService