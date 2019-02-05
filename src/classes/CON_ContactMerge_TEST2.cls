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
* @date 2011 (2.x)
* @description Tests for CON_ContactMerge_CTRL
* @group ContactMerge
* @group-content ../../ApexDocContent/ContactMerge.htm
*/
@isTest
private class CON_ContactMerge_TEST2 {

    //merge two contacts in the Individual Account
    //the organization shouldn't be deleted
    @IsTest
    private static void merge2Individuals() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        CON_ContactMerge_TEST.defaultSetup(CAO_Constants.BUCKET_PROCESSOR);
        System.assertEquals(1, [SELECT count() FROM Account], 'The bucket account should be the only account.');
        CON_ContactMerge_TEST.controller.search();
        CON_ContactMerge_TEST.selectRecords(1, 0);
        CON_ContactMerge_TEST.controller.nextStep();
        CON_ContactMerge_TEST.selectMasterRecord();
        //merge them
        CON_ContactMerge_TEST.controller.mergeContacts();
        CON_ContactMerge_TEST.verifyContactMergeResults();
        System.assertEquals(1, [SELECT count() FROM Account], 'The bucket account should not be deleted.');
    }

    @IsTest
    private static void householdDifferentFromMaster() {
        npo02__Households_Settings__c householdSettingsForTests = UTIL_CustomSettingsFacade.getHouseholdsSettingsForTests(
            new npo02__Households_Settings__c (npo02__Household_Rules__c = HH_Households.ALL_PROCESSOR));

        CON_ContactMerge_TEST.defaultSetup(CAO_Constants.ONE_TO_ONE_PROCESSOR);
        CON_ContactMerge_TEST.controller.search();
        CON_ContactMerge_TEST.selectRecords(0, 1);
        CON_ContactMerge_TEST.controller.nextStep();
        CON_ContactMerge_TEST.selectMasterRecord();

        //SELECT the household of the one that is not the one we selected as master
        for (CON_ContactMerge_CTRL.FieldRow row : CON_ContactMerge_TEST.controller.fieldRows) {
            if(row.fieldName == 'npo02__household__c') {
                row.selectedValue = String.valueOf(CON_ContactMerge_TEST.losingContact.Id);
                break;
            }
        }

        Test.startTest();
        CON_ContactMerge_TEST.controller.mergeContacts();
        Test.stopTest();

        //Merged contact should reference the second contact's household
        System.assertEquals(CON_ContactMerge_TEST.losingContact.npo02__Household__c, [SELECT npo02__Household__c FROM Contact WHERE Id = :CON_ContactMerge_TEST.winningContact.Id].npo02__Household__c);
    }

    //Run Tests for One to One and HH Account Types
    @IsTest
    private static void merge2OneToOneOne2One(){
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        merge2OneToOne(CAO_Constants.ONE_TO_ONE_PROCESSOR);
    }

    @IsTest
    private static void merge2OneToOneHHAccount(){
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        merge2OneToOne(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    }

    //merge two contacts that are both in the one-to-one account model
    //the second contact's org should be deleted
    public static void merge2OneToOne(string strProcessor) {
        CON_ContactMerge_TEST.defaultSetup(strProcessor);
        CON_ContactMerge_TEST.controller.search();
        CON_ContactMerge_TEST.selectRecords(0, 1);
        CON_ContactMerge_TEST.controller.nextStep();
        CON_ContactMerge_TEST.selectMasterRecord();
        CON_ContactMerge_TEST.controller.mergeContacts();
        CON_ContactMerge_TEST.verifyMergeResults();
    }

    @IsTest
    private static void merge2OneToOneOppsOne2One(){
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        merge2OneToOneOpps(CAO_Constants.ONE_TO_ONE_PROCESSOR);
    }

    @IsTest
    private static void merge2OneToOneOppsHHAccount(){
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        merge2OneToOneOpps(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    }

    //merge two contacts that are both in the one-to-one account model
    //the second contact's org shouldn't be deleted because it has open opportunities
    public static void merge2OneToOneOpps(string strProcessor) {
        TDTM_DefaultConfig.startTestDataInit();
        CON_ContactMerge_TEST.defaultSetup(strProcessor);
        CON_ContactMerge_TEST.controller.search();
        CON_ContactMerge_TEST.selectRecords(0, 1);

        insert new Opportunity(AccountId = CON_ContactMerge_TEST.losingContact.accountId, Amount = 500, Name = 'test', StageName = 'Closed Won', CloseDate = System.today());
        CON_ContactMerge_TEST.controller.nextStep();
        CON_ContactMerge_TEST.selectMasterRecord();
        //merge them
        TDTM_DefaultConfig.stopTestDataInit();

        Test.startTest();
        CON_ContactMerge_TEST.controller.mergeContacts();
        Test.stopTest();

        CON_ContactMerge_TEST.verifyMergeResults();
        System.assertEquals(1, [SELECT count() FROM Opportunity WHERE accountId = :CON_ContactMerge_TEST.winningContact.AccountId], 'The Opportunity should be moved.');
    }

    @IsTest
    private static void merge2OrganizationsOne2One(){
        merge2Organizations(CAO_Constants.ONE_TO_ONE_PROCESSOR);
    }

    @IsTest
    private static void merge2OrganizationsHHAccount(){
        merge2Organizations(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    }

    //merge a one-to-one contact with one in a normal organzation
    //the organization shouldn't be deleted
    public static void merge2Organizations(string strProcessor) {
        CON_ContactMerge_TEST.setContactSettings(strProcessor);
        Account acc = new Account(Name = 'Test merge org Account 1');
        Account acc2 = new Account(Name = 'Test merge org Account 2');
        insert new Account[]{ acc, acc2 };

        CON_ContactMerge_TEST.winningContact = UTIL_UnitTestData_TEST.getContact();
        CON_ContactMerge_TEST.winningContact.AccountId = acc.Id;
        CON_ContactMerge_TEST.losingContact = UTIL_UnitTestData_TEST.getContact();
        CON_ContactMerge_TEST.losingContact.LastName = '2Contact_forTests_Merge';
        CON_ContactMerge_TEST.losingContact.AccountId = acc2.Id;
        insert new Contact[]{ CON_ContactMerge_TEST.winningContact, CON_ContactMerge_TEST.losingContact };
        CON_ContactMerge_TEST.setupSearchPage();
        CON_ContactMerge_TEST.setFixedSearchResults(2);
        CON_ContactMerge_TEST.controller.search();
        CON_ContactMerge_TEST.selectRecords(0, 1);
        CON_ContactMerge_TEST.controller.nextStep();
        CON_ContactMerge_TEST.selectMasterRecord();
        CON_ContactMerge_TEST.controller.mergeContacts();
        CON_ContactMerge_TEST.verifyContactMergeResults();
        System.assertEquals(2, [SELECT count() FROM Account WHERE Id IN : new Account[]{ acc, acc2 }], 'Neither account should be deleted.');
    }

    @IsTest
    private static void merge2PrivateContactsOne2One(){
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;
        
        merge2PrivateContacts(CAO_Constants.ONE_TO_ONE_PROCESSOR);
    }

    @IsTest
    private static void merge2PrivateContactsHHAccount(){
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        merge2PrivateContacts(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    }

    //merge two private contacts
    //the organization shouldn't be deleted
    public static void merge2PrivateContacts(string strProcessor) {
        CON_ContactMerge_TEST.setContactSettings(strProcessor);
        CON_ContactMerge_TEST.winningContact = UTIL_UnitTestData_TEST.getContact();
        CON_ContactMerge_TEST.winningContact.npe01__Private__c = true;

        CON_ContactMerge_TEST.losingContact = UTIL_UnitTestData_TEST.getContact();
        CON_ContactMerge_TEST.losingContact.LastName = '2Contact_forTests_Merge';
        CON_ContactMerge_TEST.losingContact.npe01__Private__c = true;
        insert new Contact[]{ CON_ContactMerge_TEST.winningContact, CON_ContactMerge_TEST.losingContact };

        CON_ContactMerge_TEST.setupSearchPage();
        CON_ContactMerge_TEST.setFixedSearchResults(2);
        CON_ContactMerge_TEST.controller.search();
        CON_ContactMerge_TEST.selectRecords(0, 1);
        CON_ContactMerge_TEST.controller.nextStep();
        CON_ContactMerge_TEST.selectMasterRecord();
        CON_ContactMerge_TEST.controller.mergeContacts();
        CON_ContactMerge_TEST.verifyContactMergeResults();
    }

    @IsTest
    private static void merge1Org1OneToOneOne2One(){
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        merge1Org1OneToOne(CAO_Constants.ONE_TO_ONE_PROCESSOR);
    }

    @IsTest
    private static void merge1Org1OneToOneHHAccount(){
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        merge1Org1OneToOne(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    }

    //merge one contacts in the Individual Account, one in one-to-one model
    //the individual organization shouldn't be deleted
    private static void merge1Org1OneToOne(string strProcessor) {
        CON_ContactMerge_TEST.setContactSettings(strProcessor);
        Account acc = new Account(Name = 'Test Account 1');
        insert acc;

        Contact con = UTIL_UnitTestData_TEST.getContact();
        con.AccountId = acc.Id;
        
        Contact con2 = UTIL_UnitTestData_TEST.getContact();
        con2.LastName = '2Contact_forTests_Merge';

        insert new Contact[]{ con, con2 };

        CON_ContactMerge_TEST.setupSearchPage();
        CON_ContactMerge_TEST.setFixedSearchResults(2);
        CON_ContactMerge_TEST.controller.search();
        CON_ContactMerge_TEST.selectRecords(1, 0);
        CON_ContactMerge_TEST.controller.nextStep();
        CON_ContactMerge_TEST.selectMasterRecord();

        //merge them
        CON_ContactMerge_TEST.controller.mergeContacts();
        CON_ContactMerge_TEST.verifyMergeResults();
    }

    @IsTest
    private static void merge3OneToOneOne2One(){
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        merge3OneToOne(CAO_Constants.ONE_TO_ONE_PROCESSOR);
    }

    @IsTest
    private static void merge3OneToOneHHAccount(){
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        merge3OneToOne(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    }

    private static void merge3OneToOne(string strProcessor) {
        TDTM_DefaultConfig.startTestDataInit();
        CON_ContactMerge_TEST.defaultSetup(strProcessor);

        System.assertEquals(false, CON_ContactMerge_TEST.contactSettingsForTests.Household_Account_Addresses_Disabled__c, 'The disable addresses contact settings should be false.');

        TDTM_DefaultConfig.stopTestDataInit();

        if (strProcessor == CAO_Constants.HH_ACCOUNT_PROCESSOR) {
            System.assertEquals(3, [SELECT count() FROM Address__c], 'The addresses should have been created for the household account.');
        }
        CON_ContactMerge_TEST.setFixedSearchResults(3);
        CON_ContactMerge_TEST.controller.search();
        CON_ContactMerge_TEST.controller.searchResults[0].selected = true;
        CON_ContactMerge_TEST.controller.searchResults[1].selected = true;
        CON_ContactMerge_TEST.controller.searchResults[2].selected = true;
        List<Contact> losingContacts = new List<Contact>{ CON_ContactMerge_TEST.controller.searchResults[0].con, CON_ContactMerge_TEST.controller.searchResults[1].con };
        CON_ContactMerge_TEST.winningContact = CON_ContactMerge_TEST.controller.searchResults[2].con;
        CON_ContactMerge_TEST.controller.nextStep();
        CON_ContactMerge_TEST.selectMasterRecord();
        Test.startTest();
        CON_ContactMerge_TEST.controller.mergeContacts();
        // to flush our future calls that fix related data up!
        Test.stopTest();

        CON_ContactMerge_TEST.losingContact = losingContacts[0];
        CON_ContactMerge_TEST.verifyMergeResults();
        CON_ContactMerge_TEST.losingContact = losingContacts[1];
        CON_ContactMerge_TEST.verifyMergeResults();
        if (strProcessor == CAO_Constants.HH_ACCOUNT_PROCESSOR) {
            System.assertEquals(3, [SELECT count() FROM Address__c], 'All three addresses should still exist since the solo household accounts were merged.');
            System.assertEquals(1, [SELECT count() FROM Address__c WHERE Default_Address__c = true], 'Only one default should exist.');
        }
    }

    @IsTest
    private static void merge2OneToOneInSameAccountOne2One(){
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        merge2OneToOneInSameAccount(CAO_Constants.ONE_TO_ONE_PROCESSOR);
    }

    @IsTest
    private static void merge2OneToOneInSameAccountHHAccount(){
        merge2OneToOneInSameAccount(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    }

    //merge two contacts that are both in the one-to-one account model
    //the second contact's org should be deleted
    private static void merge2OneToOneInSameAccount(string strProcessor) {
        CON_ContactMerge_TEST.setContactSettings(strProcessor);

        Contact con = UTIL_UnitTestData_TEST.getContact();
        insert con;

        Id conAccountId = [SELECT accountId FROM Contact WHERE Id = :con.Id].AccountId;

        Contact con2 = UTIL_UnitTestData_TEST.getContact();
        con2.LastName = '2Contact_forTests_Merge';
        con2.AccountId = conAccountId;
        insert con2;

        CON_ContactMerge_TEST.setupSearchPage();
        CON_ContactMerge_TEST.setFixedSearchResults(2);
        CON_ContactMerge_TEST.controller.search();
        CON_ContactMerge_TEST.selectRecords(0, 1);
        CON_ContactMerge_TEST.controller.nextStep();

        CON_ContactMerge_TEST.selectMasterRecord();

        Test.startTest();
        CON_ContactMerge_TEST.controller.mergeContacts();
        Test.stopTest();

        CON_ContactMerge_TEST.verifyContactMergeResults();
    }

    /*******************************************************************************************************
    * @description Merge two Contacts in different Accounts and verifies Opps, OCRs, Rollups, and Names
    * are updated as appropriate for the account types.
    */ 
    @IsTest
    private static void testNamesAndOppsMergeHHToHH() {
        testNamesAndOppsMerge(CAO_Constants.HH_ACCOUNT_TYPE, CAO_Constants.HH_ACCOUNT_TYPE);
    }

    /*******************************************************************************************************
    * @description Merge two Contacts in different Accounts and verifies Opps, OCRs, Rollups, and Names
    * are updated as appropriate for the account types.
    */ 
    @IsTest
    private static void testNamesAndOppsMergeOne2OneToOne2One() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        testNamesAndOppsMerge(CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE, CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE);
    }

    /*******************************************************************************************************
    * @description Merge two Contacts in different Accounts and verifies Opps, OCRs, Rollups, and Names
    * are updated as appropriate for the account types.
    */ 
    @IsTest
    private static void testNamesAndOppsMergeOrgToHH() {
        testNamesAndOppsMerge(null, CAO_Constants.HH_ACCOUNT_TYPE);
    }

    /*******************************************************************************************************
    * @description Merge two Contacts in different Accounts and verifies Opps, OCRs, Rollups, and Names
    * are updated as appropriate for the account types.
    */ 
    @IsTest
    private static void testNamesAndOppsMergeHHToOrg() {
        testNamesAndOppsMerge(CAO_Constants.HH_ACCOUNT_TYPE, null);
    }

    /*******************************************************************************************************
    * @description Merge two Contacts in different Accounts and verifies Opps, OCRs, Rollups, and Names
    * are updated as appropriate for the account types.
    */ 
    @IsTest
    private static void testNamesAndOppsMergeOrgToOne2One() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        testNamesAndOppsMerge(null, CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE);
    }

    /*******************************************************************************************************
    * @description Merge two Contacts in different Accounts and verifies Opps, OCRs, Rollups, and Names
    * are updated as appropriate for the account types.
    */ 
    @IsTest
    private static void testNamesAndOppsMergeOne2OneToOrg() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        testNamesAndOppsMerge(CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE, null);
    }
    
    /*******************************************************************************************************
    * @description Merge two Contacts in different Accounts and verifies Opps, OCRs, Rollups, and Names
    * are updated as appropriate for the account types.
    */ 
    @isTest
    private static void testNamesAndOppsMergeOrgToOrg() {
        testNamesAndOppsMerge(null, null);
    }

    /*******************************************************************************************************
    * @description Merge two Contacts in different Accounts and verifies Opps, OCRs, Rollups, and Names
    * are updated as appropriate for the account types.
    */ 
    @isTest
    private static void testNamesAndOppsMergeOne2OneToHH() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        testNamesAndOppsMerge(CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE, CAO_Constants.HH_ACCOUNT_TYPE);
    }

    /*******************************************************************************************************
    * @description Merge two Contacts in different Accounts and verifies Opps, OCRs, Rollups, and Names
    * are updated as appropriate for the account types.
    */ 
    @isTest
    private static void testNamesAndOppsMergeHHToOne2One() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        testNamesAndOppsMerge(CAO_Constants.HH_ACCOUNT_TYPE, CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE);
    }

    /*******************************************************************************************************
    * @description Merge two Contacts in different Accounts and verifies Opps, OCRs, Rollups, and Names
    * are updated as appropriate for the account types.
    */ 
    @isTest
    private static void testNamesAndOppsMergeBucketToHH() {
        if (UTIL_UnitTestData_TEST.isAccountNameEncrypted()) return;

        testNamesAndOppsMerge(CAO_Constants.BUCKET_ORGANIZATION_TYPE, CAO_Constants.HH_ACCOUNT_TYPE);
    }

    /*******************************************************************************************************
    * @description Merge two Contacts in different Accounts and verifies Opps, OCRs, Rollups, and Names
    * are updated as appropriate for the account types.
    */ 
    @isTest
    private static void testNamesAndOppsMergeHHToBucket() {
        if (UTIL_UnitTestData_TEST.isAccountNameEncrypted()) return;

        testNamesAndOppsMerge(CAO_Constants.HH_ACCOUNT_TYPE, CAO_Constants.BUCKET_ORGANIZATION_TYPE);
    }

    /*******************************************************************************************************
    * @description Merge two Contacts in different Accounts and verifies Opps, OCRs, Rollups, and Names
    * are updated as appropriate for the account types.
    */ 
    @isTest
    private static void testNamesAndOppsMergeBucketToOne2One() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        if (UTIL_UnitTestData_TEST.isAccountNameEncrypted()) return;

        testNamesAndOppsMerge(CAO_Constants.BUCKET_ORGANIZATION_TYPE, CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE);
    }

    /*******************************************************************************************************
    * @description Merge two Contacts in different Accounts and verifies Opps, OCRs, Rollups, and Names
    * are updated as appropriate for the account types.
    */ 
    @isTest
    private static void testNamesAndOppsMergeOne2OneToBucket() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;
        
        if (UTIL_UnitTestData_TEST.isAccountNameEncrypted()) return;

        testNamesAndOppsMerge(CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE, CAO_Constants.BUCKET_ORGANIZATION_TYPE);
    }


    /*******************************************************************************************************
    * @description Merge two Contacts in different Accounts and verifies Opps, OCRs, Rollups, and Names
    *   the account's names and greetings are updated.
    *   Opps owned by the contact are moved over.
    *   Soft Credits for the moved Opps are recalculated.
    *   Soft Credits the contact previously had are still there.
    *   Opp Rollups are recalculated for both accounts.
    */
    public static void testNamesAndOppsMerge(string accTypeLoser, string accTypeWinner) {

        // most test cases want to have 2 contacts in each account.
        Integer cConLoser = 2;
        Integer cConWinner = 2;
        Integer iConLoser = 0;
        Integer iConLoserSibling = 1;
        Integer iConWinner = 2;
        Integer iConWinnerSibling = 3;
        Boolean isLoserAccountDeleted = false;
        
        // but when dealing with One2One accounts, they only should have one contact per account
        if (accTypeLoser == CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE) {
            cConLoser = 1;
            iConLoserSibling = 0;
            iConWinner = 1;
            iConWinnerSibling = 2;
            isLoserAccountDeleted = true;
        }
    
        // create our losing account and contacts
        UTIL_UnitTestData_TEST.createAccountContactTestData(accTypeLoser, 1, cConLoser, 1);
        Account accLoser = UTIL_UnitTestData_TEST.listAccT[0];
        list<Contact> listConAll = UTIL_UnitTestData_TEST.listConT; 
        
        // create our winning account and contacts
        UTIL_UnitTestData_TEST.createAccountContactTestData(accTypeWinner, 1, cConWinner, 3);
        Account accWinner = UTIL_UnitTestData_TEST.listAccT[0];
        listConAll.addAll(UTIL_UnitTestData_TEST.listConT);        
        
        // create an opp for each contact
        // note that for Org accounts, these Opps won't generate Soft Credits.
        list<Opportunity> listOpp = UTIL_UnitTestData_TEST.OppsForContactWithAccountList(listConAll, null, 
            UTIL_UnitTestData_TEST.getclosedWonStage(), System.Today(), 100, null, null);
        insert listOpp;
        
        // Merge the first contact in the first account to the first contact in the other account.
        Contact conWinner = listConAll[iConWinner];
        Contact conLoser = listConAll[iConLoser];        

        Test.setCurrentPageReference(new PageReference('Page.CON_ContactMerge'));        
        CON_ContactMerge_TEST.controller = new CON_ContactMerge_CTRL(new ApexPages.Standardsetcontroller(new list<Contact>()));
        
        CON_ContactMerge_TEST.controller.searchText = 'test';
        //SOSL always returns nothing in tests, unless you use the CON_ContactMerge_TEST.setFixedSearchResults value
        Id[] fixedSearchResults=new Id[2]; 
        fixedSearchResults[0]=conLoser.Id; 
        fixedSearchResults[1]=conWinner.Id; 
        
        Test.setFixedSearchResults(fixedSearchResults); 
        //search for contacts
        CON_ContactMerge_TEST.controller.search();
        //SELECT the two contacts and grab them
        CON_ContactMerge_TEST.controller.searchResults[0].selected = true;
        CON_ContactMerge_TEST.controller.searchResults[1].selected = true;
        
        //SELECT the second as winner
        CON_ContactMerge_TEST.controller.nextStep();        
        CON_ContactMerge_TEST.selectMasterRecord(conWinner.id);
        
        //list<OpportunityContactRole> listOCR = [SELECT Opportunity.Name, Contact.Name, Role, IsPrimary FROM OpportunityContactRole];
        //System.debug('****DJH listOCR before: ' + listOCR);

        //merge them
        Test.startTest();
        CON_ContactMerge_TEST.controller.mergeContacts();
        Test.stopTest();
        
        //listOCR = [SELECT Opportunity.Name, Contact.Name, Role, IsPrimary FROM OpportunityContactRole];
        //System.debug('****DJH listOCR after: ' + listOCR);

        // reload our contacts and accounts
        list<Account> listAcc = new list<Account>([SELECT Id, Name, npo02__Formal_Greeting__c, npo02__Informal_Greeting__c, 
            npo02__NumberOfClosedOpps__c, 
            BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry 
            FROM Account order by Id]);
        list<Contact> listCon = [SELECT Id, Firstname, Lastname, AccountId, 
            is_Address_Override__c, Current_Address__c, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry 
            FROM Contact order by Id];
            
        // verify the contacts belong to correct account.
        iConLoserSibling--;
        iConWinner--;
        iConWinnerSibling--;
        if (isLoserAccountDeleted) {
            System.assertEquals(1, listAcc.size());
            accLoser = new Account(npo02__Formal_Greeting__c='');
            System.assertEquals(accWinner.Id, listAcc[0].Id);
            accWinner = listAcc[0];
            System.assertEquals(2, listCon.size());
        } else {
            System.assertEquals(2, listAcc.size());
            System.assertEquals(accLoser.Id, listAcc[0].Id);
            accLoser = listAcc[0];
            System.assertEquals(accWinner.Id, listAcc[1].Id);
            accWinner = listAcc[1];
            System.assertEquals(3, listCon.size());
            System.assertEquals(listCon[iConLoserSibling].AccountId, accLoser.Id);
        }
        System.assertEquals(conWinner.Id, listCon[iConWinner].Id);
        conWinner = listCon[iConWinner];
        System.assertEquals(conWinner.AccountId, accWinner.Id);
        System.assertEquals(listCon[iConWinnerSibling].AccountId, accWinner.Id);
            
        // verify the account's names and greetings are updated
        if (accTypeLoser == CAO_Constants.HH_ACCOUNT_TYPE)
            System.assertEquals(false, accLoser.npo02__Formal_Greeting__c.contains(conLoser.Firstname));        
        if (accTypeWinner == CAO_Constants.HH_ACCOUNT_TYPE) {
            System.assertEquals(false, accWinner.npo02__Formal_Greeting__c.contains(conLoser.Firstname));
            System.assertEquals(true, accWinner.npo02__Formal_Greeting__c.contains(conWinner.Firstname));
        }                
        if (accTypeWinner == CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE)
            System.assertEquals(accWinner.name, conWinner.Firstname + ' ' + conWinner.Lastname);    
        
        Integer cAccLoserOpps = [SELECT count() FROM Opportunity where AccountId = :accLoser.Id];
        Integer cAccWinnerOpps = [SELECT count() FROM Opportunity where AccountId = :accWinner.Id];
        Integer cOCRLoserSibling = iConLoserSibling >= 0 ? 
            [SELECT count() FROM OpportunityContactRole where ContactId = :listCon[iConLoserSibling].Id] : 0;
        Integer cOCRConWinner = [SELECT count() FROM OpportunityContactRole where ContactId = :conWinner.Id];
        Integer cOCRWinnerSibling = [SELECT count() FROM OpportunityContactRole where ContactId = :listCon[iConWinnerSibling].Id];
        
        // verify Opps, OCR's, and Rollups are what we expect!
        if (accTypeLoser == CAO_Constants.HH_ACCOUNT_TYPE && accTypeWinner == CAO_Constants.HH_ACCOUNT_TYPE) {
            System.assertEquals(1, cAccLoserOpps);
            System.assertEquals(3, cAccWinnerOpps);
            System.assertEquals(1, cOCRLoserSibling);
            System.assertEquals(3, cOCRConWinner);
            System.assertEquals(3, cOCRWinnerSibling);
            System.assertEquals(1, accLoser.npo02__NumberOfClosedOpps__c);            
            System.assertEquals(3, accWinner.npo02__NumberOfClosedOpps__c);            
        }
        else if (accTypeLoser == CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE && accTypeWinner == CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE) {
            System.assertEquals(0, cAccLoserOpps);
            System.assertEquals(3, cAccWinnerOpps);
            System.assertEquals(0, cOCRLoserSibling);
            System.assertEquals(2, cOCRConWinner);
            System.assertEquals(1, cOCRWinnerSibling);
            System.assertEquals(null, accLoser.npo02__NumberOfClosedOpps__c);            
            System.assertEquals(3, accWinner.npo02__NumberOfClosedOpps__c);            
        }
        else if (accTypeLoser == null && accTypeWinner == CAO_Constants.HH_ACCOUNT_TYPE) {
            System.assertEquals(2, cAccLoserOpps);
            System.assertEquals(2, cAccWinnerOpps);
            System.assertEquals(1, cOCRLoserSibling);
            System.assertEquals(3, cOCRConWinner);
            System.assertEquals(2, cOCRWinnerSibling);
            System.assertEquals(2, accLoser.npo02__NumberOfClosedOpps__c);            
            System.assertEquals(2, accWinner.npo02__NumberOfClosedOpps__c);            
        }
        else if (accTypeLoser == CAO_Constants.HH_ACCOUNT_TYPE && accTypeWinner == null) {
            System.assertEquals(2, cAccLoserOpps);
            System.assertEquals(2, cAccWinnerOpps);
            System.assertEquals(1, cOCRLoserSibling);
            System.assertEquals(2, cOCRConWinner);
            System.assertEquals(1, cOCRWinnerSibling);
            System.assertEquals(2, accLoser.npo02__NumberOfClosedOpps__c);            
            System.assertEquals(2, accWinner.npo02__NumberOfClosedOpps__c);            
        }
        else if (accTypeLoser == null && accTypeWinner == CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE) {
            System.assertEquals(2, cAccLoserOpps);
            System.assertEquals(2, cAccWinnerOpps);
            System.assertEquals(1, cOCRLoserSibling);
            System.assertEquals(2, cOCRConWinner);
            System.assertEquals(1, cOCRWinnerSibling);
            System.assertEquals(2, accLoser.npo02__NumberOfClosedOpps__c);            
            System.assertEquals(2, accWinner.npo02__NumberOfClosedOpps__c);            
        }
        else if (accTypeLoser == CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE && accTypeWinner == null) {
            System.assertEquals(0, cAccLoserOpps);
            System.assertEquals(3, cAccWinnerOpps);
            System.assertEquals(0, cOCRLoserSibling);
            System.assertEquals(2, cOCRConWinner);
            System.assertEquals(1, cOCRWinnerSibling);
            System.assertEquals(null, accLoser.npo02__NumberOfClosedOpps__c);            
            System.assertEquals(3, accWinner.npo02__NumberOfClosedOpps__c);            
        }
        else if (accTypeLoser == null && accTypeWinner == null) {
            System.assertEquals(2, cAccLoserOpps);
            System.assertEquals(2, cAccWinnerOpps);
            System.assertEquals(1, cOCRLoserSibling);
            System.assertEquals(2, cOCRConWinner);
            System.assertEquals(1, cOCRWinnerSibling);
            System.assertEquals(2, accLoser.npo02__NumberOfClosedOpps__c);            
            System.assertEquals(2, accWinner.npo02__NumberOfClosedOpps__c);            
        }
        else if (accTypeLoser == CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE && accTypeWinner == CAO_Constants.HH_ACCOUNT_TYPE) {
            System.assertEquals(0, cAccLoserOpps);
            System.assertEquals(3, cAccWinnerOpps);
            System.assertEquals(0, cOCRLoserSibling);
            System.assertEquals(3, cOCRConWinner);
            System.assertEquals(3, cOCRWinnerSibling);
            System.assertEquals(null, accLoser.npo02__NumberOfClosedOpps__c);            
            System.assertEquals(3, accWinner.npo02__NumberOfClosedOpps__c);            
        }
        else if (accTypeLoser ==  CAO_Constants.HH_ACCOUNT_TYPE && accTypeWinner == CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE) {
            System.assertEquals(1, cAccLoserOpps);
            System.assertEquals(3, cAccWinnerOpps);
            System.assertEquals(1, cOCRLoserSibling);
            System.assertEquals(2, cOCRConWinner);
            System.assertEquals(1, cOCRWinnerSibling);
            System.assertEquals(1, accLoser.npo02__NumberOfClosedOpps__c);            
            System.assertEquals(3, accWinner.npo02__NumberOfClosedOpps__c);            
        }
        else if (accTypeLoser == CAO_Constants.BUCKET_ORGANIZATION_TYPE && accTypeWinner == CAO_Constants.HH_ACCOUNT_TYPE) {
            System.assertEquals(1, cAccLoserOpps);
            System.assertEquals(3, cAccWinnerOpps);
            System.assertEquals(1, cOCRLoserSibling);
            System.assertEquals(3, cOCRConWinner);
            System.assertEquals(3, cOCRWinnerSibling);
            System.assertEquals(0, accLoser.npo02__NumberOfClosedOpps__c);            
            System.assertEquals(3, accWinner.npo02__NumberOfClosedOpps__c);            
        }
        else if (accTypeLoser == CAO_Constants.HH_ACCOUNT_TYPE && accTypeWinner == CAO_Constants.BUCKET_ORGANIZATION_TYPE) {
            System.assertEquals(1, cAccLoserOpps);
            System.assertEquals(3, cAccWinnerOpps);
            System.assertEquals(1, cOCRLoserSibling);
            System.assertEquals(2, cOCRConWinner);
            System.assertEquals(1, cOCRWinnerSibling);
            System.assertEquals(1, accLoser.npo02__NumberOfClosedOpps__c);            
            System.assertEquals(0, accWinner.npo02__NumberOfClosedOpps__c);            
        }
        else if (accTypeLoser == CAO_Constants.BUCKET_ORGANIZATION_TYPE && accTypeWinner == CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE) {
            System.assertEquals(1, cAccLoserOpps);
            System.assertEquals(3, cAccWinnerOpps);
            System.assertEquals(1, cOCRLoserSibling);
            System.assertEquals(2, cOCRConWinner);
            System.assertEquals(1, cOCRWinnerSibling);
            System.assertEquals(0, accLoser.npo02__NumberOfClosedOpps__c);            
            System.assertEquals(3, accWinner.npo02__NumberOfClosedOpps__c);            
        }
        else if (accTypeLoser == CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE && accTypeWinner == CAO_Constants.BUCKET_ORGANIZATION_TYPE) {
            System.assertEquals(0, cAccLoserOpps);
            System.assertEquals(3, cAccWinnerOpps);
            System.assertEquals(0, cOCRLoserSibling);
            System.assertEquals(2, cOCRConWinner);
            System.assertEquals(1, cOCRWinnerSibling);
            System.assertEquals(null, accLoser.npo02__NumberOfClosedOpps__c);            
            System.assertEquals(0, accWinner.npo02__NumberOfClosedOpps__c);            
        }
        
    }

}