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

    @AuraEnabled
    public static DataImportFieldMappingWrapper[] getFieldMappingsByObjectAndFieldSetNames(
        String objectName) {

        Data_Import_Settings__c dataImportSettings = Data_Import_Settings__c.getInstance();
        String fieldSetName = dataImportSettings.Default_Data_Import_Field_Mapping_Set__c;
        DataImportFieldMappingWrapper[] fieldMappingWrappers =
            new List<DataImportFieldMappingWrapper>();

        Data_Import_Field_Mapping__mdt[] fieldMappings =
            bdiCMT.fieldMappingsByObjMappingDevName.get(objectName);

        for (Data_Import_Field_Mapping__mdt fieldMapping : fieldMappings) {

            if (fieldMapping.Data_Import_Field_Mapping_Set__r.DeveloperName == fieldSetName &&
                fieldMapping.Is_Deleted__c == false) {

                fieldMappingWrappers.add(new DataImportFieldMappingWrapper(fieldMapping));
            }
        }

        return fieldMappingWrappers;
    }

    // Method takes in field mapping as JSON
    // Uses the DataImportFieldMapping wrapper to generate the custom metadata record
    // Drops it into a DeployContainer
    // Sends it off to be deployed
    // Return the jobId
    @AuraEnabled
    public static String createDataImportFieldMapping(String fieldMappingString) {
        System.debug(LoggingLevel.ERROR, 'createDataImportFieldMapping()');
        System.debug(fieldMappingString);
        // TODO: Delete later. Used to test error toast in UI
        //throw new testerException('SOMETHING WENT WRONG');
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
            System.debug(difm);
            String deploymentId = enqueueMetadataRecords(difm);

            return deploymentId;
        } catch (Exception e) {
            throw e;
        }
    }

    // TODO: Delete later? Used to test error toast in UI
    public class testerException extends Exception {}

    // TODO: Break up into smaller methods?
    // Does the bulk of the work converting records to custom metadata that are enqueueable
    public static String enqueueMetadataRecords(List<sObject> customMetadataList ) {
        //Create Deployment container for custom Metadata
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
            customMetadata.fullName = sObjectName +'.'+recordName;
            customMetadata.label = (String)sObjectCastedCustomMetadata.get('MasterLabel');

            // Get all fields
            // Store sObjectType schema in class variable (map) and check if already exists
            // before attempting to call the global describe again
            // OR
            // Use lightning web component to get the describe and pass in to apex
            schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(sObjectName );

            Map<String, Schema.sObjectField> sObjectFields = sObjectType.getDescribe().fields.getMap();
            // TODO: Hoist up and make final
            Set<String> skipFieldSet = new Set<String>{'developername','masterlabel','language','namespaceprefix', 'label','qualifiedapiname', 'id'};

            // Use getPopulatedFieldsAsMap to loop through and populate all fields with relevant values
            // Maybe break this section out into its own method?
            for(String fieldName : sObjectCastedCustomMetadata.getPopulatedFieldsAsMap().keySet()) {

                if(skipFieldSet.contains(fieldName.toLowerCase()) || sObjectCastedCustomMetadata.get(fieldName) == null) {
                    continue;
                }

                Object value = sObjectCastedCustomMetadata.get(fieldName);

                if (value != null) {
                    // TODO: Improve casting/type checking
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
                    //Add fields in the object, similar to creating sObject instance
                    customMetadata.values.add(customField);
                } else {
                    continue;
                }
            }

            //Add metadata to deployment container
            deployContainer.addMetadata(customMetadata);
        }

        // Callback class instance
        CustomMetadataCallback callback = new CustomMetadataCallback();

        // Enqueue custom metadata deployment
        Id jobId = Metadata.Operations.enqueueDeployment(deployContainer, callback);
        return jobId;
    }

    // overload, use to pass single metadata instance
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

            System.debug('DataImportFieldMappingWrapper');
            System.debug('NAMESPACE: ' + NAMESPACE);
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
    * @description Check the status of metadata deployment
    * @return Metadata.DeployResult JSON
    */
    @AuraEnabled
    public static Metadata.DeployResult getDeploymentResult(Id deploymentId) {
        System.debug('getDeploymentResult()');
        System.debug(deploymentId);
        Http h = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:Metadata_Deployment_Result/' +
            '/services/data/v44.0/metadata/deployRequest/' +
            deploymentId +
            '?includeDetails=true');
        request.setMethod('GET');
        //request.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
        HttpResponse response = h.send(request);
        System.debug(response.getBody());
        DeploymentResponse deploymentResponse =
            (DeploymentResponse)JSON.deserialize(response.getBody(), DeploymentResponse.class);

        return deploymentResponse.deployResult;
    }

    /*******************************************************************************************************
    * @description Wrapper used to deserialize the deployment request response
    */
    private class DeploymentResponse {
        Metadata.DeployResult deployResult;
    }

    public class CustomMetadataCallback implements Metadata.DeployCallback {
        public void handleResult(Metadata.DeployResult result,
                                Metadata.DeployCallbackContext context) {
            if (result.status == Metadata.DeployStatus.Succeeded) {
                System.debug('END TIME: ' + DateTime.now());
                System.debug('success: '+ result);
                // Trying out Platform Events for checking the deployment status
                /*List<Custom_Metadata_Data_Deployment__e> deploymentEvents =
                    new List<Custom_Metadata_Data_Deployment__e>();
                deploymentEvents.add(new Custom_Metadata_Data_Deployment__e(Test__c='Test'));

                // Call method to publish events
                List<Database.SaveResult> results = EventBus.publish(deploymentEvents);

                // Inspect publishing result for each event
                for (Database.SaveResult sr : results) {
                    if (sr.isSuccess()) {
                        System.debug('Successfully published event.');
                    } else {
                        for(Database.Error err : sr.getErrors()) {
                            System.debug('Error returned: ' +
                                        err.getStatusCode() +
                                        ' - ' +
                                        err.getMessage());
                        }
                    }       
                }*/
            } else {
                // Deployment was not successful
                System.debug('fail: '+ result);
            }
        }
    }

}// BDI_ManageAdvancedMappingCtrl
