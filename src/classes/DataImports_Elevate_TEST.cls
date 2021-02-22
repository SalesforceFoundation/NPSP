@IsTest
private class DataImports_Elevate_TEST {

    @IsTest
    static void shouldMarkAsPaid() {
        // Given
        List<DataImport__c> records = new List<DataImport__c>{
                new DataImport__c(),
                new DataImport__c()
        };
        DataImports dataImports = new DataImports(records);

        // When
        dataImports.markPaid();

        // Then
        fflib_SObjects paidDataImports = dataImports.withPaidPayments();
        System.assertEquals(paidDataImports.getRecords().size(), 2);
    }
}