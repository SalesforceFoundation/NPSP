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
* @description Unit Test for BDI_ManageAdvancedMappingCtrl
*/

@IsTest
private class BDI_ManageAdvancedMappingCtrl_TEST {

    /*******************************************************************************************************
    * @description Initialize test custom settings record
    */
    private static Data_Import_Settings__c settingsInstance;

    /*******************************************************************************************************
    * @description Name of test Data Import Field Mapping Set
    */
    private static final String DEFAULT_FIELD_MAPPING_SET_NAME = 'Default_Field_Mapping_Set';

    /*******************************************************************************************************
    * @description Name of test Data Import Field Mapping Set
    */
    private static final String DEFAULT_OBJECT_MAPPING_SET_NAME = 'Default_Object_Mapping_Set';

    /*******************************************************************************************************
    * @description Name of default Account1 Data Import Object Mapping
    */
    private static final String ACCOUNT1 = 'Account1';

    /*******************************************************************************************************
    * @description Account object name
    */
    private static final String ACCOUNT_OBJECT = 'Account';

    /*******************************************************************************************************
    * @description Contact object name
    */
    private static final String CONTACT_OBJECT = 'Contact';

    /*******************************************************************************************************
    * @description Instance of Data_Import_Field_Mapping__mdt as JSON
    */
    private static final String FIELD_MAPPING_MDT =
        '{"DeveloperName":null,' +
        '"MasterLabel":"Account1 Test Field",' +
        '"Data_Import_Field_Mapping_Set":"Migrated_Custom_Field_Mapping_Set",' +
        '"Is_Deleted":false,' +
        '"Required":"No",' +
        '"Source_Field_API_Name":"Account1_Test_Field__c",' +
        '"Target_Field_API_Name":"Test_Field__c",' +
        '"Target_Object_Mapping_Dev_Name":"Account1"}';

    /*******************************************************************************************************
    * @description Instance of Data_Import_Object_Mapping__mdt as JSON
    */
    private static final String OBJECT_MAPPING_MDT =
        '{"MasterLabel":"Account3",' +
        '"DeveloperName":null,' +
        '"Object_API_Name":"Account",' +
        '"Custom_Mapping_Logic_Class":null,' +
        '"Imported_Record_Field_Name":null,' +
        '"Imported_Record_Status_Field_Name":null,' +
        '"Is_Deleted":false,' +
        '"Predecessor":"No Predecessor",' +
        '"Relationship_Field":null,' +
        '"Relationship_To_Predecessor":null}';

    /*******************************************************************************************************
    * @description Test that an admin user is correctly identified.
    */
    @isTest
    static void userIsAdmin() {
        User adminUser = UTIL_UnitTestData_TEST.createUserWithoutInsert(UTIL_Profile.SYSTEM_ADMINISTRATOR);

        System.runAs(adminUser) {
            Boolean isAdmin = BDI_ManageAdvancedMappingCtrl.isAdminUser(UserInfo.getUserId());

            System.assertEquals(true, isAdmin, 'The admin user was not correctly identified as an admin.');
        }
    }

    /*******************************************************************************************************
    * @description Test that a standard user is not incorrectly identified as an admin.
    */
    @isTest
    static void userIsNotAdmin() {
        User standardUser = UTIL_UnitTestData_TEST.createUserWithoutInsert(UTIL_Profile.PROFILE_STANDARD_USER);

        System.runAs(standardUser) {
            Boolean isAdmin = BDI_ManageAdvancedMappingCtrl.isAdminUser(UserInfo.getUserId());

            System.assertEquals(false, isAdmin, 'The standard user was incorrectly identified as an admin.');
        }
    }

