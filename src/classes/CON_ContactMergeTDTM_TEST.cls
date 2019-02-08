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
      FROM this software without specific prior written permission.
 
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

@IsTest
public with sharing class CON_ContactMergeTDTM_TEST {
    private static Contact winningContact;
    private static Contact losingContact;
    private static Account organizationAccount;

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
        ADDR_Addresses_TEST.createHHTestData(1, 2);
        createOpps(ADDR_Addresses_TEST.listConT);
        winningContact = ADDR_Addresses_TEST.listConT[1];
        losingContact = ADDR_Addresses_TEST.listConT[0];

        setAffiliationsSettings();
        createOrganizationAccount('SameHHAccount');
        winningContact.Primary_Affiliation__c = organizationAccount.Id;
        losingContact.Primary_Affiliation__c = organizationAccount.Id;
        update new List<Contact> { winningContact, losingContact };
        verifyAffiliationsCount(2, 2);

        Test.startTest();
        merge winningContact losingContact;
        Test.stopTest();

        List<Account> listAcc = getHouseholdAccounts();
        System.assertEquals(1, listAcc.size(), 'Expected one household account to remain.');
        Account winnersAccount = listAcc[0];
        System.assertEquals(winningContact.AccountId, winnersAccount.Id, 'Expected the list to contain the winning contact\'s account.');
        System.assert(!winnersAccount.npo02__Formal_Greeting__c.contains(losingContact.Firstname), 'The winning account should not contain the losing contacts name.');
        System.assert(winnersAccount.npo02__Formal_Greeting__c.contains(winningContact.Firstname), 'Expected the winners account to have the winning contact name.');

        List<Contact> listCon = getContacts();
        System.assertEquals(1, listCon.size(), 'Expected one contact to remain.');
        System.assertEquals(winningContact.Id, listCon[0].Id, 'Expected the list to contain the winning contact.');
        winningContact = listCon[0];
        System.assertEquals(2, winnersAccount.npo02__NumberOfClosedOpps__c, 'Expect 2 closed opps to be rolled up to the winning account.');
        System.assertEquals(2, winningContact.npo02__NumberOfClosedOpps__c, 'Expect 2 closed opps to be rolled up to the winning contact.');

        verifyAccountsOppCount(winnersAccount.Id, 2);
        verifyOppContactRoleCount(winningContact.Id, 2, 2, 2);
        verifyAffiliationsCount(1, 1);
    }

    /*******************************************************************************************************
    * @description merge two Contacts FROM different Household Accounts.  
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
        ADDR_Addresses_TEST.createHHTestData(2, 2);
        createOpps(ADDR_Addresses_TEST.listConT);
        winningContact = ADDR_Addresses_TEST.listConT[1];
        losingContact = ADDR_Addresses_TEST.listConT[3];

        setAffiliationsSettings();
        createOrganizationAccount('DifferentHHAccount');
        winningContact.Primary_Affiliation__c = organizationAccount.Id;
        losingContact.Primary_Affiliation__c = organizationAccount.Id;
        update new List<Contact> {winningContact, losingContact};
        verifyAffiliationsCount(2, 2);

        Test.startTest();
        merge winningContact losingContact;
        Test.stopTest();

        List<Account> listAcc = getHouseholdAccounts();
        System.assertEquals(winningContact.AccountId, listAcc[0].Id);
        Account accWinner = listAcc[0];
        System.assertEquals(losingContact.AccountId, listAcc[1].Id);
        Account accLoser = listAcc[1];

        List<Contact> listCon = getContacts();
        System.assertEquals(winningContact.Id, listCon[1].Id);
        winningContact = listCon[1];
        System.assertEquals(2, listAcc.size(), 'Expect 2 household accounts to exist.');
        System.assertEquals(3, listCon.size(), 'Expect 3 contacts to exist.');

        System.assert(accWinner.npo02__Formal_Greeting__c.contains(winningContact.Firstname), 'The winning acccount\'s formal greeting should have the winning contacts first name.');
        System.assert(!accWinner.npo02__Formal_Greeting__c.contains(losingContact.Firstname), 'The winning account\'s formal greeting should not have the losing contacts first name.');
        System.assert(!accLoser.npo02__Formal_Greeting__c.contains(losingContact.Firstname), 'The losing account\'s formal greeting should not have the losing contacts first name.');
        System.assert(!accLoser.npo02__Formal_Greeting__c.contains(winningContact.Firstname), 'The losing account\'s formal greeting should not have the winning contacts first name.');

        System.assertEquals(3, accWinner.npo02__NumberOfClosedOpps__c, 'The winning account should have 3 opps rolled up.');
        System.assertEquals(1, accLoser.npo02__NumberOfClosedOpps__c, 'The losing account should have 1 opp rolled up.');
        System.assertEquals(2, winningContact.npo02__NumberOfClosedOpps__c, 'The winning contact should have 2 opps rolled up.');

        System.assert(!winningContact.is_Address_Override__c, 'The winning contact should not have the address override set.');
        System.assertEquals(winningContact.Current_Address__r.Household_Account__c, accWinner.Id, 'The winning contact\'s address should be related to its account.');
        System.assertEquals(winningContact.MailingStreet, accWinner.BillingStreet, 'The winning contact\'s Mailing Street should match its account.');

        verifyAccountsContactCount(winningContact.AccountId, losingContact.AccountId, 2, 1);
        verifyAccountsOppCount(winningContact.AccountId, 3);
        verifyAccountsOppCount(losingContact.AccountId, 1);
        verifyOppContactRoleCount(winningContact.Id, 3, 7, 4);
        verifyAffiliationsCount(1, 1);
    }

    /*******************************************************************************************************
    * @description merge three Contacts FROM different Household Accounts with many affiliations.  
    * verify: 
    *   No Duplicate and Primary Affiliations
    */
    @IsTest
    private static void mergeContactsDifferentHHAccountManyAffl() {
        ADDR_Addresses_TEST.createHHTestData(3, 2);
        winningContact = ADDR_Addresses_TEST.listConT[1];
        losingContact = ADDR_Addresses_TEST.listConT[3];
        Contact losingContact2 = ADDR_Addresses_TEST.listConT[4];

        setAffiliationsSettings();
        createOrganizationAccount('DifferentHHAcctManyAffl');
        winningContact.Primary_Affiliation__c = organizationAccount.Id;
        losingContact.Primary_Affiliation__c = organizationAccount.Id;
        losingContact2.Primary_Affiliation__c = organizationAccount.Id;
        update new List<Contact> { winningContact, losingContact, losingContact2 };
        verifyAffiliationsCount(3, 3);

        List<npe5__Affiliation__c> listAffl = new List<npe5__Affiliation__c>();
        listAffl.add(new npe5__Affiliation__c(npe5__Contact__c=winningContact.Id, npe5__Organization__c=organizationAccount.Id, npe5__Status__c='inactive'));
        listAffl.add(new npe5__Affiliation__c(npe5__Contact__c=losingContact.Id, npe5__Organization__c=organizationAccount.Id, npe5__Status__c='inactive'));
        listAffl.add(new npe5__Affiliation__c(npe5__Contact__c=losingContact2.Id, npe5__Organization__c=organizationAccount.Id, npe5__Status__c='inactive'));
        listAffl.add(new npe5__Affiliation__c(npe5__Contact__c=losingContact2.Id, npe5__Organization__c=organizationAccount.Id, npe5__Status__c='random'));
        insert listAffl;
        verifyAffiliationsCount(7, 3);

        Test.startTest();
        merge winningContact new List<Contact>{ losingContact, losingContact2 };
        Test.stopTest();

        List<Contact> listCon = getContacts();
        System.assertEquals(winningContact.Id, listCon[1].Id);
        winningContact = listCon[1];

        System.assertEquals(4, listCon.size(), 'There total number of contacts is not as expected.');
        verifyAccountsContactCount(winningContact.AccountId, losingContact.AccountId, 2, 1);
        verifyLosingAccountsContactCount(losingContact2.AccountId, 1);
        verifyAffiliationsCount(3, 1);
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

        ADDR_Addresses_TEST.createHHTestData(2, 2);
        winningContact = ADDR_Addresses_TEST.listConT[3];
        losingContact = ADDR_Addresses_TEST.listConT[0];

        // create their own address override
        winningContact.MailingStreet = 'street override';
        winningContact.MailingCity = 'city override';
        winningContact.is_Address_Override__c = true;
        update winningContact;

        Test.startTest();
        merge winningContact losingContact;
        Test.stopTest();

        List<Account> listAcc = getHouseholdAccounts();
        System.assertEquals(winningContact.AccountId, listAcc[1].Id, 'Expected the second account to be the winning contacts account.');
        Account accWinner = listAcc[1];
        System.assertEquals(losingContact.AccountId, listAcc[0].Id, 'Expected the first account to be the losing contacts account.');
        Account accLoser = listAcc[0];

        List<Contact> listCon = getContacts();
        System.assertEquals(3, listCon.size(), 'The total number of contacts is not as expected.');
        System.assertEquals(winningContact.Id, listCon[2].Id, 'Expected the second contact to be the winning contact.');
        winningContact = listCon[2];

        System.assertEquals(listCon[0].AccountId, accLoser.Id, 'Expected the first contact to be related to the losing contacts account.');
        System.assertEquals(listCon[1].AccountId, accWinner.Id, 'Expected the second contact to be related to the winning contacts account.');
        System.assertEquals(listCon[2].AccountId, accWinner.Id, 'Expected the third contact to be related to the winning contacts account.');

        Address__c addr = [SELECT Id, Household_Account__c, MailingStreet__c, MailingCity__c FROM Address__c WHERE Id = :winningContact.Current_Address__c];
        System.assertEquals(3, [SELECT count() FROM Address__c], 'The number of total addresses is not as expected.');
        System.assertEquals(2, [SELECT count() FROM Address__c WHERE Default_Address__c = true], 'The total number of default addresses is not as expected.');
        System.assertEquals(1, [SELECT count() FROM Contact WHERE is_Address_Override__c = true], 'The total number of contacts with an address override set is not as expected.');
        System.assertEquals(true, winningContact.is_Address_Override__c, 'Expected the winning contact to have the address override set.');
        System.assertEquals(winningContact.AccountId, addr.Household_Account__c, 'Expected the address to be related to the winning contacts account.');
        System.assertEquals(winningContact.MailingStreet, addr.MailingStreet__c, 'The winning contacts mailing street is not as expected.');
        System.assertEquals(winningContact.MailingCity, addr.MailingCity__c, 'The winning contacts mailing city is not as expected.');
    }


    // Helpers
    ////////////
    private static void createOpps(List<Contact> contacts) {
        // create an opp for each contact
        List<Opportunity> listOpp = UTIL_UnitTestData_TEST.OppsForContactList(contacts, null, 
            UTIL_UnitTestData_TEST.getclosedWonStage(), System.Today(), 100, null, null);

        insert listOpp;
    }

    private static void setAffiliationsSettings() {
        npe5__Affiliations_Settings__c affiliationsSettingsForTests = UTIL_CustomSettingsFacade.getAffiliationsSettingsForTests(
            new npe5__Affiliations_Settings__c(npe5__Automatic_Affiliation_Creation_Turned_On__c = true));
    }

    private static void createOrganizationAccount(String name) {
        organizationAccount = new Account(Name = name);

        insert organizationAccount;
    }

    public static List<Account> getHouseholdAccounts() {
        Map<Id, Account> accountById = new Map<Id, Account>([
            SELECT Id, Name, npo02__Formal_Greeting__c, npo02__Informal_Greeting__c, npo02__NumberOfClosedOpps__c,
                BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry 
            FROM Account
            ORDER BY Id
        ]);

        if (organizationAccount != null) {
            accountById.remove(organizationAccount.Id);
        }

        return accountById.values();
    }

    public static List<Contact> getContacts() {
        return [
            SELECT Id, Firstname, AccountId, npo02__NumberOfClosedOpps__c,
                is_Address_Override__c, Current_Address__c, Current_Address__r.Household_Account__c,
                MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry
            FROM Contact
            ORDER BY Id];
    }

    private static void verifyAffiliationsCount(Integer totalCount, Integer totalPrimary) {
        System.assertEquals(totalCount, [SELECT count() FROM npe5__Affiliation__c], 'The total count of Affiliations is not as expected.');
        System.assertEquals(totalPrimary, [SELECT count() FROM npe5__Affiliation__c WHERE npe5__Primary__c = true], 'There should be only one primary affiliation total.');
    }

    public static void verifyAccountsContactCount(Id winningAccountId, Id losingAccountId, Integer winnersCount, Integer losersCount) {
        verifyWinningAccountsContactCount(winningAccountId, winnersCount);
        verifyLosingAccountsContactCount(losingAccountId, losersCount);
    }

    private static void verifyWinningAccountsContactCount(Id winningAccountId, Integer winnersCount) {
        System.assertEquals(winnersCount, [SELECT count() FROM Contact WHERE AccountId = :winningAccountId], 'The number of contacts related to the winning account is not as expected.');
    }

    public static void verifyLosingAccountsContactCount(Id losingAccountId, Integer losersCount) {
        System.assertEquals(losersCount, [SELECT count() FROM Contact WHERE AccountId = :losingAccountId], 'The number of contacts related to the losing account is not as expected.');
    }

    private static void verifyAccountsOppCount(Id accountId, Integer expectedCount) {
        System.assertEquals(expectedCount, [SELECT count() FROM Opportunity WHERE AccountId = :accountId], 'The count of opps related to the account is not as expected.');
    }

    private static void verifyOppContactRoleCount(Id contactId, Integer contactCount, Integer totalCount, Integer primaryCount) {
        System.assertEquals(contactCount, [SELECT count() FROM OpportunityContactRole WHERE ContactId = :contactId], 'The number of opp contact roles associated with the contact is not as expected.');
        System.assertEquals(totalCount, [SELECT count() FROM OpportunityContactRole], 'The number of total contact roles is not as expected.');
        System.assertEquals(primaryCount, [SELECT count() FROM OpportunityContactRole WHERE isPrimary = true], 'The number of total primary contact roles is not as expected.');
    }
}