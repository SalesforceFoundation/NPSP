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
* @description Address Service class in NPSP.
*/
public inherited sharing class AddressService {

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

    /*******************************************************************************************************
    * @description Utility to copy Address fields between Contacts and Accounts (or vice-versa).
    * Handles instances where State and Country picklists are enabled, and multiline street addresses.
    * @param sobjSrc the source Contact or Account
    * @param strFieldPrefixSrc the address fields to copy from, ie., Mailing, Other, Shipping, Billing
    * @param sobjDst the destination Contact or Account
    * @param strFieldPrefixDst the address fields to copy to, ie., Mailing, Other, Shipping, Billing
    */
    public void copyAddressStdSObj(SObject sobjSrc, String strFieldPrefixSrc, SObject sobjDst, String strFieldPrefixDst) {
        sobjDst.put(strFieldPrefixDst + 'Street', sobjSrc.get(strFieldPrefixSrc + 'Street'));
        sobjDst.put(strFieldPrefixDst + 'City', sobjSrc.get(strFieldPrefixSrc + 'City'));
        sobjDst.put(strFieldPrefixDst + 'PostalCode', sobjSrc.get(strFieldPrefixSrc + 'PostalCode'));
        sobjDst.put(strFieldPrefixDst + 'State', sobjSrc.get(strFieldPrefixSrc + 'State'));
        sobjDst.put(strFieldPrefixDst + 'Country', sobjSrc.get(strFieldPrefixSrc + 'Country'));
        sobjDst.put(strFieldPrefixDst + 'Latitude', sobjSrc.get(strFieldPrefixSrc + 'Latitude'));
        sobjDst.put(strFieldPrefixDst + 'Longitude', sobjSrc.get(strFieldPrefixSrc + 'Longitude'));

        if (orgConfig.isStateCountryPicklistsEnabled()) {
            sobjDst.put(strFieldPrefixDst + 'StateCode', sobjSrc.get(strFieldPrefixSrc + 'StateCode'));
            sobjDst.put(strFieldPrefixDst + 'CountryCode', sobjSrc.get(strFieldPrefixSrc + 'CountryCode'));
        }
    }

    /*******************************************************************************************************
    * @description utility to compare a Contact or Account address to the Address record
    * @param sObj Account or Contact
    * @param addr Address
    * @return boolean. true if any of the Address fields on the Contact are different from this Address record
    */
    public Boolean isSObjectAddressDifferent(SObject sObj, IAddress other) {
        Address__c addr = (Address__c) other.getRecord();
        if (sObj == null || addr == null) {
            return false;
        }
        String prefix = ((sObj.getSObjectType() == Contact.SObjectType) ? 'Mailing' : 'Billing');

        Boolean isDifferent = isDifferentIncludingLatLong(sObj, prefix, other);
        return isDifferent;
    }

    private Boolean isDifferentIncludingLatLong(SObject sObj, String prefix, IAddress other) {
        return (
                !equalsCaseSensitive((String) sObj.get(prefix + 'Street'), other.multilineStreet()) ||
                        !equalsCaseSensitive((String) sObj.get(prefix + 'City'), other.city()) ||
                        !equalsCaseSensitive((String) sObj.get(prefix + 'State'), other.state()) ||
                        !equalsCaseSensitive((String) sObj.get(prefix + 'PostalCode'), other.postalCode()) ||
                        !equalsCaseSensitive((String) sObj.get(prefix + 'Country'), other.country()) ||
                        (Decimal) sObj.get(prefix + 'Latitude') != other.latitude() ||
                        (Decimal) sObj.get(prefix + 'Longitude') != other.longitude()
        );
    }

    /*******************************************************************************************************
    * @description For the list of Addresses, sees if there is already an existing Address in the Account that
    * matches. Creates only unique addresses from their respective household, and mark any existing matches
    * as Default if the caller specifies it on the new address.
    * @param addresses a list of Addresses to update
    * @param dmlWrapper the Addresses to update
    * @param includeAddressType whether to include comparing the AddressType field
    */
    public static void createAddressesFor(AccountAdapter accounts,
            TDTM_Runnable.DmlWrapper dmlWrapper, Boolean includeAddressType) {

        Map<Address__c, Address__c> existingAddressesByAddress = Addresses.getExistingAddresses(
                accounts.allAddresses());
        Map<Id, Account> accountsById = getAccountsById(accounts);

        for (Address__c newAddress : accounts.allAddresses()) {
            NPSP_Address npspNewAddress = new NPSP_Address(newAddress);
            Address__c existingAddress = existingAddressesByAddress.get(newAddress);
            NPSP_Address npspExistingAddress = new NPSP_Address(existingAddress);
            Boolean isAddressUpdated;

            if (existingAddress != null) {
                NPSP_HouseholdAccount npspExistingAddressHousehold = new NPSP_HouseholdAccount(
                        accountsById.get(npspExistingAddress.householdId()),
                        accounts.oldMap.get(npspExistingAddress.householdId())
                );
                // if it is a fuzzy match, not exact, then we want to update the existing address.
                if (!npspNewAddress.isEqualToIncludingAddressType(npspExistingAddress, includeAddressType)) {
                    npspExistingAddress.copyFrom(npspNewAddress);
                    if (npspNewAddress.isDefault()) {
                        npspExistingAddress.setAsDefault();
                    }
                    isAddressUpdated = true;
                } else if (npspNewAddress.isDefault() && !npspExistingAddress.isDefault()) {
                    npspExistingAddress.setAsDefault();
                    isAddressUpdated = true;
                } else if (npspExistingAddressHousehold.isUndeliverableStatusChanged()) {
                    npspExistingAddress.setUndeliverable(npspExistingAddressHousehold.undeliverableAddressStatus());
                    isAddressUpdated = true;
                }
                if (isAddressUpdated) {
                    dmlWrapper.objectsToUpdate.add(existingAddress);
                }
            } else {
                NPSP_HouseholdAccount npspHouseholdAccount = new NPSP_HouseholdAccount(
                    accountsById.get(npspNewAddress.householdId())
                );
                npspNewAddress.setUndeliverable(npspHouseholdAccount.undeliverableAddressStatus());
                dmlWrapper.objectsToInsert.add(npspNewAddress.getRecord());
            }
        }
    }

    private static Map<Id, Account> getAccountsById(AccountAdapter accounts) {
        Map<Id, Account> accountsById = new Map<Id, Account>();
        for (Account account : (List<Account>) accounts.getRecords()) {
            accountsById.put(account.Id, account);
        }

        return accountsById;
    }

    public static Boolean isAddressManagementEnabled() {
        if (!UTIL_CustomSettingsFacade.getContactsSettings().Household_Account_Addresses_Disabled__c) {
            return true;
        }
        return false;
    }

    public static Boolean isOrgAccountAddressesEnabled() {
        if (UTIL_CustomSettingsFacade.getContactsSettings().Organizational_Account_Addresses_Enabled__c) {
            return true;
        }
        return false;
    }

    /*******************************************************************************************************
    * @description Returns whether two strings are equal, using a case sensitve comparison
    * @param str1 The first string
    * @param str2 The second string
    * @return boolean
    ********************************************************************************************************/
    public Boolean equalsCaseSensitive(String str1, String str2) {
        if (str1 == null) {
            return str2 == null;
        }
        if (str2 == null) {
            return false;
        }
        return str1.equals(str2);
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
    public void copyOntoSObject(IAddress anAddress, SObject sobjDst,
            String strFieldPrefix, String strFieldAddrType) {
        Address__c addr = (Address__c) anAddress.getRecord();

        sobjDst.put(strFieldPrefix + 'Street', anAddress.multilineStreet());
        sobjDst.put(strFieldPrefix + 'City', addr.MailingCity__c);
        sobjDst.put(strFieldPrefix + 'PostalCode', addr.MailingPostalCode__c);
        sobjDst.put(strFieldPrefix + 'Latitude', addr.Geolocation__Latitude__s);
        sobjDst.put(strFieldPrefix + 'Longitude', addr.Geolocation__Longitude__s);

        if (!orgConfig.isStateCountryPicklistsEnabled()) {
            sobjDst.put(strFieldPrefix + 'State', addr.MailingState__c);
            sobjDst.put(strFieldPrefix + 'Country', addr.MailingCountry__c);
        } else {
            if (addr.MailingCountry__c != null) {
                if (orgConfig.validCountriesByLabel().containsKey(addr.MailingCountry__c
                        .toUpperCase()
                )) {
                    sobjDst.put(strFieldPrefix + 'Country', addr.MailingCountry__c);
                    sobjDst.put(strFieldPrefix + 'CountryCode',
                            orgConfig.validCountriesByLabel().get(
                                    addr.MailingCountry__c.toUpperCase()));
                } else if (orgConfig.validCountriesByCode().containsKey(addr.MailingCountry__c
                        .toUpperCase())) {
                    sobjDst.put(strFieldPrefix + 'CountryCode', addr.MailingCountry__c.toUpperCase());
                    sobjDst.put(strFieldPrefix + 'Country',
                            orgConfig.validCountriesByCode().get(
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
                if (orgConfig.validStatesByLabel().containsKey(addr.MailingState__c
                        .toUpperCase())) {
                    sobjDst.put(strFieldPrefix + 'State', addr.MailingState__c);
                    sobjDst.put(strFieldPrefix + 'StateCode', orgConfig.validStatesByLabel()
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
}