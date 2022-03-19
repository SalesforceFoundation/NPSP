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
* @description Contact repository responsible for retrieval and storing of Contacts for specified Accounts
*/
public inherited sharing class Households extends fflib_SObjects2 {

    private Map<Id, Contacts> membersByHouseholdId {
        get {
            if (membersByHouseholdId == null) {
                membersByHouseholdId = new Map<Id, Contacts>();
                for (Account account : (List<Account>) getRecords()) {
                    membersByHouseholdId.put(
                            account.Id,
                            new Contacts(account.Contacts)
                    );
                }
            }
            return membersByHouseholdId;
        }
        private set;
    }

    @TestVisible
    private static HouseholdSelector householdSelector {
        get {
            if (householdSelector == null) {
                householdSelector = new HouseholdSelector();
            }
            return householdSelector;
        }
        set;
    }

    @TestVisible
    private static HouseholdNamingService householdNamingService {
        get {
            if (householdNamingService == null) {
                householdNamingService = new HouseholdNamingService();
            }
            return householdNamingService;
        }
        set;
    }

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

    /*******************************************************************************************************
    * @description Constructor
    * @param accountIds Account Ids to initialize the Contact Repository with
    */
    public Households(Set<Id> accountIds) {
        super((List<Object>) householdSelector.findByIds(accountIds));
    }

    /*******************************************************************************************************
    * @description Constructor
    * @param accountIds Account Ids to initialize the Contact Repository with
    */
    public Households(List<Account> accounts) {
        super(accounts);
    }

    public Contacts membersOf(HouseholdId aHouseholdId) {
        Contacts members = membersByHouseholdId.get(aHouseholdId.value());
        if (members == null) {
            return new Contacts(new List<Contact>());
        } else {
            return members;
        }
    }

    /*******************************************************************************************************
    * @description Updates the accounts for contacts that have been deleted
    */
    public void handleContactDeletion(TDTM_Runnable.DmlWrapper dmlWrapper) {
        updateHouseholds(dmlWrapper);
    }

    public static void insertHouseholdAddressesFor(List<Contact>
            contactsNeedingAddressesCreated) {
        //Create household addresses from Contacts instead of from
        // the Account to include mapping of the Primary Address Type.
        Households.createAddressFromContactAndSetCurrentAddressLookupId
                (contactsNeedingAddressesCreated, true);
    }

    private List<Account> withOpportunities() {
        List<Account> withOpportunities = new List<Account>();
        for (Account accountRecord : (List<Account>) getRecords()) {
            if (!accountRecord.Opportunities.isEmpty()) {
                withOpportunities.add(accountRecord);
            }
        }
        return withOpportunities;
    }

    private List<Account> withContacts() {
        List<Account> withContacts = new List<Account>();
        for (Account accountRecord : (List<Account>) getRecords()) {
            if (!accountRecord.Contacts.isEmpty()) {
                withContacts.add(accountRecord);
            }
        }
        return withContacts;
    }

    /*******************************************************************************************************
    * @description Updates the Household's naming, primary contact, and rollups.
    */
    public void updateHouseholds(TDTM_Runnable.DmlWrapper dmlWrapper) {
        resetPrimaryContact(dmlWrapper);
        updateNameAndMemberCount(ids());
        rollupAccounts(ids());
    }

    private void resetPrimaryContact(TDTM_Runnable.DmlWrapper dmlWrapper) {
        // now go thru each account and update their primary contact if the current one isn't valid
        List<Account> accounts = new List<Account>();
        for (Account accountRecord : (List<Account>) getRecords()) {
            // Households domain always has its Contacts
            Contacts members = new Contacts(accountRecord.Contacts);
            if (!members.ids().contains(accountRecord.npe01__One2OneContact__c)) {
                accountRecord.npe01__One2OneContact__c = extractFirstId(members.ids());
                accounts.add(accountRecord);
            }
        }

        if (accounts != null && !accounts.isEmpty()) {
            dmlWrapper.objectsToUpdate.addAll(accounts);
        }
    }

    private List<Id> ids() {
        return new List<Id>(getIdFieldValues(Account.Id).getIds());
    }

    /*******************************************************************************************************
    * @description for the list of Household or Account Ids, update their Household Names
    * @param accountIds the list of Household or Account Ids that need updating.
    * @return void
    */
    public static void updateNameAndMemberCount(List<Id> accountIds) {
        if (accountIds.isEmpty()) {
            return;
        }

        if (shouldProcessSynchronously(accountIds)) {
            HouseholdNamingService householdNamingService = new HouseholdNamingService();
            householdNamingService.updateHouseholdNameAndMemberCount(accountIds);
        } else {
            householdNamingService.updateHouseholdNameAndMemberCountAsync(accountIds);
        }
    }

    private static Boolean shouldProcessSynchronously(List<Id> accountIds) {
        return accountIds.size() == 1 || System.isFuture() || System.isBatch() || System.isQueueable();
    }

    /*******************************************************************************************************
    * @description returns the first Id from the specified set
    * @param ids a set of Id's
    * @return Id.  null if the set is empty.
    */
    private static Id extractFirstId(Set<Id> ids) {
        for (Id recordId : ids) {
            return recordId;
        }

        return null;
    }

    /*******************************************************************************************************
    * @description for the list of AccountId's, recalc their rollups
    * @param accountIds the list of Account (Id's) that need updating.
    */
    public static void rollupAccounts(List<Id> accountIds) {
        new RLLP_OppRollup().rollupAccounts(new Set<Id>(accountIds));
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

    public static void renameHouseholdAccountsAfterInsert(List<Contact> contacts) {

        List<Id> householdIdsToRename = new List<Id>();

        for (Contact contactRecord : contacts) {
            if (contactRecord.AccountId == null) {
                continue;
            }

            if (isHouseholdMember(contactRecord)) {
                householdIdsToRename.add(contactRecord.AccountId);
            }
        }

        updateNameAndMemberCount(householdIdsToRename);
    }

    /**
     * @description This method was originally copied from the
     * createAddressFromContactAndSetCurrentAddressLookupId(List<Contact> listConAll)
     * method.  This one is a version that always inserts new contact addresses, as
     * opposed to the method above that runs both before insert and after insert and has
     * different behavior depending on context.
     * Creating a new Household should be a responsibility of the Household domain or of
     * an Application-level service.  Relocating this method in the Households domain now
     * facilitates aggregating Household behaviors at this level, to move towards having
     * simple methods that perform all related behaviors, like "add()" -ing a Contact
     * to a Household to make it a HouseholdMember.
     */
    public static void createAddressFromContactAndSetCurrentAddressLookupId(List<Contact>
            listConAll, Boolean forceInsert) {
        if (!listConAll.isEmpty()) {
            // Strategy:
            // create a new (unsaved) address for each contact.
            // see if there is an existing address that matches each new address.
            //
            // for existing addresses we match
            //     process during BeforeInsert/Update
            //     update appropriate fields on contact
            //
            // for new addresses that won't be a default (ie, the contact has override set)
            //     process during BeforeInsert/Update
            //     create the address now
            //     update appropriate fields on contact
            //
            // for new addresses that will be a default address
            //     process during AfterInsert/Update
            //     mark the new address as default
            //     put it on dmlWrapper
            //

            Map<Contact, Address__c> mapConAddr = new Map<Contact, Address__c>();
            List<Contact> listCon = new List<Contact>();

            for (Contact con : listConAll) {
                ContactAddress contactAddress = new ContactAddress(con);
                if (!contactAddress.hasAddress()) {
                    continue;
                }
                listCon.add(con);
                NPSP_Address npspAddressFromContact = new NPSP_Address(con);
                mapConAddr.put(con, npspAddressFromContact.getRecord());
            }

            // look for duplicates for our proposed new addresses
            Map<Address__c, Address__c> mapAddrDupAddr = Addresses.getExistingAddresses(mapConAddr
                    .values());

            // maps & lists to keep track of the addresses we must insert or update
            Map<Contact, Address__c> mapConAddrInsertNow = new Map<Contact, Address__c>();

            for (Contact con : listCon) {
                Address__c addrNew = mapConAddr.get(con);
                Address__c addrDup = mapAddrDupAddr.get(addrNew);

                // if found a match
                if (addrDup != null) {
                    // record the match in the contact
                    con.Current_Address__c = addrDup.Id;

                    //reset the Primary Address Type only; resetting other fields on Contact will create a new Address
                    con.npe01__Primary_Address_Type__c = con.npe01__Primary_Address_Type__c == null
                            ? addrDup.Address_Type__c
                            : con.npe01__Primary_Address_Type__c;

                    // Prevent an address that was just inserted by the BeforeInsert trigger from being udpated
                    // a second time by the AfterInsert trigger.
                }

                // no match found, and its an override just for this contact
                else if (con.is_Address_Override__c || forceInsert) {
                    // put it on the list of addresss to create now
                    mapConAddrInsertNow.put(con, addrNew);
                }
            }

            if (mapConAddrInsertNow.size() > 0) {
                UTIL_DMLService.insertRecords(mapConAddrInsertNow.values());
                // Since we're inserting new Addresses in a Before Insert/Update scenario, set the flag to
                // prevent the After Insert/Update Contact logic from executing when it's eventually called.
                TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.flag.ADDR_hasRunContactOnBefore, true);
                for (Contact con : mapConAddrInsertNow.keySet()) {
                    Address__c addr = mapConAddrInsertNow.get(con);
                    con.Current_Address__c = addr.Id;
                }
            }
        }
    }

    /**
     * isHouseholdMember Determines whether or not the contact belongs to a household account.
     * @param  contactRecord The contact record to verify.
     * @return Boolean - true when the contact belongs to a household account.
     */
    private static Boolean isHouseholdMember(Contact contactRecord) {
        return contactRecord.Account.npe01__SYSTEM_AccountType__c == CAO_Constants.HH_ACCOUNT_TYPE;
    }

}