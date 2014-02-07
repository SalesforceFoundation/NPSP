public with sharing class STG_PanelERR_CTRL extends STG_Panel {
    
    public override String idPanel() { return 'idPanelErrors'; }
    
    public String notificationToDropDown { public get; public set; }
    public CollaborationGroup notificationToChatter { public get; public set; }
 
    //Displays the values of the drop-down (Edit Mode only)
    public List<SelectOption> listSOERRNotifOptions {
        get {
            if (listSOERRNotifOptions == null) {
                listSOERRNotifOptions = new list<SelectOption>();
                listSOERRNotifOptions.add(new SelectOption('None', 'None'));
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
                if (errorNotifRecipient instanceof id) {
                    if (errorNotifRecipient.startsWith(ERR_Notifier.NotificationOptions.chatterGroup)) {
                       strErrorNotifDisplayName = 'Group: ';
                       strErrorNotifDisplayName += [select Id, Name from CollaborationGroup where id = :errorNotifRecipient].Name;
                    }
                    else if (errorNotifRecipient.startsWith(ERR_Notifier.NotificationOptions.user)) {
                       strErrorNotifDisplayName = 'User: ';
                       strErrorNotifDisplayName += [select Name from User where id = :errorNotifRecipient].Name;
                    }               
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
        System.debug('****notification to chatter: ' + notificationToChatter);
        if(notificationToDropDown == 'Chatter Group' && notificationToChatter != null) { 
           STG_SettingsService.stgService.stgErr.Error_Notifications_To__c = notificationToChatter.Id;
        } else {
           STG_SettingsService.stgService.stgErr.Error_Notifications_To__c = notificationToDropDown;
        }
        return super.saveSettings();
    }
}