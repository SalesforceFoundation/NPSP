trigger BGE_TemplateTrigger on Batch_Template__c (before insert) {

 BGE_TemplateTriggerHandler handler = new BGE_TemplateTriggerHandler();
    
    if (Trigger.isBefore) {

        if (Trigger.isInsert) {

            handler.onBeforeInsert();
        }
    }
}