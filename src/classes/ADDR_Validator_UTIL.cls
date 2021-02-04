/*
    Copyright (c) 2020, Salesforce.org
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
* @date 2020
* @group Address Management
* @description Utility methods and constants for Address Validation in NPSP
*/
public inherited sharing class ADDR_Validator_UTIL {

    public static final String RESPONSE_OK = 'OK';
    public static final Integer RESPONSE_CODE_SUCCESS = 200;

    private static final Set<String> usCountryCodes = new Set<String>{
        'US', 'USA', 'United States', 'United States of America'
    };

    private static final Set<String> streetNumberFirstCountries = new Set<String>{
        'US', 'USA', 'United States', 'United States of America',
        'CA','Canada',
        'UK','United Kingdom',
        'GB','Great Britain',
        'IE','Republic of Ireland','Ireland',
        'FR','France',
        'LU','Luxembourg',
        'MC','Monaco',
        'AU','Australia',
        'JP','Japan'
    };

    /**
    * @description Trim a ResponseBody to 32K to avoid STRING_TOO_LONG error.
    * @param response HttpResponse
    * @return Truncated String
    */
    public static String trimBodyTo32K(HttpResponse response) {
        return trimBodyTo32K(response.getBody());
    }

    /**
    * @description Trim a string to 32K to avoid STRING_TOO_LONG error.
    * @param body String
    * @return Truncated String
    */
    public static String trimBodyTo32K(String body) {
        if (body != null && body.length() > 32768) {
            body = body.substring(0, 32768);
        }
        return body;
    }

    /*******************************************************************************************************
    * @description Determines if an address is US-based.
    *
    * Also called from ADDR_SmartyStreets_Validator. Since it's an auxiliary method we could move it to a separate
    * class, but we'll keep it here for now because it's the only auxiliary one we have for address validation.
    *
    * @param addr The address to inspect.
    * @return Boolean True if the address is US-based. False otherwise.
    */
    public static Boolean isUSAddress(Address__c addr) {
        return isUSCountry(addr.MailingCountry__c)
            && (
            addr.MailingStreet__c != null
                || addr.MailingPostalCode__c != null
                || (addr.MailingCity__c != null && addr.MailingState__c != null)
        );
    }

    /**
    * @description Returns True if the Country is null or the value is in the list of valid US Country Names/Code
    * @param country String
    * @return boolean
    */
    public static Boolean isUSCountry(String country) {
        return country == null || usCountryCodes.contains(country);
    }

    /**
    * @description Returns True if the Country is one of those that needs to always have the street
    * number formatted before the street name. Otherwise the code tries to figure this out using the
    * formatted_address response. Information comes from
    * https://www.parcelforce.com/help-and-advice/sending/address-formats-europe. There are other countries
    * However, these are the most common exceptions outlined by CCE during research.
    * @param country String
    * @return boolean
    */
    public static Boolean isStreetNumberBeforeStreetName(String country) {
        return streetNumberFirstCountries.contains(country);
    }
}