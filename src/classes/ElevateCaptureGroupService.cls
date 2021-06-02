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
public virtual with sharing class ElevateCaptureGroupService {

    public virtual ElevateAuthorizedGift addToCaptureGroup(ElevateTokenizedGift tokenizedGift, String groupId) {
        return new ElevateCaptureGroup(groupId).add(tokenizedGift);
    }

    public virtual ElevateCaptureGroup createCaptureGroup() {
        return new ElevateCaptureGroup().create();
    }

    public ElevateAuthorizedGift sendAddRequest(ElevateTokenizedGift tokenizedGift, String groupId) {
        UTIL_Http.Response response = new UTIL_Http.RequestService().sendRequest(
                addRequest(tokenizedGift, groupId)
        );
        ElevateAuthorizedGiftResponse authorizedGiftResponse = (ElevateAuthorizedGiftResponse)JSON.deserialize
                (response.body, ElevateAuthorizedGiftResponse.class);
        checkForAuthorizedGiftErrorsIn(authorizedGiftResponse);

        return new ElevateAuthorizedGift(tokenizedGift, authorizedGiftResponse);
    }

    public ElevateCaptureGroup getCaptureGroup() {
        UTIL_Http.Response response = new UTIL_Http.RequestService().sendRequest(
                createRequest()
        );
        ElevateCaptureGroupResponse captureGroupResponse = (ElevateCaptureGroupResponse)JSON.deserialize(
                response.body, ElevateCaptureGroupResponse.class);
        return new ElevateCaptureGroup(captureGroupResponse);
    }

    private HttpRequest addRequest(ElevateTokenizedGift tokenizedGift, String groupId) {
        return new PS_Request.Builder()
                .withMethod(UTIL_Http.Method.POST)
                .withCaptureGroupId(groupId)
                .withEndpoint(PS_Request.ElevateEndpoint.ADD_TO_CAPTURE_GROUP)
                .withBody(JSON.serialize(tokenizedGift))
                .build();
    }

    public List<ElevateCaptureGroupResponse> capture(Set<String> captureGroupIds) {
        List<ElevateCaptureGroupResponse> elevateCaptureGroupResponses = new List<ElevateCaptureGroupResponse>();
        for (String elevateBatchId : captureGroupIds) {
            UTIL_Http.Response response = new UTIL_Http.RequestService().sendRequest(
                    captureRequest(elevateBatchId)
            );
            ElevateCaptureGroupResponse captureGroupResponse = (ElevateCaptureGroupResponse)JSON.deserialize(
                    response.body, ElevateCaptureGroupResponse.class);
            elevateCaptureGroupResponses.add(captureGroupResponse);
        }
        return elevateCaptureGroupResponses;
    }

    @TestVisible
    private void checkForAuthorizedGiftErrorsIn(ElevateAuthorizedGiftResponse authorizedGiftResponse) {
        if (hasAuthorizedGiftErrors(authorizedGiftResponse)) {
            UTIL_AuraEnabledCommon.throwAuraHandledException(authorizedGiftResponse.errors()[0].message);
        }
    }

    private Boolean hasAuthorizedGiftErrors(ElevateAuthorizedGiftResponse authorizedGiftResponse) {
        return authorizedGiftResponse.errors() != null &&
               !authorizedGiftResponse.errors().isEmpty();
    }

    @TestVisible
    private void checkForCaptureGroupErrorsIn(ElevateCaptureGroupResponse captureGroupResponse) {
        if (hasCaptureGroupErrors(captureGroupResponse)) {
            UTIL_AuraEnabledCommon.throwAuraHandledException(captureGroupResponse.errors()[0].message);
        }
    }

    private Boolean hasCaptureGroupErrors(ElevateCaptureGroupResponse captureGroupResponse) {
        return captureGroupResponse.errors() != null &&
               !captureGroupResponse.errors().isEmpty();
    }

    private HttpRequest createRequest() {
        return new PS_Request.Builder()
                .withMethod(UTIL_Http.Method.POST)
                .withEndpoint(PS_Request.ElevateEndpoint.CREATE_CAPTURE_GROUP)
                .withBody(createRequestBody())
                .build();
    }

    private HttpRequest captureRequest(String groupId) {
        return new PS_Request.Builder()
                .withMethod(UTIL_Http.Method.POST)
                .withCaptureGroupId(groupId)
                .withEndpoint(PS_Request.ElevateEndpoint.CHARGE_CAPTURE_GROUP)
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