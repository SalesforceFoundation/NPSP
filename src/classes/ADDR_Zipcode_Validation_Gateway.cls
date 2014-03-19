/*
    Copyright (c) 2014, Salesforce.com Foundation
    All rights reserved.
    
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
    
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Salesforce.com Foundation nor the names of
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
* @author Salesforce.com Foundation
* @date 2014
* @description Base class that talks to the Zipcode verification API.
 */
public with sharing class ADDR_Zipcode_Validation_Gateway {

    Address_Authentication_Settings__c settings = Address_Authentication_Settings__c.getInstance();
    String baseUrl = 'https://api.smartystreets.com/zipcode';
    String auth;
    public class LiveAddressException extends Exception {}
    
    // Constructor with auth id and token
    public ADDR_Zipcode_Validation_Gateway( String authId, String authToken ) {
        auth = '?auth-id=' + authId + '&auth-token=' + EncodingUtil.URLEncode(authToken, 'UTF-8');
    }

    // Constructor with HTML Key only
    public ADDR_Zipcode_Validation_Gateway( String htmlKey ) {
        auth = '?auth-token=' + htmlKey;
    }

    public ADDR_Zipcode_Validation_Gateway() {
        if (settings.auth_id__c != null && settings.auth_token__c != null)
            auth = '?auth-id=' + settings.auth_id__c + '&auth-token=' + EncodingUtil.URLEncode(settings.auth_token__c, 'UTF-8');
        else if (settings.html_key__c != null)
            auth = '?auth-token=' + settings.html_key__c;
    }

    /* REQUEST DATA */
    public class Request {
        public String city;
        public String state;
        public String zipcode;

        public Request() {}
        
        public Request( String c, String s, String z ) {
            city = c;
            state = s;
            zipcode = z;
        }
    } 

    /* RESPONSE DATA */
    public class Response {
        public String status;
        public String reason;
        public list<CityState> city_states;     
        public list<ZipLoc> zipcodes;
    } 

    public class CityState {
        public String city;
        public String state_abbreviation;
        public String state;
    }

    public class ZipLoc {
        public String zipcode;
        public Double latitude;
        public Double longitude;
    }

    /* SINGLE RECORD VERIFY ZIP METHODS */
    public Response verifyZip( String zip ) { 
        return verifyZip( null, null, zip ); 
    }
    public Response verifyZip( String city, String state ) { 
        return verifyZip( city, state, null);   
    }   
    public Response verifyZip( String city, String state, String zip ) {
        list<Response> sz = verifyZips( new list<Request>{ new Request(city, state, zip) } );
        return ((sz == null) ? null : sz[0]);
    }

    /* MULTI-RECORD VERIFY ZIP METHOD */
    public list<Response> verifyZips( list<Request> zreqs ) {
        String js;
        if (zreqs == null || zreqs.isEmpty()) 
            return null;
        else if (zreqs.size() > 100)
            throw new LiveAddressException('You cannot verify more than 100 zipcodes at a time.');

      // prepare the request
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setHeader('Content-Type','application/json');
        req.setHeader('Accept','application/json');
        req.setEndpoint(baseUrl + auth);
        js = JSON.serialize( zreqs );
        //system.debug(LoggingLevel.WARN, js );
        req.setBody( js );
        req.setTimeout((settings.timeout__c == null) ? 5000 : (settings.timeout__c * 1000).intValue());
        //system.debug(LoggingLevel.WARN, req );

        // execute the request
        System.debug('****Request body: \n' + req.getBody());
        HttpResponse res = h.send(req);
        System.debug('****Response header: \n' + res);
        System.debug('****Response body: \n' + res.getBody());
        list<Response> sz;
        if (res.getStatusCode() == 200) {
            js = res.getBody();
            system.debug(LoggingLevel.WARN, js );
            sz = (list<Response>)(JSON.deserialize(js, list<Response>.class));
            //system.debug(LoggingLevel.WARN, sz );
        } else {
            throw new LiveAddressException( res.getStatus() );
        }
        return ((sz == null || sz.isEmpty()) ? null : sz);
    }
}