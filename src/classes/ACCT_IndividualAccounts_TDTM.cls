/*
    Copyright (c) 2009, Salesforce.org
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
* @date 2011 (1.x)
* @group Accounts
* @description Implements one of three account models, 1x1 or bucket or HH - controls syncing within the model
*/
public class ACCT_IndividualAccounts_TDTM extends TDTM_Runnable {

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

    @TestVisible
    private HouseholdNamingService householdNamingService {
        get {
            if (householdNamingService == null) {
                householdNamingService = new HouseholdNamingService();
            }
            return householdNamingService;
        }
        set;
    }

    @TestVisible
    private AddressService addressService {
        get {
            if (addressService == null) {
                addressService = new AddressService();
            }
            return addressService;
        }
        set;
    }

    /*******************************************************************************************************************
     * @description the current Contact Settings object
     */
    private static npe01__Contacts_And_Orgs_Settings__c contactsSettings;

    private List<Contact> contacts;
    private Map<Id, Contact> oldContactById;
    private TDTM_Runnable.Action triggerAction;
    private DmlWrapper dmlWrapper = new DmlWrapper();
    private Contacts contactsInstance;

    /*******************************************************************************************************************
     * @description Trigger Handler on Contact that handles account management.  Depending on the Account
     * Model, creates a Household Account, One-to-One Account, or uses the Individual Bucket Account.
     * @param newSObjects the list of Contacts from trigger new.
     * @param oldSObjects the list of Contacts from trigger old.
     * @param triggerAction which trigger event (BeforeInsert, AfterInsert, etc.).
     * @param objResult the describe for Contacts
     * @return dmlWrapper.
     ********************************************************************************************************************/
    public override DmlWrapper run(List<SObject> newSObjects, List<SObject> oldSObjects,
        TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {

        this.contacts = newSObjects;
        this.oldContactById = oldSObjects == null ? new Map<Id, Contact>() : new Map<Id, Contact>(
                (List<Contact>) oldSObjects);
        this.triggerAction = triggerAction;
        contactsSettings = UTIL_CustomSettingsFacade.getContactsSettings();

        if (triggerAction == TDTM_Runnable.Action.BeforeInsert) {
            contactsInstance = new Contacts(contacts);
            processAccountsBeforeInsert();
        }

        if (triggerAction == TDTM_Runnable.Action.BeforeUpdate) {
            contactsInstance = new Contacts(newSObjects, oldSObjects);
            processAccountsBeforeUpdate();
        }

        if (triggerAction == TDTM_Runnable.Action.AfterInsert || triggerAction == TDTM_Runnable.Action.AfterUpdate || triggerAction == TDTM_Runnable.Action.AfterUndelete) {
            handleAfter();

        } else if (triggerAction == TDTM_Runnable.Action.AfterDelete) {
            Contacts deletedContacts = new Contacts(new List<Contact>(), oldSObjects);
            deletedContacts.onAfterDelete_ACCT_IndividualAccounts_TDTM();
        }

        return dmlWrapper;
    }

    /**
     * @description In the after trigger context, additional fields from the account related to the contact are queried for processing
     * household updates.
     */
    private void handleAfter() {
        contacts = new ContactSelector().getContactsWithAccountAndAddressFields(contacts);
        contactsInstance = new Contacts(contacts, oldContactById.values());

        if (triggerAction == TDTM_Runnable.Action.AfterInsert || triggerAction == TDTM_Runnable.Action.AfterUndelete) {
            Households.updatePrimaryContactOnAccountsAfterInsert(
                    dmlWrapper, contacts);

            HouseholdAccounts.renameHouseholdAccountsAfterInsert(contacts);
        }

        if (triggerAction == TDTM_Runnable.Action.AfterUpdate) {
            processAccountsAfterUpdate();
        }

    }

    /**
     * @description In the before insert trigger context,
     * ensure accounts are created for the new contacts that need them.
     */
    private void processAccountsBeforeInsert() {
        avoidConfusion();

        HouseholdAccounts.createOneToOneAndHouseholdAccountsFor(
                (List<Contact>) contactsInstance.contactsAndOneToOneContacts_insertContext()
                        .getRecords());

        Households.attachToBucketAccount(
                (List<Contact>) contactsInstance.bucketContacts_insertContext()
                        .getRecords()
        );
    }

    private void avoidConfusion() {
        for (Contact contactRecord : contacts) {
            // always clear this deprecated field to avoid confusing users.
            contactRecord.npe01__SystemAccountProcessor__c = null;
        }
    }

    /**
     * @description In the before update trigger context, ensure accounts are created for the contacts that need them.
     * @param  accountById - the existing accounts that the contacts are related to.
     */
    private void processAccountsBeforeUpdate() {
        avoidConfusion();

        List<Contact> contactsWithoutAccounts = getContactsWithoutAccounts_beforeInsertContext();

        keepPrivateContactsPrivate();

        HouseholdAccounts.createOneToOneAndHouseholdAccountsFor(contactsWithoutAccounts);

        if (isBucketModelEnabled()) {
            Households.attachToBucketAccount(
                    contactsInstance.contactsWithoutAccounts()
            );
        }
    }

    private List<Contact> getContactsWithoutAccounts_beforeInsertContext() {
        List<Contact> contactsWithoutAccounts = new List<Contact>();

        if (isHouseholdAccountModelEnabled()) {
            contactsWithoutAccounts.addAll(contactsInstance.contactsWithoutAccounts());
        }

        if (isOneToOneEnabled()) {
            contactsWithoutAccounts.addAll(
                    Households.contactsWithoutAccounts(contactsInstance, oldContactById));
        }
        return contactsWithoutAccounts;
    }

    private Boolean isOneToOneEnabled() {
        return CAO_Constants.isOneToOne();
    }

    private Boolean isHouseholdAccountModelEnabled() {
        return CAO_Constants.isHHAccountModel();
    }

    private void keepPrivateContactsPrivate() {
        for (Contact contactRecord : contacts) {
            // for contacts marked private after they have been created, break the relationship from their account (any model)
            if (contactRecord.AccountId != null && contactRecord.npe01__Private__c == true) {
                contactRecord.AccountId = null;
            }
        }
    }

    /**
     * @description Depending on the contacts household type, this method will update the one to one account,
     * move opportunities related to contacts changing accounts, update household accounts, rename household accounts
     * update account owners based on the change in contact owner
     */
    private void processAccountsAfterUpdate() {
        Households.updateOneToOneAccounts(
                contactsInstance.getOneToOneContactsToUpdate(), dmlWrapper);

        HouseholdAccounts.handleContactsAfterUpdate(contactsInstance, dmlWrapper);
        householdNamingService.renameHouseholdAccounts(
                contactsInstance.getHouseholdIdsToRename(contactsInstance));
        updateOwners(contactsInstance.getNewOwnerContactById());
    }

    /*******************************************************************************************************
    * @description contact's owner has changed.  consider updating related account owner.
    * @param newOwnerContactById a map of Contact Id to Contact, for the contacts to consider
    */
    private void updateOwners(Map<Id, Contact> newOwnerContactById) {
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

    private Boolean isBucketModelEnabled() {
        return CAO_Constants.isBucketModel();
    }

}