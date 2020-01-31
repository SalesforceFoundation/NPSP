@isTest
private with sharing class GE_BatchGiftEntryController_TEST {

    /*********************************************************************************************************
    * @description Sets up a new NPSP_Data_Import_Batch__c Record
    * @return Id of the new NPSP_Data_Import_Batch__c
    */
    private static Id createDataImportBatch() {
        DataImportBatch__c dataImportBatch = new DataImportBatch__c();
        dataImportBatch.Name = 'Batch 1';

        insert dataImportBatch;
        return (Id)dataImportBatch.Id;
    }

    /*******************************************************************************************************
    * @description creates a new di record for tests
    * @param firstname the firstname to specify for Contact1
    * @param lastname the lastname to specify for Contact1
    * @return DataImport__c the new Data Import record
    */
    public static DataImport__c newDI(String firstname, String lastname) {
        return new DataImport__c(
                Contact1_Firstname__c = firstname,
                Contact1_Lastname__c = lastname,
                Contact1_Personal_Email__c = firstname + '@' + lastname + '.com'
        );
    }
    
    /*******************************************************************************************************
     * @description Saves the data import record, dry runs the record, and returns updated
     * totals with the new row.
     */
    @isTest
    private static void saveAndDryRunRow_test() {

        String firstName = 'fooName';
        String lastName = 'fooLastName';
        Id batchId = createDataImportBatch();
        DataImport__c di = newDI( firstName, lastName );

        Test.startTest();
            GE_BatchGiftEntryController.saveAndDryRunRow(batchId,di);
        Test.stopTest();

        List<DataImportBatch__c> result = [SELECT Id FROM DataImportBatch__c];
        System.assertEquals( result.size(), 1 );

    }

    /*******************************************************************************************************
    * @description Saves the data import record, dry runs the record, and returns updated
    * totals with the new row.
    */
    @isTest
    private static void alignClassNSWithEnvironment_test() {
        // TODO: placeholder... actual implementation needed
        Test.stopTest();
            String result = GE_BatchGiftEntryController.alignClassNSWithEnvironment('foo');
            System.assertNotEquals( result, null, 'Result should be ...' );
        Test.startTest();
    }

}
