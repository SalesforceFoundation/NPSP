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

    private static Boolean isNewContactInsert = false;
    public static Boolean isNewHouseholdAccountInsert = false;

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
    private Map<Id, Contact> oldContactById;
    private TDTM_Runnable.Action triggerAction;
    private DmlWrapper dmlWrapper;

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

        // Reset this flag to false for each call to run(), since some NPSP tests
        // insert Contacts in multiple DML statements.  This flag functions then as
        // protection against recursion for each call to the method.
        isNewHouseholdAccountInsert = false;

        this.contacts = newSObjects;
        this.oldContactById = oldSObjects == null ? null : new Map<Id, Contact>((List<Contact>) oldSObjects);
        this.triggerAction = triggerAction;
        this.dmlWrapper = new DmlWrapper();
        contactsSettings = UTIL_CustomSettingsFacade.getContactsSettings();

        if (triggerAction == TDTM_Runnable.Action.BeforeInsert
                || triggerAction == TDTM_Runnable.Action.AfterInsert) {
            isNewContactInsert = true;
        }

        if (triggerAction == TDTM_Runnable.Action.BeforeInsert || triggerAction == TDTM_Runnable.Action.BeforeUpdate) {
            handleBefore();

        } else if (triggerAction == TDTM_Runnable.Action.AfterInsert || triggerAction == TDTM_Runnable.Action.AfterUpdate || triggerAction == TDTM_Runnable.Action.AfterUndelete) {
            handleAfter();

        } else if (triggerAction == TDTM_Runnable.Action.AfterDelete) {
            isNewHouseholdAccountInsert = false;
            processAccountsAfterDelete(oldSObjects);
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

        accountById = new Map<Id, Account>([
            SELECT Id, npe01__One2OneContact__c, npe01__SYSTEM_AccountType__c
            FROM Account
            WHERE Id IN :accountIds
        ]);

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
        contacts = Database.query(buildContactSoql());

        if (triggerAction == TDTM_Runnable.Action.AfterInsert || triggerAction == TDTM_Runnable.Action.AfterUndelete) {
            processHouseholdAccountsAfterContactInsert();
        }

        if (triggerAction == TDTM_Runnable.Action.AfterUpdate) {
            isNewHouseholdAccountInsert = false;
            processHouseholdAccountsAfterContactUpdate();
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
            } else if (needsOneToOneAccount(contactRecord, accountById.get(contactRecord.AccountId))) {
                // Avoid creating a new contact with the 1:1 account of another contact
                if (contactRecord.AccountId != null) {
                    contactRecord.AccountId = null;
                }

                contactsWithoutAccounts.add(contactRecord);
            } else if (needsBucketAccount(contactRecord)) {
                contactsWithoutBucketAccount.add(contactRecord);
            }
        }

        createAccounts(contactsWithoutAccounts);
        attachToBucketAccount(contactsWithoutBucketAccount);
    }

    /**
     * @description In the before update trigger context, ensure accounts are created for the contacts that need them.
     * @param  accountById - the existing accounts that the contacts are related to.
     */
    private void processAccountsBeforeUpdate(Map<Id, Account> accountById) {
        List<Contact> contactsWithoutAccounts = new List<Contact>();
        List<Contact> contactsWithoutBucketAccount = new List<Contact>();

        for (Contact contactRecord : contacts) {
            // always clear this deprecated field to avoid confusing users.
            contactRecord.npe01__SystemAccountProcessor__c = null;

            if (needsHHAccount(contactRecord)) {
                contactsWithoutAccounts.add(contactRecord);

            } else if (needsOneToOneAccount(contactRecord, accountById.get(contactRecord.AccountId))) {
                Contact oldContact = oldContactById.get(contactRecord.Id);

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
        }

        createAccounts(contactsWithoutAccounts);
        attachToBucketAccount(contactsWithoutBucketAccount);
    }

    /**
     * @description Sets the primary contact on the account when needed and renames the household.
     */
    private void processHouseholdAccountsAfterContactInsert() {
        Map<Id, Id> primaryContactByAccountId = new Map<Id, Id>();
        List<Id> householdIdsToRename = new List<Id>();

        for (Contact contactRecord : contacts) {
            if (contactRecord.AccountId == null) {
                continue;
            }

            if (needsPrimaryContact(contactRecord)) {
                primaryContactByAccountId.put(contactRecord.AccountId, contactRecord.Id);
            }

            if ((!isNewContactInsertOperation()
                    || isNewContactInsertOperation()
                    && isBeingAddedToAHousehold(contactRecord))
                    && isHouseholdMember(contactRecord)) {
                householdIdsToRename.add(contactRecord.AccountId);

            }
        }

        updatePrimaryContactOnAccount(primaryContactByAccountId);
        if (!householdIdsToRename.isEmpty()) {
            householdNamingService.renameHouseholdAccounts(householdIdsToRename);
        }
    }

    private Boolean isBeingAddedToAHousehold(Contact contactRecord) {
        return contactRecord.AccountId != null;
    }

    /**
     * @description Tells whether a new Contact is being inserted - either by this class or by
     * the NPSP Trigger Handler that inserts Household objects.
     */
    private Boolean isNewContactInsertOperation() {
        return isNewContactInsert || HH_Households_TDTM.isNewContactInsert;
    }

    /**
     * @description Depending on the contacts household type, this method will update the one to one account,
     * move opportunities related to contacts changing accounts, update household accounts, rename household accounts
     * update account owners based on the change in contact owner
     */
    private void processHouseholdAccountsAfterContactUpdate() {
        List<Id> householdIdsToUpdate = new List<Id>();
        List<Id> householdIdsToRename = new List<Id>();
        List<Contact> oneToOneContactsToUpdate = new List<Contact>();
        Map<Id, Id> oldHouseholdIdByContactId = new Map<Id, Id>();
        Map<Id, Id> newHouseholdIdByContactId = new Map<Id, Id>();
        Map<Id, Contact> newOwnerContactById = new Map<Id, Contact>();

        for (Contact contactRecord : contacts) {
            Contact oldContact = oldContactById.get(contactRecord.Id);

            if (needsOne2OneAccountUpdate(contactRecord, oldContact)) {
                oneToOneContactsToUpdate.add(contactRecord);
            }

            if (contactRecord.OwnerId != oldContact.OwnerId) {
                newOwnerContactById.put(contactRecord.Id, contactRecord);
            }

            if (contactRecord.AccountId != oldContact.AccountId) {
                addHouseholdIds(householdIdsToUpdate, newHouseholdIdByContactId, contactRecord);
                addHouseholdIds(householdIdsToUpdate, oldHouseholdIdByContactId, oldContact);

            } else if (needsHHAccountRename(contactRecord, oldContact)) {
                householdIdsToRename.add(contactRecord.AccountId);
            }
        }

        updateOneToOneAccounts(oneToOneContactsToUpdate);
        moveOppsToContactAccount(newHouseholdIdByContactId, oldHouseholdIdByContactId);
        updateHouseholds(householdIdsToUpdate);
        householdNamingService.renameHouseholdAccounts(householdIdsToRename);
        updateOwners(newOwnerContactById);
    }

    /*******************************************************************************************************
    * @description Updates the accounts for contacts that have been deleted if they have other hh members
    * @param deletedContacts the list of Contacts that need to be considered
    */
    private void processAccountsAfterDelete(List<Contact> deletedContacts) {
        List<Id> accountIds = new List<Id>();
        List<Id> householdIdsToUpdate = new List<Id>();

        for (Contact contactRecord : deletedContacts) {
            accountIds.add(contactRecord.AccountId);
        }

        for (Account accountRecord : [
            SELECT Id, Type, npe01__SYSTEM_AccountType__c,
                (SELECT Id FROM Contacts LIMIT 1),
                (SELECT Id FROM Opportunities LIMIT 1)
            FROM Account
            WHERE Id IN :accountIds
        ]) {
            Boolean needsAccountUpdate = (!accountRecord.Contacts.isEmpty() || !accountRecord.Opportunities.isEmpty())
                && accountRecord.npe01__SYSTEM_AccountType__c == CAO_Constants.HH_ACCOUNT_TYPE;

            if (needsAccountUpdate) {
                householdIdsToUpdate.add(accountRecord.Id);
            }
        }

        updateHouseholds(householdIdsToUpdate);
    }

    /*******************************************************************************************************
    * @description Updates Accounts with the primary Individual Contact Id. Used for 1:1 and HH Accounts.
    * @param primaryContactByAccountId a map of AccountId's to ContactId's which specifies which accounts need updating.
    */
    private void updatePrimaryContactOnAccount(Map<Id, Id> primaryContactByAccountId) {
        if (primaryContactByAccountId.isEmpty()) {
            return;
        }

        List<Account> accounts = new List<Account>();
        for (Id accountId : primaryContactByAccountId.keySet()) {
            Account accountRecord = new Account(Id = accountId, npe01__One2OneContact__c = primaryContactByAccountId.get(accountId));
            accounts.add(accountRecord);
        }

        dmlWrapper.objectsToUpdate.addAll(accounts);
    }

    /*******************************************************************************************************
    * @description Updates an HH Account's naming, primary contact, and rollups
    * @param accountIds the list of Account (Id's) that need updating.
    */
    private void updateHouseholds(List<Id> accountIds) {
        if (accountIds.isEmpty()) {
            return;
        }

        resetPrimaryContactForAccount(accountIds);
        householdNamingService.renameHouseholdAccounts(accountIds);
        rollupAccounts(accountIds);
    }

    /*******************************************************************************************************
    * @description sets the Primary Account for each Account in the list of Accounts
    * @param accountIds the list of Account (Id's) that need updating.
    */
    private void resetPrimaryContactForAccount(List<Id> accountIds) {

        // for each account, we need a set of their contacts.
        Map<Id, Set<Id>> contactIdsByAccountId = new Map<Id, Set<Id>>();

        for (Contact contactRecord : [
            SELECT Id, AccountId, Account.npe01__One2OneContact__c
            FROM Contact
            WHERE AccountId IN :accountIds
        ]) {
            Set<Id> contactIds = contactIdsByAccountId.get(contactRecord.AccountId);
            if (contactIds == null) {
                contactIds = new Set<Id>();
                contactIdsByAccountId.put(contactRecord.AccountId, contactIds);
            }
            contactIds.add(contactRecord.Id);
        }

        // now go thru each account and update their primary contact if the current one isn't valid
        List<Account> accounts = new List<Account>();
        for (Account accountRecord : [SELECT Id, npe01__One2OneContact__c FROM Account WHERE Id IN :accountIds]) {
            Set<Id> contactIds = contactIdsByAccountId.get(accountRecord.Id);
            if (contactIds != null && !contactIds.contains(accountRecord.npe01__One2OneContact__c)) {
                accountRecord.npe01__One2OneContact__c = extractFirstId(contactIds);
                accounts.add(accountRecord);
            }
        }

        dmlWrapper.objectsToUpdate.addAll(accounts);
    }

    /*******************************************************************************************************
     * @description Builds SOQL on Contact SObject. Fields include Household Naming Settings Format fields.
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

        if (orgConfig.isStateCountryPicklistsEnabled()) {
            selectFields.add('MailingCountryCode');
            selectFields.add('MailingStateCode');
            selectFields.add('OtherCountryCode');
            selectFields.add('OtherStateCode');
        }

        selectFields.addAll(fieldsUsedForHouseholdNaming());

        return new UTIL_Query()
            .withSelectFields(selectFields)
            .withFrom(String.valueOf(Contact.SObjectType))
            .withWhere('Id IN :contacts')
            .build();
    }

    private Set<String> fieldsUsedForHouseholdNaming() {
       return householdNamingService.getHouseholdNamingContactFields();
    }

    /*******************************************************************************************************
    * @description returns the first Id from the specified set
    * @param ids a set of Id's
    * @return Id.  null if the set is empty.
    */
    private Id extractFirstId(Set<Id> ids) {
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

    /*******************************************************************************************************
    * @description Inserts a new 1:1 or HH Account for an Individual Contact
    * @param contactsWithoutAccounts the list of Contacts that need updating.
    */
    private void createAccounts(List<Contact> contactsWithoutAccounts){
        if (contactsWithoutAccounts.isEmpty()) {
            return;
        }

        List<Id> contactIds = new List<Id>();
        Map<Id, Account> accountByPrimaryContactId = new Map<Id, Account>();
        List<Contact> contacts = new List<Contact>();

        for (Contact contactRecord : contactsWithoutAccounts) {
            //track which contacts are being inserted vs. updated
            if (contactRecord.Id != null) {
                contactIds.add(contactRecord.Id);
            }
        }
        // get all the Accounts that are connected to the existing Contacts
        for (Account accountRecord : [
            SELECT Id, npe01__One2OneContact__c, npe01__SYSTEM_AccountType__c
            FROM Account
            WHERE npe01__One2OneContact__c IN :contactIds
        ]) {
            accountByPrimaryContactId.put(accountRecord.npe01__One2OneContact__c, accountRecord);
        }

        List<Account> accountInserts = new List<Account>();

        for (Contact contactRecord : contactsWithoutAccounts) {
            // if we found an Account already connected to this Contact, connect the Contact to that Account if it
            // is the correct type for the current account processor
            Account accountRecord = accountByPrimaryContactId.get(contactRecord.Id);
            if (accountRecord != null &&
                ((CAO_Constants.isHHAccountModel() && accountRecord.npe01__SYSTEM_AccountType__c == CAO_Constants.HH_ACCOUNT_TYPE) ||
                (CAO_Constants.isOneToOne() && accountRecord.npe01__SYSTEM_AccountType__c == CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE)) ) {
                // if a user has blanked out the Account for a Contact, this will put it right back
                contactRecord.AccountId = accountRecord.Id;
            } else {
                // construct the individual account for the Contact
                NPSP_HouseholdAccount npspHouseholdAccount =
                        new NPSP_HouseholdAccount(contactRecord);
                accountInserts.add(npspHouseholdAccount.getRecord());
                contacts.add(contactRecord);
            }
        }

        if (accountInserts.isEmpty()) {
            return;
        }

        // with current TDTM design, we can't use dmlWrapper
        // because we need to get the new AccountID's into the Contacts.

        // identify the specific records that had the problem, and don't fail the whole batch
        if (!accountInserts.isEmpty()) {
            isNewHouseholdAccountInsert = true;
            List<Database.SaveResult> insertResults = UTIL_DMLService.insertRecords(accountInserts, false);
            for (Integer index = 0; index < insertResults.size(); index++) {
                Database.SaveResult insertResult = insertResults[index];
                if (!insertResult.isSuccess()) {
                    for (Database.Error err : insertResult.getErrors()) {
                        accountInserts[index].addError(err.getMessage());
                        Contact contactRecord = contacts[index];
                        contactRecord.addError(String.format(System.Label.conFailedAccountCreate, new String[]{
                                contactRecord.FirstName, contactRecord.LastName, err.getMessage()
                        }));
                    }
                }
            }
        }

        // now update each contact's accountId
        Integer index = 0;
        for (Contact contactRecord : contacts) {
            contactRecord.AccountId = accountInserts[index].Id;
            index++;
        }
    }

    /*******************************************************************************************************
    * @description Updates an Individual Account for an Individual Contact
    * @param oneToOneContactsToUpdate the list of Contacts that need updating.
    */
    private void updateOneToOneAccounts(List<Contact> oneToOneContactsToUpdate){
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
                accountRecord.Name = strNameOne2OneAccountForContact(contactRecord);
            }

            // HH Account naming updates handled seperately to deal with asyncronous naming
            accounts.add(accountRecord);
        }

        if (accounts.isEmpty()) {
            return;
        }

        dmlWrapper.objectsToUpdate.addAll(accounts);
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

        Boolean isDeletedOldAccount = [SELECT COUNT() FROM Account WHERE Id =: oldContact.AccountId] == 0;

        return !isDeletedOldAccount;

    }
    /**
     * @description Determines whether or not the contact requires a household account.
     * @param  contactRecord The contact to verify.
     */
    private Boolean needsHHAccount(Contact contactRecord) {
        return CAO_Constants.isHHAccountModel()
            && contactRecord.AccountId == null
            && contactRecord.npe01__Private__c != true;
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

    /*******************************************************************************************************
    * @description returns whether changes in the contact require a rename of a HH Account
    * @param contactRecord the new version of the Contact
    * @param oldContact the old version of the Contact
    * @return Boolean
    */
    private Boolean needsHHAccountRename(Contact contactRecord, Contact oldContact) {
        if (contactRecord.npe01__Organization_Type__c != CAO_Constants.HH_ACCOUNT_TYPE) {
            return false;
        }

        if (contactRecord != null && oldContact == null) {
            return true;
        }

        contactRecord.FirstName = contactRecord.FirstName == null ? '' : contactRecord.FirstName;
        contactRecord.LastName = contactRecord.LastName == null ? '' : contactRecord.LastName;

        // check all household naming fields for changes
        for(String fieldName : fieldsUsedForHouseholdNaming()) {
            String currentName;
            String oldName;

            //separate cross object references, i.e. account.name
            List<String> splitFields = (fieldName.split('\\.',0));
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
    * @param contactRecord the Contact
    * @return String. the Household account name
    */
    public static String strNameHHAccountForContact(Contact contactRecord) {
        return contactRecord.LastName + ' ' + System.Label.npo02.DefaultHouseholdName;
    }

    /*******************************************************************************************************
    * @description returns the default name for a new 1:1 Account
    * @param contactRecord the Contact
    * @return String. the 1:1 account name
    */
    public static String strNameOne2OneAccountForContact(Contact contactRecord) {
        String accountName = '';

        if (contactRecord.FirstName != null) {
            accountName += contactRecord.FirstName;
            accountName += ' ' ;
        }

        if (EASTERN_ORDER_LANGUAGES.contains(userLocale)) {
            accountName = contactRecord.LastName + ' ' + accountName;

        } else {
            accountName += contactRecord.LastName;
        }

        return accountName;
    }

    /*******************************************************************************************************
    * @description Moves all opps for the Primary OCR provided contacts to their new account.  Note that it
    * is the caller's responsibility to decide whether moving opps is appropriate for the involved accounts.
    * @param newHouseholdIdByContactId a map of Contact Id to Account Id, for the Accounts to move opps to
    * @param oldHouseholdIdByContactId a map of Contact Id to Account Id, for the Accounts to move opps from
    */
    public static void moveOppsToContactAccount(Map<Id,Id> newHouseholdIdByContactId, Map<Id,Id> oldHouseholdIdByContactId) {
        if (newHouseholdIdByContactId.isEmpty()) {
            return;
        }

        List<Opportunity> opportunities = new List<Opportunity>();
        Set<Id> oppIds = new Set<Id>();

        for (OpportunityContactRole role : [
            SELECT ContactId, OpportunityId, Opportunity.AccountId
            FROM OpportunityContactRole
            WHERE IsPrimary = TRUE
                AND Opportunity.AccountId IN :oldHouseholdIdByContactId.values()
                AND ContactId IN :newHouseholdIdByContactId.keySet()
        ]) {
            Boolean shouldMoveOpp = oldHouseholdIdByContactId.get(role.ContactId) == role.Opportunity.AccountId
                && oppIds.add(role.OpportunityId);

            if (shouldMoveOpp) {
                opportunities.add(new Opportunity(
                    Id = role.OpportunityId,
                    AccountId = newHouseholdIdByContactId.get(role.ContactId)));
            }
        }

        if (!opportunities.isEmpty()) {
            UTIL_DMLService.updateRecords(opportunities);
        }

    }

    /*******************************************************************************************************
    * @description for the list of AccountId's, recalc their rollups
    * @param accountIds the list of Account (Id's) that need updating.
    */
    public static void rollupAccounts(List<Id> accountIds) {
        new RLLP_OppRollup().rollupAccounts(new Set<Id>(accountIds));
    }

}