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
* @date 2011 (2.x)
* @description Tests for CON_ContactMerge_CTRL
* @group ContactMerge
* @group-content ../../ApexDocContent/ContactMerge.htm
*/
@isTest
public class CON_ContactMerge_TEST {
    public static npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests;
    public static CON_ContactMerge_CTRL controller;
    private static List<Contact> contacts;
    private static Contact winningContact;
    private static Contact losingContact;

    @IsTest
    private static void exerciseUIOne2One(){
        exerciseUI(CAO_Constants.ONE_TO_ONE_PROCESSOR);
    }

    @IsTest
    private static void exerciseUIHHAccount(){
        exerciseUI(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    }

    //exercise the many UI variables
    private static void exerciseUI(String strProcessor) {
        defaultSetup(strProcessor);

        Test.startTest();
        controller.search();
        System.assert(controller.searchResults.isEmpty(), 'search results should be empty and should not be displayed');

        //call the search method, which will return the bogus SOSL results
        setFixedSearchResults(3);
        controller.search();
        System.assert(!controller.searchResults.isEmpty(), 'Search results should be displayed');
        System.assertEquals(3,controller.searchResults.size(), 'Expected 3 contacts to be returned.');

        controller.searchResults[0].selected = true;
        controller.nextStep();
        verifyError(label.npe01.Contact_Merge_Error_Too_Few_Contacts, 2);

        controller.search();
        selectRecords(0, 1);
        controller.nextStep();
        Test.stopTest();
        System.assertEquals(3, controller.step, 'Expected to be on the third step.');

        List<CON_ContactMerge_CTRL.FieldRow> fieldRows = controller.fieldRows;
        for (CON_ContactMerge_CTRL.FieldRow row : fieldRows) {
            if (row.fieldName.equals('Master')) {
                System.assert(row.showRadio);
                System.assertEquals(winningContact.Id, row.selectedValue, 'Test records Ids are always created in alphabetical order, the 2nd contact should be selected by default.');
            }

            if (row.fieldName.equalsIgnoreCase('FirstName')) {
                System.assert(!row.showRadio, 'The contacts have the same first name, the radio button should not be displayed.');
            }

            if (row.fieldName.equalsIgnoreCase('HomePhone')) {
                System.assert(row.showRadio, 'The home phone numbers are not the same, expect the radio button to be displayed.');
                System.assertEquals(winningContact.Id, row.selectedValue, 'The losing contact does not have a home phone, expect the winning contact bubble to be selected.');
            }
        }

        // Test select all for a record
        ApexPages.currentPage().getParameters().put('recordId', winningContact.Id);
        controller.selectDefaultRecord();

        for (CON_ContactMerge_CTRL.FieldRow row : fieldRows) {
            if (row.showRadio) {
                System.assertEquals(winningContact.Id, row.selectedValue, 'Expected the selected record id to match the winning contact.');
            }
        }
    }

    @IsTest
    private static void failNextStepWithDeletedRecordSelectedOne2One(){
        failNextStepWithDeletedRecordSelected(CAO_Constants.ONE_TO_ONE_PROCESSOR);
    }

    @IsTest
    private static void failNextStepWithDeletedRecordSelectedHHAccount(){
        failNextStepWithDeletedRecordSelected(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    }

    // Try selecting a deleted record for merge
    static void failNextStepWithDeletedRecordSelected(string strProcessor) {
        defaultSetup(strProcessor);
        setFixedSearchResults(2);

        Test.startTest();
        //call the search method, which will return the bogus SOSL results
        controller.search();
        System.assertEquals(2, controller.searchResults.size(), 'Expected 2 contacts to be returned.');

        selectRecords(0, 1);
        delete losingContact;
        controller.nextStep();
        verifyError(label.npe01.Contact_Merge_Error_Query_Failed + ' ' + label.npe01.Contact_Merge_Error_please_retry, 2);
        Test.stopTest();
    }

    @IsTest
    private static void failMergeWithDeletedRecordSelectedOne2One(){
        failMergeWithDeletedRecordSelected(CAO_Constants.ONE_TO_ONE_PROCESSOR);
    }

    @IsTest
    private static void failMergeWithDeletedRecordSelectedHHAccount(){
        failMergeWithDeletedRecordSelected(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    }

    // Try selecting a deleted record for merge
    private static void failMergeWithDeletedRecordSelected(string strProcessor) {
        setContactSettings(strProcessor);
        createContacts();
        Test.startTest();
        setupSearchPage();
        setFixedSearchResults(2);

        controller.search();
        System.assertEquals(2,controller.searchResults.size(), 'Expected 2 contacts to be returned.');
        Contact deletedContact = controller.searchResults[0].con;
        selectRecords(0, 1);
        controller.nextStep();
        delete losingContact;
        controller.mergeContacts();
        verifyError(label.npe01.Contact_Merge_Error_Lock_failed + ' ' + label.npe01.Contact_Merge_Error_please_retry, 3);
        Test.stopTest();
    }

    @IsTest
    private static void tooFewContactsSelectedOne2One(){
        tooFewContactsSelected(CAO_Constants.ONE_TO_ONE_PROCESSOR);
    }

    @IsTest
    private static void tooFewContactsSelectedHHAccount(){
        tooFewContactsSelected(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    }

    private static void tooFewContactsSelected(string strProcessor) {
        defaultSetup(strProcessor);
        setFixedSearchResults(1);
        //call the search method, which will return the bogus SOSL results
        controller.search();
        controller.searchResults[0].selected = true;
        controller.nextStep();
        verifyError(label.npe01.Contact_Merge_Error_Too_Few_Contacts, 2);
    }

    @IsTest
    private static void tooManyContactsSelectedOne2One(){
        tooManyContactsSelected(CAO_Constants.ONE_TO_ONE_PROCESSOR);
    }

    @IsTest
    private static void tooManyContactsSelectedHHAccount(){
        tooManyContactsSelected(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    }

    private static void tooManyContactsSelected(string strProcessor) {
        defaultSetup(strProcessor);
        setFixedSearchResults(4);

        controller.searchText = 'test';
        //call the search method, which will return the bogus SOSL results
        controller.search();
        controller.searchResults[0].selected = true;
        controller.searchResults[1].selected = true;
        controller.searchResults[2].selected = true;
        controller.searchResults[3].selected = true;
        controller.nextStep();

        verifyError(label.npe01.Contact_Merge_Error_Too_Many_Contacts, 2);
    }

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
    private static void merge2OneToOne(string strProcessor) {
        defaultSetup(strProcessor);
        setFixedSearchResults(2);
        controller.search();
        //select the two contacts and grab them
        controller.searchResults[0].selected = true;
        controller.searchResults[1].selected = true;
        losingContact = controller.searchResults[0].con;
        winningContact = controller.searchResults[1].con;
        controller.nextStep();
        selectMasterRecord(controller, winningContact.Id);
        controller.mergeContacts();
        verifyMergeResults(losingContact, winningContact);
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
    private static void merge2OneToOneOpps(string strProcessor) {
        TDTM_DefaultConfig.startTestDataInit();
        setContactSettings(strProcessor);

        String newContactMailingStreet = '123 Elm St';
        createContacts();
        setupSearchPage();
        setFixedSearchResults(2);
        controller.search();
        selectRecords(0, 1);

        insert new Opportunity(AccountId = losingContact.accountId, Amount = 500, Name = 'test', StageName = 'Closed Won', CloseDate = System.today());
        controller.nextStep();
        selectMasterRecord(controller, winningContact.Id);
        //merge them
        TDTM_DefaultConfig.stopTestDataInit();
        Test.startTest();
        controller.mergeContacts();
        Test.stopTest();

        verifyMergeResults(losingContact, winningContact);
        System.assertEquals(1, [SELECT count() FROM Opportunity WHERE accountId = :winningContact.AccountId], 'The Opportunity should be moved.');
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
    static void merge2Organizations(string strProcessor) {
        setContactSettings(strProcessor);
        Account acc = new Account(Name = 'Test merge org Account 1');
        Account acc2 = new Account(Name = 'Test merge org Account 2');
        insert new Account[]{ acc, acc2 };

        winningContact = UTIL_UnitTestData_TEST.getContact();
        winningContact.AccountId = acc.Id;
        losingContact = UTIL_UnitTestData_TEST.getContact();
        losingContact.LastName = '2Contact_forTests_Merge';
        losingContact.AccountId = acc2.Id;
        insert new Contact[]{ winningContact, losingContact };
        setupSearchPage();
        setFixedSearchResults(2);
        controller.search();
        controller.searchResults[0].selected = true;
        controller.searchResults[1].selected = true;
        controller.nextStep();
        selectMasterRecord(controller, winningContact.id);
        controller.mergeContacts();
        verifyContactMergeResults(losingContact, winningContact);
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
    private static void merge2PrivateContacts(string strProcessor) {
        setContactSettings(strProcessor);
        winningContact = UTIL_UnitTestData_TEST.getContact();
        winningContact.npe01__Private__c = true;

        losingContact = UTIL_UnitTestData_TEST.getContact();
        losingContact.LastName = '2Contact_forTests_Merge';
        losingContact.npe01__Private__c = true;
        insert new Contact[]{ winningContact, losingContact };

        setupSearchPage();
        setFixedSearchResults(2);
        controller.search();
        controller.searchResults[0].selected = true;
        controller.searchResults[1].selected = true;
        controller.nextStep();
        selectMasterRecord(controller, winningContact.Id);
        controller.mergeContacts();
        verifyContactMergeResults(losingContact, winningContact);
    }

    //merge two contacts in the Individual Account
    //the organization shouldn't be deleted
    @IsTest
    private static void merge2Individuals() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        setContactSettings(CAO_Constants.BUCKET_PROCESSOR);
        createContacts();
        System.assertEquals(1, [SELECT count() FROM Account], 'The bucket account should be the only account.');
        setupSearchPage(); 
        setFixedSearchResults(2);
        controller.search();
        controller.searchResults[0].selected = true;
        controller.searchResults[1].selected = true;
        controller.nextStep();
        selectMasterRecord(controller, contacts[0].Id);
        //merge them
        controller.mergeContacts();
        verifyContactMergeResults(contacts[1], contacts[0]);
        System.assertEquals(1, [SELECT count() FROM Account], 'The bucket account should not be deleted.');
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
        setContactSettings(strProcessor);
        Account acc = new Account(Name = 'Test Account 1');
        insert acc;
        winningContact = UTIL_UnitTestData_TEST.getContact();
        winningContact.AccountId = acc.Id;
        losingContact = UTIL_UnitTestData_TEST.getContact();
        losingContact.LastName = '2Contact_forTests_Merge';
        insert new Contact[]{ winningContact, losingContact };

        setupSearchPage();
        setFixedSearchResults(2);
        controller.search();
        selectRecords(0, 1);
        controller.nextStep();
        selectMasterRecord(controller, winningContact.id);
        
        //merge them
        controller.mergeContacts();
        verifyMergeResults(losingContact, winningContact);
    }

    //Helpers
    /////////////

    // Used to similute clicking the master record bubble on the page in the UI
    public static void selectMasterRecord(CON_ContactMerge_CTRL cont, Id masterId) {
        for (CON_ContactMerge_CTRL.FieldRow row : cont.fieldRows) {
            if (row.showRadio) {
                row.selectedValue = String.valueOf(masterId);
            }
        }
    }

    // Creates an instance of custom settings that will be used by other classes for the test execution
    // and sets the Account Processor to the string provided
    public static void setContactSettings(String strProcessor) {
        contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_and_Orgs_Settings__c (npe01__Account_Processor__c = strProcessor)
        );
    }

    public static void createContacts() {
        //set up 4 contacts for the merge interface to work with
        Contact con = UTIL_UnitTestData_TEST.getContact();
        con.FirstName = 'Merge';
        con.MailingStreet = '123 45th St';
        con.MailingCity = 'Seattle';

        Contact con2 = UTIL_UnitTestData_TEST.getContact();
        con2.FirstName = 'Merge';
        con2.LastName = 'Simpson ' + '2' + String.valueOf(Math.random());
        con2.MailingStreet = '678 90th St';
        con2.MailingCity = 'Bellevue';
        con2.HomePhone = '867-5309';

        Contact con3 = UTIL_UnitTestData_TEST.getContact();
        con3.FirstName = 'Merge';
        con3.LastName = 'Simpson ' + '3' + String.valueOf(Math.random());
        con3.MailingStreet = '999 88th St';
        con3.MailingCity = 'Redmond';

        Contact con4 = UTIL_UnitTestData_TEST.getContact();
        con4.FirstName = 'Merge';
        con4.LastName  = 'Simpson ' + '2' + String.valueOf(Math.random());

        insert new Contact[]{ con, con2, con3, con4 };
    }

    // In test classes the contacts will always be returned in creation order when sorted by Id.
    private static void getContacts(Integer size) {
        contacts = new List<Contact>([SELECT Id, AccountId, FirstName, LastName, MailingStreet FROM Contact ORDER BY Id LIMIT :size]);
    }

    public static void defaultSetup(String strProcessor) {
        setContactSettings(strProcessor);
        createContacts();
        setupSearchPage();
    }

    // SOSL will not find any records created in the test execution, we need to tell it
    // what to find
    public static void setFixedSearchResults(Integer size) {
        getContacts(size);
        Id[] fixedSearchResults = new Id[contacts.size()];

        for (Integer index = 0; index < contacts.size(); index++) {
            fixedSearchResults[index] = contacts[index].Id;
        }

        Test.setFixedSearchResults(fixedSearchResults);
    }

    public static void setupSearchPage() {
        Test.setCurrentPageReference(new PageReference('Page.CON_ContactMerge'));
        controller = new CON_ContactMerge_CTRL(new ApexPages.Standardsetcontroller(new list<Contact>()));
        controller.searchText = 'test';
    }

    private static void selectRecords(Integer losingIndex, Integer winningIndex) {
        controller.searchResults[losingIndex].selected = true;
        controller.searchResults[winningIndex].selected = true;
        losingContact = controller.searchResults[losingIndex].con;
        winningContact = controller.searchResults[winningIndex].con;
    }

    public static void verifyMergeResults(Contact losingContact, Contact winningContact) {
        verifyContactMergeResults(losingContact, winningContact);
        verifyAccountMergeResults(losingContact, winningContact);
    }

    public static void verifyContactMergeResults(Contact losingContact, Contact winningContact) {
        System.assertEquals(1, [SELECT count() FROM Contact WHERE Id = :winningContact.Id], 'The winning contact should remain.');
        System.assertEquals(0, [SELECT count() FROM Contact WHERE Id = :losingContact.Id], 'The losing contact should be deleted.');
        System.assertEquals(winningContact.AccountId, [SELECT AccountId FROM Contact WHERE id = :winningContact.Id].AccountId, 'The winning contacts account should not have changed.');
    }

    private static void verifyAccountMergeResults(Contact losingContact, Contact winningContact) {
        System.assertEquals(1, [SELECT count() FROM Account WHERE Id = :winningContact.AccountId], 'The winnings contacts account should not be deleted.');
        System.assertEquals(0, [SELECT count() FROM Account WHERE Id = :losingContact.accountId], 'The losing contacts account should be deleted.');
    }

    private static void verifyError(String error, Integer step) {
        System.assertEquals(1, ApexPages.getMessages().size()); // Selecting only one record for merge should throw an error.
        ApexPages.Message m = ApexPages.getMessages()[0];
        System.assertEquals(ApexPages.Severity.Error, m.getSeverity());
        System.assertEquals(error, m.getDetail());
        System.assertEquals(step, controller.step, 'The controller is not at the step expected.');
    }
}