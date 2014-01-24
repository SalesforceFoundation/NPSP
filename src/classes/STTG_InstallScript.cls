global class STTG_InstallScript implements InstallHandler {

    Map<String, String> npspToCumulusMap;
    
    public STTG_InstallScript() {
        npspToCumulusMap = TDTM_DefaultConfig.getNpspToCumulusMap();
    }
    
    
    global void onInstall(InstallContext context) {
    	
    	//First install of Cumulus
    	if(context.previousVersion() == null) {
    		//NPSP is a requirement to install Cumulus, so we don't need to check if it's installed
    		
    		//Map the old settings to the new TDTM default setup

    	    //Read existing NPSP trigger configuration
    	    Map<String, Boolean> existingTriggerConfig = getExistingNpspTriggerConfig();
    			
    		//Setup the new configuration
    		setupTdtmConfig(existingTriggerConfig);
    		
    	}
    }
    
    private Map<String, Boolean> getExistingNpspTriggerConfig() {
    	Map<String, Boolean> npspExistingSettings = new Map<String, Boolean>();
    	
    	List<Object> allExistingSettings = new List<SObject>();
    	allExistingSettings.add(npe01__Contacts_and_Orgs_Settings__c.getOrgDefaults());
    	allExistingSettings.add(npo02__Households_Settings__c.getOrgDefaults());
    	allExistingSettings.add(npe03__Recurring_Donations_Settings__c.getOrgDefaults());
    	allExistingSettings.add(npe4__Relationship_Settings__c.getOrgDefaults());
    	allExistingSettings.add(npe5__Affiliations_Settings__c.getOrgDefaults());
    	
    	for(String setting : npspToCumulusMap.keySet()) {
    		
    	}
    	
    	return npspExistingSettings;
    }
    
    private void setupTdtmConfig(Map<String, Boolean> existingTriggerConfig) {
    	
    }
}