public inherited sharing class NPSP_Address implements anAddress {

    private Address__c addr;

    public NPSP_Address(Address__c address) {
        this.addr = address;
    }

    public Boolean isSeasonal() {
        return (this.addr.Seasonal_Start_Month__c != null && this.addr.Seasonal_Start_Day__c != null &&
                this.addr.Seasonal_End_Month__c != null && this.addr.Seasonal_End_Day__c != null);
    }

    public void checkForPartialSeasonalErrors(){
        if (isPartialSeasonalAddr()) {
            this.addr.addError(Label.addrSeasonalPartial);
        }
    }
    /*******************************************************************************************************
    * @description utility to see if the address has only a subset of its seasonal fields set
    * @param addr the Address to look at
    * @return boolean
    */
    private boolean isPartialSeasonalAddr() {
        integer cParts = 0;
        if (addr.Seasonal_Start_Month__c != null) cParts++;
        if (addr.Seasonal_Start_Day__c != null) cParts++;
        if (addr.Seasonal_End_Month__c != null) cParts++;
        if (addr.Seasonal_End_Day__c != null) cParts++;
        return (cParts > 0 && cParts < 4);
    }

    public Address__c getRecord() {
        return this.addr;
    }

    public Boolean belongsToSameHouseholdAs(anAddress other) {
        return householdId() == other.householdId();
    }

    public String householdId() {
        return this.addr.Household_Account__c;
    }

    public Boolean overlapsWith(anAddress other) {
        if (other == null)
            return false;
        if (!isSeasonal() || !other.isSeasonal())
            return false;

        // we don't need to know what year or month we are currently in, but
        // we need to take into account days (since we could be in the same month).
        // to make this easy to compare, we convert month & day to be a decimal of month.day.
        // eg., 3.01 for Feb 1st and 3.28 for Feb 28th.
        decimal start1 = decimalOfMonthDay(startMonth(), startDay());
        decimal end1 = decimalOfMonthDay(endMonth(), endDay());
        decimal start2 = decimalOfMonthDay(other.startMonth(), other.startDay());
        decimal end2 = decimalOfMonthDay(other.endMonth(), other.endDay());

        // now we see if the ranges are increasing (Jan '14 - March '14), or decreasing (Nov 14' - Feb '15),
        boolean range1Increases = start1 < end1;
        boolean range2Increases = start2 < end2;

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

    public String endDay() {
        return addr.Seasonal_End_Day__c;
    }

    public String endMonth() {
        return addr.Seasonal_End_Month__c;
    }

    public String startDay() {
        return addr.Seasonal_Start_Day__c;
    }

    public String startMonth() {
        return addr.Seasonal_Start_Month__c;
    }

    /*******************************************************************************************************
    * @description utility to create the month and day strings to a decimal we can use in comparisons.
    * @param m the month ordinal as a string
    * @param d the day ordinal as a string
    * @return decimal
    */
    private static decimal decimalOfMonthDay(string m, string d) {
        if (integer.valueOf(d) < 10)
            return decimal.valueOf(m + '.0' + d); else
                return decimal.valueOf(m + '.' + d);
    }

    /*******************************************************************************************************
    * @description Utility to copy Address fields from an Address object to a Contact or Account.
    * Handles instances where State and Country picklists are enabled, and multiline street addresses.
    * @param addr the Address object to copy from
    * @param sobjDst the destination Contact or Account
    * @param strFieldPrefix the address fields to copy to, ie., Mailing, Other, Shipping, Billing
    * @param strFieldAddrType an optional Address Type field on sobjDst to copy to
    * @return void
    */
    public void copyOntoSObject(sobject sobjDst, string strFieldPrefix, string strFieldAddrType) {
        sobjDst.put(strFieldPrefix + 'Street', Addresses.getMultilineStreet(addr));
        sobjDst.put(strFieldPrefix + 'City', addr.MailingCity__c);
        sobjDst.put(strFieldPrefix + 'PostalCode', addr.MailingPostalCode__c);
        sobjDst.put(strFieldPrefix + 'Latitude', addr.Geolocation__Latitude__s);
        sobjDst.put(strFieldPrefix + 'Longitude', addr.Geolocation__Longitude__s);

        if (!Addresses.isStateCountryPicklistsEnabled) {
            sobjDst.put(strFieldPrefix + 'State', addr.MailingState__c);
            sobjDst.put(strFieldPrefix + 'Country', addr.MailingCountry__c);
        } else {
            if (addr.MailingCountry__c != null) {
                if (Addresses.validCountriesByLabel.containsKey(addr.MailingCountry__c
                        .toUpperCase()
                )) {
                    sobjDst.put(strFieldPrefix + 'Country', addr.MailingCountry__c);
                    sobjDst.put(strFieldPrefix + 'CountryCode',
                            Addresses.validCountriesByLabel.get(
                                    addr.MailingCountry__c.toUpperCase()));
                } else if (Addresses.validCountriesByCode.containsKey(addr.MailingCountry__c
                        .toUpperCase())) {
                    sobjDst.put(strFieldPrefix + 'CountryCode', addr.MailingCountry__c.toUpperCase());
                    sobjDst.put(strFieldPrefix + 'Country',
                            Addresses.validCountriesByCode.get(
                                    addr.MailingCountry__c.toUpperCase()));
                } else {
                    // allow the invalid country to be placed in the country field, so Salesforce will generate the error.
                    sobjDst.put(strFieldPrefix + 'Country', addr.MailingCountry__c);
                }
            } else { // MailingCountry = null
                sobjDst.put(strFieldPrefix + 'CountryCode', null);
                sobjDst.put(strFieldPrefix + 'Country', null);
            }
            if (addr.MailingState__c != null) {
                if (Addresses.validStatesByLabel.containsKey(addr.MailingState__c
                        .toUpperCase())) {
                    sobjDst.put(strFieldPrefix + 'State', addr.MailingState__c);
                    sobjDst.put(strFieldPrefix + 'StateCode', Addresses.validStatesByLabel
                            .get(addr
                            .MailingState__c.toUpperCase()));
                } else {
                    // too expensive for us to create the map of CountryCode|StateCode to StateLabel
                    // so we will just try to save any state that isn't a label as a code.
                    sobjDst.put(strFieldPrefix + 'StateCode', addr.MailingState__c.toUpperCase());
                }
            } else { // MailingState = null
                sobjDst.put(strFieldPrefix + 'StateCode', null);
                sobjDst.put(strFieldPrefix + 'State', null);
            }
        }

        if (strFieldAddrType != null)
            sobjDst.put(strFieldAddrType, addr.Address_Type__c);

    }

    public Boolean isEqualTo(anAddress other, Boolean includeAddressType) {
        Address__c addrOld = other.getRecord();
        if (addr == null || addrOld == null) {
            return false;
        }
        if (includeAddressType) {
            if (!Addresses.equalsCaseSensitive(
                    addr.Address_Type__c, addrOld.Address_Type__c)) {
                return false;
            }
        }
        return (Addresses.equalsCaseSensitive(
                addr.MailingStreet__c, addrOld.MailingStreet__c) &&
                Addresses.equalsCaseSensitive(
                        addr.MailingStreet2__c, addrOld.MailingStreet2__c) &&
                Addresses.equalsCaseSensitive(
                        addr.MailingCity__c, addrOld.MailingCity__c) &&
                Addresses.equalsCaseSensitive(
                        addr.MailingState__c, addrOld.MailingState__c) &&
                Addresses.equalsCaseSensitive(
                        addr.MailingPostalCode__c, addrOld.MailingPostalCode__c) &&
                Addresses.equalsCaseSensitive(
                        addr.MailingCountry__c, addrOld.MailingCountry__c));
    }

    /*******************************************************************************************************
    * @description Utility to copy Address fields between two Address objects.
    * @param addrSrc the source Address
    * @param addrDst the destination Address
    * @return void
    */
    public void copyFrom(anAddress other) {
        addr.MailingStreet__c = other.getRecord().MailingStreet__c;
        addr.MailingStreet2__c = other.getRecord().MailingStreet2__c;
        addr.MailingCity__c = other.getRecord().MailingCity__c;
        addr.MailingState__c = other.getRecord().MailingState__c;
        addr.MailingPostalCode__c = other.getRecord().MailingPostalCode__c;
        addr.MailingCountry__c = other.getRecord().MailingCountry__c;
        addr.Geolocation__Latitude__s = other.getRecord().Geolocation__Latitude__s;
        addr.Geolocation__Longitude__s = other.getRecord().Geolocation__Longitude__s;
        if (other.getRecord().Address_Type__c != null)
            addr.Address_Type__c = other.getRecord().Address_Type__c;
    }

    public Boolean isDefault() {
        return addr.Default_Address__c;
    }

    public void setAsDefault() {
        addr.Default_Address__c = true;
    }

    public String getType() {
        return addr.Address_Type__c;
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
    public void copyFromSObject(sObject sobjSrc, String fieldPrefixSrc, String addrType) {
        addr.MailingStreet__c = (String) sobjSrc.get(fieldPrefixSrc + 'Street');
        Addresses.handleMultilineStreet(addr);
        addr.MailingCity__c = (String) sobjSrc.get(fieldPrefixSrc + 'City');
        addr.MailingPostalCode__c = (String) sobjSrc.get(fieldPrefixSrc + 'PostalCode');
        addr.MailingState__c = (String) sobjSrc.get(fieldPrefixSrc + 'State');
        addr.MailingCountry__c = (String) sobjSrc.get(fieldPrefixSrc + 'Country');
        addr.Geolocation__Latitude__s = (Decimal) sobjSrc.get(fieldPrefixSrc + 'Latitude');
        addr.Geolocation__Longitude__s = (Decimal) sobjSrc.get(fieldPrefixSrc + 'Longitude');

        if (Addresses.isStateCountryPicklistsEnabled) {
            populateAddressCountryFromCountryCode(sobjSrc, fieldPrefixSrc, addr);
            populateAddressStateFromStateCode(sobjSrc, fieldPrefixSrc, addr);
        }

        // if specified, also include Address Type
        if (addrType != null) {
            addr.Address_Type__c = addrType;
        } else {
            // A null value will force a newly created Address record to use its defined default value for
            // the picklist, which if not reflected here could cause isAddressChanged() to return true
            // in cases when it should not.
            addr.Address_Type__c = Addresses.defaultAddressType;
        }
    }

    /*******************************************************************************************************
    * @description Updates the Address record's MailingCountry field when it is empty
    *              with the Account's BillingCountryCode or Contact's MailingCountryCode value.
    * @param sobjSrc the source Account or Contact
    * @param fieldPrefixSrc the address field to copy from, ie., Mailing, Other, Billing, Shipping
    * @param addr the Address object to update accordingly
    * @return void
    */
    @testVisible
    private static void populateAddressCountryFromCountryCode(sObject sobjSrc, String fieldPrefixSrc, Address__c addr) {
        String countryCode = (String) sobjSrc.get(fieldPrefixSrc + 'CountryCode');
        if (String.isBlank(countryCode)) {
            return;
        }

        if (String.isEmpty(addr.MailingCountry__c)) {
            addr.MailingCountry__c = Addresses.validCountriesByCode.get(countryCode
                    .toUpperCase());
        }
    }

    /*******************************************************************************************************
    * @description Updates the Address record's MailingState field when it is empty
    *              or does not match the Account's BillingStateCode or Contact's MailingStateCode value.
    * @param sobjSrc the source Account or Contact
    * @param fieldPrefixSrc the address field to copy from, ie., Mailing, Other, Billing, Shipping
    * @param addr the Address object to update accordingly
    * @return void
    */
    @testVisible
    private static void populateAddressStateFromStateCode(sObject sobjSrc, String fieldPrefixSrc, Address__c addr) {
        String stateCode = (String) sobjSrc.get(fieldPrefixSrc + 'StateCode');
        if (String.isBlank(stateCode)) {
            return;
        }

        if (String.isEmpty(addr.MailingState__c) || !isMatchingStateCode(stateCode, addr.MailingState__c)) {

            // Assume it's a valid statecode
            addr.MailingState__c = stateCode;
        }
    }

    /*******************************************************************************************************
    * @description Determines if the Account's BillingStateCode or Contact's MailingStateCode matches the
    *              Address record's Mailing State.
    * @param stateCode the BillingStateCode or MailingStateCode
    * @param addressMailingState the Address Mailing State
    * @return void
    */
    @testVisible
    private static Boolean isMatchingStateCode(String stateCode, String addressMailingState) {
        if (String.isBlank(addressMailingState)) {
            return false;
        }

        String mappedMailingState = (Addresses.validStatesByLabel == null)
                ? ''
                : Addresses.validStatesByLabel.get(addressMailingState.toUpperCase());

        return stateCode.equalsIgnoreCase(mappedMailingState);
    }
}