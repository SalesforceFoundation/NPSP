/*
    Copyright (c) 2012, Salesforce.com Foundation
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
* @date 2012 (2.0)
* @description Test class for the RecurringDonations class
*/
@isTest
public class RD_RecurringDonations_TEST {


    // if you only want to run one test in this class, fill in its name here.
    // if you want to run all tests, then use '*'
    private static string strTestOnly = '*';
    

    /// <name> insertOpportunities_Test </name>
    /// <summary> test method for insertOpportunities function </summary>
    static testMethod void insertOpportunities()
    {
        if (strTestOnly != '*' && strTestOnly != 'insertOpportunities') return;
        
        UTIL_Debug.debug('multiply: ' + system.label.npe03.RecurringDonationMultiplyValue);
        UTIL_Debug.debug('divide: ' + system.label.npe03.RecurringDonationDivideValue);
        Account a = new Account();
        a.Name = 'test Individual';
        insert a;
        
        Contact c = new Contact();
        c.FirstName = 'test';
        c.LastName = 'contact';
        c.AccountId = a.Id;        
        insert c;
        
        //added to cover
        npe03__Custom_Field_Mapping__c cfm = new npe03__Custom_Field_Mapping__c(
        npe03__Recurring_Donation_Field__c = 'npe03__Last_Payment_Date__c',
        npe03__Opportunity_Field__c = 'Description',
        Name = 'CFMName00001-Test'
        );
        insert cfm;

        npe03__Recurring_Donation__c r0 = new npe03__Recurring_Donation__c();
        r0.Name = 'test';
        r0.npe03__Installments__c = 3;
        r0.npe03__Amount__c = 100;
        r0.npe03__Installment_Period__c = system.label.npe03.RecurringDonationInstallmentPeriodYearly;
        r0.npe03__Date_Established__c = date.newinstance(1970,6,12);
        r0.npe03__Schedule_Type__c = system.label.npe03.RecurringDonationMultiplyValue;
        try {
            insert r0;
        } catch (Exception e) {
            ERR_Handler.processError(e, r0, ERR_Handler.Context.RD);
        }
        //insert should fail because there is no Contact
        system.assertEquals(null,r0.id);
        

        npe03__Recurring_Donation__c r1 = new npe03__Recurring_Donation__c();
        r1.Name = 'test';
        r1.npe03__Installments__c = 2;
        r1.npe03__Contact__c = c.Id;
        r1.npe03__Amount__c = 100;
        r1.npe03__Installment_Period__c = system.label.npe03.RecurringDonationInstallmentPeriodYearly;
        r1.npe03__Date_Established__c = date.newinstance(1970,6,12);
        r1.npe03__Schedule_Type__c = system.label.npe03.RecurringDonationMultiplyValue;
        r1.npe03__Open_Ended_Status__c = 'None'; 
        insert r1;
        
        Opportunity[] installments1 = [select Name,amount,accountid,CloseDate from Opportunity where npe03__Recurring_Donation__c = :r1.id order by CloseDate];
        system.assertEquals(2,installments1.size());
        system.assertEquals(100,installments1[0].Amount);
        system.assertEquals(date.newinstance(1970,6,12),installments1[0].CloseDate);
        system.assertEquals(a.id,installments1[0].AccountId);
        system.assertEquals(100,installments1[1].Amount);
        system.assertEquals(date.newinstance(1971,6,12),installments1[1].CloseDate);
        system.assertEquals(a.id,installments1[1].AccountId);
        UTIL_Debug.debug('****' + installments1);        
    }
    
    static testMethod void insertWeeklyOpportunities()
    {
        if (strTestOnly != '*' && strTestOnly != 'insertWeeklyOpportunities') return;
        
         Account a = new Account();
        a.Name = 'test Individual';
        insert a;
        
        Contact c = new Contact();
        c.FirstName = 'test';
        c.LastName = 'contact';
        c.AccountId = a.Id;
        insert c;       

        npe03__Recurring_Donation__c r1 = new npe03__Recurring_Donation__c();
        r1.Name = 'test';
        r1.npe03__Installments__c = 2;
        r1.npe03__Contact__c = c.Id;
        r1.npe03__Amount__c = 100;
        r1.npe03__Installment_Period__c = system.label.npe03.RecurringDonationInstallmentPeriodWeekly;
        r1.npe03__Date_Established__c = date.newinstance(1970,6,12);
        r1.npe03__Schedule_Type__c = system.label.npe03.RecurringDonationMultiplyValue;
        r1.npe03__Open_Ended_Status__c = 'None'; 
        insert r1;
        
        Opportunity[] installments1 = [select Name,amount,accountid,CloseDate from Opportunity where npe03__Recurring_Donation__c = :r1.id order by CloseDate];
        system.assertEquals(2,installments1.size());
        system.assertEquals(100,installments1[0].Amount);
        system.assertEquals(date.newinstance(1970,6,12),installments1[0].CloseDate);
        system.assertEquals(a.id,installments1[0].AccountId);
        system.assertEquals(100,installments1[1].Amount);
        system.assertEquals(date.newinstance(1970,6,19),installments1[1].CloseDate);
        system.assertEquals(a.id,installments1[1].AccountId);
    }
    
    static testMethod void insertQuarterlyOpportunities()
    {
        if (strTestOnly != '*' && strTestOnly != 'insertQuarterlyOpportunities') return;
        
         Account a = new Account();
        a.Name = 'test Individual';
        insert a;
        
        Contact c = new Contact();
        c.FirstName = 'test';
        c.LastName = 'contact';
        c.AccountId = a.Id;
        insert c;       

        npe03__Recurring_Donation__c r1 = new npe03__Recurring_Donation__c();
        r1.Name = 'test';
        r1.npe03__Installments__c = 2;
        r1.npe03__Contact__c = c.Id;
        r1.npe03__Amount__c = 100;
        r1.npe03__Installment_Period__c = system.label.npe03.RecurringDonationInstallmentPeriodQuarterly;
        r1.npe03__Date_Established__c = date.newinstance(1970,6,12);
        r1.npe03__Schedule_Type__c = system.label.npe03.RecurringDonationMultiplyValue;
        r1.npe03__Open_Ended_Status__c = 'None'; 
        insert r1;
        
        Opportunity[] installments1 = [select Name,amount,accountid,CloseDate from Opportunity where npe03__Recurring_Donation__c = :r1.id order by CloseDate];
        system.assertEquals(2,installments1.size());
        system.assertEquals(100,installments1[0].Amount);
        system.assertEquals(date.newinstance(1970,6,12),installments1[0].CloseDate);
        system.assertEquals(a.id,installments1[0].AccountId);
        system.assertEquals(100,installments1[1].Amount);
        system.assertEquals(date.newinstance(1970,9,12),installments1[1].CloseDate);
        system.assertEquals(a.id,installments1[1].AccountId);
    }
    
    static testMethod void insertCampaignOpportunities()
    {
        if (strTestOnly != '*' && strTestOnly != 'insertCampaignOpportunities') return;

        setRecurringDonationsSettingsForTest(new npe03__Recurring_Donations_Settings__c());    
        Account a = new Account();
        a.Name = 'test Individual';
        insert a;
        
        Contact c = new Contact();
        c.FirstName = 'test';
        c.LastName = 'contact';
        c.AccountId = a.Id;
        insert c;       

        Campaign camp = new Campaign();
        camp.Name = 'test campaign';
        insert camp;
        
        Id campaignId = camp.id;

        npe03__Recurring_Donation__c r1 = new npe03__Recurring_Donation__c();
        r1.Name = 'test';
        r1.npe03__Installments__c = 2;
        r1.npe03__Contact__c = c.Id;
        r1.npe03__Amount__c = 100;
        r1.npe03__Installment_Period__c = system.label.npe03.RecurringDonationInstallmentPeriodWeekly;
        r1.npe03__Date_Established__c = date.newinstance(1970,6,12);
        r1.npe03__Schedule_Type__c = system.label.npe03.RecurringDonationMultiplyValue;
        r1.npe03__Recurring_Donation_Campaign__c = campaignId;
        r1.npe03__Open_Ended_Status__c = 'None'; 
        insert r1;
        
        Opportunity[] installments1 = [select Name,amount,accountid,CloseDate,CampaignId from Opportunity where npe03__Recurring_Donation__c = :r1.id order by CloseDate];
        system.assertEquals(2,installments1.size());
        system.assertEquals(100,installments1[0].Amount);
        system.assertEquals(date.newinstance(1970,6,12),installments1[0].CloseDate);
        system.assertEquals(campaignId,installments1[0].CampaignId);
        system.assertEquals(a.id,installments1[0].AccountId);
        system.assertEquals(100,installments1[1].Amount);
        system.assertEquals(date.newinstance(1970,6,19),installments1[1].CloseDate);
        system.assertEquals(campaignId,installments1[0].CampaignId);
        system.assertEquals(a.id,installments1[1].AccountId);
    }
    
    static testMethod void deleteRecurringDonation()
    {
        if (strTestOnly != '*' && strTestOnly != 'deleteRecurringDonation') return;

        Account a = new Account();
        a.Name = 'test Individual';
        insert a;
        
        npe03__Recurring_Donation__c r2 = new npe03__Recurring_Donation__c();
        r2.Name = 'test';
        r2.npe03__Installments__c = 3;
        r2.npe03__Organization__c = a.Id;
        r2.npe03__Amount__c = 100;
        r2.npe03__Installment_Period__c = system.label.npe03.RecurringDonationInstallmentPeriodMonthly;
        r2.npe03__Date_Established__c = date.newinstance(1970,6,12);
        r2.npe03__Schedule_Type__c = system.label.npe03.RecurringDonationDivideValue;
        r2.npe03__Open_Ended_Status__c = 'None'; 
        insert r2;
        
        Opportunity[] installments2 = [select Name,amount,accountid,CloseDate from Opportunity where npe03__Recurring_Donation__c = :r2.id];
        system.assertEquals(3,installments2.size());
        system.assertEquals(33.33,installments2[0].Amount);
        system.assertEquals(date.newinstance(1970,6,12),installments2[0].CloseDate);
        system.assertEquals(33.33,installments2[1].Amount);
        system.assertEquals(date.newinstance(1970,7,12),installments2[1].CloseDate);
        system.assertEquals(33.34,installments2[2].Amount);
        system.assertEquals(date.newinstance(1970,8,12),installments2[2].CloseDate);
        system.assertEquals(a.id,installments2[0].AccountId);
        UTIL_Debug.debug('**** '+installments2);
        RD_ProcessControl.hasRun = false;
        try{
            delete r2;
        } catch (exception e1) {
            ERR_Handler.processError(e1, r2, ERR_Handler.Context.RD);
        }
        
        //delete should have failed
        Opportunity[] installments3 = [select amount from Opportunity where npe03__Recurring_Donation__c = :r2.id];
        system.assertEquals(3,installments3.size());
        system.assertEquals(33.33,installments3[0].Amount);
    }
    
