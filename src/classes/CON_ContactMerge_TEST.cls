/*
    Copyright (c) 2009, Salesforce.com Foundation
    All rights reserved.
    
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
    
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Salesforce.com Foundation nor the names of
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
* @author Salesforce.com Foundation
* @date 2011 (2.x)
* @description Tests for CON_ContactMerge_CTRL 
*/
@isTest
private class CON_ContactMerge_TEST {

    /**
    * @description if you only want to run one test in this class, fill in its name here.
    * if you want to run all tests, then use '*'
    */
    private static string strTestOnly = '*';
    
    static testMethod void exerciseUIOne2One(){
        if (strTestOnly != '*' && strTestOnly != 'exerciseUIOne2One') return;
        exerciseUI(CAO_Constants.ONE_TO_ONE_PROCESSOR);
    }
    static testMethod void exerciseUIHHAccount(){
        if (strTestOnly != '*' && strTestOnly != 'exerciseUIHHAccount') return;
        exerciseUI(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    }    
    //exercise the many UI variables
    static void exerciseUI(string strProcessor) {

        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (npe01__Account_Processor__c = strProcessor));
        
        //set up 3 contacts for the merge interface to work with
        Contact con = UTIL_UnitTestData_TEST.getContact();
        
        Contact con2 = UTIL_UnitTestData_TEST.getContact();
        con2.LastName = '2Contact_forTests_Merge';
        
        Contact con3 = UTIL_UnitTestData_TEST.getContact();
        con3.LastName = '3Contact_forTests_Merge';
        
        insert new Contact[]{con, con2, con3};
        
        Test.setCurrentPageReference(new PageReference('Page.CON_ContactMerge'));  
        CON_ContactMerge_CTRL controller = new CON_ContactMerge_CTRL(new ApexPages.Standardsetcontroller(new list<Contact>()));
        controller.searchText = 'test';
        
        Test.startTest();
        controller.search();
        
        //Since we didn't index the results yet, search results should be empty and should not be displayed
        system.assert(controller.searchResults.isEmpty());

        Id[] fixedSearchResults=new Id[3]; 
        fixedSearchResults[0]=con.Id; 
        fixedSearchResults[1]=con2.Id; 
        fixedSearchResults[2]=con3.Id; 
        
        Test.setFixedSearchResults(fixedSearchResults); 
        
        //call the search method, which will return the bogus SOSL results
        controller.search();
        
        //search results should be displayed
        system.assert(!controller.searchResults.isEmpty());
        
        //there should be 3 Contacts returned
        system.assertEquals(3,controller.searchResults.size());
        
        controller.searchResults[0].selected = true;
        
        controller.nextStep();
        
        System.assertEquals(1, ApexPages.getMessages().size()); // Selecting only one record for merge should throw an error.
        ApexPages.Message m = ApexPages.getMessages()[0];
        System.assertEquals(ApexPages.Severity.Error, m.getSeverity());
        System.assertEquals(label.npe01.Contact_Merge_Error_Too_Few_Contacts, m.getDetail());
        System.assertEquals(1, controller.step); // We should still be on step 1
        
        controller.search();
        controller.searchResults[0].selected = true;
        controller.searchResults[1].selected = true; // Select second contact
        String record1Id = controller.searchResults[1].con.id;
        
        controller.nextStep();
        
        Test.stopTest(); 
        
        System.assertEquals(2, controller.step); // We are on to next step now
        
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
        
        // Test select all for a record
        ApexPages.currentPage().getParameters().put('recordId', record1Id);
        controller.selectDefaultRecord();
        
        for (CON_ContactMerge_CTRL.FieldRow row : fieldRows) {
            if (row.showRadio) {
                System.assertEquals(record1Id, row.selectedValue); // Since we selected all radios for contact 2, contact 2 id should be the selected value
            }
        }
    }
    