    /*******************************************************************************************************
    * @description Test that we get the current namespace and npsp namespace
    */
    @isTest
    static void shouldReturnNamespaceWrapper() {
        ApexClass controllerClass = [SELECT NamespacePrefix
            FROM ApexClass
            WHERE Name = :'BDI_ManageAdvancedMappingCtrl'];

        String actualNamespace = controllerClass.NamespacePrefix;

        BDI_ManageAdvancedMappingCtrl.NamespaceWrapper nsWrapper = BDI_ManageAdvancedMappingCtrl.getNamespaceWrapper();

        String namespace = nsWrapper.currentNamespace;
        namespace = namespace == '' ? null : namespace;

        System.assertEquals(actualNamespace, namespace);
        System.assertEquals(UTIL_Namespace.HARDCODED_NPSP_NAMESPACE, nsWrapper.npspNamespace);
    }

    /*******************************************************************************************************
    * @description Test that we get the default field mapping set name
    */
    @isTest
    static void shouldReturnDefaultDataImportFieldMappingSetName() {
        String defaultDataImportFieldMappingSetName = BDI_ManageAdvancedMappingCtrl.getFieldMappingSetName();

        System.assertEquals(DEFAULT_FIELD_MAPPING_SET_NAME, defaultDataImportFieldMappingSetName);
    }

    /*******************************************************************************************************
    * @description Test that we create the correct number of Data Import Object Mapping wrappers
    */
    @isTest
    static void shouldGetCorrectNumberOfObjectMappingWrappers() {
        Data_Import_Object_Mapping_Set__mdt objectMappingSet = [SELECT Id
            FROM Data_Import_Object_Mapping_Set__mdt
            WHERE DeveloperName = :DEFAULT_OBJECT_MAPPING_SET_NAME
            LIMIT 1];

        Data_Import_Object_Mapping__mdt[] defaultObjectMappings = [SELECT Id
            FROM Data_Import_Object_Mapping__mdt
            WHERE Data_Import_Object_Mapping_Set__c = :objectMappingSet.Id];

        BDI_ObjectMapping[] objectMappingWrappers =
            BDI_ManageAdvancedMappingCtrl.getObjectMappings();

        System.assertEquals(defaultObjectMappings.size(), objectMappingWrappers.size());
    }

    /*******************************************************************************************************
    * @description Test that we create the correct number of Field Info wrappers for the given objects
    */
    @isTest
    static void shouldGetCorrectNumberOfObjectMappingFieldInfosForGivenObject() {
        Map<String, Schema.SObjectField> accountFieldMap = Account.sObjectType.getDescribe().Fields.getMap();
        Set<String> creatableAccountFields = getCreatableFields(accountFieldMap);

        Map<String, Schema.SObjectField> contactFieldMap = Contact.sObjectType.getDescribe().Fields.getMap();
        Set<String> creatableContactFields = getCreatableFields(contactFieldMap);

        BDI_ManageAdvancedMappingCtrl.FieldInfo[] accountFieldInfos =
            BDI_ManageAdvancedMappingCtrl.getObjectFieldDescribes(ACCOUNT_OBJECT);

        BDI_ManageAdvancedMappingCtrl.FieldInfo[] contactFieldInfos =
            BDI_ManageAdvancedMappingCtrl.getObjectFieldDescribes(CONTACT_OBJECT);

        System.assertEquals(creatableAccountFields.size(), accountFieldInfos.size());
        System.assertEquals(creatableContactFields.size(), contactFieldInfos.size());
    }

    /*******************************************************************************************************
    * @description Test that we create the correct number of Field Info wrappers for the given object
    */
    @isTest
    static void shouldGetCorrectNumberOfFieldMappingWrappersForGivenObjectMapping() {
        Data_Import_Field_Mapping_Set__mdt fieldMappingSet = [SELECT Id,
                DeveloperName
            FROM Data_Import_Field_Mapping_Set__mdt
            WHERE DeveloperName = :DEFAULT_FIELD_MAPPING_SET_NAME
            LIMIT 1];

        Data_Import_Object_Mapping__mdt account1 = [SELECT Id,
                DeveloperName
            FROM Data_Import_Object_Mapping__mdt
            WHERE DeveloperName = :ACCOUNT1
            LIMIT 1];

        Data_Import_Field_Mapping__mdt[] account1FieldMappings = [SELECT Id
            FROM Data_Import_Field_Mapping__mdt
            WHERE Data_Import_Field_Mapping_Set__c = :fieldMappingSet.Id
                AND Target_Object_Mapping__c = :account1.Id];

        BDI_ManageAdvancedMappingCtrl.DataImportFieldMappingWrapper[] account1FieldMappingWrappers =
            BDI_ManageAdvancedMappingCtrl.getFieldMappingsByObjectAndFieldSetNames(
                account1.DeveloperName,
                fieldMappingSet.DeveloperName);

        System.assertEquals(account1FieldMappings.size(), account1FieldMappingWrappers.size());
    }

