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
* @description The ContactAdapter's role is to provide clients with a single Type
* that will handle DML on Contacts and call the appropriate method on Domains.
*/
public inherited sharing class ContactAdapter extends fflib_SObjects {

    public Map<Id, Contact> oldMap;

    //Note: Eventually this Selector should be removed from the Adapter layer.
    //  Should move toward a design where the Adapter layer simply passes
    //  data on to domains, which would use their own Selectors to query additional
    //  data when needed.  It is here temporarily as the Contact domains get
    //  put in place and stabilized.
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

    @TestVisible
    private HouseholdSelector householdSelector {
        get {
            if (householdSelector == null) {
                householdSelector = new HouseholdSelector();
            }
            return householdSelector;
        }
        set;
    }

    @TestVisible
    private HouseholdService householdServiceInstance {
        get {
            if (householdServiceInstance == null) {
                householdServiceInstance = new HouseholdService();
            }
            return householdServiceInstance;
        }
        set;
    }

    @TestVisible
    private static ContactAndOrgSettings contactAndOrgSettingsInst {
        get {
            if (contactAndOrgSettingsInst == null) {
                contactAndOrgSettingsInst = new ContactAndOrgSettings();
            }
            return contactAndOrgSettingsInst;
        }
        set;
    }

    public ContactAdapter(List<Contact> records) {
        this(records, null);
    }

    public ContactAdapter(List<Contact> records, List<Contact> oldList) {
        super(records, Contact.SObjectType);
        this.oldMap = oldList != null ?
                new Map<Id, Contact>(oldList) : new Map<Id, Contact>();
    }

    public void onAfterInsert(TDTM_Runnable.DmlWrapper dmlWrapper) {
        List<Contact> contactsWithAccountAndAddressFields =
                getContactsWithAccountAndAddressFields();

        LegacyHouseholds.updatePrimaryContactOnAccountsAfterInsert(
                dmlWrapper, contactsWithAccountAndAddressFields);

        Households.renameHouseholdAccountsAfterInsert(
                contactsWithAccountAndAddressFields);
    }

    private List<Contact> getContactsWithAccountAndAddressFields() {
        List<Contact> contactsWithAccountAndAddressFields =
                contactSelector.getContactsWithAccountAndAddressFields(getRecords());
        return contactsWithAccountAndAddressFields;
    }

    public void onBeforeUpdate() {
        handleContactsBeforeUpdate(
                new Contacts(getRecords(), oldMap.values()));
    }

    private static List<Contact> contactsWithoutAccounts(Contacts contacts) {
        List<Contact> contactsWithoutAccounts = new List<Contact>();

        if (contactAndOrgSettingsInst.isHouseholdAccountModelEnabled()) {
            contactsWithoutAccounts.addAll(contacts.contactsWithoutAccounts());
        }

        if (contactAndOrgSettingsInst.isOneToOneAccountsEnabled()) {
            contactsWithoutAccounts.addAll(
                    contactsWithoutAccountsAndOrganizationContacts(contacts));
        }
        return contactsWithoutAccounts;
    }

    private static List<Contact> contactsWithoutAccountsAndOrganizationContacts(Contacts contactsInstance) {
        List<Contact> contactsWithoutAccounts2 = new List<Contact>();
        Map<Id, Account> accountsByIds = contactsInstance.accountById;
        for (Contact contactRecord : (List<Contact>) contactsInstance.getRecords()) {
            Account account = accountsByIds.get(contactRecord.AccountId);
            if (isWithoutAccount(contactRecord)
                    || isOrganizationContact(contactRecord, account)) {

                Contact oldContact = contactsInstance.oldMap.get(contactRecord.Id);

                if (shouldClearExistingOneToOneAccount(contactRecord, oldContact,
                        account)) {
                    contactRecord.AccountId = null;
                }

                if (contactRecord.AccountId == null) {
                    contactsWithoutAccounts2.add(contactRecord);
                }

            }
        }
        return contactsWithoutAccounts2;
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

    /**
     * @description - Determine whether the account belongs to another contact and is not
     * an deleted during an account merge.
     */
    private static Boolean shouldClearExistingOneToOneAccount(Contact contactRecord, Contact
            oldContact, Account accountRecord) {
        Boolean isExistingOneToOne = contactRecord.AccountId != null
            && accountRecord.npe01__One2OneContact__c != contactRecord.Id
            && accountRecord.npe01__One2OneContact__c != null
            && contactRecord.AccountId != oldContact.AccountId;

        if (!isExistingOneToOne) {
            return false;
        }

        Boolean isDeletedOldAccount = [SELECT COUNT() FROM Account WHERE Id =: oldContact.AccountId] == 0;

        return !isDeletedOldAccount;

    }

    /**
     * @description In the before update trigger context, ensure accounts are created for the contacts that need them.
     */
    private void handleContactsBeforeUpdate(Contacts contacts) {
        contacts.resetDeprecatedFields();
        contacts.keepPrivateContactsPrivate();
        householdServiceInstance.createOneToOneAndHouseholdAccountsFor(
                contactsWithoutAccounts(contacts));

        if (contactAndOrgSettingsInst.isBucketAccountEnabled()) {
            LegacyHouseholds.attachToBucketAccount(
                    contacts.contactsWithoutAccounts()
            );
        }
    }

    public void onAfterUpdate(TDTM_Runnable.DmlWrapper dmlWrapper) {
        List<Contact> contactsWithAccountAndAddressFields =
                new ContactSelector().getContactsWithAccountAndAddressFields(getRecords());
        LegacyHouseholds.handleContactsAfterUpdate(
                new Contacts(contactsWithAccountAndAddressFields, oldMap.values()),
                dmlWrapper);
    }

    public void onAfterDelete(TDTM_Runnable.DmlWrapper dmlWrapper) {
        Households households = getHouseholdsFor(accountIds());
        households.handleContactDeletion(dmlWrapper);
    }

    private Households getHouseholdsFor(Set<Id> ids) {
        return new Households(householdSelector.findByIds(ids));
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

    public void onAfterUndelete(TDTM_Runnable.DmlWrapper dmlWrapper) {
        List<Contact> contactsWithAccountAndAddressFields =
                getContactsWithAccountAndAddressFields();

        LegacyHouseholds.updatePrimaryContactOnAccountsAfterInsert(
                dmlWrapper, contactsWithAccountAndAddressFields);

        Households.renameHouseholdAccountsAfterInsert(
                contactsWithAccountAndAddressFields);
    }

    public void onBeforeInsert(List<Contact> newSObjects) {
        Contacts contacts = new Contacts(newSObjects);
        contacts.resetDeprecatedFields();

        if (CAO_Constants.isHHAccountModel()) {
            householdServiceInstance.createOneToOneAndHouseholdAccountsFor(
                    contacts.contactsWithoutAccounts());
        } else {
            if (CAO_Constants.isOneToOne()) {
                householdServiceInstance.createOneToOneAndHouseholdAccountsFor(
                        (List<Contact>) contacts.legacyHouseholdAndOrganizationContactsNeedingOneToOneAccounts()
                                .getRecords());
            }

            if (CAO_Constants.isBucketModel()) {
                LegacyHouseholds.attachToBucketAccount(
                        contacts.contactsWithoutAccounts());
            }
        }

    }
}