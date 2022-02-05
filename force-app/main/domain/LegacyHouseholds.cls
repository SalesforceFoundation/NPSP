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
* @description Domain class for Households in NPSP.
*/
public inherited sharing class LegacyHouseholds extends fflib_SObjects2 {

    private Map<Id, npo02__Household__c> oldMap;
    @TestVisible
    private HouseholdNamingService householdNamingServiceInst {
        get {
            if (householdNamingServiceInst == null) {
                householdNamingServiceInst = new HouseholdNamingService();
            }
            return householdNamingServiceInst;
        }
        set;
    }
    @TestVisible
    private HouseholdSettings settings {
        get {
            if (settings == null) {
                settings = new HouseholdSettings();
            }
            return settings;
        }
        set;
    }

    @TestVisible
    private static AddressService addressService {
        get {
            if (addressService == null) {
                addressService = new AddressService();
            }
            return addressService;
        }
        set;
    }

    @TestVisible
    private static HouseholdService householdService {
        get {
            if (householdService == null) {
                householdService = new HouseholdService();
            }
            return householdService;
        }
        set;
    }

    @TestVisible
    private static ContactService contactService {
        get {
            if (contactService == null) {
                contactService = new ContactService();
            }
            return contactService;
        }
        set;
    }

    public LegacyHouseholds(Set<Id> ids, LegacyHouseholdSelector selector) {
        this(selector.getHouseholdsWithMembersById(ids), null);
    }

    public LegacyHouseholds(List<npo02__Household__c> records) {
        this(records, null);
    }

    public LegacyHouseholds(List<npo02__Household__c> records, List<npo02__Household__c> oldlist) {
        super(records, npo02__Household__c.SObjectType);
        oldMap = oldlist == null ? new Map<Id, npo02__Household__c>() : new Map<Id,
                npo02__Household__c>(oldlist);
    }

    public void onBeforeUpdate() {
        if (!isHouseholdTriggerContext() && isAdvancedHouseholdNamingEnabled()) {
            setCustomNamingField();
            setNameAndGreetingsToReplacementText();
        }
    }

    public void onAfterUpdate() {
        if (!isHouseholdTriggerContext() && isAdvancedHouseholdNamingEnabled()) {
            renameHouseholdAccountsNeedingNameUpdates();
        }
    }

    public void deleteEmptyHouseholds() {
        delete emptyHouseholds().getRecords();
    }

    public LegacyHouseholds emptyHouseholds() {
        List<npo02__Household__c> emptyHouseholds = new List<npo02__Household__c>();
        for (npo02__Household__c household : (List<npo02__Household__c>) getRecords()) {
            if (household.npo02__Contacts__r.isEmpty()) {
                emptyHouseholds.add(household);
            }
        }
        return new LegacyHouseholds(emptyHouseholds);
    }

    public LegacyHouseholds nonEmptyHouseholds() {
        List<npo02__Household__c> nonEmptyHouseholds = new List<npo02__Household__c>();
        for (npo02__Household__c household : (List<npo02__Household__c>) getRecords()) {
            if (!household.npo02__Contacts__r.isEmpty()) {
                nonEmptyHouseholds.add(household);
            }
        }
        return new LegacyHouseholds(nonEmptyHouseholds);
    }

    public Map<Id, Integer> getHouseholdCountMap() {
        Map<Id, Integer> householdCountMap = new Map<Id, Integer>();
        for (npo02__Household__c household : (List<npo02__Household__c>) getRecords()) {
            householdCountMap.put(household.Id, household.npo02__Contacts__r.size());
        }
        return householdCountMap;
    }

    public void calculateLegacyHouseholdRollups() {
        LegacyHouseholds nonEmptyHouseholds =
                nonEmptyHouseholds();
        if (nonEmptyHouseholds.ids().size() > 0) {
            if (rollupsShouldRunSynchronously(nonEmptyHouseholds.ids())) {
                RLLP_OppRollup rg = new RLLP_OppRollup();
                rg.rollupHouseholds(getHouseholdMap(nonEmptyHouseholds.ids()));
            } else {
                RLLP_OppRollup.rollupHouseholdsFuture(nonEmptyHouseholds.ids());
            }
        }
    }

    public void updateHouseholdNameAndMemberCount() {
        if (isFutureEligible()) {
            householdNamingServiceInst.updateHouseholdNameAndMemberCountAsync(
                    new List<Id>(ids()));
        } else {
            householdNamingServiceInst.updateHouseholdNameAndMemberCount(new List<Id>(ids()));
        }
    }

    public Set<Id> ids() {
        return getIdFieldValues(npo02__Household__c.Id).getIds();
    }

    /*******************************************************************************************************
    * @description Updates Contacts to relate to a single Individual Account
    * @param contacts the list of Contacts that need updating.
    */
    public static void attachToBucketAccount(List<Contact> contactsWithoutBucketAccount){
        if (contactsWithoutBucketAccount.isEmpty()) {
            return;
        }

        Id individualAccountId = CAO_Constants.getIndividualAccountId();

        if (individualAccountId != null) {
            for (Contact contactRecord : contactsWithoutBucketAccount) {
                //connect all Contacts to the bucket Account
                contactRecord.AccountId = individualAccountId;
            }
        } else {
            //if there is no bucket Account, the bucket model won't function unless we create one
            Account individual = new Account();
            individual.Name = CAO_Constants.BUCKET_ACCOUNT_NAME;
            //flag the account as an individual account
            individual.npe01__SYSTEMIsIndividual__c = true;
            //individual.Type = CAO_Constants.BUCKET_ORGANIZATION_TYPE;
            individual.npe01__SYSTEM_AccountType__c = CAO_Constants.BUCKET_ORGANIZATION_TYPE;
            UTIL_DMLService.insertRecord(individual);

            for (Contact contactRecord : contactsWithoutBucketAccount) {
                //connect Contact to bucket Account
                contactRecord.AccountId = individual.Id;
            }
        }
    }

    public static Boolean isWithoutAccount(Contact contactRecord) {
        return contactRecord.npe01__Private__c != true
                && contactRecord.AccountId == null;
    }

    public static Boolean isOrganizationContact(Contact contactRecord, Account accountRecord) {
        return contactRecord.npe01__Private__c != true
                &&
                (accountRecord != null
                        && accountRecord.npe01__SYSTEM_AccountType__c == CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE
                );
    }


    /*******************************************************************************************************
    * @description contact's owner has changed.  consider updating related account owner.
    * @param newOwnerContactById a map of Contact Id to Contact, for the contacts to consider
    */
    public static void updateOwners(Map<Id, Contact> newOwnerContactById,
            TDTM_Runnable.DmlWrapper dmlWrapper) {
        if (newOwnerContactById.isEmpty()) {
            return;
        }

        Set<Id> accountIds = new Set<Id>();
        Map<Id, Account> accountsToUpdate = new Map<Id, Account>();

        for (Contact contactRecord : newOwnerContactById.values()) {
            accountIds.add(contactRecord.AccountId);
        }

        for (Account accountRecord : [
            SELECT Id, npe01__SYSTEM_AccountType__c, npe01__One2OneContact__c, OwnerId, (SELECT Id FROM Contacts LIMIT 2)
            FROM Account
            WHERE Id IN :accountIds
        ]) {
            // only consider 1:1 and HH Accounts
            if (accountRecord.npe01__SYSTEM_AccountType__c == CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE || accountRecord.npe01__SYSTEM_AccountType__c == CAO_Constants.HH_ACCOUNT_TYPE) {
                // if there is only 1 contact associated with this account
                if (accountRecord.Contacts.size() == 1 && accountRecord.npe01__One2OneContact__c != null) {
                    Contact contactRecord = newOwnerContactById.get(accountRecord.npe01__One2OneContact__c);
                    Id ownerId = (contactRecord != null ? contactRecord.OwnerId : null);
                    if (accountRecord.OwnerId != ownerId) {
                        accountRecord.OwnerId = ownerId;
                        accountsToUpdate.put(accountRecord.Id, accountRecord);
                    }
                }
            }
        }

        //update existing dmlWrapper objects with accounts already in the list
        //avoids "duplicate id in list" errors updating the same account twice
        for (SObject dmlObj : dmlWrapper.objectsToUpdate) {
            Id objId = (Id) dmlObj.get('id');
            if (accountsToUpdate.containsKey(objId)) {
                dmlObj.put('OwnerId', accountsToUpdate.get(objId).OwnerId);
                accountsToUpdate.remove(objId);
            }
        }

        // add the rest of the accounts that weren't already in the update list
        if (!accountsToUpdate.isEmpty()) {
            dmlWrapper.objectsToUpdate.addAll(accountsToUpdate.values());
        }
    }

    /**
     * @description Depending on the contacts household type, this method will update the one to one account,
     * move opportunities related to contacts changing accounts, update household accounts, rename household accounts
     * update account owners based on the change in contact owner
     */
    public static void handleContactsAfterUpdate(Contacts contactsInstance,
            TDTM_Runnable.DmlWrapper dmlWrapper) {
        updateOneToOneAccounts(
                contactsInstance.getOneToOneContactsToUpdate(), dmlWrapper);

        List<Id> householdIdsToUpdate =
                contactService.moveOppsForContactsSwitchingAccounts(contactsInstance);
        householdService.updateHouseholds(householdIdsToUpdate, dmlWrapper);

        Households.updateNameAndMemberCount(contactsInstance.getHouseholdIdsToRenameAndCountMembers());

        updateOwners(contactsInstance.getNewOwnerContactById(), dmlWrapper);
    }


    /**
     * @description Sets the primary contact on the account when needed and renames the household.
     */
    public static TDTM_Runnable.DmlWrapper updatePrimaryContactOnAccountsAfterInsert
            (TDTM_Runnable.DmlWrapper dmlWrapper, List<Contact> contacts) {
        Map<Id, Id> primaryContactByAccountId = getPrimaryContactByAccountId(contacts);

        if (primaryContactByAccountId.isEmpty()) {
            return dmlWrapper;
        }

        List<Account> accountsWithOneToOneFieldUpdated =
                setOneToOneFieldValue(primaryContactByAccountId);

        dmlWrapper.objectsToUpdate.addAll(accountsWithOneToOneFieldUpdated);
        return dmlWrapper;
    }

    /*******************************************************************************************************
    * @description Updates an Individual Account for an Individual Contact
    * @param oneToOneContactsToUpdate the list of Contacts that need updating.
    */
    public static void updateOneToOneAccounts(List<Contact> oneToOneContactsToUpdate,
            TDTM_Runnable.DmlWrapper dmlWrapper){
        if (oneToOneContactsToUpdate.isEmpty()) {
            return;
        }

        Map<Id, Contact> contactByAccountId = new Map<Id, Contact>();
        for (Contact contactRecord : oneToOneContactsToUpdate) {
            contactByAccountId.put(contactRecord.AccountId, contactRecord);
        }
        //get the corresponding Accounts
        // DJH: note that we explicitly do NOT get the account name.  This is to avoid the changes to the account from
        // this routine which get added to dmlWrapper, don't end up overwriting the name changes that are done syncronously
        // for HH accounts (which don't use dmlWrapper).
        List<Account> accounts = new List<Account>();

        for (Account accountRecord : [
            SELECT npe01__SYSTEM_AccountType__c, ShippingStreet, ShippingState, ShippingPostalCode, ShippingCountry,
                ShippingCity, BillingStreet, BillingState, BillingPostalCode, BillingCountry, BillingCity
            FROM Account
            WHERE Id IN :contactByAccountId.keySet()
        ]) {
            Contact contactRecord = contactByAccountId.get(accountRecord.Id);
            addressService.copyAddressStdSObj(contactRecord, 'Mailing', accountRecord,
                    'Billing');
            addressService.copyAddressStdSObj(contactRecord, 'Other', accountRecord,
                    'Shipping');

            if (accountRecord.npe01__SYSTEM_AccountType__c == CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE) {
                accountRecord.Name = Households.strNameOne2OneAccountForContact(contactRecord);
            }

            // HH Account naming updates handled seperately to deal with asyncronous naming
            accounts.add(accountRecord);
        }

        if (accounts.isEmpty()) {
            return;
        }

        dmlWrapper.objectsToUpdate.addAll(accounts);
    }

    private static Map<Id, Id> getPrimaryContactByAccountId(List<Contact> contacts) {
        Map<Id, Id> primaryContactByAccountId = new Map<Id, Id>();

        for (Contact contactRecord : contacts) {
            if (contactRecord.AccountId == null) {
                continue;
            }

            if (needsPrimaryContact(contactRecord)) {
                primaryContactByAccountId.put(contactRecord.AccountId, contactRecord.Id);
            }
        }
        return primaryContactByAccountId;
    }

    private static List<Account> setOneToOneFieldValue(Map<Id, Id>
            primaryContactByAccountId) {
        List<Account> accounts = new List<Account>();
        for (Id accountId : primaryContactByAccountId.keySet()) {
            Account accountRecord = new Account(Id = accountId, npe01__One2OneContact__c = primaryContactByAccountId.get(accountId));
            accounts.add(accountRecord);
        }
        return accounts;
    }

    /**
     * needsPrimaryContact Determines whether or not the account is in need of a primary contact.
     * @param  contactRecord The contact record to traverse to the account data.
     * @return Boolean - true when the account needs the primary contact set.
     */
    private static Boolean needsPrimaryContact(Contact contactRecord) {
        return contactRecord.npe01__Private__c != true
                && contactRecord.Account.npe01__SYSTEM_AccountType__c != CAO_Constants.BUCKET_ORGANIZATION_TYPE
                && contactRecord.Account.npe01__SYSTEMIsIndividual__c
                && contactRecord.Account.npe01__One2OneContact__c == null;
    }

    private void setNameAndGreetingsToReplacementText() {
        householdNamingServiceInst.setNameAndGreetingsToReplacementText(getRecords());
    }

    private void setCustomNamingField() {
        householdNamingServiceInst.setCustomNamingField(getRecords(), oldMap);
    }

    private Boolean isAdvancedHouseholdNamingEnabled() {
        return settings.isAdvancedHouseholdNaming();
    }

    private void renameHouseholdAccountsNeedingNameUpdates() {
        Households.updateNameAndMemberCount(getHouseholdsNeedingNameUpdates());
    }

    private List<Id> getHouseholdsNeedingNameUpdates() {
        List<Id> householdsNeedingNameUpdates =
                householdNamingServiceInst.getHouseholdsNeedingNameUpdates(
                        getRecords(), oldMap
                );
        return householdsNeedingNameUpdates;
    }

    private Boolean isHouseholdTriggerContext() {
        return TDTM_ProcessControl.isRecursive(TDTM_ProcessControl.flag.HH);
    }

    private Boolean isFutureEligible() {
        return settings.isAsyncEnabled()
                && !System.isFuture() && !System.isBatch();
    }

    private Map<Id, npo02__Household__c> getHouseholdMap(Set<Id> householdIds) {
        RLLP_OppRollup_UTIL oppRollupUtil = new RLLP_OppRollup_UTIL();
        Map<Id, npo02__Household__c> hhmap = new Map<Id, npo02__Household__c>(
                (List<npo02__Household__c>) Database.query(oppRollupUtil.buildHouseholdQuery() +
                        ' WHERE Id IN :householdIds'));
        return hhmap;
    }

    private Boolean rollupsShouldRunSynchronously(Set<Id> householdIds) {
        return System.isFuture() || System.isBatch() || householdIds.size() <= 2;
    }
}