    /*******************************************************************************************************
    * @description Test that we're able to create an instance of Data_Import_Field_Mapping__mdt from
    * JSON string
    */
    @isTest
    static void shouldCreateDataImportFieldMappingMetadata() {
        String dataImportFieldMappingMdt =
            BDI_ManageAdvancedMappingCtrl.createDataImportFieldMapping(FIELD_MAPPING_MDT);

        Data_Import_Field_Mapping__mdt fieldMapping =
            (Data_Import_Field_Mapping__mdt)JSON.deserialize(
                dataImportFieldMappingMdt,
                Data_Import_Field_Mapping__mdt.class);

        System.assert(fieldMapping != null);
        System.assertEquals(
            'Account1 Test Field',
            fieldMapping.MasterLabel,
            'Field Mapping MasterLabel is Account1 Test Field');
        System.assertEquals(
            'No',
            fieldMapping.Required__c,
            'Field Mapping Required__c is \'No\'');
        System.assertEquals(
            false,
            fieldMapping.Is_Deleted__c,
            'Field Mapping Is_Deleted__c is false');
        System.assertEquals(
            'Account1_Test_Field__c',
            fieldMapping.Source_Field_API_Name__c,
            'Field Mapping Source_Field_API_Name__c is Account1_Test_Field__c');
        System.assertEquals(
            'Test_Field__c',
            fieldMapping.Target_Field_API_Name__c,
            'Field Mapping Target_Field_API_Name__c is Test_Field__c');
        System.assertEquals(
            'Account1',
            fieldMapping.Target_Object_Mapping__c,
            'Field Mapping Target_Object_Mapping__c is Account1');
    }

    /*******************************************************************************************************
    * @description Test that we're able to create an instance of Data_Import_Object_Mapping__mdt from
    * JSON string
    */
    @isTest
    static void shouldCreateDataImportObjectMappingMetadata() {
        String dataImportObjectMapping =
            BDI_ManageAdvancedMappingCtrl.createDataImportObjectMapping(OBJECT_MAPPING_MDT);

        Data_Import_Object_Mapping__mdt objectMapping =
            (Data_Import_Object_Mapping__mdt)JSON.deserialize(
                dataImportObjectMapping,
                Data_Import_Object_Mapping__mdt.class);

        System.assert(objectMapping != null);
        System.assertEquals(
            'Account3',
            objectMapping.MasterLabel,
            'Object Mapping MasterLabel is Account3');
        System.assertEquals(
            null,
            objectMapping.DeveloperName,
            'Object Mapping DeveloperName is null');
        System.assertEquals(
            'Account',
            objectMapping.Object_API_Name__c,
            'Object Mapping Object_API_Name__c is Account');
        System.assertEquals(
            null,
            objectMapping.Custom_Mapping_Logic_Class__c,
            'Object Mapping Custom_Mapping_Logic_Class__c is null');
        System.assertEquals(
            null,
            objectMapping.Imported_Record_Field_Name__c,
            'Object Mapping Imported_Record_Field_Name__c is null');
        System.assertEquals(
            null,
            objectMapping.Imported_Record_Status_Field_Name__c,
            'Object Mapping Imported_Record_Status_Field_Name__c is null');
        System.assertEquals(
            false,
            objectMapping.Is_Deleted__c,
            'Object Mapping Is_Deleted__c is false');
        System.assertEquals(
            'No Predecessor',
            objectMapping.Predecessor__c,
            'Object Mapping Predecessor__c is \'No Predecessor\'');
        System.assertEquals(
            null,
            objectMapping.Relationship_Field__c,
            'Object Mapping Relationship_Field__c is null');
        System.assertEquals(
            null,
            objectMapping.Relationship_To_Predecessor__c,
            'Object Mapping Relationship_To_Predecessor__c is null');
    }

