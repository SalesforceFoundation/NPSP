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

    /*******************************************************************************************************
    * @description Name of default packaged Object Mapping Set
    */
    private static final String DATA_IMPORT_OBJECT_NAME =
        'DataImport__c';

    /*******************************************************************************************************
    * @description Name of default packaged Object Mapping Set
    */
    private static final String DEFAULT_OBJECT_MAPPING_SET_RECORD_NAME =
        'Default_Object_Mapping_Set';

    /*******************************************************************************************************
    * @description Name of custom Field Mapping Set
    * Set as static because it's used in the static method updateCustomSettings
    */
    public static final String MIGRATED_CUSTOM_FIELD_MAPPING_SET_RECORD_NAME =
        'Migrated_Custom_Field_Mapping_Set';

    /*******************************************************************************************************
    * @description Boolean flag to determine if a custom field mapping set exists
    * Set as static because it's used in the static method updateCustomSettings
    */
    public Boolean customFieldMappingSetExists {
        get {
            Integer migratedFieldMappingSetCount = [SELECT count()
                FROM Data_Import_Field_Mapping_Set__mdt
                WHERE DeveloperName = :MIGRATED_CUSTOM_FIELD_MAPPING_SET_RECORD_NAME];

            return migratedFieldMappingSetCount > 0 ? true : false;
        }
    }

    /*******************************************************************************************************
    * @description Default packaged Object Mapping Set metadata record
    */
    public Data_Import_Object_Mapping_Set__mdt getDefaultObjectMappingSet() {
        return [SELECT Id, DeveloperName, Label
            FROM Data_Import_Object_Mapping_Set__mdt
            WHERE DeveloperName = :DEFAULT_OBJECT_MAPPING_SET_RECORD_NAME];
    }

    /*******************************************************************************************************
    * @description List of bad/malformed help text mappings
    */
    public List<BDI_MigrationMappingUtility.HelpTextFieldMapping > badHelpTextFieldMappings =
        new List<BDI_MigrationMappingUtility.HelpTextFieldMapping >();

    /*******************************************************************************************************
    * @description List of BDI_FieldMappingHelpText.DataImportFieldMappings built from good help text mappings
    */
    public List<BDI_MigrationMappingUtility.DataImportFieldMapping> dataImportFieldMappings =
        new List<BDI_MigrationMappingUtility.DataImportFieldMapping>();

    /*******************************************************************************************************
     * @description Go through all fields in Data Import object and populate relevant lists from help text mappings
     */
    public void populateListsFromHelpTextMappings() {

        badHelpTextFieldMappings.clear();
        dataImportFieldMappings.clear();

        Map<String, Schema.DescribeFieldResult> describeFieldResultsByFieldName =
                UTIL_Describe.getAllFieldsDescribe(UTIL_Namespace.StrAllNSPrefix(DATA_IMPORT_OBJECT_NAME));

        for (String dataImportFieldName : describeFieldResultsByFieldName.keySet()) {

            Boolean isImportStatus = dataImportFieldName.contains('importstatus');
            Boolean isImportLookup = dataImportFieldName.contains('imported');

            if (isImportStatus || isImportLookup) {
                continue;
            }

            DescribeFieldResult sourceField = describeFieldResultsByFieldName.get(dataImportFieldName);
            BDI_MigrationMappingUtility.HelpTextFieldMapping helpTextFieldMapping =
                    new BDI_MigrationMappingUtility.HelpTextFieldMapping(sourceField);

            if (helpTextFieldMapping.isUsable) {
                // Pass help text values to a new instance of MappingDetail wrapper class
                BDI_MigrationMappingUtility.DataImportFieldMapping newDataImportFieldMapping =
                    new BDI_MigrationMappingUtility.DataImportFieldMapping(
                        sourceField.Label,
                        sourceField.Name,
                        helpTextFieldMapping.dataImportObjectName,
                        helpTextFieldMapping.targetFieldAPIName,
                        helpTextFieldMapping.targetObjectAPIName);

                dataImportFieldMappings.add(newDataImportFieldMapping);
            } else if (helpTextFieldMapping.isPotentialMapping) {
                // Park suspected help text mappings
                BDI_MigrationMappingUtility.HelpTextFieldMapping badHelpTextMapping = new BDI_MigrationMappingUtility.HelpTextFieldMapping(sourceField);
                badHelpTextFieldMappings.add(badHelpTextMapping);
            }
        }
    }

    /*******************************************************************************************************
    * @description Method to get list of good help text mappings. Used in conjuction with
    * populateListsFromHelpTextMappings()
    *
    * @return List of DataImportFieldMappings
    */
    public List<BDI_MigrationMappingUtility.DataImportFieldMapping> getDataImportFieldMappingsFromHelpText() {
        return dataImportFieldMappings;
    }

    /*******************************************************************************************************
    * @description Method to get list of bad help text mappings. Used in conjuction with
    * populateListsFromHelpTextMappings()
    *
    * @return List of HelpTextFieldMappings
    */
    public List<BDI_MigrationMappingUtility.HelpTextFieldMapping> getBadHelpTextMappings() {
        return badHelpTextFieldMappings;
    }

    /*******************************************************************************************************
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

    /*******************************************************************************************************
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