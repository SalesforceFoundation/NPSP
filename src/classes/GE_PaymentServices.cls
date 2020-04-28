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
    @TestVisible class PaymentServicesException extends Exception {}

    PurchaseCallBody purchaseCallBody;

    // Properties used to configure headers in
    // HTTP Requests to Elevate payment services
    @TestVisible static final String API_Key = 'apiKey';
    @TestVisible static final String BASE_URL = 'baseURL';
    @TestVisible static final String JWT_TOKEN = 'jwttoken';
    @TestVisible static final String SFDO_MERCHANTIDS = 'sfdo.merchantids';
    @TestVisible static final String SFDO_GATEWAYIDS = 'sfdo.gatewayids';
    @TestVisible static final String SFDO_USERNAME = 'sfdo.username';
    @TestVisible static final String ELEVATE_SDK = 'elevateSDK';
    @TestVisible protected final String PRODUCTID = 'productId';

    // Names of Payment Service configuration sets
    @TestVisible static final String PAYMENTS_SERVICE_NAME = 'payments';
    @TestVisible static final String MAKANA_SERVICE_NAME = 'makana';

    @TestVisible Map<String, String> config;

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

    public GE_PaymentServices() {
        config = new Configuration().keyValueMap;
    }

    public void setPurchaseCallBody(String jsonString) {
        Map<String, Object> requestBodyParameters =
                (Map<String, Object>) JSON.deserializeUntyped(jsonString);
        this.purchaseCallBody = new PurchaseCallBody(
                UserInfo.getDefaultCurrency(),
                config.get(SFDO_MERCHANTIDS),
                config.get(SFDO_GATEWAYIDS)
        ).applyAll(requestBodyParameters);
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
        request.setHeader(JWT_TOKEN, getJwt());
        request.setHeader(SFDO_USERNAME, UserInfo.getUserName());
        if (config.get(SFDO_MERCHANTIDS) != null) {
            request.setHeader(SFDO_MERCHANTIDS, config.get(SFDO_MERCHANTIDS));
        }

        // Set the body as a JSON object...
        String purchaseCallBodyString = purchaseCallBody.getAsJson();
        request.setBody(purchaseCallBodyString);

        HttpResponse response = http.send(request);
        ResponseWrapper responseWrapper = new ResponseWrapper(response);

        return responseWrapper;
    }

    public String getEndpointRoot() {
        return config.get(BASE_URL);
    }

    public String getJwt() {
        JWTPayload jwtPayload = new JWTPayload(this);
        String jwt = UTIL_Jwt.getSignedJWTFromString(
                jwtPayload.getAsString(),
                config.get(API_KEY)
        );

        return jwt;
    }

    public String getElevateSDKURL() {
        return config.get(ELEVATE_SDK);
    }

    public String getProductId() {
        return config.get(PRODUCTID);
    }

    /*******************************************************************************************************
    * @description Inner class to assist in constructing the Payload portion of a JSON Web Token.
    */
    public with sharing class JWTPayload {
        String sfdoId;

        public JWTPayload(GE_PaymentServices serviceInstance) {
            sfdoId = serviceInstance.config.get(serviceInstance.PRODUCTID);
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
            generator.writeNumberField('exp', getExpirationDate(1)); // Expires at
            generator.writeStringField('sub', UserInfo.getUserName()); // Subject
            if (sfdoId != null) {
                generator.writeStringField('sfdo.id', sfdoId);
            }
            generator.writeStringField('sfdo.product', 'CRM'); // Product
            generator.writeStringField('sfdo.roles', 'Payments.Purchase');

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
        public String currencyCode;
        public String paymentMethodToken;
        public String merchantId;
        public String gatewayId;
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

        public PurchaseCallBody(String currencyCode, String merchantIds, String gatewayIds) {
            this.currencyCode = currencyCode;
            this.merchantId = merchantIds;
            this.gatewayId = gatewayIds;
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
        public String error;
        public Map<String, Object> headers = new Map<String, Object>{};

        public ResponseWrapper() {}

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

    /**
    * @description Inner class responsible for retrieving Payment Services configuration from
    *              application storage and building and exposing a set of key-value
    *              configuration pairs.
    */
    @TestVisible
    private class Configuration {
        public Configuration() {}

        public Map<String, String> keyValueMap {
            get {
                if (keyValueMap == null) {
                    keyValueMap = new Map<String, String>();
                    String makanaKey;
                    for (Payment_Services_Configuration__c configRecord :
                            getConfigRecordsByName(
                                    new List<String>{
                                            PAYMENTS_SERVICE_NAME, MAKANA_SERVICE_NAME
                                    }
                            )) {
                        if (configRecord.Service__c == PAYMENTS_SERVICE_NAME) {
                            keyValueMap.put(configRecord.Key__c, configRecord.Value__c);
                        } else if (configRecord.Key__c == API_Key &&
                                configRecord.Service__c == MAKANA_SERVICE_NAME) {
                            makanaKey = configRecord.Value__c;
                        }
                    }

                    // If the payments service config does not have an Api key
                    // and makana does, use the makana Api key
                    if (makanaKey != null && keyValueMap.get(API_Key) == null) {
                        keyValueMap.put(API_Key, makanaKey);
                    }
                }
                return keyValueMap;
            }
            private set;
        }

        private List<Payment_Services_Configuration__c> getConfigRecordsByName(List<String>
                serviceNames) {
            return [
                    SELECT Key__c, Value__c, Service__c
                    FROM Payment_Services_Configuration__c
                    WHERE Service__c IN :serviceNames
            ];
        }
    }

}