    static testMethod void contactRolesOnOppsBucket() {
    	contactRolesOnOppsProcessor(CAO_Constants.BUCKET_PROCESSOR);
    }
    static testMethod void contactRolesOnOppsOne2One() {
        contactRolesOnOppsProcessor(CAO_Constants.ONE_TO_ONE_PROCESSOR);
    }
    static testMethod void contactRolesOnOppsHHAccount() {
        contactRolesOnOppsProcessor(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    }    
    static void contactRolesOnOppsProcessor(string strProcessor)
    {
        if (strTestOnly != '*' && strTestOnly != 'contactRolesOnOppsProcessor') return;
        
        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_and_Orgs_Settings__c (npe01__Account_Processor__c = strProcessor, 
                npe01__Opportunity_Contact_Role_Default_role__c = system.label.npe03.RecurringDonationContactRole));
            
        CAO_Constants.setIndividualAccountForTests(CAO_Constants.INDIVIDUAL_ACCOUNT_NAME_FOR_TESTS);
        
        Contact c = new Contact();
        c.FirstName = 'test';
        c.LastName = 'contact';
        insert c;       
        Test.startTest();
        npe03__Recurring_Donation__c r1 = new npe03__Recurring_Donation__c();
        r1.Name = 'test';
        r1.npe03__Installments__c = 2;
        r1.npe03__Contact__c = c.Id;
        r1.npe03__Open_Ended_Status__c = 'None'; 
        r1.npe03__Amount__c = 100;
        r1.npe03__Installment_Period__c = system.label.npe03.RecurringDonationInstallmentPeriodWeekly;
        r1.npe03__Date_Established__c = date.newinstance(1970,6,12);
        r1.npe03__Schedule_Type__c = system.label.npe03.RecurringDonationMultiplyValue;
        insert r1;
        Test.stopTest();
        OpportunityContactRole[] installmentCRs = [select ContactId,OpportunityId,Role from OpportunityContactRole where Opportunity.npe03__Recurring_Donation__c = :r1.id];
        system.assertEquals(2,installmentCRs.size());
        system.assertEquals(system.label.npe03.RecurringDonationContactRole,installmentCRs[0].Role);
    }
    
    static testMethod void testSettingsCreation(){
        if (strTestOnly != '*' && strTestOnly != 'testSettingsCreation') return;

        delete [select id from npe03__Recurring_Donations_Settings__c];
        npe03__Recurring_Donations_Settings__c rds = UTIL_CustomSettingsFacade.getRecurringDonationsSettings();
        system.assertEquals(12, rds.npe03__Opportunity_Forecast_Months__c);
        system.assertEquals(50, rds.npe03__Maximum_Donations__c);
        system.assertEquals(RD_RecurringDonations.RecurringDonationCloseOptions.Mark_Opportunities_Closed_Lost.name(), rds.npe03__Open_Opportunity_Behavior__c);           
    }
    
    
    //tests inserts of various types of open ended donations
    static testMethod void insertOpenEndedRecurringDonations(){
        if (strTestOnly != '*' && strTestOnly != 'insertOpenEndedRecurringDonations') return;

        setRecurringDonationsSettingsForTest(
        new npe03__Recurring_Donations_Settings__c(
        npe03__Opportunity_Forecast_Months__c = 12,
        npe03__Maximum_Donations__c = 50,
        npe03__Open_Opportunity_Behavior__c = RD_RecurringDonations.RecurringDonationCloseOptions.Mark_Opportunities_Closed_Lost.name()        
        ));             
        
        Account a = new Account();
        a.Name = 'test Individual';
        insert a;
        
        Contact c = new Contact();
        c.FirstName = 'test';
        c.LastName = 'contact';
        c.AccountId = a.Id;
        insert c;       
        
        Campaign camp = new Campaign(name = 'Campaign', isActive = true);
        insert camp;
        
        list<npe03__Recurring_Donation__c> rdlist = new list<npe03__Recurring_Donation__c>();
        
        npe03__Recurring_Donation__c RD = new npe03__Recurring_Donation__c();
        RD.Name = 'testweekly';
        RD.npe03__Contact__c = c.Id;
        RD.npe03__Amount__c = 100;
        RD.npe03__Installment_Period__c = system.label.npe03.RecurringDonationInstallmentPeriodWeekly;
        RD.npe03__Date_Established__c = system.today().toStartOfMonth();
        RD.npe03__Schedule_Type__c = system.label.npe03.RecurringDonationMultiplyValue;
        RD.npe03__Open_Ended_Status__c = system.label.npe03.RecurringDonationOpenStatus;
        rdlist.add(RD);
        
        
        RD = RD.clone(false);
        RD.Name = 'testmonthly';
        RD.npe03__Installment_Period__c = system.label.npe03.RecurringDonationInstallmentPeriodMonthly;
        RD.npe03__Contact__c = null;
        RD.npe03__Organization__c = a.id;
        RD.npe03__Recurring_Donation_Campaign__c = camp.id;
        rdlist.add(RD);
        
        RD = RD.clone(false);
        RD.Name = 'testquarterly';
        RD.npe03__Installment_Period__c = system.label.npe03.RecurringDonationInstallmentPeriodQuarterly;
        rdlist.add(RD);
        
        RD = RD.clone(false);
        RD.Name = 'testyearly';
        RD.npe03__Installment_Period__c = system.label.npe03.RecurringDonationInstallmentPeriodYearly;
        rdlist.add(RD);
        
        RD = RD.clone(false);
        RD.Name = 'testbadinstallment';
        RD.npe03__Installment_Period__c = 'GarbageValue';
        rdlist.add(RD);
        
        test.startTest();
        insert rdlist;
        test.stopTest();
        
        system.assertEquals(12, [select count() from Opportunity where npe03__Recurring_Donation__r.Name = 'testmonthly']);
        system.assertEquals(4, [select count() from Opportunity where npe03__Recurring_Donation__r.Name = 'testquarterly']);
        system.assertEquals(1, [select count() from Opportunity where npe03__Recurring_Donation__r.Name = 'testyearly']);
        integer cOpp =  [select count() from Opportunity where npe03__Recurring_Donation__r.Name = 'testweekly'];
        system.assert(cOpp == 52 || cOpp == 53);        
    }
    
    static testMethod void updateOpenEndedRecurringDonationMonthly(){
        if (strTestOnly != '*' && strTestOnly != 'updateOpenEndedRecurringDonationMonthly') return;

        setRecurringDonationsSettingsForTest(
        new npe03__Recurring_Donations_Settings__c(
        npe03__Opportunity_Forecast_Months__c = 12,
        npe03__Maximum_Donations__c = 50,
        npe03__Open_Opportunity_Behavior__c = RD_RecurringDonations.RecurringDonationCloseOptions.Mark_Opportunities_Closed_Lost.name()        
        ));           
        
        Account a = new Account();
        a.Name = 'test Individual';
        insert a;
        
        Contact c = new Contact();
        c.FirstName = 'test';
        c.LastName = 'contact';
        c.AccountId = a.Id;
        insert c;       

        npe03__Recurring_Donation__c r1 = new npe03__Recurring_Donation__c();
        r1.Name = 'test';
        r1.npe03__Installments__c = 2;
        r1.npe03__Contact__c = c.Id;
        r1.npe03__Amount__c = 100;
        r1.npe03__Installment_Period__c = system.label.npe03.RecurringDonationInstallmentPeriodWeekly;
        r1.npe03__Date_Established__c = date.newinstance(1970,6,12);
        r1.npe03__Schedule_Type__c = system.label.npe03.RecurringDonationMultiplyValue;
        r1.npe03__Open_Ended_Status__c = system.label.npe03.RecurringDonationOpenStatus;
        r1.npe03__Next_Payment_Date__c = system.today().toStartOfMonth();
        insert r1;
        
        list<Opportunity> originalOpps = new list<Opportunity>([select id, Name,amount,accountid,CloseDate from Opportunity where npe03__Recurring_Donation__c = :r1.id order by CloseDate]);          
        
        integer cOpp =  originalOpps.size();
        system.assert(cOpp == 52 || cOpp == 53);        
        system.assertEquals(100, originalOpps[0].Amount);
        RD_ProcessControl.hasRun = false;
        Test.startTest();
        r1.npe03__Installment_Period__c = system.label.npe03.RecurringDonationInstallmentPeriodMonthly;
        update r1;
        Test.stopTest();
        
        system.assertEquals(12, [select count() from Opportunity where npe03__Recurring_Donation__c = :r1.id]);        
    }
    static testMethod void updateOpenEndedRecurringDonation1an15(){
        if (strTestOnly != '*' && strTestOnly != 'updateOpenEndedRecurringDonation1an15') return;

        setRecurringDonationsSettingsForTest(
        new npe03__Recurring_Donations_Settings__c(
        npe03__Opportunity_Forecast_Months__c = 12,
        npe03__Maximum_Donations__c = 50,
        npe03__Open_Opportunity_Behavior__c = RD_RecurringDonations.RecurringDonationCloseOptions.Mark_Opportunities_Closed_Lost.name(),
        npe03__Add_Campaign_to_All_Opportunites__c = true        
        ));           
        
        Account a = new Account();
        a.Name = 'test Individual';
        insert a;
        
        Contact c = new Contact();
        c.FirstName = 'test';
        c.LastName = 'contact';
        c.AccountId = a.Id;
        insert c;       

        npe03__Recurring_Donation__c r1 = new npe03__Recurring_Donation__c();
        r1.Name = 'test';
        r1.npe03__Installments__c = 2;
        r1.npe03__Contact__c = c.Id;
        r1.npe03__Amount__c = 100;
        r1.npe03__Installment_Period__c = system.label.npe03.RecurringDonationInstallmentPeriod1stand15th;
        r1.npe03__Date_Established__c = date.newinstance(1970,6,12);
        r1.npe03__Schedule_Type__c = system.label.npe03.RecurringDonationMultiplyValue;
        r1.npe03__Open_Ended_Status__c = system.label.npe03.RecurringDonationOpenStatus;
        r1.npe03__Next_Payment_Date__c = system.today();
       
        RD_ProcessControl.hasRun = false;
        Test.startTest();
        insert r1;
        Test.stopTest();
        list<Opportunity> originalOpps = new list<Opportunity>([select id, Name,amount,accountid,CloseDate from Opportunity where npe03__Recurring_Donation__c = :r1.id order by CloseDate]);          
        integer cOpp =  originalOpps.size();
        system.assert(cOpp == 23 || cOpp == 24);        
        system.assertEquals(100, originalOpps[0].Amount);        
    }
    