    static testMethod void failNextStepWithDeletedRecordSelectedOne2One(){
        if (strTestOnly != '*' && strTestOnly != 'failNextStepWithDeletedRecordSelectedOne2One') return;
        failNextStepWithDeletedRecordSelected(CAO_Constants.ONE_TO_ONE_PROCESSOR);
    }
    static testMethod void failNextStepWithDeletedRecordSelectedHHAccount(){
        if (strTestOnly != '*' && strTestOnly != 'failNextStepWithDeletedRecordSelectedHHAccount') return;
        failNextStepWithDeletedRecordSelected(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    }    
    // Try selecting a deleted record for merge
    static void failNextStepWithDeletedRecordSelected(string strProcessor) {
        
        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (npe01__Account_Processor__c = strProcessor));
        
        //set up 2 contacts for the merge interface to work with
        Contact con = UTIL_UnitTestData_TEST.getContact();
        
        Contact con2 = UTIL_UnitTestData_TEST.getContact();
        con2.LastName = '2Contact_forTests_Merge';
        
        insert new Contact[]{con, con2};
 
        Test.setCurrentPageReference(new PageReference('Page.CON_ContactMerge')); 
        CON_ContactMerge_CTRL controller = new CON_ContactMerge_CTRL(new ApexPages.Standardsetcontroller(new list<Contact>()));
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
        System.assertEquals(1, controller.step); // We should still be on step 1
        
        Test.stopTest(); 
    }
    
    static testMethod void failMergeWithDeletedRecordSelectedOne2One(){
        if (strTestOnly != '*' && strTestOnly != 'failMergeWithDeletedRecordSelectedOne2One') return;
        failMergeWithDeletedRecordSelected(CAO_Constants.ONE_TO_ONE_PROCESSOR);
    }
    static testMethod void failMergeWithDeletedRecordSelectedHHAccount(){
        if (strTestOnly != '*' && strTestOnly != 'failMergeWithDeletedRecordSelectedHHAccount') return;
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
        if (strTestOnly != '*' && strTestOnly != 'tooFewContactsSelectedOne2One') return;
        tooFewContactsSelected(CAO_Constants.ONE_TO_ONE_PROCESSOR);
    }
    static testMethod void tooFewContactsSelectedHHAccount(){
        if (strTestOnly != '*' && strTestOnly != 'tooFewContactsSelectedHHAccount') return;
        tooFewContactsSelected(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    }    
    static void tooFewContactsSelected(string strProcessor) {
        
        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (npe01__Account_Processor__c = strProcessor));
        
        //set up 1 contact for the merge interface to work with
        Contact con = UTIL_UnitTestData_TEST.getContact();
        insert con;
        
        Test.setCurrentPageReference(new PageReference('Page.CON_ContactMerge'));   
        CON_ContactMerge_CTRL controller = new CON_ContactMerge_CTRL(new ApexPages.Standardsetcontroller(new list<Contact>()));     
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
        if (strTestOnly != '*' && strTestOnly != 'tooManyContactsSelectedOne2One') return;
        tooManyContactsSelected(CAO_Constants.ONE_TO_ONE_PROCESSOR);
    }
    static testMethod void tooManyContactsSelectedHHAccount(){
        if (strTestOnly != '*' && strTestOnly != 'tooManyContactsSelectedHHAccount') return;
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
        
        System.assertEquals(1, ApexPages.getMessages().size()); // Selecting only one record for merge should throw an error.
        ApexPages.Message m = ApexPages.getMessages()[0];
        System.assertEquals(ApexPages.Severity.Error, m.getSeverity());
        System.assertEquals(label.npe01.Contact_Merge_Error_Too_Many_Contacts, m.getDetail());
    }
    
    private static void selectMasterRecord(CON_ContactMerge_CTRL cont, Id masterId) {
        for (CON_ContactMerge_CTRL.FieldRow row : cont.fieldRows) {
            if (row.showRadio) {
                row.selectedValue = String.valueOf(masterId);
            }
        }   
    }
    
