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

    public Boolean equals(anAddress other, Boolean includeAddressType) {
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

}