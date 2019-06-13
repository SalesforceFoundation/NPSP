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
* @description Unit Test for the Migration Mapping Utility
*/

@IsTest
private class BDI_MigrationMappingUtilityTest {

    /*@isTest
    static void shouldCreateCustomMetadataRecordsFromHelpText() {
        // Create a mock version of the BDI_MigrationUtilityHelper class
        BDI_MigrationMappingHelper mock_BDI_MigrationMappingHelper =
            (BDI_MigrationMappingHelper) Test.createStub(
                BDI_MigrationMappingHelper.class,
                new BDI_MigrationMappingHelperMock());

        // Call build method
        BDI_MigrationMappingUtility util = new BDI_MigrationMappingUtility(mock_BDI_MigrationMappingHelper);
        util.sortFieldMappings('Default_Field_Mapping_Set');

        // Confirm that we have a new pending data import field mapping waiting to be deployed
        System.assertEquals(1, util.pendingMappings.size(), 'We have one new field mapping');
        System.assertEquals(2, util.pendingStandardMappings.size(), 'We have two standard field mappings');

        // Confirm that we can get custom metadata from "pendingMappings"
        Metadata.CustomMetadata cmt = util.pendingMappings[0].getMetadataRecord();
        System.assertEquals('Account 1 New Custom Field', cmt.label);
    }

    @IsTest
    static void shouldContainMetadataRecordsForDeploy() {
        // Create a mock version of the BDI_MigrationUtilityHelper class
        BDI_MigrationMappingHelper mock_BDI_MigrationMappingHelper =
            (BDI_MigrationMappingHelper) Test.createStub(
                BDI_MigrationMappingHelper.class,
                new BDI_MigrationMappingHelperMock());

        BDI_MigrationMappingUtility util = new BDI_MigrationMappingUtility(mock_BDI_MigrationMappingHelper);
        util.startMigration();

        Test.startTest();

        // Convert mappings to Custom Metadata and start deployment
        if (BDI_MigrationMappingUtility.customFieldMappingSetExists == true) {
            System.assertEquals(1, util.queuedMetadataTypesForDeploy.size());
        } else {
            System.assertEquals(4, util.queuedMetadataTypesForDeploy.size());
        }

        Test.stopTest();
    }

    @IsTest
    static void shouldContainConflictingMetadataRecordsForDeploy() {
        // Create a mock version of the BDI_MigrationUtilityHelper class
        BDI_MigrationMappingHelper mock_BDI_MigrationMappingHelper =
            (BDI_MigrationMappingHelper) Test.createStub(
                BDI_MigrationMappingHelper.class,
                new BDI_MigrationMappingHelperMock());

        // Call the method
        BDI_MigrationMappingUtility util = new BDI_MigrationMappingUtility(mock_BDI_MigrationMappingHelper);
        util.sortFieldMappings('Default_Field_Mapping_Set');

        // Force mapping conflict
        BDI_HelpTextCMT.DataImportFieldMapping conflictingMapping = util.pendingStandardMappings.remove(0);
        conflictingMapping.targetFieldAPIName='Some_Custom_Field__c';
        util.conflictingMappings.add(conflictingMapping);

        // Add conflicting mappings to list queuedMetadataTypesForDeploy
        util.handleConflictingMappings(util.conflictingMappings);

        Test.startTest();
        String targetFieldAPIName;
        for (Metadata.CustomMetadataValue customMetadataValue : util.queuedMetadataTypesForDeploy[0].values) {
            if (customMetadataValue.field.contains('Target_Field_API_Name')) {
                targetFieldAPIName = String.valueOf(customMetadataValue.value);
            }
        }
        System.assertEquals(1, util.queuedMetadataTypesForDeploy.size());
        System.assertEquals('Some_Custom_Field__c', targetFieldAPIName);
        Test.stopTest();
    }

    @IsTest
    static void shouldUpdateCustomSettingsForDataImportFieldMapping() {
        // Create a mock version of the BDI_MigrationUtilityHelper class
        BDI_MigrationMappingHelper mock_BDI_MigrationMappingHelper =
            (BDI_MigrationMappingHelper) Test.createStub(
                BDI_MigrationMappingHelper.class,
                new BDI_MigrationMappingHelperMock());

        BDI_MigrationMappingUtility util = new BDI_MigrationMappingUtility(mock_BDI_MigrationMappingHelper);
        util.startMigration();

        Test.startTest();

        util.deployCustomMetadata();

        // Confirm custom settings updated accordingly
        BDI_MigrationMappingUtility.DeploymentCallback callback = new BDI_MigrationMappingUtility.DeploymentCallback();

        // Construct a dummy Context
        TestingDeployCallbackContext context = new TestingDeployCallbackContext();

        Metadata.DeployResult deployResult = new Metadata.DeployResult();
        deployResult.status = Metadata.DeployStatus.SUCCEEDED;

        // Call the handleResult() method of our main Callback with our dummy context var
        callback.handleResult(deployResult, context);

        Test.stopTest();

        // Confirm that we've updated the CMT API Status field in Data Import Settings
        Data_Import_Settings__c dataImportSettings = UTIL_CustomSettingsFacade.getDataImportSettings();
        Map<String,String> result =
            (Map<String,String>)JSON.deserialize(dataImportSettings.CMT_API_Status__c, Map<String,String>.class);

        System.assertNotEquals(null, result.get('Status'), result);
        System.assertEquals(result.get('Field Mapping Method'), 'Data Import Field Mapping');
    }

    @IsTest
    static void shouldUpdateCustomSettingsForHelpText() {
        BDI_MigrationMappingUtility.updateCustomSettings(
            BDI_MigrationMappingUtility.HELP_TEXT,
            String.valueOf(Metadata.DeployStatus.Succeeded));

        // Confirm that we've updated the CMT API Status field in Data Import Settings
        Data_Import_Settings__c dataImportSettings = UTIL_CustomSettingsFacade.getDataImportSettings();
        Map<String,String> result =
            (Map<String,String>)JSON.deserialize(dataImportSettings.CMT_API_Status__c, Map<String,String>.class);

        System.assertEquals(result, new Map<String, String>());
    }

    private class BDI_MigrationMappingHelperMock implements System.StubProvider {

        private Integer startingNumber = 1;
        private String getFakeId(Schema.SObjectType sObjectTypeSchema) {
            String result = String.valueOf(startingNumber++);
            return sObjectTypeSchema.getDescribe().getKeyPrefix()
                + '0'.repeat(12-result.length()) + result;
        }

        private String account1ObjectMappingId = getFakeId(Schema.Data_Import_Object_Mapping__mdt.SObjectType);
        private String account2ObjectMappingId = getFakeId(Schema.Data_Import_Object_Mapping__mdt.SObjectType);

        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, Type returnType,
            List<Type> listOfParamTypes, List<String> listOfParamNames, List<Object> listOfArgs) {

            if (stubbedMethodName == 'createNewFieldMappingSet') {
                BDI_HelpTextCMT.DataImportFieldMappingSet fieldMappingSet =
                    new BDI_HelpTextCMT.DataImportFieldMappingSet(
                        'Migrated Custom Field Mapping Set',
                        'Default_Object_Mapping_Set');

                return fieldMappingSet.getMetadataRecord();
            }

            if (stubbedMethodName == 'getDefaultObjectMappingSet') {
                Data_Import_Object_Mapping_Set__mdt objectMappingSet =
                    new Data_Import_Object_Mapping_Set__mdt(
                        Label='Default Object Mapping Set',
                        DeveloperName='Default_Object_Mapping_Set');

                return objectMappingSet;
            }

            if (stubbedMethodName == 'getObjectMappingsByDeveloperName') {
                Data_Import_Object_Mapping__mdt objectMapping1 =
                    new Data_Import_Object_Mapping__mdt(
                        Id=account1ObjectMappingId,
                        Label='Account 1',
                        DeveloperName='Account1',
                        Object_API_Name__c='Account',
                        Imported_Record_Field_Name__c='npsp__Account1Imported__c',
                        Imported_Record_Status_Field_Name__c='npsp__Account1ImportStatus__c');

                Data_Import_Object_Mapping__mdt objectMapping2 =
                    new Data_Import_Object_Mapping__mdt(
                        Id=account2ObjectMappingId,
                        Label='Account 2',
                        DeveloperName='Account2',
                        Object_API_Name__c='Account',
                        Imported_Record_Field_Name__c='npsp__Account2Imported__c',
                        Imported_Record_Status_Field_Name__c='npsp__Account2ImportStatus__c');

                return new Map<String, Data_Import_Object_Mapping__mdt>{
                    'Account1' => objectMapping1,
                    'Account2' => objectMapping2};
            }

            /*if (stubbedMethodName == 'getAllMappingDetailsBySourceFieldName') {
                BDI_HelpTextCMT.MappingDetail account1CityMappingDetail = new BDI_HelpTextCMT.MappingDetail(
                    'Account1',
                    'Account1 City',
                    'Account',
                    'BillingCity',
                    'Account1Imported__c',
                    'Account1ImportStatus__c');

                BDI_HelpTextCMT.MappingDetail account2CityMappingDetail = new BDI_HelpTextCMT.MappingDetail(
                    'Account2',
                    'Account2 City',
                    'Account',
                    'BillingCity',
                    'Account2Imported__c',
                    'Account2ImportStatus__c');

                BDI_HelpTextCMT.MappingDetail newCustomFieldMappingDetail = new BDI_HelpTextCMT.MappingDetail(
                    'Account1',
                    'Account1 New Custom Field',
                    'Account',
                    'New_Custom_Field__c',
                    'Account1Imported__c',
                    'Account1ImportStatus__c');

                return new Map<String, BDI_HelpTextCMT.MappingDetail>{
                    'npsp__Account1_City__c' => account1CityMappingDetail,
                    'npsp__Account2_City__c' => account2CityMappingDetail,
                    'New_Custom_Field__c' => newCustomFieldMappingDetail};
            }

            if (stubbedMethodName == 'getFieldMappingsByFieldMappingSetDeveloperName') {
                Data_Import_Field_Mapping_Set__mdt fieldMappingSet =
                    new Data_Import_Field_Mapping_Set__mdt(
                        Id=getFakeId(Schema.Data_Import_Field_Mapping_Set__mdt.SObjectType),
                        DeveloperName='Default_Field_Mapping_Set',
                        MasterLabel='Default Field Mapping Set',
                        Label='Default Field Mapping Set');

                Data_Import_Object_Mapping__mdt account1ObjectMapping =
                    new Data_Import_Object_Mapping__mdt(
                        Id=account1ObjectMappingId,
                        DeveloperName='Account1',
                        MasterLabel='Account 1',
                        Label='Account 1',
                        Object_API_Name__c='Account',
                        Imported_Record_Field_Name__c='npsp__Account1Imported__c',
                        Imported_Record_Status_Field_Name__c='npsp__Account1ImportStatus__c');

                Data_Import_Object_Mapping__mdt account2ObjectMapping =
                    new Data_Import_Object_Mapping__mdt(
                        Id=account2ObjectMappingId,
                        DeveloperName='Account2',
                        MasterLabel='Account 2',
                        Label='Account 2',
                        Object_API_Name__c='Account',
                        Imported_Record_Field_Name__c='npsp__Account2Imported__c',
                        Imported_Record_Status_Field_Name__c='npsp__Account2ImportStatus__c');

                Data_Import_Field_Mapping__mdt fieldMapping1 =
                    new Data_Import_Field_Mapping__mdt(
                        MasterLabel='Account 1 City',
                        DeveloperName='Account_1_City',
                        Source_Field_API_Name__c='npsp__Account1_City__c',
                        Target_Field_API_Name__c='BillingCity',
                        Data_Import_Field_Mapping_Set__c=fieldMappingSet.Id,
                        Target_Object_Mapping__c=account1ObjectMapping.Id,
                        Required__c='No');

                Data_Import_Field_Mapping__mdt fieldMapping2 =
                    new Data_Import_Field_Mapping__mdt(
                        MasterLabel='Account 2 City',
                        DeveloperName='Account_2_City',
                        Source_Field_API_Name__c='npsp__Account2_City__c',
                        Target_Field_API_Name__c='BillingCity',
                        Data_Import_Field_Mapping_Set__c=fieldMappingSet.Id,
                        Target_Object_Mapping__c=account2ObjectMapping.Id,
                        Required__c='No');

                return new Map<String, Data_Import_Field_Mapping__mdt>{
                    'Account.Account1.npsp__Account1_City__c' => fieldMapping1,
                    'Account.Account2.npsp__Account2_City__c' => fieldMapping2};
            }

            return null;
        }
    }*/

    // DeployCallbackContext subclass for testing that returns jobId
    public class TestingDeployCallbackContext extends Metadata.DeployCallbackContext {
        public override Id getCallbackJobId() {
            return '000000000122345';
        }
    }
}