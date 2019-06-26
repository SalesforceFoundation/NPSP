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
* @date 2018
* @group Batch Data Import
* @group-content ../../ApexDocContent/BatchDataImport.htm
* @description Visualforce page Controller for the Manage Advanced Mappings VF page
*/
public class BDI_ManageAdvancedMappingCtrl {

    private static BDI_FieldMappingCustomMetadata bdiCMT = BDI_FieldMappingCustomMetadata.getInstance();
    private static final String NAMESPACE = UTIL_Namespace.getNamespace();

    /** @description what is the namespace (an empty string if unmanaged, or 'npsp' if managed) */
    public string getNamespacePrefix() {
        return UTIL_Namespace.getNamespace();
    }

    @AuraEnabled(cacheable=true)
    public static Data_Import_Object_Mapping__mdt[] getObjectMappings(){
        Data_Import_Object_Mapping__mdt[] objMappings = bdiCMT.objMappingsByDevName.values();
        return objMappings;
    }

    @AuraEnabled(cacheable=true)
    public static DataImportFieldMappingWrapper[] getFieldMappingsByObjectAndFieldSetNames(
        String objectSetName, String fieldSetName) {

        DataImportFieldMappingWrapper[] fieldMappingWrappers =
            new List<DataImportFieldMappingWrapper>();
        Data_Import_Field_Mapping__mdt[] fieldMappings =
            bdiCMT.fieldMappingsByObjMappingDevName.get(objectSetName);

        for (Data_Import_Field_Mapping__mdt fieldMapping : fieldMappings) {
            if (fieldMapping.Data_Import_Field_Mapping_Set__r.DeveloperName == fieldSetName) {
                fieldMappingWrappers.add(new DataImportFieldMappingWrapper(fieldMapping));
            }
        }

        return fieldMappingWrappers;
    }

