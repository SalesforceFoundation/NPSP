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
@isTest
public with sharing class PS_ElevateAPI_TEST {
    public static final String COMMITMENT_ID = '0009989378376210918302112371207242332342432';

    public static final String RESPONSE_OK = 'OK';
    public static final Integer RESPONSE_CODE_SUCCESS = 200;

    /**
    * @description Verifees that the Endpoint is set correctly for Cancelm Commitment callout 
    */
    @isTest
    private static void shouldCreateHttpRequestWhenEndpointIsCommitmentCancel() {
        PS_IntegrationService.setConfiguration(PS_IntegrationServiceConfig_TEST.testConfig);

        Test.startTest();
        HttpRequest request = new PS_ElevateAPI.RequestBuilder()
            .withMethod(PS_ElevateAPI.HttpRequestMethod.POST)
            .withEndpoint(PS_ElevateAPI.ElevateEndpoint.COMMITMENT_CANCEL)
            .withCommitmentId(COMMITMENT_ID)
            .build();
        Test.stopTest();

        String expectedEndpoint = PS_IntegrationServiceConfig_TEST.testBaseUrl 
            + '/v1/payments/verified/commitments/' 
            + COMMITMENT_ID 
            + '/cancel';

        System.assertEquals(expectedEndpoint, request.getEndpoint(), 
            'Endpoint value should match');
        System.assertEquals(PS_ElevateAPI.HttpRequestMethod.POST.name(), request.getMethod(), 
            'The request method should be POST');
        System.assertEquals(UserInfo.getUserName(), request.getHeader(PS_IntegrationServiceConfig.SFDO_USERNAME),
            'User name should be specified in the request header');
    }

    /**
    * @desciprtion Verifies response is correctly formatted based on HttpResponse
    */
    @isTest
    private static void shouldPopulateResponseWhenHttpResponseIsReturned() {
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://test.com');
        request.setHeader('Content-Type', 'application/json;charset=UTF-8');
        request.setMethod('POST');

        String body = '{"value" : "success"}';
        CalloutMock callout = new CalloutMock()
            .withStatusCode(RESPONSE_CODE_SUCCESS)
            .withStatus(RESPONSE_OK)
            .withBody(body);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, callout);

        PS_ElevateAPI api = new PS_ElevateAPI();
        PS_ElevateAPI.ResponseWrapper response = api.sendRequest(request);
        Test.stopTest();

        System.assertEquals(RESPONSE_CODE_SUCCESS, response.statusCode, 
            'The response status code should be populated');
        System.assertEquals(RESPONSE_OK, response.status, 
            'The response status should be populated');
        System.assertEquals(body, response.body, 
            'The response body should be populated');
    }

    /**
    * @description Verifies the timed out exception is correctly handled in the error response
    */
    @isTest
    private static void shouldConstructTimedOutResponseWhenExceptionIsGenerated() {
        String errorMessage = 'test callout timed out';
        System.CalloutException ex = new System.CalloutException(errorMessage);

        Test.startTest();
        PS_ElevateAPI api = new PS_ElevateAPI();
        PS_ElevateAPI.ResponseWrapper response = api.buildErrorResponse(ex);
        Test.stopTest();

        System.assertEquals(PS_ElevateAPI.TIMEOUT_STATUS_CODE, response.statusCode,
            'The status code should be set to timed out status code');
        System.assertEquals(PS_ElevateAPI.TIMED_OUT_STATUS, response.status,
            'The status should be set to timed out status');
        System.assert(response.body.contains(errorMessage),
            'The exception message should be returned in the response body: ' + response.body);
    }

    /**
    * @description Verifies the exception is correctly handled in the error response
    */
    @isTest
    private static void shouldConstructErrorResponseWhenExceptionIsGenerated() {
        String errorMessage = 'HttpRequest failed';
        System.DMLException ex = new System.DMLException(errorMessage);

        Test.startTest();
        PS_ElevateAPI api = new PS_ElevateAPI();
        PS_ElevateAPI.ResponseWrapper response = api.buildErrorResponse(ex);
        Test.stopTest();

        System.assertEquals(PS_ElevateAPI.BAD_REQUEST_STATUS_CODE, response.statusCode,
            'The status code should be set to bad request status code');
        System.assertEquals(System.Label.commonUnknownError, response.status,
            'The status should be set to unknown error');
        System.assert(response.body.contains(errorMessage),
            'The exception message should be returned in the response body: ' + response.body);
    }

    /**
    * @description Elevate Callout Mock
    */
    public class CalloutMock implements HttpCalloutMock {
        Integer statusCode;
        String body;
        String status;

        /**
        * @description Constructor
        */
        public CalloutMock() {
            //set defaults
            status = RESPONSE_OK;
            statusCode = RESPONSE_CODE_SUCCESS;
        }

        /**
        * @description Set the response body
        * @param body The body JSON of the returned mock response
        * @return CalloutMock
        */
        public CalloutMock withBody(String body) {
            this.body = body;
            return this;
        }

        /**
        * @description Set the response status code
        * @param statusCode The status code of the returned mock response
        * @return CalloutMock
        */
        public CalloutMock withStatusCode(Integer statusCode) {
            this.statusCode = statusCode;
            return this;
        }

        /**
        * @description Set the response status code
        * @param status The status of the returned mock response
        * @return CalloutMock
        */
        public CalloutMock withStatus(String status) {
            this.status = status;
            return this;
        }

        /**
        * @description HttpCalloutMock Interface method to return the response
        * @param request The request that is sent
        * @return HttpResponse
        */
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setStatusCode(statusCode);
            response.setStatus(status);

            if (body != null) {
                response.setBody(body);
            }

            return response;
        }        
    }
}
