@isTest
private class GiftView_TEST {

    @isTest
    static void shouldReturnGiftViewWithDataImport() {
        DataImport__c dataImport = new DataImport__c(
            Donation_Amount__c = 10,
            Donation_Date__c = Date.today()
        );
        Gift gift = new Gift(dataImport);
        GiftDTO giftDTO = new GiftDTO(gift);
        GiftView giftView = new GiftView(giftDTO);

        System.assertEquals(dataImport, giftView.dataImport);
    }
}
