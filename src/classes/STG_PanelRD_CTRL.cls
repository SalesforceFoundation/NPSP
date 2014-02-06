public with sharing class STG_PanelRD_CTRL extends STG_Panel { 

    public override string idPanel() { return 'idPanelRD'; }
 
    //holds value to evaluate change in forecast months
    private integer originalForecastMonths;
    
    public STG_PanelRD_CTRL() {
    	originalForecastMonths = (integer)STG_Panel.stgService.stgRD.npe03__Opportunity_Forecast_Months__c;
    }
    
    public override PageReference saveSettings() { 
        STG_SettingsManager_CTRL.idPanelCurrent = idPanel();
        Savepoint sp = Database.setSavepoint();
        try {
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
        } catch (Exception e) {
            Database.rollback(sp);
            ERR_Handler.processError(e, ERR_Handler.Context.STTG);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
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
    
}