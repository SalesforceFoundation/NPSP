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
* @description Class that provides address validation/normalization services
* through the Cicero API.
 */
public with sharing class ADDR_Cicero_Validator implements ADDR_IValidator {

    private String AUTH_TOKEN;
    private String END_POINT;
    private Double TIMEOUT;
    private List<Address__c> checked_addresses;

    public List<Address__c> verifyRecords(List<Address__c> addresses, Addr_Verification_Settings__c settings){

        this.checked_addresses = new List<Address__c>();
        this.AUTH_TOKEN = 'b65c1767a567498a9e949ab3a8e8a8cb0da2293e'; //settings.Auth_Token__c;
        this.TIMEOUT = settings.Timeout__c;

        //if (settings.Address_Verification_Endpoint__c != null)
        //    this.END_POINT = settings.Address_Verification_Endpoint__c;
        //else
            this.END_POINT = 'https://cicero.azavea.com/v3.1/legislative_district';

        if (addresses.size() == 1){
            checked_addresses.add(verifyAddress(addresses[0]));
        }
        else{
            
        }
        
        
        
        return checked_addresses;
    }

    private Address__c verifyAddress(Address__c a){
    
        String address_request_string = '?';
        if (a.MailingStreet__c != null)
            address_request_string += 'search_address=' + a.MailingStreet__c.replace(' ', '+') + '&';
        if (a.MailingCity__c != null)
            address_request_string += 'search_city=' + a.MailingCity__c.replace(' ', '+') + '&';
        if (a.MailingState__c != null)
            address_request_string += 'search_state=' + a.MailingState__c.replace(' ', '+') + '&';
        if (a.MailingPostalCode__c != null)
            address_request_string += 'search_postal=' + a.MailingPostalCode__c + '&';
        if (a.MailingCountry__c != null)
            address_request_string += 'search_country=' + a.MailingCountry__c + '&';

        HttpResponse response = new HttpResponse();
            if(AUTH_TOKEN != null && END_POINT != null) {
	            // prepare the request
	            Http h = new Http();
	            HttpRequest req = new HttpRequest();
	            req.setMethod('GET');  //UNDONE: Cicero example shows using POST
	            req.setHeader('Content-Type','application/json');
	            req.setHeader('Accept','application/json');
	            req.setEndpoint(END_POINT + address_request_string + '&key=' + AUTH_TOKEN + '&format=json'); 
	            req.setTimeout((TIMEOUT == null) ? 5000 : (TIMEOUT * 1000).intValue());
	            // execute the request
	            response = h.send(req);
	            system.debug('CICERO RESPONDS WITH: ' + response.getBody());
	            a.API_Response__c = response.getBody();
	            CiceroResponse cresp = (CiceroResponse)JSON.deserialize(response.getBody(), CiceroResponse.class);
	            system.debug('CiceroResponse is: ' + cresp);
	            
	            boolean foundData = false;
	            for (Candidates candidate : cresp.response.results.candidates) {
	               for (Districts district : candidate.districts) {
	                   if (district.district_type == 'NATIONAL_LOWER') {
	                       a.Congressional_District__c = district.district_id;
	                       foundData = true;
	                       break;
	                   }
	               }
	               //a.Geolocation__Latitude__s = decimal.valueOf(candidate.x);
	               //a.Geolocation__Longitude__s = decimal.valueOf(candidate.y);
	            }
	
	            a.Verified__c = foundData;
            }
        return a;
    }
    
    // The following classes represent the response object from Cicero

	public class CiceroResponse {
		Response response;
	}

    public class Response {
        Results results;               
    }
    
    public class Results {
    	list<Candidates> candidates;
    }
    
    public class Candidates {
        string match_addr;
        string wkid;
        list<Districts> districts;
        string x;
        string y;
        string geoservice;
    }
    
    public class Districts {
        string district_type;
        string district_id;
        string label;
        string subtype;
        string state;
        string id;
    }   
    
}