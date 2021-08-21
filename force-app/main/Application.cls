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
* @description Top-level Application class for NPSP. The Application class creates
 * Households for new Contacts and passes existing Contacts to either
 * their Household domain (Households or LegacyHouseholds) or the Organizations domain.
*/
public inherited sharing class Application {

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
    private ContactService contactService {
        get {
            if (contactService == null) {
                contactService = new ContactService();
            }
            return contactService;
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

    public void onBeforeInsertOf(AccountsAdapter accounts) {
        if (AddressService.isAddressManagementEnabled()) {
            normalizeLineBreaksFor(accounts.householdAccounts());
        }
        if (AddressService.isOrgAccountAddressesEnabled()) {
            normalizeLineBreaksFor(accounts.orgAccounts());
        }
    }

    public void onAfterInsertOf(AccountsAdapter accounts, TDTM_Runnable.DmlWrapper dmlWrapper) {
        createAddressesFromNewAccounts(accounts, dmlWrapper);
    }

    private void createAddressesFromNewAccounts(AccountsAdapter accounts, TDTM_Runnable.DmlWrapper dmlWrapper) {
        AccountsAdapter accountsWithNewAddressesToCreate = accounts.newAccountsWithAddressesToCreate();
        if (accountsWithNewAddressesToCreate.getRecords().size() > 0) {
            AddressService.createAddressesFor(accountsWithNewAddressesToCreate, dmlWrapper, false);
        }
    }

    public void onAfterUpdateOf(AccountsAdapter accounts, TDTM_Runnable.DmlWrapper dmlWrapper) {
        // note that we detect whether the change is coming from the address trigger,
        // in which case we don't want to create a new address.
        if (TDTM_ProcessControl.isRecursive(
                TDTM_ProcessControl.flag.ADDR_hasRunTrigger)) {
            UTIL_Debug.debug('**** RECURSION: ' +
                    'Stop Addr Trigger recursion in ADDR_Account_TDTM');
            return;
        }

        AccountsAdapter updatedAccountsWithAddressesToCreateOrUpdate = accounts.updatedAccountsWithAddressesToCreateOrUpdate();

        if (updatedAccountsWithAddressesToCreateOrUpdate.getRecords().size() > 0) {
            AddressService.createAddressesFor(updatedAccountsWithAddressesToCreateOrUpdate, dmlWrapper, false);
        }
    }

    public void onAfterInsertOf(Contacts contacts, TDTM_Runnable.DmlWrapper dmlWrapper) {
        List<Contact> contactsWithAccountAndAddressFields =
                getContactsWithAccountAndAddressFields(contacts);

        LegacyHouseholds.updatePrimaryContactOnAccountsAfterInsert(
                dmlWrapper, contactsWithAccountAndAddressFields);

        Households.renameHouseholdAccountsAfterInsert(
                contactsWithAccountAndAddressFields);
    }

    /**
     * @description In the before update trigger context, ensure accounts are created for the contacts that need them.
     */
    public void onBeforeUpdateOf(Contacts contacts) {
        LegacyHouseholds.handleContactsBeforeUpdate(contacts);
    }

    public void onAfterUpdateOf(Contacts contacts, TDTM_Runnable.DmlWrapper dmlWrapper) {
        List<Contact> contactsWithAccountAndAddressFields =
                new ContactSelector().getContactsWithAccountAndAddressFields(
                        contacts.getRecords());
        LegacyHouseholds.handleContactsAfterUpdate(
                new Contacts(contactsWithAccountAndAddressFields, contacts.oldMap.values()),
                dmlWrapper);
    }

    public void onAfterDeleteOf(Contacts contacts, TDTM_Runnable.DmlWrapper dmlWrapper) {
        Households households = getHouseholdsFor(contacts.accountIds());
        households.handleContactDeletion(dmlWrapper);
    }

    public void onAfterUndeleteOf(Contacts contacts, TDTM_Runnable.DmlWrapper dmlWrapper) {
        List<Contact> contactsWithAccountAndAddressFields =
                getContactsWithAccountAndAddressFields(contacts);

        LegacyHouseholds.updatePrimaryContactOnAccountsAfterInsert(
                dmlWrapper, contactsWithAccountAndAddressFields);

        Households.renameHouseholdAccountsAfterInsert(
                contactsWithAccountAndAddressFields);
    }

    private List<Contact> getContactsWithAccountAndAddressFields(Contacts contacts) {
        List<Contact> contactsWithAccountAndAddressFields =
                contactSelector.getContactsWithAccountAndAddressFields(contacts.getRecords());
        return contactsWithAccountAndAddressFields;
    }

    private Households getHouseholdsFor(Set<Id> ids) {
        return new Households(householdSelector.findByIds(ids));
    }

}