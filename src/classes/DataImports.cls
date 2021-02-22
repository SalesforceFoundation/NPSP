public with sharing class DataImports extends fflib_SObjects {

    public DataImports(List<DataImport__c> records) {
        super(records, DataImport__c.SObjectType);
    }

    public void markPaid() {
        setFieldValue(DataImport__c.Payment_Status__c, PaymentStatus.Paid.name());
//        update (List<DataImport__c>) getRecords(); // Will use injected DmlWrapper or UOW
    }

    public void importData() {
        // Send through BDI processing
    }

    public fflib_SObjects withPaidPayments() {
        fflib_SObjects withPaidPayments = selectByFieldValue(
                DataImport__c.Payment_Status__c, PaymentStatus.Paid.name());
        return withPaidPayments;
    }
}