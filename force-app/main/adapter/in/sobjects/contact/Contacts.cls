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
public inherited sharing class Contacts extends fflib_SObjects2 {

    public Map<Id, Contact> oldMap;

    @TestVisible
    private static ContactAndOrgSettings contactAndOrgSettings {
        get {
            if (contactAndOrgSettings == null) {
                contactAndOrgSettings = new ContactAndOrgSettings();
            }
            return contactAndOrgSettings;
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

    public Contacts(List<Contact> records) {
        this(records, null);
    }

    public Contacts(List<Contact> records, List<Contact> oldList) {
        super(records, Contact.SObjectType);
        this.oldMap = oldList != null ?
                new Map<Id, Contact>(oldList) : new Map<Id, Contact>();
    }

    public Contacts legacyHouseholdAndOrganizationContactsNeedingOneToOneAccounts() {
        List<Contact> contactsWithoutAccounts = new List<Contact>();
        for (Contact contactRecord : (List<Contact>) getRecords()) {
            if (LegacyHouseholds.isWithoutAccount(contactRecord)) {
                // Avoid creating a new contact with the 1:1 account of another contact
                resetAccountIdFor(contactRecord);
                contactsWithoutAccounts.add(contactRecord);
            }
        }

        List<Contact> organizationContacts = new List<Contact>();
        for (Contact contactRecord : (List<Contact>) getRecords()) {
            if (LegacyHouseholds.isOrganizationContact(contactRecord, accountFor(contactRecord))) {
                resetAccountIdFor(contactRecord);
                organizationContacts.add(contactRecord);
            }
        }
        List<Contact> contacts = new List<Contact>();
        contacts.addAll(contactsWithoutAccounts);
        contacts.addAll(organizationContacts);
        return new Contacts(contacts);
    }

    private void resetAccountIdFor(Contact contactRecord) {
        if (contactRecord.AccountId != null) {
            contactRecord.AccountId = null;
        }
    }

    /*******************************************************************************************************
    * @description replaces the losing address with the winning address in any contacts referring to the
    * loser.  Note that it just updates the contact's Address lookup, and doesn't copy any Address data.
    * Any Contacts that are modified are put on dmlWrapper for later updating.
    * @param addrLoser the Address to look for
    * @param addrWinner the Address to replace with
    * @param dmlWrapper to hold any Contacts that need updating
    */
    public void replaceAddress(Address__c addrLoser, Address__c addrWinner,
            TDTM_Runnable.DmlWrapper dmlWrapper) {
        List<Contact> contactsToUpdate = new List<Contact>();
        for (Contact con : (List<Contact>) getRecords()) {
            if (con.Current_Address__c == addrLoser.Id) {
                con.Current_Address__c = addrWinner.Id;
                contactsToUpdate.add(con);
            }
        }
        dmlWrapper.objectsToUpdate.addAll(contactsToUpdate);
    }

    public List<Contact> getOneToOneContactsToUpdate() {
        List<Contact> oneToOneContactsToUpdate = new List<Contact>();
        for (Contact contactRecord : (List<Contact>) getRecords()) {
            Contact oldContact = oldMap.get(contactRecord.Id);

            if (needsOne2OneAccountUpdate(contactRecord, oldContact)) {
                oneToOneContactsToUpdate.add(contactRecord);
            }
        }
        return oneToOneContactsToUpdate;
    }

    public Contact oldVersionOf(Contact con) {
        return oldMap.get(con.Id);
    }

    public List<Id> getHouseholdIdsToRename() {
        List<Id> householdIdsToRename = new List<Id>();
        for (Contact contactRecord : (List<Contact>) getRecords()) {
            Contact oldContact = oldVersionOf(contactRecord);
            if (needsHHAccountRename(contactRecord, oldContact)) {
                householdIdsToRename.add(contactRecord.AccountId);
            }
        }
        return householdIdsToRename;
    }

    public List<Id> getHouseholdIdsToRenameAndCountMembers() {
        Set<Id> uniqueAccountsToHandle = new Set<Id>(getHouseholdIdsToRename());

        for (Contact contactRecord : (List<Contact>) getRecords()) {
            Contact oldContact = oldVersionOf(contactRecord);
            if (needsHHDeceasedFlagUpdate(contactRecord, oldContact)) {
                uniqueAccountsToHandle.add(contactRecord.AccountId);
            }
        }

        return new List<Id>(uniqueAccountsToHandle);
    }

    public void resetDeprecatedFields() {
        for (Contact contactRecord : (List<Contact>) getRecords()) {
            // always clear this deprecated field to avoid confusing users.
            contactRecord.npe01__SystemAccountProcessor__c = null;
        }
    }

    public void resetSustainerFields() {
        for (Contact contactRecord : (List<Contact>) getRecords()) {
            contactRecord.Sustainer__c = oldVersionOf(contactRecord)?.Sustainer__c;
        }
    }

    public void keepPrivateContactsPrivate() {
        for (Contact contactRecord : (List<Contact>) getRecords()) {
            // for contacts marked private after they have been created, break the relationship from their account (any model)
            if (contactRecord.AccountId != null && contactRecord.npe01__Private__c == true) {
                contactRecord.AccountId = null;
            }
        }
    }

    public Set<Id> oldAccountIds() {
        Set<Id> accountIds = new Set<Id>();
        for (Contact contactRecord : oldMap.values()) {
            accountIds.add(contactRecord.AccountId);
        }
        return accountIds;
    }

    public Map<Id, Account> accountById {
        get {
            if (accountById == null) {
                loadAccountByIdMap();
            }
            return accountById;
        }
        set;
    }

    public Map<Id, Contact> getNewOwnerContactById() {
        Map<Id, Contact> newOwnerContactById = new Map<Id, Contact>();
        for (Contact contactRecord : (List<Contact>) getRecords()) {
            Contact oldContact = oldMap.get(contactRecord.Id);
            if (contactRecord.OwnerId != oldContact.OwnerId) {
                newOwnerContactById.put(contactRecord.Id, contactRecord);
            }
        }
        return newOwnerContactById;
    }

    public Set<Id> ids() {
        return getIdFieldValues(Contact.Id).getIds();
    }


    public Set<Id> accountIds() {
        Set<Id> setAccountId = new Set<Id>();
        for (Integer i = 0; i < getRecords().size(); i++) {
            Contact newRecord = (Contact) getRecords()[i];

            // need to query account fields we need to look at
            if (newRecord.AccountId != null) {
                setAccountId.add(newRecord.AccountId);
            }
        }
        return setAccountId;
    }

    public Contacts contactsWithNonNullAccountIds() {
        List<Contact> contactsWithNonNullAccountId = new List<Contact>();
        for (Contact contact :(List<Contact>)  getRecords()) {
            if (contact.AccountId != null) {
                contactsWithNonNullAccountId.add(contact);
            }
        }
        return new Contacts(contactsWithNonNullAccountId);
    }

    public List<Contact> publicContactsWithNonNullAccountIds() {
        List<Contact> contactsWithoutAccounts = new List<Contact>();
        for (Contact contactRecord : (List<Contact>) getRecords()) {
            if (contactRecord.AccountId == null
                    && contactRecord.npe01__Private__c != true) {
                contactsWithoutAccounts.add(contactRecord);
            }
        }
        return contactsWithoutAccounts;
    }

    /*******************************************************************************************************
    * @description returns whether changes in the contact require an update to the 1:1 account
    * @param contactRecord the new version of the Contact
    * @param oldContact the old version of the Contact
    * @return Boolean
    */
    private Boolean needsOne2OneAccountUpdate(Contact contactRecord, Contact oldContact) {
        if (contactRecord.npe01__Organization_Type__c != CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE) {
            return false;
        }

        if(contactRecord != null && oldContact == null) {
            return true;
        }

        String newFirst = contactRecord.FirstName == null ? '' : contactRecord.FirstName;
        String oldFirst = oldContact.FirstName == null ? '' : oldContact.FirstName;
        String newLast = contactRecord.LastName == null ? '' : contactRecord.LastName;
        String oldLast = oldContact.LastName == null ? '' : oldContact.LastName;

        return (contactRecord.AccountId != oldContact.AccountId ||
                !newFirst.equals(oldFirst) ||
                !newLast.equals(oldLast) ||
                contactRecord.MailingStreet != oldContact.MailingStreet ||
                contactRecord.MailingCity != oldContact.MailingCity ||
                contactRecord.MailingState != oldContact.MailingState ||
                contactRecord.MailingPostalCode != oldContact.MailingPostalCode ||
                contactRecord.MailingCountry != oldContact.MailingCountry ||
                contactRecord.OtherStreet != oldContact.OtherStreet ||
                contactRecord.OtherCity != oldContact.OtherCity ||
                contactRecord.OtherState != oldContact.OtherState ||
                contactRecord.OtherPostalCode != oldContact.OtherPostalCode ||
                contactRecord.OtherCountry != oldContact.OtherCountry ||
                contactRecord.Phone != oldContact.Phone ||
                contactRecord.Fax != oldContact.Fax);
    }

    private Boolean needsHHDeceasedFlagUpdate(Contact contactRecord, Contact oldContact) {
        if (!isContactInHouseholdAccount(contactRecord)) {
            return false;
        }
        return contactRecord.Deceased__c != oldContact.Deceased__c;
    }

    private Boolean isContactInHouseholdAccount(Contact contactRecord) {
        if (contactRecord.npe01__Organization_Type__c != CAO_Constants.HH_ACCOUNT_TYPE) {
            return false;
        }
        return true;
    }

    /*******************************************************************************************************
    * @description returns whether changes in the contact require a rename of a HH Account
    * @param contactRecord the new version of the Contact
    * @param oldContact the old version of the Contact
    * @return Boolean
    */
    private Boolean needsHHAccountRename(Contact contactRecord, Contact oldContact) {
        if (!isContactInHouseholdAccount(contactRecord)) {
            return false;
        }

        if (contactRecord != null && oldContact == null) {
            return true;
        }

        contactRecord.FirstName = contactRecord.FirstName == null ? '' : contactRecord.FirstName;
        contactRecord.LastName = contactRecord.LastName == null ? '' : contactRecord.LastName;

        // check all household naming fields for changes
        for (String fieldName : new HouseholdNamingService().getHouseholdNamingContactFields()) {
            String currentName;
            String oldName;

            //separate cross object references, i.e. account.name
            List<String> splitFields = (fieldName.split('\\.', 0));
            if (splitFields.size() > 1) {
                SObject sObj = contactRecord.getSObject(splitFields[0]);
                if (sObj != null) {
                    currentName = sObj.Id;
                }
                sObj = oldContact.getSObject(splitFields[0]);
                if (sObj != null) {
                    oldName = sObj.Id;
                }
            } else {
                currentName = String.valueOf(contactRecord.get(fieldName));
                oldName = String.valueOf(oldContact.get(fieldName));
            }

            // make sure to use case sensitive comparison
            if (currentName == null) {
                currentName = '';
            }
            if (oldName == null) {
                oldName = '';
            }
            if (!currentName.equals(oldName)) {
                return true;
            }
        }
        if (contactRecord.npo02__Household_Naming_Order__c != oldContact.npo02__Household_Naming_Order__c ||
                contactRecord.npo02__Naming_Exclusions__c != oldContact.npo02__Naming_Exclusions__c) {
            return true;
        }
        if (contactRecord.AccountId != null && contactRecord.AccountId != oldContact.AccountId) {
            return true;
        }
        return false;
    }

    private Account accountFor(Contact contactRecord) {
        return accountById.get(contactRecord.AccountId);
    }

    private void loadAccountByIdMap() {
        Set<Id> accountIds = new Set<Id>();
        for (Contact contactRecord : (List<Contact>) getRecords()) {
            accountIds.add(contactRecord.AccountId);
        }

        accountById = new Map<Id, Account>([
                SELECT Id, npe01__One2OneContact__c, npe01__SYSTEM_AccountType__c
                FROM Account
                WHERE Id IN :accountIds
        ]);
    }

}