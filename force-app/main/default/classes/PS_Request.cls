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
* @group Elevate Payment Services
* @description Contains common Elevate payment services methods to build an HttpRequest
*/
public inherited sharing class PS_Request {

    public enum ElevateEndpoint {
        TOKENIZE,
        PURCHASE,
        COMMITMENT,
        COMMITMENT_CANCEL,
        CREATE_ELEVATE_BATCH,
        ADD_TO_ELEVATE_BATCH,
        CHARGE_ELEVATE_BATCH
    }

    public enum ProductType {
        ENGAGEMENT_HUB,
        GIVING_PAGE,
        CRM,
        THIRD_PARTY_GIVING_PAGE
    }

    public enum OriginType {
        CRM,
        THIRD_PARTY_GIVING_PAGE
    }

    public static String ROLE_PAYMENT_TOKENS = 'Payments.Tokens';
    public static String ROLE_PAYMENT_PURCHASE = 'Payments.Purchase';
    public static String ROLE_PAYMENT_COMMITMENTS = 'Payments.Commitments';
    public static String ROLE_PAYMENT_BATCH = 'Payments.Batch';

    public static String JWT_ISSUER_PARAM = 'iss';
    public static String JWT_EXPIRES_AT_PARAM = 'exp';
    public static String JWT_SUBJECT_PARAM = 'sub';
    public static String JWT_SFDO_ID_PARAM = 'sfdo.id';
    public static String JWT_PRODUCT_PARAM = 'sfdo.product';
    public static String JWT_ROLES_PARAM = 'sfdo.roles';
    
    public static String ENDPOINT_TOKENIZE = '/v1/payments/verified/tokens';
    public static String ENDPOINT_PURCHASE = '/v1/payments/verified/purchase';
    public static String ENDPOINT_COMMITMENT = '/v1/payments/verified/commitments';
    public static String ENDPOINT_COMMITMENT_CANCEL = '/v1/payments/verified/commitments/{0}/cancel';
    public static String ENDPOINT_CREATE_ELEVATE_BATCH = '/v1/payments/verified/batch';
    public static String ENDPOINT_ADD_TO_ELEVATE_BATCH = '/v1/payments/verified/batch/{0}/add';
    public static String ENDPOINT_CHARGE_ELEVATE_BATCH = '/v1/payments/verified/batch/{0}/capture';

    public static String PRODUCT_METADATA_SCHEMA_URI = 'https://payments-js.elevate.salesforce.org/schema/productMetadata/donation-v1.1.0';
    private static Integer RECOMMENDED_TIMEOUT_MS = 20000;

    /***
    * @description Returns payments service endpoint URL
    * @param endpoint Elevate Endpoint enum 
    * @return String
    */
    public String getEndpoint(ElevateEndpoint endpoint) {
        return new Builder().getEndpoint(endpoint, null);
    }

    /***
    * @description Builds an HttpRequest
    */
    public class Builder {
        /***
        * @description Returns Elevate Payments Service configuration
        */
        private PS_IntegrationServiceConfig.Service configService {
            get {
                if (configService == null) {
                    configService = new PS_IntegrationServiceConfig.Service();
                }
                return configService;
            }
            set;
        }

        private UTIL_Http.Method method;
        private ElevateEndpoint endpoint;
        private String jsonBody;
        private String commitmentId;
        private String elevateBatchId;
        private Integer timeout;

        /***
        * @description Sets HttpRequest method
        * @param method HttpRequest method
        * @return Builder This request builder instance
        */
        public Builder withMethod(UTIL_Http.Method method) {
            this.method = method;
            return this;
        }

        /***
        * @description Sets HttpRequest endpoint
        * @param endpoint API endpoint
        * @return Builder This request builder instance
        */
        public Builder withEndpoint(ElevateEndpoint endpoint) {
            this.endpoint = endpoint;
            return this;
        }

        /***
        * @description Incorporates the Commitment Id into the endpoint where applicable
        * @param commitmentId Recurring Donation Commitment Id
        * @return Builder This request builder instance
        */
        public Builder withCommitmentId(String commitmentId) {
            this.commitmentId = commitmentId;
            return this;
        }

        /***
        * @description Incorporates the Elevate Elevate Batch Id into the endpoint where applicable
        * @param commitmentId Elevate Elevate Batch Id
        * @return Builder This request builder instance
        */
        public Builder withElevateBatchId(String elevateBatchId) {
            this.elevateBatchId = elevateBatchId;
            return this;
        }

        /***
        * @description Sets HttpRequest timeout
        * @return Builder This request builder instance
        */
        public Builder withRecommendedTimeout() {
            return withTimeout(RECOMMENDED_TIMEOUT_MS);
        }

        /***
        * @description Sets the timeout in milliseconds for the request
        * @param timeout Timeout value in milliseconds
        * @return Builder This request builder instance
        */
        public Builder withTimeout(Integer timeout) {
            this.timeout = timeout;
            return this;
        }

        /***
        * @description Sets HttpRequest body
        * @param jsonBody HttpRequest JSON body
        * @return Builder This request builder instance
        */
        public Builder withBody(String jsonBody) {
            this.jsonBody = jsonBody;
            return this;
        }

        /***
        * @description Builds a HttpRequest
        * @return HttpRequest
        */
        public HttpRequest build() {
            HttpRequest request = new HttpRequest();

            request.setEndpoint(getEndpoint(endpoint, commitmentId));
            request.setMethod(method.name());
            setHeader(request, endpoint);

            // Default timeout is 10s if the value is not specified
            if (timeout != null) {
                request.setTimeout(timeout);
            }

            // Set the body as a JSON object...
            if (String.isNotBlank(jsonBody)) {
                request.setBody(jsonBody);
            }

            return request;
        }

        /***
        * @description Sets HttpRequest header
        * @param request HttpRequest
        * @param endpoint API endpoint
        * @return void
        */
        private void setHeader(HttpRequest request, ElevateEndpoint endpoint) {
            request.setHeader('Content-Type', 'application/json;charset=UTF-8');
            request.setHeader(PS_IntegrationServiceConfig.JWT_TOKEN, getJwt(endpoint));
            request.setHeader(PS_IntegrationServiceConfig.SFDO_USERNAME, UserInfo.getUserName());

            if (String.isNotBlank(configService.getMerchantIds())) {
                request.setHeader(
                    PS_IntegrationServiceConfig.SFDO_MERCHANTIDS,
                    configService.getMerchantIds()
                );
            }
        }

        /***
        * @description Constructs HttpRequest endpoint including the endpoint root
        * @param endpoint API endpoint
        * @param commitmentId Recurring Donation Commitment Id (required for cancel commitment endpoint only)
        * @return String Full endpoint
        */
        public String getEndpoint(ElevateEndpoint endpoint, String commitmentId) {
            String value;
            if (endpoint == ElevateEndpoint.TOKENIZE) {
                value = ENDPOINT_TOKENIZE;

            } else if (endpoint == ElevateEndpoint.PURCHASE) {
                value = ENDPOINT_PURCHASE;

            } else if (endpoint == ElevateEndpoint.COMMITMENT) {
                value = ENDPOINT_COMMITMENT;

                if (String.isNotBlank(commitmentId)) {
                    value += '/' + commitmentId;
                }

            } else if (endpoint == ElevateEndpoint.COMMITMENT_CANCEL) {
                value = String.format(
                    ENDPOINT_COMMITMENT_CANCEL,
                    new String[]{
                        commitmentId
                    }
                );
            } else if (endpoint == ElevateEndpoint.CREATE_ELEVATE_BATCH) {
                value = ENDPOINT_CREATE_ELEVATE_BATCH;
            } else if (endpoint == ElevateEndpoint.ADD_TO_ELEVATE_BATCH) {
                value = String.format(
                    ENDPOINT_ADD_TO_ELEVATE_BATCH,
                    new String[] {
                        elevateBatchId
                    }
                );
            } else if (endpoint == ElevateEndpoint.CHARGE_ELEVATE_BATCH) {
                value = String.format(
                        ENDPOINT_CHARGE_ELEVATE_BATCH,
                        new String[] {
                                elevateBatchId
                        }
                );
            }

            return String.isBlank(value)
                ? null
                : (configService.getEndpointRoot() + value);
        }

        /***
        * @description Constructs JSON Web Token 
        * @param endpoint API endpoint
        * @return String JSON Web Token
        */
        public String getJwt(ElevateEndpoint endpoint) {
            JWTPayload payload = new JWTPayload(configService.getClientId(), endpoint);

            String jwt = UTIL_Jwt.getSignedJWTFromString(
                payload.getAsString(),
                configService.getAPIKey()
            );

            return jwt;
        }
    }

    /***
    * @description Assists in constructing the Payload portion of a JSON Web Token.
    */
    public class JWTPayload {
        String sfdoId;
        ElevateEndpoint endpoint;

        /***
        * @description Constructor 
        * @param sfdoId SFDO Id
        * @param endpoint API endpoint
        */
        public JWTPayload(String sfdoId, ElevateEndpoint endpoint) {
            this.sfdoId = sfdoId;
            this.endpoint = endpoint;
        }

        /***
        * @description Sets JSON Web Token params and values
        * @return String JSON Web Token
        */
        public String getAsString() {
            JSONGenerator generator = JSON.createGenerator(false);

            generator.writeStartObject();
            generator.writeStringField(JWT_ISSUER_PARAM, 'ApiKeyManager'); 
            generator.writeNumberField(JWT_EXPIRES_AT_PARAM, getExpirationDate(1)); 
            generator.writeStringField(JWT_SUBJECT_PARAM, UserInfo.getUserName()); 

            if (sfdoId != null) {
                generator.writeStringField(JWT_SFDO_ID_PARAM, sfdoId);
            }

            generator.writeStringField(JWT_PRODUCT_PARAM, ProductType.CRM.name());

            setRoles(generator);

            return generator.getAsString();
        }

        /***
        * @description Calculates expiration date from today
        * @param daysFromNow Number of days from now
        * @return Long JSON Web Token expiration date
        */
        @TestVisible
        private Long getExpirationDate(Integer daysFromNow) {
            DateTime expirationDate = DateTime.now().addDays(daysFromNow);

            return getEpochTimestamp(expirationDate);
        }

        /***
        * @description Calculates Epoch timestamp
        * @param dt Datetime value
        * @return Long 
        */
        private Long getEpochTimestamp(DateTime dt) {
            return dt.getTime() / 1000; // convert milliseconds to seconds as needed by iat
        }

        /***
        * @description Sets SFDO roles required for the request authorization 
        * @param generator JSON Generator containing JWT params and values
        * @return void 
        */
        private void setRoles(JSONGenerator generator) {
            String role = getRole();
            if (String.isNotBlank(role)) {
                generator.writeStringField(JWT_ROLES_PARAM, role);
            }
        }

        private String getRole () {
            String value = '';
            if (isTokenizeEndpoint()) {
                value = ROLE_PAYMENT_TOKENS;
            } else if (isPurchaseEndpoint()) {
                value = ROLE_PAYMENT_PURCHASE;
            } else if (isCommitmentEndpoint()) {
                value = ROLE_PAYMENT_COMMITMENTS;
            } else if (isElevateBatchEndpoint()) {
                value = ROLE_PAYMENT_BATCH;
            }
            return value;
        }

        private Boolean isTokenizeEndpoint() {
            return endpoint == ElevateEndpoint.TOKENIZE;
        }

        private Boolean isPurchaseEndpoint() {
            return endpoint == ElevateEndpoint.PURCHASE;
        }

        private Boolean isElevateBatchEndpoint() {
            return endpoint == ElevateEndpoint.CREATE_ELEVATE_BATCH
                    || endpoint == ElevateEndpoint.ADD_TO_ELEVATE_BATCH
                    || endpoint == ElevateEndpoint.CHARGE_ELEVATE_BATCH;
        }

        private Boolean isCommitmentEndpoint () {
            return endpoint == ElevateEndpoint.COMMITMENT
                    || endpoint == ElevateEndpoint.COMMITMENT_CANCEL;
        }
    }
}
