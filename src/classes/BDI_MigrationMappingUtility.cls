/*
    Copyright (c) 2017, Salesforce.org
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
* @group Batch Data Import
* @group-content ../../ApexDocContent/BatchDataImport.htm
* @description Methods to handle converting data import help text mappings to custom metadata records
*/
public with sharing class BDI_MigrationMappingUtility {

    /*******************************************************************************************************
    * @description Metadata queued up for deployment
    */
    public List<Metadata.CustomMetadata> queuedMetadataTypesForDeploy =
        new List<Metadata.CustomMetadata>();

    /*******************************************************************************************************
    * @description Name of default packaged Object Mapping Set
    */
    public static final String NAMESPACE = UTIL_Namespace.getNamespace();

    /*******************************************************************************************************
    * @description Name of default packaged Object Mapping Set
    */
    public static final String DATA_IMPORT_OBJECT_NAME = 'DataImport__c';

    /*******************************************************************************************************
    * @description Name of default packaged Object Mapping Set
    */
    public static final String DEFAULT_OBJECT_MAPPING_SET_RECORD_NAME = 'Default_Object_Mapping_Set';

    /*******************************************************************************************************
    * @description Name of default packaged Field Mapping Set
    * Set as static because it's used in the static method updateCustomSettings
    */
    public static final String DEFAULT_FIELD_MAPPING_SET_RECORD_NAME = 'Default_Field_Mapping_Set';

    /*******************************************************************************************************
    * @description Name of custom Field Mapping Set
    * Set as static because it's used in the static method updateCustomSettings
    */
    public static final String MIGRATED_CUSTOM_FIELD_MAPPING_SET_RECORD_NAME =
        'Migrated_Custom_Field_Mapping_Set';

    /*******************************************************************************************************
    * @description Value for Data Import custom settings Field Mapping Method
    * Set as static because it's used in the static method updateCustomSettings
    */
    public static final String DATA_IMPORT_FIELD_MAPPING = 'Data Import Field Mapping';

    /*******************************************************************************************************
    * @description Value for Data Import Custom Setting's Field Mapping Method.
    * Set as static because it's used in the static method updateCustomSettings
    */
    public static final String HELP_TEXT = 'Help Text';

    /*******************************************************************************************************
    * @description These fields are used to hold information, import status and lookup id, on the newly
    * created/imported records. The default and migrated field mapping set created by the migration utility
    * don't need Data Import Field Mappings for these fields because they're now stored in their corresponding
    * Data Import Object Mapping Custom Metadata Type.
    */
    private final Set<String> DATA_IMPORT_IMPORT_FIELDS = new Set<String>{
        'account1imported__c',
        'account2imported__c',
        'account1importstatus__c',
        'account2importstatus__c',
        'contact1imported__c',
        'contact1importstatus__c',
        'contact2imported__c',
        'contact2importstatus__c',
        'donationcampaignimported__c',
        'donationcampaignimportstatus__c',
        'donationimported__c',
        'donationimportstatus__c',
        'gau_allocation_1_import_status__c',
        'gau_allocation_1_imported__c',
        'gau_allocation_2_import_status__c',
        'gau_allocation_2_imported__c',
        'homeaddressimported__c',
        'homeaddressimportstatus__c',
        'householdaccountimported__c',
        'opportunity_contact_role_1_imported__c',
        'opportunity_contact_role_2_imported__c',
        'paymentimported__c',
        'paymentimportstatus__c'
    };

    /*******************************************************************************************************
    * @description These are known standard Help Text mappings that could be picked up by the migration
    * utility as bad help text mappings and need to be skipped
    */
    private final Set<String> HELP_TEXT_EXCEPTIONS = new Set<String>{
        'The role that the Opportunity Contact Role should be created with.  For example enter \'Soft Credit\' to create a soft credit opportunity contact role.'
    };

    /*******************************************************************************************************
    * @description Helper class that supports BDI_MigrationMappingUtility and enables mocking of test data.
    */
    private BDI_MigrationMappingHelper helper;

    /*******************************************************************************************************
    * @description Custom Setting record where we set cmt api deployment status, cmt deployment id,
    * field mapping method, and default data import field mapping set.
    */
    private Data_Import_Settings__c dataImportSettings;

    /*******************************************************************************************************
    * @description List of standard data import object mappings
    */
    private Map<String, Data_Import_Object_Mapping__mdt> objectMappingsByDeveloperName;

    /*******************************************************************************************************
    * @description List of bad/malformed help text mappings
    */
    public List<HelpTextFieldMapping > badHelpTextMappings {
        get {
            if (badHelpTextMappings == null) {
                badHelpTextMappings = new List<HelpTextFieldMapping>();
            }
            return badHelpTextMappings;
        }
        set;
    }

    /*******************************************************************************************************
    * @description List of BDI_FieldMappingHelpText.DataImportFieldMappings built from good help text mappings
    */
    public List<DataImportFieldMapping> dataImportFieldMappings = new List<DataImportFieldMapping>();

    /*******************************************************************************************************
    * @description Name of the Data Import Field Mapping Set to use
    */
    public String fieldMappingSetName {
        get {
            if (fieldMappingSetName == null) {
                List<Data_Import_Field_mapping_Set__mdt> fieldMappingSet =
                    helper.getFieldMappingSet(MIGRATED_CUSTOM_FIELD_MAPPING_SET_RECORD_NAME);

                if (fieldMappingSet != null && fieldMappingSet.size() > 0) {
                    return MIGRATED_CUSTOM_FIELD_MAPPING_SET_RECORD_NAME;
                }
                return DEFAULT_FIELD_MAPPING_SET_RECORD_NAME;
            }
            return fieldMappingSetName;
        }
        set;
    }

    /*******************************************************************************************************
    * @description Constructor for Migration Mapping Utility class
    * @param helper Instance of BDI_MigrationMappingHelper
    */
    public BDI_MigrationMappingUtility(BDI_MigrationMappingHelper helper) {
        this.helper = helper;
        this.dataImportSettings = UTIL_CustomSettingsFacade.getDataImportSettings();
        this.objectMappingsByDeveloperName =
            helper.getObjectMappingsBySetDeveloperName(DEFAULT_OBJECT_MAPPING_SET_RECORD_NAME);
    }

    /*******************************************************************************************************
    * @description Updates Data Import custom settings.
    * Static because it's used in static inner class DeploymentCallback and in
    * STG_PanelDataImportAdvancedMapping_CTRL
    *
    * @param fieldMappingMethod: String that determines what data import field mapping method
    * to use (i.e. help text, custom metadata)
    * @param status: Deployment status
    * @return Data_Import_Settings__c
    */
    public static Data_Import_Settings__c updateCustomSettings(String fieldMappingMethod, String status) {

        Data_Import_Settings__c dataImportSettings = UTIL_CustomSettingsFacade.getDataImportSettings();
        dataImportSettings.Field_Mapping_Method__c = fieldMappingMethod;
        BDI_MigrationMappingHelper helper = new BDI_MigrationMappingHelper();
        List<Data_Import_Field_mapping_Set__mdt> fieldMappingSet =
            helper.getFieldMappingSet(MIGRATED_CUSTOM_FIELD_MAPPING_SET_RECORD_NAME);

        if (fieldMappingSet.size() > 0) {
            dataImportSettings.Default_Data_Import_Field_Mapping_Set__c =
                MIGRATED_CUSTOM_FIELD_MAPPING_SET_RECORD_NAME;
        } else {
            dataImportSettings.Default_Data_Import_Field_Mapping_Set__c =
                DEFAULT_FIELD_MAPPING_SET_RECORD_NAME;
        }

        Map<String, String> statusMap;

        if (fieldMappingMethod == DATA_IMPORT_FIELD_MAPPING) {
            statusMap = new Map<String, String>{
                'Deployment Date' => String.valueOf(Datetime.now()),
                'Status' => String.valueOf(status),
                'Field Mapping Method' => fieldMappingMethod};
        } else {
            statusMap = new Map<String, String>();
        }

        dataImportSettings.CMT_API_Status__c = JSON.serializePretty(statusMap).left(255);

        try {
            upsert dataImportSettings;
            return dataImportSettings;
        } catch (Exception e) {
            throw new DeploymentException(Label.bdiErrorDataImportCustomSettings + ' ' + e.getMessage());
        }
    }

    /*******************************************************************************************************
    * @description Starts the migration from help text to custom metadata records and adds created custom
    * metadata records to list queuedMetadataTypesForDeploy.
    */
    public void migrateHelpTextToCustomMetadata() {

        queuedMetadataTypesForDeploy.clear();

        if (!Test.isRunningTest()) {
            badHelpTextMappings.clear();
            populateListsFromHelpTextMappings();
        }

        Map<String, Data_Import_Field_Mapping__mdt> fieldMappingsByFieldMappingSetDeveloperName =
            helper.getFieldMappingsByFieldMappingSetDeveloperName(fieldMappingSetName);

        for (DataImportFieldMapping fieldMapping : dataImportFieldMappings) {

            String fieldMappingKey = fieldMapping.getKey();

            Data_Import_Object_Mapping__mdt existingDefaultObjectMapping =
                objectMappingsByDeveloperName.get(fieldMapping.dataImportObjectName);
            Data_Import_Field_Mapping__mdt existingDefaultFieldMapping =
                fieldMappingsByFieldMappingSetDeveloperName.get(fieldMappingKey);

            if (existingDefaultFieldMapping == null) {
                fieldMapping.setFieldMappingSet(MIGRATED_CUSTOM_FIELD_MAPPING_SET_RECORD_NAME);
                fieldMapping.setObjectMapping(existingDefaultObjectMapping);
                // Setting name to null will force field mapping to generate a unique name
                fieldMapping.setRecordName(null, false);

                queuedMetadataTypesForDeploy.add(fieldMapping.getMetadataRecord());

            } else if (existingDefaultFieldMapping != null) {
                if (fieldMappingSetName == MIGRATED_CUSTOM_FIELD_MAPPING_SET_RECORD_NAME) {
                    // Migrated Custom Field Mapping Set exists
                    DataImportFieldMapping overwrittenMapping =
                        new DataImportFieldMapping(
                            existingDefaultFieldMapping,
                            MIGRATED_CUSTOM_FIELD_MAPPING_SET_RECORD_NAME);

                    overwrittenMapping.setFieldMappingSet(MIGRATED_CUSTOM_FIELD_MAPPING_SET_RECORD_NAME);
                    overwrittenMapping.setObjectMapping(existingDefaultObjectMapping);
                    overwrittenMapping.setTargetField(fieldMapping.targetFieldAPIName);

                    queuedMetadataTypesForDeploy.add(overwrittenMapping.getMetadataRecord());
                } else {

                    fieldMapping.setFieldMappingSet(MIGRATED_CUSTOM_FIELD_MAPPING_SET_RECORD_NAME);
                    fieldMapping.setObjectMapping(existingDefaultObjectMapping);

                    // Check if we have a conflict and update the target field based on the help text mapping
                    if (fieldMapping.hasBadDefaultValues(existingDefaultFieldMapping)) {
                        fieldMapping.setTargetField(fieldMapping.targetFieldAPIName);
                    }

                    queuedMetadataTypesForDeploy.add(fieldMapping.getMetadataRecord());
                }
            }

            fieldMappingsByFieldMappingSetDeveloperName.remove(fieldMappingKey);
        }

        createAndEnqueueNonHelpTextMappings(fieldMappingsByFieldMappingSetDeveloperName);
        createAndEnqueueMigratedCustomFieldMappingSet();
    }

    /*******************************************************************************************************
    * @description Go through all fields in Data Import object and populate relevant lists from help text
    * mappings
    */
    @TestVisible
    private void populateListsFromHelpTextMappings() {

        badHelpTextMappings.clear();
        dataImportFieldMappings.clear();

        List<HelpTextFieldMapping> helpTextFieldMappings = helper.getAllHelpTextFieldMappings();

        for (HelpTextFieldMapping helpTextFieldMapping : helpTextFieldMappings) {

            Boolean isSkippable = DATA_IMPORT_IMPORT_FIELDS.contains(
                helpTextFieldMapping.dataImportFieldAPIName.toLowerCase());

            Boolean isException = false;
            if (helpTextFieldMapping.helpText != null) {
                isException = HELP_TEXT_EXCEPTIONS.contains(helpTextFieldMapping.helpText);
            }

            if (isSkippable || isException) {
                continue;
            }

            if (helpTextFieldMapping.isUsable()) {
                DataImportFieldMapping newDataImportFieldMapping =
                    new DataImportFieldMapping(helpTextFieldMapping);

                dataImportFieldMappings.add(newDataImportFieldMapping);

            } else if (helpTextFieldMapping.isPotentialMapping()) {
                badHelpTextMappings.add(helpTextFieldMapping);
            }
        }
    }

    /*******************************************************************************************************
    * @description Creates the Migrated Custom Field Mapping Set and adds to queuedMetadataTypesForDeploy
    */
    private void createAndEnqueueMigratedCustomFieldMappingSet() {
        if (fieldMappingSetName == DEFAULT_FIELD_MAPPING_SET_RECORD_NAME) {

            DataImportFieldMappingSet fieldMappingSet =
                new DataImportFieldMappingSet(
                    MIGRATED_CUSTOM_FIELD_MAPPING_SET_RECORD_NAME,
                    DEFAULT_OBJECT_MAPPING_SET_RECORD_NAME);

            // Add custom field mapping set to list queuedMetadataTypesForDeploy
            queuedMetadataTypesForDeploy.add(fieldMappingSet.getMetadataRecord());
        }
    }

    /*******************************************************************************************************
    * @description Method for converting non help text mapped standard field mappings to Custom Metadata
    * records and adds to queuedMetadataTypesForDeploy
    *
    * @param fieldMappingSetName String Name of the parent Data Import Field Mapping Set
    */
    private void createAndEnqueueNonHelpTextMappings(
        Map<String, Data_Import_Field_Mapping__mdt> fieldMappings) {

        for (String key : fieldMappings.keySet()) {
            Data_Import_Field_Mapping__mdt existingFieldMapping =
                fieldMappings.get(key);

            DataImportFieldMapping fieldMapping =
                new DataImportFieldMapping(
                    existingFieldMapping,
                    MIGRATED_CUSTOM_FIELD_MAPPING_SET_RECORD_NAME);

            Boolean isUnique =
                fieldMappingSetName == DEFAULT_FIELD_MAPPING_SET_RECORD_NAME ? true : false;

            fieldMapping.setRecordName(
                existingFieldMapping.DeveloperName,
                isUnique);

            queuedMetadataTypesForDeploy.add(fieldMapping.getMetadataRecord());
        }
    }

    /*******************************************************************************************************
    * @description Inserting or Updating CMT's through the Apex Metadata API is an asynchronous process. This callback
    * class is used to handle the async response from the call to Metadata.Operations.enqueueDeployment().
    * An instance of this class gets passed into the deployment call from
    * STG_PanelDataImportAdvancedMapping_CTRL.enableDataImportFieldMapping()
    */
    public class DeploymentCallback implements Metadata.DeployCallback {

        /*******************************************************************************************************
        * @description Method called by salesforce with the result of the Metadata deployment operation status.
        * This will write the status of the deployment to Data Import custom settings
        */
        public void handleResult(Metadata.DeployResult result, Metadata.DeployCallbackContext context) {

            if (result != null && result.status == Metadata.DeployStatus.SUCCEEDED) {
                // Deployment was successful
                BDI_MigrationMappingUtility.updateCustomSettings(DATA_IMPORT_FIELD_MAPPING,
                    String.valueOf(result.status));

            } else if (result != null && result.status != Metadata.DeployStatus.SUCCEEDED) {
                // Deployment was not successful
                String errMsg = '';
                for (Integer n=0; n < result.details.componentFailures.size(); n++) {
                    errMsg += (n > 0 ? '\n' : '') + '* ' + result.details.componentFailures[n].fullName +
                            '> ' + result.details.componentFailures[n].problem;
                }

                BDI_MigrationMappingUtility.updateCustomSettings(HELP_TEXT, errMsg);
                if (!Test.isRunningTest()) {
                    throw new DeploymentException(Label.bdiErrorDeploymentFailed);
                }

            } else {
                // Deployment was not successful and result is null
                BDI_MigrationMappingUtility.updateCustomSettings(HELP_TEXT, 'Unknown error');
                if (!Test.isRunningTest()) {
                    throw new DeploymentException(Label.bdiErrorDeploymentFailed);
                }
            }
        }
    }

    /*******************************************************************************************************
    * @description Wrapper class for Data_Import_Field_Mapping_Set__mdt used to create
    * the custom CMT data as well as for use in the Custom UI.
    */
    public class DataImportFieldMappingSet {
        public String recordName;
        public String label;
        public String dataImportObjectMappingSetRecordName;

        public DataImportFieldMappingSet(String label, String dataImportObjectMappingSetRecordName) {
            this.label = label.trim();
            this.dataImportObjectMappingSetRecordName = dataImportObjectMappingSetRecordName;
        }

        public Metadata.CustomMetadata getMetadataRecord() {
            String mdTypeName = 'Data_Import_Field_Mapping_Set__mdt';

            // Setup custom metadata to be created or updated in the subscriber org.
            Metadata.CustomMetadata customMd = new Metadata.CustomMetadata();
            customMd.label = this.label.left(40);
            this.recordName = this.label;
            customMd.fullName = mdTypeName + '.' + this.recordName.left(40).removeEnd('_');
            customMd.protected_x = false;

            Map<String, Object> fieldValues = new Map<String, Object>{
                'Data_Import_Object_Mapping_Set__c' => this.dataImportObjectMappingSetRecordName
            };
            customMd = CMT_MetadataAPI.addFieldsToMetadataObject(customMd, fieldValues);

            return customMd;
        }
    }

    /*******************************************************************************************************
    * @description Wrapper class for Data_Import_Field_Mapping__mdt used to create
    * the default CMT data as well as for use in the Custom UI.
    */
    public class DataImportFieldMapping {
        public String recordName;
        public String label {get; set;}
        public String dataImportObjectName {get; set;}
        public String dataImportFieldMappingSetRecordName;
        public String dataImportFieldMappingSetLabel;
        public String sourceFieldAPIName;
        public String targetFieldAPIName {get; set;}
        public String targetObjectMappingRecordName;
        public String targetObjectMappingLabel;
        public String targetObjectAPIName;
        public String isRequired;
        public Boolean isDeleted;
        public String importedRecordField;
        public String importedRecordStatusField;

        public DataImportFieldMapping() {}

        public DataImportFieldMapping(HelpTextFieldMapping helpTextMapping) {
            this.label = helpTextMapping.dataImportFieldName.trim();
            this.sourceFieldAPIName = helpTextMapping.dataImportFieldAPIName;
            this.dataImportObjectName = helpTextMapping.dataImportObjectName;
            this.targetFieldAPIName = helpTextMapping.targetFieldAPIName;
            this.targetObjectAPIName = helpTextMapping.targetObjectAPIName;
        }

        public DataImportFieldMapping(
            Data_Import_Field_Mapping__mdt sourceFieldMapping, String fieldMappingSet) {

            this.dataImportFieldMappingSetRecordName = fieldMappingSet;
            this.label = sourceFieldMapping.MasterLabel;
            this.sourceFieldAPIName = sourceFieldMapping.Source_Field_API_Name__c;
            this.targetFieldAPIName = sourceFieldMapping.Target_Field_API_Name__c;
            this.targetObjectMappingRecordName = sourceFieldMapping.Target_Object_Mapping__r.DeveloperName;
            this.targetObjectMappingLabel = sourceFieldMapping.Target_Object_Mapping__r.MasterLabel;
            this.dataImportObjectName = sourceFieldMapping.Target_Object_Mapping__r.DeveloperName;
            this.targetObjectAPIName = sourceFieldMapping.Target_Object_Mapping__r.Object_API_Name__c;
            this.recordName = sourceFieldMapping.DeveloperName;
            this.isRequired = 'No';
            this.isDeleted = false;
        }

        public String getKey() {
            return this.targetObjectAPIName + '.' +
                this.dataImportObjectName + '.' +
                this.sourceFieldAPIName;
        }

        public void setFieldMappingSet(String fieldMappingSetName) {
            this.dataImportFieldMappingSetRecordName = fieldMappingSetName;
        }

        public void setObjectMapping(Data_Import_Object_Mapping__mdt objectMapping) {
            this.targetObjectMappingLabel = objectMapping.Label;
            this.targetObjectMappingRecordName = objectMapping.DeveloperName;
        }

        public void setTargetField(String targetFieldAPIName) {
            this.targetFieldAPIName = targetFieldAPIName;
        }

        public void setRecordName(String recordName, Boolean isUnique) {
            if (isUnique) {
                this.recordName = generateRecordName(
                    this.label,
                    true,
                    this.targetObjectMappingLabel,
                    this.dataImportObjectName);
            } else {
                this.recordName = recordName;
            }
        }

        public Boolean hasBadDefaultValues(Data_Import_Field_Mapping__mdt existingFieldMapping) {
            Boolean badSourceFieldAPIName =
                (existingFieldMapping.Source_Field_API_Name__c != this.sourceFieldAPIName);
            Boolean badTargetFieldAPIName =
                (existingFieldMapping.Target_Field_API_Name__c != this.targetFieldAPIName);
            Boolean badTargetObjectMapping =
                (existingFieldMapping.Target_Object_Mapping__r.DeveloperName !=
                    this.targetObjectMappingRecordName);

            return badSourceFieldAPIName || badTargetFieldAPIName || badTargetObjectMapping;
        }

        public Metadata.CustomMetadata getMetadataRecord() {
            String mdTypeName = 'Data_Import_Field_Mapping__mdt';

            // Setup custom metadata to be created or updated in the subscriber org.
            Metadata.CustomMetadata customMd = new Metadata.CustomMetadata();

            if (this.targetObjectMappingLabel != null && this.dataImportObjectName != null) {
                customMd.label = this.label.replace(
                    this.dataImportObjectName,
                    this.targetObjectMappingLabel).left(40);
            }

            if (this.recordName == null) {
                this.recordName = generateRecordName(
                    this.label,
                    true,
                    this.targetObjectMappingLabel,
                    this.dataImportObjectName);
            }

            customMd.fullName = mdTypeName + '.' + this.recordName.left(40).removeEnd('_');
            customMd.protected_x = false;

            // Convert an empty string ('') value into null for the entity reference to save properly.
            if (String.isEmpty(this.dataImportFieldMappingSetRecordName)) {
                this.dataImportFieldMappingSetRecordName = null;
            }

            // Convert an empty string ('') value into null for the entity reference to save properly.
            if (String.isEmpty(this.targetObjectMappingRecordName)) {
                this.targetObjectMappingRecordName = null;
            }

            Map<String, Object> fieldValues;
            if (this.isDeleted != true) {

                if (NAMESPACE != 'npsp') {
                    this.targetFieldAPIName =
                        UTIL_Namespace.removeNSPrefixNpspOnly(this.targetFieldAPIName);
                }

                fieldValues = new Map<String, Object>{
                    'Data_Import_Field_Mapping_Set__c' => dataImportFieldMappingSetRecordName == null ? 'Default_Field_Mapping_Set' : dataImportFieldMappingSetRecordName,
                    'Required__c' => isRequired,
                    'Source_Field_API_Name__c' => sourceFieldAPIName,
                    'Target_Field_API_Name__c' => targetFieldAPIName,
                    'Target_Object_Mapping__c' => targetObjectMappingRecordName,
                    'Is_Deleted__c' => isDeleted
                };
            } else {
                fieldValues = new Map<String, Object>{ 'Is_Deleted__c' => isDeleted };
            }
            customMd = CMT_MetadataAPI.addFieldsToMetadataObject(customMd, fieldValues);

            return customMd;
        }

        /****************************************************************************************************
        * @description Utility to convert a name into a valid 'DeveloperName' quality value (or unique GUID)
        * for the CMT record
        *
        * @param name String
        * @param makeUnique Boolean
        * @return DeveloperName format string
        */
        private String generateRecordName(String name, Boolean makeUnique, String objectLabel, String objectAPIName) {

            if (String.isNotBlank(objectLabel)) {
                objectLabel = objectLabel.replace(' ', '_');
                name = name.replace(objectAPIName, objectLabel);
            }

            if (name.length() > 30) {
                String firstFifteen = name.substring(0, 15);
                String lastFifteen = name.substring(name.length() - 15, name.length());
                name = firstFifteen + lastFifteen;
            }

            if (makeUnique == true) {
                // Create a GUID format unique string
                Blob b = Crypto.GenerateAESKey(128);
                String h = EncodingUtil.ConvertTohex(b);
                // force everything to have a 9-char random string at the end
                name = name.left(30).removeEnd('_') + '_' + h.left(9);
            } else {
                name = name.left(40);
            }

            name = name.replaceAll('[^\\w]+', '_').replaceAll('_{2,}', '_');
            return name;
        }
    }

    /*******************************************************************************************************
    * @description Wrapper class for help text field
    */
    public class HelpTextFieldMapping {
        public Boolean isUsable = false;
        public Boolean isPotentialMapping = false;
        private Boolean isFieldNameUsable = false;
        private Boolean isObjectNameUsable = false;
        private Boolean isObjectAPINameUsable = false;
        public String dataImportObjectName;
        public String targetObjectAPIName;
        public String targetFieldAPIName;
        public String dataImportFieldName { get;set; }
        public String dataImportFieldAPIName { get;set; }
        public String helpText { get;set; }

        public HelpTextFieldMapping() {}

        public HelpTextFieldMapping(Schema.DescribeFieldResult dfr) {
            this.dataImportFieldName = dfr.Label;
            this.dataImportFieldAPIName = dfr.Name;
            this.helpText = dfr.getInlineHelpText();

            if (this.helpText != null) {
                List<String> parts = helpText.split('\\.', 2);
                this.dataImportObjectName = String.isNotBlank(parts[0]) ? parts[0] : null;
                this.targetFieldAPIName = String.isNotBlank(parts[1]) ? parts[1] : null;

                if (NAMESPACE != 'npsp') {
                    this.targetFieldAPIName =
                        UTIL_Namespace.removeNSPrefixNpspOnly(this.targetFieldAPIName);
                }

                checkRequiredFields();
            }
        }

        private void checkRequiredFields() {
            this.isFieldNameUsable = String.isNotBlank(this.targetFieldAPIName);
            this.isObjectNameUsable = String.isNotBlank(this.dataImportObjectName);
            if (String.isNotBlank(this.dataImportObjectName)) {
                this.targetObjectAPIName = DI_OBJECT_MAP.get(this.dataImportObjectName);
            }
            this.isObjectAPINameUsable = String.isNotBlank(this.targetObjectAPIName);
        }

        private Boolean isUsable() {
            if (Test.isRunningTest()) {
                checkRequiredFields();
            }
            return this.isFieldNameUsable && this.isObjectNameUsable && this.isObjectAPINameUsable;
        }

        private Boolean isPotentialMapping() {
            if (Test.isRunningTest()) {
                checkRequiredFields();
            }
            return this.isFieldNameUsable && this.isObjectNameUsable && !this.isObjectAPINameUsable;
        }

        /****************************************************************************************************
        * @description Map of legacy help text field data import object names to object api names
        */
        private final Map<String, String> DI_OBJECT_MAP = new Map<String, String>{
            'Account1' => 'Account',
            'Account2' => 'Account',
            'Address' => UTIL_Namespace.StrTokenNSPrefix('Address__c'),
            'Contact1' => 'Contact',
            'Contact2' => 'Contact',
            'Household' => 'Account',
            'Opportunity' => 'Opportunity',
            'Donation' => 'Opportunity',
            'Payment' => 'npe01__OppPayment__c'
        };
    }

    /*******************************************************************************************************
    * @description an exception object wrapper for migration utility
    */
    private class DeploymentException extends Exception {}

} // BDI_MigrationMappingUtility