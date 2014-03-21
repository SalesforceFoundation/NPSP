public with sharing class ADDR_Validator_SmartyStreets implements ADDR_IValidator {
    
    // verify a List of custom object records - split them up into those we are
    // sending for address and those for zip only - max of 100 at a time for each
    public List<Address__c> verifyRecords(List<Address__c> avList, Boolean rejectAmbiguous) {
    	
        List<Address__c> shortList = new List<Address__c>();
        List<Address__c> shortListZipOnly = new List<Address__c>();
        for (Address__c av : avList) {
            if (av.MailingStreet__c == null && (av.MailingPostalCode__c != null || 
                (av.MailingCity__c != null && av.MailingState__c != null))) {

                // has no address, but can be verified and geocoded by the zipcode api
                shortListZipOnly.add(av);
                if (shortListZipOnly.size() == 100) {
                    verifyZipRecords100(shortListZipOnly);
                    shortListZipOnly = new List<Address__c>();
                }
            } else if (av.MailingStreet__c != null) {
                shortList.add(av);
                if (shortList.size() == 100) {
                    return verifyRecords100(shortList, rejectAmbiguous); 
                }
            }
        }
        if (!shortListZipOnly.isEmpty())
            return verifyZipRecords100(shortListZipOnly);
        if (!shortList.isEmpty())
            return verifyRecords100(shortList, rejectAmbiguous);
        return new List<Address__c>();
    }

    private List<Address__c> verifyRecords100(List<Address__c> avList, Boolean rejectAmbiguous) {
        integer recs = 0;
        List<ADDR_Validation_Gateway.Request> srList = new List<ADDR_Validation_Gateway.Request>();
        
        for (Address__c av : avList) {
            ADDR_Validation_Gateway.Request sr = new ADDR_Validation_Gateway.Request();
            sr.street = av.MailingStreet__c;
            // sr.street2 =     // SHOULD WE SPLIT STREET WHEN MULTILINE??
            sr.city = av.MailingCity__c;
            sr.state = av.MailingState__c;
            sr.zipcode = av.MailingPostalCode__c;

            // request a few candidates to determine if the address is unique
            sr.candidates = (rejectAmbiguous) ? 3 : 1;   
            srList.add(sr);         
        }   

        try {
            ADDR_Validation_Gateway la = new ADDR_Validation_Gateway();
            List<ADDR_Validation_Gateway.Response> responses = la.verifyAddresses(srList);
            System.debug('****Gateway responses: ' + JSON.serializePretty(responses));
            if (responses != null) {
                List<ADDR_Validation_Gateway.Response> responseGroup;
                for (ADDR_Validation_Gateway.Response sr : responses) {         
                    Address__c av = avList[ sr.input_index ];              
                    if (sr.candidate_index == 0) {
                        responseGroup = new List<ADDR_Validation_Gateway.Response>{ sr };
                        System.debug('****Flagging address as verified. Address ID: ' + av.Id);
                        av.Verified__c = true;
                        av.MailingStreet__c = sr.delivery_line_1 + 
                            ((sr.delivery_line_2 != null && sr.delivery_line_2 != '') ? ('\n' + sr.delivery_line_2) : '');
                        av.MailingCity__c = sr.components.city_name;
                        av.MailingState__c = sr.components.state_abbreviation;
                        av.MailingPostalCode__c = (sr.components.zipcode == null) ? null : (sr.components.zipcode +
                            ((sr.components.plus4_code != null && sr.components.plus4_code != '') ? ('-' + sr.components.plus4_code) : ''));
                        av.MailingCountry__c = 'US';
                        av.Geolocation__Latitude__s = sr.metadata.latitude;
                        av.Geolocation__Longitude__s = sr.metadata.longitude;
                        av.County_Name__c = sr.metadata.county_name;
                        av.Congressional_District__c = sr.metadata.congressional_district;
                    } else {
                        // more than one candidate means should mark as ambiguous
                        System.debug('****Flagging address as NOT verified. Flagging it as ambiguous. Address ID: ' + av.Id);
                        av.Verified__c = false; 
                        av.Ambiguous__c = true;
                        responseGroup.add(sr);
                    }
                    av.API_Response__c = JSON.serializePretty(responseGroup);
                }
            }
            for (Address__c av : avList) {             
                if (av.API_Response__c == null) {   
                    av.API_Response__c = Label.Address_Not_Found;
                }
            }
        } catch (Exception ex) {
            for (Address__c av : avList) {
                System.debug('****Flagging address as NOT verified Address ID: ' + av.Id 
                               + ' - Exception in verifyRecords100: ' + ex.getMessage() 
                               + '\n' + ex.getStackTraceString());
                av.Verified__c = false;
                av.API_Response__c = 'MESSAGE: ' + ex.getMessage() + '\nSTACKTRACE:\n' + ex.getStackTraceString();
            }
        }
        return avList;
    }

    private List<Address__c> verifyZipRecords100(List<Address__c> avList) {
        integer recs = 0;
        List<ADDR_Zipcode_Validation_Gateway.Request> zrList = new List<ADDR_Zipcode_Validation_Gateway.Request>();
        
        for (Address__c av : avList) {
            zrList.add(new ADDR_Zipcode_Validation_Gateway.Request(
                av.MailingCity__c,
                av.MailingState__c,
                av.MailingPostalCode__c
           ));
        }   

        try {
            ADDR_Zipcode_Validation_Gateway la = new ADDR_Zipcode_Validation_Gateway();
            List<ADDR_Zipcode_Validation_Gateway.Response> responses = la.verifyZips(zrList);
            System.debug('****Gateway responses: ' + JSON.serializePretty(responses));
            if (responses != null && !responses.isEmpty()) {
                if(responses.size() == avList.size()) {
                    for (integer i = 0; i < responses.size(); i++) {
                        ADDR_Zipcode_Validation_Gateway.Response sr = responses[i];
                        Address__c av = avList[i];             
    
                        // look for an error
                        if (sr.status != null && sr.reason != null) {
                            System.debug('****Error found. Reason: ' + sr.reason);
                            av.API_Response__c = sr.reason;
                        // if there is any response, serialize it and fill in location with first location value
                        } else if (sr.zipcodes != null) {
                            System.debug('****No error. Populating raw response field.');
                            av.API_Response__c = JSON.serializePretty(sr);
                            
                            // if there is at least one city/state, fill in city state
                            if (sr.city_states != null && sr.city_states.size() > 0) {
                                System.debug('****Populating city and estate.');
                                av.MailingCity__c = sr.city_states[0].city;
                                av.MailingState__c = sr.city_states[0].state_abbreviation;
                                av.MailingCountry__c = 'US';
                            }
    
                            // if there is exactly one zip, fill in zip
                            if (sr.zipcodes.size() == 1)
                                av.MailingPostalCode__c = sr.zipcodes[0].zipcode;
                        }
                    }
                } else {
                    System.debug('****Responses did not match number of verifications.');
                }
            }
            for (Address__c av : avList) {             
                if (av.API_Response__c == null) {   
                    av.API_Response__c = Label.Zip_Not_Found;
                }
            }
        } catch (Exception ex) {
            for (Address__c av : avList) {
                System.debug('****Flagging address as NOT verified Address ID: ' + av.Id 
                            + ' - Exception in verifyZipRecords100: ' + ex.getMessage()
                            + '\n' + ex.getStackTraceString());
                av.Verified__c = false;
                av.API_Response__c = 'MESSAGE: ' + ex.getMessage() + '\nSTACKTRACE:\n' + ex.getStackTraceString();
            }
        }
        return avList;
    }
}