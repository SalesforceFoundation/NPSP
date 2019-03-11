/*
    Copyright (c) 2019, Salesforce.org
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
* @date 2019
* @group BGE
* @group-content 
* @description BGE Wizard Component Controller.
*/
public with sharing class BGE_ConfigurationWizard_CTRL {

    /*******************************************************************************************************
    * @description These fields are required only if at least 1 field from its object group is selected
    */
    private static Set<String> conditionallyRequiredFields = new Set<String>{
        'Account1_Name__c',
        'Account2_Name__c',
        'Contact1_LastName__c',
        'Contact2_LastName__c'
    };

    /*******************************************************************************************************
    * @description Retrieves the Template Details information, the related list of fields, and component labels.
    * @param recordId Id of the record to be queried
    * @return JSON model of all template details data.
    */
    @AuraEnabled
    public static String getRecordDetails(Id recordId) {
        // instantiate DI field map from UTIL_Describe so field order is guaranteed
        Map<String, Schema.DescribeFieldResult> fieldMap = UTIL_Describe.getAllFieldsDescribe(UTIL_Namespace.StrTokenNSPrefix('DataImport__c'));

        BGEDetailsModel model = new BGEDetailsModel();

        List<String> fields = BGE_BatchGiftEntry_UTIL.getBatchFieldNames();

        if (recordId != null) {
            try {

                String soql = 'SELECT ' +
                    String.join(fields, ', ') +
                    ' FROM DataImportBatch__c'+
                    ' WHERE Id=:recordId' +
                    ' LIMIT 1';

                DataImportBatch__c recordDetails = Database.query(soql);

                model.name = recordDetails.Name;
                model.id = recordDetails.Id;
                model.description = recordDetails.Batch_Description__c;
                model.requireTotalMatch = recordDetails.RequireTotalMatch__c;
                model.activeFields = recordDetails.Active_Fields__c;
                model.batchProcessSize = recordDetails.Batch_Process_Size__c;
                model.donationDateRange = recordDetails.Donation_Date_Range__c;
                model.donationMatchingBehavior = recordDetails.Donation_Matching_Behavior__c;
                model.donationMatchingClass = recordDetails.Donation_Matching_Implementing_Class__c;
                model.donationMatchingRule = recordDetails.Donation_Matching_Rule__c.split(';');
                model.postProcessClass = recordDetails.Post_Process_Implementing_Class__c;
                model.runOpportunityRollupsWhileProcessing = recordDetails.Run_Opportunity_Rollups_while_Processing__c;
                model.expectedCount = (Integer)recordDetails.Expected_Count_of_Gifts__c;
                model.expectedTotal = recordDetails.Expected_Total_Batch_Amount__c;

            } catch (Exception ex) {
                throw new AuraHandledException('ERROR: ' + ex.getMessage());
            }

            model.recordCount = [SELECT COUNT() FROM DataImport__c WHERE NPSP_Data_Import_Batch__c = :recordId];

        }

        setDefaultValuesOnBGEDetailsModel(model);

        model.namespacePrefix = UTIL_Namespace.getNamespace();
        model.donationMatchingOptions = getDonationMatchingOptions();
        model.availableFields = getAvailableFields();

        model.labels = getBatchLabels();

        return JSON.serialize(model);
    }

    /*******************************************************************************************************
    * @description Retrieves the related list of fields.
    * @return list of BGE Fields.
    */
    public static List<BGEField> getAvailableFields() {

        List<BGEField> fields = new List<BGEField>();

        Set<String> allowedObjects = new Set<String>{
            'Opportunity',
            'npe01__OppPayment__c'
        };

        List<DescribeFieldResult> dfrs = getRelevantFields(allowedObjects);

        for (DescribeFieldResult dfr : dfrs) {

            BGEField field = new BGEField();
            field.name = dfr.getName();
            // TODO: pull these labels from target fields' schema based on help text mapping
            Boolean fieldHasSpacesAndObjName = dfr.getLabel().contains(' ') && dfr.getLabel().split(' ',2)[0] == field.sObjectName;
            field.label = (fieldHasSpacesAndObjName) ? dfr.getLabel().split(' ',2)[1] : dfr.getLabel();

            field.sObjectName = BDI_DataImportService.getTargetObject(dfr.getName());
            field.sObjectLabel = UTIL_Describe.getObjectLabel(field.sObjectName);

            if (conditionallyRequiredFields.contains(field.name)) {
                field.conditionallyRequired = true;
            }

            field.type = UTIL_LightningComponentSupport.getLightningInputDataType(dfr.getType());
            field.options = BGE_BatchGiftEntry_UTIL.getPicklistOptions(field.name);

            fields.add(field);
        }
        return fields;
    }

    /*******************************************************************************************************
    * @description Returns the Data Import DFRs for a set of target objects
    * @return list of DescribeFieldResults
    */
    public static List<Schema.DescribeFieldResult> getRelevantFields(Set<String> allowedObjects) {

        Map<String, Schema.DescribeFieldResult> filteredDFRMap = new Map<String, Schema.DescribeFieldResult>();

        Map<String, Schema.DescribeFieldResult> allFieldsMap =
                UTIL_Describe.getAllFieldsDescribe(UTIL_Namespace.StrTokenNSPrefix('DataImport__c'));

        Set<String> bannedFields = new Set<String>{
            'Account1Imported__c',
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

        // these data types have been whitelisted since they already work with BGE
        Set<Schema.DisplayType> allowedDataTypes = new Set<Schema.DisplayType>{
            Schema.DisplayType.CURRENCY,
            Schema.DisplayType.DATE,
            Schema.DisplayType.STRING,
            Schema.DisplayType.TEXTAREA,
            Schema.DisplayType.DOUBLE,
            Schema.DisplayType.PICKLIST,
            Schema.DisplayType.EMAIL,
            Schema.DisplayType.MULTIPICKLIST,
            Schema.DisplayType.PHONE,
            Schema.DisplayType.URL,
            Schema.DisplayType.REFERENCE
        };

        // these fields have been whitelisted since they have special handling in BDI
        Set<String> allowedFields = new Set<String>{
            'Donation_Record_Type_Name__c'
        };

        // looping through the fields on DataImport__c and remove unsupported data types
        for (Schema.DescribeFieldResult dfr : allFieldsMap.values()) {
            String dataImportFieldApiName = UTIL_Namespace.StrTokenRemoveNSPrefix(dfr.getName());

            String dataImportFieldMappedObject = BDI_DataImportService.getTargetObject(dfr.getName());

            Boolean fieldAllowed = (allowedObjects.contains(dataImportFieldMappedObject)
                && allowedDataTypes.contains(dfr.type)
                && !bannedFields.contains(dataImportFieldApiName)
                && dfr.getInlineHelpText() != null)
                || allowedFields.contains(dataImportFieldApiName);

            if (fieldAllowed) {
                filteredDFRMap.put(dfr.label, dfr);
            }
        }

        BGE_BatchGiftEntry_UTIL.checkFieldPermissions(filteredDFRMap.values());

        List<String> sortedFieldLabels = new List<String>(filteredDFRMap.keySet());
        sortedFieldLabels.sort();

        List<Schema.DescribeFieldResult> sortedDFRs = new List<Schema.DescribeFieldResult>();
        for (String fieldLabel : sortedFieldLabels) {
            sortedDFRs.add(filteredDFRMap.get(fieldLabel));
        }

        return sortedDFRs;
    }

    /*******************************************************************************************************
    * @description Retrieves the default active fields for a new Batch or Template in a JSON String
    */
    public static String getDefaultActiveFields() {
        List<BGEField> fields = new List<BGEField>();

        String dataImportApiName = UTIL_Namespace.StrTokenNSPrefix('DataImport__c');
        String opportunityName = Schema.SObjectType.Opportunity.name;
        String opportunityLabel = UTIL_Describe.getObjectLabel(opportunityName);
        String paymentName = Schema.SObjectType.npe01__OppPayment__c.name;
        String paymentLabel = UTIL_Describe.getObjectLabel(paymentName);

        BGEField donationAmount = new BGEField();
        String donationAmountApiName = UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c');
        donationAmount.name = donationAmountApiName;
        donationAmount.label = UTIL_Describe.getFieldLabel(dataImportApiName, donationAmountApiName.toLowerCase());
        donationAmount.sObjectName = opportunityName;
        donationAmount.sObjectLabel = opportunityLabel;
        donationAmount.defaultValue = null;
        donationAmount.isActive = true;
        donationAmount.requiredInEntryForm = true;
        donationAmount.hide = false;
        donationAmount.type = UTIL_LightningComponentSupport.getLightningInputDataType(Schema.DisplayType.CURRENCY);
        donationAmount.sortOrder = 0;
        donationAmount.alwaysRequired = true;
        fields.add(donationAmount);

        BGEField donationDate = new BGEField();
        String donationDateApiName = UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c');
        donationDate.name = donationDateApiName;
        donationDate.label = UTIL_Describe.getFieldLabel(dataImportApiName, donationDateApiName.toLowerCase());
        donationDate.sObjectName = opportunityName;
        donationDate.sObjectLabel = opportunityLabel;
        donationDate.defaultValue = null;
        donationDate.isActive = true;
        donationDate.requiredInEntryForm = true;
        donationDate.hide = false;
        donationDate.type = UTIL_LightningComponentSupport.getLightningInputDataType(Schema.DisplayType.DATE);
        donationDate.sortOrder = 1;
        donationDate.alwaysRequired = true;
        fields.add(donationDate);

        BGEField paymentMethod = new BGEField();
        String paymentMethodApiName = UTIL_Namespace.StrTokenNSPrefix('Payment_Method__c');
        paymentMethod.name = paymentMethodApiName;
        paymentMethod.label = UTIL_Describe.getFieldLabel(dataImportApiName, paymentMethodApiName.toLowerCase());
        paymentMethod.sObjectName = paymentName;
        paymentMethod.sObjectLabel = paymentLabel;
        paymentMethod.defaultValue = null;
        paymentMethod.isActive = true;
        paymentMethod.requiredInEntryForm = false;
        paymentMethod.hide = false;
        paymentMethod.type = UTIL_LightningComponentSupport.getLightningInputDataType(Schema.DisplayType.STRING);
        paymentMethod.options = BGE_BatchGiftEntry_UTIL.getPicklistOptions(paymentMethodApiName);
        paymentMethod.sortOrder = 2;
        fields.add(paymentMethod);

        BGEField checkNumber = new BGEField();
        String checkNumberApiName = UTIL_Namespace.StrTokenNSPrefix('Payment_Check_Reference_Number__c');
        checkNumber.name = checkNumberApiName;
        checkNumber.label = UTIL_Describe.getFieldLabel(dataImportApiName, checkNumberApiName.toLowerCase());
        checkNumber.sObjectName = paymentName;
        checkNumber.sObjectLabel = paymentLabel;
        checkNumber.defaultValue = null;
        checkNumber.isActive = true;
        checkNumber.requiredInEntryForm = false;
        checkNumber.hide = false;
        checkNumber.type = UTIL_LightningComponentSupport.getLightningInputDataType(Schema.DisplayType.STRING);
        checkNumber.sortOrder = 3;
        fields.add(checkNumber);

        return JSON.serialize(fields);
    }

    /*******************************************************************************************************
    * @description Gets the BGEDetailsModel's default values for Batch Gift Entry
    */
    public static BGEDetailsModel getDefaultBGEDetailsModel() {
        BGEDetailsModel model = new BGEDetailsModel();

        model.expectedCount = 0;
        model.expectedTotal = 0;
        model.requireTotalMatch = false;
        model.availableFields = new List<BGEField>();
        model.batchProcessSize = 50;
        model.contactMatchingRule = 'Firstname,Lastname,Email';
        model.donationDateRange = 0;
        model.donationMatchingBehavior = BDI_DataImport_API.ExactMatchOrCreate;
        model.donationMatchingClass = null;
        model.postProcessClass = null;
        model.runOpportunityRollupsWhileProcessing = true;
        model.namespacePrefix = UTIL_Namespace.getNamespace();
        model.activeFields = getDefaultActiveFields();

        List<String> donationMatchingRules = new List<String>();
        donationMatchingRules.add(UTIL_Namespace.StrAllNSPrefix('Donation_Amount__c').toLowerCase());
        donationMatchingRules.add(UTIL_Namespace.StrAllNSPrefix('Donation_Date__c').toLowerCase());
        model.donationMatchingRule = donationMatchingRules;

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

        if (model.availableFields == null) {
            model.availableFields = defaultModel.availableFields;
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

        if (model.activeFields == null) {
            model.activeFields = defaultModel.activeFields;
        }
    }

    /*******************************************************************************************************
    * @description Sets donation field options for BGEDetailsModel
    * @return List<Map<String,String>> donationMatchingOptions
    */
    private static List<Map<String, String>> getDonationMatchingOptions() {
        List<Map<String, String>> donationMatchingOptions = new List<Map<String, String>>();

        Set<String> donationObjects = new Set<String>{
            'Opportunity',
            'npe01__OppPayment__c'
        };
        List<DescribeFieldResult> dfrs = getRelevantFields(donationObjects);

        for (DescribeFieldResult donationField : dfrs) {
            Map<String, String> option = new Map<String, String>();
            option.put('value', donationField.Name.toLowerCase());
            option.put('label', donationField.Label);
            donationMatchingOptions.add(option);
        }
        return donationMatchingOptions;
    }

    /*******************************************************************************************************
    * @description Retrieves the object and field labels for the batch object.
    * @return Map of object and field name keys to their labels.
    */
    public static Map<String, String> getBatchLabels() {
        Map<String, String> labels = new Map<String, String> {
            'objectLabel' => Schema.SObjectType.DataImportBatch__c.getLabel(),
            'sObjectName' => Schema.SObjectType.DataImportBatch__c.getName(),
            'opportunitySObjectName' => Schema.SObjectType.Opportunity.getName(),
            'paymentSObjectName' => Schema.SObjectType.npe01__OppPayment__c.getName(),
            'dataImportSObjectName' => Schema.SObjectType.DataImport__c.getName(),
            'sObjectNameNoNamespace' => UTIL_Namespace.StrTokenRemoveNSPrefix(Schema.SObjectType.DataImportBatch__c.getName()),
            'missingNameError' => Label.exceptionRequiredField + ' ' + Schema.DataImportBatch__c.Name.getDescribe().getLabel(),
            'missingFieldsError' => Label.exceptionRequiredField,
            'description' => Schema.DataImportBatch__c.Batch_Description__c.getDescribe().getLabel(),
            'totalMatchHelp' => Schema.DataImportBatch__c.RequireTotalMatch__c.getDescribe().getInlineHelpText(),
            'totalMatchLabel' => Schema.DataImportBatch__c.RequireTotalMatch__c.getDescribe().getLabel(),
            'recordInfoLabel' => Label.bgeBatchInfoWizard,
            'expectedCountField' => Schema.SObjectType.DataImportBatch__c.fields.Expected_Count_of_Gifts__c.getName(),
            'expectedCountLabel' => Schema.SObjectType.DataImportBatch__c.fields.Expected_Count_of_Gifts__c.getLabel(),
            'expectedTotalField' => Schema.SObjectType.DataImportBatch__c.fields.Expected_Total_Batch_Amount__c.getName(),
            'expectedTotalLabel' => Schema.SObjectType.DataImportBatch__c.fields.Expected_Total_Batch_Amount__c.getLabel(),
            'batchProcessSizeLabel' => Schema.DataImportBatch__c.Batch_Process_Size__c.getDescribe().getLabel(),
            'donationDateRangeLabel' => Schema.DataImportBatch__c.Donation_Date_Range__c.getDescribe().getLabel(),
            'donationMatchingBehaviorLabel' => Schema.DataImportBatch__c.Donation_Matching_Behavior__c.getDescribe().getLabel(),
            'donationMatchingClassLabel' => Schema.DataImportBatch__c.Donation_Matching_Implementing_Class__c.getDescribe().getLabel(),
            'donationMatchingRuleLabel' => Schema.DataImportBatch__c.Donation_Matching_Rule__c.getDescribe().getLabel(),
            'postProcessClassLabel' => Schema.DataImportBatch__c.Post_Process_Implementing_Class__c.getDescribe().getLabel(),
            'runOpportunityRollupsWhileProcessingLabel' => Schema.DataImportBatch__c.Run_Opportunity_Rollups_while_Processing__c.getDescribe().getLabel()
        };
        labels.putAll(getMatchingValues());
        return labels;
    }

    /*******************************************************************************************************
    * @description Retrieves Matching string values from BDI_DataImport_API
    * @return Map of object and field name keys to their labels.
    */
    private static Map<String, String> getMatchingValues() {
        Map<String, String> labels = new Map<String, String> {
            'DoNotMatch' => BDI_DataImport_API.DoNotMatch,
            'RequireNoMatch' => BDI_DataImport_API.RequireNoMatch,
            'RequireExactMatch' => BDI_DataImport_API.RequireExactMatch,
            'ExactMatchOrCreate' => BDI_DataImport_API.ExactMatchOrCreate,
            'RequireBestMatch' => BDI_DataImport_API.RequireBestMatch,
            'BestMatchOrCreate' => BDI_DataImport_API.BestMatchOrCreate
        };
        return labels;
    }

    /*******************************************************************************************************
    * @description Deserializes information to the model and selects which record to save.
    * @param recordInfo JSON string of the record information
    * @param activeFields JSON string of the active fields to be saved to the record
    * @return string of the record information with the Id
    */
    @AuraEnabled
    public static String saveRecord(String recordInfo, String activeFields) {
        try {
            BGEDetailsModel recordDetails = (BGEDetailsModel) JSON.deserialize(recordInfo, BGEDetailsModel.class);
            recordDetails.activeFields = activeFields;

            DataImportBatch__c dataImportBatch = new DataImportBatch__c();

            if (recordDetails.id != null) {
                dataImportBatch.Id = recordDetails.id;
            }
            dataImportBatch.Name = recordDetails.name;
            dataImportBatch.Batch_Description__c = recordDetails.description;
            dataImportBatch.RequireTotalMatch__c = recordDetails.requireTotalMatch;
            dataImportBatch.Active_Fields__c = recordDetails.activeFields;
            dataImportBatch.Batch_Process_Size__c = recordDetails.batchProcessSize;
            dataImportBatch.Donation_Date_Range__c = recordDetails.donationDateRange;
            dataImportBatch.Donation_Matching_Behavior__c = recordDetails.donationMatchingBehavior;
            dataImportBatch.Donation_Matching_Implementing_Class__c = recordDetails.donationMatchingClass;
            dataImportBatch.Donation_Matching_Rule__c = String.join(recordDetails.donationMatchingRule, ';');
            dataImportBatch.Post_Process_Implementing_Class__c = recordDetails.postProcessClass;
            dataImportBatch.Run_Opportunity_Rollups_while_Processing__c = recordDetails.runOpportunityRollupsWhileProcessing;
            dataImportBatch.Expected_Count_of_Gifts__c = recordDetails.expectedCount;
            dataImportBatch.Expected_Total_Batch_Amount__c = recordDetails.expectedTotal;
            dataImportBatch.Active_Fields__c = recordDetails.activeFields;
            dataImportBatch.GiftBatch__c = true;
            dataImportBatch.Process_Using_Scheduled_Job__c = false;

            upsert dataImportBatch;

            recordDetails.id = dataImportBatch.Id;

            return JSON.serialize(recordDetails);

        } catch (Exception ex) {
            //TODO: is BDI right to use here?
            ERR_Handler.processError(ex, ERR_Handler_API.Context.BDI);
            throw new AuraHandledException('ERROR: ' + ex.getMessage());
        }
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
        @AuraEnabled public List<BGEField> availableFields;
        @AuraEnabled public String activeFields;
        @AuraEnabled public Map<String, String> labels;
        @AuraEnabled public Decimal batchProcessSize;
        @AuraEnabled public String contactMatchingRule;
        @AuraEnabled public Decimal donationDateRange;
        @AuraEnabled public String donationMatchingBehavior;
        @AuraEnabled public String donationMatchingClass;
        @AuraEnabled public List<String> donationMatchingRule;
        @AuraEnabled public List<Map<String,String>> donationMatchingOptions;
        @AuraEnabled public String namespacePrefix;
        @AuraEnabled public String postProcessClass;
        @AuraEnabled public Boolean runOpportunityRollupsWhileProcessing;
        @AuraEnabled public Integer recordCount;

        public BGEDetailsModel() {
            requireTotalMatch = false;
            expectedCount = 0;
            expectedTotal = 0;
            availableFields = new List<BGEField>();
        }
    }

    /*******************************************************************************************************
    * @description a class to retrieve and save information related to Active and Available fields.
    */
    public class BGEField {
        @AuraEnabled public Boolean alwaysRequired; // always required in BGE (e.g., Donation Amount and Donation Date)
        @AuraEnabled public Boolean conditionallyRequired; // required if any other field on its object is selected (e.g., Account Name and Contact Last Name)
        @AuraEnabled public String defaultValue;
        @AuraEnabled public Boolean hide;
        @AuraEnabled public Boolean isActive;
        @AuraEnabled public String label;
        @AuraEnabled public String name;
        @AuraEnabled public List<Map<String, String>> options;
        @AuraEnabled public String sObjectName;
        @AuraEnabled public String sObjectLabel;
        @AuraEnabled public Integer sortOrder;
        @AuraEnabled public String type;
        @AuraEnabled public Boolean requiredInEntryForm; // BGE user marked this field as "required" when setting up the batch

        public BGEField() {
            isActive = false;
            hide = false;
            alwaysRequired = false;
            requiredInEntryForm = false;
            conditionallyRequired = false;
        }
    }
}