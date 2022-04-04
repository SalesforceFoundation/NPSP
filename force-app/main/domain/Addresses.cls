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
public inherited sharing class Addresses extends fflib_SObjects2 {

    private Map<Id, Address__c> oldMap;

    @TestVisible
    private TDTM_Runnable.DmlWrapper dmlWrapperLocal {
        get {
            if (dmlWrapperLocal == null) {
                dmlWrapperLocal = new TDTM_Runnable.DmlWrapper();
            }
            return dmlWrapperLocal;
        }
        set;
    }

    @TestVisible
    private ContactSelector contactSelector {
        get {
            if (contactSelector == null) {
                contactSelector = new ContactSelector();
            }
            return contactSelector;
        }
        set;
    }

    private static OrgConfig orgConfig {
        get {
            if (orgConfig == null) {
                orgConfig = new OrgConfig();
            }
            return orgConfig;
        }
        set;
    }

    public Addresses(List<Address__c> addresses) {
        super(addresses, Address__c.SObjectType);
    }

    public Addresses(List<Address__c> addresses, List<Address__c> oldList) {
        super(addresses, Address__c.SObjectType);
        this.oldMap = oldList == NULL ?
                new Map<Id, Address__c>() :
                new Map<Id, Address__c>(oldList);
    }

    public void onBeforeInsert() {
        setLatestDatesOnDefaults();
        verifyAddrHHAccOnly();
        verifyAddrSeasonalNoOverlap();
    }

    public void onAfterInsert() {
        syncAddressesForAccountsAndContacts(addressChangesToSyncToHouseholdAccountsAndContacts(),
                dmlWrapperLocal, false);

        // we must process dmlWrapperLocal ourselves, so we can extract out the appropriate
        // errors
        // that might occur updating contacts and accounts, and associating those errors with
        // the correct addresses.
        ERR_Handler.Errors errors = TDTM_TriggerHandler.processDMLAllOrNothing
            (dmlWrapperLocal, false);
        if (errors.errorsExist) {
            putErrorsOnAddresses(errors, addressesByAccountId(), new Map<Id, Address__c>());
        }

        // hack to detect empty addresses and delete them after we've propagated the change to all contacts and account
        deleteEmptyAddresses();
    }

    public void onBeforeUpdate() {
        updateLatestDatesForDefaultChanges();
        verifyAddrHHAccOnly();
        verifyAddrSeasonalNoOverlap();
    }

    public void onAfterUpdate() {

        if (addressChangesToSyncToHouseholdAccountsAndContacts().size() > 0) {
            syncAddressesForAccountsAndContacts(addressChangesToSyncToHouseholdAccountsAndContacts(),
                dmlWrapperLocal, false);
        }

        if (addressChangesToSyncToContactOverrides().size() > 0) {
            HouseholdMembers.syncAddressChangesToContactOverrides(addressChangesToSyncToContactOverrides()
                    , dmlWrapperLocal);
        }

        // we must process dmlWrapper ourselves, so we can extract out the appropriate errors
        // that might occur updating contacts and accounts, and associating those errors with
        // the correct addresses.
        ERR_Handler.Errors errors =
                TDTM_TriggerHandler.processDMLAllOrNothing(
                        dmlWrapperLocal, false);
        if (errors.errorsExist) {
            putErrorsOnAddresses(errors, addressChangesToSyncToHouseholdAccountsAndContacts(),
                addressChangesToSyncToContactOverrides());
        }
    }

    public void onAfterDelete() {
        Map<Id, Address__c> addressesByAccountId = addressesByAccountId();
        if (!addressesByAccountId.isEmpty()) {
            clearAddressesForEachAccount(addressesByAccountId);
            syncAddressesForAccountsAndContacts(addressesByAccountId, dmlWrapperLocal,
                    false);
        }

        // we must process dmlWrapperLocal ourselves, so we can extract out the appropriate errors
        // that might occur updating contacts and accounts, and associating those errors with
        // the correct addresses.
        ERR_Handler.Errors errors = TDTM_TriggerHandler.processDMLAllOrNothing(dmlWrapperLocal,
                false);
        if (errors.errorsExist) {
            putErrorsOnAddresses(errors, addressesByAccountId(), new Map<Id, Address__c>());
        }
    }

    private void clearAddressesForEachAccount(Map<Id, Address__c> addressesByAccountId) {
        for (Id accountId : addressesByAccountId.keySet()) {
            addressesByAccountId.put(accountId, null);
        }
    }

    /*******************************************************************************************************
    * @description The main routine for finding the appropriate address to currently use for the
    * household and its contacts.  Prioritizes the Optional mapped Address as the Default
    * address, as well as checking to see if there is a seasonal address that should be used instead.
    * @param defaultSeasonalAddressesByAccountId a map of Account Id to the Account's default Address.
    * @param dmlWrapper to hold the objects that get updated
    * @param shouldReturnHouseholdInfoOnly if set, then this routine will return the map of HHId to HHInfo,
    * and not do any changes to dmlWrapper.
    * @return map<Id, HHInfo> a map of Account Id to the HHInfo object for the account
    ********************************************************************************************************/
    public static Map<Id, HouseholdInfo> syncAddressesForAccountsAndContacts(
            Map<Id, Address__c> defaultSeasonalAddressesByAccountId,
            TDTM_Runnable.DmlWrapper dmlWrapper, Boolean shouldReturnHouseholdInfoOnly) {

        List<Id> accountIds = new List<Id>(defaultSeasonalAddressesByAccountId.keySet());
        Map<Id, List<Address__c>> allAddressesByAccountId = getAllAddressesByAccountId(accountIds);

        // for each hh, find the current address to use (seasonal vs default)
        Map<Id, HouseholdInfo> householdInfoByAccountId = getHouseholdAccountAddressInfoByAccountId(new
                Set<Id>(accountIds),
                defaultSeasonalAddressesByAccountId, allAddressesByAccountId);

        // some callers just need the HHInfo for each HH Account.
        if (shouldReturnHouseholdInfoOnly) {
            return householdInfoByAccountId;
        }

        // get all Contacts by HH, that might need updating
        // note that if we have an organizational account, our query will not pick up any contacts (by design!)
        Map<Id, List<Contact>> contactsByHouseholdAccountId = getContactsByHouseholdAccountId(new Set<Id>(accountIds));

        // now go through each HH, and do all the work!
        AddressAndRelationshipsToUpdate addressAndRelationshipsToUpdate = updateAddressInfoForAccountsAndContacts(
                new Set<Id>(accountIds),
                householdInfoByAccountId,
                allAddressesByAccountId,
                contactsByHouseholdAccountId
        );

        if (addressAndRelationshipsToUpdate.accountsToUpdate.size() > 0) {
            dmlWrapper.objectsToUpdate.addAll((List<SObject>)addressAndRelationshipsToUpdate.accountsToUpdate);
        }
        if (addressAndRelationshipsToUpdate.addressesToUpdate.size() > 0) {
            dmlWrapper.objectsToUpdate.addAll((List<SObject>)addressAndRelationshipsToUpdate.addressesToUpdate);
        }
        if (addressAndRelationshipsToUpdate.contactsToUpdate.size() > 0) {
            dmlWrapper.objectsToUpdate.addAll((List<SObject>)addressAndRelationshipsToUpdate.contactsToUpdate);
        }


        return householdInfoByAccountId;
    }

    private static Map<Id, List<Contact>> getContactsByHouseholdAccountId(Set<Id> accountIds) {
            Map<Id, List<Contact>> contactsByHouseholdAccountId = new Map<Id, List<Contact>>();

        for (Contact contact : contactSelector.getContactAddressFieldsForContactAccountsIn(accountIds)) {
            List<Contact> householdContacts = contactsByHouseholdAccountId.get(contact.AccountId);
            if (householdContacts == null) {
                householdContacts = new List<Contact>();
                contactsByHouseholdAccountId.put(contact.AccountId, householdContacts);
            }
            householdContacts.add(contact);
        }
        return contactsByHouseholdAccountId;
    }

    private static NPSP_Address getAddressToSyncToAccountsAndContacts(Id accountId,
            Map<Id, HouseholdInfo> householdInfoByAccountId) {

        HouseholdInfo householdInfo = householdInfoByAccountId.get(accountId);

        return new NPSP_Address(householdInfo.seasonalAddress != null ?
               householdInfo.seasonalAddress : householdInfo.defaultAddress);
    }

    private static AddressAndRelationshipsToUpdate updateAddressInfoForAccountsAndContacts(Set<Id> accountIds,
            Map<Id, HouseholdInfo> householdInfoByAccountId,
            Map<Id, List<Address__c>> allAddressesByAccountId,
            Map<Id, List<Contact>> contactsByHouseholdAccountId) {

        List<Account> accountsToUpdate = new List<Account>();
        List<Address__c> addressesToUpdate = new List<Address__c>();
        List<Contact> contactsToUpdate = new List<Contact>();
        Map<Id, Account> accountsById = getAccountsByIds(accountIds);

        for (Id accountId : accountsById.keySet()) {

            NPSP_Address addressToSyncToAccountsAndContacts = getAddressToSyncToAccountsAndContacts(accountId,
                householdInfoByAccountId);

            NPSP_HouseholdAccount npspHouseholdAccount = new NPSP_HouseholdAccount(accountsById.get(accountId));
            updateAccountAddress(npspHouseholdAccount, addressToSyncToAccountsAndContacts, accountsToUpdate);
            clearAccountAddressDefaults(allAddressesByAccountId,
                accountId, householdInfoByAccountId, addressesToUpdate);

            updateAddressForHouseholdContacts(contactsByHouseholdAccountId,
                accountId, npspHouseholdAccount, addressToSyncToAccountsAndContacts, contactsToUpdate);

        }

        return new AddressAndRelationshipsToUpdate(accountsToUpdate, addressesToUpdate, contactsToUpdate);
    }

    private static void updateAccountAddress(NPSP_HouseholdAccount npspHouseholdAccount,
            NPSP_Address addressToSyncToAccountsAndContacts, List<Account> accountsToUpdate) {

        Boolean accountUpdated = false;

        if (shouldUpdateBillingAddress(npspHouseholdAccount, addressToSyncToAccountsAndContacts)) {
            npspHouseholdAccount.setBillingAddress(addressToSyncToAccountsAndContacts);
            accountUpdated = true;
        }

        if (shouldUpdateBillingAddressUndeliverableStatus(npspHouseholdAccount,
                addressToSyncToAccountsAndContacts)) {

            npspHouseholdAccount.setBillingAddressUndeliverableStatus(
                    addressToSyncToAccountsAndContacts.isUndeliverable());
            accountUpdated = true;
        }
        if (accountUpdated) {
            accountsToUpdate.add(npspHouseholdAccount.getRecord());
        }
    }

    private static void updateAddressForHouseholdContacts(Map<Id, List<Contact>> contactsByHouseholdAccountId,
            Id accountId, NPSP_HouseholdAccount npspHouseholdAccount,
            NPSP_Address addressToSyncToAccountsAndContacts, List<Contact> contactsToUpdate) {

        if (accountHasContacts(contactsByHouseholdAccountId, accountId)) {
            for (Contact contact : contactsByHouseholdAccountId.get(accountId)) {
                NPSP_Contact npspContact = new NPSP_Contact(contact);

                Boolean shouldUpdateContact= false;
                // detect that the contact's current address was deleted.
                // and if so clear any override flag so it will get the default address.
                if (npspContact.currentAddress() == null) {
                    npspContact.getRecord().is_Address_Override__c = false;
                }

                if (!npspContact.hasAddressOverride() ||
                        npspContact.currentAddress() == addressToSyncToAccountsAndContacts.getId()) {

                    if (npspContact.isUndeliverableMailingAddress() !=
                            addressToSyncToAccountsAndContacts.isUndeliverable()) {
                        npspContact.setUndeliverableMailingAddress(
                            addressToSyncToAccountsAndContacts.isUndeliverable());

                        shouldUpdateContact = true;
                    }

                    if (npspContact.mailingAddressIsDifferentFrom(addressToSyncToAccountsAndContacts)) {
                        npspContact.setCurrentAddress(addressToSyncToAccountsAndContacts);

                        shouldUpdateContact = true;
                    }

                }
                if (shouldUpdateContact) {
                    contactsToUpdate.add(contact);
                }
            }
        }
    }

    private static Boolean accountHasContacts(Map<Id, List<Contact>> contactsByHouseholdAccountId, Id accountId) {
        return contactsByHouseholdAccountId != null && contactsByHouseholdAccountId.containsKey(accountId);
    }

    private static void clearAccountAddressDefaults(Map<Id, List<Address__c>> allAddressesByAccountId,
        Id accountId, Map<Id, HouseholdInfo> householdInfoByAccountId, List<Address__c> addressesToUpdate) {

        if (accountHasAddresses(allAddressesByAccountId, accountId)) {
            for (Address__c address : allAddressesByAccountId.get(accountId)) {
                HouseholdInfo householdInfo = householdInfoByAccountId.get(accountId);
                NPSP_Address npspAddress = new NPSP_Address(address);
                if (npspAddress.getRecord().Id == householdInfo.defaultAddress.Id) {
                    continue;
                }

                if (npspAddress.isDefault()) {
                    address.Default_Address__c = false;
                    address.Latest_End_Date__c = System.today();
                    addressesToUpdate.add(address);
                }
            }
        }
    }

    private static Boolean accountHasAddresses(Map<Id, List<Address__c>> allAddressesByAccountId, Id accountId) {
        return allAddressesByAccountId != null && allAddressesByAccountId.size() > 0 &&
               allAddressesByAccountId.get(accountId) != null;
    }

    private static Boolean shouldUpdateBillingAddressUndeliverableStatus(NPSP_HouseholdAccount npspHouseholdAccount,
            NPSP_Address addressToSyncToAccountsAndContacts) {
        return npspHouseholdAccount.undeliverableAddressStatus() !=
                addressToSyncToAccountsAndContacts.isUndeliverable();
    }

    private static Boolean shouldUpdateBillingAddress(NPSP_HouseholdAccount npspHouseholdAccount,
            NPSP_Address addressToSyncToAccountsAndContacts) {
        return npspHouseholdAccount.billingAddressIsDifferentFrom(addressToSyncToAccountsAndContacts);
    }

    private static Map<Id, HouseholdInfo> getHouseholdAccountAddressInfoByAccountId(Set<Id> accountIds, Map<Id,
            Address__c> defaultSeasonalAddressesByAccountId, Map<Id, List<Address__c>> allAddressesByAccountId) {
        Map<Id, HouseholdInfo> householdInfoByAccountId = new Map<Id, HouseholdInfo>();
        setAddressForHouseholdInfo(accountIds,
                defaultSeasonalAddressesByAccountId,
                allAddressesByAccountId,
                householdInfoByAccountId);

        return householdInfoByAccountId;
    }

    private static void setAddressForHouseholdInfo(Set<Id> accountIds, Map<Id, Address__c>
            defaultSeasonalAddressesByAccountId, Map<Id, List<Address__c>> allAddressesByAccountId,
            Map<Id, HouseholdInfo> householdInfoByAccountId) {

        for (Id accountId : accountIds) {
            // create a HHInfo for each household
            HouseholdInfo householdInfo = getHouseholdInfoForAccount(accountId);

            // if there is a provided Default address, use it over all other defaults.
            setHouseholdAddressesToDefaultAddress(defaultSeasonalAddressesByAccountId, accountId,
                householdInfo, allAddressesByAccountId);

            // finally, if no default found, create an empty default
            if (householdHasNoDefaultAddress(householdInfo)) {
                setNewHouseholdDefaultAddress(accountId, householdInfo);
            }
            householdInfoByAccountId.put(accountId, householdInfo);
        }
    }

    private static void setNewHouseholdDefaultAddress(Id accountId, HouseholdInfo householdInfo) {
        Address__c defaultAddress = new Address__c();
        defaultAddress.Household_Account__c = accountId;
        householdInfo.defaultAddress = defaultAddress;
    }

    private static Boolean householdHasNoDefaultAddress(HouseholdInfo householdInfo) {
        return householdInfo.defaultAddress == null;
    }

    private static void setHouseholdAddressesToDefaultAddress(Map<Id, Address__c> defaultSeasonalAddressesByAccountId,
            Id accountId, HouseholdInfo householdInfo, Map<Id, List<Address__c>> allAddressesByAccountId) {
        Address__c accountAddress = defaultSeasonalAddressesByAccountId.get(accountId);
        if (accountAddress != null) {
            NPSP_Address accountNpspAddress = new NPSP_Address(accountAddress);
            if (accountNpspAddress.isDefault()) {
                householdInfo.defaultAddress = accountNpspAddress.getRecord();
            }
        }

        // go through the hh addresses storing the default and any seasonal
        if (allAddressesByAccountId.get(accountId) != null) {
            for (Address__c address : allAddressesByAccountId.get(accountId)) {
                NPSP_Address npspAddress = new NPSP_Address(address);

                if (householdInfo.defaultAddress == null && address.Default_Address__c) {
                    householdInfo.defaultAddress = address;
                }
                if (npspAddress.isSeasonalAddr()) {
                    Date dtStart = dtStartOrEndOfAddrSeasonal(address, true);
                    Date dtEnd = dtStartOrEndOfAddrSeasonal(address, false);
                    Date dtToday = System.today();
                    if (dtToday >= dtStart && dtToday < dtEnd) {
                        householdInfo.seasonalAddress = address;
                    }
                }
            }
        }
    }

    private static HouseholdInfo getHouseholdInfoForAccount(Id accountId) {
        HouseholdInfo householdInfo = new HouseholdInfo();
        householdInfo.accountId = accountId;
        return householdInfo;
    }

    /*******************************************************************************************************
    * @description helper class to keep track of the default and seasonal address for a household
    */
    public class HouseholdInfo {
        public Id accountId;
        public Address__c defaultAddress;
        public Address__c seasonalAddress;
    }

    /*******************************************************************************************************
    * @description utility to create a map of HH Account Id to a list of Addresses in that HH, given a list of HH Account Id.
    * @param accountIds the list of Account Id's
    * @return map<Id, list<Address__c>> map that contains the Addresses for each HH Account Id
    */
    public static Map<Id, List<Address__c>> getAllAddressesByAccountId(List<Id> accountIds) {
        Map<Id, List<Address__c>> allAddressesByAccountId = new Map<Id, List<Address__c>>();
        List<Address__c> allAddressesForAccountIds = [
                SELECT Id, Default_Address__c, Household_Account__c, Address_Type__c,
                        MailingStreet__c, MailingStreet2__c, MailingCity__c, MailingState__c,
                        MailingPostalCode__c, MailingCountry__c,
                        Seasonal_Start_Month__c, Seasonal_Start_Day__c, Seasonal_End_Month__c,
                        Seasonal_End_Day__c, Geolocation__Latitude__s, Geolocation__Longitude__s, Undeliverable__c
                FROM Address__c
                WHERE Household_Account__c IN :accountIds
                ORDER BY Default_Address__c DESC, LastModifiedDate ASC
        ]; // ordering needed by cleanupAccountAddresses().
        for (Address__c address : allAddressesForAccountIds) {
            List<Address__c> accountAddresses = allAddressesByAccountId.get(address.Household_Account__c);
            if (accountAddresses == null) {
                accountAddresses = new List<Address__c>();
                allAddressesByAccountId.put(address.Household_Account__c, accountAddresses);
            }
            accountAddresses.add(address);
        }
        return allAddressesByAccountId;
    }

    /*******************************************************************************************************
    * @description verify that the account for each Address is a HH account or an Organizational account if enabled.
    * Adds an Error to each Address object that has an illegal account.
    */
    public void verifyAddrHHAccOnly() {
        Set<Id> setAccId = new Set<Id>();
        for (Address__c addr : (List<Address__c>) getRecords()) {
            if (addr.Household_Account__c != null) {
                setAccId.add(addr.Household_Account__c);
            }
        }
        Map<Id, Account> mapAccIdAcc = new Map<Id, Account>([
                select Id, npe01__SYSTEM_AccountType__c, npe01__SYSTEMIsIndividual__c
                from Account
                where Id in :setAccId
        ]);
        for (Address__c addr : (List<Address__c>) getRecords()) {
            if (addr.Household_Account__c == null) {
                // with TDTM, have to use addError, not throw an exception, or the error will just
                // get logged but not passed to Salesforce to stop its DML.
                addr.addError(Label.addrHHAccountOnly);
            } else {
                Account acc = mapAccIdAcc.get(addr.Household_Account__c);
                if ((acc.npe01__SYSTEM_AccountType__c != CAO_Constants.HH_ACCOUNT_TYPE) &&
                        (acc.npe01__SYSTEMIsIndividual__c ||
                        !UTIL_CustomSettingsFacade.getContactsSettings().Organizational_Account_Addresses_Enabled__c)) {
                    // with TDTM, have to use addError, not throw an exception, or the error will just get logged
                    // but not passed to Salesforce to stop its DML.
                    addr.addError(Label.addrHHAccountOnly);
                }
            }
        }
    }

    /*******************************************************************************************************
    * @description verify that any seasonal addresses don't overlap
    * Adds an Error to each Address object that has an illegal seasonal fields
    */
    public void verifyAddrSeasonalNoOverlap() {

        // first get just the seasonal addresses
        List<NPSP_Address> seasonalAddresses = seasonalAddresses();

        addErrorsToPartialSeasonalAddresses();

        // if none are seasonal, we can bail out
        if (seasonalAddresses.size() == 0) {
            return;
        }

        // protect against overlaps within the set being inserted or updated
        checkForOverlaps(seasonalAddresses);

        // now check for overlaps within each household's saved addresses
        checkForOverlapsAgainstHouseholdAddresses(seasonalAddresses);
    }

    private void addErrorsToPartialSeasonalAddresses() {
        for (Address__c addr : (List<Address__c>) getRecords()) {
            NPSP_Address npspAddress = new NPSP_Address(addr);
            npspAddress.checkForPartialSeasonalErrors();
        }
    }

    private void checkForOverlaps(List<NPSP_Address> seasonalAddresses) {
        for (NPSP_Address addr : seasonalAddresses) {
            for (NPSP_Address addr2 : seasonalAddresses) {
                if (addr.getRecord() == addr2.getRecord()) {
                    continue;
                }
                if (addr.householdId() != addr2.householdId()) {
                    continue;
                }
                if (addr.overlapsWith(addr2)) {
                    addr.getRecord().addError(Label.addrSeasonalOverlap);
                }
            }
        }
    }

    private void checkForOverlapsAgainstHouseholdAddresses(List<NPSP_Address> seasonalAddresses) {
        List<Id> listAccId = new List<Id>();
        for (NPSP_Address addr : seasonalAddresses) {
            listAccId.add(addr.householdId());
        }
        Map<Id, List<Address__c>> mapAccIdListAddrHH = Addresses.getAllAddressesByAccountId
                (listAccId);

        for (NPSP_Address addr : seasonalAddresses) {
            List<Address__c> existingHouseholdAddresses = mapAccIdListAddrHH.get(addr.householdId());
            if (existingHouseholdAddresses == null || existingHouseholdAddresses.isEmpty()) {
                continue;
            }
            for (Address__c addr2 : existingHouseholdAddresses) {
                NPSP_Address npspAddress2 = new NPSP_Address(addr2);
                if (addr.getRecord().Id == addr2.Id) {
                    continue;
                }
                if (addr.overlapsWith(npspAddress2)) {
                    addr.getRecord().addError(Label.addrSeasonalOverlap);
                    break;
                }
            }
        }
    }

    private List<NPSP_Address> seasonalAddresses() {
        List<NPSP_Address> listAddrS = new List<NPSP_Address>();
        for (Address__c addr : (List<Address__c>) getRecords()) {
            NPSP_Address npspAddress = new NPSP_Address(addr);
            if (npspAddress.isSeasonal()) {
                listAddrS.add(npspAddress);
            }
        }
        return listAddrS;
    }

    public Map<Id, Address__c> addressChangesToSyncToHouseholdAccountsAndContacts() {
        Map<Id, Address__c> addressesByAccountId = new Map<Id, Address__c>();

        for (Address__c address : (List<Address__c>) getRecords()) {
            NPSP_Address npspAddress = new NPSP_Address(address, oldVersionOf(address));

            if (npspAddress.shouldSyncAddressToHouseholdAccountAndContacts()) {
                addressesByAccountId.put(householdAccountIdFor(address), address);
            }
        }
        return addressesByAccountId;
    }

    public Map<Id, Address__c> addressChangesToSyncToContactOverrides() {
        Map<Id, Address__c> addressesById = new Map<Id, Address__c>();
        for (Address__c address : (List<Address__c>) getRecords()) {
            NPSP_Address npspAddress = new NPSP_Address(address, oldVersionOf(address));

            if (npspAddress.shouldSyncAddressChangesToContactOverrides()) {
                addressesById.put(npspAddress.getId(), npspAddress.getRecord());
            }
        }
        return addressesById;
    }

    public Map<Id, Address__c> addressesByAccountId() {
        Map<Id, Address__c> addressesByAccountId = new Map<Id, Address__c>();
        for (Address__c address : (List<Address__c>) getRecords()) {
            if (hasHouseholdAccount(address)) {
                addressesByAccountId.put(householdAccountIdFor(address), address);
            }
        }
        return addressesByAccountId;
    }

    public void deleteEmptyAddresses() {
        List<Address__c> listAddr = new List<Address__c>();
        for (Address__c addr : (List<Address__c>) getRecords()) {
            if (isAddressEmpty(addr)) {
                listAddr.add(new Address__c(Id = addr.Id));
            }
        }
        if (listAddr.size() > 0) {
            delete listAddr;
        }
    }

    /*******************************************************************************************************
    * @description for the given addresses, find if they have a match, and return a map that
    * has null for no match, and the matching address if there is a match.
    * @param listAddr a list of Addresses to update
    * @return map<Address__c, Address__c>
    */
    public static Map<Address__c, Address__c> getExistingAddresses(List<Address__c> listAddr) {
        // for each address, create a map of HHId to lists of Addresses
        List<Id> listAccId = new List<Id>();
        for (Address__c addr : listAddr) {
            listAccId.add(addr.Household_Account__c);
        }
        Map<Id, List<Address__c>> mapAccIdListAddrHH = Addresses.getAllAddressesByAccountId
                (listAccId);
        Boolean tryFuzzy = UTIL_CustomSettingsFacade.getContactsSettings().Simple_Address_Change_Treated_as_Update__c;

        // create our map for returning information in
        Map<Address__c, Address__c> mapAddrDupAddr = new Map<Address__c, Address__c>();

        // now compare our Addresses to the existing Addresses
        for (Address__c addr : listAddr) {
            NPSP_Address npspAddress = new NPSP_Address(addr);
            List<Address__c> listAddrHH = mapAccIdListAddrHH.get(addr.Household_Account__c);
            Boolean hasMatch = false;
            if (listAddrHH != null) {
                Address__c addrMatch = null;
                for (Address__c addrHH : listAddrHH) {
                    NPSP_Address npspAddressHH = new NPSP_Address(addrHH);
                    // only include address type in the test if the new one isn't empty.
                    if (isMatch(npspAddress, npspAddressHH)) {
                        // found exact match, record it and bail out
                        addrMatch = addrHH;
                        break;
                    }
                    if (tryFuzzy && npspAddress.isAddressMatchFuzzyWith(npspAddressHH)) {
                        // found fuzzy match, remember it and continue searching
                        addrMatch = addrHH;
                        continue;
                    }
                }
                if (addrMatch != null) {
                    hasMatch = true;
                    mapAddrDupAddr.put(addr, addrMatch);
                }
            }
            if (!hasMatch) {
                mapAddrDupAddr.put(addr, null);
            }
        }

        return mapAddrDupAddr;
    }

    private static Boolean isMatch(NPSP_Address npspAddress, NPSP_Address npspAddressHH) {
        return npspAddress.isEqualToIncludingAddressType(npspAddressHH, false);
    }

    /*******************************************************************************************************
    * @description Cleanup the Addresses for the specified Accounts by removing any duplicate Addresses,
    * making sure only one is marked Default, and that the Default is propagated to the appropriate
    * Account and Contacts.
    *
    * @param listAccId a list of Account Id's to process
    */
    public static void cleanupAccountAddresses(List<Id> listAccId) {

        // use dmlWrapper to handle all of our database operations
        TDTM_Runnable.DmlWrapper dmlWrapper = new TDTM_Runnable.DmlWrapper();

        // for each Account, track its correct Default Address
        Map<Id, Address__c> mapAccIdAddr = new Map<Id, Address__c>();

        // for each Account, get its list of Addresses in oldest to newest order (of LastModifiedDate)
        Map<Id, List<Address__c>> mapAccIdListAddrHH = Addresses.getAllAddressesByAccountId(listAccId);

        // Construct Contact repository for Accounts having Addresses
        Households households = new Households(mapAccIdListAddrHH.keySet());

        for (Id accId : mapAccIdListAddrHH.keySet()) {
            if (mapAccIdListAddrHH.get(accId) != null) {
                Map<String, List<Address__c>> mapAddrKeyToAddresses = new Map<String, List<Address__c>>();
                Address__c addrDefault;

                for (Address__c addr : mapAccIdListAddrHH.get(accId)) {

                    // remember the oldest modified Default address
                    // this is the one from the winning account, since the losing account addresses get updated.
                    if (addr.Default_Address__c && addrDefault == null) {
                        addrDefault = addr;
                        mapAccIdAddr.put(accId, addrDefault);
                    }

                    // create our map of Address Keys to a list of one or more Addresses
                    NPSP_Address npspAddr = new NPSP_Address(addr);
                    String addrKey = npspAddr.getAddrKey();
                    List<Address__c> listAddr = mapAddrKeyToAddresses.get(addrKey);
                    if (listAddr == null) {
                        listAddr = new List<Address__c>();
                        mapAddrKeyToAddresses.put(addrKey, listAddr);
                    }
                    listAddr.add(addr);
                }

                // now we have the Default Address to use and lists of potential duplicate addresses
                // remove the duplicates, updating any contacts that are using the duplicates
                // we delay getting the contacts until we know we have a duplicate.
                for (String addrKey : mapAddrKeyToAddresses.keySet()) {
                    List<Address__c> listAddr = mapAddrKeyToAddresses.get(addrKey);

                    for (Integer i = 1, size = listAddr.size(); i < size; i++) {
                        Address__c addrDupe = listAddr[i];

                        Contacts householdMembers =
                                households.membersOf(
                                        new HouseholdId(accId));

                        householdMembers.replaceAddress(
                                addrDupe,
                                listAddr[0],
                                dmlWrapper);

                        dmlWrapper.objectsToDelete.add(addrDupe);
                    }
                }

            }
        }

        // perform our updates & deletes for dealing with the duplicate addresses
        TDTM_TriggerHandler.processDML(dmlWrapper);

        // now make sure all contacts are using the correct default address
        dmlWrapper = new TDTM_Runnable.DmlWrapper();
        syncAddressesForAccountsAndContacts(mapAccIdAddr, dmlWrapper, false);
        TDTM_TriggerHandler.processDML(dmlWrapper);
    }

    /*******************************************************************************************************
    * @description routine the scheduled batch job calls to update households with Seasonal addresses
    * @param listAcc a list of Accounts to see if their address needs to be updated
    */
    public static void batchSeasonalUpdate(List<Account> listAcc) {
        if (listAcc == null || listAcc.size() == 0) {
            return;
        }

        Map<Id, Address__c> mapAccIdAddr = new Map<Id, Address__c>();
        for (Account acc : listAcc) {
            mapAccIdAddr.put(acc.Id, null);
        }

        // get the default and seasonal address for each HH
        Map<Id, Addresses.HouseholdInfo> mapAccIdHHInfo =
                syncAddressesForAccountsAndContacts(mapAccIdAddr, null, true);

        // now see which accounts actually had their address change, so we only update them.
        for (Account acc : listAcc) {
            Addresses.HouseholdInfo hhinfo = mapAccIdHHInfo.get(acc.Id);
            if (hhinfo != null) {
                Address__c addr = hhinfo.seasonalAddress;
                if (addr == null) {
                    addr = hhinfo.defaultAddress;
                }
                if (addr != null) {
                    NPSP_Address npspAddr = new NPSP_Address(addr);
                    NPSP_Address npspAddressCurrent = new NPSP_Address(new Address__c());
                    npspAddressCurrent.copyFromSObject(acc, 'Billing', null);
                    // now see if the address has changed, and if not, we don't need to process it anymore
                    if (npspAddr.isEqualToIncludingAddressType(npspAddressCurrent, false)) {
                        mapAccIdAddr.remove(acc.Id);
                    }

                }
            }
        }

        // now mapAccIdAddr only contains those Accounts (and Contacts) who need updating.
        // we'll go thru refreshCurrentHHAddress() again, this time allowing it to do the updates

        // must manually set our semaphore, so when we update contacts and households,
        // they don't try to create additional addresses
        TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.flag.ADDR_hasRunTrigger, true);

        TDTM_Runnable.DmlWrapper dmlWrapper = new TDTM_Runnable.DmlWrapper();
        syncAddressesForAccountsAndContacts(mapAccIdAddr, dmlWrapper, false);
        TDTM_TriggerHandler.processDML(dmlWrapper);
        TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.flag.ADDR_hasRunTrigger, false);
    }

    /*******************************************************************************************************
    * @description Updates the Latest date fields on any address overrides
    * @param mapAddrIdIsOverride map of Address Id's to an isOverride boolean
    * @param dmlWrapper to hold the Addresses that need updating
    ********************************************************************************************************/
    public static void updateAddrIsOverride(Map<Id, Boolean> mapAddrIdIsOverride) {
        if (!mapAddrIdIsOverride.isEmpty()) {
            TDTM_Runnable.DmlWrapper dmlWrapper = new TDTM_Runnable.DmlWrapper();
            for (Id id : mapAddrIdIsOverride.keySet()) {
                Address__c addr = new Address__c();
                addr.Id = id;
                if (mapAddrIdIsOverride.get(id) == true) {
                    addr.Latest_Start_Date__c = System.today();
                    addr.Latest_End_Date__c = null;
                } else {
                    addr.Latest_End_Date__c = System.today();
                }
                dmlWrapper.objectsToUpdate.add(addr);
            }
            TDTM_TriggerHandler.processDML(dmlWrapper);
        }
    }

    /*******************************************************************************************************
    * @description utility to see if the address has only a subset of its seasonal fields set
    * @param addr the Address to look at
    */
    public static void handleMultilineStreet(Address__c addr) {

        if (addr.MailingStreet__c == null) {
            return;
        }

        // handle CR NL
        Integer ich = addr.MailingStreet__c.indexOf('\r\n');
        if (ich > -1) {
            addr.MailingStreet2__c = addr.MailingStreet__c.substring(ich+2);
            addr.MailingStreet__c = addr.MailingStreet__c.left(ich);
            return;
        }

        // handle just NL
        ich = addr.MailingStreet__c.indexOf('\n');
        if (ich > -1) {
            addr.MailingStreet2__c = addr.MailingStreet__c.substring(ich+1);
            addr.MailingStreet__c = addr.MailingStreet__c.left(ich);
            return;
        }
    }

    private Boolean hasHouseholdAccount(Address__c address) {
        return householdAccountIdFor(address) != null;
    }

    private Id householdAccountIdFor(Address__c address) {
        return address.Household_Account__c;
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
        address.Latest_Start_Date__c = System.today();
    }

    private Addresses defaultAddresses() {
        List<Address__c> defaultAddresses = getRecordsByFieldValue(
                Address__c.Default_Address__c, TRUE);
        return new Addresses(defaultAddresses);
    }

    private void updateLatestDatesForDefaultChanges() {
        for (Address__c address :
                (List<Address__c>) addressesWithDefaultChanges().getRecords()) {
            NPSP_Address npspAddress = new NPSP_Address(address);

            if (npspAddress.isDefault()) {
                resetLatestStartDateFor(address);
                resetLatestEndDateFor(address);
            } else {
                setEndDateFor(address);
            }
        }
    }

    private Addresses addressesWithDefaultChanges() {
        List<Address__c> addressesWithDefaultChanges = new List<Address__c>();
        for (Address__c address : (List<Address__c>) getRecords()) {
            NPSP_Address npspAddress = new NPSP_Address(address, oldVersionOf(address));

            if (npspAddress.hasDefaultChanged()) {
                addressesWithDefaultChanges.add(address);
            }
        }
        return new Addresses(addressesWithDefaultChanges);
    }

    private void setEndDateFor(Address__c addr) {
        addr.Latest_End_Date__c = System.today();
    }

    private Address__c oldVersionOf(Address__c address) {
        return oldMap?.get(address.Id);
    }

    private static Map<Id, Account> getAccountsByIds(Set<Id> accountIds) {
        List<String> selectFields = accountAddressFields();

        String accountAddressFieldsSOQL = new UTIL_Query()
                .withSelectFields(selectFields)
                .withFrom(String.valueOf(Account.SObjectType))
                .withWhere('Id IN :accountIds')
                .build();

        return new Map<Id, Account>((Account[])Database.query(accountAddressFieldsSOQL));
    }

    private static List<String> accountAddressFields() {
        List<String> selectFields = new List<String> {
                'Id', 'BillingStreet',
                'BillingCity', 'BillingState',
                'BillingPostalCode', 'BillingCountry',
                'BillingLatitude', 'BillingLongitude',
                'Undeliverable_Address__c'
        };

        if (orgConfig.isStateCountryPicklistsEnabled()) {
            selectFields.add('BillingCountryCode');
            selectFields.add('BillingStateCode');
        }
        return selectFields;
    }

    /*******************************************************************************************************
    * @description utility to return the current StartDate or EndDate of a Seasonal Address
    * @param addr the Address to look at
    * @param fStart whether to return the StartDate or EndDate
    * @return Date
    */
    private static Date dtStartOrEndOfAddrSeasonal(Address__c addr, Boolean fStart) {
        Integer startMonth = Integer.valueOf(addr.Seasonal_Start_Month__c);
        Integer startDay = Integer.valueOf(addr.Seasonal_Start_Day__c);
        Integer endMonth = Integer.valueOf(addr.Seasonal_End_Month__c);
        Integer endDay = Integer.valueOf(addr.Seasonal_End_Day__c);
        Date dtStart;
        Date dtEnd;
        Date dtToday = System.today();
        //seasonal address is contained within a single year
        if (startMonth <= endMonth) {
            dtStart = Date.newInstance(dtToday.year(), startMonth, startDay);
            dtEnd = Date.newInstance(dtToday.year(), endMonth, endDay);
            //seasonal address overlaps the year, and this month is past the start month
        } else if (startMonth <= dtToday.month()){
            dtStart = Date.newInstance(dtToday.year(), startMonth, startDay);
            dtEnd = Date.newInstance(dtToday.year()+1, endMonth, endDay);
            //seasonal address overlaps the year, and this month is before the start month
        } else {
            dtStart = Date.newInstance(dtToday.year()-1, startMonth, startDay);
            dtEnd = Date.newInstance(dtToday.year(), endMonth, endDay);
        }
        return (fStart ? dtStart : dtEnd);
    }

    /*******************************************************************************************************
    * @description returns whether the Address's mailing fields are null
    * @param addr the Address
    * @return boolean. true if all of the Mailing fields are empty
    */
    private static Boolean isAddressEmpty(Address__c addr) {
        if (addr == null) {
            return false;
        }
        return (
                addr.MailingStreet__c == Null &&
                        addr.MailingStreet2__c == Null &&
                        addr.MailingCity__c == Null &&
                        addr.MailingState__c == Null &&
                        addr.MailingPostalCode__c == Null &&
                        addr.MailingCountry__c == Null);
    }

    public static void replaceAddress(Address__c addrLoser, Address__c addrWinner,
            Contacts contacts, TDTM_Runnable.DmlWrapper dmlWrapper) {
        contacts.replaceAddress(addrLoser, addrWinner, dmlWrapper);
    }

    private void putErrorsOnAddresses(ERR_Handler.Errors errors, Map<Id, Address__c> mapAddressesByAcctId,
            Map<Id, Address__c> mapAddressesById) {
        for (Error__c error : errors.errorRecords) {
            Id objId = ERR_Handler.getErrorObjectId(error);
            UTIL_Debug.debug(LoggingLevel.WARN, '**** Address TDTM error on object: ' + objId);
            if (UTIL_Describe.isObjectIdThisType(objId, 'Account')) {
                Address__c addr = mapAddressesByAcctId.get(objId);
                addr.addError(error.Full_Message__c);
                UTIL_Debug.debug(LoggingLevel.WARN, '**** Address: ' + addr + ' message: ' + error.Full_Message__c);
            } else if (UTIL_Describe.isObjectIdThisType(objId, UTIL_Namespace.StrTokenNSPrefix('Address__c'))) {
                Address__c addr = mapAddressesById.get(objId);
                addr.addError(error.Full_Message__c);
                UTIL_Debug.debug(LoggingLevel.WARN, '**** Address: ' + addr + ' message: ' + error.Full_Message__c);
            }
        }
    }

    private class AddressAndRelationshipsToUpdate {
        List<Account> accountsToUpdate;
        List<Address__c> addressesToUpdate;
        List<Contact> contactsToUpdate;

        private AddressAndRelationshipsToUpdate(List<Account> accountsToUpdate, List<Address__c> addressesToUpdate,
                List<Contact> contactsToUpdate) {

            this.accountsToUpdate = accountsToUpdate;
            this.addressesToUpdate = addressesToUpdate;
            this.contactsToUpdate = contactsToUpdate;
        }
    }
}