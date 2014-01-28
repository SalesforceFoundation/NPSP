global class STTG_InstallScript implements InstallHandler {   
  
    global void onInstall(InstallContext context) {
    	
    	//First install of Cumulus. NPSP is a requirement to install Cumulus, so we don't need to check if it's installed
    	if(context.previousVersion() == null) {
    		System.debug('****First install');
    		
    		//Get the mapping from old settings to the new TDTM default setup
            Map<String, String> npspToCumulusMap = TDTM_DefaultConfig.getNpspToCumulusMap();
            
    	    //Read existing NPSP trigger configuration
    	    Map<String, Boolean> existingTriggerConfig = getExistingNpspTriggerConfig(npspToCumulusMap);
    		
    		//Setup the new configuration
    		setupTdtmConfig(npspToCumulusMap, existingTriggerConfig);
    		
    		//All disable flags have been set to false in existingTriggerConfig (so next time no work needs to be done)
    	
    	} else if(context.previousVersion().compareTo(new Version(1,0)) == 0) {
    		System.debug('****First upgrade from version 1.0');
    	}
    	
    	if(context.isUpgrade()) {
    		System.debug('****It is an upgrade');
    	}
    	
    	if(context.isPush()) {
    		System.debug('****It is a push');
    	}
    }
    
    private Map<String, Boolean> getExistingNpspTriggerConfig(Map<String, String> npspToCumulusMap) {
    	
    	Map<String, Boolean> npspExistingSettings = new Map<String, Boolean>();
    	
    	npe01__Contacts_and_Orgs_Settings__c npe01Settings = npe01__Contacts_and_Orgs_Settings__c.getOrgDefaults();
    	npo02__Households_Settings__c npo02Settings = npo02__Households_Settings__c.getOrgDefaults();
    	npe03__Recurring_Donations_Settings__c npe03Settings = npe03__Recurring_Donations_Settings__c.getOrgDefaults();
    	npe4__Relationship_Settings__c npe04Settings = npe4__Relationship_Settings__c.getOrgDefaults();
    	npe5__Affiliations_Settings__c npe05Settings = npe5__Affiliations_Settings__c.getOrgDefaults();
    	
    	for(String setting : npspToCumulusMap.keySet()) {
    		//System.debug('****Mapping key: ' + setting);
    		if(setting.startsWith('npe01')) {
	    		if(npe01Settings.get(setting) != null) {
	    			//System.debug('****Adding key to existing settings map.');
	    			npspExistingSettings.put(setting, (Boolean)npe01Settings.get(setting));
	    			//Deactivating flag
	    			npe01Settings.put(setting, false);
	    			continue;
	    		}
    		} else if(setting.startsWith('npo02')) {
    			if(npo02Settings.get(setting) != null) {
                    //System.debug('****Adding key to existing settings map.');
                    npspExistingSettings.put(setting, (Boolean)npo02Settings.get(setting));
                    //Deactivating flag
                    npo02Settings.put(setting, false);
                    continue;
                }
    		} else if(setting.startsWith('npe03')) {
    			if(npe03Settings.get(setting) != null) {
                    //System.debug('****Adding key to existing settings map.');
                    npspExistingSettings.put(setting, (Boolean)npe03Settings.get(setting));
                    //Deactivating flag
                    npe03Settings.put(setting, false);
                    continue;
                }
    		} else if(setting.startsWith('npe4')) {
    			if(npe04Settings.get(setting) != null) {
                    //System.debug('****Adding key to existing settings map.');
                    npspExistingSettings.put(setting, (Boolean)npe04Settings.get(setting));
                    //Deactivating flag
                    npe04Settings.put(setting, false);
                    continue;
                }
    		}
    	}
    	
    	List<SObject> allSettings = new SObject[] {npe01Settings, npo02Settings, npe03Settings, npe04Settings};
    	update allSettings; //To deactivate the flags
    	
    	return npspExistingSettings;
    }
    
    private void setupTdtmConfig(Map<String, String> npspToCumulusMap, Map<String, Boolean> existingTriggerConfig) {
        
        System.debug('****NPSP to Cumulus Map: \n' + JSON.serializePretty(npspToCumulusMap));
        System.debug('****Existing Trigger Config: \n' + JSON.serializePretty(existingTriggerConfig));
        
        //First we insert all TDTM records as active
        List<Trigger_Handler__c> triggerHandlers = TDTM_DefaultConfig.getDefaultRecords();
        for(Trigger_Handler__c handler : triggerHandlers) {
        	handler.Active__c = false;
        }
        insert triggerHandlers;
        
        //Now we can deactive only those that were flagged as inactive in NPSP
        List<String> handlerSettingsToUpdate = new List<String>();
        
        for(String flag : existingTriggerConfig.keySet()) {
        	Boolean active = existingTriggerConfig.get(flag);
        	//System.debug('****Value of flag ' + flag + ': ' + active);
        	
        	String mapsTo = npspToCumulusMap.get(flag);
        	//System.debug('****Maps to: ' + mapsTo);
        	
        	if(active) {
        	   handlerSettingsToUpdate.add(mapsTo);
        	}
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