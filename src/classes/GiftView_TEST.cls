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

        String donationAmountField = String.valueOf(DataImport__c.Donation_Amount__c);
        System.assertEquals(10, giftView.fields.get(donationAmountField));
    }

    @isTest
    static void shouldReturnGiftViewWith2SoftCredits() {
        DataImport__c dataImport = new DataImport__c(
            Donation_Amount__c = 10,
            Donation_Date__c = Date.today(),
            Additional_Object_JSON__c = UTIL_UnitTestData_TEST.DUMMY_ADDITIONAL_OBJECT_JSON_WITH_SOFT_CREDITS
        );
        Gift gift = new Gift(dataImport);
        GiftDTO giftDTO = new GiftDTO(gift);
        GiftView giftView = new GiftView(giftDTO);

        System.assertEquals(2, giftView.softCredits.all.size());
    }
}
