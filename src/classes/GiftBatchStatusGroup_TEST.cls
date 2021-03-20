@isTest
private with sharing class GiftBatchStatusGroup_TEST {

    @isTest
    private static void shouldReturnTrueWithCorrectRecordCountForImportedStatusGroup() {
        AggregateResultProxy resultProxy = new AggregateResultProxy()
            .withAliasAndValue('Status__c','Imported')
            .withAliasAndValue('recordCount', 10);

        GiftBatchStatusGroup statusGroup = new GiftBatchStatusGroup(resultProxy);
        System.assert(statusGroup.isImported());
        System.assertEquals(10, statusGroup.count());
    }

    @isTest
    private static void shouldReturnFalseForNotImportedGroup() {
        AggregateResultProxy resultProxy = new AggregateResultProxy()
            .withAliasAndValue('Status__c','Dummy Status');

        GiftBatchStatusGroup statusGroup = new GiftBatchStatusGroup(resultProxy);
        System.assert(!statusGroup.isImported());
    }

    @isTest
    private static void shouldReturnTrueWithCorrectRecordCountForFailedStatusGroup() {
        AggregateResultProxy resultProxy = new AggregateResultProxy()
            .withAliasAndValue('Status__c','Failed')
            .withAliasAndValue('recordCount', 5);

        GiftBatchStatusGroup statusGroup = new GiftBatchStatusGroup(resultProxy);
        System.assert(statusGroup.isProcessingFailed());
        System.assertEquals(5, statusGroup.count());
    }

    @isTest
    private static void shouldReturnFalseForNoneFailedGroup() {
        AggregateResultProxy resultProxy = new AggregateResultProxy()
            .withAliasAndValue('Status__c','Imported');

        GiftBatchStatusGroup statusGroup = new GiftBatchStatusGroup(resultProxy);
        System.assert(!statusGroup.isProcessingFailed());
    }

    @isTest
    private static void shouldReturnTrueWithCorrectCountForGroupWithFailedPayments() {
        AggregateResultProxy resultProxy = new AggregateResultProxy()
            .withAliasAndValue('Payment_Status__c','DECLINED')
            .withAliasAndValue('recordCount', 7);

        GiftBatchStatusGroup statusGroup = new GiftBatchStatusGroup(resultProxy);
        System.assert(statusGroup.isPaymentFailed());
        System.assertEquals(7, statusGroup.count());
    }

    @isTest
    private static void shouldReturnFalseForGroupWithoutPaymentFailures() {
        AggregateResultProxy resultProxy = new AggregateResultProxy()
            .withAliasAndValue('Payment_Status__c','AUTHORIZED');

        GiftBatchStatusGroup statusGroup = new GiftBatchStatusGroup(resultProxy);
        System.assert(!statusGroup.isPaymentFailed());
    }
}
