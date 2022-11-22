/*
 * Copyright (c) 2020, Salesforce.org
 *     All rights reserved.
 *
 *     Redistribution and use in source and binary forms, with or without
 *     modification, are permitted provided that the following conditions are met:
 *
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of Salesforce.org nor the names of
 *       its contributors may be used to endorse or promote products derived
 *       from this software without specific prior written permission.
 *
 *     THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *     "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *     LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 *     FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 *     COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 *     INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 *     BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 *     LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 *     CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 *     LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
 *     ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 *     POSSIBILITY OF SUCH DAMAGE.
 */
public virtual with sharing class ElevateBatchService {

    @TestVisible
    private ElevateBatch elevateBatch {
        get {
            if (elevateBatch == null) {
                elevateBatch = new ElevateBatch();
            }
            return elevateBatch;
        }
        set;
    }

    public virtual ElevateBatchItem addToElevateBatch(ElevateCreateBatchItemRequestDTO batchItemRequestDTO, String
            elevateBatchId) {
        return new ElevateBatch(elevateBatchId).add(batchItemRequestDTO);
    }

    public ElevateCreateBatchItemRequest buildBatchItemRequestFrom(ElevateCreateBatchItemRequestDTO
            batchItemRequestDTO) {
        return new ElevateCreateBatchItemRequest(batchItemRequestDTO);
    }

    public virtual ElevateBatchItem removeFromElevateBatch(ElevateBatchItem batchItem) {
        return new ElevateBatch(batchItem.elevateBatchId).remove(batchItem.id());
    }

    // Method is used for dependency injection in test classes
    @TestVisible
    private virtual ElevateBatchItem removeFromElevateBatch(ElevateBatch elevateBatch, ElevateBatchItem batchItem) {
        return elevateBatch.remove(batchItem.id());
    }

    public virtual ElevateBatch createElevateBatch() {
        return new ElevateBatch().create();
    }


    public ElevateBatchItem sendAddRequest(ElevateCreateBatchItemRequest tokenizedGift, String elevateBatchId) {
        UTIL_Http.Response response = new UTIL_Http.RequestService().sendRequest(
                addRequest(tokenizedGift, elevateBatchId)
        );
        ElevateBatchItemCreateResponse batchItemCreateResponse = ElevateBatchItemCreateResponse.parse(response.body);
        checkForBatchItemErrorsIn(batchItemCreateResponse);

        return new ElevateBatchItem(batchItemCreateResponse);
    }

    public virtual UTIL_Http.Response sendRemoveRequest(String elevatePaymentId, String elevateBatchId) {
        return new UTIL_Http.RequestService().sendRequest(
                removeRequest(elevateBatchId, elevatePaymentId));
    }

    public virtual void handleRemoveResponse(UTIL_Http.Response response) {
        if (response.statusCode != 204) {
            UTIL_AuraEnabledCommon.throwAuraHandledException(response.status);
        }
    }

    public ElevateBatch getElevateBatch() {
        UTIL_Http.Response response = new UTIL_Http.RequestService().sendRequest(
                createRequest()
        );
        ElevateBatchResponse elevateBatchResponse = (ElevateBatchResponse)JSON.deserialize(
                response.body, ElevateBatchResponse.class);
        checkForElevateBatchErrorsIn(elevateBatchResponse);

        return new ElevateBatch(elevateBatchResponse);
    }

    private HttpRequest addRequest(ElevateCreateBatchItemRequest tokenizedGift, String elevateBatchId) {
        return new PS_Request.Builder()
                .withMethod(UTIL_Http.Method.POST)
                .withElevateBatchId(elevateBatchId)
                .withRecommendedTimeout()
                .withEndpoint(PS_Request.ElevateEndpoint.ADD_TO_ELEVATE_BATCH)
                .withBody(JSON.serialize(tokenizedGift))
                .build();
    }

    private HttpRequest removeRequest(String elevateBatchId, String elevatePaymentId) {
        return new PS_Request.Builder()
                .withMethod(UTIL_Http.Method.DEL)
                .withElevateBatchId(elevateBatchId)
                .withElevatePaymentId(elevatePaymentId)
                .withRecommendedTimeout()
                .withEndpoint(PS_Request.ElevateEndpoint.REMOVE_FROM_ELEVATE_BATCH)
                .build();
    }

    public void enqueuePaymentCaptureJobFor(Id batchId, Set<String> elevateBatchIds) {
        if (elevateBatchIds.isEmpty()) {
            return;
        }
        ElevateBatchCapturer capturer =
            new ElevateBatchCapturer(batchId, elevateBatchIds);
        System.enqueueJob(capturer);
    }

    public ElevateBatchResponse capture(String elevateBatchId) {
        HttpRequest captureRequest = captureRequest(elevateBatchId);
        UTIL_Http.Response response =
            new UTIL_Http.RequestService().sendRequest(captureRequest);

        ElevateBatchResponse captureResponse = (ElevateBatchResponse)
            JSON.deserialize(response.body, ElevateBatchResponse.class);
        return captureResponse;
    }

    @TestVisible
    private void checkForBatchItemErrorsIn(ElevateBatchItemCreateResponse batchItemCreateResponse) {
        if (hasBatchItemErrors(batchItemCreateResponse)) {
            UTIL_AuraEnabledCommon.throwAuraHandledException(batchItemCreateResponse.errors()[0].message);
        }
    }

    private Boolean hasBatchItemErrors(ElevateBatchItemCreateResponse authorizedGiftResponse) {
        return authorizedGiftResponse.errors() != null &&
               !authorizedGiftResponse.errors().isEmpty();
    }

    @TestVisible
    private void checkForElevateBatchErrorsIn(ElevateBatchResponse ElevateBatchResponse) {
        if (hasBatchErrors(ElevateBatchResponse)) {
            UTIL_AuraEnabledCommon.throwAuraHandledException(ElevateBatchResponse.errors()[0].message);
        }
    }

    private Boolean hasBatchErrors(ElevateBatchResponse ElevateBatchResponse) {
        return ElevateBatchResponse.errors() != null &&
               !ElevateBatchResponse.errors().isEmpty();
    }

    private HttpRequest createRequest() {
        return new PS_Request.Builder()
                .withMethod(UTIL_Http.Method.POST)
                .withEndpoint(PS_Request.ElevateEndpoint.CREATE_ELEVATE_BATCH)
                .withRecommendedTimeout()
                .withBody(createRequestBody())
                .build();
    }

    private HttpRequest captureRequest(String elevateBatchId) {
        return new PS_Request.Builder()
                .withMethod(UTIL_Http.Method.POST)
                .withElevateBatchId(elevateBatchId)
                .withRecommendedTimeout()
                .withEndpoint(PS_Request.ElevateEndpoint.CHARGE_ELEVATE_BATCH)
                .build();
    }

    private String createRequestBody() {
        return JSON.serialize(new CreateRequestBody());
    }

    public with sharing class CreateRequestBody {
        private String merchantId;

        public CreateRequestBody() {
            this.merchantId = new PS_IntegrationServiceConfig.Service().getMerchantIds();
        }
    }

}