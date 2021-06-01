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
* @description Contains common Elevate payment services API tests
*/
@IsTest(IsParallel=true)
private with sharing class PS_Request_TEST {
    private static final String COMMITMENT_ID = RD2_ElevateIntegrationService_TEST.COMMITMENT_ID;

    /**
    * @description Verifies one-time Payments Purchase HttpRequest 
    */
    @isTest
    private static void shouldCreateHttpRequestWhenPaymentsPurchaseEndpoint() {
        PS_IntegrationService.setConfiguration(PS_IntegrationServiceConfig_TEST.testConfig);
        final String jsonRequestBody = 'purchase request body';

        Test.startTest();
        HttpRequest request = new PS_Request.Builder()
            .withMethod(UTIL_Http.Method.POST)
            .withEndpoint(PS_Request.ElevateEndpoint.PURCHASE)
            .withBody(jsonRequestBody)
            .build();
        Test.stopTest();

        final String expectedEndpoint = PS_IntegrationServiceConfig_TEST.testBaseUrl
            + PS_Request.ENDPOINT_PURCHASE;

        assertRequest(request, expectedEndpoint, UTIL_Http.Method.POST, jsonRequestBody);
    }

    /**
    * @description Verifies Commitment creation HttpRequest 
    */
    @isTest
    private static void shouldCreateHttpRequestWhenCreateCommitmentEndpoint() {
        PS_IntegrationService.setConfiguration(PS_IntegrationServiceConfig_TEST.testConfig);
        final String jsonRequestBody = 'commitment request body';

        Test.startTest();
        HttpRequest request = new PS_Request.Builder()
            .withMethod(UTIL_Http.Method.POST)
            .withEndpoint(PS_Request.ElevateEndpoint.COMMITMENT)
            .withBody(jsonRequestBody)
            .build();
        Test.stopTest();

        final String expectedEndpoint = PS_IntegrationServiceConfig_TEST.testBaseUrl
            + PS_Request.ENDPOINT_COMMITMENT;

        assertRequest(request, expectedEndpoint, UTIL_Http.Method.POST, jsonRequestBody);
    }

    /**
    * @description Verifies Cancel Commitment HttpRequest 
    */
    @isTest
    private static void shouldCreateHttpRequestWhenCancelCommitmentEndpoint() {
        PS_IntegrationService.setConfiguration(PS_IntegrationServiceConfig_TEST.testConfig);

        Test.startTest();
        HttpRequest request = new PS_Request.Builder()
            .withMethod(UTIL_Http.Method.POST)
            .withEndpoint(PS_Request.ElevateEndpoint.COMMITMENT_CANCEL)
            .withCommitmentId(COMMITMENT_ID)
            .build();
        Test.stopTest();

        final String jsonRequestBody = '';
        final String expectedEndpoint = PS_IntegrationServiceConfig_TEST.testBaseUrl
            + String.format(
            PS_Request.ENDPOINT_COMMITMENT_CANCEL,
            new String[]{ COMMITMENT_ID }
        );

        assertRequest(request, expectedEndpoint, UTIL_Http.Method.POST, jsonRequestBody);
    }

    /**
    * @description Verifies Cancel Commitment HttpRequest
    */
    @isTest
    private static void shouldCreateHttpRequestWhenCommitmentEndpointWithId() {
        PS_IntegrationService.setConfiguration(PS_IntegrationServiceConfig_TEST.testConfig);

        Test.startTest();
        HttpRequest request = new PS_Request.Builder()
            .withMethod(UTIL_Http.Method.GET)
            .withEndpoint(PS_Request.ElevateEndpoint.COMMITMENT)
            .withCommitmentId(COMMITMENT_ID)
            .build();
        Test.stopTest();

        final String jsonRequestBody = '';
        final String expectedEndpoint = PS_IntegrationServiceConfig_TEST.testBaseUrl
            + PS_Request.ENDPOINT_COMMITMENT + '/' + COMMITMENT_ID;

        assertRequest(request, expectedEndpoint, UTIL_Http.Method.GET, jsonRequestBody);
    }

    /**
    * @description Verifies JSON Web Token "sfdo.roles" param is set based on the endpoint
    */
    @isTest
    private static void shouldSetSfdoRolesSpecificToTheEndpoint() {
        final String sfdoId = 'test id';

        for (PS_Request.ElevateEndpoint endpoint : PS_Request.ElevateEndpoint.values()) {
            String roles;
            if (endpoint == PS_Request.ElevateEndpoint.TOKENIZE) {
                roles = PS_Request.ROLE_PAYMENT_TOKENS;
            } else if (endpoint == PS_Request.ElevateEndpoint.PURCHASE) {
                roles = PS_Request.ROLE_PAYMENT_PURCHASE;

            } else if (endpoint == PS_Request.ElevateEndpoint.COMMITMENT
                || endpoint == PS_Request.ElevateEndpoint.COMMITMENT_CANCEL) {

                roles = PS_Request.ROLE_PAYMENT_COMMITMENTS;
            } else if (endpoint == PS_Request.ElevateEndpoint.ADD_TO_ELEVATE_BATCH
                || endpoint == PS_Request.ElevateEndpoint.CREATE_ELEVATE_BATCH
                || endpoint == PS_Request.ElevateEndpoint.CHARGE_ELEVATE_BATCH) {

                roles = PS_Request.ROLE_PAYMENT_BATCH;
            }

            String jwtPayload = new PS_Request.JWTPayload(sfdoId, endpoint).getAsString();
            System.assert(jwtPayload.contains(roles), 
                'JSON Web Token for ' + endpoint.name() + ' should contain expected roles: ' + jwtPayload);
        }
    }

    /**
    * @description Verifies generate JSON Web Token 
    */
    @isTest
    private static void shouldGenerateJSONWebToken() {
        final String sfdoId = 'test id';
        PS_Request.ElevateEndpoint endpoint = PS_Request.ElevateEndpoint.PURCHASE;
        PS_Request.JWTPayload jwtPayload = new PS_Request.JWTPayload(sfdoId, endpoint);

        Map<String, String> valueByParam = new Map<String, String>{
            PS_Request.JWT_ISSUER_PARAM => 'ApiKeyManager',
            PS_Request.JWT_EXPIRES_AT_PARAM => String.valueOf(jwtPayload.getExpirationDate(1)),
            PS_Request.JWT_SUBJECT_PARAM => UserInfo.getUserName(),
            PS_Request.JWT_SFDO_ID_PARAM => sfdoId,
            PS_Request.JWT_PRODUCT_PARAM => PS_Request.ProductType.CRM.name(),
            PS_Request.JWT_ROLES_PARAM => PS_Request.ROLE_PAYMENT_PURCHASE
        };

        JSONParser parser = JSON.createParser(jwtPayload.getAsString());        
        while (parser.nextToken() != null) {
            if (parser.getCurrentToken() == JSONToken.FIELD_NAME) {
                String param = parser.getText();

                parser.nextToken();
                String value = parser.getText();

                String expectedValue = valueByParam.get(param);
                System.assertEquals(expectedValue, value, 'JSON Web Token param (' + param + ') value should match');
            }
        } 
    }


    // Helpers
    /////////////

    /**
    * @description Verifies HttpRequest is as expected
    * @param request HttpRequest to verify
    * @param endpoint Expected Elevate API endpoint
    * @param method Expected HttpRequest method
    * @param jsonRequestBody Expected HttpRequest body
    * @return void
    */
    private static void assertRequest(HttpRequest request, String endpoint, UTIL_Http.Method method, String jsonRequestBody) {
        System.assertEquals(endpoint, request.getEndpoint(), 'Endpoint should match');
        System.assertEquals(method.name(), request.getMethod(), 'The HttpRequest method should match');

        System.assertEquals(
            UserInfo.getUserName(), 
            request.getHeader(PS_IntegrationServiceConfig.SFDO_USERNAME),
            'User name should be specified in the request header'
        );
        System.assertEquals(
            PS_IntegrationServiceConfig_TEST.testMerchantId, 
            request.getHeader(PS_IntegrationServiceConfig.SFDO_MERCHANTIDS),
            'Merchant Id should be specified in the request header'
        );
        System.assertNotEquals(
            null, 
            request.getHeader(PS_IntegrationServiceConfig.JWT_TOKEN), 
            'JSON Web Token should be specified in the request header'
        );
        
        System.assertEquals(jsonRequestBody, request.getBody(), 'Request body should match');
    }

}
