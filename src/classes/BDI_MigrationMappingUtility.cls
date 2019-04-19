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
    public static List<Metadata.CustomMetadata> queuedMetadataTypesForDeploy = new List<Metadata.CustomMetadata>();

    /**
     * @description Calls method for building custom metadata mapping from help text mapping
     * @param  deployIt Boolean
     * @return A unique jobId. This value is used when writing the final status to the Data_Import_Settings__c
     * object and is needed to ensure that the status retrieved from that custom settings object is for this
     * particular deployment and not a previous one.
     */
    public String convertLegacyHelpTextToCustomMetadata(Boolean deployIt) {

        buildCustomMetadataRecordsFromHelpText();

        if (queuedMetadataTypesForDeploy.size() > 0) {
            String jobId = getUniqueJobId();

            // deployIt just debugging purposes when called from anon window, didn't want to constantly delete CMTs
            if (deployIt) {
                CMT_MetadataAPI.deployMetadata(jobId, queuedMetadataTypesForDeploy.clone(), true);
            }
            return jobId;
        }

        // Queue is empty, but we still need to update Data Import settings
        Data_Import_Settings__c dataImportSettings = UTIL_CustomSettingsFacade.getDataImportSettings();
        dataImportSettings.Field_Mapping_Method__c = 'Data Import Field Mapping';

        if (!Test.isRunningTest()) {
            upsert dataImportSettings;
        }

        return 'Queue is empty';
    }

    /**
     * @description Collect all Help Text field mappings and compare against default Field Mapping Metadata Type records
     * reserve all non-standard NPSP Help Text mappings. What to do with reserved list of Help Text mappings TBD.
     */
    public void buildCustomMetadataRecordsFromHelpText() {
        List<Metadata.CustomMetadata> pendingFieldMappings = new List<Metadata.CustomMetadata>();

        Map<String, BDI_HelpTextCMT.MappingDetail> listHelpTextFieldDetails = getAllMappedHelpTextFields();
        Map<String, Data_Import_Object_Mapping__mdt> existingObjectMappings = getDefaultObjectMappings(defaultObjectMappingSet.Id);
        Map<String, Data_Import_Field_Mapping__mdt> existingFieldMappings = getDefaultFieldMappings(defaultFieldMappingSet.Id);

        for(String key : listHelpTextFieldDetails.keySet()) {
            BDI_HelpTextCMT.DataImportFieldMapping fieldMapping = new BDI_HelpTextCMT.DataImportFieldMapping(key, listHelpTextFieldDetails.get(key));
            Data_Import_Object_Mapping__mdt existingDefaultObjectMapping = existingObjectMappings.get(fieldMapping.dataImportObjectName);
            Boolean foundDefaultObjectMapping = (existingDefaultObjectMapping != null);

            if (foundDefaultObjectMapping) {

                //TODO If found object mapping, check values and repair if needed.
                Data_Import_Field_Mapping__mdt existingDefaultFieldMapping = existingFieldMappings.get(fieldMapping.sourceFieldAPIName);
                Boolean foundDefaultFieldMapping = (existingDefaultFieldMapping != null);

                if (foundDefaultFieldMapping) {
                    //TODO If existing field mapping found, check values and repair if needed.
                    /*Boolean invalidFieldMapping = foundDefaultFieldMappingMismatch(fieldMapping, existingDefaultFieldMapping, existingDefaultObjectMapping);
                    if (invalidFieldMapping) {
                        fieldMapping.recordName = existingDefaultFieldMapping.DeveloperName;
                        fieldMapping.targetObjectMappingLabel = existingDefaultObjectMapping.Label;
                        fieldMapping.targetObjectMappingRecordName = existingDefaultObjectMapping.DeveloperName;
                        fieldMapping.dataImportFieldMappingSetLabel = defaultFieldMappingSet.Label;
                        fieldMapping.dataImportFieldMappingSetRecordName = defaultFieldMappingSet.DeveloperName;
                        //pendingFieldMappings.add(fieldMapping.getMetadataRecord());
                        pendingFieldMappings.add(fieldMapping.getMetadataRecord());
                    }*/
                } else {
                    // New Field Mapping, not part of our initial config
                    fieldMapping.targetObjectMappingLabel = existingDefaultObjectMapping.Label;
                    fieldMapping.targetObjectMappingRecordName = existingDefaultObjectMapping.DeveloperName;
                    fieldMapping.dataImportFieldMappingSetLabel = defaultFieldMappingSet.Label;
                    fieldMapping.dataImportFieldMappingSetRecordName = defaultFieldMappingSet.DeveloperName;

                    // Park custom help text mappings
                    pendingFieldMappings.add(fieldMapping.getMetadataRecord());
                }
            }
        }

        // Don't enqueue custom help text mappings
        //queuedMetadataTypesForDeploy.addAll(pendingFieldMappings);
    }

    /**
     * @description Check if Field Mapping Metadata Type field values are out of sync with default values
     * @return Boolean
     */
    private Boolean foundDefaultFieldMappingMismatch(BDI_HelpTextCMT.DataImportFieldMapping newFieldMapping,
                                                     Data_Import_Field_Mapping__mdt existingFieldMapping,
                                                     Data_Import_Object_Mapping__mdt existingDefaultObjectMapping) {

        Boolean badMappingSetId = (existingFieldMapping.Data_Import_Field_Mapping_Set__c != defaultFieldMappingSet.Id);
        Boolean badRequiredField = (existingFieldMapping.Required__c != 'No');
        Boolean badSourceFieldAPIName = (existingFieldMapping.Source_Field_API_Name__c != newFieldMapping.sourceFieldAPIName);
        Boolean badTargetFieldAPIName = (existingFieldMapping.Target_Field_API_Name__c != newFieldMapping.targetFieldAPIName);
        Boolean badTargetObjectMappingId = (existingFieldMapping.Target_Object_Mapping__c != existingDefaultObjectMapping.Id);
        Boolean badIsDeletedField = (existingFieldMapping.Is_Deleted__c != false);
        Boolean foundMismatch = badMappingSetId || badRequiredField || badSourceFieldAPIName || badTargetFieldAPIName || badTargetObjectMappingId || badIsDeletedField;

        return foundMismatch;
    }

    /**
     * @description Go through all fields in Data Import object and collect relevant help text mappings
     * @return A collection of help text field names mapped to an instance of MappingDetail which holds relevant values for building
     * the corresponding Metadata Type record (i.e. Source Object Name, Target Object Name, Target Field API Name, etc)
     */
    public Map<String, BDI_HelpTextCMT.MappingDetail> getAllMappedHelpTextFields() {
        Map<String, BDI_HelpTextCMT.MappingDetail> helpTextFieldMap = new Map<String, BDI_HelpTextCMT.MappingDetail>();
        Map<String, BDI_HelpTextCMT.ImportStatusAndLookupParts> importStatusAndLookupMap = new Map<String, BDI_HelpTextCMT.ImportStatusAndLookupParts>();
        Map<String, Schema.DescribeFieldResult> allDFRs = UTIL_Describe.getAllFieldsDescribe('npsp__DataImport__c');

        for (String dataImportFieldName : allDFRs.keySet()) {

            // check if field is importstatus or imported
            Boolean isImportStatus = dataImportFieldName.contains('importstatus');
            Boolean isImportLookup = dataImportFieldName.contains('imported');

            if (isImportStatus || isImportLookup) {
                BDI_HelpTextCMT.ImportStatusAndLookupParts importRelatedField = getImportStatusAndLookupParts(dataImportFieldName, importStatusAndLookupMap);
                importStatusAndLookupMap.put(importRelatedField.objectName, importRelatedField);

                // Found an import status or import lookup field, no help text value so continue
                continue;
            }

            DescribeFieldResult sourceField = allDFRS.get(dataImportFieldName);
            String helpText = sourceField.getInlineHelpText();
            Boolean helpTextIsUsable = String.isNotBlank(helpText) && !helpText.contains(' ');

            if (helpTextIsUsable) {
                BDI_HelpTextCMT.HelpTextParts parts = new BDI_HelpTextCMT.HelpTextParts(helpText);
                Boolean fieldNameIsUsable = String.isNotBlank(parts.fieldName);
                Boolean objectNameIsUsable = String.isNotBlank(parts.objectName);

                if (fieldNameIsUsable && objectNameIsUsable) {
                    BDI_HelpTextCMT.MappingDetail newMappingDetail = new BDI_HelpTextCMT.MappingDetail(parts.objectName, sourceField.Label, parts.objectAPIName,
                                                                                                       parts.fieldName, null, null);
                    helpTextFieldMap.put(sourceField.Name, newMappingDetail);

                    // Remove from map once mapped
                    allDFRS.remove(dataImportFieldName);
                }
            }
        }

        // Add import status and import lookup field values
        for (String key : helpTextFieldMap.keySet()) {
            BDI_HelpTextCMT.MappingDetail mappingDetail = helpTextFieldMap.get(key);
            setImportStatusAndLookupFields(mappingDetail, importStatusAndLookupMap);
        }

        return helpTextFieldMap;
    }

    /**
     * @description Set import lookup and import status fields on the MappingDetail instance
     * @param  mappingDetail Instance of MappingDetail where fields are to be set
     * @param  importStatusAndLookupMap Map holding the field values to be set to MappingDetail
     */
    private void setImportStatusAndLookupFields(BDI_HelpTextCMT.MappingDetail mappingDetail, Map<String, BDI_HelpTextCMT.ImportStatusAndLookupParts> importStatusAndLookupMap) {
        BDI_HelpTextCMT.ImportStatusAndLookupParts importStatusAndLookupParts = importStatusAndLookupMap.get(mappingDetail.dataImportObjectName);

        mappingDetail.importedRecordField = importStatusAndLookupParts.importLookupFieldName;
        mappingDetail.importedRecordStatusField = importStatusAndLookupParts.importStatusFieldName;
    }

    /**
     * @description Builds an instance of ImportStatusAndLookupParts which holds an object name, ImportedLookup__c and ImportStatus__c field names
     * @param dataImportFieldName Name of a Data Import field
     * @param importStatusAndLookupMap List of ImportStatusAndLookupParts instances
     * @return instance of ImportStatusAndLookupParts
     */
    private BDI_HelpTextCMT.ImportStatusAndLookupParts getImportStatusAndLookupParts(String dataImportFieldName, Map<String, BDI_HelpTextCMT.ImportStatusAndLookupParts> importStatusAndLookupMap) {
        // Create new instance of ImportStatusAndLookupParts
        BDI_HelpTextCMT.ImportStatusAndLookupParts importRelatedField = new BDI_HelpTextCMT.ImportStatusAndLookupParts(dataImportFieldName);

        // Check if there is already an existing and matching instance of ImportStatusAndLookupParts
        BDI_HelpTextCMT.ImportStatusAndLookupParts exists = importStatusAndLookupMap.get(importRelatedField.objectName);

        // If one exists, reset instance with new values
        if (exists != null) {
            importRelatedField = new BDI_HelpTextCMT.ImportStatusAndLookupParts(exists, dataImportFieldName);
        }

        return importRelatedField;
    }

    /** @description Queries for default Object Mapping Set */
    private static Data_Import_Object_Mapping_Set__mdt getDefaultObjectMappingSet() {
        // TODO: Do we need to add logic for when the default doesn't exist?
        return [SELECT Id, DeveloperName, Label FROM Data_Import_Object_Mapping_Set__mdt WHERE DeveloperName = 'Default_Object_Mapping_Set'];
    }

    /** @description Queries for default Field Mapping Set */
    private static Data_Import_Field_Mapping_Set__mdt getDefaultFieldMappingSet() {
        // TODO: Do we need to add logic for when the default doesn't exist?
        return [SELECT Id, DeveloperName, Label FROM Data_Import_Field_Mapping_Set__mdt WHERE DeveloperName = 'Default_Field_Mapping_Set'];
    }

    /**
     * @description Queries for default Object Mappings and builds a map of DeveloperName to Object Mapping record
     * Used to check for existance of Object Mapping record without loop
     * @param objectMappingSetId Id of the default Object Mapping Set
     * @return Collection of Object Mapping DeveloperName to Object Mapping record
     */
    private Map<String, Data_Import_Object_Mapping__mdt> getDefaultObjectMappings(Id objectMappingSetId) {
        List<Data_Import_Object_Mapping__mdt> existingObjectMappings = [SELECT Id,
                                                                            Label,
                                                                            DeveloperName,
                                                                            Imported_Record_Field_Name__c,
                                                                            Imported_Record_Status_Field_Name__c,
                                                                            Object_API_Name__c,
                                                                            Predecessor__c,
                                                                            Relationship_Field__c,
                                                                            Relationship_To_Predecessor__c,
                                                                            Is_Deleted__c
                                                                        FROM Data_Import_Object_Mapping__mdt
                                                                        WHERE Data_Import_Object_Mapping_Set__c = :objectMappingSetId];
        Map<String, Data_Import_Object_Mapping__mdt> diObjectNameToObjectMappingMap = new Map<String, Data_Import_Object_Mapping__mdt>();

        for(Data_Import_Object_Mapping__mdt objectMapping : existingObjectMappings) {
            diObjectNameToObjectMappingMap.put(objectMapping.DeveloperName, objectMapping);
        }

        return diObjectNameToObjectMappingMap;
    }

    /**
     * @description Queries for default Field Mappings and builds a map of DeveloperName to Field Mapping record
     * Used to check for existance of Field Mapping record without loop
     * @param fieldMappingSetId Id of the default Field Mapping Set
     * @return Collection of Field Mapping DeveloperName to Field Mapping record
     */
    private Map<String, Data_Import_Field_Mapping__mdt> getDefaultFieldMappings(Id fieldMappingSetId) {
        List<Data_Import_Field_Mapping__mdt> existingFieldMappings = [SELECT Id,
                                                                            Label,
                                                                            DeveloperName,
                                                                            Data_Import_Field_Mapping_Set__c,
                                                                            Required__c,
                                                                            Source_Field_API_Name__c,
                                                                            Target_Field_API_Name__c,
                                                                            Target_Object_Mapping__c,
                                                                            Is_Deleted__c
                                                                        FROM Data_Import_Field_Mapping__mdt
                                                                        WHERE Data_Import_Field_Mapping_Set__c = :fieldMappingSetId];
        Map<String, Data_Import_Field_Mapping__mdt> diFieldNameToFieldMappingMap = new Map<String, Data_Import_Field_Mapping__mdt>();

        for(Data_Import_Field_Mapping__mdt fieldMapping : existingFieldMappings) {
            diFieldNameToFieldMappingMap.put(fieldMapping.Source_Field_API_Name__c, fieldMapping);
        }

        return diFieldNameToFieldMappingMap;
    }

    /**
     * @return A 10 character unique 'jobId' to use for
     */
    private static String getUniqueJobId() {
        return UserInfo.getUserId().left(15).right(4).toUpperCase() +
                String.valueOf(Integer.valueOf(math.rint(math.random()*5000000))).right(6);
    }

    /** @description Default Object Mapping Set record */
    public static Data_Import_Object_Mapping_Set__mdt defaultObjectMappingSet {
        get {
            if(defaultObjectMappingSet == null) {
                return getDefaultObjectMappingSet();
            }
            return defaultObjectMappingSet;
        } private set;
    }

    /** @description Default Field Mapping Set record */
    public static Data_Import_Field_Mapping_Set__mdt defaultFieldMappingSet {
        get {
            if(defaultFieldMappingSet == null) {
                return getDefaultFieldMappingSet();
            }
            return defaultFieldMappingSet;
        } private set;
    }

} // BDI_MigrationMappingUtility