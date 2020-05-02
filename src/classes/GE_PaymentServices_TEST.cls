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

    public static final String SUCCESS_RESPONSE_BODY = '{"id":"TEST_ID","status":"CAPTURED","merchantId":"TEST_MERCHANT_ID","merchantName":"Test Merchant","gatewayId":"TEST_GATEWAY_ID","gatewayTransactionId":"TEST_TRANSACTION_ID","currencyCode":"USD","amount":25,"lastName":"Doe","firstName":"John","email":"john.doe@example.com","metadata":{"campaignCode":"test-campaign-code"},"type":"PAYMENT","paymentType":"CARD","cardData":{"last4":"1111","brand":"visa","expirationYear":"9999","expirationMonth":"12","firstName":"john","lastName":"doe","fingerprint":"TEST_FINGERPRINT"},"authorizedAt":"2020-03-10T20:17:24.897054Z"}';
    public static final String FAILED_RESPONSE_BODY = '{"message":"Unprocessable Entity"}';
    public static final String GOOD_TOKEN = 'good-token';
    public static final String BAD_TOKEN = 'bad-token';
    public static final String BASE_PURCHASE_CALL_BODY = '{"amount":5,"email":"test@test.test","firstName":"Test First Name","lastName":"Test Last Name","metadata":{},';
    public static final String GOOD_PURCHASE_CALL_BODY = BASE_PURCHASE_CALL_BODY + '"paymentMethodToken":"' + GOOD_TOKEN + '"}';
    public static final String BAD_PURCHASE_CALL_BODY = BASE_PURCHASE_CALL_BODY + '"paymentMethodToken":"' + BAD_TOKEN + '"}';

    private static String testMerchantId = 'abc123-xyz456';
    private static String testApiKey = 'def1234-tuv4567';
    private static String testMakanaApiKey = 'ghi12345-qrs45678';

    // Key-Values by service name
    private static final Map<String, List<Map<String, String>>> testConfig =
            new Map<String, List<Map<String, String>>>{
                    GE_PaymentServices.PAYMENTS_SERVICE_NAME =>
                            new List<Map<String, String>>{
                                    new Map<String, String>{
                                            'key' => GE_PaymentServices.SFDO_MERCHANTIDS,
                                            'value' => testMerchantId
                                    },
                                    new Map<String, String>{
                                            'key' => 'sfdo.roles',
                                            'value' => 'Payments.Purchase'
                                    },
                                    new Map<String, String>{
                                            'key' => GE_PaymentServices.API_KEY,
                                            'value' => testApiKey
                                    }
                            }
            };

    @isTest static void shouldReturnSuccessfulResponse() {
        PS_IntegrationService.setConfiguration(testConfig);

        // Set mock callout class
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        DataImport__c dataImport = new DataImport__c();
        dataImport.Donation_Amount__c = 150;
        dataImport.Payment_Authorization_Token__c = GOOD_TOKEN;

        Test.startTest();
        GE_PaymentServices paymentServices = new GE_PaymentServices();
        paymentServices.setPurchaseCallBody(GOOD_PURCHASE_CALL_BODY);
        GE_PaymentServices.ResponseWrapper response = paymentServices.createTransaction();
        Test.stopTest();

        String actualValue = response.body;
        String expectedValue = SUCCESS_RESPONSE_BODY;
        System.assertEquals(201, response.statusCode);
        System.assertEquals(actualValue, expectedValue);
    }

    @isTest static void shouldReturnFailedResponse() {
        PS_IntegrationService.setConfiguration(testConfig);

        // Set mock callout class
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        DataImport__c dataImport = new DataImport__c();
        dataImport.Donation_Amount__c = null;
        dataImport.Payment_Authorization_Token__c = BAD_TOKEN;

        Test.startTest();
        GE_PaymentServices paymentServices = new GE_PaymentServices();
        paymentServices.setPurchaseCallBody(BAD_PURCHASE_CALL_BODY);
        GE_PaymentServices.ResponseWrapper response = paymentServices.createTransaction();
        Test.stopTest();

        String actualValue = response.body;
        String expectedValue = FAILED_RESPONSE_BODY;
        System.assertEquals(403, response.statusCode);
        System.assertEquals(actualValue, expectedValue);
    }

    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');

            if (req.getBody().contains(GOOD_TOKEN)) {
                res.setBody(SUCCESS_RESPONSE_BODY);
                res.setStatusCode(201);
            } else if (req.getBody().contains(BAD_TOKEN)) {
                res.setBody(FAILED_RESPONSE_BODY);
                res.setStatusCode(403);
            }

            return res;
        }
    }

    @IsTest
    private static void shouldUsePaymentServicesConfig() {
        PS_IntegrationService.setConfiguration(testConfig);

        Test.startTest();
        GE_PaymentServices service = new GE_PaymentServices();
        Test.stopTest();

        // Verify that the config properties of the class are
        // the same as those of the inserted config records
        System.assertEquals(testMerchantId,
                service.config.get(GE_PaymentServices.SFDO_MERCHANTIDS));
        System.assertEquals(testApiKey, service.config.get(GE_PaymentServices.API_KEY));
    }

    /**
     * @description When GE_PaymentServices is initialized with its
     *              default payment service names, it should use the apiKey
     *              from "makana" set if not found or null in "payments" config set
    */
    @IsTest
    private static void shouldUseMakanaApiKey() {
        PS_IntegrationService.setConfiguration(testConfig);

        // Set payments Api key to null and set an Api key for makana
        PS_IntegrationService.setConfiguration(
                new Map<String, List<Map<String, String>>>{
                        GE_PaymentServices.PAYMENTS_SERVICE_NAME =>
                                new List<Map<String, String>>{
                                        new Map<String, String>{
                                                'key' => GE_PaymentServices.API_KEY,
                                                'value' => null
                                        }
                                },
                        GE_PaymentServices.MAKANA_SERVICE_NAME =>
                                new List<Map<String, String>>{
                                        new Map<String, String>{
                                                'key' => GE_PaymentServices.API_KEY,
                                                'value' => testMakanaApiKey
                                        }
                                }
                }
        );

        Test.startTest();
        GE_PaymentServices service = new GE_PaymentServices();
        Test.stopTest();

        // Verify apiKey matches makana, while the rest match payments
        System.assertEquals(testMakanaApiKey,
                service.config.get(GE_PaymentServices.API_KEY));
        System.assertEquals(testMerchantId,
                service.config.get(GE_PaymentServices.SFDO_MERCHANTIDS));
    }

    @IsTest
    private static void shouldRequireConfigurationKeysToBeAnElevateCustomer() {
        List<Payment_Services_Configuration__c> requiredConfigs = new
                List<Payment_Services_Configuration__c>();

        for (Integer i = 0; i < GE_PaymentServices.REQUIRED_CONFIG_KEYS.size(); i++) {
            requiredConfigs.add(new Payment_Services_Configuration__c(
                    Service__c = GE_PaymentServices.PAYMENTS_SERVICE_NAME,
                    Key__c = GE_PaymentServices.REQUIRED_CONFIG_KEYS.get(i),
                    Value__c = String.valueOf(i)
            ));
        }
        insert requiredConfigs;

        System.assertEquals(true, GE_PaymentServices.isElevateCustomer,
                'The org should be considered an Elevate customer when ' +
                        'all required configuration keys are present.');

        // Now delete a required configuration key and validate that
        // GE_PaymentServices.isElevateCustomer is false
        delete [SELECT Id FROM Payment_Services_Configuration__c LIMIT 1];
        System.assertEquals(false, GE_PaymentServices.isElevateCustomer,
                'The org should not be considered an Elevate customer without ' +
                        'all required configuration keys present.');
    }

}
