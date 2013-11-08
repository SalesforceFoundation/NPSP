public with sharing class TDTM_ObjectDataGateway implements TDTM_iTableDataGateway {

    private static Map<String, SObject> classesToCallOnTriggers;
    
    public static Map<String, SObject> getClassesToCallOnTriggers() {   
        if (classesToCallOnTriggers == null){
            classesToCallOnTriggers = new Map<String, Trigger_Handler__c>();
            List<Trigger_Handler__c> classesToCallOnTriggersList = [select Asynchronous__c, Class__c, Load_Order__c, Object__c, 
                                                            Active__c, Trigger_Actions__c from Trigger_Handler__c 
                                                            where Active__c = true];
            System.debug('****Number of Trigger_Handler__c records found: ' + classesToCallOnTriggersList.size());
            Integer i = 0; //So that the map keys are different and they don't override each other
            for(Trigger_Handler__c subsys : classesToCallOnTriggersList) {
                classesToCallOnTriggers.put(subsys.Class__c + i, subsys);
                i++;
            }
        }
        System.debug('****Classes to call on triggers: ' + classesToCallOnTriggers.size());
        return classesToCallOnTriggers;
    }
}