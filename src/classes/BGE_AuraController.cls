public with sharing class BGE_AuraController {


	@AuraEnabled
    public static Id saveBatchTemplate (DataImportBatch__c batch, Id templateId) {

		Id result = BGE_TemplateController.saveBatch(batch,templateId);
		return result;
	}

	@AuraEnabled
    public static Id updateBatchTemplate (DataImportBatch__c batch, Id templateId) {

		Id result = BGE_TemplateController.updateBatch(batch,templateId);
		return result;
	}

	@AuraEnabled
    public static String saveTemplate (Batch_Template__c newTemplate, Batch_Template_Field__c[] batchTemplateFields) {

		return BGE_TemplateController.saveTemplate (newTemplate, batchTemplateFields);
	}

	@AuraEnabled
    public static Boolean deleteTemplate (Id templateIdToDelete) {

		return BGE_TemplateController.deleteTemplate (templateIdToDelete);
	}

	@AuraEnabled
    public static String cloneTemplate (Batch_Template__c newTemplate, Batch_Template_Field__c[] batchTemplateFields) {

		return BGE_TemplateController.cloneTemplate (newTemplate, batchTemplateFields);
	}

	@AuraEnabled
    public static String editTemplate (Batch_Template__c newTemplate, Batch_Template_Field__c[] batchTemplateFields, Batch_Template_Field__c[] batchTemplateFieldsToDelete) {

		return BGE_TemplateController.editTemplate (newTemplate, batchTemplateFields, batchTemplateFieldsToDelete);
	}

	@AuraEnabled
    public static Batch_Template_Field__c[] loadTemplateFields (Id templateId) {

		return BGE_TemplateController.loadTemplateFields(templateId);
	}

	@AuraEnabled
    public static Batch_Template__c[] loadTemplates () {

		return BGE_TemplateController.loadTemplates();
	}

	@AuraEnabled
    public static void saveBatch (DataImportBatch__c newBatch) {

		BGE_BatchController.saveBatch(newBatch);
	}

	@AuraEnabled
    public static List<DataImportBatch__c> findByName(String searchKey) {

		return BGE_BatchController.findByName(searchKey);
	}

	@AuraEnabled
  public static Batch_Template_Field__c[] loadDataImportApiNames() {

			return BGE_TemplateController.loadDataImportApiNames();
	}
	


}