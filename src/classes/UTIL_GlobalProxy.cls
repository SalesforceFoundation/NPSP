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
    
    /** Utility methods - debugging-related **/
    public static void debug(string message) {
    	
    }
    
    public static void debug(System.LoggingLevel level, string message) {
    	
    }
    
    public static void debugWithInfo(string message) {
     	
    }
    
    public static void debugWithInfo(System.LoggingLevel level, string message) {
    	
    }
    
    /** Utility methods - describe-related **/
    public static Schema.DescribeSObjectResult getObjectDescribe(String objectName) {
    	
    	return null;
    }
    
    /** Utility method - namespage-related **/
    public static Boolean inManagedPackage() {
    
        return null;	
    }
}