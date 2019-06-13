/*
    Copyright (c) 2018, Salesforce.org
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
* @group Rollups
* @group-content ../../ApexDocContent/BatchDataImport.htm
* @description Wrapper classes for the Help Text mappings used to create Custom Metadata records
*/
public class BDI_HelpTextCMT {

    /**
     * @description Enum of the supported MetadataType objects (without the __mdt suffix)
     */
    public enum MetadataObject {
        Data_Import_Field_Mapping,
        Data_Import_Field_Mapping_Set
    }

    /**
     * @description Default value for the Protected_x property when inserting new Custom Metadata Type records
     */
    private static final Boolean IS_PROTECTED = false;

    /**
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
            String mdTypeName = UTIL_Namespace.StrTokenNSPrefix(BDI_HelpTextCMT.MetadataObject.Data_Import_Field_Mapping_Set.Name() + '__mdt');

            // Setup custom metadata to be created or updated in the subscriber org.
            Metadata.CustomMetadata customMd = new Metadata.CustomMetadata();
            customMd.label = this.label.left(40);
            this.recordName = this.label;
            customMd.fullName = mdTypeName + '.' + this.recordName.left(40).removeEnd('_');
            customMd.protected_x = IS_PROTECTED;

            Map<String, Object> fieldValues = new Map<String, Object>{
                'Data_Import_Object_Mapping_Set__c' => this.dataImportObjectMappingSetRecordName
            };
            customMd = addFieldsToMetadataObject(customMd, fieldValues);

            return customMd;
        }
    }

    /**
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

        public DataImportFieldMapping(String label) {
            this.label = label.trim();
        }

        public DataImportFieldMapping(String label, String sourceFieldAPIName, String dataImportObjectName,
            String targetFieldAPIName, String targetObjectAPIName) {

            this.label = label.trim();
            this.sourceFieldAPIName = sourceFieldAPIName;
            this.dataImportObjectName = dataImportObjectName;
            this.targetFieldAPIName = targetFieldAPIName;
            this.targetObjectAPIName = targetObjectAPIName;
        }

        public DataImportFieldMapping(DataImportFieldMapping sourceFieldMapping, String fieldMappingSet) {
            this.dataImportFieldMappingSetRecordName = fieldMappingSet;
            this.label = sourceFieldMapping.label;
            this.sourceFieldAPIName = sourceFieldMapping.sourceFieldAPIName;
            this.targetFieldAPIName = sourceFieldMapping.targetFieldAPIName;
            this.targetObjectMappingRecordName = sourceFieldMapping.targetObjectMappingRecordName;
            this.targetObjectMappingLabel = sourceFieldMapping.targetObjectMappingLabel;
            this.targetObjectAPIName = sourceFieldMapping.targetObjectAPIName;
            this.dataImportObjectName = sourceFieldMapping.dataImportObjectName;
            this.recordName = generateRecordName(this.label, true, null, this.dataImportObjectName);
            this.isRequired = 'No';
            this.isDeleted = false;
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
                this.recordName = generateRecordName(this.label, true, null, this.dataImportObjectName);
            } else {
                this.recordName = recordName;
            }
        }

        public Metadata.CustomMetadata getMetadataRecord() {
            String mdTypeName = UTIL_Namespace.StrTokenNSPrefix(BDI_HelpTextCMT.MetadataObject.Data_Import_Field_Mapping.Name() + '__mdt');

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
            customMd = addFieldsToMetadataObject(customMd, fieldValues);

            return customMd;
        }
    }

    /**
     * @description Wrapper class for help text field
     */
    public class HelpTextParts {
        public String objectName;
        public String fieldName;
        public String objectAPIName;

        public HelpTextParts(String helpText) {
            List<String> parts = helpText.split('\\.', 2);

            this.objectName = String.isNotBlank(parts[0]) ? parts[0] : null;
            this.fieldName = String.isNotBlank(parts[1]) ? parts[1] : null;

            if (String.isNotBlank(this.objectName)) {
                this.objectAPIName = DI_OBJECT_MAP.get(this.objectName);
            }
        }
    }

    /**
     * @description Set field values on the specified Custom Metadata Type record
     * @param customMetadata CustomMetadata instance
     * @param fieldValues Key-Value pair map of fields/values
     * @return Updated CustomMetadata object instance with the fields added to the values collection
     */
    private static Metadata.CustomMetadata addFieldsToMetadataObject(Metadata.CustomMetadata customMetadata,
        Map<String, Object> fieldValues) {

        Metadata.CustomMetadataValue customField;
        for (String fieldKey : fieldValues.keySet()) {
            customField = new Metadata.CustomMetadataValue();
            customField.field = UTIL_Namespace.StrAllNSPrefix(fieldKey);
            customField.value = fieldValues.get(fieldKey);
            customMetadata.values.add(customField);
        }
        return customMetadata;
    }

    /**
     * @description Utility to convert a name into a valid 'DeveloperName' quality value (or unique GUID)
     * for the CMT record
     * @param name String
     * @param makeUnique Boolean
     * @return DeveloperName format string
     */
    private static String generateRecordName(String name, Boolean makeUnique, String objectLabel, String objectAPIName) {
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

    /**
    * @description Map of legacy help text field data import object names to object api names
    */
    private static final Map<String, String> DI_OBJECT_MAP = new Map<String, String>{
        'Account1' => 'Account',
        'Account2' => 'Account',
        'Address' => UTIL_Namespace.StrTokenNSPrefix('Address__c'),
        'Contact1' => 'Contact',
        'Contact2' => 'Contact',
        'Household' => 'Account',
        'Opportunity' => 'Opportunity',
        'Donation' => 'Opportunity',
        'Payment' => 'npe01__OppPayment__c'
    };
}