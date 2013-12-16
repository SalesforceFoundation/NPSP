trigger TDTM_Opportunity on Opportunity (after delete, after insert, after undelete, 
    after update, before delete, before insert, before update) {

    TDTM_TriggerHandler handler = new TDTM_TriggerHandler();  
    handler.initialize(Trigger.isBefore, Trigger.isAfter, Trigger.isInsert, Trigger.isUpdate, Trigger.isDelete, 
        Trigger.isUnDelete, Trigger.new, Trigger.old, Schema.Sobjecttype.Opportunity);
    handler.runClasses(new TDTM_ObjectDataGateway());
}