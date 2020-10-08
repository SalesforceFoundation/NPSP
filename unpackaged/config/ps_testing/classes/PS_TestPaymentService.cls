/*
    Copyright (c) 2020, Salesforce.org
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
* @group-content
* @description Class for testing payment services
*/
public with sharing class PS_TestPaymentService {

    private static final String BASE_PURCHASE_CALL_BODY = '{"amount":25,"email":"test@test.test","firstName":"John","lastName":"Doe","metadata":{},';
    private static final String TOKEN_FIELD_NAME = 'token';
    private static final String STATUS_FIELD_NAME = 'status';
    private static final String STATUS_FIELD_SUCCESS = 'CAPTURED';

    // TODO: use Org id 
    private static final String PRODUCT_ID = '00D6g0000000000EAA';

    /**
     * @description method for testing the end to end payment processing
     * @return  Boolean: true is successful, false if failed
     */
    public static Boolean testPaymentServiceFlow() {   
        Boolean success = true;

        try {
            GE_PaymentServices paymentServices = new GE_PaymentServices();

            // build the url for tokenize
            String tokenizeEndpoint = paymentServices.getEndpointRoot() + 
                        paymentServices.getEndpoint(PS_Request.ElevateEndpoints.TOKENIZE);

            // tokenize the card
            HttpResponse tokenHttpResponse = makeTokenizeCall(tokenizeEndpoint);
            String token = getToken(tokenHttpResponse);

            // purchase
            String requestBodyParameters = BASE_PURCHASE_CALL_BODY + '"paymentMethodToken":"' + token + '"}';
            paymentServices.setPurchaseCallBody(requestBodyParameters);
            UTIL_Http.Response purchaseResponse = paymentServices.createTransaction();
            checkPurchaseStatus(purchaseResponse);
            
            System.debug('Payment Service Flow successful.');
        } catch(Exception ex) {
            success = false;
            System.debug('Payment Service Flow failed. ' + ex.getStackTraceString());
        } 

        return success;
    }

    /**
     * @description: submit the tokenize request
     * @return HttpResponse: the response from the tokenize request
     * @param String: the endpoint for tokenize
     */ 
    private static HttpResponse makeTokenizeCall(String endpoint) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json;charset=UTF-8');
        request.setHeader('productid', PRODUCT_ID);

        // set the request body
        request.setBody('{"cardNumber": "4111111111111111",' +
            '"nameOnCard": "John Doe",' +
            '"expMonth": "' + String.valueOf(Date.today().month()) + '",' +
            '"expYear": "' + String.valueOf(Date.today().year() + 1) + '",' +
            '"cvc": "123",' +
            '"gatewayType": "CONFIGURED"' + '}');

        HttpResponse response = http.send(request);
        return response;
    }

    /**
     * @description: read the token from the response
     * @return String: the token
     * @param HttpResponse: the response
     */ 
    private static String getToken(HttpResponse response) {
        if (response.getStatusCode() != 201) {
            // failed
            String status = JSON.serialize(response.getStatus());
            System.assert(false, 'Failed to tokenize card. ' + status);
        } else {
            // success
            JSONParser parser = JSON.createParser(response.getBody());
            while (parser.nextToken() != null) {
                if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == TOKEN_FIELD_NAME)) {
                    // read the token
                    parser.nextToken();
                    String token = parser.getText();
                    return token;
                }
            } 
        }
        return '';
    }

    /**
     * @description: check the purchase status
     * @param UTIL_Http.Response response
     */ 
    private static void checkPurchaseStatus(UTIL_Http.Response response) {
        // check the request status
        System.assertEquals(201, response.statusCode, 'Purchase failed. ' + response.status);

        // check the body
        String body = response.body;
        JSONParser parser = JSON.createParser(response.body);
        while (parser.nextToken() != null) {
            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == STATUS_FIELD_NAME)) {
                // read the status
                parser.nextToken();
                String status = parser.getText();
                System.assertEquals(STATUS_FIELD_SUCCESS, status, 'Purchase failed. ' + status);
                break;
            }
        } 
    }
    
}
