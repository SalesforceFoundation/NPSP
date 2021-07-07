@IsTest
private class GiftBatchService_TEST {
    @IsTest
    static void shouldReturnGiftBatchDTO() {
        GiftBatchMock giftBatchMock = new GiftBatchMock();
        GiftBatch giftBatch = stubFor(giftBatchMock);

        GiftBatchService service = new GiftBatchService();
        GiftBatchDTO giftBatchDTO = service.dtoFrom(giftBatch);

        System.assertNotEquals(null, giftBatchDTO);
    }

    public class GiftBatchMock implements StubProvider {
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
