public with sharing class STG_PanelRD_CTRL extends STG_Panel { 

    public override string idPanel() { return 'idPanelRD'; }
 
    //holds value to evaluate change in forecast months
    private integer originalForecastMonths;
    
    public STG_PanelRD_CTRL() {
    	originalForecastMonths = (integer)STG_Panel.stgService.stgRD.npe03__Opportunity_Forecast_Months__c;
    }
    
    public override PageReference saveSettings() { 
        try{
            strErrorEmailDisplayName = null;
            update STG_Panel.stgService.stgRD;

            //if we reduced the number of forecast months, we need to trim opps
            if (originalForecastMonths > STG_Panel.stgService.stgRD.npe03__Opportunity_Forecast_Months__c){
                trimOpportunities();                
            }
            //if we added months, kick off the batch job to update the RDs
            else if (originalForecastMonths < STG_Panel.stgService.stgRD.npe03__Opportunity_Forecast_Months__c){
                STG_PanelRDBatch_CTRL rdbatch = new STG_PanelRDBatch_CTRL();
                rdbatch.runBatch();
            }
            originalForecastMonths = (integer)STG_Panel.stgService.stgRD.npe03__Opportunity_Forecast_Months__c;
        }
        catch (Exception e){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, e.getMessage());
            ApexPages.addMessage(myMsg);                        
        }
    	return null;
    }
    
    private void trimOpportunities(){
        date limitDate = system.today().addMonths((integer)STG_Panel.stgService.stgRD.npe03__Opportunity_Forecast_Months__c);
        string openlabel = system.label.npe03.RecurringDonationOpenStatus;
        delete [select id from Opportunity 
               where CloseDate > :limitDate 
               and isClosed != true 
               and npe03__Recurring_Donation__r.npe03__Open_Ended_Status__c = :openLabel];
    }
        
    public list<SelectOption> listSORDCloseOptions {
        get {
        	if (listSORDCloseOptions == null) {
	            listSORDCloseOptions = new list<SelectOption>();
	            list<RD_RecurringDonations.RecurringDonationCloseOptions> CloseOptionValues = RD_RecurringDonations.RecurringDonationCloseOptions.values();       
	            for (RD_RecurringDonations.RecurringDonationCloseOptions rdco : CloseOptionValues) {
	                listSORDCloseOptions.add(new SelectOption(rdco.name(), rdco.name()));
	            }
        	}
            return listSORDCloseOptions;
        }
        private set;
    }    
    
    public list<SelectOption> listSOErrorEmailOptions {
        get {
        	if (listSOErrorEmailOptions == null) {
	            listSOErrorEmailOptions = new list<SelectOption>();
	            listSOErrorEmailOptions.add(new SelectOption('None', 'None'));
	            listSOErrorEmailOptions.add(new SelectOption('All Sys Admins', 'All Sys Admins'));
	            for (User u : [select Name, id from User where User.Profile.Name = 'System Administrator']) {
	                listSOErrorEmailOptions.add(new SelectOption(u.id, 'User: ' + u.Name));
	            }
	            for (Group g : [select id, Name from Group where Type = 'Regular']) {
	                listSOErrorEmailOptions.add(new SelectOption(g.id, 'Group: ' + g.Name));
	            } 
        	}
            return listSOErrorEmailOptions;
        }
        private set;
    }  
    
    public string strErrorEmailDisplayName {
    	get {
    		if (strErrorEmailDisplayName == null) {
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
	            } else
	               g.Name = strErrorEmail;
	            strErrorEmailDisplayName = g.Name;
    		}
	        return strErrorEmailDisplayName;
        }
        private set;
    }

}