public with sharing class STG_PanelERR_CTRL extends STG_Panel {
    
    public enum EmailOptions {USER, SYSADMIN, USERGROUP}
    
    public EmailOptions emailOption { public get; public set; }
    
    public override string idPanel() { return 'idPanelErrors'; }
    
    public Boolean userSelected { public get; set; }
    
    public Boolean groupSelected { public get; set; }
    
    public Boolean userOrGroupSelected {
    	public get {
    		if(userSelected == null) userSelected = false;
    		if(groupSElected == null) groupSelected = false;
    		return userSelected || groupSelected; 
        }
    }
    
    public STG_PanelERR_CTRL() {
        if(ERR_Notifier.getOrgSettings().Email_List__c.startsWith(ERR_Notifier.NotificationOptions.user)) {
            emailOption = EmailOptions.USER;
            userSelected = true;
        } else if(ERR_Notifier.getOrgSettings().Email_List__c.startsWith(ERR_Notifier.NotificationOptions.usergroup)) {
            emailOption = EmailOptions.USERGROUP;
            groupSelected = true;
        } else if(ERR_Notifier.getOrgSettings().Email_List__c == ERR_Notifier.NotificationOptions.sysAdmins) {
            emailOption = EmailOptions.USERGROUP;
        }
    }
}