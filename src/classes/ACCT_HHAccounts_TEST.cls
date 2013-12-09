/*
    Copyright (c) 2013, Salesforce.com Foundation
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
* @date 2013
* @description tests specific to the Household Account model 
*/

@isTest
private with sharing class ACCT_HHAccounts_TEST {
	
    /*********************************************************************************************************
    operation:
        create N new contacts, no accounts 
    verify:
        N hh accounts created
		accounts' name and naming fields set
		hh accounts' primary contact set to new contact
    **********************************************************************************************************/            
    static testMethod void NewContactsNoAccounts() {
        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = CAO_Constants.getContactsSettingsForTests(
            new npe01__Contacts_and_Orgs_Settings__c (npe01__Account_Processor__c = CAO_Constants.HH_ACCOUNT_PROCESSOR));
    
        list<Contact> listCon = UTIL_UnitTestData_TEST.CreateMultipleTestContacts(5);
        system.assertEquals(null, listCon[0].AccountId); 
        
        Test.startTest();      
        insert listCon;
        test.stopTest();    // to flush any future calls.
        
        list<Account> listAcc = [select Name, npe01__SYSTEM_AccountType__c, npo02__SYSTEM_CUSTOM_NAMING__c, npe01__SYSTEMIsIndividual__c, 
            npe01__One2OneContact__c, npo02__Formal_Greeting__c, npo02__Informal_Greeting__c from Account];
        system.assertEquals(5, listAcc.size());
        
        for (Account acc : listAcc) {
        	system.assertNotEquals(null, acc.npe01__One2OneContact__c);
            system.assertNotEquals(null, acc.npo02__Formal_Greeting__c);
            system.assertNotEquals(null, acc.npo02__Informal_Greeting__c);
            system.assertEquals(null, acc.npo02__SYSTEM_CUSTOM_NAMING__c);
            system.assertEquals(CAO_Constants.HH_ACCOUNT_PROCESSOR, acc.npe01__SYSTEM_AccountType__c);
            system.assertEquals(true, acc.npe01__SYSTEMIsIndividual__c);
            if (acc.npe01__One2OneContact__c == listCon[1].Id) {
            	system.assertEquals(listCon[1].LastName + ' Household', acc.Name);
                system.assertEquals(listCon[1].FirstName, acc.npo02__Informal_Greeting__c);
                system.assertEquals(listCon[1].FirstName + ' ' + listCon[1].LastName, acc.npo02__Formal_Greeting__c);
            }
        }
    
    }
    
    /*********************************************************************************************************
    operation:
        create N new contacts, M empty hh account supplied 
    verify:
        contacts added to existing hh accounts
        (N - M) accounts have multiple contacts
        accounts' name and naming fields updated
        hh accounts' primary contact updated to contact
    **********************************************************************************************************/            
    static testMethod void NewContactsEmptyHHAccounts() {
        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = CAO_Constants.getContactsSettingsForTests(
            new npe01__Contacts_and_Orgs_Settings__c (npe01__Account_Processor__c = CAO_Constants.HH_ACCOUNT_PROCESSOR));
    
        list<Contact> listCon = UTIL_UnitTestData_TEST.CreateMultipleTestContacts(5);
        system.assertEquals(null, listCon[0].AccountId); 
        list<Account> listAcc = UTIL_UnitTestData_TEST.CreateMultipleTestAccounts(3, CAO_Constants.HH_ACCOUNT_TYPE);
        insert listAcc;
        system.assertNotEquals(null, listAcc[0].Id);
        
        // specify the account for each contact, some sharing an account.
        listCon[0].AccountId = listAcc[0].Id;
        listCon[1].AccountId = listAcc[0].Id;
        listCon[2].AccountId = listAcc[1].Id;
        listCon[3].AccountId = listAcc[1].Id;
        listCon[4].AccountId = listAcc[2].Id;
        
        // lastname permutations
        system.assertEqualS(listCon[0].LastName, listCon[1].LastName);
        listCon[3].LastName = 'DifferentLastName';
        system.assertNotEquals(listCon[2].LastName, listCon[3].LastName);
        
        Test.startTest();      
        insert listCon;
        test.stopTest();    // to flush any future calls.
        
        listAcc = [select Name, npe01__SYSTEM_AccountType__c, npo02__SYSTEM_CUSTOM_NAMING__c, npe01__SYSTEMIsIndividual__c, 
            npe01__One2OneContact__c, npo02__Formal_Greeting__c, npo02__Informal_Greeting__c from Account];
        system.assertEquals(3, listAcc.size());
        
        for (Account acc : listAcc) {
            system.assertNotEquals(null, acc.npe01__One2OneContact__c);
            system.assertNotEquals(null, acc.npo02__Formal_Greeting__c);
            system.assertNotEquals(null, acc.npo02__Informal_Greeting__c);
            system.assertEquals(null, acc.npo02__SYSTEM_CUSTOM_NAMING__c);
            system.assertEquals(CAO_Constants.HH_ACCOUNT_PROCESSOR, acc.npe01__SYSTEM_AccountType__c);
            system.assertEquals(true, acc.npe01__SYSTEMIsIndividual__c);
            // single contact
            if (acc.Id == listCon[4].AccountId) {
            	system.assertEquals(listCon[4].Id, acc.npe01__One2OneContact__c);
                system.assertEquals(listCon[4].LastName + ' Household', acc.Name);
                system.assertEquals(listCon[4].FirstName, acc.npo02__Informal_Greeting__c);
                system.assertEquals(listCon[4].FirstName + ' ' + listCon[4].LastName, acc.npo02__Formal_Greeting__c);
            }
            // 2 contacts, same lastname
            if (acc.Id == listCon[0].AccountId) {
                system.assertEquals(listCon[0].LastName + ' Household', acc.Name);
                system.assertEquals(listCon[0].FirstName + ' and ' + listCon[1].FirstName, acc.npo02__Informal_Greeting__c);
                system.assertEquals(listCon[0].FirstName + ' and ' + listCon[1].FirstName + ' ' + listCon[0].LastName, acc.npo02__Formal_Greeting__c);
            }
            // 2 contacts, different lastname
            if (acc.Id == listCon[2].AccountId) {
                system.assertEquals(listCon[2].LastName + ' and ' + listCon[3].LastName + ' Household', acc.Name);
                system.assertEquals(listCon[2].FirstName + ' and ' + listCon[3].FirstName, acc.npo02__Informal_Greeting__c);
                system.assertEquals(listCon[2].FirstName + ' ' + listCon[2].LastName + ' and ' + listCon[3].FirstName + ' ' + listCon[3].LastName, acc.npo02__Formal_Greeting__c);
            }
        }
    
    }

    /*********************************************************************************************************
    operation:
        create N new contacts, M non-empty hh account supplied 
    verify:
        contacts added to existing hh accounts
        accounts' name and naming fields updated
        hh accounts' primary contact not updated
    **********************************************************************************************************/            
    static testMethod void NewContactsNonEmptyHHAccounts() {
        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = CAO_Constants.getContactsSettingsForTests(
            new npe01__Contacts_and_Orgs_Settings__c (npe01__Account_Processor__c = CAO_Constants.HH_ACCOUNT_PROCESSOR));
    
        list<Contact> listCon = UTIL_UnitTestData_TEST.CreateMultipleTestContacts(5);
        system.assertEquals(null, listCon[0].AccountId); 
        list<Account> listAcc = UTIL_UnitTestData_TEST.CreateMultipleTestAccounts(3, CAO_Constants.HH_ACCOUNT_TYPE);
        insert listAcc;
        system.assertNotEquals(null, listAcc[0].Id);
        
        // specify the account for each contact, some sharing an account.
        listCon[0].AccountId = listAcc[0].Id;
        listCon[1].AccountId = listAcc[0].Id;
        listCon[2].AccountId = listAcc[1].Id;
        listCon[3].AccountId = listAcc[1].Id;
        listCon[4].AccountId = listAcc[2].Id;
        
        // lastname permutations
        system.assertEqualS(listCon[0].LastName, listCon[1].LastName);
        listCon[3].LastName = 'DifferentLastName';
        system.assertNotEquals(listCon[2].LastName, listCon[3].LastName);
        
        // first insert 3 of the contacts and let them hook up to their accounts.
        list<Contact> listConA = new list<Contact>{ listCon[0], listCon[2], listCon[4] };
        insert listConA;
        
        // now we test creating the last two contacts with existing non-empty households
        list<Contact> listConB = new list<Contact>{ listCon[1], listCon[3] };
        Test.startTest();      
        insert listConB;
        test.stopTest();    // to flush any future calls.
        
        listAcc = [select Name, npe01__SYSTEM_AccountType__c, npo02__SYSTEM_CUSTOM_NAMING__c, npe01__SYSTEMIsIndividual__c, 
            npe01__One2OneContact__c, npo02__Formal_Greeting__c, npo02__Informal_Greeting__c from Account];
        system.assertEquals(3, listAcc.size());
        
        for (Account acc : listAcc) {
            system.assertNotEquals(null, acc.npe01__One2OneContact__c);
            system.assertNotEquals(null, acc.npo02__Formal_Greeting__c);
            system.assertNotEquals(null, acc.npo02__Informal_Greeting__c);
            system.assertEquals(null, acc.npo02__SYSTEM_CUSTOM_NAMING__c);
            system.assertEquals(CAO_Constants.HH_ACCOUNT_PROCESSOR, acc.npe01__SYSTEM_AccountType__c);
            system.assertEquals(true, acc.npe01__SYSTEMIsIndividual__c);
            // single contact
            if (acc.Id == listCon[4].AccountId) {
                system.assertEquals(listCon[4].Id, acc.npe01__One2OneContact__c);
                system.assertEquals(listCon[4].LastName + ' Household', acc.Name);
                system.assertEquals(listCon[4].FirstName, acc.npo02__Informal_Greeting__c);
                system.assertEquals(listCon[4].FirstName + ' ' + listCon[4].LastName, acc.npo02__Formal_Greeting__c);
            }
            // 2 contacts, same lastname
            if (acc.Id == listCon[0].AccountId) {
                system.assertEquals(listCon[0].LastName + ' Household', acc.Name);
                system.assertEquals(listCon[0].FirstName + ' and ' + listCon[1].FirstName, acc.npo02__Informal_Greeting__c);
                system.assertEquals(listCon[0].FirstName + ' and ' + listCon[1].FirstName + ' ' + listCon[0].LastName, acc.npo02__Formal_Greeting__c);
            }
            // 2 contacts, different lastname
            if (acc.Id == listCon[2].AccountId) {
                system.assertEquals(listCon[2].LastName + ' and ' + listCon[3].LastName + ' Household', acc.Name);
                system.assertEquals(listCon[2].FirstName + ' and ' + listCon[3].FirstName, acc.npo02__Informal_Greeting__c);
                system.assertEquals(listCon[2].FirstName + ' ' + listCon[2].LastName + ' and ' + listCon[3].FirstName + ' ' + listCon[3].LastName, acc.npo02__Formal_Greeting__c);
            }
        }
    
    }

    /*********************************************************************************************************
    operation:
        create N new contacts, household object supplied 
    verify:
        N hh accounts created
        accounts' name and naming fields set
        hh accounts' primary contact set to new contact
        UNDONE: household object ignored or set???
    **********************************************************************************************************/            
    static testMethod void NewContactsNoAccountsWithHHObj() {
        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = CAO_Constants.getContactsSettingsForTests(
            new npe01__Contacts_and_Orgs_Settings__c (npe01__Account_Processor__c = CAO_Constants.HH_ACCOUNT_PROCESSOR));
    
        list<Contact> listCon = UTIL_UnitTestData_TEST.CreateMultipleTestContacts(5);
        system.assertEquals(null, listCon[0].AccountId); 
        
        npo02__household__c hh = new npo02__household__c();
        insert hh;
        
        // assign a HH object to some of the new contacts
        listCon[0].npo02__Household__c = hh.Id;
        listCon[1].npo02__Household__c = hh.Id;
        listCon[3].npo02__Household__c = hh.Id;        
        
        Test.startTest();      
        insert listCon;
        test.stopTest();    // to flush any future calls.
        
        set<Id> setConId = new set<Id>();
        for (Contact con : listCon) 
            setConId.add(con.Id);
        list<Account> listAcc = [select Name, npe01__SYSTEM_AccountType__c, npo02__SYSTEM_CUSTOM_NAMING__c, npe01__SYSTEMIsIndividual__c, 
            npe01__One2OneContact__c, npo02__Formal_Greeting__c, npo02__Informal_Greeting__c from Account
            where npe01__One2OneContact__c in :setConId];
        system.assertEquals(5, listAcc.size());
        
        for (Account acc : listAcc) {
            system.assertNotEquals(null, acc.npe01__One2OneContact__c);
            system.assertNotEquals(null, acc.npo02__Formal_Greeting__c);
            system.assertNotEquals(null, acc.npo02__Informal_Greeting__c);
            system.assertEquals(null, acc.npo02__SYSTEM_CUSTOM_NAMING__c);
            system.assertEquals(CAO_Constants.HH_ACCOUNT_PROCESSOR, acc.npe01__SYSTEM_AccountType__c);
            system.assertEquals(true, acc.npe01__SYSTEMIsIndividual__c);
            if (acc.npe01__One2OneContact__c == listCon[1].Id) {
                system.assertEquals(listCon[1].LastName + ' Household', acc.Name);
                system.assertEquals(listCon[1].FirstName, acc.npo02__Informal_Greeting__c);
                system.assertEquals(listCon[1].FirstName + ' ' + listCon[1].LastName, acc.npo02__Formal_Greeting__c);
            }
        }
        
        list<Contact> listCon2 = [select Id, Name, npo02__Household__c from Contact where npo02__Household__c = :hh.Id];
        // UNDONE: what do we want to happen
        system.assertEquals(3, listCon2.size());
    
    }

    /*********************************************************************************************************
    operation:
        update N existing contacts w/ HH accounts to M different HH accounts 
    verify:
        N-M hh accounts originally created get deleted
        accounts' name and naming fields set
        hh accounts' primary contact set to one of the HH contacts
    **********************************************************************************************************/            
     static testMethod void UpdateContactsMergeHHAccounts() {
        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = CAO_Constants.getContactsSettingsForTests(
            new npe01__Contacts_and_Orgs_Settings__c (npe01__Account_Processor__c = CAO_Constants.HH_ACCOUNT_PROCESSOR));
    
        list<Contact> listCon = UTIL_UnitTestData_TEST.CreateMultipleTestContacts(5);
        system.assertEquals(null, listCon[0].AccountId); 
        insert listCon;

        list<Account> listAcc = [select Name, npe01__SYSTEM_AccountType__c, npo02__SYSTEM_CUSTOM_NAMING__c, npe01__SYSTEMIsIndividual__c, 
            npe01__One2OneContact__c, npo02__Formal_Greeting__c, npo02__Informal_Greeting__c from Account];
        system.assertEquals(5, listAcc.size());
        
        // refresh our contacts to get their accounts
        listCon = [select Name, FirstName, LastName, AccountId from Contact];
        system.assertEquals(5, listCon.size());
        system.assertNotEquals(null, listCon[0].AccountId);
        
        // now merge some HH Accounts
        listCon[0].AccountId = listAcc[0].Id;
        listCon[1].AccountId = listAcc[0].Id;
        listCon[2].AccountId = listAcc[1].Id;
        listCon[3].AccountId = listAcc[1].Id;
        listCon[4].AccountId = listAcc[4].Id;
        
        // lastname permutations
        system.assertEqualS(listCon[0].LastName, listCon[1].LastName);
        listCon[3].LastName = 'DifferentLastName';
        system.assertNotEquals(listCon[2].LastName, listCon[3].LastName);
        
        Test.startTest();      
        update listCon;
        test.stopTest();    // to flush any future calls.
        
        listAcc = [select Name, npe01__SYSTEM_AccountType__c, npo02__SYSTEM_CUSTOM_NAMING__c, npe01__SYSTEMIsIndividual__c, 
            npe01__One2OneContact__c, npo02__Formal_Greeting__c, npo02__Informal_Greeting__c from Account];
        system.assertEquals(3, listAcc.size());
        
        for (Account acc : listAcc) {
            system.assertNotEquals(null, acc.npe01__One2OneContact__c);
            system.assertNotEquals(null, acc.npo02__Formal_Greeting__c);
            system.assertNotEquals(null, acc.npo02__Informal_Greeting__c);
            system.assertEquals(null, acc.npo02__SYSTEM_CUSTOM_NAMING__c);
            system.assertEquals(CAO_Constants.HH_ACCOUNT_PROCESSOR, acc.npe01__SYSTEM_AccountType__c);
            system.assertEquals(true, acc.npe01__SYSTEMIsIndividual__c);
            // single contact
            if (acc.Id == listCon[4].AccountId) {
                system.assertEquals(listCon[4].Id, acc.npe01__One2OneContact__c);
                system.assertEquals(listCon[4].LastName + ' Household', acc.Name);
                system.assertEquals(listCon[4].FirstName, acc.npo02__Informal_Greeting__c);
                system.assertEquals(listCon[4].FirstName + ' ' + listCon[4].LastName, acc.npo02__Formal_Greeting__c);
            }
            // 2 contacts, same lastname
            if (acc.Id == listCon[0].AccountId) {
                system.assertEquals(listCon[0].LastName + ' Household', acc.Name);
                system.assertEquals(listCon[0].FirstName + ' and ' + listCon[1].FirstName, acc.npo02__Informal_Greeting__c);
                system.assertEquals(listCon[0].FirstName + ' and ' + listCon[1].FirstName + ' ' + listCon[0].LastName, acc.npo02__Formal_Greeting__c);
            }
            // 2 contacts, different lastname
            if (acc.Id == listCon[2].AccountId) {
                system.assertEquals(listCon[2].LastName + ' and ' + listCon[3].LastName + ' Household', acc.Name);
                system.assertEquals(listCon[2].FirstName + ' and ' + listCon[3].FirstName, acc.npo02__Informal_Greeting__c);
                system.assertEquals(listCon[2].FirstName + ' ' + listCon[2].LastName + ' and ' + listCon[3].FirstName + ' ' + listCon[3].LastName, acc.npo02__Formal_Greeting__c);
            }
        }
    }
    
    /*********************************************************************************************************
    operation:
        split N multi member HH accounts into 2N HH accounts 
    verify:
        2N HH accounts remain
        accounts' name and naming fields set
        hh accounts' primary contact set to one of the HH contacts
    **********************************************************************************************************/            
     static testMethod void UpdateContactsSplitHHAccounts() {
        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = CAO_Constants.getContactsSettingsForTests(
            new npe01__Contacts_and_Orgs_Settings__c (npe01__Account_Processor__c = CAO_Constants.HH_ACCOUNT_PROCESSOR));
    
        list<Contact> listCon = UTIL_UnitTestData_TEST.CreateMultipleTestContacts(5);
        system.assertEquals(null, listCon[0].AccountId); 

        list<Account> listAcc = UTIL_UnitTestData_TEST.CreateMultipleTestAccounts(3, CAO_Constants.HH_ACCOUNT_TYPE);
        insert listAcc;
        system.assertNotEquals(null, listAcc[0].Id);
 
        // setup HH Accounts
        listCon[0].AccountId = listAcc[0].Id;
        listCon[1].AccountId = listAcc[0].Id;
        listCon[2].AccountId = listAcc[1].Id;
        listCon[3].AccountId = listAcc[1].Id;
        listCon[4].AccountId = listAcc[1].Id;
        
        insert listCon;
        
        // refresh our contacts to get their accounts
        listCon = [select Name, FirstName, LastName, AccountId from Contact];
        system.assertEquals(5, listCon.size());
        system.assertNotEquals(null, listCon[0].AccountId);        
        
        // lastname permutations
        system.assertEqualS(listCon[0].LastName, listCon[1].LastName);
        listCon[3].LastName = 'DifferentLastName';
        system.assertNotEquals(listCon[2].LastName, listCon[3].LastName);
        
        // now split the HH's
        listCon[1].AccountId = listAcc[2].Id;
        listCon[4].AccountId = listAcc[2].Id;
        
        Test.startTest();      
        update listCon;
        test.stopTest();    // to flush any future calls.
        
        listAcc = [select Name, npe01__SYSTEM_AccountType__c, npo02__SYSTEM_CUSTOM_NAMING__c, npe01__SYSTEMIsIndividual__c, 
            npe01__One2OneContact__c, npo02__Formal_Greeting__c, npo02__Informal_Greeting__c from Account];
        system.assertEquals(3, listAcc.size());
        
        for (Account acc : listAcc) {
            system.assertNotEquals(null, acc.npe01__One2OneContact__c);
            system.assertNotEquals(null, acc.npo02__Formal_Greeting__c);
            system.assertNotEquals(null, acc.npo02__Informal_Greeting__c);
            system.assertEquals(null, acc.npo02__SYSTEM_CUSTOM_NAMING__c);
            system.assertEquals(CAO_Constants.HH_ACCOUNT_PROCESSOR, acc.npe01__SYSTEM_AccountType__c);
            system.assertEquals(true, acc.npe01__SYSTEMIsIndividual__c);
            // 2 contacts, same lastname
            if (acc.Id == listCon[1].AccountId) {
                system.assertEquals(listCon[1].LastName + ' Household', acc.Name);
                system.assertEquals(listCon[1].FirstName + ' and ' + listCon[4].FirstName, acc.npo02__Informal_Greeting__c);
                system.assertEquals(listCon[1].FirstName + ' and ' + listCon[4].FirstName + ' ' + listCon[4].LastName, acc.npo02__Formal_Greeting__c);
            }
            // now single contact
            if (acc.Id == listCon[0].AccountId) {
                system.assertEquals(listCon[0].Id, acc.npe01__One2OneContact__c);
                system.assertEquals(listCon[0].LastName + ' Household', acc.Name);
                system.assertEquals(listCon[0].FirstName, acc.npo02__Informal_Greeting__c);
                system.assertEquals(listCon[0].FirstName + ' ' + listCon[0].LastName, acc.npo02__Formal_Greeting__c);
            }
            // 2 contacts, different lastname
            if (acc.Id == listCon[2].AccountId) {
                system.assertEquals(listCon[2].LastName + ' and ' + listCon[3].LastName + ' Household', acc.Name);
                system.assertEquals(listCon[2].FirstName + ' and ' + listCon[3].FirstName, acc.npo02__Informal_Greeting__c);
                system.assertEquals(listCon[2].FirstName + ' ' + listCon[2].LastName + ' and ' + listCon[3].FirstName + ' ' + listCon[3].LastName, acc.npo02__Formal_Greeting__c);
            }
        }
    }

    /*********************************************************************************************************
    operation:
        delete contacts from single and multi-contact HH Accounts
    verify:
        HH Accounts with no remaining contacts are deleted
        HH Accounts with remaining contacts remain
        accounts' name and naming fields set
        hh accounts' primary contact set to one of the HH contacts
    **********************************************************************************************************/            
     static testMethod void DeleteContactsFromHHAccounts() {
        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = CAO_Constants.getContactsSettingsForTests(
            new npe01__Contacts_and_Orgs_Settings__c (npe01__Account_Processor__c = CAO_Constants.HH_ACCOUNT_PROCESSOR));
    
        list<Contact> listCon = UTIL_UnitTestData_TEST.CreateMultipleTestContacts(5);
        system.assertEquals(null, listCon[0].AccountId); 

        list<Account> listAcc = UTIL_UnitTestData_TEST.CreateMultipleTestAccounts(3, CAO_Constants.HH_ACCOUNT_TYPE);
        insert listAcc;
        system.assertNotEquals(null, listAcc[0].Id);
 
        // setup HH Accounts
        listCon[0].AccountId = listAcc[0].Id;
        listCon[1].AccountId = listAcc[0].Id;
        listCon[2].AccountId = listAcc[1].Id;
        listCon[3].AccountId = listAcc[1].Id;
        listCon[4].AccountId = listAcc[2].Id;
        
        insert listCon;
        
        // refresh our contacts to get their accounts
        listCon = [select Name, FirstName, LastName, AccountId from Contact];
        system.assertEquals(5, listCon.size());
        system.assertNotEquals(null, listCon[0].AccountId);        
        
        // lastname permutations
        system.assertEqualS(listCon[0].LastName, listCon[1].LastName);
        listCon[3].LastName = 'DifferentLastName';
        system.assertNotEquals(listCon[2].LastName, listCon[3].LastName);
        
        // create the list of Contacts to delete
        list<Contact> listConDel = new list<Contact>();
        listConDel.add(listCon[1]); // con0 remains in HH account
        listConDel.add(listCon[4]); // no contacts remain in single contact HH account
        listConDel.add(listCon[2]);
        listConDel.add(listCon[3]); // no contacts remain in multi-contact HH account
        
        Test.startTest();      
        delete listConDel;
        test.stopTest();    // to flush any future calls.
        
        listCon = [select Id, FirstName, LastName from Contact];
        system.assertEquals(1, listCon.size());
        
        listAcc = [select Name, npe01__SYSTEM_AccountType__c, npo02__SYSTEM_CUSTOM_NAMING__c, npe01__SYSTEMIsIndividual__c, 
            npe01__One2OneContact__c, npo02__Formal_Greeting__c, npo02__Informal_Greeting__c from Account];
        system.assertEquals(1, listAcc.size());
        
        Account acc = listAcc[0];
        system.assertEquals(null, acc.npo02__SYSTEM_CUSTOM_NAMING__c);
        system.assertEquals(CAO_Constants.HH_ACCOUNT_PROCESSOR, acc.npe01__SYSTEM_AccountType__c);
        system.assertEquals(true, acc.npe01__SYSTEMIsIndividual__c);
        system.assertEquals(listCon[0].Id, acc.npe01__One2OneContact__c);
        system.assertEquals(listCon[0].LastName + ' Household', acc.Name);
        system.assertEquals(listCon[0].FirstName, acc.npo02__Informal_Greeting__c);
        system.assertEquals(listCon[0].FirstName + ' ' + listCon[0].LastName, acc.npo02__Formal_Greeting__c);
    }

    /*********************************************************************************************************
    operation:
        delete and then undelete contacts from single and multi-contact HH Accounts
    verify:
        contacts added back to existing hh accounts
        accounts' name and naming fields updated
        hh accounts' primary contact valid
    **********************************************************************************************************/            
    static testMethod void UndeleteContactsFromHHAccounts() {
        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = CAO_Constants.getContactsSettingsForTests(
            new npe01__Contacts_and_Orgs_Settings__c (npe01__Account_Processor__c = CAO_Constants.HH_ACCOUNT_PROCESSOR));
    
        list<Contact> listCon = UTIL_UnitTestData_TEST.CreateMultipleTestContacts(5);
        system.assertEquals(null, listCon[0].AccountId); 

        list<Account> listAcc = UTIL_UnitTestData_TEST.CreateMultipleTestAccounts(3, CAO_Constants.HH_ACCOUNT_TYPE);
        insert listAcc;
        system.assertNotEquals(null, listAcc[0].Id);
 
        // setup HH Accounts
        listCon[0].AccountId = listAcc[0].Id;
        listCon[1].AccountId = listAcc[0].Id;
        listCon[2].AccountId = listAcc[1].Id;
        listCon[3].AccountId = listAcc[1].Id;
        listCon[4].AccountId = listAcc[2].Id;
        
        insert listCon;
        
        // refresh our contacts to get their accounts
        listCon = [select Name, FirstName, LastName, AccountId from Contact];
        system.assertEquals(5, listCon.size());
        system.assertNotEquals(null, listCon[0].AccountId);        
        
        // lastname permutations
        system.assertEqualS(listCon[0].LastName, listCon[1].LastName);
        listCon[3].LastName = 'DifferentLastName';
        system.assertNotEquals(listCon[2].LastName, listCon[3].LastName);
        
        // create the list of Contacts to delete
        list<Contact> listConDel = new list<Contact>();
        listConDel.add(listCon[1]); // con0 remains in HH account
        listConDel.add(listCon[4]); // no contacts remain in single contact HH account
        listConDel.add(listCon[2]);
        listConDel.add(listCon[3]); // no contacts remain in multi-contact HH account
        
        Test.startTest();      
        delete listConDel;
        list<Contact> listCon2 = [select Id, Name from Contact];
        system.assertEquals(1, listCon2.size());
        list<Account> listAcc2 = [select Id, Name from Account];
        system.assertEquals(1, listAcc2.size());
             
        // unfortunately, we can't undelete any contact whose account was also deleted.
        // Salesforce defaultly supports deleting the contacts of deleted accounts, and
        // undeleting them when the account is undeleted.
        // but due to our trigger on contact delete, also deleting the hh account,
        // there is no way to undelete the contact.  we do have an issue in gitHub for this.
        // so for this test, only undelete the contacts whose account wasn't deleted.
        undelete listCon[1];
        test.stopTest();    // to flush any future calls.
       
        listCon = [select Id, FirstName, LastName, AccountId from Contact];
        system.assertEquals(2, listCon.size());
        
        listAcc = [select Name, npe01__SYSTEM_AccountType__c, npo02__SYSTEM_CUSTOM_NAMING__c, npe01__SYSTEMIsIndividual__c, 
            npe01__One2OneContact__c, npo02__Formal_Greeting__c, npo02__Informal_Greeting__c from Account];
        system.assertEquals(1, listAcc.size());
        
        for (Account acc : listAcc) {
            system.assertNotEquals(null, acc.npe01__One2OneContact__c);
            system.assertNotEquals(null, acc.npo02__Formal_Greeting__c);
            system.assertNotEquals(null, acc.npo02__Informal_Greeting__c);
            system.assertEquals(null, acc.npo02__SYSTEM_CUSTOM_NAMING__c);
            system.assertEquals(CAO_Constants.HH_ACCOUNT_PROCESSOR, acc.npe01__SYSTEM_AccountType__c);
            system.assertEquals(true, acc.npe01__SYSTEMIsIndividual__c);
            // 2 contacts, same lastname
            if (acc.Id == listCon[0].AccountId) {
                system.assertEquals(listCon[0].LastName + ' Household', acc.Name);
                system.assertEquals(listCon[0].FirstName + ' and ' + listCon[1].FirstName, acc.npo02__Informal_Greeting__c);
                system.assertEquals(listCon[0].FirstName + ' and ' + listCon[1].FirstName + ' ' + listCon[0].LastName, acc.npo02__Formal_Greeting__c);
            }
        }
    
    }

}