    @AuraEnabled(cacheable=true)
    public static String createDataImportFieldMapping(String fieldMappingString) {
        System.debug('createDataImportFieldMapping()');
        System.debug('difm: ' + fieldMappingString);
        try {
            DataImportFieldMapping difm =
                (DataImportFieldMapping)JSON.deserialize(fieldMappingString, DataImportFieldMapping.class);

            Metadata.CustomMetadata cmt = difm.getMetadataRecord();
            System.debug(cmt);
            Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
            mdContainer.addMetadata(cmt);
            
            // Setup deploy callback, MyDeployCallback implements
            // the Metadata.DeployCallback interface 
            CustomMetadataCallback callback = new CustomMetadataCallback();
        
            // Enqueue custom metadata deployment
            // jobId is the deployment ID
            Id jobId = Metadata.Operations.enqueueDeployment(mdContainer, callback);
            System.debug('***Custom Metadata Record Below:');
            System.debug(mdContainer);
            return JSON.serialize(cmt);
            
        } catch(Exception ex){
             System.assert(false,ex.getMessage()); 
             return 'Error while creating new button.';
        }
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, String> getDataImportFieldDescribes() {
        Map<String, String> useableDFRs = new Map<String, String>();
        Map<String, Schema.DescribeFieldResult> fieldDescribes =
            UTIL_Describe.getAllFieldsDescribe('DataImport__c');
        
        for (String key : fieldDescribes.keySet()) {
            System.debug('Key: ' + key);
            useableDFRs.put(fieldDescribes.get(key).label, key);
        }

        return useableDFRs;
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, String> getObjectFieldDescribes(String objectName) {
        Map<String, String> useableDFRs = new Map<String, String>();
        Map<String, Schema.DescribeFieldResult> fieldDescribes =
            UTIL_Describe.getAllFieldsDescribe(objectName);
        
        for (String key : fieldDescribes.keySet()) {
            useableDFRs.put(fieldDescribes.get(key).label, key);
        }

        return useableDFRs;
    }

    /*******************************************************************************************************
    * @description Wrapper class for Data_Import_Field_Mapping__mdt used to create
    * the default CMT data as well as for use in the Custom UI.
    */
    public class DataImportFieldMapping {
        public String recordName;
        public String label;
        public String dataImportFieldMappingSetName;
        public String sourceFieldAPIName;
        public String targetFieldAPIName;
        public String targetObjectMappingName;
        public Boolean isDeleted = false;
        public Boolean isRequired = false;

        public DataImportFieldMapping() {}

        // TODO: Make more generic
        public Metadata.CustomMetadata getMetadataRecord() {
            String mdTypeName = 'Data_Import_Field_Mapping__mdt';

            // Setup custom metadata to be created or updated in the subscriber org.
            Metadata.CustomMetadata customMd = new Metadata.CustomMetadata();

            recordName = generateRecordName(label);

            customMd.fullName = mdTypeName + '.' + this.recordName.left(40).removeEnd('_');
            customMd.protected_x = false;
            // TODO: remove debugging string
            customMd.label = 'AAA  ' + label;

            Map<String, Object> fieldValues;
            if (this.isDeleted != true) {

                if (NAMESPACE != 'npsp') {
                    this.targetFieldAPIName =
                        UTIL_Namespace.removeNSPrefixNpspOnly(this.targetFieldAPIName);
                }

                fieldValues = new Map<String, Object>{
                    'Data_Import_Field_Mapping_Set__c' => dataImportFieldMappingSetName == null ? 'Default_Field_Mapping_Set' : dataImportFieldMappingSetName,
                    'Required__c' => isRequired,
                    'Source_Field_API_Name__c' => sourceFieldAPIName,
                    'Target_Field_API_Name__c' => targetFieldAPIName,
                    'Target_Object_Mapping__c' => targetObjectMappingName,
                    'Is_Deleted__c' => isDeleted
                };
            } else {
                fieldValues = new Map<String, Object>{ 'Is_Deleted__c' => isDeleted };
            }
            customMd = CMT_MetadataAPI.addFieldsToMetadataObject(customMd, fieldValues);

            return customMd;
        }

        /****************************************************************************************************
        * @description Utility to convert a name into a valid 'DeveloperName' quality value (or unique GUID)
        * for the CMT record
        *
        * @param name String
        * @param makeUnique Boolean
        * @return DeveloperName format string
        */
        private String generateRecordName(String label) {
            String name = '';

            if (String.isNotBlank(label)) {
                name = label.replace(' ', '_');
            }

            if (name.length() > 30) {
                String firstFifteen = name.substring(0, 15);
                String lastFifteen = name.substring(name.length() - 15, name.length());
                name = firstFifteen + lastFifteen;
            }

            // Create a GUID format unique string
            Blob b = Crypto.GenerateAESKey(128);
            String h = EncodingUtil.ConvertTohex(b);
            // force everything to have a 9-char random string at the end
            name = name.left(30).removeEnd('_') + '_' + h.left(9);

            name = name.replaceAll('[^\\w]+', '_').replaceAll('_{2,}', '_');
            return name;
        }
    }


    public class DataImportFieldMappingWrapper {
        @AuraEnabled public String MasterLabel;
        @AuraEnabled public String Source_Field_API_Name;
        @AuraEnabled public String Target_Field_API_Name;
        @AuraEnabled public String Maps_To_Icon;
        @AuraEnabled public String Source_Field_Label;
        @AuraEnabled public String Source_Field_Data_Type;
        // TODO: Still needs to be assigned
        @AuraEnabled public String Target_Field_Data_Type;

        public DataImportFieldMappingWrapper(Data_Import_Field_Mapping__mdt fieldMapping) {
            Schema.DescribeFieldResult dfr = UTIL_Describe.getFieldDescribe(
                UTIL_Namespace.StrTokenNSPrefix('DataImport__c'),
                UTIL_Namespace.removeNSPrefixNpspOnly(fieldMapping.Source_Field_API_Name__c));

            this.MasterLabel = fieldMapping.MasterLabel;
            this.Source_Field_API_Name = fieldMapping.Source_Field_API_Name__c;
            this.Target_Field_API_Name = fieldMapping.Target_Field_API_Name__c;

            this.Maps_To_Icon = 'utility:forward';
            this.Source_Field_Label = dfr.label;
            this.Source_Field_Data_Type = String.valueOf(dfr.type);
        }
    }

    public class CustomMetadataCallback implements Metadata.DeployCallback {
        public void handleResult(Metadata.DeployResult result,
                                Metadata.DeployCallbackContext context) {
            if (result.status == Metadata.DeployStatus.Succeeded) {
                System.debug('success: '+ result);
            } else {
                // Deployment was not successful
                System.debug('fail: '+ result);
            }
        }
    }

}// BDI_ManageAdvancedMappingCtrl
