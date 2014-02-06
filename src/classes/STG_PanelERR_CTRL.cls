public with sharing class STG_PanelERR_CTRL extends STG_Panel {
    
    public override String idPanel() { return 'idPanelErrors'; }
    
    public String notificationOption { public get; public set; }
    
    //Displays the values of the drop-down (Edit Mode only)
    public List<SelectOption> listSOERRNotifOptions {
        get {
            if (listSOERRNotifOptions == null) {
                listSOERRNotifOptions = new list<SelectOption>();
                listSOERRNotifOptions.add(new SelectOption('None', 'None'));
                listSOERRNotifOptions.add(new SelectOption('Chatter Group', 'Chatter Group'));
                listSOERRNotifOptions.add(new SelectOption('All Sys Admins', 'All Sys Admins'));
                for (User u : [select Name, id from User where User.Profile.Name = 'System Administrator']) {
                    listSOERRNotifOptions.add(new SelectOption(u.id, 'User: ' + u.Name));
                }
                /*for (Group g : [select id, Name from Group where Type = 'Regular']) {
                    listSOERRNotifOptions.add(new SelectOption(g.id, 'Group: ' + g.Name));
                }*/ 
            }
            return listSOERRNotifOptions;
        }
        private set;
    }  
    
    //Displays the Error Notification Recipients (View Mode only)
    public String strErrorNotifDisplayName {
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