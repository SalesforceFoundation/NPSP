@isTest
private with sharing class GiftBatchAggregateResults_TEST {

    @isTest
    private static void shouldReturnMapContainingCorrectRecordCounts() {
        List<AggregateResultProxy> resultProxies = new List<AggregateResultProxy> {
            new AggregateResultProxy()
                .withAliasAndValue('Status__c','Imported')
                .withAliasAndValue('recordCount', 1),
            new AggregateResultProxy()
                .withAliasAndValue('Status__c','Failed')
                .withAliasAndValue('recordCount', 2),
            new AggregateResultProxy()
                .withAliasAndValue('Payment_Status__c','AUTHORIZED')
                .withAliasAndValue('recordCount', 3),
            new AggregateResultProxy()
                .withAliasAndValue('Payment_Status__c','DECLINED')
                .withAliasAndValue('recordCount', 4),
            new AggregateResultProxy()
                .withAliasAndValue('Status__c', 'Failed')
                .withAliasAndValue('Payment_Status__c','DECLINED')
                .withAliasAndValue('recordCount', 5)
        };

        GiftBatchAggregateResults batchTotals = new GiftBatchAggregateResults(resultProxies);
        Map<String, Integer> mappedTotals = batchTotals.toMap();

        System.assertEquals(1, mappedTotals.get(GiftBatchAggregateGroupName.PROCESSED.name()));
        System.assertEquals(7, mappedTotals.get(GiftBatchAggregateGroupName.FAILED.name()));
        System.assertEquals(9, mappedTotals.get(GiftBatchAggregateGroupName.FAILED_PAYMENT.name()));
        System.assertEquals(1 + 2 + 3 + 4 + 5, mappedTotals.get(GiftBatchAggregateGroupName.TOTAL.name()));
    }
}

