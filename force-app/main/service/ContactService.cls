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
* @description Contact Service class in NPSP.
*/
public with sharing class ContactService {

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
    private AddressService addressService {
        get {
            if (addressService == null) {
                addressService = new AddressService();
            }
            return addressService;
        }
        set;
    }

    /*******************************************************************************************************
    * @description compares two contacts' addresses
    * @param con1 a Contact
    * @param con2 a Contact
    * @return boolean. true if the Mailing Address fields have changed
    ********************************************************************************************************/
    public Boolean isContactAddressChanged(Contact con1, Contact con2) {
        // if both null, no change
        if (con1 == null && con2 == null) {
            return false;
        }

        // if one null, make sure other has at least one address field set
        if (con1 == null || con2 == null) {
            if (con1 == null) {
                con1 = con2;
            }
            return (!isContactAddressEmpty(con1) ||
                    con1.npe01__Primary_Address_Type__c != null);
        }

        // both provided, so look for at least one change between address fields
        Boolean isChanged =
                !addressService.equalsCaseSensitive(con1.MailingStreet, con2.MailingStreet) ||
                        !addressService.equalsCaseSensitive(con1.MailingCity, con2
                                .MailingCity) ||
                        !addressService.equalsCaseSensitive(con1.MailingState, con2
                                .MailingState) ||
                        !addressService.equalsCaseSensitive(con1.MailingPostalCode, con2
                                .MailingPostalCode) ||
                        !addressService.equalsCaseSensitive(con1.MailingCountry, con2
                                .MailingCountry) ||
                        !addressService.equalsCaseSensitive(con1
                                .npe01__Primary_Address_Type__c,
                                con2
                                .npe01__Primary_Address_Type__c);

        if (!isChanged && orgConfig.isStateCountryPicklistsEnabled()) {
            isChanged =
                    !addressService.equalsCaseSensitive(String.valueOf(con1.get
                            ('MailingStateCode')),
                            String.valueOf(con2.get('MailingStateCode'))) ||
                            !addressService.equalsCaseSensitive(String.valueOf(con1.get
                                    ('MailingCountryCode')), String.valueOf(con2.get('MailingCountryCode')));
        }
        return isChanged;
    }

    /*******************************************************************************************************
    * @description returns whether the contact's mailing address is empty
    * @param con1 a Contact
    * @return boolean. true if the Mailing Address fields are all empty
    ********************************************************************************************************/
    public Boolean isContactAddressEmpty(Contact con1) {
        Boolean isEmpty =
                con1.MailingStreet == null &&
                        con1.MailingCity == null &&
                        con1.MailingState == null &&
                        con1.MailingPostalCode == null &&
                        // note that we decided to ignore country so that a default value won't create unnecessary address objects
                        (con1.MailingCountry == null || orgConfig.isStateCountryPicklistsEnabled()) &&
                        // only test StateCode if picklists enabled.
                        (!orgConfig.isStateCountryPicklistsEnabled() || con1.get('MailingStateCode') == null);
        return isEmpty;

    }

    public void moveOppsToNewContactAccount(Map<Id, Id> newAcctIdByContactId, Map<Id, Id> oldAcctIdByContactId) {
       moveOppsToContactAccount(newAcctIdByContactId, oldAcctIdByContactId);
    }

    /*******************************************************************************************************
    * @description Moves all opps for the Primary OCR provided contacts to their new account.  Note that it
    * is the caller's responsibility to decide whether moving opps is appropriate for the involved accounts.
    * @param newHouseholdIdByContactId a map of Contact Id to Account Id, for the Accounts to move opps to
    * @param oldHouseholdIdByContactId a map of Contact Id to Account Id, for the Accounts to move opps from
    */
    private static void moveOppsToContactAccount(Map<Id,Id> newHouseholdIdByContactId, Map<Id,Id>
            oldHouseholdIdByContactId) {
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

    public List<Id> moveOppsForContactsSwitchingAccounts(Contacts contacts) {
        Map<Id, Id> oldHouseholdIdByContactId = new Map<Id, Id>();
        Map<Id, Id> newHouseholdIdByContactId = new Map<Id, Id>();

        List<Id> householdIdsToUpdate = new List<Id>();
        for (Contact contactRecord : (List<Contact>) contacts.getRecords()) {
            Contact oldContact = contacts.oldVersionOf(contactRecord);

            if (contactRecord.AccountId != oldContact.AccountId) {
                addHouseholdIds(householdIdsToUpdate, newHouseholdIdByContactId, contactRecord);
                addHouseholdIds(householdIdsToUpdate, oldHouseholdIdByContactId, oldContact);

            }
        }

        moveOppsToContactAccount(newHouseholdIdByContactId,
                oldHouseholdIdByContactId);
        return householdIdsToUpdate;
    }

    /**
     * addHouseholdIds Adds the account ids from all of the contacts belonging to a household
     * @param  householdIds           The collection of householdIds to add the account ids to
     * @param  householdIdByContactId The map of household by their id.
     * @param  contactRecord          The contact to extract the id from.
     */
    private static void addHouseholdIds(List<Id> householdIds, Map<Id, Id>
            householdIdByContactId, Contact contactRecord) {
        if (contactRecord.npe01__Organization_Type__c == CAO_Constants.HH_ACCOUNT_TYPE) {
            householdIds.add(contactRecord.AccountId);
            householdIdByContactId.put(contactRecord.Id, contactRecord.AccountId);
        }
    }

    /*******************************************************************************************************
    * @description Inserts a new 1:1 or HH Account for an Individual Contact
    * @param contactsWithoutAccounts the list of Contacts that need updating.
    */
    public void createOneToOneAndHouseholdAccountsFor(List<Contact>
            contactsWithoutAccounts){
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
        Id individualRecordTypeId =
                ContactAndOrgSettings.rtIdForAccountModel(CAO_Constants.isHHAccountModel());

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
                // construct the individul account for the Contact
                accountRecord = new Account();

                // construct the Account name
                accountRecord.Name = CAO_Constants.isHHAccountModel() ?
                        Households.strNameHHAccountForContact(contactRecord) :
                        Households.strNameOne2OneAccountForContact(contactRecord);

                // connect the Account to the Contact for 1:1 and HHAccount
                if (contactRecord.Id != null) {
                    accountRecord.npe01__One2OneContact__c = contactRecord.Id;
                }

                accountRecord.Phone = contactRecord.Phone;
                accountRecord.Fax = contactRecord.Fax;
                accountRecord.OwnerId = contactRecord.OwnerId;

                if (UserInfo.isMultiCurrencyOrganization()) {
                    accountRecord.put('CurrencyIsoCode', (String) contactRecord.get('CurrencyIsoCode'));
                }

                // Always copy the Contact's Mailing & Others address to the new Account's
                // Billing & Shipping address.
                if (contactRecord.is_Address_Override__c != true) {
                    addressService.copyAddressStdSObj(contactRecord, 'Mailing', accountRecord, 'Billing');
                    addressService.copyAddressStdSObj(contactRecord, 'Other', accountRecord, 'Shipping');
                }

                accountRecord.npe01__SYSTEM_AccountType__c = CAO_Constants.isHHAccountModel() ? CAO_Constants.HH_ACCOUNT_TYPE : CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE;
                if (individualRecordTypeId != null) {
                    accountRecord.put('RecordTypeID', individualRecordTypeId);
                }
                accountRecord.Type = CAO_Constants.isHHAccountModel() ? CAO_Constants.HH_TYPE : '';
                accountRecord.npe01__SYSTEMIsIndividual__c = true;
                accountInserts.add(accountRecord);
                contacts.add(contactRecord);
            }
        }

        if (accountInserts.isEmpty()) {
            return;
        }

        // with current TDTM design, we can't use dmlWrapper
        // because we need to get the new AccountID's into the Contacts.

        // identify the specific records that had the problem, and don't fail the whole batch
        //Note: this insert inserts both Accounts and Addresses (in the Acct triggers)
        List<Database.SaveResult> insertResults = UTIL_DMLService.insertRecords(accountInserts, false);
        for (Integer index = 0; index < insertResults.size(); index++) {
            Database.SaveResult insertResult = insertResults[index];
            if (!insertResult.isSuccess()) {
                for (Database.Error err : insertResult.getErrors()) {
                    accountInserts[index].addError(err.getMessage());
                    Contact contactRecord = contacts[index];
                    contactRecord.addError(String.format(System.Label.conFailedAccountCreate, new String[]{contactRecord.FirstName, contactRecord.LastName, err.getMessage()}));
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
}