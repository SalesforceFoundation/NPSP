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

    //todo: this is public and used outside of this test class.
    public static void selectMasterRecord(CON_ContactMerge_CTRL cont, Id masterId) {
        for (CON_ContactMerge_CTRL.FieldRow row : cont.fieldRows) {
            if (row.showRadio) {
                row.selectedValue = String.valueOf(masterId);
            }
        }
    }

    static testMethod void exerciseUIOne2One(){
        exerciseUI(CAO_Constants.ONE_TO_ONE_PROCESSOR);
    }
    //todo: whats different between the two account models?
    static testMethod void exerciseUIHHAccount(){
        exerciseUI(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    }
    //exercise the many UI variables
    static void exerciseUI(string strProcessor) {
//        // todo: is this used?
//        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (npe01__Account_Processor__c = strProcessor));
//
//        //set up 3 contacts for the merge interface to work with
//        Contact con = UTIL_UnitTestData_TEST.getContact();
//
//        Contact con2 = UTIL_UnitTestData_TEST.getContact();
//        con2.LastName = '2Contact_forTests_Merge';
//
//        Contact con3 = UTIL_UnitTestData_TEST.getContact();
//        con3.LastName = '3Contact_forTests_Merge';
//
//        insert new Contact[]{con, con2, con3};
    }

    @IsTest
    private static void searchReturnsResultsWhenMatchFound() {
        CON_ContactMerge_CTRL controller = getControllerForSearch();
        controller.showContactSearch = true;
        controller.searchText = CAO_Constants.CONTACT_FIRSTNAME_FOR_TESTS;
        controller.mergeSelector = stubFor(new ContactMergeSelectorMock(3));

        Test.startTest();
        controller.search();
        Test.stopTest();

        System.assert(!controller.searchResults.isEmpty(), 'Search results should not be empty.');
        System.assertEquals(3, controller.searchResults.size(), 'The correct number of search results should be ' +
                'returned.');
    }

    @IsTest
    private static void searchReturnsNoResultsWhenNoMatchesFound() {
        CON_ContactMerge_CTRL controller = getControllerForSearch();
        controller.showContactSearch = true;
        controller.searchText = 'test';

        Test.startTest();
        controller.search();
        Test.stopTest();

        System.assert(controller.searchResults.isEmpty(), 'Search results returned from controller should be empty.');
    }

    @IsTest
    private static void shouldSelectEntireDefaultRecordWhenChoosingSelectAll() {
        // given
        CON_ContactMerge_CTRL controller = getController();
        List<Contact> mockContactsWithIds = getMockContactsWithIds(5);
        controller.selectedRecords = getMockSelectedRecordsForMerge(mockContactsWithIds);
        controller.fieldRows = getMockFieldRows(new List<String>{
                String.valueOf(Contact.FirstName),
                String.valueOf(Contact.LastName),
                String.valueOf(Contact.npe01__Preferred_Email__c)
        }, mockContactsWithIds);

        Id defaultRecordId = controller.selectedRecords.get(mockContactsWithIds[0].Id).Id;
        ApexPages.currentPage().getParameters().put('recordId', defaultRecordId);

        //when
        Test.startTest();
            controller.selectDefaultRecord();
        Test.stopTest();

        //then
        for (CON_ContactMerge_CTRL.FieldRow row : controller.fieldRows) {
            if (row.showRadio) {
                System.assertEquals(defaultRecordId, row.selectedValue, 'The selected record should be the default ' +
                    'record.');
            }
        }
    }

    private static Map<String, Contact> getMockSelectedRecordsForMerge(List<Contact> mockContactsWithIds) {
        return new Map<String, Contact>(mockContactsWithIds);
    }
    //todo: not finished
    private static List<CON_ContactMerge_CTRL.FieldRow> mergeCandidatesShouldDisplayCorrectValues(Contact con2) {
        CON_ContactMerge_CTRL controller = getControllerForSearch();
        controller.search();
        selectSearchResults(controller.searchResults);

        Test.startTest();
            //todo: full loadMergeCandidates would get called here
            controller.nextStep();
        Test.stopTest();

        System.assertEquals(3, controller.step); // We are now on step 3, "choose winning contact"

        List<CON_ContactMerge_CTRL.FieldRow> fieldRows = controller.fieldRows;

        for (CON_ContactMerge_CTRL.FieldRow row : fieldRows) {
            if (row.fieldName.equals('Master')) {
                System.assert(row.showRadio);
                System.assert(row.selectedValue != null); // Since all contacts were created simulateneously, hard to know which one will be selected by default
            }

            if (row.fieldName.equalsIgnoreCase('MailingStreet')) {
                System.assert(!row.showRadio); // Since both records have the same value, we dont need to show the radio
            }

            if (row.fieldName.equalsIgnoreCase('homephone')) {
                System.assert(row.showRadio);
                System.assertEquals(con2.id, row.selectedValue); // Since contact 1 has a null homephone while contact 2 has a non-null homephone, the contact 2 should be selected here.
            }
        }
        return fieldRows;
    }

    //todo: not finished
    @IsTest
    private static void shouldDisplayErrorWhenTooFewContactsSelected() {
        CON_ContactMerge_CTRL controller = getControllerForSearch();
        // given
        selectSearchResult(controller.searchResults[0]);

        // when
        // todo: moves into loadMergeCandidates() but exits the logic so not much to gain here
        controller.nextStep();

        // then
        // todo: Asserts whether or not error is thrown when loading merge page
        System.assertEquals(1, ApexPages.getMessages().size(), 'Selecting only one contact should display one ' +
                'page-level error message.');
        ApexPages.Message pageMessage = ApexPages.getMessages()[0];
        System.assertEquals(ApexPages.Severity.Error, pageMessage.getSeverity(), 'The error thrown should be an error' +
                ' severity.');
        System.assertEquals(Label.npe01.Contact_Merge_Error_Too_Few_Contacts, pageMessage.getDetail(), 'The correct ' +
                'error message should be displayed.');
    }

    private static void selectSearchResult(CON_ContactMerge_CTRL.ContactWrapper searchResult) {
        searchResult.selected = true;
    }

    private static void selectSearchResults(List<CON_ContactMerge_CTRL.ContactWrapper> searchResults) {
        for (CON_ContactMerge_CTRL.ContactWrapper contactWrapper : searchResults) {
            contactWrapper.selected = true;
        }
    }

    static testMethod void failNextStepWithDeletedRecordSelectedOne2One() {
        failNextStepWithDeletedRecordSelected(CAO_Constants.ONE_TO_ONE_PROCESSOR);
    }
    static testMethod void failNextStepWithDeletedRecordSelectedHHAccount(){
        failNextStepWithDeletedRecordSelected(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    }

    //todo: next step fails when deleted contact selected as the winner
    static void failNextStepWithDeletedRecordSelected(string strProcessor) {

        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (npe01__Account_Processor__c = strProcessor));

        //set up 2 contacts for the merge interface to work with
        Contact con = UTIL_UnitTestData_TEST.getContact();

        Contact con2 = UTIL_UnitTestData_TEST.getContact();
        con2.LastName = '2Contact_forTests_Merge';

        insert new Contact[]{con, con2};

        Test.setCurrentPageReference(new PageReference('Page.CON_ContactMerge'));
        CON_ContactMerge_CTRL controller = getControllerForSearch();
        controller.showContactSearchPage();
        controller.searchText = 'test';

        Id[] fixedSearchResults=new Id[2];
        fixedSearchResults[0]=con.Id;
        fixedSearchResults[1]=con2.Id;

        Test.setFixedSearchResults(fixedSearchResults);

        Test.startTest();
        //call the search method, which will return the bogus SOSL results
        controller.search();

        //there should be 2 Contacts returned
        system.assertEquals(2,controller.searchResults.size());

        controller.searchResults[0].selected = true;
        controller.searchResults[1].selected = true;

        // delete 1 contact
        delete con;

        controller.nextStep();

        System.assertEquals(1, ApexPages.getMessages().size()); // Selecting a deleted record must throw an error
        ApexPages.Message m = ApexPages.getMessages()[0];
        System.assertEquals(ApexPages.Severity.Error, m.getSeverity());
        System.assertEquals(label.npe01.Contact_Merge_Error_Query_Failed + ' ' + label.npe01.Contact_Merge_Error_please_retry, m.getDetail());
        System.assertEquals(2, controller.step); // We are on step 2 "select contacts"

        Test.stopTest();
    }

    static testMethod void failMergeWithDeletedRecordSelectedOne2One() {
        failMergeWithDeletedRecordSelected(CAO_Constants.ONE_TO_ONE_PROCESSOR);
    }
    static testMethod void failMergeWithDeletedRecordSelectedHHAccount(){
        failMergeWithDeletedRecordSelected(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    }
        // Try selecting a deleted record for merge
    static void failMergeWithDeletedRecordSelected(string strProcessor) {

        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (npe01__Account_Processor__c = strProcessor));

        //set up 2 contacts for the merge interface to work with
        Contact con = UTIL_UnitTestData_TEST.getContact();

        Contact con2 = UTIL_UnitTestData_TEST.getContact();
        con2.LastName = '2Contact_forTests_Merge';

        insert new Contact[]{con, con2};

        Test.startTest();

        Test.setCurrentPageReference(new PageReference('Page.CON_ContactMerge'));

        CON_ContactMerge_CTRL controller = new CON_ContactMerge_CTRL(new ApexPages.Standardsetcontroller(new list<Contact>()));
        controller.showContactSearchPage();
        controller.searchText = 'test';

        Id[] fixedSearchResults=new Id[2];
        fixedSearchResults[0]=con.Id;
        fixedSearchResults[1]=con2.Id;

        Test.setFixedSearchResults(fixedSearchResults);

        //call the search method, which will return the bogus SOSL results

        controller.search();

        //there should be 2 Contacts returned
        system.assertEquals(2,controller.searchResults.size());

        controller.searchResults[0].selected = true;
        controller.searchResults[1].selected = true;

        controller.nextStep();

        // delete 1 contact
        delete con;

        controller.mergeContacts();

        System.assertEquals(1, ApexPages.getMessages().size()); // Selecting a deleted record must throw an error
        ApexPages.Message m = ApexPages.getMessages()[0];
        System.assertEquals(ApexPages.Severity.Error, m.getSeverity());
        System.assertEquals(label.npe01.Contact_Merge_Error_Lock_failed + ' ' + label.npe01.Contact_Merge_Error_please_retry, m.getDetail());

        Test.stopTest();

    }

    static testMethod void tooFewContactsSelectedOne2One(){
        tooFewContactsSelected(CAO_Constants.ONE_TO_ONE_PROCESSOR);
    }
    static testMethod void tooFewContactsSelectedHHAccount(){
        tooFewContactsSelected(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    }
    static void tooFewContactsSelected(string strProcessor) {

        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (npe01__Account_Processor__c = strProcessor));

        //set up 1 contact for the merge interface to work with
        Contact con = UTIL_UnitTestData_TEST.getContact();
        insert con;

        Test.setCurrentPageReference(new PageReference('Page.CON_ContactMerge'));
        CON_ContactMerge_CTRL controller = new CON_ContactMerge_CTRL(new ApexPages.Standardsetcontroller(new list<Contact>()));
        controller.showContactSearchPage();
        controller.searchText = 'test';
        //SOSL always returns nothing in tests, unless you use the setFixedSearchResults value
        Id[] fixedSearchResults=new Id[1];
        fixedSearchResults[0]=con.Id;

        Test.setFixedSearchResults(fixedSearchResults);
        //call the search method, which will return the bogus SOSL results
        controller.search();

        controller.searchResults[0].selected = true;

        controller.nextStep();

        System.assertEquals(1, ApexPages.getMessages().size()); // Selecting only one record for merge should throw an error.
        ApexPages.Message m = ApexPages.getMessages()[0];
        System.assertEquals(ApexPages.Severity.Error, m.getSeverity());
        System.assertEquals(label.npe01.Contact_Merge_Error_Too_Few_Contacts, m.getDetail());
    }


    static testMethod void tooManyContactsSelectedOne2One(){
        tooManyContactsSelected(CAO_Constants.ONE_TO_ONE_PROCESSOR);
    }
    static testMethod void tooManyContactsSelectedHHAccount(){
        tooManyContactsSelected(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    }
    static void tooManyContactsSelected(string strProcessor) {

        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (npe01__Account_Processor__c = strProcessor));

        //set up 4 contacts for the merge interface to work with
        Contact con = UTIL_UnitTestData_TEST.getContact();

        Contact con2 = UTIL_UnitTestData_TEST.getContact();
        con2.LastName = '2Contact_forTests_Merge';

        Contact con3 = UTIL_UnitTestData_TEST.getContact();
        con3.LastName = '3Contact_forTests_Merge';

        Contact con4 = UTIL_UnitTestData_TEST.getContact();
        con4.LastName = '4Contact_forTests_Merge';

        insert new Contact[]{con, con2, con3, con4};

        Test.setCurrentPageReference(new PageReference('Page.CON_ContactMerge'));
        CON_ContactMerge_CTRL controller = new CON_ContactMerge_CTRL(new ApexPages.Standardsetcontroller(new list<Contact>()));
        controller.showContactSearchPage();
        controller.searchText = 'test';

        Id[] fixedSearchResults=new Id[4];
        fixedSearchResults[0]=con.Id;
        fixedSearchResults[1]=con2.Id;
        fixedSearchResults[2]=con3.Id;
        fixedSearchResults[3]=con4.Id;

        Test.setFixedSearchResults(fixedSearchResults);
        //call the search method, which will return the bogus SOSL results
        controller.search();

        controller.searchResults[0].selected = true;
        controller.searchResults[1].selected = true;
        controller.searchResults[2].selected = true;
        controller.searchResults[3].selected = true;

        controller.nextStep();

        System.assertEquals(1, ApexPages.getMessages().size()); // Selecting too many records for merge should throw an error.
        ApexPages.Message m = ApexPages.getMessages()[0];
        System.assertEquals(ApexPages.Severity.Error, m.getSeverity());
        System.assertEquals(label.npe01.Contact_Merge_Error_Too_Many_Contacts, m.getDetail());
    }

    /**
     * @description Validate that a User with no delete permissions to the Contact object gets a pageMessage
     * error when navigating to Contact Merge page.
     */
    @isTest
    private static void shouldDisplayErrorWithNoDeletePermission() {
        // Create contacts for going through the contact merge page
        Contact con = UTIL_UnitTestData_TEST.getContact();

        Contact con2 = UTIL_UnitTestData_TEST.getContact();
        con2.LastName = '2Contact_forTests_Merge';

        insert new Contact[]{con, con2};

        // Find the ReadOnly profile (a Salesforce standard profile) and create a dummy User with that Profile
        User readOnlyUser = UTIL_UnitTestData_TEST.createUser(UTIL_UnitTestData_TEST.PROFILE_READONLY_USER);

        // Verify that controller detects the User doesn't have delete permissions on the Contact object
        Test.startTest();
        System.runAs(readOnlyUser) {
            Test.setCurrentPage(Page.CON_ContactMerge);
            Con_ContactMerge_CTRL ctlr = new Con_ContactMerge_CTRL(new ApexPages.StandardSetController(new List<Contact>()));
            UTIL_UnitTestData_TEST.assertPageHasError(System.Label.conMergeErrorNoDeleteObjPermission);
        }
        Test.stopTest();
    }

    /**
     * @description Validate that a User with delete permissions to the Contact object, but no record level acesss
       gets a pageErrorMessage doing the contact merge.
     */
    @isTest
    private static void shouldDisplayErrorWithNoDeleteRecAccess() {
        //Create contacts for going through the contact merge page
        Contact con = UTIL_UnitTestData_TEST.getContact();

        Contact con2 = UTIL_UnitTestData_TEST.getContact();
        con2.LastName = '2Contact_forTests_Merge';

        insert new Contact[]{con, con2};

        // Find the ReadOnly profile (a Salesforce standard profile) and create a dummy User with that Profile
        User readOnlyUser = UTIL_UnitTestData_TEST.createUser(UTIL_UnitTestData_TEST.PROFILE_READONLY_USER);

        User adminUser = UTIL_UnitTestData_TEST.createUserWithoutInsert(UTIL_Profile.SYSTEM_ADMINISTRATOR);
        // Run as admin user to set the permission set with object level delete permission for the readonlyuser
        System.runas(adminUser) {
            assignDeletePermissionSet(readOnlyUser.Id);
        }

        Test.startTest();
        // Verify that when logged in as readonlyuser, it returns error when merging contacts because of record level permissions
        System.runAs(readOnlyUser) {
            Test.setCurrentPage(Page.CON_ContactMerge);
            Con_ContactMerge_CTRL ctlr = new Con_ContactMerge_CTRL(new ApexPages.StandardSetController(new List<Contact>()));

            ctlr.showContactSearchPage();
            ctlr.searchText = 'test';
            //SOSL always returns nothing in tests, unless you use the setFixedSearchResults value
            List<Id> fixedSearchResults = new List<Id>{ con.Id, con2.Id };

            Test.setFixedSearchResults(fixedSearchResults);
            //search for contacts
            ctlr.search();
            //select the two contacts and grab them
            ctlr.searchResults[0].selected = true;
            ctlr.searchResults[1].selected = true;
            ctlr.nextStep();

            UTIL_UnitTestData_TEST.assertPageHasError(System.Label.conMergeErrorNoDeleteRecAccess);
        }

        Test.stopTest();
    }

    /*******************************************************************************************************
    * @description Creates and assigns the permission set with delete permission on contact object
    */
    private static void assignDeletePermissionSet(Id userId) {
        // Create a permission set with CustomizeApplication set ensuring other flags
        // on which CustomizeApplication settings depends are set as well
        PermissionSet permission = new PermissionSet(
            Name = 'PermissionTest',
            Label = 'PermissionTest'
        );

        insert permission;

        insert new ObjectPermissions (
            SObjectType = 'Contact',
            ParentId = permission.id,
            PermissionsRead = true,
            PermissionsViewAllRecords = true,
            PermissionsCreate = true,
            PermissionsDelete = true,
            PermissionsEdit = true
        );

        insert new PermissionSetAssignment(
            AssigneeId = userId,
            PermissionSetId = permission.Id
        );

    }

    static testMethod void merge2OneToOneOne2One(){
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        merge2OneToOne(CAO_Constants.ONE_TO_ONE_PROCESSOR);
    }
    static testMethod void merge2OneToOneHHAccount(){
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        merge2OneToOne(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    }
    //merge two contacts that are both in the one-to-one account model
    //the second contact's org should be deleted
    static void merge2OneToOne(string strProcessor) {

        Test.startTest();  
        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = 
            UTIL_CustomSettingsFacade.getContactsSettingsForTests(
                new npe01__Contacts_and_Orgs_Settings__c(npe01__Account_Processor__c = strProcessor));

        Contact con = UTIL_UnitTestData_TEST.getContact();

        Contact con2 = UTIL_UnitTestData_TEST.getContact();
        con2.LastName = '2Contact_forTests_Merge';

        insert new Contact[] {con, con2};

        Test.setCurrentPageReference(new PageReference('Page.CON_ContactMerge'));

        CON_ContactMerge_CTRL controller = 
            new CON_ContactMerge_CTRL(new ApexPages.Standardsetcontroller(new list<Contact>()));
            
        Test.stopTest();          
            
        con = [SELECT Id, AccountId, FirstName, LastName, MailingStreet FROM Contact WHERE Id = :con.id];
        con2 = [SELECT Id, AccountId, FirstName, LastName, MailingStreet FROM Contact WHERE Id = :con2.id];
      
        controller.showContactSearchPage();
        controller.searchText = 'test';
        //SOSL always returns nothing in tests, unless you use the setFixedSearchResults value
        Id[] fixedSearchResults=new Id[2];
        fixedSearchResults[0]=con.Id;
        fixedSearchResults[1]=con2.Id;

        Test.setFixedSearchResults(fixedSearchResults);
        
        //search for contacts
        controller.search();
        //select the two contacts and grab them
        controller.searchResults[0].selected = true;
        controller.searchResults[1].selected = true;

        controller.nextStep();

        selectMasterRecord(controller, con2.id);

        //merge them
        controller.mergeContacts();

        //first contact should be deleted
        system.assertEquals(1,[select count() from Contact where id=:con2.id]);
        system.assertEquals(0,[select count() from Contact where id=:con.id]);
        //first contact's account should be deleted
        system.assertEquals(1,[select count() from Account where id=:con2.accountId]);
        system.assertEquals(0,[select count() from Account where id=:con.accountId]);
        //Second contact's account id should not have changed
        system.assertEquals(con2.accountId,[select AccountId from Contact where id=:con2.id].AccountId);
    }

    static testMethod void merge2OneToOneOppsOne2One(){
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        merge2OneToOneOpps(CAO_Constants.ONE_TO_ONE_PROCESSOR);
    }
    static testMethod void merge2OneToOneOppsHHAccount(){
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        merge2OneToOneOpps(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    }
    //merge two contacts that are both in the one-to-one account model
    //the second contact's org shouldn't be deleted because it has open opportunities
    static void merge2OneToOneOpps(string strProcessor) {

        TDTM_DefaultConfig.startTestDataInit();

        UTIL_CustomSettingsFacade.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (npe01__Account_Processor__c = strProcessor));

        String newContactMailingStreet = '123 Elm St';
        Contact con = UTIL_UnitTestData_TEST.getContact();

        Contact con2 = UTIL_UnitTestData_TEST.getContact();
        con2.LastName = '2Contact_forTests_Merge';

        insert new Contact[]{con, con2};

        con = [Select id, accountId, FirstName, LastName, MailingStreet from Contact where Id = :con.id];
        con2 = [Select id, accountId, FirstName, LastName, MailingStreet from Contact where Id = :con2.id];

        Test.setCurrentPageReference(new PageReference('Page.CON_ContactMerge'));

        CON_ContactMerge_CTRL controller = new CON_ContactMerge_CTRL(new ApexPages.Standardsetcontroller(new list<Contact>()));

        controller.showContactSearchPage();
        controller.searchText = 'test';
        //SOSL always returns nothing in tests, unless you use the setFixedSearchResults value
        Id[] fixedSearchResults=new Id[2];
        fixedSearchResults[0]=con.Id;
        fixedSearchResults[1]=con2.Id;

        Test.setFixedSearchResults(fixedSearchResults);
        //search for contacts
        controller.search();
        //select the two contacts and grab them
        controller.searchResults[0].selected = true;
        controller.searchResults[1].selected = true;

        Opportunity o = new Opportunity(AccountId=con.accountId,Amount=500,Name='test',StageName='Closed Won',CloseDate=System.today());
        insert o;

        //select the second as winner
        controller.nextStep();

        selectMasterRecord(controller, con2.id);

        //merge them
        TDTM_DefaultConfig.stopTestDataInit();
        Test.startTest();
        controller.mergeContacts();
        Test.stopTest();

        //first contact should be deleted
        system.assertEquals(1,[select count() from Contact where id=:con2.id]);
        system.assertEquals(0,[select count() from Contact where id=:con.id]);
        //first contact's account should be deleted
        system.assertEquals(1,[select count() from Account where id=:con2.AccountId]);
        if (strProcessor == CAO_Constants.ONE_TO_ONE_PROCESSOR) {
            system.assertEquals(0,[select count() from Account where id=:con.accountId]);
            system.assertEquals(1,[select count() from Opportunity where accountId=:con2.AccountId]);
        } else {
            system.assertEquals(0,[select count() from Account where id=:con.accountId]);
            system.assertEquals(1,[select count() from Opportunity where accountId=:con2.AccountId]);
            system.assertEquals(0,[select count() from Opportunity where accountId=:con.AccountId]);
        }

        //Second contact's account id should not have changed
        system.assertEquals(con2.AccountId,[select AccountId from Contact where id=:con2.id].AccountId);
    }

    static testMethod void merge2OrganizationsOne2One(){
        merge2Organizations(CAO_Constants.ONE_TO_ONE_PROCESSOR);
    }
    static testMethod void merge2OrganizationsHHAccount(){
        merge2Organizations(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    }
    //merge a one-to-one contact with one in a normal organzation
    //the organization shouldn't be deleted
    static void merge2Organizations(string strProcessor) {

        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (npe01__Account_Processor__c = strProcessor));

        Account acc = new Account(
            Name = 'Test Account 1'
        );

        Account acc2 = new Account(
            Name = 'Test Account 2'
        );
        insert new Account[]{acc, acc2};

        Contact con = UTIL_UnitTestData_TEST.getContact();
        con.AccountId = acc.Id;

        Contact con2 = UTIL_UnitTestData_TEST.getContact();
        con2.LastName = '2Contact_forTests_Merge';
        con2.AccountId = acc2.Id;

        insert new Contact[]{con, con2};

        con = [Select id, accountId, FirstName, LastName, MailingStreet from Contact where Id = :con.id];
        con2 = [Select id, accountId, FirstName, LastName, MailingStreet from Contact where Id = :con2.id];

        Test.setCurrentPageReference(new PageReference('Page.CON_ContactMerge'));

        CON_ContactMerge_CTRL controller = new CON_ContactMerge_CTRL(new ApexPages.Standardsetcontroller(new list<Contact>()));

        controller.showContactSearchPage();
        controller.searchText = 'test';
        //SOSL always returns nothing in tests, unless you use the setFixedSearchResults value
        Id[] fixedSearchResults=new Id[2];
        fixedSearchResults[0]=con.Id;
        fixedSearchResults[1]=con2.Id;

        Test.setFixedSearchResults(fixedSearchResults);
        //search for contacts
        controller.search();
        //select the two contacts and grab them
        controller.searchResults[0].selected = true;
        controller.searchResults[1].selected = true;

        controller.nextStep();

        selectMasterRecord(controller, con.id);

        //merge them
        controller.mergeContacts();

        //second contact should be deleted
        system.assertEquals(0,[select count() from Contact where id=:con2.id]);
        system.assertEquals(1,[select count() from Contact where id=:con.id]);
        //second contact's account should not be deleted
        system.assertEquals(1,[select count() from Account where id=:con2.accountId]);
        system.assertEquals(1,[select count() from Account where id=:con.AccountId]);
        //First contact's account id should not have changed
        system.assertEquals(con.accountId,[select AccountId from Contact where id=:con.id].AccountId);
    }

    static testMethod void merge2PrivateContactsOne2One(){
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        merge2PrivateContacts(CAO_Constants.ONE_TO_ONE_PROCESSOR);
    }
    static testMethod void merge2PrivateContactsHHAccount(){
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        merge2PrivateContacts(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    }
    //merge two private contacts
    //the organization shouldn't be deleted
    static void merge2PrivateContacts(string strProcessor) {

        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (npe01__Account_Processor__c = strProcessor));

        Contact con = UTIL_UnitTestData_TEST.getContact();
        con.npe01__Private__c = true;

        Contact con2 = UTIL_UnitTestData_TEST.getContact();
        con2.LastName = '2Contact_forTests_Merge';
        con2.npe01__Private__c = true;

        insert new Contact[]{con, con2};

        con = [Select id, accountId, FirstName, LastName, MailingStreet from Contact where Id = :con.id];
        con2 = [Select id, accountId, FirstName, LastName, MailingStreet from Contact where Id = :con2.id];

        Test.setCurrentPageReference(new PageReference('Page.CON_ContactMerge'));

        CON_ContactMerge_CTRL controller = new CON_ContactMerge_CTRL(new ApexPages.Standardsetcontroller(new list<Contact>()));

        controller.showContactSearchPage();
        controller.searchText = 'test';
        //SOSL always returns nothing in tests, unless you use the setFixedSearchResults value
        Id[] fixedSearchResults=new Id[2];
        fixedSearchResults[0]=con.Id;
        fixedSearchResults[1]=con2.Id;

        Test.setFixedSearchResults(fixedSearchResults);
        //search for contacts
        controller.search();
        //select the two contacts and grab them
        controller.searchResults[0].selected = true;
        controller.searchResults[1].selected = true;

        controller.nextStep();

        selectMasterRecord(controller, con.id);

        //merge them
        controller.mergeContacts();

        //second contact should be deleted
        system.assertEquals(0,[select count() from Contact where id=:con2.id]);
        system.assertEquals(1,[select count() from Contact where id=:con.id]);
        //First contact's account id should not have changed
        system.assertEquals(null,[select AccountId from Contact where id=:con.id].AccountId);
    }

    static testMethod void merge2IndividualsOne2One(){
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        merge2IndividualBucketContacts(CAO_Constants.ONE_TO_ONE_PROCESSOR);
    }
    static testMethod void merge2IndividualsHHAccount(){
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        merge2IndividualBucketContacts(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    }
    //merge two contacts in the Individual Account
    //the organization shouldn't be deleted or renamed
    static void merge2IndividualBucketContacts(string strProcessor) {
        // Arrange: GIVEN two Individual Bucket Contacts exist and are to be merged on the
        // Contact Merge Visualforce page
        Contact con = UTIL_UnitTestData_TEST.getContact();
        Contact con2 = UTIL_UnitTestData_TEST.getContact();
        con2.LastName = '2Contact_forTests_Merge';
        Contact[] contacts = new Contact[]{
                con, con2
        };
        insertAsIndividualBucketContacts(contacts);

        Map<Id, Contact> queriedBucketContacts = getContacts(new Set<Id>{con.Id, con2.Id});
        con = queriedBucketContacts.get(con.Id);
        con2 = queriedBucketContacts.get(con2.Id);

        Test.setCurrentPageReference(new PageReference('Page.CON_ContactMerge'));

        CON_ContactMerge_CTRL controller = new CON_ContactMerge_CTRL(new ApexPages.Standardsetcontroller(new list<Contact>()));

        controller.showContactSearchPage();
        controller.searchText = 'test';
        //SOSL always returns nothing in tests, unless you use the setFixedSearchResults value
        Id[] fixedSearchResults=new Id[2];
        fixedSearchResults[0]=con.Id;
        fixedSearchResults[1]=con2.Id;

        Test.setFixedSearchResults(fixedSearchResults);
        //search for contacts
        controller.search();
        //select the two contacts and grab them
        controller.searchResults[0].selected = true;
        controller.searchResults[1].selected = true;

        controller.nextStep();

        selectMasterRecord(controller, con.id);

        // Act: WHEN one Individual Bucket Contact is merged into another Bucket Contact
        Test.startTest();
        controller.mergeContacts();
        Test.stopTest();

        // Assert: THEN
        //second contact should be deleted
        System.assertEquals(0, [SELECT COUNT() FROM Contact WHERE Id = :con2.Id]);
        System.assertEquals(1, [SELECT COUNT() FROM Contact WHERE Id = :con.Id]);
        //second contact's account should not be deleted
        System.assertEquals(1, [SELECT COUNT() FROM Account WHERE Id = :con2.AccountId]);
        System.assertEquals(1, [SELECT COUNT() FROM Account WHERE Id = :con.AccountId]);

        Map<Id, Contact> queriedContacts = getContacts(new Set<Id>{
                con.Id
        });
        Contact mergeWinner = queriedContacts.get(con.Id);

        System.assertEquals(con.AccountId, mergeWinner.AccountId,
                'The winning Contact\'s account id should not have changed');
        System.assertEquals(CAO_Constants.BUCKET_ACCOUNT_NAME, mergeWinner.Account.Name,
                'The winning Contact\'s Account\'s Name should not have changed');
    }

    private static Map<Id, Contact> getContacts(Set<Id> contactIds) {
        return new Map<Id, Contact>([
                Select accountId, FirstName, LastName, MailingStreet, Account.Name
                from Contact
                where Id = :contactIds
        ]);
    }

    private static void insertAsIndividualBucketContacts(Contact[] contacts) {
        UTIL_CustomSettingsFacade.getContactsSettingsForTests(
                new npe01__Contacts_and_Orgs_Settings__c (
                        npe01__Account_Processor__c = CAO_Constants.BUCKET_PROCESSOR));

        insert contacts;
    }

    static testMethod void merge1Org1OneToOneOne2One(){
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        merge1Org1OneToOne(CAO_Constants.ONE_TO_ONE_PROCESSOR);
    }
    static testMethod void merge1Org1OneToOneHHAccount(){
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        merge1Org1OneToOne(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    }
    //merge one contacts in the Individual Account, one in one-to-one model
    //the individual organization shouldn't be deleted
    static void merge1Org1OneToOne(string strProcessor) {

        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (npe01__Account_Processor__c = strProcessor));

        Account acc = new Account(
            Name = 'Test Account 1'
        );
        insert acc;

        Contact con = UTIL_UnitTestData_TEST.getContact();
        con.AccountId = acc.Id;

        Contact con2 = UTIL_UnitTestData_TEST.getContact();
        con2.LastName = '2Contact_forTests_Merge';

        insert new Contact[]{con, con2};

        con = [Select id, accountId, FirstName, LastName, MailingStreet from Contact where Id = :con.id];
        con2 = [Select id, accountId, FirstName, LastName, MailingStreet from Contact where Id = :con2.id];

        Test.setCurrentPageReference(new PageReference('Page.CON_ContactMerge'));

        CON_ContactMerge_CTRL controller = new CON_ContactMerge_CTRL(new ApexPages.Standardsetcontroller(new list<Contact>()));

        controller.showContactSearchPage();
        controller.searchText = 'test';
        //SOSL always returns nothing in tests, unless you use the setFixedSearchResults value
        Id[] fixedSearchResults=new Id[2];
        fixedSearchResults[0]=con.Id;
        fixedSearchResults[1]=con2.Id;

        Test.setFixedSearchResults(fixedSearchResults);
        //search for contacts
        controller.search();
        //select the two contacts and grab them
        controller.searchResults[0].selected = true;
        controller.searchResults[1].selected = true;

        controller.nextStep();

        selectMasterRecord(controller, con.id);

        //merge them
        controller.mergeContacts();

        //second contact should be deleted
        system.assertEquals(0,[select count() from Contact where id=:con2.id]);
        system.assertEquals(1,[select count() from Contact where id=:con.id]);

        //second contact's account should be deleted
        system.assertEquals(0,[select count() from Account where id=:con2.accountId]);

        system.assertEquals(1,[select count() from Account where id=:con.accountId]);
        //First contact's account id should not have changed
        system.assertEquals(con.accountId,[select AccountId from Contact where id=:con.id].AccountId);
    }

    static testMethod void testShowDuplicateRecordSets() {
        //Create 15 DRS records
        getDuplicateSetOfRecords(15);
        CON_ContactMerge_CTRL controller 
            = new CON_ContactMerge_CTRL(new ApexPages.Standardsetcontroller(new List<Contact>()));
        controller.showDuplicateRecordSets();
        Test.startTest();
        System.assertEquals(controller.hasDSRObjectReadPermission(), true);
        
        Boolean hasNextvalue = controller.hasNext;
        Boolean hasPreviousValue = controller.hasPrevious;
        Integer pageNumberValue = controller.pageNumber;

        System.assertEquals(pageNumberValue, 1);
        System.assertEquals(hasPreviousValue, false);
        System.assertEquals(hasNextvalue, true);
        
        // Test pagination methods
        controller.lastPage();
        controller.firstPage();
        controller.previouspage();
        controller.nextpage();

        //Asserts to check the results are correct.
        System.assertEquals(controller.showDRS, true);
        System.assertEquals(controller.totalPages, 2);
        System.assertEquals(controller.hasContactObjectDeletePermission(), true, 'Do not have delete permission on DRS');
        System.assertNotEquals(controller.listDuplicateRecordSets.size(), 0, 'List is empty');
        
        Test.stopTest();

    }

    static testMethod void testSelectDRSrecord() {

        Test.startTest();
        getDuplicateSetOfRecords(15);

        Test.setCurrentPageReference(new PageReference('Page.CON_ContactMerge'));
        CON_ContactMerge_CTRL controller
            = new CON_ContactMerge_CTRL(new ApexPages.Standardsetcontroller(new List<Contact>()));
        controller.showDuplicateRecordSets();
        controller.DRSrecordId = controller.listDuplicateRecordSets[0].Id;
        controller.search();
        System.assertEquals(controller.step, 2);
        System.assertNotEquals(controller.searchResults.size(), 0 ,'Contact Not found');
        Test.stopTest();
    }

    static testMethod void shouldDisplayDuplicateRecordSetWithLeadAndTwoContacts() {

        Test.startTest();
        getDuplicateSetOfRecords(15, 2, true);

        Test.setCurrentPageReference(new PageReference('Page.CON_ContactMerge'));
        CON_ContactMerge_CTRL controller
            = new CON_ContactMerge_CTRL(new ApexPages.Standardsetcontroller(new List<Contact>()));
        controller.getUnactionableDuplicateRecordSets();
        System.assertEquals(controller.unactionableDuplicateRecordSets.size(), 0,
            'All Duplicate Record Sets should be visible');
        System.assertEquals(Label.commonContactCount, Label.commonContactCount,
            'Label should be ' + Label.commonContactCount);
        System.assertEquals(Label.conMergeFirstContactLabel, Label.conMergeFirstContactLabel,
            'Label should be ' + Label.conMergeFirstContactLabel);

        Test.stopTest();
    }

    static testMethod void shouldNotDisplayDuplicateRecordSetWithLeadAndOneContact() {

        Test.startTest();
        getDuplicateSetOfRecords(15, 1, true);

        Test.setCurrentPageReference(new PageReference('Page.CON_ContactMerge'));
        CON_ContactMerge_CTRL controller
            = new CON_ContactMerge_CTRL(new ApexPages.Standardsetcontroller(new List<Contact>()));
        controller.getUnactionableDuplicateRecordSets();
        System.assertEquals(controller.unactionableDuplicateRecordSets.size(), 15,
            'All 15 Duplicate Record Sets should not be visible');
        Test.stopTest();
    }
    //todo: first happy path merge test.
    @IsTest
    static void testMergeContact() {
        // given
//        getDuplicateSetOfRecords(15);
        CON_ContactMerge_CTRL controller = getController();
        Id winningContactId = setupMockDataForMerge(controller, getMockContactsWithIds(2));

        Test.startTest();
            //todo: needed for method - fieldRows, MASTER_KEY, showRadio, row.selectedValue
            PageReference mergedContact = controller.mergeContacts();
        Test.stopTest();
        PageReference expectedMergedContactPage  = new PageReference('/' + winningContactId);
        System.assertEquals(expectedMergedContactPage.getUrl(), mergedContact.getUrl());
    }

    private static Id setupMockDataForMerge(CON_ContactMerge_CTRL controller, List<Contact> contactsToMerge) {
        setMockFieldRows(controller, contactsToMerge);
        setSelectedRecordsForMerge(controller, contactsToMerge);
        Id winningContactId = setWinningContact(
            getMasterRecordRow(controller.fieldRows), contactsToMerge[0].Id);

        return winningContactId;
    }

    private static void setMockFieldRows(CON_ContactMerge_CTRL controller, List<Contact> contactsToMerge) {
        controller.fieldRows = getMockFieldRows(new List<String>{
                CON_ContactMerge_CTRL.MASTER_KEY,
                String.valueOf(Contact.FirstName),
                String.valueOf(Contact.LastName),
                String.valueOf(Contact.npe01__Preferred_Email__c)
        }, contactsToMerge);
    }

    private static void setSelectedRecordsForMerge(CON_ContactMerge_CTRL controller, List<Contact> contactsToMerge) {
        controller.selectedRecords = getMockSelectedRecordsForMerge(contactsToMerge);
    }

    private static CON_ContactMerge_CTRL.FieldRow getMasterRecordRow(List<CON_ContactMerge_CTRL.FieldRow> fieldRows) {
        CON_ContactMerge_CTRL.FieldRow masterRecordRow;
        for (CON_ContactMerge_CTRL.FieldRow row : fieldRows) {
            if (row.showRadio && isMasterRecordField(row.fieldName)) {
                masterRecordRow = row;
            }
        }
        return masterRecordRow;
    }

    private static Id setWinningContact(CON_ContactMerge_CTRL.FieldRow masterRecordRow, Id winningContactIdToSet) {
        masterRecordRow.selectedValue = winningContactIdToSet;

        return winningContactIdToSet;
    }

    //When one contact is selected on the page
    static testMethod void testOneContactSelectedToMerge() {
        
        getDuplicateSetOfRecords(15);        
        Test.setCurrentPageReference(new PageReference('Page.CON_ContactMerge'));
        CON_ContactMerge_CTRL controller 
            = new CON_ContactMerge_CTRL(new ApexPages.Standardsetcontroller(new List<Contact>()));
        Test.startTest();
        controller.showDuplicateRecordSets();
        controller.DRSrecordId = controller.listDuplicateRecordSets[0].Id;
        controller.search(); 
        // now select  2 contacts from the contactwrapper to proceed for merge
        controller.searchResults[0].selected = true;
        Id contactId = controller.searchResults[0].contactRecord.Id; 
        controller.nextStep();
        
        apexPages.Message[] pageMessages = ApexPages.getMessages();
        System.assertNotEquals(0, pageMessages.size());
        Boolean messageFound = false;
        for (ApexPages.Message message : pageMessages) {
            if ( message.getSeverity() == ApexPages.Severity.Error
              && message.getDetail() == Label.npe01.Contact_Merge_Error_Too_Few_Contacts) {
                messageFound = true;
            }
        }
        System.assert(messageFound);
        //Exception is thrown hence the selectedRecordsCount is not populated.
        System.assertEquals(controller.selectedRecordsCount, 0 );

        Test.stopTest();
    }

    //Test if more than 3 contacts are selected for merge
    static testMethod void testFourContactSelectedToMerge() {
        
        DuplicateRule dR = [
                            SELECT 
                                Id
                            FROM 
                                DuplicateRule
                            Where
                                SobjectType = 'Contact'
                            LIMIT 1
                            ];
        Test.startTest();
        
        //Create Original Contacts
        Contact con = UTIL_UnitTestData_TEST.getContact();
        Contact con2 = UTIL_UnitTestData_TEST.getContact();
        Contact con3 = UTIL_UnitTestData_TEST.getContact();
        Contact con4 = UTIL_UnitTestData_TEST.getContact();
        
        insert new Contact[]{con, con2, con3, con4};
        
        //Create Duplicate Record Set
        List<DuplicateRecordSet> dupRSList = getDuplicateRecordSets(dR.Id , 1);
        insert dupRSList;
        
        //Create Duplicate Record Items
        List<DuplicateRecordItem> duplicateRecordItems = new List<DuplicateRecordItem>();
        duplicateRecordItems.add(getDuplicateRecordItem(dupRSList[0].Id , con.Id));
        duplicateRecordItems.add(getDuplicateRecordItem(dupRSList[0].Id , con2.Id));
        duplicateRecordItems.add(getDuplicateRecordItem(dupRSList[0].Id , con3.Id));
        duplicateRecordItems.add(getDuplicateRecordItem(dupRSList[0].Id , con4.Id));
        insert duplicateRecordItems;

        CON_ContactMerge_CTRL controller 
            = new CON_ContactMerge_CTRL(new ApexPages.Standardsetcontroller(new List<Contact>()));
        controller.showDuplicateRecordSets();
        controller.DRSrecordId = controller.listDuplicateRecordSets[0].Id;
        controller.search(); 
        // now select 4 contacts from the contactwrapper to proceed for merge
        controller.searchResults[0].selected = true;
        controller.searchResults[1].selected = true;
        controller.searchResults[2].selected = true;
        controller.searchResults[3].selected = true;
        Id contactId = controller.searchResults[0].contactRecord.Id; 

        controller.nextStep();
        apexPages.Message[] pageMessages = ApexPages.getMessages();
        System.assertNotEquals(0, pageMessages.size());
        Boolean messageFound = false;
        for (ApexPages.Message message : pageMessages) {
            if ( message.getSeverity() == ApexPages.Severity.Error
              && message.getDetail() == Label.npe01.Contact_Merge_Error_Too_Many_Contacts) {
                messageFound = true;
            }
        }
        System.assert(messageFound);
        //Exception is thrown hence the selectedRecordsCount is not populated.
        System.assertEquals(controller.selectedRecordsCount, 0 );

        Test.stopTest();
    }

    public static void getDuplicateSetOfRecords(Integer duplicateRecordSize) {
        getDuplicateSetOfRecords(duplicateRecordSize, 2, false);
    }
    
    //Create the duplicate data for contact
    public static void getDuplicateSetOfRecords(Integer duplicateRecordSize,
                                                Integer contactsPerSet,
                                                Boolean createLeads) {
        DuplicateRule dR = [
                            SELECT 
                                Id
                            FROM 
                                DuplicateRule
                            Where
                                SobjectType = 'Contact'
                            LIMIT 1
                            ];
        //Create Original Contacts
        List<Contact> contacts = UTIL_UnitTestData_TEST.createMultipleTestContacts(duplicateRecordSize);
        insert contacts;
        
        //Create Duplicate Record Set
        List<DuplicateRecordSet> dupRSList = getDuplicateRecordSets(dR.Id , duplicateRecordSize);
        insert dupRSList;
        
        //Create Duplicate Contact Records
        List<Contact> duplicatecontacts = UTIL_UnitTestData_TEST.createMultipleTestContacts(duplicateRecordSize);

        //Create Duplicate Leads
        List<Lead> duplicateleads;
        if (createLeads) {
            //Create Duplicate Contact Records
            duplicateleads = UTIL_UnitTestData_TEST.createMultipleTestLeads(duplicateRecordSize);
            insert duplicateleads;
        }
        
        //Create Duplicate Record Items
        List<DuplicateRecordItem> duplicateRecordItems = new List<DuplicateRecordItem>();

        Database.DMLOptions insertDML = new Database.DMLOptions(); 
        insertDML.DuplicateRuleHeader.AllowSave = true; 
        List<Database.SaveResult> srList  = Database.insert(duplicatecontacts, insertDML);
        Integer index = 0 ;
        for (Database.SaveResult sr : srList) {
            if (sr.isSuccess()) {
                duplicateRecordItems.add(getDuplicateRecordItem(dupRSList[index].Id , sr.getId()));
                if (contactsPerSet == 2) {
                    duplicateRecordItems.add(getDuplicateRecordItem(dupRSList[index].Id, contacts[index].Id));
                }
                if (createLeads) {
                    duplicateRecordItems.add(getDuplicateRecordItem(dupRSList[index].Id, duplicateleads[index].Id));
                }
            }
            index = index + 1;
        }
        insert duplicateRecordItems;
    }
   
    //Create Duplicate Record Sets
    public static List<DuplicateRecordSet> getDuplicateRecordSets(Id duplicateRuleId, Integer count) {
        List<DuplicateRecordSet> drsList = new List<DuplicateRecordSet>();
        for (Integer i = 0; i < count; i++) {
            drsList.add(
                new DuplicateRecordSet(DuplicateRuleId = duplicateRuleId)
            );
        }
        return drsList;
    }

    //Create Duplicate Record Items
    public static DuplicateRecordItem getDuplicateRecordItem(Id drsId, Id recordId) {
        return new DuplicateRecordItem(
            DuplicateRecordSetId = drsId,
            RecordId = recordId
        );
    }

    private static List<Id> getFixedSearchResultsForSOSL(Integer numberOfResults) {
        return UTIL_UnitTestData_TEST.mockIds(Contact.SObjectType, numberOfResults);
    }

    private static List<Contact> getMockContactsWithIds(Integer numberOfResults) {
        List<Contact> mockContacts = new List<Contact>();
        for (Integer i = 0; i < numberOfResults; i++) {
            Contact testContact = UTIL_UnitTestData_TEST.getContact();
            UTIL_UnitTestData_TEST.setMockId(testContact);

            mockContacts.add(testContact);
        }
        return mockContacts;
    }

    private static List<CON_ContactMerge_CTRL.FieldRow> getMockFieldRows(List<String> fieldNames,
            List<Contact> contacts) {
        List<CON_ContactMerge_CTRL.FieldRow> mockFieldRows = new List<CON_ContactMerge_CTRL.FieldRow>();
        for (Integer i=0; i < fieldNames.size(); i++) {
            CON_ContactMerge_CTRL.FieldRow mockFieldRow = new CON_ContactMerge_CTRL.FieldRow();

            if (isMasterRecordField(fieldNames[i])) {
                mockFieldRow.fieldName = CON_ContactMerge_CTRL.MASTER_KEY;
                mockFieldRow.fieldLabel = 'Master Record';
                mockFieldRow.showRadio = true;
            } else {
                mockFieldRow.fieldLabel = 'Test Field ' + i;
                mockFieldRow.fieldName = 'Test_Field_' + i;
                mockFieldRow.showRadio = true;
            }

            List<CON_ContactMerge_CTRL.Cell> mockCells = getMockCells(fieldNames[i], contacts);
            mockFieldRow.values = mockCells;
            mockFieldRows.add(mockFieldRow);
        }
        return mockFieldRows;
    }

    private static List<CON_ContactMerge_CTRL.Cell> getMockCells(String fieldName, List<Contact> contacts) {
        List<CON_ContactMerge_CTRL.Cell> mockCells = new List<CON_ContactMerge_CTRL.Cell>();
        for (Contact contact : contacts) {
            CON_ContactMerge_CTRL.Cell mockCell = new CON_ContactMerge_CTRL.Cell(
                contact.Id,
                getCellValue(fieldName, contact)
            );
            mockCells.add(mockCell);
        }
        return mockCells;
    }

    private static String getCellValue(String fieldName, Contact contact) {
        if (isMasterRecordField(fieldName)) {
            return String.valueOf(contact.Id);
        } else {
           return String.valueOf(contact.get(fieldName));
        }
    }

    private static Boolean isMasterRecordField(String fieldName) {
        return fieldName == CON_ContactMerge_CTRL.MASTER_KEY;
    }

    private static CON_ContactMerge_CTRL getControllerForSearch() {
        Test.setCurrentPageReference(new PageReference('Page.CON_ContactMerge'));
        CON_ContactMerge_CTRL controller = new CON_ContactMerge_CTRL(new ApexPages.StandardSetController(new List<Contact>()));
        controller.showContactSearch = true;
        controller.searchText = 'test';
        return controller;
    }

    private static CON_ContactMerge_CTRL getController() {
        Test.setCurrentPageReference(new PageReference('Page.CON_ContactMerge'));
        CON_ContactMerge_CTRL controller = new CON_ContactMerge_CTRL(new ApexPages.StandardSetController(new List<Contact>()));
        return controller;
    }

    //todo: is this needed?
    private static Map<String,Map<Id, Object>> getContactRecordValuesByFieldName(List<Contact> contacts) {
        Map<String, Map<Id, Object>> contactRecordValuesByFieldName = new Map<String, Map<Id, Object>>();
        for (Contact contact : contacts) {
            Map<String, Object> valuesByPopulatedField = contact.getPopulatedFieldsAsMap();
        }
        return new Map<String,Map<Id, Object>>();
    }

    private static ContactMergeSelector stubFor(StubProvider mock) {
        return  (ContactMergeSelector) Test.createStub(
                ContactMergeSelector.class,
                mock
        );
    }

    private class UnitOfWorkMock implements StubProvider {
        List<Contact> contactsToUpdate;
        List<Contact> contactsToDelete;
        Boolean saveCalled = false;

        public Object handleMethodCall(Object stubbedObject,
                String stubbedMethodName,
                Type returnType,
                List<Type> listOfParamTypes,
                List<String> listOfParamNames,
                List<Object> listOfArgs) {

            switch on (stubbedMethodName) {
                when 'registerDirty' {
                    contactsToUpdate = (List<Contact>)listOfArgs;
                }
                when 'registerDelete' {
                    contactsToDelete = (List<Contact>)listOfArgs;
                }
                when 'save' {
                    saveCalled = true;
                    return new List<Database.SaveResult>();
                }
            }

            return null;
        }
    }

    private class ContactMergeSelectorMock implements StubProvider {
        Integer numberOfResults;

        public ContactMergeSelectorMock(Integer numberOfResults) {
            this.numberOfResults = numberOfResults;
        }

        public Object handleMethodCall(Object stubbedObject,
                String stubbedMethodName,
                Type returnType,
                List<Type> listOfParamTypes,
                List<String> listOfParamNames,
                List<Object> listOfArgs) {

            switch on (stubbedMethodName) {
                when 'selectContactsByName' {
                    List<Contact> contacts = UTIL_UnitTestData_TEST.getContacts(numberOfResults);
                    UTIL_UnitTestData_TEST.setMockIds(contacts);

                    return contacts;
                }

            }

            return null;
        }
    }
}
