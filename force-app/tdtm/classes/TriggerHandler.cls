/**
 * Created by  on .
 */

public with sharing class TriggerHandler {

    private SObject record;

    public TriggerHandler(SObject record) {
        this.record = record;
    }

    public String name() {
        return String.valueOf(record.get('Class__c'));
    }


    public Boolean isAsync() {
        return Boolean.valueOf(record.get('Asynchronous__c'));
    }


}