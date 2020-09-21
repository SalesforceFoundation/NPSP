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
* @group Utilities
* @description Contains common HttpRequest and HttpResponse constants and methods
*/
public with sharing class UTIL_Http {
    public static final Integer STATUS_CODE_OK = 200;
    public static final Integer STATUS_CODE_CREATED = 201;
    public static final Integer STATUS_CODE_BAD_REQUEST = 400;
    public static final Integer STATUS_CODE_REQUEST_TIMEOUT = 408;

    public static final String STATUS_OK = 'OK';
    public static final String STATUS_TIMED_OUT = 'Request Timeout';
    
    public static final String TIMED_OUT_MESSAGE = 'timed out';

    public enum Method {
        GET, POST, PATCH
    }

    /***
    * @description Contains method to send the HttpRequest and parse its response
    */
    public with sharing class RequestService {

        /***
        * @description Sends an HttpRequest 
        * @param request HttpRequest
        * @return Response HttpResponse wrapper
        */
        public Response sendRequest(HttpRequest request) {
            HttpResponse response = new Http().send(request);
            return new Response(response);
        }

        /***
        * @description Creates an error response for an exception
        * @param ex An unexpected exception
        * @return Response HttpResponse wrapper
        */
        public Response buildErrorResponse(Exception ex) {
            return isTimeout(ex)
                ? buildTimeoutResponse(ex)
                : buildBadRequestResponse(ex);
        }

        /***
        * @description Checks if the exception is generated due to a callout timeout
        * @param ex An unexpected exception
        * @return Boolean Indicates if the exception is generated due to the callout timeout
        */
        public Boolean isTimeout(Exception ex) {
            Boolean isCalloutException = ex instanceof System.CalloutException;
            return isCalloutException && ex.getMessage().contains(TIMED_OUT_MESSAGE);
        }

        /***
        * @description Creates a timeout error response
        * @param ex An unexpected exception
        * @return Response HttpResponse wrapper
        */
        public Response buildTimeoutResponse(Exception ex) {
            Response response = new Response();
            response.statusCode = STATUS_CODE_REQUEST_TIMEOUT;
            response.status = STATUS_TIMED_OUT;
            response.body = new ErrorResponseBody()
                .withError(ex.getMessage())
                .getAsJson();

            return response;
        }

        /***
        * @description Creates an exception error response
        * @param ex An unexpected exception
        * @return Response HttpResponse wrapper
        */
        public Response buildBadRequestResponse(Exception ex) {
            Response response = new Response();
            response.statusCode = STATUS_CODE_BAD_REQUEST;
            response.status = System.Label.commonUnknownError;
            response.body = new ErrorResponseBody()
                .withError(ex.getMessage())
                .getAsJson();

            return response;
        }
    }

    /***
    * @description Returns contents of the HttpResponse since it
    * cannot be directly serialized using JSON.serialize().
    */
    public with sharing class Response {
        public Map<String, Object> headers = new Map<String, Object>{};
        public Integer statusCode;
        public String status;
        public String body;

        /***
        * @description Default Constructor
        */
        public Response() {}

        /***
        * @description Constructor
        * @param response HttpResponse
        */
        public Response(HttpResponse response) {
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

    /***
    * @description Contains all error messages to be returned in the response
    */
    public with sharing class ErrorResponseBody {
        public List<Error> errors = new List<Error>();

        /***
        * @description Adds an error with the specified message
        * @param message An error message
        * @return ErrorResponseBody This error response body instance
        */
        public ErrorResponseBody withError(String message) {
            return withError(new Error(message));
        }

        /***
        * @description Adds an error
        * @param err An error
        * @return ErrorResponseBody This error response body instance
        */
        public ErrorResponseBody withError(Error err) {
            this.errors.add(err);
            return this;
        }

        /***
        * @description Returns the error response body JSON string
        * @return String
        */
        public String getAsJson() {
            return JSON.serialize(this);
        }
    }

    /***
    * @description Contains an error message
    */
    public with sharing class Error {
        public String message;

        /***
        * @description Constructor
        * @param message An error message
        */
        public Error(String message) {
            this.message = message;
        }
    }
}
