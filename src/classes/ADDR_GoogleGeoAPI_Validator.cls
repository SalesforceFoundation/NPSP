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
* @description Validator to provide address geocoding/verification through the Google Geocoding API
 */
public with sharing class ADDR_GoogleGeoAPI_Validator implements ADDR_IValidator{

    private List<Address__c> checked_addresses;

    /*******************************************************************************************************
    * @description Provides the called with the service name.
    * @return String The name of the address validation service.
    */
    public String getServiceName() {
        return 'The Google Geocoding API';
    }

    /*******************************************************************************************************
    * @description Provides the caller with the default endpoint URL.
    * @return String The URL to send requests to.
    */
    public String getDefaultURL() {
        return 'https://maps.googleapis.com/maps/api/geocode/json?';
    }

    /*******************************************************************************************************
    * @description Tells the caller if the class supports batch address validation.
    * @return Boolean True is the class supports batch address validation. False otherwise.
    */
    public Boolean supportsBatch() {
        return false;
    }

    /*******************************************************************************************************
    * @description Provides the caller with help text regarding batch support.
    * @return String The help text.
    */
    public String getBatchHelpText() {
        return Label.Addr_Verification_Batch_Not_Supported;
    }

    /*******************************************************************************************************
    * @description Verifies a list of Addresses records.
    * @param addresses List of Address records to verify.
    * @param settings The Address Verification Settings to use.
    * @return List<Address__c> List of verified address records.
    */
    public List<Address__c> verifyRecords(List<Address__c> addresses, Addr_Verification_Settings__c settings) {

        this.checked_addresses = new List<Address__c>();

        String endPoint = settings.Address_Verification_Endpoint__c != null ?
            settings.Address_Verification_Endpoint__c : getDefaultURL();

        if (!addresses.isEmpty()){
            for (Address__c a : addresses) {
                Verifier addrVerify = new Verifier(a)
                    .withAddressSettings(settings)
                    .withEndPoint(endPoint)
                    .verifyAddress();
                checked_addresses.add(addrVerify.getUpdatedAddress());
            }
        }
        return checked_addresses;
    }

    /*******************************************************************************************************
    * @description Apex model of the Google JSON response.
    */
    public class GoogleGeoResponse {
        public List<ADDR_GoogleGeoAPI_Validator.Results> results;
        public String status;
    }

    /*******************************************************************************************************
    * @description Apex model of the results element of the Google JSON response.
    */
    public class Results {
        public List<ADDR_GoogleGeoAPI_Validator.Address_components> address_components;
        public String formatted_address;
        public Geometry geometry;
        public Boolean partial_match;
        public List<String> types;
    }

    /*******************************************************************************************************
    * @description Apex model of the address_components element of the Google JSON response.
    */
    public class Address_components {
        public String long_name;
        public String short_name;
        public List<String> types;
    }

    /*******************************************************************************************************
    * @description Apex model of the geometry element of the Google JSON response.
    */
    public class Geometry {
        public Location location;
        public String location_type;
        public Viewport viewport;
    }

    /*******************************************************************************************************
    * @description Apex model of the location element of the Google JSON response.
    */
    public class Location {
        public Double lat;
        public Double lng;
    }

    /*******************************************************************************************************
    * @description Apex model of the viewport element of the Google JSON response.
    */
    public class Viewport {
        public Location northeast;
        public Location southwest;
    }

    /*******************************************************************************************************
    * @description Parses a JSON strings and returns a GoogleGeoResponse Apex object.
    * @param json The JSON string.
    * @return GoogleGeoResponse The Apex object the JSON string has been transformed into.
    */
    public static GoogleGeoResponse parse(String json) {
        return (GoogleGeoResponse) System.JSON.deserialize(json, GoogleGeoResponse.class);
    }

    /**
    * @description Address Verification Wrapper Class
    */
    public class Verifier {

        private Address__c address;
        private String endPoint;
        private Addr_Verification_Settings__c settings;
        private GoogleGeoResponse googleResponse;
        private HttpResponse rawResponse;

        /** @description SubPremise from the original address to append to the Street Address (if not null) */
        private String subPremise;

        /** @description Constructor with the address to verify */
        public Verifier(Address__c addr) {
            this.address = addr;
        }

        /**
        * @description Pass an instance of the AddressVerificationSettings object
        * @return Instance
        * */
        public Verifier withAddressSettings(Addr_Verification_Settings__c settings) {
            this.settings = settings;
            return this;
        }

        /**
        * @description Pass the endpoint to use
        * @return Instance
        */
        public Verifier withEndPoint(String endPoint) {
            this.endPoint = endPoint;
            return this;
        }

        /**
       * @description Verify this Aaddress record and return an instance of this class
       * @return Instance
       */
        public Verifier verifyAddress() {

            if (settings == null || settings.Auth_Token__c == null || endPoint == null) {
                address.Verified__c = false;
                address.API_Response__c = 'MISSING AUTHID OR ENDPOINT.  Please see the Address Verification menu in the NPSP Settings tab for more information';
                return this;
            }

            if (!sendAdressVerificationRequest()) {
                return this;
            }

            if (googleResponse.status != ADDR_Validator_UTIL.RESPONSE_OK || googleResponse.results == null) {
                handleOtherResponses();
                return this;
            }

            Boolean ignoreAmbiguous = settings.Reject_Ambiguous_Addresses__c == true;
            Integer resultSize = googleResponse.results.size();
            Boolean isPartialMatch = googleResponse.results[0].partial_match == true;

            if (resultSize == 1 && !(ignoreAmbiguous && isPartialMatch)) {

                // Single match and not a partial match
                parseAddressResponse();

            } else if (resultSize > 1 || (resultSize == 1 && ignoreAmbiguous && isPartialMatch)) {

                // Multiple Matches and Ignore Ambiguous is enabled
                address.Ambiguous__c = true;
                address.Verified__c = true;
                address.API_Response__c = ADDR_Validator_UTIL.trimBodyTo32K(rawResponse);
                address.Verification_Status__c = 'Ambiguous';
            }

            return this;
        }

        /**
        * @description Return the updated address record
        * @return Address__c record with all updated fields
        */
        public Address__c getUpdatedAddress() {
            return this.address;
        }

        /**
        * @description Build and complete the callout to the verification service
        * @return Boolean True if the verification callout completes with zero errors and the address
        * is able to be properly verified.
        */
        private Boolean sendAdressVerificationRequest() {
            Http h = new Http();
            HttpRequest req = new HttpRequest();
            req.setMethod('GET');
            req.setHeader('Accept', 'application/json');
            req.setEndpoint(this.endPoint +
                'address=' + buildAddressRequestString() +
                '&key=' + this.settings.Auth_Token__c
            );

            try {
                UTIL_Debug.debug('****Request body: \n' + req);
                rawResponse = h.send(req);
                UTIL_Debug.debug('****Response body: \n' + rawResponse.getBody());
            } catch (Exception e) {
                address.Verified__c = false;
                address.API_Response__c = 'REQUEST FAILED.  MESSAGE: ' + e.getMessage();
                ERR_Handler.processError(e, ERR_Handler_API.Context.ADDR);
                address.Verification_Status__c = e.getMessage();
                return false;
            }

            if (rawResponse.getStatusCode() != ADDR_Validator_UTIL.RESPONSE_CODE_SUCCESS) {
                address.Verified__c = false;
                address.API_Response__c = rawResponse.getStatusCode() + ': ' + rawResponse.getStatus();
                address.Verification_Status__c = address.API_Response__c;
                return false;
            }

            googleResponse = new ADDR_GoogleGeoAPI_Validator.GoogleGeoResponse();
            try {
                googleResponse = (ADDR_GoogleGeoAPI_Validator.GoogleGeoResponse) JSON.deserialize(rawResponse.getBody(), ADDR_GoogleGeoAPI_Validator.GoogleGeoResponse.class);
            } catch (Exception e) {
                address.Verified__c = false;
                address.API_Response__c = 'BAD JSON PARSE.  MESSAGE: ' + e.getMessage();
                ERR_Handler.processError(e, ERR_Handler_API.Context.ADDR);
                address.Verification_Status__c = e.getMessage();
                return false;
            }

            return true;
        }

        /**
        * @description Build the address request string to pass to the verification service in the URL
        * @return single line of an address to be verified
        */
        private String buildAddressRequestString() {
            String address_request_string = '';
            String mailingStreet = '';

            if (!String.isBlank(address.MailingStreet__c)) {
                mailingStreet += address.MailingStreet__c.trim();
            }
            if (!String.isBlank(address.MailingStreet2__c)) {
                mailingStreet += ' ' + address.MailingStreet2__c.trim();
            }

            // if our address has a comma, split it off and append it after verification
            if (mailingStreet.contains(',')) {
                List<String> split = mailingStreet.split(',', 2);
                address_request_string += 'search_address=' + split[0].replace(' ', '+') + '+';
                subPremise = split[1];
            } else {
                address_request_string += 'search_address=' + mailingStreet.replace(' ', '+') + '+';
            }

            if (address.MailingCity__c != null) {
                address_request_string += address.MailingCity__c.replace(' ', '+') + '+';
            }
            if (address.MailingState__c != null) {
                address_request_string += address.MailingState__c.replace(' ', '+') + '+';
            }
            if (address.MailingPostalCode__c != null) {
                address_request_string += address.MailingPostalCode__c.replace(' ', '+') + '+';
            }
            if (address.MailingCountry__c != null) {
                address_request_string += address.MailingCountry__c.replace(' ', '+');
            }
            address_request_string = address_request_string.replace('\r\n', ',').replace('\r', ',').replace('\n', ',');

            this.rawResponse = new HttpResponse();

            // copy address before verification takes place, in case any information is lost
            if (!String.isBlank(address.Formula_MailingAddress__c)) {
                address.Pre_Verification_Address__c = address.Formula_MailingAddress__c.replace('<br>', '\r\n');
            }

            return address_request_string;
        }

        /**
        * @description Fully Parse a valid matched address response and update the Address__c record
        * as necessary.
        */
        private void parseAddressResponse() {

            populateAddressFromGoogleResponse();

            Addresses.handleMultilineStreet(address);
            address.Geolocation__Latitude__s = googleResponse.results[0].geometry.location.lat;
            address.Geolocation__Longitude__s = googleResponse.results[0].geometry.location.lng;
            address.Verified__c = true;
            address.API_Response__c = ADDR_Validator_UTIL.trimBodyTo32K(rawResponse);
            address.Verification_Status__c = System.Label.Addr_Verified;
        }

        /**
        * @description Parse Address_Components from the Google Response to populate the specific address fields
        * on the address object
        */
        private void populateAddressFromGoogleResponse() {
            String premise = '';
            String streetNumber = '';
            String streetName = '';
            String intersection = '';

            List<ADDR_GoogleGeoAPI_Validator.Address_components> addrComponents = googleResponse.results[0].address_components;
            for (ADDR_GoogleGeoAPI_Validator.Address_components addrCmp : addrComponents) {
                Set<String> type_set = new Set<String>();
                type_set.addAll(addrCmp.types);

                if (type_set.contains('postal_code')) {
                    String verified5digs = addrCmp.long_name;
                    String originalFull = address.MailingPostalCode__c;
                    String original5digs = '';
                    if (originalFull != null && originalFull.length() > 5) {
                        original5digs = originalFull.substring(0, 5);
                    }
                    //Google only returns 5-digit zipcodes. We don't want to override the original, if the
                    //first 5 match, and the original has the additional 4.
                    if (!(verified5digs == original5digs)) {
                        address.MailingPostalCode__c = addrCmp.long_name;
                    }
                } else if (type_set.contains('country')) {
                    address.MailingCountry__c = addrCmp.short_name;
                } else if (type_set.contains('administrative_area_level_1')) {
                    address.MailingState__c = addrCmp.short_name;
                } else if (type_set.contains('administrative_area_level_2')) {
                    address.County_Name__c = addrCmp.long_name;
                } else if (type_set.contains('administrative_area_level_3')) {
                    address.Administrative_Area__c = addrCmp.long_name;
                } else if (type_set.contains('street_number')) {
                    streetNumber = addrCmp.long_name;
                } else if (type_set.contains('route')) {
                    streetName = addrCmp.long_name;
                } else if (type_set.contains('intersection')) {
                    intersection = addrCmp.long_name;
                } else if (type_set.contains('premise')) {
                    premise += addrCmp.long_name;
                } else if (type_set.contains('subpremise')) {
                    premise += addrCmp.long_name;
                } else if (type_set.contains('locality')) {
                    address.MailingCity__c = addrCmp.long_name;
                }
            }

            address.MailingStreet__c = buildStreetAddress(address.MailingCountry__c, streetName, streetNumber,
                intersection, premise, subPremise, googleResponse.results[0].formatted_address);
        }

        /**
        * @description Concatenate the different components of a Street Address as appropriate based on the
        * country and the various retrieved components from the address validation service
        * @param mailingCountry Mailing Country
        * @param streetName Street Name
        * @param streetNumber Street Number
        * @param intersection Interection (if any)
        * @param premise Premise
        * @param subPremise Sub-Premise from the original address
        * @param formattedAddress Formatted Address from the validation service
        * @return Properly formatted Street Address
        */
        private String buildStreetAddress(String mailingCountry, String streetName, String streetNumber,
            String intersection, String premise, String subPremise, String formattedAddress
        ) {
            String verified_street = '';

            // US addresses always format as StreetNumber StreetName, while many others are reversed
            // If the country isn't this specified hardcoded list, try to figure it out based on whether
            // the first character of the Formatted_Address response is a letter or a number.
            Boolean shouldStartWithStreetName = !ADDR_Validator_UTIL.isStreetNumberBeforeStreetName(mailingCountry)
                && formattedAddress.left(1).isAlpha();

            if (shouldStartWithStreetName) {
                verified_street = streetName + ' ' + streetNumber + ' ' + intersection;
            } else {
                verified_street = streetNumber + ' ' + streetName + ' ' + intersection;
            }

            if (!String.isBlank(premise)) {
                verified_street = verified_street.trim() + ' ' + premise.trim();
            }
            if (!String.isBlank(subPremise)) {
                if (!String.isBlank(verified_street)) {
                    verified_street = verified_street.trim() + ', ' + subPremise.trim();
                } else{
                    verified_street = subPremise.trim();
                }
            }

            return verified_street.trim();
        }

        /**
        * @description Handle other response types besides OK/200
        */
        private void handleOtherResponses() {

            switch on googleResponse.status {
                when 'OVER_QUERY_LIMIT' {
                    address.Verified__c = false;
                    address.API_Response__c = 'OVER_QUERY_LIMIT: indicates that you are over your quota.';
                    address.Verification_Status__c = address.API_Response__c;

                } when 'REQUEST_DENIED' {
                    address.Verified__c = false;
                    address.API_Response__c = 'REQUEST_DENIED: indicates that your request was denied.';
                    address.Verification_Status__c = address.API_Response__c;

                } when 'UNKNOWN_ERROR' {
                    address.Verified__c = false;
                    address.API_Response__c = 'UNKNOWN_ERROR: indicates that the request could not be processed due to a server error. The request may succeed if you try again.';
                    address.Verification_Status__c = address.API_Response__c;

                } when 'INVALID_REQUEST' {
                    address.Verified__c = true;
                    address.API_Response__c = 'INVALID_REQUEST: generally indicates that the query (address, components or latlng) is missing.';
                    address.Verification_Status__c = address.API_Response__c;

                } when 'ZERO_RESULTS' {
                    address.Verified__c = true;
                    address.API_Response__c = 'ZERO_RESULTS: indicates that the geocode was successful but returned no results. This may occur if the geocoder was passed a non-existent address.';
                    address.Verification_Status__c = address.API_Response__c;

                } when else {
                    address.Verified__c = true;
                    //Truncating body response to avoid STRING_TOO_LONG error.
                    address.API_Response__c = 'STATUS: ' + googleResponse.status + ' BODY: '
                        + ADDR_Validator_UTIL.trimBodyTo32K(rawResponse);
                    address.Verification_Status__c = address.API_Response__c;
                }
            }
        }

    }
}