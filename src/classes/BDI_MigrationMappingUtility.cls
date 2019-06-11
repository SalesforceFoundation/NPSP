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

    /**
    * @description Metadata queued up for deployment
    */
    public List<Metadata.CustomMetadata> queuedMetadataTypesForDeploy =
        new List<Metadata.CustomMetadata>();

    /*
    * @description List of help text mappings that conflicts with our packaged default custom metatadata type mappings
    */
    @TestVisible
    private List<BDI_HelpTextCMT.DataImportFieldMapping> conflictingMappings =
        new List<BDI_HelpTextCMT.DataImportFieldMapping>();

    /*
    * @description List of custom metatadata type mappings pending deployment
    */
    @TestVisible
    private List<BDI_HelpTextCMT.DataImportFieldMapping> pendingMappings =
        new List<BDI_HelpTextCMT.DataImportFieldMapping>();

    /**
    * @description List of standard mappings
    */
    @TestVisible
    private List<BDI_HelpTextCMT.DataImportFieldMapping> pendingStandardMappings =
        new List<BDI_HelpTextCMT.DataImportFieldMapping>();

    /**
    * @description List of special cased mappings (GAU and Opportunity)
    */
    @TestVisible
    private List<BDI_HelpTextCMT.DataImportFieldMapping> pendingNonHelpTextMappings =
        new List<BDI_HelpTextCMT.DataImportFieldMapping>();

    /**
    * @description Name of default packaged Field Mapping Set
    * Set as static because it's used in the static method updateCustomSettings
    */
    public static final String DEFAULT_FIELD_MAPPING_SET_RECORD_NAME =
        'Default_Field_Mapping_Set';

    /**
    * @description Name of custom Field Mapping Set
    * Set as static because it's used in the static method updateCustomSettings
    */
    public static final String MIGRATED_CUSTOM_FIELD_MAPPING_SET_RECORD_NAME =
        'Migrated_Custom_Field_Mapping_Set';

    /**
    * @description Value for Data Import custom settings Field Mapping Method
    * Set as static because it's used in the static method updateCustomSettings
    */
    public static final String DATA_IMPORT_FIELD_MAPPING =
        'Data Import Field Mapping';

    /**
    * @description Value for Data Import Custom Setting's Field Mapping Method.
    * Set as static because it's used in the static method updateCustomSettings
    */
    public static final String HELP_TEXT =
        'Help Text';

    /**
    * @description Default packaged Field Mapping Set metadata record
    */
    private static final Data_Import_Field_Mapping_Set__mdt DEFAULT_FIELD_MAPPING_SET = [SELECT
            Id,
            DeveloperName,
            Label
        FROM Data_Import_Field_Mapping_Set__mdt
        WHERE DeveloperName = :DEFAULT_FIELD_MAPPING_SET_RECORD_NAME];

    /**
    * @description Boolean flag to determine if a custom field mapping set exists 
    * Set as static because it's used in the static method updateCustomSettings
    */
    public static Boolean customFieldMappingSetExists {
        get {
            List<Data_Import_Field_Mapping_Set__mdt> fieldMappingSets = [SELECT Id
                FROM Data_Import_Field_Mapping_Set__mdt
                WHERE DeveloperName = :MIGRATED_CUSTOM_FIELD_MAPPING_SET_RECORD_NAME];
            if (fieldMappingSets.size() > 0) {
                return true;
            }
            return false;
        }
        set;
    }

    /**
     * @description Metadata deployment id
     */
    public String deploymentId;

    /**
     * @description Helper class that supports BDI_MigrationMappingUtility and enables mocking of test data.
     */
    private BDI_MigrationMappingHelper helper;

    /**
     * @description Custom Setting record where we set cmt api deployment status, cmt deployment id,
     * field mapping method, and default data import field mapping set.
     */
    private Data_Import_Settings__c dataImportSettings;

    /**
     * @description Constructor for Migration Mapping Utility class
     * @param helper Instance of BDI_MigrationMappingHelper
     */
    public BDI_MigrationMappingUtility(BDI_MigrationMappingHelper helper) {
        this.helper = helper;
        this.dataImportSettings = UTIL_CustomSettingsFacade.getDataImportSettings();
    }

    /**
     * @description Initiate a deployment of custom metadata type records
     * or update custom settings if there are no records to deploy.
     * @return Metadata deployment id
     */
    public String deployCustomMetadata() {

        try {
            If (queuedMetadataTypesForDeploy.size() > 0) {
                Metadata.DeployContainer deploymentContainer = new Metadata.DeployContainer();

                for (Metadata.CustomMetadata customMetadataRecord : queuedMetadataTypesForDeploy) {
                    deploymentContainer.addMetadata(customMetadataRecord);
                }

                if (Test.isRunningTest()) {
                    deploymentId = '123';
                } else {
                    deploymentId = Metadata.Operations.enqueueDeployment(deploymentContainer,
                        new DeploymentCallback());
                }
            } else {
                BDI_MigrationMappingUtility.updateCustomSettings(DATA_IMPORT_FIELD_MAPPING,
                    String.valueOf(Metadata.DeployStatus.SUCCEEDED));
            }
        } catch (Exception e) {
            throw new DeploymentException(Label.bdiErrorDeploymentFailed + ' ' + e.getMessage());
        }

        clearLists();

        return deploymentId;
    }

    /**
     * @description Updates Data Import custom settings
     * @param fieldMappingMethod String that determines what data import field mapping method
     * to use (i.e. help text, custom metadata)
     * @param status Deployment status
     *
     * Set as static because it's used in a couple different contexts, inner class DeploymentCallback and
     * STG_PanelDataImportAdvancedMapping_CTRL
     */
    public static Data_Import_Settings__c updateCustomSettings(String fieldMappingMethod, String status) {

        Data_Import_Settings__c dataImportSettings = UTIL_CustomSettingsFacade.getDataImportSettings();
        dataImportSettings.Field_Mapping_Method__c = fieldMappingMethod;

        if (BDI_MigrationMappingUtility.customFieldMappingSetExists == true) {
            dataImportSettings.Default_Data_Import_Field_Mapping_Set__c = MIGRATED_CUSTOM_FIELD_MAPPING_SET_RECORD_NAME;
        } else {
            dataImportSettings.Default_Data_Import_Field_Mapping_Set__c = DEFAULT_FIELD_MAPPING_SET_RECORD_NAME;
        }

        Map<String, String> statusMap = new Map<String, String>();

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

    /**
     * @description Inserting or Updating CMT's through the Apex Metadata API is an asynchronous process. This callback
     * class is used to handle the async response from the call to Metadata.Operations.enqueueDeployment().
     */
    public class DeploymentCallback implements Metadata.DeployCallback {

        /**
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

    /**
    * @description Method fills various field mapping lists that we later deploy as needed.
    * pendingMappings, conflictingMappings, pendingStandardMappings.
    */
    public void startMigration() {

        if (BDI_MigrationMappingUtility.customFieldMappingSetExists == true) {
            // Inspects help text mappings, compares against migrated field mapping set, and
            // parks cmt records in various lists (pendingMappings, pendingStandardMappings, etc)
            buildCustomMetadataRecordsFromHelpText(MIGRATED_CUSTOM_FIELD_MAPPING_SET_RECORD_NAME);
        } else {
            // Inspects help text mappings, compares against default field mapping set, and
            // parks cmt records in various lists (pendingMappings, pendingStandardMappings, etc)
            buildCustomMetadataRecordsFromHelpText(DEFAULT_FIELD_MAPPING_SET_RECORD_NAME);

            // Create migrated field mapping set
            Metadata.CustomMetadata fieldMappingSet =
                helper.createNewFieldMappingSet(MIGRATED_CUSTOM_FIELD_MAPPING_SET_RECORD_NAME);

            // Add custom field mapping set to list queuedMetadataTypesForDeploy
            queuedMetadataTypesForDeploy.add(fieldMappingSet);
        }

        // Add standard field mappings to list queuedMetadataTypesForDeploy
        handleStandardMappings();

        // Add net new field mappings to list queuedMetadataTypesForDeploy
        handleNewMappings();

        // Add conflicting mappings to list queuedMetadataTypesForDeploy
        // If we had a conflict with an existing CMT record, we overwrite that existing record
        handleConflictingMappings(conflictingMappings);

        // Add non help text mapped standard mappings
        handleNonHelpTextMappedMappings();
    }

    /**
    * @description Handles list of non help text mapped standard mappings (pendingNonHelpTextMappings),
    * converts them to custom metadata type, and adds them to list of
    * custom metadata types (queuedMetadataTypesForDeploy)
    */
    public void handleNonHelpTextMappedMappings() {
        if (customFieldMappingSetExists) {
            handleConflictingMappings(pendingNonHelpTextMappings);
        } else {
            enqueueFieldMappings(pendingNonHelpTextMappings);
        }
    }

    /**
    * @description Handles list of standard mappings (pendingStandardMappings), converts them to custom metadata type
    * records, and adds them to list of custom metadata types (queuedMetadataTypesForDeploy)
    */
    public void handleStandardMappings() {
        if (BDI_MigrationMappingUtility.customFieldMappingSetExists == false) {
            enqueueFieldMappings(pendingStandardMappings);
        }
    }

    /**
    * @description Handles list of new mappings (pendingMappings), converts them to custom metadata type
    * records, and adds them to list of custom metadata types (queuedMetadataTypesForDeploy)
    */
    public void handleNewMappings() {
        enqueueFieldMappings(pendingMappings);
    }

    /**
    * @description Add metadata records to queuedMedataTypesForDeploy list.
    * @param fieldMappings List of DataImportFieldMapping wrappers
    */
    public void enqueueFieldMappings(List<BDI_HelpTextCMT.DataImportFieldMapping> fieldMappings) {
        if (fieldMappings.size() > 0) {
            for (BDI_HelpTextCMT.DataImportFieldMapping fieldMapping : fieldMappings) {
                fieldMapping.dataImportFieldMappingSetRecordName =
                    MIGRATED_CUSTOM_FIELD_MAPPING_SET_RECORD_NAME;

                queuedMetadataTypesForDeploy.add(fieldMapping.getMetadataRecord());
            }
        }
    }

    /**
    * @description Handles list of conflicting mappings (conflictingMappings).
    * If custom metadata record exists, overwrite values.
    * If custom metadata record doesn't exist, clone existing record with help text values.
    * @param mappings List of BDI_HelpTextCMT.DataImportFieldMappings
    */
    public void handleConflictingMappings(List<BDI_HelpTextCMT.DataImportFieldMapping> mappings) {
        if (mappings.size() > 0) {
            List<BDI_HelpTextCMT.DataImportFieldMapping> updatedConflictingMappings =
                new List<BDI_HelpTextCMT.DataImportFieldMapping>();

            for (BDI_HelpTextCMT.DataImportFieldMapping dataImportFieldMapping : mappings) {
                Boolean isDefaultFieldMappingSet =
                    dataImportFieldMapping.dataImportFieldMappingSetRecordName == DEFAULT_FIELD_MAPPING_SET_RECORD_NAME;

                if (isDefaultFieldMappingSet) {
                    BDI_HelpTextCMT.DataImportFieldMapping clonedFieldMapping =
                        new BDI_HelpTextCMT.DataImportFieldMapping(dataImportFieldMapping,
                            MIGRATED_CUSTOM_FIELD_MAPPING_SET_RECORD_NAME);
                        queuedMetadataTypesForDeploy.add(clonedFieldMapping.getMetadataRecord());
                } else {
                    updatedConflictingMappings.add(dataImportFieldMapping);
                }
            }

            String fieldMappingSetToCompareAgainst;
            if (BDI_MigrationMappingUtility.customFieldMappingSetExists == true) {
                fieldMappingSetToCompareAgainst = MIGRATED_CUSTOM_FIELD_MAPPING_SET_RECORD_NAME;
            } else {
                fieldMappingSetToCompareAgainst = DEFAULT_FIELD_MAPPING_SET_RECORD_NAME;
            }

            List<Metadata.CustomMetadata> updatedCMTs = updateCustomMetadataRecords(fieldMappingSetToCompareAgainst,
                updatedConflictingMappings);

            queuedMetadataTypesForDeploy.addAll(updatedCMTs);
        }
    }

    /**
    * @description Method updates existing custom metadata records in memory.
    * @param fieldMappingSetName Name of parent Field Mapping Set
    * @param fieldMappings List of field mappings with new field values we want to keep
    * @return List of custom metadata type records
    */
    public List<Metadata.CustomMetadata> updateCustomMetadataRecords(
        String fieldMappingSetName,
        List<BDI_HelpTextCMT.DataImportFieldMapping> fieldMappings) {

        Map<String, Data_Import_Field_Mapping__mdt> fieldMappingsByFieldMappingSetDeveloperName =
            helper.getFieldMappingsByFieldMappingSetDeveloperName(fieldMappingSetName);
        List<Metadata.CustomMetadata> updatedCMTs = new List<Metadata.CustomMetadata>();

        for (BDI_HelpTextCMT.DataImportFieldMapping fieldMapping : fieldMappings) {
            Data_Import_Field_Mapping__mdt existingDefaultFieldMapping =
                fieldMappingsByFieldMappingSetDeveloperName.get(fieldMapping.targetObjectAPIName
                    + '.'
                    + fieldMapping.targetObjectMappingRecordName
                    + '.'
                    + fieldMapping.sourceFieldAPIName);

            Metadata.CustomMetadata updatedCMT = fieldMapping.getMetadataRecord();
            List<String> nameParts = updatedCMT.fullName.split('\\.', 2);
            updatedCMT.fullName = nameParts[0] + '.' + existingDefaultFieldMapping.DeveloperName;
            updatedCMTs.add(updatedCMT);
        }

        return updatedCMTs;
    }

    /**
     * @description Collect all Help Text field mappings and compare against default Field Mapping Metadata Type
     * records reserve all non-standard NPSP Help Text mappings. Add new custom mappings to list pendingMappings
     * and add conflicting existing mappings to list conflictingMappings
     */
    public void buildCustomMetadataRecordsFromHelpText(String fieldMappingSetName) {

        clearLists();

        Map<String, BDI_HelpTextCMT.MappingDetail> mappingDetailsBySourceFieldName =
                helper.getAllMappingDetailsBySourceFieldName();

        Map<String, Data_Import_Object_Mapping__mdt> objectMappingsByDeveloperName =
                helper.getObjectMappingsByDeveloperName(helper.getDefaultObjectMappingSet().Id);

        Map<String, Data_Import_Field_Mapping__mdt> fieldMappingsByFieldMappingSetDeveloperName =
                helper.getFieldMappingsByFieldMappingSetDeveloperName(fieldMappingSetName);

        for (String key : mappingDetailsBySourceFieldName.keySet()) {
            BDI_HelpTextCMT.DataImportFieldMapping fieldMapping = 
                new BDI_HelpTextCMT.DataImportFieldMapping(key, mappingDetailsBySourceFieldName.get(key));

            String fieldMappingKey = fieldMapping.targetObjectAPIName
                + '.'
                + fieldMapping.dataImportObjectName
                + '.'
                + fieldMapping.sourceFieldAPIName;

            Data_Import_Object_Mapping__mdt existingDefaultObjectMapping = 
                objectMappingsByDeveloperName.get(fieldMapping.dataImportObjectName);

            Boolean foundDefaultObjectMapping = (existingDefaultObjectMapping != null);

            if (foundDefaultObjectMapping) {
                Data_Import_Field_Mapping__mdt existingDefaultFieldMapping = 
                    fieldMappingsByFieldMappingSetDeveloperName.get(fieldMappingKey);

                Boolean foundDefaultFieldMapping = (existingDefaultFieldMapping != null);

                if (!foundDefaultFieldMapping) {
                    // New Field Mapping, not part of our initial config
                    setFieldMappingValues(fieldMapping, existingDefaultObjectMapping, null);

                    // Add metadata record to queue for deployment
                    pendingMappings.add(fieldMapping);

                } else if (foundDefaultFieldMapping) {
                    // Existing Field Mapping, check if CMTs field values match Help Text field values
                    Boolean invalidFieldMapping = foundDefaultFieldMappingMismatch(fieldMapping, 
                            existingDefaultFieldMapping, 
                            existingDefaultObjectMapping);

                    setFieldMappingValues(fieldMapping,
                            existingDefaultObjectMapping, 
                            existingDefaultFieldMapping);

                    if (invalidFieldMapping) {
                        // If existing help text mapping doesn't match our packaged cmt record, park the mapping
                        fieldMapping.expectedHelpTextValue =
                            existingDefaultFieldMapping.Target_Object_Mapping__r.Object_API_Name__c
                            + '.'
                            + existingDefaultFieldMapping.Target_Field_API_Name__c;

                        conflictingMappings.add(fieldMapping);

                    } else {
                        pendingStandardMappings.add(fieldMapping);
                    }
                    fieldMappingsByFieldMappingSetDeveloperName.remove(fieldMappingKey);
                }
            }
        }

        collectNonHelpTextStandardMappings(fieldMappingsByFieldMappingSetDeveloperName, fieldMappingSetName);
    }

    /**
     * @description Method for converting non help text mapped standard field mappings to
     * instances of BDI_HelpTextCMT.DataImportFieldMapping so that we can update field values
     * and add to the deployment with the other custom metadata records
     * @param fieldMappingsByFieldMappingSetDeveloperName List of non help text mapped
     * standard field mappings
     * @param fieldMappingSetName String Name of the parent Data Import Field Mapping Set
     */
    private void collectNonHelpTextStandardMappings(
        Map<String, Data_Import_Field_Mapping__mdt> fieldMappingsByFieldMappingSetDeveloperName,
        String fieldMappingSetName) {

        for (String key : fieldMappingsByFieldMappingSetDeveloperName.keySet()) {
            pendingNonHelpTextMappings.add(
                new BDI_HelpTextCMT.DataImportFieldMapping(
                    fieldMappingsByFieldMappingSetDeveloperName.get(key),
                    fieldMappingSetName));
        }
    }

    /**
     * @description Set the record and lookup names for the default object and field mappings
     * @param fieldMapping Current instance of DataImportFieldMapping wrapper
     * @param existingDefaultObjectMapping Corresponding Data_Import_Object_Mapping__mdt
     * @param existingDefaultFieldMapping Corresponding Data_Import_Field_Mapping__mdt
     */
    private void setFieldMappingValues(
        BDI_HelpTextCMT.DataImportFieldMapping fieldMapping,
        Data_Import_Object_Mapping__mdt existingDefaultObjectMapping,
        Data_Import_Field_Mapping__mdt existingDefaultFieldMapping) {

        fieldMapping.targetObjectMappingLabel = existingDefaultObjectMapping.Label;
        fieldMapping.targetObjectMappingRecordName = existingDefaultObjectMapping.DeveloperName;

        if (fieldMapping.dataImportFieldMappingSetRecordName == null) {
            fieldMapping.dataImportFieldMappingSetLabel = DEFAULT_FIELD_MAPPING_SET.Label;
            fieldMapping.dataImportFieldMappingSetRecordName = DEFAULT_FIELD_MAPPING_SET.DeveloperName;
        }

        if (existingDefaultFieldMapping != null) {
            fieldMapping.recordName = existingDefaultFieldMapping.DeveloperName;
            fieldMapping.dataImportFieldMappingSetLabel =
                existingDefaultFieldMapping.Data_Import_Field_Mapping_Set__r.label;
            fieldMapping.dataImportFieldMappingSetRecordName =
                existingDefaultFieldMapping.Data_Import_Field_Mapping_Set__r.DeveloperName;
        }
    }

    /**
     * @description Check if Field Mapping Metadata Type field values are out of sync with default values
     * @return Boolean
     */
    private Boolean foundDefaultFieldMappingMismatch(
        BDI_HelpTextCMT.DataImportFieldMapping newFieldMapping,
        Data_Import_Field_Mapping__mdt existingFieldMapping,
        Data_Import_Object_Mapping__mdt existingDefaultObjectMapping) {

        Boolean badRequiredField = (existingFieldMapping.Required__c != 'No');
        Boolean badIsDeletedField = (existingFieldMapping.Is_Deleted__c == true);
        Boolean badSourceFieldAPIName =
            (existingFieldMapping.Source_Field_API_Name__c != newFieldMapping.sourceFieldAPIName);
        Boolean badTargetFieldAPIName =
            (existingFieldMapping.Target_Field_API_Name__c != newFieldMapping.targetFieldAPIName);
        Boolean badTargetObjectMappingId =
            (existingFieldMapping.Target_Object_Mapping__c != existingDefaultObjectMapping.Id);

        Boolean foundMismatch = badRequiredField
            || badSourceFieldAPIName
            || badTargetFieldAPIName
            || badTargetObjectMappingId
            || badIsDeletedField;

        return foundMismatch;
    }

    /**
     * @description Empty deployment queue and related lists
     */
    private void clearLists() {
        queuedMetadataTypesForDeploy.clear();
        conflictingMappings.clear();
        pendingMappings.clear();
        pendingStandardMappings.clear();
        pendingNonHelpTextMappings.clear();
    }

    /**
     * @description Check the status of custom metadata deployment
     * @return Metadata.DeployResult JSON
     */
    public Metadata.DeployResult getDeploymentResult(String deploymentId) {
        Http h = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(Url.getOrgDomainUrl().toExternalForm() +
            '/services/data/v44.0/metadata/deployRequest/' +
            deploymentId +
            '?includeDetails=true');
        request.setMethod('GET');
        request.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
        HttpResponse response = h.send(request);
        Metadata.DeployResult deploymentResult =
            (Metadata.DeployResult)JSON.deserialize(response.getBody(), Metadata.DeployResult.class);

        return deploymentResult;
    }

    /**
    * @description an exception object wrapper for migration utility
    */
    private class DeploymentException extends Exception {}

} // BDI_MigrationMappingUtility