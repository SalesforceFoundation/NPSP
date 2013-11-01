public with sharing class SUBSYS_HelperSettings {

	private static Map<String, SubsystemModule_Settings__c> SubsystemModuleSettings;
    
	public static Map<String, SubsystemModule_Settings__c> getSubsystemModuleSettings(){    	
    	if (SubsystemModuleSettings == null){
    	   SubsystemModuleSettings = new Map<String, SubsystemModule_Settings__c>();
    	   SubsystemModuleSettings = SubsystemModule_Settings__c.getAll();
    	}
    	return SubsystemModuleSettings;
    }
}