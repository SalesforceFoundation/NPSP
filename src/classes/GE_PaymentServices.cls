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

    PurchaseCallBody purchaseCallBody;

    public GE_PaymentServices() {}

    public void setPurchaseCallBody(String jsonString) {
        Map<String, Object> requestBodyParameters =
            (Map<String, Object>) JSON.deserializeUntyped(jsonString);
        this.purchaseCallBody = new PurchaseCallBody().applyAll(requestBodyParameters);
    }

    /*******************************************************************************************************
    * @description Method sends a OneTimePurchaseRequest to Elevate. Check out the Payments swagger in the
    * SFDO Payments repo for additional information.
    */
    public ResponseWrapper createTransaction() {
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
        String purchaseCallBodyString = purchaseCallBody.getAsJson();
        request.setBody(purchaseCallBodyString);

        HttpResponse response = http.send(request);
        ResponseWrapper responseWrapper = new ResponseWrapper(response);

        return responseWrapper;
    }

    public enum ElevateEndpoints { TOKENIZE, PURCHASE }

    public String getEndpoint(ElevateEndpoints endpoint) {
        if (endpoint === ElevateEndpoints.TOKENIZE) {
            return '/v1/payments/public/tokens';
        }

        if (endpoint === ElevateEndpoints.PURCHASE) {
            return '/v1/payments/verified/purchase';
        }

        return null;
    }

    // TODO: Get header/secret info from payments configuration hidden sobject
    public String getEndpointRoot() {
        return 'https://7jpea5zk79.execute-api.us-west-2.amazonaws.com';
    }

    public String getJwt() {
        JWTPayload jwtPayload = new JWTPayload();
        String jwt = UTIL_Jwt.getSignedJWTFromString(jwtPayload.getAsString(), getJwtSecret());

        return jwt;
    }

    private String getMerchantIds() {
        // Dev1
        return '47b70ca4-0f6e-4c52-819f-667ae804f9d2';
        // Dev2
        //return 'a5146b4b-3d2b-4fc4-a5e5-8387968859a4';
    }

    private String getUsername() {
        return 'cbaxter';
    }

    private String getJwtSecret() {
        return 'foo';
    }

    /*******************************************************************************************************
    * @description Inner class to assist in constructing the Payload portion of a JSON Web Token.
    */
    public with sharing class JWTPayload {

        public JWTPayload(/*SecretObject config*/) {
            // TODO: Handle secret object fields
        }

        private Long getEpochTimestamp(DateTime dt) {
            return dt.getTime() / 1000; // convert milliseconds to seconds as needed by iat
        }

        private Long getExpirationDate(Integer daysFromNow) {
            DateTime expirationDate = DateTime.now().addDays(daysFromNow);
            return getEpochTimestamp(expirationDate);
        }

        private String getAsString() {
            JSONGenerator generator = JSON.createGenerator(false);

            generator.writeStartObject();
            generator.writeStringField('iss', 'ApiKeyManager'); // Issuer
            generator.writeNumberField('iat', getEpochTimestamp(Datetime.now())); // Issued at
            generator.writeNumberField('exp', getExpirationDate(1)); // Expires at
            generator.writeStringField('aud', 'www.example.com'); // Audience
            generator.writeStringField('sub', 'cbaxter'); // Subject
            generator.writeStringField('sfdo.id', '00D6g0000000000EAA'); // Org ID
            generator.writeStringField('sfdo.product', 'CRM'); // Product
            generator.writeStringField('sfdo.roles', 'Payments.Purchase'); // Call Role

            return generator.getAsString();
        }
    }

    /*******************************************************************************************************
    * @description Inner class of PurchaseCallBody to assist in constructing the metadata property.
    * This could/should probably just be a map.
    */
    public with sharing class Metadata {
        public String campaignCode;
    }

    /*******************************************************************************************************
    * @description Inner class to assist in constructing the Purchase http request body.
    */
    public with sharing class PurchaseCallBody {
        /*********************************
        * Required properties
        */
        public Double amount;
        // Currency code for the amount property. Currently an ENUM = [USD] from Elevate
        public String currencyCode = getCurrencyCode();
        public String paymentMethodToken;
        public String merchantId = getMerchantId();
        public String gatewayId = getGatewayId();
        public String email;
        public String firstName;
        public String lastName;

        /*********************************
        * Optional properties
        */
        // May be any key:value pairs. i.e. campaignCode: 123
        public Metadata metadata;
        // The donor salutation. E.g. Mr., Ms.
        public String salutation;
        // The donor suffix. E.g. III, Esq.
        public String suffix;
        public String phone;
        public String addressLine1;
        public String addressLine2;
        public String city;
        public String state;
        public String postalCode;
        // The ISO 3166-1 alpha-2 country code. E.g. US
        public String country;

        private String getCurrencyCode() {
            return 'USD';
        }

        private String getMerchantId() {
            return '47b70ca4-0f6e-4c52-819f-667ae804f9d2';
        }

        private String getGatewayId() {
            return 'f23da98a-c7aa-4637-962a-8c852e765e38';
        }

        public PurchaseCallBody() {
            this.currencyCode = getCurrencyCode();
            this.merchantId = getMerchantId();
            this.gatewayId = getGatewayId();
        }

        public String getAsJson() {
            return JSON.serialize(this);
        }

        public PurchaseCallBody applyAll(Map<String, Object> requestBodyParameters) {
            Map<String, Object> selfAsUntyped = (Map<String, Object>) JSON.deserializeUntyped(getAsJson());
            for (String key : requestBodyParameters.keySet()) {
                selfAsUntyped.put(key, requestBodyParameters.get(key));
            }

            return (PurchaseCallBody) JSON.deserialize(JSON.serialize(selfAsUntyped), PurchaseCallBody.class);
        }
    }

    /*******************************************************************************************************
    * @description Inner class needed to return contents of the HttpResponse. HttpResponse can't be directly
    * serialized using JSON.serialize().
    */
    public with sharing class ResponseWrapper {
        public Integer statusCode;
        public String status;
        public String body;
        public Map<String, Object> headers = new Map<String, Object>{};

        public ResponseWrapper(HttpResponse response) {
            this.statusCode = response.getStatusCode();
            this.status = response.getStatus();
            this.body = response.getBody();

            String[] headerKeys = response.getHeaderKeys();
            if (headerKeys != null) {
                for (String headerKey : headerKeys) {
                    this.headers.put(headerKey, response.getHeader(headerKey));
                }
            }
        }
    }
}