@isTest
private class BGE_AuraController_TEST {

    static testMethod void testFacadeTemplateMethods(){

        Batch_Template__c templateToInsert = new Batch_Template__c();
        Batch_Template_Field__c batchTemplateFieldToInsert = new Batch_Template_Field__c();

        templateToInsert.Name = 'Test Template';

        insert templateToInsert;

        Batch_Template__c newTemplate = BGE_AuraController.loadTemplates()[0];

        Id templateId = newTemplate.Id;

        batchTemplateFieldToInsert.Batch_Template__c = templateId;
        batchTemplateFieldToInsert.Name = 'Donation_Type__c';
        batchTemplateFieldToInsert.Order__c = 1;

        insert batchTemplateFieldToInsert;

        Batch_Template_Field__c[] batchTemplateFields = BGE_AuraController.loadTemplateFields(templateId);

        BGE_AuraController.saveTemplate (newTemplate, batchTemplateFields);

        BGE_AuraController.cloneTemplate (newTemplate, batchTemplateFields);

        BGE_AuraController.deleteTemplate (templateId);

    }

    static testMethod void testFacadeBatchMethods(){

        Batch_Template__c templateToInsert = new Batch_Template__c();
        DataImportBatch__c dataImportBatchToInsert = new DataImportBatch__c();

        insert templateToInsert;
        insert dataImportBatchToInsert;

        Id templateId = BGE_AuraController.loadTemplates()[0].Id;

        BGE_AuraController.loadTemplateFields(templateId);

        DataImportBatch__c newBatch = new DataImportBatch__c();

        newBatch.Name = 'Test Batch';

        BGE_AuraController.saveBatch(newBatch);

        // saveBatchTemplate
    //    BGE_AuraController.saveBatch(newBatch,templateId);

        // updateBatchTemplate
    //    BGE_AuraController.updateBatch(newBatch,templateId);

        BGE_AuraController.findByName(newBatch.Name);

    }


}