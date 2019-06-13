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
* @description Helper class that supports BDI_MigrationMappingUtility and
* enables mocking of test data.
*/
public class BDI_MigrationMappingHelper {

    /**
    * @description Name of default packaged Object Mapping Set
    */
    private static final String DATA_IMPORT_OBJECT_NAME =
        'DataImport__c';

    /**
    * @description Name of default packaged Object Mapping Set
    */
    private static final String DEFAULT_OBJECT_MAPPING_SET_RECORD_NAME =
        'Default_Object_Mapping_Set';

    /**
    * @description Default packaged Object Mapping Set metadata record
    */
    public Data_Import_Object_Mapping_Set__mdt getDefaultObjectMappingSet() {
        return [SELECT
                Id,
                DeveloperName,
                Label
        FROM Data_Import_Object_Mapping_Set__mdt
        WHERE DeveloperName = :DEFAULT_OBJECT_MAPPING_SET_RECORD_NAME];
    }

    /**
     * @description Creates a new Field Mapping Set to be used as the new set when migration utility
     * encounters a help text mapping customization and user opts to keep their customization
     * @return Data_Import_Field_Mapping_Set__mdt
     */
    public Metadata.CustomMetadata createNewFieldMappingSet(String fieldMappingName) {
        BDI_HelpTextCMT.DataImportFieldMappingSet fieldMappingSet =
            new BDI_HelpTextCMT.DataImportFieldMappingSet(fieldMappingName, DEFAULT_OBJECT_MAPPING_SET_RECORD_NAME);

        return fieldMappingSet.getMetadataRecord();
    }

    /**
     * @description Go through all fields in Data Import object and collect relevant help text mappings
     *
     * @return A collection of help text field names mapped to an instance of DataImportFieldMapping
     */
    public Map<String, BDI_HelpTextCMT.DataImportFieldMapping> getAllMappingDetailsBySourceFieldName() {

        Map<String, BDI_HelpTextCMT.DataImportFieldMapping> mappingDetailsBySourceFieldName =
                new Map<String, BDI_HelpTextCMT.DataImportFieldMapping>();

        Map<String, Schema.DescribeFieldResult> describeFieldResultsByFieldName =
                UTIL_Describe.getAllFieldsDescribe(UTIL_Namespace.StrAllNSPrefix(DATA_IMPORT_OBJECT_NAME));

        for (String dataImportFieldName : describeFieldResultsByFieldName.keySet()) {

            Boolean isImportStatus = dataImportFieldName.contains('importstatus');
            Boolean isImportLookup = dataImportFieldName.contains('imported');

            if (isImportStatus || isImportLookup) {
                continue;
            }

            DescribeFieldResult sourceField = describeFieldResultsByFieldName.get(dataImportFieldName);
            String helpText = sourceField.getInlineHelpText();
            Boolean helpTextIsUsable = String.isNotBlank(helpText) && !helpText.contains(' ');

            if (helpTextIsUsable) {
                BDI_HelpTextCMT.HelpTextParts helpTextParts = new BDI_HelpTextCMT.HelpTextParts(helpText);
                Boolean fieldNameIsUsable = String.isNotBlank(helpTextParts.fieldName);
                Boolean objectNameIsUsable = String.isNotBlank(helpTextParts.objectName);
                Boolean objectAPINameIsUsable = String.isNotBlank(helpTextParts.objectAPIName);

                // We may need to collect help text mapping with false objectAPINameIsUsable (bad mappings)
                // so we can potentially display it in the UI at some point
                // Check if the current help text mapping's object and field name are usable
                if (fieldNameIsUsable && objectNameIsUsable && objectAPINameIsUsable) {

                    // Pass help text values to a new instance of MappingDetail wrapper class
                    BDI_HelpTextCMT.DataImportFieldMapping newDataImportFieldMapping =
                        new BDI_HelpTextCMT.DataImportFieldMapping(
                            sourceField.Label,
                            sourceField.Name,
                            helpTextParts.objectName,
                            helpTextParts.fieldName,
                            helpTextParts.objectAPIName);

                    mappingDetailsBySourceFieldName.put(sourceField.Name, newDataImportFieldMapping);
                    // Remove from map once mapped
                    describeFieldResultsByFieldName.remove(dataImportFieldName);
                }
            }
        }

        return mappingDetailsBySourceFieldName;
    }

