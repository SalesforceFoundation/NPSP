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
* @description Tests for lead convert override
*/
@isTest
private class LD_LeadConvertOverride_TEST {

    // if you only want to run one test in this class, fill in its name here.
    // if you want to run all tests, then use '*'
    private static string strTestOnly = '*';

    static testMethod void newLeadConversion_TestOne2One(){
        newLeadConversion_Test(CAO_Constants.ONE_TO_ONE_PROCESSOR);
    }
    static testMethod void newLeadConversion_TestHHAccount(){
        newLeadConversion_Test(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    }    
    static testMethod void newLeadConversion_TestBucketAccount(){
        newLeadConversion_Test(CAO_Constants.BUCKET_PROCESSOR);
    }    
    //tests if the company is called Self. End point depends on the model
    public static void newLeadConversion_Test(string strProcessor) {
        if (strTestOnly != '*' && strTestOnly != 'newLeadConversion_Test') return;
        
        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_and_Orgs_Settings__c (npe01__Account_Processor__c = strProcessor));
        CAO_Constants.setIndividualAccountForTests(CAO_Constants.INDIVIDUAL_ACCOUNT_NAME_FOR_TESTS);
        
        Test.setCurrentPageReference(new PageReference('Page.LD_LeadConvertOverride'));
        string companyName = 'Self';           
        String leadFirstName = 'Leady';
        String leadLastName = 'lead for tests_987';
        Lead l = new Lead();
        l.FirstName = leadFirstName;
        l.LastName = leadLastName;
        l.Company = companyName;
        insert l;
        
        system.currentPageReference().getParameters().put('id', l.id);
        
        //pass contact into the controller
        ApexPages.StandardController sc = new ApexPages.standardController(l);
        
        //pass the controller into the extension
        LD_LeadConvertOverride_CTRL ext = new LD_LeadConvertOverride_CTRL(sc); 
        
        // fill the lists (for coverage)
        ext.getConList();
        system.assertEquals(2, ext.conList.size());
        system.assert(ext.lcStatuses.size() > 0);
        system.assert(ext.leadConvStatus != null && ext.leadConvStatus != '');
        
        // this selects the "New" option in the Contact box
        ext.con = 'NEW_CONTACT';        
        ext.convertLeadNow();
        
        Contact[] convertedContacts = [select id, firstname, lastname,Account.npe01__Systemisindividual__c, Account.Name from Contact where lastname = :leadLastName];
        //one contact should have been created
        system.assertEquals(1,convertedContacts.size());
        system.assertEquals(true,convertedContacts[0].Account.npe01__Systemisindividual__c);

        String accountName = convertedContacts[0].FirstName + ' ' + convertedContacts[0].lastname;
        if (CAO_Constants.isOneToOne()) {
            system.assertEquals(accountName, convertedContacts[0].Account.Name);
            List<Account> createdAccount2 = [select id from Account where name = :accountName];
            system.assertEquals(1,createdAccount2.size());
        } else if (CAO_Constants.isHHAccountModel()) {
            system.assertEquals(convertedContacts[0].lastname + ' Household', convertedContacts[0].Account.Name);
        } else if (CAO_Constants.isBucketModel()) {
            system.assertEquals(CAO_Constants.INDIVIDUAL_ACCOUNT_NAME_FOR_TESTS, convertedContacts[0].Account.Name);
        }
    }


    static testMethod void newLeadConversionMerge_TestOne2One() {
        newLeadConversionMerge_Test(CAO_Constants.ONE_TO_ONE_PROCESSOR);
    }
    static testMethod void newLeadConversionMerge_TestHHAccount(){
        newLeadConversionMerge_Test(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    }    
    static testMethod void newLeadConversionMerge_TestBucketAccount(){
        newLeadConversionMerge_Test(CAO_Constants.BUCKET_PROCESSOR);
    }    
    public static void newLeadConversionMerge_Test(string strProcessor) {
        if (strTestOnly != '*' && strTestOnly != 'newLeadConversionMerge_Test') return;

        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_and_Orgs_Settings__c (npe01__Account_Processor__c = strProcessor));
        CAO_Constants.setIndividualAccountForTests(CAO_Constants.INDIVIDUAL_ACCOUNT_NAME_FOR_TESTS);
        
        Test.setCurrentPageReference(new PageReference('Page.LD_LeadConvertOverride'));
 
        // create a contact to merge into
        contact c = new contact(
            FirstName=CAO_Constants.CONTACT_FIRSTNAME_FOR_TESTS,
            LastName=CAO_Constants.CONTACT_LASTNAME_FOR_TESTS
        );          
        insert c;
        
        Lead l = new Lead();
        l.FirstName = CAO_Constants.CONTACT_FIRSTNAME_FOR_TESTS;
        l.LastName = CAO_Constants.CONTACT_LASTNAME_FOR_TESTS;
        l.Company = 'self';
        insert l;
        
        system.currentPageReference().getParameters().put('id', l.id);
        
        //pass contact into the controller
        ApexPages.StandardController sc = new ApexPages.standardController(l);
        
        //pass the controller into the extension
        LD_LeadConvertOverride_CTRL ext = new LD_LeadConvertOverride_CTRL(sc); 
        
        // fill the lists (for coverage)
        ext.getConList();
        system.assertEquals(3, ext.conList.size());
        system.assert(ext.lcStatuses.size() > 0);
        
        // this selects the Merge to <contact> option in the Contact box
        ext.con = c.id;        
        ext.convertLeadNow();

        Contact[] convertedContacts = [select id, firstname, lastname,Account.npe01__Systemisindividual__c from Contact where lastname = :CAO_Constants.CONTACT_LASTNAME_FOR_TESTS];
        lead[] unconvertedLeads = [select id, firstname, lastname from lead where lastname = :CAO_Constants.CONTACT_LASTNAME_FOR_TESTS and isconverted = false];
        //no lead still unconverted             
        system.assertEquals(0,unconvertedLeads.size());
        //one contact should have been created
        system.assertEquals(1,convertedContacts.size());
        //the account for this contact should be an individual account, no matter the model
        system.assertEquals(true, convertedContacts[0].Account.npe01__Systemisindividual__c);        
    }


