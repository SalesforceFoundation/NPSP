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
                !equalsCaseSensitive((String) sObj.get(prefix + 'Street'),
                        ADDR_Addresses_TDTM.getMultilineStreet(addr)) ||
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

}