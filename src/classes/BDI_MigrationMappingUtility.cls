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
* @description Service methods to handle building custom Help Text mapping records
*/
public class BDI_MigrationMappingUtility {

    public String migrationType = 'default';

    /**
    * @description Metadata queued up for deployment
    */
    public List<Metadata.CustomMetadata> queuedMetadataTypesForDeploy =
        new List<Metadata.CustomMetadata>();

    /*
    * @description List of help text mappings that conflicts with our packaged default custom metatadata type mappings
    */
    public List<BDI_HelpTextCMT.DataImportFieldMapping> conflictingMappings {
        get {
            if (conflictingMappings == null) {
                conflictingMappings = new List<BDI_HelpTextCMT.DataImportFieldMapping>();
            }
            return conflictingMappings;
        }
        set;
    }

    /*
    * @description List of custom metatadata type mappings pending deployment
    */
    public List<BDI_HelpTextCMT.DataImportFieldMapping> pendingMappings {
        get {
            if (pendingMappings == null) {
                pendingMappings = new List<BDI_HelpTextCMT.DataImportFieldMapping>();
            }
            return pendingMappings;
        }
        set;
    }

    /**
    * @description List of standard mappings
    */
    public List<BDI_HelpTextCMT.DataImportFieldMapping> pendingStandardMappings =
        new List<BDI_HelpTextCMT.DataImportFieldMapping>();

    /**
    * @description Name of default packaged Object Mapping Set
    */
    private static final String DEFAULT_OBJECT_MAPPING_SET_RECORD_NAME =
        'Default_Object_Mapping_Set';

    /**
    * @description Name of default packaged Field Mapping Set
    */
    private static final String DEFAULT_FIELD_MAPPING_SET_RECORD_NAME =
        'Default_Field_Mapping_Set';

    /**
    * @description Name of custom Field Mapping Set
    */
    private static final String MIGRATED_CUSTOM_FIELD_MAPPING_SET_NAME =
        'Migrated_Custom_Mapping_Set';

    /**
    * @description Default packaged Object Mapping Set metadata record
    */
    private static final Data_Import_Object_Mapping_Set__mdt DEFAULT_OBJECT_MAPPING_SET = [SELECT
                Id,
                DeveloperName,
                Label
        FROM Data_Import_Object_Mapping_Set__mdt
        WHERE DeveloperName = :DEFAULT_OBJECT_MAPPING_SET_RECORD_NAME];

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
     * New
     */
    public Id deploymentId;

    private BDI_MigrationMappingHelper helper;
    private Data_Import_Settings__c dataImportSettings;

    public BDI_MigrationMappingUtility(BDI_MigrationMappingHelper helper) {
        this.helper = helper;
        this.dataImportSettings = UTIL_CustomSettingsFacade.getDataImportSettings();
    }

    public Id deployCustomMetadata() {
        System.debug(LoggingLevel.ERROR, '*** deployCustomMetadata()');

        if (queuedMetadataTypesForDeploy.isEmpty()) {
            // queue is empty, nothing to deploy
            // todo: set field mapping method to default in data import custom settings
            upsertCustomSettings('Data Import Field Mapping', 'default', String.valueOf(Metadata.DeployStatus.SUCCEEDED));
        } else {
            System.debug(LoggingLevel.ERROR, '*** attempting to deploy');
            try {
                Metadata.DeployContainer deploymentContainer = new Metadata.DeployContainer();
                for (Metadata.CustomMetadata customMetadataRecord : queuedMetadataTypesForDeploy) {
                    deploymentContainer.addMetadata(customMetadataRecord);
                }

                deploymentId = Metadata.Operations.enqueueDeployment(deploymentContainer, new DeploymentCallback(migrationType));
                System.debug(LoggingLevel.ERROR, '*** deployment container enqueued');
                System.debug('deploymentId: ' + deploymentId);
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, '*** e: ' + e);
                throw new DeploymentException('There was an error attempting to deploy the custom metadata records.');
            }
        }

        pendingMappings.clear();
        pendingStandardMappings.clear();
        conflictingMappings.clear();

