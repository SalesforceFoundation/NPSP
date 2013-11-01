public with sharing class SUBSYS_Helper {

    private static Map<String, SubsystemModule__c> SubsystemModules;
    
    public static Map<String, SubsystemModule__c> getSubsystemModules(){	
        if (SubsystemModules == null){
           List<SubsystemModule__c> SubsystemModulesList = [select Asynchronous__c, Class__c, Load_Order__c, Object__c, Trigger_Actions__c 
                                                            from SubsystemModule__c where Active__c = true];
           for(SubsystemModule__c subsys : SubsystemModulesList) {
                //@TODO: verify which key we should be using here 
                SubsystemModules.put(subsys.Class__c, subsys);
            }
        }
        return SubsystemModules;
    }
}