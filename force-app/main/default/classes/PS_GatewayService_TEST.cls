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
* @group Payment Services
* @description Contains unit tests for retrieval of Elevate gateways
*/
@IsTest
public with sharing class PS_GatewayService_TEST {

    @IsTest
    private static void shouldReturnTimeoutError() {
        final String TIMEOUT_MESSAGE = 'Read timed out';

        PS_IntegrationServiceConfig_TEST.enableElevateIntegrationService();

        UTIL_Http_TEST.CalloutMock calloutMock = getGatewaysByMerchantErrorMock(TIMEOUT_MESSAGE);

        Test.startTest();
        try {
            PS_GatewayService gatewayService = new PS_GatewayService();
            String jsonString = gatewayService.getGatewaysByMerchant();
            System.assert(false, 'Should throw an Exception');
        } catch (Exception e) {
            String error = e.getMessage();
            System.assert(error.contains(TIMEOUT_MESSAGE), 'Response should include ' + TIMEOUT_MESSAGE);
        }
        Test.stopTest();

    }

    @IsTest
    private static void shouldReturnEmptyGatewayArray() {
        PS_IntegrationServiceConfig_TEST.enableElevateIntegrationService();

        UTIL_Http_TEST.CalloutMock calloutMock = getEmptyGatewaysByMerchantSuccessMock();

        Test.startTest();
        PS_GatewayService gatewayService = new PS_GatewayService();
        String jsonString = gatewayService.getGatewaysByMerchant();
        Test.stopTest();

        List<PS_GatewayService.GatewayTemplateSetting> templateSettings =
                (List<PS_GatewayService.GatewayTemplateSetting>)
                        JSON.deserialize(jsonString, List<PS_GatewayService.GatewayTemplateSetting>.class);

        System.assertNotEquals(null, templateSettings, 'templateSettings should not be null');
        System.assertEquals(0, templateSettings.size(), 'templateSettings should be empty');
    }

    @IsTest
    private static void shouldReturnValidTemplateSettings() {
        final String GATEWAY_ID = 'a206b228-27c8-4fed-8699-6b0525902b94';
        final String GATEWAY_ALIAS = 'Gateway Alias';
        final String VENDOR_NAME = 'Test Vendor Name';
        final String ENABLED_PAYMENT_METHODS = '';

        PS_IntegrationServiceConfig_TEST.enableElevateIntegrationService();

        UTIL_Http_TEST.CalloutMock calloutMock = getPopulatedGatewaysByMerchantSuccessMock(
                GATEWAY_ID, GATEWAY_ALIAS, VENDOR_NAME, ENABLED_PAYMENT_METHODS);

        Test.startTest();
        PS_GatewayService gatewayService = new PS_GatewayService();
        String jsonString = gatewayService.getGatewaysByMerchant();
        Test.stopTest();

        List<PS_GatewayService.GatewayTemplateSetting> templateSettings =
                (List<PS_GatewayService.GatewayTemplateSetting>)
                        JSON.deserialize(jsonString, List<PS_GatewayService.GatewayTemplateSetting>.class);

        System.assertNotEquals(null, templateSettings, 'templateSettings should not be null');
        System.assertEquals(2, templateSettings.size(), 'templateSettings should contain two gateways');
        System.assertEquals(GATEWAY_ALIAS, templateSettings[0].gatewayName,
                'Gateway Name Should be "' + GATEWAY_ALIAS + '"');
        System.assertEquals(true, templateSettings[0].isACHEnabled,
                'ACH should be enabled');
        System.assertEquals(true, templateSettings[0].isCreditCardEnabled,
                'Credit Card should be enabled');
        System.assertEquals(VENDOR_NAME, templateSettings[1].gatewayName,
                'Gateway Name Should be "' + VENDOR_NAME + '"');
        System.assertEquals(false, templateSettings[1].isACHEnabled,
                'ACH should not be enabled');
        System.assertEquals(true, templateSettings[1].isCreditCardEnabled,
                'Credit Card should be enabled');
    }

    public static UTIL_Http_TEST.CalloutMock getGatewaysByMerchantErrorMock(String errorMessage) {
        String errorResponseBody = new UTIL_Http.ErrorResponseBody()
                .withError(errorMessage)
                .getAsJson();

        UTIL_Http_TEST.CalloutMock calloutMock = UTIL_Http_TEST.mockErrorCalloutResponse(
                UTIL_Http.STATUS_CODE_REQUEST_TIMEOUT,
                UTIL_Http.STATUS_TIMED_OUT,
                errorResponseBody
        );

        return calloutMock;
    }

    public static UTIL_Http_TEST.CalloutMock getEmptyGatewaysByMerchantSuccessMock() {
        UTIL_Http_TEST.CalloutMock calloutMock = UTIL_Http_TEST.mockSuccessCalloutResponse(
                '{\n' +
                        '  "gateways": [\n' +
                        '  ]\n' +
                        '}'
        );

        return calloutMock;
    }

    public static UTIL_Http_TEST.CalloutMock getPopulatedGatewaysByMerchantSuccessMock(
            String gatewayId,
            String gatewayAlias,
            String vendorName,
            String enabledPaymentMethods
    ) {
        UTIL_Http_TEST.CalloutMock calloutMock = UTIL_Http_TEST.mockSuccessCalloutResponse(
                '{\n' +
                        '  "gateways": [\n' +
                        '    {\n' +
                        '      "id": "' + gatewayId + '",\n' +
                        '      "merchantId": "fcdaee39-d8e9-4197-80da-0b2d4182d7c4",\n' +
                        '      "createdAt": "2022-07-27T02:31:43.144Z",\n' +
                        '      "type": "STRIPE_CONNECT",\n' +
                        '      "alias": "' + gatewayAlias + '",\n' +
                        '      "settings": {\n' +
                        enabledPaymentMethods + '\n' +
                        '      },\n' +
                        '      "vendorName": "Stripe Connect",\n' +
                        '      "vendorType": "STRIPE_CONNECT",\n' +
                        '      "version": 1,\n' +
                        '      "tenantId": "99"\n' +
                        '    },\n' +
                        '    {\n' +
                        '      "id": "8970570c-b731-466f-9282-8ee749e40ad0",\n' +
                        '      "merchantId": "fcdaee39-d8e9-4197-80da-0b2d4182d7c4",\n' +
                        '      "createdAt": "2022-07-27T02:30:03.399Z",\n' +
                        '      "type": "STRIPE_CONNECT_TEST",\n' +
                        '      "settings": {\n' +
                        '        "enabledPaymentMethods": [\n' +
                        '          "CARD"\n' +
                        '        ]\n' +
                        '      },\n' +
                        '      "vendorName": "' + vendorName + '",\n' +
                        '      "vendorType": "test",\n' +
                        '      "version": 1,\n' +
                        '      "tenantId": "99"\n' +
                        '    }\n' +
                        '  ]\n' +
                        '}'
        );

        return calloutMock;
    }
}