    static testMethod void merge2OneToOneOne2One(){
        if (strTestOnly != '*' && strTestOnly != 'merge2OneToOneOne2One') return;
        merge2OneToOne(CAO_Constants.ONE_TO_ONE_PROCESSOR);
    }
    static testMethod void merge2OneToOneHHAccount(){
        if (strTestOnly != '*' && strTestOnly != 'merge2OneToOneHHAccount') return;
        merge2OneToOne(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    }    
    //merge two contacts that are both in the one-to-one account model
    //the second contact's org should be deleted
    static void merge2OneToOne(string strProcessor) {
        
        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (npe01__Account_Processor__c = strProcessor));

        Contact con = UTIL_UnitTestData_TEST.getContact();
        
		Contact con2 = UTIL_UnitTestData_TEST.getContact();
		con2.LastName = '2Contact_forTests_Merge';
		
        insert new Contact[]{con, con2};
        
        con = [Select id, accountId, FirstName, LastName, MailingStreet from Contact where Id = :con.id];
        con2 = [Select id, accountId, FirstName, LastName, MailingStreet from Contact where Id = :con2.id];
        
        Test.setCurrentPageReference(new PageReference('Page.CON_ContactMerge'));
        
        CON_ContactMerge_CTRL controller = new CON_ContactMerge_CTRL(new ApexPages.Standardsetcontroller(new list<Contact>()));
        
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
        if (strTestOnly != '*' && strTestOnly != 'merge2OneToOneOppsOne2One') return;
        merge2OneToOneOpps(CAO_Constants.ONE_TO_ONE_PROCESSOR);
    }
    static testMethod void merge2OneToOneOppsHHAccount(){
        if (strTestOnly != '*' && strTestOnly != 'merge2OneToOneOppsHHAccount') return;
        merge2OneToOneOpps(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    }    
    //merge two contacts that are both in the one-to-one account model
    //the second contact's org shouldn't be deleted because it has open opportunities
    static void merge2OneToOneOpps(string strProcessor) {
        
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
        
        //select the first as winner
        controller.nextStep();
        
        selectMasterRecord(controller, con2.id);
        
        //merge them
        Test.startTest();
        controller.mergeContacts();
        Test.stopTest();
        
        //first contact should be deleted
        system.assertEquals(1,[select count() from Contact where id=:con2.id]);
        system.assertEquals(0,[select count() from Contact where id=:con.id]);
        //first contact's account should be deleted
        system.assertEquals(1,[select count() from Account where id=:con2.AccountId]);
        system.assertEquals(0,[select count() from Account where id=:con.accountId]);
        
        // check opps
        system.assertEquals(1,[select count() from Opportunity where accountId=:con2.AccountId]);
        
        //Second contact's account id should not have changed
        system.assertEquals(con2.AccountId,[select AccountId from Contact where id=:con2.id].AccountId);
    }
    
    static testMethod void merge2OrganizationsOne2One(){
        if (strTestOnly != '*' && strTestOnly != 'merge2OrganizationsOne2One') return;
        merge2Organizations(CAO_Constants.ONE_TO_ONE_PROCESSOR);
    }
    static testMethod void merge2OrganizationsHHAccount(){
        if (strTestOnly != '*' && strTestOnly != 'merge2OrganizationsHHAccount') return;
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
        if (strTestOnly != '*' && strTestOnly != 'merge2PrivateContactsOne2One') return;
        merge2PrivateContacts(CAO_Constants.ONE_TO_ONE_PROCESSOR);
    }
    static testMethod void merge2PrivateContactsHHAccount(){
        if (strTestOnly != '*' && strTestOnly != 'merge2PrivateContactsHHAccount') return;
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
        if (strTestOnly != '*' && strTestOnly != 'merge2IndividualsOne2One') return;
        merge2Individuals(CAO_Constants.ONE_TO_ONE_PROCESSOR);
    }
    static testMethod void merge2IndividualsHHAccount(){
        if (strTestOnly != '*' && strTestOnly != 'merge2IndividualsHHAccount') return;
        merge2Individuals(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    }    
    //merge two contacts in the Individual Account
    //the organization shouldn't be deleted
    static void merge2Individuals(string strProcessor) {
        
        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (npe01__Account_Processor__c = CAO_Constants.BUCKET_PROCESSOR));
        
        Contact con = UTIL_UnitTestData_TEST.getContact();
        
        Contact con2 = UTIL_UnitTestData_TEST.getContact();
        con2.LastName = '2Contact_forTests_Merge';
        
        insert new Contact[]{con, con2};
        
        con = [Select id, accountId, FirstName, LastName, MailingStreet from Contact where Id = :con.id];
        con2 = [Select id, accountId, FirstName, LastName, MailingStreet from Contact where Id = :con2.id];
        
        Test.setCurrentPageReference(new PageReference('Page.CON_ContactMerge'));
        
        CON_ContactMerge_CTRL controller = new CON_ContactMerge_CTRL(new ApexPages.Standardsetcontroller(new list<Contact>()));
        
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
        system.assertEquals(1,[select count() from Account where id=:con2.AccountId]);
        system.assertEquals(1,[select count() from Account where id=:con.AccountId]);
        //First contact's account id should not have changed
        system.assertEquals(con.accountId,[select AccountId from Contact where id=:con.id].AccountId);
    }
    /*
    //merge one contacts in the Individual Account, one in one-to-one model
    //the individual organization shouldn't be deleted
    static testMethod void merge1Individual1OneToOne() {
        
        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (npe01__Account_Processor__c = strProcessor));
        
        Contact con = UTIL_UnitTestData_TEST.getContact();
        
        Contact con2 = UTIL_UnitTestData_TEST.getContact();
        con2.LastName = '2Contact_forTests_Merge';
        
        insert new Contact[]{con, con2};
        
        con = [Select id, accountId, FirstName, LastName, MailingStreet from Contact where Id = :con.id];
        con2 = [Select id, accountId, FirstName, LastName, MailingStreet from Contact where Id = :con2.id];
        
        Test.setCurrentPageReference(new PageReference('Page.CON_ContactMerge'));
        
        CON_ContactMerge_CTRL controller = new CON_ContactMerge_CTRL(new ApexPages.Standardsetcontroller(new list<Contact>()));
        
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
        system.assertEquals(1,[select count() from Account where id=:con2.AccountId]);
        system.assertEquals(1,[select count() from Account where id=:con.AccountId]);
        //First contact's account id should not have changed
        system.assertEquals(con.AccountId,[select AccountId from Contact where id=:con.Id].AccountId);
    }
    
    //merge one contacts in the Individual Account, one in one-to-one model
    //the individual organization shouldn't be deleted
    static testMethod void merge1OneToOne1Individual() {
        
        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (npe01__Account_Processor__c = CAO_Constants.BUCKET_PROCESSOR));
        
        Contact con = UTIL_UnitTestData_TEST.getContact();
        
        Contact con2 = UTIL_UnitTestData_TEST.getContact();
        con2.LastName = '2Contact_forTests_Merge';
        
        insert new Contact[]{con, con2};
        
        con = [Select id, accountId, FirstName, LastName, MailingStreet from Contact where Id = :con.id];
        con2 = [Select id, accountId, FirstName, LastName, MailingStreet from Contact where Id = :con2.id];
        
        Test.setCurrentPageReference(new PageReference('Page.CON_ContactMerge'));
        
        CON_ContactMerge_CTRL controller = new CON_ContactMerge_CTRL(new ApexPages.Standardsetcontroller(new list<Contact>()));
        
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
    */


    static testMethod void merge1Org1OneToOneOne2One(){
        if (strTestOnly != '*' && strTestOnly != 'merge1Org1OneToOneOne2One') return;
        merge1Org1OneToOne(CAO_Constants.ONE_TO_ONE_PROCESSOR);
    }
    static testMethod void merge1Org1OneToOneHHAccount(){
        if (strTestOnly != '*' && strTestOnly != 'merge1Org1OneToOneHHAccount') return;
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
    
    static testMethod void merge3OneToOneOne2One(){
        if (strTestOnly != '*' && strTestOnly != 'merge3OneToOneOne2One') return;
        merge3OneToOne(CAO_Constants.ONE_TO_ONE_PROCESSOR);
    }
    static testMethod void merge3OneToOneHHAccount(){
        if (strTestOnly != '*' && strTestOnly != 'merge3OneToOneHHAccount') return;
        merge3OneToOne(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    }    
    static void merge3OneToOne(string strProcessor) {
        
        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (npe01__Account_Processor__c = strProcessor));
        
        Contact con = UTIL_UnitTestData_TEST.getContact();
        
        Contact con2 = UTIL_UnitTestData_TEST.getContact();
        con2.LastName = '2Contact_forTests_Merge';
        
        Contact con3 = UTIL_UnitTestData_TEST.getContact();
        con3.LastName = '3Contact_forTests_Merge';
        
        insert new Contact[]{con, con2, con3};
        
        con = [Select id, accountId, FirstName, LastName, MailingStreet from Contact where Id = :con.id];
        con2 = [Select id, accountId, FirstName, LastName, MailingStreet from Contact where Id = :con2.id];
        con3 = [Select id, accountId, FirstName, LastName, MailingStreet from Contact where Id = :con3.id];
        
        Test.setCurrentPageReference(new PageReference('Page.CON_ContactMerge'));
        
        CON_ContactMerge_CTRL controller = new CON_ContactMerge_CTRL(new ApexPages.Standardsetcontroller(new list<Contact>()));
        
        controller.searchText = 'test';
        //SOSL always returns nothing in tests, unless you use the setFixedSearchResults value
        Id[] fixedSearchResults=new Id[3]; 
        fixedSearchResults[0]=con.Id; 
        fixedSearchResults[1]=con2.Id; 
        fixedSearchResults[2]=con3.Id; 
        
        Test.setFixedSearchResults(fixedSearchResults); 
        
        controller.search();
        
        //select the two contacts and grab them
        controller.searchResults[0].selected = true;
        controller.searchResults[1].selected = true;
        controller.searchResults[2].selected = true;
        
        controller.nextStep();
        
        selectMasterRecord(controller, con3.id);
        
        //merge them
        controller.mergeContacts();
        
        //first and second contact should be deleted
        system.assertEquals(1,[select count() from Contact where id=:con3.id]);
        system.assertEquals(0,[select count() from Contact where id=:con2.id]);
        system.assertEquals(0,[select count() from Contact where id=:con.id]);
        //first and second contact's account should be deleted
        system.assertEquals(1,[select count() from Account where id=:con3.AccountId]);
        system.assertEquals(0,[select count() from Account where id=:con2.AccountId]);
        system.assertEquals(0,[select count() from Account where id=:con.AccountId]);
        //Third contact's account id should not have changed
        system.assertEquals(con3.AccountId,[select AccountId from Contact where id=:con3.id].AccountId);
    }
    
    static testMethod void merge2OneToOneInSameAccountOne2One(){
        if (strTestOnly != '*' && strTestOnly != 'merge2OneToOneInSameAccountOne2One') return;
        merge2OneToOneInSameAccount(CAO_Constants.ONE_TO_ONE_PROCESSOR);
    }
    static testMethod void merge2OneToOneInSameAccountHHAccount(){
        if (strTestOnly != '*' && strTestOnly != 'merge2OneToOneInSameAccountHHAccount') return;
        merge2OneToOneInSameAccount(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    }    
    //merge two contacts that are both in the one-to-one account model
    //the second contact's org should be deleted
    static void merge2OneToOneInSameAccount(string strProcessor) {
        
        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (npe01__Account_Processor__c = strProcessor));

        Contact con = UTIL_UnitTestData_TEST.getContact();
        insert con;
        
        Id conAccountId = [select accountId from Contact where id=:con.id].accountId;
        
        Contact con2 = UTIL_UnitTestData_TEST.getContact();
        con2.LastName = '2Contact_forTests_Merge';
        con2.AccountId = conAccountId;
        
        insert con2;
        
        con = [Select id, accountId, FirstName, LastName, MailingStreet from Contact where Id = :con.id];
        con2 = [Select id, accountId, FirstName, LastName, MailingStreet from Contact where Id = :con2.id];
        
        Test.setCurrentPageReference(new PageReference('Page.CON_ContactMerge'));
        
        CON_ContactMerge_CTRL controller = new CON_ContactMerge_CTRL(new ApexPages.Standardsetcontroller(new list<Contact>()));
        
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
        Test.startTest();
        controller.mergeContacts();
        Test.stopTest();
        
        //second contact should be deleted
        system.assertEquals(0,[select count() from Contact where id=:con2.id]);
        system.assertEquals(1,[select count() from Contact where id=:con.id]);
        if (strProcessor == CAO_Constants.ONE_TO_ONE_PROCESSOR) {
	        //second contact's account shouldn't be deleted
	        system.assertEquals(0,[select count() from Account where id=:con2.AccountId]);
	        system.assertEquals(1,[select count() from Account where id=:con.AccountId]);
        } else {
            //contacts have the same account which should not be deleted
            system.assertEquals(con.AccountId, con2.AccountId);
            system.assertEquals(1,[select count() from Account where id=:con.AccountId]);       
        }
        //First contact's account id should not have changed
        system.assertEquals(con.AccountId,[select AccountId from Contact where id=:con.id].AccountId);
    }
    
    static testMethod void ghIssue6One2One(){
        if (strTestOnly != '*' && strTestOnly != 'ghIssue6One2One') return;
        ghIssue6(CAO_Constants.ONE_TO_ONE_PROCESSOR);
    }
    static testMethod void ghIssue6HHAccount(){
        if (strTestOnly != '*' && strTestOnly != 'ghIssue6HHAccount') return;
        ghIssue6(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    }    
    static void ghIssue6(string strProcessor){
        
        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (npe01__Account_Processor__c = strProcessor));
                
        Contact con = UTIL_UnitTestData_TEST.getContact();
        con.LastName = 'O\'Sullivan';
        
        Contact con2 = UTIL_UnitTestData_TEST.getContact();
        con2.LastName = 'O\'Sullivan';
        
        insert new Contact[]{con, con2};
        
        con = [Select id, accountId, FirstName, LastName, MailingStreet from Contact where Id = :con.id];
        system.assertEquals(con.LastName, 'O\'Sullivan');
                
        Test.setCurrentPageReference(new PageReference('Page.CON_ContactMerge'));
        CON_ContactMerge_CTRL controller = new CON_ContactMerge_CTRL(new ApexPages.Standardsetcontroller(new list<Contact>()));
        
        controller.searchText = 'O\'Sullivan';
        //SOSL always returns nothing in tests, unless you use the setFixedSearchResults value
        List<Id> fixedSearchResults=new List<Id>(); 
        fixedSearchResults.add(con.Id);
        fixedSearchResults.add(con2.Id);  
        Test.setFixedSearchResults(fixedSearchResults); 
        controller.search();
        
        //select the two contacts and grab them
        controller.searchResults[0].selected = true;
        controller.searchResults[1].selected = true;        
        
        controller.nextStep();
        
        selectMasterRecord(controller, con2.id);
        
        //merge them
        controller.mergeContacts();
    /*    
        //first and second contact should be deleted
        system.assertEquals(1,[select count() from Contact where id=:con3.id]);
        system.assertEquals(0,[select count() from Contact where id=:con2.id]);
        system.assertEquals(0,[select count() from Contact where id=:con.id]);
        //first and second contact's account should be deleted
        system.assertEquals(1,[select count() from Account where id=:con3.AccountId]);
        system.assertEquals(0,[select count() from Account where id=:con2.AccountId]);
        system.assertEquals(0,[select count() from Account where id=:con.AccountId]);
        //Third contact's account id should not have changed
        system.assertEquals(con3.AccountId,[select AccountId from Contact where id=:con3.id].AccountId);*/
        
        
    }
  
    public static testmethod  void householdDifferentFromMaster() {
        if (strTestOnly != '*' && strTestOnly != 'householdDifferentFromMaster') return;
        npe01__Contacts_And_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_And_Orgs_Settings__c (npe01__Account_Processor__c = CAO_Constants.ONE_TO_ONE_PROCESSOR));
        
        npo02__Households_Settings__c householdSettingsForTests = UTIL_CustomSettingsFacade.getHouseholdsSettingsForTests(
            new npo02__Households_Settings__c (npo02__Household_Rules__c = HH_Households.ALL_PROCESSOR));
        
        Contact con = UTIL_UnitTestData_TEST.getContact();
        
        Contact con2 = UTIL_UnitTestData_TEST.getContact();
        con2.LastName = '2Contact_forTests_Merge';
        
        insert new Contact[] {con, con2};
        
        Id hh1Id = [select npo02__Household__c from Contact where Id = :con.Id].npo02__Household__c;
        Id hh2Id = [select npo02__Household__c from Contact where Id = :con2.Id].npo02__Household__c;
        System.assertNotEquals(null, hh1Id);
        System.assertNotEquals(null, hh2Id);
         
        Test.setCurrentPageReference(new PageReference('Page.CON_ContactMerge'));
        
        CON_ContactMerge_CTRL controller = new CON_ContactMerge_CTRL(new ApexPages.Standardsetcontroller(new list<Contact>()));
        
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
        //Select the household of the one that is not the one we selected as master
        List<CON_ContactMerge_CTRL.FieldRow> fieldRows = controller.fieldRows;  
        for (CON_ContactMerge_CTRL.FieldRow row : fieldRows) {
        	if(row.fieldName == 'npo02__household__c') {
                row.selectedValue = String.valueOf(con2.id);
                break;
        	}
        }
        
        //merge them
        controller.mergeContacts();
        
        //Merged contact should reference the second contact's household
        System.assertEquals(hh2Id, [select npo02__Household__c from Contact where id=:con.id].npo02__Household__c);
    }  

    
    //check a standard set controller passed into the page is handled correctly
    static testMethod void testStandardSetSelected(){
        if (strTestOnly != '*' && strTestOnly != 'testStandardSetSelected') return;
        
        npe01__Contacts_And_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_And_Orgs_Settings__c (npe01__Account_Processor__c = CAO_Constants.ONE_TO_ONE_PROCESSOR));
        
        Contact con = UTIL_UnitTestData_TEST.getContact();        
        Contact con2 = UTIL_UnitTestData_TEST.getContact();
        insert new Contact[]{con, con2};
                
        Test.setCurrentPageReference(new PageReference('Page.CON_ContactMerge'));
        
        //create standard set controller with 2 records
        ApexPages.Standardsetcontroller ssc =new ApexPages.Standardsetcontroller(new list<Contact>{con,con2});
        
        //select these two records for merge
        ssc.setSelected(new list<Contact>{con,con2});
        
        CON_ContactMerge_CTRL controller = new CON_ContactMerge_CTRL(ssc);
        
        //check we ended up on step 2 of the merge
        system.assertEquals(2, controller.step); 
        
        //check 2 records selected
        system.assertEquals(2, controller.selectedRecordsCount);
        
        //and that fields were populated
        system.assert(!controller.fieldRows.isEmpty());
    }
  
