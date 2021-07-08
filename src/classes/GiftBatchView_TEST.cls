@isTest
private class GiftBatchView_TEST {
    
    @isTest
    static void shouldReturn200TotalAmount() {
        GiftBatchView giftBatchView = createDummyGiftBatchView();

        System.assertEquals(200, giftBatchView.total);
    }

    @isTest
    static void shouldReturn2TotalCount() {
        GiftBatchView giftBatchView = createDummyGiftBatchView();

        System.assertEquals(2, giftBatchView.totalCount);
    }

    static String DUMMY_DATA_IMPORT_MODEL = '{"totalRowAmount":200.0,"totalCountOfRows":2}';
    static GiftBatchView createDummyGiftBatchView() {
        GiftBatch giftBatch = new GiftBatch();
        giftBatch.typedModel = (BGE_DataImportBatchEntry_CTRL.DataImportModel)
            JSON.deserialize(DUMMY_DATA_IMPORT_MODEL,
                BGE_DataImportBatchEntry_CTRL.DataImportModel.class);
        GiftBatchDTO giftBatchDTO = new GiftBatchDTO(giftBatch);
        return new GiftBatchView(giftBatchDTO);
    }
}
