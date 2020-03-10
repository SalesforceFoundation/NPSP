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
* @description Class holds payment services related methods.
*/
public with sharing class GE_PaymentServices {

    String paymentMethodToken = null;

    public GE_PaymentServices(String token) {
        this.paymentMethodToken = token;
    }

    public HttpResponse makePurchaseCall() {
        return makePurchaseCall(this.paymentMethodToken);
    }

    public HttpResponse makePurchaseCall(String token) {
        // Create http request...
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(getEndpointRoot() + getEndpoint(ElevateEndpoints.PURCHASE));
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json;charset=UTF-8');
        request.setHeader('jwttoken', getJwt());
        request.setHeader('sfdo.merchantids', getMerchantIds());
        request.setHeader('sfdo.username', getUsername());

        // Set the body as a JSON object...
        request.setBody('{"amount": ' + getAmount() + ',' +
            '"currencyCode": "' + getCurrencyCode() + '",' +
            '"paymentMethodToken": "' + token + '",' +
            '"merchantId": "' + getMerchantId() + '",' +
            '"gatewayId": "' + getGatewayId() + '",' +
            '"email": "' + getEmail() + '",' +
            '"firstName": "' + getFirstName() + '",' +
            '"lastName": "' + getLastName() + '",' +
            '"metadata": ' + getMetadata() + '}');

        HttpResponse response = http.send(request);

        return response;
    }

    private enum ElevateEndpoints { PURCHASE }

    private String getEndpoint(ElevateEndpoints endpoint) {
        if (endpoint === ElevateEndpoints.PURCHASE) {
            return '/v1/payments/verified/purchase';
        }
        return null;
    }

    //
    // Methods for retrieving request headers
    //

    private String getEndpointRoot() {
        return 'https://7jpea5zk79.execute-api.us-west-2.amazonaws.com';
    }

    private String getJwt() {
        return 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJBcGlLZXlNYW5hZ2VyIiwiaWF0IjoxNTgzMTk2MTAxLCJleHAiOjE2MTQ3MzIxMTAsImF1ZCI6Ind3dy5leGFtcGxlLmNvbSIsInN1YiI6ImNiYXh0ZXIiLCJzZmRvLmlkIjoiMDBENmcwMDAwMDAwMDAwRUFBIiwic2Zkby5wcm9kdWN0IjoiQ1JNIiwic2Zkby5yb2xlcyI6IlBheW1lbnRzLlB1cmNoYXNlIn0.Fk2kH8occu-tEabrYALiAN16XlIUj4vpptWGs0x8eZs';
    }

    private String getMerchantIds() {
        return '47b70ca4-0f6e-4c52-819f-667ae804f9d2';
    }

    private String getUsername() {
        return 'cbaxter';
    }

    //
    // Methods for retrieving the request body
    //

    private Integer getAmount() {
        return 25;
    }

    private String getCurrencyCode() {
        return 'USD';
    }

    private String getPaymentMethodToken() {
        return this.paymentMethodToken;
    }

    private String getMerchantId() {
        return '47b70ca4-0f6e-4c52-819f-667ae804f9d2';
    }

    private String getGatewayId() {
        return 'f23da98a-c7aa-4637-962a-8c852e765e38';
    }

    private String getEmail() {
        return 'bart.simpson@example.com';
    }

    private String getFirstName() {
        return 'Bart';
    }

    private String getLastName() {
        return 'Simpson';
    }

    private String getMetadata() {
        return '{ "campaignCode": "fake-campaign-code" }';
    }
}
