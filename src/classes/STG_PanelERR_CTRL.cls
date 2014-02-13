public with sharing class STG_PanelERR_CTRL extends STG_Panel {
    
    public override String idPanel() { return 'idPanelErrors'; }
    
    public String notificationToDropDown { public get; public set; }
    public String groupId { public get; public set; }
 
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
        	String errorNotifRecipient = Error_Settings__c.getOrgDefaults().Error_Notifications_To__c; 
        	
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
        System.debug('****notification to drop down: ' + notificationToDropDown);
        System.debug('****group ID: ' + groupId);
        if(notificationToDropDown == ERR_Notifier.NotificationOptions.chatterGroup && groupId != null) { 
           STG_SettingsService.stgService.stgErr.Error_Notifications_To__c = groupId;
        } else {
           STG_SettingsService.stgService.stgErr.Error_Notifications_To__c = notificationToDropDown;
        }
        return super.saveSettings();
    }
}