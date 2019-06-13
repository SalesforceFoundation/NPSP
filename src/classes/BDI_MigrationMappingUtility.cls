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
    * @description Boolean flag to determine if a custom field mapping set exists 
    * Set as static because it's used in the static method updateCustomSettings
    */
    public static Boolean customFieldMappingSetExists {
        get {
            if (customFieldMappingSetExists == null) {
                Integer migratedFieldMappingSetCount = [SELECT count()
                    FROM Data_Import_Field_Mapping_Set__mdt
                    WHERE DeveloperName = :MIGRATED_CUSTOM_FIELD_MAPPING_SET_RECORD_NAME];

                return migratedFieldMappingSetCount > 0 ? true : false;
            }
            return customFieldMappingSetExists;
        }
    }

    /*******************************************************************************************************
    * @description Helper class that supports BDI_MigrationMappingUtility and enables mocking of test data.
    */
    private BDI_MigrationMappingHelper helper;

    /*******************************************************************************************************
    * @description Custom Setting record where we set cmt api deployment status, cmt deployment id,
    * field mapping method, and default data import field mapping set.
    */
    private Data_Import_Settings__c dataImportSettings;

    private Map<String, Data_Import_Object_Mapping__mdt> objectMappingsByDeveloperName;

    private Map<String, Data_Import_Field_Mapping__mdt> fieldMappingsByFieldMappingSetDeveloperName;

    private String fieldMappingSetName {
        get {
            if (fieldMappingSetName == null) {
                if (customFieldMappingSetExists) {
                    return MIGRATED_CUSTOM_FIELD_MAPPING_SET_RECORD_NAME;
                }
                return DEFAULT_FIELD_MAPPING_SET_RECORD_NAME;
            }
            return fieldMappingSetName;
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
        this.fieldMappingsByFieldMappingSetDeveloperName =
            helper.getFieldMappingsByFieldMappingSetDeveloperName(fieldMappingSetName);
    }

    /*******************************************************************************************************
    * @description Initiate a deployment of custom metadata type records
    *
    * @return Metadata deployment id
    */
    public String deployCustomMetadata() {
        String deploymentId;

        try {
            If (queuedMetadataTypesForDeploy.size() > 0) {
            Metadata.DeployContainer deploymentContainer = new Metadata.DeployContainer();
            for (Metadata.CustomMetadata customMetadataRecord : queuedMetadataTypesForDeploy) {
                deploymentContainer.addMetadata(customMetadataRecord);
            }

            if (Test.isRunningTest()) {
                deploymentId = '123';
            } else {
                deploymentId = Metadata.Operations.enqueueDeployment(deploymentContainer, new DeploymentCallback());
            }
        }
        } catch (Exception e) {
            throw new DeploymentException(Label.bdiErrorDeploymentFailed + ' ' + e.getMessage());
        }

        return deploymentId;
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

        if (BDI_MigrationMappingUtility.customFieldMappingSetExists == true) {
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
    * @description Collect and inspect existing field mappings and mappings found from Help Text and
    * add mappings to appropriate lists (pendingMappings, conflictingMappings, pendingStandardMappings,
    * pendingNonHelpTextMappings)
    */
    public void migrateHelpTextToCustomMetadata() {
        System.debug('***migrateHelpTextToCustomMetadata');

        queuedMetadataTypesForDeploy.clear();

        // Mappings found in Data Import Help Text
        Map<String, BDI_HelpTextCMT.DataImportFieldMapping> mappingDetailsBySourceFieldName =
                helper.getAllMappingDetailsBySourceFieldName();

        for (String key : mappingDetailsBySourceFieldName.keySet()) {
            BDI_HelpTextCMT.DataImportFieldMapping fieldMapping = 
                mappingDetailsBySourceFieldName.get(key);

            String fieldMappingKey = fieldMapping.targetObjectAPIName
                + '.'
                + fieldMapping.dataImportObjectName
                + '.'
                + fieldMapping.sourceFieldAPIName;

            Data_Import_Object_Mapping__mdt existingDefaultObjectMapping =
                objectMappingsByDeveloperName.get(fieldMapping.dataImportObjectName);

            if (existingDefaultObjectMapping != null) {

                Data_Import_Field_Mapping__mdt existingDefaultFieldMapping = 
                    fieldMappingsByFieldMappingSetDeveloperName.get(fieldMappingKey);

                if (existingDefaultFieldMapping == null) {
                    // New Field Mapping, not part of our initial config
                    fieldMapping.setInstance(
                        existingDefaultObjectMapping,
                        MIGRATED_CUSTOM_FIELD_MAPPING_SET_RECORD_NAME);
                    fieldMapping.setRecordName('', true);
                    // Add metadata record to queue for deployment
                    System.debug('>>>NEW');
                    System.debug(fieldMapping.recordName + ' *** ' + fieldMapping.targetFieldAPIName + ' *** ' + fieldMapping.sourceFieldAPIName);
                    queuedMetadataTypesForDeploy.add(fieldMapping.getMetadataRecord());

                } else if (existingDefaultFieldMapping != null) {
                    // Existing Field Mapping, check if CMTs field values match Help Text field values
                    Boolean conflictingMapping = hasDefaultFieldMappingMismatch(fieldMapping,
                            existingDefaultFieldMapping, 
                            existingDefaultObjectMapping);

                    if (conflictingMapping) {
                        fieldMapping.setInstance(
                            existingDefaultObjectMapping,
                            MIGRATED_CUSTOM_FIELD_MAPPING_SET_RECORD_NAME,
                            fieldMapping.targetFieldAPIName);
                        fieldMapping.setRecordName(existingDefaultFieldMapping.DeveloperName, true);
                        System.debug('>>>CONFLICT');
                        System.debug(fieldMapping.recordName + ' *** ' + fieldMapping.targetFieldAPIName + ' *** ' + fieldMapping.sourceFieldAPIName);
                        queuedMetadataTypesForDeploy.add(fieldMapping.getMetadataRecord());
                    } else {
                        System.debug('>>>STANDARD');
                        fieldMapping.setInstance(
                            existingDefaultObjectMapping,
                            MIGRATED_CUSTOM_FIELD_MAPPING_SET_RECORD_NAME);
                        fieldMapping.setRecordName('', true);
                        System.debug(fieldMapping.recordName + ' *** ' + fieldMapping.targetFieldAPIName + ' *** ' + fieldMapping.sourceFieldAPIName);
                        queuedMetadataTypesForDeploy.add(fieldMapping.getMetadataRecord());
                    }

                    fieldMappingsByFieldMappingSetDeveloperName.remove(fieldMappingKey);
                }
            }
        }

        handleNonHelpTextMappings(fieldMappingsByFieldMappingSetDeveloperName);

        if (customFieldMappingSetExists == false) {
            // Create migrated field mapping set
            Metadata.CustomMetadata fieldMappingSet =
                helper.createNewFieldMappingSet(MIGRATED_CUSTOM_FIELD_MAPPING_SET_RECORD_NAME);

            // Add custom field mapping set to list queuedMetadataTypesForDeploy
            queuedMetadataTypesForDeploy.add(fieldMappingSet);
        }
    }

    /*******************************************************************************************************
    * @description Method for converting non help text mapped standard field mappings to
    * instances of BDI_HelpTextCMT.DataImportFieldMapping so that we can update field values
    * and add to the deployment with the other custom metadata records
    * @param fieldMappingsByFieldMappingSetDeveloperName List of non help text mapped
    * standard field mappings
    * @param fieldMappingSetName String Name of the parent Data Import Field Mapping Set
    */
    private void handleNonHelpTextMappings(Map<String, Data_Import_Field_Mapping__mdt> fieldMappingsByFieldMappingSetDeveloperName) {

        for (String key : fieldMappingsByFieldMappingSetDeveloperName.keySet()) {
            
            Data_Import_Field_Mapping__mdt existingFieldMapping =
                fieldMappingsByFieldMappingSetDeveloperName.get(key);

            BDI_HelpTextCMT.DataImportFieldMapping fieldMapping =
                new BDI_HelpTextCMT.DataImportFieldMapping(existingFieldMapping,
                    MIGRATED_CUSTOM_FIELD_MAPPING_SET_RECORD_NAME);

            Boolean isUnique = customFieldMappingSetExists ? false : true;
            fieldMapping.setRecordName(existingFieldMapping.DeveloperName, isUnique);

            System.debug(fieldMapping.recordName + ' *** ' + fieldMapping.targetFieldAPIName + ' *** ' + fieldMapping.sourceFieldAPIName);
            queuedMetadataTypesForDeploy.add(fieldMapping.getMetadataRecord());
        }

        System.debug(queuedMetadataTypesForDeploy.size());
        /*for (Metadata.CustomMetadata cmt : queuedMetadataTypesForDeploy) {
            System.debug(cmt.fullName + ' *** ' + cmt.label);
        }*/
    }

    /*******************************************************************************************************
    * @description Check if Field Mapping Metadata Type field values are out of sync with default values
    * @return Boolean
    */
    private Boolean hasDefaultFieldMappingMismatch(
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

    /*******************************************************************************************************
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
        DeploymentResponse deploymentResponse =
            (DeploymentResponse)JSON.deserialize(response.getBody(), DeploymentResponse.class);

        return deploymentResponse.deployResult;
    }

    /*******************************************************************************************************
    * @description Wrapper object for the deployment request response
    */
    private class DeploymentResponse {
        Metadata.DeployResult deployResult;
    }

    /*******************************************************************************************************
    * @description an exception object wrapper for migration utility
    */
    private class DeploymentException extends Exception {}

} // BDI_MigrationMappingUtility