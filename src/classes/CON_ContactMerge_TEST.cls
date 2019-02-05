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
    public static Contact winningContact;
    public static Contact losingContact;

    @TestSetup
    static void createHouseholdContacts() {
        setContactSettings(CAO_Constants.HH_ACCOUNT_PROCESSOR);
        createContacts();
    }

    @IsTest
    private static void emptyListReturnedWhenSearchTermNotProvided() {
        setupSearchPage();

        controller.search();
        System.assert(controller.searchResults.isEmpty(), 'search results should be empty and should not be displayed');
    }

    @IsTest
    private static void searchResultsReturned() {
        setupSearchPage();
        setFixedSearchResults(3);

        controller.search();
        System.assert(!controller.searchResults.isEmpty(), 'Search results should be displayed');
        System.assertEquals(3, controller.searchResults.size(), 'Expected 3 contacts to be returned.');
    }

    @IsTest
    private static void nextStepSucceedsWhenTwoContactsAreSelected() {
        setupSearchPage();
        setFixedSearchResults(2);

        controller.search();
        selectRecords(0, 1);

        controller.nextStep();
        verifyStep(3);
    }

    @IsTest
    private static void fieldRowsReturnedWithDefaultSelections() {
        setupSearchPage();
        setFixedSearchResults(2);
        controller.search();
        selectRecords(0, 1);

        controller.nextStep();

        for (CON_ContactMerge_CTRL.FieldRow row : controller.fieldRows) {
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
    }

    @IsTest
    private static void recordSelectedByDefaultWhenPassedInUrlParameter() {
        setupSearchPage();
        setFixedSearchResults(2);
        controller.search();
        selectRecords(0, 1);
        ApexPages.currentPage().getParameters().put('recordId', winningContact.Id);

        controller.selectDefaultRecord();

        for (CON_ContactMerge_CTRL.FieldRow row : controller.fieldRows) {
            if (row.showRadio) {
                System.assertEquals(winningContact.Id, row.selectedValue, 'Expected the selected record to match the winning contact.');
            }
        }
    }

    @IsTest
    private static void nextStepDisplaysErrorWhenOnlyOneContactSelected() {
        setupSearchPage();
        setFixedSearchResults(2);

        controller.search();
        controller.searchResults[0].selected = true;
        controller.nextStep();
        verifyError(label.npe01.Contact_Merge_Error_Too_Few_Contacts, 2);
    }

    @IsTest
    private static void nextStepDisplaysErrorWhenMoreThanThreeContactsAreSelected() {
        setupSearchPage();
        setFixedSearchResults(4);
        controller.search();
        controller.searchResults[0].selected = true;
        controller.searchResults[1].selected = true;
        controller.searchResults[2].selected = true;
        controller.searchResults[3].selected = true;

        controller.nextStep();
        verifyError(label.npe01.Contact_Merge_Error_Too_Many_Contacts, 2);
    }

    @IsTest
    private static void nextStepDisplaysErrorWhenDeletedContactSelected() {
        setupSearchPage();
        setFixedSearchResults(2);
        controller.search();
        selectRecords(0, 1);
        delete losingContact;

        Test.startTest();
        controller.nextStep();
        verifyError(label.npe01.Contact_Merge_Error_Query_Failed + ' ' + label.npe01.Contact_Merge_Error_please_retry, 2);
        Test.stopTest();
    }

    @IsTest
    private static void mergeDisplaysErrorWhenDeletedContactSelected() {
        setupSearchPage();
        setFixedSearchResults(2);
        controller.search();
        selectRecords(0, 1);
        controller.nextStep();
        delete losingContact;

        Test.startTest();
        controller.mergeContacts();
        verifyError(label.npe01.Contact_Merge_Error_Lock_failed + ' ' + label.npe01.Contact_Merge_Error_please_retry, 3);
        Test.stopTest();
    }

    @IsTest
    private static void contactsSelectedWhenStandardSetControllerProvidesRecords() {
        setContacts(2);
        Test.setCurrentPageReference(new PageReference('Page.CON_ContactMerge'));
        ApexPages.Standardsetcontroller stdSetCtrl = new ApexPages.Standardsetcontroller(contacts);
        stdSetCtrl.setSelected(contacts);

        controller = new CON_ContactMerge_CTRL(stdSetCtrl);
        verifyStep(3);
        System.assertEquals(2, controller.selectedRecordsCount, 'The records selected on the standard set controller should be selected.');
        System.assert(!controller.fieldRows.isEmpty(), 'The fields should be populated.');
    }

    @IsTest
    private static void searchPerformedWhenSrchUrlParameterIsProvided() {
        PageReference pageRef = Page.CON_ContactMerge;
        pageRef.getParameters().put('srch', 'O\'Sullivan');
        Test.setCurrentPageReference(pageRef);
        setFixedSearchResults(2);

        controller = new CON_ContactMerge_CTRL(new ApexPages.Standardsetcontroller(new List<Contact>()));
        verifyStep(2);
        System.assertEquals(2, controller.searchResults.size(), 'The search results should be populated with the search results.');
    }

    @IsTest
    private static void contactsSelectedWhenMergeIdsUrlParameterIsProvided(){
        setContacts(2);
        PageReference pageRef = Page.CON_ContactMerge;
        pageRef.getParameters().put('mergeIds', contacts[0].Id + ',' + contacts[1].Id);
        Test.setCurrentPageReference(pageRef);

        controller = new CON_ContactMerge_CTRL(new ApexPages.Standardsetcontroller(new List<Contact>()));
        verifyStep(3);
        System.assertEquals(2, controller.selectedRecordsCount, 'The records passed in should be selected.');
        System.assert(!controller.fieldRows.isEmpty(), 'The fields should be populated.');
    }

    @IsTest
    private static void errorDisplayedWhenMergeIdsURLParameterIsInvalid(){
        setContacts(2);
        PageReference pageRef = Page.CON_ContactMerge;
        pageRef.getParameters().put('mergeIds', 'blah');
        Test.setCurrentPageReference(pageRef);

        controller = new CON_ContactMerge_CTRL(new ApexPages.Standardsetcontroller(contacts));
        verifyStep(1);
        System.assert(ApexPages.hasMessages(), 'An error should be displayed.');
    }

    @IsTest
    private static void errorDisplayedWhenPersonAccountDetected() {
        Boolean isPersonAccountEnabled = UTIL_Describe.isValidField('Account', 'isPersonAccount');
        if (!isPersonAccountEnabled) {
            return;
        }

        setContactSettings(CAO_Constants.ONE_TO_ONE_PROCESSOR);
        RecordType personAccountRecordType =  [SELECT Id FROM RecordType WHERE DeveloperName = 'PersonAccount' and SObjectType = 'Account'];

        Account pa1 = new Account();
        pa1.put('FirstName', 'Fred');
        pa1.put('LastName', 'Smith');
        pa1.RecordType = personAccountRecordType;
        insert pa1;

        Account pa2 = new Account();
        pa2.put('FirstName', 'Freddy');
        pa2.put('LastName', 'Smith');
        pa2.RecordType = personAccountRecordType;
        insert pa2;
        List<Id> personAccountIds = new List<Id>{ pa1.Id, pa2.Id };

        Test.setFixedSearchResults(personAccountIds);

        PageReference pageRef = Page.CON_ContactMerge;
        pageRef.getParameters().put('mergeIds', pa1.Id + ',' + pa2.Id);
        Test.setCurrentPageReference(pageRef);

        controller = new CON_ContactMerge_CTRL(new ApexPages.Standardsetcontroller(new List<Contact>()));
        verifyStep(1);
        selectMasterRecord(pa1.id);

        controller.mergeContacts();
        System.assert(ApexPages.hasMessages(), 'Expected the page to display an error.');
        System.assertEquals(2, [SELECT count() FROM Account WHERE Id IN :personAccountIds], 'Expected both accounts to remain.'); 
    }

    @IsTest
    private static void mergeSucceedsWithNameWithAnApostrophe() {
        Contact con = UTIL_UnitTestData_TEST.getContact();
        con.LastName = 'O\'Sullivan';

        Contact con2 = UTIL_UnitTestData_TEST.getContact();
        con2.LastName = 'O\'Sullivan';

        contacts = new List<Contact>{ con, con2 };
        insert contacts;


        setupSearchPage();
        setFixedSearchResults(UTIL_UnitTestData_TEST.extractIds(contacts));
        controller.searchText = 'O\'Sullivan';
        controller.search();
        selectRecords(0, 1);
        System.assertEquals(winningContact.LastName, 'O\'Sullivan', 'Verify the apostrophe is in the last name.');
        controller.nextStep();
        selectMasterRecord();

        controller.mergeContacts();
        verifyContactMergeResults();
    }


    //Helpers
    /////////////

    /*******************************************************************************************************************
     * @description Used to similute clicking the master record bubble on the page in the UI.
     */
    public static void selectMasterRecord(Id masterId) {
        for (CON_ContactMerge_CTRL.FieldRow row : controller.fieldRows) {
            if (row.showRadio) {
                row.selectedValue = String.valueOf(masterId);
            }
        }
    }

    public static void selectMasterRecord() {
        selectMasterRecord(winningContact.Id);
    }

    /*******************************************************************************************************************
     * @description Creates an instance of custom settings that will be used by other classes for the test execution
     * and sets the Account Processor to the string provided
     */
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

    /*******************************************************************************************************************
     * @description In test classes the contacts will always be returned in creation order when sorted by Id.
     */
    private static void setContacts(Integer size) {
        contacts = new List<Contact>([
            SELECT Id, AccountId, FirstName, LastName, MailingStreet, npo02__household__c
            FROM Contact ORDER BY Id LIMIT :size
        ]);
    }

    /*******************************************************************************************************************
     * @description In test classes the contacts will always be returned in creation order when sorted by Id.
     */
    private static void setContacts(Set<Id> ids) {
        contacts = new List<Contact>([
            SELECT Id, AccountId, FirstName, LastName, MailingStreet, npo02__household__c
            FROM Contact WHERE Id IN :ids ORDER BY Id
        ]);
    }

    public static void defaultSetup(String strProcessor) {
        setContactSettings(strProcessor);
        createContacts();
        setupSearchPage();
        setFixedSearchResults(2);
    }

    /*******************************************************************************************************************
     * @description The search method uses SOSL to find records that match, SOSL cannot be tested directly and must
     * be told what to return.
     */
    public static void setFixedSearchResults(Integer size) {
        setContacts(size);
        setFixedSearchResults();
    }

    private static void setFixedSearchResults(Set<Id> contactIds) {
        setContacts(contactIds);
        setFixedSearchResults();
    }

    private static void setFixedSearchResults() {
        List<Id> fixedSearchResults = new List<Id>();

        for (Contact record : contacts) {
            fixedSearchResults.add(record.Id);
        }

        Test.setFixedSearchResults(fixedSearchResults);
    }

    public static void setupSearchPage() {
        Test.setCurrentPageReference(new PageReference('Page.CON_ContactMerge'));
        controller = new CON_ContactMerge_CTRL(new ApexPages.Standardsetcontroller(new List<Contact>()));
        controller.searchText = 'test';
    }

    public static void selectRecords(Integer losingIndex, Integer winningIndex) {
        controller.searchResults[losingIndex].selected = true;
        controller.searchResults[winningIndex].selected = true;
        losingContact = contacts[losingIndex];
        winningContact = contacts[winningIndex];
    }

    public static void verifyMergeResults() {
        verifyContactMergeResults();
        verifyAccountMergeResults();
    }

    public static void verifyContactMergeResults() {
        System.assertEquals(1, [SELECT count() FROM Contact WHERE Id = :winningContact.Id], 'The winning contact should remain.');
        System.assertEquals(0, [SELECT count() FROM Contact WHERE Id = :losingContact.Id], 'The losing contact should be deleted.');
        System.assertEquals(winningContact.AccountId, [SELECT AccountId FROM Contact WHERE id = :winningContact.Id].AccountId, 'The winning contacts account should not have changed.');
    }

    private static void verifyAccountMergeResults() {
        System.assertEquals(1, [SELECT count() FROM Account WHERE Id = :winningContact.AccountId], 'The winnings contacts account should not be deleted.');
        System.assertEquals(0, [SELECT count() FROM Account WHERE Id = :losingContact.accountId], 'The losing contacts account should be deleted.');
    }

    private static void verifyError(String error, Integer step) {
        System.assertEquals(1, ApexPages.getMessages().size()); // Selecting only one record for merge should throw an error.
        ApexPages.Message m = ApexPages.getMessages()[0];
        System.assertEquals(ApexPages.Severity.Error, m.getSeverity());
        System.assertEquals(error, m.getDetail());
        verifyStep(step);
    }

    private static void verifyStep(Integer step) {
        System.assertEquals(step, controller.step, 'Expected to be on step: ' + step);
    }
}