public with sharing class TDTM_ObjectDataGateway implements TDTM_iTableDataGateway {

    
    public static List<SObject> getClassesToCallOnTriggers(String objectName, TDTM_TriggerActionHelper.Action action) {   
        
        return [select Asynchronous__c, Class__c, Load_Order__c, Object__c, Active__c, Trigger_Action__c 
                from Trigger_Handler__c where Active__c = true and Object__c = :objectName and 
                Trigger_Action__c = :action.name() order by Load_Order__c];
    }
}