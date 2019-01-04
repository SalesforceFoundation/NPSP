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
private with sharing class RD_RecurringDonations_TEST2 {
    private static final Date DEFAULT_ESTABLISHED_DATE = RD_RecurringDonations_TEST.DEFAULT_ESTABLISHED_DATE;
    private static final Date TODAY = System.today();

    //test closing an opportunity for an open recurring donation
    @isTest
    private static void closeOppForOpenEndedRecurringDonationYearly() {
        RD_RecurringDonations_TEST.createRdSettingsWithYearForecast();           
        
        Account a = RD_RecurringDonations_TEST.buildAccount();
        insert a;
        
        Contact c = RD_RecurringDonations_TEST.buildContact(a.Id);
        insert c;       

        npe03__Recurring_Donation__c rd = RD_RecurringDonations_TEST.buildRecurringDonationYearlyInstallment(null);
        rd.npe03__Organization__c = a.id;
        rd.npe03__Open_Ended_Status__c = System.Label.npe03.RecurringDonationOpenStatus;
        rd.npe03__Next_Payment_Date__c = TODAY;
        rd.OwnerId = System.UserInfo.getUserId();
        insert rd;
        
        List<Opportunity> originalOpps = RD_RecurringDonations_TEST.getOppsOrderByCloseDate(rd.Id);
        System.assertEquals(1, originalOpps.size());          
        
        Opportunity o = originalOpps[0];
        o.StageName = UTIL_UnitTestData_TEST.getClosedWonStage();
        o.CloseDate = TODAY;

        Test.startTest();
        update o;
        RD_RecurringDonations.evaluateRecurringDonationsForNewOppInsert(new List<npe03__Recurring_Donation__c>{rd});
        Test.stopTest();
        
        rd = RD_RecurringDonations_TEST.getRecurringDonation(rd.id);     
        System.assertEquals(0, RD_RecurringDonations_TEST.getOpenOppCount(rd.Id));
        System.assertEquals(TODAY, rd.npe03__Last_Payment_Date__c);
    }
    
    @isTest
    private static void closeOpenEndedRecurringDonationMarkOppsClosedLost() {
        RD_RecurringDonations_TEST.createRdSettingsWithYearForecast();           
        
        Account a = RD_RecurringDonations_TEST.buildAccount();
        insert a;
        
        Contact c = RD_RecurringDonations_TEST.buildContact(a.Id);
        insert c;       

        npe03__Recurring_Donation__c rd = RD_RecurringDonations_TEST.buildRecurringDonationWeeklyInstallment(c.Id);
        rd.npe03__Open_Ended_Status__c = System.Label.npe03.RecurringDonationOpenStatus;
        rd.npe03__Next_Payment_Date__c = TODAY.toStartOfMonth();
        insert rd;
        
        List<Opportunity> originalOpps = RD_RecurringDonations_TEST.getOppsOrderByCloseDate(rd.Id);
        Integer cOpp = originalOpps.size();
        System.assert(cOpp == 52 || cOpp == 53); 

        Test.startTest();
        rd.npe03__Open_Ended_Status__c = System.Label.npe03.RecurringDonationClosedStatus;
        update rd;
        Test.stopTest();
        
        //assert all previously open opps are marked closed lost
        System.assertEquals(53, [select count() from Opportunity where isClosed = true and isWon = false and npe03__Recurring_Donation__c = :rd.id]);
        
    }
    
    @isTest
    private static void updateRecurringDonationWithClosedOpp() {
        RD_RecurringDonations_TEST.createRdSettingsWithYearForecast();           
        
        Account a = RD_RecurringDonations_TEST.buildAccount();
        insert a;
        
        Contact c = RD_RecurringDonations_TEST.buildContact(a.Id);
        insert c;        

        npe03__Recurring_Donation__c rd = RD_RecurringDonations_TEST.buildRecurringDonationWeeklyInstallment(c.Id);
        rd.npe03__Open_Ended_Status__c = System.Label.npe03.RecurringDonationOpenStatus;
        rd.npe03__Next_Payment_Date__c = TODAY;
        insert rd;
        
        List<Opportunity> originalOpps = RD_RecurringDonations_TEST.getOppsOrderByCloseDate(rd.Id);
        Opportunity o = originalOpps[0];
        o.StageName = UTIL_UnitTestData_TEST.getClosedWonStage();
        o.CloseDate = TODAY;
        update o;
        
        //fake the last payment date close operation
        rd.npe03__Last_Payment_Date__c = TODAY;
        update rd;
        Test.startTest();
        rd.npe03__Installment_Period__c = System.Label.npe03.RecurringDonationInstallmentPeriodYearly;
        update rd;
        Test.stopTest();        
        
        rd = RD_RecurringDonations_TEST.getRecurringDonation(rd.id);     
        
        System.assertEquals(1, RD_RecurringDonations_TEST.getOpenOppCount(rd.Id));
        System.assertEquals(TODAY, rd.npe03__Last_Payment_Date__c);
    }

    /*******************************************************************************************************
     * Verifies open Opportunities Close Date is updated when the Recurring Donation
     * Next Donation Date is changed.
     */ 
    @isTest
    private static void shouldUpdateOpenOppCloseDatesWhenRecDonationNextDonationDateIsChanged() {
        RD_RecurringDonations_TEST.createRdSettingsWithYearForecast();           
        
        Account a = RD_RecurringDonations_TEST.buildAccount();
        insert a;
        
        Contact c = RD_RecurringDonations_TEST.buildContact(a.Id);
        insert c;       
        
        Date nextDonationDate = TODAY.toStartOfMonth();
        Integer expectedInstallments = 2;

        npe03__Recurring_Donation__c rd = RD_RecurringDonations_TEST.buildRecurringDonationMonthlyInstallment(null);
        rd.npe03__Organization__c = a.id;
        rd.npe03__Date_Established__c = nextDonationDate.addDays(-1);
        rd.npe03__Next_Payment_Date__c = nextDonationDate;
        insert rd;
        
        List<Opportunity> actualOpps = RD_RecurringDonations_TEST.getOppsOrderByCloseDate(rd.Id);
        System.assertEquals(expectedInstallments, actualOpps.size(), 'The installment on Monthly RD should match expected Opp size');  
        System.assertEquals(nextDonationDate, actualOpps[0].CloseDate, 'The first Close Date should be Next Donation Date');                  
        
        nextDonationDate = nextDonationDate.addDays(1);
        rd.npe03__Next_Payment_Date__c = nextDonationDate;
        Test.startTest();
        update rd;
        Test.stopTest();
        
        rd = RD_RecurringDonations_TEST.getRecurringDonation(rd.id); 
        System.assertEquals(nextDonationDate, rd.npe03__Next_Payment_Date__c, 'The RD Next Donation Date should be updated'); 
        
        actualOpps = RD_RecurringDonations_TEST.getOppsOrderByCloseDate(rd.Id);
        System.assertEquals(expectedInstallments, actualOpps.size(), 'The installment on Monthly RD should match expected Opp size');  
        System.assertEquals(nextDonationDate, actualOpps[0].CloseDate, 'The first Close Date should be updated Next Donation Date');       

        System.assertEquals(expectedInstallments, RD_RecurringDonations_TEST.getOpenOppCount(rd.Id));
    }

    //test inserting a closed/won opportunity for an open recurring donation
    @isTest
    private static void insertClosedOppForOpenEndedRecurringDonation() {
        RD_RecurringDonations_TEST.createRdSettingsWithYearForecast();           
        
        Account a = RD_RecurringDonations_TEST.buildAccount();
        insert a;
        
        Contact c = RD_RecurringDonations_TEST.buildContact(a.Id);
        insert c;       

        npe03__Recurring_Donation__c rd = new npe03__Recurring_Donation__c();
        rd.Name = 'test';
        rd.npe03__Installments__c = 0;
        rd.npe03__Contact__c = c.Id;
        rd.npe03__Amount__c = 100;
        rd.npe03__Date_Established__c = DEFAULT_ESTABLISHED_DATE;
        rd.npe03__Open_Ended_Status__c = System.Label.npe03.RecurringDonationOpenStatus;
        rd.npe03__Next_Payment_Date__c = TODAY.toStartOfMonth();
        rd.OwnerId = System.UserInfo.getUserId();
        insert rd;        
        
        Opportunity o = new Opportunity();
        o.StageName = UTIL_UnitTestData_TEST.getClosedWonStage();
        o.CloseDate = TODAY;
        o.Amount = 50;
        o.AccountId = a.Id;
        o.Name = 'test';
        o.npe03__Recurring_Donation__c = rd.Id;

        Test.startTest();
        insert o;
        Test.stopTest();

        rd = RD_RecurringDonations_TEST.getRecurringDonation(rd.id);    
        System.assertEquals(50, rd.npe03__Paid_Amount__c);
    }
    
    //test closing an opportunity for an open recurring donation
    @isTest
    private static void closeOppForOpenEndedRecurringDonationBadRecurrance() {
        RD_RecurringDonations_TEST.createRdSettingsWithYearForecast();           
        
        Account a = RD_RecurringDonations_TEST.buildAccount();
        insert a;
        
        Contact c = RD_RecurringDonations_TEST.buildContact(a.Id);
        insert c;       
        
        Campaign camp = new Campaign(Name = 'MyTestCamp', isActive = true);
        insert camp;

        npe03__Recurring_Donation__c rd = RD_RecurringDonations_TEST.buildRecurringDonationYearlyInstallment(null);
        rd.npe03__Organization__c = a.id;
        rd.npe03__Recurring_Donation_Campaign__c = camp.id;
        rd.npe03__Open_Ended_Status__c = System.Label.npe03.RecurringDonationOpenStatus;
        rd.npe03__Next_Payment_Date__c = TODAY;
        insert rd;

        List<Opportunity> originalOpps = RD_RecurringDonations_TEST.getOppsOrderByCloseDate(rd.Id);
        Opportunity o = originalOpps[0];
        o.StageName = UTIL_UnitTestData_TEST.getClosedWonStage();
        o.CloseDate = TODAY;

        rd.npe03__Installment_Period__c = 'GarbageDate';

        // Need to simulate that this previously ran to prevent the Opp from being deleted.
        TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.flag.RD, true);
        update rd;
        TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.flag.RD, false);

        Test.startTest();
        update o;
        Test.stopTest();
    }
    
    //test closing an opportunity for an open recurring donation
    @isTest
    private static void closeRecurringDonationDeleteOpps() {
        RD_RecurringDonations_TEST.createRdSettingsWithYearForecast();           
        
        Account a = RD_RecurringDonations_TEST.buildAccount();
        insert a;
        
        Contact c = RD_RecurringDonations_TEST.buildContact(a.Id);
        insert c;       
        
        Campaign camp = new Campaign(Name = 'MyTestCamp', isActive = true);
        insert camp;

        npe03__Recurring_Donation__c rd = RD_RecurringDonations_TEST.buildRecurringDonationYearlyInstallment(null);
        rd.npe03__Organization__c = a.id;
        rd.npe03__Recurring_Donation_Campaign__c = camp.id;
        rd.npe03__Open_Ended_Status__c = System.Label.npe03.RecurringDonationOpenStatus;
        rd.npe03__Next_Payment_Date__c = TODAY;
        insert rd;
        
        System.assertNotEquals(0, RD_RecurringDonations_TEST.getOpenOppCount(rd.Id));
        //reset the semaphore
        Test.startTest();
        rd.npe03__Open_Ended_Status__c = System.Label.npe03.RecurringDonationClosedStatus;
        update rd;
        Test.stopTest();
        
        //there should be no open donations
        System.assertEquals(0, RD_RecurringDonations_TEST.getOpenOppCount(rd.Id));        
    }
    
    @isTest
    private static void multipleRDInsert() {
        RD_RecurringDonations_TEST.createRdSettingsWithForecast(6);           
        
        delete [select id from npe03__Custom_Field_Mapping__c];
        npe03__Custom_Field_Mapping__c cfm1 = new npe03__Custom_Field_Mapping__c(
            npe03__Recurring_Donation_Field__c = 'Name',
            npe03__Opportunity_Field__c = 'Description',
            Name = 'CFMName00001-Test'
        );
        insert cfm1;
        
        Account a = RD_RecurringDonations_TEST.buildAccount();
        insert a;
        
        Contact c = RD_RecurringDonations_TEST.buildContact(a.Id);
        insert c;       

        List<npe03__Recurring_Donation__c> rdlist = new List<npe03__Recurring_Donation__c>();
        npe03__Recurring_Donation__c rd = RD_RecurringDonations_TEST.buildRecurringDonationYearlyInstallment(c.Id);
        rd.npe03__Open_Ended_Status__c = System.Label.npe03.RecurringDonationOpenStatus;
        rd.npe03__Next_Payment_Date__c = TODAY.toStartOfMonth();
        rdlist.add(rd);
                
        npe03__Recurring_Donation__c r2 = RD_RecurringDonations_TEST.buildRecurringDonationMonthlyInstallment(c.Id);
        r2.npe03__Open_Ended_Status__c = System.Label.npe03.RecurringDonationOpenStatus;
        r2.npe03__Next_Payment_Date__c = TODAY.toStartOfMonth();
        rdlist.add(r2);
                                        
        Test.startTest();
        insert rdlist;
        rdlist[0].npe03__Amount__c = 50;
        rdlist[1].npe03__Amount__c = 50;
        rdlist[1].npe03__Next_Payment_Date__c = TODAY.toStartOfMonth().addDays(5);
        update rdlist;
        Test.stopTest();

        List<Opportunity> originalOpps = new List<Opportunity>([select id, Name,amount,accountid,CloseDate,Description from Opportunity where npe03__Recurring_Donation__r.id = :rd.id or npe03__Recurring_Donation__c = :r2.id]);
        System.assertEquals(7, originalOpps.size());
        System.assertEquals(50, originalOpps[0].Amount);
        System.assertNotEquals(null, originalOpps[0].Description);
        System.assertNotEquals(null, originalOpps[1].Description);
    }
    @isTest
    private static void tooManyInstallments() {
        UTIL_CustomSettingsFacade.getRecurringDonationsSettingsForTest(new npe03__Recurring_Donations_Settings__c(
            npe03__Opportunity_Forecast_Months__c = 6,
            npe03__Maximum_Donations__c = 2,
            npe03__Open_Opportunity_Behavior__c = RD_RecurringDonations.RecurringDonationCloseOptions.Mark_Opportunities_Closed_Lost.name()        
        ));           
        
        Account a = RD_RecurringDonations_TEST.buildAccount();
        insert a;
        
        Contact c = RD_RecurringDonations_TEST.buildContact(a.Id);
        insert c;       

        npe03__Recurring_Donation__c rd = RD_RecurringDonations_TEST.buildRecurringDonationYearlyInstallment(c.Id);
        rd.npe03__Installments__c = 50;
        rd.npe03__Next_Payment_Date__c = TODAY;
        try{
            insert rd;
        } catch (exception e) {}

        //insert should fail because of too many installments
        System.assertEquals(null,rd.id);
    }
    @isTest
    private static void updateOppsFromMultipleRDs() {
        RD_RecurringDonations_TEST.createRdSettingsWithYearForecast();           
        
        //remove any existing custom field mappings
        delete [select id from npe03__Custom_Field_Mapping__c];        
        npe03__Custom_Field_Mapping__c cfm = new npe03__Custom_Field_Mapping__c(
            npe03__Recurring_Donation_Field__c = 'Name',
            npe03__Opportunity_Field__c = 'Description',
            Name = 'CFMName00001-Test'
        );
        insert cfm;
        
        Account a = RD_RecurringDonations_TEST.buildAccount();
        insert a;
        
        Contact c = RD_RecurringDonations_TEST.buildContact(a.Id);
        insert c;       
        
        npe03__Recurring_Donation__c rd = RD_RecurringDonations_TEST.buildRecurringDonationYearlyInstallment(c.Id);
        rd.npe03__Open_Ended_Status__c = System.Label.npe03.RecurringDonationOpenStatus;
        rd.npe03__Next_Payment_Date__c = TODAY;
        insert rd;
                
        npe03__Recurring_Donation__c r2 = RD_RecurringDonations_TEST.buildRecurringDonationMonthlyInstallment(c.Id);
        r2.npe03__Open_Ended_Status__c = System.Label.npe03.RecurringDonationOpenStatus;
        r2.npe03__Next_Payment_Date__c = TODAY;
        insert r2;

        List<Opportunity> originalOpps = new List<Opportunity>([select id, Name,amount,accountid,CloseDate from Opportunity where npe03__Recurring_Donation__r.id = :rd.id or npe03__Recurring_Donation__c = :r2.id]);
        System.assert(originalOpps.size() > 1);
        
        Test.startTest();
        originalOpps[0].Stagename = UTIL_UnitTestData_TEST.getClosedWonStage();
        originalOpps[1].stagename = UTIL_UnitTestData_TEST.getClosedWonStage();        
        update originalOpps;
        Test.stopTest();

        System.assert(originalOpps.size() > [select count() from Opportunity where isClosed = false and (npe03__Recurring_Donation__c = :rd.id or npe03__Recurring_Donation__c = :r2.id)]);        
    }
    
    @isTest
    private static void testErrorHandlingAllSysAdmins() {
        UTIL_CustomSettingsFacade.getRecurringDonationsSettingsForTest(new npe03__Recurring_Donations_Settings__c(
            npe03__Error_Email_Notifications__c ='All Sys Admins',
            npe03__Opportunity_Forecast_Months__c = 12                
        ));         
        
        Account a = RD_RecurringDonations_TEST.buildAccount();
        insert a;

        npe03__Recurring_Donation__c rd = new npe03__Recurring_Donation__c();
        rd.Name = 'test';
        rd.npe03__Organization__c = a.id;
        rd.npe03__Amount__c = 100;
        rd.npe03__Installment_Period__c = System.Label.npe03.RecurringDonationInstallmentPeriodWeekly;
        rd.npe03__Open_Ended_Status__c = System.Label.npe03.RecurringDonationOpenStatus;
        rd.npe03__Next_Payment_Date__c = TODAY;
        insert rd;    
        
        //create some opps
        List<Opportunity> olist = new List<Opportunity>();
        for (Integer i = 0; i<=10; i++) {
            Opportunity o = new Opportunity(
                StageName = 'Closed Won',
                Name = 'Opp ' + i,
                CloseDate = TODAY,
                Amount = 1.00,
                npe03__Recurring_Donation__c = rd.id                
            );
            olist.add(o);                       
        }
        //invalidate one opp        
        olist[0].Name = null;

        Database.saveresult[] lsr = Database.insert(olist, false);
        
        ERR_Handler.Errors errors = ERR_Handler.getErrors(lsr, olist);
        System.assertEquals(true, errors.errorsExist);
        System.assertEquals(1, errors.errorRecords.size());
    }
    
    @isTest
    private static void testErrorHandlingUser() {
        User u = [select id from User limit 1];
        UTIL_CustomSettingsFacade.getRecurringDonationsSettingsForTest(new npe03__Recurring_Donations_Settings__c( 
            npe03__Error_Email_Notifications__c = u.id,
            npe03__Opportunity_Forecast_Months__c = 12
        ));  
        
        Account a = RD_RecurringDonations_TEST.buildAccount();
        insert a;
        npe03__Recurring_Donation__c rd = new npe03__Recurring_Donation__c();
        rd.Name = 'test';
        rd.npe03__Organization__c = a.id;
        rd.npe03__Amount__c = 100;
        rd.npe03__Installment_Period__c = System.Label.npe03.RecurringDonationInstallmentPeriodWeekly;
        rd.npe03__Open_Ended_Status__c = System.Label.npe03.RecurringDonationOpenStatus;
        rd.npe03__Next_Payment_Date__c = TODAY;
        insert rd;      
        
         //create some opps
        List<Opportunity> olist = new List<Opportunity>();
        for (Integer i = 0; i<=10; i++) {
            Opportunity o = new Opportunity(
                StageName = 'Closed Won',
                Name = 'Opp ' + i,
                CloseDate = TODAY,
                Amount = 1.00,
                npe03__Recurring_Donation__c = rd.id                
            );
            olist.add(o);                       
        }
        //invalidate one opp        
        olist[0].Name = null;

        Database.saveresult[] lsr = Database.insert(olist, false); 

        ERR_Handler.Errors errors = ERR_Handler.getErrors(lsr, olist);
        System.assertEquals(true, errors.errorsExist);
        System.assertEquals(1, errors.errorRecords.size());
    }
    
    @isTest
    private static void testErrorHandlingPublicGroup() {
        Group g = new Group(Name = 'MyGroup');
        insert g;
        UTIL_Debug.debug('GID IS: ' + g.id);
        UTIL_CustomSettingsFacade.getRecurringDonationsSettingsForTest(new npe03__Recurring_Donations_Settings__c( 
            npe03__Error_Email_Notifications__c = g.id,
            npe03__Opportunity_Forecast_Months__c = 12
        ));         
        
        Account a = RD_RecurringDonations_TEST.buildAccount();
        insert a;
        npe03__Recurring_Donation__c rd = new npe03__Recurring_Donation__c();
        rd.Name = 'test';
        rd.npe03__Organization__c = a.id;
        rd.npe03__Amount__c = 100;
        rd.npe03__Installment_Period__c = System.Label.npe03.RecurringDonationInstallmentPeriodWeekly;
        rd.npe03__Open_Ended_Status__c = System.Label.npe03.RecurringDonationOpenStatus;
        rd.npe03__Next_Payment_Date__c = TODAY;
        insert rd;                   
        
        //create some opps
        List<Opportunity> olist = new List<Opportunity>();
        for (Integer i = 0; i<=10; i++) {
            Opportunity o = new Opportunity(
                StageName = 'Closed Won',
                Name = 'Opp ' + i,
                CloseDate = TODAY,
                Amount = 1.00,
                npe03__Recurring_Donation__c = rd.id                
            );
            olist.add(o);                       
        }
        //invalidate one opp        
        olist[0].Name = null;

        Database.saveresult[] lsr = Database.insert(olist, false); 

        ERR_Handler.Errors errors = ERR_Handler.getErrors(lsr, olist);
        System.assertEquals(true, errors.errorsExist);
        System.assertEquals(1, errors.errorRecords.size());
    }     

    //--------------------TEST METHOD from RD_RecurringDonations_BATCH -----------------------
    @isTest
    private static void batchStatusBarTest() {
        UTIL_JobProgress_CTRL controller = new UTIL_JobProgress_CTRL();
        controller.getBatchJobs();
    }

    //--------------- from RD_RecurringDonations_BATCH -----------------
    @isTest 
    public static void testBatch() {
        RD_RecurringDonations_TEST.createRdSettingsWithYearForecast();           
                    
        Account a = RD_RecurringDonations_TEST.buildAccount();
        insert a;
        
        Contact c = RD_RecurringDonations_TEST.buildContact(a.Id);
        insert c;       

        npe03__Recurring_Donation__c rd = RD_RecurringDonations_TEST.buildRecurringDonationWeeklyInstallment(null);
        rd.npe03__Organization__c = a.id;
        rd.npe03__Open_Ended_Status__c = System.Label.npe03.RecurringDonationOpenStatus;
        rd.npe03__Next_Payment_Date__c = TODAY;
        insert rd;
        
        List<Opportunity> originalOpps = RD_RecurringDonations_TEST.getOppsOrderByCloseDate(rd.Id);
        
        Opportunity o = originalOpps[0];
        o.StageName = UTIL_UnitTestData_TEST.getClosedWonStage();
        o.CloseDate = TODAY;
        update o;        
        
        //kick it off from the vf page
        Test.setCurrentPageReference(new PageReference('Page.RecurringDonationsSettings'));
        
        Test.StartTest();
        RD_RecurringDonations_BATCH rdbatch = new RD_RecurringDonations_BATCH();
        ID ApexJobId = Database.executeBatch(rdbatch, 10);
        Test.stopTest();
    }  
    
    @isTest
    private static void testBTN() {
        Account a = new Account(Name = 'TestA');
        insert a;
        npe03__Recurring_Donation__c rd = RD_RecurringDonations_TEST.buildRecurringDonationWeeklyInstallment(null);
        rd.npe03__Organization__c = a.Id;
        rd.npe03__Open_Ended_Status__c = System.Label.npe03.RecurringDonationOpenStatus;
        rd.npe03__Next_Payment_Date__c = TODAY;
        insert rd;  
        
        delete[select id from npe03__Custom_Field_Mapping__c];
        insert new npe03__Custom_Field_Mapping__c(
            Name = 'CFM-' + system.now(),
            npe03__Opportunity_Field__c = 'closedate',
            npe03__Recurring_Donation_Field__c = 'Name'
        );
        
        Test.startTest();
        
        ApexPages.StandardController scc = new ApexPages.StandardController(rd);
        RD_AddDonationsBTN_CTRL addDonationsBtn = new RD_AddDonationsBTN_CTRL(scc);
        System.assertEquals(rd.id, addDonationsBtn.sc.getId());
        addDonationsBtn.buttonClick();

        Test.stopTest();
    }

    /*******************************************************************************************************
    * @description Ensures proper message is displayed when navigating to Visualforce page without an ID
    */
    @isTest
    public static void errorMessageDisplayedWhenMissingId() {
        npe03__Recurring_Donation__c rd = RD_RecurringDonations_TEST.buildRecurringDonationWeeklyInstallment(null);
        rd.npe03__Organization__c = UTIL_UnitTestData_TEST.MOCK_ACCOUNT_ID;
        
        Test.startTest();
        
        ApexPages.StandardController controller = new ApexPages.StandardController(rd);
        RD_AddDonationsBTN_CTRL addDonationsBtn = new RD_AddDonationsBTN_CTRL(controller);
       
        //No redirect should occur
        System.assertEquals(null, addDonationsBtn.buttonClick());

        //Correct info message is returned
        UTIL_UnitTestData_TEST.assertPageHasMessage(System.Label.RD_ErrorAddDonationMissingId, ApexPages.Severity.ERROR);

        //Cancel button redirects back to list recurring donation list view
        Schema.DescribeSObjectResult describeResult = npe03__Recurring_Donation__c.SObjectType.getDescribe();
        PageReference listViewPage = new PageReference('/' + describeResult.getKeyPrefix());
        System.assertNotEquals(listViewPage, addDonationsBtn.redirectToRecurringDonationsPage());

        Test.stopTest();
    }

    /*******************************************************************************************************
    * @description test method for custom field mapping on insert and update of Fixed Length RDs
    */ 
    @isTest
    private static void testRDCustomFieldMappingFixedRD() {
        UTIL_Debug.debug('multiply: ' + System.Label.npe03.RecurringDonationMultiplyValue);
        UTIL_Debug.debug('divide: ' + System.Label.npe03.RecurringDonationDivideValue);
        Account a = RD_RecurringDonations_TEST.buildAccount();
        insert a;
        
        Contact c = RD_RecurringDonations_TEST.buildContact(a.Id);        
        insert c;
        
        //Create new CFM
        delete [select id from npe03__Custom_Field_Mapping__c];
        npe03__Custom_Field_Mapping__c cfm = new npe03__Custom_Field_Mapping__c(
            npe03__Recurring_Donation_Field__c = 'Name',
            npe03__Opportunity_Field__c = 'Description',
            Name = 'CFMName00001-Test'
        );
        insert cfm;


        npe03__Recurring_Donation__c rd = RD_RecurringDonations_TEST.buildRecurringDonationYearlyInstallment(c.Id);
        rd.Name = 'TestRD CFM Insert';
        insert rd;
        
        //check that opps have picked up the value of the RD field set through custom field mapping
        Opportunity[] installments1 = RD_RecurringDonations_TEST.getOppsOrderByCloseDate(rd.id);
        for (opportunity opp:installments1) {
            System.assertEquals(rd.name, opp.description);                
        }

        Test.startTest();
        rd.name='TestRD CFM Update';
        update rd;
        Test.stopTest();

        rd = RD_RecurringDonations_TEST.getRecurringDonation(rd.id);
        System.assertEquals(rd.name,'TestRD CFM Update');

        //check that opps have picked up the upated value of the RD field set through custom field mapping
        Opportunity[] installments2 = RD_RecurringDonations_TEST.getOppsOrderByCloseDate(rd.id);
        for (opportunity opp:installments2) {
            System.assertEquals(rd.name, opp.description);                
        }
    }

    /*******************************************************************************************************
    * @description test method for custom field mapping on insert and update on Open Ended RD's
    */ 
    @isTest
    private static void testRDCustomFieldMappingOpenRD() {
        UTIL_Debug.debug('multiply: ' + System.Label.npe03.RecurringDonationMultiplyValue);
        UTIL_Debug.debug('divide: ' + System.Label.npe03.RecurringDonationDivideValue);
        Account a = RD_RecurringDonations_TEST.buildAccount();
        insert a;
        
        Contact c = RD_RecurringDonations_TEST.buildContact(a.Id);        
        insert c;
        
        //Create new CFM
        delete [select id from npe03__Custom_Field_Mapping__c];
        npe03__Custom_Field_Mapping__c cfm = new npe03__Custom_Field_Mapping__c(
            npe03__Recurring_Donation_Field__c = 'Name',
            npe03__Opportunity_Field__c = 'Description',
            Name = 'CFMName00001-Test'
        );
        insert cfm;


        npe03__Recurring_Donation__c rd = new npe03__Recurring_Donation__c();
        rd.Name = 'TestRD CFM Insert';
        rd.npe03__Contact__c = c.Id;
        rd.npe03__Amount__c = 100;
        rd.npe03__Installment_Period__c = System.Label.npe03.RecurringDonationInstallmentPeriodMonthly;
        rd.npe03__Date_Established__c = TODAY;
        rd.npe03__Schedule_Type__c = System.Label.npe03.RecurringDonationMultiplyValue;
        rd.npe03__Open_Ended_Status__c = 'Open'; 
        insert rd;
        
        //check that opps have picked up the value of the RD field set through custom field mapping
        Opportunity[] installments1 = RD_RecurringDonations_TEST.getOppsOrderByCloseDate(rd.id);
        System.assertNotEquals(0, installments1.size());
        for (opportunity opp:installments1) {
            System.assertEquals(rd.name, opp.description);                
        }

        Test.startTest();
        rd.name='TestRD CFM Update';
        update rd;
        Test.stopTest();

        rd = RD_RecurringDonations_TEST.getRecurringDonation(rd.id);
        System.assertEquals(rd.name, 'TestRD CFM Update');

        //check that opps have picked up the upated value of the RD field set through custom field mapping
        Opportunity[] installments2 = RD_RecurringDonations_TEST.getOppsOrderByCloseDate(rd.id);
        System.assertNotEquals(0, installments2.size());
        for (opportunity opp:installments2) {
            System.assertEquals(rd.name, opp.description);                
        }
    }

    @isTest
    private static void testInstallmentNumbers() {
        RD_RecurringDonations_TEST.createRdSettingsWithYearForecast();           
        
        Account a = RD_RecurringDonations_TEST.buildAccount();
        insert a;
        
        Contact c = RD_RecurringDonations_TEST.buildContact(a.Id);
        insert c;       
        
        Campaign camp = new Campaign(Name = 'MyTestCamp', isActive = true);
        insert camp;

        npe03__Recurring_Donation__c rd = RD_RecurringDonations_TEST.buildRecurringDonationYearlyInstallment(null);
        rd.npe03__Installments__c = 10;
        rd.npe03__Organization__c = a.id;
        rd.npe03__Recurring_Donation_Campaign__c = camp.id;
        rd.npe03__Open_Ended_Status__c = System.Label.npe03.RecurringDonationOpenStatus;
        rd.npe03__Next_Payment_Date__c = TODAY;
        insert rd;
        
        List<opportunity> queryopp = [SELECT Id, Recurring_Donation_Installment_Number__c FROM Opportunity ORDER BY CloseDate];

        for (Integer i=0; i<queryopp.size(); i++) {
            System.assertEquals(i+1,queryopp[i].Recurring_Donation_Installment_Number__c, 'Recurring Donation opportunities should have the correct installment number.');
            queryopp[i].Recurring_Donation_Installment_Number__c = null;
        }
        update queryopp;

        queryopp = [SELECT Id, Recurring_Donation_Installment_Number__c FROM Opportunity ORDER BY CloseDate];

        for (opportunity opp : queryopp) {
            System.assertEquals(null, opp.Recurring_Donation_Installment_Number__c, 'Recurring Donation opportunities shouldn\'t have an installment number.');
        }

        Test.startTest();
        Test.testInstall(new STG_InstallScript(), null, true);
        Test.stopTest();

        queryopp = [SELECT Id, Recurring_Donation_Installment_Number__c FROM Opportunity ORDER BY CloseDate];

        for (Integer i=0; i<queryopp.size(); i++) {
            System.assertEquals(i+1,queryopp[i].Recurring_Donation_Installment_Number__c, 'Recurring Donation opportunities should have the correct installment number.');
            queryopp[i].Recurring_Donation_Installment_Number__c = null;
        }
    }

    @isTest
    private static void testOpenEndedMonthlyEndDates_28th() {
        UTIL_CustomSettingsFacade.getRecurringDonationsSettingsForTest(new npe03__Recurring_Donations_Settings__c(
            npe03__Opportunity_Forecast_Months__c = 12,
            npe03__Maximum_Donations__c = 50
        ));

        Contact c = RD_RecurringDonations_TEST.buildContact(null);
        insert c;
        Account a = [SELECT Id FROM Account WHERE Id IN (SELECT AccountId FROM Contact WHERE Id = :c.Id) LIMIT 1];

        // This should create Installments with a date of the 28th.
        npe03__Recurring_Donation__c rd = new npe03__Recurring_Donation__c();
        rd.Name = 'test28th';
        rd.npe03__Contact__c = c.Id;
        rd.npe03__Amount__c = 100;
        rd.npe03__Installment_Period__c = System.Label.npe03.RecurringDonationInstallmentPeriodMonthly;
        rd.npe03__Date_Established__c = TODAY.toStartOfMonth().addDays(27);
        rd.npe03__Schedule_Type__c = System.Label.npe03.RecurringDonationMultiplyValue;
        rd.npe03__Open_Ended_Status__c = System.Label.npe03.RecurringDonationOpenStatus;

        Test.startTest();
        insert rd;
        Test.stopTest();

        List<Opportunity> listOpp28th = [SELECT Id, CloseDate FROM Opportunity WHERE npe03__Recurring_Donation__r.Name = 'test28th' order by CloseDate];
        System.assertEquals(12, listOpp28th.size(), 'There should be 12 Opps with a Close Date of the 28th');
        for (Opportunity opp : listOpp28th) {
            System.assertEquals(28, opp.CloseDate.Day(), 'The Opp.CloseDate.Day should be the 28th');
        }
    }

    @isTest
    private static void testOpenEndedMonthlyEndDates_30th() {
        UTIL_CustomSettingsFacade.getRecurringDonationsSettingsForTest(
            new npe03__Recurring_Donations_Settings__c(
                npe03__Opportunity_Forecast_Months__c = 12,
                npe03__Maximum_Donations__c = 50
            ));

        Contact c = RD_RecurringDonations_TEST.buildContact(null);
        insert c;
        Account a = [SELECT Id FROM Account WHERE Id IN (SELECT AccountId FROM Contact WHERE Id = :c.Id) LIMIT 1];

        // This should create Installments with a date of the 28th.
        npe03__Recurring_Donation__c rd = new npe03__Recurring_Donation__c();
        rd.Name = 'test30th';
        rd.npe03__Contact__c = c.Id;
        rd.npe03__Amount__c = 100;
        rd.npe03__Installment_Period__c = System.Label.npe03.RecurringDonationInstallmentPeriodMonthly;
        rd.npe03__Schedule_Type__c = System.Label.npe03.RecurringDonationMultiplyValue;
        rd.npe03__Open_Ended_Status__c = System.Label.npe03.RecurringDonationOpenStatus;

        // Find a start date for a month that has 30 days and calculate an offset from the current month
        // to use in the asserts below to account for the fact that Opp installments are only created from
        // the current month forward even if the start date is months in the future. Theoretically could just
        // subtract a day from 10/31 to get 10/31 (for example), but that won't work in February. As a result
        // it's better to just skip ahead months to find one with exactly 30 days and then use that offset
        // for the asserts.
        Date startDt = TODAY.toStartOfMonth().addMonths(1).addDays(-1);
        Integer opps30thMonthOffset = 0;
        while (startDt.day() != 30) {
            startDt = startDt.addMonths(2).toStartOfMonth().addDays(-1);
            opps30thMonthOffset++;
        }
        rd.npe03__Date_Established__c = startDt;
        rd.npe03__Next_Payment_Date__c = null;

        Test.startTest();
        insert rd;
        Test.stopTest();

        // All Installments should be on the 30th except for February, which should be on the last day of the month
        List<Opportunity> listOpp30th = [SELECT Id, CloseDate FROM Opportunity WHERE npe03__Recurring_Donation__r.Name = 'test30th' order by CloseDate];
        System.assertEquals(12-opps30thMonthOffset, listOpp30th.size(), 
            'There should be ' + (12-opps30thMonthOffset) + ' Opps with a Close Date of the 30th');

        for (Opportunity opp : listOpp30th) {
            if (opp.CloseDate.Month() != 2) {
                System.assertEquals(30, opp.CloseDate.Day(), 'The Opp.CloseDate.Day should be the 30th');
            } else {
                System.assertEquals(Date.DaysInMonth(opp.CloseDate.Year(), 2), opp.CloseDate.Day(),
                    'The installment close date for February should be on the last day of February for the year');
            }
        }
    }

    @isTest
    private static void testOpenEndedMonthlyEndDates_EOM() {
        UTIL_CustomSettingsFacade.getRecurringDonationsSettingsForTest(
            new npe03__Recurring_Donations_Settings__c(
                npe03__Opportunity_Forecast_Months__c = 12,
                npe03__Maximum_Donations__c = 50
            ));

        Contact c = RD_RecurringDonations_TEST.buildContact(null);
        insert c;
        Account a = [SELECT Id FROM Account WHERE Id IN (SELECT AccountId FROM Contact WHERE Id = :c.Id) LIMIT 1];

        // This should create Installments with a date of the 28th.
        npe03__Recurring_Donation__c rd = new npe03__Recurring_Donation__c();
        rd.Name = 'testEndOfMonth';
        rd.npe03__Contact__c = c.Id;
        rd.npe03__Amount__c = 100;
        rd.npe03__Installment_Period__c = System.Label.npe03.RecurringDonationInstallmentPeriodMonthly;
        rd.npe03__Date_Established__c = TODAY.toStartOfMonth().addDays(12);    // this shouldn't matter
        rd.npe03__Schedule_Type__c = System.Label.npe03.RecurringDonationMultiplyValue;
        rd.npe03__Open_Ended_Status__c = System.Label.npe03.RecurringDonationOpenStatus;
        rd.Always_Use_Last_Day_Of_Month__c = true;

        Test.startTest();
        insert rd;
        Test.stopTest();

        // All Installments should be on the last day of the month
        List<Opportunity> listOppEnd = [SELECT Id, CloseDate FROM Opportunity WHERE npe03__Recurring_Donation__r.Name = 'testEndOfMonth' order by CloseDate];
        System.assertEquals(12, listOppEnd.size(), 'There should be 12 Opps with a close date of the last day of the month');
        for (Opportunity opp : listOppEnd) {
            System.assertEquals(Date.DaysInMonth(opp.CloseDate.Year(), opp.CloseDate.Month()), opp.CloseDate.Day(),
                    'The Opps Close Date should be the very last day of the month: ' + opp.CloseDate);
        }
    }

    @isTest
    private static void adjustDayOfMonthReturnsDateBasedOnNextDonationDay() {
        Date nextDonationDate = Date.newInstance(TODAY.year(), 1, 31);
        Date dateEstablished = nextDonationDate.toStartOfMonth();
        Date installmentDate = Date.newInstance(TODAY.year(), 3, 28);
        Integer expectedDay;
        Integer actualDay;

        npe03__Recurring_Donation__c recurringDonation = new npe03__Recurring_Donation__c(
            Name = 'NextDonationDate',
            npe03__Next_Payment_Date__c = nextDonationDate,
            npe03__Date_Established__c = dateEstablished,
            npe03__Installment_Period__c = System.Label.npe03.RecurringDonationInstallmentPeriodMonthly,
            Always_Use_Last_Day_Of_Month__c = false,
            Day_Of_Month__c = null
        );

        for (Integer i = 0; i < 3; i++) {
            recurringDonation.npe03__Next_Payment_Date__c = nextDonationDate.addDays(-i);
            expectedDay = nextDonationDate.addDays(-i).day();
            actualDay = RD_RecurringDonations.adjustDayOfMonth(installmentDate, recurringDonation).day();
            System.assertEquals(expectedDay, actualDay);
        }
    }

    @isTest
    private static void adjustDayOfMonthReturnsSameDateWhenNotEndOfMonthDay() {
        Date nextDonationDate = Date.newInstance(TODAY.year(), 1, 31);
        Date dateEstablished = nextDonationDate.toStartOfMonth();
        Date installmentDate = Date.newInstance(TODAY.year(), 3, 27);
        Date expectedDate = installmentDate;
        Date actualDate;

        npe03__Recurring_Donation__c recurringDonation = new npe03__Recurring_Donation__c(
            Name = 'DateProvided',
            npe03__Next_Payment_Date__c = nextDonationDate,
            npe03__Date_Established__c = dateEstablished,
            npe03__Installment_Period__c = System.Label.npe03.RecurringDonationInstallmentPeriodMonthly,
            Always_Use_Last_Day_Of_Month__c = false,
            Day_Of_Month__c = null
        );

        actualDate = RD_RecurringDonations.adjustDayOfMonth(installmentDate, recurringDonation);
        System.assertEquals(expectedDate, actualDate);
    }

    @isTest
    private static void adjustDayOfMonthReturnsDateBasedOnEstablishedDay() {
        Date dateEstablished = Date.newInstance(TODAY.year(), 1, 31);
        Date installmentDate = Date.newInstance(TODAY.year(), 3, 28);
        Integer expectedDay;
        Integer actualDay;

        npe03__Recurring_Donation__c recurringDonation = new npe03__Recurring_Donation__c(
            Name = 'EstablishedDate',
            npe03__Next_Payment_Date__c = null,
            npe03__Date_Established__c = dateEstablished,
            npe03__Installment_Period__c = System.Label.npe03.RecurringDonationInstallmentPeriodMonthly,
            Always_Use_Last_Day_Of_Month__c = false,
            Day_Of_Month__c = null
        );

        for (Integer i = 0; i < 3; i++) {
            expectedDay = dateEstablished.day();
            actualDay = RD_RecurringDonations.adjustDayOfMonth(installmentDate.addDays(i), recurringDonation).day();
            System.assertEquals(expectedDay, actualDay);
        }
    }

    @isTest
    private static void adjustDayOfMonthReturnsSameDateWhenNextDonationNotEndOfMonth() {
        Date dateEstablished = Date.newInstance(TODAY.year(), 1, 11);
        Date installmentDate = Date.newInstance(TODAY.year(), 3, 28);
        Date expectedDate;
        Date actualDate;

        npe03__Recurring_Donation__c recurringDonation = new npe03__Recurring_Donation__c(
            Name = 'EstablishedDate',
            npe03__Next_Payment_Date__c = dateEstablished,
            npe03__Date_Established__c = dateEstablished,
            npe03__Installment_Period__c = System.Label.npe03.RecurringDonationInstallmentPeriodMonthly,
            Always_Use_Last_Day_Of_Month__c = false,
            Day_Of_Month__c = null
        );

        for (Integer i = 0; i < 3; i++) {
            expectedDate = installmentDate.addDays(i);
            actualDate = RD_RecurringDonations.adjustDayOfMonth(expectedDate, recurringDonation);
            System.assertEquals(expectedDate, actualDate);
        }
    }

    @isTest
    private static void adjustDayOfMonthReturnsEndOfMonthWhenAlwaysEndOfMonthIsSet() {
        Date nextDonationDate = Date.newInstance(TODAY.year(), 1, 30);
        Date dateEstablished = nextDonationDate.toStartOfMonth();
        Date installmentDate = Date.newInstance(TODAY.year(), 3, 28);
        Integer expectedDay;
        Integer actualDay;

        npe03__Recurring_Donation__c recurringDonation = new npe03__Recurring_Donation__c(
            Name = 'AlwaysEndOfMonth',
            npe03__Next_Payment_Date__c = nextDonationDate,
            npe03__Date_Established__c = dateEstablished,
            npe03__Installment_Period__c = System.Label.npe03.RecurringDonationInstallmentPeriodMonthly,
            Always_Use_Last_Day_Of_Month__c = true,
            Day_Of_Month__c = '11'
        );

        expectedDay = Date.daysInMonth(installmentDate.year(), installmentDate.Month());
        actualDay = RD_RecurringDonations.adjustDayOfMonth(installmentDate, recurringDonation).day();
        System.assertEquals(expectedDay, actualDay);
    }

    @isTest
    private static void adjustDayOfMonthReturnsDayOfMonthSelected() {
        Date nextDonationDate = Date.newInstance(TODAY.year(), 1, 31);
        Date dateEstablished = nextDonationDate.toStartOfMonth();
        Date installmentDate = Date.newInstance(TODAY.year(), 3, 28);
        Integer expectedDay;
        Integer actualDay;

        npe03__Recurring_Donation__c recurringDonation = new npe03__Recurring_Donation__c(
            Name = 'DayOfMonth',
            npe03__Next_Payment_Date__c = nextDonationDate,
            npe03__Date_Established__c = dateEstablished,
            npe03__Installment_Period__c = System.Label.npe03.RecurringDonationInstallmentPeriodMonthly,
            Always_Use_Last_Day_Of_Month__c = false,
            Day_Of_Month__c = '11'
        );

        expectedDay = Integer.valueOf(recurringDonation.Day_Of_Month__c);
        actualDay = RD_RecurringDonations.adjustDayOfMonth(installmentDate, recurringDonation).day();
        System.assertEquals(expectedDay, actualDay);

        recurringDonation.npe03__Next_Payment_Date__c = null;
        actualDay = RD_RecurringDonations.adjustDayOfMonth(installmentDate, recurringDonation).day();
        System.assertEquals(expectedDay, actualDay);
    }


    /*********************************************************************************************************
    * @description Verifies start date (first Opportunity Close Date)
    * is on the Day of Month date that is greater or equal to the Date Established.
    */
    @isTest
    private static void nextDonationDateIsGreaterOrEqualToDateEstablished() {
        npe03__Recurring_Donation__c rd = new npe03__Recurring_Donation__c(
            npe03__Date_Established__c = Date.newInstance(2000, 11, 19),//day is greater than Day of Month
            npe03__Installment_Period__c = System.Label.npe03.RecurringDonationInstallmentPeriodMonthly,
            Always_Use_Last_Day_Of_Month__c = false,
            Day_Of_Month__c = '15'
        );

        System.assertEquals(Date.newInstance(2000, 12, 15), RD_RecurringDonations.getStartDate(rd),
            'Expecting Day of Month date greater than Date Established');

        rd.npe03__Date_Established__c = Date.newInstance(2000, 11, 14);//day is less than Day of Month

        System.assertEquals(Date.newInstance(2000, 11, 15), RD_RecurringDonations.getStartDate(rd),
            'Expecting Day of Month date for the same month as Date Established');
    }

    /*********************************************************************************************************
    * @description Verifies calculated Next Donation Date based on the current
    * Next Donation Date, Date Established and Day of Month values
    */
    @isTest
    private static void nextDonationDateIsCalculatedBasedOnDayOfMonthAndCurrentNextDonationDate() {
        npe03__Recurring_Donation__c rd = new npe03__Recurring_Donation__c(
            npe03__Date_Established__c = Date.newInstance(2000, 11, 19),
            npe03__Next_Payment_Date__c = Date.newInstance(2000, 11, 21),
            npe03__Installment_Period__c = System.Label.npe03.RecurringDonationInstallmentPeriodMonthly,
            Always_Use_Last_Day_Of_Month__c = false,
            Day_Of_Month__c = '20'// Day of Month is in between Date Established and Next Donation Date
        );

        System.assertEquals(Date.newInstance(2000, 11, 20), RD_RecurringDonations.getStartDate(rd),
            'Expecting Day of Month date in the same month as Next Donation Date');

        rd.Day_Of_Month__c = '23';//day is greater than Date Established and Next Donation Date days
        System.assertEquals(Date.newInstance(2000, 11, 23), RD_RecurringDonations.getStartDate(rd),
            'Expecting Day of Month date for the same month as Next Donation Date');

        rd.Day_Of_Month__c = '2';//day is less than Date Established and Next Donation Date days
        System.assertEquals(Date.newInstance(2000, 12, 2), RD_RecurringDonations.getStartDate(rd),
            'Expecting Day of Month date greater than Date Established');

        rd.npe03__Next_Payment_Date__c = Date.newInstance(2000, 10, 30);//date is in a month before Date Established
        System.assertEquals(Date.newInstance(2000, 12, 2), RD_RecurringDonations.getStartDate(rd),
            'Expecting Day of Month date greater than Date Established');

        rd.npe03__Date_Established__c = Date.newInstance(2000, 10, 19);
        rd.npe03__Next_Payment_Date__c = Date.newInstance(2000, 9, 21);
        rd.Day_Of_Month__c = '31';
        System.assertEquals(Date.newInstance(2000, 10, 31), RD_RecurringDonations.getStartDate(rd),
            'Expecting end of month based on Day of Month and Date Established');

    }

    /*********************************************************************************************************
    * @description Verifies Close Date values on recurring donation Opportunities based on Day of Month value
    * that does not exist in the current Next Donation Date month
    */
    @isTest
    private static void closeDateIsCalculatedBasedOnDayOfMonthStartDateEndOfMonth() {
        npe03__Recurring_Donation__c rd = new npe03__Recurring_Donation__c(
            npe03__Date_Established__c = Date.newInstance(2000, 9, 19),
            npe03__Next_Payment_Date__c = Date.newInstance(2000, 9, 21),
            npe03__Installment_Period__c = System.Label.npe03.RecurringDonationInstallmentPeriodMonthly,
            Always_Use_Last_Day_Of_Month__c = false,
            Day_Of_Month__c = '31'// Day of Month that does not exist in the current Next Donation Date
        );

        Date expectedStartDate = Date.newInstance(2000, 9, 30);
        System.assertEquals(expectedStartDate, RD_RecurringDonations.getStartDate(rd),
            'Start Date is end of the same month as Next Donation Date, greater than Date Established');

        Date nextDate = RD_RecurringDonations.getNextDate(expectedStartDate, rd);
        System.assertEquals(Date.newInstance(2000, 10, 31), nextDate, 'Expecting next month Day of Month date');

        nextDate = RD_RecurringDonations.getNextDate(nextDate, rd);
        System.assertEquals(Date.newInstance(2000, 11, 30), nextDate, 'Expecting next month end of month date');

        nextDate = RD_RecurringDonations.getNextDate(nextDate, rd);
        System.assertEquals(Date.newInstance(2000, 12, 31), nextDate, 'Expecting next month Day of Month date');
    }

    /*********************************************************************************************************
    * @description Verifies Close Date values on recurring donation Opportunities based on Day of Month value
    * that exists in the current Next Donation Date month
    */
    @isTest
    private static void closeDateIsCalculatedBasedOnDayOfMonth() {
        npe03__Recurring_Donation__c rd = new npe03__Recurring_Donation__c(
            npe03__Date_Established__c = Date.newInstance(2000, 7, 19),
            npe03__Next_Payment_Date__c = Date.newInstance(2000, 7, 21),
            npe03__Installment_Period__c = System.Label.npe03.RecurringDonationInstallmentPeriodMonthly,
            Always_Use_Last_Day_Of_Month__c = false,
            Day_Of_Month__c = '31'// Day of Month exists in the current Next Donation Date
        );

        Date expectedStartDate = Date.newInstance(2000, 7, 31);
        System.assertEquals(expectedStartDate, RD_RecurringDonations.getStartDate(rd),
            'Start Date is Day of Month date in the same month as Next Donation Date and greater than Date Established');

        Date nextDate = RD_RecurringDonations.getNextDate(expectedStartDate, rd);
        System.assertEquals(Date.newInstance(2000, 8, 31), nextDate, 'Expecting next month Day of Month date');

        nextDate = RD_RecurringDonations.getNextDate(nextDate, rd);
        System.assertEquals(Date.newInstance(2000, 9, 30), nextDate, 'Expecting next month end of month date');

        nextDate = RD_RecurringDonations.getNextDate(nextDate, rd);
        System.assertEquals(Date.newInstance(2000, 10, 31), nextDate, 'Expecting next month Day of Month date');
    }

    @isTest
    private static void testOrphanedRd() {
        Contact con = new Contact(LastName='test');
        insert con;

        List<npe03__Recurring_Donation__c> rdList = new List<npe03__Recurring_Donation__c>();
        rdList.add(new npe03__Recurring_Donation__c(
            Name='Orphan',
            npe03__Open_Ended_Status__c= Label.npe03.RecurringDonationOpenStatus
        ));
        rdList.add(new npe03__Recurring_Donation__c(
            Name='Orphan2',
            npe03__Open_Ended_Status__c= Label.npe03.RecurringDonationOpenStatus
        ));
        rdList.add(new npe03__Recurring_Donation__c(
            Name = 'test',
            npe03__Contact__c = con.id,
            npe03__Amount__c = 100,
            npe03__Installments__c = 2,
            npe03__Installment_Period__c = Label.npe03.RecurringDonationInstallmentPeriodMonthly,
            npe03__Date_Established__c = DEFAULT_ESTABLISHED_DATE,
            npe03__Schedule_Type__c = Label.npe03.RecurringDonationMultiplyValue,
            npe03__Open_Ended_Status__c = Label.npe03.RecurringDonationOpenStatus,
            npe03__Next_Payment_Date__c = TODAY
        ));


        //disable triggers to skip opp creation and validation, which would prevent the insertion of the orphan
        //orphaned RDs may exist due to a historical lack of RD cascade deletion when contacts and accounts were deleted
        TDTM_TriggerHandler.disableTDTM = true;
        insert rdList;
        TDTM_TriggerHandler.disableTDTM = false;

        Test.startTest();
        Database.executeBatch(new RD_RecurringDonations_BATCH(), 10);
        Test.stopTest();

        List<Opportunity> rdOpps = [SELECT Id FROM Opportunity WHERE npe03__Recurring_Donation__c IN :rdList];
        System.assertEquals(12,rdOpps.size(), 'Twelve opps should be created for the well formed recurring donation.');

    }


    //========================================================================
    // Test that the Open Recurring Donation's npe03__Paid_Amount__c is updated 
    // when a ClosedWon Opportunity is associate with the open Recurring Donation 
    //========================================================================
    @isTest
    private static void updateOpenEndedRecurringDonationsPaidAmountWithAClosedWonOpp() {
        RD_RecurringDonations_TEST.createRdSettingsWithYearForecast();           
        
        Account a = RD_RecurringDonations_TEST.buildAccount();
        insert a;
        
        Contact c = RD_RecurringDonations_TEST.buildContact(a.Id);
        insert c;       

        //--------------------------------
        // Setup the Recurring Donation
        npe03__Recurring_Donation__c rd = new npe03__Recurring_Donation__c();
        rd.Name = 'TestRD';
        rd.npe03__Installments__c = 0;
        rd.npe03__Contact__c = c.Id;
        rd.npe03__Amount__c = 100;
        rd.npe03__Date_Established__c = DEFAULT_ESTABLISHED_DATE;
        rd.npe03__Open_Ended_Status__c = System.Label.npe03.RecurringDonationOpenStatus;
        rd.npe03__Next_Payment_Date__c = TODAY.toStartOfMonth();
        rd.OwnerId = System.UserInfo.getUserId();
        insert rd;        
        
        //--------------------------------
        // Setup the First Opportunity
        Opportunity o = new Opportunity();
        o.StageName = UTIL_UnitTestData_TEST.getClosedWonStage();
        o.CloseDate = TODAY;
        o.Amount = 50;
        o.AccountId = a.Id;
        o.Name = 'test';
        o.npe03__Recurring_Donation__c = rd.Id;
        
        //--------------------------------
        // Setup the Second Opportunity
        Opportunity oppty2 = new Opportunity();
        oppty2.StageName = UTIL_UnitTestData_TEST.getClosedWonStage();
        oppty2.CloseDate = TODAY;
        oppty2.Amount = 100;
        oppty2.AccountId = a.Id;
        oppty2.Name = 'test2';
        oppty2.npe03__Recurring_Donation__c = null;

        //--------------------------------
        // Insert the two Opportunities
        Test.startTest();        
        insert o;
        insert oppty2;
        
        //--------------------------------
        // Confirm that only the First Opportunity has updated the Recurring Donation's npe03__Paid_Amount__c
        rd = RD_RecurringDonations_TEST.getRecurringDonation(rd.id);    
        System.assertEquals(50, rd.npe03__Paid_Amount__c);

        //--------------------------------
        // Update the Second Opportunity's Recurring Donation field
        oppty2.npe03__Recurring_Donation__c = rd.Id;
        update oppty2;
        Test.stopTest();

        //--------------------------------
        // Confirm that the Second Opportunity has updated the Recurring Donation's npe03__Paid_Amount__c
        rd = RD_RecurringDonations_TEST.getRecurringDonation(rd.id);    
        System.assertEquals(150, rd.npe03__Paid_Amount__c);
    }


    //========================================================================
    // Test that changing a ClosedWon Opportunity from one Recurring Donation
    // to another Recurring Donation updates the npe03__Paid_Amount__c value 
    // for both Recurring Donations accordingly
    //========================================================================
    @isTest
    private static void updateMultipleOpenEndedRecurringDonationsPaidAmountWithAClosedWonOpp() {
        RD_RecurringDonations_TEST.createRdSettingsWithYearForecast();           
        
        Account a = RD_RecurringDonations_TEST.buildAccount();
        insert a;
        
        Contact c = RD_RecurringDonations_TEST.buildContact(a.Id);
        insert c;       

        //--------------------------------
        // Setup the First Recurring Donation
        npe03__Recurring_Donation__c rd = new npe03__Recurring_Donation__c();
        rd.Name = 'TestRD1';
        rd.npe03__Installments__c = 0;
        rd.npe03__Contact__c = c.Id;
        rd.npe03__Amount__c = 100;
        rd.npe03__Date_Established__c = DEFAULT_ESTABLISHED_DATE;
        rd.npe03__Open_Ended_Status__c = System.Label.npe03.RecurringDonationOpenStatus;
        rd.npe03__Next_Payment_Date__c = TODAY.toStartOfMonth();
        rd.OwnerId = System.UserInfo.getUserId();
        insert rd;        
        
        //--------------------------------
        // Setup the Second Recurring Donation
        npe03__Recurring_Donation__c r2 = new npe03__Recurring_Donation__c();
        r2.Name = 'TestRD2';
        r2.npe03__Installments__c = 0;
        r2.npe03__Contact__c = c.Id;
        r2.npe03__Amount__c = 100;
        r2.npe03__Date_Established__c = DEFAULT_ESTABLISHED_DATE;
        r2.npe03__Open_Ended_Status__c = System.Label.npe03.RecurringDonationOpenStatus;
        r2.npe03__Next_Payment_Date__c = TODAY.toStartOfMonth();
        r2.OwnerId = System.UserInfo.getUserId();
        insert r2;    

        //--------------------------------
        // Setup the Opportunity
        Opportunity o = new Opportunity();
        o.StageName = UTIL_UnitTestData_TEST.getClosedWonStage();
        o.CloseDate = TODAY;
        o.Amount = 50;
        o.AccountId = a.Id;
        o.Name = 'test';
        o.npe03__Recurring_Donation__c = rd.Id;

        //--------------------------------
        // Insert the Opportunity
        Test.startTest();        
        insert o;
        
        //--------------------------------
        // Confirm the Opportunity has updated only the Recurring Donation's (rd) npe03__Paid_Amount__c
        rd = RD_RecurringDonations_TEST.getRecurringDonation(rd.id);    
        System.assertEquals(50, rd.npe03__Paid_Amount__c);

        r2 = RD_RecurringDonations_TEST.getRecurringDonation(r2.id);    
        System.assertEquals(null, r2.npe03__Paid_Amount__c);
        
        //--------------------------------
        // Update the Opportunity's Recurring Donation field
        o.npe03__Recurring_Donation__c = r2.Id;
        update o;
        Test.stopTest();

        //--------------------------------
        // Confirm the Opportunity has updated the npe03__Paid_Amount__c for both Recurring Donations (rd & r2) 
        rd = RD_RecurringDonations_TEST.getRecurringDonation(rd.id);    
        System.assertEquals(null, rd.npe03__Paid_Amount__c);

        r2 = RD_RecurringDonations_TEST.getRecurringDonation(r2.id);    
        System.assertEquals(50, r2.npe03__Paid_Amount__c);
    }


    //========================================================================
    // Test that removing a ClosedWon Opportunity from one Recurring Donation
    // updates the npe03__Paid_Amount__c value 
    //========================================================================
    @isTest
    private static void updateOpenEndedRecurringDonationsPaidAmountByRemovingAClosedWonOpp() {
        RD_RecurringDonations_TEST.createRdSettingsWithYearForecast();           
        
        Account a = RD_RecurringDonations_TEST.buildAccount();
        insert a;

        Contact c = RD_RecurringDonations_TEST.buildContact(a.Id);
        insert c;       

        //--------------------------------
        // Setup the First Recurring Donation
        npe03__Recurring_Donation__c rd = new npe03__Recurring_Donation__c();
        rd.Name = 'TestRD1';
        rd.npe03__Installments__c = 0;
        rd.npe03__Contact__c = c.Id;
        rd.npe03__Amount__c = 100;
        rd.npe03__Date_Established__c = DEFAULT_ESTABLISHED_DATE;
        rd.npe03__Open_Ended_Status__c = System.Label.npe03.RecurringDonationOpenStatus;
        rd.npe03__Next_Payment_Date__c = TODAY.toStartOfMonth();
        rd.OwnerId = System.UserInfo.getUserId();
        insert rd;        
        
        //--------------------------------
        // Setup the Opportunity
        Opportunity o = new Opportunity();
        o.StageName = UTIL_UnitTestData_TEST.getClosedWonStage();
        o.CloseDate = TODAY;
        o.Amount = 50;
        o.AccountId = a.Id;
        o.Name = 'test';
        o.npe03__Recurring_Donation__c = rd.Id;

        //--------------------------------
        // Insert the Opportunity
        Test.startTest();        
        insert o;
        
        //--------------------------------
        // Confirm the Opportunity has updated the Recurring Donation's (rd) npe03__Paid_Amount__c
        rd = RD_RecurringDonations_TEST.getRecurringDonation(rd.id);    
        System.assertEquals(50, rd.npe03__Paid_Amount__c);
        
        //--------------------------------
        // Remove the Opportunity's Recurring Donation value by setting the field to null
        o.npe03__Recurring_Donation__c = null;
        update o;
        Test.stopTest();

        //--------------------------------
        // Confirm the Opportunity has updated the npe03__Paid_Amount__c for both Recurring Donation (rd) 
        rd = RD_RecurringDonations_TEST.getRecurringDonation(rd.id);    
        System.assertEquals(null, rd.npe03__Paid_Amount__c);
    }
    

}
