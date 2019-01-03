/*
    Copyright (c) 2018, Salesforce.org
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Salesforce.org nor the names of
      its contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
    COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
    LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
    ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
    POSSIBILITY OF SUCH DAMAGE.
*/
/**
* @author Salesforce.org
* @date 2018
* @group BGE
* @group-content ../../ApexDocContent/BatchDataImport.htm
* @description Utilities to support Batch Gift Entry.
*/
public with sharing class BGE_BatchGiftEntry_UTIL {

    /*******************************************************************************************************
    * @description returns a list of DataImport__c fields the Batch Gift Entry UI needs in SOQL
    * @param batchId the batch for which to get all fields for soql
    * @return List<String> list of DataImport__c field api names
    */
    public static List<String> getDataImportFields(Id batchId) {
        return getDataImportFields(batchId, true);
    }

    /*******************************************************************************************************
    * @description returns a list of DataImport__c fields the Batch Gift Entry UI needs in SOQL
    * @param batchId the batch for which to get all fields for soql
    * @param includeRelationshipFields whether to include relationship fields in the returned list
    * @return List<String> list of DataImport__c field api names
    */
    public static List<String> getDataImportFields(Id batchId, Boolean includeRelationshipFields) {

        List<String> fields = getCoreDataImportFields(includeRelationshipFields);
        fields.addAll(getActiveFieldNamesFromBatch(batchId));

        return fields;
    }

    /*******************************************************************************************************
    * @description returns the subset of DataImport__c fields that are part of every batch
    * @param includeRelationshipFields whether to include relationship fields in the returned list
    * @return List<String> list of DataImport__c field api names
    */
    private static List<String> getCoreDataImportFields(Boolean includeRelationshipFields) {
        List<String> fields = new List<String> {
                'Id',
                'Account1Imported__c',
                'Contact1Imported__c',
                'Donation_Donor__c',
                'DonationImported__c',
                'DonationImportStatus__c',
                'FailureInformation__c',
                'NPSP_Data_Import_Batch__c',
                'PaymentImported__c',
                'PaymentImportStatus__c',
                'Status__c'
        };

        if (includeRelationshipFields) {
            fields.addAll(new List<String>{
                'Account1Imported__r.Name',
                'Contact1Imported__r.Name',
                'DonationImported__r.Name',
                'PaymentImported__r.Name'
            });
        }

        return fields;
    }

    /*******************************************************************************************************
    * @description parses Active_Fields__c for the list of user-defined fields included in the batch config
    * @param batchId: ID of the NPSP_Data_Import_Batch__c
    * @return list of field api names
    */
    public static List<String> getActiveFieldNamesFromBatch(Id batchId) {

        DataImportBatch__c batch = [SELECT Active_Fields__c FROM DataImportBatch__c WHERE Id = :batchId];
        String activeFieldsJSON = batch.Active_Fields__c;
        List<String> activeFieldNames = new List<String>();

        if (activeFieldsJSON != null) {
            List<BGE_ConfigurationWizard_CTRL.BGEField> activeFields = (List<BGE_ConfigurationWizard_CTRL.BGEField>)JSON.deserialize(activeFieldsJSON, List<BGE_ConfigurationWizard_CTRL.BGEField>.class);
            for (BGE_ConfigurationWizard_CTRL.BGEField field : activeFields) {
                activeFieldNames.add(field.name);
            }
        }

        return activeFieldNames;
    }

    /*******************************************************************************************************
    * @description Checks for field permissions needed to create a new Batch
    * User must have fields on DataImportBatch__c that appear in the config wizard
    * as well as Donation_Amount__c on DataImport__c because it is locked as a required field in config wizard
    * @return void; throws an AuraHandledException if any fields fail FLS check
    */
    public static void checkFieldPermissionsNeededForBatch() {

        List<DescribeFieldResult> fieldsToCheck = new List<DescribeFieldResult>();

        List<String> batchFieldNames = getBatchFieldNames();

        for (String field : batchFieldNames) {
            if (field != 'Id') {
                if (field.contains('__c')) {
                    field = UTIL_Namespace.StrTokenNSPrefix(field);
                }
                fieldsToCheck.add(UTIL_Describe.getFieldDescribe(UTIL_Namespace.StrTokenNSPrefix('DataImportBatch__c'), field));
            }
        }

        // Donation Amount is also required
        fieldsToCheck.add(UTIL_Describe.getFieldDescribe(UTIL_Namespace.StrTokenNSPrefix('DataImport__c'), UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c')));

        for (DescribeFieldResult dfr : fieldsToCheck) {
            if (!canUpdateField(dfr)) {
                throw new AuraHandledException(Label.bgeFLSError);
            }
        }
    }

    /*******************************************************************************************************
    * @description checks for read, create, and edit FLS for a given field
    * @param dfr DescribeFieldResult of the field to check
    * @return Boolean
    */
    public static Boolean canUpdateField(DescribeFieldResult dfr) {
        return dfr.isCreateable() && dfr.isUpdateable();
    }

    /*******************************************************************************************************
    * @description Returns the relevant Batch fields for soql
    * @return list of field API names
    */
    public static List<String> getBatchFieldNames() {
        return new List<String>{
                'Id',
                'Name',
                'Active_Fields__c',
                'Batch_Description__c',
                'Batch_Process_Size__c',
                'Contact_Matching_Rule__c',
                'Donation_Matching_Behavior__c',
                'Donation_Matching_Implementing_Class__c',
                'Donation_Matching_Rule__c',
                'Donation_Date_Range__c',
                'Expected_Count_of_Gifts__c',
                'Expected_Total_Batch_Amount__c',
                'Post_Process_Implementing_Class__c',
                'Process_Using_Scheduled_Job__c',
                'RequireTotalMatch__c',
                'Run_Opportunity_Rollups_while_Processing__c'

        };
    }

}