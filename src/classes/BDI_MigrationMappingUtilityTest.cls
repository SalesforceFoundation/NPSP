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

    @IsTest
    static void migrationUtilityCreatesCustomMetadataRecordsFromHelpText() {
        // Create a mock version of the BDI_MigrationUtilityHelper class
        BDI_MigrationMappingHelper mock_BDI_MigrationMappingHelper =
                (BDI_MigrationMappingHelper) Test.createStub(
                        BDI_MigrationMappingHelper.class,
                        new BDI_MigrationMappingHelperMock());

        // Call build method
        BDI_MigrationMappingUtility util = new BDI_MigrationMappingUtility();
        util.buildCustomMetadataRecordsFromHelpText(mock_BDI_MigrationMappingHelper);

        // Confirm that we have a new pending data import field mapping waiting to be deployed
        System.assertEquals(1, util.pendingCMTs.size());

        // Confirm that we can get custom metadata from "pendingCMTs"
        Metadata.CustomMetadata cmt = util.pendingCMTs[0].getMetadataRecord();
        System.assertEquals('New Mapping', cmt.label);
    }

    @IsTest
    static void migrationUtilityDeploysWithMetadata() {
        // Create a mock version of the BDI_MigrationUtilityHelper class.
        BDI_MigrationMappingHelper mock_BDI_MigrationMappingHelper =
                (BDI_MigrationMappingHelper) Test.createStub(
                        BDI_MigrationMappingHelper.class,
                        new BDI_MigrationMappingHelperMock());

        // Call the method
        BDI_MigrationMappingUtility util = new BDI_MigrationMappingUtility();
        util.buildCustomMetadataRecordsFromHelpText(mock_BDI_MigrationMappingHelper);

        Test.startTest();

        // Convert mappings to Custom Metadata and start deployment
        String jobId = util.convertLegacyHelpTextToCustomMetadata();

        // Confirm custom settings updated accordingly
        CMT_MetadataAPI.MetadataCallBack callback = new CMT_MetadataAPI.MetadataCallBack(jobId, CMT_MetadataAPI.Source.HELP_TEXT_MIGRATION);

        // Construct a dummy Context
        TestingDeployCallbackContext context = new TestingDeployCallbackContext();

        // Call the handleResult() method of our main Callback with our dummy context var
        callback.handleResult(null, context);

        Test.stopTest();

        // Confirm that we've updated the CMT API Status field in Data Import Settings
        Data_Import_Settings__c dataImportSettings = UTIL_CustomSettingsFacade.getDataImportSettings();
        Map<String,String> result = (Map<String,String>)JSON.deserialize(dataImportSettings.CMT_API_Status__c, Map<String,String>.class);

        System.assertNotEquals(null, result.get(jobId), result);
    }

    @IsTest
    static void migrationUtilityDeploysWithoutMetadata() {
        BDI_MigrationMappingUtility util = new BDI_MigrationMappingUtility();

        Test.startTest();
        // Convert mappings to Custom Metadata and start deployment
        String jobId = util.convertLegacyHelpTextToCustomMetadata();

        // Confirm custom settings updated accordingly
        CMT_MetadataAPI.MetadataCallBack callback = new CMT_MetadataAPI.MetadataCallBack(jobId, CMT_MetadataAPI.Source.HELP_TEXT_MIGRATION);

        // Construct a dummy Context
        TestingDeployCallbackContext context = new TestingDeployCallbackContext();

        // Call the handleResult() method of our main Callback with our dummy context var
        callback.handleResult(null, context);

        Test.stopTest();

        // Confirm that we've updated the CMT API Status field in Data Import Settings
        Data_Import_Settings__c dataImportSettings = UTIL_CustomSettingsFacade.getDataImportSettings();
        Map<String,String> result = (Map<String,String>)JSON.deserialize(dataImportSettings.CMT_API_Status__c, Map<String,String>.class);

        System.assertNotEquals(null, result.get(jobId), result);
    }

    private class BDI_MigrationMappingHelperMock implements System.StubProvider {

        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName,
                Type returnType, List<Type> listOfParamTypes, List<String> listOfParamNames,
                List<Object> listOfArgs) {

            if (stubbedMethodName == 'getAllMappedHelpTextFields') {
                BDI_HelpTextCMT.MappingDetail mapping1 = new BDI_HelpTextCMT.MappingDetail(
                        'Account1',
                        'test1_dataImportFieldLabel',
                        'test1_targetObjectName',
                        'test1_targetFieldAPIName',
                        'test1_importedRecordField',
                        'test1_importedRecordStatusField'
                );

                BDI_HelpTextCMT.MappingDetail mapping2 = new BDI_HelpTextCMT.MappingDetail(
                        'Account2',
                        'test2_dataImportFieldLabel',
                        'test2_targetObjectName',
                        'test2_targetFieldAPIName',
                        'test2_importedRecordField',
                        'test2_importedRecordStatusField'
                );

                BDI_HelpTextCMT.MappingDetail mapping3 = new BDI_HelpTextCMT.MappingDetail(
                        'Account2',
                        'New Mapping',
                        'test3_targetObjectName',
                        'test3_targetFieldAPIName',
                        'test3_importedRecordField',
                        'test3_importedRecordStatusField'
                );

                return new Map<String, BDI_HelpTextCMT.MappingDetail>{
                        'npsp__Account1_City__c' => mapping1, 'npsp__Account2_City__c' => mapping2, 'New_Mapping__c' => mapping3
                };
            }

            if (stubbedMethodName == 'getDefaultObjectMappings') {
                Data_Import_Object_Mapping__mdt objectMapping1 = new Data_Import_Object_Mapping__mdt(
                    Label='Account 1',
                    DeveloperName='Account1',
                    Object_API_Name__c='Account',
                    Imported_Record_Field_Name__c='npsp__Account1Imported__c',
                    Imported_Record_Status_Field_Name__c='npsp__Account1ImportStatus__c'
                );

                Data_Import_Object_Mapping__mdt objectMapping2 = new Data_Import_Object_Mapping__mdt(
                    Label='Account 2',
                    DeveloperName='Account2',
                    Object_API_Name__c='Account',
                    Imported_Record_Field_Name__c='npsp__Account2Imported__c',
                    Imported_Record_Status_Field_Name__c='npsp__Account2ImportStatus__c'
                );

                return new Map<String, Data_Import_Object_Mapping__mdt>{
                    'Account1' => objectMapping1,
                    'Account2' => objectMapping2
                };
            }

            if (stubbedMethodName == 'getDefaultFieldMappings') {
                Data_Import_Field_Mapping__mdt fieldMapping1 = new Data_Import_Field_Mapping__mdt(
                    Label='Account 1 City',
                    DeveloperName='Account_1_City',
                    Source_Field_API_Name__c='npsp__Account1_City__c',
                    Target_Field_API_Name__c='BillingCity'
                );

                Data_Import_Field_Mapping__mdt fieldMapping2 = new Data_Import_Field_Mapping__mdt(
                    Label='Account 2 City',
                    DeveloperName='Account_2_City',
                    Source_Field_API_Name__c='npsp__Account2_City__c',
                    Target_Field_API_Name__c='BillingCity'
                );

                return new Map<String, Data_Import_Field_Mapping__mdt>{
                    'npsp__Account1_City__c' => fieldMapping1,
                    'npsp__Account2_City__c' => fieldMapping2
                };
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