        return deploymentId;
    }

    public static Data_Import_Settings__c upsertCustomSettings(String fieldMappingMethod, String migrationType, String status) {

        Data_Import_Settings__c dataImportSettings = UTIL_CustomSettingsFacade.getDataImportSettings();
        dataImportSettings.Field_Mapping_Method__c = fieldMappingMethod;

        if (migrationType == 'default') {
            dataImportSettings.Default_Data_Import_Field_Mapping_Set__c = DEFAULT_FIELD_MAPPING_SET_RECORD_NAME;
        } else {
            dataImportSettings.Default_Data_Import_Field_Mapping_Set__c = MIGRATED_CUSTOM_FIELD_MAPPING_SET_NAME;
        }

        Map<String, String> statusMap = new Map<String, String>{
            'Deployment Date' => String.valueOf(Datetime.now()),
            'Status' => String.valueOf(status),
            'Field Mapping Method' => fieldMappingMethod
        };

        dataImportSettings.CMT_API_Status__c = JSON.serialize(statusMap);

        try {
            upsert dataImportSettings;
            return dataImportSettings;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, '*** e: ' + e);
            throw new DeploymentException('There was an error attempting to update data import settings.');
        }
    }

    //copied from docs - TODO: implement our handler here
    public class DeploymentCallback implements Metadata.DeployCallback {

        private String migrationType;

        public DeploymentCallback(String migrationType) {
            this.migrationType = migrationType;
        }

        public void handleResult(Metadata.DeployResult result,
                Metadata.DeployCallbackContext context) {
            
            System.debug('*** handleResult');
            System.debug(migrationType);

            if (result.status == Metadata.DeployStatus.Succeeded) {
                // Deployment was successful
                //TODO: update Field_Mapping_Method__c in custom setting to reflect successful enablement of advanced mapping
                BDI_MigrationMappingUtility.upsertCustomSettings('Data Import Field Mapping', migrationType, String.valueOf(result.status));
            } else {
                // Deployment was not successful
                //TODO: In this case it failed, and we would want to store the error and notify the user (generally speaking)
                String errMsg = '';
                for (Integer n=0; n < result.details.componentFailures.size(); n++) {
                    errMsg += (n > 0 ? '\n' : '') + '* ' + result.details.componentFailures[n].fullName +
                            '> ' + result.details.componentFailures[n].problem;
                }

                BDI_MigrationMappingUtility.upsertCustomSettings('Help Text', migrationType, errMsg);
                throw new DeploymentException('There was an error attempting to deploy custom metadata.');
            }
        }
    }

    public void keepConflicts() {
        System.debug('keepConflicts');

        queuedMetadataTypesForDeploy.clear();
        conflictingMappings.clear();
        pendingMappings.clear();
        pendingStandardMappings.clear();
        migrationType = 'custom';

        buildCustomMetadataRecordsFromHelpText(MIGRATED_CUSTOM_FIELD_MAPPING_SET_NAME);

        System.debug('PM: ' + pendingMappings.size());
        System.debug('PSM: ' + pendingStandardMappings.size());
        System.debug('CM: ' + conflictingMappings.size());

        List<Metadata.CustomMetadata> pendingCMTs = new List<Metadata.CustomMetadata>();
        List<BDI_HelpTextCMT.DataImportFieldMapping> allMappings =
            new List<BDI_HelpTextCMT.DataImportFieldMapping>();

        if (pendingMappings.size() > 0) {
            allMappings.addAll(pendingMappings);
        }

        if (pendingStandardMappings.size() > 0) {
            allMappings.addAll(pendingStandardMappings);
        }

        if (allMappings.size() > 0) {
            Metadata.CustomMetadata fieldMappingSet =
                helper.createNewFieldMappingSet(MIGRATED_CUSTOM_FIELD_MAPPING_SET_NAME);

            pendingCMTs.add(fieldMappingSet);

            for (BDI_HelpTextCMT.DataImportFieldMapping dataImportFieldMapping : allMappings) {
                if (dataImportFieldMapping.dataImportObjectName == 'Payment') {
                    System.debug(dataImportFieldMapping.targetFieldAPIName);

                    dataImportFieldMapping.dataImportFieldMappingSetRecordName = MIGRATED_CUSTOM_FIELD_MAPPING_SET_NAME;
                    dataImportFieldMapping = dataImportFieldMapping;
                    pendingCMTs.add(dataImportFieldMapping.getMetadataRecord());
                }
            }

            queuedMetadataTypesForDeploy = pendingCMTs;
            System.debug('PCMTS: ' + pendingCMTs.size());
        }

        if (conflictingMappings.size() > 0) {
            //allMappings.addAll(conflictingMappings);

            // Update existing mappings to point to custom field mapping set
            for (BDI_HelpTextCMT.DataImportFieldMapping dataImportFieldMapping : conflictingMappings) {
                dataImportFieldMapping.dataImportFieldMappingSetRecordName = MIGRATED_CUSTOM_FIELD_MAPPING_SET_NAME;
                dataImportFieldMapping = dataImportFieldMapping;
            }

            // Update existing mappings to point to custom field mapping set
            List<Metadata.CustomMetadata> updatedCMTs = updateCustomMetadataRecords(
                MIGRATED_CUSTOM_FIELD_MAPPING_SET_NAME,
                conflictingMappings
            );

            queuedMetadataTypesForDeploy.addAll(updatedCMTs);
        }

        deployCustomMetadata();
        System.debug('keepConflicts deploymentId: ' + deploymentId);
    }

    public void discardConflicts() {
        System.debug('*** discardConflicts()');
        migrationType = 'default';

        // Keep any net new custom help text mappings to be added to our standard defaults
        if (pendingMappings.size() > 0) {
            List<Metadata.CustomMetadata> pendingCMTs = new List<Metadata.CustomMetadata>();
            for (BDI_HelpTextCMT.DataImportFieldMapping dataImportFieldMapping : pendingMappings) {
                pendingCMTs.add(dataImportFieldMapping.getMetadataRecord());
            }

            queuedMetadataTypesForDeploy = pendingCMTs;
            pendingMappings.clear();
        }

        deployCustomMetadata();
    }

    public List<Metadata.CustomMetadata> updateCustomMetadataRecords(String fieldMappingSetName,
                                                                     List<BDI_HelpTextCMT.DataImportFieldMapping> fieldMappings) {
        System.debug('updateCustomMetadataRecords');
        Map<String, Data_Import_Field_Mapping__mdt> existingFieldMappings =
            helper.getFieldMappingsByDeveloperName(fieldMappingSetName);
        List<Metadata.CustomMetadata> updatedCMTs = new List<Metadata.CustomMetadata>();

        for (BDI_HelpTextCMT.DataImportFieldMapping fieldMapping : fieldMappings) {
            Data_Import_Field_Mapping__mdt existingDefaultFieldMapping =
                    existingFieldMappings.get(fieldMapping.sourceFieldAPIName);
            System.debug('==========================');
            System.debug(existingDefaultFieldMapping);
            Metadata.CustomMetadata updatedCMT = fieldMapping.getMetadataRecord();
            System.debug(updatedCMT);
            List<String> nameParts = updatedCMT.fullName.split('\\.', 2);
            System.debug(nameParts);
            updatedCMT.fullName = nameParts[0] + '.' + existingDefaultFieldMapping.DeveloperName;
            updatedCMTs.add(updatedCMT);
        }

        return updatedCMTs;
    }

    /**
     * @description Collect all Help Text field mappings and compare against default Field Mapping Metadata 
     * Type records reserve all non-standard NPSP Help Text mappings. What to do with reserved list of Help 
     * Text mappings TBD.
     */
    public void buildCustomMetadataRecordsFromHelpText(String fieldMappingSetName) {

        Map<String, BDI_HelpTextCMT.MappingDetail> listHelpTextFieldDetails =
                helper.getAllMappedHelpTextFields();

        Map<String, Data_Import_Object_Mapping__mdt> existingObjectMappings =
                helper.getDefaultObjectMappings(DEFAULT_OBJECT_MAPPING_SET.Id);

        Map<String, Data_Import_Field_Mapping__mdt> existingFieldMappings =
                helper.getFieldMappingsByDeveloperName(fieldMappingSetName);

        for (String key : listHelpTextFieldDetails.keySet()) {

            BDI_HelpTextCMT.DataImportFieldMapping fieldMapping = 
                new BDI_HelpTextCMT.DataImportFieldMapping(key, listHelpTextFieldDetails.get(key));

            Data_Import_Object_Mapping__mdt existingDefaultObjectMapping = 
                existingObjectMappings.get(fieldMapping.dataImportObjectName);

            Boolean foundDefaultObjectMapping = (existingDefaultObjectMapping != null);

            if (foundDefaultObjectMapping) {

                Data_Import_Field_Mapping__mdt existingDefaultFieldMapping = 
                    existingFieldMappings.get(fieldMapping.sourceFieldAPIName);

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

                    if (invalidFieldMapping) {
                        // Add metadata record to queue for deployment
                        setFieldMappingValues(fieldMapping, 
                            existingDefaultObjectMapping, 
                            existingDefaultFieldMapping);

                        // If existing help text mapping doesn't match our packaged cmt record, park the mapping
                        fieldMapping.expectedHelpTextValue =
                            existingDefaultFieldMapping.Target_Object_Mapping__r.Object_API_Name__c
                            + '.'
                            + existingDefaultFieldMapping.Target_Field_API_Name__c;

                        conflictingMappings.add(fieldMapping);
                    }
                }
            }
        }
    }

    /**
     * @description Set the record and lookup names for the default object and field mappings
     * @param fieldMapping Current instance of DataImportFieldMapping wrapper
     * @param existingDefaultObjectMapping Corresponding Data_Import_Object_Mapping__mdt
     * @param existingDefaultFieldMapping Corresponding Data_Import_Field_Mapping__mdt
     */
    private void setFieldMappingValues(BDI_HelpTextCMT.DataImportFieldMapping fieldMapping,
                                       Data_Import_Object_Mapping__mdt existingDefaultObjectMapping,
                                       Data_Import_Field_Mapping__mdt existingDefaultFieldMapping) {

        fieldMapping.targetObjectMappingLabel = existingDefaultObjectMapping.Label;
        fieldMapping.targetObjectMappingRecordName = existingDefaultObjectMapping.DeveloperName;
        fieldMapping.dataImportFieldMappingSetLabel = DEFAULT_FIELD_MAPPING_SET.Label;
        fieldMapping.dataImportFieldMappingSetRecordName = DEFAULT_FIELD_MAPPING_SET.DeveloperName;

        if (existingDefaultFieldMapping != null) {
            fieldMapping.recordName = existingDefaultFieldMapping.DeveloperName;
        }
    }

    /**
     * @description Check if Field Mapping Metadata Type field values are out of sync with default values
     * This method isn't currently used anywhere.
     * @return Boolean
     */
    private Boolean foundDefaultFieldMappingMismatch(BDI_HelpTextCMT.DataImportFieldMapping newFieldMapping,
                                                     Data_Import_Field_Mapping__mdt existingFieldMapping,
                                                     Data_Import_Object_Mapping__mdt existingDefaultObjectMapping) {

        Boolean badMappingSetId = (existingFieldMapping.Data_Import_Field_Mapping_Set__c != 
            DEFAULT_FIELD_MAPPING_SET.Id);
        Boolean badRequiredField = (existingFieldMapping.Required__c != 'No');
        Boolean badSourceFieldAPIName = (existingFieldMapping.Source_Field_API_Name__c != 
            newFieldMapping.sourceFieldAPIName);
        Boolean badTargetFieldAPIName = (existingFieldMapping.Target_Field_API_Name__c != 
            newFieldMapping.targetFieldAPIName);
        Boolean badTargetObjectMappingId = (existingFieldMapping.Target_Object_Mapping__c != 
            existingDefaultObjectMapping.Id);
        Boolean badIsDeletedField = (existingFieldMapping.Is_Deleted__c != false);
        Boolean foundMismatch = badMappingSetId || 
                badRequiredField || 
                badSourceFieldAPIName || 
                badTargetFieldAPIName || 
                badTargetObjectMappingId || 
                badIsDeletedField;

        return foundMismatch;
    }

    private class DeploymentException extends Exception {}

} // BDI_MigrationMappingUtility