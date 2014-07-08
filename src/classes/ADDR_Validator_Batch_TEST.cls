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
* @date 2014
* @description Test class for batch address verification.
*/
@isTest
public with sharing class ADDR_Validator_Batch_TEST {

    // if you only want to run one test in this class, fill in its name here.
    // if you want to run all tests, then use '*'
    private static string strTestOnly = 'multipleValidAddresses';
    
    public static Addr_Verification_Settings__c createDefaultSettings() {
    	// use the household account model
        CAO_Constants.getContactsSettingsForTests(
            new npe01__Contacts_and_Orgs_Settings__c (npe01__Account_Processor__c = CAO_Constants.HH_ACCOUNT_PROCESSOR));

        // create the basic api settings - SmartyStreets off
        Addr_Verification_Settings__c settings = Addr_Verification_Settings__c.getOrgDefaults();
        settings.Using_SmartyStreets__c = false;
        settings.Auth_ID__c = 'hey';
        settings.Auth_Token__c = 'there';
        settings.Address_Verification_Endpoint__c = 'api.smartystreets.com/street-address';
        settings.Zipcode_Verification_Endpoint__c = 'api.smartystreets.com/zipcode';
        settings.Class__c = 'ADDR_SmartyStreets_Validator';
        settings.Enable_Automatic_Verification__c = true;
        settings.Reject_Ambiguous_Addresses__c = true;
        insert settings;
   
        Test.setMock(HttpCalloutMock.class, new ADDR_MockHttpRespGenerator_TEST());
        
        return settings;
    }
    
    public static testmethod void oneValidAddress() {
    	if (strTestOnly != '*' && strTestOnly != 'oneValidAddress') return;
    	
    	Addr_Verification_Settings__c settings = createDefaultSettings();
        
        //create contact 
        Contact contact = new contact(firstname='Test', lastname='Person');
        contact.MailingStreet = 'single-address';
        contact.MailingCity = 'Cupertino';
        contact.MailingState = 'ca';
        contact.MailingPostalCode = '95014'; 
        insert contact;
        ADDR_Addresses_TDTM.hasRunAddrTrigger = false;
        
        //check household got created for contact
        contact = [select Account.Id from Contact where Id = :contact.Id];
        Id accountId = contact.Account.Id;
        System.assertNotEquals(null, accountId);
        
        //check address record got created for household
        Address__c[] av = [select Id, MailingStreet__c, MailingState__c, MailingPostalCode__c, Verified__c
                             from Address__c where Household_Account__c = :accountId];
        System.assertEquals(1, av.size());
        System.assertEquals('single-address', av[0].MailingStreet__c);
        System.assertEquals('ca', av[0].MailingState__c);
        System.assertEquals('95014', av[0].MailingPostalCode__c);
        System.assertEquals(false, av[0].Verified__c);
        
        //run batch address verification
        Test.StartTest();
        ADDR_Validator_Batch b = new ADDR_Validator_Batch(true);
        Database.executeBatch(b);
        Test.stopTest();
        
        //check address record was verified
        av = [select MailingStreet__c, MailingState__c, MailingPostalCode__c, Verified__c 
                from Address__c where Household_Account__c = :accountId];
        System.assertEquals(1, av.size());
        System.assertEquals('1 Infinite Loop', av[0].MailingStreet__c);
        System.assertEquals('CA', av[0].MailingState__c);
        System.assertEquals('95014-2083', av[0].MailingPostalCode__c);
        System.assertEquals(true, av[0].Verified__c);
        
        /*
        //check verified data got pushed to contact 
        contact = [select id, MailingStreet, MailingCity, MailingPostalCode, MailingState
                         from contact where id = :contact.id];
        System.assertEquals('1 Infinite Loop', contact.MailingStreet);
        System.assertEquals('Cupertino', contact.MailingCity);
        System.assertEquals('95014-2083', contact.MailingPostalCode);
        System.assertEquals('CA', contact.MailingState);
        
        //check verified data got pushed to account
        Account account = [select id, BillingStreet, BillingCity, BillingPostalCode, BillingState
                         from Account where id = :accountId];
        System.assertEquals('1 Infinite Loop', account.BillingStreet);
        System.assertEquals('Cupertino', account.BillingCity);
        System.assertEquals('95014-2083', account.BillingPostalCode);
        System.assertEquals('CA', account.BillingState);*/
    }
    
    public static testmethod void multipleValidAddresses() {
    	if (strTestOnly != '*' && strTestOnly != 'multipleValidAddresses') return;
    	
    	Addr_Verification_Settings__c settings = createDefaultSettings();
        
        //create contacts
        List<Contact> contacts = new List<Contact>();
        for(integer i = 0; i< 200; i++) {
	        Contact contact = new contact(firstname='Test', lastname='Person' + i);
	        contact.MailingStreet = 'multiple-address';
	        contact.MailingCity = 'Cupertino';
	        contact.MailingState = 'ca';
	        contact.MailingPostalCode = '95014';
	        contacts.add(contact);
        }
        insert contacts;
        ADDR_Addresses_TDTM.hasRunAddrTrigger = false;
        
        //check households got created for contacts
        List<Id> AccountIDs = new List<Id>();
        for(Contact c : contacts) {
	        Contact contact = [select Account.Id from Contact where Id = :c.Id];
	        Id accountId = contact.Account.Id;
	        System.assertNotEquals(null, accountId);
	        AccountIDs.add(accountId);
        }
        
        //run batch address verification
        Test.StartTest();
        ADDR_Validator_Batch b = new ADDR_Validator_Batch(true);
        Database.executeBatch(b);
        Test.stopTest();
        
        //check address records were verified
        for(Id accountId : accountIds) {
	        List<Address__c> av = [select MailingStreet__c, MailingState__c, MailingPostalCode__c, Verified__c 
	                from Address__c where Household_Account__c = :accountId];
	        System.assertEquals(1, av.size());
	        System.assertEquals('1 Infinite Loop', av[0].MailingStreet__c);
	        System.assertEquals('CA', av[0].MailingState__c);
	        System.assertEquals('95014-2083', av[0].MailingPostalCode__c);
	        System.assertEquals(true, av[0].Verified__c);
        }
    }
    
    public static testmethod void oneValidZipcode() {
        if (strTestOnly != '*' && strTestOnly != 'oneValidZipcode') return;
    }
    
    public static testmethod void multipleValidZipcodes() {
        if (strTestOnly != '*' && strTestOnly != 'multipleValidZipcodes') return;
    }
    
    public static testmethod void multipleValidAddressessZipcodes() {
    	
    }
    
    public static testmethod void validAddressInvalidZipcode() {
        if (strTestOnly != '*' && strTestOnly != 'validAddressInvalidZipcode') return;
        
        Addr_Verification_Settings__c settings = createDefaultSettings();
        
        //create contacts 
        Contact contact1 = new contact(firstname='Test1', lastname='Person1');
        contact1.MailingStreet = 'multiple-valid-invalid';

        
        Contact contact2 = new contact(firstname='Test2', lastname='Person2');
        contact1.MailingStreet = 'multiple-valid-invalid';
         
        insert new Contact[] {contact1, contact2};
        ADDR_Addresses_TDTM.hasRunAddrTrigger = false;
        
        //check households got created for contacts
        contact1 = [select Account.Id from Contact where Id = :contact1.Id];
        Id accountId1 = contact1.Account.Id;
        System.assertNotEquals(null, accountId1);
        
        contact2 = [select Account.Id from Contact where Id = :contact2.Id];
        Id accountId2 = contact2.Account.Id;
        System.assertNotEquals(null, accountId2);
        
        //check address records got created for households
        Address__c[] av1 = [select Id, MailingStreet__c, MailingState__c, MailingPostalCode__c, Verified__c
                             from Address__c where Household_Account__c = :accountId1];
        System.assertEquals(1, av1.size());
        System.assertEquals('multiple-valid-invalid', av1[0].MailingStreet__c);
        
        Address__c[] av2 = [select Id, MailingStreet__c, MailingState__c, MailingPostalCode__c, Verified__c
                             from Address__c where Household_Account__c = :accountId2];
        System.assertEquals(1, av2.size());
        System.assertEquals('multiple-valid-invalid', av2[0].MailingStreet__c);
        
        //run batch address verification
        Test.StartTest();
        ADDR_Validator_Batch b = new ADDR_Validator_Batch(true);
        Database.executeBatch(b);
        Test.stopTest();
        
        //check address record was verified
        av1 = [select MailingStreet__c, MailingState__c, MailingPostalCode__c, Verified__c 
                from Address__c where Household_Account__c = :accountId1];
        System.assertEquals(1, av1.size());
        System.assertEquals('1 Infinite Loop', av1[0].MailingStreet__c);
        System.assertEquals('CA', av1[0].MailingState__c);
        System.assertEquals('95014-2083', av1[0].MailingPostalCode__c);
        System.assertEquals(true, av1[0].Verified__c);
        
        //check address record was not verified
        av2 = [select MailingStreet__c, MailingState__c, MailingPostalCode__c, Verified__c 
                from Address__c where Household_Account__c = :accountId2];
        System.assertEquals(1, av2.size());
        System.assertEquals(false, av1[0].Verified__c);
    }
        
}