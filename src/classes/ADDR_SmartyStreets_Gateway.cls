/*
    Copyright (c) 2014, Salesforce.com Foundation
    All rights reserved.
    
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
    
    * Redistributions of source code must retain the above copyright
      notice, this List of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this List of conditions and the following disclaimer in the
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
* @description Class that talks to the SmartyStreets address verification API.
 */
public with sharing class ADDR_SmartyStreets_Gateway {

    private Address_Verification_Settings__c settings;
    private String auth;
    
    public class LiveAddressException extends Exception {}

    public ADDR_SmartyStreets_Gateway(Address_Verification_Settings__c settings) {
        this.settings = settings;
        
        if (settings.auth_id__c != null && settings.auth_token__c != null)
            auth = '?auth-id=' + settings.auth_id__c + '&auth-token=' + EncodingUtil.URLEncode(settings.auth_token__c, 'UTF-8');
        else if (settings.html_key__c != null)
            auth = '?auth-token=' + settings.html_key__c;
    }

    /* SINGLE RECORD VERIFY ADDRESS METHODS */
    public AddressResponse verifyAddress(String address) {
        return verifyAddress(new AddressRequest(address));
    }
    public AddressResponse verifyAddress(AddressRequest address) {
        List<AddressResponse> sr = verifyAddresses(new List<AddressRequest>{address});
        return ((sr == null) ? null : sr[0]);
    }

    /* MULTI-RECORD VERIFY ADDRESS METHODS */
    public List<AddressResponse> verifyAddresses(List<String> addresses) {
        List<AddressRequest> requests = new List<AddressRequest>();
        for (String addr : addresses)
            requests.add(new AddressRequest(addr));
        return verifyAddresses(requests);
    }
    public List<AddressResponse> verifyAddresses(List<AddressRequest> addresses) {

        if (addresses == null || addresses.isEmpty()) 
            return null;
        else if (addresses.size() > 100) //This is a smartyStreets limit
            throw new LiveAddressException(Label.Address_Verification_Limit);
        
        // send the request
        HttpResponse res = prepareRequest(addresses, settings.Address_Verification_Endpoint__c);

        List<AddressResponse> sr;
        if (res.getStatusCode() == 200)
            sr = (List<AddressResponse>)(JSON.deserialize(res.getBody(), List<AddressResponse>.class));
        else
            throw new LiveAddressException(res.getStatus());
        
        if (sr == null || sr.isEmpty()) return null;
        else return sr; 
    }
    
    /* SINGLE RECORD VERIFY ZIP METHODS */
    public ZipResponse verifyZip(String zip) { 
        return verifyZip(null, null, zip); 
    }
    public ZipResponse verifyZip(String city, String state) { 
        return verifyZip(city, state, null);   
    }   
    public ZipResponse verifyZip(String city, String state, String zip) {
        list<ZipResponse> sz = verifyZips(new list<ZipRequest>{ new ZipRequest(city, state, zip) });
        return ((sz == null) ? null : sz[0]);
    }

    /* MULTI-RECORD VERIFY ZIP METHOD */
    public list<ZipResponse> verifyZips(list<ZipRequest> zreqs) {

        if (zreqs == null || zreqs.isEmpty()) 
            return null;
        else if (zreqs.size() > 100)
            throw new LiveAddressException(Label.Zipcode_Verification_Limit);
        
        // send the request
        HttpResponse res = prepareRequest(zreqs, settings.Zipcode_Verification_Endpoint__c);

        list<ZipResponse> sz;
        if (res.getStatusCode() == 200)
            sz = (list<ZipResponse>)(JSON.deserialize(res.getBody(), list<ZipResponse>.class));
        else
            throw new LiveAddressException(res.getStatus());
        
        if (sz == null || sz.isEmpty()) return null;
        else return sz;
    }
    
    private HTTPResponse prepareRequest(List<Object> payload, String baseURL) {
    	// prepare the request
        Http h = new Http();
    	String body = JSON.serialize(payload);
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setHeader('Content-Type','application/json');
        req.setHeader('Accept','application/json');
        req.setEndpoint(baseURL + auth);  
        req.setBody(body);
        req.setTimeout((settings.timeout__c == null) ? 5000 : (settings.timeout__c * 1000).intValue());
        System.debug('****Request body: \n' + req.getBody());
        // execute the request
        HttpResponse res = h.send(req);
        System.debug('****Response body: \n' + res.getBody());
        return res;
    }
    
    /* ADDRESS REQUEST DATA */
    public class AddressRequest {
        
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
        
        public AddressRequest() {}
        
        public AddressRequest(String address) {
            street = address;
        }
    }
    
    /* ADDRESS RESPONSE DATA */
    public class AddressResponse {

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
    
    /* ZIP REQUEST DATA */
    public class ZipRequest {
        public String city;
        public String state;
        public String zipcode;

        public ZipRequest() {}
        
        public ZipRequest(String c, String s, String z) {
            city = c;
            state = s;
            zipcode = z;
        }
    }
    
    /* ZIP RESPONSE DATA */
    public class ZipResponse {
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
}