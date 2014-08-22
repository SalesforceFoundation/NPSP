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

    public Boolean supportsBatch(){return false;}
    public String getServiceName(){return 'The Google Geocoding API';} 
    public String getDefaultURL(){return 'https://maps.googleapis.com/maps/api/geocode/json?';}
    public String getHelpText(){return Label.Addr_Verify_Google_Help;}
    public String getBatchHelpText() { return Label.Addr_Verification_Batch_Not_Supported;}

    public List<Address__c> verifyRecords(List<Address__c> addresses, Addr_Verification_Settings__c settings){

        this.checked_addresses = new List<Address__c>();
        this.AUTH_TOKEN = settings.Auth_Token__c;
        this.TIMEOUT = settings.Timeout__c;

        if (settings.Address_Verification_Endpoint__c != null)
            this.END_POINT = settings.Address_Verification_Endpoint__c;
        else
            this.END_POINT = 'https://maps.googleapis.com/maps/api/geocode/json?';

        if (!addresses.isEmpty()){
            for (Address__c a : addresses){
                checked_addresses.add(verifyAddress(a));
            }
        }
        return checked_addresses;
    }

    private Address__c verifyAddress(Address__c a){

        String address_request_string = '';
        if (a.MailingStreet__c != null)
            address_request_string += a.MailingStreet__c.replace(' ', '+') + '+';
        if (a.MailingStreet2__c != null)
            address_request_string += a.MailingStreet2__c.replace(' ', '+') + '+';
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
            Http h = new Http();
            HttpRequest req = new HttpRequest();
            req.setMethod('GET');
            req.setHeader('Accept','application/json');
            req.setEndpoint(END_POINT + 'address=' + address_request_string + '&key=' + AUTH_TOKEN); 
            try{
                response = h.send(req);
            } catch (Exception e){
                a.Verified__c = false;
                a.API_Response__c = 'REQUEST FAILED.  MESSAGE: ' + e.getMessage() + '\nSTACKTRACE:\n' + e.getStackTraceString();
            }

            if (response.getStatusCode() == 200){
                ADDR_GoogleGeoAPI_Validator.GoogleGeoResponse googresp = new ADDR_GoogleGeoAPI_Validator.GoogleGeoResponse();
                try{
                    googresp = (ADDR_GoogleGeoAPI_Validator.GoogleGeoResponse)JSON.deserialize(response.getBody(), ADDR_GoogleGeoAPI_Validator.GoogleGeoResponse.class);
                }catch (Exception e){
                    a.Verified__c = false;
                    a.API_Response__c = 'BAD JSON PARSE.  MESSAGE: ' + e.getMessage() + '\nSTACKTRACE:\n' + e.getStackTraceString();
                }

                String verified_street = '';
                if (googresp.status == 'OK' && googresp.results.size() == 1){

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
                        } else if (type_set.contains('administrative_area_level_3')){
                            a.Administrative_Area__c = add.long_name;
                        } else if (type_set.contains('street_number')){
                            verified_street = add.long_name + ' ' + verified_street;
                        } else if (type_set.contains('route')){
                            verified_street += add.long_name;
                        } else if (type_set.contains('intersection')){
                            verified_street += add.long_name;
                        } else if (type_set.contains('locality')){
                            a.MailingCity__c = add.long_name;
                        }
                    }
                    a.MailingStreet__c = verified_street;
                    ADDR_Addresses_TDTM.handleMultilineStreet(a);                    
                    a.Geolocation__Latitude__s = googresp.results[0].geometry.location.lat;
                    a.Geolocation__Longitude__s = googresp.results[0].geometry.location.lat;
                    a.Verified__c = true;
                    a.API_Response__c = response.getBody();
                } else if (googresp.status == 'OK' && googresp.results.size() > 1){
                    a.Ambiguous__c = true;
                    a.Verified__c = false;
                    a.API_Response__c = response.getBody();
                } else if (googresp.status == 'OVER_QUERY_LIMIT'){
                    a.Verified__c = false;
                    a.API_Response__c = 'OVER_QUERY_LIMIT: indicates that you are over your quota.';
                } else if (googresp.status == 'REQUEST_DENIED'){
                    a.Verified__c = false;
                    a.API_Response__c = 'REQUEST_DENIED: indicates that your request was denied.';
                } else if (googresp.status == 'UNKNOWN_ERROR'){
                    a.Verified__c = false;
                    a.API_Response__c = 'UNKNOWN_ERROR: indicates that the request could not be processed due to a server error. The request may succeed if you try again.';
                } else if (googresp.status == 'INVALID_REQUEST'){
                    a.Verified__c = false;
                    a.API_Response__c = 'INVALID_REQUEST: generally indicates that the query (address, components or latlng) is missing.';
                } else if (googresp.status == 'ZERO_RESULTS'){
                    a.Verified__c = false;
                    a.API_Response__c = 'ZERO_RESULTS: indicates that the geocode was successful but returned no results. This may occur if the geocoder was passed a non-existent address.';
                }
                else{
                    a.Verified__c = false;
                    a.API_Response__c = 'STATUS: ' + googresp.status + ' BODY: '+ response.getBody();
                }
            }
            else{
                a.Verified__c = false;
                a.API_Response__c = response.getStatusCode() + ': ' + response.getStatus();
            }
        }
        else{
            a.Verified__c = false;
            a.API_Response__c = 'MISSING AUTHID OR ENDPOINT.  Please see the Address Verification menu in the NPSP Settings tab for more information';
        }
        return a;
    }

/* Apex JSON model of Google response */
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