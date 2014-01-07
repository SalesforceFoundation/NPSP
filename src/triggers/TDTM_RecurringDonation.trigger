trigger TDTM_RecurringDonation on npe03__Recurring_Donation__c (after delete, after insert, after undelete, 
    after update, before delete, before insert, before update) {

    TDTM_TriggerHandler handler = new TDTM_TriggerHandler();  
    handler.initialize(Trigger.isBefore, Trigger.isAfter, Trigger.isInsert, Trigger.isUpdate, Trigger.isDelete, 
        Trigger.isUnDelete, Trigger.new, Trigger.old, Schema.Sobjecttype.npe03__Recurring_Donation__c);
    handler.runClasses(new TDTM_ObjectDataGateway());
}