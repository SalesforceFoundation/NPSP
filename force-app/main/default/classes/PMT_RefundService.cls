/*
    Copyright (c) 2022, Salesforce.org
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Salesforce.org nor the names of
      its contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
    COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
    LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
    ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
    POSSIBILITY OF SUCH DAMAGE.
*/
/**
* @author Salesforce.org
* @date 2022
* @group Payment
* @description Payment Refund Service
*/
public with sharing class PMT_RefundService {
    private UTIL_Http.RequestService requestService {
        get {
            if (requestService == null) {
                requestService = new UTIL_Http.RequestService();
            }
            return requestService;
        }
        set;
    }

    /***
     * @description Contains configuration related to the Elevate integration service config and permissions
     */
    @TestVisible
    private static PS_IntegrationServiceConfig config {
        get {
            if (config == null) {
                config = new PS_IntegrationServiceConfig();
            }
            return config;
        }
        set;
    }

    public static Boolean isElevateEnabled() {
        return config.isIntegrationEnabled();
    }

    public UTIL_Http.Response processRefund(String transactionId) {
        HttpRequest request = buildRefundRequest(transactionId);

        UTIL_Http.Response response;
        try {
            response = requestService.sendRequest(request);
        } catch (Exception ex) {
            response = requestService.buildErrorResponse(ex);
        }

        processPaymentStatusCode(response);
        return response;
    }

    private HttpRequest buildRefundRequest(String transactionId) {
        RequestBody reqBody = new RequestBody(transactionId);

        return new PS_Request.Builder()
            .withMethod(UTIL_Http.Method.POST)
            .withEndpoint(PS_Request.ElevateEndpoint.REFUND)
            .withRecommendedTimeout()
            .withBody(JSON.serialize(reqBody))
            .build();
    }

    private void processPaymentStatusCode(UTIL_Http.Response response) {
        String paymentErrorMessage;
        if (response.statusCode == UTIL_Http.STATUS_CODE_NOT_FOUND) {
            paymentErrorMessage = System.Label.pmtPaymentNotFund;

        } else if (response.statusCode == UTIL_Http.STATUS_CODE_CONFLICT) {
            paymentErrorMessage = System.Label.pmtPaymentNotRefundable;

        }  else if (response.statusCode == UTIL_Http.STATUS_CODE_UNPROCESSABLE_ENTITY) {
            paymentErrorMessage =  System.Label.pmtOriginalPaymentNotCompleted;
        }
        
        if (String.isNotBlank(paymentErrorMessage)) {
            response.body = new UTIL_Http.ErrorResponseBody()
                .withError(paymentErrorMessage)
                .getAsJson();
        }
    }

    public class RequestBody {
        @TestVisible
        String transactionId;

        public RequestBody(String transactionId) {
            this.transactionId = transactionId;
        }
    }
}
