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
* @description Domain class for Addresses in NPSP.
*/
public inherited sharing class Addresses extends fflib_SObjects {

    /*******************************************************************************************************
    * @description map from Country name (UPPER CASE) to Country Code
    */
    public static Map<String, String> validCountriesByLabel = new Map<String, String>();

    /*******************************************************************************************************
    * @description map from State name (UPPER CASE) to State Code
    */
    public static Map<String, String> validStatesByLabel = new Map<String, String>();

    /*******************************************************************************************************
    * @description map from Country Code to Country Name
    */
    public static Map<String, String> validCountriesByCode = new Map<String, String>();

    private Map<Id, Address__c> oldMap;

    public Addresses(List<Address__c> addresses) {
        super(addresses, Address__c.SObjectType);
    }

    public Addresses(List<Address__c> addresses, List<Address__c> oldList) {
        super(addresses, Address__c.SObjectType);
        this.oldMap = oldList == NULL ?
                new Map<Id, Address__c>() :
                new Map<Id, Address__c>(oldList);
    }

    /********************************************************************************************************
    * @description Retreive the defined default address type picklist value to use when creating a new
    * Address record.
    */
    public static String defaultAddressType {
        get {
            if (defaultAddressType == null) {
                for (Schema.PicklistEntry pv: Address__c.Address_Type__c.getDescribe().getPicklistValues()) {
                    if (pv.isDefaultValue()) {
                        defaultAddressType = pv.getValue();
                        break;
                    }
                }
            }
            return defaultAddressType;
        } private set;
    }

    public Map<Id, Address__c> getMapAddressesByAcctId() {
        Map<Id, Address__c> mapAddressesByAcctId = new Map<Id, Address__c>(); // map of HH Accounts, and their default Address
        for (Address__c address : (List<Address__c>) getRecords()) {
            if (hasHouseholdAccount(address)) {
                mapAddressesByAcctId.put(householdAccountIdFor(address), null);
            }
        }
        return mapAddressesByAcctId;
    }

    private Boolean hasHouseholdAccount(Address__c address) {
        return householdAccountIdFor(address) != null;
    }

    private Id householdAccountIdFor(Address__c address) {
        return address.Household_Account__c;
    }

    public void onBeforeInsert() {
        setLatestDatesOnDefaults();
    }

    public void onBeforeUpdate() {
        updateLatestDatesForDefaultChanges();
    }

    private void setLatestDatesOnDefaults() {
        for (Address__c addr : (List<Address__c>) defaultAddresses().getRecords()) {
            resetLatestStartDateFor(addr);
            resetLatestEndDateFor(addr);
        }
    }

    private void resetLatestEndDateFor(Address__c address) {
        address.Latest_End_Date__c = NULL;
    }

    private void resetLatestStartDateFor(Address__c address) {
        address.Latest_Start_Date__c = system.today();
    }

    private Addresses defaultAddresses() {
        fflib_SObjects defaultAddresses = selectByFieldValue(
                Address__c.Default_Address__c, TRUE);
        return new Addresses(defaultAddresses.getRecords());
    }

    private void updateLatestDatesForDefaultChanges() {
        for (Address__c addr :
                (List<Address__c>) addressesWithDefaultChanges().getRecords()) {
            // when an address changes Default, we update its latest date fields
            if (isDefault(addr)) {
                resetLatestStartDateFor(addr);
                resetLatestEndDateFor(addr);
            } else {
                setEndDateFor(addr);
            }
        }
    }

    private Addresses addressesWithDefaultChanges() {
        List<Address__c> addressesWithDefaultChanges = new List<Address__c>();
        for (Address__c addr : (List<Address__c>) getRecords()) {
            if (isDefaultChanged(addr)) {
                addressesWithDefaultChanges.add(addr);
            }
        }
        return new Addresses(addressesWithDefaultChanges);
    }

    private void setEndDateFor(Address__c addr) {
        addr.Latest_End_Date__c = system.today();
    }

    private Boolean isDefaultChanged(Address__c addr) {
        return isDefault(addr) != isDefault(oldVersionOf(addr));
    }

    private Boolean isDefault(Address__c addr) {
        return addr.Default_Address__c;
    }

    private Address__c oldVersionOf(Address__c addr) {
        return oldMap.get(addr.Id);
    }

    /*******************************************************************************************************
    * @description utility to compare a Contact or Account address to the Address record
    * @param sObj Account or Contact
    * @param addr Address
    * @return boolean. true if any of the Address fields on the Contact are different from this Address record
    */
    public static Boolean shouldUpdateAddress(SObject sObj, Address__c addr) {
        if (sObj == null || addr == null) {
            return false;
        }
        Boolean isContact = (sObj.getSObjectType() == Contact.SObjectType);
        String prefix = (isContact ? 'Mailing' : 'Billing');

        Boolean isDifferent = (
                !equalsCaseSensitive((String) sObj.get(prefix + 'Street'), getMultilineStreet(addr)) ||
                        !equalsCaseSensitive((String) sObj.get(prefix + 'City'), addr.MailingCity__c) ||
                        !equalsCaseSensitive((String) sObj.get(prefix + 'State'), addr.MailingState__c) ||
                        !equalsCaseSensitive((String) sObj.get(prefix + 'PostalCode'), addr.MailingPostalCode__c) ||
                        !equalsCaseSensitive((String) sObj.get(prefix + 'Country'), addr.MailingCountry__c) ||
                        (Decimal) sObj.get(prefix + 'Latitude') != addr.Geolocation__Latitude__s ||
                        (Decimal) sObj.get(prefix + 'Longitude') != addr.Geolocation__Longitude__s ||
                        (isContact &&
                                (!equalsCaseSensitive((String) sObj.get('npe01__Primary_Address_Type__c'), addr.Address_Type__c) ||
                                        !equalsCaseSensitive((String) sObj.get('Current_Address__c'), addr.Id))
                        )
        );
        return isDifferent;
    }

    /*******************************************************************************************************
    * @description Returns whether two strings are equal, using a case sensitve comparison
    * @param str1 The first string
    * @param str2 The second string
    * @return boolean
    ********************************************************************************************************/
    public static Boolean equalsCaseSensitive(String str1, String str2) {
        if (str1 == null) {
            return str2 == null;
        }
        if (str2 == null) {
            return false;
        }
        return str1.equals(str2);
    }

    /*******************************************************************************************************
    * @description utility to compare two address objects address fields
    * @param addrNew the new version of the Address
    * @param addrOld the old version of the Address
    * @param includeAddressType whether to include comparing the AddressType field
    * @return boolean. true if any of the fields fields have changed on the Address
    */
    public static Boolean isAddressChanged(Address__c addrNew, Address__c addrOld, Boolean includeAddressType) {
        if (addrNew == null || addrOld == null) {
            return false;
        }
        return (!equalsCaseSensitive(addrNew.MailingStreet__c, addrOld.MailingStreet__c) ||
                !equalsCaseSensitive(addrNew.MailingStreet2__c, addrOld.MailingStreet2__c) ||
                !equalsCaseSensitive(addrNew.MailingCity__c, addrOld.MailingCity__c) ||
                !equalsCaseSensitive(addrNew.MailingState__c, addrOld.MailingState__c) ||
                !equalsCaseSensitive(addrNew.MailingPostalCode__c, addrOld.MailingPostalCode__c) ||
                !equalsCaseSensitive(addrNew.MailingCountry__c, addrOld.MailingCountry__c) ||
                (includeAddressType && (!equalsCaseSensitive(addrNew.Address_Type__c, addrOld.Address_Type__c))));
    }


    /*******************************************************************************************************
    * @description The main routine for finding the appropriate address to currently use for the
    * household and its contacts.  Prioritizes the Optional mapped Address as the Default
    * address, as well as checking to see if there is a seasonal address that should be used instead.
    * @param mapAccIdAddr a map of Account Id to the Account's default Address.
    * @param dmlWrapper to hold the objects that get updated
    * @param isCalcHHInfoOnly if set, then this routine will return the map of HHId to HHInfo,
    * and not do any changes to dmlWrapper.
    * @return map<Id, HHInfo> a map of Account Id to the HHInfo object for the account
    ********************************************************************************************************/
    public static Map<Id, HHInfo> refreshCurrentHHAddress(Map<Id, Address__c> mapAccIdAddr,
            TDTM_Runnable.DmlWrapper dmlWrapper, Boolean isCalcHHInfoOnly) {

        // assumptions:
        // called after all modifications saved to db
        // so either from a scheduled job,
        // or in the Address AfterUpdate trigger, AFTER any related objects updated
        //
        // strategy:
        // for each hh, get all its addresses (query)
        // for each hh, find all its contacts (query)
        // for each hh, find its current seasonal or default address (loop calculation)
        // for each hh, update its billing fields with seasonal current/default
        // for each hh addr, clear its Default field if it isn't default
        // for each hh contact, if no override, update mailing fields with seasonal current/default
        //

        // get all Addresses by HH, that might need updating
        list<Id> listAccId = new list<Id>(mapAccIdAddr.keySet());
        map<Id, list<Address__c>> mapAccIdListAddrHH = getMapAccIdListAddrHH(listAccId);

        // for each hh, find the current address to use (seasonal vs default)
        map<Id, HHInfo> mapAccIdHHInfo = new map<Id, HHInfo>();
        for (Id accId : listAccId) {
            // create a HHInfo for each household
            HHInfo hhinfo = new HHInfo();
            hhinfo.accId = accId;
            mapAccIdHHInfo.put(accId, hhinfo);

            // if there is a provided Default address, use it over all other defaults.
            Address__c addr = mapAccIdAddr.get(accId);
            if (addr != null && addr.Default_Address__c) {
                hhinfo.addrDefault = addr;
            }

            // go through the hh addresses storing the default and any seasonal
            if (mapAccIdListAddrHH.get(accId) != null) {
                for (Address__c addrHH : mapAccIdListAddrHH.get(accId)) {

                    if (hhinfo.addrDefault == null && addrHH.Default_Address__c) {
                        hhinfo.addrDefault = addrHH;
                    }
                    if (isSeasonalAddr(addrHH)) {
                        Date dtStart = dtStartOrEndOfAddrSeasonal(addrHH, true);
                        Date dtEnd = dtStartOrEndOfAddrSeasonal(addrHH, false);
                        Date dtToday = system.today();
                        if (dtToday >= dtStart && dtToday < dtEnd) {
                            hhinfo.addrSeasonal = addrHH;
                        }
                    }
                }
            }

            // finally, if no default found, create an empty default
            if (hhinfo.addrDefault == null) {
                Address__c addrEmpty = new Address__c();
                addrEmpty.Household_Account__c = accId;
                hhinfo.addrDefault = addrEmpty;
            }
        }

        // some callers just need the HHInfo for each HH Account.
        if (isCalcHHInfoOnly) {
            return mapAccIdHHInfo;
        }

        // get all Contacts by HH, that might need updating
        // note that if we have an organizational account, our query will not pick up any contacts (by design!)
        Map<Id, List<Contact>> mapAccIdListCon = new Map<Id, List<Contact>>();
        Map<Id, Account> accountsById = getAccountsByIds(mapAccIdAddr.keySet());
        Set<Id> setHHId =  mapAccIdAddr.keySet();

        for (Contact con : [SELECT Id, is_Address_Override__c, Current_Address__c, AccountId,
                MailingStreet, MailingCity, MailingState,
                MailingPostalCode, MailingCountry, MailingLatitude, MailingLongitude,
                npe01__Primary_Address_Type__c
        FROM Contact
        WHERE Account.npe01__SYSTEM_AccountType__c = :CAO_Constants.HH_ACCOUNT_TYPE
        AND AccountId != Null
        AND AccountId IN :setHHId]
        ) {
            List<Contact> listConHH = mapAccIdListCon.get(con.AccountId);
            if (listConHH == null) {
                listConHH = new List<Contact>();
                mapAccIdListCon.put(con.AccountId, listConHH);
            }
            listConHH.add(con);
        }

        // lists of objects to update
        List<Account> listAccUpdate = new List<Account>();
        List<Address__c> listAddrUpdate = new List<Address__c>();
        List<Contact> listConUpdate = new List<Contact>();

        // now go through each HH, and do all the work!
        for (Id accId : listAccId) {

            // pick the address to use
            HHInfo hhinfo = mapAccIdHHInfo.get(accId);
            Address__c addrDefault = hhinfo.addrDefault;
            Address__c addr = hhinfo.addrSeasonal;
            if (addr == null) {
                addr = addrDefault;
            }

            // update HH Account's Billing address fields
            Account acc = new Account(Id = accId);
            if (Addresses.shouldUpdateAddress(accountsById.get(accId), addr)) {
                copyAddressAddrSObj(addr, acc, 'Billing', null);
                listAccUpdate.add(acc);
            }

            // check other addresses on this household that are no longer the default
            if (mapAccIdListAddrHH != null && mapAccIdListAddrHH.size() > 0 && mapAccIdListAddrHH.get(accId) != null) {
                for (Address__c addrHH : mapAccIdListAddrHH.get(accId)) {
                    if (addrHH.Id == addrDefault.Id) {
                        continue;
                    }
                    if (addrHH.Default_Address__c) {
                        addrHH.Default_Address__c = false;
                        addrHH.Latest_End_Date__c = System.today();
                        listAddrUpdate.add(addrHH);
                    }
                }
            }

            // check the Contacts on this household
            if (mapAccIdListCon != null && mapAccIdListCon.containsKey(accId)) {
                for (Contact con : mapAccIdListCon.get(accId)) {
                    // detect that the contact's current address was deleted.
                    // and if so clear any override flag so it will get the default address.
                    if (con.Current_Address__c == null) {
                        con.is_Address_Override__c = false;
                    }
                    if (con.is_Address_Override__c == false || con.Current_Address__c == addr.Id) {
                        if (Addresses.shouldUpdateAddress(con, addr)) {
                            con.Current_Address__c = addr.Id;
                            copyAddressAddrSObj(addr, con, 'Mailing', 'npe01__Primary_Address_Type__c');
                            listConUpdate.add(con);
                        }
                    }
                }
            }
        }

        if (listAccUpdate.size() > 0) {
            dmlWrapper.objectsToUpdate.addAll((List<SObject>)listAccUpdate);
        }
        if (listAddrUpdate.size() > 0) {
            dmlWrapper.objectsToUpdate.addAll((List<SObject>)listAddrUpdate);
        }
        if (listConUpdate.size() > 0) {
            dmlWrapper.objectsToUpdate.addAll((List<SObject>)listConUpdate);
        }

        return mapAccIdHHInfo;
    }

    /*******************************************************************************************************
    * @description helper class to keep track of the default and seasonal address for a household
    */
    public class HHInfo {
        public Id accId;
        public Address__c addrDefault;
        public Address__c addrSeasonal;
    }

    /*******************************************************************************************************
    * @description utility to create a map of HH Account Id to a list of Addresses in that HH, given a list of HH Account Id.
    * @param acctIds the list of Account Id's
    * @return map<Id, list<Address__c>> map that contains the Addresses for each HH Account Id
    */
    public static Map<Id, List<Address__c>> getMapAccIdListAddrHH(List<Id> acctIds) {
        Map<Id, List<Address__c>> mapAccIdListAddrHH = new Map<Id, List<Address__c>>();
        List<Address__c> listAddrOther = [
                SELECT Id, Default_Address__c, Household_Account__c, Address_Type__c,
                        MailingStreet__c, MailingStreet2__c, MailingCity__c, MailingState__c,
                        MailingPostalCode__c, MailingCountry__c,
                        Seasonal_Start_Month__c, Seasonal_Start_Day__c, Seasonal_End_Month__c,
                        Seasonal_End_Day__c, Geolocation__Latitude__s, Geolocation__Longitude__s
                FROM Address__c
                WHERE Household_Account__c IN :acctIds
                ORDER BY Default_Address__c DESC, LastModifiedDate ASC
        ]; // ordering needed by cleanupAccountAddresses().
        for (Address__c addr : listAddrOther) {
            List<Address__c> listAddrHH = mapAccIdListAddrHH.get(addr.Household_Account__c);
            if (listAddrHH == null) {
                listAddrHH = new List<Address__c>();
                mapAccIdListAddrHH.put(addr.Household_Account__c, listAddrHH);
            }
            listAddrHH.add(addr);
        }
        return mapAccIdListAddrHH;
    }

    private static Map<Id, Account> getAccountsByIds(Set<Id> acctIds) {
        return new Map<Id, Account>([
                SELECT Id, BillingStreet, BillingCity, BillingState,
                        BillingPostalCode, BillingCountry, BillingLatitude, BillingLongitude
                FROM Account
                WHERE Id IN :acctIds
        ]);
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
    public static void copyAddressAddrSObj(Address__c addr, sobject sobjDst, string strFieldPrefix, string strFieldAddrType) {
        sobjDst.put(strFieldPrefix + 'Street', getMultilineStreet(addr));
        sobjDst.put(strFieldPrefix + 'City', addr.MailingCity__c);
        sobjDst.put(strFieldPrefix + 'PostalCode', addr.MailingPostalCode__c);
        sobjDst.put(strFieldPrefix + 'Latitude', addr.Geolocation__Latitude__s);
        sobjDst.put(strFieldPrefix + 'Longitude', addr.Geolocation__Longitude__s);

        if (!isStateCountryPicklistsEnabled) {
            sobjDst.put(strFieldPrefix + 'State', addr.MailingState__c);
            sobjDst.put(strFieldPrefix + 'Country', addr.MailingCountry__c);
        } else {
            if (addr.MailingCountry__c != null) {
                if (validCountriesByLabel.containsKey(addr.MailingCountry__c.toUpperCase())) {
                    sobjDst.put(strFieldPrefix + 'Country', addr.MailingCountry__c);
                    sobjDst.put(strFieldPrefix + 'CountryCode', validCountriesByLabel.get(addr.MailingCountry__c.toUpperCase()));
                } else if (validCountriesByCode.containsKey(addr.MailingCountry__c.toUpperCase())) {
                    sobjDst.put(strFieldPrefix + 'CountryCode', addr.MailingCountry__c.toUpperCase());
                    sobjDst.put(strFieldPrefix + 'Country', validCountriesByCode.get(addr.MailingCountry__c.toUpperCase()));
                } else {
                    // allow the invalid country to be placed in the country field, so Salesforce will generate the error.
                    sobjDst.put(strFieldPrefix + 'Country', addr.MailingCountry__c);
                }
            } else { // MailingCountry = null
                sobjDst.put(strFieldPrefix + 'CountryCode', null);
                sobjDst.put(strFieldPrefix + 'Country', null);
            }
            if (addr.MailingState__c != null) {
                if (validStatesByLabel.containsKey(addr.MailingState__c.toUpperCase())) {
                    sobjDst.put(strFieldPrefix + 'State', addr.MailingState__c);
                    sobjDst.put(strFieldPrefix + 'StateCode', validStatesByLabel.get(addr.MailingState__c.toUpperCase()));
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

    /*******************************************************************************************************
    * @description utility to combine mailing street fields into a single string with embedded CR LF
    * @param addr the Address to look at
    * @return boolean
    */
    public static String getMultilineStreet(Address__c addr) {
        Boolean isOneLineStreetAddress = String.isBlank(addr.MailingStreet2__c);
        if (isOneLineStreetAddress) {
            return addr.MailingStreet__c;
        }
        return addr.MailingStreet__c + '\r\n' + addr.MailingStreet2__c;
    }

    /*******************************************************************************************************
    * @description specifies whether state and country picklists are enabled in this org.
    * @return true if enabled
    */
    public static Boolean isStateCountryPicklistsEnabled {
        get {
            if (isStateCountryPicklistsEnabled == null)
                isStateCountryPicklistsEnabled = initValidStateCountryCodes();
            return isStateCountryPicklistsEnabled;
        }
        private set;
    }

    /*******************************************************************************************************
    * @description utility to determine if the "State and Country Picklist" field feature is enabled in Salesforce
    * @return true if enabled; Fills 4 sets<> with a list of value codes and labels for each field
    */
    private static Boolean initValidStateCountryCodes() {

        // If State & Country Picklists are enabled in the org, build maps of the
        // valid Labels and Codes for each field to use for validation
        map<String, Schema.SObjectField> acctFields = Account.getSobjectType().getDescribe().fields.getMap();
        boolean isCodesEnabled = acctFields.containsKey('BillingCountryCode');
        if (isCodesEnabled) {
            list<Schema.Picklistentry> countryPLValues = acctFields.get('BillingCountryCode').getDescribe().getPicklistValues();
            for (Schema.Picklistentry p : countryPLValues) {
                if (p.isActive()) {
                    validCountriesByLabel.put(p.getLabel().toUpperCase(), p.getValue());
                    validCountriesByCode.put(p.getValue(), p.getLabel());
                }
            }
            list<Schema.Picklistentry> statePLValues = acctFields.get('BillingStateCode').getDescribe().getPicklistValues();
            for (Schema.Picklistentry p : statePLValues) {
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
    /*******************************************************************************************************
    * @description utility to return the current StartDate or EndDate of a Seasonal Address
    * @param addr the Address to look at
    * @param fStart whether to return the StartDate or EndDate
    * @return Date
    */
    private static Date dtStartOrEndOfAddrSeasonal(Address__c addr, boolean fStart) {
        integer startMonth = integer.valueOf(addr.Seasonal_Start_Month__c);
        integer startDay = integer.valueOf(addr.Seasonal_Start_Day__c);
        integer endMonth = integer.valueOf(addr.Seasonal_End_Month__c);
        integer endDay = integer.valueOf(addr.Seasonal_End_Day__c);
        Date dtStart;
        Date dtEnd;
        Date dtToday = system.today();
        //seasonal address is contained within a single year
        if (startMonth <= endMonth) {
            dtStart = date.newInstance(dtToday.year(), startMonth, startDay);
            dtEnd = date.newInstance(dtToday.year(), endMonth, endDay);
            //seasonal address overlaps the year, and this month is past the start month
        } else if (startMonth <= dtToday.month()){
            dtStart = date.newInstance(dtToday.year(), startMonth, startDay);
            dtEnd = date.newInstance(dtToday.year()+1, endMonth, endDay);
            //seasonal address overlaps the year, and this month is before the start month
        } else {
            dtStart = date.newInstance(dtToday.year()-1, startMonth, startDay);
            dtEnd = date.newInstance(dtToday.year(), endMonth, endDay);
        }
        return (fStart ? dtStart : dtEnd);
    }

    /*******************************************************************************************************
    * @description utility to see if the address has seasonal fields set
    * @param addr the Address to look at
    * @return boolean
    */
    public static boolean isSeasonalAddr(Address__c addr) {
        return (addr.Seasonal_Start_Month__c != null && addr.Seasonal_Start_Day__c != null &&
                addr.Seasonal_End_Month__c != null && addr.Seasonal_End_Day__c != null);
    }

}