public with sharing class BGE_DataImportBatchTriggerHandler {

	private DataImportBatch__c[] batchesNew;
	private DataImportBatch__c[] batchesOld;

	private Data_Import_Settings__c campaignSettings;
	private Map<Id, Batch_Template__c> batchTemplatesMap;

	public BGE_DataImportBatchTriggerHandler(DataImportBatch__c[] batchesNew, DataImportBatch__c[] batchesOld) {

		this.batchesNew = batchesNew;
		this.batchesOld = batchesOld;

		batchTemplatesMap = new Map<Id, Batch_Template__c>();
	}

	public void setDefaultValues() {

		campaignSettings = Data_Import_Settings__c.getOrgDefaults();
		batchTemplatesMap = getBatchTemplatesMap();

		for (DataImportBatch__c batch : batchesNew) {

			if (batch.Batch_Template__c != null) {

				setBatchTemplateValues(batch);
			}
			else {
				setOrgWideSettingsValues(batch);
			}
		}
	}

	private void setOrgWideSettingsValues(DataImportBatch__c batch) {

		batch.Account_Custom_Unique_ID__c = campaignSettings.Account_Custom_Unique_ID__c;
		batch.Contact_Custom_Unique_ID__c = campaignSettings.Contact_Custom_Unique_ID__c;
		batch.Contact_Matching_Rule__c = campaignSettings.Contact_Matching_Rule__c;
		//batch.Account_Matching_Rule__c = campaignSettings.Account_Matching_Rule__c;
		batch.Batch_Process_Size__c = campaignSettings.Batch_Size__c;
		batch.Run_Opportunity_Rollups_while_Processing__c = campaignSettings.Run_Opportunity_Rollups_while_Processing__c;
		batch.Donation_Matching_Behavior__c = campaignSettings.Donation_Matching_Behavior__c;
		batch.Donation_Matching_Implementing_Class__c = campaignSettings.Donation_Matching_Implementing_Class__c;
		batch.Donation_Matching_Rule__c = campaignSettings.Donation_Matching_Rule__c;
		batch.Donation_Date_Range__c = campaignSettings.Donation_Date_Range__c;
		batch.Post_Process_Implementing_Class__c = campaignSettings.Post_Process_Implementing_Class__c;
	}

	private void setBatchTemplateValues(DataImportBatch__c batch) {

		if (!batchTemplatesMap.isEmpty()) {

			if (batchTemplatesMap.containsKey(batch.Batch_Template__c)) {

				Batch_Template__c template = batchTemplatesMap.get(batch.Batch_Template__c);

				batch.Account_Custom_Unique_ID__c = template.Account_Custom_Unique_ID__c;
				batch.Contact_Custom_Unique_ID__c = template.Contact_Custom_Unique_ID__c;
				batch.Contact_Matching_Rule__c = template.Contact_Matching_Rule__c;
				//batch.Account_Matching_Rule__c = template.Account_Matching_Rule__c;
				batch.Batch_Process_Size__c = template.Batch_Process_Size__c;
				batch.Run_Opportunity_Rollups_while_Processing__c = template.Run_Opportunity_Rollups_while_Processing__c;
				batch.Donation_Matching_Behavior__c = template.Donation_Matching_Behavior__c;
				batch.Donation_Matching_Implementing_Class__c = template.Donation_Matching_Implementing_Class__c;
				batch.Donation_Matching_Rule__c = template.Donation_Matching_Rule__c;
				batch.Donation_Date_Range__c = template.Donation_Date_Range__c;
				//batch.Post_Process_Implementing_Class__c = template.Post_Process_Implementing_Class__c;
			}
		}
	}

	private Map<Id, Batch_Template__c> getBatchTemplatesMap() {

		Map<Id, Batch_Template__c> result = new Map<Id, Batch_Template__c>();

		Set<Id> templatesIds = new Set<Id>();

		for (DataImportBatch__c batch : batchesNew) {

			if (batch.Batch_Template__c != null && !templatesIds.contains(batch.Batch_Template__c)) {

				templatesIds.add(batch.Batch_Template__c);
			}
		}

		if (!templatesIds.isEmpty()) {

			Batch_Template__c[] templatesList = [SELECT
													   Id,
													   Account_Custom_Unique_ID__c,
													   Contact_Custom_Unique_ID__c,
													   Contact_Matching_Rule__c,
													   Batch_Process_Size__c,
													   Run_Opportunity_Rollups_while_Processing__c,
													   Donation_Matching_Behavior__c,
													   Donation_Matching_Implementing_Class__c,
													   Donation_Matching_Rule__c,
													   Donation_Date_Range__c

												FROM Batch_Template__c
												WHERE Id IN :templatesIds];

			if (!templatesList.isEmpty()) {

				result.putAll(templatesList);
			}
		}

		return result;
	}
}