/*
    Copyright (c) 2017 Salesforce.org
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
* @date 2017
* @group Getting Started
* @description Base HTTP Client.
*/
public with sharing virtual class RP_HTTPClient {

    public Boolean remoteSiteSettingIsNotActive {get; set;}

    protected HttpRequest request;

    //Set common information for each client implemented
    public RP_HTTPClient() {

        request = new HttpRequest();
        request.setTimeout(10000);
        request.setMethod('GET');
        request.setHeader('Content-Type', 'application/json');
    }

    /*******************************************************************************************************
    * @description send a request to the any service according its endpoint value
    * @return HttpResponse
    */
    public HttpResponse send() {

        try {

            Http http = new Http();
            HttpResponse response = http.send(request);

            return response;
        }
        catch(exception e) {

            String message = e.getMessage();

            if (message.contains('Unauthorized endpoint')) {

                remoteSiteSettingIsNotActive = true;
            }

            return null;
        }
    }
}