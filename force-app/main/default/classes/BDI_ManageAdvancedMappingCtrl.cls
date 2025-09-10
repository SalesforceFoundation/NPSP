/*
    Copyright (c) 2020, Salesforce.org
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
    
    /*******************************************************************************************************
    * @description Returns a wrapper class containing the current namespace and the npsp namespace defined 
    * in UTIL_Namespace class.
    */
    @AuraEnabled(cacheable=true)
    public static NamespaceWrapper getNamespaceWrapper() {
        return new NamespaceWrapper();
    }

    /*******************************************************************************************************
    * @description Instance of BDI_MappingServiceAdvanced
    */
    private static BDI_MappingServiceAdvanced bdiMsAdv = BDI_MappingServiceAdvanced.getInstance();

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
    * @description This is a list of the standard objects we will let users choose from (plus custom objects) 
    * when creating a new object mappping.  This is necessary since there are hundreds of standard objects
    * and including them all would negatively impact performance and make the list unusable.
    */ 
    private static final Set<String> STANDARD_OBJECT_ALLOWED_LIST = new Set<String>{
        'account', 'asset', 'assetrelationship', 
        'campaign', 'campaignmember', 'case', 
        'contact', 'contract', 'event', 'lead', 
        'opportunity', 'opportunitylineitem', 
        'order', 'orderitem', 'pricebook2', 
        'pricebookEntry', 'product2', 'task', 
        'user','opportunitycontactrole','contactrole','workorder'
    };

    /**
     * @description Checks if the running user has system admin permissions
     * @return Boolean
    */
    @AuraEnabled
    public static Boolean isAdminUser(Id userId) {
        List<User> runningUser = [SELECT ProfileId FROM User WHERE Id = :userId];
        Map<Id, Boolean> userIdToIsAdmin = USER_UserService.isSysAdmin(
                runningUser
        );

        return userIdToIsAdmin.get(userId);
    }

    /*******************************************************************************************************
    * @description Name of the default Field Mapping Set
    *
    * @return String: Default Field Mapping Set name
    */
    public static String getFieldMappingSetName() {
        return bdiMsAdv.fieldMappingSet.DeveloperName;
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
    @TestVisible
    private static BDI_ObjectMapping[] getObjectMappings(){

        BDI_ObjectMapping[] objMappings = bdiMsAdv.objectMappingByDevName.values();

        for (BDI_ObjectMapping objectMapping : objMappings) {
            BDI_FieldMapping [] fieldMappings =
                bdiMsAdv.fieldMappingsByObjMappingDevName.get(objectMapping.DeveloperName);
            if (fieldMappings == null) {
                fieldMappings = new BDI_FieldMapping[]{};
            }
            if (!fieldMappings.isEmpty()) {
               for (BDI_FieldMapping fieldMapping : fieldMappings) {
                   if (!fieldMapping.isDescribable && !fieldMapping.Is_Deleted) {
                       objectMapping.Field_Mappings.add(fieldMapping);
                   }
               }
            }
            BDI_ObjectMapping predecessorObjMapping =
                bdiMsAdv.objectMappingByDevName.get(objectMapping.Predecessor);
            //Assign the label name field for the predecessor using the constructed map by dev name.
            if (predecessorObjMapping != null) {
                objectMapping.Predecessor_Label_Name = predecessorObjMapping.MasterLabel;
            }
        }
        return objMappings;
    }

    /*******************************************************************************************************
     * @description This method gathers and returns data required to use the Advanced Mapping Object Mapping
     * Component
     * @return AdvancedMappingObjectData
     */
    @AuraEnabled
    public static AdvancedMappingObjectData getAdvancedMappingObjectData () {
        if (!isAdminUser(UserInfo.getUserId())) {
            throw new AuraHandledException(Label.commonInsufficientPermissions);
        }

        return new AdvancedMappingObjectData(getObjectMappings(), getObjectOptions());
    }

    /*******************************************************************************************************
    * @description This method gathers and returns data required to use the Advanced Mapping Fields Mapping
    * Component
    * @param targetObjectApiName Target Object ApiName
    * @param sourceObjectApiName Source Object ApiName
    * @return AdvancedMappingFieldData
    */
    @AuraEnabled(Cacheable = true)
    public static AdvancedMappingFieldData getAdvancedMappingFieldsData (String targetObjectApiName,
        String sourceObjectApiName) {
        String fieldMappingSetName = getFieldMappingSetName();
        FieldInfo[] sourceObjectFieldDescribes = getObjectFieldDescribes(sourceObjectApiName, false);
        FieldInfo[] targetObjectFieldDescribes = getObjectFieldDescribes(targetObjectApiName, false);
        List<String> mappedDISourceFields = getMappedDISourceFields();
        return new AdvancedMappingFieldData(
            fieldMappingSetName, sourceObjectFieldDescribes, targetObjectFieldDescribes, mappedDISourceFields);
    }

    /*******************************************************************************************************
    * @description Get the namespaced/un-namespaced api name of DataImport__c
    *
    * @return String: API name of DataImport__c
    */
    @AuraEnabled
    public static String getDataImportObjectName() {
        return DataImport__c.SObjectType.getDescribe().getName();
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
        return getObjectFieldDescribes(objectName,false);
    }

    /*******************************************************************************************************
    * @description Gets all the field describes from a given object, and retrieves the reference object information.
    *
    * @param objectName: Object name
    * @param includeReferenceToObjectList: Boolean indicating whether the reference to objects should be returned 
    * as part of field info.
    *
    * @return List: List of BDI_ManageAdvancedMappingCtrl.FieldInfo
    */
    @AuraEnabled
    public static FieldInfo[] getObjectFieldDescribes(String objectName, Boolean includeReferenceToObjectList) {
        FieldInfo[] fieldInfos = new List<FieldInfo>();

        if (includeReferenceToObjectList == null) {
            includeReferenceToObjectList = false;
        }

        Map<String, Schema.DescribeFieldResult> fieldDescribes =
            UTIL_Describe.getAllFieldsDescribe(objectName);

        for (String key : fieldDescribes.keySet()) {

            //Only include fields that are createable by the current user or formula fields.
            //Formula fields can be selectively excluded later by the calling component.
            if (fieldDescribes.get(key).isCreateable() || fieldDescribes.get(key).isCalculated()) {
                fieldInfos.add(new FieldInfo(fieldDescribes.get(key),includeReferenceToObjectList));
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
        BDI_FieldMapping[] fieldMappings = extractInvalidFieldMappings(
            bdiMsAdv.objectMappingByDevName.get(objectName));
        for (BDI_FieldMapping fieldMapping : fieldMappings) {
            if ((bdiMsAdv.fieldMappingSet.DeveloperName == fieldMappingSetname &&
                fieldMapping.Is_Deleted == false)) {
                DataImportFieldMappingWrapper wrapper = new DataImportFieldMappingWrapper(fieldMapping);
                fieldMappingWrappers.add(wrapper);
            }
        }
        return fieldMappingWrappers;
    }

    /**
     * @description Adds invalid field mappings to list of valid field mappings to be returned
     * to Advanced Mapping Fields Mapping component
     * @param objectMapping Object Mapping that contains invalid field mappings
     *
     * @return {BDI_FieldMapping[]} fieldMappings
     */
    private static BDI_FieldMapping[] extractInvalidFieldMappings (BDI_ObjectMapping objectMapping) {
        BDI_FieldMapping[] fieldMappings = bdiMsAdv.fieldMappingsByObjMappingDevName.get(objectMapping.DeveloperName);
        if (!objectMapping.Field_Mappings.isEmpty()) {
            //Add possible invalid field mappings
            fieldMappings.addAll(objectMapping.Field_Mappings);
        }
        return fieldMappings == null ? new BDI_FieldMapping[]{} : fieldMappings;
    }

    /*******************************************************************************************************
    * @description Aura enabled method for creating Data Import Field Mappings
    *
    * @param fieldMappingString: DataImportFieldMappingWrapper as JSON
    *
    * @return String: Deployment Id or BDI_FieldMapping instance JSON when in tests
    */
    @AuraEnabled
    public static String createDataImportFieldMapping(String fieldMappingString) {
        try {
            Data_Import_Field_Mapping__mdt fieldMapping = constructDataImportFieldMapping(fieldMappingString);

            if (Test.isRunningTest()) {
                return JSON.serialize(fieldMapping);
            }

            return enqueueMetadataRecords(fieldMapping);
        } catch(Exception e) {
            throw e;
        }
    }

    /*******************************************************************************************************
    * @description Converts a JSON string of a DataImportFieldMappingWrapper to an instance of
    * Data_Import_Field_Mapping__mdt.
    *
    * @param fieldMappingString: DataImportFieldMappingWrapper as JSON
    *
    * @return String: Deployment Id or BDI_FieldMapping instance JSON when in tests
    */
    private static Data_Import_Field_Mapping__mdt constructDataImportFieldMapping(String fieldMappingString) {
        DataImportFieldMappingWrapper fieldMappingWrapper =
            (DataImportFieldMappingWrapper)JSON.deserialize(
                fieldMappingString,
                DataImportFieldMappingWrapper.class);

        String diFieldMappingSetFieldName =
            SObjectType.Data_Import_Field_Mapping__mdt.fields.Data_Import_Field_Mapping_Set__c.Name;
        String targetObjectMappingFieldName =
            SObjectType.Data_Import_Field_Mapping__mdt.fields.Target_Object_Mapping__c.Name;

        //This is a workaround to get the developer name of the Data Import Object Mapping Set into the field
        //since that is what is required for the custom metadata creation. This can't be done with the normal
        //constructor since it requires that the field be an Id
        String tempFieldMappingString =
            '{ "' + diFieldMappingSetFieldName + '" : "' +
            UTIL_Namespace.StrAllNSPrefix(fieldMappingWrapper.Data_Import_Field_Mapping_Set) + '",' +
            '"' + targetObjectMappingFieldName + '": "' +
            UTIL_Namespace.StrAllNSPrefix(fieldMappingWrapper.Target_Object_Mapping_Dev_Name)  + '"}';

        Data_Import_Field_Mapping__mdt diFieldMapping =
            (Data_Import_Field_Mapping__mdt)JSON.deserialize(
                tempFieldMappingString,
                Data_Import_Field_Mapping__mdt.class);

        diFieldMapping.MasterLabel = fieldMappingWrapper.MasterLabel;
        diFieldMapping.DeveloperName = fieldMappingWrapper.DeveloperName;
        diFieldMapping.Is_Deleted__c = fieldMappingWrapper.Is_Deleted;
        diFieldMapping.Required__c = fieldMappingWrapper.Required;
        diFieldMapping.Source_Field_API_Name__c = fieldMappingWrapper.Source_Field_API_Name;
        diFieldMapping.Target_Field_API_Name__c = fieldMappingWrapper.Target_Field_API_Name;

        return diFieldMapping;
    }

    /*******************************************************************************************************
    * @description Flag all child field mappings of object mapping as deleted
    *
    * @param objectMappingDeveloperName: Developer name of the Object Mapping
    *
    * @return List: List of Data Import Field Mappings with "Is_Deleted" set to true
    */
    @TestVisible
    private static Data_Import_Field_Mapping__mdt[] flagFieldMappingsAsDeleted(String objectMappingDeveloperName) {
        DataImportFieldMappingWrapper[] fieldMappingWrappers = getFieldMappingsByObjectAndFieldSetNames(
            objectMappingDeveloperName, getFieldMappingSetName());
        Data_Import_Field_Mapping__mdt[] updatedFieldMappings = new Data_Import_Field_Mapping__mdt[]{};

        for (DataImportFieldMappingWrapper fieldMappingWrapper : fieldMappingWrappers) {
            fieldMappingWrapper.Is_Deleted = true;
            Data_Import_Field_Mapping__mdt updatedFieldMapping =
                constructDataImportFieldMapping(JSON.serialize(fieldMappingWrapper));

            updatedFieldMappings.add(updatedFieldMapping);
        }

        return updatedFieldMappings;
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

            String diObjMappingSetFieldName = SObjectType.Data_Import_Object_Mapping__mdt.fields.Data_Import_Object_Mapping_Set__c.Name;

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

            String deploymentId;

            if (objMapping.Is_Deleted__c == true) {
                sObject[] mappingsToDelete = new sObject[]{};
                mappingsToDelete.addAll(flagFieldMappingsAsDeleted(objMappingWrapper.DeveloperName));
                mappingsToDelete.add(objMapping);

                deploymentId = enqueueMetadataRecords(mappingsToDelete);
            } else {
                deploymentId = enqueueMetadataRecords(objMapping);
            }

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
    * @description BDI_FieldMapping wrapper class used in the Field Mapping UI and for
    * building corresponding custom metadata type records.
    */
    public class DataImportFieldMappingWrapper extends BDI_FieldMapping {
        @AuraEnabled public String Label;
        @AuraEnabled public String Maps_To_Icon;

        public DataImportFieldMappingWrapper(BDI_FieldMapping fieldMapping) {
            this.DeveloperName = fieldMapping.DeveloperName;
            this.MasterLabel = fieldMapping.MasterLabel;
            this.Label = fieldMapping.MasterLabel;
            this.Source_Field_Label = fieldMapping.Source_Field_Label;
            this.Source_Field_API_Name = fieldMapping.Source_Field_API_Name;
            this.Source_Field_Data_Type = fieldMapping.Source_Field_Data_Type;
            this.Source_Field_Display_Type_Label = fieldMapping.Source_Field_Display_Type_Label;

            this.Target_Field_Label = fieldMapping.Target_Field_Label;
            this.Target_Field_API_Name = fieldMapping.Target_Field_API_Name;
            this.Target_Field_Data_Type = fieldMapping.Target_Field_Data_Type;
            this.Target_Field_Display_Type_Label = fieldMapping.Target_Field_Display_Type_Label;

            this.Maps_To_Icon = UTILITY_FORWARD_SLDS_ICON;

            this.Data_Import_Field_Mapping_Set = fieldMapping.Data_Import_Field_Mapping_Set;
            this.Target_Object_Mapping_Dev_Name = fieldMapping.Target_Object_Mapping_Dev_Name;
            this.Required = fieldMapping.Required;
            this.Is_Deleted = fieldMapping.Is_Deleted;
            this.isDescribable = fieldMapping.isDescribable;
        }
    }

    /*******************************************************************************************************
    * @description Wrapper class for Field Describe Results used in the Field Mapping UI
    */
    public class FieldInfo {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        @AuraEnabled public String displayType;
        @AuraEnabled public String[] referenceToObjectList;
        @AuraEnabled public Boolean isBooleanMappable;
        @AuraEnabled public Boolean isFormula;
        private String[] picklistOptions = new String[]{};

        // Restricting Picklist=>Bool mappings to only picklists with options 'true' and 'false'.
        // Update BDI_DataImportService.copyDIFieldToDestinationRecord to handle more Picklist=>Bool mappings
        private List<List<String>> allowedPicklistOptions =
            new List<List<String>>{new List<String>{'true', 'false'}};

        public FieldInfo(DescribeFieldResult dfr) {
            this.value = dfr.getName();
            this.label = dfr.getLabel();
            this.displayType = dfr.getType().name();
            this.isFormula = dfr.isCalculated();
        }

        public FieldInfo(DescribeFieldResult dfr, Boolean includeReferenceToObjectList) {
            this.value = dfr.getName();
            this.label = dfr.getLabel();
            this.displayType = dfr.getType().name();
            this.isFormula = dfr.isCalculated();

            if (includeReferenceToObjectList) {
                this.referenceToObjectList = new String[]{};
                if (dfr.getType().name() == 'REFERENCE') {

                    List<Schema.sObjectType> objTypes = dfr.getReferenceTo();
                    
                    if (objTypes != null) {
                        for (Schema.sObjectType objType : objTypes) {
                            this.referenceToObjectList.add(objType.getDescribe().getName().toLowerCase());
                        }
                    }
                }
            }

            if (dfr.getType() == Schema.DisplayType.PICKLIST) {
                Set<String> picklistOptionsSet = new Set<String>();
                Schema.PicklistEntry[] picklistEntry = dfr.getPicklistValues();

                if (picklistEntry != null && picklistEntry.size() > 0) {
                    for (Schema.PicklistEntry picklistValue : picklistEntry) {
                        picklistOptionsSet.add(picklistValue.getLabel().toLowerCase());
                    }
                    picklistOptions.addAll(picklistOptionsSet);
                }

                picklistOptions.sort();

                for (String[] allowedOptions : allowedPicklistOptions) {
                    allowedOptions.sort();

                    if (picklistOptions.equals(allowedOptions)) {
                        this.isBooleanMappable = true;
                    }
                }
            }
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
    private static List<ComboboxOption> getObjectOptions() {
        List<ComboboxOption> objectOptions = new List<ComboboxOption>();
        Map<String, Schema.SObjectType> allObjectMap = Schema.getGlobalDescribe(); 
        List<String> filteredObjectNames = new List<String>();

        // Removing custom metadata types and knowledge article versions from the list of object names
        // Also restricting to only an predefined list of standard objects to keep the list manageable
        for (String objectName : allObjectMap.keySet()) { 
            if (!objectName.endsWith('__mdt')
                && !objectName.endsWith('__kav') 
                && (objectName.endsWith('__c') || STANDARD_OBJECT_ALLOWED_LIST.contains(objectName))
            ) {
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

            if (dfr.getType().name() == 'REFERENCE' && dfr.isCreateable()) {

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

        if (bdiMsAdv.fieldMappingsByObjMappingDevName != null) {
            for (String objMappingDevName : bdiMsAdv.fieldMappingsByObjMappingDevName.keySet()) {
                BDI_FieldMapping[] fieldMappings =
                    bdiMsAdv.fieldMappingsByObjMappingDevName.get(objMappingDevName);

                if (fieldMappings != null) {
                    for (BDI_FieldMapping fieldMapping : fieldMappings) {
                        mappedFieldNamesSet.add(fieldMapping.Source_Field_API_Name.toLowerCase());
                    }
                }
            }
        }
        List<String> mappedFieldNamesList = new List<String>(mappedFieldNamesSet);
        return mappedFieldNamesList;
    }

    /*******************************************************************************************************
    * @description Simple class to contain both the current namespace, and the npsp namespace variable for
    * use in constructing/modifying urls and schema names in lightning web components. Wrapped in a class
    * to reduce calls.
    */
    public class NamespaceWrapper {
        @AuraEnabled
        public String currentNamespace {get;set;}
        @AuraEnabled
        public String npspNamespace {get;set;}  

        public NamespaceWrapper(){
            this.currentNamespace = UTIL_Namespace.getNamespace();
            this.npspNamespace = UTIL_Namespace.HARDCODED_NPSP_NAMESPACE;
        }
    }

    /******************************************************************************************************
     * @description Inner class representation of the data needed to render Advanced Mapping Object Mapping
     * component
     */
    public class AdvancedMappingObjectData {
        @AuraEnabled
        public BDI_ObjectMapping[] objectMappings;
        @AuraEnabled
        public List<ComboboxOption> objectOptions;

        public AdvancedMappingObjectData (BDI_ObjectMapping [] objectMappings,
            List<ComboboxOption> objectOptions) {
            this.objectMappings = objectMappings;
            this.objectOptions = objectOptions;
        }
    }

    /******************************************************************************************************
    * @description Inner class representation of the data needed to render Advanced Mapping Fields Mapping
    * component
    */
    public class AdvancedMappingFieldData {
        @AuraEnabled public String fieldMappingSetName;
        @AuraEnabled public FieldInfo[] sourceObjectFieldDescribes;
        @AuraEnabled public FieldInfo[] targetObjectFieldDescribes;
        @AuraEnabled public List<String> mappedDISourceFields;

        public AdvancedMappingFieldData (String fieldMappingSetName, FieldInfo[] sourceObjectFieldDescribes,
            FieldInfo[] targetObjectFieldDescribes, List<String> mappedDISourceFields) {
            this.fieldMappingSetName = fieldMappingSetName;
            this.sourceObjectFieldDescribes = sourceObjectFieldDescribes;
            this.targetObjectFieldDescribes = targetObjectFieldDescribes;
            this.mappedDISourceFields = mappedDISourceFields;
        }

    }
}
