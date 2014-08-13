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
* @description Validator to provide address geocoding/verification through the Google Geocoding API
 */
public with sharing class ADDR_GoogleGeoAPI_Validator implements ADDR_IValidator{

    private String AUTH_TOKEN;
    private String END_POINT;
    private Double TIMEOUT;
    private List<Address__c> checked_addresses;

    public List<Address__c> verifyRecords(List<Address__c> addresses, Addr_Verification_Settings__c settings){

        this.checked_addresses = new List<Address__c>();
        this.AUTH_TOKEN = settings.Auth_Token__c;
        this.TIMEOUT = settings.Timeout__c;

        if (settings.Address_Verification_Endpoint__c != null)
            this.END_POINT = settings.Address_Verification_Endpoint__c;
        else
            this.END_POINT = 'https://maps.googleapis.com/maps/api/geocode/json?';

        
 //   Select a.Zipcode_Verification_Endpoint__c, a.Using_SmartyStreets__c, a.Timeout__c, a.Reject_Ambiguous_Addresses__c, a.Enable_Automatic_Verification__c, a.Class__c, a.Auth_Token__c, a.Auth_ID__c, a.Address_Verification_Endpoint__c From Addr_Verification_Settings__c a


        if (addresses.size() == 1){
            checked_addresses.add(verifyAddress(addresses[0]));
        }
        else{
            
        }
    	
    	
    	
        return checked_addresses;
    }

    private Address__c verifyAddress(Address__c a){
    
        String address_request_string = '';
        if (a.MailingStreet__c != null)
            address_request_string += a.MailingStreet__c.replace(' ', '+') + '+';
        if (a.MailingCity__c != null)
            address_request_string += a.MailingCity__c.replace(' ', '+') + '+';
        if (a.MailingState__c != null)
            address_request_string += a.MailingState__c.replace(' ', '+') + '+';
        if (a.MailingPostalCode__c != null)
            address_request_string += a.MailingPostalCode__c + '+';
        if (a.MailingCountry__c != null)
            address_request_string += a.MailingCountry__c;

        HttpResponse response = new HttpResponse();
            if(AUTH_TOKEN != null && END_POINT != null) {
            // prepare the request
            Http h = new Http();
            HttpRequest req = new HttpRequest();
            req.setMethod('GET');
            req.setHeader('Content-Type','application/json');
            req.setHeader('Accept','application/json');
            req.setEndpoint(END_POINT + 'address=' + address_request_string + '&key=' + AUTH_TOKEN); 
            req.setTimeout((TIMEOUT == null) ? 5000 : (TIMEOUT * 1000).intValue());
            // execute the request
            response = h.send(req);
            system.debug('GOOGLE RESPONDS WITH: ' + response.getBody());
            a.API_Response__c = response.getBody();
            ADDR_GoogleGeoAPI_Validator.GoogleGeoResponse googresp = (ADDR_GoogleGeoAPI_Validator.GoogleGeoResponse)JSON.deserialize(response.getBody(), ADDR_GoogleGeoAPI_Validator.GoogleGeoResponse.class);

            String verified_street = '';

            for (ADDR_GoogleGeoAPI_Validator.Address_components add : googresp.results[0].address_components){
                Set<String> type_set = new Set<String>();
                type_set.addAll(add.types);

                if(type_set.contains('postal_code')){
                    a.MailingPostalCode__c = add.long_name;
                } else if (type_set.contains('country')){
                    a.MailingCountry__c = add.short_name;
                } else if (type_set.contains('administratrive_area_level_1')){
                    a.MailingState__c = add.short_name;
                } else if (type_set.contains('administrative_area_level_2')){
                    a.County_Name__c = add.long_name;
                } else if (type_set.contains('street_number')){
                    verified_street = add.long_name + ' ' + verified_street;
                } else if (type_set.contains('route')){
                    verified_street += add.long_name;
                }else if (type_set.contains('intersection')){
                    verified_street += add.long_name;
                }else if (type_set.contains('locality')){
                    a.MailingCity__c = add.long_name;
                }
            }
            a.MailingStreet__c = verified_street;
            a.Geolocation__Latitude__s = googresp.results[0].geometry.location.lat;
            a.Geolocation__Longitude__s = googresp.results[0].geometry.location.lat;
            a.Verified__c = true;
            }
        return a;
    }

public class GoogleGeoResponse {
    public List<ADDR_GoogleGeoAPI_Validator.Results> results;
    public String status;
    
}
    public class Address_components {
        public String long_name;
        public String short_name;
        public List<String> types;
    }

    public class Location {
        public Double lat;
        public Double lng;
    }

    public class Geometry {
        public Location location;
        public String location_type;
        public Viewport viewport;
    }

    public class Results {
        public List<ADDR_GoogleGeoAPI_Validator.Address_components> address_components;
        public String formatted_address;
        public Geometry geometry;
        public List<String> types;
    }

    public class Viewport {
        public Location northeast;
        public Location southwest;
    }

    
    public static GoogleGeoResponse parse(String json) {
        return (GoogleGeoResponse) System.JSON.deserialize(json, GoogleGeoResponse.class);
    }
    
    
}