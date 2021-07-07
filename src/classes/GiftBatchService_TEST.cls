@IsTest
private class GiftBatchService_TEST {

    @IsTest static void shouldReturnGiftBatch() {
        DataImportBatch__c batch = new DataImportBatch__c();
        insert batch;

        GiftBatchService service = new GiftBatchService();
        GiftBatch giftBatch = service.getGiftBatchBy(batch.Id);

        System.assertNotEquals(null, giftBatch);
    }

    @IsTest static void shouldReturnGiftBatchDTO() {
        GiftBatchMock giftBatchMock = new GiftBatchMock();
        GiftBatch giftBatch = stubFor(giftBatchMock);

        GiftBatchService service = new GiftBatchService();
        GiftBatchDTO giftBatchDTO = service.dtoFrom(giftBatch);

        System.assertNotEquals(null, giftBatchDTO);
    }

    @IsTest static void shouldReturnGiftBatchView() {
        GiftBatchMock giftBatchMock = new GiftBatchMock();
        GiftBatch giftBatch = stubFor(giftBatchMock);

        GiftBatchService service = new GiftBatchService();
        GiftBatchView view = service.viewFor(giftBatch);

        System.assertNotEquals(null, view);
    }

    private class GiftBatchMock implements StubProvider {
        public Object handleMethodCall(Object stubbedObject,
            String stubbedMethodName,
            Type returnType,
            List<Type> listOfParamTypes,
            List<String> listOfParamNames,
            List<Object> listOfArgs) {

            switch on (stubbedMethodName) {
                when 'hasElevateWidget' {
                    return true;
                }
            }

            return null;
        }
    }

    private static GiftBatch stubFor(GiftBatchMock giftBatchMock) {
        return (GiftBatch) Test.createStub(GiftBatch.class, giftBatchMock);
    }
}