    static testMethod void updateOpenEndedRecurringDonationYearly(){
        if (strTestOnly != '*' && strTestOnly != 'updateOpenEndedRecurringDonationYearly') return;

        setRecurringDonationsSettingsForTest(
        new npe03__Recurring_Donations_Settings__c(
        npe03__Opportunity_Forecast_Months__c = 12,
        npe03__Maximum_Donations__c = 50,
        npe03__Open_Opportunity_Behavior__c = RD_RecurringDonations.RecurringDonationCloseOptions.Mark_Opportunities_Closed_Lost.name()        
        ));           
        
        Account a = new Account();
        a.Name = 'test Individual';
        insert a;
        
        Contact c = new Contact();
        c.FirstName = 'test';
        c.LastName = 'contact';
        c.AccountId = a.Id;
        insert c;       

        npe03__Recurring_Donation__c r1 = new npe03__Recurring_Donation__c();
        r1.Name = 'test';
        r1.npe03__Installments__c = 2;
        r1.npe03__Contact__c = c.Id;
        r1.npe03__Amount__c = 100;
        r1.npe03__Installment_Period__c = system.label.npe03.RecurringDonationInstallmentPeriodWeekly;
        r1.npe03__Date_Established__c = date.newinstance(1970,6,12);
        r1.npe03__Schedule_Type__c = system.label.npe03.RecurringDonationMultiplyValue;
        r1.npe03__Open_Ended_Status__c = system.label.npe03.RecurringDonationOpenStatus;
        r1.npe03__Next_Payment_Date__c = system.today().toStartOfMonth();
        insert r1;
        
        list<Opportunity> originalOpps = new list<Opportunity>([select id, Name,amount,accountid,CloseDate from Opportunity where npe03__Recurring_Donation__c = :r1.id order by CloseDate]);          
        
        integer cOpp =  originalOpps.size();
        system.assert(cOpp == 52 || cOpp == 53);        
        system.assertEquals(100, originalOpps[0].Amount);
        RD_ProcessControl.hasRun = false;
        Test.startTest();
        r1.npe03__Installment_Period__c = system.label.npe03.RecurringDonationInstallmentPeriodYearly;
        update r1;
        Test.stopTest();
        
        system.assertEquals(1, [select count() from Opportunity where npe03__Recurring_Donation__c = :r1.id]);
    }
    static testMethod void updateOpenEndedRecurringDonationWeekly(){
        if (strTestOnly != '*' && strTestOnly != 'updateOpenEndedRecurringDonationWeekly') return;

            setRecurringDonationsSettingsForTest(
        new npe03__Recurring_Donations_Settings__c(
        npe03__Opportunity_Forecast_Months__c = 12,
        npe03__Maximum_Donations__c = 50,
        npe03__Open_Opportunity_Behavior__c = RD_RecurringDonations.RecurringDonationCloseOptions.Mark_Opportunities_Closed_Lost.name()        
        ));           
        
        Account a = new Account();
        a.Name = 'test Individual';
        insert a;
        
        Contact c = new Contact();
        c.FirstName = 'test';
        c.LastName = 'contact';
        c.AccountId = a.Id;
        insert c;       

        npe03__Recurring_Donation__c r1 = new npe03__Recurring_Donation__c();
        r1.Name = 'test';
        r1.npe03__Installments__c = 2;
        r1.npe03__Contact__c = c.Id;
        r1.npe03__Amount__c = 100;
        r1.npe03__Installment_Period__c = system.label.npe03.RecurringDonationInstallmentPeriodMonthly;
        r1.npe03__Date_Established__c = date.newinstance(1970,6,12);
        r1.npe03__Schedule_Type__c = system.label.npe03.RecurringDonationMultiplyValue;
        r1.npe03__Open_Ended_Status__c = system.label.npe03.RecurringDonationOpenStatus;
        r1.npe03__Next_Payment_Date__c = system.today().toStartOfMonth();
        insert r1;
        
        list<Opportunity> originalOpps = new list<Opportunity>([select id, Name,amount,accountid,CloseDate from Opportunity where npe03__Recurring_Donation__c = :r1.id order by CloseDate]);          
        
        system.assertEquals(12, originalOpps.size());
        system.assertEquals(100, originalOpps[0].Amount);
        RD_ProcessControl.hasRun = false;
        Test.startTest();
        r1.npe03__Installment_Period__c = system.label.npe03.RecurringDonationInstallmentPeriodWeekly;
        update r1;
        Test.stopTest();        
        integer cOpp = [select count() from Opportunity where npe03__Recurring_Donation__c = :r1.id];
        system.assert(cOpp == 52 || cOpp == 53);        
    }
    
    static testMethod void updateOpenEndedRecurringDonationQuarterly(){
        if (strTestOnly != '*' && strTestOnly != 'updateOpenEndedRecurringDonationQuarterly') return;

        setRecurringDonationsSettingsForTest(
        new npe03__Recurring_Donations_Settings__c(
        npe03__Opportunity_Forecast_Months__c = 12,
        npe03__Maximum_Donations__c = 50,
        npe03__Open_Opportunity_Behavior__c = RD_RecurringDonations.RecurringDonationCloseOptions.Mark_Opportunities_Closed_Lost.name()        
        ));           
        
        Account a = new Account();
        a.Name = 'test Individual';
        insert a;
        
        Contact c = new Contact();
        c.FirstName = 'test';
        c.LastName = 'contact';
        c.AccountId = a.Id;
        insert c;       

        npe03__Recurring_Donation__c r1 = new npe03__Recurring_Donation__c();
        r1.Name = 'test';
        r1.npe03__Installments__c = 2;
        r1.npe03__Contact__c = c.Id;
        r1.npe03__Amount__c = 100;
        r1.npe03__Installment_Period__c = system.label.npe03.RecurringDonationInstallmentPeriodWeekly;
        r1.npe03__Date_Established__c = date.newinstance(1970,6,12);
        r1.npe03__Schedule_Type__c = system.label.npe03.RecurringDonationMultiplyValue;
        r1.npe03__Open_Ended_Status__c = system.label.npe03.RecurringDonationOpenStatus;
        r1.npe03__Next_Payment_Date__c = system.today().toStartOfMonth();
        insert r1;
        
        list<Opportunity> originalOpps = new list<Opportunity>([select id, Name,amount,accountid,CloseDate from Opportunity where npe03__Recurring_Donation__c = :r1.id order by CloseDate]);          
        
        integer cOpp =  originalOpps.size();
        system.assert(cOpp == 52 || cOpp == 53);        
        system.assertEquals(100, originalOpps[0].Amount);
        RD_ProcessControl.hasRun = false;
        Test.startTest();
        r1.npe03__Installment_Period__c = system.label.npe03.RecurringDonationInstallmentPeriodQuarterly;
        update r1;
        Test.stopTest();
        
        system.assertEquals(4, [select count() from Opportunity where npe03__Recurring_Donation__c = :r1.id]);
    }    
        
    //test closing an opportunity for an open recurring donation
    static testMethod void closeOppForOpenEndedRecurringDonationWeekly(){
        if (strTestOnly != '*' && strTestOnly != 'closeOppForOpenEndedRecurringDonationWeekly') return;

        setRecurringDonationsSettingsForTest(
        new npe03__Recurring_Donations_Settings__c(
        npe03__Opportunity_Forecast_Months__c = 12,
        npe03__Maximum_Donations__c = 50,
        npe03__Open_Opportunity_Behavior__c = RD_RecurringDonations.RecurringDonationCloseOptions.Mark_Opportunities_Closed_Lost.name()        
        ));           
        
        Account a = new Account();
        a.Name = 'test Individual';
        insert a;
        
        Contact c = new Contact();
        c.FirstName = 'test';
        c.LastName = 'contact';
        c.AccountId = a.Id;
        insert c;       

        npe03__Recurring_Donation__c r1 = new npe03__Recurring_Donation__c();
        r1.Name = 'test';
        r1.npe03__Installments__c = 2;
        r1.npe03__Contact__c = c.Id;
        r1.npe03__Amount__c = 100;
        r1.npe03__Installment_Period__c = system.label.npe03.RecurringDonationInstallmentPeriodWeekly;
        r1.npe03__Date_Established__c = date.newinstance(1970,6,12);
        r1.npe03__Schedule_Type__c = system.label.npe03.RecurringDonationMultiplyValue;
        r1.npe03__Open_Ended_Status__c = system.label.npe03.RecurringDonationOpenStatus;
        r1.npe03__Next_Payment_Date__c = system.today().toStartOfMonth();
        r1.OwnerId = system.Userinfo.getUserId();
        insert r1;
        
        list<Opportunity> originalOpps = new list<Opportunity>([select id, Name,amount,accountid,CloseDate from Opportunity where npe03__Recurring_Donation__c = :r1.id order by CloseDate]);
        integer cOpp =  originalOpps.size();
        system.assert(cOpp == 52 || cOpp == 53);        
        
        Opportunity o = originalOpps[0];
        string closedstage = [select masterlabel from opportunitystage where isActive = true and iswon = true and isClosed = true limit 1].masterlabel;
        o.StageName = closedstage;
        o.CloseDate = system.today();
        RD_ProcessControl.hasRun = false;
        Test.startTest();        
        //update opp
        update o;
        //call the update method
        RD_RecurringDonations.evaluateRecurringDonationsForNewOppInsert(new list<npe03__Recurring_Donation__c>{r1});
        Test.stopTest();        
        
        npe03__Recurring_Donation__c rd = [select npe03__Last_Payment_Date__c from npe03__Recurring_Donation__c where id = :r1.id];     
        
        system.assertEquals(cOpp - 1, [select count() from Opportunity where npe03__Recurring_Donation__c = :r1.id and isClosed = false]);
        system.assertEquals(system.today(), rd.npe03__Last_Payment_Date__c);
    }
    //test closing an opportunity for an open recurring donation
    static testMethod void closeOppForOpenEndedRecurringDonationMonthly(){
        if (strTestOnly != '*' && strTestOnly != 'closeOppForOpenEndedRecurringDonationMonthly') return;

        setRecurringDonationsSettingsForTest(
        new npe03__Recurring_Donations_Settings__c(
        npe03__Opportunity_Forecast_Months__c = 6,
        npe03__Maximum_Donations__c = 50,
        npe03__Open_Opportunity_Behavior__c = RD_RecurringDonations.RecurringDonationCloseOptions.Mark_Opportunities_Closed_Lost.name()        
        ));           
        
        Account a = new Account();
        a.Name = 'test Individual';
        insert a;
        
        Contact c = new Contact();
        c.FirstName = 'test';
        c.LastName = 'contact';
        c.AccountId = a.Id;
        insert c;       

        list<npe03__Recurring_Donation__c> rdlist = new list<npe03__Recurring_Donation__c>();
        npe03__Recurring_Donation__c r1 = new npe03__Recurring_Donation__c();
        r1.Name = 'test';
        r1.npe03__Installments__c = 2;
        r1.npe03__Contact__c = c.Id;
        r1.npe03__Amount__c = 100;
        r1.npe03__Installment_Period__c = system.label.npe03.RecurringDonationInstallmentPeriodYearly;
        r1.npe03__Date_Established__c = date.newinstance(1970,6,12);
        r1.npe03__Schedule_Type__c = system.label.npe03.RecurringDonationMultiplyValue;
        r1.npe03__Open_Ended_Status__c = system.label.npe03.RecurringDonationOpenStatus;
        r1.npe03__Next_Payment_Date__c = system.today();
        r1.OwnerId = system.Userinfo.getUserId();
        rdlist.add(r1);
        insert rdlist; 
        
        system.assertNotEquals(null, r1.id);
        list<Opportunity> originalOpps = new list<Opportunity>([select id, Name,amount,accountid,CloseDate from Opportunity where npe03__Recurring_Donation__r.id = :r1.id order by CloseDate]);
        system.assertEquals(1, originalOpps.size());          
        
        Opportunity o1 = originalOpps[0];
        string closedstage = [select masterlabel from opportunitystage where isActive = true and iswon = true and isClosed = true limit 1].masterlabel;
        o1.StageName = closedstage;
        o1.CloseDate = system.today();
        list<Opportunity> oppList = new list<Opportunity>{o1};
        RD_ProcessControl.hasRun = false;
        Test.startTest();        
        //update opp
        update oppList;
        //call the update method
        RD_RecurringDonations.evaluateRecurringDonationsForNewOppInsert(new list<npe03__Recurring_Donation__c>{r1});
        Test.stopTest();
        npe03__Recurring_Donation__c rd = [select npe03__Last_Payment_Date__c from npe03__Recurring_Donation__c where id = :r1.id];     
        system.assertEquals(system.today(), rd.npe03__Last_Payment_Date__c);
        originalOpps = new list<Opportunity>([select id, Name,amount,accountid,CloseDate from Opportunity where isClosed = false and npe03__Recurring_Donation__r.id = :r1.id]);
        system.assertEquals(0, originalOpps.size());          
    }
    