    //check a search term passed into the page is handled correctly
    static testMethod void testSearchSpecPassed(){
        if (strTestOnly != '*' && strTestOnly != 'testSearchSpecPassed') return;
        
        npe01__Contacts_And_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_And_Orgs_Settings__c (npe01__Account_Processor__c = CAO_Constants.ONE_TO_ONE_PROCESSOR));
        
        Contact con = UTIL_UnitTestData_TEST.getContact();        
        Contact con2 = UTIL_UnitTestData_TEST.getContact();
        insert new Contact[]{con, con2};
        
        list<Id> fixedSearchResults = new List<Id>(); 
        fixedSearchResults.add(con.Id);
        fixedSearchResults.add(con2.Id);  
        Test.setFixedSearchResults(fixedSearchResults); 
        
        PageReference pr = Page.CON_ContactMerge;
        pr.getParameters().put('srch', 'O\'Sullivan');
        
        Test.setCurrentPageReference(pr);
        
        CON_ContactMerge_CTRL controller = new CON_ContactMerge_CTRL(new ApexPages.Standardsetcontroller(new list<Contact>()));
        
        //check we ended up on step 1 of the merge
        system.assertEquals(1, controller.step); 
        
        //check the 2 records already retrieved in search results
        system.assertEquals(2, controller.searchResults.size());
    }
    
    //check a comma separated list of Ids are handled correctly
    static testMethod void testGoodIdsPassed(){
        if (strTestOnly != '*' && strTestOnly != 'testGoodIdsPassed') return;
        
        npe01__Contacts_And_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_And_Orgs_Settings__c (npe01__Account_Processor__c = CAO_Constants.ONE_TO_ONE_PROCESSOR));
        
        Contact con = UTIL_UnitTestData_TEST.getContact();        
        Contact con2 = UTIL_UnitTestData_TEST.getContact();
        insert new Contact[]{con, con2};
        
        PageReference pr = Page.CON_ContactMerge;
        pr.getParameters().put('mergeIds', con.Id + ',' + con2.Id);
        
        Test.setCurrentPageReference(pr);
        
        CON_ContactMerge_CTRL controller = new CON_ContactMerge_CTRL(new ApexPages.Standardsetcontroller(new list<Contact>()));
        
        //check we ended up on step 2 of the merge
        system.assertEquals(2, controller.step); 
        
        //check 2 records selected
        system.assertEquals(2, controller.selectedRecordsCount);
        
        //and that fields were populated
        system.assert(!controller.fieldRows.isEmpty());
    }
    
    //check invalid Ids are handled
    static testMethod void testBadIdsPassed(){
        if (strTestOnly != '*' && strTestOnly != 'testBadIdsPassed') return;
        
        npe01__Contacts_And_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_And_Orgs_Settings__c (npe01__Account_Processor__c = CAO_Constants.ONE_TO_ONE_PROCESSOR));
        
        Contact con = UTIL_UnitTestData_TEST.getContact();        
        Contact con2 = UTIL_UnitTestData_TEST.getContact();
        insert new Contact[]{con, con2};
        
        list<Id> fixedSearchResults = new List<Id>(); 
        fixedSearchResults.add(con.Id);
        fixedSearchResults.add(con2.Id);  
        Test.setFixedSearchResults(fixedSearchResults); 
        
        PageReference pr = Page.CON_ContactMerge;
        pr.getParameters().put('mergeIds', 'blah');
        
        Test.setCurrentPageReference(pr);
        
        CON_ContactMerge_CTRL controller = new CON_ContactMerge_CTRL(new ApexPages.Standardsetcontroller(new list<Contact>()));
        
        //check we ended up on step 1 of the merge
        system.assertEquals(1, controller.step); 
        
        //check error message logged to the page
        system.assert(ApexPages.hasMessages()); 
        
    }
    
    static testMethod void personAccountErrorDetection() {
        if (strTestOnly != '*' && strTestOnly != 'personAccountErrorDetection') return;
        
        // detect PersonAccounts
        boolean isPAEnabled = UTIL_Describe.isValidField('Account', 'isPersonAccount');
        if (!isPAEnabled)
            return;
        
        npe01__Contacts_And_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_And_Orgs_Settings__c (npe01__Account_Processor__c = CAO_Constants.ONE_TO_ONE_PROCESSOR));
        
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

        list<Id> fixedSearchResults = new List<Id>(); 
        fixedSearchResults.add(pa1.Id);
        fixedSearchResults.add(pa2.Id);  
        Test.setFixedSearchResults(fixedSearchResults); 
        
        PageReference pr = Page.CON_ContactMerge;
        pr.getParameters().put('mergeIds', pa1.Id + ',' + pa2.Id);
        
        Test.setCurrentPageReference(pr);
        
        CON_ContactMerge_CTRL controller = new CON_ContactMerge_CTRL(new ApexPages.Standardsetcontroller(new list<Contact>()));
        
        //check we ended up on step 1 of the merge
        system.assertEquals(1, controller.step); 
        
        selectMasterRecord(controller, pa1.id);
        
        //merge them
        controller.mergeContacts();

        //check error message logged to the page
        system.assert(ApexPages.hasMessages());
        
        // no merge occurred
        system.assertEquals(2, [select count() from Account]); 

    }
}