    /**
     * @description Queries for default Object Mappings and builds a map of DeveloperName to Object Mapping record
     * Used to check for existance of Object Mapping record without loop
     * @param objectMappingSetId Id of the default Object Mapping Set
     * @return Collection of Object Mapping DeveloperName to Object Mapping record
     */
    public Map<String, Data_Import_Object_Mapping__mdt> getObjectMappingsByDeveloperName(Id objectMappingSetId) {
        List<Data_Import_Object_Mapping__mdt> existingObjectMappings = [SELECT 
                    Id, 
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

        Map<String, Data_Import_Object_Mapping__mdt> objectMappingsByDeveloperName = 
            new Map<String, Data_Import_Object_Mapping__mdt>();

        for (Data_Import_Object_Mapping__mdt objectMapping : existingObjectMappings) {
            objectMappingsByDeveloperName.put(objectMapping.DeveloperName, objectMapping);
        }

        return objectMappingsByDeveloperName;
    }

    /**
     * @description Queries for default Field Mappings and builds a map of DeveloperName to Field Mapping record
     * Used to check for existance of Field Mapping record without loop
     * @param fieldMappingSetId Id of the default Field Mapping Set
     * @return Collection of Field Mapping DeveloperName to Field Mapping record
     */
    public Map<String, Data_Import_Field_Mapping__mdt> getFieldMappingsByFieldMappingSetDeveloperName(
        String developerName) {

        List<Data_Import_Field_Mapping__mdt> existingFieldMappings = [SELECT 
                    Id, 
                    Label, 
                    MasterLabel,
                    DeveloperName, 
                    Data_Import_Field_Mapping_Set__c,
                    Data_Import_Field_Mapping_Set__r.Label,
                    Data_Import_Field_Mapping_Set__r.DeveloperName,
                    Required__c, 
                    Source_Field_API_Name__c, 
                    Target_Field_API_Name__c, 
                    Target_Object_Mapping__c,
                    Target_Object_Mapping__r.Object_API_Name__c,
                    Target_Object_Mapping__r.DeveloperName,
                    Target_Object_Mapping__r.MasterLabel,
                    Is_Deleted__c
            FROM Data_Import_Field_Mapping__mdt
            WHERE Data_Import_Field_Mapping_Set__r.DeveloperName = :developerName];

        Map<String, Data_Import_Field_Mapping__mdt> fieldMappingsBySourceFieldName =
            new Map<String, Data_Import_Field_Mapping__mdt>();

        String namespace = UTIL_Namespace.getNamespace();

        for (Data_Import_Field_Mapping__mdt fieldMapping : existingFieldMappings) {
            if (namespace != 'npsp') {
                fieldMapping.Source_Field_API_Name__c =
                    UTIL_Namespace.removeNSPrefixNpspOnly(fieldMapping.Source_Field_API_Name__c);
                fieldMapping.Target_Object_Mapping__r.Object_API_Name__c =
                    UTIL_Namespace.removeNSPrefixNpspOnly(fieldMapping.Target_Object_Mapping__r.Object_API_Name__c);
            }
            fieldMappingsBySourceFieldName.put(
                fieldMapping.Target_Object_Mapping__r.Object_API_Name__c
                + '.'
                + fieldMapping.Target_Object_Mapping__r.DeveloperName
                + '.'
                + fieldMapping.Source_Field_API_Name__c,
                fieldMapping);
        }

        return fieldMappingsBySourceFieldName;
    }
}