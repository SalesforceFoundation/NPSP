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
* @description Trigger handler on User object to handle User status changes.
*/

@isTest
public with sharing class USER_FrozenInActiveUser_TDTM_TEST {
    /*********************************************************************************************************
    * @description Tests the handling of the TDTM_Runnable.Action for AfterUpdate
    * @return void
    **********************************************************************************************************/
    private static testMethod void testRunOverrideAfterUpdate() {
        USER_FrozenInActiveUser_TDTM userFrozenInActiveUserTDTM = new USER_FrozenInActiveUser_TDTM();

        List<User> newUsers = USER_UserService_TEST.createUsers();

        // Set the Error Notification Recipient to a User
        Error_Settings__c errorSettings = UTIL_CustomSettingsFacade.getErrorSettings();
        errorSettings.Error_Notifications_To__c = newUsers[0].Id;
        Database.insert(errorSettings, true);

        System.assertEquals(newUsers[0].Id, errorSettings.Error_Notifications_To__c);

        // Freeze a User
        List<UserLogin> currentUserLogin = [SELECT Id, IsFrozen, UserId FROM UserLogin WHERE UserId = :newUsers[0].Id];
        currentUserLogin[0].IsFrozen = true;

        Test.startTest();
        Database.update(currentUserLogin, false);
        Database.update(newUsers[0], true);
        Test.stopTest();

        Error_Settings__c errorSettingsSysAdmin = UTIL_CustomSettingsFacade.getErrorSettings();
        System.assertEquals(USER_UserService.ERROR_NOTIFICATION_RECIPIENT_ALL_SYS_ADMINS, errorSettingsSysAdmin.Error_Notifications_To__c);
    }


} // end class USER_FrozenInActiveUser_TDTM_TEST