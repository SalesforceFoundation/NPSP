@IsTest
private class GiftBatchView_TEST {

    @IsTest
    static void sample_gift_batch_view() {
        Gifts gifts = dummyGifts();
        GiftBatch giftBatch = new GiftBatch(gifts);
        GiftBatchView giftBatchView =
                new GiftBatchView(new GiftBatchDTO(giftBatch));
        System.debug(LoggingLevel.ERROR, '*** variable value: ' +
                JSON.serializePretty(giftBatchView));
        System.debug(LoggingLevel.ERROR, '^^^^^^ giftBatchView ^^^^^^');
    }

    private static Gifts dummyGifts() {
        return new Gifts(
                new List<DataImport__c>{
                        new DataImport__c(
                                Donation_Amount__c = 100,
                                Donation_Date__c = Date.today()
                        ),
                        new DataImport__c(
                                Donation_Amount__c = 100,
                                Donation_Date__c = Date.today()
                        )
                }
        );
    }
}