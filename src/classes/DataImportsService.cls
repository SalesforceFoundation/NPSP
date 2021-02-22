public with sharing class DataImportsService {

    // Service method used to instantiate an instance of the domain class and
    // orchestrate business logic/behavior
    public void markElevatePaymentsPaid(Set<String> elevateTransactionsToMarkPaid) {
        DataImportsFactory factory = new DataImportsFactory();
        DataImports dataImports =
                factory.createFromElevateTransactionIds(elevateTransactionsToMarkPaid);

        dataImports.markPaid(); // markPaid() is a business action/command, this encapsulates
                                // business logic related to DataImports inside the domain

        dataImports.importData(); // Send through BDI processing
    }
}