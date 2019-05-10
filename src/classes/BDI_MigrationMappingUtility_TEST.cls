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
        //List<Data_Import_Field_Mapping__mdt> mockedDataImportFieldMappings = getMockedDataImportFieldMappings();
        //System.assertEquals(2, mockedDataImportFieldMappings.size());

        //But since we are deploying the metadata, we'll probably need to simply inspect the property of the instance
        System.debug(LoggingLevel.ERROR, '*** variable value: ' + util.pendingCMTs);
        //Confirm that "pendingCMTs" now contains the mocked mappings that will be deployed...
        //...
        //...

        //Confirm that we have two pending data import field mappings
        System.assertEquals(2, util.pendingCMTs.size());

        //Confirm that we can get custom metadata from "pendingCMTs"
        Metadata.CustomMetadata cmt1 = util.pendingCMTs[0].getMetadataRecord();
        System.assertEquals('test1_dataImportFieldLabel', cmt1.label);

        Metadata.CustomMetadata cmt2 = util.pendingCMTs[1].getMetadataRecord();
        System.assertEquals('test2_dataImportFieldLabel', cmt2.label);
    }

    /*private static List<Data_Import_Field_Mapping__mdt> getMockedDataImportFieldMappings() {
        return [
                SELECT Id, Label, DeveloperName, Source_Field_API_Name__c
                FROM Data_Import_Field_Mapping__mdt
                WHERE Label IN ('1','2')
        ];
    }*/
}