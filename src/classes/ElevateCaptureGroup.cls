public virtual with sharing class ElevateCaptureGroup implements CaptureGroup {
    private String id;
    private String status;

    public UTIL_Http.Response create() {
        UTIL_Http.Response response = new UTIL_Http.RequestService().sendRequest(createRequest());
        return response;
    }

    protected virtual HttpRequest createRequest() {
        return new PS_Request.Builder()
                .withMethod(UTIL_Http.Method.POST)
                .withEndpoint(PS_Request.ElevateEndpoint.CREATE_CAPTURE_GROUP)
                .withBody(createRequestBody())
                .build();
    }

    protected virtual HttpRequest addRequest(ElevateTokenizedGift tokenizedGift, String groupId) {
        return new PS_Request.Builder()
                .withMethod(UTIL_Http.Method.POST)
                .withCaptureGroupId(groupId)
                .withEndpoint(PS_Request.ElevateEndpoint.ADD_TO_CAPTURE_GROUP)
                .withBody(JSON.serialize(tokenizedGift))
                .build();
    }

    private String createRequestBody() {
        return JSON.serialize(new CreateRequestBody());
    }

    public virtual UTIL_Http.Response add(ElevateTokenizedGift tokenizedGift, String groupId) {
        UTIL_Http.Response response = new UTIL_Http.RequestService().sendRequest(addRequest(tokenizedGift, groupId));
        return response;
    }

    public virtual String groupId() {
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