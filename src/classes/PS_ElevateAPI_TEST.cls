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
    /**
    * @description Verifees that the Endpoint is set correctly for Cancelm Commitment callout 
    */
    @isTest
    private static void shouldCreateCancelHttpRequestWhenActionIsCancelled() {
        PS_IntegrationService.setConfiguration(PS_IntegrationServiceConfig_TEST.testConfig);
        String commitmentId = 'abcd-efgh-ijkl-mnop-qrst';

        Test.startTest();
        HttpRequest httpRequest = new PS_ElevateAPI.RequestBuilder()
            .withMethod(PS_ElevateAPI.HttpRequestMethod.POST)
            .withEndpoint(PS_ElevateAPI.ElevateEndpoint.COMMITMENT_CANCEL)
            .withCommitmentId(commitmentId)
            .build();
        Test.stopTest();

        String expectedEndpoint = PS_IntegrationServiceConfig_TEST.testBaseUrl + '/v1/payments/verified/commitments/' + commitmentId + '/cancel';
        System.assertEquals(expectedEndpoint, httpRequest.getEndPoint(), 'Cancel API url should be set as the http request end point');
        System.assertEquals(PS_ElevateAPI.HttpRequestMethod.POST.name(), httpRequest.getMethod(), 'The Http request should been set to POST method');
        System.assertEquals(UserInfo.getUserName(), httpRequest.getHeader(PS_IntegrationServiceConfig.SFDO_USERNAME),
            'Current User info should be set in the header file');
    }

    /**
    * @desciprtion Verifies that the http respond is correctly format 
    */
    @isTest
    private static void shouldSuccessfullyCalloutAndFormatHttpResponse() {
        String body = '{"Value" : "Success"}';
        MockElevateHttpResponse mockHttpRespons = new MockElevateHttpResponse()
            .withStatusCode(200)
            .withStatus('OK')
            .withBody(body);

        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://test.com');
        request.setHeader('Content-Type', 'application/json;charset=UTF-8');
        request.setMethod('POST');

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, mockHttpRespons);

        PS_ElevateAPI apiService = new PS_ElevateAPI();
        PS_ElevateAPI.ResponseWrapper returnWrapper = apiService.sendRequest(request);
        Test.stopTest();

        System.assertEquals(200, returnWrapper.statusCode, 'The reponse status code should be populated');
        System.assertEquals('OK', returnWrapper.status, 'The reponse status should be populated');
        System.assertEquals(body, returnWrapper.body, 'The reponse body should be populated');
    }

    /**
    * @description HttpCalloutMock interface to Mock Elevate http response
    */
    public class MockElevateHttpResponse implements HttpCalloutMock {
        Integer statusCode;
        String body;
        String status;

        /**
        * @description Set the response body
        * @param body The body JSON of the returned mock response
        * @return MockElevateHttpResponse
        */
        public MockElevateHttpResponse withBody(String body) {
            this.body = body;
            return this;
        }

        /**
        * @description Set the reponse status code
        * @param statusCode The status code of the returned mock response
        * @return MockElevateHttpResponse
        */
        public MockElevateHttpResponse withStatusCode(Integer statusCode) {
            this.statusCode = statusCode;
            return this;
        }

        /**
        * @description Set the reponse status code
        * @param status The status of the returned mock response
        * @return MockElevateHttpResponse
        */
        public MockElevateHttpResponse withStatus(String status) {
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
            response.setStatusCode( (statusCode != null) ? statusCode : 200 );
            response.setStatus((status != null) ? status : 'OK');
            if (body != null) {
                response.setBody(body);
            }
            return response;
        }
        
    }
}

