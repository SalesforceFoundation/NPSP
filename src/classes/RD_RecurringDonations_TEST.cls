/*
    Copyright (c) 2012, Salesforce.org
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
* @date 2012 (2.0)
* @group Recurring Donations
* @description Test class for the RecurringDonations class
*/
@isTest
public class RD_RecurringDonations_TEST {

    public static final Date DEFAULT_ESTABLISHED_DATE = Date.newInstance(1970,6,12);
    private static final Date TODAY = System.today();

    /*******************************************************************************************************
    * @description test method for insertOpportunities function 
    */ 
    @isTest
    private static void insertOpportunities()
    {
        UTIL_Debug.debug('multiply: ' + System.Label.npe03.RecurringDonationMultiplyValue);
        UTIL_Debug.debug('divide: ' + System.Label.npe03.RecurringDonationDivideValue);
        Account a = buildAccount();
        insert a;
        
        Contact c = buildContact(a.Id);        
        insert c;
        
        //added to cover
        npe03__Custom_Field_Mapping__c cfm = new npe03__Custom_Field_Mapping__c(
            npe03__Recurring_Donation_Field__c = 'Name',
            npe03__Opportunity_Field__c = 'Description',
            Name = 'CFMName00001-Test'
        );
        insert cfm;

        npe03__Recurring_Donation__c r0 = buildRecurringDonationYearlyInstallment(null);
        r0.npe03__Installments__c = 3;
        try {
            insert r0;
        } catch (Exception e) {
            ERR_Handler.processError(e, ERR_Handler_API.Context.RD);
        }
        //insert should fail because there is no Contact
        System.assertEquals(null,r0.id);
        

        npe03__Recurring_Donation__c rd = buildRecurringDonationYearlyInstallment(c.Id); 
        insert rd;
        
        Opportunity[] installments1 = getOppsOrderByCloseDate(rd.id);
        System.assertEquals(2,installments1.size());
        System.assertEquals(100,installments1[0].Amount);
        System.assertEquals(DEFAULT_ESTABLISHED_DATE,installments1[0].CloseDate);
        System.assertEquals(a.id,installments1[0].AccountId);
        System.assertEquals(100,installments1[1].Amount);
        System.assertEquals(DEFAULT_ESTABLISHED_DATE.addYears(1),installments1[1].CloseDate);
        System.assertEquals(a.id,installments1[1].AccountId);
        System.assertNotEquals(null, installments1[0].Description);
        System.assertNotEquals(null, installments1[1].Description);
        UTIL_Debug.debug('****' + installments1);        
    }
    
    
    @isTest
    private static void insertWeeklyOpportunities() {
        Account a = buildAccount();
        insert a;
        
        Contact c = buildContact(a.Id);
        insert c;       

        npe03__Recurring_Donation__c rd = buildRecurringDonationWeeklyInstallment(c.Id);
        insert rd;
        
        Opportunity[] installments1 = getOppsOrderByCloseDate(rd.id);
        System.assertEquals(2,installments1.size());
        System.assertEquals(100,installments1[0].Amount);
        System.assertEquals(DEFAULT_ESTABLISHED_DATE,installments1[0].CloseDate);
        System.assertEquals(a.id,installments1[0].AccountId);
        System.assertEquals(100,installments1[1].Amount);
        System.assertEquals(DEFAULT_ESTABLISHED_DATE.addDays(7),installments1[1].CloseDate);
        System.assertEquals(a.id,installments1[1].AccountId);
    }
    
    
    @isTest
    private static void insertQuarterlyOpportunities() {
        Account a = buildAccount();
        insert a;
        
        Contact c = buildContact(a.Id);
        insert c;       

        npe03__Recurring_Donation__c rd = buildRecurringDonationQuarterlyInstallment(c.Id);
        insert rd;
        
        Opportunity[] installments1 = getOppsOrderByCloseDate(rd.id);
        System.assertEquals(2,installments1.size());
        System.assertEquals(100,installments1[0].Amount);
        System.assertEquals(DEFAULT_ESTABLISHED_DATE,installments1[0].CloseDate);
        System.assertEquals(a.id,installments1[0].AccountId);
        System.assertEquals(100,installments1[1].Amount);
        System.assertEquals(DEFAULT_ESTABLISHED_DATE.addMonths(3),installments1[1].CloseDate);
        System.assertEquals(a.id,installments1[1].AccountId);
    }
    
    
    @isTest
    private static void insertCampaignOpportunities() {
        UTIL_CustomSettingsFacade.getRecurringDonationsSettingsForTest(new npe03__Recurring_Donations_Settings__c());
        Account a = buildAccount();
        insert a;
        
        Contact c = buildContact(a.Id);
        insert c;       

        Campaign camp = new Campaign();
        camp.Name = 'test campaign';
        insert camp;

        npe03__Recurring_Donation__c rd = buildRecurringDonationWeeklyInstallment(c.Id);
        rd.npe03__Recurring_Donation_Campaign__c = camp.id;
        insert rd;
        
        Opportunity[] installments1 = getOppsOrderByCloseDate(rd.id);
        System.assertEquals(2,installments1.size());
        System.assertEquals(100,installments1[0].Amount);
        System.assertEquals(DEFAULT_ESTABLISHED_DATE,installments1[0].CloseDate);
        System.assertEquals(camp.id,installments1[0].CampaignId);
        System.assertEquals(a.id,installments1[0].AccountId);
        System.assertEquals(100,installments1[1].Amount);
        System.assertEquals(DEFAULT_ESTABLISHED_DATE.addDays(7),installments1[1].CloseDate);
        System.assertEquals(camp.id,installments1[0].CampaignId);
        System.assertEquals(a.id,installments1[1].AccountId);
    }
    
    
    @isTest
    private static void deleteRecurringDonation() {
        Account a = buildAccount();
        insert a;
        
        npe03__Recurring_Donation__c r2 = buildRecurringDonationMonthlyInstallment(null);
        r2.npe03__Installments__c = 3;
        r2.npe03__Organization__c = a.Id;
        r2.npe03__Date_Established__c = Date.newInstance(1970,6,30);
        r2.npe03__Schedule_Type__c = System.Label.npe03.RecurringDonationDivideValue;
        insert r2;
        
        Opportunity[] installments2 = getOpps(r2.id);
        System.assertEquals(3,installments2.size());
        System.assertEquals(33.33,installments2[0].Amount);
        System.assertEquals(Date.newInstance(1970,6,30),installments2[0].CloseDate);
        System.assertEquals(33.33,installments2[1].Amount);
        System.assertEquals(Date.newInstance(1970,7,30),installments2[1].CloseDate);
        System.assertEquals(33.34,installments2[2].Amount);
        System.assertEquals(Date.newInstance(1970,8,30),installments2[2].CloseDate);
        System.assertEquals(a.id,installments2[0].AccountId);
        UTIL_Debug.debug('**** '+installments2);

        delete r2;
        
        //delete should cascade related opps that aren't closed/won
        Opportunity[] installments3 = [select Amount, IsDeleted from Opportunity where IsDeleted=true ALL ROWS];
        System.assertEquals(3,installments3.size());
        System.assertEquals(33.33,installments3[0].Amount);

        undelete r2;

        installments3 = getOpps(r2.id);
        System.assertEquals(false,installments3[0].IsDeleted, 'Record should be undeleted.');
    }
    
    
    @isTest
    private static void contactRolesOnOppsBucket() {
        //skip the test if Advancement is installed - Bucket Account not supported in ADV
        if (ADV_PackageInfo_SVC.useAdv()) return;
        
        contactRolesOnOppsProcessor(CAO_Constants.BUCKET_PROCESSOR);
    }
    