    //test closing an opportunity for an open recurring donation
    static testMethod void closeOppForOpenEndedRecurringDonationQuarterly(){
        if (strTestOnly != '*' && strTestOnly != 'closeOppForOpenEndedRecurringDonationQuarterly') return;

        setRecurringDonationsSettingsForTest(
        new npe03__Recurring_Donations_Settings__c(
        npe03__Opportunity_Forecast_Months__c = 12,
        npe03__Maximum_Donations__c = 50,
        npe03__Open_Opportunity_Behavior__c = RD_RecurringDonations.RecurringDonationCloseOptions.Mark_Opportunities_Closed_Lost.name()        
        ));           
        
        Account a = new Account();
        a.Name = 'test Individual';
        insert a;
        
        Contact c = new Contact();
        c.FirstName = 'test';
        c.LastName = 'contact';
        c.AccountId = a.Id;
        insert c;       

        npe03__Recurring_Donation__c r1 = new npe03__Recurring_Donation__c();
        r1.Name = 'test';
        r1.npe03__Installments__c = 2;
        r1.npe03__Contact__c = c.Id;
        r1.npe03__Amount__c = 100;
        r1.npe03__Installment_Period__c = system.label.npe03.RecurringDonationInstallmentPeriodQuarterly;
        r1.npe03__Date_Established__c = date.newinstance(1970,6,12);
        r1.npe03__Schedule_Type__c = system.label.npe03.RecurringDonationMultiplyValue;
        r1.npe03__Open_Ended_Status__c = system.label.npe03.RecurringDonationOpenStatus;
        r1.npe03__Next_Payment_Date__c = system.today().toStartOfMonth();
        r1.OwnerId = system.Userinfo.getUserId();
        insert r1;
        
        list<Opportunity> originalOpps = new list<Opportunity>([select id, Name,amount,accountid,CloseDate from Opportunity where npe03__Recurring_Donation__c = :r1.id order by CloseDate]);
        system.assertEquals(4, originalOpps.size());          
        
        Opportunity o = originalOpps[0];
        system.debug('**** DJH gonna close opp with date: ' + o.CloseDate);
        system.assertEquals(system.today().toStartOfMonth(), o.CloseDate);
        string closedstage = [select masterlabel from opportunitystage where isActive = true and iswon = true and isClosed = true limit 1].masterlabel;
        o.StageName = closedstage;
        o.CloseDate = system.today();
        RD_ProcessControl.hasRun = false;
        Test.startTest();        
        //update opp
        update o;
        //call the update method
        RD_RecurringDonations.evaluateRecurringDonationsForNewOppInsert(new list<npe03__Recurring_Donation__c>{r1});
        Test.stopTest();
                
        npe03__Recurring_Donation__c rd = [select npe03__Last_Payment_Date__c from npe03__Recurring_Donation__c where id = :r1.id];     
        system.assertEquals(system.today(), rd.npe03__Last_Payment_Date__c);
        system.assertEquals(3, [select count() from Opportunity where npe03__Recurring_Donation__c = :r1.id and isClosed = false]);        
    }
    
