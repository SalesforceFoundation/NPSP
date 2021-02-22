public with sharing class DataImportsFactory {

    public DataImports createFromElevateTransactionIds(Set<String> elevateTransactionIds) {
        DataImportsSelector selector = new DataImportsSelector();
        List<DataImport__c> dataImportsToMarkPaid = selector
                .selectByElevateTransactionId(elevateTransactionIds);

        DataImports dataImportsDomain = new DataImports(dataImportsToMarkPaid);
        return dataImportsDomain;
    }

}