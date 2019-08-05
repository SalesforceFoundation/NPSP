/*
    Copyright (c) 2019, Salesforce.org
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
    * @description Get a list of by Data Import Object Mapping Set by Developer Name
    *
    * @param developerName: String name of the Data Import Object Mapping Set
    * @return List<Data_Import_Object_Mapping_Set__mdt>
    */
    public List<Data_Import_Object_Mapping_Set__mdt> getObjectMappingSet(String developerName) {
        List<Data_Import_Object_Mapping_Set__mdt> sets =
            [SELECT Id FROM Data_Import_Object_Mapping_Set__mdt WHERE DeveloperName = :developerName];
        return sets;
    }

    /*******************************************************************************************************
    * @description Get a list of by Data Import Field Mapping Set by Developer Name
    *
    * @param developerName: String name of the Data Import Field Mapping Set
    * @return List<Data_Import_Field_Mapping_Set__mdt>
    */
    public List<Data_Import_Field_Mapping_Set__mdt> getFieldMappingSet(String developerName) {
        List<Data_Import_Field_Mapping_Set__mdt> sets =
            [SELECT Id FROM Data_Import_Field_Mapping_Set__mdt WHERE DeveloperName = :developerName];
        return sets;
    }

    /*******************************************************************************************************
    * @description Get a list of Help Text Field Mappings from Data Import Help Text Field Describes
    *
    * @return List<Data_Import_Field_Mapping_Set__mdt>
    */
    public List<BDI_MigrationMappingUtility.HelpTextFieldMapping> getAllHelpTextFieldMappings() {

        Map<String, Schema.DescribeFieldResult> describeFieldResultsByFieldName =
            UTIL_Describe.getAllFieldsDescribe(UTIL_Namespace.StrAllNSPrefix(
                BDI_MigrationMappingUtility.DATA_IMPORT_OBJECT_NAME));

        List<BDI_MigrationMappingUtility.HelpTextFieldMapping> helpTextFieldMappings =
            new List<BDI_MigrationMappingUtility.HelpTextFieldMapping>();

        for (String dataImportFieldName : describeFieldResultsByFieldName.keySet()) {

            DescribeFieldResult sourceField = describeFieldResultsByFieldName.get(dataImportFieldName);
            BDI_MigrationMappingUtility.HelpTextFieldMapping helpTextFieldMapping =
                new BDI_MigrationMappingUtility.HelpTextFieldMapping(sourceField);

            helpTextFieldMappings.add(helpTextFieldMapping);
        }

        return helpTextFieldMappings;
    }

    /*******************************************************************************************************
     * @description Queries for default Object Mappings and builds a map of DeveloperName to Object Mapping
     * record used to check for existance of Object Mapping record without loop
     *
     * @param objectMappingSetId Id of the default Object Mapping Set
     * @return Collection of Object Mapping DeveloperName to Object Mapping record
     */
    public Map<String, Data_Import_Object_Mapping__mdt> getObjectMappingsBySetDeveloperName(String developerName) {

        Data_Import_Object_Mapping_Set__mdt[] objectMappingSets = [SELECT Id
            FROM Data_Import_Object_Mapping_Set__mdt
            WHERE DeveloperName = :developerName];

        Map<String, Data_Import_Object_Mapping__mdt> objectMappingsByDeveloperName =
            new Map<String, Data_Import_Object_Mapping__mdt>();

        if (objectMappingSets == null || objectMappingSets.size() == 0) {
            return objectMappingsByDeveloperName;
        }

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
                    Is_Deleted__c,
                    Legacy_Data_Import_Object_Name__c,
                    Custom_Mapping_Logic_Class__c
            FROM Data_Import_Object_Mapping__mdt
            WHERE Data_Import_Object_Mapping_Set__c = :objectMappingSets[0].Id
                AND Is_Deleted__c = false];

        for (Data_Import_Object_Mapping__mdt objectMapping : existingObjectMappings) {
            objectMappingsByDeveloperName.put(objectMapping.Legacy_Data_Import_Object_Name__c, objectMapping);
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

        Data_Import_Field_Mapping_Set__mdt[] fieldMappingSets = [SELECT Id
            FROM Data_Import_Field_Mapping_Set__mdt
            WHERE DeveloperName = :developerName];

        Map<String, Data_Import_Field_Mapping__mdt> fieldMappingsBySourceFieldName =
            new Map<String, Data_Import_Field_Mapping__mdt>();

        if (fieldMappingSets == null || fieldMappingSets.size() == 0) {
            return fieldMappingsBySourceFieldName;
        }

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
                    Target_OBject_Mapping__r.Legacy_Data_Import_Object_Name__c,
                    Target_Object_Mapping__r.MasterLabel,
                    Is_Deleted__c
            FROM Data_Import_Field_Mapping__mdt
            WHERE Data_Import_Field_Mapping_Set__c = :fieldMappingSets[0].Id
                AND Is_Deleted__c = false];

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
                + fieldMapping.Target_Object_Mapping__r.Legacy_Data_Import_Object_Name__c
                + '.'
                + fieldMapping.Source_Field_API_Name__c,
                fieldMapping);
        }

        return fieldMappingsBySourceFieldName;
    }
}