    //test closing an opportunity for an open recurring donation
    static testMethod void closeOppForOpenEndedRecurringDonationCustomWeeks(){
        if (strTestOnly != '*' && strTestOnly != 'closeOppForOpenEndedRecurringDonationCustomWeeks') return;

        setRecurringDonationsSettingsForTest(
        new npe03__Recurring_Donations_Settings__c(
        npe03__Opportunity_Forecast_Months__c = 12,
        npe03__Maximum_Donations__c = 50,
        npe03__Open_Opportunity_Behavior__c = RD_RecurringDonations.RecurringDonationCloseOptions.Mark_Opportunities_Closed_Lost.name()        
        ));           
        
        Account a = new Account();
        a.Name = 'test Individual';
        insert a;
        
        Contact c = new Contact();
        c.FirstName = 'test';
        c.LastName = 'contact';
        c.AccountId = a.Id;
        insert c;       

        npe03__Custom_Installment_Settings__c cis = new npe03__Custom_Installment_Settings__c(
        npe03__Increment__c = 'Weeks',
        npe03__Value__c = 2,
        Name = 'TESTCIS'        
        );
        insert cis;        

        npe03__Recurring_Donation__c r1 = new npe03__Recurring_Donation__c();
        r1.Name = 'test';
        r1.npe03__Installments__c = 2;
        r1.npe03__Organization__c = a.id;
        r1.npe03__Amount__c = 100;
        r1.npe03__Installment_Period__c = 'TESTCIS';
        r1.npe03__Date_Established__c = date.newinstance(1970,6,12);
        r1.npe03__Schedule_Type__c = system.label.npe03.RecurringDonationMultiplyValue;
        r1.npe03__Open_Ended_Status__c = system.label.npe03.RecurringDonationOpenStatus;
        r1.npe03__Next_Payment_Date__c = system.today().toStartOfMonth();
        r1.OwnerId = system.Userinfo.getUserId();
        insert r1;
        
        list<Opportunity> originalOpps = new list<Opportunity>([select id, Name,amount,accountid,CloseDate from Opportunity where npe03__Recurring_Donation__c = :r1.id order by CloseDate]);
        integer cOpp = originalOpps.size();
        system.assert(cOpp == 26 || cOpp == 27);          
        
        Opportunity o = originalOpps[0];
        string closedstage = [select masterlabel from opportunitystage where isActive = true and iswon = true and isClosed = true limit 1].masterlabel;
        o.StageName = closedstage;
        o.CloseDate = system.today();
        RD_ProcessControl.hasRun = false;
        Test.startTest();        
        //update opp
        update o;
        //call the update method
        RD_RecurringDonations.evaluateRecurringDonationsForNewOppInsert(new list<npe03__Recurring_Donation__c>{r1});
        Test.stopTest();        
        
        npe03__Recurring_Donation__c rd = [select npe03__Last_Payment_Date__c from npe03__Recurring_Donation__c where id = :r1.id];     
        
        system.assert(26 <= [select count() from Opportunity where npe03__Recurring_Donation__c = :r1.id and isClosed = false]);
        system.assertEquals(system.today(), rd.npe03__Last_Payment_Date__c);
    }
    
    
       //test closing an opportunity for an open recurring donation
    static testMethod void closeOppForOpenEndedRecurringDonationCustomDays(){
        if (strTestOnly != '*' && strTestOnly != 'closeOppForOpenEndedRecurringDonationCustomDays') return;

        setRecurringDonationsSettingsForTest(
        new npe03__Recurring_Donations_Settings__c(
        npe03__Opportunity_Forecast_Months__c = 1,
        npe03__Maximum_Donations__c = 50,
        npe03__Open_Opportunity_Behavior__c = RD_RecurringDonations.RecurringDonationCloseOptions.Mark_Opportunities_Closed_Lost.name()        
        ));           
        
        Account a = new Account();
        a.Name = 'test Individual';
        insert a;
        
        Contact c = new Contact();
        c.FirstName = 'test';
        c.LastName = 'contact';
        c.AccountId = a.Id;
        insert c;       

        npe03__Custom_Installment_Settings__c cis = new npe03__Custom_Installment_Settings__c(
        npe03__Increment__c = 'Days',
        npe03__Value__c = 2,
        Name = 'TESTCIS'        
        );
        insert cis;        

        npe03__Recurring_Donation__c r1 = new npe03__Recurring_Donation__c();
        r1.Name = 'test';
        r1.npe03__Installments__c = 2;
        r1.npe03__Organization__c = a.id;
        r1.npe03__Amount__c = 100;
        r1.npe03__Installment_Period__c = 'TESTCIS';
        r1.npe03__Date_Established__c = date.newinstance(1970,6,12);
        r1.npe03__Schedule_Type__c = system.label.npe03.RecurringDonationMultiplyValue;
        r1.npe03__Open_Ended_Status__c = system.label.npe03.RecurringDonationOpenStatus;
        r1.npe03__Next_Payment_Date__c = system.today().toStartOfMonth();
        insert r1;
        
        list<Opportunity> originalOpps = new list<Opportunity>([select id, Name,amount,accountid,CloseDate from Opportunity where npe03__Recurring_Donation__c = :r1.id order by CloseDate]);
        system.assertEquals(15, originalOpps.size());          
        
        Opportunity o = originalOpps[0];
        string closedstage = [select masterlabel from opportunitystage where isActive = true and iswon = true and isClosed = true limit 1].masterlabel;
        o.StageName = closedstage;
        o.CloseDate = system.today();
        RD_ProcessControl.hasRun = false;
        Test.startTest();        
        //update opp
        update o;
        //call the update method        
        Test.stopTest();        
        
        npe03__Recurring_Donation__c rd = [select npe03__Last_Payment_Date__c from npe03__Recurring_Donation__c where id = :r1.id];     
        
        system.assertEquals(14, [select count() from Opportunity where npe03__Recurring_Donation__c = :r1.id and isClosed = false]);
        system.assertEquals(system.today(), rd.npe03__Last_Payment_Date__c);
    }
    
    
       //test closing an opportunity for an open recurring donation
    static testMethod void closeOppForOpenEndedRecurringDonationCustomMonths(){
        if (strTestOnly != '*' && strTestOnly != 'closeOppForOpenEndedRecurringDonationCustomMonths') return;

        setRecurringDonationsSettingsForTest(
        new npe03__Recurring_Donations_Settings__c(
        npe03__Opportunity_Forecast_Months__c = 12,
        npe03__Maximum_Donations__c = 50,
        npe03__Open_Opportunity_Behavior__c = RD_RecurringDonations.RecurringDonationCloseOptions.Mark_Opportunities_Closed_Lost.name(),
        npe03__Add_Campaign_to_All_Opportunites__c = true        
        ));           
        
        Account a = new Account();
        a.Name = 'test Individual';
        insert a;
        
        Contact c = new Contact();
        c.FirstName = 'test';
        c.LastName = 'contact';
        c.AccountId = a.Id;
        insert c;       

        npe03__Custom_Installment_Settings__c cis = new npe03__Custom_Installment_Settings__c(
        npe03__Increment__c = 'Months',
        npe03__Value__c = 2,
        Name = 'TESTCIS'        
        );
        insert cis;        

        npe03__Recurring_Donation__c r1 = new npe03__Recurring_Donation__c();
        r1.Name = 'test';
        r1.npe03__Installments__c = 2;
        r1.npe03__Organization__c = a.id;
        r1.npe03__Amount__c = 100;
        r1.npe03__Installment_Period__c = 'TESTCIS';
        r1.npe03__Date_Established__c = date.newinstance(2000,1,1);
        r1.npe03__Schedule_Type__c = system.label.npe03.RecurringDonationMultiplyValue;
        r1.npe03__Open_Ended_Status__c = system.label.npe03.RecurringDonationOpenStatus;
        r1.npe03__Next_Payment_Date__c = system.today().toStartOfMonth();
        r1.OwnerId = system.Userinfo.getUserId();
        insert r1;
        
        list<Opportunity> originalOpps = new list<Opportunity>([select id, Name,amount,accountid,CloseDate from Opportunity where npe03__Recurring_Donation__c = :r1.id order by CloseDate]);
        system.assertEquals(6, originalOpps.size());          
        
        Opportunity o = originalOpps[0];
        string closedstage = [select masterlabel from opportunitystage where isActive = true and iswon = true and isClosed = true limit 1].masterlabel;
        o.StageName = closedstage;
        o.CloseDate = system.today();
        RD_ProcessControl.hasRun = false;
        Test.startTest();        
        //update opp
        update o;
        //call the update method
        RD_RecurringDonations.evaluateRecurringDonationsForNewOppInsert(new list<npe03__Recurring_Donation__c>{r1});
        Test.stopTest();        
        
        npe03__Recurring_Donation__c rd = [select npe03__Last_Payment_Date__c from npe03__Recurring_Donation__c where id = :r1.id];     
        
        system.assertEquals(5, [select count() from Opportunity where npe03__Recurring_Donation__c = :r1.id and isClosed = false]);
        system.assertEquals(system.today(), rd.npe03__Last_Payment_Date__c);
    }
       //test closing an opportunity for an open recurring donation
    static testMethod void closeOppForOpenEndedRecurringDonationCustomYears(){
        if (strTestOnly != '*' && strTestOnly != 'closeOppForOpenEndedRecurringDonationCustomYears') return;

        setRecurringDonationsSettingsForTest(
        new npe03__Recurring_Donations_Settings__c(
        npe03__Opportunity_Forecast_Months__c = 12,
        npe03__Maximum_Donations__c = 50,
        npe03__Open_Opportunity_Behavior__c = RD_RecurringDonations.RecurringDonationCloseOptions.Mark_Opportunities_Closed_Lost.name(),
        npe03__Add_Campaign_to_All_Opportunites__c = true       
        ));           
        
        Account a = new Account();
        a.Name = 'test Individual';
        insert a;
        
        Contact c = new Contact();
        c.FirstName = 'test';
        c.LastName = 'contact';
        c.AccountId = a.Id;
        insert c;       

        npe03__Custom_Installment_Settings__c cis = new npe03__Custom_Installment_Settings__c(
        npe03__Increment__c = 'Years',
        npe03__Value__c = 2,
        Name = 'TESTCIS'        
        );
        insert cis;        

        npe03__Recurring_Donation__c r1 = new npe03__Recurring_Donation__c();
        r1.Name = 'test';
        r1.npe03__Installments__c = 2;
        r1.npe03__Organization__c = a.id;
        r1.npe03__Amount__c = 100;
        r1.npe03__Installment_Period__c = 'TESTCIS';
        r1.npe03__Date_Established__c = date.newinstance(1970,6,12);
        r1.npe03__Schedule_Type__c = system.label.npe03.RecurringDonationMultiplyValue;
        r1.npe03__Open_Ended_Status__c = system.label.npe03.RecurringDonationOpenStatus;
        r1.npe03__Next_Payment_Date__c = system.today();
        r1.OwnerId = system.Userinfo.getUserId();
        insert r1;
        
        list<Opportunity> originalOpps = new list<Opportunity>([select id, Name,amount,accountid,CloseDate from Opportunity where npe03__Recurring_Donation__c = :r1.id order by CloseDate]);
        system.assertEquals(1, originalOpps.size());          
        
        Opportunity o = originalOpps[0];
        string closedstage = [select masterlabel from opportunitystage where isActive = true and iswon = true and isClosed = true limit 1].masterlabel;
        o.StageName = closedstage;
        o.CloseDate = system.today();
        RD_ProcessControl.hasRun = false;
        Test.startTest();        
        //update opp
        update o;
        //call the update method
        RD_RecurringDonations.evaluateRecurringDonationsForNewOppInsert(new list<npe03__Recurring_Donation__c>{r1});
        Test.stopTest();        
        
        npe03__Recurring_Donation__c rd = [select npe03__Last_Payment_Date__c from npe03__Recurring_Donation__c where id = :r1.id];     
        
        system.assertEquals(0, [select count() from Opportunity where npe03__Recurring_Donation__c = :r1.id and isClosed = false]);
        system.assertEquals(system.today(), rd.npe03__Last_Payment_Date__c);
    }
    
    //test closing an opportunity for an open recurring donation
    static testMethod void closeOppForOpenEndedRecurringDonationYearly(){
        if (strTestOnly != '*' && strTestOnly != 'closeOppForOpenEndedRecurringDonationYearly') return;

        setRecurringDonationsSettingsForTest(
        new npe03__Recurring_Donations_Settings__c(
        npe03__Opportunity_Forecast_Months__c = 12,
        npe03__Maximum_Donations__c = 50,
        npe03__Open_Opportunity_Behavior__c = RD_RecurringDonations.RecurringDonationCloseOptions.Mark_Opportunities_Closed_Lost.name()        
        ));           
        
        Account a = new Account();
        a.Name = 'test Individual';
        insert a;
        
        Contact c = new Contact();
        c.FirstName = 'test';
        c.LastName = 'contact';
        c.AccountId = a.Id;
        insert c;       

        npe03__Recurring_Donation__c r1 = new npe03__Recurring_Donation__c();
        r1.Name = 'test';
        r1.npe03__Installments__c = 2;
        r1.npe03__Organization__c = a.id;
        r1.npe03__Amount__c = 100;
        r1.npe03__Installment_Period__c = system.label.npe03.RecurringDonationInstallmentPeriodYearly;
        r1.npe03__Date_Established__c = date.newinstance(1970,6,12);
        r1.npe03__Schedule_Type__c = system.label.npe03.RecurringDonationMultiplyValue;
        r1.npe03__Open_Ended_Status__c = system.label.npe03.RecurringDonationOpenStatus;
        r1.npe03__Next_Payment_Date__c = system.today();
        r1.OwnerId = system.Userinfo.getUserId();
        insert r1;
        
        list<Opportunity> originalOpps = new list<Opportunity>([select id, Name,amount,accountid,CloseDate from Opportunity where npe03__Recurring_Donation__c = :r1.id order by CloseDate]);
        system.assertEquals(1, originalOpps.size());          
        
        Opportunity o = originalOpps[0];
        string closedstage = [select masterlabel from opportunitystage where isActive = true and iswon = true and isClosed = true limit 1].masterlabel;
        o.StageName = closedstage;
        o.CloseDate = system.today();
        RD_ProcessControl.hasRun = false;
        Test.startTest();        
        //update opp
        update o;
        //call the update method
        RD_RecurringDonations.evaluateRecurringDonationsForNewOppInsert(new list<npe03__Recurring_Donation__c>{r1});
        Test.stopTest();
        
        
        npe03__Recurring_Donation__c rd = [select npe03__Last_Payment_Date__c from npe03__Recurring_Donation__c where id = :r1.id];     
        
        system.assertEquals(0, [select count() from Opportunity where npe03__Recurring_Donation__c = :r1.id and isClosed = false]);
        system.assertEquals(system.today(), rd.npe03__Last_Payment_Date__c);
    }
    
    static testMethod void closeOpenEndedRecurringDonationMarkOppsClosedLost(){
        if (strTestOnly != '*' && strTestOnly != 'closeOpenEndedRecurringDonationMarkOppsClosedLost') return;

        setRecurringDonationsSettingsForTest(
        new npe03__Recurring_Donations_Settings__c(
        npe03__Opportunity_Forecast_Months__c = 12,
        npe03__Maximum_Donations__c = 50,
        npe03__Open_Opportunity_Behavior__c = RD_RecurringDonations.RecurringDonationCloseOptions.Mark_Opportunities_Closed_Lost.name()        
        ));           
        
        Account a = new Account();
        a.Name = 'test Individual';
        insert a;
        
        Contact c = new Contact();
        c.FirstName = 'test';
        c.LastName = 'contact';
        c.AccountId = a.Id;
        insert c;       

        npe03__Recurring_Donation__c r1 = new npe03__Recurring_Donation__c();
        r1.Name = 'test';
        r1.npe03__Installments__c = 2;
        r1.npe03__Contact__c = c.Id;
        r1.npe03__Amount__c = 100;
        r1.npe03__Installment_Period__c = system.label.npe03.RecurringDonationInstallmentPeriodWeekly;
        r1.npe03__Date_Established__c = date.newinstance(1970,6,12);
        r1.npe03__Schedule_Type__c = system.label.npe03.RecurringDonationMultiplyValue;
        r1.npe03__Open_Ended_Status__c = system.label.npe03.RecurringDonationOpenStatus;
        r1.npe03__Next_Payment_Date__c = system.today().toStartOfMonth();
        insert r1;
        
        list<Opportunity> originalOpps = new list<Opportunity>([select id, Name,amount,accountid,CloseDate from Opportunity where npe03__Recurring_Donation__c = :r1.id order by CloseDate]);
        integer cOpp =  originalOpps.size();
        system.assert(cOpp == 52 || cOpp == 53);        
        RD_ProcessControl.hasRun = false;
        Test.startTest();
        r1.npe03__Open_Ended_Status__c = system.label.npe03.RecurringDonationClosedStatus;
        update r1;
        Test.stopTest();
        
        //assert all previously open opps are marked closed lost
        system.assertEquals(53, [select count() from Opportunity where isClosed = true and isWon = false and npe03__Recurring_Donation__c = :r1.id]);
        
    }
    
