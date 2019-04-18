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
* @description PLACEHOLDER
*
*/
public class BDI_MigrationMappingUtility {
    private static List<Metadata.CustomMetadata> queuedMetadataTypes = new List<Metadata.CustomMetadata>();
    private static Set<String> dataImportObjectMappingNames = new Set<String>();

    public static Data_Import_Object_Mapping_Set__mdt defaultObjectMappingSet {
        get {
            if(defaultObjectMappingSet == null) {
                return getDefaultObjectMappingSet();
            }
            return defaultObjectMappingSet;
        } private set;
    }

    public static Data_Import_Field_Mapping_Set__mdt defaultFieldMappingSet {
        get {
            if(defaultFieldMappingSet == null) {
                return getDefaultFieldMappingSet();
            }
            return defaultFieldMappingSet;
        } private set;
    }

    public String convertLegacyHelpTextToCustomMetadata(Boolean doIt) {
        System.debug('convertLegacyHelpTextToCustomMetadata()');
        buildCustomMetadataRecordsFromHelpText();

        if (queuedMetadataTypes.size() > 0) {
            String jobId = getUniqueJobId();
            if (doit) {
                CMT_MetadataAPI.deployMetadata(jobId, queuedMetadataTypes.clone());
            }
            return jobId;
        }
        return 'Queue is empty';
    }

    public void buildCustomMetadataRecordsFromHelpText() {
        System.debug('buildObjectMappingMetadataRecords');
        Map<String, BDI_HelpTextCMT.MappingDetail> listHelpTextFieldDetails = getAllMappedHelpTextFields();
        Map<String, Data_Import_Object_Mapping__mdt> existingObjectMappings = getDefaultObjectMappings(defaultObjectMappingSet.Id);
        Map<String, Data_Import_Field_Mapping__mdt> existingFieldMappings = getDefaultFieldMappings(defaultFieldMappingSet.Id);

        List<Metadata.CustomMetadata> pendingObjectMapping = new List<Metadata.CustomMetadata>();
        List<Metadata.CustomMetadata> pendingFieldMappings = new List<Metadata.CustomMetadata>();

        System.debug(defaultObjectMappingSet);
        System.debug(defaultFieldMappingSet);
        //System.debug(listHelpTextFieldDetails);
        System.debug('Object Size: ' + existingObjectMappings.size());
        System.debug('Field Size: ' + existingFieldMappings.size());

        for(String key : listHelpTextFieldDetails.keySet()) {
            System.debug(key);
            System.debug('====================================');
            BDI_HelpTextCMT.DataImportFieldMapping fieldMapping = new BDI_HelpTextCMT.DataImportFieldMapping(key, listHelpTextFieldDetails.get(key));
            //System.debug(fieldMapping);
            Data_Import_Object_Mapping__mdt existingDefaultObjectMapping = existingObjectMappings.get(fieldMapping.dataImportObjectName);
            Boolean foundDefaultObjectMapping = (existingDefaultObjectMapping != null);
            System.debug(existingDefaultObjectMapping.Label);

            if (foundDefaultObjectMapping) {
                //System.debug('Found Default Object Mapping MDT');
                //TODO If found object mapping, check values and repair if needed.
                Data_Import_Field_Mapping__mdt existingDefaultFieldMapping = existingFieldMappings.get(fieldMapping.sourceFieldAPIName);
                Boolean foundDefaultFieldMapping = (existingDefaultFieldMapping != null);

                if (foundDefaultFieldMapping) {
                    System.debug('Found Default Field Mapping MDT');
                    //System.debug('= ' + defaultFieldMapping);
                    //TODO If found field mapping, check values and repair if needed.
                    Boolean invalidFieldMapping = validFieldMapping(fieldMapping, existingDefaultFieldMapping, existingDefaultObjectMapping);
                    if (invalidFieldMapping) {
                        System.debug('Found invalid field mapping');
                        fieldMapping.recordName = existingDefaultFieldMapping.DeveloperName;
                        fieldMapping.targetObjectMappingLabel = existingDefaultObjectMapping.Label;
                        fieldMapping.targetObjectMappingRecordName = existingDefaultObjectMapping.DeveloperName;
                        fieldMapping.dataImportFieldMappingSetLabel = defaultFieldMappingSet.Label;
                        fieldMapping.dataImportFieldMappingSetRecordName = defaultFieldMappingSet.DeveloperName;
                        pendingFieldMappings.add(fieldMapping.getMetadataRecord());
                    }
                    //newFieldMappings.add(existingDefaultFieldMapping);
                } else {
                    System.debug('NEED NEW FIELD MAPPING MDT');
                    //System.debug(fieldMapping);
                    fieldMapping.targetObjectMappingLabel = existingDefaultObjectMapping.Label;
                    fieldMapping.targetObjectMappingRecordName = existingDefaultObjectMapping.DeveloperName;
                    fieldMapping.dataImportFieldMappingSetLabel = defaultFieldMappingSet.Label;
                    fieldMapping.dataImportFieldMappingSetRecordName = defaultFieldMappingSet.DeveloperName;

                    //System.debug(fieldMapping);
                    System.debug(fieldMapping.getMetadataRecord());
                    pendingFieldMappings.add(fieldMapping.getMetadataRecord());
                }
            } else {
                //TODO New Default Object Mapping records needed
            }
        }

        queuedMetadataTypes.addAll(pendingObjectMapping);
        queuedMetadataTypes.addAll(pendingFieldMappings);

        System.debug('New Fields Count: ' + pendingFieldMappings.size());
        System.debug('New Object Count: ' + pendingObjectMapping.size());
    }

