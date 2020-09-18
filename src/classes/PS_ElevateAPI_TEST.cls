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
    * @description HttpCalloutMock interface to Mock Elevate http response
    */
    public class MockElevateHttpResponse implements HttpCalloutMock {
        Integer statusCode;
        String body;

        /**
        * @description Set the response body
        * @param body The body JSON of the returned mock response
        * @return MockElevateHttpResponse
        */
        public MockElevateHttpResponse setMockBody(String body) {
            this.body = body;
            return this;
        }

        /**
        * @description Set the reponse status code
        * @param statusCode The status code of the returned mock response
        * @return MockElevateHttpResponse
        */
        public MockElevateHttpResponse setReturnStatusCode(Integer statusCode) {
            this.statusCode = statusCode;
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
            if (body != null) {
                response.setBody(body);
            }
            return response;
        }
        
    }
}