    static testMethod void updateRecurringDonationWithClosedOpp(){
        if (strTestOnly != '*' && strTestOnly != 'updateRecurringDonationWithClosedOpp') return;

        setRecurringDonationsSettingsForTest(
        new npe03__Recurring_Donations_Settings__c(
        npe03__Opportunity_Forecast_Months__c = 12,
        npe03__Maximum_Donations__c = 50, 
        npe03__Open_Opportunity_Behavior__c = RD_RecurringDonations.RecurringDonationCloseOptions.Mark_Opportunities_Closed_Lost.name()        
        ));           
        
        Account a = new Account();
        a.Name = 'test Individual';
        insert a;
        
        Contact c = new Contact();
        c.FirstName = 'test';
        c.LastName = 'contact';
        c.AccountId = a.Id;
        insert c;        

        npe03__Recurring_Donation__c r1 = new npe03__Recurring_Donation__c();
        r1.Name = 'test';
        r1.npe03__Installments__c = 2;
        r1.npe03__Contact__c = c.Id;
        r1.npe03__Amount__c = 100;
        r1.npe03__Installment_Period__c = system.label.npe03.RecurringDonationInstallmentPeriodWeekly;
        r1.npe03__Date_Established__c = date.newinstance(1970,6,12);
        r1.npe03__Schedule_Type__c = system.label.npe03.RecurringDonationMultiplyValue;
        r1.npe03__Open_Ended_Status__c = system.label.npe03.RecurringDonationOpenStatus;
        r1.npe03__Next_Payment_Date__c = system.today();
        insert r1;
        
        list<Opportunity> originalOpps = new list<Opportunity>([select id, Name,amount,accountid,CloseDate from Opportunity where npe03__Recurring_Donation__c = :r1.id order by CloseDate]);
        Opportunity o = originalOpps[0];
        string closedstage = [select masterlabel from opportunitystage where isActive = true and iswon = true and isClosed = true limit 1].masterlabel;
        o.StageName = closedstage;
        o.CloseDate = system.today();
        update o;
        
        //fake the last payment date close operation
        r1.npe03__Last_Payment_Date__c = system.today();
        update r1;
        RD_ProcessControl.hasRun = false;                
        Test.startTest();        
        r1.npe03__Installment_Period__c = system.label.npe03.RecurringDonationInstallmentPeriodYearly;
        update r1;
        Test.stopTest();        
        
        npe03__Recurring_Donation__c rd = [select npe03__Last_Payment_Date__c from npe03__Recurring_Donation__c where id = :r1.id];     
        
        system.assertEquals(1, [select count() from Opportunity where npe03__Recurring_Donation__c = :r1.id and isClosed = false]);
        system.assertEquals(system.today(), rd.npe03__Last_Payment_Date__c);
    }
    
    //test closing an opportunity for an open recurring donation
    static testMethod void closeOppForOpenEndedRecurringDonationBadRecurrance(){
        if (strTestOnly != '*' && strTestOnly != 'closeOppForOpenEndedRecurringDonationBadRecurrance') return;

        setRecurringDonationsSettingsForTest(
        new npe03__Recurring_Donations_Settings__c(
        npe03__Opportunity_Forecast_Months__c = 12,
        npe03__Maximum_Donations__c = 50,
        npe03__Open_Opportunity_Behavior__c = RD_RecurringDonations.RecurringDonationCloseOptions.Mark_Opportunities_Closed_Lost.name()        
        ));           
        
        Account a = new Account();
        a.Name = 'test Individual';
        insert a;
        
        Contact c = new Contact();
        c.FirstName = 'test';
        c.LastName = 'contact';
        c.AccountId = a.Id;
        insert c;       
        
        Campaign camp = new Campaign(Name = 'MyTestCamp', isActive = true);
        insert camp;

        npe03__Recurring_Donation__c r1 = new npe03__Recurring_Donation__c();
        r1.Name = 'test';
        r1.npe03__Installments__c = 2;
        r1.npe03__Organization__c = a.id;
        r1.npe03__Amount__c = 100;
        r1.npe03__Recurring_Donation_Campaign__c = camp.id;
        r1.npe03__Installment_Period__c = system.label.npe03.RecurringDonationInstallmentPeriodYearly;
        r1.npe03__Date_Established__c = date.newinstance(1970,6,12);
        r1.npe03__Schedule_Type__c = system.label.npe03.RecurringDonationMultiplyValue;
        r1.npe03__Open_Ended_Status__c = system.label.npe03.RecurringDonationOpenStatus;
        r1.npe03__Next_Payment_Date__c = system.today();
        insert r1;
        
        list<Opportunity> originalOpps = new list<Opportunity>([select id, Name,amount,accountid,CloseDate from Opportunity where npe03__Recurring_Donation__c = :r1.id order by CloseDate]);
        Opportunity o = originalOpps[0];
        string closedstage = [select masterlabel from opportunitystage where isActive = true and iswon = true and isClosed = true limit 1].masterlabel;
        o.StageName = closedstage;
        o.CloseDate = system.today();
        r1.npe03__Installment_Period__c = 'GarbageDate';
        update r1;
        RD_ProcessControl.hasRun = false;
        Test.startTest();        
        update o;
        Test.stopTest();
    }
    
       //test closing an opportunity for an open recurring donation
    static testMethod void closeRecurringDonationDeleteOpps(){
        if (strTestOnly != '*' && strTestOnly != 'closeRecurringDonationDeleteOpps') return;

        setRecurringDonationsSettingsForTest(
        new npe03__Recurring_Donations_Settings__c(
        npe03__Opportunity_Forecast_Months__c = 12,
        npe03__Maximum_Donations__c = 50,
        npe03__Open_Opportunity_Behavior__c = RD_RecurringDonations.RecurringDonationCloseOptions.Delete_Open_Opportunities.name()        
        ));           
        
        Account a = new Account();
        a.Name = 'test Individual';
        insert a;
        
        Contact c = new Contact();
        c.FirstName = 'test';
        c.LastName = 'contact';
        c.AccountId = a.Id;
        insert c;       
        
        Campaign camp = new Campaign(Name = 'MyTestCamp', isActive = true);
        insert camp;

        npe03__Recurring_Donation__c r1 = new npe03__Recurring_Donation__c();
        r1.Name = 'test';
        r1.npe03__Installments__c = 2;
        r1.npe03__Organization__c = a.id;
        r1.npe03__Amount__c = 100;
        r1.npe03__Recurring_Donation_Campaign__c = camp.id;
        r1.npe03__Installment_Period__c = system.label.npe03.RecurringDonationInstallmentPeriodYearly;
        r1.npe03__Date_Established__c = date.newinstance(1970,6,12);
        r1.npe03__Schedule_Type__c = system.label.npe03.RecurringDonationMultiplyValue;
        r1.npe03__Open_Ended_Status__c = system.label.npe03.RecurringDonationOpenStatus;
        r1.npe03__Next_Payment_Date__c = system.today();
        insert r1;
        
        system.assertNotEquals(0, [select count() from Opportunity where npe03__Recurring_Donation__c = :r1.id and isClosed = false]);
        //reset the semaphore
        RD_ProcessControl.hasRun = false;
        Test.startTest();        
        r1.npe03__Open_Ended_Status__c = system.label.npe03.RecurringDonationClosedStatus;
        update r1;
        Test.stopTest();
        
        //there should be no open donations
        system.assertEquals(0, [select count() from Opportunity where npe03__Recurring_Donation__c = :r1.id and isClosed = false]);        
    }
    
