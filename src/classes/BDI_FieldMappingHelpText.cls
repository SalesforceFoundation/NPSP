/*
    Copyright (c) 2014 Salesforce.org
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
* @description Implement field mapping behavior for help text mapping scheme
*/

public with sharing class BDI_FieldMappingHelpText implements BDI_FieldMapping {


    private static BDI_FieldMappingHelpText fieldMappingInstance = null;

    /*******************************************************************************************************
    * @description manually specified mappings addition to those specified in help text
    */
    private Map<String,Map<String,String>> additionalFieldMappings = new Map<String,Map<String,String>>();

    /*******************************************************************************************************
    * @description Default value for the Protected_x property when inserting new Custom Metadata Type records
    */
    private static final Boolean IS_PROTECTED = false;

    /*******************************************************************************************************
    * @description return singleton instance of the class
    */
    public static BDI_FieldMappingHelpText getInstance() {
        if(fieldMappingInstance == null) {
            fieldMappingInstance = new BDI_FieldMappingHelpText();
        }
        return fieldMappingInstance;
    }

    /*******************************************************************************************************
    * @description Manually add a mapping
    *
    * @param targetObjectName the underlying object the bdi object is (ie, Contact, Account, etc)
    * @param sourceFieldName field name on the DI  object
    * @Param destinationFieldName  field name on the destination record
    */
    public void addMappedField(String targetObjectName, String sourceFieldName, String destinationFieldName) {
        if(!additionalFieldMappings.containsKey(targetObjectName)) {
            additionalFieldMappings.put(targetObjectName, new Map<String,String>());
        }
        additionalFieldMappings.get(targetObjectName).put(sourceFieldName, destinationFieldName);
    }

    /*******************************************************************************************************
    * @description For the provided fields (in the form DIObject.developerfieldname) and target object, 
    * return a map of DI field (key) to mapped field name on the destination record (value). 
    *
    * @param dataImportObjectName the bdi object we care about (Contact1, Contact2, Account1, etc)
    * @param targetObjectName the underlying object the bdi object is (ie, Contact, Account, etc)
    * @param dataImportFields the DataImport fields to consider
    * @return Map<String, String> a map of DataImport fields to underlying object fields (eg, Donation_Amount__c => Amount)
    */ 

    public Map<String,String> getFieldMap(String dataImportObjectName, 
        String targetObjectName, List<String> dataImportFields) {
        
        Map<String, String> targetFieldByDataImportField = new Map<String, String>();

        for (String dataImportField : dataImportFields) {

            DescribeFieldResult fieldDescribe =
                UTIL_Describe.getFieldDescribe(UTIL_Namespace.StrTokenNSPrefix('DataImport__c'), dataImportField);
            String helpText = fieldDescribe.getInlineHelpText();

            if (helpText != null && helpText != '') {
                List<String> parts = helpText.split('\\.', 2);

                if (parts.size() == 2 && parts[0] == dataImportObjectName && parts[1] != '') {
                    String fieldName = parts[1];
                    //if we aren't in the npsp namespace, remove those tokens from help text
                    //also removes tokens from actual detected namespace, if we happen to be
                    //in a non-npsp namespace
                    if (UTIL_Namespace.getNamespace() != 'npsp') {
                        String fieldNameOld = fieldName;
                        fieldName = UTIL_Namespace.StrTokenRemoveNSPrefix(fieldName);

                        //if we have a detected namespace, and removed a namespace from the current field
                        //add the current namespace back in, allowing this code to run in any namespace
                        if (fieldName != fieldNameOld && UTIL_Namespace.getNamespace() != '') {
                            fieldName = UTIL_Namespace.StrAllNSPrefix(fieldName);
                        }
                    }

                    targetFieldByDataImportField.put(dataImportField, fieldName);
                }
            }
        }

        if (isCurrencyMapped(targetObjectName)) {
            addCurrencyIsoCode(targetFieldByDataImportField);
        }

        if(additionalFieldMappings.containsKey(targetObjectName)) {
            for(String diField: additionalFieldMappings.get(targetObjectName).keySet()) {
                targetFieldByDataImportField.put(diField, 
                    additionalFieldMappings.get(targetObjectName).get(diField));
            }
        }

        return targetFieldByDataImportField;
    }

    /*******************************************************************************************************
    * @description Adds the currencyisocode to the Map passed as parameter.
    * @param Map<String, String> a map of DataImport fields to underlying object fields (eg, Donation_Amount__c => Amount)
    * @return void.
    */
    public void addCurrencyIsoCode(Map<String, String> fieldMap) {

        // handle multicurrency if it's enabled
        if (UserInfo.isMultiCurrencyOrganization()) {
            fieldMap.put('currencyisocode', 'CurrencyIsoCode');
        }
    }

    /*******************************************************************************************************
    * @description Checks if this is one of the objects where we want to have a currency mapped.
    * As of now, that object is Opportunity. Payment CurrencyISOCode is inherited from the Opportunity.
    * @param strBaseObj the underlying object the bdi object is (ie, Contact, Account, etc)
    * @return Boolean if the strBaseObj is an Opportunity.
    */
    public Boolean isCurrencyMapped(String objectName) {
        return objectName.equalsIgnoreCase('Opportunity');
    }

    /*******************************************************************************************************
    * @description Wrapper class for Data_Import_Field_Mapping_Set__mdt used to create
    * the custom CMT data as well as for use in the Custom UI.
    */
    public class DataImportFieldMappingSet {
        public String recordName;
        public String label;
        public String dataImportObjectMappingSetRecordName;

        public DataImportFieldMappingSet(String label, String dataImportObjectMappingSetRecordName) {
            this.label = label.trim();
            this.dataImportObjectMappingSetRecordName = dataImportObjectMappingSetRecordName;
        }

        public Metadata.CustomMetadata getMetadataRecord() {
            String mdTypeName = UTIL_Namespace.StrTokenNSPrefix('Data_Import_Field_Mapping_Set__mdt');

            // Setup custom metadata to be created or updated in the subscriber org.
            Metadata.CustomMetadata customMd = new Metadata.CustomMetadata();
            customMd.label = this.label.left(40);
            this.recordName = this.label;
            customMd.fullName = mdTypeName + '.' + this.recordName.left(40).removeEnd('_');
            customMd.protected_x = IS_PROTECTED;

            Map<String, Object> fieldValues = new Map<String, Object>{
                'Data_Import_Object_Mapping_Set__c' => this.dataImportObjectMappingSetRecordName
            };
            customMd = CMT_MetadataAPI.addFieldsToMetadataObject(customMd, fieldValues);

            return customMd;
        }
    }

    /*******************************************************************************************************
    * @description Wrapper class for Data_Import_Field_Mapping__mdt used to create
    * the default CMT data as well as for use in the Custom UI.
    */
    public class DataImportFieldMapping {
        public String recordName;
        public String label {get; set;}
        public String dataImportObjectName {get; set;}
        public String dataImportFieldMappingSetRecordName;
        public String dataImportFieldMappingSetLabel;
        public String sourceFieldAPIName;
        public String targetFieldAPIName {get; set;}
        public String targetObjectMappingRecordName;
        public String targetObjectMappingLabel;
        public String targetObjectAPIName;
        public String isRequired;
        public Boolean isDeleted;
        public String importedRecordField;
        public String importedRecordStatusField;

        public DataImportFieldMapping(String label, String sourceFieldAPIName, String dataImportObjectName,
            String targetFieldAPIName, String targetObjectAPIName) {

            this.label = label.trim();
            this.sourceFieldAPIName = sourceFieldAPIName;
            this.dataImportObjectName = dataImportObjectName;
            this.targetFieldAPIName = targetFieldAPIName;
            this.targetObjectAPIName = targetObjectAPIName;
        }

        public DataImportFieldMapping(Data_Import_Field_Mapping__mdt sourceFieldMapping, String fieldMappingSet) {
            this.dataImportFieldMappingSetRecordName = fieldMappingSet;
            this.label = sourceFieldMapping.MasterLabel;
            this.sourceFieldAPIName = sourceFieldMapping.Source_Field_API_Name__c;
            this.targetFieldAPIName = sourceFieldMapping.Target_Field_API_Name__c;
            this.targetObjectMappingRecordName = sourceFieldMapping.Target_Object_Mapping__r.DeveloperName;
            this.targetObjectMappingLabel = sourceFieldMapping.Target_Object_Mapping__r.MasterLabel;
            this.dataImportObjectName = sourceFieldMapping.Target_Object_Mapping__r.DeveloperName;
            this.targetObjectAPIName = sourceFieldMapping.Target_Object_Mapping__r.Object_API_Name__c;
            this.recordName = sourceFieldMapping.DeveloperName;
            this.isRequired = 'No';
            this.isDeleted = false;
        }

        public void setInstance(Data_Import_Object_Mapping__mdt objectMapping,
            String fieldMappingSetName) {

            this.targetObjectMappingLabel = objectMapping.Label;
            this.targetObjectMappingRecordName = objectMapping.DeveloperName;
            this.dataImportFieldMappingSetRecordName = fieldMappingSetName;
        }

        public void setInstance(Data_Import_Object_Mapping__mdt objectMapping,
            String fieldMappingSetName,
            String targetFieldAPIName) {

            this.targetObjectMappingLabel = objectMapping.Label;
            this.targetObjectMappingRecordName = objectMapping.DeveloperName;
            this.dataImportFieldMappingSetRecordName = fieldMappingSetName;
            this.targetFieldAPIName = targetFieldAPIName;
        }

        public void setRecordName(String recordName, Boolean isUnique) {
            if (isUnique) {
                this.recordName = generateRecordName(this.label, true, this.targetObjectMappingLabel, this.dataImportObjectName);
            } else {
                this.recordName = recordName;
            }
        }

        public Metadata.CustomMetadata getMetadataRecord() {
            String mdTypeName = UTIL_Namespace.StrTokenNSPrefix('Data_Import_Field_Mapping__mdt');

            // Setup custom metadata to be created or updated in the subscriber org.
            Metadata.CustomMetadata customMd = new Metadata.CustomMetadata();
            customMd.label = this.label.replace(this.dataImportObjectName, this.targetObjectMappingLabel).left(40);
            if (this.recordName == null) {
                this.recordName = generateRecordName(this.label, true, this.targetObjectMappingLabel, this.dataImportObjectName);
            }
            customMd.fullName = mdTypeName + '.' + this.recordName.left(40).removeEnd('_');
            customMd.protected_x = IS_PROTECTED;

            // Convert an empty string ('') value into null for the entity reference to save properly.
            if (String.isEmpty(this.dataImportFieldMappingSetRecordName)) {
                this.dataImportFieldMappingSetRecordName = null;
            }

            // Convert an empty string ('') value into null for the entity reference to save properly.
            if (String.isEmpty(this.targetObjectMappingRecordName)) {
                this.targetObjectMappingRecordName = null;
            }

            Map<String, Object> fieldValues;
            if (this.isDeleted != true) {
                fieldValues = new Map<String, Object>{
                    'Data_Import_Field_Mapping_Set__c' => dataImportFieldMappingSetRecordName == null ? 'Default_Field_Mapping_Set' : dataImportFieldMappingSetRecordName,
                    'Required__c' => isRequired,
                    'Source_Field_API_Name__c' => sourceFieldAPIName,
                    'Target_Field_API_Name__c' => targetFieldAPIName,
                    'Target_Object_Mapping__c' => targetObjectMappingRecordName,
                    'Is_Deleted__c' => isDeleted
                };
            } else {
                fieldValues = new Map<String, Object>{ 'Is_Deleted__c' => isDeleted };
            }
            customMd = CMT_MetadataAPI.addFieldsToMetadataObject(customMd, fieldValues);

            return customMd;
        }

        /*******************************************************************************************************
        * @description Utility to convert a name into a valid 'DeveloperName' quality value (or unique GUID)
        * for the CMT record
        *
        * @param name String
        * @param makeUnique Boolean
        * @return DeveloperName format string
        */
        private String generateRecordName(String name, Boolean makeUnique, String objectLabel, String objectAPIName) {
            name = name.replaceAll('[^\\w]+', '_').replaceAll('_{2,}', '_');

            if (String.isNotBlank(objectLabel)) {
                objectLabel = objectLabel.replace(' ', '_');
                name = name.replace(objectAPIName, objectLabel);
            }

            if (name.length() > 30) {
                String firstFifteen = name.substring(0, 15);
                String lastFifteen = name.substring(name.length() - 15, name.length());
                name = firstFifteen + lastFifteen;
            }

            if (makeUnique == true) {
                // Create a GUID format unique string
                Blob b = Crypto.GenerateAESKey(128);
                String h = EncodingUtil.ConvertTohex(b);
                // force everything to have a 9-char random string at the end
                name = name.left(30).removeEnd('_') + '_' + h.left(9);
            } else {
                name = name.left(40);
            }

            return name;
        }
    }
}