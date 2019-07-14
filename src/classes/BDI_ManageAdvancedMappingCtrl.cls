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

    /** @description what is the namespace (an empty string if unmanaged, or 'npsp' if managed) */
    public string getNamespacePrefix() {
        return UTIL_Namespace.getNamespace();
    }

    /*******************************************************************************************************
    * @description Instance of BDI_FieldMappingCustomMetadata
    */
    private static BDI_FieldMappingCustomMetadata bdiCMT = BDI_FieldMappingCustomMetadata.getInstance();

    /*******************************************************************************************************
    * @description Current package namespace
    */
    private static final String NAMESPACE = UTIL_Namespace.getNamespace();

    /*******************************************************************************************************
    * @description Name of default packaged Object Mapping Set
    */
    private static final Set<String> IGNORE_FIELDS = new Set<String> {
        'developername',
        'masterlabel',
        'language',
        'namespaceprefix',
        'label',
        'qualifiedapiname',
        'id'};

    /*******************************************************************************************************
    * @description Name of the default Field Mapping Set
    *
    * @return String: Default Field Mapping Set name
    */
    @AuraEnabled(cacheable=true)
    public static String getFieldMappingSetName() {
        return UTIL_CustomSettings_API.getDataImportSettings().Default_Data_Import_Field_Mapping_Set__c;
    }

    /*******************************************************************************************************
    * @description Gets all the existing Data Import Object Mapping records.
    *
    * @return List: List of Data Import Object Mapping
    */
    @AuraEnabled(cacheable=true)
    public static Data_Import_Object_Mapping__mdt[] getObjectMappings(){
        return bdiCMT.objMappingsByDevName.values();
    }

    /*******************************************************************************************************
    * @description Gets all the field describes from a given object.
    *
    * @param objectName: Object name
    *
    * @return List: List of BDI_ManageAdvancedMappingCtrl.FieldInfo
    */
    @AuraEnabled
    public static FieldInfo[] getObjectFieldDescribes(String objectName) {
        Map<String, String> useableDFRs = new Map<String, String>();
        FieldInfo[] fieldInfos = new List<FieldInfo>();

        objectName = UTIL_Namespace.StrAllNSPrefix(objectName);

        Map<String, Schema.DescribeFieldResult> fieldDescribes =
            UTIL_Describe.getAllFieldsDescribe(objectName);

        for (String key : fieldDescribes.keySet()) {
            fieldInfos.add(new FieldInfo(fieldDescribes.get(key)));
        }

        return fieldInfos;
    }

    /*******************************************************************************************************
    * @description Gets Data Import Field Mapping records based on their parent object and a Field Mapping
    * Set name and converts each to instances of DataImportFieldMappingWrapper for use in the UI.
    *
    * @param objectName: Object name
    * @param fieldMappingSetname: Field Mapping Set name
    *
    * @return List: List of DataImportFieldMappingWrapper
    */
    @AuraEnabled
    public static DataImportFieldMappingWrapper[] getFieldMappingsByObjectAndFieldSetNames(
        String objectName, String fieldMappingSetname) {

        DataImportFieldMappingWrapper[] fieldMappingWrappers =
            new List<DataImportFieldMappingWrapper>();

        Data_Import_Field_Mapping__mdt[] fieldMappings =
            bdiCMT.fieldMappingsByObjMappingDevName.get(objectName);

        for (Data_Import_Field_Mapping__mdt fieldMapping : fieldMappings) {

            if (fieldMapping.Data_Import_Field_Mapping_Set__r.DeveloperName == fieldMappingSetname &&
                fieldMapping.Is_Deleted__c == false) {

                fieldMappingWrappers.add(new DataImportFieldMappingWrapper(fieldMapping));
            }
        }

        return fieldMappingWrappers;
    }

    /*******************************************************************************************************
    * @description Converts a JSON string of a DataImportFieldMappingWrapper to an instance of
    * Data_Import_Field_Mapping__mdt. Replaces the prefix 'xxx_' with the namespace if necessary
    * and replaces the suffix '_xxx' with '__c' if necessary.
    *
    * @param fieldMappingString: DataImportFieldMappingWrapper as JSON
    *
    * @return String: Deployment Id
    */
    @AuraEnabled
    public static String createDataImportFieldMapping(String fieldMappingString) {
        fieldMappingString = fieldMappingString.replaceAll('_xxx','__c');

        if (NAMESPACE == 'npsp') {
            fieldMappingString = fieldMappingString.replaceAll('xxx_','npsp__');
        } else {
            fieldMappingString = fieldMappingString.replaceAll('xxx_','');
        }

        try {
            Data_Import_Field_Mapping__mdt difm =
                (Data_Import_Field_Mapping__mdt)JSON.deserialize(
                    fieldMappingString, Data_Import_Field_Mapping__mdt.class);

            String deploymentId = enqueueMetadataRecords(difm);

            return deploymentId;
        } catch (Exception e) {
            throw e;
        }
    }

    /*******************************************************************************************************
    * @description Method takes in a list of generic sObjects and casts them a relevant metadata type.
    * Builds the deployment container, metadata type records along with their fields, and enqueues them
    * for deployment.
    *
    * @param customMetadataList: List of generic sObjects to be converted to custom metadata type records
    *
    * @return String: Deployment Id
    */
    public static String enqueueMetadataRecords(List<sObject> customMetadataList ) {
        Metadata.DeployContainer deployContainer = new Metadata.DeployContainer();

        for(sobject sObjectCastedCustomMetadata : customMetadataList) {

            //Get metadata object name and details
            String sObjectName = sObjectCastedCustomMetadata.getSObjectType().getDescribe().getName();

            //Create custom Metadata instance
            Metadata.CustomMetadata customMetadata =  new Metadata.CustomMetadata();

            String developerName = String.valueOf(sObjectCastedCustomMetadata.get('DeveloperName'));
            String recordName;

            if (developerName == null) {
                recordName = generateRecordName(String.valueOf(sObjectCastedCustomMetadata.get('MasterLabel')));
            } else {
                recordName = developerName;
            }

            customMetadata.fullName = sObjectName + '.' + recordName;
            customMetadata.label = (String)sObjectCastedCustomMetadata.get('MasterLabel');

            schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(sObjectName );

            Map<String, Schema.sObjectField> sObjectFields = sObjectType.getDescribe().fields.getMap();

            for(String fieldName : sObjectCastedCustomMetadata.getPopulatedFieldsAsMap().keySet()) {

                Boolean invalidField =
                    IGNORE_FIELDS.contains(fieldName.toLowerCase()) ||
                    sObjectCastedCustomMetadata.get(fieldName) == null;

                if (invalidField) {
                    continue;
                }

                Object value = sObjectCastedCustomMetadata.get(fieldName);

                if (value != null) {
                    Metadata.CustomMetadataValue customField = new Metadata.CustomMetadataValue();

                    customField.field = fieldName;

                    if (value instanceof Id) {
                        customField.value = (Id)value;
                    }
                    if (value instanceof String) {
                        customField.value = (String)value;
                    }
                    if (value instanceof Boolean) {
                        customField.value = (Boolean)value;
                    }

                    customMetadata.values.add(customField);
                } else {
                    continue;
                }
            }

            deployContainer.addMetadata(customMetadata);
        }

        DeploymentCallback callback = new DeploymentCallback();

        Id jobId = Metadata.Operations.enqueueDeployment(deployContainer, callback);

        return jobId;
    }

    /*******************************************************************************************************
    * @description Method takes in a single of generic sObject and cast it a relevant metadata type.
    * Builds the deployment container, metadata type record along with its fields, and enqueues it
    * for deployment.
    *
    * @param customMetadataList: A generic sObject to be converted to custom metadata type record
    *
    * @return String: Deployment Id
    */
    public static String enqueueMetadataRecords(sObject customMetadata ) {
        return enqueueMetadataRecords(new List<sObject>{customMetadata} );
    }

    /****************************************************************************************************
    * @description Utility to convert a name into a valid 'DeveloperName' quality value (or unique GUID)
    * for the CMT record
    *
    * @param name String
    * @param makeUnique Boolean
    * @return DeveloperName format string
    */
    public static String generateRecordName(String label) {
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

    /*******************************************************************************************************
    * @description Data_Import_Field_Mapping__mdt wrapper class used in the Field Mapping UI and for
    * building corresponding custom metadata type records. Attributes have prefix 'xxx_' and suffix '_xxx'
    * because we build instances of DataImportFieldMappingWrapper in the lightning web component and
    * later replace the prefix with the namespace and the suffix with '__c' and deserialize to
    * Data_Import_Field_Mapping__mdt.
    */
    public class DataImportFieldMappingWrapper {
        @AuraEnabled public String DeveloperName;
        @AuraEnabled public String MasterLabel;
        @AuraEnabled public String Label;
        @AuraEnabled public String Maps_To_Icon;
        @AuraEnabled public String xxx_Source_Field_Label_xxx;
        @AuraEnabled public String xxx_Source_Field_API_Name_xxx;
        @AuraEnabled public String xxx_Source_Field_Data_Type_xxx;
        @AuraEnabled public String xxx_Target_Field_Label_xxx;
        @AuraEnabled public String xxx_Target_Field_API_Name_xxx;
        @AuraEnabled public String xxx_Target_Field_Data_Type_xxx;
        @AuraEnabled public String xxx_Data_Import_Field_Mapping_Set_xxx;
        @AuraEnabled public String xxx_Target_Object_Mapping_xxx;
        @AuraEnabled public String xxx_Required_xxx;
        @AuraEnabled public Boolean xxx_Is_Deleted_xxx;

        public DataImportFieldMappingWrapper(Data_Import_Field_Mapping__mdt fieldMapping) {
            String dataImport = 'npsp__DataImport__c';
            String objectAPIName = fieldMapping.Target_Object_Mapping__r.Object_API_Name__c;
            String sourceFieldAPIName = fieldMapping.Source_Field_API_Name__c;
            String targetFieldAPIName = fieldMapping.Target_Field_API_Name__c;

            if (NAMESPACE != 'npsp') {
                dataImport = 'DataImport__c';
                objectAPIName =
                    UTIL_Namespace.removeNSPrefixNpspOnly(fieldMapping.Target_Object_Mapping__r.Object_API_Name__c);
                sourceFieldAPIName =
                    UTIL_Namespace.removeNSPrefixNpspOnly(fieldMapping.Source_Field_API_Name__c);
                targetFieldAPIName =
                    UTIL_Namespace.removeNSPrefixNpspOnly(fieldMapping.Target_Field_API_Name__c);
            }

            Schema.DescribeFieldResult sourceFieldDescribe = UTIL_Describe.getFieldDescribe(
                dataImport,
                sourceFieldAPIName);

            Schema.DescribeFieldResult targetFieldDescribe = UTIL_Describe.getFieldDescribe(
                objectAPIName,
                targetFieldAPIName);

            this.DeveloperName = fieldMapping.DeveloperName;
            this.MasterLabel = fieldMapping.MasterLabel;
            this.Label = fieldMapping.MasterLabel;
            this.xxx_Source_Field_Label_xxx = sourceFieldDescribe.label;
            this.xxx_Source_Field_API_Name_xxx = fieldMapping.Source_Field_API_Name__c;
            this.xxx_Source_Field_Data_Type_xxx = String.valueOf(sourceFieldDescribe.type);

            this.xxx_Target_Field_Label_xxx = targetFieldDescribe.label;
            this.xxx_Target_Field_API_Name_xxx = fieldMapping.Target_Field_API_Name__c;
            this.xxx_Target_Field_Data_Type_xxx = String.valueOf(targetFieldDescribe.type);

            this.Maps_To_Icon = 'utility:forward';

            this.xxx_Data_Import_Field_Mapping_Set_xxx = fieldMapping.Data_Import_Field_Mapping_Set__r.DeveloperName;
            this.xxx_Target_Object_Mapping_xxx = fieldMapping.Target_Object_Mapping__r.DeveloperName;
            this.xxx_Required_xxx = fieldMapping.Required__c;
            this.xxx_Is_Deleted_xxx = fieldMapping.Is_Deleted__c;
        }
    }

    /*******************************************************************************************************
    * @description Wrapper class for Field Describe Results used in the Field Mapping UI
    */
    public class FieldInfo {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        @AuraEnabled public String displayType;

        public FieldInfo(DescribeFieldResult dfr) {
            this.value = dfr.getName();
            this.label = dfr.getLabel();
            this.displayType = dfr.getType().name();
        }
    }

    /*******************************************************************************************************
    * @description Inserting or Updating Custom Metadata Types through the Apex Metadata API is an
    * asynchronous process. This callback class is used to handle the async response from the call to
    * Metadata.Operations.enqueueDeployment().
    */
    public class DeploymentCallback implements Metadata.DeployCallback {

        public void handleResult(
                Metadata.DeployResult deployResult,
                Metadata.DeployCallbackContext context) {

            DeploymentEvent__e de = new DeploymentEvent__e(
                    DeploymentId__c = deployResult.id,
                    Status__c = deployResult.status.name(),
                    CompletedDate__c = deployResult.completedDate
            );

            Database.SaveResult saveResult = EventBus.publish(de);

            if (!saveResult.isSuccess()) {
                for (Database.Error error : saveResult.getErrors()) {
                    //TODO: collaborate with docs on label/text value in the event that a deployment fails
                    throw new AuraHandledException('Error returned: ' +
                            error.getStatusCode() + ' - ' +
                            error.getMessage());
                }
            }
        }
    }

}// BDI_ManageAdvancedMappingCtrl
