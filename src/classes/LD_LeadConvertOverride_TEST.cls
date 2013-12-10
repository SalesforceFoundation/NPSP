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

    static testMethod void newLeadConversion_TestOne2One(){
        newLeadConversion_Test(CAO_Constants.ONE_TO_ONE_PROCESSOR);
    }
    static testMethod void newLeadConversion_TestHHAccount(){
        newLeadConversion_Test(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    }    
    //tests if the company is called Self. End point depends on the model
    public static void newLeadConversion_Test(string strProcessor) {
        
        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = CAO_Constants.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (npe01__Account_Processor__c = strProcessor));
        CAO_Constants.setIndividualAccountForTests(CAO_Constants.INDIVIDUAL_ACCOUNT_NAME_FOR_TESTS);
        
        Test.setCurrentPageReference(new PageReference('Page.LD_LeadConvertOverride'));
 
        String companyName = 'Individual';
        
        companyName = 'Self';           
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
        
        //this should NOT convert the lead - because it is one to one
        PageReference landingPage = ext.convertLead();
        system.assert(landingPage == null);
        
        // fill the lists (for coverage)
        ext.getConList();
        system.assertEquals(2, ext.conList.size());
        ext.getlcStatuses();
        system.assert(ext.lcStatuses.size() > 0);
        
        // this selects the "New" option in the Contact box
        ext.con = 'NEW_CONTACT';
        
        ext.convertOneToOne();
        
        if (CAO_Constants.isOneToOne() || CAO_Constants.isHHAccountModel()){                
            Contact[] convertedContacts = [select id, firstname, lastname,Account.npe01__Systemisindividual__c, Account.Name from Contact where lastname = :leadLastName];
            //one contact should have been created
            system.assertEquals(1,convertedContacts.size());
            //the account for this contact should be an individual account, no matter the model
            system.assertEquals(true,convertedContacts[0].Account.npe01__Systemisindividual__c);
            String accountName = convertedContacts[0].FirstName + ' ' + convertedContacts[0].lastname;
            if (CAO_Constants.isOneToOne()) {
                system.assertEquals(accountName, convertedContacts[0].Account.Name);
	            List<Account> createdAccount2 = [select id from Account where name = :accountName];
	            system.assertEquals(1,createdAccount2.size());
            } else {
                system.assertEquals(convertedContacts[0].lastname + ' Household', convertedContacts[0].Account.Name);
            }
        } else {
            system.Assert(landingPage.getUrl().contains('leadconvert.jsp'));
        }

    }

    static testMethod void newLeadConversionMerge_TestOne2One(){
        newLeadConversionMerge_Test(CAO_Constants.ONE_TO_ONE_PROCESSOR);
    }
    static testMethod void newLeadConversionMerge_TestHHAccount(){
        newLeadConversionMerge_Test(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    }    
    //tests if the company is called Self. End point depends on the model
    public static void newLeadConversionMerge_Test(string strProcessor) {

        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = CAO_Constants.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (npe01__Account_Processor__c = strProcessor));
        CAO_Constants.setIndividualAccountForTests(CAO_Constants.INDIVIDUAL_ACCOUNT_NAME_FOR_TESTS);
        
        Test.setCurrentPageReference(new PageReference('Page.LD_LeadConvertOverride'));
 
        String companyName = 'Individual';

        companyName = 'Self'; 
        
        // create a contact to merge into
        contact c = new contact(
            FirstName=CAO_Constants.CONTACT_FIRSTNAME_FOR_TESTS,
            LastName=CAO_Constants.CONTACT_LASTNAME_FOR_TESTS
        );          
        insert c;
        
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
        
        //this should NOT convert the lead - because it is one to one
        PageReference landingPage = ext.convertLead();
        system.assert(landingPage == null);
        
        // fill the lists (for coverage)
        ext.getConList();
        system.assertEquals(3, ext.conList.size());
        ext.getlcStatuses();
        system.assert(ext.lcStatuses.size() > 0);
        
        // this selects the Merge to <contact> option in the Contact box
        ext.con = c.id;
        
        ext.convertOneToOne();
        
        if (CAO_Constants.isOneToOne() || CAO_Constants.isHHAccountModel()){                
            Contact[] convertedContacts = [select id, firstname, lastname,Account.npe01__Systemisindividual__c from Contact where lastname = :CAO_Constants.CONTACT_LASTNAME_FOR_TESTS];
            lead[] unconvertedLeads = [select id, firstname, lastname from lead where lastname = :CAO_Constants.CONTACT_LASTNAME_FOR_TESTS and isconverted = false];
            //no lead still unconverted             
            system.assertEquals(0,unconvertedLeads.size());
            //one contact should have been created
            system.assertEquals(1,convertedContacts.size());
            //the account for this contact should be an individual account, no matter the model
            system.assertEquals(true,convertedContacts[0].Account.npe01__Systemisindividual__c);
        } else {
            system.Assert(landingPage.getUrl().contains('leadconvert.jsp'));
        }

    }

    static testMethod void newLeadConversionNamedCompany_TestOne2One(){
        newLeadConversionNamedCompany_Test(CAO_Constants.ONE_TO_ONE_PROCESSOR);
    }
    static testMethod void newLeadConversionNamedCompany_TestHHAccount(){
        newLeadConversionNamedCompany_Test(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    }    
    //tests if it's a regular lead conversion in either model
    public static void newLeadConversionNamedCompany_Test(string strProcessor) {

        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = CAO_Constants.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (npe01__Account_Processor__c = strProcessor));
        CAO_Constants.setIndividualAccountForTests(CAO_Constants.INDIVIDUAL_ACCOUNT_NAME_FOR_TESTS);
        
        Test.setCurrentPageReference(new PageReference('Page.LD_LeadConvertOverride'));
        
        String companyName = 'Individual';
        
        companyName = 'Junky company for tests';

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
        PageReference landingPage = ext.convertLead();
        system.Assert(landingPage.getUrl().contains('leadconvert.jsp'));
    }
    
    static testMethod void newLeadConversionNamedCompanyNoFirstName_TestOne2One(){
        newLeadConversionNamedCompanyNoFirstName_Test(CAO_Constants.ONE_TO_ONE_PROCESSOR);
    }
    static testMethod void newLeadConversionNamedCompanyNoFirstName_TestHHAccount(){
        newLeadConversionNamedCompanyNoFirstName_Test(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    }    
     //tests if it's a regular lead conversion in either model
    public static void newLeadConversionNamedCompanyNoFirstName_Test(string strProcessor) {

        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = CAO_Constants.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (npe01__Account_Processor__c = strProcessor));
        CAO_Constants.setIndividualAccountForTests(CAO_Constants.INDIVIDUAL_ACCOUNT_NAME_FOR_TESTS);
        
        Test.setCurrentPageReference(new PageReference('Page.LD_LeadConvertOverride')); 
        
        String companyName = 'Individual';
        
        
        companyName = 'Junky company for tests';

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
        PageReference landingPage = ext.convertLead();
        system.Assert(landingPage.getUrl().contains('leadconvert.jsp'));
    }
    
    static testMethod void newLeadWithCompanyMatchingLeadName_TestOne2One(){
        newLeadWithCompanyMatchingLeadName_Test(CAO_Constants.ONE_TO_ONE_PROCESSOR);
    }
    static testMethod void nnewLeadWithCompanyMatchingLeadName_TestHHAccount(){
        newLeadWithCompanyMatchingLeadName_Test(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    }    
    //tests if the company has the exact same name as the lead. End point depends on the model
    public static void newLeadWithCompanyMatchingLeadName_Test(string strProcessor) {
        
        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = CAO_Constants.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (npe01__Account_Processor__c = strProcessor));
        CAO_Constants.setIndividualAccountForTests(CAO_Constants.INDIVIDUAL_ACCOUNT_NAME_FOR_TESTS);
        
        Test.setCurrentPageReference(new PageReference('Page.LD_LeadConvertOverride'));
        
        String companyName = 'Individual';
        
        companyName = 'test lead for tests_989';

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
        PageReference landingPage = ext.convertLead();
        
    }
    
    static testMethod void newLeadBucketModelWithCompanyBucket(){
        newLeadBucketModelWithCompany(CAO_Constants.BUCKET_PROCESSOR);
    }
    static testMethod void newLeadBucketModelWithCompanyHHAccount(){
        newLeadBucketModelWithCompany(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    }    
    //make sure the lead conversion respects the bucket model
    public static void newLeadBucketModelWithCompany(string strProcessor){
        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = CAO_Constants.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (npe01__Account_Processor__c = strProcessor));
        CAO_Constants.setIndividualAccountForTests(CAO_Constants.INDIVIDUAL_ACCOUNT_NAME_FOR_TESTS);
        
        Test.setCurrentPageReference(new PageReference('Page.LD_LeadConvertOverride'));
        
        String companyName = 'FunkyTown USA';
        
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
        //set the toggle
        ext.con = 'NEW_CONTACT';
        
        ext.leadConvStatus = [select Masterlabel from LeadStatus where IsConverted = true limit 1].MasterLabel; 
        test.startTest();
        PageReference landingPage = ext.convertOnetoOne();
        test.stopTest();
        
        Contact c = [select id, Account.Name from Contact where FirstName = :CAO_Constants.CONTACT_FIRSTNAME_FOR_TESTS and LastName = :CAO_Constants.CONTACT_LASTNAME_FOR_TESTS];
        
        //bucket model should forward the company account name
        //and not attach the individual unless no name is provided 
        if (CAO_Constants.isBucketModel()) 
            system.assertEquals('FunkyTown USA', c.Account.Name);
        else
            system.assertEquals(CAO_Constants.CONTACT_LASTNAME_FOR_TESTS + ' Household', c.Account.Name);   
           
    }
    
    static testMethod void newLeadBucketModelWithOutCompanyBucket(){
        newLeadBucketModelWithOutCompany(CAO_Constants.BUCKET_PROCESSOR);
    }
    static testMethod void newLeadBucketModelWithOutCompanyHHAccount(){
        newLeadBucketModelWithOutCompany(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    }    
    public static void newLeadBucketModelWithOutCompany(string strProcessor){
        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = CAO_Constants.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (npe01__Account_Processor__c = strProcessor));
        CAO_Constants.setIndividualAccountForTests(CAO_Constants.INDIVIDUAL_ACCOUNT_NAME_FOR_TESTS);
        
        Test.setCurrentPageReference(new PageReference('Page.LD_LeadConvertOverride'));
        
        String companyName = 'self';
        
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
        //set the toggle
        ext.con = 'NEW_CONTACT';
        
        ext.leadConvStatus = [select MasterLabel from LeadStatus where IsConverted = true limit 1].MasterLabel; 
        test.startTest();
        PageReference landingPage = ext.convertOnetoOne();
        test.stopTest();
        
        Contact c = [select id, Account.Name from Contact where FirstName = :CAO_Constants.CONTACT_FIRSTNAME_FOR_TESTS and LastName = :CAO_Constants.CONTACT_LASTNAME_FOR_TESTS];
        
        //bucket model should forward the company account name
        //and not attach the individual unless no name is provided 
        if (CAO_Constants.isBucketModel()) 
            system.assertEquals(CAO_Constants.INDIVIDUAL_ACCOUNT_NAME_FOR_TESTS, c.Account.Name);
        else
            system.assertEquals(CAO_Constants.CONTACT_LASTNAME_FOR_TESTS + ' Household', c.Account.Name);   
    }
    
    
}