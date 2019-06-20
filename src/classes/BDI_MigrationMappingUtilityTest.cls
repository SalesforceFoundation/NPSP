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

    @isTest
    static void shouldCreateCustomMetadataRecordsFromHelpText() {
        // Create a mock version of the BDI_MigrationUtilityHelper class
        BDI_MigrationMappingHelper mock_BDI_MigrationMappingHelper =
            (BDI_MigrationMappingHelper) Test.createStub(
                BDI_MigrationMappingHelper.class,
                new BDI_MigrationMappingHelperMock());

        BDI_MigrationMappingUtility util = new BDI_MigrationMappingUtility(mock_BDI_MigrationMappingHelper);
        BDI_MigrationMappingHelper helper = new BDI_MigrationMappingHelper();

        util.dataImportFieldMappings = buildDataImportFieldMappingsFromHelpText();
        util.badHelpTextMappings = buildBadHelpTextMappings();

        util.migrateHelpTextToCustomMetadata();

        if (util.customFieldMappingSetExists == true) {
            System.assertEquals(6,
                util.queuedMetadataTypesForDeploy.size(),
                'We have 6 metadata records queued for deployment.');
        } else {
            System.assertEquals(7,
                util.queuedMetadataTypesForDeploy.size(),
                'We have 7 metadata records queued for deployment including the custom field mapping set.');
        }

        System.assertEquals(2, util.badHelpTextMappings.size(), 'We have 2 bad help text field mappings.');

        // Confirm that we can get custom metadata from "pendingMappings"
        Metadata.CustomMetadata cmt = util.queuedMetadataTypesForDeploy[3];
        System.assertEquals('Account 1 Custom Field', cmt.label);
    }

    @IsTest
    static void shouldPopulateListsFromHelpText() {
        // Create a mock version of the BDI_MigrationUtilityHelper class
        BDI_MigrationMappingHelper mock_BDI_MigrationMappingHelper =
            (BDI_MigrationMappingHelper) Test.createStub(
                BDI_MigrationMappingHelper.class,
                new BDI_MigrationMappingHelperMock());

        // Start migration
        BDI_MigrationMappingUtility util = new BDI_MigrationMappingUtility(mock_BDI_MigrationMappingHelper);
        util.populateListsFromHelpTextMappings();

        System.assertNotEquals(util.badHelpTextMappings, null);
        System.assertNotEquals(util.dataImportFieldMappings, null);
    }

    @IsTest
    static void shouldUpdateCustomSettingsForDataImportFieldMapping() {
        // Create a mock version of the BDI_MigrationUtilityHelper class
        BDI_MigrationMappingHelper mock_BDI_MigrationMappingHelper =
            (BDI_MigrationMappingHelper) Test.createStub(
                BDI_MigrationMappingHelper.class,
                new BDI_MigrationMappingHelperMock());

        Test.startTest();

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

    private static List<BDI_MigrationMappingUtility.DataImportFieldMapping> buildDataImportFieldMappingsFromHelpText() {
        BDI_MigrationMappingUtility.DataImportFieldMapping account1NameHelpText =
            new BDI_MigrationMappingUtility.DataImportFieldMapping();
        account1NameHelpText.label = 'Account 1 Name';
        account1NameHelpText.sourceFieldAPIName = 'npsp__Account1_Name__c';
        account1NameHelpText.dataImportObjectName = 'Account1';
        account1NameHelpText.targetFieldAPIName = 'Custom_Name__c';
        account1NameHelpText.targetObjectAPIName = 'Account';

        BDI_MigrationMappingUtility.DataImportFieldMapping account1CityHelpText =
            new BDI_MigrationMappingUtility.DataImportFieldMapping();
        account1CityHelpText.label = 'Account 1 City';
        account1CityHelpText.sourceFieldAPIName = 'npsp__Account1_City__c';
        account1CityHelpText.dataImportObjectName = 'Account1';
        account1CityHelpText.targetFieldAPIName = 'BillingCity';
        account1CityHelpText.targetObjectAPIName = 'Account';

        BDI_MigrationMappingUtility.DataImportFieldMapping account1CustomFieldHelpText =
            new BDI_MigrationMappingUtility.DataImportFieldMapping();
        account1CustomFieldHelpText.label = 'Account 1 Custom Field';
        account1CustomFieldHelpText.sourceFieldAPIName = 'npsp__Account1_Custom_Field__c';
        account1CustomFieldHelpText.dataImportObjectName = 'Account1';
        account1CustomFieldHelpText.targetFieldAPIName = 'Custom_Field__c';
        account1CustomFieldHelpText.targetObjectAPIName = 'Account';

        BDI_MigrationMappingUtility.DataImportFieldMapping account1CustomFieldHelpText2 =
            new BDI_MigrationMappingUtility.DataImportFieldMapping();
        account1CustomFieldHelpText2.label = 'Account 1 Name';
        account1CustomFieldHelpText2.sourceFieldAPIName = 'npsp__Account1_Custom_Field__c';
        account1CustomFieldHelpText2.dataImportObjectName = 'Account1';
        account1CustomFieldHelpText2.targetFieldAPIName = 'Custom_Field_Long_Name_xxxxxxxxxxxxxxxxxxxx__c';
        account1CustomFieldHelpText2.targetObjectAPIName = 'Account';

        BDI_MigrationMappingUtility.DataImportFieldMapping account2CityHelpText =
            new BDI_MigrationMappingUtility.DataImportFieldMapping();
        account2CityHelpText.label = 'Account 2 Name';
        account2CityHelpText.sourceFieldAPIName = 'npsp__Account2_City__c';
        account2CityHelpText.dataImportObjectName = 'Account2';
        account2CityHelpText.targetFieldAPIName = 'BillingCity';
        account2CityHelpText.targetObjectAPIName = 'Account';

        return new List<BDI_MigrationMappingUtility.DataImportFieldMapping>{
            account1NameHelpText,
            account1CityHelpText,
            account2CityHelpText,
            account1CustomFieldHelpText,
            account1CustomFieldHelpText2};
    }

    private static List<BDI_MigrationMappingUtility.HelpTextFieldMapping> buildBadHelpTextMappings() {
        BDI_MigrationMappingUtility.HelpTextFieldMapping badAccount1Mapping =
            (BDI_MigrationMappingUtility.HelpTextFieldMapping)JSON.deserialize(
                '{"targetObjectAPIName":"AcCount1","targetFieldAPIName":"BillingCity",' +
                    '"isUsable":false,"isPotentialMapping":true,"helpText":"AcCount1.BillingCity"}',
                BDI_MigrationMappingUtility.HelpTextFieldMapping.class);

        BDI_MigrationMappingUtility.HelpTextFieldMapping badAccount3Mapping =
            (BDI_MigrationMappingUtility.HelpTextFieldMapping)JSON.deserialize(
                '{"targetObjectAPIName":"Account3","targetFieldAPIName":"BillingCity",' +
                    '"isUsable":false,"isPotentialMapping":true,"helpText":"Account3.BillingCity"}',
                BDI_MigrationMappingUtility.HelpTextFieldMapping.class);

        return new List<BDI_MigrationMappingUtility.HelpTextFieldMapping>{
            badAccount1Mapping,
            badAccount3Mapping};
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
        private String gauObjectMappingId = getFakeId(Schema.Data_Import_Object_Mapping__mdt.SObjectType);

        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, Type returnType,
            List<Type> listOfParamTypes, List<String> listOfParamNames, List<Object> listOfArgs) {

            if (stubbedMethodName == 'getFieldMappingSet') {
                List<Data_Import_Field_Mapping_Set__mdt> fieldMappingSets =
                    new List<Data_Import_Field_Mapping_Set__mdt>{
                        new Data_Import_Field_Mapping_Set__mdt(
                            Label='Default Field Mapping Set',
                            DeveloperName='Default_Field_Mapping_Set')};

                return fieldMappingSets;
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

            if (stubbedMethodName == 'getFieldMappingsByFieldMappingSetDeveloperName') {
                Data_Import_Field_Mapping_Set__mdt fieldMappingSet;

                if (listOfArgs.contains('Migrated_Custom_Field_Mapping_Set')) {
                    fieldMappingSet = new Data_Import_Field_Mapping_Set__mdt(
                        Id=getFakeId(Schema.Data_Import_Field_Mapping_Set__mdt.SObjectType),
                        DeveloperName='Migrated_Custom_Field_Mapping_Set',
                        MasterLabel='Migrated Custom Field Mapping Set',
                        Label='Migrated Custom Field Mapping Set');
                } else {
                    fieldMappingSet = new Data_Import_Field_Mapping_Set__mdt(
                        Id=getFakeId(Schema.Data_Import_Field_Mapping_Set__mdt.SObjectType),
                        DeveloperName='Default_Field_Mapping_Set',
                        MasterLabel='Default Field Mapping Set',
                        Label='Default Field Mapping Set');
                }

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

                Data_Import_Object_Mapping__mdt gauObjectMapping =
                    new Data_Import_Object_Mapping__mdt(
                        Id=gauObjectMappingId,
                        DeveloperName='GAU_Allocation_1',
                        MasterLabel='GAU Allocation 1',
                        Label='GAU Allocation 1',
                        Object_API_Name__c='npsp__Allocation__c',
                        Imported_Record_Field_Name__c='npsp__GAU_Allocation_1_Imported__c',
                        Imported_Record_Status_Field_Name__c='npsp__GAU_Allocation_1_Import_Status__c');

                Data_Import_Field_Mapping__mdt fieldMapping =
                    (Data_Import_Field_Mapping__mdt)JSON.deserialize(
                        '{"Id":"' + getFakeId(Schema.Data_Import_Field_Mapping__mdt.SObjectType) + '",' +
                        '"MasterLabel":"Account 1 Name",' +
                        '"DeveloperName":"npsp__Account1_Name",' +
                        '"Source_Field_API_Name__c":"npsp__Account1_Name__c",' +
                        '"Target_Field_API_Name__c":"Name",' +
                        '"Required__c":"No",' +
                        '"Data_Import_Field_Mapping_Set__c":"' + fieldMappingSet.Id + '",' +
                        '"Target_Object_Mapping__c":"' + account1ObjectMapping.Id +
                            '","Target_Object_Mapping__r":{"Id":"' +
                            account1ObjectMapping.Id + '","DeveloperName":"Account1"}}',
                        Data_Import_Field_Mapping__mdt.class);

                Data_Import_Field_Mapping__mdt fieldMapping1 =
                    (Data_Import_Field_Mapping__mdt)JSON.deserialize(
                        '{"Id":"' + getFakeId(Schema.Data_Import_Field_Mapping__mdt.SObjectType) + '",' +
                        '"MasterLabel":"Account 1 City",' +
                        '"DeveloperName":"npsp__Account1_City",' +
                        '"Source_Field_API_Name__c":"npsp__Account1_City__c",' +
                        '"Target_Field_API_Name__c":"BillingCity",' +
                        '"Required__c":"No",' +
                        '"Data_Import_Field_Mapping_Set__c":"' + fieldMappingSet.Id + '",' +
                        '"Target_Object_Mapping__c":"' + account1ObjectMapping.Id +
                            '","Target_Object_Mapping__r":{"Id":"'
                            + account1ObjectMapping.Id + '","DeveloperName":"Account1"}}',
                        Data_Import_Field_Mapping__mdt.class);

                Data_Import_Field_Mapping__mdt fieldMapping2 =
                    (Data_Import_Field_Mapping__mdt)JSON.deserialize(
                        '{"Id":"' + getFakeId(Schema.Data_Import_Field_Mapping__mdt.SObjectType) + '",' +
                        '"MasterLabel":"Account 2 City",' +
                        '"DeveloperName":"npsp__Account2_City",' +
                        '"Source_Field_API_Name__c":"npsp__Account2_City__c",' +
                        '"Target_Field_API_Name__c":"BillingCity",' +
                        '"Required__c":"No",' +
                        '"Data_Import_Field_Mapping_Set__c":"' + fieldMappingSet.Id + '",' +
                        '"Target_Object_Mapping__c":"' + account2ObjectMapping.Id +
                            '","Target_Object_Mapping__r":{"Id":"'
                            + account2ObjectMapping.Id + '","DeveloperName":"Account2"}}',
                        Data_Import_Field_Mapping__mdt.class);

                Data_Import_Field_Mapping__mdt fieldMapping3 =
                    (Data_Import_Field_Mapping__mdt)JSON.deserialize(
                        '{"Id":"' + getFakeId(Schema.Data_Import_Field_Mapping__mdt.SObjectType) + '",' +
                        '"MasterLabel":"GAU Allocation 1: Amount",' +
                        '"DeveloperName":"GAU_Allocation_1_Amount",' +
                        '"Source_Field_API_Name__c":"npsp__GAU_Allocation_1_Amount__c",' +
                        '"Target_Field_API_Name__c":"npsp__Amount__c",' +
                        '"Required__c":"No",' +
                        '"Data_Import_Field_Mapping_Set__c":"' + fieldMappingSet.Id + '",' +
                        '"Target_Object_Mapping__c":"' + gauObjectMapping.Id +
                            '","Target_Object_Mapping__r":{"Id":"' + gauObjectMapping.Id +
                            '","DeveloperName":"GAU_Allocation_1","MasterLabel":"GAU Allocation 1"}}',
                        Data_Import_Field_Mapping__mdt.class);

                return new Map<String, Data_Import_Field_Mapping__mdt>{
                    'Account.Account1.npsp__Account1_Name__c' => fieldMapping,
                    'Account.Account1.npsp__Account1_City__c' => fieldMapping1,
                    'Account.Account2.npsp__Account2_City__c' => fieldMapping2,
                    'npsp__Allocation__c.GAU_Allocation_1.npsp__GAU_Allocation_1_Amount__c' => fieldMapping3};
            }

            return null;
        }
    }

    // DeployCallbackContext subclass for testing that returns jobId
    public class TestingDeployCallbackContext extends Metadata.DeployCallbackContext {
        public override Id getCallbackJobId() {
            return '000000000122345';
        }
    }
}