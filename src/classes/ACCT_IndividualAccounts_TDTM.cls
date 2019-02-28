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

    /*******************************************************************************************************************
     * @description the current Contact Settings object
     */
    private static npe01__Contacts_and_Orgs_Settings__c contactsSettings;
    /*******************************************************************************************************************
     * @description the set of fields used for household naming
     */
    private static final Set<String> HH_NAMING_FIELDS = new HH_HouseholdNaming().getHouseholdNamingContactFields();
    /*******************************************************************************************************************
     * @description a set of languages that require different naming conventions
     */
    private static final Set<String> EASTERN_ORDER_LANGUAGES = new Set<String>{
        'ja',
        'ko',
        'vi',
        'hu',
        'ro',
        'zh_CN',
        'zh_TW'
    };
    /*******************************************************************************************************************
     * @description the current user's Locale/Language
     */
    private static String userLocale {
        get {
            if (userLocale == null) {
                userLocale = UserInfo.getLocale();
            }

            return userLocale;
        }
        set;
    }

    private List<Contact> contacts;
    private List<Contact> oldContacts;
    private TDTM_Runnable.Action triggerAction;
    private DmlWrapper dmlWrapper;

    /*******************************************************************************************************************
     * @description Trigger Handler on Contact that handles account management.  Depending on the Account
     * Model, creates a Household Account, One-to-One Account, or uses the Individual Bucket Account.
     * @param listNew the list of Contacts from trigger new.
     * @param listOld the list of Contacts from trigger old.
     * @param triggerAction which trigger event (BeforeInsert, AfterInsert, etc.).
     * @param objResult the describe for Contacts
     * @return dmlWrapper.
     ********************************************************************************************************************/
    public override DmlWrapper run(List<SObject> newSObjects, List<SObject> oldSObjects,
        TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {

        this.contacts = newSObjects;
        this.oldContacts = oldSObjects;
        this.triggerAction = triggerAction;
        dmlWrapper = new DmlWrapper();
        contactsSettings = UTIL_CustomSettingsFacade.getContactsSettings();

        if (triggerAction == TDTM_Runnable.Action.BeforeInsert || triggerAction == TDTM_Runnable.Action.BeforeUpdate) {
            handleBefore();

        } else if (triggerAction == TDTM_Runnable.Action.AfterInsert || triggerAction == TDTM_Runnable.Action.AfterUpdate || triggerAction == TDTM_Runnable.Action.AfterUndelete) {
            handleAfter();

        } else if (triggerAction == TDTM_Runnable.Action.AfterDelete) {
            processAccountsAfterDelete(oldContacts);
        }

        return dmlWrapper;
    }

    /**
     * @description In the before trigger context, determines whether or not a contact requires a new account.
     */
    private void handleBefore() {
        Map<Id, Account> accountById = null;

        Set<Id> accountIds = new Set<Id>();
        for (Contact contactRecord : contacts) {
            accountIds.add(contactRecord.AccountId);
        }

        accountById = new Map<Id, Account>([SELECT Id, npe01__One2OneContact__c, npe01__SYSTEM_AccountType__c FROM Account WHERE Id IN :accountIds]);

        if (triggerAction == TDTM_Runnable.Action.BeforeInsert) {
            processAccountsBeforeInsert(accountById);
        }

        if (triggerAction == TDTM_Runnable.Action.BeforeUpdate) {
            processAccountsBeforeUpdate(accountById);
        }

    }

    /**
     * @description In the after trigger context, additional fields from the account related to the contact are queried for processing
     * household updates.
     */
    private void handleAfter() {
        String soql = buildContactSoql();
        contacts = database.query(soql);

        if (triggerAction == TDTM_Runnable.Action.AfterInsert || triggerAction == TDTM_Runnable.Action.AfterUndelete) {
            processAccountsAfterInsert();
        }

        if (triggerAction == TDTM_Runnable.Action.AfterUpdate) {
            processAccountsAfterUpdate();
        }

    }

    /**
     * @description In the before insert trigger context, ensure accounts are created for the new contacts that need them.
     * @param  accountById - the existing accounts that the contacts are related to.
     */
    private void processAccountsBeforeInsert(Map<Id, Account> accountById) {
        List<Contact> contactsWithoutAccounts = new List<Contact>();
        List<Contact> contactsWithoutBucketAccount = new List<Contact>();

        for (Contact contactRecord : contacts) {
            // always clear this deprecated field to avoid confusing users.
            contactRecord.npe01__SystemAccountProcessor__c = null;

            if (needsHHAccount(contactRecord)) {
                contactsWithoutAccounts.add(contactRecord);
            }

            else if (needsOneToOneAccount(contactRecord, accountById.get(contactRecord.AccountId))) {
                // Avoid creating a new contact with the 1:1 account of another contact
                if (contactRecord.AccountId != null) {
                    contactRecord.AccountId = null;
                }

                contactsWithoutAccounts.add(contactRecord);
            }
            else if (needsBucketAccount(contactRecord)) {
                contactsWithoutBucketAccount.add(contactRecord);
            }
        }

        insertContactAccount(contactsWithoutAccounts);
        attachToBucketAccount(contactsWithoutBucketAccount);
    }

    /**
     * @description In the before update trigger context, ensure accounts are created for the contacts that need them.
     * @param  accountById - the existing accounts that the contacts are related to.
     */
    private void processAccountsBeforeUpdate(Map<Id, Account> accountById) {
        List<Contact> contactsWithoutAccounts = new List<Contact>();
        List<Contact> contactsWithoutBucketAccount = new List<Contact>();

        Integer index = 0;
        for (Contact contactRecord : contacts) {
            // always clear this deprecated field to avoid confusing users.
            contactRecord.npe01__SystemAccountProcessor__c = null;

            if (needsHHAccount(contactRecord)) {
                contactsWithoutAccounts.add(contactRecord);

            } else if (needsOneToOneAccount(contactRecord, accountById.get(contactRecord.AccountId))) {
                Contact oldContact = oldContacts[index];

                if (shouldClearExistingOneToOneAccount(contactRecord, oldContact, accountById.get(contactRecord.AccountId))) {
                    contactRecord.AccountId = null;
                }

                if (contactRecord.AccountId == null) {
                    contactsWithoutAccounts.add(contactRecord);
                }

            } else if (needsBucketAccount(contactRecord)) {
                contactsWithoutBucketAccount.add(contactRecord);
            }

            // for contacts marked private after they have been created, break the relationship from their account (any model)
            if (contactRecord.AccountId != null && contactRecord.npe01__Private__c == true) {
                contactRecord.AccountId = null;
            }

            index++;
        }

        insertContactAccount(contactsWithoutAccounts);
        attachToBucketAccount(contactsWithoutBucketAccount);
    }

    /**
     * @description Sets the primary contact on the account when needed and renames the household.
     */
    private void processAccountsAfterInsert() {
        Map<Id, Id> primaryContactByAccountId = new Map<Id, Id>();
        List<Id> householdIdsToRename = new List<Id>();

        for (Contact contactRecord : contacts) {
            if (contactRecord.AccountId == null) {
                continue;
            }

            if (needsPrimaryContact(contactRecord)) {
                primaryContactByAccountId.put(contactRecord.AccountId, contactRecord.Id);
            }

            if (isHouseholdMember(contactRecord)) {
                householdIdsToRename.add(contactRecord.AccountId);
            }
        }

        if (primaryContactByAccountId.size() > 0) {
            updatePrimaryContactOnAccount(primaryContactByAccountId);
        }

        if (householdIdsToRename.size() > 0) {
            renameHHAccounts(householdIdsToRename);
        }
    }

    /**
     * @description Depending on the contacts household type, this method will update the one to one account,
     * move opportunities related to contacts changing accounts, update household accounts, rename household accounts
     * update account owners based on the change in contact owner
     */
    private void processAccountsAfterUpdate() {
        List<Id> householdIdsToUpdate = new List<Id>();
        List<Id> householdIdsToRename = new List<Id>();
        List<Contact> oneToOneContactsToUpdate = new List<Contact>();
        Map<Id, Id> oldHouseholdIdByContactId = new Map<Id, Id>();
        Map<Id, Id> newHouseholdIdByContactId = new Map<Id, Id>();
        Map<Id, Contact> contactWithNewOwnerById = new Map<Id, Contact>();

        Integer index = 0;
        for (Contact contactRecord : contacts) {
            Contact oldContact = oldContacts[index];

            if (needsOne2OneAccountUpdate(contactRecord, oldContact)) {
                oneToOneContactsToUpdate.add(contactRecord);
            }

            if (contactRecord.OwnerId != oldContact.OwnerId) {
                contactWithNewOwnerById.put(contactRecord.Id, contactRecord);
            }

            if (contactRecord.AccountId != oldContact.AccountId) {
                addHouseholdIds(householdIdsToUpdate, newHouseholdIdByContactId, contactRecord);
                addHouseholdIds(householdIdsToUpdate, oldHouseholdIdByContactId, oldContact);

            } else if (needsHHAccountRename(contactRecord, oldContact)) {
                householdIdsToRename.add(contactRecord.AccountId);
            }

            index++;
        }

        updateOneToOneAccounts(oneToOneContactsToUpdate);
        moveOppsToContactAccount(newHouseholdIdByContactId, oldHouseholdIdByContactId);
        updateHHAccount(householdIdsToUpdate);
        renameHHAccounts(householdIdsToRename);
        updateOwners(contactWithNewOwnerById);
    }

    /*******************************************************************************************************
    * @description Updates the accounts for contacts that have been deleted if they have other hh members
    * @param deletedContacts the list of Contacts that need to be considered
    * @return void
    */
    private void processAccountsAfterDelete(List<Contact> deletedContacts) {
        List<Id> accountIds = new List<Id>();
        List<Id> householdIdsToUpdate = new List<Id>();
        List<Account> accounts = new List<Account>();

        for (Contact thisContact : deletedContacts) {
            accountIds.add(thisContact.accountId);
        }

        accounts = [SELECT Id, Type, npe01__SYSTEM_AccountType__c, (SELECT Id FROM Opportunities LIMIT 1), (SELECT Id FROM Contacts LIMIT 1) FROM Account WHERE Id IN :accountIds];

        for (Account accountRecord : accounts) {
            if (accountRecord.Contacts.size() > 0
                && accountRecord.npe01__SYSTEM_AccountType__c == CAO_Constants.HH_ACCOUNT_TYPE) {
                householdIdsToUpdate.add(accountRecord.Id);
            }
        }

        updateHHAccount(householdIdsToUpdate);
    }

    /*******************************************************************************************************
    * @description Updates Accounts with the primary Individual Contact Id. Used for 1:1 and HH Accounts.
    * @param mapAccountIdContactId a map of AccountId's to ContactId's which specifies which accounts need updating.
    * @return void
    */
    private void updatePrimaryContactOnAccount(Map<Id, Id> mapAccountIdContactId) {
        List<Account> listAccount = new List<Account>();
        for (Id i : mapAccountIdContactId.keySet()) {
            Account a = new Account(Id = i, npe01__One2OneContact__c = mapAccountIdContactId.get(i));
            listAccount.add(a);
        }
        if (listAccount.size() > 0) {
            dmlWrapper.objectsToUpdate.addAll(listAccount);
            //Database.SaveResult[] lsr = Database.update(listAccount, false);
        }
    }

    /*******************************************************************************************************
    * @description Updates an HH Account's naming, primary contact, and rollups
    * @param accountIds the list of Account (Id's) that need updating.
    * @return void
    */
    private void updateHHAccount(List<Id> accountIds) {
        if (accountIds.isEmpty()) {
            return;
        }

        resetPrimaryContactForAccount(accountIds);
        renameHHAccounts(accountIds);
        rollupAccounts(accountIds);
    }

    /*******************************************************************************************************
    * @description sets the Primary Account for each Account in the list of Accounts
    * @param listAccountId the list of Account (Id's) that need updating.
    * @return void
    */
    private void resetPrimaryContactForAccount(List<Id> listAccountId) {

        // for each account, we need a set of their contacts.
        Map<Id, Set<Id>> mapAccountIdSetContacts = new Map<Id, Set<Id>>();

        List<Contact> listCon = [SELECT Id, AccountId, Account.npe01__One2OneContact__c FROM Contact WHERE AccountId IN :listAccountId];
        for (Contact con : listCon) {
            Set<Id> setContactId = mapAccountIdSetContacts.get(con.AccountId);
            if (setContactId == null) {
                setContactId = new Set<Id>();
                mapAccountIdSetContacts.put(con.AccountId, setContactId);
            }
            setContactId.add(con.Id);
        }

        // now go thru each account and update their primary contact if the current one isn't valid
        List<Account> listAcc = [SELECT Id, npe01__One2OneContact__c FROM Account WHERE Id IN :listAccountId];
        List<Account> listAccToUpdate = new List<Account>();
        for (Account acc : listAcc) {
            Set<Id> setContactId = mapAccountIdSetContacts.get(acc.Id);
            if (setContactId != null && !setContactId.contains(acc.npe01__One2OneContact__c)) {
                acc.npe01__One2OneContact__c = firstIdFromSet(setContactId);
                listAccToUpdate.add(acc);
            }
        }

        // now do the update
        dmlWrapper.objectsToUpdate.addAll(listAccToUpdate);
        //update listAccToUpdate;
    }

    /*******************************************************************************************************
     * @description Builds SOQL on Contact Sobject. Fields include Household Naming Settings Format fields.
     * @return String SOQL
     */
    @TestVisible
    private String buildContactSoql() {
        List<String> selectFields = new List<String>{
            'Id', 'npe01__Private__c', 'AccountId', 'Account.npe01__SYSTEMIsIndividual__c',
            'Account.npe01__SYSTEM_AccountType__c', 'Account.npe01__One2OneContact__c', 'npe01__Organization_Type__c', 'Account.Name',
            'FirstName', 'LastName', 'OwnerId', 'Salutation', 'npo02__Naming_Exclusions__c', 'npo02__Household_Naming_Order__c',
            'MailingStreet', 'MailingCity', 'MailingState', 'MailingPostalCode', 'MailingCountry', 'MailingLatitude', 'MailingLongitude',
            'OtherStreet', 'OtherCity', 'OtherState', 'OtherPostalCode', 'OtherCountry', 'OtherLatitude', 'OtherLongitude',
            'Phone', 'Fax'
        };

        if (ADDR_Addresses_TDTM.isStateCountryPicklistsEnabled) {
            selectFields.add('MailingCountryCode');
            selectFields.add('MailingStateCode');
            selectFields.add('OtherCountryCode');
            selectFields.add('OtherStateCode');
        }

        selectFields.addAll(HH_NAMING_FIELDS);

        return new UTIL_Query()
            .withSelectFields(selectFields)
            .withFrom(String.valueOf(Contact.SObjectType))
            .withWhere('Id IN :contacts')
            .build();
    }

    /*******************************************************************************************************
    * @description returns the first Id from the specified set
    * @param ids a set of Id's
    * @return Id.  null if the set is empty.
    */
    private Id firstIdFromSet(Set<Id> ids) {
        for (Id recordId : ids) {
            return recordId;
        }
        return null;
    }

    /**
     * addHouseholdIds Adds the account ids from all of the contacts belonging to a household
     * @param  householdIds           The collection of householdIds to add the account ids to
     * @param  householdIdByContactId The map of household by their id.
     * @param  contactRecord          The contact to extract the id from.
     */
    private void addHouseholdIds(List<Id> householdIds, Map<Id, Id> householdIdByContactId, Contact contactRecord) {
        if (contactRecord.npe01__Organization_Type__c == CAO_Constants.HH_ACCOUNT_TYPE) {
            householdIds.add(contactRecord.AccountId);
            householdIdByContactId.put(contactRecord.Id, contactRecord.AccountId);
        }
    }

    /*******************************************************************************************************
    * @description Updates Contacts to relate to a single Individual Account
    * @param contacts the list of Contacts that need updating.
    * @return void
    */
    private void attachToBucketAccount(List<Contact> contactsWithoutBucketAccount){
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
            individual.npe01__SYSTEMISINDIVIDUAL__c = true;
            //individual.Type = CAO_Constants.BUCKET_ORGANIZATION_TYPE;
            individual.npe01__SYSTEM_AccountType__c = CAO_Constants.BUCKET_ORGANIZATION_TYPE;
            UTIL_DMLService.insertRecord(individual);

            for (Contact contactRecord : contactsWithoutBucketAccount) {
                //connect Contact to bucket Account
                contactRecord.AccountId = individual.Id;
            }
        }
    }

    /*******************************************************************************************************
    * @description Inserts a new 1:1 or HH Account for an Individual Contact
    * @param contactsWithoutAccounts the list of Contacts that need updating.
    * @return void
    */
    private void insertContactAccount(List<Contact> contactsWithoutAccounts){
        if (contactsWithoutAccounts.isEmpty()) {
            return;
        }

        List<Id> contactIds = new List<Id>();
        Map<Id, Account> mapContactIdAccount = new Map<Id, Account>();
        List<Contact> listContactNewAcct = new List<Contact>();

        for (Contact contactRecord : contactsWithoutAccounts) {
            //track which contacts are being inserted vs. updated
            if (contactRecord.Id != null) {
                contactIds.add(contactRecord.Id);
            }
        }
        // get all the Accounts that are connected to the existing Contacts
        for (Account acc : [SELECT Id, npe01__One2OneContact__c, npe01__SYSTEM_AccountType__c FROM Account
                WHERE npe01__One2OneContact__c IN :contactIds]) {
            mapContactIdAccount.put(acc.npe01__One2OneContact__c, acc);
        }

        List<Account> accountInserts = new List<Account>();
        Id rtIdAcccount = rtIdForNewAccount();

        for (Contact contactRecord : contactsWithoutAccounts) {
            // if we found an Account already connected to this Contact, connect the Contact to that Account if it
            // is the correct type for the current account processor
            Account acc = mapContactIdAccount.get(contactRecord.Id);
            if (acc != null &&
                ((CAO_Constants.isHHAccountModel() && acc.npe01__SYSTEM_AccountType__c == CAO_Constants.HH_ACCOUNT_TYPE) ||
                (CAO_Constants.isOneToOne() && acc.npe01__SYSTEM_AccountType__c == CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE)) ) {
                // if a user has blanked out the Account for a Contact, this will put it right back
                contactRecord.AccountId = acc.Id;
            } else {
                // construct the individul account for the Contact
                Account a = new Account();

                // construct the Account name
                a.Name = CAO_Constants.isHHAccountModel() ? strNameHHAccountForContact(contactRecord) : strNameOne2OneAccountForContact(contactRecord);

                // connect the Account to the Contact for 1:1 and HHAccount
                if (contactRecord.Id != null) {
                    a.npe01__One2OneContact__c = contactRecord.Id;
                }
                a.Phone = contactRecord.Phone;
                a.Fax = contactRecord.Fax;
                a.OwnerId = contactRecord.OwnerId;
                // only set account's billing address if address management is off.
                // otherwise, we'll let ADDR_Contact_TDTM push the new address into the account.
                if (!CAO_Constants.isHHAccountModel() || UTIL_CustomSettingsFacade.getContactsSettings().Household_Account_Addresses_Disabled__c) {
                    ADDR_Addresses_TDTM.copyAddressStdSObj(contactRecord, 'Mailing', a, 'Billing');
                }
                ADDR_Addresses_TDTM.copyAddressStdSObj(contactRecord, 'Other', a, 'Shipping');

                a.npe01__SYSTEM_AccountType__c = CAO_Constants.isHHAccountModel() ? CAO_Constants.HH_ACCOUNT_TYPE : CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE;
                if (rtIdAcccount != null) {
                    a.put('RecordTypeID', rtIdAcccount);
                }
                a.Type = CAO_Constants.isHHAccountModel() ? CAO_Constants.HH_TYPE : '';
                a.npe01__SYSTEMISINDIVIDUAL__c = true;
                accountInserts.add(a);
                listContactNewAcct.add(contactRecord);
            }
        }

        if (accountInserts.size() > 0) {
            // with current TDTM design, we can't use dmlWrapper
            // because we need to get the new AccountID's into the Contacts.

            // identify the specific records that had the problem, and don't fail the whole batch
            List<Database.SaveResult> insertResults = UTIL_DMLService.insertRecords(accountInserts, false);
            for (integer i = 0; i < insertResults.size(); i++) {
                Database.SaveResult sr = insertResults[i];
                if (!sr.isSuccess()) {
                    for (Database.Error err : sr.getErrors()) {
                        accountInserts[i].addError(err.getMessage());
                        Contact con = listContactNewAcct[i];
                        con.addError(String.format(label.conFailedAccountCreate, new String[]{con.Firstname, con.Lastname, err.getMessage()}));
                    }
                }
            }

            // now update each contact's accountId
            Integer i = 0;
            for (Contact contactRecord : listContactNewAcct) {
                contactRecord.AccountId = accountInserts[i].Id;
                i++;
            }
        }
    }

    /*******************************************************************************************************
    * @description Updates an Individual Account for an Individual Contact
    * @param oneToOneContactsToUpdate the list of Contacts that need updating.
    * @return void
    */
    private void updateOneToOneAccounts(List<Contact> oneToOneContactsToUpdate){
        if (oneToOneContactsToUpdate.isEmpty()) {
            return;
        }

        Map<Id,Contact> accConMap = new Map<Id,Contact>();
        for (Contact contactRecord : oneToOneContactsToUpdate) {
            accConMap.put(contactRecord.AccountId, contactRecord);
        }
        //get the corresponding Accounts
        // DJH: note that we explicitly do NOT get the account name.  This is to avoid the changes to the account from
        // this routine which get added to dmlWrapper, don't end up overwriting the name changes that are done syncronously
        // for HH accounts (which don't use dmlWrapper).
        List<Account> accts = [SELECT a.npe01__SYSTEM_AccountType__c, a.ShippingStreet, a.ShippingState, a.ShippingPostalCode, a.ShippingCountry,
            a.ShippingCity, a.BillingStreet, a.BillingState, a.BillingPostalCode, a.BillingCountry, a.BillingCity
            FROM Account a WHERE a.Id IN :accConMap.keyset()];
        List<Account> listAccount = new List<Account>();

        for (Account a : accts) {
            Contact contactRecord = accConMap.get(a.Id);
            //if any address data has changed on the contact, push it all to the Account
            {
                // Update Account fields
                ADDR_Addresses_TDTM.copyAddressStdSObj(contactRecord, 'Mailing', a, 'Billing');
                ADDR_Addresses_TDTM.copyAddressStdSObj(contactRecord, 'Other', a, 'Shipping');

                if (a.npe01__SYSTEM_AccountType__c == CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE) {
                    a.Name = strNameOne2OneAccountForContact(contactRecord);
                }
                // HH Account naming updates handled seperately to deal with asyncronous naming

                listAccount.add(a);
            }
        }

        if (listAccount.size() > 0) {
            dmlWrapper.objectsToUpdate.addAll(listAccount);
        }
    }

    /*******************************************************************************************************
    * @description contact's owner has changed.  consider updating related account owner.
    * @param contactWithNewOwnerById a map of Contact Id to Contact, for the contacts to consider
    * @return void
    */
    private void updateOwners(Map<Id, Contact> contactWithNewOwnerById) {
        if (contactWithNewOwnerById.isEmpty()) {
            return;
        }

        Map<Id, Account> allAccounts = new Map<Id, Account>();
        Map<Id, Account> accountsToUpdate = new Map<Id, Account>();

        for (Contact con : contactWithNewOwnerById.values()) {
            allAccounts.put(con.AccountId, null);
        }

        allAccounts = new Map<Id, Account>(
            [SELECT Id, npe01__SYSTEM_AccountType__c, npe01__One2OneContact__c, OwnerId,
                (SELECT Id FROM Contacts limit 2)
                FROM Account WHERE Id IN :allAccounts.keySet()]
        );

        for (Account acc : allAccounts.values()) {
            // only consider 1:1 and HH Accounts
            if (acc.npe01__SYSTEM_AccountType__c == CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE || acc.npe01__SYSTEM_AccountType__c == CAO_Constants.HH_ACCOUNT_TYPE) {
                // if there is only 1 contact associated with this account
                if (acc.Contacts.size() == 1 && acc.npe01__One2OneContact__c != null) {
                    Contact c = contactWithNewOwnerById.get(acc.npe01__One2OneContact__c);
                    Id ownerIdContact = (c != null ? c.OwnerId : null);
                    if (acc.OwnerId != ownerIdContact) {
                        acc.OwnerId = ownerIdContact;
                        accountsToUpdate.put(acc.id, acc);
                    }
                }
            }
        }

        //update existing dmlWrapper objects with accounts already in the list
        //avoids "duplicate id in list" errors updating the same account twice
        for (sObject dmlObj : dmlWrapper.objectsToUpdate) {
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
     * @description - Determine whether the account belongs to another contact and is not an deleted during an account merge.
     */
    private Boolean shouldClearExistingOneToOneAccount(Contact contactRecord, Contact oldContact, Account accountRecord) {
        Boolean isExistingOneToOne = contactRecord.AccountId != null
            && accountRecord.npe01__One2OneContact__c != contactRecord.Id
            && accountRecord.npe01__One2OneContact__c != null
            && contactRecord.AccountId != oldContact.AccountId;

        if (!isExistingOneToOne) {
            return false;
        }

        Boolean isDeletedOldAccount = [SELECT count() FROM Account WHERE Id =: oldContact.AccountId] == 0;

        return !isDeletedOldAccount;

    }
    /**
     * @description Determines whether or not the contact requires a household account.
     * @param  contactRecord The contact to verify.
     * @return Boolean - true when the contact needs a household account.
     */
    private Boolean needsHHAccount(Contact contactRecord) {
        return CAO_Constants.isHHAccountModel()
            && contactRecord.AccountId == null
            && contactRecord.npe01__Private__c != true;
    }

    /*******************************************************************************************************
    * @description returns whether changes in the contact require an update to the 1:1 account
    * @param conNew the new version of the Contact
    * @param conOld the old version of the Contact
    * @return Boolean
    */
    private Boolean needsOne2OneAccountUpdate(Contact conNew, Contact conOld) {
        if (conNew.npe01__Organization_Type__c != CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE) {
            return false;
        }

        if(conNew != null && conOld == null) {
            return true;
        }
        
        String newFirst = conNew.FirstName == null ? '' : conNew.FirstName;
        String oldFirst = conOld.FirstName == null ? '' : conOld.FirstName;
        String newLast = conNew.LastName == null ? '' : conNew.LastName;
        String oldLast = conOld.LastName == null ? '' : conOld.LastName;

        return (conNew.AccountId != conOld.AccountId ||
                !newFirst.equals(oldFirst) ||
                !newLast.equals(oldLast) ||
                conNew.MailingStreet != conOld.MailingStreet ||
                conNew.MailingCity != conOld.MailingCity ||
                conNew.MailingState != conOld.MailingState ||
                conNew.MailingPostalCode != conOld.MailingPostalCode ||
                conNew.MailingCountry != conOld.MailingCountry ||
                conNew.OtherStreet != conOld.OtherStreet ||
                conNew.OtherCity != conOld.OtherCity ||
                conNew.OtherState != conOld.OtherState ||
                conNew.OtherPostalCode != conOld.OtherPostalCode ||
                conNew.OtherCountry != conOld.OtherCountry ||
                conNew.Phone != conOld.Phone ||
                conNew.Fax != conOld.Fax);
    }

    /*******************************************************************************************************
    * @description returns whether changes in the contact require a rename of a HH Account
    * @param hhNamingFields the set of fields used in the namespec
    * @param conNew the new version of the Contact
    * @param conOld the old version of the Contact
    * @return Boolean
    */
    private Boolean needsHHAccountRename(Contact conNew, Contact conOld) {
        if (conNew.npe01__Organization_Type__c != CAO_Constants.HH_ACCOUNT_TYPE) {
            return false;
        }
        if (conNew != null && conOld == null) {
            return true;
        }
        if (conNew.FirstName == null) conNew.FirstName = '';
        if (conNew.LastName == null) conNew.LastName = '';

        // check all household naming fields for changes
        for(String fieldName : HH_NAMING_FIELDS) {
            String strName;
            String strNameOld;

            //separate cross object references, i.e. account.name
            List<String> splitField = (fieldName.split('\\.',0));
            if (splitField.size() > 1) {
                SObject sobj = conNew.getSobject(splitField[0]);
                if (sobj != null) {
                    strName = sobj.Id;
                }
                sobj = conOld.getSobject(splitField[0]);
                if (sobj != null) {
                    strNameOld = sobj.Id;
                }
            } else {
                strName = String.valueOf(conNew.get(fieldName));
                strNameOld = String.valueOf(conOld.get(fieldName));
            }

            // make sure to use case sensitive comparison
            if (strName == null) {
                strName = '';
            }
            if (strNameOld == null) {
                strNameOld = '';
            }
            if (!strName.equals(strNameOld)) {
                return true;
            }
        }
        if (conNew.npo02__Household_Naming_Order__c != conOld.npo02__Household_Naming_Order__c ||
            conNew.npo02__Naming_Exclusions__c != conOld.npo02__Naming_Exclusions__c) {
            return true;
        }
        return false;
    }

    /**
     * isHouseholdMember Determines whether or not the contact belongs to a household account.
     * @param  contactRecord The contact record to verify.
     * @return Boolean - true when the contact belongs to a household account.
     */
    private Boolean isHouseholdMember(Contact contactRecord) {
        return contactRecord.Account.npe01__SYSTEM_AccountType__c == CAO_Constants.HH_ACCOUNT_TYPE;
    }

    /**
     * @description Determines whether or not the contact needs a one to one account assigned.
     * @param  The contact record to verify.
     * @param  The existing account record assocatied with the contact.
     * @return Boolean - true when the contact needs a one to one account.
     */
    private Boolean needsOneToOneAccount(Contact contactRecord, Account accountRecord) {
        return CAO_Constants.isOneToOne()
            && contactRecord.npe01__Private__c != true
            && (contactRecord.AccountId == null
                || (accountRecord != null
                    && accountRecord.npe01__SYSTEM_AccountType__c == CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE));
    }

    /**
     * @description Determines whether or not the contact should be assigned to the bucket account
     * @param  contactRecord The contact record to verify.
     * @return Boolean - true when the contact should be assigned to the bucket account
     */
    private Boolean needsBucketAccount(Contact contactRecord) {
        return CAO_Constants.isBucketModel() && contactRecord.AccountId == null && contactRecord.npe01__Private__c != true;
    }

    /**
     * needsPrimaryContact Determines whether or not the account is in need of a primary contact.
     * @param  contactRecord The contact record to traverse to the account data.
     * @return Boolean - true when the account needs the primary contact set.
     */
    private Boolean needsPrimaryContact(Contact contactRecord) {
        return contactRecord.npe01__Private__c != true
            && contactRecord.Account.npe01__SYSTEM_AccountType__c != CAO_Constants.BUCKET_ORGANIZATION_TYPE
            && contactRecord.Account.npe01__SYSTEMIsIndividual__c
            && contactRecord.Account.npe01__One2OneContact__c == null;
    }

    /*******************************************************************************************************
    * @description returns the default name for a new HH Account. Custom household naming will update this
    * account later if enabled, but we still need one if not enabled.
    * @param con the Contact
    * @return String. the Household account name
    */
    public static String strNameHHAccountForContact(Contact con) {
        return con.LastName + ' ' + System.Label.npo02.DefaultHouseholdName;
    }

    /*******************************************************************************************************
    * @description returns the default name for a new 1:1 Account
    * @param con the Contact
    * @return String. the 1:1 account name
    */
    public static String strNameOne2OneAccountForContact(Contact con) {
        String str = '';

        if (con.FirstName != null) {
            str += con.FirstName;
            str += ' ' ;
        }
        if (EASTERN_ORDER_LANGUAGES.contains(userLocale)) {
            str = con.LastName + ' ' + str;

        } else {
            str += con.LastName;
        }

        return str;
    }

    /*******************************************************************************************************
    * @description Moves all opps for the Primary OCR provided contacts to their new account.  Note that it
    * is the caller's responsibility to decide whether moving opps is appropriate for the involved accounts.
    * @param mapContactIdAccountIdNew a map of Contact Id to Account Id, for the Accounts to move opps to
    * @param mapContactIdAccountIdOld a map of Contact Id to Account Id, for the Accounts to move opps from
    * @return void
    */
    public static void moveOppsToContactAccount(Map<Id,Id> mapContactIdAccountIdNew, Map<Id,Id> mapContactIdAccountIdOld) {
        if (mapContactIdAccountIdNew.isEmpty()) {
            return;
        }

        Set<Id> setConId = mapContactIdAccountIdNew.keySet();
        List<Id> listAccIdOld = mapContactIdAccountIdOld.values();
        List<Opportunity> listOpp = new List<Opportunity>();
        Set<Id> setOppId = new Set<Id>();

        // query changed to also include Role = default role, because Contact Merge scenarios were clearing isPrimary (not by our code)!
        npe01__Contacts_and_Orgs_Settings__c cs = UTIL_CustomSettingsFacade.getContactsSettings();

        List<OpportunityContactRole> listOCR = [SELECT ContactId, OpportunityId, Opportunity.isClosed, Opportunity.AccountId, IsPrimary, Role
            FROM OpportunityContactRole WHERE IsPrimary = true AND Opportunity.AccountId IN :listAccIdOld AND ContactId IN :setConId];

        for (OpportunityContactRole ocr : listOCR) {
            if (mapContactIdAccountIdOld.get(ocr.ContactId) == ocr.Opportunity.AccountId) {
                if (setOppId.add(ocr.OpportunityId)) {
                    listOpp.add(new Opportunity(Id = ocr.OpportunityId, AccountId = mapContactIdAccountIdNew.get(ocr.ContactId)));
                }
            }
        }

        if (listOpp.size() > 0) {
            UTIL_DMLService.updateRecords(listOpp);
        }
    }

    /*******************************************************************************************************
    * @description for the list of HH AccountId's, update their Household Names
    * @param accountIds the list of Account (Id's) that need updating.
    * @return void
    */
    public static void renameHHAccounts(List<Id> accountIds) {
        if (accountIds.isEmpty()) {
            return;
        }

        if (accountIds.size() == 1 || system.isFuture() || system.isBatch()) {
            HH_HouseholdNaming hhName = new HH_HouseholdNaming();
            hhName.UpdateNames(accountIds);
        } else {
            HH_HouseholdNaming.FutureUpdateNames(accountIds);
        }
    }

    /*******************************************************************************************************
    * @description utility to return the recordtypeId for a new account, given the account model.
    * @return Id. if none is explicitly specified, returns null.
    */
    public static Id rtIdForNewAccount() {
        return rtIdForAccountModel(CAO_Constants.isHHAccountModel());
    }

    /*******************************************************************************************************
    * @description utility to return the recordtypeId for a new account, given the account model.
    * @param isHHAccountModel whether we are using the Household Account Model
    * @return Id. recordtype Id to use, or null if none is specified for the account model.
    */
    public static Id rtIdForAccountModel(Boolean isHHAccountModel) {
        contactsSettings = UTIL_CustomSettingsFacade.getContactsSettings();
        Schema.Recordtypeinfo rtById = null;
        // check if recordtypes are enabled, and if it matches the existing setting
        // we go thru describe to validate that it is a valid recordType ID.
        Id rtId = isHHAccountModel ? contactsSettings.npe01__HH_Account_RecordTypeID__c : contactsSettings.npe01__One_to_One_RecordTypeID__c;
        if (rtId != null) {
            Schema.DescribeSObjectResult R = Account.SObjectType.getDescribe();
            Map<Id,Schema.RecordTypeInfo> rtMapById = r.getRecordTypeInfosById();
            rtById = rtMapById.get(rtId);
            return (rtById == null ? null : rtById.getRecordTypeID());
        }
        return null;
    }

    /*******************************************************************************************************
    * @description for the list of AccountId's, recalc their rollups 
    * @param accountIds the list of Account (Id's) that need updating.
    * @return void
    */ 
    public static void rollupAccounts(List<Id> accountIds) {
        Boolean isImmediate = accountIds.size() == 1 || System.isFuture() || System.isBatch() || System.isQueueable();

        if (isImmediate) {
            RLLP_OppRollup_UTIL oppRollupUtil = new RLLP_OppRollup_UTIL();
            String query = new RLLP_OppRollup_UTIL().buildAccountQuery() + ' WHERE Id IN :accountIds';
            Map<Id, Account> accountsById = new Map<Id, Account>((List<Account>)Database.query(query));
            RLLP_OppRollup oppRollup = new RLLP_OppRollup();

            oppRollup.rollupAccounts(accountsById);

        } else {
            RLLP_OppRollup.rollupAccountsFuture(new set<Id>(accountIds));
        }
    }

}