    static testMethod void newLeadConversionNewNamedCompany_TestOne2One(){
        newLeadConversionNewNamedCompany_Test(CAO_Constants.ONE_TO_ONE_PROCESSOR);
    }
    static testMethod void newLeadConversionNewNamedCompany_TestHHAccount(){
        newLeadConversionNewNamedCompany_Test(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    }    
    static testMethod void newLeadConversionNewNamedCompany_TestBucketAccount(){
        newLeadConversionNewNamedCompany_Test(CAO_Constants.BUCKET_PROCESSOR);
    }    
    public static void newLeadConversionNewNamedCompany_Test(string strProcessor) {
        if (strTestOnly != '*' && strTestOnly != 'newLeadConversionNewNamedCompany_Test') return;

        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_and_Orgs_Settings__c (npe01__Account_Processor__c = strProcessor));
        CAO_Constants.setIndividualAccountForTests(CAO_Constants.INDIVIDUAL_ACCOUNT_NAME_FOR_TESTS);
        
        Test.setCurrentPageReference(new PageReference('Page.LD_LeadConvertOverride'));
        
        string companyName = 'Junky company for tests';
        Lead l = new Lead();
        l.FirstName = CAO_Constants.CONTACT_FIRSTNAME_FOR_TESTS;
        l.LastName = CAO_Constants.CONTACT_LASTNAME_FOR_TESTS;
        l.Company = companyName;
        l.Status = 'Open';
        insert l;
        
        system.currentPageReference().getParameters().put('id', l.id);
        
        //pass contact into the controller
        ApexPages.StandardController sc = new ApexPages.standardController(l);
        //pass the controller into the extension
        LD_LeadConvertOverride_CTRL ext = new LD_LeadConvertOverride_CTRL(sc); 

        // this selects the "New" option in the Contact box
        ext.con = 'NEW_CONTACT';        
        ext.convertLeadNow();

        Contact[] convertedContacts = [select id, firstname, lastname, Account.npe01__Systemisindividual__c, Account.Name from Contact where lastname = :CAO_Constants.CONTACT_LASTNAME_FOR_TESTS];
        lead[] unconvertedLeads = [select id, firstname, lastname from lead where lastname = :CAO_Constants.CONTACT_LASTNAME_FOR_TESTS and isconverted = false];
        //no lead still unconverted             
        system.assertEquals(0,unconvertedLeads.size());
        //one contact should have been created
        system.assertEquals(1,convertedContacts.size());
        //the account for this contact should be a normal account, no matter the model
        system.assertEquals(false, convertedContacts[0].Account.npe01__Systemisindividual__c);
        system.assertEquals(companyName, convertedContacts[0].Account.Name);        
    }
    
    
    static testMethod void newLeadConversionExistingNamedCompany_TestOne2One(){
        newLeadConversionExistingNamedCompany_Test(CAO_Constants.ONE_TO_ONE_PROCESSOR);
    }
    static testMethod void newLeadConversionExistingNamedCompany_TestHHAccount(){
        newLeadConversionExistingNamedCompany_Test(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    }    
    static testMethod void newLeadConversionExistingNamedCompany_TestBucketAccount(){
        newLeadConversionExistingNamedCompany_Test(CAO_Constants.BUCKET_PROCESSOR);
    }    
    public static void newLeadConversionExistingNamedCompany_Test(string strProcessor) {
        if (strTestOnly != '*' && strTestOnly != 'newLeadConversionExistingNamedCompany_Test') return;

        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_and_Orgs_Settings__c (npe01__Account_Processor__c = strProcessor));
        CAO_Constants.setIndividualAccountForTests(CAO_Constants.INDIVIDUAL_ACCOUNT_NAME_FOR_TESTS);
        
        Test.setCurrentPageReference(new PageReference('Page.LD_LeadConvertOverride'));
        
        string companyName = 'Junky company for tests';
        //create a real company account
        Account acc = new Account();
        acc.Name = companyName;
        insert acc;        
        
        Lead l = new Lead();
        l.FirstName = CAO_Constants.CONTACT_FIRSTNAME_FOR_TESTS;
        l.LastName = CAO_Constants.CONTACT_LASTNAME_FOR_TESTS;
        l.Company = companyName;
        l.Status = 'Open';
        insert l;
        
        system.currentPageReference().getParameters().put('id', l.id);
        
        //pass contact into the controller
        ApexPages.StandardController sc = new ApexPages.standardController(l);
        //pass the controller into the extension
        LD_LeadConvertOverride_CTRL ext = new LD_LeadConvertOverride_CTRL(sc); 

        // this selects the "New" option in the Contact box
        ext.con = 'NEW_CONTACT';        
        ext.convertLeadNow();

        Contact[] convertedContacts = [select id, firstname, lastname, Account.npe01__Systemisindividual__c, Account.Name from Contact where lastname = :CAO_Constants.CONTACT_LASTNAME_FOR_TESTS];
        lead[] unconvertedLeads = [select id, firstname, lastname from lead where lastname = :CAO_Constants.CONTACT_LASTNAME_FOR_TESTS and isconverted = false];
        //no lead still unconverted             
        system.assertEquals(0,unconvertedLeads.size());
        //one contact should have been created
        system.assertEquals(1,convertedContacts.size());
        //the account for this contact should be a normal account, no matter the model
        system.assertEquals(false, convertedContacts[0].Account.npe01__Systemisindividual__c);
        system.assertEquals(companyName, convertedContacts[0].Account.Name);        
    }

    
    // tests if it's a regular lead conversion and HH Objects are in use, we still get Household Object
    static testMethod void newLeadConversionHHObjOne2One(){
        newLeadConversionHHObj(CAO_Constants.ONE_TO_ONE_PROCESSOR);
    }
    static testMethod void newLeadConversionHHObjBucket(){
        newLeadConversionHHObj(CAO_Constants.BUCKET_PROCESSOR);
    }    
    public static void newLeadConversionHHObj(string strProcessor) {
        if (strTestOnly != '*' && strTestOnly != 'newLeadConversionHHObj') return;

        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_and_Orgs_Settings__c (npe01__Account_Processor__c = strProcessor));
        CAO_Constants.setIndividualAccountForTests(CAO_Constants.INDIVIDUAL_ACCOUNT_NAME_FOR_TESTS);
        
