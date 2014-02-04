public with sharing class STG_PanelERR_CTRL extends STG_Panel {
    
    public String emailOption { public get; public set; }
    public String chatterOption { public get; public set; }
    
    public override string idPanel() { return 'idPanelErrors'; }
    
    public Boolean emailUserSelected { public get; public set; }
    public Boolean emailGroupSelected { public get; public set; }
    public Boolean emailUserOrGroupSelected {
    	public get {
    		if(emailUserSelected == null) emailUserSelected = false;
    		if(emailGroupSelected == null) emailGroupSelected = false;
    		return emailUserSelected || emailGroupSelected; 
        }
    }
    
    public Boolean chatterUserSelected { public get; public set; }
    public Boolean chatterGroupSelected { public get; public set; }
    public Boolean chatterUserOrGroupSelected {
        public get {
            if(chatterUserSelected == null) chatterUserSelected = false;
            if(chatterGroupSelected == null) chatterGroupSelected = false;
            return chatterUserSelected || chatterGroupSelected; 
        }
    }
}