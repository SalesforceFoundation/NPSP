public with sharing class STG_PanelHouseholds_CTRL extends STG_Panel {
	
	public STG_PanelHouseholds_CTRL() {
		isRunningBatch = false;
	}
	    
    public override string idPanel() { return 'idPanelHH'; }

    public boolean isRunningBatch { get; set; }

    public PageReference activateHouseholdNaming() {
        isRunningBatch = true; 
                
        STG_Panel.stgService.stgHH.npo02__Advanced_Household_Naming__c = true;
        // DJH:UNDONE is it ok that we save all settings to perform this action?
        saveSettings();
        
        //call advanced rollup batch process
        HH_HouseholdNaming hn = new HH_Householdnaming();
        hn.ActivateAdvancedGreetings(false);
        
        return null;
    }

}