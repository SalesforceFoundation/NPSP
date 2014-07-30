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
* @description Tests specific to Opportunity Allocations. 
*/

@isTest
private with sharing class ALLO_Allocations_TEST {
    
    // if you only want to run one test in this class, fill in its name here.
    // if you want to run all tests, then use '*'
    private static string strTestOnly = 'recurringDonationsValidation';
    private static Allocations_Settings__c settings;

    /*
    only percentage defined, amount is calculated
    percentage changed, amount is recalculated

    enabled default allocation:
        allocations must equal 100% or total
    disabled default allocation
        allocations must equal less than 100% or total 

    Bulk: multiple allocations equaling 100%
          multiple allocations over 100%
          multiple allocations for different objects

          create default allocations when an allocation is inserted on an opp without one?
          

    */

    //when changing the amount of an Opportunity with Allocations: 
    //increasing the amount will adjust the percentage allocations
    //decreasing the amount so that the total allocation amount is still below the opportunity amount will adjust the percentage allocations
    //decreasing the amount so that the total allocation amount is greater than the opportunity amount, an error is thrown and the opportunity update is blocked

    @isTest
    static void oppAmountChange() {
        if (strTestOnly != '*' && strTestOnly != 'oppAmountChange') return;
        settings = UTIL_CustomSettingsFacade.getAllocationsSettings();
        settings.Allocations_Enabled__c = true;
        settings.Default_Allocations_Enabled__c = false;
        update settings;

        Account acc = new Account(Name='foo');
        insert acc;
        Opportunity opp = new Opportunity(Name='foo', Amount = 8, AccountID=acc.id, CloseDate=system.today(), StageName=UTIL_UnitTestData_TEST.getClosedWonStage());
        insert opp;
        General_Accounting_Unit__c gau = new General_Accounting_Unit__c(Name='foo');
        insert gau;

        //resetting these manually as a test is considered a single context for static variables
        ALLO_Allocations_TDTM.hasRunForAllocations = false;
        ALLO_Allocations_TDTM.hasRunForOpportunities = false;
        
        list<Allocation__c> alloForInsert = new list<Allocation__c>();

        Allocation__c percentAllo = new Allocation__c(Opportunity__c=opp.id, Percent__c = 50, General_Accounting_Unit__c = gau.id);
        alloForInsert.add(percentAllo);
        Allocation__c amountAllo = new Allocation__c(Opportunity__c=opp.id, Amount__c = 4, General_Accounting_Unit__c = gau.id);
        alloForInsert.add(amountAllo);
        insert alloForInsert;

        list<Allocation__c> queryAllo = [SELECT Id, Percent__c, Amount__c FROM Allocation__c ORDER BY Percent__c];
        system.assertEquals(50, queryAllo[1].Percent__c, 'The percentage allocation should be 50%.');
        system.assertEquals(4, queryAllo[1].Amount__c, 'The amount of the percentage allocation should be calculated based on the Opportunity amount.');
        system.assertEquals(4, queryAllo[0].Amount__c, 'The amount of the standard number allocation should be 4.');
        
        ALLO_Allocations_TDTM.hasRunForAllocations = false;
        ALLO_Allocations_TDTM.hasRunForOpportunities = false;
        opp.Amount = 10;
        update opp;
        
        queryAllo = [SELECT Id, Percent__c, Amount__c FROM Allocation__c ORDER BY Percent__c];
        system.assertEquals(5, queryAllo[1].Amount__c, 'The amount of the percentage allocation should increase proportionately with the Opportunity amount.');
        system.assertEquals(4, queryAllo[0].Amount__c, 'The amount of the standard number allocation should be unchanged at 4.');
        
        ALLO_Allocations_TDTM.hasRunForAllocations = false;
        ALLO_Allocations_TDTM.hasRunForOpportunities = false;
        opp.Amount = 8;
        update opp;

        queryAllo = [SELECT Id, Percent__c, Amount__c FROM Allocation__c ORDER BY Percent__c];
        system.assertEquals(4, queryAllo[1].Amount__c, 'The amount of the percentage allocation should decrease proportionately with the Opportunity amount.');
        system.assertEquals(4, queryAllo[0].Amount__c, 'The amount of the standard number allocation should be unchanged at 4.');

        ALLO_Allocations_TDTM.hasRunForAllocations = false;
        ALLO_Allocations_TDTM.hasRunForOpportunities = false;
        opp.Amount = 1;
        
        Exception ex = null;
        try {
            update opp;
        } catch (Exception e) {
            ex = e;
        }
        system.assertNotEquals(null,ex,'An exception should be caught.');
        //system.assert(ex.getMessage().contains(), ex.getMessage());

        list<Opportunity> queryOpps = [SELECT Id, Amount FROM opportunity WHERE Id = :opp.id];
        system.assertEquals(8, queryOpps[0].Amount, 'The opportunity amount should remain unchanged after the exception is caught.');
    }

    //with default General Accounting Units enabled, creating an Opportunity automatically creates a default allocation for the full amount of the opportunity
    //creating a new allocation for that opportunity decreases the default fund allocation
    //creating an allocation for the total amount deletes the default allocation
    @isTest
    static void defaultAllocations() {
        if (strTestOnly != '*' && strTestOnly != 'defaultAllocations') return;
        
        General_Accounting_Unit__c defaultGau = new General_Accounting_Unit__c(Name='General');
        insert defaultGau;

        settings = UTIL_CustomSettingsFacade.getAllocationsSettings();
        settings.Allocations_Enabled__c = true;
        settings.Default_Allocations_Enabled__c = true;
        settings.Default__c = defaultGau.id;
        update settings;

        Account acc = new Account(Name='foo');
        insert acc;
        Opportunity opp = new Opportunity(Name='foo', Amount = 8, AccountID=acc.id, CloseDate=system.today(), StageName=UTIL_UnitTestData_TEST.getClosedWonStage());
        insert opp;

        General_Accounting_Unit__c gau = new General_Accounting_Unit__c(Name='foo');
        insert gau;

        list<Allocation__c> queryAllo = [SELECT Id, Percent__c, Amount__c FROM Allocation__c ORDER BY Percent__c];
        system.assertEquals(1,queryAllo.size(), 'An allocation to the default General Accounting Unit should be created.');
        system.assertEquals(8,queryAllo[0].Amount__c, 'The default allocation should be for the total amount of the Opportunity.');

        //resetting these manually as a test is considered a single context for static variables
        ALLO_Allocations_TDTM.hasRunForAllocations = false;
        ALLO_Allocations_TDTM.hasRunForOpportunities = false;
        Allocation__c amountAllo = new Allocation__c(Opportunity__c=opp.id, Amount__c = 6, General_Accounting_Unit__c = gau.id);
        insert amountAllo;

        queryAllo = [SELECT Id, Percent__c, Amount__c FROM Allocation__c ORDER BY Amount__c];
        system.assertEquals(2,queryAllo[0].Amount__c, 'The default allocation should be equal to the remainder of the total Opp amount after removing the new Allocation amount.');

        ALLO_Allocations_TDTM.hasRunForAllocations = false;
        ALLO_Allocations_TDTM.hasRunForOpportunities = false;
        amountAllo.Amount__c = 8;
        update amountAllo;

        queryAllo = [SELECT Id, Percent__c, Amount__c FROM Allocation__c ORDER BY Amount__c];
        system.assertEquals(1,queryAllo.size(), 'The default fund allocation should be deleted.');
    }

    //if allocations are disabled, nothing is done to prevent bad data
    @isTest
    static void allocationsDisabled() {
        if (strTestOnly != '*' && strTestOnly != 'allocationsDisabled') return;
        settings = UTIL_CustomSettingsFacade.getAllocationsSettings();
        settings.Allocations_Enabled__c = false;
        settings.Default_Allocations_Enabled__c = false;
        update settings;

        Account acc = new Account(Name='foo');
        insert acc;
        Opportunity opp = new Opportunity(Name='foo', Amount = 8, AccountID=acc.id, CloseDate=system.today(), StageName=UTIL_UnitTestData_TEST.getClosedWonStage());
        insert opp;
        General_Accounting_Unit__c gau = new General_Accounting_Unit__c(Name='foo');
        insert gau;

        //allocation amount is greater than opportunity amount, which would generate an exception if allocations were enabled.
        Allocation__c allo = new Allocation__c(Opportunity__c=opp.id, Amount__c = 10, General_Accounting_Unit__c = gau.id);
        
        Exception ex = null;
        try {
            insert allo;
        } catch (Exception e) {
            ex = e;
        }
        system.assertEquals(null,ex,'No exception should be generated by incorrect allocations if allocations are disabled.');
    }

    //Campaign Allocations:
    //test opp created with campaign allocation: allocations are created, default allocation covers the remainder
    //test opp where allocations exceed opp amount: exception thrown, only default allocation created
    @isTest
    static void campaignAllocations() {
        if (strTestOnly != '*' && strTestOnly != 'campaignExceedsAmount') return;
        
        General_Accounting_Unit__c defaultgau = new General_Accounting_Unit__c(Name='General');
        insert defaultgau;

        settings = UTIL_CustomSettingsFacade.getAllocationsSettings();
        settings.Allocations_Enabled__c = true;
        settings.Default_Allocations_Enabled__c = true;
        settings.Default__c = defaultgau.id;
        update settings;

        Account acc = new Account(Name='foo');
        insert acc;
        General_Accounting_Unit__c campaigngau = new General_Accounting_Unit__c(Name='foo');
        insert campaigngau;
        Campaign cam = new Campaign(Name='Foo', IsActive=true);
        insert cam;

        list<Allocation__c> alloForInsert = new list<Allocation__c>();
        Allocation__c percentAllo = new Allocation__c(Campaign__c=cam.id, Percent__c = 50, General_Accounting_Unit__c = campaigngau.id);
        alloForInsert.add(percentAllo);
        Allocation__c amountAllo = new Allocation__c(Campaign__c=cam.id, Amount__c = 4, General_Accounting_Unit__c = campaigngau.id);
        alloForInsert.add(amountAllo);
        insert alloForInsert;

        ALLO_Allocations_TDTM.hasRunForAllocations = false;
        ALLO_Allocations_TDTM.hasRunForOpportunities = false;
        Opportunity opp = new Opportunity(Name='success', Amount = 10, AccountID=acc.id, CampaignId=cam.id, CloseDate=system.today(), StageName=UTIL_UnitTestData_TEST.getClosedWonStage());
        insert opp;

        //verify campaign allocation and default allocation created
        list<Allocation__c> queryAllo = [SELECT Id, General_Accounting_Unit__c, Amount__c, Percent__c FROM Allocation__c WHERE Opportunity__c=:opp.id ORDER BY Amount__c];
        system.assertEquals(3,queryAllo.size(), 'An allocation for the Campaign Opportunity should be created.');
        system.assertEquals(defaultgau.id, queryAllo[0].General_Accounting_Unit__c, 'A default allocation should be created.');
        system.assertEquals(1, queryAllo[0].Amount__c, 'The default allocation should cover the remainder of the amount.');
        system.assertEquals(campaigngau.id, queryAllo[1].General_Accounting_Unit__c, 'An allocation mirroring the Campaign Allocation should be created.');
        system.assertEquals(4, queryAllo[1].Amount__c, 'The allocation amount should mirror the Campaign allocation, and the percentage should be calculated based on the opportunity amount.');
        system.assertEquals(campaigngau.id, queryAllo[2].General_Accounting_Unit__c, 'An allocation mirroring the Campaign Allocation should be created.');
        system.assertEquals(5, queryAllo[2].Amount__c, 'The allocation amount should mirror the Campaign allocation.');

        ALLO_Allocations_TDTM.hasRunForAllocations = false;
        ALLO_Allocations_TDTM.hasRunForOpportunities = false;
        Opportunity opp2 = new Opportunity(Name='error', Amount = 6, AccountID=acc.id, CampaignId=cam.id, CloseDate=system.today(), StageName=UTIL_UnitTestData_TEST.getClosedWonStage());
        insert opp2;

        //verify error created
        list<Error__c> queryError = [SELECT Id, Full_Message__c FROM Error__c];
        system.debug('LookHere: queryError ' + queryError);
        system.assertEquals(1, queryError.size(), 'A single error should be generated.');
        system.assert(queryError[0].Full_Message__c.contains(Label.alloCampaignExceedsOppAmount), 'The error should have the correct error message.');

        //verify default allocation created
        queryAllo = [SELECT Id, Amount__c FROM Allocation__c WHERE Opportunity__c=:opp2.id];
        system.assertEquals(1, queryAllo.size(), 'Only the default allocation should be created in the case where the allocation amount exceeded the Opportunity amount.');
    }

    //Recurring Payment allocations:
    //Create recurring payment. Pledged opportunity is generated automatically with a default allocation.

    //test allocations validation, etc when created for recurring payments
    @isTest
    static void recurringDonationsValidation() {
        if (strTestOnly != '*' && strTestOnly != 'recurringDonationsValidation') return;

        General_Accounting_Unit__c defaultgau = new General_Accounting_Unit__c(Name='General');
        insert defaultgau;

        settings = UTIL_CustomSettingsFacade.getAllocationsSettings();
        settings.Allocations_Enabled__c = true;
        settings.Default_Allocations_Enabled__c = true;
        settings.Default__c = defaultgau.id;
        update settings;

        Account acc = new Account(Name='foo');
        insert acc;
        General_Accounting_Unit__c gau = new General_Accounting_Unit__c(Name = 'foo');
        insert gau;
        npe03__Recurring_Donation__c rd = new npe03__Recurring_Donation__c(
            Name = 'foo', 
            npe03__Installment_Period__c = system.label.npe03.RecurringDonationInstallmentPeriodYearly, 
            npe03__Date_Established__c=date.newinstance(1984,01,29), 
            npe03__Organization__c = acc.id, 
            npe03__Amount__c = 20,
            npe03__Schedule_Type__c = system.label.npe03.RecurringDonationMultiplyValue,
            npe03__Open_Ended_Status__c = system.label.npe03.RecurringDonationOpenStatus
        );
        insert rd;
        list<Allocation__c> alloForInsert = new list<Allocation__c>();
        Allocation__c percentAllo = new Allocation__c(Recurring_Donation__c = rd.id, Percent__c = 50, General_Accounting_Unit__c = gau.id);
        alloForInsert.add(percentAllo);
        Allocation__c amountAllo = new Allocation__c(Recurring_Donation__c = rd.id, Amount__c = 10, General_Accounting_Unit__c = gau.id);
        alloForInsert.add(amountAllo);
        insert alloForInsert;


        list<Allocation__c> queryAllo = [SELECT Id, Amount__c, Percent__c, Recurring_Donation__r.Name FROM Allocation__c];
        system.debug('LookHere: inserted allocation in test ' + queryAllo);
        list<Opportunity> queryOpp = [SELECT Id, npe03__Recurring_Donation__c, Amount, CloseDate, StageName FROM Opportunity WHERE npe03__Recurring_Donation__c = :rd.id];
        system.debug('LookHere: opp before opp insert ' + queryOpp);

        ALLO_Allocations_TDTM.hasRunForAllocations = false;
        ALLO_Allocations_TDTM.hasRunForOpportunities = false;
        queryOpp[0].StageName = UTIL_UnitTestData_TEST.getClosedWonStage();
        update queryOpp;

        queryOpp = [SELECT Id, npe03__Recurring_Donation__c, Amount, CloseDate, StageName FROM Opportunity WHERE npe03__Recurring_Donation__c = :rd.id];
        system.debug('LookHere: opp after opp update ' + queryOpp);

        //Opportunity opp = new Opportunity(Name='foo', npe03__Recurring_Donation__c = rd.id, Amount = 20, AccountID=acc.id, CloseDate=system.today(), StageName=UTIL_UnitTestData_TEST.getClosedWonStage());
        //insert opp;

        queryAllo = [SELECT Id, Amount__c FROM Allocation__c WHERE Opportunity__c = :queryOpp[0].id];
        system.assertEquals(2,queryAllo.size(), 'Allocation for the automatically created Recurring Donation Opportunity should be created automatically after it is set to Closed Won.');
        system.assertEquals(10,queryAllo[0].Amount__c, 'Allocation amount should be set to the same as the Recurring Donation Allocation .');
    }

}