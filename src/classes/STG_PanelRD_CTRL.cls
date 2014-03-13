public with sharing class STG_PanelRD_CTRL extends STG_Panel { 

    public override string idPanel() { return 'idPanelRD'; }
 
    //holds value to evaluate change in forecast months
    private integer originalForecastMonths;
    public Schedulable__c rdSched { public get; public set; }
    
    public STG_PanelRD_CTRL() { }
    
    public void init(){
        originalForecastMonths = (integer)STG_Panel.stgService.stgRD.npe03__Opportunity_Forecast_Months__c;        
        list<Schedulable__c> listSch = [select Id, Active__c from Schedulable__c where Class_Name__c = 'RD_RecurringDonations_SCHED' limit 1];
        if (listSch.size() > 0) 
            rdSched = listSch[0];
    }
    
    public override PageReference saveSettings() { 
        STG_SettingsManager_CTRL.idPanelCurrent = idPanel();
        Savepoint sp = Database.setSavepoint();
        try {
        	List<SObject> toUpdate = new List<SObject>();
        	if(STG_Panel.stgService.stgRD != null)
        		toUpdate.add(STG_Panel.stgService.stgRD);
        	if(rdSched != null)
                toUpdate.add(rdSched);
            update toUpdate;
            
            strRDOppRecordTypeLabel = null;

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
            isEditMode = false;
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

    static public string strRDOppRecordTypeLabel {
        get {
            if (strRDOppRecordTypeLabel == null) {
                strRDOppRecordTypeLabel = UTIL_RecordTypes.GetRecordTypeName('Opportunity', STG_Panel.stgService.stgRD.npe03__Record_Type__c);
            }
            return strRDOppRecordTypeLabel;
        }
        private set;
    }
    
}