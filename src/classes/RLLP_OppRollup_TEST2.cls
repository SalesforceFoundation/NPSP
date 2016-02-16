/*
    Copyright (c) 2014 Salesforce.org
    All rights reserved.
    
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
    
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Salesforce.org nor the names of
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
* @author Salesforce.org
* @date 2014 
* @description test Class which holds test methods for common utilities, 
* such as detecting whether we are in a managed package, and some string helpers.
*/
@isTest
public with sharing class RLLP_OppRollup_TEST2 {

    // if you only want to run one test in this class, fill in its name here.
    // if you want to run all tests, then use '*'
    private static String strTestOnly = '*';
    
    static String giftRecordTypeNameForTests = UTIL_RecordTypes.getRecordTypeNameForGiftsTests('Opportunity');
    
    static testMethod void testOpportunityUtilityErrorHandlingOne2One() {
    	if (strTestOnly != '*' && strTestOnly != 'testOpportunityUtilityErrorHandlingOne2One') return;
        testOpportunityUtilityErrorHandling(CAO_Constants.ONE_TO_ONE_PROCESSOR);
    }
    static testMethod void testOpportunityUtilityErrorHandlingHHAccount() {
    	if (strTestOnly != '*' && strTestOnly != 'testOpportunityUtilityErrorHandlingHHAccount') return;
        testOpportunityUtilityErrorHandling(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    }
    static void testOpportunityUtilityErrorHandling(string strProcessor) {
    	
    	Error_Settings__c errorSettings = UTIL_CustomSettingsFacade.getErrorSettings();
    	errorSettings.Error_Notifications_On__c = false;
		if(!Test.isRunningTest())
		    upsert errorSettings;

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

        // create & insert contact(s)
        Contact[] TestCons = UTIL_UnitTestData_TEST.CreateMultipleTestContacts(10);
        insert TestCons;
        system.assert(TestCons[0].id != null);

        //create new opp with a missing required field (close date)
        Opportunity[] newOpps = UTIL_UnitTestData_TEST.OppsForContactList (TestCons, null, 
            UTIL_UnitTestData_TEST.getClosedWonStage(), null, 1000 , giftRecordTypeNameForTests ,null);

        Test.startTest();
        List<Database.Saveresult> sr = Database.insert(newOpps, false);
        Test.stopTest();
        
        //Verify no opps were inserted
        Integer oppsInserted = [select Count() from Opportunity];
        System.assertEquals(0, oppsInserted);

        /*Error records don't get created because the first time Database.insert runs all records fail to insert,
        and thus everything gets rolled back. We cannot control the validation failure, as this is controlled by the 
        platform. 
        List<Error__c> errors = [select Error_Type__c, Record_URL__c, Object_Type__c from Error__c];
        system.assertEquals(1, errors.size());
        Error__c ore = errors[0];
        system.assert(ore != null);
        system.assertEquals('Required Field Missing', ore.Error_Type__c);
        system.assert(ore.Record_URL__c.endsWith(TestCons[0].id));
        system.assertEquals('Opportunity', ore.Object_Type__c);*/
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

        map<string, npo02__User_Rollup_Field_Settings__c> urfsMap = UTIL_ListCustomSettingsFacade.getMapUserRollupFieldSettings();
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

    /**
     * @description For a given date, test to see if fiscal year is correctly calculated based on all combinations of org fiscal year settings
     */
    static testMethod void testGetFiscalYearForDate() {
        if (strTestOnly != '*' && strTestOnly != 'testGetFiscalYearForDate') return;

        Date targetDate = Date.newInstance(2014, 10, 1);

        // Target date is in fiscal year Jan 2014 through Dec 2014, year comes from start
        System.assertEquals(2014, RLLP_OppRollup_UTIL.getFiscalYearForDate(targetDate, 1, true));

        // Target date is in fiscal year Jan 2014 through Dec 2014, year comes from end
        System.assertEquals(2014, RLLP_OppRollup_UTIL.getFiscalYearForDate(targetDate, 1, false));

        // Target date is in fiscal year Feb 2014 through Jan 2015, year comes from start
        System.assertEquals(2014, RLLP_OppRollup_UTIL.getFiscalYearForDate(targetDate, 2, true));

        // Target date is in fiscal year Feb 2014 through Jan 2015, year comes from end
        System.assertEquals(2015, RLLP_OppRollup_UTIL.getFiscalYearForDate(targetDate, 2, false));

        // Target date is in fiscal year March 2014 through Feb 2015, year comes from start
        System.assertEquals(2014, RLLP_OppRollup_UTIL.getFiscalYearForDate(targetDate, 3, true));

        // Target date is in fiscal year March 2014 through Feb 2015, year comes from end
        System.assertEquals(2015, RLLP_OppRollup_UTIL.getFiscalYearForDate(targetDate, 3, false));

        // Target date is in fiscal year April 2014 through March 2015, year comes from start
        System.assertEquals(2014, RLLP_OppRollup_UTIL.getFiscalYearForDate(targetDate, 4, true));

        // Target date is in fiscal year April 2014 through March 2015, year comes from end
        System.assertEquals(2015, RLLP_OppRollup_UTIL.getFiscalYearForDate(targetDate, 4, false));

        // Target date is in fiscal year May 2014 through April 2015, year comes from start
        System.assertEquals(2014, RLLP_OppRollup_UTIL.getFiscalYearForDate(targetDate, 5, true));

        // Target date is in fiscal year May 2014 through April 2015, year comes from end
        System.assertEquals(2015, RLLP_OppRollup_UTIL.getFiscalYearForDate(targetDate, 5, false));

        // Target date is in fiscal year June 2014 through May 2015, year comes from start
        System.assertEquals(2014, RLLP_OppRollup_UTIL.getFiscalYearForDate(targetDate, 6, true));

        // Target date is in fiscal year June 2014 through May 2015, year comes from end
        System.assertEquals(2015, RLLP_OppRollup_UTIL.getFiscalYearForDate(targetDate, 6, false));

        // Target date is in fiscal year July 2014 through June 2015, year comes from start
        System.assertEquals(2014, RLLP_OppRollup_UTIL.getFiscalYearForDate(targetDate, 7, true));

        // Target date is in fiscal year July 2014 through June 2015, year comes from end
        System.assertEquals(2015, RLLP_OppRollup_UTIL.getFiscalYearForDate(targetDate, 7, false));

        // Target date is in fiscal year August 2014 through July 2015, year comes from start
        System.assertEquals(2014, RLLP_OppRollup_UTIL.getFiscalYearForDate(targetDate, 8, true));

        // Target date is in fiscal year August 2014 through July 2015, year comes from end
        System.assertEquals(2015, RLLP_OppRollup_UTIL.getFiscalYearForDate(targetDate, 8, false));

        // Target date is in fiscal year September 2014 through August 2015, year comes from start
        System.assertEquals(2014, RLLP_OppRollup_UTIL.getFiscalYearForDate(targetDate, 9, true));

        // Target date is in fiscal year September 2014 through August 2015, year comes from end
        System.assertEquals(2015, RLLP_OppRollup_UTIL.getFiscalYearForDate(targetDate, 9, false));

        // Target date is in fiscal year October 2014 through September 2015, year comes from start
        System.assertEquals(2014, RLLP_OppRollup_UTIL.getFiscalYearForDate(targetDate, 10, true));

        // Target date is in fiscal year October 2014 through September 2015, year comes from end
        System.assertEquals(2015, RLLP_OppRollup_UTIL.getFiscalYearForDate(targetDate, 10, false));

        // Target date is in fiscal year November 2013 through October 2014, year comes from start
        System.assertEquals(2013, RLLP_OppRollup_UTIL.getFiscalYearForDate(targetDate, 11, true));

        // Target date is in fiscal year November 2013 through October 2014, year comes from end
        System.assertEquals(2014, RLLP_OppRollup_UTIL.getFiscalYearForDate(targetDate, 11, false));

        // Target date is in fiscal year December 2013 through November 2014, year comes from start
        System.assertEquals(2013, RLLP_OppRollup_UTIL.getFiscalYearForDate(targetDate, 12, true));

        // Target date is in fiscal year December 2013 through November 2014, year comes from end
        System.assertEquals(2014, RLLP_OppRollup_UTIL.getFiscalYearForDate(targetDate, 12, false));
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

        map<string, npo02__User_Rollup_Field_Settings__c> urfsMap = UTIL_ListCustomSettingsFacade.getMapUserRollupFieldSettings();
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