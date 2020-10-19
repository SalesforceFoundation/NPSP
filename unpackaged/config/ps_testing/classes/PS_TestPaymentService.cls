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

    private static final String BASE_PURCHASE_CALL_BODY = '{"amount":2500,"email":"test@test.test","firstName":"John","lastName":"Doe","metadata":{},';
    private static final String STATUS_FIELD_SUCCESS = 'CAPTURED';
    
    private static PS_IntegrationServiceConfig.Service configService {
        get {
            if (configService == null) {
                configService = new PS_IntegrationServiceConfig.Service();
            }
            return configService;
        }
        set;
    }

    private static UTIL_Http.RequestService requestService {
        get {
            if (requestService == null) {
                requestService = new UTIL_Http.RequestService();
            }
            return requestService;
        }
        set;
    }

    /**
     * @description method for testing the end to end payment processing
     * @return  Boolean: true is successful, false if failed
     */
    public static Boolean testPaymentServiceFlow() {   
        Boolean success = true;

        try {
            // tokenize the card
            UTIL_Http.Response tokenResponse = makeTokenizeCall();
            String token = getToken(tokenResponse);

            // purchase
            GE_PaymentServices paymentServices = new GE_PaymentServices();
            String requestBodyParameters = BASE_PURCHASE_CALL_BODY + '"paymentMethodToken":"' + token + '"}';
            UTIL_Http.Response response = paymentServices.createTransaction(requestBodyParameters);

            checkPurchaseStatus(response);
            
            System.debug('Payment Service Flow successful.');
        } catch(Exception ex) {
            success = false;
            System.debug('Payment Service Flow failed. ' + ex.getStackTraceString());
        } 

        return success;
    }

    /**
     * @description: submit the tokenize request
     * @return UTIL_Http.Response: the response from the tokenize request
     */ 
    private static UTIL_Http.Response makeTokenizeCall() {
        String jsonRequestBody = '{"cardNumber": "4111111111111111",' +
            '"nameOnCard": "John Doe",' +
            '"expMonth": "' + String.valueOf(Date.today().month()) + '",' +
            '"expYear": "' + String.valueOf(Date.today().year() + 1) + '",' +
            '"cvc": "123",' +
            '"gatewayId": "' + configService.getGatewayIds() + '",' +
            '"gatewayType": "CONFIGURED"' + '}';
        
        HttpRequest request = new PS_Request.Builder()
            .withMethod(UTIL_Http.Method.POST)
            .withEndpoint(PS_Request.ElevateEndpoint.TOKENIZE)
            .withBody(jsonRequestBody)
            .build();
        
        UTIL_Http.Response response = requestService.sendRequest(request);
        return response;
    }

    /**
     * @description: read the token from the response
     * @return String: the token
     * @param HttpResponse: the response
     */ 
    private static String getToken(UTIL_Http.Response response) {
        System.assertEquals(UTIL_Http.STATUS_CODE_CREATED, response.statusCode, 
            'The tokenize card callout failed: ' + response.getErrorMessages());

        TokenResponseBody tokenData = (TokenResponseBody) JSON.deserialize(response.body, TokenResponseBody.class);  
            
        return tokenData.token;
    }

    /**
     * @description: check the purchase status
     * @param UTIL_Http.Response response
     */ 
    private static void checkPurchaseStatus(UTIL_Http.Response response) {
        System.assertEquals(UTIL_Http.STATUS_CODE_CREATED, response.statusCode, 
            'The purchase callout failed: ' + response.getErrorMessages());
        
        PurchaseResponseBody purchaseData = (PurchaseResponseBody) JSON.deserialize(response.body, PurchaseResponseBody.class);  

        System.assertEquals(STATUS_FIELD_SUCCESS, purchaseData.status, 'The purchase status should match');
    }
    
    /**
     * @description Contains Elevate token data in the response body
     */
    public class TokenResponseBody {
        public String addressPostalCodeCheck;
        public String cvcCheck;
        public String addressLine1Check;
        public String token;
    }

    /**
     * @description Contains Elevate one-time payment (purchase) data in the response body
     */
    public class PurchaseResponseBody {
        public String status;
        public String commitmentId;
        public String type;
    }
    
}
