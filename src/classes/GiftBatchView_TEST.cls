@isTest
private class GiftBatchView_TEST {

    @isTest
    static void shouldReturn200TotalAmount() {
        GiftBatchView giftBatchView = createDummyGiftBatchViewFromLegacyDataImportModel();

        System.assertEquals(200, giftBatchView.total);
    }

    @isTest
    static void shouldReturn2TotalCount() {
        GiftBatchView giftBatchView = createDummyGiftBatchViewFromLegacyDataImportModel();

        System.assertEquals(2, giftBatchView.totalCount);
    }

    @isTest
    static void shouldHave2GiftViews() {
        Gifts gifts = new Gifts(DUMMY_DATA_IMPORTS_WITH_CONTACT_FIRST_NAME);
        GiftBatch giftBatch = new GiftBatch();
        giftBatch.giftBatchId = new GiftBatchId(DUMMY_DATA_IMPORT_BATCH_ID);
        giftBatch.gifts = gifts;
        giftBatch.typedModel = (BGE_DataImportBatchEntry_CTRL.DataImportModel)
            JSON.deserialize(DUMMY_DATA_IMPORT_MODEL,
                BGE_DataImportBatchEntry_CTRL.DataImportModel.class);

        GiftBatchDTO giftBatchDTO = new GiftBatchDTO(giftBatch);
        GiftBatchView giftBatchView = new GiftBatchView(giftBatchDTO);

        System.assertEquals(2, giftBatchView.gifts.size());
    }

    @isTest
    static void shouldHave0GiftViews() {
        GiftBatch giftBatch = new GiftBatch();
        giftBatch.giftBatchId = new GiftBatchId(DUMMY_DATA_IMPORT_BATCH_ID);
        giftBatch.typedModel = (BGE_DataImportBatchEntry_CTRL.DataImportModel)
            JSON.deserialize('{"totalRowAmount":0,"totalCountOfRows":0}',
                BGE_DataImportBatchEntry_CTRL.DataImportModel.class);
        GiftBatchDTO giftBatchDTO = new GiftBatchDTO(giftBatch);
        GiftBatchView giftBatchView = new GiftBatchView(giftBatchDTO);

        System.assertEquals(0, giftBatchView.gifts.size());
    }

    // TODO: remove after GiftBatch is decoupled from legacy data import model
    private static String DUMMY_DATA_IMPORT_MODEL = '{"totalRowAmount":200.0,"totalCountOfRows":2}';
    private static GiftBatchView createDummyGiftBatchViewFromLegacyDataImportModel() {
        GiftBatch giftBatch = new GiftBatch();
        giftBatch.giftBatchId = new GiftBatchId(DUMMY_DATA_IMPORT_BATCH_ID);
        giftBatch.typedModel = (BGE_DataImportBatchEntry_CTRL.DataImportModel)
            JSON.deserialize(DUMMY_DATA_IMPORT_MODEL,
                BGE_DataImportBatchEntry_CTRL.DataImportModel.class);
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
