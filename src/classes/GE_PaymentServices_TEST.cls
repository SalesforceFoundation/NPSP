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

    // JWT secret key
    private static final string API_SECRET_KEY = 'a5146b4b-3d2b-4fc4-a5e5-8387968859a4';

    // JWT payload; exp is in miliseconds - we make the JWT valid for 1 minute
    private static final Map<String, String> JWT_PAYLOAD = 
            new Map<String, String> { 'iss' => 'ApiKeyManager',
                                      'sub' => UserInfo.getUserName(),
                                      'sfdo.roles' => 'Payments.Purchase',
                                      'sfdo.product' => 'CRM',
                                      'exp' => String.valueOf(Datetime.now().getTime() + 60 * 1000)};

    // endpoints
    // TODO: at the moment we use the dev1 env, we should replace with a QA env when it becomes available
    private static final String ENDPOINT_ROOT = 'https://7jpea5zk79.execute-api.us-west-2.amazonaws.com/v1/payments';
    private static final String TOKENIZE_ENDPOINT = '/public/tokens';
    private static final String PURCHASE_ENDPOINT = '/verified/purchase';

    // TODO: use Org id 
    private static final String PRODUCT_ID = '00D6g0000000000EAA';

    @isTest static void shouldReturnSuccessfulResponse() {
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        GE_PaymentServices paymentServices = new GE_PaymentServices(GOOD_TOKEN);
        HttpResponse response = paymentServices.makePurchaseCall();

        String contentType = response.getHeader('Content-Type');
        System.assert(contentType == 'application/json');

        String actualValue = response.getBody();
        String expectedValue = SUCCESS_RESPONSE_BODY;
        System.assertEquals(201, response.getStatusCode());
        System.assertEquals(actualValue, expectedValue);
    }

    @isTest static void shouldReturnFailedResponse() {
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        GE_PaymentServices paymentServices = new GE_PaymentServices(BAD_TOKEN);
        HttpResponse response = paymentServices.makePurchaseCall();

        String contentType = response.getHeader('Content-Type');
        System.assert(contentType == 'application/json');

        String actualValue = response.getBody();
        String expectedValue = FAILED_RESPONSE_BODY;
        System.assertEquals(403, response.getStatusCode());
        System.assertEquals(actualValue, expectedValue);
    }


    @isTest
    private static void testMakePayment() {
        // create the payload
        String payload = JSON.serialize(JWT_PAYLOAD);

        // create the jwt
        String jwt = UTIL_Jwt.getSignedJWTFromString(payload, API_SECRET_KEY);

        // tokenize
        HttpResponse response = makeTokenizeCall();
        // Parse the JSON response
        if (response.getStatusCode() != 201) {
            //return JSON.serialize(response.getStatus());
        } else {
            //return JSON.serialize(response.getBody());
            String token = JSON.serialize(response.getBody());
            System.debug('token = ' + token);
        }
        //System.debug('token = ' + token);

        // purchase

    }

    private static HttpResponse makeTokenizeCall() {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(ENDPOINT_ROOT + TOKENIZE_ENDPOINT);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json;charset=UTF-8');
        request.setHeader('productid', PRODUCT_ID);
    
        // Set the body as a JSON object...
        request.setBody('{"cardNumber": "411111111111111",' +
            '"nameOnCard": "John Doe",' +
            '"expMonth": "' + String.valueOf(Date.today().month()) + '",' +
            '"expYear": "' + String.valueOf(Date.today().year() + 1) + '",' +
            '"cvc": "123",' +
            '"gatewayType": "CONFIGURED"' + '}');

        HttpResponse response = http.send(request);

        return response;
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
}
