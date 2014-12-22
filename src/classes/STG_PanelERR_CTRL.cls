/*
    Copyright (c) 2014, Salesforce.com Foundation
    All rights reserved.
    
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
    
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Salesforce.com Foundation nor the names of
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
* @author Salesforce.com Foundation
* @date 2014
* @description Controller for the error notifications settings page.
 */
public with sharing class STG_PanelERR_CTRL extends STG_Panel {
    
    public override String idPanel() { return 'idPanelErrors'; }
    
    public String notificationToDropDown { public get; public set; }
    public String groupId { public get; public set; }
    public String saveErrorMessage { public get; set; }
 
    public STG_PanelERR_CTRL() {
    	notificationToDropDown = STG_SettingsService.stgService.stgErr.Error_Notifications_To__c;
    }
    
    //Displays the values of the drop-down (Edit Mode only)
    public List<SelectOption> listSOERRNotifOptions {
        get {
            if (listSOERRNotifOptions == null) {
                listSOERRNotifOptions = new list<SelectOption>();
                listSOERRNotifOptions.add(new SelectOption('None', 'None'));
                if(Schema.SObjectType.User.isFeedEnabled())
                    listSOERRNotifOptions.add(new SelectOption(ERR_Notifier.NotificationOptions.chatterGroup, 'Chatter Group'));
                listSOERRNotifOptions.add(new SelectOption(ERR_Notifier.NotificationOptions.sysAdmins, 'All Sys Admins'));
                for (User u : [select Name, id from User where User.Profile.Name = 'System Administrator']) {
                    listSOERRNotifOptions.add(new SelectOption(u.id, 'User: ' + u.Name));
                }
            }
            return listSOERRNotifOptions;
        }
        private set;
    }  
    
    //Displays the Error Notification Recipients (View Mode only)
    public String strErrorNotifDisplayName {
        get {
        	String errorNotifRecipient = UTIL_CustomSettingsFacade.getErrorSettings().Error_Notifications_To__c; 
        	
            if (errorNotifRecipient != null) {
                if (errorNotifRecipient.startsWith(ERR_Notifier.NotificationOptions.chatterGroup) && Schema.SObjectType.User.isFeedEnabled()) {
                   strErrorNotifDisplayName = 'Group: ';
                   List<SObject> chatterGroupsNotif = Database.query('select Id, Name from CollaborationGroup where id = :errorNotifRecipient');
                   if(chatterGroupsNotif.size() > 0) 
                       strErrorNotifDisplayName += chatterGroupsNotif[0].get('Name');
                } else if (errorNotifRecipient.startsWith(ERR_Notifier.NotificationOptions.user)) {
                   strErrorNotifDisplayName = 'User: ';
                   List<User> usersNotif = [select Name from User where id = :errorNotifRecipient];
                   if(usersNotif.size() > 0)
                       strErrorNotifDisplayName += usersNotif[0].Name;              
                } else {
                   strErrorNotifDisplayName = errorNotifRecipient;
                }
            } else {
            	strErrorNotifDisplayName = '';
            }
            return strErrorNotifDisplayName;
        }
        private set;
    }  
    
    public override PageReference saveSettings() {
        UTIL_Debug.debug('****notification to drop down: ' + notificationToDropDown);
        UTIL_Debug.debug('****group ID: ' + groupId);
        if(notificationToDropDown == ERR_Notifier.NotificationOptions.chatterGroup && String.isBlank(groupId)) { 
            saveErrorMessage = 'Please enter valid Chatter group name.';
            return null;
        } else if(notificationToDropDown == ERR_Notifier.NotificationOptions.chatterGroup && !String.isBlank(groupId)) { 
           STG_SettingsService.stgService.stgErr.Error_Notifications_To__c = groupId;
           saveErrorMessage = null;
        } else {
           STG_SettingsService.stgService.stgErr.Error_Notifications_To__c = notificationToDropDown;
           saveErrorMessage = null;
        }
        return super.saveSettings();
    }
    
    public override PageReference cancelEdit() {
    	saveErrorMessage = null;
    	return super.cancelEdit();
    }
    
    public override PageReference editSettings() {
    	if((STG_SettingsService.stgService.stgErr.Error_Notifications_To__c).startsWith(ERR_Notifier.NotificationOptions.chatterGroup)) {
    		notificationToDropDown = ERR_Notifier.NotificationOptions.chatterGroup;
    	}
    	
    	return super.editSettings();
    }
}