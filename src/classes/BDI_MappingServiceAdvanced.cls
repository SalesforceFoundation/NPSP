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
            BDI_ObjectMapping targetObjectMapping = objectMappingByDevName.get(dataImportObjectName);
            if (targetObjectMapping != null) {
                String targetObject = targetObjectMapping.Object_API_Name;
                List<BDI_FieldMapping> fieldMappingsForThisDataImportObject =
                        fieldMappingsByObjMappingDevName.get(dataImportObjectName);

                for (BDI_FieldMapping dataImportFieldMapping :
                        fieldMappingsForThisDataImportObject) {

                    String sourceField = dataImportFieldMapping.Source_Field_API_Name;
                    try {
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
                    } catch (UTIL_Describe.SchemaDescribeException ex) {
                        // exception thrown if source field is not found
                        // do not add to targetFieldsBySourceField map
                    }
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
            fieldMappingInstance.retrieveCustMetadata(false);
        }
        return fieldMappingInstance;
    }

    /*******************************************************************************************************
    * @description return singleton instance of the class
    *
    * @param includeUtilityFields: Determines whether or not to include simulated field mappings
    * e.g. DataImport__c.Donation_Donor__c field or the various Data_Import_Object_Mapping__mdt
    * Imported_Record_Field_Name__c fields.
    */
    public static BDI_MappingServiceAdvanced getInstance(Boolean includeUtilityFields) {
        if (fieldMappingInstance == null) {
            fieldMappingInstance = new BDI_MappingServiceAdvanced();
            fieldMappingInstance.setFieldMappingSetName(null);
            fieldMappingInstance.retrieveCustMetadata(includeUtilityFields);
        }
        return fieldMappingInstance;
    }

    /*******************************************************************************************************
    * @description return singleton instance of the class using specified field mapping set dev name
    *
    * @param fieldMappingSetDevName: Developer Name of the Data_Import_Field_Mapping_Set__mdt to use.
    * @param includeUtilityFields: Determines whether or not to include simulated field mappings
    * e.g. DataImport__c.Donation_Donor__c field or the various Data_Import_Object_Mapping__mdt
    * Imported_Record_Field_Name__c fields.
    */
    public static BDI_MappingServiceAdvanced getInstance(String fieldMappingSetDevName,
        Boolean includeUtilityFields) {

        if (fieldMappingInstance == null) {
            fieldMappingInstance = new BDI_MappingServiceAdvanced();
            fieldMappingInstance.setFieldMappingSetName(fieldMappingSetDevName);
            fieldMappingInstance.retrieveCustMetadata(includeUtilityFields);
        } else if (fieldMappingInstance.diFieldMappingSet.DeveloperName != fieldMappingSetDevName) {
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

    private void retrieveCustMetadata(Boolean includeUtilityFields) {
        //If the code is not in the npsp namespace, then the npsp field prefixes will need to be systematically removed.
        diFieldMappingSet = getDataImportFieldMappingSets()[0];
        List<Data_Import_Object_Mapping__mdt> dataImportObjectMappings =
            getDataImportObjectMappingMetadata(diFieldMappingSet);
        populateObjectMappings(dataImportObjectMappings);
        populateFieldMappings(dataImportObjectMappings);

        if (includeUtilityFields) {
            addUtilityFields(fieldMappingInstance.objectMappingByDevName,
                fieldMappingInstance.fieldMappingByDevName,
                fieldMappingInstance.fieldMappingsByObjMappingDevName);
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
    * @param includeUtilityFields
    *
    * @return fieldMappingSet: Instance of BDI_FieldMappingSet.
    */
    @AuraEnabled
    public static BDI_FieldMappingSet getFieldMappingSet(String fieldMappingSetName,
        Boolean includeUtilityFields) {

        getInstance(fieldMappingSetName, includeUtilityFields);
        return fieldMappingInstance.fieldMappingSet;
    }

    /******************************************************************************************************************
     * @description Returns data required to build object mapping and field mapping wrapper objects
     * @param diFieldMappingSet Data Import Field Mapping Set
     * @return A list of Data Import Object Metadata
     */
    private List<Data_Import_Object_Mapping__mdt> getDataImportObjectMappingMetadata (
        Data_Import_Field_Mapping_Set__mdt diFieldMappingSet) {
        return [
            SELECT Id,
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
            ORDER BY MasterLabel ASC
        ];
    }

    private List<Data_Import_Field_Mapping_Set__mdt> getDataImportFieldMappingSets () {
        return [
            SELECT Id,
                MasterLabel,
                DeveloperName,
                Data_Import_Object_Mapping_Set__c,
                Data_Import_Object_Mapping_Set__r.DeveloperName
            FROM Data_Import_Field_Mapping_Set__mdt
            WHERE DeveloperName =: fieldMappingSetName LIMIT 1
        ];
    }

    /******************************************************************************************************************
    * @description Builds various maps for field mappings based on retrieved data import object mappings
    * @param dataImportObjectMappings List of Data Import Object Mapping Metadata
    */
    private void populateFieldMappings (List<Data_Import_Object_Mapping__mdt> dataImportObjectMappings) {
        for (Data_Import_Object_Mapping__mdt diom : dataImportObjectMappings) {
            if (hasFieldMappings(diom)) {
                for (Data_Import_Field_Mapping__mdt difm : diom.Data_Import_Field_Mappings__r) {
                    BDI_FieldMapping fieldMapping =  new BDI_FieldMapping();
                    fieldMapping.withBaseFieldMappingFields(difm).withFieldDescribeInfo();
                    buildFieldMappingDataStructures(fieldMapping, difm);
                }
            }
        }
    }

    private void buildFieldMappingDataStructures (BDI_FieldMapping fieldMapping, Data_Import_Field_Mapping__mdt difm) {
        BDI_FieldMapping[] tempFieldMappings = new BDI_FieldMapping[]{};
        if (fieldMappingsByObjMappingDevName.get(fieldMapping.Target_Object_Mapping_Dev_Name) != null) {
            tempFieldMappings = fieldMappingsByObjMappingDevName.get(
                fieldMapping.Target_Object_Mapping_Dev_Name);
        }
        tempFieldMappings.add(fieldMapping);
        fieldMappingByDevName.put(fieldMapping.DeveloperName,fieldMapping);
        String objectAndField =
            fieldMapping.Target_Object_API_Name + '.' + fieldMapping.Target_Field_API_Name;
        fieldMappingByTargetFieldName.put(objectAndField,fieldMapping);
        fieldMappingsByObjMappingDevName.put(fieldMapping.Target_Object_Mapping_Dev_Name,tempFieldMappings);
        fieldMappingsByObjMappingLegacyName.put(
            difm.Target_Object_Mapping__r.Legacy_Data_Import_Object_Name__c, tempFieldMappings);
    }

    private Boolean hasFieldMappings (Data_Import_Object_Mapping__mdt diom) {
        return diom.Data_Import_Field_Mappings__r != null &&
            diom.Data_Import_Field_Mappings__r.size() > 0;
    }

    /******************************************************************************************************************
     * @description Builds a map of object mapping developer name to BDI Object mapping object
     * @param dataImportObjectMappings List of Data Import Object Mapping Metadata
     */
    private void populateObjectMappings (
        List<Data_Import_Object_Mapping__mdt> dataImportObjectMappings) {
        for (Data_Import_Object_Mapping__mdt diom : dataImportObjectMappings) {
            if (diom.Imported_Record_Field_Name__c != null) {
                if (UTIL_Namespace.shouldAlignNamespace) {
                    diom.Imported_Record_Field_Name__c =
                        UTIL_Namespace.alignSchemaNSWithEnvironment(diom.Imported_Record_Field_Name__c);
                }
                importedRecordFieldNames.add(diom.Imported_Record_Field_Name__c.toLowerCase());
            }
            try {
                BDI_ObjectMapping objectMapping = new BDI_ObjectMapping(diom);
                this.objectMappingByDevName.put(objectMapping.DeveloperName, objectMapping);
            } catch (UTIL_Describe.SchemaDescribeException ex) {
                // if the object itself is not describable
                // do not add it to objectMappingByDevName since we can't map it
            }
        }
    }

    /*******************************************************************************************************
    * @description Method explicitly adds unmapped/non-field mapping fields to the field mapping set.
    * Currently only adds the Donation_Donor__c field from the DataImport__c object.
    *
    * @param objectMappingByDevName: Map of object mappings by developer name.
    * @param fieldMappingByDevName: Map of field mappings by developer name.
    * @param fieldMappingsByObjMappingDevName: Map of field mappings by object mapping by developer name.
    */
    private static void addUtilityFields(Map<String,BDI_ObjectMapping> objectMappingByDevName,
        Map<String,BDI_FieldMapping> fieldMappingByDevName,
        Map<String,BDI_FieldMapping[]> fieldMappingsByObjMappingDevName) {

        // TODO: Turn magic strings below into constants once custom labels/names are decided.
        BDI_ObjectMapping simulatedDataImportObjectMapping =
            constructSimulatedObjectMapping('Data_Import', 'Data Import', SObjectType.DataImport__c.Name);

        // Add the various 'Imported' lookup fields from Object Mappings as simulated Field Mappings
        for (String objectMappingDevName : objectMappingByDevName.keySet()) {
            BDI_ObjectMapping currentObjectMapping = objectMappingByDevName.get(objectMappingDevName);
            Schema.DescribeFieldResult unmappedFieldDescribe =
                UTIL_Describe.getFieldDescribe(
                    SObjectType.DataImport__c.Name,
                    currentObjectMapping.Imported_Record_Field_Name);

            BDI_FieldMapping simulatedFieldMapping =
                constructSimulatedFieldMapping(unmappedFieldDescribe, simulatedDataImportObjectMapping);

            fieldMappingByDevName.put(simulatedFieldMapping.DeveloperName, simulatedFieldMapping);
            if (fieldMappingsByObjMappingDevName.containsKey(objectMappingDevName)) {
                BDI_FieldMapping[] currentObjectMappings = fieldMappingsByObjMappingDevName.get(objectMappingDevName);
                currentObjectMappings.add(simulatedFieldMapping);
            }           
        }

        BDI_FieldMapping donationDonorField =
            constructSimulatedFieldMapping(
                SObjectType.DataImport__c.fields.Donation_Donor__c,
                simulatedDataImportObjectMapping);

        BDI_FieldMapping[] simulatedFieldMappings = new BDI_FieldMapping[] {donationDonorField};

        fieldMappingByDevName.put(donationDonorField.DeveloperName, donationDonorField);
        objectMappingByDevName.put(
            simulatedDataImportObjectMapping.DeveloperName,
            simulatedDataImportObjectMapping);
        fieldMappingsByObjMappingDevName.put(
            simulatedDataImportObjectMapping.DeveloperName,
            simulatedFieldMappings);
    }

    /*******************************************************************************************************
    * @description Method constructs an instance of BDI_ObjectMapping with the bare minimum required
    * fields for use in the addUtilityFields method. This is to support adding in fields that aren't
    * Field Mappings, but need to look like Field Mappings such as the DataImport__c.Donation_Donor__c field.
    *
    * @param developerName: Object Mapping developer name.
    * @param masterLabel: Object Mapping master label, this will display in the UI.
    * @param objectApiName: The target sObject API name.
     * @return BDI_ObjectMapping
    */
    private static BDI_ObjectMapping constructSimulatedObjectMapping(String developerName,
        String masterLabel,
        String objectApiName) {

        BDI_ObjectMapping objectMapping = new BDI_ObjectMapping();
        objectMapping.DeveloperName = developerName;
        objectMapping.MasterLabel = masterLabel;
        objectMapping.Object_API_Name = objectApiName;

        return objectMapping;
    }

    /*******************************************************************************************************
    * @description Method constructs an instance of BDI_FieldMapping with the bare minimum required
    * fields for use in the addUtilityFields method. This is to support adding in fields that aren't
    * Field Mappings, but need to look like Field Mappings such as the DataImport__c.Donation_Donor__c field.
    *
    * @param fieldDescribe: Describe info of the field we need a Field Mapping for.
    * @param parentObjectMapping: The parent object mapping this Field Mapping needs to reference.
    * @return BDI_FieldMapping
    */
    private static BDI_FieldMapping constructSimulatedFieldMapping(Schema.DescribeFieldResult fieldDescribe,
        BDI_ObjectMapping parentObjectMapping) {

        BDI_FieldMapping fieldMapping = new BDI_FieldMapping();
        String apiName = fieldDescribe.getName();
        String label = fieldDescribe.getLabel();

        fieldMapping.DeveloperName = apiName;
        fieldMapping.MasterLabel = label;
        fieldMapping.Source_Field_API_Name = apiName;
        fieldMapping.Source_Field_Required = false;
        fieldMapping.Target_Field_API_Name = apiName;
        fieldMapping.Target_Field_Data_Type = String.valueOf(fieldDescribe.getType());
        fieldMapping.Target_Field_Label    = label;
        fieldMapping.Target_Object_API_Name = parentObjectMapping.Object_API_Name;
        fieldMapping.Target_Object_Mapping_Dev_Name = parentObjectMapping.DeveloperName;

        return fieldMapping;
    }
}