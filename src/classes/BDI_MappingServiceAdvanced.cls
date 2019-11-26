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

public with sharing class BDI_MappingServiceAdvanced implements BDI_MappingService {

    public class MappingServiceException extends Exception{}

    public static final String DEFAULT_DATA_IMPORT_FIELD_MAPPING_SET_NAME = 'Default_Field_Mapping_Set';

    public Data_Import_Field_Mapping_Set__mdt diFieldMappingSet;
    public String fieldMappingSetName;

    public Map<String,BDI_ObjectMapping> objectMappingByDevName = new Map<String,BDI_ObjectMapping>();
    public Map<String,BDI_FieldMapping> fieldMappingByDevName = new Map<String,BDI_FieldMapping>();
    public Map<String,BDI_FieldMapping> fieldMappingByTargetFieldName = new Map<String,BDI_FieldMapping>();
    public Map<String,BDI_FieldMapping[]> fieldMappingsByObjMappingDevName = new Map<String,BDI_FieldMapping[]>();
    public Map<String,BDI_FieldMapping[]> fieldMappingsByObjMappingLegacyName = new Map<String,BDI_FieldMapping[]>();
    public Set<String> importedRecordFieldNames = new Set<String>();

    public BDI_FieldMappingSet fieldMappingSet;

    private static BDI_MappingServiceAdvanced fieldMappingInstance = null;

    /**
    * @description Reads Data_Import_Field_Mapping__mdt field mappings and produces a map of source field
    * to target field wrappers.
    */
    public Map<SObjectField, BDI_TargetFields> getTargetFieldsBySourceField() {

        Map<SObjectField, BDI_TargetFields> targetFieldsBySourceField =
                new Map<SObjectField, BDI_TargetFields>();

        String sourceObject = DataImport__c.SObjectType.getDescribe().getName();
        for (String dataImportObjectName : fieldMappingsByObjMappingDevName.keySet()) {

            String targetObject =
                    objectMappingByDevName.get(dataImportObjectName).Object_API_Name;
            List<BDI_FieldMapping> fieldMappingsForThisDataImportObject =
                    fieldMappingsByObjMappingDevName.get(dataImportObjectName);

            for (BDI_FieldMapping dataImportFieldMapping :
                    fieldMappingsForThisDataImportObject) {

                String sourceField = dataImportFieldMapping.Source_Field_API_Name;

                SObjectField sourceSObjectField =
                        UTIL_Describe.getFieldDescribe(
                                sourceObject, sourceField).getSobjectField();

                String targetField = dataImportFieldMapping.Target_Field_API_Name;

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
    public static BDI_MappingServiceAdvanced getInstance() {
        if (fieldMappingInstance == null) {
            fieldMappingInstance = new BDI_MappingServiceAdvanced();
            fieldMappingInstance.setFieldMappingSetName(null);
            fieldMappingInstance.retrieveCustMetadata();
        }
        return fieldMappingInstance;
    }

    /*******************************************************************************************************
    * @description return singleton instance of the class using specified field mapping set dev name
    */
    public static BDI_MappingServiceAdvanced getInstance(String fieldMappingSetDevName) {

        if (fieldMappingInstance == null) {
            fieldMappingInstance = new BDI_MappingServiceAdvanced();
            fieldMappingInstance.setFieldMappingSetName(fieldMappingSetDevName);
            fieldMappingInstance.retrieveCustMetadata();
        } else if(fieldMappingInstance.diFieldMappingSet.DeveloperName != fieldMappingSetDevName) {
            throw new MappingServiceException('Error: Field Mapping Set may not be changed after '+ 
                                                'initial instantiation');
        }
        return fieldMappingInstance;
    }

    /**
    * @description Sets instance member variable holding instance of this class.  Primarily
    * used to facilitate dependency injection in tests.
    * @param bdiFieldMappingInstance An instance of the BDI_MappingServiceAdvanced class.
    */
    @TestVisible
    private static void setInstance(BDI_MappingServiceAdvanced bdiFieldMappingInstance){
        fieldMappingInstance = bdiFieldMappingInstance;
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

    public Map<String,String> getFieldMap(String dataImportObjectName, 
                                            String targetObjectName, 
                                            List<String> dataImportFields) {

        Map<String,String> targetFieldByDataImportField = new Map<String,String>();

        BDI_FieldMapping[] fieldMappings = fieldMappingsByObjMappingLegacyName.get(dataImportObjectName);

        if (fieldMappings != null) {
            for (BDI_FieldMapping fieldMapping : fieldMappings) {
                targetFieldByDataImportField.put(
                    fieldMapping.Source_Field_API_Name.toLowerCase(),
                    fieldMapping.Target_Field_API_Name);
            }
        }

        return targetFieldByDataImportField;
    }

    private void setFieldMappingSetName(String fieldMappingSetDevName){
        if (fieldMappingSetDevName != null) {
            fieldMappingSetName = fieldMappingSetDevName;
        } else if (fieldMappingSetName == null) {
            //Retreive the Data Import Settings to determine the default field mapping set.
            Data_Import_Settings__c dis = UTIL_CustomSettingsFacade.getDataImportSettings();

            fieldMappingSetName = UTIL_Namespace.alignSchemaNSWithEnvironment(dis.Default_Data_Import_Field_Mapping_Set__c);
        }
    }

    private void retrieveCustMetadata(){
        //If the code is not in the npsp namespace, then the npsp field prefixes will need to be systematically removed.
        Map<String,Data_Import_Object_Mapping__mdt> objMappingsByDevName =
            new Map<String,Data_Import_Object_Mapping__mdt>();

        diFieldMappingSet = [SELECT id, 
                                MasterLabel, 
                                DeveloperName, 
                                Data_Import_Object_Mapping_Set__c,
                                Data_Import_Object_Mapping_Set__r.DeveloperName    
                    FROM Data_Import_Field_Mapping_Set__mdt
                    WHERE DeveloperName =: fieldMappingSetName LIMIT 1];

        Data_Import_Field_Mapping__mdt[] fieldMappings = new List<Data_Import_Field_Mapping__mdt>();

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

            if (diom.Data_Import_Field_Mappings__r != null &&
                diom.Data_Import_Field_Mappings__r.size() > 0) {

                fieldMappings.addAll(diom.Data_Import_Field_Mappings__r);
            }

            if (diom.Imported_Record_Field_Name__c != null) {
                if (UTIL_Namespace.shouldAlignNamespace) {
                    diom.Imported_Record_Field_Name__c = 
                        UTIL_Namespace.alignSchemaNSWithEnvironment(diom.Imported_Record_Field_Name__c);
                }
                
                importedRecordFieldNames.add(diom.Imported_Record_Field_Name__c.toLowerCase());
            }
            
            BDI_ObjectMapping objectMapping = new BDI_ObjectMapping(diom);
            this.objectMappingByDevName.put(objectMapping.DeveloperName,objectMapping);
        }


        if (fieldMappings != null) {
            for (Data_Import_Field_Mapping__mdt difm : fieldMappings) {

                BDI_FieldMapping fieldMapping = new BDI_FieldMapping(difm);

                BDI_FieldMapping[] tempFieldMappings = new BDI_FieldMapping[]{};

                if (fieldMappingsByObjMappingDevName.get(fieldMapping.Target_Object_Mapping_Dev_Name) != null) {
                    tempFieldMappings = fieldMappingsByObjMappingDevName.get(fieldMapping.Target_Object_Mapping_Dev_Name);
                }

                tempFieldMappings.add(fieldMapping);
                fieldMappingByDevName.put(fieldMapping.DeveloperName,fieldMapping);
                String objectAndField = fieldMapping.Target_Object_API_Name + '.' + fieldMapping.Target_Field_API_Name;
                fieldMappingByTargetFieldName.put(objectAndField,fieldMapping);
                fieldMappingsByObjMappingDevName.put(fieldMapping.Target_Object_Mapping_Dev_Name,tempFieldMappings);
                fieldMappingsByObjMappingLegacyName.put(
                    difm.Target_Object_Mapping__r.Legacy_Data_Import_Object_Name__c,
                    tempFieldMappings);
            }
        }

        fieldMappingSet = new BDI_FieldMappingSet(diFieldMappingSet,
            objectMappingByDevName,
            fieldMappingByDevName,
            fieldMappingByTargetFieldName,
            fieldMappingsByObjMappingDevName);
    }

    /*******************************************************************************************************
    * @description Method instantiates an instance of BDI_MappingServiceAdvanced by a given field mapping
    * set name and returns an instance of BDI_FieldMappingSet.
    *
    * @param fieldMappingSetName: Developer name of a Data_Import_Field_Mapping_Set__mdt record.
    *
    * @return fieldMappingSet: Instance of BDI_FieldMappingSet.
    */
    @AuraEnabled
    public static BDI_FieldMappingSet getFieldMappingSet(String fieldMappingSetName) {
        getInstance(fieldMappingSetName);
        return fieldMappingInstance.fieldMappingSet;
    }
}
