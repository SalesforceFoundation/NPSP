/*
    Copyright (c) 2019 Salesforce.org
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
* @description Implement field mapping behavior for mapping with custom metadata types
*/

public with sharing class BDI_FieldMappingCustomMetadata implements BDI_FieldMapping {

    public static final String DEFAULT_DATA_IMPORT_FIELD_MAPPING_SET_NAME = 'Default_Field_Mapping_Set';

    public Data_Import_Field_Mapping_Set__mdt diFieldMappingSet;
    public String fieldMappingSetName;

    public Map<String,Data_Import_Object_Mapping__mdt> objMappingsByDevName =
        new Map<String,Data_Import_Object_Mapping__mdt>();
    public Map<String,Data_Import_Field_Mapping__mdt[]> fieldMappingsByObjMappingDevName =
        new Map<String,Data_Import_Field_Mapping__mdt[]>();
    public Map<String,Data_Import_Field_Mapping__mdt[]> fieldMappingsByObjMappingLegacyName =
        new Map<String,Data_Import_Field_Mapping__mdt[]>();

    private static BDI_FieldMappingCustomMetadata fieldMappingInstance = null;

    /**
    * @description Reads Data_Import_Field_Mapping__mdt field mappings and produces a map of source field
    * to target field wrappers.
    */
    public Map<SObjectField, BDI_TargetFields> getTargetFieldsBySourceField() {

        Map<SObjectField, BDI_TargetFields> targetFieldsBySourceField =
                new Map<SObjectField, BDI_TargetFields>();

        for (String dataImportObjectName : fieldMappingsByObjMappingDevName.keySet()) {

            String targetObject =
                    objMappingsByDevName.get(dataImportObjectName).Object_API_Name__c;
            List<Data_Import_Field_Mapping__mdt> fieldMappingsForThisDataImportObject =
                    fieldMappingsByObjMappingDevName.get(dataImportObjectName);

            for (Data_Import_Field_Mapping__mdt dataImportFieldMapping :
                    fieldMappingsForThisDataImportObject) {

                String sourceObject = DataImport__c.SObjectType.getDescribe().getName();
                String sourceField = dataImportFieldMapping.Source_Field_API_Name__c;

                SObjectField sourceSObjectField =
                        UTIL_Describe.getFieldDescribe(
                                sourceObject, sourceField).getSobjectField();

                String targetField = dataImportFieldMapping.Target_Field_API_Name__c;

                if (targetFieldsBySourceField.keySet().contains(sourceSObjectField)) {
                    targetFieldsBySourceField.get(
                            sourceSObjectField).addTargetField(targetObject, targetField);
                } else {
                    BDI_TargetFields targetFields = new BDI_TargetFields();
                    targetFields.addTargetField(targetObject, targetField);
                    targetFieldsBySourceField.put(sourceSObjectField, targetFields);
                }
            }
        }
        return targetFieldsBySourceField;
    }

    /*******************************************************************************************************
    * @description return singleton instance of the class
    */
    public static BDI_FieldMappingCustomMetadata getInstance() {
        if (fieldMappingInstance == null) {
            fieldMappingInstance = new BDI_FieldMappingCustomMetadata();
            fieldMappingInstance.getFieldMappingSetName();
            fieldMappingInstance.retrieveCustMetadata();
        }
        return fieldMappingInstance;
    }

    /*******************************************************************************************************
    * @description For the provided fields (in the form DIObject.developerfieldname) and target object, 
    * return a map of DI field (key) to mapped field name on the destination record (value). 
    *
    * @param dataImportObjectName the bdi object we care about (Contact1, Contact2, Account1, etc)
    * @param targetObjectName the underlying object the bdi object is (ie, Contact, Account, etc)
    * @param dataImportFields the DataImport fields to consider
    * @return Map<String, String> a map of DataImport fields to underlying object fields (eg, Donation_Amount__c => Amount)
    *
    */

    public Map<String,String> getFieldMap(String dataImportObjectName, String targetObjectName, List<String> dataImportFields) {
        Map<String,String> targetFieldByDataImportField = new Map<String,String>();

        Data_Import_Field_Mapping__mdt[] diFieldMappings = fieldMappingsByObjMappingLegacyName.get(dataImportObjectName);

        if (diFieldMappings != null) {
            for (Data_Import_Field_Mapping__mdt difm : diFieldMappings) {

                targetFieldByDataImportField.put(difm.Source_Field_API_Name__c,difm.Target_Field_API_Name__c);
            }
        }

        return targetFieldByDataImportField;
    }

    private String getFieldMappingSetName(){
        if (fieldMappingSetName == null) {
            //Retreive the Data Import Settings to determine the default field mapping set.
            Data_Import_Settings__c dis = UTIL_CustomSettingsFacade.getDataImportSettings();

            fieldMappingSetName = UTIL_Namespace.alignSchemaNSWithEnvironment(dis.Default_Data_Import_Field_Mapping_Set__c);
        }

        return fieldMappingSetName;
    }

    private void retrieveCustMetadata(){
        //If the code is not in the npsp namespace, then the npsp field prefixes will need to be systematically removed.
        Boolean removeNPSPNamespace = (UTIL_Namespace.shouldAlignNamespace);

        diFieldMappingSet = [SELECT id, DeveloperName, 
                        Data_Import_Object_Mapping_Set__c,
                        Data_Import_Object_Mapping_Set__r.DeveloperName    
                    FROM Data_Import_Field_Mapping_Set__mdt
                    WHERE DeveloperName =: fieldMappingSetName LIMIT 1];
                    
        for (Data_Import_Object_Mapping__mdt diom:[SELECT Id,
                                            MasterLabel,
                                            Custom_Mapping_Logic_Class__c,
                                            DeveloperName, 
                                            Data_Import_Object_Mapping_Set__c,
                                            Data_Import_Object_Mapping_Set__r.DeveloperName, 
                                            Imported_Record_Field_Name__c,
                                            Imported_Record_Status_Field_Name__c,
                                            Is_Deleted__c,
                                            NamespacePrefix,
                                            Object_API_Name__c,
                                            Predecessor__c,
                                            Relationship_Field__c,
                                            Relationship_To_Predecessor__c,
                                            (SELECT MasterLabel,
                                                DeveloperName,
                                                Data_Import_Field_Mapping_Set__c,
                                                Data_Import_Field_Mapping_Set__r.DeveloperName,
                                                Required__c,
                                                Source_Field_API_Name__c,
                                                Target_Field_API_Name__c,
                                                Target_Object_Mapping__c,
                                                Target_Object_Mapping__r.DeveloperName,
                                                Target_Object_Mapping__r.Object_API_Name__c,
                                                Target_Object_Mapping__r.Legacy_Data_Import_Object_Name__c,
                                                Is_Deleted__c
                                            FROM Data_Import_Field_Mappings__r
                                            WHERE Is_Deleted__c = false
                                                AND Target_Object_Mapping__r.Is_Deleted__c = false)
                                    FROM Data_Import_Object_Mapping__mdt
                                    WHERE Data_Import_Object_Mapping_Set__c =: diFieldMappingSet.Data_Import_Object_Mapping_Set__c
                                        AND Is_Deleted__c = false
                                    ORDER BY MasterLabel ASC]) {

            // Removing the npsp namespace and potentially adding a new namespace if UTIL_Namespace is under a different namespace
            if (removeNPSPNamespace) {
               diom.Imported_Record_Field_Name__c = UTIL_Namespace.alignSchemaNSWithEnvironment(diom.Imported_Record_Field_Name__c);
               diom.Imported_Record_Status_Field_Name__c = UTIL_Namespace.alignSchemaNSWithEnvironment(diom.Imported_Record_Status_Field_Name__c);
               diom.Object_API_Name__c = UTIL_Namespace.alignSchemaNSWithEnvironment(diom.Object_API_Name__c);
               diom.Relationship_Field__c = UTIL_Namespace.alignSchemaNSWithEnvironment(diom.Relationship_Field__c);
            }

            objMappingsByDevName.put(diom.DeveloperName, diom);
        }

        Data_Import_Field_Mapping__mdt[] fieldMappings = new List<Data_Import_Field_Mapping__mdt>();

        for (String objectName : objMappingsByDevName.keySet()) {
            Data_Import_Object_Mapping__mdt objectMapping = objMappingsByDevName.get(objectName);

            if (objectMapping.Data_Import_Field_Mappings__r != null &&
                objectMapping.Data_Import_Field_Mappings__r.size() > 0) {

                fieldMappings.addAll(objectMapping.Data_Import_Field_Mappings__r);
            }
        }

        if (objMappingsByDevName != null && objMappingsByDevName.size() > 0) {
            for (Data_Import_Field_Mapping__mdt difm : fieldMappings) {

                // Removing the npsp namespace since the code is not currently packaged.
                if (removeNPSPNamespace) {
                   difm.Source_Field_API_Name__c = UTIL_Namespace.alignSchemaNSWithEnvironment(difm.Source_Field_API_Name__c);
                   difm.Target_Field_API_Name__c = UTIL_Namespace.alignSchemaNSWithEnvironment(difm.Target_Field_API_Name__c);
                }

                Data_Import_Field_Mapping__mdt[] tempDifms = new Data_Import_Field_Mapping__mdt[]{};

                if (fieldMappingsByObjMappingDevName.get(difm.Target_Object_Mapping__r.DeveloperName) != null) {
                    tempDifms = fieldMappingsByObjMappingDevName.get(difm.Target_Object_Mapping__r.DeveloperName);
                }

                tempDifms.add(difm);
                fieldMappingsByObjMappingDevName.put(difm.Target_Object_Mapping__r.DeveloperName,tempDifms);
                fieldMappingsByObjMappingLegacyName.put(
                    difm.Target_Object_Mapping__r.Legacy_Data_Import_Object_Name__c,
                    tempDifms);
            }
        }
    }
}
