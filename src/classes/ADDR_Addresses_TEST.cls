/*
    Copyright (c) 2014, Salesforce.com Foundation
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
* @description tests specific to Address Management 
*/

@isTest
private with sharing class ADDR_Addresses_TEST {

    // if you only want to run one test in this class, fill in its name here.
    // if you want to run all tests, then use '*'
    private static string strTestOnly = '*';
    

    /*********************************************************************************************************
    utility to set up common test data for the Address tests.
        - this will create & insert N household Accounts, each with M contacts
        - also will create a Default Addresses for each HH Account
        - will also setup the default Account Processor to be HH Accounts
    **********************************************************************************************************/
    private static list<Contact> listConT;
    private static list<Account> listAccT;            
    private static void createHHTestData(integer cHH, integer cCon) {
        
        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = CAO_Constants.getContactsSettingsForTests(
            new npe01__Contacts_and_Orgs_Settings__c (npe01__Account_Processor__c = CAO_Constants.HH_ACCOUNT_PROCESSOR));
            
        listConT = UTIL_UnitTestData_TEST.CreateMultipleTestContacts(cHH * cCon);
        listAccT = UTIL_UnitTestData_TEST.CreateMultipleTestAccounts(cHH, CAO_Constants.HH_ACCOUNT_TYPE);
        insert listAccT;
        
        for (integer i = 0; i < cHH; i++) {
        	for (integer j = 0; j < cCon; j++) {
        		listConT[ (i * cHH) + j].AccountId = listAccT[i].Id;
        	}
        }        
        insert listConT;    	

        initTestAddr(cHH);
        for (integer i = 0; i < cHH; i++) {
            listAddrT[i].Household_Account__c = listAccT[i].Id;
            listAddrT[i].Default_Address__c = true;
        }
        // clear our triggers recursion prevention since we starting a new test
        ADDR_Addresses_TDTM.hasRunAddrTrigger = false;
        insert listAddrT;
        // clear our triggers recursion prevention since we are starting a new test
        ADDR_Addresses_TDTM.hasRunAddrTrigger = false;
    }
    
    /*********************************************************************************************************
    utility to initialize (but not insert) N new Address objects.
    **********************************************************************************************************/
    private static list<Address__c> listAddrT;
    private static void initTestAddr(integer cAddr) {
    	listAddrT = new list<Address__c>();
    	for (integer i = 0; i < cAddr; i++) {
    		Address__c addr = new Address__c();
    		addr.Address_Type__c = 'Home';
    		addr.MailingStreet__c = 'Street' + i;
    		addr.MailingCity__c = 'City' + i;
            addr.MailingState__c = 'State' + i;
            addr.MailingPostalCode__c = 'Zip' + i;
            addr.MailingCountry__c = 'Country' + i;
            listAddrT.add(addr);    		
    	}
    }
    
    /*********************************************************************************************************
    utility to verify an Account Billing address matches a Contact Mailing address
    **********************************************************************************************************/
    private static boolean isMatchAddressAccCon(Account acc, Contact con) {
        return (acc.BillingStreet == con.MailingStreet &&          
            acc.BillingCity == con.MailingCity &&          
            acc.BillingState == con.MailingState &&         
            acc.BillingPostalCode == con.MailingPostalCode &&          
            acc.BillingCountry == con.MailingCountry);                
    }
        
    /*********************************************************************************************************
    operation:
        create N new default Addresses for N Households (with M Contacts)  
    verify:
        N addresses created
        N household shipping address fields updated
        M contact Mailing address fields updated
    **********************************************************************************************************/            
    static testMethod void newDefaultAddr() {
        if (strTestOnly != '*' && strTestOnly != 'newDefaultAddr') return;
        
        // this creates a default Address for each HH
        createHHTestData(3, 3);

        // verify that the HH and Contacts share the same address
        map<Id, Account> mapAccIdAcc = new map<Id, Account>([select Id, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry from Account]);
        list<Contact> listCon = [select Id, Name, AccountId, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry from Contact];
        
        for (Contact con : listCon) {
            Account acc = mapAccIdAcc.get(con.AccountId);
            system.assertEquals(true, isMatchAddressAccCon(acc, con));
        }
    }
        
    /*********************************************************************************************************
    operation:
        update existing default Addresses  
    verify:
        household shipping address fields updated
        contact Mailing address fields updated
    **********************************************************************************************************/            
    static testMethod void updateDefaultAddr() {
        if (strTestOnly != '*' && strTestOnly != 'updateDefaultAddr') return;
        
        // this creates a default Address for each HH
        createHHTestData(3, 3);
        
        // now let's update the Addresses
        for (integer i = 0; i < 3; i++) {
        	Address__c addr = listAddrT[i];
        	addr.MailingStreet__c = 'New Street' + i;
        	addr.MailingCity__c = 'New City' + i;
        }
        system.assertEquals(false, ADDR_Addresses_TDTM.hasRunAddrTrigger);
        update listAddrT;
    
        // verify that the HH and Contacts share the same address and it's new!
        map<Id, Account> mapAccIdAcc = new map<Id, Account>([select Id, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry from Account]);
        list<Contact> listCon = [select Id, Name, AccountId, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry from Contact];
        system.assertEquals(9, listCon.size());
        
        for (Contact con : listCon) {
            Account acc = mapAccIdAcc.get(con.AccountId);
            system.assertEquals(true, isMatchAddressAccCon(acc, con));
            system.assert(con.MailingStreet.contains('New Street'));
            system.assert(con.MailingCity.contains('New City'));
        }
    }

    /*********************************************************************************************************
    operation:
        update existing non-default Addresses  
    verify:
        no change to HH and contact addresses
    **********************************************************************************************************/            
    static testMethod void updateNonDefaultAddr() {
        if (strTestOnly != '*' && strTestOnly != 'updateNonDefaultAddr') return;
        
        // this creates a default Address for each HH
        createHHTestData(3, 3);
        
        // now let's update the Addresses
        for (integer i = 0; i < 3; i++) {
            Address__c addr = listAddrT[i];
            addr.Default_Address__c = false;
            addr.MailingStreet__c = 'New Street' + i;
            addr.MailingCity__c = 'New City' + i;
        }
        system.assertEquals(false, ADDR_Addresses_TDTM.hasRunAddrTrigger);
        update listAddrT;
    
        // verify that the HH and Contacts share the same address and it's new!
        map<Id, Account> mapAccIdAcc = new map<Id, Account>([select Id, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry from Account]);
        list<Contact> listCon = [select Id, Name, AccountId, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry from Contact];
        system.assertEquals(9, listCon.size());
        
        for (Contact con : listCon) {
            Account acc = mapAccIdAcc.get(con.AccountId);
            system.assertEquals(true, isMatchAddressAccCon(acc, con));
            system.assert(!con.MailingStreet.contains('New Street'));
            system.assert(!con.MailingCity.contains('New City'));
        }
    }

    /*********************************************************************************************************
    operation:
        set contact address override  
    verify:
        contact's address matches override
    **********************************************************************************************************/            
    static testMethod void setConAddrOverride() {
        if (strTestOnly != '*' && strTestOnly != 'setConAddrOverride') return;
        
        // this creates a default Address for each HH
        createHHTestData(3, 3);
        
        // create a new non-default address
        Address__c addrNew = new Address__c();
        addrNew.MailingStreet__c = 'street override';
        addrNew.MailingCity__c = 'city override';
        addrNew.Default_Address__c = false;
        addrNew.Household_Account__c = listAccT[0].Id;
        insert addrNew;
        ADDR_Addresses_TDTM.hasRunAddrTrigger = false;
        
        // set a contact's address override
        listConT[0].Address_Override__c = addrNew.Id;
        update listConT[0];
        ADDR_Addresses_TDTM.hasRunAddrTrigger = false;
    
        // now let's update the default Addresses
        for (integer i = 0; i < 3; i++) {
            Address__c addr = listAddrT[i];
            addr.MailingStreet__c = 'New Street' + i;
            addr.MailingCity__c = 'New City' + i;
        }
        update listAddrT;
        
        // verify that the HH and Contacts share the same address and it's new!
        map<Id, Account> mapAccIdAcc = new map<Id, Account>([select Id, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry from Account]);
        list<Contact> listCon = [select Id, Name, AccountId, Address_Override__c, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry from Contact];
        system.assertEquals(9, listCon.size());
        
        for (Contact con : listCon) {
            Account acc = mapAccIdAcc.get(con.AccountId);
        	if (con.Address_Override__c != null) {
        		system.assertEquals(con.Address_Override__c, addrNew.Id);
	            system.assertEquals(false, isMatchAddressAccCon(acc, con));
	            system.assert(!con.MailingStreet.contains('New Street'));
	            system.assert(!con.MailingCity.contains('New City'));        		
        	} else {
	            system.assertEquals(true, isMatchAddressAccCon(acc, con));
	            system.assert(con.MailingStreet.contains('New Street'));
	            system.assert(con.MailingCity.contains('New City'));
        	}
        }
    }

    /*********************************************************************************************************
    operation:
        insert new default addresses to HH w/ existing default addresses  
    verify:
        contact's && hh address matches new default
        old default addresses no longer marked default
    **********************************************************************************************************/            
    static testMethod void insertNewDefaultAddr() {
        if (strTestOnly != '*' && strTestOnly != 'insertNewDefaultAddr') return;
        
        // this creates a default Address for each HH
        createHHTestData(3, 3);
        
        // create additional addresses
        initTestAddr(3);
        for (integer i = 0; i < 3; i++) {
            listAddrT[i].Household_Account__c = listAccT[i].Id;
            listAddrT[i].Default_Address__c = true;
            listAddrT[i].MailingStreet__c = 'New Default Street' + i;
            listAddrT[i].MailingCity__c = 'New Default City' + i;
        }
        ADDR_Addresses_TDTM.hasRunAddrTrigger = false;
        insert listAddrT;
        ADDR_Addresses_TDTM.hasRunAddrTrigger = false;
        
        // verify that the HH and Contacts share the same address and it's new!
        map<Id, Account> mapAccIdAcc = new map<Id, Account>([select Id, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry from Account]);
        list<Contact> listCon = [select Id, Name, AccountId, Address_Override__c, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry from Contact];
        system.assertEquals(9, listCon.size());
        
        for (Contact con : listCon) {
            Account acc = mapAccIdAcc.get(con.AccountId);
            system.assertEquals(true, isMatchAddressAccCon(acc, con));
            system.assert(con.MailingStreet.contains('New Default Street'));
            system.assert(con.MailingCity.contains('New Default City'));
        }
        
        // verify the previous addresses got Default cleared.
        list<Address__c> listAddr = [select Id, Default_Address__c, MailingStreet__c, Household_Account__c from Address__c];
        system.assertEquals(6, listAddr.size());
        for (Address__c addr : listAddr) {
        	boolean fNewDefault = (addr.MailingStreet__c.contains('New Default Street'));
       		system.assertEquals(fNewDefault, addr.Default_Address__c);
        }        
    }
    
    /*********************************************************************************************************
    operation:
        update contacts' Address Override  
    verify:
        contacts' Mailing address fields updated to the Address Override's fields.
    **********************************************************************************************************/            
    static testMethod void updateAddrOverride() {
        if (strTestOnly != '*' && strTestOnly != 'updateAddrOverride') return;
        
        // this creates a default Address for each HH
        createHHTestData(3, 3);

        // create additional addresses
        initTestAddr(3);
        for (integer i = 0; i < 3; i++) {
            listAddrT[i].Household_Account__c = listAccT[i].Id;
            listAddrT[i].Default_Address__c = false;
            listAddrT[i].MailingStreet__c = 'override' + i;
            listAddrT[i].MailingCity__c = 'override' + i;
        }
        insert listAddrT;
        ADDR_Addresses_TDTM.hasRunAddrTrigger = false;
        
        // set the contacts' address overrides
        list<Contact> listCon = new list<Contact>();
        for (integer i = 0; i < 3; i++) {
        	Contact con = listConT[i*3 + i];
            con.Address_Override__c = listAddrT[i].Id;
            listCon.add(con);
        }
        update listCon;
        
        // verify that the HH and Contacts share the same address
        map<Id, Account> mapAccIdAcc = new map<Id, Account>([select Id, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry from Account]);
        listCon = [select Id, Name, AccountId, Address_Override__c, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry from Contact];
        
        for (Contact con : listCon) {
            Account acc = mapAccIdAcc.get(con.AccountId);
            if (con.Address_Override__c != null) {
                system.assertEquals(false, isMatchAddressAccCon(acc, con));
                system.assert(con.MailingStreet.contains('override'));
                system.assert(con.MailingCity.contains('override'));               
            } else {
                system.assertEquals(true, isMatchAddressAccCon(acc, con));
                system.assert(con.MailingStreet.contains('Street'));
                system.assert(con.MailingCity.contains('City'));
            }
        }
    }
        
    /*********************************************************************************************************
    operation:
        update contacts' mailing address to cause creation of new default Address object  
    verify:
        new Default Address created
        HH and Contacts get new Address
    **********************************************************************************************************/            
    static testMethod void updateConAddr() {
        if (strTestOnly != '*' && strTestOnly != 'updateConAddr') return;
        
        // this creates a default Address for each HH
        createHHTestData(3, 3);

        // modify some of the contact addresses directly
        list<Contact> listCon = new list<Contact>();
        for (integer i = 0; i < 3; i++) {
            Contact con = listConT[i*3 + i];
            con.MailingStreet = 'Direct Street Edit';
            con.MailingCity = 'Direct City Edit';
            listCon.add(con);
        }
        update listCon;
        
        // verify that the HH and Contacts share the same address
        map<Id, Account> mapAccIdAcc = new map<Id, Account>([select Id, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry from Account]);
        listCon = [select Id, Name, AccountId, Address_Override__c, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry from Contact];
        
        for (Contact con : listCon) {
            Account acc = mapAccIdAcc.get(con.AccountId);
            system.assertEquals(true, isMatchAddressAccCon(acc, con));
            system.assert(con.MailingStreet.contains('Direct Street Edit'));
            system.assert(con.MailingCity.contains('Direct City Edit'));
        }
 
         // verify the previous addresses got Default cleared.
        list<Address__c> listAddr = [select Id, Default_Address__c, MailingStreet__c, Household_Account__c from Address__c];
        system.assertEquals(6, listAddr.size());
        for (Address__c addr : listAddr) {
            boolean fNewDefault = (addr.MailingStreet__c.contains('Direct Street Edit'));
            system.assertEquals(fNewDefault, addr.Default_Address__c);
        }        
        
        
    }

}