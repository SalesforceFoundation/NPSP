/*
    Copyright (c) 2014, Salesforce.org
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
* @date 2014
* @group Address Management
* @description Class that provides address validation/normalization services
* through the Cicero API.
 */
public with sharing class ADDR_Cicero_Validator implements ADDR_IValidator {

    /*******************************************************************************************************
    * @description holds the Cicero authorization token from NPSP Settings
    */     
    private String strAuthToken;

    /*******************************************************************************************************
    * @description holds the Cicero endpoint from NPSPS Settings
    */     
    private String strEndPoint;

    /*******************************************************************************************************
    * @description holds the timeout value from NPSP Settings
    */     
    private Double dblTimeout;
    
    /*******************************************************************************************************
    * @description returns the name of the Service (Cicero)
    */     
    public String getServiceName() {
        return 'Cicero';
    }
    
    /*******************************************************************************************************
    * @description returns the default URL to use with the Cicero address verification service
    */     
    public String getDefaultURL() {
        return 'https://cicero.azavea.com/v3.1/legislative_district';
    }
    
    /*******************************************************************************************************
    * @description returns false, since Cicero does not support a batch verification mode
    */     
    public Boolean supportsBatch() {
        return false;
    }
    
    /*******************************************************************************************************
    * @description returns a message saying batch is not supported with Cicero
    */     
    public String getBatchHelpText() {
        return Label.Addr_Verification_Batch_Not_Supported;
    }
    
    /*******************************************************************************************************
    * @description Verifies the list of Address objects using the Cicero service.
    * @param listAddr the list of Address objects
    * @param settings an address verification settings object
    * @return List<Address__c> a list of verified and potentially updated addresses
    */ 
    public List<Address__c> verifyRecords(List<Address__c> listAddr, Addr_Verification_Settings__c settings) {

        List<Address__c> listAddrChecked = new List<Address__c>();
        this.strAuthToken = settings.Auth_Token__c;
        this.dblTimeout = settings.Timeout__c;
        
        if (settings.Address_Verification_Endpoint__c != null)
            this.strEndPoint = settings.Address_Verification_Endpoint__c;      
        else       
            this.strEndPoint = getDefaultURL();

        for (Address__c addr : listAddr)    {
            listAddrChecked.add(verifyAddress(addr, settings));
        }

        return listAddrChecked;
    }

    /*******************************************************************************************************
    * @description Verifies a single Address object using the Cicero service.
    * @param addr the Address object
    * @param settings an address verification settings object
    * @return Address__c a verified and potentially updated address
    */ 
    private Address__c verifyAddress(Address__c addr, Addr_Verification_Settings__c settings) {
    
        String strRequest = '?';
        String lastFourPostalDigits;

        //replacing formula with actual fields, as formula was null for tests
        String mailingAddress = '';
        if (addr.MailingStreet__c!=null)
            mailingAddress += addr.MailingStreet__c.trim();
        if (addr.MailingStreet2__c!=null)
            mailingAddress += ' ' + addr.MailingStreet2__c.trim();
        if (mailingAddress!='')
            strRequest += 'search_address=' + EncodingUtil.urlEncode(mailingAddress,'UTF-8') + '&';
        if (addr.MailingCity__c != null)
            strRequest += 'search_city=' + EncodingUtil.urlEncode(addr.MailingCity__c,'UTF-8') + '&';
        if (addr.MailingState__c != null)
            strRequest += 'search_state=' + EncodingUtil.urlEncode(addr.MailingState__c,'UTF-8') + '&';
        if (addr.MailingPostalCode__c != null) {
            if (addr.MailingPostalCode__c.contains('-')) {
                List<String> splitPostal = addr.MailingPostalCode__c.split('-');
                lastFourPostalDigits = splitPostal[1];
                strRequest += 'search_postal=' + EncodingUtil.urlEncode(splitPostal[0],'UTF-8') + '&';
            } else {
                strRequest += 'search_postal=' + EncodingUtil.urlEncode(addr.MailingPostalCode__c,'UTF-8') + '&';
            }
        }
        if (addr.MailingCountry__c != null)
            strRequest += 'search_country=' + EncodingUtil.urlEncode(addr.MailingCountry__c,'UTF-8') + '&';

        try {
            if (strAuthToken != null && strEndPoint != null) {
                //copy address before verification takes place, in case any information is lost
                if (!String.isBlank(addr.Formula_MailingAddress__c))
                    addr.Pre_Verification_Address__c = addr.Formula_MailingAddress__c.replace('<br>','\r\n');

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
                String responseBody = JSON.serializePretty(objResp);
                if(responseBody.length() > 32768) {
                    responseBody = responseBody.substring(0, 32768);
                }
                addr.API_Response__c = responseBody;
                
                if (cresp != null && cresp.response != null && cresp.response.results != null && cresp.response.results.candidates != null) {
                    list<Candidates> listCandidates = cresp.response.results.candidates;  
    
                    // more than one candidate means should mark as ambiguous
                    if (listCandidates.size() > 1) {
                        addr.Ambiguous__c = true;
                    } else {
                        addr.Ambiguous__c = false;
                    }
                    // find the congressional legislative district
                    if (listCandidates.size() == 1 || (listCandidates.size() > 1 && !settings.Reject_Ambiguous_Addresses__c)) {
                        Candidates candidate = listCandidates[0];
                        for (Districts district : candidate.districts) {
                            if (district.district_type == 'NATIONAL_LOWER') {
                                addr.Congressional_District__c = district.district_id;
                                addr.MailingCountry__c = district.country;
                            } else if (district.district_type == 'STATE_UPPER') {
                                addr.State_Upper_District__c = district.district_id;
                            } else if (district.district_type == 'STATE_LOWER') {
                                addr.State_Lower_District__c = district.district_id;
                            } else if (district.district_type == 'LOCAL' && district.subtype != 'COUNTY') {
                                addr.Administrative_Area__c = district.district_id;
                            }
                        }

                        if(!settings.Prevent_Address_Overwrite__c){
                            addr.MailingStreet__c = candidate.match_addr.split(',')[0].trim();
                            addr.MailingCity__c = candidate.match_city;
                            addr.MailingState__c = candidate.match_region;
                            addr.MailingPostalCode__c = candidate.match_postal;
                            if (!String.isBlank(lastFourPostalDigits)) {
                                addr.MailingPostalCode__c += '-' + lastFourPostalDigits;
                            }
                        }
                        addr.County_Name__c  = candidate.match_subregion;

                        ADDR_Addresses_TDTM.handleMultilineStreet(addr);
                    
                        // save location
                        addr.Geolocation__Latitude__s = decimal.valueOf(candidate.y);
                        addr.Geolocation__Longitude__s = decimal.valueOf(candidate.x);
                    }
                }   
                addr.Verified__c = true;
                addr.Verification_Status__c = 'Response Received';
                return addr;
            } else {
                throw(new CiceroException(Label.addrCiceroMissingAPIKey));
            }
        } catch (Exception ex) {
            addr.Verified__c = false;
            addr.API_Response__c = ex.getMessage();
            addr.Verification_Status__c = addr.API_Response__c; 
            ERR_Handler.processError(ex, ERR_Handler_API.Context.ADDR);
        }
        return addr;
    }

    /*******************************************************************************************************
    * @description an exception object wrapper for Cicero
    */ 
    public class CiceroException extends Exception {}
        
    // The following classes represent the response object from Cicero

    /*******************************************************************************************************
    * @description a class to contain a Cicero Response
    */ 
    public class CiceroResponse {
        public Response response;
    }

    /*******************************************************************************************************
    * @description a class to contain a list of Response results
    */ 
    public class Response {
        public Results results;               
    }
    
    /*******************************************************************************************************
    * @description a class to contain a list of Cicero Candidates
    */ 
    public class Results {
        public list<Candidates> candidates;
    }
    
    /*******************************************************************************************************
    * @description a class to contain a Cicero Candidate
    */ 
    public class Candidates {
        /** @description the full normalized address that looks like street, city, state, zip */
        public string match_addr;
        
        /** @description house # and street of the matched address */
        public string match_streetaddr;
        
        /** @description postal/zip code of the matched address */ 
        public string match_postal; 
        
        /** @description city of the matched address */
        public string match_city; 
        
        /** @description county of the matched address -- the upstream geocoder is very spotty with populating this and it is not reliable; may be used more for addresses outside the U.S. */        
        public string match_subregion; 

        /** @description state of the matched address */
        public string match_region; 
        
        /** @description country of the matched address. seems to be UN 3 character code, so I left getting country 2 digit ISO code from district. */        
        public string match_country; 
        
        public string wkid;
        public list<Districts> districts;
        public string x;
        public string y;
        public string geoservice;
    }
    
    /*******************************************************************************************************
    * @description a class to contain a Cicero District
    */ 
    public class Districts {
        public string district_type;
        public string district_id;
        public string country;
        public string label;
        public string subtype;
        public string state;
        public string id;
    }   
    
}