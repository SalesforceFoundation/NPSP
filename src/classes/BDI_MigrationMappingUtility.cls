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
    private static final String DEFAULT_OBJECT_MAPPING_SET_RECORD_NAME =
        'Default_Object_Mapping_Set';

    /*******************************************************************************************************
    * @description Name of default packaged Field Mapping Set
    * Set as static because it's used in the static method updateCustomSettings
    */
    public static final String DEFAULT_FIELD_MAPPING_SET_RECORD_NAME =
        'Default_Field_Mapping_Set';

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
    public static final String DATA_IMPORT_FIELD_MAPPING =
        'Data Import Field Mapping';

    /*******************************************************************************************************
    * @description Value for Data Import Custom Setting's Field Mapping Method.
    * Set as static because it's used in the static method updateCustomSettings
    */
    public static final String HELP_TEXT =
        'Help Text';

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
    public List<HelpTextFieldMapping> badHelpTextMappings {
        get {
            if (badHelpTextMappings == null) {
                return new List<HelpTextFieldMapping>();
            }
            return badHelpTextMappings;
        } set;
    }

    private String fieldMappingSetName {
        get {
            if (helper.customFieldMappingSetExists) {
                return MIGRATED_CUSTOM_FIELD_MAPPING_SET_RECORD_NAME;
            }
            return DEFAULT_FIELD_MAPPING_SET_RECORD_NAME;
        }
    }

    /*******************************************************************************************************
    * @description Constructor for Migration Mapping Utility class
    * @param helper Instance of BDI_MigrationMappingHelper
    */
    public BDI_MigrationMappingUtility(BDI_MigrationMappingHelper helper) {
        this.helper = helper;
        this.dataImportSettings = UTIL_CustomSettingsFacade.getDataImportSettings();
        this.objectMappingsByDeveloperName =
            helper.getObjectMappingsByDeveloperName(helper.getDefaultObjectMappingSet().Id);
    }

    /*******************************************************************************************************
    * @description Updates Data Import custom settings.
    * Static because it's used in static inner class DeploymentCallback and in STG_PanelDataImportAdvancedMapping_CTRL
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

        if (helper.customFieldMappingSetExists == true) {
            dataImportSettings.Default_Data_Import_Field_Mapping_Set__c = MIGRATED_CUSTOM_FIELD_MAPPING_SET_RECORD_NAME;
        } else {
            dataImportSettings.Default_Data_Import_Field_Mapping_Set__c = DEFAULT_FIELD_MAPPING_SET_RECORD_NAME;
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
    * @description Collect and inspect existing field mappings and mappings found from Help Text and
    * add mappings to appropriate lists (pendingMappings, conflictingMappings, pendingStandardMappings,
    * pendingNonHelpTextMappings)
    */
    public void migrateHelpTextToCustomMetadata() {

        queuedMetadataTypesForDeploy.clear();
        badHelpTextMappings.clear();

        helper.populateListsFromHelpTextMappings();

        List<BDI_FieldMappingHelpText.DataImportFieldMapping> helpTextFieldMappings =
                helper.getDataImportFieldMappingsFromHelpText();

        Map<String, Data_Import_Field_Mapping__mdt> fieldMappingsByFieldMappingSetDeveloperName =
            helper.getFieldMappingsByFieldMappingSetDeveloperName(fieldMappingSetName);

        for (BDI_FieldMappingHelpText.DataImportFieldMapping fieldMapping : helpTextFieldMappings) {

            String fieldMappingKey = fieldMapping.targetObjectAPIName +
                '.' + fieldMapping.dataImportObjectName +
                '.' + fieldMapping.sourceFieldAPIName;

            Data_Import_Object_Mapping__mdt existingDefaultObjectMapping =
                objectMappingsByDeveloperName.get(fieldMapping.dataImportObjectName);
            Data_Import_Field_Mapping__mdt existingDefaultFieldMapping =
                fieldMappingsByFieldMappingSetDeveloperName.get(fieldMappingKey);

            if (existingDefaultFieldMapping == null) {
                enqueueNewFieldMapping(fieldMapping, existingDefaultObjectMapping);
            } else if (existingDefaultFieldMapping != null) {

                if (helper.customFieldMappingSetExists) {
                    enqueueOverwrittenFieldMapping(fieldMapping, existingDefaultFieldMapping, existingDefaultObjectMapping);
                } else {
                    enqueueFieldMapping(fieldMapping, existingDefaultFieldMapping, existingDefaultObjectMapping);
                }
            }

            fieldMappingsByFieldMappingSetDeveloperName.remove(fieldMappingKey);
        }

        enqueueNonHelpTextMappings(fieldMappingsByFieldMappingSetDeveloperName);
        enqueueMigratedCustomFieldMappingSet();
        badHelpTextMappings = helper.badhelpTextMappings;
    }

    /*******************************************************************************************************
    * @description Converts DataImportFieldMapping into a Custom Metadata record and called when we have
    * a conflict and need to carryover values from the help text mapping or a standard field mapping and
    * need to carryover values from the existingDefaultFieldMapping
    *
    * @param fieldMapping: DataImportFieldMapping that will be converted to a Custom Metadata Record
    * @param existingDefaultFieldMapping: Corresponding standard Data_Import_Field_Mapping__mdt
    * @param existingDefaultObjectMapping: Corresponding standard Data_Import_Object_Mapping__mdt
    */
    private void enqueueFieldMapping(BDI_FieldMappingHelpText.DataImportFieldMapping fieldMapping,
        Data_Import_Field_Mapping__mdt existingDefaultFieldMapping,
        Data_Import_Object_Mapping__mdt existingDefaultObjectMapping) {
        // Existing Field Mapping, check if CMTs field values match Help Text field values
        Boolean hasConflictingValues = isConflictingWithStandardFieldMapping(fieldMapping,
                existingDefaultFieldMapping,
                existingDefaultObjectMapping);

        if (hasConflictingValues) {
            fieldMapping.setLookupsAndTargetField(
                existingDefaultObjectMapping,
                MIGRATED_CUSTOM_FIELD_MAPPING_SET_RECORD_NAME,
                fieldMapping.targetFieldAPIName);
        } else {
            System.debug('Existing Mapping + Standard');
            fieldMapping.setLookupsAndTargetField(
                existingDefaultObjectMapping,
                MIGRATED_CUSTOM_FIELD_MAPPING_SET_RECORD_NAME,
                null);
        }

        queuedMetadataTypesForDeploy.add(fieldMapping.getMetadataRecord());
    }

    /*******************************************************************************************************
    * @description Converts DataImportFieldMapping into a Custom Metadata record and called when we have
    * an existing Migrated Custom Field Mapping Set and need DataImportFieldMapping to overwrite the
    * existingDefaultFieldMapping
    *
    * @param fieldMapping: DataImportFieldMapping that will be converted to a Custom Metadata Record
    * and overwrite the existingDefaultFieldMapping
    * @param existingDefaultFieldMapping: Corresponding standard Data_Import_Field_Mapping__mdt
    * @param existingDefaultObjectMapping: Corresponding standard Data_Import_Object_Mapping__mdt
    */
    private void enqueueOverwrittenFieldMapping(BDI_FieldMappingHelpText.DataImportFieldMapping fieldMapping,
        Data_Import_Field_Mapping__mdt existingDefaultFieldMapping,
        Data_Import_Object_Mapping__mdt existingDefaultObjectMapping) {
        // Migrated custom field mapping set exists, overwrite all existing field mappings
        // with values from help text
        BDI_FieldMappingHelpText.DataImportFieldMapping overwrittenMapping =
            new BDI_FieldMappingHelpText.DataImportFieldMapping(existingDefaultFieldMapping, MIGRATED_CUSTOM_FIELD_MAPPING_SET_RECORD_NAME);
        overwrittenMapping.setLookupsAndTargetField(
            existingDefaultObjectMapping,
            MIGRATED_CUSTOM_FIELD_MAPPING_SET_RECORD_NAME,
            fieldMapping.targetFieldAPIName);

        queuedMetadataTypesForDeploy.add(overwrittenMapping.getMetadataRecord());
    }

    /*******************************************************************************************************
    * @description Converts DataImportFieldMapping into a Custom Metadata record and called when we
    * encounter a new field mapping from help text and need a new record
    *
    * @param fieldMapping: DataImportFieldMapping that will be converted to a Custom Metadata Record
    * @param existingDefaultFieldMapping: Corresponding standard Data_Import_Field_Mapping__mdt
    * @param existingDefaultObjectMapping: Corresponding standard Data_Import_Object_Mapping__mdt
    */
    private void enqueueNewFieldMapping(BDI_FieldMappingHelpText.DataImportFieldMapping fieldMapping,
        Data_Import_Object_Mapping__mdt existingDefaultObjectMapping) {
        fieldMapping.setLookupsAndTargetField(existingDefaultObjectMapping,
            MIGRATED_CUSTOM_FIELD_MAPPING_SET_RECORD_NAME,
            null);
        // Setting name to null will force field mapping to generate a unique name
        fieldMapping.setRecordName(null, false);

        queuedMetadataTypesForDeploy.add(fieldMapping.getMetadataRecord());
    }

    /*******************************************************************************************************
    * @description Creates the Migrated Custom Field Mapping Set
    */
    private void enqueueMigratedCustomFieldMappingSet() {
        if (helper.customFieldMappingSetExists == false) {
            // Create migrated field mapping set
            Metadata.CustomMetadata fieldMappingSet =
                createNewFieldMappingSet(MIGRATED_CUSTOM_FIELD_MAPPING_SET_RECORD_NAME);

            // Add custom field mapping set to list queuedMetadataTypesForDeploy
            queuedMetadataTypesForDeploy.add(fieldMappingSet);
        }
    }

    /*******************************************************************************************************
    * @description Method for converting non help text mapped standard field mappings to
    * instances of BDI_FieldMappingHelpText.DataImportFieldMapping so that we can update field values
    * and add to the deployment with the other custom metadata records
    * standard field mappings
    *
    * @param fieldMappingSetName String Name of the parent Data Import Field Mapping Set
    */
    private void enqueueNonHelpTextMappings(Map<String, Data_Import_Field_Mapping__mdt> fieldMappings) {

        for (String key : fieldMappings.keySet()) {
            Data_Import_Field_Mapping__mdt existingFieldMapping =
                fieldMappings.get(key);

            BDI_FieldMappingHelpText.DataImportFieldMapping fieldMapping =
                new BDI_FieldMappingHelpText.DataImportFieldMapping(existingFieldMapping,
                    MIGRATED_CUSTOM_FIELD_MAPPING_SET_RECORD_NAME);

            fieldMapping.setRecordName(existingFieldMapping.DeveloperName, !helper.customFieldMappingSetExists); 

            queuedMetadataTypesForDeploy.add(fieldMapping.getMetadataRecord());
        }
    }

    /*******************************************************************************************************
    * @description Check if Field Mapping Metadata Type field values are out of sync with standard data import
    * field mapping values
    *
    * @return Boolean
    */
    private Boolean isConflictingWithStandardFieldMapping(BDI_FieldMappingHelpText.DataImportFieldMapping newFieldMapping,
        Data_Import_Field_Mapping__mdt existingFieldMapping,
        Data_Import_Object_Mapping__mdt existingDefaultObjectMapping) {

        Boolean badSourceFieldAPIName =
            (existingFieldMapping.Source_Field_API_Name__c != newFieldMapping.sourceFieldAPIName);
        Boolean badTargetFieldAPIName =
            (existingFieldMapping.Target_Field_API_Name__c != newFieldMapping.targetFieldAPIName);
        Boolean badTargetObjectMappingId =
            (existingFieldMapping.Target_Object_Mapping__c != existingDefaultObjectMapping.Id);

        Boolean foundMismatch = badSourceFieldAPIName
            || badTargetFieldAPIName
            || badTargetObjectMappingId;

        return foundMismatch;
    }

    /*******************************************************************************************************
    * @description Creates a new Field Mapping Set to be used as the new set when migration utility
    * encounters a help text mapping customization and user opts to keep their customization
    * @return Data_Import_Field_Mapping_Set__mdt
    */
    public Metadata.CustomMetadata createNewFieldMappingSet(String fieldMappingName) {
        BDI_FieldMappingHelpText.DataImportFieldMappingSet fieldMappingSet =
            new BDI_FieldMappingHelpText.DataImportFieldMappingSet(fieldMappingName, DEFAULT_OBJECT_MAPPING_SET_RECORD_NAME);

        return fieldMappingSet.getMetadataRecord();
    }

    /*******************************************************************************************************
    * @description Inserting or Updating CMT's through the Apex Metadata API is an asynchronous process. This callback
    * class is used to handle the async response from the call to Metadata.Operations.enqueueDeployment().
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
    * @description Wrapper class for help text field
    */
    public class HelpTextFieldMapping {
        public Boolean isUsable = false;
        public Boolean isPotentialMapping = false;
        public String dataImportObjectName;
        public String targetObjectAPIName;
        public String targetFieldAPIName;
        public String dataImportFieldName { get;set; }
        public String dataImportFieldAPIName { get;set; }
        public String helpText { get;set; }

        public HelpTextFieldMapping(Schema.DescribeFieldResult dfr) {

            this.dataImportFieldName = dfr.Label;
            this.dataImportFieldAPIName = dfr.Name;
            this.helpText = dfr.getInlineHelpText();
            if (this.helpText != null) {
                List<String> parts = helpText.split('\\.', 2);
                this.dataImportObjectName = String.isNotBlank(parts[0]) ? parts[0] : null;
                this.targetFieldAPIName = String.isNotBlank(parts[1]) ? parts[1] : null;

                if (String.isNotBlank(this.dataImportObjectName)) {
                    this.targetObjectAPIName = DI_OBJECT_MAP.get(this.dataImportObjectName);
                }

                Boolean fieldNameIsUsable = String.isNotBlank(targetFieldAPIName);
                Boolean objectNameIsUsable = String.isNotBlank(dataImportObjectName);
                Boolean objectAPINameIsUsable = String.isNotBlank(targetObjectAPIName);

                if (fieldNameIsUsable && objectNameIsUsable && objectAPINameIsUsable) {
                    this.isUsable = true;
                } else if (fieldNameIsUsable && objectNameIsUsable && !objectAPINameIsUsable) {
                    this.isPotentialMapping = true;
                }
            }
        }

        /*******************************************************************************************************
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