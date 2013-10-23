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
* @date 2011
* @description test class for Opportunity Rollup functionality
*/
@isTest
public with sharing class RLLP_OppRollup_TEST {
    
    static testMethod void testGivingRollup(){
                
        String giftRecordTypeNameForTests = RecordTypes.getRecordTypeNameForGiftsTests('Opportunity');
        
        Households_Settings__c householdSettingsForTests = Households.getHouseholdsSettingsForTests(
            new Households_Settings__c (
            Household_Rules__c = Households.ALL_PROCESSOR, 
            Always_Rollup_to_Primary_Contact__c = false,
            Enable_Opp_Rollup_Triggers__c = true,
            Excluded_Account_Opp_Rectypes__c = null,
            Excluded_Account_Opp_Types__c = null,
            Excluded_Contact_Opp_Rectypes__c = null,
            Excluded_Contact_Opp_Types__c = null,
            Membership_Record_Types__c = null
        )); 
            
        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = npe01.Constants.getContactsSettingsForTests(
            new npe01__Contacts_and_Orgs_Settings__c (
            npe01__Account_Processor__c = npe01.Constants.ONE_TO_ONE_PROCESSOR,
            npe01__Enable_Opportunity_Contact_Role_Trigger__c = true,
            npe01__Opportunity_Contact_Role_Default_role__c = 'Donor'
        ));
            
        Date datClose = System.Today();
                
        // create & insert contact(s)
        Contact c = new Contact( 
            FirstName = npe01.Constants.CONTACT_FIRSTNAME_FOR_TESTS,
            LastName = npe01.Constants.CONTACT_LASTNAME_FOR_TESTS,
            npe01__Private__c=false,
            npe01__WorkEmail__c = npe01.Constants.CONTACT_EMAIL_FOR_TESTS, 
            npe01__Preferred_Email__c = npe01.Constants.CONTACT_PREFERRED_EMAIL_FOR_TESTS,
            npe01__WorkPhone__c = npe01.Constants.CONTACT_PHONE_FOR_TESTS,
            npe01__PreferredPhone__c = npe01.Constants.CONTACT_PREFERRED_PHONE_FOR_TESTS
        );
        insert c;        
                        
        //create new opp            
        Opportunity o = new Opportunity(
                    Name = 'Test Opp 45',
                    CloseDate = datClose,
                    StageName = UnitTestData.getClosedWonStage(),
                    npe01__Contact_Id_for_Role__c = c.id,
                    Amount = 100, 
                    RecordTypeId = RecordTypes.GetRecordTypeId('Opportunity', giftRecordTypeNameForTests)
                    );
        
        //insert the opp(s)
        Test.StartTest();
        insert o;
        Test.StopTest();
        
        system.assertEquals('true', [select npe01__Is_Opp_from_Individual__c from Opportunity where id = :o.id].npe01__Is_Opp_from_Individual__c);
        system.AssertEquals(1, [select count() from OpportunityContactRole where ContactId = :c.id and isPrimary = true]);
        system.AssertEquals(1, [select count() from Account where npe01__One2OneContact__c = :c.id and npe01__SYSTEMIsIndividual__c = true]);
                  
        //now test that a contact has received the proper member stats from the trigger
        Contact UpdatedCon = [SELECT id, npo02__OppAmountLastNDays__c, npo02__OppAmountThisYear__c, npo02__TotalMembershipOppAmount__c,
                                    npo02__OppAmount2YearsAgo__c, npo02__OppAmountLastYear__c, npo02__household__c,
                                    Best_Gift_Year__c, Best_Gift_Year_Total__c, Household__r.Best_Gift_Year__c, Household__r.Best_Gift_Year_Total__c,  
                                    npo02__household__r.npo02__TotalOppAmount__c, npo02__TotalOppAmount__c, LastCloseDate__c 
                                    FROM Contact WHERE Id = :c.id];
    
        system.AssertEquals(100, UpdatedCon.npo02__TotalOppAmount__c);
        system.AssertEquals(100, UpdatedCon.npo02__Household__r.npo02__TotalOppAmount__c);      
        system.AssertEquals(100, UpdatedCon.npo02__OppAmountThisYear__c);
        system.AssertEquals(0, UpdatedCon.npo02__OppAmountLastYear__c);
        system.AssertEquals(100, UpdatedCon.Best_Gift_Year_Total__c);
        system.AssertEquals(string.valueof(datClose.year()), UpdatedCon.Best_Gift_Year__c);
        system.AssertEquals(100, UpdatedCon.Household__r.Best_Gift_Year_Total__c);
        system.AssertEquals(string.valueof(datClose.year()), UpdatedCon.Household__r.Best_Gift_Year__c);        
    }
    
    static testMethod void testGivingRollupIndividual () {
       
        String giftRecordTypeNameForTests = RecordTypes.getRecordTypeNameForGiftsTests('Opportunity');
            Households_Settings__c householdSettingsForTests = Households.getHouseholdsSettingsForTests(
                new Households_Settings__c (
                    Household_Rules__c = Households.ALL_PROCESSOR,
                    Always_Rollup_to_Primary_Contact__c = false,
                    Enable_Opp_Rollup_Triggers__c = true,
                    Excluded_Account_Opp_Rectypes__c = null,
                    Excluded_Account_Opp_Types__c = null,
                    Excluded_Contact_Opp_Rectypes__c = null,
                    Excluded_Contact_Opp_Types__c = null,
                    Membership_Record_Types__c = null
                ));
            
            npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = npe01.Constants.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (
                npe01__Account_Processor__c = npe01.Constants.BUCKET_PROCESSOR,
                npe01__Enable_Opportunity_Contact_Role_Trigger__c = true,
                npe01__Opportunity_Contact_Role_Default_role__c = 'Donor'
            ));
            
            Date datClose = System.Today();
                
            // create & insert contact(s)
            Contact[] TestCons = new contact[]{ new contact(
                FirstName= npe01.Constants.CONTACT_FIRSTNAME_FOR_TESTS,
                LastName= npe01.Constants.CONTACT_LASTNAME_FOR_TESTS,
                npe01__Private__c=false,
                npe01__WorkEmail__c = npe01.Constants.CONTACT_EMAIL_FOR_TESTS, 
                npe01__Preferred_Email__c = npe01.Constants.CONTACT_PREFERRED_EMAIL_FOR_TESTS,
                npe01__WorkPhone__c = npe01.Constants.CONTACT_PHONE_FOR_TESTS,
                npe01__PreferredPhone__c = npe01.Constants.CONTACT_PREFERRED_PHONE_FOR_TESTS
            ) };
            insert TestCons;
    
            // create new opps
            Opportunity[] newOpps = UnitTestData.OppsForContactList ( TestCons, null, UnitTestData.getClosedWonStage(), datClose, 100 , giftRecordTypeNameForTests ,null);
    
            // insert the opp(s)
            Test.StartTest();
            insert newOpps;
            Test.StopTest();
            
            //now test that a contact has received the proper member stats from the trigger
            id FirstConId = TestCons[0].id;
            Contact UpdatedCon = [SELECT id, account.npo02__TotalOppAmount__c, npo02__OppAmountThisYear__c, npo02__OppAmountLastYear__c, npo02__household__c, npo02__household__r.npo02__TotalOppAmount__c, npo02__TotalOppAmount__c, npo02__household__r.npo02__MembershipEndDate__c, npo02__MembershipJoinDate__c FROM Contact WHERE Id = :FirstConId];
    
            System.AssertEquals ( 100 , UpdatedCon.npo02__TotalOppAmount__c );
            System.AssertEquals ( 100 , UpdatedCon.npo02__household__r.npo02__TotalOppAmount__c );      
            System.AssertEquals ( 100 , UpdatedCon.npo02__OppAmountThisYear__c);
            System.AssertEquals ( 0 , UpdatedCon.npo02__OppAmountLastYear__c);
    
            // now roll up manually
            OpportunityRollups rg = new OpportunityRollups();
            rg.rollupContacts(new map<id, Contact>(new list<Contact>{TestCons[0]}));
         
            id hhid = UpdatedCon.npo02__household__r.id;
            npo02__Household__c[] hhs = database.query('SELECT id, npo02__TotalOppAmount__c, npo02__LastCloseDate__c, '+
            'npo02__TotalMembershipOppAmount__c, npo02__OppAmountLastNDays__c, npo02__OppAmountThisYear__c, npo02__LastMembershipLevel__c, ' +
            'npo02__OppAmountLastYear__c, npo02__OppAmount2YearsAgo__c, npo02__MembershipJoinDate__c, npo02__MembershipEndDate__c, '+
            'npo02__Best_Gift_Year__c, npo02__Best_Gift_Year_Total__c ' +
            (OpportunityRollup_Utilities.isMultiCurrency() ? ', CurrencyIsoCode ' : '')+      
            'FROM npo02__household__c WHERE id = :hhid LIMIT 1');
        
            rg = new OpportunityRollups();
            rg.rollupHouseholds(new map<id, npo02__Household__c>(hhs));
    
            //make sure the values are still right
            UpdatedCon = [SELECT id, account.npo02__TotalOppAmount__c, 
                                npo02__OppAmountThisYear__c, npo02__OppAmountLastYear__c, npo02__household__c, 
                                npo02__household__r.npo02__TotalOppAmount__c, npo02__TotalOppAmount__c FROM Contact WHERE Id = :FirstConId];
    
            System.AssertEquals (100 , UpdatedCon.npo02__TotalOppAmount__c);
            System.AssertEquals (100 , UpdatedCon.npo02__household__r.npo02__TotalOppAmount__c);      
            System.AssertEquals (100 , UpdatedCon.npo02__OppAmountThisYear__c);
            System.AssertEquals (0 , UpdatedCon.npo02__OppAmountLastYear__c);
        
    }
    
    static testMethod void testGivingRollupExcludedRT () {
      
        String giftRecordTypeNameForTests = RecordTypes.getRecordTypeNameForGiftsTests('Opportunity');
        if(giftRecordTypeNameForTests!=''){
            Households_Settings__c householdSettingsForTests = Households.getHouseholdsSettingsForTests(
                new Households_Settings__c (
                    Household_Rules__c = Households.ALL_PROCESSOR,
                    Always_Rollup_to_Primary_Contact__c = false,
                    Enable_Opp_Rollup_Triggers__c = true,
                    Excluded_Account_Opp_Rectypes__c = giftRecordTypeNameForTests,
                    Excluded_Account_Opp_Types__c = null,
                    Excluded_Contact_Opp_Rectypes__c = giftRecordTypeNameForTests,
                    Excluded_Contact_Opp_Types__c = null,
                    Membership_Record_Types__c = null
                ));
            
            npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = npe01.Constants.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (
                npe01__Account_Processor__c = npe01.Constants.ONE_TO_ONE_PROCESSOR,
                npe01__Enable_Opportunity_Contact_Role_Trigger__c = true,
                npe01__Opportunity_Contact_Role_Default_role__c = 'Donor'
            ));
            
            Date datClose = System.Today();
                
            // create & insert contact(s)
            Contact[] TestCons = new contact[]{ new contact(
                FirstName= npe01.Constants.CONTACT_FIRSTNAME_FOR_TESTS,
                LastName= npe01.Constants.CONTACT_LASTNAME_FOR_TESTS,
                npe01__Private__c=false,
                npe01__WorkEmail__c = npe01.Constants.CONTACT_EMAIL_FOR_TESTS, 
                npe01__Preferred_Email__c = npe01.Constants.CONTACT_PREFERRED_EMAIL_FOR_TESTS,
                npe01__WorkPhone__c = npe01.Constants.CONTACT_PHONE_FOR_TESTS,
                npe01__PreferredPhone__c = npe01.Constants.CONTACT_PREFERRED_PHONE_FOR_TESTS
            ) };
            insert TestCons;
    
            // create new opps
            Opportunity[] newOpps = UnitTestData.OppsForContactList ( TestCons, null, UnitTestData.getClosedWonStage(), datClose, 100 , giftRecordTypeNameForTests ,null);
    
            // insert the opp(s)
            Test.StartTest();
            insert newOpps;
            Test.StopTest();
            
            //now test that a contact has received the proper member stats from the trigger
            id FirstConId = TestCons[0].id;
            Contact UpdatedCon = [SELECT id, account.npo02__TotalOppAmount__c, npo02__OppAmountThisYear__c, npo02__OppAmountLastYear__c, npo02__household__c, npo02__household__r.npo02__TotalOppAmount__c, npo02__TotalOppAmount__c FROM Contact WHERE Id = :FirstConId];
    
            System.AssertEquals ( 0 , UpdatedCon.npo02__TotalOppAmount__c );
            System.AssertEquals ( 0 , UpdatedCon.npo02__household__r.npo02__TotalOppAmount__c );        
            System.AssertEquals ( 0 , UpdatedCon.npo02__OppAmountThisYear__c);
    
            // now roll up manually
            OpportunityRollups rg = new OpportunityRollups();
            rg.rollupContacts(new map<id, Contact>(new list<Contact>{TestCons[0]}));
        
            id hhid = UpdatedCon.npo02__household__r.id;
            npo02__Household__c[] hhs = database.query('SELECT id, npo02__TotalOppAmount__c, npo02__LastCloseDate__c, '+
            'npo02__TotalMembershipOppAmount__c, npo02__OppAmountLastNDays__c, npo02__OppAmountThisYear__c, '+
            'npo02__OppAmountLastYear__c, npo02__OppAmount2YearsAgo__c, npo02__MembershipJoinDate__c, npo02__MembershipEndDate__c, '+
            'npo02__LastMembershipLevel__c, ' +
            'npo02__Best_Gift_Year__c, npo02__Best_Gift_Year_Total__c ' +
            (OpportunityRollup_Utilities.isMultiCurrency() ? ', CurrencyIsoCode ' : '')+      
            'FROM npo02__household__c WHERE id = :hhid LIMIT 1');
            
            rg = new OpportunityRollups();
            rg.rollupHouseholds(new map<id, Household__c>(hhs));
    
            //make sure the values are still right
            UpdatedCon = [SELECT id, Account.npo02__TotalOppAmount__c, npo02__OppAmountThisYear__c, npo02__OppAmountLastYear__c, npo02__Household__c, npo02__Household__r.npo02__TotalOppAmount__c, npo02__TotalOppAmount__c FROM Contact WHERE Id = :FirstConId];
    
            System.AssertEquals (0, UpdatedCon.npo02__TotalOppAmount__c );
            System.AssertEquals (0, UpdatedCon.npo02__household__r.npo02__TotalOppAmount__c );        
            System.AssertEquals (0, UpdatedCon.npo02__OppAmountThisYear__c);
            System.AssertEquals (0, UpdatedCon.npo02__OppAmountLastYear__c);
        }
    }
    
    
   static testMethod void testGivingRollupAlwaysPrimary () {

        String giftRecordTypeNameForTests = RecordTypes.getRecordTypeNameForGiftsTests('Opportunity');
            Households_Settings__c householdSettingsForTests = Households.getHouseholdsSettingsForTests(
                new Households_Settings__c (
                    Household_Rules__c = Households.ALL_PROCESSOR,
                    Always_Rollup_to_Primary_Contact__c = true,
                    Enable_Opp_Rollup_Triggers__c = true,
                    Excluded_Account_Opp_Rectypes__c = null,
                    Excluded_Account_Opp_Types__c = null,
                    Excluded_Contact_Opp_Rectypes__c = null,
                    Excluded_Contact_Opp_Types__c = null,
                    Membership_Record_Types__c = null
                ));
            
            npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = npe01.Constants.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (
                npe01__Account_Processor__c = npe01.Constants.ONE_TO_ONE_PROCESSOR,
                npe01__Enable_Opportunity_Contact_Role_Trigger__c = true,
                npe01__Opportunity_Contact_Role_Default_role__c = 'Donor'
            ));
            
            Date datClose = System.Today();
            // create account
            account testacct = new account(name='testacct');
            insert testacct;
            // create & insert contact(s)
            Contact[] TestCons = new contact[]{ new contact(
                FirstName= npe01.Constants.CONTACT_FIRSTNAME_FOR_TESTS,
                LastName= npe01.Constants.CONTACT_LASTNAME_FOR_TESTS,
                npe01__Private__c=false,
                AccountId = testacct.id,
                npe01__WorkEmail__c = npe01.Constants.CONTACT_EMAIL_FOR_TESTS, 
                npe01__Preferred_Email__c = npe01.Constants.CONTACT_PREFERRED_EMAIL_FOR_TESTS,
                npe01__WorkPhone__c = npe01.Constants.CONTACT_PHONE_FOR_TESTS,
                npe01__PreferredPhone__c = npe01.Constants.CONTACT_PREFERRED_PHONE_FOR_TESTS
            ) };
            insert TestCons;
    
            // create new opps
            Opportunity[] newOpps = UnitTestData.OppsForContactList ( TestCons, null, UnitTestData.getClosedWonStage(), datClose, 100 , giftRecordTypeNameForTests ,null);
    
            // insert the opp(s)
            Test.StartTest();
            insert newOpps;
            Test.StopTest();
            
            //now test that a contact has received the proper member stats from the trigger
            id FirstConId = TestCons[0].id;
            Contact UpdatedCon = [SELECT id, account.npo02__TotalOppAmount__c, npo02__OppAmountThisYear__c, npo02__OppAmountLastYear__c, npo02__household__c, npo02__household__r.npo02__TotalOppAmount__c, npo02__TotalOppAmount__c FROM Contact WHERE Id = :FirstConId];
    
            System.AssertEquals ( 100 , UpdatedCon.npo02__TotalOppAmount__c );
            System.AssertEquals ( 100 , UpdatedCon.npo02__household__r.npo02__TotalOppAmount__c );      
            System.AssertEquals ( 100 , UpdatedCon.npo02__OppAmountThisYear__c);
            System.AssertEquals ( 0 , UpdatedCon.npo02__OppAmountLastYear__c);
    
            // now roll up manually
            OpportunityRollups rg = new OpportunityRollups();
            rg.rollupContacts(new map<id, Contact>(new list<Contact>{TestCons[0]}));
         
            id hhid = UpdatedCon.npo02__household__r.id;
            npo02__household__c[] hhs = database.query('SELECT id, npo02__TotalOppAmount__c, npo02__LastCloseDate__c, '+
            'npo02__TotalMembershipOppAmount__c, npo02__OppAmountLastNDays__c, npo02__OppAmountThisYear__c, '+
            'npo02__OppAmountLastYear__c, npo02__OppAmount2YearsAgo__c, npo02__MembershipEndDate__c, npo02__MembershipJoinDate__c, npo02__LastMembershipLevel__c, '+
            'npo02__Best_Gift_Year__c, npo02__Best_Gift_Year_Total__c ' + 
            (OpportunityRollup_Utilities.isMultiCurrency() ? ', CurrencyIsoCode ' : '')+      
            'FROM npo02__household__c WHERE id = :hhid LIMIT 1');
            
            rg = new OpportunityRollups();
            rg.rollupHouseholds(new map<id, Household__c>(hhs));
    
            //make sure the values are still right
            UpdatedCon = [SELECT id, account.npo02__TotalOppAmount__c, npo02__OppAmountThisYear__c, npo02__OppAmountLastYear__c, npo02__household__c, npo02__household__r.npo02__TotalOppAmount__c, npo02__TotalOppAmount__c FROM Contact WHERE Id = :FirstConId];
    
            System.AssertEquals ( 100 , UpdatedCon.npo02__TotalOppAmount__c );
            System.AssertEquals ( 100 , UpdatedCon.npo02__household__r.npo02__TotalOppAmount__c );      
            System.AssertEquals ( 100 , UpdatedCon.npo02__OppAmountThisYear__c);
            System.AssertEquals ( 0 , UpdatedCon.npo02__OppAmountLastYear__c);
        
    }
    
 static testMethod void testMemberRollup () {

        String giftRecordTypeNameForTests = RecordTypes.getRecordTypeNameForGiftsTests('Opportunity');
        String membershipRecordTypeNameForTests = RecordTypes.getRecordTypeNameForMembershipTests('Opportunity');
        if(membershipRecordTypeNameForTests!=''){
            Households_Settings__c householdSettingsForTests = Households.getHouseholdsSettingsForTests(
                new Households_Settings__c (
                    Household_Rules__c = Households.ALL_PROCESSOR,
                    Always_Rollup_to_Primary_Contact__c = false,
                    Enable_Opp_Rollup_Triggers__c = true,
                    Excluded_Account_Opp_Rectypes__c = null,
                    Excluded_Account_Opp_Types__c = null,
                    Excluded_Contact_Opp_Rectypes__c = null,
                    Excluded_Contact_Opp_Types__c = null,
                    Membership_Record_Types__c = membershipRecordTypeNameForTests
                ));
                
            npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = npe01.Constants.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (
                npe01__Account_Processor__c = npe01.Constants.ONE_TO_ONE_PROCESSOR,
                npe01__Enable_Opportunity_Contact_Role_Trigger__c = true,
                npe01__Opportunity_Contact_Role_Default_role__c = 'Donor'
            ));
                    
            Date datClose = System.Today();
                
            // create & insert contact(s)
            Contact[] TestCons = new contact[]{ new contact(
                FirstName= npe01.Constants.CONTACT_FIRSTNAME_FOR_TESTS,
                LastName= npe01.Constants.CONTACT_LASTNAME_FOR_TESTS,
                npe01__Private__c=false,
                npe01__WorkEmail__c = npe01.Constants.CONTACT_EMAIL_FOR_TESTS, 
                npe01__Preferred_Email__c = npe01.Constants.CONTACT_PREFERRED_EMAIL_FOR_TESTS,
                npe01__WorkPhone__c = npe01.Constants.CONTACT_PHONE_FOR_TESTS,
                npe01__PreferredPhone__c = npe01.Constants.CONTACT_PREFERRED_PHONE_FOR_TESTS
            ) };
            insert TestCons;
    
            // create new opps
            Opportunity[] newOpps = UnitTestData.OppsForContactList (
                TestCons,
                null,
                UnitTestData.getClosedWonStage(),
                datClose,
                100,
                householdSettingsForTests.Membership_Record_Types__c,
                null
            );
            
            // insert the opp(s)
            Test.StartTest();
            newOpps[0].npe01__Membership_Origin__c = 'Renewal';
            insert newOpps;
            Test.StopTest();
            
            //now test that a contact has received the proper member stats from the trigger
            id FirstConId = TestCons[0].id;
            Contact UpdatedCon = [SELECT id, npo02__TotalMembershipOppAmount__c,npo02__LastMembershipOrigin__c,
                npo02__LastMembershipAmount__c, npo02__LastMembershipDate__c 
                from contact where id =: firstconid];
            System.AssertEquals (100 , updatedcon.npo02__TotalMembershipOppAmount__c );        
            System.AssertEquals (100 , updatedcon.npo02__LastMembershipAmount__c );        
            System.AssertEquals ('Renewal' , updatedcon.npo02__LastMembershipOrigin__c );      
            System.AssertEquals (system.today() , updatedcon.npo02__LastMembershipDate__c );   
        }   
    }
    
    static testMethod void testGivingRollupAcct () {
 
        String giftRecordTypeNameForTests = RecordTypes.getRecordTypeNameForGiftsTests('Opportunity');
        String membershipRecordTypeNameForTests = RecordTypes.getRecordTypeNameForMembershipTests('Opportunity');

            Households_Settings__c householdSettingsForTests = Households.getHouseholdsSettingsForTests(
                new Households_Settings__c (
                    Household_Rules__c = Households.ALL_PROCESSOR,
                    Always_Rollup_to_Primary_Contact__c = false,
                    Enable_Opp_Rollup_Triggers__c = true,
                    Excluded_Account_Opp_Rectypes__c = null,
                    Excluded_Account_Opp_Types__c = null,
                    Excluded_Contact_Opp_Rectypes__c = null,
                    Excluded_Contact_Opp_Types__c = null,
                    Membership_Record_Types__c = null
                ));
                
            npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = npe01.Constants.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (
                npe01__Account_Processor__c = npe01.Constants.ONE_TO_ONE_PROCESSOR,
                npe01__Enable_Opportunity_Contact_Role_Trigger__c = true,
                npe01__Opportunity_Contact_Role_Default_role__c = 'Donor'
            ));
            
            Date datClose = System.Today();
    
            // create account
            account testacct = new account(name='testacct');
            insert testacct;
            opportunity newOpp =
                 new opportunity (
                    name = 'testopp',
                    accountid = testacct.id, 
                    stagename=UnitTestData.getClosedWonStage(),
                    closedate=datClose, amount=33333
                 );
            if(OpportunityRollup_Utilities.areRecordTypesOnOpps()){
                newOpp.put('RecordTypeId',RecordTypes.GetRecordTypeId('Opportunity', giftRecordTypeNameForTests));
            }
            // insert the opp(s)
            Test.StartTest();
            insert newOpp;
            Test.StopTest();
            
            // test whether the trigger worked
            Account updatedAcct = [select id, TotalOppAmount__c, OppAmountThisYear__c,
                                    OppAmountLastYear__c, OppAmountLastNDays__c,
                                    OppAmount2YearsAgo__c, OppsClosedThisYear__c,
                                    LastCloseDate__c, NumberOfClosedOpps__c, 
                                    TotalMembershipOppAmount__c, OppsClosedLastYear__c,
                                    OppsClosedLastNDays__c, OppsClosed2YearsAgo__c,
                                    LastMembershipLevel__c, Best_Gift_Year__c, Best_Gift_Year_Total__c, 
                                    MembershipEndDate__c, MembershipJoinDate__c
                                    from Account where id =: testacct.id];
                                    
            System.AssertEquals ( 33333 , updatedAcct.npo02__TotalOppAmount__c );       
    
            // now roll up manually
            OpportunityRollups rg = new OpportunityRollups();
            rg.rollupAccounts(new map<id, Account>(new list<Account>{updatedAcct}));
    
            updatedAcct = [select id, npo02__TotalOppAmount__c from account where id =: testacct.id];
            System.AssertEquals ( 33333 , updatedAcct.npo02__TotalOppAmount__c );    
    }   

    static testMethod void testGivingRollupAcctMembership () {

        String giftRecordTypeNameForTests = RecordTypes.getRecordTypeNameForGiftsTests('Opportunity');
        String membershipRecordTypeNameForTests = RecordTypes.getRecordTypeNameForMembershipTests('Opportunity');
        if(membershipRecordTypeNameForTests!=''){
            Households_Settings__c householdSettingsForTests = Households.getHouseholdsSettingsForTests(
                new Households_Settings__c (
                    Household_Rules__c = Households.ALL_PROCESSOR,
                    Always_Rollup_to_Primary_Contact__c = false,
                    Enable_Opp_Rollup_Triggers__c = true,
                    Excluded_Account_Opp_Rectypes__c = null,
                    Excluded_Account_Opp_Types__c = null,
                    Excluded_Contact_Opp_Rectypes__c = null,
                    Excluded_Contact_Opp_Types__c = null,
                    Membership_Record_Types__c = membershipRecordTypeNameForTests
                ));
                
            npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = npe01.Constants.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (
                npe01__Account_Processor__c = npe01.Constants.ONE_TO_ONE_PROCESSOR,
                npe01__Enable_Opportunity_Contact_Role_Trigger__c = true,
                npe01__Opportunity_Contact_Role_Default_role__c = 'Donor'
            ));
            
            Date datClose = System.Today();
    
            // create account
            account testacct = new account(name='testacct');
            insert testacct;
            opportunity newOpp =
                 new opportunity (name = 'testopp', accountid = testacct.id, 
                                    npe01__member_level__c = 'Gold', npe01__membership_origin__c = 'New',
                                    stagename=UnitTestData.getClosedWonStage(), closedate=datClose, amount=33333);
            newOpp.put('RecordTypeId',RecordTypes.GetRecordTypeId('Opportunity', householdSettingsForTests.Membership_Record_Types__c));
            // insert the opp(s)
            Test.StartTest();
            insert newOpp;
            Test.StopTest();
            
            // test whether the trigger worked      
            account updatedAcct = [select id, TotalOppAmount__c, OppAmountThisYear__c,
                                    OppAmountLastYear__c, OppAmountLastNDays__c,
                                    OppAmount2YearsAgo__c, OppsClosedThisYear__c,
                                    LastCloseDate__c, NumberOfClosedOpps__c, 
                                    TotalMembershipOppAmount__c, OppsClosedLastYear__c,
                                    OppsClosedLastNDays__c, OppsClosed2YearsAgo__c,
                                    LastMembershipLevel__c, LastMembershipDate__c,
                                    LastMembershipAmount__c, LastMembershipOrigin__c,
                                    Best_Gift_Year__c, Best_Gift_Year_Total__c, MembershipEndDate__c,
                                    MembershipJoinDate__c
                                    from Account where id =: testacct.id];
                                
                      
            System.AssertEquals ( 33333 , updatedAcct.npo02__TotalMembershipOppAmount__c );     
            System.AssertEquals ( system.today() , updatedAcct.npo02__LastMembershipDate__c );      
            System.AssertEquals ( 33333 , updatedAcct.npo02__LastMembershipAmount__c );     
            System.AssertEquals ( 'Gold' , updatedAcct.npo02__LastMembershipLevel__c );     
            System.AssertEquals ( 'New' , updatedAcct.npo02__LastMembershipOrigin__c );
            
            // now roll up manually
            OpportunityRollups rg = new OpportunityRollups();
            rg.rollupAccounts(new map<id, Account>(new list<Account>{updatedAcct}));
    
            updatedAcct = [select id, npo02__TotalMembershipOppAmount__c from account where id =: testacct.id];
            System.AssertEquals ( 33333 , updatedAcct.npo02__TotalMembershipOppAmount__c );     
        }
    }   

    static testMethod void testGivingRollupBatch () {

        String giftRecordTypeNameForTests = RecordTypes.getRecordTypeNameForGiftsTests('Opportunity');

            Households_Settings__c householdSettingsForTests = Households.getHouseholdsSettingsForTests(
                new Households_Settings__c (
                    Household_Rules__c = Households.ALL_PROCESSOR,
                    Always_Rollup_to_Primary_Contact__c = false,
                    Enable_Opp_Rollup_Triggers__c = true,
                    Excluded_Account_Opp_Rectypes__c = null,
                    Excluded_Account_Opp_Types__c = null,
                    Excluded_Contact_Opp_Rectypes__c = null,
                    Excluded_Contact_Opp_Types__c = null,
                    Membership_Record_Types__c = null
                ));
                
            npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = npe01.Constants.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (
                npe01__Account_Processor__c = npe01.Constants.ONE_TO_ONE_PROCESSOR,
                npe01__Enable_Opportunity_Contact_Role_Trigger__c = true,
                npe01__Opportunity_Contact_Role_Default_role__c = 'Donor'
            ));
                
            Date datClose = System.Today();
                
            // create & insert contact(s)
            Contact[] TestCons = UnitTestData.CreateMultipleTestContacts ( 50 ) ;
            insert TestCons;
    
            // create new opps
            Opportunity[] newOpps = UnitTestData.OppsForContactList ( TestCons, null, UnitTestData.getClosedWonStage(), datClose, 1000 , giftRecordTypeNameForTests ,null);
    
            account testacct = new account(name='testacct');
            insert testacct;
    
            // test the batch rollup method
            Test.StartTest();
            OpportunityRollups rg = new OpportunityRollups();
            rg.rollupAll();
            Test.StopTest();
        
    }   

    static testMethod void OneContactMultipleOpps() {

        String giftRecordTypeNameForTests = RecordTypes.getRecordTypeNameForGiftsTests('Opportunity');
        String membershipRecordTypeNameForTests = RecordTypes.getRecordTypeNameForMembershipTests('Opportunity');
        if(membershipRecordTypeNameForTests!=''){
            Households_Settings__c householdSettingsForTests = Households.getHouseholdsSettingsForTests(
                new Households_Settings__c (
                    Household_Rules__c = Households.ALL_PROCESSOR,
                    Always_Rollup_to_Primary_Contact__c = false,
                    Enable_Opp_Rollup_Triggers__c = true,
                    Excluded_Account_Opp_Rectypes__c = null,
                    Excluded_Account_Opp_Types__c = null,
                    Excluded_Contact_Opp_Rectypes__c = null,
                    Excluded_Contact_Opp_Types__c = null,
                    Membership_Record_Types__c = membershipRecordTypeNameForTests
                ));
                
            npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = npe01.Constants.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (
                npe01__Account_Processor__c = npe01.Constants.ONE_TO_ONE_PROCESSOR,
                npe01__Enable_Opportunity_Contact_Role_Trigger__c = true,
                npe01__Opportunity_Contact_Role_Default_role__c = 'Donor'
            ));
                
            integer howMany = 1;
            Date datToday = System.Today();
            Date dat1YearAgo = Date.newInstance( datToday.year()-1,1,1);
            Date dat2YearAgo = Date.newInstance( datToday.year()-2,1,1);
            Date dat4YearAgo = Date.newInstance( datToday.year()-4,1,1);
                
            // create & insert contact(s)
            Contact[] TestCons = UnitTestData.CreateMultipleTestContacts ( howMany ) ;
            insert TestCons;
            
            test.starttest();
            // create a new gift for this yr
            Opportunity[] testGift1 = UnitTestData.OppsForContactList ( TestCons, null, UnitTestData.getClosedWonStage(), datToday, 100 , householdSettingsForTests.Membership_Record_Types__c,null);
            insert testGift1 ;
            //create a 2nd gift for last yr
            Opportunity[] testGift2 = UnitTestData.OppsForContactList ( TestCons, null, UnitTestData.getClosedWonStage(), dat1YearAgo, 60, householdSettingsForTests.Membership_Record_Types__c,null);
            insert testGift2;
            test.stopTest();
            
            //now test that the contact has received the proper stats from the trigger
            id ThisConId = TestCons[0].id;
            Contact UpdatedCon = [SELECT Id,  npo02__TotalOppAmount__c, npo02__OppAmountThisYear__c, npo02__OppAmountLastYear__c FROM Contact WHERE Id = :ThisConId];
            
            System.AssertEquals ( 160 , UpdatedCon.npo02__TotalOppAmount__c );
            System.AssertEquals ( 100 , UpdatedCon.npo02__OppAmountThisYear__c );
            System.AssertEquals ( 60 , UpdatedCon.npo02__OppAmountLastYear__c );
     
            // now chg the amts for both opps (cheapskate!)
            testGift1[0].Amount = 50;
            update TestGift1;
            
            testGift2[0].Amount=25;
            update TestGift2;
            
            // now roll up manually
            OpportunityRollups rg = new OpportunityRollups();
            rg.rollupContacts(new map<id, Contact>(new list<Contact>{UpdatedCon}));
    
            ThisConId = TestCons[0].id;
            UpdatedCon = [SELECT Id, npo02__TotalOppAmount__c, npo02__OppAmountThisYear__c, npo02__OppAmountLastYear__c  FROM Contact WHERE Id = :ThisConId];
            
            System.AssertEquals ( 75 , UpdatedCon.npo02__TotalOppAmount__c );
            System.AssertEquals ( 50 , UpdatedCon.npo02__OppAmountThisYear__c );        
            System.AssertEquals ( 25 , UpdatedCon.npo02__OppAmountLastYear__c );
            
            // now create a gift from 2 yrs ago
            Opportunity[] testGift3 = UnitTestData.OppsForContactList ( TestCons, null, UnitTestData.getClosedWonStage(), dat2YearAgo, 10 , giftRecordTypeNameForTests,null);
    
            insert testGift3;
            
            // now roll up manually
            rg = new OpportunityRollups();
            rg.rollupContacts(new map<id, Contact>(new list<Contact>{testcons[0]}));
    
            ThisConId = TestCons[0].id;
            UpdatedCon = [SELECT Id,  npo02__TotalOppAmount__c, npo02__OppAmountThisYear__c, npo02__OppAmountLastYear__c, npo02__OppAmount2YearsAgo__c FROM Contact WHERE Id = :ThisConId];
            
            System.AssertEquals ( 85 , UpdatedCon.npo02__TotalOppAmount__c );
            System.AssertEquals ( 50 , UpdatedCon.npo02__OppAmountThisYear__c );        
            System.AssertEquals ( 25 , UpdatedCon.npo02__OppAmountLastYear__c );
            System.AssertEquals ( 10 , UpdatedCon.npo02__OppAmount2YearsAgo__c );
    
            // add another from this year (to test adding)
            Opportunity[] testGift4 = UnitTestData.OppsForContactList ( TestCons, null, UnitTestData.getClosedWonStage(), datToday, 25 , giftRecordTypeNameForTests,null);
    
            insert testGift4;
            
            // now roll up manually
            rg = new OpportunityRollups();
            rg.rollupContacts(new map<id, Contact>(new list<Contact>{testcons[0]}));
    
            UpdatedCon = [SELECT Id,  npo02__TotalOppAmount__c, npo02__OppAmountThisYear__c, npo02__OppAmountLastYear__c, npo02__OppAmount2YearsAgo__c FROM Contact WHERE Id = :ThisConId];
            
            System.AssertEquals ( 110 , UpdatedCon.npo02__TotalOppAmount__c );
            System.AssertEquals ( 75 , UpdatedCon.npo02__OppAmountThisYear__c );        
            System.AssertEquals ( 25 , UpdatedCon.npo02__OppAmountLastYear__c );
            System.AssertEquals ( 10 , UpdatedCon.npo02__OppAmount2YearsAgo__c );
    
            // TBD add a gift from longer ago
            Opportunity[] testGift5 = UnitTestData.OppsForContactList ( TestCons, null, UnitTestData.getClosedWonStage(), dat4YearAgo, 200 , giftRecordTypeNameForTests,null);
    
            insert testGift5;
            
            // now roll up manually
            rg = new OpportunityRollups();
            rg.rollupContacts(new map<id, Contact>(new list<Contact>{testcons[0]}));
            
            // totals should not have changed, except lifetime & best yr
            UpdatedCon = [SELECT Id,  npo02__TotalOppAmount__c, npo02__OppAmountThisYear__c, npo02__OppAmountLastYear__c, npo02__OppAmount2YearsAgo__c FROM Contact WHERE Id = :ThisConId];
            
            System.AssertEquals ( 310 , UpdatedCon.npo02__TotalOppAmount__c );
            System.AssertEquals ( 75 , UpdatedCon.npo02__OppAmountThisYear__c );        
            System.AssertEquals ( 25 , UpdatedCon.npo02__OppAmountLastYear__c );
            System.AssertEquals ( 10 , UpdatedCon.npo02__OppAmount2YearsAgo__c );       
            
            // TBD add non-won gift
            Opportunity[] testGift6 = UnitTestData.OppsForContactList ( TestCons, null, UnitTestData.getOpenStage(), dat4YearAgo, 35 , giftRecordTypeNameForTests,null);
    
            insert testGift6;
            
            // now roll up manually
            rg = new OpportunityRollups();
            rg.rollupContacts(new map<id, Contact>(new list<Contact>{testcons[0]}));
            
            // totals should not have changed at all
            UpdatedCon = [SELECT Id,  npo02__TotalOppAmount__c, npo02__OppAmountThisYear__c, npo02__OppAmountLastYear__c, npo02__OppAmount2YearsAgo__c FROM Contact WHERE Id = :ThisConId];
            
            System.AssertEquals ( 310 , UpdatedCon.npo02__TotalOppAmount__c );
            System.AssertEquals ( 75 , UpdatedCon.npo02__OppAmountThisYear__c );        
            System.AssertEquals ( 25 , UpdatedCon.npo02__OppAmountLastYear__c );
            System.AssertEquals ( 10 , UpdatedCon.npo02__OppAmount2YearsAgo__c );       
                    
            // now delete the 1st gift (now at $50), totals should decrease
            delete testGift1;
            
            // now roll up manually
            rg = new OpportunityRollups();
            rg.rollupContacts(new map<id, Contact>(new list<Contact>{testcons[0]}));
            
            UpdatedCon = [SELECT Id,  npo02__TotalOppAmount__c, npo02__OppAmountThisYear__c, npo02__OppAmountLastYear__c, npo02__OppAmount2YearsAgo__c FROM Contact WHERE Id = :ThisConId];
            
            System.AssertEquals ( 260 , UpdatedCon.npo02__TotalOppAmount__c );
            System.AssertEquals ( 25 , UpdatedCon.npo02__OppAmountThisYear__c );        
            System.AssertEquals ( 25 , UpdatedCon.npo02__OppAmountLastYear__c );
            System.AssertEquals ( 10 , UpdatedCon.npo02__OppAmount2YearsAgo__c );
        }
    }

    static testMethod void OneContactOneInkind() {
 
        String giftRecordTypeNameForTests = RecordTypes.getRecordTypeNameForGiftsTests('Opportunity');

            Households_Settings__c householdSettingsForTests = Households.getHouseholdsSettingsForTests(
                new Households_Settings__c (
                    Household_Rules__c = Households.ALL_PROCESSOR,
                    Always_Rollup_to_Primary_Contact__c = false,
                    Enable_Opp_Rollup_Triggers__c = true,
                    Excluded_Account_Opp_Rectypes__c = null,
                    Excluded_Account_Opp_Types__c = 'In Kind',
                    Excluded_Contact_Opp_Rectypes__c = null,
                    Excluded_Contact_Opp_Types__c = 'In Kind',
                    Membership_Record_Types__c = null
                ));
                
            npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = npe01.Constants.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (
                npe01__Account_Processor__c = npe01.Constants.ONE_TO_ONE_PROCESSOR,
                npe01__Enable_Opportunity_Contact_Role_Trigger__c = true,
                npe01__Opportunity_Contact_Role_Default_role__c = 'Donor'
            ));
            
            integer howMany = 1;
            Date datToday = System.Today();
            
            // create & insert contact(s)
            Contact[] TestCons = UnitTestData.CreateMultipleTestContacts ( howMany ) ;
            insert TestCons;
            
            // create a new gift for this yr
            Opportunity[] testGift1 = UnitTestData.OppsForContactList ( TestCons, null, UnitTestData.getClosedWonStage(), datToday, 100 , giftRecordTypeNameForTests,'In Kind');
            Test.StartTest();
            insert testGift1 ;
            Test.StopTest();
            
            id ThisConId = TestCons[0].id;
            contact UpdatedCon = [SELECT Id,  npo02__TotalOppAmount__c, npo02__OppAmountThisYear__c, npo02__OppAmountLastYear__c, npo02__OppAmount2YearsAgo__c FROM Contact WHERE Id = :ThisConId];
        
            System.Assert(!(UpdatedCon.npo02__TotalOppAmount__c>0));
    }

    static testMethod void testGivingRollupBulk () {
    
        String giftRecordTypeNameForTests = RecordTypes.getRecordTypeNameForGiftsTests('Opportunity');
        
            Households_Settings__c householdSettingsForTests = Households.getHouseholdsSettingsForTests(
                new Households_Settings__c (
                    Household_Rules__c = Households.ALL_PROCESSOR,
                    Always_Rollup_to_Primary_Contact__c = false,
                    Enable_Opp_Rollup_Triggers__c = true,
                    Excluded_Account_Opp_Rectypes__c = null,
                    Excluded_Account_Opp_Types__c = null,
                    Excluded_Contact_Opp_Rectypes__c = null,
                    Excluded_Contact_Opp_Types__c = null,
                    Membership_Record_Types__c = null
                ));
                
            npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = npe01.Constants.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (
                npe01__Account_Processor__c = npe01.Constants.ONE_TO_ONE_PROCESSOR,
                npe01__Enable_Opportunity_Contact_Role_Trigger__c = true,
                npe01__Opportunity_Contact_Role_Default_role__c = 'Donor'
            ));
            
            // for a single contact w/ no previous mbrships, add a new membership
            // and test mbr stats are created
            integer howMany = 50;
            Date datClose = System.Today();
                
            // create & insert contact(s)
            Contact[] TestCons = UnitTestData.CreateMultipleTestContacts ( howMany ) ;
            insert TestCons;
            
            // create new opps
            Opportunity[] newOpps1 = UnitTestData.OppsForContactList ( TestCons, null, UnitTestData.getClosedWonStage(), datClose, 100 , giftRecordTypeNameForTests,null);
            Opportunity[] newOpps2 = UnitTestData.OppsForContactList ( TestCons, null, UnitTestData.getClosedWonStage(), datClose.addYears(-1), 50 , giftRecordTypeNameForTests,null);
    
            // insert the opp(s)
            Test.StartTest();
            insert newOpps1;
    
            insert newOpps2;
    
            Test.StopTest();
            
            id FirstConId = TestCons[10].id;
            Contact UpdatedCon = [SELECT Id,  npo02__TotalOppAmount__c, npo02__OppAmountThisYear__c, npo02__OppAmountLastYear__c, npo02__OppAmount2YearsAgo__c FROM Contact WHERE Id = :FirstConId];
            
            System.AssertEquals ( 150 , UpdatedCon.npo02__TotalOppAmount__c );
            System.AssertEquals ( 100 , UpdatedCon.npo02__OppAmountThisYear__c );       
            System.AssertEquals ( 50 , UpdatedCon.npo02__OppAmountLastYear__c );
            System.AssertEquals ( 0 , UpdatedCon.npo02__OppAmount2YearsAgo__c );
        
    }

    static testMethod void testGivingRollupTooManyOpps () {
  
        String giftRecordTypeNameForTests = RecordTypes.getRecordTypeNameForGiftsTests('Opportunity');

            Households_Settings__c householdSettingsForTests = Households.getHouseholdsSettingsForTests(
                new Households_Settings__c (
                    Household_Rules__c = Households.ALL_PROCESSOR,
                    Always_Rollup_to_Primary_Contact__c = false,
                    Enable_Opp_Rollup_Triggers__c = true,
                    Excluded_Account_Opp_Rectypes__c = null,
                    Excluded_Account_Opp_Types__c = null,
                    Excluded_Contact_Opp_Rectypes__c = null,
                    Excluded_Contact_Opp_Types__c = null,
                    Membership_Record_Types__c = null
                ));
                
            npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = npe01.Constants.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (
                npe01__Account_Processor__c = npe01.Constants.ONE_TO_ONE_PROCESSOR,
                npe01__Enable_Opportunity_Contact_Role_Trigger__c = true,
                npe01__Opportunity_Contact_Role_Default_role__c = 'Donor'
            ));
            
            // for a single contact w/ no previous mbrships, add a new membership
            // and test mbr stats are created
        
            // create & insert contact(s)
            Contact[] TestCons = UnitTestData.CreateMultipleTestContacts ( 1 ) ;
            insert TestCons;
            
            // create new opps
            Opportunity[] newOpps1 = new Opportunity[0];
            for (integer n = 0; n < 450; n++) {
                Opportunity newOpp1 = new opportunity(npe01__Contact_Id_for_Role__c = TestCons[0].id,
                    name = 'test opp ' + n, 
                    stagename = UnitTestData.getClosedWonStage(), closedate = system.today().adddays(-n), amount = 100);
                if(OpportunityRollup_Utilities.areRecordTypesOnOpps()){
                    newOpp1.put('RecordTypeId',RecordTypes.GetRecordTypeId('Opportunity', giftRecordTypeNameForTests));
                }
                newOpps1.add( newOpp1);
            }
            
            // insert the opp(s)
            Test.StartTest();
            insert newOpps1;
            Test.StopTest();
            
            id FirstConId = TestCons[0].id;
            Contact UpdatedCon = [SELECT Id,  npo02__TotalOppAmount__c, npo02__OppAmountThisYear__c, npo02__OppAmountLastYear__c, npo02__OppAmount2YearsAgo__c FROM Contact WHERE Id = :FirstConId];
            
            System.AssertEquals ( 45000 , UpdatedCon.npo02__TotalOppAmount__c );        
    } 
    
    static testMethod void testHouseholdStats () {
   
        String giftRecordTypeNameForTests = RecordTypes.getRecordTypeNameForGiftsTests('Opportunity');

            Households_Settings__c householdSettingsForTests = Households.getHouseholdsSettingsForTests(
                new Households_Settings__c (
                    Household_Rules__c = Households.ALL_PROCESSOR,
                    Always_Rollup_to_Primary_Contact__c = false,
                    Enable_Opp_Rollup_Triggers__c = true,
                    Excluded_Account_Opp_Rectypes__c = null,
                    Excluded_Account_Opp_Types__c = null,
                    Excluded_Contact_Opp_Rectypes__c = null,
                    Excluded_Contact_Opp_Types__c = null,
                    Membership_Record_Types__c = null
                ));
                
            npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = npe01.Constants.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (
                npe01__Account_Processor__c = npe01.Constants.ONE_TO_ONE_PROCESSOR,
                npe01__Enable_Opportunity_Contact_Role_Trigger__c = true,
                npe01__Opportunity_Contact_Role_Default_role__c = 'Donor'
            ));
            
            Date datClose = System.Today();
                
            // create & insert contact
            Contact Con1 = new contact(
                FirstName= npe01.Constants.CONTACT_FIRSTNAME_FOR_TESTS,
                LastName= npe01.Constants.CONTACT_LASTNAME_FOR_TESTS,
                npe01__Private__c=false,
                npe01__WorkEmail__c = npe01.Constants.CONTACT_EMAIL_FOR_TESTS, 
                npe01__Preferred_Email__c = npe01.Constants.CONTACT_PREFERRED_EMAIL_FOR_TESTS,
                npe01__WorkPhone__c = npe01.Constants.CONTACT_PHONE_FOR_TESTS,
                npe01__PreferredPhone__c = npe01.Constants.CONTACT_PREFERRED_PHONE_FOR_TESTS
            );
            insert Con1;
            
            Contact con = [SELECT npo02__household__r.id FROM Contact WHERE id = :Con1.id LIMIT 1];
            
            // create & insert second household member
            Contact Con2 = new contact(
                FirstName= npe01.Constants.CONTACT_FIRSTNAME_FOR_TESTS+'second',
                LastName= npe01.Constants.CONTACT_LASTNAME_FOR_TESTS,
                npe01__Private__c=false,
                npe01__WorkEmail__c = npe01.Constants.CONTACT_EMAIL_FOR_TESTS, 
                npe01__Preferred_Email__c = npe01.Constants.CONTACT_PREFERRED_EMAIL_FOR_TESTS,
                npe01__WorkPhone__c = npe01.Constants.CONTACT_PHONE_FOR_TESTS,
                npe01__PreferredPhone__c = npe01.Constants.CONTACT_PREFERRED_PHONE_FOR_TESTS,
                npo02__household__c = con.npo02__household__c
            );
            insert Con2;
            
            Contact[] TestCons = new Contact[] {Con1}; 
        
            // create new opps
            Opportunity[] newOpps1 = UnitTestData.OppsForContactList ( TestCons, null, UnitTestData.getClosedWonStage(), datClose, 100 , giftRecordTypeNameForTests ,null);
            Opportunity[] newOpps2 = UnitTestData.OppsForContactList ( TestCons, null, UnitTestData.getClosedWonStage(), datClose.addYears(-2), 200 , giftRecordTypeNameForTests ,null);
            Opportunity[] newOpps3 = UnitTestData.OppsForContactList ( TestCons, null, UnitTestData.getClosedWonStage(), datClose.addYears(-3), 75 , giftRecordTypeNameForTests ,null);
    
            Opportunity[] testOpps = new Opportunity[0];
            testOpps.addAll (newOpps1);
            testOpps.addAll (newOpps2);
            testOpps.addAll (newOpps3);
    
            // insert the opp(s)
            Test.StartTest();
            insert testOpps;
            Test.StopTest();
            
            Contact c = [SELECT Id,Total_Household_Gifts__c,OppAmountThisYearHH__c,OppAmountLastYearHH__c,
                            LastCloseDateHH__c, Best_Gift_Year__c, Best_Gift_Year_Total__c, Household__r.Best_Gift_Year__c, Household__r.Best_Gift_Year_Total__c
                FROM Contact WHERE LastName=:npe01.Constants.CONTACT_LASTNAME_FOR_TESTS AND FirstName=:npe01.Constants.CONTACT_FIRSTNAME_FOR_TESTS+'second' LIMIT 1];
            System.assertEquals (375,c.Total_Household_Gifts__c);
            System.assertEquals (100,c.OppAmountThisYearHH__c);
            System.assertEquals (0,c.OppAmountLastYearHH__c);
            System.assertEquals (datClose,c.LastCloseDateHH__c );
            System.assertEquals (375,c.Total_Household_Gifts__c);       
            System.assertEquals (null, c.Best_Gift_Year_Total__c); 
            System.assertEquals (null, c.Best_Gift_Year__c);
            System.assertEquals (string.valueof(datClose.addYears(-2).year()), c.Household__r.Best_Gift_Year__c);
            System.assertEquals (200, c.Household__r.Best_Gift_Year_Total__c);                    
    }    
        
    static testMethod void testUserDefinedRollup() {

        Households_Settings__c householdSettingsForTests = Households.getHouseholdsSettingsForTests(
                new Households_Settings__c (
                    Household_Rules__c = Households.ALL_PROCESSOR,
                    Always_Rollup_to_Primary_Contact__c = false,
                    Enable_Opp_Rollup_Triggers__c = true,
                    Excluded_Account_Opp_Rectypes__c = null,
                    Excluded_Account_Opp_Types__c = null,
                    Excluded_Contact_Opp_Rectypes__c = null,
                    Excluded_Contact_Opp_Types__c = null,
                    Membership_Record_Types__c = null
         ));
        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = npe01.Constants.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (
                npe01__Account_Processor__c = npe01.Constants.ONE_TO_ONE_PROCESSOR,
                npe01__Enable_Opportunity_Contact_Role_Trigger__c = true,
                npe01__Opportunity_Contact_Role_Default_role__c = 'Donor'
        ));
    
        //need to clear out any existing user fields
        //otherwise we can't insert of stuff referenced by apex
        delete [select id from User_Rollup_Field_Settings__c];
        
        list<User_Rollup_Field_Settings__c> testURFS = new list<User_Rollup_Field_Settings__c>();
                
        User_Rollup_Field_Settings__c testUserRollup1 = new User_Rollup_Field_Settings__c();
        testUserRollup1.npo02__Target_Field__c = 'Birthdate'; 
        testUserRollup1.npo02__Source_Field__c = 'CloseDate';
        testUserRollup1.npo02__Object_Name__c = 'Contact'; 
        testUserRollup1.npo02__Field_Action__c = 'MAX';
        testUserRollup1.Name = 'TestRollup8675309';
        testURFS.add(TestUserRollup1);
        
        User_Rollup_Field_Settings__c TestUserRollup2 = new User_Rollup_Field_Settings__c();
        testUserRollup2.npo02__Target_Field__c = 'NumberOfEmployees'; 
        testUserRollup2.npo02__Source_Field__c = 'FiscalYear';
        testUserRollup2.npo02__Object_Name__c = 'Account'; 
        testUserRollup2.npo02__Field_Action__c = 'MAX';
        testUserRollup2.Name = 'TestRollup2';
        testURFS.add(TestUserRollup2);
        
        User_Rollup_Field_Settings__c testUserRollup3 = new User_Rollup_Field_Settings__c();
        testUserRollup3.npo02__Target_Field__c = 'npo02__LastCloseDate__c'; 
        testUserRollup3.npo02__Source_Field__c = 'CloseDate';
        testUserRollup3.npo02__Object_Name__c = 'npo02__Household__c'; 
        testUserRollup3.npo02__Field_Action__c = 'MAX';
        testUserRollup3.Name = 'TestRollup3';
        testURFS.add(TestUserRollup3);
        
        insert testURFS; 
        
        Contact c = new Contact(LastName = 'Lastname', BirthDate = system.today().addDays(-4));
        insert c;
        
        id rtid = RecordTypes.GetRecordTypeId ('Opportunity',RecordTypes.getRecordTypeNameForGiftsTests('Opportunity'));
        Opportunity newOpp = New Opportunity (
                Name = 'Test Opp ',
                Amount = 100,
                CloseDate = system.today().adddays(-2),
                StageName = UnitTestData.getClosedWonStage(),
                npe01__Contact_Id_for_Role__c = c.Id                                
            );  
            if(rtid != null){
                newOpp.put('RecordTypeId',rtid);
            }
            
        map<string, User_Rollup_Field_Settings__c> urfsMap = User_Rollup_Field_Settings__c.getAll();
        system.assertEquals(3, urfsMap.keySet().size());                    
         
        Test.StartTest();
        insert newOpp;
        Test.StopTest();     
    
        Contact ct = [select Birthdate, OppAmountThisYearHH__c from Contact where id = :c.id];
        system.assertEquals (100,ct.OppAmountThisYearHH__c);    
        system.assertEquals(system.today().addDays(-2), ct.BirthDate);        
    }
    
    static testMethod void testMultiCurrencyMethods(){
        //exercise internal multicurrency helper methods, check currency conversion             
        decimal d = OpportunityRollup_Utilities.ConvertFromCorporate('USD', 55.00);      
        d = OpportunityRollup_Utilities.ConvertCurrency('USD', 'USD', 55.00);

        //create & insert second household member
        Contact Con = new contact(
                FirstName= npe01.Constants.CONTACT_FIRSTNAME_FOR_TESTS,
                LastName= npe01.Constants.CONTACT_LASTNAME_FOR_TESTS,
                npe01__Private__c=false,
                npe01__WorkEmail__c = npe01.Constants.CONTACT_EMAIL_FOR_TESTS, 
                npe01__Preferred_Email__c = npe01.Constants.CONTACT_PREFERRED_EMAIL_FOR_TESTS,
                npe01__WorkPhone__c = npe01.Constants.CONTACT_PHONE_FOR_TESTS,
                npe01__PreferredPhone__c = npe01.Constants.CONTACT_PREFERRED_PHONE_FOR_TESTS                
            );
            insert Con;
            
        Contact[] TestCons = new Contact[] {Con}; 
        
        // create new opps
        Opportunity o = new Opportunity(
            Name = 'MyContactOpportunity',
            StageName = 'Closed Won',
            CloseDate = system.today(),
            npe01__Contact_Id_for_Role__c = con.Id  
        );        
        insert o;
        
        list<sobject> sobjectlist = new list<sobject>();
        
        OpportunityRollups opproll = new OpportunityRollups();
        map<Id, Opportunity> omap = OpportunityRollup_Utilities.rcfFindCurrency(sobjectList);
    }
    
    static testMethod void testRollupAlls(){
        OpportunityRollups og = new OpportunityRollups();
        
        test.startTest();
        og.rollupAllContacts();
        og.rollupAllAccounts();     
        boolean x = OpportunityRollup_Utilities.isMultiCurrency();
        decimal y = OpportunityRollup_Utilities.ConvertFromCorporate('USD', 500.00);
        decimal z = OpportunityRollup_Utilities.ConvertCurrency('USD', 'USD', 6565.54);
        test.stopTest();
    }
    static testMethod void testFiscalYearandCustomNDay () {

        String giftRecordTypeNameForTests = RecordTypes.getRecordTypeNameForGiftsTests('Opportunity');

            Households_Settings__c householdSettingsForTests = Households.getHouseholdsSettingsForTests(
                new Households_Settings__c (
                    Household_Rules__c = Households.ALL_PROCESSOR,
                    Always_Rollup_to_Primary_Contact__c = false,
                    Enable_Opp_Rollup_Triggers__c = true,
                    Excluded_Account_Opp_Rectypes__c = null,
                    Excluded_Account_Opp_Types__c = null,
                    Excluded_Contact_Opp_Rectypes__c = null,
                    Excluded_Contact_Opp_Types__c = null,
                    Membership_Record_Types__c = null,                      
                    Use_Fiscal_Year_for_Rollups__c = true, 
                    Rollup_N_Day_Value__c = 10,
                    Batch_Size__c = 200
                ));
                
            npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = npe01.Constants.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (
                npe01__Account_Processor__c = npe01.Constants.ONE_TO_ONE_PROCESSOR,
                npe01__Enable_Opportunity_Contact_Role_Trigger__c = true,
                npe01__Opportunity_Contact_Role_Default_role__c = 'Donor'
            ));
            
            // for a single contact w/ no previous mbrships, add a new membership
            // and test mbr stats are created
        
            // create & insert contact(s)
            Contact[] TestCons = UnitTestData.CreateMultipleTestContacts ( 1 ) ;
            insert TestCons;
            
            // create 2 new opps
            Opportunity[] newOpps1 = new Opportunity[0];
            
            Opportunity newOpp1 = new opportunity(npe01__Contact_Id_for_Role__c = TestCons[0].id,
                    name = 'test opp ', 
                    stagename = UnitTestData.getClosedWonStage(), closedate = system.today(), amount = 100);
               if(OpportunityRollup_Utilities.areRecordTypesOnOpps())
                    newOpp1.put('RecordTypeId',RecordTypes.GetRecordTypeId('Opportunity', giftRecordTypeNameForTests));
            newOpps1.add( newOpp1);
            
            Opportunity newOpp2 = new opportunity(npe01__Contact_Id_for_Role__c = TestCons[0].id,
                    name = 'test opp 2', 
                    stagename = UnitTestData.getClosedWonStage(), closedate = system.today().adddays(-40), amount = 100);
               if(OpportunityRollup_Utilities.areRecordTypesOnOpps())
                    newOpp2.put('RecordTypeId',RecordTypes.GetRecordTypeId('Opportunity', giftRecordTypeNameForTests));
            newOpps1.add(newOpp2);
           
            // insert the opp(s)
            Test.StartTest();
            insert newOpps1;
            Test.StopTest();
    
            system.assertEquals(100, [select OppAmountLastNDays__c from Contact where id = :TestCons[0].id].OppAmountLastNDays__c);
    }
    
   static testMethod void testSoftCredits() {

        String giftRecordTypeNameForTests = RecordTypes.getRecordTypeNameForGiftsTests('Opportunity');

            Households_Settings__c householdSettingsForTests = Households.getHouseholdsSettingsForTests(
                new Households_Settings__c (
                    Household_Rules__c = Households.NO_HOUSEHOLDS_PROCESSOR,
                    Always_Rollup_to_Primary_Contact__c = false,
                    Enable_Opp_Rollup_Triggers__c = false,
                    Excluded_Account_Opp_Rectypes__c = null,
                    Excluded_Account_Opp_Types__c = null,
                    Excluded_Contact_Opp_Rectypes__c = null,
                    Excluded_Contact_Opp_Types__c = null,
                    Membership_Record_Types__c = null,
                    Enable_Soft_Credit_Rollups__c = true,
                    Soft_Credit_Roles__c = 'TestOCR',     
                    Advanced_Household_Naming__c = false               
                ));
                
            npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = npe01.Constants.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (
                npe01__Account_Processor__c = npe01.Constants.ONE_TO_ONE_PROCESSOR,
                npe01__Enable_Opportunity_Contact_Role_Trigger__c = true,
                npe01__Opportunity_Contact_Role_Default_role__c = 'Donor'
            ));
                
            Date datClose = System.Today();
                
            // create & insert contact(s)
            Contact[] TestCons = UnitTestData.CreateMultipleTestContacts(10) ;
            insert TestCons;
    
            // create new opps
            Opportunity[] newOpps = UnitTestData.OppsForContactList ( TestCons, null, UnitTestData.getClosedWonStage(), datClose, 1000 , giftRecordTypeNameForTests ,null);
            insert newOpps;
            
            account testacct = new account(name='testacct');
            insert testacct;
            
            Opportunity[] lastYearOpps = UnitTestData.OppsForContactList(new list<Contact>{TestCons[5]}, null, UnitTestData.getClosedWonStage(), datClose.addyears(-1), 150 , giftRecordTypeNameForTests ,null);
            insert lastYearOpps;
            
            Opportunity[] last2YearOpps = UnitTestData.OppsForContactList(new list<Contact>{TestCons[8]}, null, UnitTestData.getClosedWonStage(), datClose.addyears(-2), 100 , giftRecordTypeNameForTests ,null);
            insert last2YearOpps;
            
            //grab two random contacts and two random Opps and create an OCR for them
            id TCid1 = TestCons[5].id;
            id TCid2 = TestCons[8].id;            
            
            list<OpportunityContactRole> ocrlist = new list<OpportunityContactRole>();
            
            ocrlist.add(new OpportunityContactRole(ContactId = TCid1, OpportunityId = newOpps[1].id, Role = 'TestOCR'));
            ocrlist.add(new OpportunityContactRole(ContactId = TCid2, OpportunityId = newOpps[2].id, Role = 'TestOCR'));
            ocrlist.add(new OpportunityContactRole(ContactId = TCid1, OpportunityId = lastYearOpps[0].id, Role = 'TestOCR'));
            ocrlist.add(new OpportunityContactRole(ContactId = TCid2, OpportunityId = last2YearOpps[0].id, Role = 'TestOCR'));
            insert ocrlist;
            
            
            // test the batch rollup method
            Test.StartTest();
            OpportunityRollups rg = new OpportunityRollups();
            rg.rollupAll();
            Test.StopTest();    
            
            Contact c1 = [select Soft_Credit_Two_Years_Ago__c, Soft_Credit_Total__c, 
                                Soft_Credit_This_Year__c, Soft_Credit_Last_Year__c From Contact where id = :TCid1];
            
            Contact c2 = [select Soft_Credit_Two_Years_Ago__c, Soft_Credit_Total__c, 
                                Soft_Credit_This_Year__c, Soft_Credit_Last_Year__c From Contact where id = :TCid2];                
    
            system.assertEquals(1150, c1.Soft_Credit_Total__c);
            system.assertEquals(1000, c1.Soft_Credit_This_Year__c);
            system.assertEquals(150, c1.Soft_Credit_Last_Year__c);
            system.assertEquals(1100, c2.Soft_Credit_Total__c);
            system.assertEquals(100, c2.Soft_Credit_Two_Years_Ago__c);
    }  
    
    static testMethod void testFutureMethods(){
         String giftRecordTypeNameForTests = RecordTypes.getRecordTypeNameForGiftsTests('Opportunity');

            Households_Settings__c householdSettingsForTests = Households.getHouseholdsSettingsForTests(
                new Households_Settings__c (
                    Household_Rules__c = Households.ALL_PROCESSOR,
                    Always_Rollup_to_Primary_Contact__c = false,
                    Enable_Opp_Rollup_Triggers__c = false,
                    Excluded_Account_Opp_Rectypes__c = null,
                    Excluded_Account_Opp_Types__c = null,
                    Excluded_Contact_Opp_Rectypes__c = null,
                    Excluded_Contact_Opp_Types__c = null,
                    Membership_Record_Types__c = null,
                    Enable_Soft_Credit_Rollups__c = true,
                    Soft_Credit_Roles__c = 'TestOCR',     
                    Advanced_Household_Naming__c = false               
                ));
                
            npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = npe01.Constants.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (
                npe01__Account_Processor__c = npe01.Constants.ONE_TO_ONE_PROCESSOR,
                npe01__Enable_Opportunity_Contact_Role_Trigger__c = true,
                npe01__Opportunity_Contact_Role_Default_role__c = 'Donor'
            ));
                
            Date datClose = System.Today();
                
            // create & insert contact(s)
        Contact[] TestCons = UnitTestData.CreateMultipleTestContacts(10) ;
        insert TestCons;
    
        // create new opps
        Opportunity[] newOpps = UnitTestData.OppsForContactList ( TestCons, null, UnitTestData.getClosedWonStage(), datClose, 1000 , giftRecordTypeNameForTests ,null);
        insert newOpps;
            
        TestCons = [select id, Household__c from Contact where ID IN :TestCons];
        set<id> HHid = new set<id>();
        set<id> CID = new set<id>();
        
        for (Contact c : TestCons){
            HHid.add(c.Household__c);
            CID.add(c.id);
        }          
        
        Test.startTest();
        OpportunityRollups.rollupContactsFuture(CID);
        OpportunityRollups.rollupHouseholdsFuture(HHid);        
        Test.stopTest();
    }    
    
    static testMethod void testOpportunityUtilityErrorHandling(){
        String giftRecordTypeNameForTests = RecordTypes.getRecordTypeNameForGiftsTests('Opportunity');

        Households_Settings__c householdSettingsForTests = Households.getHouseholdsSettingsForTests(
            new Households_Settings__c (
            Household_Rules__c = Households.ALL_PROCESSOR,
            Always_Rollup_to_Primary_Contact__c = false,
            Enable_Opp_Rollup_Triggers__c = false,
            Excluded_Account_Opp_Rectypes__c = null,
            Excluded_Account_Opp_Types__c = null,
            Excluded_Contact_Opp_Rectypes__c = null,
            Excluded_Contact_Opp_Types__c = null,
            Membership_Record_Types__c = null,
            Enable_Soft_Credit_Rollups__c = true,
            Soft_Credit_Roles__c = 'TestOCR',     
            Advanced_Household_Naming__c = false               
        ));
                
        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = npe01.Constants.getContactsSettingsForTests(
            new npe01__Contacts_and_Orgs_Settings__c (
            npe01__Account_Processor__c = npe01.Constants.ONE_TO_ONE_PROCESSOR,
            npe01__Enable_Opportunity_Contact_Role_Trigger__c = true,
            npe01__Opportunity_Contact_Role_Default_role__c = 'Donor'
        ));
                
        // create & insert contact(s)
        Contact[] TestCons = UnitTestData.CreateMultipleTestContacts(10) ;
        insert TestCons;
    
        //create new opp with a missing required field
        Opportunity[] newOpps = UnitTestData.OppsForContactList ( TestCons, null, UnitTestData.getClosedWonStage(), null, 1000 , giftRecordTypeNameForTests ,null);
                
        Database.Saveresult[] sr = Database.insert(newOpps, false);
        system.assert(sr != null);
        system.assert(TestCons[0].id != null);
        Opportunity_Rollup_Error__c ore = OpportunityRollup_Utilities.createError(sr[0], 'Opportunity', TestCons[0].id);
        system.assert(ore != null);
        system.assertEquals('Required Field Missing',ore.Error_Type__c);
        system.assert(ore.Name.startsWith(TestCons[0].id));
        system.assertEquals('Opportunity',ore.Error_Object_Type__c);
    }
    
    static testMethod void testFYUtility(){     
        integer fy = OpportunityRollup_Utilities.getCurrentFY();
        system.assert(fy != null);      
    }
    
    //a change to a UDR value should trigger a rollup
    static testMethod void testUDRChangeBehavior(){
        Households_Settings__c householdSettingsForTests = Households.getHouseholdsSettingsForTests(
                new Households_Settings__c (
                    Household_Rules__c = Households.ALL_PROCESSOR,
                    Always_Rollup_to_Primary_Contact__c = false,
                    Enable_Opp_Rollup_Triggers__c = true,
                    Excluded_Account_Opp_Rectypes__c = null,
                    Excluded_Account_Opp_Types__c = null,
                    Excluded_Contact_Opp_Rectypes__c = null,
                    Excluded_Contact_Opp_Types__c = null,
                    Membership_Record_Types__c = null
         ));
        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = npe01.Constants.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (
                npe01__Account_Processor__c = npe01.Constants.ONE_TO_ONE_PROCESSOR,
                npe01__Enable_Opportunity_Contact_Role_Trigger__c = true,
                npe01__Opportunity_Contact_Role_Default_role__c = 'Donor'
        ));
    
        //need to clear out any existing user fields
        //otherwise we can't insert of stuff referenced by apex
        delete [select id from User_Rollup_Field_Settings__c];
        
        list<User_Rollup_Field_Settings__c> testURFS = new list<User_Rollup_Field_Settings__c>();
                
        User_Rollup_Field_Settings__c testUserRollup1 = new User_Rollup_Field_Settings__c();
        testUserRollup1.npo02__Target_Field__c = 'npo02__Household_ID__c'; 
        testUserRollup1.npo02__Source_Field__c = 'TotalOpportunityQuantity';
        testUserRollup1.npo02__Object_Name__c = 'npo02__Household__c'; 
        testUserRollup1.npo02__Field_Action__c = 'MAX';
        testUserRollup1.Name = 'TestRollup8675309';
        testURFS.add(TestUserRollup1);
        
        insert testURFS; 
        
        Contact c = new Contact(LastName = 'TestCon');
        insert c;        
        
        //get all of the fields
        String q = OpportunityRollup_Utilities.buildContactQuery() + ' where id = \'' + c.id + '\'';
        
        c = database.query(q);
        
        id rtid = RecordTypes.GetRecordTypeId ('Opportunity',RecordTypes.getRecordTypeNameForGiftsTests('Opportunity'));
        Opportunity newOpp = New Opportunity (
                Name = 'Test Opp ',
                Amount = 100,
                CloseDate = system.today(),
                StageName = UnitTestData.getClosedWonStage(),
                npe01__Contact_Id_for_Role__c = c.id,                      
                TotalOpportunityQuantity = 2                              
            );  
            if(rtid != null){
                newOpp.put('RecordTypeId',rtid);
            }
            
        map<string, User_Rollup_Field_Settings__c> urfsMap = User_Rollup_Field_Settings__c.getAll();
        system.assertEquals(1, urfsMap.keySet().size());        
                
        insert newOpp;
        OpportunityRollups og = new OpportunityRollups();
        Map<Id,Contact> cmap = new Map<Id,Contact>();
        Map<Id, npo02__Household__c> hmap = new Map<Id, npo02__Household__c>();
        q = OpportunityRollup_Utilities.buildHouseholdQuery() + ' where id = \'' + c.npo02__Household__c + '\'';
        
        npo02__Household__c h =database.query(q); 
        cmap.put(c.id, c);
        hmap.put(h.id, h);
        og.rollupContacts(cmap);
        og.rollupHouseholds(hmap);        
        
        Contact ct = [select TotalOppAmount__c, npo02__Household__r.npo02__Household_ID__c from Contact where id = :c.id];
        system.assertEquals (100,ct.TotalOppAmount__c);    
        system.assertEquals(2, ct.npo02__Household__r.npo02__Household_ID__c);        
        
        newOpp.TotalOpportunityQuantity = 4;                             
        
        //issue an update
        Test.startTest();
        update newOpp;
        Test.stopTest();     
        
        ct = [select TotalOppAmount__c, npo02__Household__r.npo02__Household_ID__c from Contact where id = :c.id];
        system.assertEquals (100,ct.TotalOppAmount__c);    
        system.assertEquals(4, ct.npo02__Household__r.npo02__Household_ID__c);      
    }

    public static testMethod void testBatch() {
        String giftRecordTypeNameForTests = RecordTypes.getRecordTypeNameForGiftsTests('Opportunity');
        if(giftRecordTypeNameForTests!=''){
            Households_Settings__c householdSettingsForTests = Households.getHouseholdsSettingsForTests(
                new Households_Settings__c (
                    Household_Rules__c = Households.ALL_PROCESSOR,
                    Always_Rollup_to_Primary_Contact__c = true,
                    Enable_Opp_Rollup_Triggers__c = true,
                    Excluded_Account_Opp_Rectypes__c = null,
                    Excluded_Account_Opp_Types__c = null,
                    Excluded_Contact_Opp_Rectypes__c = null,
                    Excluded_Contact_Opp_Types__c = null,
                    Membership_Record_Types__c = null
                ));
            
            npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = npe01.Constants.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (
                npe01__Account_Processor__c = npe01.Constants.ONE_TO_ONE_PROCESSOR,
                npe01__Enable_Opportunity_Contact_Role_Trigger__c = true,
                npe01__Opportunity_Contact_Role_Default_role__c = 'Donor'
            ));
            
            Date datClose = System.Today();
                
            // create & insert contact(s)
            Contact[] TestCons = new contact[]{ new contact(
                FirstName= npe01.Constants.CONTACT_FIRSTNAME_FOR_TESTS,
                LastName= npe01.Constants.CONTACT_LASTNAME_FOR_TESTS,
                npe01__Private__c=false,
                npe01__WorkEmail__c = npe01.Constants.CONTACT_EMAIL_FOR_TESTS, 
                npe01__Preferred_Email__c = npe01.Constants.CONTACT_PREFERRED_EMAIL_FOR_TESTS,
                npe01__WorkPhone__c = npe01.Constants.CONTACT_PHONE_FOR_TESTS,
                npe01__PreferredPhone__c = npe01.Constants.CONTACT_PREFERRED_PHONE_FOR_TESTS
            ) };
            insert TestCons;
            
            Contact insertedContact = [select accountid from Contact where id IN :TestCons];

            // create new opps
            Opportunity[] newOpps = UnitTestData.OppsForContactList ( TestCons, null, UnitTestData.getClosedWonStage(), datClose, 100 , giftRecordTypeNameForTests ,null);
            String contactAccountId = insertedContact.accountid;
        
            RLLP_OppRollup_BATCH batch = new RLLP_OppRollup_BATCH(
                'SELECT id FROM account where Id =\'' + contactAccountId + '\' limit 200'
            );
            
            Test.StartTest(); 
            id batchProcessId = database.executeBatch(batch);
            Test.StopTest(); 
        }
    }

    public static testMethod void testRollupCtrl() {
        String giftRecordTypeNameForTests = RecordTypes.getRecordTypeNameForGiftsTests('Opportunity');
        Households_Settings__c householdSettingsForTests = Households.getHouseholdsSettingsForTests(
            new Households_Settings__c (
                Household_Rules__c = Households.ALL_PROCESSOR,
                Always_Rollup_to_Primary_Contact__c = true,
                Enable_Opp_Rollup_Triggers__c = true,
                Excluded_Account_Opp_Rectypes__c = null,
                Excluded_Account_Opp_Types__c = null,
                Excluded_Contact_Opp_Rectypes__c = null,
                Excluded_Contact_Opp_Types__c = null,
                Membership_Record_Types__c = null
            ));
        
        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = npe01.Constants.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (
            npe01__Account_Processor__c = npe01.Constants.ONE_TO_ONE_PROCESSOR,
            npe01__Enable_Opportunity_Contact_Role_Trigger__c = true,
            npe01__Opportunity_Contact_Role_Default_role__c = 'Donor'
        ));
        Date datClose = System.Today();
            
        // create & insert contact(s)
        Contact[] TestCons = UnitTestData.CreateMultipleTestContacts ( 50 ) ;
        insert TestCons;

        // create new opps
        Opportunity[] newOpps = UnitTestData.OppsForContactList ( TestCons, null, UnitTestData.getClosedWonStage(), datClose, 1000 , giftRecordTypeNameForTests ,null);

        account testacct = new account(name='testacct');
        insert testacct;

        Test.startTest();

        // create the page 
        PageReference pageRef=Page.OpportunityRollup; 
        Test.setCurrentPage(pageRef); 

        // set the parameter for the contact
        ApexPages.currentPage().getParameters().put('id', testcons[3].id);
        
        // instantiate the controller
        RLLP_OppRollup_CTRL controller=new RLLP_OppRollup_CTRL();

        // rollup the contact
        pageReference nextref = controller.startAction();       

        system.assert(nextref.getUrl().contains(testcons[3].id));
        
        // roll up everyone
        controller.rollup();
        controller.cancel();
    }
    
    static testmethod void testOppRollupSchedule(){ 
        Test.startTest(); 
        
        //Schedule the test job 
        String jobId = System.schedule('test Opp Sched', 
        '0 0 0 3 9 ? 2022',new RLLP_OppRollup_SCHED()); 

        CronTrigger ct =[SELECT id,CronExpression,TimesTriggered,NextFireTime 
        FROM CronTrigger WHERE id=:jobId]; 
        //Verify the expressions are the same 
        System.assertEquals('0 0 0 3 9 ? 2022',ct.CronExpression); 
        //Verify the job has not run 
        System.assertEquals(0,ct.TimesTriggered); 
        //Verify the next time the job will run 
        System.assertEquals('2022-09-03 00:00:00',String.valueOf(ct.NextFireTime)); 
        
        Test.stopTest();        
    } 
}