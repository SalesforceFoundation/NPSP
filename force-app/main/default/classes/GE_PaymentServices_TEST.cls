/*
    Copyright (c) 2019 Salesforce.org
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
* @date 2020
* @group HGE
* @group-content ../../ApexDocContent/BatchDataImport.htm
* @description Unit Test for GE_PaymentServices
*/

@isTest
public class GE_PaymentServices_TEST {

    public static final String SUCCESS_RESPONSE_BODY = '{"id":"TEST_ID","status":"CAPTURED","merchantId":"TEST_MERCHANT_ID","merchantName":"Test Merchant","gatewayId":"TEST_GATEWAY_ID","gatewayTransactionId":"TEST_TRANSACTION_ID","currencyCode":"USD","amount":2500,"lastName":"Doe","firstName":"John","email":"john.doe@example.com","metadata":{"campaignCode":"test-campaign-code"},"type":"PAYMENT","paymentType":"CARD","cardData":{"last4":"1111","brand":"visa","expirationYear":"9999","expirationMonth":"12","firstName":"john","lastName":"doe","fingerprint":"TEST_FINGERPRINT"},"authorizedAt":"2020-03-10T20:17:24.897054Z"}';
    public static final String FAILED_RESPONSE_MESSAGE = 'Unprocessable Entity';
    public static final String FAILED_RESPONSE_BODY = '{"errors":[{"message":"' + FAILED_RESPONSE_MESSAGE + '"}]}';

    private static final String GOOD_TOKEN = 'good-token';
    private static final String BAD_TOKEN = 'bad-token';
    private static final String BASE_PURCHASE_CALL_BODY = '{"amount":2500,"email":"test@test.test","firstName":"Test First Name","lastName":"Test Last Name","metadata":{},';

    public static final String GOOD_PURCHASE_CALL_BODY = BASE_PURCHASE_CALL_BODY + '"paymentMethodToken":"' + GOOD_TOKEN + '"}';
    public static final String BAD_PURCHASE_CALL_BODY = BASE_PURCHASE_CALL_BODY + '"paymentMethodToken":"' + BAD_TOKEN + '"}';  


    @isTest static void shouldReturnSuccessfulResponse() {
        PS_IntegrationService.setConfiguration(PS_IntegrationServiceConfig_TEST.testConfig);

        // Set mock callout class
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        GE_PaymentServices paymentServices = new GE_PaymentServices();
        UTIL_Http.Response response = paymentServices.createTransaction(GOOD_PURCHASE_CALL_BODY);
        Test.stopTest();

        String actualValue = response.body;
        String expectedValue = SUCCESS_RESPONSE_BODY;
        System.assertEquals(UTIL_Http.STATUS_CODE_CREATED, response.statusCode);
        System.assertEquals(actualValue, expectedValue);
    }

    @isTest static void shouldReturnPaymentTransactionStatusValues() {
        Set<String> paymentStatusValues = new Set<String>();

        Map<String, Object> paymentStatusEnumByName =
            ( Map<String, Object> ) JSON.deserializeUntyped(
                GE_PaymentServices.getPaymentTransactionStatusValues()
            );

        for (String enumName : paymentStatusEnumByName.keySet()) {
            paymentStatusValues.add(enumName);
        }

        for (ElevateTransactionStatus value :
                ElevateTransactionStatus.values()) {
                    System.assert(paymentStatusValues.contains(value.name()), 'Every payment transaction status value' +
                        'should be included in the enum returned by the method.');
        }

        System.assert(!paymentStatusValues.isEmpty(), 'List of payment transaction status values should not be empty.');
    }

    @isTest static void shouldReturnFailedResponse() {
        PS_IntegrationService.setConfiguration(PS_IntegrationServiceConfig_TEST.testConfig);

        // Set mock callout class
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        GE_PaymentServices paymentServices = new GE_PaymentServices();
        UTIL_Http.Response response = paymentServices.createTransaction(BAD_PURCHASE_CALL_BODY);
        Test.stopTest();

        String actualValue = response.body;
        String expectedValue = FAILED_RESPONSE_BODY;
        System.assertEquals(UTIL_Http.STATUS_CODE_FORBIDDEN, response.statusCode);
        System.assertEquals(actualValue, expectedValue);
    }

    @IsTest
    private static void shouldRequireConfigurationKeysToBeAnElevateCustomer() {
        List<Payment_Services_Configuration__c> requiredConfigs = new
                List<Payment_Services_Configuration__c>();

        for (Integer i = 0; i < PS_IntegrationServiceConfig.REQUIRED_CONFIG_KEYS.size(); i++) {
            requiredConfigs.add(new Payment_Services_Configuration__c(
                Service__c = PS_IntegrationServiceConfig.PAYMENTS_SERVICE_NAME,
                Key__c = PS_IntegrationServiceConfig.REQUIRED_CONFIG_KEYS.get(i),
                Value__c = String.valueOf(i)
            ));
        }
        insert requiredConfigs;
        GE_PaymentServices paymentServices = new GE_PaymentServices();
        System.assertEquals(true, paymentServices.isElevateCustomer(),
            'The org should be considered an Elevate customer when '
            + 'all required configuration keys are present.');
    }

    @IsTest
    private static void shouldNotBeAnElevateCustomer() {
        GE_PaymentServices paymentServices = new GE_PaymentServices();
        System.assertEquals(false, paymentServices.isElevateCustomer(),
            'The org should not be considered an Elevate customer without '
            + 'all required configuration keys present.');
    }


    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');

            if (req.getBody().contains(GOOD_TOKEN)) {
                res.setBody(SUCCESS_RESPONSE_BODY);
                res.setStatusCode(UTIL_Http.STATUS_CODE_CREATED);

            } else if (req.getBody().contains(BAD_TOKEN)) {
                res.setBody(FAILED_RESPONSE_BODY);
                res.setStatusCode(UTIL_Http.STATUS_CODE_FORBIDDEN);
            }

            return res;
        }
    }

}
