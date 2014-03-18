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
* @description Base class that talks to the address verification API.
 */
public with sharing class ADDR_Validation_Gateway {

    Address_Authentication_Settings__c settings = Address_Authentication_Settings__c.getInstance();
    String baseUrl = 'https://api.smartystreets.com/street-address';
    String auth;
    
    public class LiveAddressException extends Exception {}
    
    // Constructor with auth id and token
    public ADDR_Validation_Gateway( String authId, String authToken ) {
        auth = '?auth-id=' + authId + '&auth-token=' + EncodingUtil.URLEncode(authToken, 'UTF-8');
    }

    // Constructor with HTML Key only - works for a single domain
    public ADDR_Validation_Gateway( String htmlKey ) {
        auth = '?auth-token=' + htmlKey;
    }

    public ADDR_Validation_Gateway() {
        if (settings.auth_id__c != null && settings.auth_token__c != null)
            auth = '?auth-id=' + settings.auth_id__c + '&auth-token=' + EncodingUtil.URLEncode(settings.auth_token__c, 'UTF-8');
        else if (settings.html_key__c != null)
            auth = '?auth-token=' + settings.html_key__c;
    }

    /* SINGLE RECORD VERIFY ADDRESS METHODS */
    public Response verifyAddress( String address ) {
        return verifyAddress( new Request(address) );
    }
    public Response verifyAddress( Request address ) {
        list<Response> sr = verifyAddresses( new list<Request>{ address } );
        return ((sr == null) ? null : sr[0]);
    }

    /* MULTI-RECORD VERIFY ADDRESS METHODS */
    public list<Response> verifyAddresses( list<String> addresses ) {
        list<Request> requests = new list<Request>();
        for (String addr : addresses)
            requests.add( new Request(addr) );
        return verifyAddresses( requests );
    }
    public list<Response> verifyAddresses( list<Request> addresses ) {
        System.debug('****Addresses to verify: ' + JSON.serializePretty(addresses));
        String js;
        if (addresses == null || addresses.isEmpty()) 
            return null;
        else if (addresses.size() > 100)
            throw new LiveAddressException(Label.Address_Verification_Limit);

      // prepare the request
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setHeader('Content-Type','application/json');
        req.setHeader('Accept','application/json');
        req.setEndpoint(baseUrl + auth);
        js = JSON.serialize( addresses );
        //system.debug(LoggingLevel.WARN, js );
        req.setBody( js );
        req.setTimeout((settings.timeout__c == null) ? 5000 : (settings.timeout__c * 1000).intValue());
        //system.debug(LoggingLevel.WARN, req );

        // execute the request
        System.debug('****Request body: \n' + req.getBody());
        HttpResponse res = h.send(req);
        System.debug('****Response header: \n' + res);
        System.debug('****Response body: \n' + res.getBody());
        list<Response> sr;
        if (res.getStatusCode() == 200) {
            js = res.getBody();
            sr = (list<Response>)(JSON.deserialize(js, list<Response>.class));
            system.debug('****Fixed addresses: ' + sr);
        } else {
            throw new LiveAddressException( res.getStatus() );
        }
        if (sr == null || sr.isEmpty()) {
            return null;
        } else {
            //system.debug( LoggingLevel.INFO, sr[0].getFullAddress() );
            return sr; 
        }
    }
    
    public class Request {
    	
    	public String street;           // REQUIRED - Can be full address, or just first line
	    public String street2;
	    public String secondary;        // If used, usually contains apartment or suite number.
	    public String city;
	    public String state;
	    public String urbanization;     // Only used with Puerto Rican addresses.
	    public String zipcode;          
	    public String addressee;        // The recipient's name or FirmName. Can also be the company.
	    public Integer candidates = 1;  // The maximum number of valid addresses returned when the  
	                                    //   input address is ambiguous (max = 10, default = 1).
		
		public Request() {}
		
	    public Request(String address) {
	        street = address;
	    }
    }
    
    public class Response {

	    public Integer input_index;      // The order in which this address was submitted
	    public Integer candidate_index;  // Index when there are multiple addresses returned
	    public String addressee;         // Company name or intended recipient
	    public String delivery_line_1;  // Verified street address
	    public String delivery_line_2;
	    public String last_line;            // City, state, and ZIP code combined
	    public String delivery_point_barcode;
	    public Components components;
	    public Metadata metadata;
	    public Analysis analysis;
	
	    public String getFullAddress() {
	        return (((addressee != null) ? (addressee + '\n') : '') + ((delivery_line_1 != null) ? (delivery_line_1 + '\n') : '') + 
	            ((delivery_line_2 != null) ? (delivery_line_2 + '\n') : '') + ((last_line != null) ? (last_line) : '')).trim();
	    }
	}
	
	public class Components {
        public String primary_number;   // The house, PO box, or building number
        public String street_name;
        public String street_predirection;
        public String street_postdirection;
        public String street_suffix;
        public String secondary_number;
        public String secondary_designator;
        public String pmb_designator;
        public String pmb_number;
        public String city_name;
        public String state_abbreviation;
        public String zipcode;
        public String plus4_code;
        public String delivery_point;
        public String delivery_point_check_digit;
    }
    
    public class Metadata {
        public String record_type;
        public String county_fips;
        public String county_name;
        public String carrier_route;
        public String building_default_indicator;
        public String congressional_district;
        public String rdi;
        public Double latitude;
        public Double longitude;
        public String precision;
    }
    
    public class Analysis {
        public String dpv_match_code;
        public String dpv_footnotes;
        public String dpv_cmra;
        public String dpv_vacant;
        public String active;
        public String ews_match;
        public String footnotes;
        public String lacslink_code;
        public String lacslink_indicator;
    }
}