trigger BGE_DataImportBatchTrigger on DataImportBatch__c (before insert, before update) {

    BGE_DataImportBatchTriggerHandler handler = new BGE_DataImportBatchTriggerHandler(Trigger.new, Trigger.old);

    if (Trigger.isBefore) {

        if (Trigger.isInsert) {

            handler.setDefaultValues();
        }
    }
}