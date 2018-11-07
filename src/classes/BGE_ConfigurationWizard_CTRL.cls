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

                    String soql = 'SELECT Name, Id, ' +
                            descriptionField + ', ' +
                            'RequireTotalMatch__c, ' +
                            'Active_Fields__c, ' +
                            'Batch_Process_Size__c, ' +
                            'Run_Opportunity_Rollups_while_Processing__c, ' +
                            'Contact_Matching_Rule__c, ' +
                            'Donation_Matching_Behavior__c, ' +
                            'Donation_Matching_Rule__c, ' +
                            'Donation_Date_Range__c, ' +
                            'Process_Using_Scheduled_Job__c' +
                            ' FROM ' + sObjectName +
                            ' WHERE Id=:recordId';

                    SObject recordDetails = Database.query(soql);

                    model.name = (String)recordDetails.get('Name');
                    model.id = (String)recordDetails.get('Id');
                    model.description = (String)recordDetails.get(descriptionField);
                    model.requireTotalMatch = (Boolean)recordDetails.get('RequireTotalMatch__c');
                    model.activeFields = (String)recordDetails.get('Active_Fields__c');

                    // TODO: If/When users are able to change the processing settings, we will need to retrieve their defined values here as well.

                    if (sObjectName == 'DataImportBatch__c') {
                        model.expectedCount = (Integer)recordDetails.get('Expected_Count_of_Gifts__c');
                        model.expectedTotal = (Decimal)recordDetails.get('Expected_Total_Batch_Amount__c');
                    }
                }
                catch (Exception ex){
                    throw new AuraHandledException('ERROR: ' + ex.getMessage());
                }
            } else {
                throw new AuraHandledException('ERROR: Only Batch_Template__c and DataImportBatch__c are supported objects.');
            }
        }

        setDefaultValuesOnBGEDetailsModel(model);

        model.templateFields = getAvailableFields();
        model.labels = getLabels(sObjectName);

        return JSON.serialize(model);
    }

    /*******************************************************************************************************
    * @description Retrieves the related list of fields.
    * @return list of Template Fields with sObjectName and Name.
    */
    public static List<BGEField> getAvailableFields() {

        List<BGEField> fields = new List<BGEField>();

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

        // these data types have been whitelisted since they already work with BGE
        Set<String> allowedDataTypes = new Set<String>{
                'CURRENCY',
                'DATE',
                'STRING',
                'TEXTAREA',
                'DOUBLE',
                'PICKLIST'
        };

        // looping through the fields on DataImport__c
        for (Schema.DescribeFieldResult fieldResult : fieldMap.values()) {
            String dataImportFieldApiName = UTIL_Namespace.StrTokenRemoveNSPrefix(fieldResult.getName());

            String dataImportFieldMappedObject = BDI_DataImportService.getTargetObject(fieldResult.getName());
            Boolean fieldAllowed = allowedObjects.contains(dataImportFieldMappedObject)
                    && allowedDataTypes.contains(fieldResult.getType().name())
                    && !bannedFields.contains(dataImportFieldApiName)
                    && fieldResult.getInlineHelpText() != null;

            if (fieldAllowed) {

                BGEField field = new BGEField();

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
    * @description Retrieves the default active fields for a new Batch or Template in a JSON String
    */
    public static String getDefaultActiveFields() {
        //todo: change this into BGE Field objects instead
        return '[{"label":"Donation Amount",' +
                    '"name":"' + UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') + '",' +
                    '"sObjectName":"Opportunity",' +
                    '"defaultValue":null,' +
                    '"required":true,' +
                    '"hide":false,' +
                    '"sortOrder":0},' +
                '{"label":"Donation Date",' +
                    '"name":"' + UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c') + '",' +
                    '"sObjectName":"Opportunity",' +
                    '"defaultValue":null,' +
                    '"required":false,' +
                    '"hide":false,' +
                    '"sortOrder":1},' +
                '{"label":"Method",' +
                    '"name":"' + UTIL_Namespace.StrTokenNSPrefix('Payment_Method__c') + '",' +
                    '"sObjectName":"Payment",' +
                    '"defaultValue":null,' +
                    '"required":false,' +
                    '"hide":false,' +
                    '"sortOrder":2},' +
                '{"label":"Check/Reference Number",' +
                    '"name":"' + UTIL_Namespace.StrTokenNSPrefix('Payment_Check_Reference_Number__c') + '",' +
                    '"sObjectName":"Payment",' +
                    '"defaultValue":null,' +
                    '"required":false,' +
                    '"hide":false,' +
                    '"sortOrder":3' +
                '}]';
    }

    /*******************************************************************************************************
    * @description Gets the BGEDetailsModel's default values for Batch Gift Entry
    */
    public static BGEDetailsModel getDefaultBGEDetailsModel() {
        BGEDetailsModel model = new BGEDetailsModel();

        model.expectedCount = 0;
        model.expectedTotal = 0;
        model.requireTotalMatch = false;
        model.templateFields = new List<BGEField>();
        model.batchProcessSize = 50;
        model.runOpportunityRollupsWhileProcessing = false;
        model.contactMatchingRule = 'Firstname,Lastname,Email';
        model.donationMatchingBehavior = BDI_DataImport_API.ExactMatchOrCreate;
        model.donationMatchingClass = '';
        model.donationMatchingRule = UTIL_Namespace.StrAllNSPrefix('Donation_Amount__c') + ';' + UTIL_Namespace.StrAllNSPrefix('Donation_Date__c');
        model.donationDateRange = 0;
        model.processUsingScheduledJob = false;
        model.postProcessClass = '';
        model.activeFields = getDefaultActiveFields();

        return model;
    }

    /*******************************************************************************************************
    * @description Sets default values on BGEDetails Model to avoid returning any null values
    */
    private static void setDefaultValuesOnBGEDetailsModel(BGEDetailsModel model) {

        BGEDetailsModel defaultModel = getDefaultBGEDetailsModel();

        if (model.expectedCount == null) {
            model.expectedCount = defaultModel.expectedCount;
        }

        if (model.expectedTotal == null) {
            model.expectedTotal = defaultModel.expectedTotal;
        }

        if (model.requireTotalMatch == null) {
            model.requireTotalMatch = defaultModel.requireTotalMatch;
        }

        if (model.templateFields == null) {
            model.templateFields = defaultModel.templateFields;
        }

        if (model.batchProcessSize == null) {
            model.batchProcessSize = defaultModel.batchProcessSize;
        }

        if (model.runOpportunityRollupsWhileProcessing == null) {
            model.runOpportunityRollupsWhileProcessing = defaultModel.runOpportunityRollupsWhileProcessing;
        }

        if (model.contactMatchingRule == null) {
            model.contactMatchingRule = defaultModel.contactMatchingRule;
        }

        if (model.donationMatchingBehavior == null) {
            model.donationMatchingBehavior = defaultModel.donationMatchingBehavior;
        }

        if (model.donationMatchingRule == null) {
            model.donationMatchingRule = defaultModel.donationMatchingRule;
        }

        if (model.donationMatchingClass == null) {
            model.donationMatchingClass = defaultModel.donationMatchingClass;
        }

        if (model.donationDateRange == null) {
            model.donationDateRange = defaultModel.donationDateRange;
        }

        if (model.postProcessClass == null) {
            model.postProcessClass = defaultModel.postProcessClass;
        }

        if (model.processUsingScheduledJob == null) {
            model.processUsingScheduledJob = defaultModel.processUsingScheduledJob;
        }

        if (model.activeFields == null) {
            model.activeFields = defaultModel.activeFields;
        }
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
            recordDetails.activeFields = activeFields;

            if (sObjectName == 'Batch_Template__c') {
                recordDetails.id = saveRecordTemplate(recordDetails);
            } else if (sObjectName == 'DataImportBatch__c') {
                recordDetails.id = saveRecordBatch(recordDetails);
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
    public static Id saveRecordBatch(BGEDetailsModel recordDetails) {
        DataImportBatch__c dataImportBatch = new DataImportBatch__c();

        if (recordDetails.id != null) {
            dataImportBatch.Id = recordDetails.id;
        }
        dataImportBatch.Name = recordDetails.name;
        dataImportBatch.Batch_Description__c = recordDetails.description;
        dataImportBatch.RequireTotalMatch__c = recordDetails.requireTotalMatch;
        dataImportBatch.Active_Fields__c = recordDetails.activeFields;
        dataImportBatch.Batch_Process_Size__c = recordDetails.batchProcessSize;
        dataImportBatch.Run_Opportunity_Rollups_while_Processing__c = recordDetails.runOpportunityRollupsWhileProcessing;
        dataImportBatch.Donation_Matching_Behavior__c = recordDetails.donationMatchingBehavior;
        dataImportBatch.Donation_Matching_Implementing_Class__c = recordDetails.donationMatchingClass;
        dataImportBatch.Donation_Matching_Rule__c = recordDetails.donationMatchingRule;
        dataImportBatch.Donation_Date_Range__c = recordDetails.donationDateRange;
        dataImportBatch.Post_Process_Implementing_Class__c = recordDetails.postProcessClass;
        dataImportBatch.Process_Using_Scheduled_Job__c = recordDetails.processUsingScheduledJob;
        dataImportBatch.Expected_Count_of_Gifts__c = recordDetails.expectedCount;
        dataImportBatch.Expected_Total_Batch_Amount__c = recordDetails.expectedTotal;
        dataImportBatch.Active_Fields__c = recordDetails.activeFields;
        dataImportBatch.UseBatchGiftEntryGrid__c = true;

        upsert dataImportBatch;

        return dataImportBatch.Id;
    }

    /*******************************************************************************************************
    * @description Saves the Template information with the structured list of active fields.
    * @param recordDetails model of the information to save
    * @param activeFields JSON string of the active fields to be saved to the record
    * @return Id of the saved record
    */
    public static Id saveRecordTemplate(BGEDetailsModel recordDetails) {
        Batch_Template__c batchTemplate = new Batch_Template__c();

        if (recordDetails.id != null) {
            batchTemplate.Id = recordDetails.id;
        }
        batchTemplate.Name = recordDetails.name;
        batchTemplate.Description__c = recordDetails.description;
        batchTemplate.RequireTotalMatch__c = recordDetails.requireTotalMatch;
        batchTemplate.Active_Fields__c = recordDetails.activeFields;
        batchTemplate.Batch_Process_Size__c = recordDetails.batchProcessSize;
        batchTemplate.Run_Opportunity_Rollups_while_Processing__c = recordDetails.runOpportunityRollupsWhileProcessing;
        batchTemplate.Contact_Matching_Rule__c = recordDetails.contactMatchingRule;
        batchTemplate.Donation_Matching_Behavior__c = recordDetails.donationMatchingBehavior;
        batchTemplate.Donation_Matching_Implementing_Class__c = recordDetails.donationMatchingClass;
        batchTemplate.Donation_Matching_Rule__c = recordDetails.donationMatchingRule;
        batchTemplate.Donation_Date_Range__c = recordDetails.donationDateRange;
        batchTemplate.Post_Process_Implementing_Class__c = recordDetails.postProcessClass;
        batchTemplate.Process_Using_Scheduled_Job__c = recordDetails.processUsingScheduledJob;

        upsert batchTemplate;

        return batchTemplate.Id;
    }

    /*******************************************************************************************************
    * @description a class to retrieve and save the required information for the BGE_ConfigurationWizard component.
    */
    public class BGEDetailsModel {
        @AuraEnabled public String name;
        @AuraEnabled public String description;
        @AuraEnabled public Id id;
        @AuraEnabled public Boolean requireTotalMatch;
        @AuraEnabled public Integer expectedCount;
        @AuraEnabled public Decimal expectedTotal;
        @AuraEnabled public List<BGEField> templateFields;
        @AuraEnabled public String activeFields;
        @AuraEnabled public Map<String, String> labels;
        @AuraEnabled public Integer batchProcessSize;
        @AuraEnabled public Boolean runOpportunityRollupsWhileProcessing;
        @AuraEnabled public String contactMatchingRule;
        @AuraEnabled public String donationMatchingBehavior;
        @AuraEnabled public String donationMatchingClass;
        @AuraEnabled public String donationMatchingRule;
        @AuraEnabled public Integer donationDateRange;
        @AuraEnabled public String postProcessClass;
        @AuraEnabled public Boolean processUsingScheduledJob;
        @AuraEnabled public List<Batch_Template__c> availableBatchTemplates;

        public BGEDetailsModel() {
            requireTotalMatch = false;
            expectedCount = 0;
            expectedTotal = 0;
            templateFields = new List<BGEField>();
        }
    }

    /*******************************************************************************************************
    * @description a class to retrieve and save information related to Active and Available fields.
    */
    public class BGEField {
        @AuraEnabled public String label;
        @AuraEnabled public String name;
        @AuraEnabled public String sObjectName;
        @AuraEnabled public Boolean isActive;
        @AuraEnabled public String defaultValue;
        @AuraEnabled public Boolean required;
        @AuraEnabled public Boolean systemRequired;
        @AuraEnabled public Boolean hide;

        public BGEField() {
            isActive = false;
            required = false;
            hide = false;
            systemRequired = false;
        }
    }
}