    static testMethod void multipleRDInsert(){
        if (strTestOnly != '*' && strTestOnly != 'multipleRDInsert') return;

        setRecurringDonationsSettingsForTest(
        new npe03__Recurring_Donations_Settings__c(
        npe03__Opportunity_Forecast_Months__c = 6,
        npe03__Maximum_Donations__c = 50,
        npe03__Open_Opportunity_Behavior__c = RD_RecurringDonations.RecurringDonationCloseOptions.Mark_Opportunities_Closed_Lost.name()        
        ));           
        
        delete [select id from npe03__Custom_Field_Mapping__c];
        npe03__Custom_Field_Mapping__c cfm1 = new npe03__Custom_Field_Mapping__c(
        npe03__Recurring_Donation_Field__c = 'Name',
        npe03__Opportunity_Field__c = 'Description',
        Name = 'CFMName00001-Test'
        );
        insert cfm1;
        
        Account a = new Account();
        a.Name = 'test Individual';
        insert a;
        
        Contact c = new Contact();
        c.FirstName = 'test';
        c.LastName = 'contact';
        c.AccountId = a.Id;
        insert c;       

        list<npe03__Recurring_Donation__c> rdlist = new list<npe03__Recurring_Donation__c>();
        npe03__Recurring_Donation__c r1 = new npe03__Recurring_Donation__c();
        r1.Name = 'test';
        r1.npe03__Installments__c = 2;
        r1.npe03__Contact__c = c.Id;
        r1.npe03__Amount__c = 100;
        r1.npe03__Installment_Period__c = system.label.npe03.RecurringDonationInstallmentPeriodYearly;
        r1.npe03__Date_Established__c = date.newinstance(1970,6,12);
        r1.npe03__Schedule_Type__c = system.label.npe03.RecurringDonationMultiplyValue;
        r1.npe03__Open_Ended_Status__c = system.label.npe03.RecurringDonationOpenStatus;
        r1.npe03__Next_Payment_Date__c = system.today().toStartOfMonth();
        rdlist.add(r1);
                
        npe03__Recurring_Donation__c r2 = new npe03__Recurring_Donation__c();
        r2.Name = 'test';
        r2.npe03__Installments__c = 2;
        r2.npe03__Contact__c = c.Id;
        r2.npe03__Amount__c = 100;
        r2.npe03__Installment_Period__c = system.label.npe03.RecurringDonationInstallmentPeriodMonthly;
        r2.npe03__Date_Established__c = date.newinstance(1970,6,12);
        r2.npe03__Schedule_Type__c = system.label.npe03.RecurringDonationMultiplyValue;
        r2.npe03__Open_Ended_Status__c = system.label.npe03.RecurringDonationOpenStatus;
        r2.npe03__Next_Payment_Date__c = system.today().toStartOfMonth();
        rdlist.add(r2);
                                        
        Test.startTest();
        insert rdlist;
        rdlist[0].npe03__Amount__c = 50;
        rdlist[1].npe03__Amount__c = 50;
        rdlist[1].npe03__Next_Payment_Date__c = system.today().toStartOfMonth().addDays(5);
        RD_ProcessControl.hasRun = false;
        update rdlist;        
        Test.stopTest();
        
        list<Opportunity> originalOpps = new list<Opportunity>([select id, Name,amount,accountid,CloseDate from Opportunity where npe03__Recurring_Donation__r.id = :r1.id or npe03__Recurring_Donation__c = :r2.id]);
        system.assertEquals(7, originalOpps.size());
        system.assertEquals(50, originalOpps[0].Amount);
    }
    static testMethod void tooManyInstallments(){
        if (strTestOnly != '*' && strTestOnly != 'tooManyInstallments') return;

        setRecurringDonationsSettingsForTest(
        new npe03__Recurring_Donations_Settings__c(
        npe03__Opportunity_Forecast_Months__c = 6,
        npe03__Maximum_Donations__c = 2,
        npe03__Open_Opportunity_Behavior__c = RD_RecurringDonations.RecurringDonationCloseOptions.Mark_Opportunities_Closed_Lost.name()        
        ));           
        
        Account a = new Account();
        a.Name = 'test Individual';
        insert a;
        
        Contact c = new Contact();
        c.FirstName = 'test';
        c.LastName = 'contact';
        c.AccountId = a.Id;
        insert c;       

        list<npe03__Recurring_Donation__c> rdlist = new list<npe03__Recurring_Donation__c>();
        npe03__Recurring_Donation__c r1 = new npe03__Recurring_Donation__c();
        r1.Name = 'test';
        r1.npe03__Installments__c = 50;
        r1.npe03__Contact__c = c.Id;
        r1.npe03__Amount__c = 100;
        r1.npe03__Installment_Period__c = system.label.npe03.RecurringDonationInstallmentPeriodYearly;
        r1.npe03__Date_Established__c = date.newinstance(1970,6,12);
        r1.npe03__Schedule_Type__c = system.label.npe03.RecurringDonationMultiplyValue;
        r1.npe03__Open_Ended_Status__c = 'None';
        r1.npe03__Next_Payment_Date__c = system.today();
        try{
            insert r1;
        }
        catch (exception e){}
        //insert should fail because of too many installments
        system.assertEquals(null,r1.id);
    }
    static testmethod void updateOppsFromMultipleRDs(){
        if (strTestOnly != '*' && strTestOnly != 'updateOppsFromMultipleRDs') return;

        setRecurringDonationsSettingsForTest(
        new npe03__Recurring_Donations_Settings__c(
        npe03__Opportunity_Forecast_Months__c = 6,
        npe03__Maximum_Donations__c = 50,
        npe03__Open_Opportunity_Behavior__c = RD_RecurringDonations.RecurringDonationCloseOptions.Mark_Opportunities_Closed_Lost.name()        
        ));           
        
        //remove any existing custom field mappings
        delete [select id from npe03__Custom_Field_Mapping__c];        
        npe03__Custom_Field_Mapping__c cfm = new npe03__Custom_Field_Mapping__c(
        npe03__Recurring_Donation_Field__c = 'Name',
        npe03__Opportunity_Field__c = 'Description',
        Name = 'CFMName00001-Test'
        );
        insert cfm;
        
        Account a = new Account(); 
        a.Name = 'test Individual';
        insert a;
        
        Contact c = new Contact();
        c.FirstName = 'test';
        c.LastName = 'contact';
        c.AccountId = a.Id;
        insert c;       
        
        list<npe03__Recurring_Donation__c> rdlist = new list<npe03__Recurring_Donation__c>();
        npe03__Recurring_Donation__c r1 = new npe03__Recurring_Donation__c();
        r1.Name = 'test';
        r1.npe03__Installments__c = 2;
        r1.npe03__Contact__c = c.Id;
        r1.npe03__Amount__c = 100;
        r1.npe03__Installment_Period__c = system.label.npe03.RecurringDonationInstallmentPeriodYearly;
        r1.npe03__Date_Established__c = date.newinstance(1970,6,12);
        r1.npe03__Schedule_Type__c = system.label.npe03.RecurringDonationMultiplyValue;
        r1.npe03__Open_Ended_Status__c = system.label.npe03.RecurringDonationOpenStatus;
        r1.npe03__Next_Payment_Date__c = system.today();
        insert r1;
        RD_ProcessControl.hasRun = false;
                
        npe03__Recurring_Donation__c r2 = new npe03__Recurring_Donation__c();
        r2.Name = 'test';
        r2.npe03__Installments__c = 2;
        r2.npe03__Contact__c = c.Id;
        r2.npe03__Amount__c = 100;
        r2.npe03__Installment_Period__c = system.label.npe03.RecurringDonationInstallmentPeriodMonthly;
        r2.npe03__Date_Established__c = date.newinstance(1970,6,12);
        r2.npe03__Schedule_Type__c = system.label.npe03.RecurringDonationMultiplyValue;
        r2.npe03__Open_Ended_Status__c = system.label.npe03.RecurringDonationOpenStatus;
        r2.npe03__Next_Payment_Date__c = system.today();
        insert r2;
        RD_ProcessControl.hasRun = false;
        list<Opportunity> originalOpps = new list<Opportunity>([select id, Name,amount,accountid,CloseDate from Opportunity where npe03__Recurring_Donation__r.id = :r1.id or npe03__Recurring_Donation__c = :r2.id]);                                
        string closedstage = [select masterlabel from opportunitystage where isActive = true and iswon = true and isClosed = true limit 1].masterlabel;
        system.assert(originalOpps.size() > 1);
        
        Test.startTest();
        originalOpps[0].Stagename = closedstage;
        originalOpps[1].stagename = closedstage;        
        update originalOpps;
        Test.stopTest();
        system.assert(originalOpps.size() > [select count() from Opportunity where isClosed = false and (npe03__Recurring_Donation__c = :r1.id or npe03__Recurring_Donation__c = :r2.id)]);        
    }    
        
    public static void setRecurringDonationsSettingsForTest(npe03__Recurring_Donations_Settings__c rds){
        //clear out the old ones and insert this
        delete [select id from npe03__Recurring_Donations_Settings__c];
        insert rds;
    }
    
    /*** Test Methods from RD_ErrorHandling ***/
    
    static testMethod void testErrorHandlingAllSysAdmins(){
        if (strTestOnly != '*' && strTestOnly != 'testErrorHandlingAllSysAdmins') return;

        setRecurringDonationsSettingsForTest(new npe03__Recurring_Donations_Settings__c( 
        npe03__Error_Email_Notifications__c ='All Sys Admins'                
        ));         
        
        Account a = new Account(Name = 'Test');
        insert a;
        npe03__Recurring_Donation__c r1 = new npe03__Recurring_Donation__c();
        r1.Name = 'test';
        r1.npe03__Organization__c = a.id;
        r1.npe03__Amount__c = 100;
        r1.npe03__Installment_Period__c = system.label.npe03.RecurringDonationInstallmentPeriodWeekly;
        r1.npe03__Open_Ended_Status__c = system.label.npe03.RecurringDonationOpenStatus;
        r1.npe03__Next_Payment_Date__c = system.today();
        insert r1;    
        
        //create some opps
        list<Opportunity> olist = new list<Opportunity>();
        integer i;
        for (i = 0; i<=10; i++){
            Opportunity o = new Opportunity(
                StageName = 'Closed Won',
                Name = 'Opp ' + i,
                CloseDate = system.today(),
                Amount = 1.00,
                npe03__Recurring_Donation__c = r1.id                
            );
            olist.add(o);                       
        }
        //invalidate one opp        
        olist[0].Name = null;
        Database.saveresult[] lsr = Database.insert(olist, false);
        list<Opportunity> badOpps = new list<Opportunity>{olist[0]};
        //run it using bulk setup
        ERR_Handler errorHandler = new ERR_Handler();
        errorHandler.processInsertResults(lsr, badOpps, ERR_Handler.Context.RD);
    }
    
    static testMethod void testErrorHandlingUser(){
        if (strTestOnly != '*' && strTestOnly != 'testErrorHandlingUser') return;

        User u = [select id from User limit 1];
        setRecurringDonationsSettingsForTest(new npe03__Recurring_Donations_Settings__c( 
        npe03__Error_Email_Notifications__c = u.id                
        ));  
        
        Account a = new Account(Name = 'Test');
        insert a;
        npe03__Recurring_Donation__c r1 = new npe03__Recurring_Donation__c();
        r1.Name = 'test';
        r1.npe03__Organization__c = a.id;
        r1.npe03__Amount__c = 100;
        r1.npe03__Installment_Period__c = system.label.npe03.RecurringDonationInstallmentPeriodWeekly;
        r1.npe03__Open_Ended_Status__c = system.label.npe03.RecurringDonationOpenStatus;
        r1.npe03__Next_Payment_Date__c = system.today();
        insert r1;      
        
         //create some opps
        list<Opportunity> olist = new list<Opportunity>();
        integer i;
        for (i = 0; i<=10; i++){
            Opportunity o = new Opportunity(
                StageName = 'Closed Won',
                Name = 'Opp ' + i,
                CloseDate = system.today(),
                Amount = 1.00,
                npe03__Recurring_Donation__c = r1.id                
            );
            olist.add(o);                       
        }
        //invalidate one opp        
        olist[0].Name = null;
        Database.saveresult[] lsr = Database.insert(olist, false);
        list<Opportunity> badOpps = new list<Opportunity>{olist[0]};
        
        ERR_Handler errorHandler = new ERR_Handler();
        errorHandler.processInsertResults(lsr, badOpps, ERR_Handler.Context.RD);
    }
    
    static testMethod void testErrorHandlingPublicGroup(){
        if (strTestOnly != '*' && strTestOnly != 'testErrorHandlingPublicGroup') return;

        Group g = new Group(Name = 'MyGroup');
        insert g;
        UTIL_Debug.debug('GID IS: ' + g.id);
        setRecurringDonationsSettingsForTest(new npe03__Recurring_Donations_Settings__c( 
        npe03__Error_Email_Notifications__c = g.id                
        ));         
        
        Account a = new Account(Name = 'Test');
        insert a;
        npe03__Recurring_Donation__c r1 = new npe03__Recurring_Donation__c();
        r1.Name = 'test';
        r1.npe03__Organization__c = a.id;
        r1.npe03__Amount__c = 100;
        r1.npe03__Installment_Period__c = system.label.npe03.RecurringDonationInstallmentPeriodWeekly;
        r1.npe03__Open_Ended_Status__c = system.label.npe03.RecurringDonationOpenStatus;
        r1.npe03__Next_Payment_Date__c = system.today();
        insert r1;                   
        
        //create some opps
        list<Opportunity> olist = new list<Opportunity>();
        integer i;
        for (i = 0; i<=10; i++){
            Opportunity o = new Opportunity(
                StageName = 'Closed Won',
                Name = 'Opp ' + i,
                CloseDate = system.today(),
                Amount = 1.00,
                npe03__Recurring_Donation__c = r1.id                
            );
            olist.add(o);                       
        }
        //invalidate one opp        
        olist[0].Name = null;
        Database.saveresult[] lsr = Database.insert(olist, false);
        list<Opportunity> badOpps = new list<Opportunity>{olist[0]};
        
        ERR_Handler errorHandler = new ERR_Handler();
        errorHandler.processInsertResults(lsr, badOpps, ERR_Handler.Context.RD);
    }     