    @isTest
    private static void contactRolesOnOppsOne2One() {
        contactRolesOnOppsProcessor(CAO_Constants.ONE_TO_ONE_PROCESSOR);
    }
    
    @isTest
    private static void contactRolesOnOppsHHAccount() {
        contactRolesOnOppsProcessor(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    }  

    private static void contactRolesOnOppsProcessor(String strProcessor) {
        UTIL_CustomSettingsFacade.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c(
            npe01__Account_Processor__c = strProcessor, 
            npe01__Opportunity_Contact_Role_Default_role__c = System.Label.npe03.RecurringDonationContactRole
        ));
            
        CAO_Constants.setIndividualAccountForTests(CAO_Constants.INDIVIDUAL_ACCOUNT_NAME_FOR_TESTS);
        
        Contact c = buildContact(null);
        insert c; 

        Test.startTest();
        npe03__Recurring_Donation__c rd = buildRecurringDonationWeeklyInstallment(c.Id);
        insert rd;
        Test.stopTest();

        OpportunityContactRole[] installmentCRs = [
            SELECT ContactId, OpportunityId, Role 
            FROM OpportunityContactRole 
            WHERE Opportunity.npe03__Recurring_Donation__c = :rd.id
        ];
        System.assertEquals(2,installmentCRs.size());
        System.assertEquals(System.Label.npe03.RecurringDonationContactRole, installmentCRs[0].Role);
    }

    /*********************************************************************************************************
    @description 
        Verify Primary Opportunity Contact Roles (OCRs) creation using oppContactRoles().
        NOTE: Test the method even though it has not been used since NPSP3 which always 
        leverages npe01__Contact_Id_for_Role__c field on Opportunity instead of calling this method. 
    verify:
        - New Primary OCRs are created for provided Opportunities having Recurring Donations 
        with a specified Contact. 
    **********************************************************************************************************/ 
    @isTest
    private static void testOppContactRoleMethod() {
        UTIL_CustomSettingsFacade.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c(
            npe01__Account_Processor__c = CAO_Constants.HH_ACCOUNT_PROCESSOR, 
            npe01__Opportunity_Contact_Role_Default_role__c = System.Label.npe03.RecurringDonationContactRole
        ));
            
        CAO_Constants.setIndividualAccountForTests(CAO_Constants.INDIVIDUAL_ACCOUNT_NAME_FOR_TESTS);

        List<Contact> contacts = UTIL_UnitTestData_TEST.createMultipleTestContacts(3);
        insert contacts;
        contacts = new List<Contact>([SELECT LastName, AccountId FROM Contact]);

        List<npe03__Recurring_Donation__c> rds = new List<npe03__Recurring_Donation__c>();
        for (Contact c : contacts) {
            rds.add(new npe03__Recurring_Donation__c(
                Name = 'Test' + c.LastName,
                npe03__Amount__c = 100,
                npe03__Installment_Period__c = System.Label.npe03.RecurringDonationInstallmentPeriodYearly,
                npe03__Date_Established__c = DEFAULT_ESTABLISHED_DATE,
                npe03__Schedule_Type__c = System.Label.npe03.RecurringDonationMultiplyValue,
                npe03__Contact__c = c.Id
            ));
        }

        // Execute the insert of Recurring Donations in start/stop Test to create Primary OCRs 
        // by utilizing npe01__Contact_Id_for_Role__c field on Opportunity if it exists. 
        // Otherwise, the Recurring Donations code should execute oppContactRoles() instead.
        Test.startTest();
        insert rds;
        Test.stopTest();

