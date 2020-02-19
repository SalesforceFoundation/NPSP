@isTest
private with sharing class GE_GiftEntryController_TEST {

    /*********************************************************************************************************
    * @description Sets up a new NPSP_Data_Import_Batch__c Record
    * @return Id of the new NPSP_Data_Import_Batch__c
    */
    private static Id createDataImportBatch( String batchName ) {
        DataImportBatch__c dataImportBatch = new DataImportBatch__c();
        dataImportBatch.Name = batchName;

        insert dataImportBatch;
        return (Id)dataImportBatch.Id;
    }

    /*******************************************************************************************************
    * @description creates a new di record for tests
    * @param firstname the firstname to specify for Contact1
    * @param lastname the lastname to specify for Contact1
    * @return DataImport__c the new Data Import record
    */
    public static DataImport__c newDI(String firstname, String lastname, Id batchId) {
        return new DataImport__c(
                Contact1_Firstname__c = firstname,
                Contact1_Lastname__c = lastname,
                Contact1_Personal_Email__c = firstname + '@' + lastname + '.com',
                NPSP_Data_Import_Batch__c = batchId
        );
    }

    /*******************************************************************************************************
     * @description Confirm that the DataImport process used in Gift Entry works
     */
    @isTest
    private static void createAndProcessDataImportRecord() {
        DataImport__c di = BDI_DataImport_TEST.newDI('First', 'Last', 100);
        // TODO: Update this test to take a Additional Object string, and also process that
        Id oppId = GE_GiftEntryController.saveAndProcessDataImport(di, null, false);
        System.assert(oppId != null);
    }

    /*******************************************************************************************************
     * @description Saves the data import record, dry runs the record, and returns updated
     * totals with the new row.
     */
    @isTest
    private static void testShouldSaveAndDryRunDataImport() {

        // required setting
        UTIL_CustomSettingsFacade.getDataImportSettings();
        // aux vars
        String firstName = 'fooName';
        String lastName = 'fooLastName';
        String batchName = 'fooBatch';
        // test data
        Id batchId = createDataImportBatch( batchName );
        DataImport__c di = newDI( firstName, lastName, batchId );

        Test.startTest();
        GE_GiftEntryController.saveAndDryRunDataImport(batchId,di,'');
        Test.stopTest();

        List<DataImportBatch__c> result = [SELECT Id FROM DataImportBatch__c];
        System.assertEquals( result.size(), 1 );

    }

}