    //--------------------TEST METHOD from RD_RecurringDonations_BATCH -----------------------
    static testMethod void batchStatusBarTest(){
        if (strTestOnly != '*' && strTestOnly != 'batchStatusBarTest') return;

        UTIL_JobProgress_CTRL controller = new UTIL_JobProgress_CTRL();
        controller.getBatchJobs();
    }

    //--------------- from RD_RecurringDonations_BATCH -----------------
    @isTest 
    public static void testBatch() {
        if (strTestOnly != '*' && strTestOnly != 'testBatch') return;
        
        setRecurringDonationsSettingsForTest(
        new npe03__Recurring_Donations_Settings__c(
        npe03__Opportunity_Forecast_Months__c = 12,
        npe03__Maximum_Donations__c = 50,
        npe03__Open_Opportunity_Behavior__c = RD_RecurringDonations.RecurringDonationCloseOptions.Mark_Opportunities_Closed_Lost.name()
        ));           
                    
        Account a = new Account();
        a.Name = 'test Individual';
        insert a;
        
        Contact c = new Contact();
        c.FirstName = 'test';
        c.LastName = 'contact';
        c.AccountId = a.Id;
        insert c;       

        npe03__Recurring_Donation__c r1 = new npe03__Recurring_Donation__c();
        r1.Name = 'test';
        r1.npe03__Installments__c = 2;
        r1.npe03__Organization__c = a.id;
        r1.npe03__Amount__c = 100;
        r1.npe03__Installment_Period__c = system.label.npe03.RecurringDonationInstallmentPeriodWeekly;
        r1.npe03__Date_Established__c = date.newinstance(1970,6,12);
        r1.npe03__Schedule_Type__c = system.label.npe03.RecurringDonationMultiplyValue;
        r1.npe03__Open_Ended_Status__c = system.label.npe03.RecurringDonationOpenStatus;
        r1.npe03__Next_Payment_Date__c = system.today();
        insert r1;
        
        list<Opportunity> originalOpps = new list<Opportunity>([select id, Name,amount,accountid,CloseDate from Opportunity where npe03__Recurring_Donation__c = :r1.id order by CloseDate]);
        
        Opportunity o = originalOpps[0];
        string closedstage = [select masterlabel from opportunitystage where isActive = true and iswon = true and isClosed = true limit 1].masterlabel;
        o.StageName = closedstage;
        o.CloseDate = system.today();
        update o;        
        
        //kick it off from the vf page
        Test.setCurrentPageReference(new PageReference('Page.RecurringDonationsSettings'));
        
        //pass the controller into the extension
        /****
        STTG_RecurringDonations_CTRL controller = new STTG_RecurringDonations_CTRL();
        controller.getSettingsFirstTime();
        test.startTest();
        controller.runBatch();
        test.stopTest();
        *********/  
    }  

/******************************************************************    
    // Test Methods from STTG_RecurringDonations_CTRL   
    public static testMethod void TEST_RecurringDonationsSettings() {
        if (strTestOnly != '*' && strTestOnly != 'TEST_RecurringDonationsSettings') return;

        id rtid = [select id from RecordType where sobjecttype = 'Opportunity' limit 1].id;
        id uid = [select id from User limit 1].id;
        setRecurringDonationsSettingsForTest(new npe03__Recurring_Donations_Settings__c(
        npe03__Error_Email_Notifications__c = uid, npe03__Record_Type__c = rtid, npe03__Max_Package_Version__c = '2.0',
        npe03__Package_Update_URL__c = 'http://www.salesforce.com', npe03__Last_Update_Check__c = system.today(),
        npe03__Has_Package_Update__c = 'true'        
        ));
        
        npe03__Custom_Installment_Settings__c cis = new npe03__Custom_Installment_Settings__c(Name = 'TESTINSTALLMENT', npe03__Value__c = 1, npe03__Increment__c = 'Weeks');
        insert cis;
        
        Account a = new Account(Name='TestAccount');
        insert a;
        insert new npe03__Recurring_Donation__c(Name = 'TestRD', npe03__Organization__c = a.id, npe03__Installment_Period__c='TestValueForUnitTests');
 
        Test.setCurrentPageReference(new PageReference('Page.RecurringDonationsSettings'));
        
        //pass the controller into the extension
        STTG_RecurringDonations_CTRL controller = new STTG_RecurringDonations_CTRL(); 
        controller.getSettingsFirstTime();
        system.assertNotEquals(null,UTIL_CustomSettingsFacade.getRecurringDonationsSettings(
                                            RD_RecurringDonations.RecurringDonationCloseOptions.Mark_Opportunities_Closed_Lost));
        
        list<SelectOption> enumvalues  =  controller.closeOptions; 
        system.assertEquals(3,enumvalues.size());
        
        controller.testPackageIntegrity();
        controller.cancel();
        controller.editRDsettings();
        controller.rds.npe03__Open_Opportunity_Behavior__c = '-------------------';
        controller.saveRDSettings();   
        controller.rds.npe03__Open_Opportunity_Behavior__c = '1234';
        controller.saveRDSettings();
        controller.addCIRow();        
        controller.editCISettings();
        npe03__Custom_Installment_Settings__c c = new npe03__Custom_Installment_Settings__c(Name='TestValueForUnitTests', npe03__Value__c = 5.0, npe03__Increment__c = 'Weeks');
        controller.cis.add(c);
        controller.saveCISettings(); 
        controller.runDeleteWizard();
        controller.selectedInstallmentName = 'TestValueForUnitTests';
        controller.replacementInstallment = 'Weekly';        
        controller.deleteInstallment();        
        controller.RDField = 'npe03__Amount__c';
        controller.OppField = 'Amount';
        controller.saveFieldMapping();
        controller.fieldMappingName = 'TestNAME';
        controller.deleteFieldMapping();
        Recordtype rt = controller.RTName;
        Group g =  controller.EmailErrorDisplayName;
        g =  controller.EmailErrorDisplayName;        
        controller.addFieldMapping();
        list<SelectOption> eeolist = controller.ErrorEmailOptions;
        list<SelectOption> rtlist = controller.RecordTypeList;
        list<SelectOption> mylist = controller.validInstallments;
        list<SelectOption> rdfield = controller.availableRDFields;
        list<SelectOption> oppfield = controller.availableOpportunityFields;
        controller.trimOpportunities();
        controller.clearErrorQueue();
    }   
    //covering everything else 
    public static testMethod void TEST_RecurringDonationsSettings2(){
        if (strTestOnly != '*' && strTestOnly != 'TEST_RecurringDonationsSettings2') return;

        id rtid = [select id from RecordType where sobjecttype = 'Opportunity' limit 1].id;
        Group g = new Group(Name = 'Testgroup');
        insert g;        
        
        setRecurringDonationsSettingsForTest(new npe03__Recurring_Donations_Settings__c(
        npe03__Error_Email_Notifications__c = g.id, npe03__Record_Type__c = rtid, npe03__Max_Package_Version__c = '2.0',
        npe03__Package_Update_URL__c = 'http://www.salesforce.com', npe03__Last_Update_Check__c = null,
        npe03__Has_Package_Update__c = 'false'        
        ));   
        
        Test.setCurrentPageReference(new PageReference('Page.RecurringDonationsSettings'));
        //pass the controller into the extension
        STTG_RecurringDonations_CTRL controller = new STTG_RecurringDonations_CTRL(); 
        controller.getSettingsFirstTime();
        list<SelectOption> eeolist = controller.ErrorEmailOptions;
        controller.RDField = 'garbage';
        controller.OppField = 'garbage';
        controller.saveFieldMapping();
        controller.cis.add(new npe03__Custom_Installment_Settings__c(Name = 'CisSetTest', npe03__Value__c = 1, npe03__Increment__c = 'Weeks'));
        controller.saveCISettings();
    }
*************************************************************************/
   
   // from RD_RecurringDonations_SCHED  
   static testmethod void test(){ 
        if (strTestOnly != '*' && strTestOnly != 'test') return;
             
        npe03__Custom_Field_Mapping__c cfm = new npe03__Custom_Field_Mapping__c(
        npe03__Recurring_Donation_Field__c = 'npe03__Last_Payment_Date__c',
        npe03__Opportunity_Field__c = 'Description',
        Name = 'CFMName00001-Test'
        );
        insert cfm;
        
        Test.startTest(); 
        
        //Schedule the test job 
        insert new Schedulable__c(Name = 'test rd Sched', Class_Name__c = 'RD_RecurringDonations_SCHED', Active__c = true);
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
    
    // from RD_AddDonationsBTN_CTRL
    public static testMethod void testBTN(){
        if (strTestOnly != '*' && strTestOnly != 'testBTN') return;

        Account a = new Account(Name = 'TestA');
        insert a;
        npe03__Recurring_Donation__c r1 = new npe03__Recurring_Donation__c();
        r1.Name = 'test';
        r1.npe03__Installments__c = 2;
        r1.npe03__Organization__c = a.Id;
        r1.npe03__Amount__c = 100;
        r1.npe03__Installment_Period__c = system.label.npe03.RecurringDonationInstallmentPeriodWeekly;
        r1.npe03__Date_Established__c = date.newinstance(1970,6,12);
        r1.npe03__Schedule_Type__c = system.label.npe03.RecurringDonationMultiplyValue;
        r1.npe03__Open_Ended_Status__c = system.label.npe03.RecurringDonationOpenStatus;
        r1.npe03__Next_Payment_Date__c = system.today();
        insert r1;
        
        delete[select id from npe03__Custom_Field_Mapping__c];
        insert new npe03__Custom_Field_Mapping__c(
        Name = 'CFM-' + system.now(),
        npe03__Opportunity_Field__c = 'closedate',
        npe03__Recurring_Donation_Field__c = 'npe03__Last_Payment_Date__c'
        );
        
        ApexPages.StandardController scc = new ApexPages.StandardController(r1);
        RD_AddDonationsBTN_CTRL rdadb = new RD_AddDonationsBTN_CTRL(scc);
        system.assertEquals(r1.id, rdadb.RecurringDonation.id);
        rdadb.buttonClick();    
    }    
                
}