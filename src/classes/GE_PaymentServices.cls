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

    private enum ElevateEndpoints { PURCHASE }

    private String getEndpoint(ElevateEndpoints endpoint) {
        if (endpoint === ElevateEndpoints.PURCHASE) {
            return '/v1/payments/verified/purchase';
        }
        return null;
    }

    // TODO: Get header/secret info from payments configuration hidden sobject
    private String getEndpointRoot() {
        return 'https://7jpea5zk79.execute-api.us-west-2.amazonaws.com';
    }

    public String getJwt() {
        JWTPayload jwtPayload = new JWTPayload();
        String jwt = UTIL_Jwt.getSignedJWTFromString(jwtPayload.getAsString(), getJwtSecret());

        return jwt;
    }

    private String getMerchantIds() {
        return '47b70ca4-0f6e-4c52-819f-667ae804f9d2';
    }

    private String getUsername() {
        return 'cbaxter';
    }

    private String getJwtSecret() {
        return 'foo';
    }

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

    public with sharing class Metadata {
        public String campaignCode;
    }

    public with sharing class PurchaseCallBody {
        public Double amount;
        public String currencyCode = getCurrencyCode();
        public String paymentMethodToken;
        public String merchantId = getMerchantId();
        public String gatewayId = getGatewayId();
        public String email;
        public String firstName;
        public String lastName;
        public Metadata metadata;

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