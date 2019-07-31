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
* @description Visualforce page Controller for the Manage Advanced Mappings VF page
*/
public class BDI_ManageAdvancedMappingCtrl {
    
    /** @description what is the namespace (an empty string if unmanaged, or 'npsp' if managed) */
    @AuraEnabled(cacheable=true)
    public static string getNamespacePrefix() {
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
    * @description SLDS icon utility:forward used in the field mapping datatable rows
    */
    private static final String UTILITY_FORWARD_SLDS_ICON = 'utility:forward';

    private static final Set<String> IGNORE_FIELDS = new Set<String> {
        'developername',
        'masterlabel',
        'language',
        'namespaceprefix',
        'label',
        'qualifiedapiname',
        'id'};

    /*******************************************************************************************************
    * @description Map of labels by display types used in the field mapping UI
    */
    private static final Map<String, String> LABELS_BY_DISPLAY_TYPE = new Map<String, String> {
        'ADDRESS' => 'Address',
        'BASE64' => 'Base64',
        'BOOLEAN' => 'Checkbox',
        'COMBOBOX' => 'Picklist',
        'CURRENCY' => 'Currency',
        'DATACATEGORYGROUPREFERENCE' => 'DataCategoryGroupReference',
        'DATE' => 'Date',
        'DATETIME' => 'Date/Time',
        'DOUBLE' => 'Number',
        'EMAIL' => 'Email',
        'ENCRYPTEDSTRING' => 'Text (Encrypted)',
        'ID' => 'Id',
        'INTEGER' => 'Number',
        'LONG' => 'Text Area (Long)',
        'MULTIPICKLIST' => 'Picklist (Multi-Select)',
        'PERCENT' => 'Percent',
        'PHONE' => 'Phone',
        'PICKLIST' => 'Picklist',
        'REFERENCE' => 'Lookup Relationship',
        'STRING' => 'Text',
        'TEXTAREA' => 'Text Area',
        'TIME' => 'Time',
        'URL' => 'URL'
    };

    /*******************************************************************************************************
    * @description This is a list of the standard objects we will let users choose from (plus custom objects) 
    * when creating a new object mappping.  This is necessary since there are hundreds of standard objects
    * and including them all would negatively impact performance and make the list unusable.
    */ 
    private static final Set<String> STANDARD_OBJECT_WHITELIST = new Set<String>{'account', 'asset', 'assetrelationship', 
                                                            'campaign', 'campaignmember', 'case', 
                                                            'contact', 'contract', 'event', 'lead', 
                                                            'opportunity', 'opportunitylineitem', 
                                                            'order', 'orderitem', 'pricebook2', 
                                                            'pricebookEntry', 'product2', 'task', 
                                                            'user','opportunitycontactrole','contactrole','workorder'};

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
    * @description List of Platform Events created from Metadata deployments
    */
    @TestVisible
    private static DeploymentEvent__e[] deploymentEvents = new List<DeploymentEvent__e>();

    /*******************************************************************************************************
    * @description Gets all the existing Data Import Object Mapping records and wraps them for use in the 
    * component
    * @return List: List of Data Import Object Mapping
    */
    @AuraEnabled(cacheable=false)
    public static DataImportObjectMappingWrapper[] getObjectMappings(){

        DataImportObjectMappingWrapper[] objMappingWrappers = new DataImportObjectMappingWrapper[]{};
        Data_Import_Object_Mapping__mdt[] objMappings = bdiCMT.objMappingsByDevName.values();

        Map<String,DataImportObjectMappingWrapper> objMappingWrappersByDevName = new Map<String,DataImportObjectMappingWrapper>();

        for (Data_Import_Object_Mapping__mdt objMapping : objMappings) {
            DataImportObjectMappingWrapper objMappingWrapper = new DataImportObjectMappingWrapper(objMapping);
            objMappingWrappers.add(objMappingWrapper);
            objMappingWrappersByDevName.put(objMappingWrapper.DeveloperName, objMappingWrapper);
        }

        //Assign the label name field for the predecessor using the constructed map by dev name.
        for (DataImportObjectMappingWrapper objMappingWrapper : objMappingWrappers) {

            DataImportObjectMappingWrapper predecessorObjMappingWrapper = objMappingWrappersByDevName.get(objMappingWrapper.Predecessor);
            if(predecessorObjMappingWrapper != null) {
                objMappingWrapper.Predecessor_Label_Name = predecessorObjMappingWrapper.MasterLabel;
            }
        }

        return objMappingWrappers;
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
        FieldInfo[] fieldInfos = new List<FieldInfo>();

        objectName = UTIL_Namespace.StrAllNSPrefix(objectName);

        Map<String, Schema.DescribeFieldResult> fieldDescribes =
            UTIL_Describe.getAllFieldsDescribe(objectName);

        for (String key : fieldDescribes.keySet()) {

            //Only include fields that are createable by the current user
            //This will filter out System / formula fields
            if (fieldDescribes.get(key).isCreateable()) {
                fieldInfos.add(new FieldInfo(fieldDescribes.get(key)));
            }
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

        if (fieldMappings != null) {
            for (Data_Import_Field_Mapping__mdt fieldMapping : fieldMappings) {

            if (fieldMapping.Data_Import_Field_Mapping_Set__r.DeveloperName == fieldMappingSetname &&
                fieldMapping.Is_Deleted__c == false) {

                    fieldMappingWrappers.add(new DataImportFieldMappingWrapper(fieldMapping));
                }
            }
        }

        return fieldMappingWrappers;
    }

    /*******************************************************************************************************
    * @description Converts a JSON string of a DataImportFieldMappingWrapper to an instance of
    * Data_Import_Field_Mapping__mdt.
    *
    * @param fieldMappingString: DataImportFieldMappingWrapper as JSON
    *
    * @return String: Deployment Id or Data_Import_Field_Mapping__mdt instance JSON when in tests
    */
    @AuraEnabled
    public static String createDataImportFieldMapping(String fieldMappingString) {
        try {
            DataImportFieldMappingWrapper fieldMappingWrapper =
                (DataImportFieldMappingWrapper)JSON.deserialize(fieldMappingString, DataImportFieldMappingWrapper.class);

            String diFieldMappingSetFieldName = 'npsp__Data_Import_Field_Mapping_Set__c';
            String targetObjectMappingFieldName = 'npsp__Target_Object_Mapping__c';
            if (NAMESPACE != 'npsp') {
                diFieldMappingSetFieldName = diFieldMappingSetFieldName.replaceFirst('npsp__', '');
                targetObjectMappingFieldName = targetObjectMappingFieldName.replaceFirst('npsp__', '');
            }

            //This is a workaround to get the developer name of the Data Import Object Mapping Set into the field since
            //that is what is required for the custom metadata creation.  This can't be done with the normal constructor
            //since it requires that the field be an Id
            String tempFieldMappingString =
                '{ "' + diFieldMappingSetFieldName + '" : "' +
                UTIL_Namespace.StrAllNSPrefix(fieldMappingWrapper.Data_Import_Field_Mapping_Set) + '",' +
                '"' + targetObjectMappingFieldName + '": "' +
                UTIL_Namespace.StrAllNSPrefix(fieldMappingWrapper.Target_Object_Mapping)  + '"}';

            Data_Import_Field_Mapping__mdt fieldMapping =
                (Data_Import_Field_Mapping__mdt)JSON.deserialize(tempFieldMappingString, Data_Import_Field_Mapping__mdt.class);

            fieldMapping.MasterLabel = fieldMappingWrapper.MasterLabel;
            fieldMapping.DeveloperName = fieldMappingWrapper.DeveloperName;
            fieldMapping.Is_Deleted__c = fieldMappingWrapper.Is_Deleted;
            fieldMapping.Required__c = fieldMappingWrapper.Required;
            fieldMapping.Source_Field_API_Name__c = fieldMappingWrapper.Source_Field_API_Name;
            fieldMapping.Target_Field_API_Name__c = fieldMappingWrapper.Target_Field_API_Name;

            if (Test.isRunningTest()) {
                return JSON.serialize(fieldMapping);
            }

            String deploymentId = enqueueMetadataRecords(fieldMapping);
            return deploymentId;
        } catch(Exception e) {
            throw e;
        }
    }


    /*******************************************************************************************************
    * @description Converts a JSON string of a DataImportObjectMappingWrapper to an instance of
    * Data_Import_Object_Mapping__mdt. 
    *
    * @param objectMappingString: DataImportFieldMappingWrapper as JSON
    * @return String: Deployment Id or Data_Import_Object_Mapping__mdt instance JSON when in tests
    */
    @AuraEnabled(cacheable=true)
    public static String createDataImportObjectMapping(String objectMappingString) {

        try {
            DataImportObjectMappingWrapper objMappingWrapper = 
                (DataImportObjectMappingWrapper)JSON.deserialize(objectMappingString, DataImportObjectMappingWrapper.class);

            String diObjMappingSetFieldName = 'npsp__Data_Import_Object_Mapping_Set__c';
            if (NAMESPACE != 'npsp') {
                diObjMappingSetFieldName = diObjMappingSetFieldName.replaceFirst('npsp__','');
            }

            //This is a workaround to get the developer name of the Data Import Object Mapping Set into the field since 
            //that is what is required for the custom metadata creation.  This can't be done with the normal constructor
            //since it requires that the field be an Id
            String tempObjMappingString = 
                '{ "'+ diObjMappingSetFieldName+'" : "' + objMappingWrapper.Data_Import_Object_Mapping_Set + '"}';

            Data_Import_Object_Mapping__mdt objMapping = 
                (Data_Import_Object_Mapping__mdt)JSON.deserialize(tempObjMappingString, Data_Import_Object_Mapping__mdt.class);  

            objMapping.MasterLabel = objMappingWrapper.MasterLabel;
            objMapping.DeveloperName = objMappingWrapper.DeveloperName;
            objMapping.Object_API_Name__c = objMappingWrapper.Object_API_Name;
            objMapping.Custom_Mapping_Logic_Class__c = objMappingWrapper.Custom_Mapping_Logic_Class;
            objMapping.Imported_Record_Field_Name__c = objMappingWrapper.Imported_Record_Field_Name;
            objMapping.Imported_Record_Status_Field_Name__c = objMappingWrapper.Imported_Record_Status_Field_Name;
            objMapping.Is_Deleted__c = objMappingWrapper.Is_Deleted;
            objMapping.Predecessor__c = objMappingWrapper.Predecessor;
            objMapping.Relationship_Field__c = objMappingWrapper.Relationship_Field;
            objMapping.Relationship_To_Predecessor__c = objMappingWrapper.Relationship_To_Predecessor;

            if (Test.isRunningTest()) {
                return JSON.serialize(objMapping);
            }

            String deploymentId = enqueueMetadataRecords(objMapping);
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

        if (Test.isRunningTest()) {
            return JSON.serialize(deployContainer);
        }

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
    * building corresponding custom metadata type records.
    */
    public class DataImportFieldMappingWrapper {
        @AuraEnabled public String DeveloperName;
        @AuraEnabled public String MasterLabel;
        @AuraEnabled public String Label;
        @AuraEnabled public String Maps_To_Icon;
        @AuraEnabled public String Source_Field_Label;
        @AuraEnabled public String Source_Field_API_Name;
        @AuraEnabled public String Source_Field_Data_Type;
        @AuraEnabled public String Target_Field_Label;
        @AuraEnabled public String Target_Field_API_Name;
        @AuraEnabled public String Target_Field_Data_Type;
        @AuraEnabled public String Data_Import_Field_Mapping_Set;
        @AuraEnabled public String Target_Object_Mapping;
        @AuraEnabled public String Required;
        @AuraEnabled public Boolean Is_Deleted;
        @AuraEnabled public String Source_Field_Display_Type_Label;
        @AuraEnabled public String Target_Field_Display_Type_Label;

        public DataImportFieldMappingWrapper(Data_Import_Field_Mapping__mdt fieldMapping) {
            String dataImport = 'npsp__DataImport__c';
            String objectAPIName = fieldMapping.Target_Object_Mapping__r.Object_API_Name__c;
            String sourceFieldAPIName = fieldMapping.Source_Field_API_Name__c;
            String targetFieldAPIName = fieldMapping.Target_Field_API_Name__c;

            if (NAMESPACE != 'npsp') {
                dataImport = 'DataImport__c';
                objectAPIName =
                    UTIL_Namespace.removeNSPrefixNpspOnly(
                        fieldMapping.Target_Object_Mapping__r.Object_API_Name__c);
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
            this.Label =fieldMapping.MasterLabel;
            this.Source_Field_Label = sourceFieldDescribe.label;
            this.Source_Field_API_Name = fieldMapping.Source_Field_API_Name__c;
            this.Source_Field_Data_Type = String.valueOf(sourceFieldDescribe.type);
            this.Source_Field_Display_Type_Label = LABELS_BY_DISPLAY_TYPE.get(this.Source_Field_Data_Type);

            this.Target_Field_Label = targetFieldDescribe.label;
            this.Target_Field_API_Name = fieldMapping.Target_Field_API_Name__c;
            this.Target_Field_Data_Type = String.valueOf(targetFieldDescribe.type);
            this.Target_Field_Display_Type_Label = LABELS_BY_DISPLAY_TYPE.get(this.Target_Field_Data_Type);

            this.Maps_To_Icon = UTILITY_FORWARD_SLDS_ICON;

            this.Data_Import_Field_Mapping_Set = fieldMapping.Data_Import_Field_Mapping_Set__r.DeveloperName;
            this.Target_Object_Mapping = fieldMapping.Target_Object_Mapping__r.DeveloperName;
            this.Required = fieldMapping.Required__c;
            this.Is_Deleted = fieldMapping.Is_Deleted__c;
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

            deploymentEvents.add(de);
            Database.SaveResult saveResult = EventBus.publish(de);

            if (!saveResult.isSuccess()) {
                for (Database.Error error : saveResult.getErrors()) {
                    throw new AuraHandledException('Error returned: ' +
                            error.getStatusCode() + ' - ' +
                            error.getMessage());
                }
            }
        }
    }

    /*******************************************************************************************************
    * @description Wrapper class for the Data Import Object Mapping object.
    */
    public class DataImportObjectMappingWrapper {
        @AuraEnabled public Id Id;
        @AuraEnabled public String DeveloperName;
        @AuraEnabled public String MasterLabel;
        @AuraEnabled public String Custom_Mapping_Logic_Class;
        @AuraEnabled public String Data_Import_Object_Mapping_Set;
        @AuraEnabled public String Data_Import_Object_Mapping_Set_Dev_Name;
        @AuraEnabled public String Imported_Record_Field_Name;
        @AuraEnabled public String Imported_Record_Status_Field_Name;
        @AuraEnabled public Boolean Is_Deleted;
        @AuraEnabled public String Object_API_Name;
        @AuraEnabled public String Predecessor;
        @AuraEnabled public String Predecessor_Label_Name;
        @AuraEnabled public String Relationship_Field;
        @AuraEnabled public String Relationship_To_Predecessor;

        public DataImportObjectMappingWrapper(Data_Import_Object_Mapping__mdt objectMapping) {
            this.Id = objectMapping.Id;
            this.MasterLabel = objectMapping.MasterLabel;
            this.DeveloperName = objectMapping.DeveloperName;
            this.Custom_Mapping_Logic_Class = objectMapping.Custom_Mapping_Logic_Class__c;
            this.Data_Import_Object_Mapping_Set = objectMapping.Data_Import_Object_Mapping_Set__c;
            this.Data_Import_Object_Mapping_Set_Dev_Name = objectMapping.Data_Import_Object_Mapping_Set__r.DeveloperName;
            this.Imported_Record_Field_Name = objectMapping.Imported_Record_Field_Name__c;
            this.Imported_Record_Status_Field_Name = objectMapping.Imported_Record_Status_Field_Name__c;
            this.Is_Deleted = objectMapping.Is_Deleted__c;
            this.Object_API_Name = objectMapping.Object_API_Name__c;
            this.Predecessor = objectMapping.Predecessor__c;
            this.Relationship_Field = objectMapping.Relationship_Field__c;
            this.Relationship_To_Predecessor = objectMapping.Relationship_To_Predecessor__c;
        }
    }

    /*******************************************************************************************************
    * @description Returns a list of combobox options for the valid objects to chooose from.
    * @return objectOptions List of combobox options for the valid objects to chooose from.
    */
    @AuraEnabled(cacheable=true)
    public static List<ComboboxOption> getObjectOptions(){
        List<ComboboxOption> objectOptions = new List<ComboboxOption>();
        Map<String, Schema.SObjectType> allObjectMap = Schema.getGlobalDescribe(); 
        List<String> filteredObjectNames = new List<String>();

        // Removing custom metadata types and knowledge article versions from the list of object names
        // Also restricting to only an predefined list of standard objects to keep the list manageable
        for (String objectName : allObjectMap.keySet()) { 
            if (!objectName.endsWith('__mdt') && !objectName.endsWith('__kav') 
                && (objectName.endsWith('__c') || STANDARD_OBJECT_WHITELIST.contains(objectName))) {
                filteredObjectNames.add(objectName);
            }
        }

        List<Schema.DescribeSObjectResult> objectDescribeResults = new List<Schema.DescribeSObjectResult>();
        objectDescribeResults = Schema.describeSObjects(filteredObjectNames);

        // Create a temporary list of every non-custom setting and non-custom metadata object
        // to a list of objects to choose from.
        for (Schema.DescribeSObjectResult eachObject : objectDescribeResults) {
            if (!eachObject.isCustomSetting()) {
                String objectName = eachObject.getName();
                String objectLabel = eachObject.getLabel();
                objectOptions.add(new ComboboxOption(objectLabel + ' (' + objectName + ')', objectName));
            }
        }

        objectOptions.sort();

        return objectOptions;
    }

    /*******************************************************************************************************
    * @description Simple class for combobox options.
    */
    public class ComboboxOption implements Comparable{
        @AuraEnabled
        public String label {get;set;}
        @AuraEnabled
        public String value {get;set;}  

        public ComboboxOption(String label, String value) {
            this.label = label;
            this.value = value;
        }

        public Integer compareTo(Object compareTo) {
            ComboboxOption compareToOption = (ComboboxOption)compareTo;
            if (label == compareToOption.label) return 0;
            if (label > compareToOption.label) return 1;
            return -1;        
        }         
    }

    /*******************************************************************************************************
    * @description Returns a list of field info objects for valid relationship field options.
    * @return fieldInfos field info objects that contain label and value info.
    */
    @AuraEnabled(cacheable=true)
    public static FieldInfo[] getRelationshipFieldOptions(String objectName, String lookupToObjectName) {
        FieldInfo[] fieldInfos = new List<FieldInfo>();

        Map<String, Schema.DescribeFieldResult> fieldDescribes =
            UTIL_Describe.getAllFieldsDescribe(objectName);

        for (String key : fieldDescribes.keySet()) {
            Schema.DescribeFieldResult dfr = fieldDescribes.get(key);

            if (dfr.getType().name() == 'REFERENCE' && fieldDescribes.get(key).isCreateable() ) {

                List<Schema.sObjectType> objTypes = dfr.getReferenceTo();

                //Get sObjectType of the object being looked up to for comparison purposes.
                Schema.SObjectType lookupToObjectType = 
                    Schema.getGlobalDescribe().get(lookupToObjectName.toLowerCase());

                if (objTypes != null) {
                    for (Schema.sObjectType objType : objTypes) {
                        if (objType == lookupToObjectType) {
                            fieldInfos.add(new FieldInfo(dfr));
                            break;
                        }
                    }
                }
            }
        }
        return fieldInfos;
    }


    /*******************************************************************************************************
    * @description Returns a unique set of Data Import field names that have already been mapped 
    * to a target field, and are therefore not eligible for re-use.
    * @return mappedFieldNamesList format set of strings
    */
    @AuraEnabled(cacheable=true)
    public static List<String> getMappedDISourceFields() {

        Set<String> mappedFieldNamesSet = new Set<String>();

        if (bdiCMT.fieldMappingsByObjMappingDevName != null) {
            for (String objMappingDevName : bdiCMT.fieldMappingsByObjMappingDevName.keySet()) {
                Data_Import_Field_Mapping__mdt[] fieldMappings =
                    bdiCMT.fieldMappingsByObjMappingDevName.get(objMappingDevName);

                if (fieldMappings != null) {
                    for (Data_Import_Field_Mapping__mdt fieldMapping : fieldMappings) {
                        mappedFieldNamesSet.add(fieldMapping.Source_Field_API_Name__c.toLowerCase());
                    }
                }
            }
        }
        List<String> mappedFieldNamesList = new List<String>(mappedFieldNamesSet);
        return mappedFieldNamesList;
    }
}// BDI_ManageAdvancedMappingCtrl
