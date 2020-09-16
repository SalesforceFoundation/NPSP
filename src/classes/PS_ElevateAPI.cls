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
* @description Contains common Elevate payment services API methods to send HttpRequest and return response
*/
public inherited sharing class PS_ElevateAPI {
    public class APIException extends Exception {}

    public enum ElevateEndpoint { 
        TOKENIZE, PURCHASE, 
        COMMITMENT, COMMITMENT_CANCEL 
    }

    public enum HttpRequestMethod { 
        GET, POST, PATCH 
    }

    public static final String TIMED_OUT = 'timed out';
    public static final Integer TIMEOUT_STATUS_CODE = 408;
    public static final Integer BAD_REQUEST_STATUS_CODE = 400;

    @TestVisible
    private Map<String, String> config {
        get {
            if (config == null) {
                config = new PS_IntegrationServiceConfig.Configuration().keyValueMap;
            }
            return config;
        }
        set;
    }

    /***
    * @description Sends an HttpRequest to the Elevate Payment Services API
    */
    public ResponseWrapper sendRequest(HttpRequestMethod method, ElevateEndpoint endpoint, String commitmentId, String jsonBody) {
        HttpRequest request = new HttpRequest();

        request.setEndpoint(getEndpoint(endpoint, commitmentId));
        request.setMethod(method.name());
        setHeader(request, endpoint);

        // Set the body as a JSON object...
        if (String.isNotBlank(jsonBody)) {
            request.setBody(jsonBody);
        }

        HttpResponse response = new Http().send(request);
        return new ResponseWrapper(response);
    }

    private void setHeader(HttpRequest request, ElevateEndpoint endpoint) {
        request.setHeader('Content-Type', 'application/json;charset=UTF-8');
        request.setHeader(PS_IntegrationServiceConfig.JWT_TOKEN, getJwt(endpoint));
        request.setHeader(PS_IntegrationServiceConfig.SFDO_USERNAME, UserInfo.getUserName());

        if (config.get(PS_IntegrationServiceConfig.SFDO_MERCHANTIDS) != null) {
            request.setHeader(
                PS_IntegrationServiceConfig.SFDO_MERCHANTIDS,
                config.get(PS_IntegrationServiceConfig.SFDO_MERCHANTIDS)
            );
        }
    }

    public String getEndpoint(ElevateEndpoint endpoint, String commitmentId) {
        String value;
        if (endpoint == ElevateEndpoint.TOKENIZE) {
            value = '/v1/payments/public/tokens';

        } else if (endpoint == ElevateEndpoint.PURCHASE) {
            value = '/v1/payments/verified/purchase';

        } else if (endpoint == ElevateEndpoint.COMMITMENT) {
            value = '/v1/payments/public/commitments';

        } else if (endpoint == ElevateEndpoint.COMMITMENT_CANCEL) {
            value = '/v1/payments/verified/commitments/' + commitmentId + '/cancel';
        }

        return String.isBlank(value)
            ? null
            : (getEndpointRoot() + value);
    }

    public String getEndpointRoot() {
        return config.get(PS_IntegrationServiceConfig.BASE_URL);
    }

    public String getElevateSDKURL() {
        return config.get(PS_IntegrationServiceConfig.ELEVATE_SDK);
    }

    public String getProductId() {
        return config.get(PS_IntegrationServiceConfig.PRODUCTID);
    }

    public String getGatewayIds() {
        return config.get(PS_IntegrationServiceConfig.SFDO_GATEWAYIDS);
    }

    public String getJwt(ElevateEndpoint endpoint) {
        JWTPayload payload = new JWTPayload(
            config.get(PS_IntegrationServiceConfig.PRODUCTID),
            endpoint
        );

        String jwt = UTIL_Jwt.getSignedJWTFromString(
            payload.getAsString(),
            config.get(PS_IntegrationServiceConfig.API_KEY)
        );

        return jwt;
    }

    /***
    * @description Assists in constructing the Payload portion of a JSON Web Token.
    */
    public with sharing class JWTPayload {
        String sfdoId;
        ElevateEndpoint endpoint;

        public JWTPayload(String sfdoId, ElevateEndpoint endpoint) {
            this.sfdoId = sfdoId;
            this.endpoint = endpoint;
        }

        private Long getEpochTimestamp(DateTime dt) {
            return dt.getTime() / 1000; // convert milliseconds to seconds as needed by iat
        }

        private Long getExpirationDate(Integer daysFromNow) {
            DateTime expirationDate = DateTime.now().addDays(daysFromNow);
            return getEpochTimestamp(expirationDate);
        }

        public String getAsString() {
            JSONGenerator generator = JSON.createGenerator(false);

            generator.writeStartObject();
            generator.writeStringField('iss', 'ApiKeyManager'); // Issuer
            generator.writeNumberField('exp', getExpirationDate(1)); // Expires at
            generator.writeStringField('sub', UserInfo.getUserName()); // Subject
            if (sfdoId != null) {
                generator.writeStringField('sfdo.id', sfdoId);
            }
            generator.writeStringField('sfdo.product', 'CRM'); // Product

            setRoles(generator);

            return generator.getAsString();
        }

        private void setRoles(JSONGenerator generator) {
            String value = '';

            if (endpoint == ElevateEndpoint.TOKENIZE) {
                value = 'Payments.Tokens';

            } else if (endpoint == ElevateEndpoint.PURCHASE) {
                value = 'Payments.Purchase';

            } else if (endpoint == ElevateEndpoint.COMMITMENT 
                || endpoint == ElevateEndpoint.COMMITMENT_CANCEL
            ) {
                value = 'Payments.Commitments';
            }

            if (String.isNotBlank(value)) {
                generator.writeStringField('sfdo.roles', value);
            }
        }
    }

    /***
    * @description Creates an http request wrapper for an exception
    */
    public ResponseWrapper buildErrorResponse(Exception ex, String message) {
        Boolean isCalloutException = ex instanceof System.CalloutException;
        Boolean hasTimedOut = isCalloutException && ex.getMessage().contains(TIMED_OUT);

        return hasTimedOut
            ? buildTimeoutResponse(ex, message)
            : buildErrorResponse(ex);
    }

    /***
    * @description Creates an http request wrapper for an exception
    */
    public ResponseWrapper buildErrorResponse(Exception ex) {
        ResponseWrapper response = new ResponseWrapper();
        response.statusCode = BAD_REQUEST_STATUS_CODE;
        response.status = ex.getMessage();
        response.body = JSON.serialize(new Map<String, String>{ 'message' => System.Label.commonUnknownError });

        return response;
    }

    /***
    * @description Creates an http request wrapper for a timeout error response
    */
    public ResponseWrapper buildTimeoutResponse(Exception ex, String message) {
        ResponseWrapper response = new ResponseWrapper();
        response.statusCode = TIMEOUT_STATUS_CODE;
        response.status = ex.getMessage();
        response.body = JSON.serialize(new Map<String, String>{ 'message' => message });

        return response;
    }

    /***
    * @description Returns contents of the HttpResponse.
    * HttpResponse can't be directly serialized using JSON.serialize().
    */
    public with sharing class ResponseWrapper {
        public Map<String, Object> headers = new Map<String, Object>{};
        public Integer statusCode;
        public String status;
        public String body;

        public ResponseWrapper() {}

        public ResponseWrapper(HttpResponse response) {
            String[] headerKeys = response.getHeaderKeys();
            if (headerKeys != null) {
                for (String key : headerKeys) {
                    this.headers.put(key, response.getHeader(key));
                }
            }

            this.statusCode = response.getStatusCode();
            this.status = response.getStatus();
            this.body = response.getBody();
        }
    }

}