    private Boolean validFieldMapping(BDI_HelpTextCMT.DataImportFieldMapping newFieldMapping,
                                      Data_Import_Field_Mapping__mdt existingFieldMapping,
                                      Data_Import_Object_Mapping__mdt existingDefaultObjectMapping) {
        Boolean badMappingSetId = (existingFieldMapping.Data_Import_Field_Mapping_Set__c != defaultFieldMappingSet.Id);
        Boolean badRequiredField = (existingFieldMapping.Required__c != 'No');
        Boolean badSourceFieldAPIName = (existingFieldMapping.Source_Field_API_Name__c != newFieldMapping.sourceFieldAPIName);
        Boolean badTargetFieldAPIName = (existingFieldMapping.Target_Field_API_Name__c != newFieldMapping.targetFieldAPIName);
        Boolean badTargetObjectMappingId = (existingFieldMapping.Target_Object_Mapping__c != existingDefaultObjectMapping.Id);
        Boolean badIsDeletedField = (existingFieldMapping.Is_Deleted__c != false);
        System.debug(badMappingSetId
+ ' | ' + badRequiredField
+ ' | ' + badSourceFieldAPIName
+ ' | ' + badTargetFieldAPIName
+ ' | ' + badTargetObjectMappingId
+ ' | ' + badIsDeletedField);
        Boolean foundMismatch = badMappingSetId || badRequiredField || badSourceFieldAPIName || badTargetFieldAPIName || badTargetObjectMappingId || badIsDeletedField;

        return foundMismatch;
    }

