@isTest
private with sharing class GiftBatchGroupedTotals_TEST {

    @isTest
    private static void shouldReturnMapContainingCorrectRecordCounts() {
        Id DUMMY_BATCH_ID_0 = Id.valueOf('001xa000003DIlo');
        List<AggregateResultProxy> proxiesForBatch0 = new List<AggregateResultProxy> {
            new AggregateResultProxy()
                .withAliasAndValue('NPSP_Data_Import_Batch__c', DUMMY_BATCH_ID_0)
                .withAliasAndValue('Status__c','Imported')
                .withAliasAndValue('recordCount', 1),
            new AggregateResultProxy()
                .withAliasAndValue('NPSP_Data_Import_Batch__c', DUMMY_BATCH_ID_0)
                .withAliasAndValue('Status__c','Failed')
                .withAliasAndValue('recordCount', 2),
            new AggregateResultProxy()
                .withAliasAndValue('NPSP_Data_Import_Batch__c', DUMMY_BATCH_ID_0)
                .withAliasAndValue('Payment_Status__c','AUTHORIZED')
                .withAliasAndValue('recordCount', 3)
        };

        Id DUMMY_BATCH_ID_1 = Id.valueOf('002zb000004EJmp');
        List<AggregateResultProxy> proxiesForBatch1 = new List<AggregateResultProxy> {
            new AggregateResultProxy()
                .withAliasAndValue('NPSP_Data_Import_Batch__c', DUMMY_BATCH_ID_1)
                .withAliasAndValue('Payment_Status__c','DECLINED')
                .withAliasAndValue('recordCount', 4),
            new AggregateResultProxy()
                .withAliasAndValue('NPSP_Data_Import_Batch__c', DUMMY_BATCH_ID_1)
                .withAliasAndValue('Status__c', 'Failed')
                .withAliasAndValue('Payment_Status__c','DECLINED')
                .withAliasAndValue('recordCount', 5)
        };

        List<AggregateResultProxy> allProxies = new List<AggregateResultProxy>();
        allProxies.addAll(proxiesForBatch0);
        allProxies.addAll(proxiesForBatch1);
        GiftBatchGroupedTotals batchTotals = new GiftBatchGroupedTotals(allProxies);

        Map<String, Integer> totalsForBatch0 = batchTotals.totalsFor(DUMMY_BATCH_ID_0);
        System.assertEquals(1, totalsForBatch0.get(GiftBatchAggregateGroupName.PROCESSED.name()));
        System.assertEquals(2, totalsForBatch0.get(GiftBatchAggregateGroupName.FAILED.name()));
        System.assertEquals(0, totalsForBatch0.get(GiftBatchAggregateGroupName.FAILED_PAYMENT.name()));
        System.assertEquals(1 + 2 + 3, totalsForBatch0.get(GiftBatchAggregateGroupName.TOTAL.name()));

        Map<String, Integer> totalsForBatch1 = batchTotals.totalsFor(DUMMY_BATCH_ID_1);
        System.assertEquals(0, totalsForBatch1.get(GiftBatchAggregateGroupName.PROCESSED.name()));
        System.assertEquals(5, totalsForBatch1.get(GiftBatchAggregateGroupName.FAILED.name()));
        System.assertEquals(9, totalsForBatch1.get(GiftBatchAggregateGroupName.FAILED_PAYMENT.name()));
        System.assertEquals(4 + 5, totalsForBatch1.get(GiftBatchAggregateGroupName.TOTAL.name()));
    }
}
