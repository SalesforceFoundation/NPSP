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
public class ElevateCaptureGroupMockHttpResponse implements HttpCalloutMock {

    public final String INVALID_GROUP_ID = 'invalid-group-id';
    public final String VALID_GROUP_ID = 'valid-group-id';
    public final String INVALID_BODY_PARAMETER = 'invalid-parameter';


    public HttpResponse respond(HttpRequest request) {
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');

        switch on getEndpointOperation(request) {
            when 'create' {
                if (hasInvalidRequestParameter(request)) {
                    response.setStatusCode(UTIL_Http.STATUS_CODE_BAD_REQUEST);
                    response.setBody(creatureCaptureGroupFailureBody());
                } else {
                    response.setStatusCode(UTIL_Http.STATUS_CODE_CREATED);
                    response.setBody(createCaptureGroupSuccessBody());
                }
            }
            when 'add' {
                if (request.getEndpoint().contains(INVALID_GROUP_ID)) {
                    response.setStatusCode(UTIL_Http.STATUS_CODE_NOT_FOUND);
                    response.setBody(addToCaptureGroupFailureBody());
                } else {
                    response.setStatusCode(UTIL_Http.STATUS_CODE_CREATED);
                    response.setBody(addToCaptureGroupSuccessBody());
                }
            }
        }
        return response;
    }

    private Boolean hasInvalidRequestParameter(HttpRequest request) {
        return request.getBody().contains(INVALID_BODY_PARAMETER);
    }

    private String getEndpointOperation(HttpRequest request) {
        return request.getEndpoint().substringAfterLast('/');
    }
    @TestVisible
    private String createCaptureGroupSuccessBody() {
        return '{\n' +
                '  "id": "newElevateCaptureGroupdId",\n' +
                '  "status": "Open"\n' +
                '}';
    }

    private String creatureCaptureGroupFailureBody() {
        return '{\n' +
                '  "errors": [\n' +
                '    {\n' +
                '      "message": "create failed",\n' +
                '      "localizedPaymentsMessage": "Bad Request",\n' +
                '      "detailedMessage": "create failed"\n' +
                '    }\n' +
                '  ]\n' +
                '}';
    }

    private String addToCaptureGroupSuccessBody() {
        DateTime DUMMY_TIME = System.today();
        return '{\n' +
                '  "body": {\n' +
                '    "id": "ElevateCaptureGroupId",\n' +
                '    "timestamp":' + DUMMY_TIME + ',\n' +
                '    "createdAt":' + DUMMY_TIME + ',\n' +
                '    "submittedAt":' + DUMMY_TIME + ',\n' +
                '    "authExpiresAt":' + DUMMY_TIME.addDays(1) + ',\n' +
                '    "status": "PENDING",\n' +
                '    "merchantId": "TestElevateMerchantId",\n' +
                '    "merchantName": "TestMerchant",\n' +
                '    "gatewayId": "TestElevateGatewayId",\n' +
                '    "currencyCode": "USD",\n' +
                '    "amount": 500,\n' +
                '    "lastName": "Bond",\n' +
                '    "firstName": "James",\n' +
                '    "type": "PAYMENT",\n' +
                '    "paymentType": "CARD",\n' +
                '    "cardData": {\n' +
                '      "last4": "1111",\n' +
                '      "brand": "VISA",\n' +
                '      "expirationYear": "2025",\n' +
                '      "expirationMonth": "05",\n' +
                '      "firstName": "James",\n' +
                '      "lastName": "Bond",\n' +
                '      "fingerprint": "nofingerprint"\n' +
                '    },\n' +
                '    "originalTransactionId": "TestElevateTransactionId",\n' +
                '    "batchId": "ElevateCaptureGroupId",\n' +
                '    "receiptTimezone": "America/Los_Angeles",\n' +
                '    "amountRefunded": 0,\n' +
                '    "achData": {},\n' +
                '    "version": 1\n' +
                '  },\n' +
                '  "statusCode": 201\n' +
                '}';
    }

    private String addToCaptureGroupFailureBody() {
        return '{\n' +
                '  "errors": [\n' +
                '    {\n' +
                '      "message": "Not Found",\n' +
                '      "localizedPaymentsMessage": "Not Found"\n' +
                '    }\n' +
                '  ]\n' +
                '}';
    }
}