        List<Opportunity> opps = getOpps(rds);

        opps.add(new Opportunity(
            Amount = 200,
            AccountId = contacts[0].AccountId,
            Name = 'Test Opp',
            StageName = UTIL_UnitTestData_TEST.getClosedWonStage(),
            CloseDate = TODAY,
            npe03__Recurring_Donation__c = rds[0].Id
        ));
        upsert opps;

        Set<Id> oppIds = new Map<Id, Opportunity>(opps).keySet();
        Set<Id> rdIds = new Map<Id, npe03__Recurring_Donation__c>(rds).keySet();

        delete getPrimaryOppContactRoles(rdIds);
        System.assertEquals(0, getPrimaryOppContactRoles(rdIds).size(), 'OCRs should be deleted if created');

        RD_RecurringDonations.oppContactRoles(oppIds);

        System.assertEquals(opps.size(), getPrimaryOppContactRoles(rdIds).size(), 'OCR should be created for each Opportunity');

        // Execute the method again and ensure no duplicate OCR is created
        RD_RecurringDonations.oppContactRoles(oppIds);
        System.assertEquals(opps.size(), getPrimaryOppContactRoles(rdIds).size(), 'No new OCR should be created when oppContactRoles() is called once more');
    }

    /*********************************************************************************************************
    @description 
        Verify Primary Opportunity Contact Roles (OCRs) are not created by oppContactRoles() 
        for Opportunities having "Disable Contact Role Automation" checked.
        NOTE: Test the method even though it has not been used since NPSP3 which always 
        leverages npe01__Contact_Id_for_Role__c field on Opportunity instead of calling this method. 
    **********************************************************************************************************/ 
    @isTest
    private static void shouldNotCreatePrimaryOcrsForRecurringDonationOppsWithDisableContactRoleAutomation() {
        UTIL_CustomSettingsFacade.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c(
            npe01__Account_Processor__c = CAO_Constants.HH_ACCOUNT_PROCESSOR, 
            npe01__Opportunity_Contact_Role_Default_role__c = System.Label.npe03.RecurringDonationContactRole
        ));
            
        CAO_Constants.setIndividualAccountForTests(CAO_Constants.INDIVIDUAL_ACCOUNT_NAME_FOR_TESTS);

        List<Contact> contacts = UTIL_UnitTestData_TEST.createMultipleTestContacts(2);
        insert contacts;
        contacts = [SELECT LastName, AccountId FROM Contact WHERE Id IN :contacts];

        List<npe03__Recurring_Donation__c> rds = new List<npe03__Recurring_Donation__c>();
        for (Contact c : contacts) {
            rds.add(new npe03__Recurring_Donation__c(
                Name = 'Test' + c.LastName,
                npe03__Amount__c = 100,
                npe03__Installment_Period__c = System.Label.npe03.RecurringDonationInstallmentPeriodYearly,
                npe03__Date_Established__c = Date.newInstance(1970, 6, 12),
                npe03__Schedule_Type__c = System.Label.npe03.RecurringDonationMultiplyValue,
                npe03__Contact__c = c.Id
            ));
        }

        // Execute the insert of Recurring Donations in start/stop Test to create Primary OCRs 
        // by utilizing npe01__Contact_Id_for_Role__c field on Opportunity if it exists. 
        // Otherwise, the Recurring Donations code should execute oppContactRoles() instead.
        Test.startTest();
        insert rds;
        Test.stopTest();

        List<Opportunity> opps = new List<Opportunity>([
            SELECT Id, Name
            FROM Opportunity
            WHERE npe03__Recurring_Donation__c IN :rds
        ]);

        opps.add(new Opportunity(
            Amount = 200,
            AccountId = contacts[0].AccountId,
            Name = 'Test Opp',
            StageName = UTIL_UnitTestData_TEST.getClosedWonStage(),
            CloseDate = System.today(),
            npe03__Recurring_Donation__c = rds[0].Id,
            DisableContactRoleAutomation__c = true
        ));
        upsert opps;

        Set<Id> oppIds = new Map<Id, Opportunity>(opps).keySet();
        Set<Id> rdIds = new Map<Id, npe03__Recurring_Donation__c>(rds).keySet();

        delete getPrimaryOppContactRoles(rdIds);
        System.assertEquals(0, getPrimaryOppContactRoles(rdIds).size(), 'OCRs should be deleted if created');

        RD_RecurringDonations.oppContactRoles(oppIds);

        System.assertEquals(opps.size() - 1, getPrimaryOppContactRoles(rdIds).size(), 'OCRs should not be created for Opp with Disable Contact Role Automation');

        // Execute the method again and ensure no duplicate OCR is created
        RD_RecurringDonations.oppContactRoles(oppIds);
        System.assertEquals(opps.size() - 1, getPrimaryOppContactRoles(rdIds).size(), 'OCRs should not be created for Opp with Disable Contact Role Automation');
    }
    
    
    @isTest
    private static void testSettingsCreation() {
        delete [select id from npe03__Recurring_Donations_Settings__c];

        //Using the API class just to give it test coverage.
        npe03__Recurring_Donations_Settings__c rds = UTIL_CustomSettings_API.getRecurringDonationsSettings();
        System.assertEquals(12, rds.npe03__Opportunity_Forecast_Months__c);
        System.assertEquals(50, rds.npe03__Maximum_Donations__c);
        System.assertEquals(RD_RecurringDonations.RecurringDonationCloseOptions.Mark_Opportunities_Closed_Lost.name(), rds.npe03__Open_Opportunity_Behavior__c);           
    }
    
    
    //tests inserts of various types of open ended donations
    @isTest
    private static void insertOpenEndedRecurringDonations(){
        createRdSettingsWithYearForecast();             
        
        Account a = buildAccount();
        insert a;
        
        Contact c = buildContact(a.Id);
        insert c;       
        
        Campaign camp = new Campaign(Name = 'Campaign', isActive = true);
        insert camp;
        
        List<npe03__Recurring_Donation__c> rdlist = new List<npe03__Recurring_Donation__c>();
        
        npe03__Recurring_Donation__c rd = new npe03__Recurring_Donation__c();
        rd.Name = 'testweekly';
        rd.npe03__Contact__c = c.Id;
        rd.npe03__Amount__c = 100;
        rd.npe03__Installment_Period__c = system.label.npe03.RecurringDonationInstallmentPeriodWeekly;
        rd.npe03__Date_Established__c = TODAY.toStartOfMonth();
        rd.npe03__Open_Ended_Status__c = System.Label.npe03.RecurringDonationOpenStatus;
        rdlist.add(rd);
        
        
        rd = rd.clone(false);
        rd.Name = 'testmonthly';
        rd.npe03__Installment_Period__c = System.Label.npe03.RecurringDonationInstallmentPeriodMonthly;
        rd.npe03__Contact__c = null;
        rd.npe03__Organization__c = a.id;
        rd.npe03__Recurring_Donation_Campaign__c = camp.id;
        rdlist.add(rd);
        
        rd = rd.clone(false);
        rd.Name = 'testquarterly';
        rd.npe03__Installment_Period__c = System.Label.npe03.RecurringDonationInstallmentPeriodQuarterly;
        rdlist.add(rd);
        
        rd = rd.clone(false);
        rd.Name = 'testyearly';
        rd.npe03__Installment_Period__c = System.Label.npe03.RecurringDonationInstallmentPeriodYearly;
        rdlist.add(rd);
        
        rd = rd.clone(false);
        rd.Name = 'testbadinstallment';
        rd.npe03__Installment_Period__c = 'GarbageValue';
        rdlist.add(rd);
        
        test.startTest();
        insert rdlist;
        test.stopTest();
        
        System.assertEquals(12, [select count() from Opportunity where npe03__Recurring_Donation__r.Name = 'testmonthly']);
        System.assertEquals(4, [select count() from Opportunity where npe03__Recurring_Donation__r.Name = 'testquarterly']);
        System.assertEquals(1, [select count() from Opportunity where npe03__Recurring_Donation__r.Name = 'testyearly']);
        Integer cOpp =  [select count() from Opportunity where npe03__Recurring_Donation__r.Name = 'testweekly'];
        System.assert(cOpp == 52 || cOpp == 53);        
    }
    
    
    @isTest
    private static void updateOpenEndedRecurringDonationMonthly(){
        createRdSettingsWithYearForecast();           
        
        Account a = buildAccount();
        insert a;
        
        Contact c = buildContact(a.Id);
        insert c;       

        npe03__Recurring_Donation__c rd = buildRecurringDonationWeeklyInstallment(c.Id);
        rd.npe03__Open_Ended_Status__c = System.Label.npe03.RecurringDonationOpenStatus;
        rd.npe03__Next_Payment_Date__c = TODAY.toStartOfMonth();
        insert rd;
        
        List<Opportunity> originalOpps = getOppsOrderByCloseDate(rd.id); 
        
        Integer cOpp =  originalOpps.size();
        System.assert(cOpp == 52 || cOpp == 53);        
        System.assertEquals(100, originalOpps[0].Amount);

        Test.startTest();
        rd.npe03__Installment_Period__c = System.Label.npe03.RecurringDonationInstallmentPeriodMonthly;
        update rd;
        Test.stopTest();
        
        System.assertEquals(12, getOppsOrderByCloseDate(rd.id).size());    
    }
    
    @isTest
    private static void updateOpenEndedRecurringDonation1an15(){
        createRdSettingsCampaignWithYearForecast();      
        
        Account a = buildAccount();
        insert a;
        
        Contact c = buildContact(a.Id);
        insert c;       

        npe03__Recurring_Donation__c rd = buildRecurringDonation(
            c.Id, System.Label.npe03.RecurringDonationInstallmentPeriod1stand15th
        );
        rd.npe03__Open_Ended_Status__c = System.Label.npe03.RecurringDonationOpenStatus;
        rd.npe03__Next_Payment_Date__c = TODAY;
       
        Test.startTest();
        insert rd;
        Test.stopTest();

        List<Opportunity> originalOpps = getOppsOrderByCloseDate(rd.id);          
        Integer cOpp =  originalOpps.size();
        System.assert(cOpp == 23 || cOpp == 24);        
        System.assertEquals(100, originalOpps[0].Amount);        
    }
    
    
    @isTest
    private static void updateOpenEndedRecurringDonationYearly(){
        createRdSettingsWithYearForecast();           
        
        Account a = buildAccount();
        insert a;
        
        Contact c = buildContact(a.Id);
        insert c;       

        npe03__Recurring_Donation__c rd = buildRecurringDonationWeeklyInstallment(c.Id);
        rd.npe03__Open_Ended_Status__c = System.Label.npe03.RecurringDonationOpenStatus;
        rd.npe03__Next_Payment_Date__c = TODAY.toStartOfMonth();
        insert rd;
        
        List<Opportunity> originalOpps = getOppsOrderByCloseDate(rd.id);          
        
        Integer cOpp =  originalOpps.size();
        System.assert(cOpp == 52 || cOpp == 53);        
        System.assertEquals(100, originalOpps[0].Amount);

        Test.startTest();
        rd.npe03__Installment_Period__c = System.Label.npe03.RecurringDonationInstallmentPeriodYearly;
        update rd;
        Test.stopTest();
        
        System.assertEquals(1, getOppsOrderByCloseDate(rd.id).size());
    }
    
    @isTest
    private static void updateOpenEndedRecurringDonationWeekly(){
        createRdSettingsWithYearForecast();           
        
        Account a = buildAccount();
        insert a;
        
        Contact c = buildContact(a.Id);
        insert c;       

        npe03__Recurring_Donation__c rd = buildRecurringDonationMonthlyInstallment(c.Id);
        rd.npe03__Open_Ended_Status__c = System.Label.npe03.RecurringDonationOpenStatus;
        rd.npe03__Next_Payment_Date__c = TODAY.toStartOfMonth();
        insert rd;
        
        List<Opportunity> originalOpps = getOppsOrderByCloseDate(rd.id);    
        
        System.assertEquals(12, originalOpps.size());
        System.assertEquals(100, originalOpps[0].Amount);

        Test.startTest();
        rd.npe03__Installment_Period__c = System.Label.npe03.RecurringDonationInstallmentPeriodWeekly;
        update rd;
        Test.stopTest(); 

        Integer cOpp = getOppsOrderByCloseDate(rd.id).size();
        System.assert(cOpp == 52 || cOpp == 53);        
    }
    
    
    @isTest
    private static void updateOpenEndedRecurringDonationQuarterly(){
        createRdSettingsWithYearForecast();           
        
        Account a = buildAccount();
        insert a;
        
        Contact c = buildContact(a.Id);
        insert c;       

        npe03__Recurring_Donation__c rd = buildRecurringDonationWeeklyInstallment(c.Id);
        rd.npe03__Open_Ended_Status__c = System.Label.npe03.RecurringDonationOpenStatus;
        rd.npe03__Next_Payment_Date__c = TODAY.toStartOfMonth();
        insert rd;
        
        List<Opportunity> originalOpps = getOppsOrderByCloseDate(rd.id);          
        
        Integer cOpp =  originalOpps.size();
        System.assert(cOpp == 52 || cOpp == 53);        
        System.assertEquals(100, originalOpps[0].Amount);
        Test.startTest();
        rd.npe03__Installment_Period__c = System.Label.npe03.RecurringDonationInstallmentPeriodQuarterly;
        update rd;
        Test.stopTest();
        
        System.assertEquals(4, getOppsOrderByCloseDate(rd.id).size());
    }    
        
    //test closing an opportunity for an open recurring donation
    @isTest
    private static void closeOppForOpenEndedRecurringDonationWeekly(){
        createRdSettingsWithYearForecast();           
        
        Account a = buildAccount();
        insert a;
        
        Contact c = buildContact(a.Id);
        insert c;       

        npe03__Recurring_Donation__c rd = buildRecurringDonationWeeklyInstallment(c.Id);
        rd.npe03__Open_Ended_Status__c = System.Label.npe03.RecurringDonationOpenStatus;
        rd.npe03__Next_Payment_Date__c = TODAY.toStartOfMonth();
        rd.OwnerId = system.Userinfo.getUserId();
        insert rd;
        
        List<Opportunity> originalOpps = getOppsOrderByCloseDate(rd.id);
        Integer cOpp =  originalOpps.size();
        System.assert(cOpp == 52 || cOpp == 53);        
        
        Opportunity o = originalOpps[0];
        o.StageName = UTIL_UnitTestData_TEST.getClosedWonStage();
        o.CloseDate = TODAY;

        Test.startTest();
        update o;
        RD_RecurringDonations.evaluateRecurringDonationsForNewOppInsert(new List<npe03__Recurring_Donation__c>{rd});
        Test.stopTest();        
        
        rd = getRecurringDonation(rd.id);     
        System.assertEquals(cOpp - 1, getOpenOppCount(rd.id));
        System.assertEquals(TODAY, rd.npe03__Last_Payment_Date__c);
    }
    //test closing an opportunity for an open recurring donation
    @isTest
    private static void closeOppForOpenEndedRecurringDonationMonthly(){
        createRdSettingsWithForecast(6);           
        
        Account a = buildAccount();
        insert a;
        
        Contact c = buildContact(a.Id);
        insert c;       

        npe03__Recurring_Donation__c rd = buildRecurringDonationYearlyInstallment(c.Id);
        rd.npe03__Open_Ended_Status__c = System.Label.npe03.RecurringDonationOpenStatus;
        rd.npe03__Next_Payment_Date__c = TODAY;
        rd.OwnerId = system.Userinfo.getUserId();
        insert rd; 
        
        System.assertNotEquals(null, rd.id);
        List<Opportunity> originalOpps = getOppsOrderByCloseDate(rd.id);
        System.assertEquals(1, originalOpps.size());          
        
        Opportunity o1 = originalOpps[0];
        o1.StageName = UTIL_UnitTestData_TEST.getClosedWonStage();
        o1.CloseDate = TODAY;
        List<Opportunity> oppList = new List<Opportunity>{o1};

        Test.startTest();
        update oppList;
        RD_RecurringDonations.evaluateRecurringDonationsForNewOppInsert(new List<npe03__Recurring_Donation__c>{rd});
        Test.stopTest();
        
        rd = getRecurringDonation(rd.id);    
        System.assertEquals(TODAY, rd.npe03__Last_Payment_Date__c);

        originalOpps = new List<Opportunity>([select id, Name,amount,accountid,CloseDate from Opportunity where isClosed = false and npe03__Recurring_Donation__r.id = :rd.id]);
        System.assertEquals(0, originalOpps.size());          
    }
    
    //test closing an opportunity for an open recurring donation
    @isTest
    private static void closeOppForOpenEndedRecurringDonationQuarterly(){
        createRdSettingsWithYearForecast();           
        
        Account a = buildAccount();
        insert a;
        
        Contact c = buildContact(a.Id);
        insert c;       

        npe03__Recurring_Donation__c rd = buildRecurringDonationQuarterlyInstallment(c.Id);
        rd.npe03__Open_Ended_Status__c = System.Label.npe03.RecurringDonationOpenStatus;
        rd.npe03__Next_Payment_Date__c = TODAY.toStartOfMonth();
        rd.OwnerId = system.Userinfo.getUserId();
        insert rd;
        
        List<Opportunity> originalOpps = getOppsOrderByCloseDate(rd.id);
        System.assertEquals(4, originalOpps.size());          
        
        Opportunity o = originalOpps[0];
        system.debug('**** DJH gonna close opp with date: ' + o.CloseDate);
        System.assertEquals(TODAY.toStartOfMonth(), o.CloseDate);
        o.StageName = UTIL_UnitTestData_TEST.getClosedWonStage();
        o.CloseDate = TODAY;

        Test.startTest();
        update o;
        RD_RecurringDonations.evaluateRecurringDonationsForNewOppInsert(new List<npe03__Recurring_Donation__c>{rd});
        Test.stopTest();
                
        rd = getRecurringDonation(rd.id); 
        System.assertEquals(TODAY, rd.npe03__Last_Payment_Date__c);
        System.assertEquals(3, getOpenOppCount(rd.id));        
    }
    
    //test closing an opportunity for an open recurring donation
    @isTest
    private static void closeOppForOpenEndedRecurringDonationCustomWeeks(){
        createRdSettingsWithYearForecast();           
        
        Account a = buildAccount();
        insert a;
        
        Contact c = buildContact(a.Id);
        insert c;       

        npe03__Custom_Installment_Settings__c customInstallment = new npe03__Custom_Installment_Settings__c(
            npe03__Increment__c = 'Weeks',
            npe03__Value__c = 2,
            Name = 'TESTCIS'     
        );
        insert customInstallment;        

        npe03__Recurring_Donation__c rd = buildRecurringDonation(null, customInstallment.Name);
        rd.npe03__Organization__c = a.id;
        rd.npe03__Open_Ended_Status__c = System.Label.npe03.RecurringDonationOpenStatus;
        rd.npe03__Next_Payment_Date__c = TODAY.toStartOfMonth();
        rd.OwnerId = system.Userinfo.getUserId();
        insert rd;
        
        List<Opportunity> originalOpps = getOppsOrderByCloseDate(rd.id);
        Integer cOpp = originalOpps.size();
        System.assert(cOpp == 26 || cOpp == 27);          
        
        Opportunity o = originalOpps[0];
        o.StageName = UTIL_UnitTestData_TEST.getClosedWonStage();
        o.CloseDate = TODAY;

        Test.startTest();
        update o;
        RD_RecurringDonations.evaluateRecurringDonationsForNewOppInsert(new List<npe03__Recurring_Donation__c>{rd});
        Test.stopTest();        
        
        rd = getRecurringDonation(rd.id);
        System.assert(26 <= getOpenOppCount(rd.id));
        System.assertEquals(TODAY, rd.npe03__Last_Payment_Date__c);
    }
    
    //test closing an opportunity for an open recurring donation
    @isTest
    private static void closeOppForOpenEndedRecurringDonationCustomDays(){
        createRdSettingsWithForecast(1);           
        
        Account a = buildAccount();
        insert a;
        
        Contact c = buildContact(a.Id);
        insert c;       

        npe03__Custom_Installment_Settings__c customInstallment = new npe03__Custom_Installment_Settings__c(
            npe03__Increment__c = 'Days',
            npe03__Value__c = 2,
            Name = 'TESTCIS'        
        );
        insert customInstallment;        

        npe03__Recurring_Donation__c rd = buildRecurringDonation(null, customInstallment.Name);
        rd.npe03__Organization__c = a.id;
        rd.npe03__Open_Ended_Status__c = System.Label.npe03.RecurringDonationOpenStatus;
        rd.npe03__Next_Payment_Date__c = TODAY.toStartOfMonth();
        insert rd;
        
        List<Opportunity> originalOpps = getOppsOrderByCloseDate(rd.id);
        Integer cOpp =  originalOpps.size();
        System.assert(cOpp == 14 || cOpp == 15 || cOpp == 16);        
        
        Opportunity o = originalOpps[0];
        o.StageName = UTIL_UnitTestData_TEST.getClosedWonStage();
        o.CloseDate = TODAY;

        Test.startTest();
        update o;       
        Test.stopTest();        
        
        rd = getRecurringDonation(rd.id);  
        System.assertEquals(cOpp - 1,getOpenOppCount(rd.id));
        System.assertEquals(TODAY, rd.npe03__Last_Payment_Date__c);
    }
    
    //test closing an opportunity for an open recurring donation
    @isTest
    private static void closeOppForOpenEndedRecurringDonationCustomMonths(){
        createRdSettingsCampaignWithYearForecast();           
        
        Account a = buildAccount();
        insert a;
        
        Contact c = buildContact(a.Id);
        insert c;       

        npe03__Custom_Installment_Settings__c customInstallment = new npe03__Custom_Installment_Settings__c(
            npe03__Increment__c = 'Months',
            npe03__Value__c = 2,
            Name = 'TESTCIS'      
        );
        insert customInstallment;        

        npe03__Recurring_Donation__c rd = buildRecurringDonation(null, customInstallment.Name);
        rd.npe03__Organization__c = a.id;
        rd.npe03__Date_Established__c = Date.newInstance(2000,1,1);
        rd.npe03__Open_Ended_Status__c = System.Label.npe03.RecurringDonationOpenStatus;
        rd.npe03__Next_Payment_Date__c = TODAY.toStartOfMonth();
        rd.OwnerId = system.Userinfo.getUserId();
        insert rd;
        
        List<Opportunity> originalOpps = getOppsOrderByCloseDate(rd.id);
        System.assertEquals(6, originalOpps.size());          
        
        Opportunity o = originalOpps[0];
        o.StageName = UTIL_UnitTestData_TEST.getClosedWonStage();
        o.CloseDate = TODAY;

        Test.startTest();
        update o;
        RD_RecurringDonations.evaluateRecurringDonationsForNewOppInsert(new List<npe03__Recurring_Donation__c>{rd});
        Test.stopTest();        
        
        rd = getRecurringDonation(rd.id);     
        System.assertEquals(5, getOpenOppCount(rd.id));
        System.assertEquals(TODAY, rd.npe03__Last_Payment_Date__c);
    }

    //test closing an opportunity for an open recurring donation
    @isTest
    private static void closeOppForOpenEndedRecurringDonationCustomYears(){
        createRdSettingsCampaignWithYearForecast();      
        
        Account a = buildAccount();
        insert a;
        
        Contact c = buildContact(a.Id);
        insert c;       

        npe03__Custom_Installment_Settings__c customInstallment = new npe03__Custom_Installment_Settings__c(
            npe03__Increment__c = 'Years',
            npe03__Value__c = 2,
            Name = 'TESTCIS'        
        );
        insert customInstallment;        

        npe03__Recurring_Donation__c rd = buildRecurringDonation(null, customInstallment.Name);
        rd.npe03__Organization__c = a.id;
        rd.npe03__Open_Ended_Status__c = System.Label.npe03.RecurringDonationOpenStatus;
        rd.npe03__Next_Payment_Date__c = TODAY;
        rd.OwnerId = system.Userinfo.getUserId();
        insert rd;
        
        List<Opportunity> originalOpps = getOppsOrderByCloseDate(rd.id);
        System.assertEquals(1, originalOpps.size());          
        
        Opportunity o = originalOpps[0];
        o.StageName = UTIL_UnitTestData_TEST.getClosedWonStage();
        o.CloseDate = TODAY;

        Test.startTest();
        update o;
        RD_RecurringDonations.evaluateRecurringDonationsForNewOppInsert(new List<npe03__Recurring_Donation__c>{rd});
        Test.stopTest();        
        
        rd = getRecurringDonation(rd.id);     
        System.assertEquals(0, getOpenOppCount(rd.id));
        System.assertEquals(TODAY, rd.npe03__Last_Payment_Date__c);
    }

    // Helpers
    ////////////

    /*******************************************************************************************************
    * @description Builds an account record with default values
    * @return Account
    */
    public static Account buildAccount() {
        return new Account(Name = 'test Individual');
    }

    /*******************************************************************************************************
    * @description Builds a contact record with default values
    * @param accId Id of the account to assign to the contact
    * @return Contact
    */
    public static Contact buildContact(Id accId) {
        return new Contact(
            FirstName = 'test',
            LastName = 'contact',
            AccountId = accId
        );  
    }

    /*******************************************************************************************************
    * @description Builds a recurring donation with yearly installment
    * @param contactId Id of the contact to assign to the recurring donation
    * @return npe03__Recurring_Donation__c
    */
    public static npe03__Recurring_Donation__c buildRecurringDonationYearlyInstallment(Id contactId) {
        return buildRecurringDonation(contactId, System.Label.npe03.RecurringDonationInstallmentPeriodYearly);
    }

    /*******************************************************************************************************
    * @description Builds a recurring donation with quarterly installment
    * @param contactId Id of the contact to assign to the recurring donation
    * @return npe03__Recurring_Donation__c
    */
    public static npe03__Recurring_Donation__c buildRecurringDonationQuarterlyInstallment(Id contactId) {
        return buildRecurringDonation(contactId, System.Label.npe03.RecurringDonationInstallmentPeriodQuarterly);
    }

    /*******************************************************************************************************
    * @description Builds a recurring donation with monthly installment
    * @param contactId Id of the contact to assign to the recurring donation
    * @return npe03__Recurring_Donation__c
    */
    public static npe03__Recurring_Donation__c buildRecurringDonationMonthlyInstallment(Id contactId) {
        return buildRecurringDonation(contactId, System.Label.npe03.RecurringDonationInstallmentPeriodMonthly);
    }

    /*******************************************************************************************************
    * @description Builds a recurring donation with weekly installment
    * @param contactId Id of the contact to assign to the recurring donation
    * @return npe03__Recurring_Donation__c
    */
    public static npe03__Recurring_Donation__c buildRecurringDonationWeeklyInstallment(Id contactId) {
        return buildRecurringDonation(contactId, System.Label.npe03.RecurringDonationInstallmentPeriodWeekly);
    }

    /*******************************************************************************************************
    * @description Builds a recurring donation with default values
    * @param contactId Id of the contact to assign to the recurring donation
    * @param installmentPeriod An installment period to assign to the recurring donation
    * @return npe03__Recurring_Donation__c
    */
    public static npe03__Recurring_Donation__c buildRecurringDonation(Id contactId, String installmentPeriod) {
        return new npe03__Recurring_Donation__c(
            Name = 'test',
            npe03__Installments__c = 2,
            npe03__Contact__c = contactId,
            npe03__Amount__c = 100,
            npe03__Installment_Period__c = installmentPeriod,
            npe03__Date_Established__c = DEFAULT_ESTABLISHED_DATE,
            npe03__Schedule_Type__c = System.Label.npe03.RecurringDonationMultiplyValue,
            npe03__Open_Ended_Status__c = 'None'
        ); 
    }

    /*******************************************************************************************************
    * @description Creates recurring donation settings with yearly forecast as default
    * @return void
    */
    public static void createRdSettingsWithYearForecast() {
        createRdSettingsWithForecast(12);
    }

    /*******************************************************************************************************
    * @description Creates recurring donation settings
    * @param forecastMonths Forecast month number
    * @return void
    */
    public static void createRdSettingsWithForecast(Integer forecastMonths) {
        UTIL_CustomSettingsFacade.getRecurringDonationsSettingsForTest(new npe03__Recurring_Donations_Settings__c(
            npe03__Opportunity_Forecast_Months__c = forecastMonths,
            npe03__Maximum_Donations__c = 50,
            npe03__Open_Opportunity_Behavior__c = RD_RecurringDonations.RecurringDonationCloseOptions.Mark_Opportunities_Closed_Lost.name()        
        ));
    }

    /*******************************************************************************************************
    * @description Creates recurring donation settings specific to campaigns and 
    * sets forecast to yearly forecast
    * @return void
    */
    public static void createRdSettingsCampaignWithYearForecast() {
        UTIL_CustomSettingsFacade.getRecurringDonationsSettingsForTest(new npe03__Recurring_Donations_Settings__c(
            npe03__Opportunity_Forecast_Months__c = 12,
            npe03__Maximum_Donations__c = 50,
            npe03__Open_Opportunity_Behavior__c = RD_RecurringDonations.RecurringDonationCloseOptions.Mark_Opportunities_Closed_Lost.name(),
            npe03__Add_Campaign_to_All_Opportunites__c = true        
        ));           
    }

    /*********************************************************************************************************
    * @description Retrieve Primary Opportunity Contact Roles for specified Recurring Donations
    * @param rdIds Recurring Donation Ids
    * @return List<OpportunityContactRole>
    */
    private static List<OpportunityContactRole> getPrimaryOppContactRoles(Set<Id> rdIds) {
        List<OpportunityContactRole> ocrs = new List<OpportunityContactRole>([ 
            SELECT ContactId, OpportunityId, Role 
            FROM OpportunityContactRole 
            WHERE Opportunity.npe03__Recurring_Donation__c IN :rdIds
            AND isPrimary = true
        ]);

        return ocrs == null ? new List<OpportunityContactRole>() : ocrs;
    }

    /*******************************************************************************************************
    * @description Retrieves Opportunities for the specified recurring donations
    * @param rds List of recurring donations
    * @return List<Opportunity>
    */
    private static List<Opportunity> getOpps(List<npe03__Recurring_Donation__c> rds) {
        return getOpps((new Map<Id, Sobject>(rds)).keySet());
    }

    /*******************************************************************************************************
    * @description Retrieves Opportunities for the specified recurring donation
    * @param rdId Id of the recurring donation
    * @return List<Opportunity>
    */
    private static List<Opportunity> getOpps(Id rdId) {
        return getOpps(new Set<Id> { rdId });
    }

    /*******************************************************************************************************
    * @description Retrieves Opportunities for the specified recurring donations
    * @param rdIds Ids of recurring donations
    * @return List<Opportunity>
    */
    private static List<Opportunity> getOpps(Set<Id> rdIds) {
        return [
            SELECT Name, Amount, Accountid, CloseDate, isDeleted
            FROM Opportunity 
            WHERE npe03__Recurring_Donation__c IN :rdIds
        ];
    }

    /*******************************************************************************************************
    * @description Retrieves Opportunities for the specified recurring donation and orders them by Close Date
    * @param rdId Id of the recurring donation
    * @return List<Opportunity>
    */
    public static List<Opportunity> getOppsOrderByCloseDate(Id rdId) {
        return [
            SELECT Id, Name, Amount, AccountId, 
                CloseDate, Description, CampaignId
            FROM Opportunity 
            WHERE npe03__Recurring_Donation__c = :rdId 
            ORDER BY CloseDate
        ]; 
    }

    /*******************************************************************************************************
    * @description Returns numbef of Opportunities for the specified recurring donation
    * @param rdId Id of the recurring donation
    * @return Integer
    */
    public static Integer getOpenOppCount(Id rdId) {
        return [
            SELECT COUNT() 
            FROM Opportunity 
            WHERE npe03__Recurring_Donation__c = :rdId 
            AND isClosed = false
        ];
    }

    /*******************************************************************************************************
    * @description Retrieves recurring donation record for the specified Id
    * @param rdId Id of the recurring donation
    * @return npe03__Recurring_Donation__c
    */
    public static npe03__Recurring_Donation__c getRecurringDonation(Id rdId) {
        return [
            SELECT Name, npe03__Next_Payment_Date__c, npe03__Last_Payment_Date__c, npe03__Paid_Amount__c
            FROM npe03__Recurring_Donation__c 
            WHERE Id = :rdId
        ];
    }
 }