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
	
	/**********************************************************
    operation:
        create N new contacts, no accounts 
    verify:
        N hh accounts created
		accounts' name and naming fields set
		hh accounts' primary contact set to new contact
    */            
    static testMethod void NewContactsNoAccounts() {
        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = CAO_Constants.getContactsSettingsForTests(
            new npe01__Contacts_and_Orgs_Settings__c (npe01__Account_Processor__c = CAO_Constants.HH_ACCOUNT_PROCESSOR));
    
        list<Contact> listCon = UTIL_UnitTestData_TEST.CreateMultipleTestContacts(5);
        system.assertEquals(null, listCon[0].AccountId); 
        
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
    
    }
    
    /**********************************************************
    operation:
        create N new contacts, M empty hh account supplied 
    verify:
        contacts added to existing hh accounts
        (N - M) accounts have multiple contacts
        accounts' name and naming fields updated
        hh accounts' primary contact updated to contact
    */            
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
        system.debug('DJH');
        system.debug(listCon);
        
        listAcc = [select Name, npe01__SYSTEM_AccountType__c, npo02__SYSTEM_CUSTOM_NAMING__c, npe01__SYSTEMIsIndividual__c, 
            npe01__One2OneContact__c, npo02__Formal_Greeting__c, npo02__Informal_Greeting__c from Account];
        system.debug('DJH');
        system.debug(listAcc);
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

    /**********************************************************
    operation:
        create N new contacts, M non-empty hh account supplied 
    verify:
        contacts added to existing hh accounts
        accounts' name and naming fields updated
        hh accounts' primary contact not updated
    */            

    /**********************************************************
    operation:
        create N new contacts, household object supplied 
    verify:
        N hh accounts created
        accounts' name and naming fields set
        hh accounts' primary contact set to new contact
        UNDONE: household object ignored or set???
        UNDONE: behavior dependent on whether HH Account provided? 
    */            


}