    /*******************************************************************************************************
    * @description Test that our Deployment Callback creates a Platform Event
    */
    @IsTest
    static void shouldCreateDeploymentEventOnDeployment() {
        Test.startTest();

        BDI_ManageAdvancedMappingCtrl.DeploymentCallback callback =
            new BDI_ManageAdvancedMappingCtrl.DeploymentCallback();

        // Construct a dummy Context
        TestingDeployCallbackContext context = new TestingDeployCallbackContext();

        // Create dummy Deploy Result
        Metadata.DeployResult deployResult = new Metadata.DeployResult();
        deployResult.Id = '04s000000122345';
        deployResult.status = Metadata.DeployStatus.SUCCEEDED;
        Datetime currentDatetime = datetime.now();
        deployResult.completedDate = currentDatetime;

        // Call the handleResult() method of our main Callback with our dummy context and result
        callback.handleResult(deployResult, context);

        Test.stopTest();

        System.assertEquals(BDI_ManageAdvancedMappingCtrl.deploymentEvents.size(), 1);
    }

    /*******************************************************************************************************
    * @description Test that child field mappings for a given deleted object mapping are flagged as deleted
    */
    @IsTest
    static void shouldFlagFieldMappingsAsDeleted() {
        Data_Import_Field_Mapping_Set__mdt fieldMappingSet = [SELECT Id,
                DeveloperName
            FROM Data_Import_Field_Mapping_Set__mdt
            WHERE DeveloperName = :DEFAULT_FIELD_MAPPING_SET_NAME
            LIMIT 1];

        Data_Import_Object_Mapping__mdt account1 = [SELECT Id,
                DeveloperName
            FROM Data_Import_Object_Mapping__mdt
            WHERE DeveloperName = :ACCOUNT1
            LIMIT 1];

        Data_Import_Field_Mapping__mdt[] account1FieldMappings = [SELECT Id, Is_Deleted__c
            FROM Data_Import_Field_Mapping__mdt
            WHERE Data_Import_Field_Mapping_Set__c = :fieldMappingSet.Id
                AND Target_Object_Mapping__c = :account1.Id];

        BDI_ManageAdvancedMappingCtrl.DataImportFieldMappingWrapper[] account1FieldMappingWrappers =
            BDI_ManageAdvancedMappingCtrl.getFieldMappingsByObjectAndFieldSetNames(
                account1.DeveloperName,
                fieldMappingSet.DeveloperName);

        Data_Import_Field_Mapping__mdt[] deletedFieldMappings =
            BDI_ManageAdvancedMappingCtrl.flagFieldMappingsAsDeleted(account1.DeveloperName);

        for (Data_Import_Field_Mapping__mdt fieldMapping : deletedFieldMappings) {
            System.assertEquals(fieldMapping.Is_Deleted__c, true);
        }
    }

    /*******************************************************************************************************
    * @description Helper method to collect isCreatable fields
    */
    static Set<String> getCreatableFields(Map<String, Schema.SObjectField> fieldMap) {
        Set<String> creatableFields = new Set<String>();
        if (fieldMap != null) {
            for (Schema.SObjectField ft : fieldMap.values()) {
                Schema.DescribeFieldResult fieldDescribe = ft.getDescribe();
                if (fieldDescribe.isCreateable() || fieldDescribe.isCalculated()) {
                    creatableFields.add(fieldDescribe.getName());
                }
            }
        }
        return creatableFields;
    }

    /*******************************************************************************************************
    * @description DeployCallbackContext subclass for testing that returns jobId
    */
    public class TestingDeployCallbackContext extends Metadata.DeployCallbackContext {
        public override Id getCallbackJobId() {
            return '000000000122345';
        }
    }
}
