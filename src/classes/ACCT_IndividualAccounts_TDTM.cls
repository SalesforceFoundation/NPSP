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
        this.oldContactById = oldSObjects == null ? null : new Map<Id, Contact>((List<Contact>) oldSObjects);
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
        contacts = Database.query(buildContactSoql());

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

        attachToBucketAccount(
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
        List<Id> householdIdsToUpdate = new List<Id>();
        List<Id> householdIdsToRename = new List<Id>();
        List<Contact> oneToOneContactsToUpdate = new List<Contact>();
        Map<Id, Id> oldHouseholdIdByContactId = new Map<Id, Id>();
        Map<Id, Id> newHouseholdIdByContactId = new Map<Id, Id>();

        for (Contact contactRecord : contacts) {
            Contact oldContact = oldContactById.get(contactRecord.Id);

            if (needsOne2OneAccountUpdate(contactRecord, oldContact)) {
                oneToOneContactsToUpdate.add(contactRecord);
            }

            if (contactRecord.AccountId != oldContact.AccountId) {
                addHouseholdIds(householdIdsToUpdate, newHouseholdIdByContactId, contactRecord);
                addHouseholdIds(householdIdsToUpdate, oldHouseholdIdByContactId, oldContact);

            } else if (needsHHAccountRename(contactRecord, oldContact)) {
                householdIdsToRename.add(contactRecord.AccountId);
            }
        }

        Map<Id, Contact> newOwnerContactById = new Map<Id, Contact>();
        for (Contact contactRecord : contacts) {
            Contact oldContact = oldContactById.get(contactRecord.Id);
            if (contactRecord.OwnerId != oldContact.OwnerId) {
                newOwnerContactById.put(contactRecord.Id, contactRecord);
            }
        }

        Households.updateOneToOneAccounts(oneToOneContactsToUpdate, dmlWrapper);
        moveOppsToContactAccount(newHouseholdIdByContactId, oldHouseholdIdByContactId);
        HouseholdAccounts.updateHouseholds(householdIdsToUpdate, dmlWrapper);
        householdNamingService.renameHouseholdAccounts(householdIdsToRename);
        updateOwners(newOwnerContactById);
    }

    /*******************************************************************************************************
     * @description Builds SOQL on Contact SObject. Fields include Household Naming Settings Format fields.
     * @return String SOQL
     */
    @TestVisible
    private String buildContactSoql() {
        List<String> selectFields = getContactSelectionFields();

        selectFields.addAll(fieldsUsedForHouseholdNaming());

        return new UTIL_Query()
            .withSelectFields(selectFields)
            .withFrom(String.valueOf(Contact.SObjectType))
            .withWhere('Id IN :contacts')
            .build();
    }

    private List<String> getContactSelectionFields() {
        List<String> selectFields = new List<String>{
                'Id', 'npe01__Private__c', 'AccountId', 'Account.npe01__SYSTEMIsIndividual__c',
                'Account.npe01__SYSTEM_AccountType__c', 'Account.npe01__One2OneContact__c',
                'npe01__Organization_Type__c', 'Account.Name',
                'FirstName', 'LastName', 'OwnerId', 'Salutation', 'npo02__Naming_Exclusions__c',
                'npo02__Household_Naming_Order__c',
                'MailingStreet', 'MailingCity', 'MailingState', 'MailingPostalCode',
                'MailingCountry', 'MailingLatitude', 'MailingLongitude',
                'OtherStreet', 'OtherCity', 'OtherState', 'OtherPostalCode',
                'OtherCountry', 'OtherLatitude', 'OtherLongitude',
                'Phone', 'Fax'
        };

        if (orgConfig.isStateCountryPicklistsEnabled()) {
            selectFields.add('MailingCountryCode');
            selectFields.add('MailingStateCode');
            selectFields.add('OtherCountryCode');
            selectFields.add('OtherStateCode');
        }
        return selectFields;
    }

    private Set<String> fieldsUsedForHouseholdNaming() {
       return householdNamingService.getHouseholdNamingContactFields();
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

    private Boolean isBucketModelEnabled() {
        return CAO_Constants.isBucketModel();
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

}