@isTest
private class GiftBatchView_TEST {

    @isTest
    static void shouldReturn200TotalAmount() {
        GiftBatchView giftBatchView = createDummyGiftBatchViewWith(new Gifts());
        System.assertEquals(200, giftBatchView.total);
    }

    @isTest
    static void shouldReturn2TotalCount() {
        GiftBatchView giftBatchView = createDummyGiftBatchViewWith(new Gifts());
        System.assertEquals(2, giftBatchView.totalCount);
    }

    @isTest
    static void shouldHave2GiftViews() {
        Gifts gifts = new Gifts(DUMMY_DATA_IMPORTS_WITH_CONTACT_FIRST_NAME);
        GiftBatchView giftBatchView = createDummyGiftBatchViewWith(gifts);
        System.assertEquals(2, giftBatchView.gifts.size());
    }

    @isTest
    static void shouldHave0GiftViews() {
        GiftBatchView giftBatchView = createDummyGiftBatchViewWith(new Gifts());
        System.assertEquals(0, giftBatchView.gifts.size());
    }

    private static GiftBatchView createDummyGiftBatchViewWith(Gifts gifts) {
        AggregateResultProxy mockTotalsResult = new AggregateResultProxy()
            .withAliasAndValue('recordCount', 2);
        AggregateResultProxy mockedTotalAmountResult = new AggregateResultProxy()
            .withAliasAndValue('totalAmount', 200);
        GiftBatchTotals totals = new GiftBatchTotals(mockTotalsResult, mockedTotalAmountResult);

        GiftBatch giftBatch = new GiftBatch();
        giftBatch.giftBatchId = new GiftBatchId(DUMMY_DATA_IMPORT_BATCH_ID);
        giftBatch.totals = totals;
        giftBatch.gifts = gifts;

        GiftBatchDTO giftBatchDTO = new GiftBatchDTO(giftBatch);
        return new GiftBatchView(giftBatchDTO);
    }

    private static List<DataImport__c> DUMMY_DATA_IMPORTS_WITH_CONTACT_FIRST_NAME =
        new List<DataImport__c>{
            new DataImport__c(
                    Contact1_Firstname__c = 'Dummy First Name',
                    Donation_Amount__c = 100,
                    Donation_Date__c = Date.today()
            ),
            new DataImport__c(
                    Contact1_Firstname__c = 'Dummy First Name',
                    Donation_Amount__c = 200,
                    Donation_Date__c = Date.today()
            )
        };

    private static Id DUMMY_DATA_IMPORT_BATCH_ID = UTIL_UnitTestData_TEST.mockId(DataImportBatch__c.getSObjectType());
}
