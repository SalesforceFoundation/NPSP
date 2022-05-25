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
* @description Test class for PMT_RefundService
*/
@IsTest
public with sharing class PMT_RefundService_TEST {
    @isTest
    private static void verifyRefundEndpointCanBeCalloutSuccessfully() {
        PS_IntegrationServiceConfig_TEST.enableElevateIntegrationService();
        UTIL_Http_TEST.CalloutMock calloutMock = UTIL_Http_TEST.mockSuccessCalloutResponse(null);
        PMT_RefundService refundService = new PMT_RefundService();
        Test.startTest();
        UTIL_Http.Response response = refundService.processRefund('random-id');
        Test.stopTest();

        System.assertEquals(1, calloutMock.getCalloutCounter(),
            '1 callout should be made when the refund callout is made');
        System.assertEquals(UTIL_Http.STATUS_CODE_OK, response.statusCode,
            'The status code should return OK when the callout is successful');
    }

    @isTest
    private static void verifyReturnNotFoundErrorWhenStatusCodeIs404() {
        PS_IntegrationServiceConfig_TEST.enableElevateIntegrationService();
        UTIL_Http_TEST.CalloutMock calloutMock = UTIL_Http_TEST.mockNotFoundCalloutResponse();
        PMT_RefundService refundService = new PMT_RefundService();
        Test.startTest();
        UTIL_Http.Response response = refundService.processRefund('random-id');
        Test.stopTest();

        System.assertEquals(1, calloutMock.getCalloutCounter(),
            '1 callout should be made when the refund callout is made');
        System.assertEquals(UTIL_Http.STATUS_CODE_NOT_FOUND, response.statusCode,
            'The status code should return 404 not found when the Elevate record cannot be found');
        System.assertEquals(System.Label.pmtPaymentNotFund, response.getErrorMessages(),
            'The response body should be convert to original payment not found error message');
    }

    @isTest
    private static void verifyReturnNotRefundableErrorWhenStatusCodeIs409() {
        PS_IntegrationServiceConfig_TEST.enableElevateIntegrationService();
        UTIL_Http_TEST.CalloutMock calloutMock = UTIL_Http_TEST.mockDataConflictCalloutResponse();
        PMT_RefundService refundService = new PMT_RefundService();
        Test.startTest();
        UTIL_Http.Response response = refundService.processRefund('random-id');
        Test.stopTest();

        System.assertEquals(1, calloutMock.getCalloutCounter(),
            '1 callout should be made when the refund callout is made');
        System.assertEquals(UTIL_Http.STATUS_CODE_CONFLICT, response.statusCode,
            'The status code should return 409 conflic when the payment is not refundable');
        System.assertEquals(System.Label.pmtPaymentNotRefundable, response.getErrorMessages(),
            'The response body should be convert to not refundable error message');
    }

    @isTest
    private static void verifyReturnPaymentNotCompleteErrorWhenStatusCodeIs422() {
        PS_IntegrationServiceConfig_TEST.enableElevateIntegrationService();
        UTIL_Http_TEST.CalloutMock calloutMock = UTIL_Http_TEST.mockDataUnprocessableResponse();
        PMT_RefundService refundService = new PMT_RefundService();
        Test.startTest();
        UTIL_Http.Response response = refundService.processRefund('random-id');
        Test.stopTest();

        System.assertEquals(1, calloutMock.getCalloutCounter(),
            '1 callout should be made when the refund callout is made');
        System.assertEquals(UTIL_Http.STATUS_CODE_UNPROCESSABLE_ENTITY, response.statusCode,
            'The status code should return 422 unprocessable when the transaction is not completed');
        System.assertEquals(System.Label.pmtOriginalPaymentNotCompleted, response.getErrorMessages(),
            'The response body should be convert to original transaction is not completed error message');
    }
}