    /**
     * getAllMappedHelpTextFields description
     * @return   return description
     */
    public Map<String, BDI_HelpTextCMT.MappingDetail> getAllMappedHelpTextFields() {
        System.debug('getAllMappedHelpTextFields');
        Map<String, BDI_HelpTextCMT.MappingDetail> helpTextFieldMap = new Map<String, BDI_HelpTextCMT.MappingDetail>();
        Map<String, BDI_HelpTextCMT.ImportStatusAndLookupParts> importStatusAndLookupMap = new Map<String, BDI_HelpTextCMT.ImportStatusAndLookupParts>();
        Map<String, Schema.DescribeFieldResult> allDFRs = UTIL_Describe.getAllFieldsDescribe('npsp__DataImport__c');

        for (String key : allDFRs.keySet()) {

            // check if field is importstatus or imported
            Boolean isImportStatus = key.contains('importstatus');
            Boolean isImportLookup = key.contains('imported');

            if (isImportStatus || isImportLookup) {
                BDI_HelpTextCMT.ImportStatusAndLookupParts importRelatedField = getImportStatusAndLookupParts(key, importStatusAndLookupMap);
                importStatusAndLookupMap.put(importRelatedField.objectName, importRelatedField);

                // Found an import status or import lookup field, no help text value so continue
                continue;
            }

            DescribeFieldResult sourceField = allDFRS.get(key);
            String helpText = sourceField.getInlineHelpText();
            Boolean helpTextIsUsable = String.isNotBlank(helpText) && !helpText.contains(' ');

            if (helpTextIsUsable) {
                BDI_HelpTextCMT.HelpTextParts parts = new BDI_HelpTextCMT.HelpTextParts(helpText);
                Boolean fieldNameIsUsable = String.isNotBlank(parts.fieldName);
                Boolean objectNameIsUsable = String.isNotBlank(parts.objectName);

                if (fieldNameIsUsable && objectNameIsUsable) {

                    // Collect a unique set of object names for creating default object mappings
                    dataImportObjectMappingNames.add(parts.objectName == 'Opportunity' ? 'Donation' : parts.objectName);

                    BDI_HelpTextCMT.MappingDetail newMappingDetail = new BDI_HelpTextCMT.MappingDetail(parts.objectName, sourceField.Label, parts.objectAPIName,
                                                                                                       parts.fieldName, null, null);
                    helpTextFieldMap.put(sourceField.Name, newMappingDetail);

                    // Remove from map once mapped
                    allDFRS.remove(key);
                }
            }
        }

        for (String key : helpTextFieldMap.keySet()) {
            BDI_HelpTextCMT.MappingDetail mappingDetail = helpTextFieldMap.get(key);
            setImportStatusAndLookupFields(mappingDetail, importStatusAndLookupMap);
        }
        //DEBUGGING
        /*for (String key : helpTextFieldMap.keySet()) {
            System.debug(helpTextFieldMap.get(key));
        }*/
        System.debug('Help Text Field Map Size: ' + helpTextFieldMap.size());
        return helpTextFieldMap;
    }

    private void setImportStatusAndLookupFields(BDI_HelpTextCMT.MappingDetail mappingDetail, Map<String, BDI_HelpTextCMT.ImportStatusAndLookupParts> importStatusAndLookupMap) {
        BDI_HelpTextCMT.ImportStatusAndLookupParts importStatusAndLookupParts = importStatusAndLookupMap.get(mappingDetail.dataImportObjectName);

        mappingDetail.importedRecordField = importStatusAndLookupParts.importLookupFieldName;
        mappingDetail.importedRecordStatusField = importStatusAndLookupParts.importStatusFieldName;
    }

    private BDI_HelpTextCMT.ImportStatusAndLookupParts getImportStatusAndLookupParts(String key, Map<String, BDI_HelpTextCMT.ImportStatusAndLookupParts> importStatusAndLookupMap) {
        BDI_HelpTextCMT.ImportStatusAndLookupParts importRelatedField = new BDI_HelpTextCMT.ImportStatusAndLookupParts(key);
        BDI_HelpTextCMT.ImportStatusAndLookupParts exists = importStatusAndLookupMap.get(importRelatedField.objectName);
        if (exists != null) {
            importRelatedField = new BDI_HelpTextCMT.ImportStatusAndLookupParts(exists, key);
        }

        return importRelatedField;
    }

    private static Data_Import_Object_Mapping_Set__mdt getDefaultObjectMappingSet() {
        // TODO: Do we need to add logic for when the default doesn't exist?
        return [SELECT Id, DeveloperName, Label FROM Data_Import_Object_Mapping_Set__mdt WHERE DeveloperName = 'Default_Object_Mapping_Set'];
    }

    private static Data_Import_Field_Mapping_Set__mdt getDefaultFieldMappingSet() {
        // TODO: Do we need to add logic for when the default doesn't exist?
        return [SELECT Id, DeveloperName, Label FROM Data_Import_Field_Mapping_Set__mdt WHERE DeveloperName = 'Default_Field_Mapping_Set'];
    }

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
            diObjectNameToObjectMappingMap.put(objectMapping.Label, objectMapping);
        }

        return diObjectNameToObjectMappingMap;
    }

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

} // BDI_MigrationMappingUtility