global with sharing class UTIL_GlobalProxy {

    global List<Trigger_Handler__c> getDefaultTdtmConfig() {
    	
    	
    	return null;
    }
    
    global List<SObject> getDefaultCustomSettings() {
    	
    	return null;
    }
    
    global void processError() {
    	//send error notification, according to configuration
    	
    	//store error record
    }
}