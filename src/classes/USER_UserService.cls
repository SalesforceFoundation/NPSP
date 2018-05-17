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
    public static final String OBJECT_ID_PREFIX_USER = '005';
    public static final String ERROR_NOTIFICATION_RECIPIENT_ALL_SYS_ADMINS = 'All Sys Admins';
    public static final String JOB_TYPE_SCHEDULED_APEX = '7';
    public static final String ERROR_TYPE_SCHEDULED_APEX = 'Scheduled Apex Error';
    public static final String OBJECT_TYPE_USER = 'User';


    /*********************************************************************************************************
    * @description Determines if a User in the List is a System Administrator based on ProfileId.
    * @param updatedUsers The User records of the deactivated System Administrators.
    * @return A Map containing the UserId and Boolean value based on the User's ProfileId.
    **********************************************************************************************************/
    public static Map<Id, Boolean> isSysAdmin(List<User> updatedUsers) {
        Map<Id, Boolean> userIdToIsSysAdmin = new Map<Id, Boolean>();

        Map<Id, Profile> sysAdminProfiles = new Map<Id, Profile>([SELECT Id
                , PermissionsCustomizeApplication
                , PermissionsModifyAllData
                , PermissionsAuthorApex
                FROM Profile
                WHERE PermissionsCustomizeApplication = TRUE
                AND PermissionsModifyAllData = TRUE
                AND PermissionsAuthorApex = TRUE]);

        if (updatedUsers != null && !updatedUsers.isEmpty()) {
            for (User currentUser : updatedUsers) {
                userIdToIsSysAdmin.put(currentUser.Id, sysAdminProfiles.containsKey(currentUser.ProfileId) ? true : false);
            }
        }

        return userIdToIsSysAdmin;
    }


    /*********************************************************************************************************
    * @description Determines if a User in the List is active based on IsActive field.
    * @param updatedUsers The User records of the deactivated System Administrators.
    * @return A Map containing the UserId and Boolean value based on the User's IsActive status.
    **********************************************************************************************************/
    public static Map<Id, Boolean> isActiveUser(List<User> updatedUsers) {
        Map<Id, Boolean> userIdToIsActive = new Map<Id, Boolean>();

        if (updatedUsers != null && !updatedUsers.isEmpty()) {
            for (User currentUser : updatedUsers) {
                userIdToIsActive.put(currentUser.Id, currentUser.IsActive);
            }
        }

        return userIdToIsActive;
    }


    /*********************************************************************************************************
    * @description Handles the deactivation of a System Administrator by performing the following tasks:
    *               1) Sets the Error Notification Recipients to 'All Sys Admins' when set to the deactivated
    *                  System Administrator.
    *               2) Logs an Error record and adds it to the Error Log.
    *               3) Sends an email to the org's System Administrators when the deactived
    *                  System Administrator is the owner of Scheduled Jobs.
    * @param sysAdminUserIds The User Ids of the deactivated System Administrators
    * @return void
    **********************************************************************************************************/
    @future
    public static void handleDeactivatedSysAdminFuture(Set<Id> sysAdminUserIds) {
        setErrorNotificationToAllSysAdminsForInActiveSysAdmin(sysAdminUserIds);

        handleScheduledJobsSubmittedByInActiveSysAdmin(sysAdminUserIds);
    }


    /*********************************************************************************************************
    * @description Sets the NPSP Settings Error Notification Recipients to 'All Sys Admins' for Inactive
    *              System Administrator.
    * @param sysAdminUserIds The User Ids of the deactivated System Administrators.
    * @return void
    **********************************************************************************************************/
    public static void setErrorNotificationToAllSysAdminsForInActiveSysAdmin(Set<Id> sysAdminUserIds) {
        Error_Settings__c errorSettings = UTIL_CustomSettingsFacade.getErrorSettings();

        if (errorSettings.Error_Notifications_To__c.startsWith(OBJECT_ID_PREFIX_USER)) {
            for (Id currentSysAdminId: sysAdminUserIds) {
                if (errorSettings.Error_Notifications_To__c == currentSysAdminId) {
                    errorSettings.Error_Notifications_To__c = ERROR_NOTIFICATION_RECIPIENT_ALL_SYS_ADMINS;
                    Database.update(errorSettings, true);
                    break;
                }
            }
        }
    }


    /*********************************************************************************************************
    * @description Determines if an Inactive User is the owner of Scheduled Jobs and notifies the org's
    *              other System Administrators.
    * @param sysAdminUserIds The User Ids of the deactivated System Administrators.
    * @return void
    **********************************************************************************************************/
    public static void handleScheduledJobsSubmittedByInActiveSysAdmin(Set<Id> sysAdminUserIds) {
        List<CronTrigger> scheduledJobs = retrieveScheduledJobs(sysAdminUserIds);

        for (Id currentSysAdminId : sysAdminUserIds) {
            for (CronTrigger eachScheduledJob : scheduledJobs) {
                if (currentSysAdminId == eachScheduledJob.OwnerId) {
                    notifySysAdminsAboutInActiveSysAdminUser();
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
    private static void notifySysAdminsAboutInActiveSysAdminUser() {
        logInActiveSysAdminError();
        sendInActiveSysAdminEmail();
    }


    /*********************************************************************************************************
    * @description Logs an Error__c record for the Inactive System Administrator who owns Scheduled Jobs.
    * @return void
    **********************************************************************************************************/
    @testVisible
    private static void logInActiveSysAdminError() {
        Error__c inActiveError = new Error__c(Error_Type__c = ERROR_TYPE_SCHEDULED_APEX,
                                                Object_Type__c = OBJECT_TYPE_USER,
                                                Datetime__c = System.now(), 
                                                Full_Message__c = Label.InactiveScheduledJobsOwnerErrMsg);

        Database.insert(inActiveError, true);
    }


    /*********************************************************************************************************
    * @description Emails the org's System Administrators for the Inactive System Administrator who owns
    *              Scheduled Jobs.
    * @return void
    **********************************************************************************************************/
    @testVisible
    private static void sendInActiveSysAdminEmail() {
        ERR_Notifier.sendErrorNotifications(ERR_Handler_API.Context.USER.name());
    }


    /*********************************************************************************************************
    * @description Utility method to retrieve the System Adminstrator's ProfileId.
    * @return Id The Id of the System Administrator Profile.
    **********************************************************************************************************/
    private static Id retrieveSysAdminProfileId() {
        List<Id> sysAdminProfileIds = UTIL_Profile.getInstance().getProfileIds(UTIL_Profile.SYSTEM_ADMINISTRATOR);

        return sysAdminProfileIds.isEmpty()
            ? null
            : sysAdminProfileIds[0];
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

    /*********************************************************************************************************
    * @description Return a page reference to the appropriate Salesforce Home Page depending on which UI the
    * current user is in (Classic or LEX).
    * @return Page Reference.
    **********************************************************************************************************/
    public static pageReference getHomePageReference() {
        PageReference ref;
        if (isUserRunningLightning() || isUserRunningMobile()) {
            ref = new PageReference('/one/one.app#/home');
        } else {
            ref = new PageReference('/home/home.jsp');
        }
        ref.setRedirect(true);
        return ref;
    }

    /*********************************************************************************************************
    * @description Returns true if the User is currently running the Lightning Experience UI
    * @return True or False
    **********************************************************************************************************/
    public static Boolean isUserRunningLightning() {
        return (UserInfo.getUiThemeDisplayed() == 'Theme4d');
    }

    /*********************************************************************************************************
    * @description Returns true if the User is currently running the Salesforce1 Mobile UI
    * @return True or False
    **********************************************************************************************************/
    public static Boolean isUserRunningMobile() {
        return (UserInfo.getUiThemeDisplayed() == 'Theme4t');
    }

    /*********************************************************************************************************
    * @description Returns the relative target URL string for a Lightning Experience SObject (including reports)
    * @return Relative URL
    **********************************************************************************************************/
    public static String getLightningBaseURL(String targetId) {
        return '/one/one.app#/sObject/' + targetId + '/view';
    }
}