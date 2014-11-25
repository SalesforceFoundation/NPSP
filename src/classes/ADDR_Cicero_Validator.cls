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

    private String strAuthToken;
    private String strEndPoint;
    private Double dblTimeout;
    
    public String getServiceName() {
    	return 'Cicero';
    }
    
    public String getDefaultURL() {
    	return 'https://cicero.azavea.com/v3.1/legislative_district';
    }
    
    public String getHelpText() {
    	return Label.stgHelpCiceroAddrVerification; 
    }
    
    public Boolean supportsBatch() {
    	return false;
    }
    
    public String getBatchHelpText() {
    	return Label.Addr_Verification_Batch_Not_Supported;
    }
    
    public List<Address__c> verifyRecords(List<Address__c> listAddr, Addr_Verification_Settings__c settings) {

        List<Address__c> listAddrChecked = new List<Address__c>();
        this.strAuthToken = settings.Auth_Token__c;
        this.dblTimeout = settings.Timeout__c;

        if (settings.Address_Verification_Endpoint__c != null)
            this.strEndPoint = settings.Address_Verification_Endpoint__c;
        else
            this.strEndPoint = 'https://cicero.azavea.com/v3.1/legislative_district';

        for (Address__c addr : listAddr)	{
            listAddrChecked.add(verifyAddress(addr, settings));
        }

        return listAddrChecked;
    }

    private Address__c verifyAddress(Address__c addr, Addr_Verification_Settings__c settings) {
    
        String strRequest = '?';
        if (addr.Formula_MailingStreetAddress__c != null)
            strRequest += 'search_address=' + addr.Formula_MailingStreetAddress__c.replace(' ', '+') + '&';
        if (addr.MailingCity__c != null)
            strRequest += 'search_city=' + addr.MailingCity__c.replace(' ', '+') + '&';
        if (addr.MailingState__c != null)
            strRequest += 'search_state=' + addr.MailingState__c.replace(' ', '+') + '&';
        if (addr.MailingPostalCode__c != null)
            strRequest += 'search_postal=' + addr.MailingPostalCode__c.replace(' ', '+') + '&';
        if (addr.MailingCountry__c != null)
            strRequest += 'search_country=' + addr.MailingCountry__c.replace(' ', '+') + '&';

        try {
	        if (strAuthToken != null && strEndPoint != null) {
	            // prepare the request
	            Http h = new Http();
	            HttpRequest req = new HttpRequest();
	            req.setMethod('GET');  
	            req.setHeader('Content-Type','application/json');
	            req.setHeader('Accept','application/json');
	            req.setEndpoint(strEndPoint + strRequest + '&key=' + strAuthToken + '&format=json'); 
	            req.setTimeout((dblTimeout == null) ? 5000 : (dblTimeout * 1000).intValue());
	
	            // execute the request
	            HttpResponse response = new HttpResponse();
	            if (Test.isRunningTest())
	                response = ADDR_Cicero_Test.respond(req);
	            else
	                response = h.send(req);
	            UTIL_Debug.debug('****CICERO RESPONDS WITH Status: ' + response.getStatus() + ' StatusCode: ' + response.getStatusCode());
	            UTIL_Debug.debug('****CICERO response.body: ' + response.getBody());
	            if (response.getStatusCode() != 200) {
	            	string strError = response.getStatusCode() + ': ' + response.getStatus() + '\r\n' + response.getBody();
	            	throw(new CiceroException(strError));
	            }
	            CiceroResponse cresp = (CiceroResponse)JSON.deserialize(response.getBody(), CiceroResponse.class);
	            Object objResp = JSON.deserializeUntyped(response.getBody());
	            addr.API_Response__c = JSON.serializePretty(objResp);
	            
	            boolean foundData = false;
	            if (cresp != null && cresp.response != null && cresp.response.results != null && cresp.response.results.candidates != null) {
	                list<Candidates> listCandidates = cresp.response.results.candidates;  
	
	                // more than one candidate means should mark as ambiguous
	                if (listCandidates.size() > 1) {
	                    addr.Ambiguous__c = true;
	                }             
		            // find the congressional legislative district
		            if (listCandidates.size() == 1 || (listCandidates.size() > 1 && !settings.Reject_Ambiguous_Addresses__c)) {
	                    Candidates candidate = listCandidates[0];
	                    for (Districts district : candidate.districts) {
		                    if (district.district_type == 'NATIONAL_LOWER') {
		                        addr.Congressional_District__c = district.district_id;
		                        addr.MailingCountry__c = district.country;
		                        foundData = true;
		                        break;
		                    }
		                }
	                
	                // parse match_addr to get normalized form
	                // we assume it looks like 'street, city, state, zip'
	                list<string> listParts = candidate.match_addr.split(',');
	                if (listParts.size() == 4) {
	                    addr.MailingStreet__c = listParts[0].trim();
	                    ADDR_Addresses_TDTM.handleMultilineStreet(addr);
	                    addr.MailingCity__c = listParts[1].trim();
	                    addr.MailingState__c = listParts[2].trim();
	                    addr.MailingPostalCode__c = listParts[3].trim();
	                }
	                
	                // save location
	                addr.Geolocation__Latitude__s = decimal.valueOf(candidate.y);
	                addr.Geolocation__Longitude__s = decimal.valueOf(candidate.x);
		            }
	            }	
	            addr.Verified__c = foundData;
	            addr.Verification_Status__c = 'Response Received';
	            return addr;
	        } else {
	        	throw(new CiceroException(Label.addrCiceroMissingAPIKey));
	        }
        } catch (Exception ex) {
	        addr.Verified__c = false;
	        addr.API_Response__c = ex.getMessage();
	        addr.Verification_Status__c = addr.API_Response__c; 
            ERR_Handler.processError(ex, ERR_Handler.Context.ADDR);
        }
        return addr;
    }

    public class CiceroException extends Exception {}
        
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
        
        string match_streetaddr; // house # and street of the matched address
        string match_postal; // postal/zip code of the matched address
        string match_city; // city of the matched address
        string match_subregion; // county of the matched address -- I've found our upstream geocoder is very spotty with populating this and I wouldn't rely on it, may be used more for addresses outside the U.S.
        string match_region; // state of the matched address - doesn't seem to be part of the response, even though I was told it would be.        
        string match_country; // country of the matched address. seems to be UN 3 character code, so I left getting country 2 digit ISO code from district.
        
        string wkid;
        list<Districts> districts;
        string x;
        string y;
        string geoservice;
    }
    
    public class Districts {
        string district_type;
        string district_id;
        string country;
        string label;
        string subtype;
        string state;
        string id;
    }   
    
}