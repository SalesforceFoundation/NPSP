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

    /** @description Metadata queued up for deployment */
    public List<Metadata.CustomMetadata> queuedMetadataTypesForDeploy = new List<Metadata.CustomMetadata>();

    /** @description Metadata parked due to conflicts with our default cmt records */
    public List<BDI_HelpTextCMT.DataImportFieldMapping> conflictingCMTs = new List<BDI_HelpTextCMT.DataImportFieldMapping>();

    /** @description Metadata parked due to conflicts with our default cmt records */
    public List<BDI_HelpTextCMT.DataImportFieldMapping> pendingCMTs = new List<BDI_HelpTextCMT.DataImportFieldMapping>();

    /** @description Unique job id for Custom Settings */
    public String jobId = getUniqueJobId();

    /**
     * @description Calls method for building custom metadata mapping from help text mapping
     * @param  deployIt Boolean
     * @return A unique jobId. This value is used when writing the final status to the Data_Import_Settings__c
     * object and is needed to ensure that the status retrieved from that custom settings object is for this
     * particular deployment and not a previous one.
     */
    public String convertLegacyHelpTextToCustomMetadata() {

        if (!queuedMetadataTypesForDeploy.isEmpty()) {
            CMT_MetadataAPI.deployMetadata(jobId, queuedMetadataTypesForDeploy.clone(), 
                CMT_MetadataAPI.Source.HELP_TEXT_MIGRATION);
        } else {
            // Queue is empty, but we still need to update Data Import settings
            updateCustomDataImportSettings(jobId, Label.bdiCustomObjectMappingSummary);
        }

        return jobId;
    }

    /**
     * @description Update the custom data import settings field mapping method field
     * @param fieldMappingMethod String
     */
    private void updateCustomDataImportSettings(String jobId, String fieldMappingMethod) {
        Map<String, String> statusMap = new Map<String, String>{jobId => 'Queue was empty'};
        CMT_MetadataAPI.setHelpTextMigrationSettings(statusMap, true);
    }

    /**
     * @description Collect all Help Text field mappings and compare against default Field Mapping Metadata 
     * Type records reserve all non-standard NPSP Help Text mappings. What to do with reserved list of Help 
     * Text mappings TBD.
     */
    public void buildCustomMetadataRecordsFromHelpText(BDI_MigrationMappingHelper helper) {

        Map<String, BDI_HelpTextCMT.MappingDetail> listHelpTextFieldDetails =
                helper.getAllMappedHelpTextFields();

        Map<String, Data_Import_Object_Mapping__mdt> existingObjectMappings =
                helper.getDefaultObjectMappings(DEFAULT_OBJECT_MAPPING_SET.Id);

        Map<String, Data_Import_Field_Mapping__mdt> existingFieldMappings =
                helper.getDefaultFieldMappings(DEFAULT_FIELD_MAPPING_SET.Id);

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
                    queuedMetadataTypesForDeploy.add(fieldMapping.getMetadataRecord());
                    pendingCMTs.add(fieldMapping);
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

                        conflictingCMTs.add(fieldMapping);
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

    /** @description Name of default packaged Object Mapping Set */
    private static final String DEFAULT_OBJECT_MAPPING_SET_RECORD_NAME = 'Default_Object_Mapping_Set';

    /** @description Name of default packaged Field Mapping Set */
    private static final String DEFAULT_FIELD_MAPPING_SET_RECORD_NAME = 'Default_Field_Mapping_Set';

    /** @description Default packaged Object Mapping Set metadata record */
    private static final Data_Import_Object_Mapping_Set__mdt DEFAULT_OBJECT_MAPPING_SET = [SELECT 
                Id, 
                DeveloperName, 
                Label
        FROM Data_Import_Object_Mapping_Set__mdt
        WHERE DeveloperName = :DEFAULT_OBJECT_MAPPING_SET_RECORD_NAME];

    /** @description Default packaged Field Mapping Set metadata record */
    private static final Data_Import_Field_Mapping_Set__mdt DEFAULT_FIELD_MAPPING_SET = [SELECT 
                Id, 
                DeveloperName, 
                Label
        FROM Data_Import_Field_Mapping_Set__mdt
        WHERE DeveloperName = :DEFAULT_FIELD_MAPPING_SET_RECORD_NAME];

    /**
     * @return A 10 character unique 'jobId' to use for
     */
    private static String getUniqueJobId() {
        return UserInfo.getUserId().left(15).right(4).toUpperCase() +
                String.valueOf(Integer.valueOf(math.rint(math.random()*5000000))).right(6);
    }

} // BDI_MigrationMappingUtility