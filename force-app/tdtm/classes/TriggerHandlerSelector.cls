public inherited sharing class TriggerHandlerSelector {

    public List<Trigger_Handler__c> getTriggerHandlers() {
        List<Trigger_Handler__c> triggerHandlers = [
                SELECT Id, Name, Object__c, Active__c, Asynchronous__c,
                        Load_Order__c, Trigger_Action__c, Class__c
                FROM Trigger_Handler__c
                ORDER BY Object__c ASC, Load_Order__c ASC
                LIMIT 50000
        ];
        return triggerHandlers;
    }
}