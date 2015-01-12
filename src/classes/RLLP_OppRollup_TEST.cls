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

    // if you only want to run one test in this class, fill in its name here.
    // if you want to run all tests, then use '*'
    private static string strTestOnly = '*';
    
    //-----------------------------------------------------------------------------------------------------------------------
    // TEST DATA HELPER
    //  use the following static variables and initialization routine to help setup test data for opportunities. 
    //-----------------------------------------------------------------------------------------------------------------------
    
    // helper static variables provided by setupTestData
    static Date datToday = System.Today();
    static Date dat1YearAgo = Date.newInstance( datToday.year()-1,1,1);
    static Date dat2YearAgo = Date.newInstance( datToday.year()-2,1,1);
    static Date dat4YearAgo = Date.newInstance( datToday.year()-4,1,1);
    static String giftRecordTypeNameForTests = UTIL_RecordTypes.getRecordTypeNameForGiftsTests('Opportunity');
    static String membershipRecordTypeNameForTests = UTIL_RecordTypes.getRecordTypeNameForMembershipTests('Opportunity');
    static list<Contact> listConTest;
    static list<Opportunity> listOppTest;

    // helper utility to create test contacts and test opps
    static boolean setupTestData(integer numContacts, string strProcessor) {      
        
        if (membershipRecordTypeNameForTests == null)
            return false;
            
        // reinitialize our lists
        listConTest = new list<Contact>();
        listOppTest = new list<Opportunity>();
            
        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (
            npe01__Account_Processor__c = strProcessor,
            npe01__Enable_Opportunity_Contact_Role_Trigger__c = true,
            npe01__Opportunity_Contact_Role_Default_role__c = 'Donor'
        ));
                
        npo02__Households_Settings__c householdSettingsForTests = UTIL_CustomSettingsFacade.getHouseholdsSettingsForTests(
            new npo02__Households_Settings__c (
                npo02__Household_Rules__c = HH_Households.ALL_PROCESSOR,
                npo02__Always_Rollup_to_Primary_Contact__c = false,
                npo02__Enable_Opp_Rollup_Triggers__c = false, // DJH: not needed since calling opp rollups directly. 
                npo02__Excluded_Account_Opp_Rectypes__c = null,
                npo02__Excluded_Account_Opp_Types__c = null,
                npo02__Excluded_Contact_Opp_Rectypes__c = null,
                npo02__Excluded_Contact_Opp_Types__c = null,
                npo02__Membership_Record_Types__c = membershipRecordTypeNameForTests
            ));
                
        // create & insert contact(s)
        listConTest = UTIL_UnitTestData_TEST.CreateMultipleTestContacts (numContacts) ;
        insert listConTest;
            
        // create a new gift for this yr
        Opportunity[] testGift1 = UTIL_UnitTestData_TEST.OppsForContactList ( listConTest, null, UTIL_UnitTestData_TEST.getClosedWonStage(), 
            datToday, 100 , householdSettingsForTests.npo02__Membership_Record_Types__c,null);
        listOppTest.addAll(testGift1);
        //create a 2nd gift for last yr
        Opportunity[] testGift2 = UTIL_UnitTestData_TEST.OppsForContactList ( listConTest, null, UTIL_UnitTestData_TEST.getClosedWonStage(), 
            dat1YearAgo, 60, householdSettingsForTests.npo02__Membership_Record_Types__c,null);
        listOppTest.addAll(testGift2);
        insert listOppTest;
            
        // now roll up manually
        RLLP_OppRollup rg = new RLLP_OppRollup();
        rg.rollupContacts(new map<id, Contact>(listConTest));

        //now test that the contact has received the proper stats from the trigger
        RLLP_OppRollup_UTIL oppRollupUtil = new RLLP_OppRollup_UTIL();
        string strSoql = oppRollupUtil.buildContactQuery();
        strSoql = strSoql.replace('select id,', 'select id, Firstname, LastName,');
        listConTest = database.query(strSoql);
            
        System.AssertEquals ( 160 , listConTest[0].npo02__TotalOppAmount__c );
        System.AssertEquals ( 100 , listConTest[0].npo02__OppAmountThisYear__c );
        System.AssertEquals ( 60 , listConTest[0].npo02__OppAmountLastYear__c );
        System.AssertEquals ( 0 , listConTest[0].npo02__OppAmount2YearsAgo__c );
        return true;
    }

    static testMethod void testGivingRollupOne2One(){
    	if (strTestOnly != '*' && strTestOnly != 'testGivingRollupOne2One') return;
        testGivingRollupProcessor(CAO_Constants.ONE_TO_ONE_PROCESSOR);
    }
    static testMethod void testGivingRollupHHAccount(){
        if (strTestOnly != '*' && strTestOnly != 'testGivingRollupHHAccount') return;
        testGivingRollupProcessor(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    }
    static void testGivingRollupProcessor(string strProcessor){

        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_and_Orgs_Settings__c (
            npe01__Account_Processor__c = strProcessor,
            npe01__Enable_Opportunity_Contact_Role_Trigger__c = true,
            npe01__Opportunity_Contact_Role_Default_role__c = 'Donor'
        ));

        npo02__Households_Settings__c householdSettingsForTests = UTIL_CustomSettingsFacade.getHouseholdsSettingsForTests(
            new npo02__Households_Settings__c (
            npo02__Household_Rules__c = HH_Households.ALL_PROCESSOR, 
            npo02__Always_Rollup_to_Primary_Contact__c = false,
            npo02__Enable_Opp_Rollup_Triggers__c = true,
            npo02__Excluded_Account_Opp_Rectypes__c = null,
            npo02__Excluded_Account_Opp_Types__c = null,
            npo02__Excluded_Contact_Opp_Rectypes__c = null,
            npo02__Excluded_Contact_Opp_Types__c = null,
            npo02__Membership_Record_Types__c = null
        )); 
            
        Date datClose = System.Today();

        // create & insert contact(s)
        Contact c = new Contact( 
            FirstName = CAO_Constants.CONTACT_FIRSTNAME_FOR_TESTS,
            LastName = CAO_Constants.CONTACT_LASTNAME_FOR_TESTS,
            npe01__Private__c=false,
            npe01__WorkEmail__c = CAO_Constants.CONTACT_EMAIL_FOR_TESTS, 
            npe01__Preferred_Email__c = CAO_Constants.CONTACT_PREFERRED_EMAIL_FOR_TESTS,
            npe01__WorkPhone__c = CAO_Constants.CONTACT_PHONE_FOR_TESTS,
            npe01__PreferredPhone__c = CAO_Constants.CONTACT_PREFERRED_PHONE_FOR_TESTS
        );
        insert c;

        Id rt_id = UTIL_RecordTypes.GetRecordTypeId('Opportunity', giftRecordTypeNameForTests);

        //create new opp            
        Opportunity o = new Opportunity(
                    Name = 'Test Opp 45',
                    CloseDate = datClose,
                    StageName = UTIL_UnitTestData_TEST.getClosedWonStage(),
                    npe01__Contact_Id_for_Role__c = c.id,
                    Amount = 100
                    );

        if (rt_id != null) {
            o.put('RecordTypeId', rt_id);
        }

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
                                    npo02__Best_Gift_Year__c, npo02__Best_Gift_Year_Total__c, npo02__Household__r.npo02__Best_Gift_Year__c, npo02__Household__r.npo02__Best_Gift_Year_Total__c,  
                                    npo02__household__r.npo02__TotalOppAmount__c, npo02__TotalOppAmount__c, npo02__LastCloseDate__c 
                                    FROM Contact WHERE Id = :c.id];
    
        system.AssertEquals(100, UpdatedCon.npo02__TotalOppAmount__c);
        system.AssertEquals(100, UpdatedCon.npo02__Household__r.npo02__TotalOppAmount__c);
        system.AssertEquals(100, UpdatedCon.npo02__OppAmountThisYear__c);
        system.AssertEquals(0, UpdatedCon.npo02__OppAmountLastYear__c);
        system.AssertEquals(100, UpdatedCon.npo02__Best_Gift_Year_Total__c);
        system.AssertEquals(string.valueof(datClose.year()), UpdatedCon.npo02__Best_Gift_Year__c);
        system.AssertEquals(100, UpdatedCon.npo02__household__r.npo02__Best_Gift_Year_Total__c);
        system.AssertEquals(string.valueof(datClose.year()), UpdatedCon.npo02__household__r.npo02__Best_Gift_Year__c);
    }
    
    static testMethod void testGivingRollupIndividualBucket(){
    	if (strTestOnly != '*' && strTestOnly != 'testGivingRollupIndividualBucket') return;
        testGivingRollupIndividualProcessor(CAO_Constants.BUCKET_PROCESSOR);
    }
    static testMethod void testGivingRollupIndividualHHAccount(){
    	if (strTestOnly != '*' && strTestOnly != 'testGivingRollupIndividualHHAccount') return;
        testGivingRollupIndividualProcessor(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    }
    static void testGivingRollupIndividualProcessor(string strProcessor) {

            npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (
                npe01__Account_Processor__c = strProcessor,
                npe01__Enable_Opportunity_Contact_Role_Trigger__c = true,
                npe01__Opportunity_Contact_Role_Default_role__c = 'Donor'
            ));

            npo02__Households_Settings__c householdSettingsForTests = UTIL_CustomSettingsFacade.getHouseholdsSettingsForTests(
                new npo02__Households_Settings__c (
                    npo02__Household_Rules__c = HH_Households.ALL_PROCESSOR,
                    npo02__Always_Rollup_to_Primary_Contact__c = false,
                    npo02__Enable_Opp_Rollup_Triggers__c = true,
                    npo02__Excluded_Account_Opp_Rectypes__c = null,
                    npo02__Excluded_Account_Opp_Types__c = null,
                    npo02__Excluded_Contact_Opp_Rectypes__c = null,
                    npo02__Excluded_Contact_Opp_Types__c = null,
                    npo02__Membership_Record_Types__c = null
                ));

            Date datClose = System.Today();

            // create & insert contact(s)
            Contact[] TestCons = new contact[]{ new contact(
                FirstName= CAO_Constants.CONTACT_FIRSTNAME_FOR_TESTS,
                LastName= CAO_Constants.CONTACT_LASTNAME_FOR_TESTS,
                npe01__Private__c=false,
                npe01__WorkEmail__c = CAO_Constants.CONTACT_EMAIL_FOR_TESTS, 
                npe01__Preferred_Email__c = CAO_Constants.CONTACT_PREFERRED_EMAIL_FOR_TESTS,
                npe01__WorkPhone__c = CAO_Constants.CONTACT_PHONE_FOR_TESTS,
                npe01__PreferredPhone__c = CAO_Constants.CONTACT_PREFERRED_PHONE_FOR_TESTS
            ) };
            insert TestCons;

            // create new opps
            Opportunity[] newOpps = UTIL_UnitTestData_TEST.OppsForContactList ( TestCons, null, UTIL_UnitTestData_TEST.getClosedWonStage(), datClose, 100 , giftRecordTypeNameForTests ,null);

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
            RLLP_OppRollup rg = new RLLP_OppRollup();
            rg.rollupContacts(new map<id, Contact>(new list<Contact>{TestCons[0]}));

            id hhid = UpdatedCon.npo02__household__r.id;
            npo02__Household__c[] hhs = database.query('SELECT id, npo02__TotalOppAmount__c, npo02__LastCloseDate__c, '+
            'npo02__TotalMembershipOppAmount__c, npo02__OppAmountLastNDays__c, npo02__OppAmountThisYear__c, npo02__LastMembershipLevel__c, ' +
            'npo02__OppAmountLastYear__c, npo02__OppAmount2YearsAgo__c, npo02__MembershipJoinDate__c, npo02__MembershipEndDate__c, '+
            'npo02__Best_Gift_Year__c, npo02__Best_Gift_Year_Total__c ' +
            (RLLP_OppRollup_UTIL.isMultiCurrency() ? ', CurrencyIsoCode ' : '')+      
            'FROM npo02__household__c WHERE id = :hhid LIMIT 1');

            rg = new RLLP_OppRollup();
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

    static testMethod void testGivingRollupExcludedRTOne2One(){
    	if (strTestOnly != '*' && strTestOnly != 'testGivingRollupExcludedRTOne2One') return;
        testGivingRollupExcludedRTProcessor(CAO_Constants.ONE_TO_ONE_PROCESSOR);
    }
    static testMethod void testGivingRollupExcludedRTHHAccount(){
    	if (strTestOnly != '*' && strTestOnly != 'testGivingRollupExcludedRTHHAccount') return;
        testGivingRollupExcludedRTProcessor(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    }
    static void testGivingRollupExcludedRTProcessor (string strProcessor) {

        if(giftRecordTypeNameForTests!=''){
            npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (
                npe01__Account_Processor__c = strProcessor,
                npe01__Enable_Opportunity_Contact_Role_Trigger__c = true,
                npe01__Opportunity_Contact_Role_Default_role__c = 'Donor'
            ));

            npo02__Households_Settings__c householdSettingsForTests = UTIL_CustomSettingsFacade.getHouseholdsSettingsForTests(
                new npo02__Households_Settings__c (
                    npo02__Household_Rules__c = HH_Households.ALL_PROCESSOR,
                    npo02__Always_Rollup_to_Primary_Contact__c = false,
                    npo02__Enable_Opp_Rollup_Triggers__c = true,
                    npo02__Excluded_Account_Opp_Rectypes__c = giftRecordTypeNameForTests,
                    npo02__Excluded_Account_Opp_Types__c = null,
                    npo02__Excluded_Contact_Opp_Rectypes__c = giftRecordTypeNameForTests,
                    npo02__Excluded_Contact_Opp_Types__c = null,
                    npo02__Membership_Record_Types__c = null
                ));

            Date datClose = System.Today();

            // create & insert contact(s)
            Contact[] TestCons = new contact[]{ new contact(
                FirstName= CAO_Constants.CONTACT_FIRSTNAME_FOR_TESTS,
                LastName= CAO_Constants.CONTACT_LASTNAME_FOR_TESTS,
                npe01__Private__c=false,
                npe01__WorkEmail__c = CAO_Constants.CONTACT_EMAIL_FOR_TESTS, 
                npe01__Preferred_Email__c = CAO_Constants.CONTACT_PREFERRED_EMAIL_FOR_TESTS,
                npe01__WorkPhone__c = CAO_Constants.CONTACT_PHONE_FOR_TESTS,
                npe01__PreferredPhone__c = CAO_Constants.CONTACT_PREFERRED_PHONE_FOR_TESTS
            ) };
            insert TestCons;

            // create new opps
            Opportunity[] newOpps = UTIL_UnitTestData_TEST.OppsForContactList ( TestCons, null, UTIL_UnitTestData_TEST.getClosedWonStage(), datClose, 100 , giftRecordTypeNameForTests ,null);

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
            RLLP_OppRollup rg = new RLLP_OppRollup();
            rg.rollupContacts(new map<id, Contact>(new list<Contact>{TestCons[0]}));

            id hhid = UpdatedCon.npo02__household__r.id;
            npo02__Household__c[] hhs = database.query('SELECT id, npo02__TotalOppAmount__c, npo02__LastCloseDate__c, '+
            'npo02__TotalMembershipOppAmount__c, npo02__OppAmountLastNDays__c, npo02__OppAmountThisYear__c, '+
            'npo02__OppAmountLastYear__c, npo02__OppAmount2YearsAgo__c, npo02__MembershipJoinDate__c, npo02__MembershipEndDate__c, '+
            'npo02__LastMembershipLevel__c, ' +
            'npo02__Best_Gift_Year__c, npo02__Best_Gift_Year_Total__c ' +
            (RLLP_OppRollup_UTIL.isMultiCurrency() ? ', CurrencyIsoCode ' : '')+      
            'FROM npo02__household__c WHERE id = :hhid LIMIT 1');

            rg = new RLLP_OppRollup();
            rg.rollupHouseholds(new map<id, npo02__Household__c>(hhs));

            //make sure the values are still right
            UpdatedCon = [SELECT id, Account.npo02__TotalOppAmount__c, npo02__OppAmountThisYear__c, npo02__OppAmountLastYear__c, npo02__Household__c, npo02__Household__r.npo02__TotalOppAmount__c, npo02__TotalOppAmount__c FROM Contact WHERE Id = :FirstConId];

            System.AssertEquals (0, UpdatedCon.npo02__TotalOppAmount__c );
            System.AssertEquals (0, UpdatedCon.npo02__household__r.npo02__TotalOppAmount__c );        
            System.AssertEquals (0, UpdatedCon.npo02__OppAmountThisYear__c);
            System.AssertEquals (0, UpdatedCon.npo02__OppAmountLastYear__c);
        }
    }

    static testMethod void testGivingRollupAlwaysPrimaryOne2One(){
    	if (strTestOnly != '*' && strTestOnly != 'testGivingRollupAlwaysPrimaryOne2One') return;
        testGivingRollupAlwaysPrimaryProcessor(CAO_Constants.ONE_TO_ONE_PROCESSOR);
    }
    static testMethod void testGivingRollupAlwaysPrimaryHHAccount(){
        if (strTestOnly != '*' && strTestOnly != 'testGivingRollupAlwaysPrimaryHHAccount') return;
        testGivingRollupAlwaysPrimaryProcessor(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    }
   static void testGivingRollupAlwaysPrimaryProcessor (string strProcessor) {

            npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (
                npe01__Account_Processor__c = strProcessor,
                npe01__Enable_Opportunity_Contact_Role_Trigger__c = true,
                npe01__Opportunity_Contact_Role_Default_role__c = 'Donor'
            ));

            npo02__Households_Settings__c householdSettingsForTests = UTIL_CustomSettingsFacade.getHouseholdsSettingsForTests(
                new npo02__Households_Settings__c (
                    npo02__Household_Rules__c = HH_Households.ALL_PROCESSOR,
                    npo02__Always_Rollup_to_Primary_Contact__c = true,
                    npo02__Enable_Opp_Rollup_Triggers__c = true,
                    npo02__Excluded_Account_Opp_Rectypes__c = null,
                    npo02__Excluded_Account_Opp_Types__c = null,
                    npo02__Excluded_Contact_Opp_Rectypes__c = null,
                    npo02__Excluded_Contact_Opp_Types__c = null,
                    npo02__Membership_Record_Types__c = null
                ));

            Date datClose = System.Today();
            // create account
            account testacct = new account(name='testacct');
            insert testacct;
            // create & insert contact(s)
            Contact[] TestCons = new contact[]{ new contact(
                FirstName= CAO_Constants.CONTACT_FIRSTNAME_FOR_TESTS,
                LastName= CAO_Constants.CONTACT_LASTNAME_FOR_TESTS,
                npe01__Private__c=false,
                AccountId = testacct.id,
                npe01__WorkEmail__c = CAO_Constants.CONTACT_EMAIL_FOR_TESTS, 
                npe01__Preferred_Email__c = CAO_Constants.CONTACT_PREFERRED_EMAIL_FOR_TESTS,
                npe01__WorkPhone__c = CAO_Constants.CONTACT_PHONE_FOR_TESTS,
                npe01__PreferredPhone__c = CAO_Constants.CONTACT_PREFERRED_PHONE_FOR_TESTS
            ) };
            insert TestCons;

            // create new opps
            Opportunity[] newOpps = UTIL_UnitTestData_TEST.OppsForContactList ( TestCons, null, UTIL_UnitTestData_TEST.getClosedWonStage(), datClose, 100 , giftRecordTypeNameForTests ,null);

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
            RLLP_OppRollup rg = new RLLP_OppRollup();
            rg.rollupContacts(new map<id, Contact>(new list<Contact>{TestCons[0]}));

            id hhid = UpdatedCon.npo02__household__r.id;
            npo02__household__c[] hhs = database.query('SELECT id, npo02__TotalOppAmount__c, npo02__LastCloseDate__c, '+
            'npo02__TotalMembershipOppAmount__c, npo02__OppAmountLastNDays__c, npo02__OppAmountThisYear__c, '+
            'npo02__OppAmountLastYear__c, npo02__OppAmount2YearsAgo__c, npo02__MembershipEndDate__c, npo02__MembershipJoinDate__c, npo02__LastMembershipLevel__c, '+
            'npo02__Best_Gift_Year__c, npo02__Best_Gift_Year_Total__c ' + 
            (RLLP_OppRollup_UTIL.isMultiCurrency() ? ', CurrencyIsoCode ' : '')+      
            'FROM npo02__household__c WHERE id = :hhid LIMIT 1');

            rg = new RLLP_OppRollup();
            rg.rollupHouseholds(new map<id, npo02__Household__c>(hhs));

            //make sure the values are still right
            UpdatedCon = [SELECT id, account.npo02__TotalOppAmount__c, npo02__OppAmountThisYear__c, npo02__OppAmountLastYear__c, npo02__household__c, npo02__household__r.npo02__TotalOppAmount__c, npo02__TotalOppAmount__c FROM Contact WHERE Id = :FirstConId];

            System.AssertEquals ( 100 , UpdatedCon.npo02__TotalOppAmount__c );
            System.AssertEquals ( 100 , UpdatedCon.npo02__household__r.npo02__TotalOppAmount__c );      
            System.AssertEquals ( 100 , UpdatedCon.npo02__OppAmountThisYear__c);
            System.AssertEquals ( 0 , UpdatedCon.npo02__OppAmountLastYear__c);
        
    }
    
    static testMethod void testMemberRollupOne2One(){
        if (strTestOnly != '*' && strTestOnly != 'testMemberRollupOne2One') return;
        testMemberRollupProcessor(CAO_Constants.ONE_TO_ONE_PROCESSOR);
    }
    static testMethod void testMemberRollupHHAccount(){
    	if (strTestOnly != '*' && strTestOnly != 'testMemberRollupHHAccount') return;
        testMemberRollupProcessor(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    }    
    static void testMemberRollupProcessor (string strProcessor) {

        if(membershipRecordTypeNameForTests!=''){
            npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (
                npe01__Account_Processor__c = strProcessor,
                npe01__Enable_Opportunity_Contact_Role_Trigger__c = true,
                npe01__Opportunity_Contact_Role_Default_role__c = 'Donor'
            ));

            npo02__Households_Settings__c householdSettingsForTests = UTIL_CustomSettingsFacade.getHouseholdsSettingsForTests(
                new npo02__Households_Settings__c (
                    npo02__Household_Rules__c = HH_Households.ALL_PROCESSOR,
                    npo02__Always_Rollup_to_Primary_Contact__c = false,
                    npo02__Enable_Opp_Rollup_Triggers__c = true,
                    npo02__Excluded_Account_Opp_Rectypes__c = null,
                    npo02__Excluded_Account_Opp_Types__c = null,
                    npo02__Excluded_Contact_Opp_Rectypes__c = null,
                    npo02__Excluded_Contact_Opp_Types__c = null,
                    npo02__Membership_Record_Types__c = membershipRecordTypeNameForTests
                ));

            Date datClose = System.Today();

            // create & insert contact(s)
            Contact[] TestCons = new contact[]{ new contact(
                FirstName= CAO_Constants.CONTACT_FIRSTNAME_FOR_TESTS,
                LastName= CAO_Constants.CONTACT_LASTNAME_FOR_TESTS,
                npe01__Private__c=false,
                npe01__WorkEmail__c = CAO_Constants.CONTACT_EMAIL_FOR_TESTS, 
                npe01__Preferred_Email__c = CAO_Constants.CONTACT_PREFERRED_EMAIL_FOR_TESTS,
                npe01__WorkPhone__c = CAO_Constants.CONTACT_PHONE_FOR_TESTS,
                npe01__PreferredPhone__c = CAO_Constants.CONTACT_PREFERRED_PHONE_FOR_TESTS
            ) };
            insert TestCons;

            // create new opps
            Opportunity[] newOpps = UTIL_UnitTestData_TEST.OppsForContactList (
                TestCons,
                null,
                UTIL_UnitTestData_TEST.getClosedWonStage(),
                datClose,
                100,
                householdSettingsForTests.npo02__Membership_Record_Types__c,
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

    static testMethod void testGivingRollupAcctOne2One(){
        if (strTestOnly != '*' && strTestOnly != 'testGivingRollupAcctOne2One') return;
        testGivingRollupAcct(CAO_Constants.ONE_TO_ONE_PROCESSOR);
    }
    static testMethod void testGivingRollupAcctHHAccount(){
        if (strTestOnly != '*' && strTestOnly != 'testGivingRollupAcctHHAccount') return;
        testGivingRollupAcct(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    }
    static void testGivingRollupAcct (string strProcessor) {
 
            npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (
                npe01__Account_Processor__c = strProcessor,
                npe01__Enable_Opportunity_Contact_Role_Trigger__c = true,
                npe01__Opportunity_Contact_Role_Default_role__c = 'Donor'
            ));
            
            npo02__Households_Settings__c householdSettingsForTests = UTIL_CustomSettingsFacade.getHouseholdsSettingsForTests(
                new npo02__Households_Settings__c (
                    npo02__Household_Rules__c = HH_Households.ALL_PROCESSOR,
                    npo02__Always_Rollup_to_Primary_Contact__c = false,
                    npo02__Enable_Opp_Rollup_Triggers__c = true,
                    npo02__Excluded_Account_Opp_Rectypes__c = null,
                    npo02__Excluded_Account_Opp_Types__c = null,
                    npo02__Excluded_Contact_Opp_Rectypes__c = null,
                    npo02__Excluded_Contact_Opp_Types__c = null,
                    npo02__Membership_Record_Types__c = null
                ));

            Date datClose = System.Today();

            // create account
            account testacct = new account(name='testacct');
            insert testacct;
            opportunity newOpp =
                 new opportunity (
                    name = 'testopp',
                    accountid = testacct.id, 
                    stagename=UTIL_UnitTestData_TEST.getClosedWonStage(),
                    closedate=datClose, amount=33333
                 );
            if(RLLP_OppRollup_UTIL.areRecordTypesOnOpps()){
                newOpp.put('RecordTypeId',UTIL_RecordTypes.GetRecordTypeId('Opportunity', giftRecordTypeNameForTests));
            }
            // insert the opp(s)
            Test.StartTest();
            insert newOpp;
            Test.StopTest();
            
            // test whether the trigger worked
            Account updatedAcct = [select id, npo02__TotalOppAmount__c, npo02__OppAmountThisYear__c,
                                    npo02__OppAmountLastYear__c, npo02__OppAmountLastNDays__c,
                                    npo02__OppAmount2YearsAgo__c, npo02__OppsClosedThisYear__c,
                                    npo02__LastCloseDate__c, npo02__NumberOfClosedOpps__c, 
                                    npo02__TotalMembershipOppAmount__c, npo02__OppsClosedLastYear__c,
                                    npo02__OppsClosedLastNDays__c, npo02__OppsClosed2YearsAgo__c,
                                    npo02__LastMembershipLevel__c, npo02__Best_Gift_Year__c, npo02__Best_Gift_Year_Total__c, 
                                    npo02__MembershipEndDate__c, npo02__MembershipJoinDate__c
                                    from Account where id =: testacct.id];
                                    
            System.AssertEquals ( 33333 , updatedAcct.npo02__TotalOppAmount__c );

            // now roll up manually
            RLLP_OppRollup rg = new RLLP_OppRollup();
            rg.rollupAccounts(new map<id, Account>(new list<Account>{updatedAcct}));

            updatedAcct = [select id, npo02__TotalOppAmount__c from account where id =: testacct.id];
            System.AssertEquals ( 33333 , updatedAcct.npo02__TotalOppAmount__c );    
    }

    static testMethod void testGivingRollupAcctMembershipOne2One(){
        if (strTestOnly != '*' && strTestOnly != 'testGivingRollupAcctMembershipOne2One') return;
        testGivingRollupAcctMembership(CAO_Constants.ONE_TO_ONE_PROCESSOR);
    }
    static testMethod void testGivingRollupAcctMembershipHHAccount(){
        if (strTestOnly != '*' && strTestOnly != 'testGivingRollupAcctMembershipHHAccount') return;
        testGivingRollupAcctMembership(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    }
    static void testGivingRollupAcctMembership (string strProcessor) {

        if(membershipRecordTypeNameForTests!=''){
            npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (
                npe01__Account_Processor__c = strProcessor,
                npe01__Enable_Opportunity_Contact_Role_Trigger__c = true,
                npe01__Opportunity_Contact_Role_Default_role__c = 'Donor'
            ));

            npo02__Households_Settings__c householdSettingsForTests = UTIL_CustomSettingsFacade.getHouseholdsSettingsForTests(
                new npo02__Households_Settings__c (
                    npo02__Household_Rules__c = HH_Households.ALL_PROCESSOR,
                    npo02__Always_Rollup_to_Primary_Contact__c = false,
                    npo02__Enable_Opp_Rollup_Triggers__c = true,
                    npo02__Excluded_Account_Opp_Rectypes__c = null,
                    npo02__Excluded_Account_Opp_Types__c = null,
                    npo02__Excluded_Contact_Opp_Rectypes__c = null,
                    npo02__Excluded_Contact_Opp_Types__c = null,
                    npo02__Membership_Record_Types__c = membershipRecordTypeNameForTests
                ));

            Date datClose = System.Today();

            // create account
            account testacct = new account(name='testacct');
            insert testacct;
            opportunity newOpp =
                 new opportunity (name = 'testopp', accountid = testacct.id, 
                                    npe01__member_level__c = 'Gold', npe01__membership_origin__c = 'New',
                                    stagename=UTIL_UnitTestData_TEST.getClosedWonStage(), closedate=datClose, amount=33333);
            newOpp.put('RecordTypeId',UTIL_RecordTypes.GetRecordTypeId('Opportunity', householdSettingsForTests.npo02__Membership_Record_Types__c));
            // insert the opp(s)
            Test.StartTest();
            insert newOpp;
            Test.StopTest();

            // test whether the trigger worked      
            account updatedAcct = [select id, npo02__TotalOppAmount__c, npo02__OppAmountThisYear__c,
                                    npo02__OppAmountLastYear__c, npo02__OppAmountLastNDays__c,
                                    npo02__OppAmount2YearsAgo__c, npo02__OppsClosedThisYear__c,
                                    npo02__LastCloseDate__c, npo02__NumberOfClosedOpps__c, 
                                    npo02__TotalMembershipOppAmount__c, npo02__OppsClosedLastYear__c,
                                    npo02__OppsClosedLastNDays__c, npo02__OppsClosed2YearsAgo__c,
                                    npo02__LastMembershipLevel__c, npo02__LastMembershipDate__c,
                                    npo02__LastMembershipAmount__c, npo02__LastMembershipOrigin__c,
                                    npo02__Best_Gift_Year__c, npo02__Best_Gift_Year_Total__c, npo02__MembershipEndDate__c,
                                    npo02__MembershipJoinDate__c
                                    from Account where id =: testacct.id];

            System.AssertEquals ( 33333 , updatedAcct.npo02__TotalMembershipOppAmount__c );
            System.AssertEquals ( system.today() , updatedAcct.npo02__LastMembershipDate__c );
            System.AssertEquals ( 33333 , updatedAcct.npo02__LastMembershipAmount__c );
            System.AssertEquals ( 'Gold' , updatedAcct.npo02__LastMembershipLevel__c );
            System.AssertEquals ( 'New' , updatedAcct.npo02__LastMembershipOrigin__c );

            // now roll up manually
            RLLP_OppRollup rg = new RLLP_OppRollup();
            rg.rollupAccounts(new map<id, Account>(new list<Account>{updatedAcct}));

            updatedAcct = [select id, npo02__TotalMembershipOppAmount__c from account where id =: testacct.id];
            System.AssertEquals ( 33333 , updatedAcct.npo02__TotalMembershipOppAmount__c );
        }
    }

    static testMethod void testGivingRollupBatchOne2One(){
        if (strTestOnly != '*' && strTestOnly != 'testGivingRollupBatchOne2One') return;
        testGivingRollupBatch(CAO_Constants.ONE_TO_ONE_PROCESSOR);
    }
    static testMethod void testGivingRollupBatchHHAccount(){
        if (strTestOnly != '*' && strTestOnly != 'testGivingRollupBatchHHAccount') return;
        testGivingRollupBatch(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    }
    static void testGivingRollupBatch (string strProcessor) {

            npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (
                npe01__Account_Processor__c = strProcessor,
                npe01__Enable_Opportunity_Contact_Role_Trigger__c = true,
                npe01__Opportunity_Contact_Role_Default_role__c = 'Donor'
            ));

            npo02__Households_Settings__c householdSettingsForTests = UTIL_CustomSettingsFacade.getHouseholdsSettingsForTests(
                new npo02__Households_Settings__c (
                    npo02__Household_Rules__c = HH_Households.ALL_PROCESSOR,
                    npo02__Always_Rollup_to_Primary_Contact__c = false,
                    npo02__Enable_Opp_Rollup_Triggers__c = true,
                    npo02__Excluded_Account_Opp_Rectypes__c = null,
                    npo02__Excluded_Account_Opp_Types__c = null,
                    npo02__Excluded_Contact_Opp_Rectypes__c = null,
                    npo02__Excluded_Contact_Opp_Types__c = null,
                    npo02__Membership_Record_Types__c = null
                ));

            Date datClose = System.Today();

            // create & insert contact(s)
            Contact[] TestCons = UTIL_UnitTestData_TEST.CreateMultipleTestContacts ( 50 ) ;
            insert TestCons;

            // create new opps
            Opportunity[] newOpps = UTIL_UnitTestData_TEST.OppsForContactList ( TestCons, null, UTIL_UnitTestData_TEST.getClosedWonStage(), datClose, 1000 , giftRecordTypeNameForTests ,null);

            account testacct = new account(name='testacct');
            insert testacct;

            // test the batch rollup method
            Test.StartTest();
            RLLP_OppRollup rg = new RLLP_OppRollup();
            rg.rollupAll();
            Test.StopTest();
    }

    static testMethod void OneContactMultipleOppsOne2One_1(){
        if (strTestOnly != '*' && strTestOnly != 'OneContactMultipleOppsOne2One_1') return;
        OneContactMultipleOpps_1(CAO_Constants.ONE_TO_ONE_PROCESSOR);
    }
    static testMethod void OneContactMultipleOppsHHAccount_1(){
        if (strTestOnly != '*' && strTestOnly != 'OneContactMultipleOppsHHAccount_1') return;
        OneContactMultipleOpps_1(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    }
    public static void OneContactMultipleOpps_1(string strProcessor) {

        integer numCon = 1;
        if (!setupTestData(numCon, strProcessor))
            return;

        System.AssertEquals ( 160 , listConTest[0].npo02__TotalOppAmount__c );
        System.AssertEquals ( 100 , listConTest[0].npo02__OppAmountThisYear__c );
        System.AssertEquals ( 60 , listConTest[0].npo02__OppAmountLastYear__c );

        // now chg the amts for both opps (cheapskate!)
        listOppTest[0].Amount = 50;
        listOppTest[numCon].Amount = 25;
        update listOppTest;
        
        // now roll up manually
        RLLP_OppRollup rg = new RLLP_OppRollup();        
        rg.rollupContacts(new map<id, Contact>(listConTest));

        ID ThisConId = listConTest[0].id;
        Contact UpdatedCon = [SELECT Id, npo02__TotalOppAmount__c, npo02__OppAmountThisYear__c, npo02__OppAmountLastYear__c  FROM Contact WHERE Id = :ThisConId];        
        System.AssertEquals ( 75 , UpdatedCon.npo02__TotalOppAmount__c );
        System.AssertEquals ( 50 , UpdatedCon.npo02__OppAmountThisYear__c );
        System.AssertEquals ( 25 , UpdatedCon.npo02__OppAmountLastYear__c );
    }

    static testMethod void OneContactMultipleOppsOne2One_2(){
        if (strTestOnly != '*' && strTestOnly != 'OneContactMultipleOppsOne2One_2') return;
        OneContactMultipleOpps_2(CAO_Constants.ONE_TO_ONE_PROCESSOR);
    }
    static testMethod void OneContactMultipleOppsHHAccount_2(){
        if (strTestOnly != '*' && strTestOnly != 'OneContactMultipleOppsHHAccount_2') return;
        OneContactMultipleOpps_2(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    }    
    public static void OneContactMultipleOpps_2(string strProcessor) {

        integer numCon = 1;
        if (!setupTestData(numCon, strProcessor))
            return;

        System.AssertEquals ( 160 , listConTest[0].npo02__TotalOppAmount__c );
        System.AssertEquals ( 100 , listConTest[0].npo02__OppAmountThisYear__c );
        System.AssertEquals ( 60 , listConTest[0].npo02__OppAmountLastYear__c );

        // now create a gift from 2 yrs ago
        Opportunity[] testGift3 = UTIL_UnitTestData_TEST.OppsForContactList ( listConTest, null, UTIL_UnitTestData_TEST.getClosedWonStage(), dat2YearAgo, 10 , giftRecordTypeNameForTests,null);  
        insert testGift3;

        // now roll up manually
        RLLP_OppRollup rg = new RLLP_OppRollup();
        rg.rollupContacts(new map<id, Contact>(new list<Contact>{listConTest[0]}));

        ID ThisConId = listConTest[0].id;
        Contact UpdatedCon = [SELECT Id, npo02__TotalOppAmount__c, npo02__OppAmountThisYear__c, npo02__OppAmountLastYear__c, npo02__OppAmount2YearsAgo__c  FROM Contact WHERE Id = :ThisConId];        

        System.AssertEquals ( 170 , UpdatedCon.npo02__TotalOppAmount__c );
        System.AssertEquals ( 100 , UpdatedCon.npo02__OppAmountThisYear__c );
        System.AssertEquals ( 60 , UpdatedCon.npo02__OppAmountLastYear__c );
        System.AssertEquals ( 10 , UpdatedCon.npo02__OppAmount2YearsAgo__c ); 
    }

    static testMethod void OneContactMultipleOppsOne2One_3(){
        if (strTestOnly != '*' && strTestOnly != 'OneContactMultipleOppsOne2One_3') return;
        OneContactMultipleOpps_3(CAO_Constants.ONE_TO_ONE_PROCESSOR);
    }
    static testMethod void OneContactMultipleOppsHHAccount_3(){
    	if (strTestOnly != '*' && strTestOnly != 'OneContactMultipleOppsHHAccount_3') return;
        OneContactMultipleOpps_3(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    }    
    public static void OneContactMultipleOpps_3(string strProcessor) {

        integer numCon = 1;
        if (!setupTestData(numCon, strProcessor))
            return;

        System.AssertEquals ( 160 , listConTest[0].npo02__TotalOppAmount__c );
        System.AssertEquals ( 100 , listConTest[0].npo02__OppAmountThisYear__c );
        System.AssertEquals ( 60 , listConTest[0].npo02__OppAmountLastYear__c );

        // add another from this year (to test adding)
        Opportunity[] testGift4 = UTIL_UnitTestData_TEST.OppsForContactList ( listConTest, null, UTIL_UnitTestData_TEST.getClosedWonStage(), datToday, 25 , giftRecordTypeNameForTests,null);
        insert testGift4;
        Opportunity[] testGift5 = UTIL_UnitTestData_TEST.OppsForContactList ( listConTest, null, UTIL_UnitTestData_TEST.getClosedWonStage(), datToday, 25 , giftRecordTypeNameForTests,null);
        insert testGift5;

        // now roll up manually
        RLLP_OppRollup rg = new RLLP_OppRollup();
        rg.rollupContacts(new map<id, Contact>(new list<Contact>{listConTest[0]}));

        ID ThisConId = listConTest[0].id;
        Contact UpdatedCon = [SELECT Id, npo02__TotalOppAmount__c, npo02__OppAmountThisYear__c, npo02__OppAmountLastYear__c, npo02__OppAmount2YearsAgo__c  FROM Contact WHERE Id = :ThisConId];        
        System.AssertEquals ( 210 , UpdatedCon.npo02__TotalOppAmount__c );
        System.AssertEquals ( 150 , UpdatedCon.npo02__OppAmountThisYear__c );        
        System.AssertEquals ( 60 , UpdatedCon.npo02__OppAmountLastYear__c );
        System.AssertEquals ( 0 , UpdatedCon.npo02__OppAmount2YearsAgo__c );
    }

    static testMethod void OneContactMultipleOppsOne2One_4(){
    	if (strTestOnly != '*' && strTestOnly != 'OneContactMultipleOppsOne2One_4') return;
        OneContactMultipleOpps_4(CAO_Constants.ONE_TO_ONE_PROCESSOR);
    }
    static testMethod void OneContactMultipleOppsHHAccount_4(){
        if (strTestOnly != '*' && strTestOnly != 'OneContactMultipleOppsHHAccount_4') return;
        OneContactMultipleOpps_4(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    }    
    public static void OneContactMultipleOpps_4(string strProcessor) {

        integer numCon = 1;
        if (!setupTestData(numCon, strProcessor))
            return;

        System.AssertEquals ( 160 , listConTest[0].npo02__TotalOppAmount__c );
        System.AssertEquals ( 100 , listConTest[0].npo02__OppAmountThisYear__c );
        System.AssertEquals ( 60 , listConTest[0].npo02__OppAmountLastYear__c );

        // TBD add a gift from longer ago
        Opportunity[] testGift5 = UTIL_UnitTestData_TEST.OppsForContactList ( listConTest, null, UTIL_UnitTestData_TEST.getClosedWonStage(), dat4YearAgo, 200 , giftRecordTypeNameForTests,null);
        insert testGift5;

        // now roll up manually
        RLLP_OppRollup rg = new RLLP_OppRollup();
        rg.rollupContacts(new map<id, Contact>(new list<Contact>{listConTest[0]}));

        // totals should not have changed, except lifetime & best yr
        ID ThisConId = listConTest[0].id;
        Contact UpdatedCon = [SELECT Id, npo02__TotalOppAmount__c, npo02__OppAmountThisYear__c, npo02__OppAmountLastYear__c, npo02__OppAmount2YearsAgo__c  FROM Contact WHERE Id = :ThisConId];        

        System.AssertEquals ( 360 , UpdatedCon.npo02__TotalOppAmount__c );
        System.AssertEquals ( 100 , UpdatedCon.npo02__OppAmountThisYear__c );
        System.AssertEquals ( 60 , UpdatedCon.npo02__OppAmountLastYear__c );
        System.AssertEquals ( 0 , UpdatedCon.npo02__OppAmount2YearsAgo__c );
    }

    static testMethod void OneContactMultipleOppsOne2One_5(){
        if (strTestOnly != '*' && strTestOnly != 'OneContactMultipleOppsOne2One_5') return;
        OneContactMultipleOpps_5(CAO_Constants.ONE_TO_ONE_PROCESSOR);
    }
    static testMethod void OneContactMultipleOppsHHAccount_5(){
        if (strTestOnly != '*' && strTestOnly != 'OneContactMultipleOppsHHAccount_5') return;
        OneContactMultipleOpps_5(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    }
    public static void OneContactMultipleOpps_5(string strProcessor) {

        integer numCon = 1;
        if (!setupTestData(numCon, strProcessor))
            return;

        System.AssertEquals ( 160 , listConTest[0].npo02__TotalOppAmount__c );
        System.AssertEquals ( 100 , listConTest[0].npo02__OppAmountThisYear__c );
        System.AssertEquals ( 60 , listConTest[0].npo02__OppAmountLastYear__c );

        // TBD add non-won gift
        Opportunity[] testGift6 = UTIL_UnitTestData_TEST.OppsForContactList ( listConTest, null, UTIL_UnitTestData_TEST.getOpenStage(), dat4YearAgo, 35 , giftRecordTypeNameForTests,null);
        insert testGift6;

        // now roll up manually
        RLLP_OppRollup rg = new RLLP_OppRollup();
        rg.rollupContacts(new map<id, Contact>(new list<Contact>{listConTest[0]}));

        // totals should not have changed at all
        ID ThisConId = listConTest[0].id;
        Contact UpdatedCon = [SELECT Id, npo02__TotalOppAmount__c, npo02__OppAmountThisYear__c, npo02__OppAmountLastYear__c, npo02__OppAmount2YearsAgo__c  FROM Contact WHERE Id = :ThisConId];        
        System.AssertEquals ( 160 , UpdatedCon.npo02__TotalOppAmount__c );
        System.AssertEquals ( 100 , UpdatedCon.npo02__OppAmountThisYear__c );
        System.AssertEquals ( 60 , UpdatedCon.npo02__OppAmountLastYear__c );
        System.AssertEquals ( 0 , UpdatedCon.npo02__OppAmount2YearsAgo__c );
    }

    static testMethod void OneContactMultipleOppsOne2One_6(){
        if (strTestOnly != '*' && strTestOnly != 'OneContactMultipleOppsOne2One_6') return;
        OneContactMultipleOpps_6(CAO_Constants.ONE_TO_ONE_PROCESSOR);
    }
    static testMethod void OneContactMultipleOppsHHAccount_6(){
        if (strTestOnly != '*' && strTestOnly != 'OneContactMultipleOppsHHAccount_6') return;
        OneContactMultipleOpps_6(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    }    
    public static void OneContactMultipleOpps_6(string strProcessor) {

        integer numCon = 1;
        if (!setupTestData(numCon, strProcessor))
            return;

        System.AssertEquals ( 160 , listConTest[0].npo02__TotalOppAmount__c );
        System.AssertEquals ( 100 , listConTest[0].npo02__OppAmountThisYear__c );
        System.AssertEquals ( 60 , listConTest[0].npo02__OppAmountLastYear__c );

        // now delete the 1st gift, totals should decrease
        decimal dblAmt = listOppTest[0].Amount;
        delete listOppTest[0];

        // now roll up manually
        RLLP_OppRollup rg = new RLLP_OppRollup();
        rg.rollupContacts(new map<id, Contact>(new list<Contact>{listConTest[0]}));

        ID ThisConId = listConTest[0].id;
        Contact UpdatedCon = [SELECT Id, npo02__TotalOppAmount__c, npo02__OppAmountThisYear__c, npo02__OppAmountLastYear__c, npo02__OppAmount2YearsAgo__c  FROM Contact WHERE Id = :ThisConId];        

        System.AssertEquals ( 160-dblAmt , UpdatedCon.npo02__TotalOppAmount__c );
        System.AssertEquals ( 100-dblAmt , UpdatedCon.npo02__OppAmountThisYear__c );        
        System.AssertEquals ( 60 , UpdatedCon.npo02__OppAmountLastYear__c );
        System.AssertEquals ( 0 , UpdatedCon.npo02__OppAmount2YearsAgo__c );        
    }

    static testMethod void OneContactOneInkindOne2One(){
        if (strTestOnly != '*' && strTestOnly != 'OneContactOneInkindOne2One') return;
        OneContactOneInkind(CAO_Constants.ONE_TO_ONE_PROCESSOR);
    }
    static testMethod void OneContactOneInkindHHAccount(){
        if (strTestOnly != '*' && strTestOnly != 'OneContactOneInkindHHAccount') return;
        OneContactOneInkind(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    }
    static void OneContactOneInkind(string strProcessor) {

            npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (
                npe01__Account_Processor__c = strProcessor,
                npe01__Enable_Opportunity_Contact_Role_Trigger__c = true,
                npe01__Opportunity_Contact_Role_Default_role__c = 'Donor'
            ));

            npo02__Households_Settings__c householdSettingsForTests = UTIL_CustomSettingsFacade.getHouseholdsSettingsForTests(
                new npo02__Households_Settings__c (
                    npo02__Household_Rules__c = HH_Households.ALL_PROCESSOR,
                    npo02__Always_Rollup_to_Primary_Contact__c = false,
                    npo02__Enable_Opp_Rollup_Triggers__c = true,
                    npo02__Excluded_Account_Opp_Rectypes__c = null,
                    npo02__Excluded_Account_Opp_Types__c = 'In Kind',
                    npo02__Excluded_Contact_Opp_Rectypes__c = null,
                    npo02__Excluded_Contact_Opp_Types__c = 'In Kind',
                    npo02__Membership_Record_Types__c = null
                ));

            integer howMany = 1;

            // create & insert contact(s)
            Contact[] TestCons = UTIL_UnitTestData_TEST.CreateMultipleTestContacts ( howMany ) ;
            insert TestCons;

            // create a new gift for this yr
            Opportunity[] testGift1 = UTIL_UnitTestData_TEST.OppsForContactList ( TestCons, null, UTIL_UnitTestData_TEST.getClosedWonStage(), datToday, 100 , giftRecordTypeNameForTests,'In Kind');
            Test.StartTest();
            insert testGift1 ;
            Test.StopTest();

            id ThisConId = TestCons[0].id;
            contact UpdatedCon = [SELECT Id,  npo02__TotalOppAmount__c, npo02__OppAmountThisYear__c, npo02__OppAmountLastYear__c, npo02__OppAmount2YearsAgo__c FROM Contact WHERE Id = :ThisConId];

            System.Assert(!(UpdatedCon.npo02__TotalOppAmount__c>0));
    }

    static testMethod void testGivingRollupBulkOne2One(){
        if (strTestOnly != '*' && strTestOnly != 'testGivingRollupBulkOne2One') return;
        testGivingRollupBulk(CAO_Constants.ONE_TO_ONE_PROCESSOR);
    }
    static testMethod void testGivingRollupBulkHHAccount(){
        if (strTestOnly != '*' && strTestOnly != 'testGivingRollupBulkHHAccount') return;
        testGivingRollupBulk(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    }    
    static void testGivingRollupBulk (string strProcessor) {
    
            npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (
                npe01__Account_Processor__c = strProcessor,
                npe01__Enable_Opportunity_Contact_Role_Trigger__c = true,
                npe01__Opportunity_Contact_Role_Default_role__c = 'Donor'
            ));

            npo02__Households_Settings__c householdSettingsForTests = UTIL_CustomSettingsFacade.getHouseholdsSettingsForTests(
                new npo02__Households_Settings__c (
                    npo02__Household_Rules__c = HH_Households.ALL_PROCESSOR,
                    npo02__Always_Rollup_to_Primary_Contact__c = false,
                    npo02__Enable_Opp_Rollup_Triggers__c = true,
                    npo02__Excluded_Account_Opp_Rectypes__c = null,
                    npo02__Excluded_Account_Opp_Types__c = null,
                    npo02__Excluded_Contact_Opp_Rectypes__c = null,
                    npo02__Excluded_Contact_Opp_Types__c = null,
                    npo02__Membership_Record_Types__c = null
                ));

            // for a single contact w/ no previous mbrships, add a new membership
            // and test mbr stats are created
            integer howMany = 50;
            Date datClose = System.Today();

            // create & insert contact(s)
            Contact[] TestCons = UTIL_UnitTestData_TEST.CreateMultipleTestContacts ( howMany ) ;
            insert TestCons;

            // create new opps
            Opportunity[] newOpps1 = UTIL_UnitTestData_TEST.OppsForContactList ( TestCons, null, UTIL_UnitTestData_TEST.getClosedWonStage(), datClose, 100 , giftRecordTypeNameForTests,null);
            Opportunity[] newOpps2 = UTIL_UnitTestData_TEST.OppsForContactList ( TestCons, null, UTIL_UnitTestData_TEST.getClosedWonStage(), datClose.addYears(-1), 50 , giftRecordTypeNameForTests,null);

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

    static testMethod void testGivingRollupTooManyOppsOne2One(){
        if (strTestOnly != '*' && strTestOnly != 'testGivingRollupTooManyOppsOne2One') return;
        testGivingRollupTooManyOpps(CAO_Constants.ONE_TO_ONE_PROCESSOR);
    }
    static testMethod void testGivingRollupTooManyOppsHHAccount(){
        if (strTestOnly != '*' && strTestOnly != 'testGivingRollupTooManyOppsHHAccount') return;
        testGivingRollupTooManyOpps(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    }    
    static void testGivingRollupTooManyOpps (string strProcessor) {

            npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (
                npe01__Account_Processor__c = strProcessor,
                npe01__Enable_Opportunity_Contact_Role_Trigger__c = true,
                npe01__Opportunity_Contact_Role_Default_role__c = 'Donor'
            ));

            npo02__Households_Settings__c householdSettingsForTests = UTIL_CustomSettingsFacade.getHouseholdsSettingsForTests(
                new npo02__Households_Settings__c (
                    npo02__Household_Rules__c = HH_Households.ALL_PROCESSOR,
                    npo02__Always_Rollup_to_Primary_Contact__c = false,
                    npo02__Enable_Opp_Rollup_Triggers__c = true,
                    npo02__Excluded_Account_Opp_Rectypes__c = null,
                    npo02__Excluded_Account_Opp_Types__c = null,
                    npo02__Excluded_Contact_Opp_Rectypes__c = null,
                    npo02__Excluded_Contact_Opp_Types__c = null,
                    npo02__Membership_Record_Types__c = null
                ));

            // for a single contact w/ no previous mbrships, add a new membership
            // and test mbr stats are created

            // create & insert contact(s)
            Contact[] TestCons = UTIL_UnitTestData_TEST.CreateMultipleTestContacts ( 1 ) ;
            insert TestCons;

            // create new opps
            Opportunity[] newOpps1 = new Opportunity[0];
            for (integer n = 0; n < 450; n++) {
                Opportunity newOpp1 = new opportunity(npe01__Contact_Id_for_Role__c = TestCons[0].id,
                    name = 'test opp ' + n, 
                    stagename = UTIL_UnitTestData_TEST.getClosedWonStage(), closedate = system.today().adddays(-n), amount = 100);
                if(RLLP_OppRollup_UTIL.areRecordTypesOnOpps()){
                    newOpp1.put('RecordTypeId',UTIL_RecordTypes.GetRecordTypeId('Opportunity', giftRecordTypeNameForTests));
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

    static testMethod void testHouseholdStatsOne2One(){
        if (strTestOnly != '*' && strTestOnly != 'testHouseholdStatsOne2One') return;
        testHouseholdStats(CAO_Constants.ONE_TO_ONE_PROCESSOR);
    }
    static testMethod void testHouseholdStatsHHAccount(){
        if (strTestOnly != '*' && strTestOnly != 'testHouseholdStatsHHAccount') return;
        testHouseholdStats(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    }
    static void testHouseholdStats (string strProcessor) {

            npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (
                npe01__Account_Processor__c = strProcessor,
                npe01__Enable_Opportunity_Contact_Role_Trigger__c = true,
                npe01__Opportunity_Contact_Role_Default_role__c = 'Donor'
            ));

            npo02__Households_Settings__c householdSettingsForTests = UTIL_CustomSettingsFacade.getHouseholdsSettingsForTests(
                new npo02__Households_Settings__c (
                    npo02__Household_Rules__c = HH_Households.ALL_PROCESSOR,
                    npo02__Always_Rollup_to_Primary_Contact__c = false,
                    npo02__Enable_Opp_Rollup_Triggers__c = true,
                    npo02__Excluded_Account_Opp_Rectypes__c = null,
                    npo02__Excluded_Account_Opp_Types__c = null,
                    npo02__Excluded_Contact_Opp_Rectypes__c = null,
                    npo02__Excluded_Contact_Opp_Types__c = null,
                    npo02__Membership_Record_Types__c = null
                ));

            Date datClose = System.Today();

            // create & insert contact
            Contact Con1 = new contact(
                FirstName= CAO_Constants.CONTACT_FIRSTNAME_FOR_TESTS,
                LastName= CAO_Constants.CONTACT_LASTNAME_FOR_TESTS,
                npe01__Private__c=false,
                npe01__WorkEmail__c = CAO_Constants.CONTACT_EMAIL_FOR_TESTS, 
                npe01__Preferred_Email__c = CAO_Constants.CONTACT_PREFERRED_EMAIL_FOR_TESTS,
                npe01__WorkPhone__c = CAO_Constants.CONTACT_PHONE_FOR_TESTS,
                npe01__PreferredPhone__c = CAO_Constants.CONTACT_PREFERRED_PHONE_FOR_TESTS
            );
            insert Con1;

            Contact con = [SELECT AccountId, npo02__household__r.id FROM Contact WHERE id = :Con1.id LIMIT 1];

            // create & insert second household member
            Contact Con2 = new contact(
                FirstName= CAO_Constants.CONTACT_FIRSTNAME_FOR_TESTS+'second',
                LastName= CAO_Constants.CONTACT_LASTNAME_FOR_TESTS,
                npe01__Private__c=false,
                npe01__WorkEmail__c = CAO_Constants.CONTACT_EMAIL_FOR_TESTS, 
                npe01__Preferred_Email__c = CAO_Constants.CONTACT_PREFERRED_EMAIL_FOR_TESTS,
                npe01__WorkPhone__c = CAO_Constants.CONTACT_PHONE_FOR_TESTS,
                npe01__PreferredPhone__c = CAO_Constants.CONTACT_PREFERRED_PHONE_FOR_TESTS,
                npo02__household__c = con.npo02__household__c,
                AccountId = (strProcessor == CAO_Constants.HH_ACCOUNT_PROCESSOR ? con.AccountId : null)
            );
            insert Con2;

            Contact[] TestCons = new Contact[] {Con1}; 

            // create new opps
            Opportunity[] newOpps1 = UTIL_UnitTestData_TEST.OppsForContactList ( TestCons, null, UTIL_UnitTestData_TEST.getClosedWonStage(), datClose, 100 , giftRecordTypeNameForTests ,null);
            Opportunity[] newOpps2 = UTIL_UnitTestData_TEST.OppsForContactList ( TestCons, null, UTIL_UnitTestData_TEST.getClosedWonStage(), datClose.addYears(-2), 200 , giftRecordTypeNameForTests ,null);
            Opportunity[] newOpps3 = UTIL_UnitTestData_TEST.OppsForContactList ( TestCons, null, UTIL_UnitTestData_TEST.getClosedWonStage(), datClose.addYears(-3), 75 , giftRecordTypeNameForTests ,null);

            Opportunity[] testOpps = new Opportunity[0];
            testOpps.addAll (newOpps1);
            testOpps.addAll (newOpps2);
            testOpps.addAll (newOpps3);

            // insert the opp(s)
            Test.StartTest();
            insert testOpps;
            Test.StopTest();

            Contact c = [SELECT Id,npo02__Total_Household_Gifts__c,npo02__OppAmountThisYearHH__c,npo02__OppAmountLastYearHH__c,
                            npo02__LastCloseDateHH__c, npo02__Best_Gift_Year__c, npo02__Best_Gift_Year_Total__c, npo02__Household__r.npo02__Best_Gift_Year__c, npo02__Household__r.npo02__Best_Gift_Year_Total__c
                FROM Contact WHERE LastName=:CAO_Constants.CONTACT_LASTNAME_FOR_TESTS AND FirstName=:CAO_Constants.CONTACT_FIRSTNAME_FOR_TESTS+'second' LIMIT 1];
            System.assertEquals (375,c.npo02__Total_Household_Gifts__c);
            System.assertEquals (100,c.npo02__OppAmountThisYearHH__c);
            System.assertEquals (0,c.npo02__OppAmountLastYearHH__c);
            System.assertEquals (datClose,c.npo02__LastCloseDateHH__c );
            System.assertEquals (375,c.npo02__Total_Household_Gifts__c);
            System.assertEquals (null, c.npo02__Best_Gift_Year_Total__c); 
            System.assertEquals (null, c.npo02__Best_Gift_Year__c);
            System.assertEquals (string.valueof(datClose.addYears(-2).year()), c.npo02__household__r.npo02__Best_Gift_Year__c);
            System.assertEquals (200, c.npo02__household__r.npo02__Best_Gift_Year_Total__c);
    }

    static testMethod void testUserDefinedRollupOne2One(){
        if (strTestOnly != '*' && strTestOnly != 'testUserDefinedRollupOne2One') return;
        testUserDefinedRollup(CAO_Constants.ONE_TO_ONE_PROCESSOR);
    }
    static testMethod void testUserDefinedRollupHHAccount(){
        if (strTestOnly != '*' && strTestOnly != 'testUserDefinedRollupHHAccount') return;
        testUserDefinedRollup(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    }
    static void testUserDefinedRollup(string strProcessor) {

        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (
                npe01__Account_Processor__c = strProcessor,
                npe01__Enable_Opportunity_Contact_Role_Trigger__c = true,
                npe01__Opportunity_Contact_Role_Default_role__c = 'Donor'
        ));

        npo02__Households_Settings__c householdSettingsForTests = UTIL_CustomSettingsFacade.getHouseholdsSettingsForTests(
                new npo02__Households_Settings__c (
                    npo02__Household_Rules__c = HH_Households.ALL_PROCESSOR,
                    npo02__Always_Rollup_to_Primary_Contact__c = false,
                    npo02__Enable_Opp_Rollup_Triggers__c = true,
                    npo02__Excluded_Account_Opp_Rectypes__c = null,
                    npo02__Excluded_Account_Opp_Types__c = null,
                    npo02__Excluded_Contact_Opp_Rectypes__c = null,
                    npo02__Excluded_Contact_Opp_Types__c = null,
                    npo02__Membership_Record_Types__c = null
         ));
        //need to clear out any existing user fields
        //otherwise we can't insert of stuff referenced by apex
        delete [select id from npo02__User_Rollup_Field_Settings__c];

        list<npo02__User_Rollup_Field_Settings__c> testURFS = new list<npo02__User_Rollup_Field_Settings__c>();

        npo02__User_Rollup_Field_Settings__c testUserRollup1 = new npo02__User_Rollup_Field_Settings__c();
        testUserRollup1.npo02__Target_Field__c = 'Birthdate'; 
        testUserRollup1.npo02__Source_Field__c = 'CloseDate';
        testUserRollup1.npo02__Object_Name__c = 'Contact'; 
        testUserRollup1.npo02__Field_Action__c = 'MAX';
        testUserRollup1.Name = 'TestRollup8675309';
        testURFS.add(TestUserRollup1);

        npo02__User_Rollup_Field_Settings__c TestUserRollup2 = new npo02__User_Rollup_Field_Settings__c();
        testUserRollup2.npo02__Target_Field__c = 'NumberOfEmployees'; 
        testUserRollup2.npo02__Source_Field__c = 'FiscalYear';
        testUserRollup2.npo02__Object_Name__c = 'Account'; 
        testUserRollup2.npo02__Field_Action__c = 'MAX';
        testUserRollup2.Name = 'TestRollup2';
        testURFS.add(TestUserRollup2);

        npo02__User_Rollup_Field_Settings__c testUserRollup3 = new npo02__User_Rollup_Field_Settings__c();
        testUserRollup3.npo02__Target_Field__c = 'npo02__LastCloseDate__c'; 
        testUserRollup3.npo02__Source_Field__c = 'CloseDate';
        testUserRollup3.npo02__Object_Name__c = 'npo02__Household__c'; 
        testUserRollup3.npo02__Field_Action__c = 'MAX';
        testUserRollup3.Name = 'TestRollup3';
        testURFS.add(TestUserRollup3);

        insert testURFS; 

        Contact c = new Contact(LastName = 'Lastname', BirthDate = system.today().addDays(-4));
        insert c;

        id rtid = UTIL_RecordTypes.GetRecordTypeId ('Opportunity',UTIL_RecordTypes.getRecordTypeNameForGiftsTests('Opportunity'));
        Opportunity newOpp = New Opportunity (
                Name = 'Test Opp ',
                Amount = 100,
                CloseDate = system.today().adddays(-2),
                StageName = UTIL_UnitTestData_TEST.getClosedWonStage(),
                npe01__Contact_Id_for_Role__c = c.Id                                
            );  
            if(rtid != null){
                newOpp.put('RecordTypeId',rtid);
            }

        map<string, npo02__User_Rollup_Field_Settings__c> urfsMap = npo02__User_Rollup_Field_Settings__c.getAll();
        system.assertEquals(3, urfsMap.keySet().size());                    

        Test.StartTest();
        insert newOpp;
        Test.StopTest();

        Contact ct = [select Birthdate, npo02__OppAmountThisYearHH__c from Contact where id = :c.id];
        if (system.today().addDays(-4).year() == system.today().year())
            system.assertEquals (100,ct.npo02__OppAmountThisYearHH__c);
        system.assertEquals(system.today().addDays(-2), ct.BirthDate);
    }

    static testMethod void testMultiCurrencyMethodsOne2One(){
        if (strTestOnly != '*' && strTestOnly != 'testMultiCurrencyMethodsOne2One') return;
        testMultiCurrencyMethods(CAO_Constants.ONE_TO_ONE_PROCESSOR);
    }
    static testMethod void testMultiCurrencyMethodsHHAccount(){
        if (strTestOnly != '*' && strTestOnly != 'testMultiCurrencyMethodsHHAccount') return;
        testMultiCurrencyMethods(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    }
    static void testMultiCurrencyMethods(string strProcessor){
        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (
                npe01__Account_Processor__c = strProcessor,
                npe01__Enable_Opportunity_Contact_Role_Trigger__c = true,
                npe01__Opportunity_Contact_Role_Default_role__c = 'Donor'
        ));
        //exercise internal multicurrency helper methods, check currency conversion             
        decimal d = RLLP_OppRollup_UTIL.ConvertFromCorporate('USD', 55.00);      
        d = RLLP_OppRollup_UTIL.ConvertCurrency('USD', 'USD', 55.00);

        //create & insert second household member
        Contact Con = new contact(
                FirstName= CAO_Constants.CONTACT_FIRSTNAME_FOR_TESTS,
                LastName= CAO_Constants.CONTACT_LASTNAME_FOR_TESTS,
                npe01__Private__c=false,
                npe01__WorkEmail__c = CAO_Constants.CONTACT_EMAIL_FOR_TESTS, 
                npe01__Preferred_Email__c = CAO_Constants.CONTACT_PREFERRED_EMAIL_FOR_TESTS,
                npe01__WorkPhone__c = CAO_Constants.CONTACT_PHONE_FOR_TESTS,
                npe01__PreferredPhone__c = CAO_Constants.CONTACT_PREFERRED_PHONE_FOR_TESTS                
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

        RLLP_OppRollup opproll = new RLLP_OppRollup();
        map<Id, Opportunity> omap = RLLP_OppRollup_UTIL.rcfFindCurrency(sobjectList);

        // UNDONE: THERE ARE NO ASSERTS!!!!
    }

    static testMethod void testRollupAllsOne2One(){
        if (strTestOnly != '*' && strTestOnly != 'testRollupAllsOne2One') return;
        testRollupAlls(CAO_Constants.ONE_TO_ONE_PROCESSOR);
    }
    static testMethod void testRollupAllsHHAccount(){
        if (strTestOnly != '*' && strTestOnly != 'testRollupAllsHHAccount') return;
        testRollupAlls(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    }
    static void testRollupAlls(string strProcessor){
        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (
                npe01__Account_Processor__c = strProcessor,
                npe01__Enable_Opportunity_Contact_Role_Trigger__c = true,
                npe01__Opportunity_Contact_Role_Default_role__c = 'Donor'
        ));
        RLLP_OppRollup og = new RLLP_OppRollup();

        test.startTest();
        og.rollupAllContacts();
        og.rollupAllAccounts();     
        boolean x = RLLP_OppRollup_UTIL.isMultiCurrency();
        decimal y = RLLP_OppRollup_UTIL.ConvertFromCorporate('USD', 500.00);
        decimal z = RLLP_OppRollup_UTIL.ConvertCurrency('USD', 'USD', 6565.54);
        test.stopTest();

        // UNDONE: THERE ARE NO ASSERTRS!!!!
    }
    
    static testMethod void testFiscalYearandCustomNDayOne2One(){
        if (strTestOnly != '*' && strTestOnly != 'testFiscalYearandCustomNDayOne2One') return;
        testFiscalYearandCustomNDay(CAO_Constants.ONE_TO_ONE_PROCESSOR);
    }
    static testMethod void testFiscalYearandCustomNDayHHAccount(){
        if (strTestOnly != '*' && strTestOnly != 'testFiscalYearandCustomNDayHHAccount') return;
        testFiscalYearandCustomNDay(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    }    
    static void testFiscalYearandCustomNDay (string strProcessor) {

            npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (
                npe01__Account_Processor__c = strProcessor,
                npe01__Enable_Opportunity_Contact_Role_Trigger__c = true,
                npe01__Opportunity_Contact_Role_Default_role__c = 'Donor'
            ));

            npo02__Households_Settings__c householdSettingsForTests = UTIL_CustomSettingsFacade.getHouseholdsSettingsForTests(
                new npo02__Households_Settings__c (
                    npo02__Household_Rules__c = HH_Households.ALL_PROCESSOR,
                    npo02__Always_Rollup_to_Primary_Contact__c = false,
                    npo02__Enable_Opp_Rollup_Triggers__c = true,
                    npo02__Excluded_Account_Opp_Rectypes__c = null,
                    npo02__Excluded_Account_Opp_Types__c = null,
                    npo02__Excluded_Contact_Opp_Rectypes__c = null,
                    npo02__Excluded_Contact_Opp_Types__c = null,
                    npo02__Membership_Record_Types__c = null,                      
                    npo02__Use_Fiscal_Year_for_Rollups__c = true, 
                    npo02__rollup_N_Day_Value__c = 10,
                    npo02__Batch_Size__c = 200
                ));

            // for a single contact w/ no previous mbrships, add a new membership
            // and test mbr stats are created

            // create & insert contact(s)
            Contact[] TestCons = UTIL_UnitTestData_TEST.CreateMultipleTestContacts ( 1 ) ;
            insert TestCons;

            // create 2 new opps
            Opportunity[] newOpps1 = new Opportunity[0];

            Opportunity newOpp1 = new opportunity(npe01__Contact_Id_for_Role__c = TestCons[0].id,
                    name = 'test opp ', 
                    stagename = UTIL_UnitTestData_TEST.getClosedWonStage(), closedate = system.today(), amount = 100);
               if(RLLP_OppRollup_UTIL.areRecordTypesOnOpps())
                    newOpp1.put('RecordTypeId',UTIL_RecordTypes.GetRecordTypeId('Opportunity', giftRecordTypeNameForTests));
            newOpps1.add( newOpp1);

            Opportunity newOpp2 = new opportunity(npe01__Contact_Id_for_Role__c = TestCons[0].id,
                    name = 'test opp 2', 
                    stagename = UTIL_UnitTestData_TEST.getClosedWonStage(), closedate = system.today().adddays(-40), amount = 100);
               if(RLLP_OppRollup_UTIL.areRecordTypesOnOpps())
                    newOpp2.put('RecordTypeId',UTIL_RecordTypes.GetRecordTypeId('Opportunity', giftRecordTypeNameForTests));
            newOpps1.add(newOpp2);

            // insert the opp(s)
            Test.StartTest();
            insert newOpps1;
            Test.StopTest();

            system.assertEquals(100, [select npo02__OppAmountLastNDays__c from Contact where id = :TestCons[0].id].npo02__OppAmountLastNDays__c);
    }

    static testMethod void testSoftCreditsOne2One(){
        if (strTestOnly != '*' && strTestOnly != 'testSoftCreditsOne2One') return;
        testSoftCredits(CAO_Constants.ONE_TO_ONE_PROCESSOR);
    }
    static testMethod void testSoftCreditsHHAccount(){
        if (strTestOnly != '*' && strTestOnly != 'testSoftCreditsHHAccount') return;
        testSoftCredits(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    }
   static void testSoftCredits(string strProcessor) {

            npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (
                npe01__Account_Processor__c = strProcessor,
                npe01__Enable_Opportunity_Contact_Role_Trigger__c = true,
                npe01__Opportunity_Contact_Role_Default_role__c = 'Donor'
            ));

            npo02__Households_Settings__c householdSettingsForTests = UTIL_CustomSettingsFacade.getHouseholdsSettingsForTests(
                new npo02__Households_Settings__c (
                    npo02__Household_Rules__c = HH_Households.NO_HOUSEHOLDS_PROCESSOR,
                    npo02__Always_Rollup_to_Primary_Contact__c = false,
                    npo02__Enable_Opp_Rollup_Triggers__c = false,
                    npo02__Excluded_Account_Opp_Rectypes__c = null,
                    npo02__Excluded_Account_Opp_Types__c = null,
                    npo02__Excluded_Contact_Opp_Rectypes__c = null,
                    npo02__Excluded_Contact_Opp_Types__c = null,
                    npo02__Membership_Record_Types__c = null,
                    npo02__Enable_Soft_Credit_Rollups__c = true,
                    npo02__Soft_Credit_Roles__c = 'TestOCR',
                    npo02__Advanced_Household_Naming__c = false
                ));

            Date datClose = System.Today();

            // create & insert contact(s)
            Contact[] TestCons = UTIL_UnitTestData_TEST.CreateMultipleTestContacts(10) ;
            insert TestCons;

            // create new opps
            Opportunity[] newOpps = UTIL_UnitTestData_TEST.OppsForContactList ( TestCons, null, UTIL_UnitTestData_TEST.getClosedWonStage(), datClose, 1000 , giftRecordTypeNameForTests ,null);
            insert newOpps;

            account testacct = new account(name='testacct');
            insert testacct;

            Opportunity[] lastYearOpps = UTIL_UnitTestData_TEST.OppsForContactList(new list<Contact>{TestCons[5]}, null, UTIL_UnitTestData_TEST.getClosedWonStage(), datClose.addyears(-1), 150 , giftRecordTypeNameForTests ,null);
            insert lastYearOpps;

            Opportunity[] last2YearOpps = UTIL_UnitTestData_TEST.OppsForContactList(new list<Contact>{TestCons[8]}, null, UTIL_UnitTestData_TEST.getClosedWonStage(), datClose.addyears(-2), 100 , giftRecordTypeNameForTests ,null);
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
            RLLP_OppRollup rg = new RLLP_OppRollup();
            rg.rollupAll();
            Test.StopTest();

            Contact c1 = [select npo02__Soft_Credit_Two_Years_Ago__c, npo02__Soft_Credit_Total__c, 
                                npo02__Soft_Credit_This_Year__c, npo02__Soft_Credit_Last_Year__c From Contact where id = :TCid1];

            Contact c2 = [select npo02__Soft_Credit_Two_Years_Ago__c, npo02__Soft_Credit_Total__c, 
                                npo02__Soft_Credit_This_Year__c, npo02__Soft_Credit_Last_Year__c From Contact where id = :TCid2];                

            system.assertEquals(1150, c1.npo02__Soft_Credit_Total__c);
            system.assertEquals(1000, c1.npo02__Soft_Credit_This_Year__c);
            system.assertEquals(150, c1.npo02__Soft_Credit_Last_Year__c);
            system.assertEquals(1100, c2.npo02__Soft_Credit_Total__c);
            system.assertEquals(100, c2.npo02__Soft_Credit_Two_Years_Ago__c);
    }

    /*********************************************************************************************************
    operation:
        create Organizational Opportunities, with Soft Credit OCR's
    verify:
        soft credits correctly rollup to their appropriate contacts
    **********************************************************************************************************/            
    static testMethod void testOrgSoftCreditsOne2One(){
        if (strTestOnly != '*' && strTestOnly != 'testOrgSoftCreditsOne2One') return;
        testOrgSoftCredits(CAO_Constants.ONE_TO_ONE_PROCESSOR);
    }
    static testMethod void testOrgSoftCreditsHHAccount(){
        if (strTestOnly != '*' && strTestOnly != 'testOrgSoftCreditsHHAccount') return;
        testOrgSoftCredits(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    }
   static void testOrgSoftCredits(string strProcessor) {

            npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (
                npe01__Account_Processor__c = strProcessor,
                npe01__Enable_Opportunity_Contact_Role_Trigger__c = true,
                npe01__Opportunity_Contact_Role_Default_role__c = 'Donor'
            ));

            npo02__Households_Settings__c householdSettingsForTests = UTIL_CustomSettingsFacade.getHouseholdsSettingsForTests(
                new npo02__Households_Settings__c (
                    npo02__Household_Rules__c = HH_Households.NO_HOUSEHOLDS_PROCESSOR,
                    npo02__Always_Rollup_to_Primary_Contact__c = false,
                    npo02__Enable_Opp_Rollup_Triggers__c = false,
                    npo02__Excluded_Account_Opp_Rectypes__c = null,
                    npo02__Excluded_Account_Opp_Types__c = null,
                    npo02__Excluded_Contact_Opp_Rectypes__c = null,
                    npo02__Excluded_Contact_Opp_Types__c = null,
                    npo02__Membership_Record_Types__c = null,
                    npo02__Enable_Soft_Credit_Rollups__c = true,
                    npo02__Soft_Credit_Roles__c = 'TestOCR',
                    npo02__Advanced_Household_Naming__c = false
                ));

            Date datClose = System.Today();
            
            integer cTest = 5;

            // create & insert contact(s)
            list<Contact> listCon = UTIL_UnitTestData_TEST.CreateMultipleTestContacts(5) ;
            insert listCon;

            // create accounts
            list<Account> listAcc = new list<Account>();
            for (integer i = 0; i < cTest; i++) {
            	listAcc.add(new Account(name='Test Account' + string.valueOf(i), npe01__SYSTEMIsIndividual__c=false));
            }
            insert listAcc;
            listAcc = [select Id, Name, npe01__SYSTEMIsIndividual__c from Account where Name like 'Test Account%'];
            system.assertEquals(cTest, listAcc.size());
            system.assertEquals(false, listAcc[0].npe01__SYSTEMIsIndividual__c);
            
            // create new opps
            list<Opportunity> listOpp = UTIL_UnitTestData_TEST.OppsForAccountList(listAcc, null, UTIL_UnitTestData_TEST.getClosedWonStage(), datClose, 1000 , giftRecordTypeNameForTests ,null);
            insert listOpp;

            // create our soft credit ocr's
            list<OpportunityContactRole> listOCR = new list<OpportunityContactRole>();            
            for (integer i = 0; i < cTest; i++) {
            	listOCR.add(new OpportunityContactRole(ContactId=listCon[i].Id, OpportunityId=listOpp[i].Id, Role='TestOCR', IsPrimary=false));
            }
            insert listOCR;
            

            // test the batch rollup method
            Test.StartTest();
            RLLP_OppRollup rg = new RLLP_OppRollup();
            rg.rollupAll();
            Test.StopTest();

            // verify expected results
            listCon = [select Id, Name, npo02__Soft_Credit_Two_Years_Ago__c, npo02__Soft_Credit_Total__c, 
                                npo02__Soft_Credit_This_Year__c, npo02__Soft_Credit_Last_Year__c From Contact];

            for (Contact con : listCon) {
	            system.assertEquals(1000, con.npo02__Soft_Credit_Total__c);
	            system.assertEquals(1000, con.npo02__Soft_Credit_This_Year__c);
	            system.assertEquals(0, con.npo02__Soft_Credit_Last_Year__c);
	            system.assertEquals(0, con.npo02__Soft_Credit_Two_Years_Ago__c);
            }
    }
    
    static testMethod void testFutureMethodsOne2One(){
        if (strTestOnly != '*' && strTestOnly != 'testFutureMethodsOne2One') return;
        testFutureMethods(CAO_Constants.ONE_TO_ONE_PROCESSOR);
    }
    static testMethod void testFutureMethodsHHAccount(){
        if (strTestOnly != '*' && strTestOnly != 'testFutureMethodsHHAccount') return;
        testFutureMethods(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    }    
    static void testFutureMethods(string strProcessor){

            npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (
                npe01__Account_Processor__c = strProcessor,
                npe01__Enable_Opportunity_Contact_Role_Trigger__c = true,
                npe01__Opportunity_Contact_Role_Default_role__c = 'Donor'
            ));

            npo02__Households_Settings__c householdSettingsForTests = UTIL_CustomSettingsFacade.getHouseholdsSettingsForTests(
                new npo02__Households_Settings__c (
                    npo02__Household_Rules__c = HH_Households.ALL_PROCESSOR,
                    npo02__Always_Rollup_to_Primary_Contact__c = false,
                    npo02__Enable_Opp_Rollup_Triggers__c = false,
                    npo02__Excluded_Account_Opp_Rectypes__c = null,
                    npo02__Excluded_Account_Opp_Types__c = null,
                    npo02__Excluded_Contact_Opp_Rectypes__c = null,
                    npo02__Excluded_Contact_Opp_Types__c = null,
                    npo02__Membership_Record_Types__c = null,
                    npo02__Enable_Soft_Credit_Rollups__c = true,
                    npo02__Soft_Credit_Roles__c = 'TestOCR',
                    npo02__Advanced_Household_Naming__c = false
                ));

            Date datClose = System.Today();

        // create & insert contact(s)
        Contact[] TestCons = UTIL_UnitTestData_TEST.CreateMultipleTestContacts(10) ;
        insert TestCons;

        // create new opps
        Opportunity[] newOpps = UTIL_UnitTestData_TEST.OppsForContactList ( TestCons, null, UTIL_UnitTestData_TEST.getClosedWonStage(), datClose, 1000 , giftRecordTypeNameForTests ,null);
        insert newOpps;

        TestCons = [select id, npo02__Household__c from Contact where ID IN :TestCons];
        set<id> HHid = new set<id>();
        set<id> CID = new set<id>();

        for (Contact c : TestCons){
            HHid.add(c.npo02__household__c);
            CID.add(c.id);
        }

        Test.startTest();
        RLLP_OppRollup.rollupContactsFuture(CID);
        RLLP_OppRollup.rollupHouseholdsFuture(HHid);
        Test.stopTest();
    }

    static testMethod void testFYUtility(){
        if (strTestOnly != '*' && strTestOnly != 'testFYUtility') return;
        integer fy = RLLP_OppRollup_UTIL.getCurrentFY();
        system.assert(fy != null);      
    }

    static testMethod void testUDRChangeBehaviorOne2One(){
        if (strTestOnly != '*' && strTestOnly != 'testUDRChangeBehaviorOne2One') return;
        testUDRChangeBehavior(CAO_Constants.ONE_TO_ONE_PROCESSOR);
    }
    static testMethod void testUDRChangeBehaviorHHAccount(){
        if (strTestOnly != '*' && strTestOnly != 'testUDRChangeBehaviorHHAccount') return;
        testUDRChangeBehavior(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    }
    //a change to a UDR value should trigger a rollup
    static void testUDRChangeBehavior(string strProcessor){
        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (
                npe01__Account_Processor__c = strProcessor,
                npe01__Enable_Opportunity_Contact_Role_Trigger__c = true,
                npe01__Opportunity_Contact_Role_Default_role__c = 'Donor'
        ));

        npo02__Households_Settings__c householdSettingsForTests = UTIL_CustomSettingsFacade.getHouseholdsSettingsForTests(
                new npo02__Households_Settings__c (
                    npo02__Household_Rules__c = HH_Households.ALL_PROCESSOR,
                    npo02__Always_Rollup_to_Primary_Contact__c = false,
                    npo02__Enable_Opp_Rollup_Triggers__c = true,
                    npo02__Excluded_Account_Opp_Rectypes__c = null,
                    npo02__Excluded_Account_Opp_Types__c = null,
                    npo02__Excluded_Contact_Opp_Rectypes__c = null,
                    npo02__Excluded_Contact_Opp_Types__c = null,
                    npo02__Membership_Record_Types__c = null
         ));

        //need to clear out any existing user fields
        //otherwise we can't insert of stuff referenced by apex
        delete [select id from npo02__User_Rollup_Field_Settings__c];

        list<npo02__User_Rollup_Field_Settings__c> testURFS = new list<npo02__User_Rollup_Field_Settings__c>();

        npo02__User_Rollup_Field_Settings__c testUserRollup1 = new npo02__User_Rollup_Field_Settings__c();
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
        RLLP_OppRollup_UTIL oppRollupUtil = new RLLP_OppRollup_UTIL();
        String q = oppRollupUtil.buildContactQuery() + ' where id = \'' + c.id + '\'';

        c = database.query(q);

        id rtid = UTIL_RecordTypes.GetRecordTypeId ('Opportunity',UTIL_RecordTypes.getRecordTypeNameForGiftsTests('Opportunity'));
        Opportunity newOpp = New Opportunity (
                Name = 'Test Opp ',
                Amount = 100,
                CloseDate = system.today(),
                StageName = UTIL_UnitTestData_TEST.getClosedWonStage(),
                npe01__Contact_Id_for_Role__c = c.id,
                TotalOpportunityQuantity = 2
            );
            if(rtid != null){
                newOpp.put('RecordTypeId',rtid);
            }

        map<string, npo02__User_Rollup_Field_Settings__c> urfsMap = npo02__User_Rollup_Field_Settings__c.getAll();
        system.assertEquals(1, urfsMap.keySet().size());

        insert newOpp;
        RLLP_OppRollup og = new RLLP_OppRollup();
        Map<Id,Contact> cmap = new Map<Id,Contact>();
        Map<Id, npo02__Household__c> hmap = new Map<Id, npo02__Household__c>();
        q = oppRollupUtil.buildHouseholdQuery() + ' where id = \'' + c.npo02__Household__c + '\'';

        npo02__Household__c h =database.query(q); 
        cmap.put(c.id, c);
        hmap.put(h.id, h);
        og.rollupContacts(cmap);
        og.rollupHouseholds(hmap);

        Contact ct = [select npo02__TotalOppAmount__c, npo02__Household__r.npo02__Household_ID__c from Contact where id = :c.id];
        system.assertEquals (100,ct.npo02__TotalOppAmount__c);
        system.assertEquals(2, ct.npo02__Household__r.npo02__Household_ID__c);

        newOpp.TotalOpportunityQuantity = 4;

        //issue an update
        Test.startTest();
        update newOpp;
        Test.stopTest();

        ct = [select npo02__TotalOppAmount__c, npo02__Household__r.npo02__Household_ID__c from Contact where id = :c.id];
        system.assertEquals (100,ct.npo02__TotalOppAmount__c);
        system.assertEquals(4, ct.npo02__Household__r.npo02__Household_ID__c);
    }

    static testmethod void testOppRollupSchedule(){ 
        if (strTestOnly != '*' && strTestOnly != 'testOppRollupSchedule') return;
        Test.startTest(); 

        //Schedule the test job 
        insert new Schedulable__c(Name = 'test Opp Sched', Class_Name__c = 'RLLP_OppRollup_SCHED', Active__c = true);
        String jobId = System.schedule('Global Scheduler', '0 0 0 3 9 ? 2022', new UTIL_MasterSchedulable());

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