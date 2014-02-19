global class STTG_InstallScript implements InstallHandler {

    global void onInstall(InstallContext context) {
        //First install of Cumulus. NPSP is a requirement to install Cumulus, so we don't need to check if it's installed
        if(context.previousVersion() == null) {
            System.debug('****First install');
            runNewOrgScript();
        }
    }

    global void runNewOrgScript(){
        //provides a global callable method for running the default install script to setup TDTM in new orgs

        //Get the mapping from old settings to the new TDTM default setup
        Map<String, String> npspToCumulusMap = TDTM_DefaultConfig.getNpspToCumulusMap();           
        //Read existing NPSP trigger configuration and turn off NPSP flags (so no work needs to be done next time) 
        Map<String, Boolean> existingTriggerConfig = getExistingNpspTriggerConfig(npspToCumulusMap);        
        //Setup the new configuration
        setupTdtmConfig(npspToCumulusMap, existingTriggerConfig);
        
        //set default settings
        
        
        //schedule cron jobs
        UTIL_JobScheduler.scheduleJobIfNotScheduled('Recurring Donation Updates', '17 11 3 * * ?', 'RD_RecurringDonations_SCHED');
        UTIL_JobScheduler.scheduleJobIfNotScheduled('Opportunity Rollups', '0 15 23 * * ?', 'RLLP_OppRollup_SCHED');
    }

    private Map<String, Boolean> getExistingNpspTriggerConfig(Map<String, String> npspToCumulusMap) {
    	
    	Map<String, Boolean> npspExistingSettings = new Map<String, Boolean>();
    	
    	npe01__Contacts_and_Orgs_Settings__c npe01Settings = npe01__Contacts_and_Orgs_Settings__c.getOrgDefaults();
    	npo02__Households_Settings__c npo02Settings = npo02__Households_Settings__c.getOrgDefaults();
    	npe03__Recurring_Donations_Settings__c npe03Settings = npe03__Recurring_Donations_Settings__c.getOrgDefaults();
    	npe4__Relationship_Settings__c npe04Settings = npe4__Relationship_Settings__c.getOrgDefaults();
    	npe5__Affiliations_Settings__c npe05Settings = npe5__Affiliations_Settings__c.getOrgDefaults();
    	
    	for(String setting : npspToCumulusMap.keySet()) {
    		if(setting.startsWith('npe01')) {
	    		if(npe01Settings.Id != null && npe01Settings.get(setting) != null) {
	    			npspExistingSettings.put(setting, (Boolean)npe01Settings.get(setting));	    			
	    			npe01Settings.put(setting, false); //Deactivating flag
	    			continue;
	    		}
    		} else if(setting.startsWith('npo02')) {
    			if(npo02Settings.Id != null && npo02Settings.get(setting) != null) {
                    npspExistingSettings.put(setting, (Boolean)npo02Settings.get(setting));            
                    npo02Settings.put(setting, false); //Deactivating flag
                    continue;
                }
    		} else if(setting.startsWith('npe03')) {
    			if(npe03Settings.Id != null && npe03Settings.get(setting) != null) {
                    npspExistingSettings.put(setting, (Boolean)npe03Settings.get(setting));                    
                    npe03Settings.put(setting, false); //Deactivating flag
                    continue;
                }
    		} else if(setting.startsWith('npe4')) {
    			if(npe04Settings.Id != null && npe04Settings.get(setting) != null) {
                    npspExistingSettings.put(setting, (Boolean)npe04Settings.get(setting));
                    npe04Settings.put(setting, false); //Deactivating flag
                    continue;
                }
    		}
    	}
    	
    	//Deactivate NPSP flags - getOrgDefaults returns an empty object if the custom setting has no records
    	List<SObject> npspCustomSettings = new List<SObject>();
    	if(npe01Settings.Id != null) npspCustomSettings.add(npe01Settings);
    	if(npo02Settings.Id != null) npspCustomSettings.add(npo02Settings);
    	if(npe03Settings.Id != null) npspCustomSettings.add(npe03Settings);
    	if(npe04Settings.Id != null) npspCustomSettings.add(npe04Settings);
    	update npspCustomSettings;
    	
    	return npspExistingSettings;
    }
    
    private void setupTdtmConfig(Map<String, String> npspToCumulusMap, Map<String, Boolean> existingTriggerConfig) {        
        //First we insert all TDTM records as active
        insertTdtmDefauls();   
        //Now we can deactive only those that were flagged as inactive in NPSP
        deactivateMatchingTdtm(npspToCumulusMap, existingTriggerConfig);
    }
    
    private static void insertTdtmDefauls() {
    	List<Trigger_Handler__c> triggerHandlers = TDTM_DefaultConfig.getDefaultRecords();
        for(Trigger_Handler__c handler : triggerHandlers)
            handler.Active__c = true;
        insert triggerHandlers;
    }
    
    private static void deactivateMatchingTdtm(Map<String, String> npspToCumulusMap, Map<String, Boolean> existingTriggerConfig) {
    	//System.debug('****NPSP to Cumulus Map: \n' + JSON.serializePretty(npspToCumulusMap));
        //System.debug('****Existing Trigger Config: \n' + JSON.serializePretty(existingTriggerConfig));
        
    	List<String> handlerSettingsToUpdate = new List<String>();
    	
        for(String flag : existingTriggerConfig.keySet()) {
            Boolean active = existingTriggerConfig.get(flag);           
            String mapsTo = npspToCumulusMap.get(flag);         
            if(active)
               handlerSettingsToUpdate.add(mapsTo);
        }
        
        List<Trigger_Handler__c> handlersToUpdate = [select Active__c, Class__c from Trigger_Handler__c where Class__c 
                                                     IN :handlerSettingsToUpdate];
        for(Trigger_Handler__c handler : handlersToUpdate) {
            System.debug('****Deactivating class: ' + handler.Class__c);
            handler.Active__c = false;
        }
        update handlersToUpdate; 
    }
}