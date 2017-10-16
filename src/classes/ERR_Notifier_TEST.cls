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
* @description Unit tests for UTIL_Profile class
*/
@isTest
private class ERR_Notifier_TEST {
	
	/**************************************************************************************************************************
    @description Test sending emails to all System Administrator Users
    verify: The number emails list from ERR_Notifier is correct
    ***************************************************************************************************************************/   
    private static testMethod void testSetErrorNotificationToAllSysAdmins() {
        UTIL_CustomSettingsFacade.getErrorSettingsForTests(new Error_Settings__c(
    		Error_Notifications_On__c = true, 
        	Error_Notifications_To__c = ERR_Notifier.notificationOptions.sysAdmins, 
        	Store_Errors_On__c = true
        ));
        Error_Settings__c errorSettings = UTIL_CustomSettingsFacade.getErrorSettings();
        Database.insert(errorSettings, true);

        Test.startTest();
        ERR_Notifier.sendErrorNotifications('');
        Test.stopTest();

        System.assert(ERR_Notifier.emailNotificationRecipients != null, 'The Email List should not be null');

        Set<String> expectedSystemAdminEmails = getSystemAdminEmails();
        System.assertEquals(expectedSystemAdminEmails.size(), ERR_Notifier.emailNotificationRecipients.size());
        for (String sysAdminEmail : ERR_Notifier.emailNotificationRecipients) {
            System.assert(expectedSystemAdminEmails.contains(sysAdminEmail));
        }
    }

    /*********************************************************************************************************
    * @description Get a List of All emails from Users
    * @return Set of Emails
    */
    private static Set<String> getSystemAdminEmails() {
        Set<String> result = new Set<String>();
        for(User currentUser : [
                SELECT Email
                FROM User
                WHERE Profile.Name = 'System Administrator'
                AND IsActive = TRUE
        ]) {
            result.add(currentUser.Email);
        }
        return result;
    }
}