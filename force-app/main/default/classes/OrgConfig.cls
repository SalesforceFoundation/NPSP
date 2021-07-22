/*
    Copyright (c) 2021 Salesforce.org
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
* @date 2021
* @description Org Settings class in NPSP.
*/
public inherited sharing class OrgConfig {

    /*******************************************************************************************************
    * @description map from Country name (UPPER CASE) to Country Code
    */
    private static Map<String, String> validCountriesByLabel = new Map<String, String>();

    public Map<String, String> validCountriesByLabel() {
        return validCountriesByLabel;
    }

    /*******************************************************************************************************
    * @description map from State name (UPPER CASE) to State Code
    */
    private static Map<String, String> validStatesByLabel = new Map<String, String>();

    public Map<String, String> validStatesByLabel() {
        return validStatesByLabel;
    }

    /*******************************************************************************************************
    * @description map from Country Code to Country Name
    */
    private static Map<String, String> validCountriesByCode = new Map<String, String>();

    public Map<String, String> validCountriesByCode() {
        return validCountriesByCode;
    }

    /*******************************************************************************************************
    * @description specifies whether state and country picklists are enabled in this org.
    * @return true if enabled
    */
    private static Boolean isStateCountryPicklistsEnabled {
        get {
            if (isStateCountryPicklistsEnabled == null) {
                isStateCountryPicklistsEnabled = initValidStateCountryCodes();
            }
            return isStateCountryPicklistsEnabled;
        }
        private set;
    }

    public Boolean isStateCountryPicklistsEnabled() {
        return isStateCountryPicklistsEnabled;
    }

    /*******************************************************************************************************
    * @description utility to determine if the "State and Country Picklist" field feature is enabled in Salesforce
    * @return true if enabled; Fills 4 sets<> with a list of value codes and labels for each field
    */
    private static Boolean initValidStateCountryCodes() {
        // If State & Country Picklists are enabled in the org, build maps of the
        // valid Labels and Codes for each field to use for validation
        Map<String, Schema.SObjectField> acctFields = Account.getSObjectType().getDescribe().fields.getMap();
        Boolean isCodesEnabled = acctFields.containsKey('BillingCountryCode');
        if (isCodesEnabled) {
            List<Schema.PicklistEntry> countryPLValues = acctFields.get('BillingCountryCode').getDescribe().getPicklistValues();
            for (Schema.PicklistEntry p : countryPLValues) {
                if (p.isActive()) {
                    validCountriesByLabel.put(p.getLabel().toUpperCase(), p.getValue());
                    validCountriesByCode.put(p.getValue(), p.getLabel());
                }
            }
            List<Schema.PicklistEntry> statePLValues = acctFields.get('BillingStateCode').getDescribe().getPicklistValues();
            for (Schema.PicklistEntry p : statePLValues) {
                if (p.isActive()) {
                    validStatesByLabel.put(p.getLabel().toUpperCase(), p.getValue());
                    // we can't have a map of valid StateCodes, because they are not unique.
                    // ideally we would have a map of CountryCode + StateCode -> StateLabel
                    // but Salesforce provides us no way of figuring out picklist dependencies efficiently.
                }
            }
        }
        return isCodesEnabled;
    }

}