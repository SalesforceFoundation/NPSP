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
* @description Address entity class in NPSP.
*/
public inherited sharing class NPSP_Address implements IAddress {

    private Address__c address;
    private Address__c oldAddress;

    @TestVisible
    private OrgConfig orgConfig {
        get {
            if (orgConfig == null) {
                orgConfig = new OrgConfig();
            }
            return orgConfig;
        }
        set;
    }

    @TestVisible
    private AddressService addressService {
        get {
            if (addressService == null) {
                addressService = new AddressService();
            }
            return addressService;
        }
        set;
    }

    public NPSP_Address(Address__c address) {
        this.address = address;
    }

    public NPSP_Address(Address__c address, Address__c oldAddress) {
        this.address = address;
        this.oldAddress = oldAddress;
    }

    public NPSP_Address(Contact con) {
        this.address = new Address__c();
        try {
            address.Household_Account__c = con.AccountId;
        } catch (NullPointerException npe) {
            UTIL_Debug.debug('*** ##### npe on NPSP_Address doing nothing. ######');
        }
        if (con.getPopulatedFieldsAsMap().keySet().contains(
                String.valueOf(Contact.is_Address_Override__c)
        )) {
            address.Default_Address__c = !con.is_Address_Override__c;
        }
        address.Undeliverable__c = con.Undeliverable_Address__c;
        if (con.getPopulatedFieldsAsMap().keySet().contains(
                String.valueOf(Contact.npe01__Primary_Address_Type__c)
        )) {
            copyFromSObject(con, 'Mailing', con.npe01__Primary_Address_Type__c);
        } else {
            copyFromSObject(con, 'Mailing', null);
        }
    }

    public NPSP_Address(NPSP_HouseholdAccount npspHouseholdAccount) {
        this.address = new Address__c();
        address.Household_Account__c = npspHouseholdAccount.getId();
        address.Default_Address__c = true;
        address.Latest_Start_Date__c = System.today();
        address.Latest_End_Date__c = null;
        copyFromSObject(npspHouseholdAccount.getRecord(), 'Billing', null);
    }

    public NPSP_Address(npo02__Household__c household) {
        this.address = new Address__c();
        address.MailingStreet__c = household.npo02__MailingStreet__c;
        address.MailingCity__c = household.npo02__MailingCity__c;
        address.MailingState__c = household.npo02__MailingState__c;
        address.MailingPostalCode__c = household.npo02__MailingPostalCode__c;
        address.MailingCountry__c = household.npo02__MailingCountry__c;
    }

    public NPSP_Address oldVersion() {
        return new NPSP_Address(oldAddress);
    }

    public Boolean isSeasonal() {
        return (this.address.Seasonal_Start_Month__c != null && this.address.Seasonal_Start_Day__c != null &&
                this.address.Seasonal_End_Month__c != null && this.address.Seasonal_End_Day__c != null);
    }

    public Address__c getRecord() {
        return address;
    }

    public String householdId() {
        return this.address.Household_Account__c;
    }

    public Boolean isAddressMatchFuzzyWith(NPSP_Address other) {
        Address__c otherAddress = other.getRecord();

        if (address == null || otherAddress == null) {
            return false;
        }

        Integer cChange = 0;
        if (strCleanup(address.MailingStreet__c) != strCleanup(otherAddress.MailingStreet__c)
                && otherAddress.MailingStreet__c != null) {
            cChange++;
        }
        if (strCleanup(address.MailingStreet2__c) != strCleanup(otherAddress.MailingStreet2__c)
                && otherAddress.MailingStreet2__c != null) {
            cChange++;
        }
        if (strCleanup(address.MailingCity__c) != strCleanup(otherAddress.MailingCity__c)
                && otherAddress.MailingCity__c != null) {
            cChange++;
        }
        if (strCleanup(address.MailingState__c) != strCleanup(otherAddress.MailingState__c)
                && otherAddress.MailingState__c != null) {
            cChange++;
        }
        if (strCleanup(address.MailingPostalCode__c) != strCleanup(otherAddress.MailingPostalCode__c)
                && otherAddress.MailingPostalCode__c != null) {
            cChange++;
        }
        if (strCleanup(address.MailingCountry__c) != strCleanup(otherAddress.MailingCountry__c)
                && otherAddress.MailingCountry__c != null) {
            cChange++;
        }
        if (address.Address_Type__c != null
                && strCleanup(address.Address_Type__c) != strCleanup(otherAddress.Address_Type__c)
                && otherAddress.Address_Type__c != null) {
            cChange++;
        }
        return cChange <= 1;
    }

    public String getAddrKey() {
        String strKey =
                strCleanup(address.MailingStreet__c) +
                        strCleanup(address.MailingStreet2__c) +
                        strCleanup(address.MailingCity__c) +
                        strCleanup(address.MailingState__c) +
                        strCleanup(address.MailingPostalCode__c) +
                        strCleanup(address.MailingCountry__c) +
                        strCleanup(address.Address_Type__c) +
                        (address.Seasonal_Start_Day__c != null ? address.Seasonal_Start_Day__c : '') +
                        (address.Seasonal_Start_Month__c != null ? address.Seasonal_Start_Month__c : '') +
                        (address.Seasonal_End_Day__c != null ? address.Seasonal_End_Day__c : '') +
                        (address.Seasonal_End_Month__c != null ? address.Seasonal_End_Month__c : '');
        return strKey;
    }

    /*******************************************************************************************************
    * @description utility to remove all whitespace and to lowercase the string
    * @param str the string to clean up
    * @return string
    */
    private static String strCleanup(String str) {
        if (str != null) {
            str = str.replace(' ', '');
            str = str.toLowerCase();
        } else {
            str = '';
        }
        return str;
    }

    public Boolean overlapsWith(NPSP_Address other) {
        if (other == null) {
            return false;
        }
        if (!isSeasonal() || !other.isSeasonal()) {
            return false;
        }

        // we don't need to know what year or month we are currently in, but
        // we need to take into account days (since we could be in the same month).
        // to make this easy to compare, we convert month & day to be a decimal of month.day.
        // eg., 3.01 for Feb 1st and 3.28 for Feb 28th.
        Decimal start1 = decimalOfMonthDay(startMonth(), startDay());
        Decimal end1 = decimalOfMonthDay(endMonth(), endDay());
        Decimal start2 = decimalOfMonthDay(other.startMonth(), other.startDay());
        Decimal end2 = decimalOfMonthDay(other.endMonth(), other.endDay());

        // now we see if the ranges are increasing (Jan '14 - March '14), or decreasing (Nov 14' - Feb '15),
        Boolean range1Increases = start1 < end1;
        Boolean range2Increases = start2 < end2;

        // we can now tell if there is overlap simply by looking at three scenarios:
        // 1. both ranges increase, make sure start1 not in range2, and start2 not in range1.
        if (range1Increases && range2Increases) {
            return (start1 >= start2 && start1 <= end2) || (start2 >= start1 && start2 <= end1);
        }
        // 2. one range increases, one range decreases, make sure end1 not in range2, and end2 not in range1.
        else if (range1Increases != range2Increases) {
            return (end1 >= start2 && end1 <= end2) || (end2 >= start1 && end2 <= end1);
        }
        // 3. both ranges decrease, always implies an overlap of the new year!
        else {
            return true;
        }

    }
    public Id getId() {
        return address.Id;
    }
    public String endDay() {
        return address.Seasonal_End_Day__c;
    }

    public String endMonth() {
        return address.Seasonal_End_Month__c;
    }

    public String startDay() {
        return address.Seasonal_Start_Day__c;
    }

    public String startMonth() {
        return address.Seasonal_Start_Month__c;
    }

    public Boolean isEqualToIncludingAddressType(IAddress other, Boolean includeAddressType) {
        if (address == null || other == null) {
            return false;
        }
        if (includeAddressType) {
            if (!addressService.equalsCaseSensitive(getType(), other.getType())) {
                return false;
            }
        }
        return isEqualTo(other);
    }

    private Boolean isEqualTo(IAddress other) {
        return (addressService.equalsCaseSensitive(street(), other.street()) &&
                addressService.equalsCaseSensitive(street2(), other.street2()) &&
                addressService.equalsCaseSensitive(city(), other.city()) &&
                addressService.equalsCaseSensitive(state(), other.state()) &&
                addressService.equalsCaseSensitive(postalCode(), other.postalCode()) &&
                addressService.equalsCaseSensitive(country(), other.country())
        );
    }

    public Boolean isDifferentIncludingLatLong(IAddress other) {
        Boolean isDifferent = (
                        !isEqualToIncludingAddressType(other, false) ||
                        latitude() != other.latitude() ||
                        longitude() != other.longitude()
        );
        return isDifferent;
    }

    /*******************************************************************************************************
    * @description Utility to copy Address fields between two Address objects.
    * @param addrSrc the source Address
    * @param addrDst the destination Address
    * @return void
    */
    public void copyFrom(IAddress other) {
        address.MailingStreet__c = other.street();
        address.MailingStreet2__c = other.street2();
        address.MailingCity__c = other.city();
        address.MailingState__c = other.state();
        address.MailingPostalCode__c = other.postalCode();
        address.MailingCountry__c = other.country();
        address.Geolocation__Latitude__s = other.latitude();
        address.Geolocation__Longitude__s = other.longitude();
        if (other.getType() != null) {
            address.Address_Type__c = other.getType();
        }
    }

    public Boolean isDefault() {
        return address.Default_Address__c;
    }

    public Boolean isNewDefault() {
        return address.Default_Address__c && (address.Default_Address__c != oldAddress.Default_Address__c);
    }

    public Boolean hasDefaultChanged() {
        return address.Default_Address__c != oldAddress?.Default_Address__c;
    }

    public void setAsDefault() {
        address.Default_Address__c = true;
    }

    public String getType() {
        return address.Address_Type__c;
    }

    /*******************************************************************************************************
    * @description utility to copy Address fields from a Contact or Account to an Address object.
    * Handles instances where State and Country picklists are enabled, and multiline street addresses.
    * @param sobjSrc the source Contact or Account
    * @param fieldPrefixSrc the address fields to copy from, ie., Mailing, Other, Shipping, Billing
    * @param addr the Address object to copy to
    * @param addrType if not null, copy to address.Address_Type__c
    * @return void
    */
    public void copyFromSObject(SObject sobjSrc, String fieldPrefixSrc, String addrType) {
        address.MailingStreet__c = (String) getSObjectField(sobjSrc, fieldPrefixSrc, 'Street');
        Addresses.handleMultilineStreet(address);
        address.MailingCity__c = (String) getSObjectField(sobjSrc, fieldPrefixSrc, 'City');
        address.MailingPostalCode__c = (String) getSObjectField(sobjSrc, fieldPrefixSrc, 'PostalCode');
        address.MailingState__c = (String) getSObjectField(sobjSrc, fieldPrefixSrc, 'State');
        address.MailingCountry__c = (String) getSObjectField(sobjSrc, fieldPrefixSrc, 'Country');
        address.Geolocation__Latitude__s = (Decimal) getSObjectField(sobjSrc, fieldPrefixSrc, 'Latitude');
        address.Geolocation__Longitude__s = (Decimal) getSObjectField(sobjSrc, fieldPrefixSrc, 'Longitude');

        if (orgConfig.isStateCountryPicklistsEnabled()) {
            populateAddressCountryFromCountryCode(sobjSrc, fieldPrefixSrc);
            populateAddressStateFromStateCode(sobjSrc, fieldPrefixSrc);
        }

        // if specified, also include Address Type
        if (addrType != null) {
            address.Address_Type__c = addrType;
        }
    }

    private Object getSObjectField(SObject sobjSrc, String fieldPrefixSrc, String field) {
        Object val;
        try {
            val = sobjSrc.get(fieldPrefixSrc + field);
        } catch (Exception e) {
            val = null;
        }
        return val;
    }

    public void checkForPartialSeasonalErrors() {
        if (isPartialSeasonalAddr()) {
            this.address.addError(Label.addrSeasonalPartial);
        }
    }

    /*******************************************************************************************************
    * @description utility to see if the address has only a subset of its seasonal fields set
    * @param addr the Address to look at
    * @return boolean
    */
    private Boolean isPartialSeasonalAddr() {
        Integer cParts = 0;
        if (address.Seasonal_Start_Month__c != null) cParts++;
        if (address.Seasonal_Start_Day__c != null) cParts++;
        if (address.Seasonal_End_Month__c != null) cParts++;
        if (address.Seasonal_End_Day__c != null) cParts++;
        return (cParts > 0 && cParts < 4);
    }

    /*******************************************************************************************************
    * @description utility to create the month and day strings to a decimal we can use in comparisons.
    * @param m the month ordinal as a string
    * @param d the day ordinal as a string
    * @return decimal
    */
    private static Decimal decimalOfMonthDay(String m, String d) {
        if (Integer.valueOf(d) < 10)
            return Decimal.valueOf(m + '.0' + d); else
                return Decimal.valueOf(m + '.' + d);
    }

    /*******************************************************************************************************
    * @description Updates the Address record's MailingCountry field when it is empty
    *              with the Account's BillingCountryCode or Contact's MailingCountryCode value.
    * @param sobjSrc the source Account or Contact
    * @param fieldPrefixSrc the address field to copy from, ie., Mailing, Other, Billing, Shipping
    * @param addr the Address object to update accordingly
    * @return void
    */
    @TestVisible
    private void populateAddressCountryFromCountryCode(SObject sobjSrc, String fieldPrefixSrc) {
        String countryCode = (String) sobjSrc.get(fieldPrefixSrc + 'CountryCode');
        if (String.isBlank(countryCode)) {
            return;
        }

        if (String.isEmpty(address.MailingCountry__c)) {
            address.MailingCountry__c = orgConfig.validCountriesByCode().get(countryCode
                    .toUpperCase());
        }
    }

    /*******************************************************************************************************
    * @description Updates the Address record's MailingState field when it is empty
    *              or does not match the Account's BillingStateCode or Contact's MailingStateCode value.
    * @param sobjSrc the source Account or Contact
    * @param fieldPrefixSrc the address field to copy from, ie., Mailing, Other, Billing, Shipping
    * @return void
    */
    @TestVisible
    private void populateAddressStateFromStateCode(SObject sobjSrc, String fieldPrefixSrc) {
        String stateCode = (String) sobjSrc.get(fieldPrefixSrc + 'StateCode');
        if (String.isBlank(stateCode)) {
            return;
        }

        if (String.isEmpty(address.MailingState__c) || !isMatchingStateCode(stateCode)) {
            // Assume it's a valid statecode since we can't map from Code to State Name
            address.MailingState__c = stateCode;
        }
    }

    /*******************************************************************************************************
    * @description Determines if the Account's BillingStateCode or Contact's MailingStateCode matches the
    *              Address record's Mailing State.
    * @param stateCode the BillingStateCode or MailingStateCode
    * @return void
    */
    @TestVisible
    private Boolean isMatchingStateCode(String stateCode) {
        if (String.isBlank(address.MailingState__c)) {
            return false;
        }

        String mappedMailingState = (orgConfig.validStatesByLabel() == null)
                ? ''
                : orgConfig.validStatesByLabel().get(address.MailingState__c.toUpperCase());

        return stateCode.equalsIgnoreCase(mappedMailingState);
    }

    /*******************************************************************************************************
    * @description utility to see if the address has seasonal fields set
    * @param addr the Address to look at
    * @return boolean
    */
    public Boolean isSeasonalAddr() {
        return (address.Seasonal_Start_Month__c != null && address.Seasonal_Start_Day__c != null &&
                address.Seasonal_End_Month__c != null && address.Seasonal_End_Day__c != null);
    }

    /*******************************************************************************************************
    * @description utility to compare two address objects seasonal fields
    * @param addrNew the new version of the Address
    * @param addrOld the old version of the Address
    * @return boolean. true if any of the seasonal fields have changed on the Address
    */
    private Boolean isSeasonalChanged() {
        if (address == null || oldAddress == null) {
            return false;
        }
        return (
                address.Seasonal_Start_Month__c != oldAddress.Seasonal_Start_Month__c ||
                        address.Seasonal_Start_Day__c != oldAddress.Seasonal_Start_Day__c ||
                        address.Seasonal_End_Month__c != oldAddress.Seasonal_End_Month__c ||
                        address.Seasonal_End_Day__c != oldAddress.Seasonal_End_Day__c);
    }

    public Boolean shouldSyncAddressChangesToContactOverrides() {
        return !isDefault() && (!isEqualToIncludingAddressType(oldVersion(), TRUE) ||
                isUndeliverableStatusChanged());
    }

    public Boolean shouldSyncAddressToHouseholdAccountAndContacts() {
        if (oldAddress == null) {
            return isDefault() ||
                    isSeasonalAddr();
        }

        if (isNewDefault() ||
            isSeasonalChanged() ||
            (isUndeliverableStatusChanged()) && isDefault()) {

            return true;
        } else if (!isEqualToIncludingAddressType(oldVersion(), TRUE)) {
            if (isDefault()) {

                return true;
            }
        }
        return false;
    }

    public void state(String state) {
        address.MailingState__c = state;
    }

    public String street() {
        return address?.MailingStreet__c;
    }

    public String street2() {
        return address?.MailingStreet2__c;
    }

    public String city() {
        return address?.MailingCity__c;
    }

    public String state() {
        return address?.MailingState__c;
    }

    public String postalCode() {
        return address?.MailingPostalCode__c;
    }

    public String country() {
        return address?.MailingCountry__c;
    }

    public Decimal longitude() {
        return address?.Geolocation__Longitude__s;
    }

    public Decimal latitude() {
        return address?.Geolocation__Latitude__s;
    }

    public Boolean isUndeliverable() {
        return address?.Undeliverable__c;
    }

    public Boolean isUndeliverableStatusChanged() {
        return address?.Undeliverable__c != oldAddress.Undeliverable__c;
    }

    public void setUndeliverable(Boolean isUndeliverable) {
        address.Undeliverable__c = isUndeliverable;
    }

    /*******************************************************************************************************
    * @description utility to combine mailing street fields into a single string with embedded CR LF
    * @param addr the Address to look at
    * @return boolean
    */
    public String multilineStreet() {
        Boolean isOneLineStreetAddress = String.isBlank(address.MailingStreet2__c);
        if (isOneLineStreetAddress) {
            return address.MailingStreet__c;
        }
        return address.MailingStreet__c + '\r\n' + address.MailingStreet2__c;
    }

}