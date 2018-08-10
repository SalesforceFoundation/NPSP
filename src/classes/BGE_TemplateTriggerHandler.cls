public with sharing class BGE_TemplateTriggerHandler {

    private static Boolean isRunningBefore = false;

    private Batch_Template__c[] templatesNew;
    private Batch_Template__c[] templatesOld;

    private Data_Import_Settings__c campaignSettings;

    public BGE_TemplateTriggerHandler (Batch_Template__c[] templatesNew, Batch_Template__c[] templatesOld) {

        this.templatesNew = templatesNew;
        this.templatesOld = templatesOld;
    }

    public void onBeforeInsert () {

        if (!isRunningBefore) {

            isRunningBefore = true;
            isRunningBefore = false;
        }
    }

    public void setDefaultValues() {

        campaignSettings = Data_Import_Settings__c.getOrgDefaults();

        for (Batch_Template__c template : templatesNew) {

            template.Account_Custom_Unique_ID__c = campaignSettings.Account_Custom_Unique_ID__c;
            template.Contact_Custom_Unique_ID__c = campaignSettings.Contact_Custom_Unique_ID__c;
            template.Contact_Matching_Rule__c = campaignSettings.Contact_Matching_Rule__c;
            template.Batch_Process_Size__c = campaignSettings.Batch_Size__c;
            template.Run_Opportunity_Rollups_while_Processing__c = campaignSettings.Run_Opportunity_Rollups_while_Processing__c;
            template.Donation_Matching_Behavior__c = campaignSettings.Donation_Matching_Behavior__c;
            template.Donation_Matching_Implementing_Class__c = campaignSettings.Donation_Matching_Implementing_Class__c;
            template.Donation_Matching_Rule__c = campaignSettings.Donation_Matching_Rule__c;
            template.Donation_Date_Range__c = campaignSettings.Donation_Date_Range__c;
        }

    }
}