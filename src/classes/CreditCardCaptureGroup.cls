public with sharing class CreditCardCaptureGroup implements ElevateCaptureGroup{
    private String id;
    private String status;
    public static CreditCardCaptureGroup captureGroupInstance;

    public static void setInstance(CreditCardCaptureGroup instance) {
        captureGroupInstance = instance;
    }

    public static CreditCardCaptureGroup getInstance() {
        if (captureGroupInstance == null) {
            captureGroupInstance = new CreditCardCaptureGroup();
        }
        return captureGroupInstance;
    }

    public UTIL_Http.Response create() {
        UTIL_Http.Response response = new UTIL_Http.RequestService().sendRequest(createRequest());
        return response;
    }

    private HttpRequest createRequest() {
        return new PS_Request.Builder()
                .withMethod(UTIL_Http.Method.POST)
                .withEndpoint(PS_Request.ElevateEndpoint.CREATE_CAPTURE_GROUP)
                .withBody(createRequestBody())
                .build();
    }

    private String createRequestBody() {
        return JSON.serialize(new CreateRequestBody());
    }

    public void add(ElevateTokenizedGift creditCardGift) {

    }

    public String groupId() {
        return id;
    }

    public String status() {
        return status;
    }

    public with sharing class CreateRequestBody {
        private String merchantId;

        public CreateRequestBody() {
            this.merchantId = new PS_IntegrationServiceConfig.Service().getMerchantIds();
        }
    }


}