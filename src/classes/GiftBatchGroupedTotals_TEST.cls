@isTest
private with sharing class GiftBatchGroupedTotals_TEST {

    @isTest
    private static void shouldReturnMapContainingCorrectRecordCounts() {
        Id DUMMY_ID = Id.valueOf('001xa000003DIlo');
        List<AggregateResultProxy> resultProxies = new List<AggregateResultProxy> {
            new AggregateResultProxy()
                .withAliasAndValue('NPSP_Data_Import_Batch__c', DUMMY_ID)
                .withAliasAndValue('Status__c','Imported')
                .withAliasAndValue('recordCount', 1),
            new AggregateResultProxy()
                .withAliasAndValue('NPSP_Data_Import_Batch__c', DUMMY_ID)
                .withAliasAndValue('Status__c','Failed')
                .withAliasAndValue('recordCount', 2),
            new AggregateResultProxy()
                .withAliasAndValue('NPSP_Data_Import_Batch__c', DUMMY_ID)
                .withAliasAndValue('Payment_Status__c','AUTHORIZED')
                .withAliasAndValue('recordCount', 3),
            new AggregateResultProxy()
                .withAliasAndValue('NPSP_Data_Import_Batch__c', DUMMY_ID)
                .withAliasAndValue('Payment_Status__c','DECLINED')
                .withAliasAndValue('recordCount', 4),
            new AggregateResultProxy()
                .withAliasAndValue('NPSP_Data_Import_Batch__c', DUMMY_ID)
                .withAliasAndValue('Status__c', 'Failed')
                .withAliasAndValue('Payment_Status__c','DECLINED')
                .withAliasAndValue('recordCount', 5)
        };

        GiftBatchGroupedTotals batchTotals = new GiftBatchGroupedTotals(resultProxies);
        Map<String, Integer> mappedTotals = batchTotals.totalsFor(DUMMY_ID);

        System.assertEquals(1, mappedTotals.get(GiftBatchAggregateGroupName.PROCESSED.name()));
        System.assertEquals(7, mappedTotals.get(GiftBatchAggregateGroupName.FAILED.name()));
        System.assertEquals(9, mappedTotals.get(GiftBatchAggregateGroupName.FAILED_PAYMENT.name()));
        System.assertEquals(1 + 2 + 3 + 4 + 5, mappedTotals.get(GiftBatchAggregateGroupName.TOTAL.name()));
    }
}

