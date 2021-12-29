public with sharing class TriggerHandler {

    private Trigger_Handler__c record;

    public TriggerHandler(Trigger_Handler__c record) {
        this.record = record;
    }

    public String className() {
        return record.Class__c;
    }

    public Boolean isAsync() {
        return record.Asynchronous__c;
    }

}