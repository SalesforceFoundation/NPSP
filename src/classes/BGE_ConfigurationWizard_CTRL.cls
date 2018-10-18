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
* @group-content 
* @description BGE Wizard Component Controller.
*/
public with sharing class BGE_ConfigurationWizard_CTRL {

    /*******************************************************************************************************
    * @description Retrieves the Template Details information, the related list of fields, and component labels.
    * @param sObjectName string of the sObjectName retrieved with force:hasSObjectName
    * @param recordId Id of the record to be queried
    * @return JSON model of all template details data.
    */
    @AuraEnabled
    public static String getRecordDetails(String sObjectName, Id recordId) {
        BGEDetailsModel model = new BGEDetailsModel();

        sObjectName = UTIL_Namespace.StrTokenRemoveNSPrefix(sObjectName);

        if (recordId != null) {

            if (sObjectName == 'Batch_Template__c' || sObjectName == 'DataImportBatch__c') {
                try {
                    String descriptionField = (sObjectName == 'DataImportBatch__c') ? 'Batch_Description__c' : 'Description__c';

                    String soql = 'SELECT Name, Id, ' + descriptionField + ', RequireTotalMatch__c, Active_Fields__c ';
                    soql += 'FROM ' + sObjectName;
                    soql += ' WHERE Id=:recordId';

                    SObject recordDetails = Database.query(soql);

                    model.name = (String)recordDetails.get('Name');
                    model.id = (String)recordDetails.get('Id');
                    model.description = (String)recordDetails.get(descriptionField);
                    model.requireTotalMatch = (Boolean)recordDetails.get('RequireTotalMatch__c');
                    model.activeFields = (String)recordDetails.get('Active_Fields__c');

                    if (sObjectName == 'DataImportBatch__c') {
                        model.expectedCount = (Integer)recordDetails.get('Expected_Count_of_Gifts__c');
                        model.expectedTotal = (Decimal)recordDetails.get('Expected_Total_Batch_Amount__c');
                    }
                }
                catch (Exception ex){
                    throw new AuraHandledException('ERROR: ' + ex.getMessage());
                }
            } else {
                throw new AuraHandledException('ERROR: ' + 'Only Batch_Template__c and DataImportBatch__c are supported objects.');
            }
        }

        model.templateFields = getAvailableFields();
        model.labels = getLabels(sObjectName);

        return JSON.serialize(model);
    }

    /*******************************************************************************************************
    * @description Retrieves the related list of fields.
    * @return list of Template Fields with sObjectName and Name.
    */
    public static List<bgeField> getAvailableFields() {

        List<bgeField> fields = new List<bgeField>();

        Map<String, Schema.DescribeFieldResult> fieldMap = UTIL_Describe.getAllFieldsDescribe(UTIL_Namespace.StrTokenNSPrefix('DataImport__c'));
        Set<String> bannedFields = new Set<String>{'Account1Imported__c',
                'Account1ImportStatus__c',
                'Account2Imported__c',
                'Account2ImportStatus__c',
                'ApexJobId__c',
                'Contact1Imported__c',
                'Contact1ImportStatus__c',
                'Contact2Imported__c',
                'Contact2ImportStatus__c',
                'DonationImported__c',
                'DonationImportStatus__c',
                'Donation_Possible_Matches__c',
                'FailureInformation__c',
                'HomeAddressImported__c',
                'HomeAddressImportStatus__c',
                'HouseholdAccountImported__c',
                'ImportedDate__c',
                'NPSP_Data_Import_Batch__c',
                'PaymentImported__c',
                'PaymentImportStatus__c',
                'Payment_Possible_Matches__c',
                'Status__c',
                'Account2ImportStatus__c'
        };

        Set<String> allowedObjects = new Set<String>{
                'Opportunity',
                'Payment'
        };

        // these fields are required only if at least 1 field from its object group is selected
        Set<String> systemRequiredFields = new Set<String>{
                'Account1_Name__c',
                'Account2_Name__c',
                'Donation_Amount__c',
                'Contact1_LastName__c',
                'Contact2_LastName__c'
        };

        // looping through the fields on DataImport__c
        for (Schema.DescribeFieldResult fieldResult : fieldMap.values()) {
            String dataImportFieldApiName = UTIL_Namespace.StrTokenRemoveNSPrefix(fieldResult.name);
            //Special case for Donation_Donor because it's derived 

            //todo: rework these 2 lines
            String dataImportFieldMappedObject = fieldResult.inlineHelpText != null ? fieldResult.inlineHelpText.split('\\.')[0] : null;
            Boolean fieldAllowed = allowedObjects.contains(dataImportFieldMappedObject) && !bannedFields.contains(dataImportFieldApiName) && fieldResult.inlineHelpText != null;

            if (fieldAllowed) {

                bgeField field = new bgeField();

                // TODO: make these localized with schema describes
                field.sObjectName = dataImportFieldMappedObject;

                // TODO: pull these labels from target fields' schema based on help text mapping
                Boolean fieldHasSpacesAndObjName = fieldResult.getLabel().contains(' ') && fieldResult.getLabel().split(' ',2)[0] == field.sObjectName;
                field.label = (fieldHasSpacesAndObjName) ? fieldResult.getLabel().split(' ',2)[1] : fieldResult.getLabel();
                field.name = fieldResult.getName();

                String unnamespacedField = UTIL_Namespace.StrTokenRemoveNSPrefix(field.name);
                if (systemRequiredFields.contains(unnamespacedField)) {
                    field.systemRequired = true;
                }

                fields.add(field);
            }
        }
        return fields;
    }
    /*******************************************************************************************************
    * @description Retrieves the object and field labels for the component.
    * @param sObjectName the object being used by the component (already stripped of the namespace prefix)
    * @return Map of object and field name keys to their labels.
    */
    public static Map<String, String> getLabels(String sObjectName) {

        if (sObjectName == 'Batch_Template__c') {
            Map<String, String> labels = getTemplateLabels();
            return labels;
        } else if (sObjectName == 'DataImportBatch__c') {
            Map<String, String> labels = getBatchLabels();
            return labels;
        } else {
            throw new AuraHandledException('ERROR: ' + 'Only Batch_Template__c and DataImportBatch__c are supported objects.');
        }
    }

    /*******************************************************************************************************
    * @description Retrieves the object and field labels for the template object.
    * @return Map of object and field name keys to their labels.
    */
    public static Map<String, String> getTemplateLabels() {
        Map<String, String> labels = new Map<String, String> {
                'objectLabel' => Schema.SObjectType.Batch_Template__c.getLabel(),
                'backToTemplates' => String.format(Label.CRLP_Return, new List<String>{Schema.SObjectType.Batch_Template__c.getLabelPlural()}),
                'sObjectName' => Schema.SObjectType.Batch_Template__c.getName(),
                'sObjectNameNoNamespace' => UTIL_Namespace.StrTokenRemoveNSPrefix(Schema.SObjectType.Batch_Template__c.getName()),
                'missingNameDescriptionError' => Label.exceptionRequiredField + ' ' + Schema.Batch_Template__c.Name.getDescribe().getLabel() + ', ' + Schema.Batch_Template__c.Description__c.getDescribe().getLabel(),
                'description' => Schema.Batch_Template__c.Description__c.getDescribe().getLabel(),
                'totalMatchHelp' => Schema.Batch_Template__c.RequireTotalMatch__c.getDescribe().getInlineHelpText(),
                'totalMatchLabel' => Schema.Batch_Template__c.RequireTotalMatch__c.getDescribe().getLabel(),
                'recordInfoLabel' => Label.bgeBatchTemplateOverviewWizard
        };
        return labels;
    }

    /*******************************************************************************************************
    * @description Retrieves the object and field labels for the batch object.
    * @return Map of object and field name keys to their labels.
    */
    public static Map<String, String> getBatchLabels() {
        Map<String, String> labels = new Map<String, String> {
                'objectLabel' => Schema.SObjectType.DataImportBatch__c.getLabel(),
                'sObjectName' => Schema.SObjectType.DataImportBatch__c.getName(),
                'sObjectNameNoNamespace' => UTIL_Namespace.StrTokenRemoveNSPrefix(Schema.SObjectType.DataImportBatch__c.getName()),
                'missingNameDescriptionError' => Label.exceptionRequiredField + ' ' + Schema.DataImportBatch__c.Name.getDescribe().getLabel() + ', ' + Schema.DataImportBatch__c.Batch_Description__c.getDescribe().getLabel(),
                'description' => Schema.DataImportBatch__c.Batch_Description__c.getDescribe().getLabel(),
                'totalMatchHelp' => Schema.DataImportBatch__c.RequireTotalMatch__c.getDescribe().getInlineHelpText(),
                'totalMatchLabel' => Schema.DataImportBatch__c.RequireTotalMatch__c.getDescribe().getLabel(),
                'recordInfoLabel' => Label.bgeBatchInfoWizard,
                'expectedCountField' => Schema.SObjectType.DataImportBatch__c.fields.Expected_Count_of_Gifts__c.getName(),
                'expectedCountLabel' => Schema.SObjectType.DataImportBatch__c.fields.Expected_Count_of_Gifts__c.getLabel(),
                'expectedTotalField' => Schema.SObjectType.DataImportBatch__c.fields.Expected_Total_Batch_Amount__c.getName(),
                'expectedTotalLabel' => Schema.SObjectType.DataImportBatch__c.fields.Expected_Total_Batch_Amount__c.getLabel()
        };
        return labels;
    }

    /*******************************************************************************************************
    * @description Checks if an org uses namespacing
    * @return Boolean of if namespace is used
    */
    @AuraEnabled
    public static Boolean isOrgNamespaced() {
        return UTIL_Namespace.getNamespace() != '';
    }

    /*******************************************************************************************************
    * @description Deserializes information to the model and selects which record to save.
    * @param sObjectName the non-namespaced sObjectName
    * @param recordInfo JSON string of the record information
    * @param activeFields JSON string of the active fields to be saved to the record
    * @return string of the record information with the Id
    */
    @AuraEnabled
    public static String saveRecord(String sObjectName, String recordInfo, String activeFields) {
        try {
            BGEDetailsModel recordDetails = (BGEDetailsModel) JSON.deserialize(recordInfo, BGEDetailsModel.class);

            if (sObjectName == 'Batch_Template__c') {
                recordDetails.id = saveRecordTemplate(recordDetails, activeFields);
            } else if (sObjectName == 'DataImportBatch__c') {
                recordDetails.id = saveRecordBatch(recordDetails, activeFields);
            } else {
                throw new AuraHandledException('ERROR: ' + 'Only Batch_Template__c and DataImportBatch__c are supported objects.');
            }

            return JSON.serialize(recordDetails);

        } catch (Exception ex) {
            //TODO: is BDI right to use here?
            ERR_Handler.processError(ex, ERR_Handler_API.Context.BDI);
            throw new AuraHandledException('ERROR: ' + ex.getMessage());
        }
    }

    /*******************************************************************************************************
    * @description Saves the Batch information with the structured list of active fields.
    * @param recordDetails model of the information to save
    * @param activeFields JSON string of the active fields to be saved to the record
    * @return Id of the saved record
    */
    public static Id saveRecordBatch(BGEDetailsModel recordDetails, String activeFields) {
        DataImportBatch__c dataImportBatch = new DataImportBatch__c();

        if (recordDetails.id != null) {
            dataImportBatch.Id = recordDetails.id;
        }
        dataImportBatch.Name = recordDetails.name;
        dataImportBatch.Batch_Description__c = recordDetails.description;
        dataImportBatch.RequireTotalMatch__c = recordDetails.requireTotalMatch;
        dataImportBatch.Expected_Count_of_Gifts__c = recordDetails.expectedCount;
        dataImportBatch.Expected_Total_Batch_Amount__c = recordDetails.expectedTotal;
        dataImportBatch.Active_Fields__c = activeFields;

        upsert dataImportBatch;

        return dataImportBatch.Id;
    }

    /*******************************************************************************************************
    * @description Saves the Template information with the structured list of active fields.
    * @param recordDetails model of the information to save
    * @param activeFields JSON string of the active fields to be saved to the record
    * @return Id of the saved record
    */
    public static Id saveRecordTemplate(BGEDetailsModel recordDetails, String activeFields) {
        Batch_Template__c batchTemplate = new Batch_Template__c();

        if (recordDetails.id != null) {
            batchTemplate.Id = recordDetails.id;
        }
        batchTemplate.Name = recordDetails.name;
        batchTemplate.Description__c = recordDetails.description;
        batchTemplate.RequireTotalMatch__c = recordDetails.requireTotalMatch;
        batchTemplate.Active_Fields__c = activeFields;

        upsert batchTemplate;

        return batchTemplate.Id;
    }

    /*******************************************************************************************************
    * @description a class to retrieve and save the required information for the BGE_ConfigurationWizard component.
    */
    public class BGEDetailsModel {
        @AuraEnabled public String name;
        @AuraEnabled public String description;
        @AuraEnabled public Boolean enableTotalEntry;
        @AuraEnabled public Id id;
        @AuraEnabled public Boolean requireTotalMatch;
        @AuraEnabled public Integer expectedCount;
        @AuraEnabled public Decimal expectedTotal;
        @AuraEnabled public List<bgeField> templateFields;
        @AuraEnabled public String activeFields;
        @AuraEnabled public Map<String, String> labels;

        public BGEDetailsModel() {
            enableTotalEntry = false;
            requireTotalMatch = false;
            expectedCount = 0;
            expectedTotal = 0;
            templateFields = new List<bgeField>();
        }
    }

    /*******************************************************************************************************
    * @description a class to retrieve and save information related to Active and Available fields.
    */
    public class bgeField {
        @AuraEnabled public String label;
        @AuraEnabled public String name;
        @AuraEnabled public String sObjectName;
        @AuraEnabled public Boolean isActive;
        @AuraEnabled public String defaultValue;
        @AuraEnabled public Boolean required;
        @AuraEnabled public Boolean systemRequired;
        @AuraEnabled public Boolean hide;

        public bgeField() {
            isActive = false;
            required = false;
            hide = false;
            systemRequired = false;
        }
    }
}