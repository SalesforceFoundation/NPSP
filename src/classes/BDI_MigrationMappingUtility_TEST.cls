/**
 * Created by kenneth.lewis on 2019-05-08.
 */

@IsTest
private class BDI_MigrationMappingUtility_TEST {

    @IsTest
    static void migrationUtilityCreatesCustomMetadataRecordsFromHelpText() {
        //1. Set the mock
        // Create a mock version of the BDI_MigrationUtilityHelper class.
        BDI_MigrationMappingHelper mock_BDI_MigrationMappingHelper =
                (BDI_MigrationMappingHelper) Test.createStub(
                        BDI_MigrationMappingHelper.class,
                        new BDI_MigrationMappingHelperMock());

        //2. Call the method
        BDI_MigrationMappingUtility util = new BDI_MigrationMappingUtility();
        util.buildCustomMetadataRecordsFromHelpText(mock_BDI_MigrationMappingHelper);

        //3. Verify results - if we were doing regular DML for the net new (pending) mappings, we might do this to verify:

        //But since we are deploying the metadata, we'll probably need to simply inspect the property of the instance
        System.debug(LoggingLevel.ERROR, '*** variable value: ' + util.pendingCMTs);
        //Confirm that "pendingCMTs" now contains the mocked mappings that will be deployed...

        //Confirm that we have two pending data import field mappings
        System.assertEquals(1, util.pendingCMTs.size());

        //Confirm that we can get custom metadata from "pendingCMTs"
        Metadata.CustomMetadata cmt = util.pendingCMTs[0].getMetadataRecord();
        System.assertEquals('New Mapping', cmt.label);
    }

    private class BDI_MigrationMappingHelperMock implements System.StubProvider {

        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName,
                Type returnType, List<Type> listOfParamTypes, List<String> listOfParamNames,
                List<Object> listOfArgs) {

            System.debug(LoggingLevel.ERROR, '*** ##### in handleMethodCall ######');
            System.debug(LoggingLevel.ERROR, '*** variable value stubbedMethodName: ' + stubbedMethodName);

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
}