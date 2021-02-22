public with sharing class DataImportsSelector {

    public List<DataImport__c> selectByElevateTransactionId(Set<String> ids) {
        List<DataImport__c> dataImports = [
                SELECT Id, Name, Donation_Amount__c, Payment_Status__c
                FROM DataImport__c
                WHERE Payment_Elevate_ID__c IN :ids
        ];
        return dataImports;
    }
}