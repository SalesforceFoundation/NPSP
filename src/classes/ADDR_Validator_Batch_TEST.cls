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

    public static testmethod void testBatch() {
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
        
        //create contact 
        Contact contact = new contact(firstname='Test', lastname='Person');
        contact.MailingStreet = 'single-address-response';
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
        System.assertEquals('single-address-response', av[0].MailingStreet__c);
        System.assertEquals('ca', av[0].MailingState__c);
        System.assertEquals('95014', av[0].MailingPostalCode__c);
        System.assertEquals(false, av[0].Verified__c);
        
        //turn SmartyStreets verification on
        settings.Using_SmartyStreets__c = true;
        update settings;
        
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
}