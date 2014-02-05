public with sharing class STG_PanelERR_CTRL extends STG_Panel {
    
    public override string idPanel() { return 'idPanelErrors'; }
    
    public String notificationOption { public get; public set; }
        
    public Boolean chatterGroupSelected { public get; public set; }
    
    /*
    static public list<SelectOption> listSOERRNotifOptions {
        get {
            if (listSOERRNotifOptions == null) {
                listSOERRNotifOptions = new list<SelectOption>();
                listSOERRNotifOptions.add(new SelectOption('', ''));
                listSOERRNotifOptions.add(new SelectOption(ERR_Notifier.notificationOptions.user, 'User'));
                listSOERRNotifOptions.add(new SelectOption(ERR_Notifier.notificationOptions.sysAdmins, ERR_Notifier.notificationOptions.sysAdmins));
                listSOERRNotifOptions.add(new SelectOption(ERR_Notifier.notificationOptions.userGroup, 'User Group'));
            }
            return listSOERRNotifOptions;
        }
        private set;
    }*/
    
    public list<SelectOption> listSOERRNotifOptions {
        get {
            if (listSOERRNotifOptions == null) {
                listSOERRNotifOptions = new list<SelectOption>();
                listSOERRNotifOptions.add(new SelectOption('None', 'None'));
                listSOERRNotifOptions.add(new SelectOption('All Sys Admins', 'All Sys Admins'));
                for (User u : [select Name, id from User where User.Profile.Name = 'System Administrator']) {
                    listSOERRNotifOptions.add(new SelectOption(u.id, 'User: ' + u.Name));
                }
                for (Group g : [select id, Name from Group where Type = 'Regular']) {
                    listSOERRNotifOptions.add(new SelectOption(g.id, 'Group: ' + g.Name));
                } 
            }
            return listSOERRNotifOptions;
        }
        private set;
    }  
    
    public string strErrorNotifDisplayName {
        get {
            if (strErrorNotifDisplayName == null) {
                Group g = new Group();
                string strErrorEmail = STG_SettingsService.stgService.stgRD.npe03__Error_Email_Notifications__c;          
                if (strErrorEmail instanceof id) {
                    if (strErrorEmail.startsWith('00G')) {
                        g.Name = 'Group: ';
                        g.Name += [select Name from Group where id = :strErrorEmail].Name;                   
                    }
                    else if (strErrorEmail.startsWith('005')) {
                        g.Name = 'User: ';
                        g.Name += [select Name from User where id = :strErrorEmail].Name;
                    }               
                } else {
                   g.Name = strErrorEmail;
                }
                strErrorNotifDisplayName = g.Name;
            }
            return strErrorNotifDisplayName;
        }
        private set;
    }
    
}