        npo02__Households_Settings__c householdSettingsForTests = UTIL_CustomSettingsFacade.getHouseholdsSettingsForTests(
            new npo02__Households_Settings__c (npo02__Household_Rules__c = HH_Households.ALL_PROCESSOR));

        Test.setCurrentPageReference(new PageReference('Page.LD_LeadConvertOverride'));
 
        string companyName = 'Self';           
        Lead l = new Lead();
        l.FirstName = CAO_Constants.CONTACT_FIRSTNAME_FOR_TESTS;
        l.LastName = CAO_Constants.CONTACT_LASTNAME_FOR_TESTS;
        l.Company = companyName;
        insert l;
        
        system.currentPageReference().getParameters().put('id', l.id);
        
        //pass contact into the controller
        ApexPages.StandardController sc = new ApexPages.standardController(l);
        
        //pass the controller into the extension
        LD_LeadConvertOverride_CTRL ext = new LD_LeadConvertOverride_CTRL(sc); 
        
        // fill the lists (for coverage)
        ext.getConList();
        system.assertEquals(2, ext.conList.size());
        system.assert(ext.lcStatuses.size() > 0);
        
        // this selects the "New" option in the Contact box
        ext.con = 'NEW_CONTACT';        
        ext.convertLeadNow();
        
        Contact[] convertedContacts = [select id, firstname, lastname, npo02__Household__c, Account.npe01__Systemisindividual__c from Contact where lastname = :CAO_Constants.CONTACT_LASTNAME_FOR_TESTS];
        lead[] unconvertedLeads = [select id, firstname, lastname from lead where lastname = :CAO_Constants.CONTACT_LASTNAME_FOR_TESTS and isconverted = false];
        //no lead still unconverted             
        system.assertEquals(0,unconvertedLeads.size());
        //one contact should have been created
        system.assertEquals(1,convertedContacts.size());
        //the account for this contact should be an individual account, no matter the model
        system.assertEquals(true, convertedContacts[0].Account.npe01__Systemisindividual__c);        
 
        // make sure HH created
        list<npo02__Household__c> listHH = [select Id, Name from npo02__Household__c];
        system.assertEquals(1, listHH.size());
        system.assertEquals(convertedContacts[0].npo02__Household__c, listHH[0].Id);
    }
    
}