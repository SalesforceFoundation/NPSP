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
* @date 2015
* @description Tests Contact Merge when done through the API
* @group ContactMerge
*/

@isTest
public with sharing class CON_ContactMergeTDTM_TEST {
    private static final Integer MOCK_IDS_SIZE = 5;

    /*******************************************************************************************************
    * @description merge two Contacts in the same Household Account.  
    * verify: 
    *   the account's names and greetings are updated.
    *   Soft Credits are recalculated.
    *   Opportunity Rollups on Contact are recalculated
    *   No Duplicate and Primary Affiliations
    */
    @IsTest
    private static void mergeContactsSameHHAccount() {
        // this creates 1 Household Accounts, with 2 Contacts, and a default Address for each HH
        ADDR_Addresses_TEST.createHHTestData(1, 2);
        
        // create an opp for each contact
        List<Opportunity> listOpp = UTIL_UnitTestData_TEST.OppsForContactList(ADDR_Addresses_TEST.listConT, null, 
            UTIL_UnitTestData_TEST.getclosedWonStage(), System.Today(), 100, null, null);
        insert listOpp;
        
        Contact conWinner = ADDR_Addresses_TEST.listConT[1];
        Contact conLoser = ADDR_Addresses_TEST.listConT[0];

        // create a primary affiliation for each contact
        npe5__Affiliations_Settings__c affiliationsSettingsForTests = UTIL_CustomSettingsFacade.getAffiliationsSettingsForTests(
            new npe5__Affiliations_Settings__c(npe5__Automatic_Affiliation_Creation_Turned_On__c = true));
        Account accOrg = new Account(Name='OrgAccount');
        insert accOrg;
        conWinner.Primary_Affiliation__c = accOrg.Id;
        conLoser.Primary_Affiliation__c = accOrg.Id;
        update new List<Contact> {conWinner, conLoser};
        System.assertEquals(2, [select count() from npe5__Affiliation__c]);
        
        Test.startTest();
        merge conWinner conLoser;

        // to flush our future calls that fix related data up!        
        Test.stopTest();

        // reload our contacts and accounts
        List<Account> listAcc = new List<Account>([select Id, Name, npo02__Formal_Greeting__c, npo02__Informal_Greeting__c, 
            npo02__NumberOfClosedOpps__c, 
            BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry 
            from Account where Id != :accOrg.Id order by Id]);
        List<Contact> listCon = [select Id, Firstname, AccountId, npo02__NumberOfClosedOpps__c,
            is_Address_Override__c, Current_Address__c, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry 
            from Contact order by Id];
            
        // verify the merge
        System.assertEquals(1, listAcc.size());
        System.assertEquals(1, listCon.size());
        System.assertEquals(conWinner.Id, listCon[0].Id);
                    
        // verify the account's names and greetings are updated
        System.assertEquals(false, listAcc[0].npo02__Formal_Greeting__c.contains(conLoser.Firstname));        
        System.assertEquals(true, listAcc[0].npo02__Formal_Greeting__c.contains(conWinner.Firstname));    
        
        // verify opps still in the account
        System.assertEquals(2, [select count() from Opportunity where AccountId = :listAcc[0].Id]);  
            
        // verify Account rollups are still valid
        System.assertEquals(2, listAcc[0].npo02__NumberOfClosedOpps__c);  
        
        // verify Contact rollups are valid
        System.assertEquals(2, listCon[0].npo02__NumberOfClosedOpps__c);          

        // verify Soft Credits recalculated
        System.assertEquals(2, [select count() from OpportunityContactRole where ContactId = :listCon[0].Id]);
        System.assertEquals(2, [select count() from OpportunityContactRole where isPrimary = true]);
        System.assertEquals(2, [select count() from OpportunityContactRole]);
        
        // verify no duplicate Affiliations and one primary Affiliation
        System.assertEquals(1, [select count() from npe5__Affiliation__c where npe5__Primary__c = true]);
        System.assertEquals(1, [select count() from npe5__Affiliation__c]);
    }

    /*******************************************************************************************************
    * @description merge two Contacts from different Household Accounts.  
    * verify: 
    *   the account's names and greetings are updated.
    *   Opps are moved to the Winning Contact's account
    *   Soft Credits are recalculated.
    *   Opp Rollups are recalculated.
    *   Addresses are dealt with
    *   No Duplicate and Primary Affiliations
    */
    @IsTest
    private static void mergeContactsDifferentHHAccount() {
        // this creates 2 Household Accounts, each with 2 Contacts, and a default Address for each HH
        ADDR_Addresses_TEST.createHHTestData(2, 2);
        
        // create an opp for each contact
        List<Opportunity> listOpp = UTIL_UnitTestData_TEST.OppsForContactList(ADDR_Addresses_TEST.listConT, null, 
            UTIL_UnitTestData_TEST.getclosedWonStage(), System.Today(), 100, null, null);
        insert listOpp;
        
        Contact conWinner = ADDR_Addresses_TEST.listConT[1];
        Contact conLoser = ADDR_Addresses_TEST.listConT[3];

        // create a primary affiliation for each contact
        npe5__Affiliations_Settings__c affiliationsSettingsForTests = UTIL_CustomSettingsFacade.getAffiliationsSettingsForTests(
            new npe5__Affiliations_Settings__c(npe5__Automatic_Affiliation_Creation_Turned_On__c = true));
        Account accOrg = new Account(Name='OrgAccount');
        insert accOrg;
        conWinner.Primary_Affiliation__c = accOrg.Id;
        conLoser.Primary_Affiliation__c = accOrg.Id;
        update new List<Contact> {conWinner, conLoser};
        System.assertEquals(2, [select count() from npe5__Affiliation__c]);

        Test.startTest();
        merge conWinner conLoser;

        // to flush our future calls that fix related data up!        
        Test.stopTest();

        // reload our accounts
        List<Account> listAcc = new List<Account>([select Id, Name, npo02__Formal_Greeting__c, npo02__Informal_Greeting__c, 
            npo02__NumberOfClosedOpps__c, 
            BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry 
            from Account where Id != :accOrg.Id order by Id]);
        System.assertEquals(conWinner.AccountId, listAcc[0].Id);
        Account accWinner = listAcc[0];
        System.assertEquals(conLoser.AccountId, listAcc[1].Id);
        Account accLoser = listAcc[1];

        // reload our contacts
        List<Contact> listCon = [select Id, Firstname, AccountId, npo02__NumberOfClosedOpps__c,
            is_Address_Override__c, Current_Address__c, Current_Address__r.Household_Account__c,
            MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry 
            from Contact order by Id];
        System.assertEquals(conWinner.Id, listCon[1].Id);
        conWinner = listCon[1];            
            
        // verify the merge
        System.assertEquals(2, listAcc.size());
        System.assertEquals(3, listCon.size());
        System.assertEquals(2, [select count() from Contact where AccountId = :conWinner.AccountId]);
        System.assertEquals(1, [select count() from Contact where AccountId = :conLoser.AccountId]);
                    
        // verify the account's names and greetings are updated
        System.assertEquals(true, accWinner.npo02__Formal_Greeting__c.contains(conWinner.Firstname));    
        System.assertEquals(false, accWinner.npo02__Formal_Greeting__c.contains(conLoser.Firstname));        
        System.assertEquals(false, accLoser.npo02__Formal_Greeting__c.contains(conLoser.Firstname));        
        System.assertEquals(false, accLoser.npo02__Formal_Greeting__c.contains(conWinner.Firstname));    
        
        // verify opps in the correct accounts
        System.assertEquals(3, [select count() from Opportunity where AccountId = :conWinner.AccountId]);  
        System.assertEquals(1, [select count() from Opportunity where AccountId = :conLoser.AccountId]);  
            
        // verify Account rollups are still valid
        System.assertEquals(3, accWinner.npo02__NumberOfClosedOpps__c);            
        System.assertEquals(1, accLoser.npo02__NumberOfClosedOpps__c);    
        
        // verify Contact rollups are valid
        System.assertEquals(2, conWinner.npo02__NumberOfClosedOpps__c);          

        // verify Soft Credits recalculated
        System.assertEquals(3, [select count() from OpportunityContactRole where ContactId = :conWinner.Id]);        
        System.assertEquals(4, [select count() from OpportunityContactRole where isPrimary = true]);        
        System.assertEquals(7, [select count() from OpportunityContactRole]);  
        
        // verify Winner's address matches their account
        System.assertEquals(false, conWinner.is_Address_Override__c);
        System.assertEquals(conWinner.Current_Address__r.Household_Account__c, accWinner.Id);
        System.assertEquals(conWinner.MailingStreet, accWinner.BillingStreet);      

        // verify no duplicate Affiliations and one primary Affiliation
        System.assertEquals(1, [select count() from npe5__Affiliation__c where npe5__Primary__c = true]);              
        System.assertEquals(1, [select count() from npe5__Affiliation__c]);              
    }

    /*******************************************************************************************************
    * @description merge three Contacts from different Household Accounts with many affiliations.  
    * verify: 
    *   No Duplicate and Primary Affiliations
    */
    @IsTest
    private static void mergeContactsDifferentHHAccountManyAffl() {
        // this creates 3 Household Accounts, each with 2 Contacts, and a default Address for each HH
        ADDR_Addresses_TEST.createHHTestData(3, 2);
        
        Contact conWinner = ADDR_Addresses_TEST.listConT[1];
        Contact conLoser1 = ADDR_Addresses_TEST.listConT[3];
        Contact conLoser2 = ADDR_Addresses_TEST.listConT[4];

        // create a primary affiliation for each contact
        npe5__Affiliations_Settings__c affiliationsSettingsForTests = UTIL_CustomSettingsFacade.getAffiliationsSettingsForTests(
            new npe5__Affiliations_Settings__c(npe5__Automatic_Affiliation_Creation_Turned_On__c = true));
        Account accOrg = new Account(Name='OrgAccount');
        insert accOrg;
        conWinner.Primary_Affiliation__c = accOrg.Id;
        conLoser1.Primary_Affiliation__c = accOrg.Id;
        conLoser2.Primary_Affiliation__c = accOrg.Id;
        update new List<Contact> {conWinner, conLoser1, conLoser2};
        System.assertEquals(3, [select count() from npe5__Affiliation__c]);
        
        // create additional affiliations
        List<npe5__Affiliation__c> listAffl = new List<npe5__Affiliation__c>();
        listAffl.add(new npe5__Affiliation__c(npe5__Contact__c=conWinner.Id, npe5__Organization__c=accOrg.Id, npe5__Status__c='inactive'));             
        listAffl.add(new npe5__Affiliation__c(npe5__Contact__c=conLoser1.Id, npe5__Organization__c=accOrg.Id, npe5__Status__c='inactive'));             
        listAffl.add(new npe5__Affiliation__c(npe5__Contact__c=conLoser2.Id, npe5__Organization__c=accOrg.Id, npe5__Status__c='inactive'));             
        listAffl.add(new npe5__Affiliation__c(npe5__Contact__c=conLoser2.Id, npe5__Organization__c=accOrg.Id, npe5__Status__c='random'));             
        insert listAffl;
        System.assertEquals(7, [select count() from npe5__Affiliation__c]);

        // now let's do the merge!
        Test.startTest();
        merge conWinner new List<Contact>{conLoser1, conLoser2};

        // to flush our future calls that fix related data up!        
        Test.stopTest();

        // reload our contacts
        List<Contact> listCon = [select Id, Firstname, AccountId, npo02__NumberOfClosedOpps__c,
            is_Address_Override__c, Current_Address__c, Current_Address__r.Household_Account__c,
            MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry 
            from Contact order by Id];
        System.assertEquals(conWinner.Id, listCon[1].Id);
        conWinner = listCon[1];            
            
        // verify the merge
        System.assertEquals(4, listCon.size());
        System.assertEquals(2, [select count() from Contact where AccountId = :conWinner.AccountId]);
        System.assertEquals(1, [select count() from Contact where AccountId = :conLoser1.AccountId]);
        System.assertEquals(1, [select count() from Contact where AccountId = :conLoser2.AccountId]);
                    
        // verify no duplicate Affiliations and one primary Affiliation
        System.assertEquals(1, [select count() from npe5__Affiliation__c where npe5__Primary__c = true]);              
        System.assertEquals(3, [select count() from npe5__Affiliation__c]);              
    }

    /*******************************************************************************************************
    * @description Merge a Contact with an Address Override to a different Account, and verify: 
    *   the Address Override is copied to the new Account
    *   the Contact's Address Override lookup is updated
    *   the Contact's mailing address matches the override
    */
    @IsTest
    private static void mergeContactsDifferentHHAccountAddressOverride() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;
        
        // this creates 2 Household Accounts, each with 2 Contacts, and a default Address for each HH
        ADDR_Addresses_TEST.createHHTestData(2, 2);
        
        Contact conWinner = ADDR_Addresses_TEST.listConT[3];
        Contact conLoser = ADDR_Addresses_TEST.listConT[0];
        
        // create their own address override
        conWinner.MailingStreet = 'street override';
        conWinner.MailingCity = 'city override';
        conWinner.is_Address_Override__c = true;
        update conWinner;
        // here we go!
        Test.startTest();
        merge conWinner conLoser;

        // to flush our future calls that fix related data up!        
        Test.stopTest();

        // reload our accounts
        List<Account> listAcc = new List<Account>([select Id, Name, npo02__Formal_Greeting__c, npo02__Informal_Greeting__c, 
            BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry 
            from Account order by Id]);
        System.assertEquals(conWinner.AccountId, listAcc[1].Id);
        Account accWinner = listAcc[1];
        System.assertEquals(conLoser.AccountId, listAcc[0].Id);
        Account accLoser = listAcc[0];

        // reload our contacts
        List<Contact> listCon = [select Id, Firstname, AccountId, 
            is_Address_Override__c, Current_Address__c, Current_Address__r.Household_Account__c,
            MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry 
            from Contact order by Id];
        System.assertEquals(3, listCon.size());
        System.assertEquals(conWinner.Id, listCon[2].Id);
        conWinner = listCon[2];            
                        
        // verify the contacts belong to correct account.
        System.assertEquals(listCon[0].AccountId, accLoser.Id);
        System.assertEquals(listCon[1].AccountId, accWinner.Id);
        System.assertEquals(listCon[2].AccountId, accWinner.Id);
        
        // verify we have the expected number of addresses (2 + override we created)
        System.assertEquals(3, [select count() from Address__c]);
        System.assertEquals(2, [select count() from Address__c where Default_Address__c = true]);
        System.assertEquals(1, [select count() from Contact where is_Address_Override__c = true]);
        
        // verify the correct contact has the override
        System.assertEquals(true, conWinner.is_Address_Override__c);
        Address__c addr = [select Id, Household_Account__c, MailingStreet__c, MailingCity__c from Address__c where Id = :conWinner.Current_Address__c];
        
        // verify the address is in the winning acccount
        System.assertEquals(conWinner.AccountId, addr.Household_Account__c);
            
        // verify the contact's address is still the address override
        System.assertEquals(conWinner.MailingStreet, addr.MailingStreet__c);
        System.assertEquals(conWinner.MailingCity, addr.MailingCity__c);
    }

    /***************************************************************************************************************
     * @description Verifies the list of merge keys is split into each list of ids
     */
    @IsTest
    private static void shouldSetMergeKeyIds() {
        List<String> losersAccountIds = UTIL_UnitTestData_TEST.mockIds(Account.SObjectType, MOCK_IDS_SIZE);
        List<String> losingContactIds = UTIL_UnitTestData_TEST.mockIds(Contact.SObjectType, MOCK_IDS_SIZE);
        List<String> winningContactIds = UTIL_UnitTestData_TEST.mockIds(Contact.SObjectType, MOCK_IDS_SIZE);
        List<String> mergeKeys = new String[MOCK_IDS_SIZE];

        for (Integer index = 0; index < MOCK_IDS_SIZE; index++) {
            mergeKeys[index] = losingContactIds[index] + ':' + losersAccountIds[index] + ':' + winningContactIds[index];
        }

        CON_ContactMerge_TDTM.mergeProcessor.setMergeKeyIds(mergeKeys);
        System.assert(new Set<String>(losersAccountIds).equals(new Set<String>(CON_ContactMerge_TDTM.mergeProcessor.losersAccountIds)), 'Expected all of the losersAccountIds from the mockKeys to be extracted.');
        System.assert(new Set<String>(losingContactIds).equals(new Set<String>(CON_ContactMerge_TDTM.mergeProcessor.losingContactIds)), 'Expected all of the losingContactIds from the mockKeys to be extracted.');
        System.assert(new Set<String>(winningContactIds).equals(new Set<String>(CON_ContactMerge_TDTM.mergeProcessor.winningContactIds)), 'Expected all of the winningContactIds from the mockKeys to be extracted.');
    }

    /***************************************************************************************************************
     * @description Verifies the account ids are returned when household
     */
    @IsTest
    private static void shouldReturnAccountIdsWhenAccountsAreHouseholds() {
        List<Account> accounts = createMockAccounts(CAO_Constants.HH_ACCOUNT_TYPE);

        List<Id> actualIds = CON_ContactMerge_TDTM.mergeProcessor.getHouseholdAcctIds(accounts);
        System.assert(UTIL_UnitTestData_TEST.extractIds(accounts).equals(new Set<Id>(actualIds)), 'Expected the returned Ids to match the account Ids passed in.');
    }

    /***************************************************************************************************************
     * @description Verifies the contacts account ids are returned when household
     */
    @IsTest
    private static void shouldReturnAccountIdsWhenContactsAccountsAreHouseholds() {
        List<Account> accounts = createMockAccounts(CAO_Constants.HH_ACCOUNT_TYPE);
        List<Contact> contacts = createMockContacts(accounts);

        List<Id> actualIds = CON_ContactMerge_TDTM.mergeProcessor.getHouseholdAcctIds(contacts);
        System.assert(UTIL_UnitTestData_TEST.extractIds(accounts).equals(new Set<Id>(actualIds)), 'Expected the returned Ids to match the account Ids of the contacts passed in.');
    }

    /***************************************************************************************************************
     * @description Verifies the account ids are returned when household
     */
    @IsTest
    private static void shouldReturnEmptyListWhenAccountsAreNotHouseholds() {
        List<Account> accounts = createMockAccounts(CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE);

        List<Id> actualIds = CON_ContactMerge_TDTM.mergeProcessor.getHouseholdAcctIds(accounts);
        System.assert(actualIds.isEmpty(), 'Expected an empty list to be returned.');
    }

    /***************************************************************************************************************
     * @description Verifies the contacts account ids are returned when household
     */
    @IsTest
    private static void shouldReturnEmptyListWhenContactsAccountsAreNotHouseholds() {
        List<Account> accounts = createMockAccounts(CAO_Constants.BUCKET_ORGANIZATION_TYPE);
        List<Contact> contacts = createMockContacts(accounts);

        List<Id> actualIds = CON_ContactMerge_TDTM.mergeProcessor.getHouseholdAcctIds(contacts);
        System.assert(actualIds.isEmpty(), 'Expected an empty list to be returned.');
    }

    /***************************************************************************************************************
     * @description Verifies the account id by contact id are returned when any individual type of account
     */
    @IsTest
    private static void shouldReturnAccountIdByWinningContactIdWhenAccountsAreIndividualType() {
        List<Account> accounts = createMockAccounts(CAO_Constants.HH_ACCOUNT_TYPE);
        Set<Id> accountIds = UTIL_UnitTestData_TEST.extractIds(accounts);
        Set<Id> contactIds = new Set<Id>(UTIL_UnitTestData_TEST.mockIds(Contact.SObjectType, accounts.size()));
        CON_ContactMerge_TDTM.mergeProcessor.losersAccountIds = new List<Id>(accountIds);
        CON_ContactMerge_TDTM.mergeProcessor.winningContactIds = new List<Id>(contactIds);

        Map<Id, Id> accountIdsByContactId = CON_ContactMerge_TDTM.mergeProcessor.getOldAcctIdForOppsByWinningContactId(accounts);
        System.assert(accountIds.equals(new Set<Id>(accountIdsByContactId.values())), 'Expected the returned Ids to match the account Ids of the accounts passed in.');
        System.assert(contactIds.equals(new Set<Id>(accountIdsByContactId.keySet())), 'Expected the returned Ids to match the winning contact Ids.');
    }

    /***************************************************************************************************************
     * @description Verifies the contacts account id by contact id are returned when any individual type of account
     */
    @IsTest
    private static void shouldReturnAccountIdByWinningContactIdWhenContactsAccountsAreIndividualType() {
        List<Account> accounts = createMockAccounts(CAO_Constants.BUCKET_ORGANIZATION_TYPE);
        List<Contact> contacts = createMockContacts(accounts);
        Set<Id> accountIds = UTIL_UnitTestData_TEST.extractIds(accounts);
        Set<Id> contactIds = UTIL_UnitTestData_TEST.extractIds(contacts);

        Map<Id, Id> accountIdsByContactId = CON_ContactMerge_TDTM.mergeProcessor.getNewAcctIdForOppsByWinningContactId(contacts);
        System.assert(contactIds.equals(accountIdsByContactId.keySet()), 'Expected the returned Ids to match the winning contact Ids.');
        System.assert(accountIds.equals(new Set<Id>(accountIdsByContactId.values())), 'Expected the returned Ids to match the account Ids of the contacts passed in.');
    }

    /***************************************************************************************************************
     * @description Verifies an empty map is returned when the losing account is not an individual type of account
     */
    @IsTest
    private static void shouldReturnEmptyMapWhenAccountsAreIndividualType() {
        List<Account> accounts = createMockAccounts('');
        Set<Id> accountIds = UTIL_UnitTestData_TEST.extractIds(accounts);
        Set<Id> contactIds = new Set<Id>(UTIL_UnitTestData_TEST.mockIds(Contact.SObjectType, accounts.size()));
        CON_ContactMerge_TDTM.mergeProcessor.losersAccountIds = new List<Id>(accountIds);
        CON_ContactMerge_TDTM.mergeProcessor.winningContactIds = new List<Id>(contactIds);

        Map<Id, Id> accountIdsByContactId = CON_ContactMerge_TDTM.mergeProcessor.getOldAcctIdForOppsByWinningContactId(accounts);
        System.assert(accountIdsByContactId.isEmpty(), 'Expected an empty map to be returned.');
    }

    /***************************************************************************************************************
     * @description Verifies an empty map is returned when the winning contacts account 
     * is not an individual type of account
     */
    @IsTest
    private static void shouldReturnEmptyMapWhenContactsAccountsAreIndividualType() {
        List<Account> accounts = createMockAccounts('');
        List<Contact> contacts = createMockContacts(accounts);
        Set<Id> accountIds = UTIL_UnitTestData_TEST.extractIds(accounts);
        Set<Id> contactIds = UTIL_UnitTestData_TEST.extractIds(contacts);

        Map<Id, Id> accountIdsByContactId = CON_ContactMerge_TDTM.mergeProcessor.getNewAcctIdForOppsByWinningContactId(contacts);
        System.assert(accountIdsByContactId.isEmpty(), 'Expected an empty map to be returned.');
    }


    // Helpers
    ////////////

    /***************************************************************************************************************
     * @description Create accounts with mock ids and for the account type provided.
     */
    private static List<Account> createMockAccounts(String acctType) {
        List<Account> accounts = new List<Account>();

        for (Id recordId : UTIL_UnitTestData_TEST.mockIds(Account.SObjectType, MOCK_IDS_SIZE)) {
            accounts.add(new Account(Id = recordId, npe01__SYSTEM_AccountType__c = acctType));
        }

        return accounts;
    }

    /***************************************************************************************************************
     * @description Create contacts with mock ids and related to the accounts provided.
     */
    private static List<Contact> createMockContacts(List<Account> accounts) {
        List<Id> contactIds = UTIL_UnitTestData_TEST.mockIds(Contact.SObjectType, accounts.size());
        List<Contact> contacts = new List<Contact>();

        for (Integer index = 0; index < MOCK_IDS_SIZE; index++) {
            Contact contactRecord = new Contact(Id = contactIds[index]);
            contactRecord.Account = accounts[index];
            contactRecord.AccountId = accounts[index].Id;
            contacts.add(contactRecord);
        }

        return contacts;
    }

}