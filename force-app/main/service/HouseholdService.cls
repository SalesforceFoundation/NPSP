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
* @description Domain class for Contacts in NPSP.
*/
public inherited sharing class HouseholdService {

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
    private AddressService addressServiceInstance {
        get {
            if (addressServiceInstance == null) {
                addressServiceInstance = new AddressService();
            }
            return addressServiceInstance;
        }
        set;
    }

    @TestVisible
    private HouseholdSettings householdSettings {
        get {
            if (householdSettings == null) {
                householdSettings = new HouseholdSettings();
            }
            return householdSettings;
        }
        set;
    }

    private static final String RECORD_TYPE_ID = 'RecordTypeId';

    @TestVisible
    private UnitOfWork unitOfWorkInst {
        get {
            if (unitOfWorkInst == null) {
                unitOfWorkInst = new UnitOfWork();
            }
            return unitOfWorkInst;
        }
        set;
    }

    public Set<String> fieldsUsedForHouseholdNaming() {
        return householdNamingServiceInst.getHouseholdNamingContactFields();
    }

    public void createHouseholdsFor(
            LegacyHouseholdMembers legacyHouseholdMembers) {
        if (allContactsGetHouseholds()) {
            insertHouseholdsForContacts(
                    legacyHouseholdMembers.contactsWithoutHouseholds());
        }
        if (allIndividualContactsGetHouseholds()) {
            insertHouseholdsForContacts(
                    legacyHouseholdMembers.contactsInIndividualAccountsWithoutHouseholds());
        }
    }

    public void deleteEmptyHouseholdsFor(LegacyHouseholdMembers legacyHouseholdMembers) {
        LegacyHouseholds oldHouseholds = new LegacyHouseholds(
                new Set<Id>(legacyHouseholdMembers.oldHouseholdIds()),
                new LegacyHouseholdSelector());
        oldHouseholds.deleteEmptyHouseholds();
    }

    public void updateHouseholdNamesFor(LegacyHouseholdMembers legacyHouseholdMembers) {
        if (legacyHouseholdMembers.householdsWithMembershipOrNamingFieldChanges().size() > 0) {
            if (isFutureEligible()) {
                HouseholdNamingService.updateHouseholdNameAndMemberCountAsynchronously(
                        legacyHouseholdMembers
                                .householdsWithMembershipOrNamingFieldChanges());
            } else {
                HouseholdNamingService householdNamingService = new HouseholdNamingService();
                householdNamingService.updateHouseholdNameAndMemberCount(
                        legacyHouseholdMembers
                                .householdsWithMembershipOrNamingFieldChanges());
            }
        }
    }

    private Boolean isFutureEligible() {
        return settings.isAsyncEnabled()
                && !System.isFuture() && !System.isBatch();
    }

    public void fireHouseholdRollupsFor(LegacyHouseholdMembers legacyHouseholdMembers) {
        if (legacyHouseholdMembers.householdsWithMembershipChanges().isEmpty()) {
            return; //No need to fire rollups if no Contacts changed Households
        }
        LegacyHouseholds householdsWithMembershipChanges =
                new LegacyHouseholds(
                        legacyHouseholdMembers.householdsWithMembershipChanges(),
                        new LegacyHouseholdSelector());
        householdsWithMembershipChanges.calculateLegacyHouseholdRollups();
    }

    public void processOldHouseholdsAfterDeletingContacts(
            LegacyHouseholdMembers legacyHouseholdMembers) {
        LegacyHouseholds oldHouseholds =
                new LegacyHouseholds(legacyHouseholdMembers.householdIds(),
                        new LegacyHouseholdSelector());
        oldHouseholds.deleteEmptyHouseholds();
        oldHouseholds.updateHouseholdNameAndMemberCount();
    }

    private Boolean allIndividualContactsGetHouseholds() {
        return settings.isAllIndividualsProcessor();
    }

    private Boolean allContactsGetHouseholds() {
        return settings.isAllProcessor();
    }

    /*******************************************************************************************************
    * @description Creates a new Household Object for each contact, unless excluded by recordType
    * @param contacts List of Contacts
    * @param isInsertTrigger Whether called from the afterInsert trigger (vs. afterUpdate trigger) on Contacts
    ********************************************************************************************************/
    private void insertHouseholdsForContacts(List<Contact> contacts) {
        List<npo02__Household__c> households = getHouseholdsForInsert(contacts);
        if (households.size() > 0) {
            unitOfWorkInst.registerNew((List<SObject>) households);
            Database.SaveResult[] householdSaveResults = unitOfWorkInst.save();
            if (householdSaveResults != null && !householdSaveResults.isEmpty()) {
                putHouseholdIdOntoContacts(contacts, householdSaveResults);
                updateNamesAfterHouseholdInsert(householdSaveResults);
            }
        }
    }

    private void putHouseholdIdOntoContacts(List<Contact> contacts,
            Database.SaveResult[] householdSaveResults) {
        List<Contact> contactsToBeUpdatedWithHouseholdId =
                getContactsToBeUpdatedWithNewHouseholdId(contacts, householdSaveResults);
        update contactsToBeUpdatedWithHouseholdId;
    }

    private void updateNamesAfterHouseholdInsert(Database.SaveResult[] lsr) {
        List<Id> householdIdsNeedingNamesUpdated =
                getHouseholdIdsNeedingNamesUpdatedFromSaveResult(lsr);
        if (!householdIdsNeedingNamesUpdated.isEmpty()) {
            if (isFutureEligible()) {
                HouseholdNamingService.updateHouseholdNameAndMemberCountAsynchronously(
                        householdIdsNeedingNamesUpdated
                );
            } else {
                HouseholdNamingService householdNamingService = new HouseholdNamingService();
                householdNamingService.updateHouseholdNameAndMemberCount(
                        householdIdsNeedingNamesUpdated
                );
            }
        }
    }

    private List<Id> getHouseholdIdsNeedingNamesUpdatedFromSaveResult(
            Database.SaveResult[] lsr) {
        List<Id> householdIdsNeedingNamesUpdated = new List<Id>();
        for (Database.SaveResult sr : lsr) {
            if (sr.isSuccess()) {
                householdIdsNeedingNamesUpdated.add(sr.getID());
            }
        }
        return householdIdsNeedingNamesUpdated;
    }

    private List<Contact> getContactsToBeUpdatedWithNewHouseholdId(List<Contact> contacts,
            Database.SaveResult[] householdSaveResults) {
        List<Contact> contactsToBeUpdatedWithHouseholdId = new List<Contact>();
        Integer i = 0;
        for (Contact con : getContactsThatAreNotExcludedByRecordType(contacts)) {
            Database.SaveResult saveResult = householdSaveResults[i];
            if (saveResult.isSuccess() == true) {
                //write the new Household Ids to the Contacts
                Contact cloneContact = con.Clone(true, false);
                cloneContact.npo02__household__c = saveResult.getId();
                contactsToBeUpdatedWithHouseholdId.add(cloneContact);
            } else {
                Database.Error err = saveResult.getErrors()[0];
                con.addError(err.getMessage());
            }
            i += 1;
        }
        return contactsToBeUpdatedWithHouseholdId;
    }

    private List<npo02__Household__c> getHouseholdsForInsert(List<Contact> contacts) {
        List<npo02__household__c> households = new List<npo02__household__c>();
        for (Contact con : getContactsThatAreNotExcludedByRecordType(contacts)) {
            households.add(getHouseholdForInsertFromContact(con));
        }
        return households;
    }

    private List<Contact> getContactsThatAreNotExcludedByRecordType(List<Contact> contacts) {
        List<Contact> contactsThatAreNotExcludedByRecordType = new List<Contact>();
        for (Contact con : contacts) {
            if (isNotExcludedByRecordType(con)) {
                contactsThatAreNotExcludedByRecordType.add(con);
            }
        }
        return contactsThatAreNotExcludedByRecordType;
    }

    private npo02__Household__c getHouseholdForInsertFromContact(Contact con) {
        npo02__household__c household =
                new npo02__household__c(Name = getDefaultHouseholdName(con));
        syncPrimaryAddressBlock(household, con);
        return household;
    }

    private void syncPrimaryAddressBlock(npo02__Household__c household, Contact con) {
        household.npo02__MailingStreet__c = con.MailingStreet;
        household.npo02__MailingCity__c = con.MailingCity;
        household.npo02__MailingState__c = con.MailingState;
        household.npo02__MailingPostalCode__c = con.MailingPostalCode;
        household.npo02__MailingCountry__c = con.MailingCountry;
        household.npo02__HouseholdPhone__c = con.HomePhone;
        household.npo02__HouseholdEmail__c = con.Email;
    }

    private String getDefaultHouseholdName(Contact con) {
        String hName = con.LastName;
        return hName += ' ' + System.Label.npo02.DefaultHouseholdName;
    }

    private Boolean isNotExcludedByRecordType(Contact con) {
        return !isRecordTypeInUseOnContacts
                || !settings.contactRecordTypesToExclude().contains(recordTypeIdFor(con));
    }

    private Id recordTypeIdFor(Contact con) {
        return (Id) con.get(RECORD_TYPE_ID);
    }

    private static Boolean isRecordTypeInUseOnContacts {
        get {
            if (isRecordTypeInUseOnContacts == NULL) {
                isRecordTypeInUseOnContacts =
                        Schema.sObjectType.Contact.fields.getMap().get(RECORD_TYPE_ID) != null;
            }
            return isRecordTypeInUseOnContacts;
        }
        set;
    }

    public void updateHouseholds(List<Id> ids, TDTM_Runnable.DmlWrapper dmlWrapper) {
        if (ids.isEmpty()) {
            return;
        }

        Households households = new Households(new Set<Id>(ids));
        households.updateHouseholds(dmlWrapper);
    }

    /*******************************************************************************************************
    * @description Inserts a new 1:1 or HH Account for an Individual Contact
    * @param contacts the list of Contacts that need updating.
    */
    public void createOneToOneAndHouseholdAccountsFor(List<Contact> contacts){
        if (contacts.isEmpty()) {
            return;
        }

        List<Contact> contactRecords = new List<Contact>();

        //track which contacts are being inserted vs. updated
        List<Id> existingContactIds = getContactIds(contacts);

        // get all the Accounts that are connected to the existing Contacts
        Map<Id, Account> accountByPrimaryContactId =
                getAccountByPrimaryContactId(existingContactIds);

        List<Account> accountsToInsert = new List<Account>();
        List<Account> accountsToUpdate = new List<Account>();
        List<Contact> contactsNeedingAddressesCreated = new List<Contact>();
        for (Contact contactRecord : contacts) {
            // if we found an Account already connected to this Contact, connect the Contact to that Account if it
            // is the correct type for the current account processor
            Account accountRecord = accountByPrimaryContactId.get(contactRecord.Id);
            if (accountRecord != null && CAO_Constants.isHHAccountModel() && isHousehold(accountRecord)
                    || accountRecord != null && CAO_Constants.isOneToOne() && isOneToOne(accountRecord)) {
                // if a user has blanked out the Account for a Contact, this will put it right back
                contactRecord.AccountId = accountRecord.Id;
                if (CAO_Constants.isHHAccountModel() && AddressService.isAddressManagementEnabled()) {
                    ContactAddress contactAddress = new ContactAddress(contactRecord);
                    if (contactAddress.hasAddress()) { // todo: should check for changes on
                        // before update
                        contactsNeedingAddressesCreated.add(contactRecord);
                    }
                }
                if (accountRecord.Number_of_Household_Members__c == null) {
                    accountRecord.Number_of_Household_Members__c = 1;
                } else {
                    accountRecord.Number_of_Household_Members__c =
                            accountRecord.Contacts.size();
                }
                accountsToUpdate.add(accountRecord);
            } else {
                // Construct the Household (Account), or the Individual/One2One Account when
                // in the Legacy Household model.
                accountRecord = getBaseOneToOneOrHouseholdAccountFor(contactRecord);

                // ***
                // This method seems to be called from both before and after insert.
                // When called after insert, the accounts One2One (aka Primary Contact)
                // field is set.
                // ***
                // connect the Account to the Contact for 1:1 and HHAccount
                if (contactRecord.Id != null) {
                    accountRecord.npe01__One2OneContact__c = contactRecord.Id;
                }

                if (CAO_Constants.isHHAccountModel()) {
                    configureHouseholdAccount(contactRecord, accountRecord);
                    if (AddressService.isAddressManagementEnabled()) {
                        contactsNeedingAddressesCreated.add(contactRecord);
                    }
                } else {
                    configureOneToOneAccount(accountRecord, contactRecord);
                }

                accountsToInsert.add(accountRecord);
                contactRecords.add(contactRecord);
            }
        }

        if (!accountsToUpdate.isEmpty()) {
            update accountsToUpdate; // Update member count
            Households.updateNameAndMemberCount( // Update name and greetings
                    new List<Id>(new Map<Id, Account>(accountsToUpdate).keySet()));
        }

        if (!accountsToInsert.isEmpty()) {
            insertNewHouseholds(accountsToInsert, contactRecords);
        }

        if (!contactsNeedingAddressesCreated.isEmpty()) {
            Contacts contactsDomain = new Contacts(contactsNeedingAddressesCreated);
            List<Contact> contactsWithNonNullAccountIdsRecords =
                    contactsDomain.contactsWithNonNullAccountIds().getRecords();
            if (!contactsWithNonNullAccountIdsRecords.isEmpty()) {
                Households.insertHouseholdAddressesFor(
                        contactsWithNonNullAccountIdsRecords
                );
            }
        }
    }

    private void insertNewHouseholds(List<Account> accountsToInsert, List<Contact> contactRecords) {
        // Set the HH flag to true to prevent the trigger handlers from running again
        // to update the name and member count now that they are already set correctly here.
        TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.flag.HH, true);
        // Suppress the trigger handler that creates Addresses from Accounts, as
        // the Addresses will be inserted using the Contact info as a next step.
        TDTM_ProcessControl.toggleTriggerState('Account', 'ADDR_Account_TDTM', false);
        List<Database.SaveResult> insertResults = UTIL_DMLService.insertRecords(accountsToInsert, false);
        TDTM_ProcessControl.toggleTriggerState('Account', 'ADDR_Account_TDTM', true);
        TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.flag.HH, false);

        applyErrorsToContactRecords(insertResults, accountsToInsert, contactRecords);

        // now update each contact's accountId
        applyAccountIdsToContactRecords(contactRecords, accountsToInsert);
    }

    private void applyAccountIdsToContactRecords(List<Contact> contactRecords, List<Account> accountsToInsert) {
        Integer index = 0;
        for (Contact contactRecord : contactRecords) {
            contactRecord.AccountId = accountsToInsert[index].Id;
            index++;
        }
    }

    private void applyErrorsToContactRecords(List<Database.SaveResult> insertResults, List<Account> accountsToInsert, List<Contact> contactRecords) {
        for (Integer index = 0; index < insertResults.size(); index++) {
            Database.SaveResult insertResult = insertResults[index];
            if (!insertResult.isSuccess()) {
                for (Database.Error err : insertResult.getErrors()) {
                    accountsToInsert[index].addError(err.getMessage());
                    Contact contactRecord = contactRecords[index];
                    contactRecord.addError(String.format(System.Label.conFailedAccountCreate, new String[]{
                            contactRecord.FirstName, contactRecord.LastName, err.getMessage()
                    }));
                }
            }
        }
    }

    private Map<Id, Account> getAccountByPrimaryContactId(List<Id> existingContactIds) {
        Map<Id, Account> accountByPrimaryContactId = new Map<Id, Account>();
        for (Account accountRecord : getAccounts(existingContactIds)) {
            accountByPrimaryContactId.put(
                    accountRecord.npe01__One2OneContact__c, accountRecord);
        }
        return accountByPrimaryContactId;
    }

    private Account getBaseOneToOneOrHouseholdAccountFor(Contact contactRecord) {
        Account accountRecord = new Account();
        if (UserInfo.isMultiCurrencyOrganization()) {
            accountRecord.put('CurrencyIsoCode',
                    (String) contactRecord.get('CurrencyIsoCode'));
        }

        // Always copy the Contact's Mailing & Others address to the new Account's
        // Billing & Shipping address.
        // NOTE: This does NOT map the Contact's Primary Address Type, since there
        // is no equivalent field on the Household/Account.  This results in
        // Addresses that are created during the new Contact flow not getting the
        // correct Address Type.
        if (contactRecord.is_Address_Override__c != true) {
            addressServiceInstance.copyAddressStdSObj(contactRecord, 'Mailing',
                    accountRecord, 'Billing');
            addressServiceInstance.copyAddressStdSObj(contactRecord, 'Other',
                    accountRecord, 'Shipping');
        }

        accountRecord.Phone = contactRecord.Phone;
        accountRecord.Fax = contactRecord.Fax;
        accountRecord.OwnerId = contactRecord.OwnerId;
        accountRecord.npe01__SYSTEMIsIndividual__c = true;
        return accountRecord;
    }

    private void configureOneToOneAccount(Account accountRecord, Contact contactRecord) {
        accountRecord.Name =
                Households.strNameOne2OneAccountForContact(contactRecord);
        accountRecord.npe01__SYSTEM_AccountType__c =
                CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE;
        accountRecord.Type = '';

        if (ContactAndOrgSettings.rtIdForAccountModel(false) != null) {
            accountRecord.put('RecordTypeID',
                    ContactAndOrgSettings.rtIdForAccountModel(false));
        }
    }

    private void configureHouseholdAccount(Contact contactRecord, Account accountRecord) {
        if (householdSettings.isAdvancedHouseholdNaming()) {
            // Generate and set the Name + Greetings
            HouseholdName householdName =
                    new HouseholdName(new HouseholdMembers(new List<Contact>{
                            contactRecord
                    }));
            accountRecord.Name = householdName.asName();
            accountRecord.npo02__Formal_Greeting__c =
                    householdName.asFormalGreeting();
            accountRecord.npo02__Informal_Greeting__c =
                    householdName.asInformalGreeting();
        } else {
            accountRecord.Name =
                    Households.strNameHHAccountForContact(contactRecord);
        }

        // Set the member count
        accountRecord.Number_of_Household_Members__c = 1;

        // Set the account Type fields
        accountRecord.npe01__SYSTEM_AccountType__c =
                CAO_Constants.HH_ACCOUNT_TYPE;
        accountRecord.Type = CAO_Constants.HH_TYPE;

        // Set the Record Type
        if (ContactAndOrgSettings.rtIdForAccountModel(true) != null) {
            accountRecord.put('RecordTypeID',
                    ContactAndOrgSettings.rtIdForAccountModel(true));
        }
    }

    private Boolean isOneToOne(Account accountRecord) {
        return accountRecord.npe01__SYSTEM_AccountType__c
                == CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE;
    }

    private Boolean isHousehold(Account accountRecord) {
        return accountRecord.npe01__SYSTEM_AccountType__c
                == CAO_Constants.HH_ACCOUNT_TYPE;
    }

    private List<Id> getContactIds(List<Contact> contactsWithoutAccounts) {
        List<Id> contactIds = new List<Id>();
        for (Contact contactRecord : contactsWithoutAccounts) {
            if (contactRecord.Id != null) {
                contactIds.add(contactRecord.Id);
            }
        }
        return contactIds;
    }

    private List<Account> getAccounts(List<Id> contactIds) {
        return [
                SELECT Id, npe01__One2OneContact__c,
                        npe01__SYSTEM_AccountType__c,
                        Number_of_Household_Members__c,
                (SELECT Id FROM Contacts)
                FROM Account
                WHERE npe01__One2OneContact__c IN :contactIds
        ];
    }
}