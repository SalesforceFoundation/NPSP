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
public inherited sharing class HouseholdAccounts extends fflib_SObjects implements
                IHouseholds {

    /*******************************************************************************************************
    * @description Account filter when querying Contacts
    */
    private Set<Id> queryAccountIds;

    /*******************************************************************************************************
    * @description Contains list of retrieved Contacts by an Account Id
    */
    private Map<Id, Contact[]> contactsByAccountId {
        get {
            return contactsByAccountId = contactsByAccountId == null
                    ? findContactsByAccount()
                    : contactsByAccountId;
        }
        set;
    }

    /*******************************************************************************************************
    * @description Constructor
    * @param accountIds Account Ids to initialize the Contact Repository with
    */
    public HouseholdAccounts(Set<Id> accountIds) {
        //todo: change this lazy load to up front
        super(new List<Account>());
        queryAccountIds = accountIds == null
                ? new Set<Id>()
                : accountIds;
    }

    /*******************************************************************************************************
    * @description Constructor
    * @param accountIds Account Ids to initialize the Contact Repository with
    */
    public HouseholdAccounts(List<Account> accounts) {
        super(accounts);
    }

    /*******************************************************************************************************
    * @description Returns Contacts for the specified Account
    * @param accountId The Id of an Account to retrieve Contacts for
    * @return Contact[] List of Contacts for the specified Account. Empty list if the Account has no Contacts.
    */
    public Contact[] membersOf(Id accountId) {
        if (!queryAccountIds.contains(accountId)) {
            queryAccountIds.add(accountId);

            //reset Contacts repo so the next reference to the variable retrieves data from DB
            contactsByAccountId = null;
        }

        Contact[] contacts = contactsByAccountId.get(accountId);
        return contacts == null ? new Contact[0] : contacts;
    }

    /*******************************************************************************************************
    * @description Queries DB for specified ContactRepository Account Ids
    * @return Map<Id, Contact[]> Map of Contacts by an Account Id
    */
    private Map<Id, Contact[]> findContactsByAccount() {
        Map<Id, Contact[]> contactsByAccountId = new Map<Id, Contact[]>();

        if (queryAccountIds.isEmpty()) {
            return contactsByAccountId;
        }

        for (Contact c : [SELECT Id, AccountId, Current_Address__c FROM Contact WHERE AccountId IN :queryAccountIds]) {
            if (!contactsByAccountId.containsKey(c.AccountId)) {
                contactsByAccountId.put(c.AccountId, new Contact[0]);
            }
            contactsByAccountId.get(c.AccountId).add(c);
        }

        return contactsByAccountId;
    }

    /*******************************************************************************************************
    * @description Updates the accounts for contacts that have been deleted if they have other hh members
    * @param deletedContacts the list of Contacts that need to be considered
    */
    //Todo: HHAct-only, so:
    //      HHAccts.handleDeleted(Contacts c);
    //      UL: When a Contact is deleted, its Household(Account?) wil update its Primary
    //      Contact and Name, and recalc rollups.
    public void handleContactDeletion() {
//        List<Id> householdIdsToUpdate = new List<Id>();
        Set<Id> householdIdsToUpdate = new Set<Id>();

        for (Account accountRecord : (List<Account>) getRecords()) {
            System.debug(LoggingLevel.ERROR, '*** variable value: ' + accountRecord);
            System.debug(LoggingLevel.ERROR, '^^^^^^ accountRecord ^^^^^^');
            Boolean needsAccountUpdate =
                    (!accountRecord.Contacts.isEmpty()
                            || !accountRecord.Opportunities.isEmpty());

            if (needsAccountUpdate) {
                householdIdsToUpdate.add(accountRecord.Id);
            }
        }

        new ACCT_IndividualAccounts_TDTM()
                .updateHouseholds(new List<Id>(householdIdsToUpdate));
    }
}