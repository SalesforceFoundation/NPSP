/*
    Copyright (c) 2014, Salesforce.org
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
* @group Allocations
* @group-content ../../ApexDocContent/Allocations.htm
* @description Tests specific to Allocations trigger based functionality.
*/
@isTest
private with sharing class ALLO_Allocations_TEST {

    // These variables are used in a "Setup Results" object map to find different
    // test data that was created

    /** @description Key to find GAUs with */
    private static final String GAUS_KEY = 'GAUS';

    /** @description Key to find DEFAULT GAU with */
    private static final String DEFAULTGAU_KEY = 'DEFAULTGAU';

    /** @description Key to find Opportunity Test Data with */
    private static final String OPPS_KEY = 'OPPS';

    /** @description Key to find Payment Test Data with */
    private static final String PMTS_KEY = 'PMTS';

    /*******************************************************************************************************
    * @description Setup of allocations settings.
    * @param alloset An instance of Allocations_Settings__c custom setting. Calling this method with a null
    * parameter uses default settings.
    * @return void Modifies settings, returns nothing.
    ********************************************************************************************************/
    private static void setupSettings (Allocations_Settings__c alloset) {
        //set running user to avoid dml issue
        System.runAs(new User(id = UserInfo.getUserId())){
            if (alloset!=null)
                UTIL_CustomSettingsFacade.getAllocationsSettingsForTests(alloset);
            else
                UTIL_CustomSettingsFacade.getAllocationsSettingsForTests(new Allocations_Settings__c());

        }
    }

    /*******************************************************************************************************
    * @description When changing the amount of an Opportunity with Allocations:
    * Increasing the amount will adjust the percentage allocations.
    * Decreasing the amount so that the total allocation amount is below the opportunity amount will adjust
    * the percentage allocations.
    * Decreasing the amount so that the total allocation amount is greater than the opportunity amount, an
    * error is thrown and the opportunity update is blocked.
    ********************************************************************************************************/
    static testMethod void oppAmountChange() {
        setupSettings(null);

        Account acc = new Account(Name='foo');
        insert acc;
        Opportunity opp = new Opportunity(Name='foo', Amount = 8, AccountID=acc.Id, CloseDate=System.today(), StageName=UTIL_UnitTestData_TEST.getClosedWonStage());
        insert opp;
        General_Accounting_Unit__c gau = new General_Accounting_Unit__c(Name='foo');
        insert gau;

        //resetting these manually as a test is considered a single context for static variables
        List<Allocation__c> alloForInsert = new List<Allocation__c>{
            createOppAllocation(gau.Id, opp.Id, null, 50),
            createOppAllocation(gau.Id, opp.Id, 4, null)
        };
        insert alloForInsert;

        list<Allocation__c> queryAllo = getAllocationsOrderByPercent();
        System.assertEquals(50, queryAllo[1].Percent__c, 'The percentage allocation should be 50%.');
        System.assertEquals(4, queryAllo[1].Amount__c, 'The amount of the percentage allocation should be calculated based on the Opportunity amount.');
        System.assertEquals(4, queryAllo[0].Amount__c, 'The amount of the standard number allocation should be 4.');

        opp.Amount = 10;
        Test.startTest();
        update opp;
        Test.stopTest();

        queryAllo = getAllocationsOrderByPercent();
        System.assertEquals(5, queryAllo[1].Amount__c, 'The amount of the percentage allocation should increase proportionately with the Opportunity amount.');
        System.assertEquals(4, queryAllo[0].Amount__c, 'The amount of the standard number allocation should be unchanged at 4.');

        opp.Amount = 8;
        update opp;

        queryAllo = getAllocationsOrderByPercent();
        System.assertEquals(4, queryAllo[1].Amount__c, 'The amount of the percentage allocation should decrease proportionately with the Opportunity amount.');
        System.assertEquals(4, queryAllo[0].Amount__c, 'The amount of the standard number allocation should be unchanged at 4.');

        opp.Amount = 1;

        Exception ex = null;
        try {
            update opp;
        } catch (Exception e) {
            ex = e;
        }
        System.assertNotEquals(null,ex,'An exception should be caught.');
        //System.assert(ex.getMessage().contains(), ex.getMessage());

        list<Opportunity> queryOpps = [SELECT Id, Amount FROM opportunity WHERE Id = :opp.Id];
        System.assertEquals(8, queryOpps[0].Amount, 'The opportunity amount should remain unchanged after the exception is caught.');
    }

    /*******************************************************************************************************
    * @description When Payments are created after the Opportunity and Opportunity Allocations exist,
    * ensure that the payment allocation percentages match those from the Opportunity Allocations, and
    * are not overwritten by additional logic in the trigger.
    * Also check that allocation rounding works correctly and no amounts are allocated to the Default GAU
    ********************************************************************************************************/
    @isTest
    private static void confirmNewPaymentAllocationsMatchExistingOpportunityAllocations() {
        General_Accounting_Unit__c defaultGau = new General_Accounting_Unit__c(Name='default GAU');
        insert defaultGau;

        setupSettings(new Allocations_Settings__c(
            Payment_Allocations_Enabled__c = true,
            Default_Allocations_Enabled__c = true,
            Default__c = defaultGau.Id));

        Account acc = new Account(Name='Account-pmtAlloPercentCheck');
        insert acc;
        Opportunity opp = new Opportunity(
            Name = 'Opp-pmtAlloPercentCheck',
            Amount = 100,
            AccountID = acc.Id,
            CloseDate = System.today(),
            StageName = UTIL_UnitTestData_TEST.getClosedWonStage()
        );
        insert opp;

        List<General_Accounting_Unit__c> gauForInsert = new List<General_Accounting_Unit__c>();

        General_Accounting_Unit__c gau1 = new General_Accounting_Unit__c(Name='GAU-1');
        gauForInsert.add(gau1);
        General_Accounting_Unit__c gau2 = new General_Accounting_Unit__c(Name='GAU-2');
        gauForInsert.add(gau2);
        General_Accounting_Unit__c gau3 = new General_Accounting_Unit__c(Name='GAU-3');
        gauForInsert.add(gau3);
        insert gauForInsert;

        List<Allocation__c> alloForInsert = new List<Allocation__c>{
            createOppAllocation(gau1.Id, opp.Id, null, 10),
            createOppAllocation(gau1.Id, opp.Id, null, 24),
            createOppAllocation(gau2.Id, opp.Id, null, 33),
            createOppAllocation(gau3.Id, opp.Id, 33, null)
        };
        insert alloForInsert;

        // This Payment amount will allow us to test rounding of allocation percentages and amounts
        npe01__OppPayment__c pmt = new npe01__OppPayment__c(npe01__Payment_Amount__c = 7.70, npe01__Opportunity__c = opp.Id);
        Test.startTest();
        insert pmt;
        Test.stopTest();

        // Check that each allocation has the correct amount and percent
        List<Allocation__c> queryAllo = getAllocationsOrderByPercent(pmt.Id, gau1.Id);

        // Make sure the percent value carried through to the Payment Allocation
        System.assertEquals(34, queryAllo[0].Percent__c, 'The allocation percentage should be 34%.');
        System.assertEquals(2.62, queryAllo[0].Amount__c, 'The amount of the percentage allocation should be calculated based on the Payment amount.');

        queryAllo = getAllocationsOrderByPercent(pmt.Id, gau2.Id);

        System.assertEquals(33, queryAllo[0].Percent__c, 'The allocation percentage should be 33%.');
        System.assertEquals(2.54, queryAllo[0].Amount__c, 'The amount of the percentage allocation should be calculated based on the Payment amount.');

        // This Allocation did not have a Percent set, but it should now
        queryAllo = getAllocationsOrderByPercent(pmt.Id, gau3.Id);

        System.assertEquals(33, queryAllo[0].Percent__c, 'The allocation percentage should be 33%.');
        System.assertEquals(2.54, queryAllo[0].Amount__c, 'The amount of the percentage allocation should be calculated based on the Payment amount.');

        queryAllo = getAllocationsOrderByPercent(pmt.Id, defaultGau.Id);
        System.assertEquals(queryAllo.size(), 0, 'This payment should be fully allocated without the Default GAU');

    }

    /*******************************************************************************************************
    * @description When Payments are created after the Opportunity and Opportunity Allocations exist,
    * ensure that the payment allocation percentages match those from the Opportunity Allocations, and
    * are not overwritten by additional logic in the trigger.
    * Also check that no amounts are allocated to the Default GAU
    ********************************************************************************************************/
    @isTest
    private static void confirmNewPaymentAllocationsMatchExistingOppAllocationNotRounding() {
        General_Accounting_Unit__c defaultGau = new General_Accounting_Unit__c(Name='default GAU');
        insert defaultGau;

        setupSettings(new Allocations_Settings__c(
            Payment_Allocations_Enabled__c = true,
            Default_Allocations_Enabled__c = true,
            Default__c = defaultGau.Id));

        Account acc = new Account(Name='Account-pmtAlloPercentCheck');
        insert acc;
        Opportunity opp = new Opportunity(
            Name = 'Opp-pmtAlloPercentCheck',
            Amount = 100.01,
            AccountID = acc.Id,
            CloseDate = System.today(),
            StageName = UTIL_UnitTestData_TEST.getClosedWonStage()
        );
        insert opp;

        List<General_Accounting_Unit__c> gauForInsert = new List<General_Accounting_Unit__c>();

        General_Accounting_Unit__c gau1 = new General_Accounting_Unit__c(Name='GAU-1');
        gauForInsert.add(gau1);
        General_Accounting_Unit__c gau2 = new General_Accounting_Unit__c(Name='GAU-2');
        gauForInsert.add(gau2);
        insert gauForInsert;

        List<Allocation__c> alloForInsert = new List<Allocation__c>{
            createOppAllocation(gau1.Id, opp.Id, null, 25),
            createOppAllocation(gau1.Id, opp.Id, 25, null),
            createOppAllocation(gau2.Id, opp.Id, 50.01, null)
        };
        insert alloForInsert;

        // This Payment amount will allow us to test rounding of allocation percentages and amounts
        npe01__OppPayment__c pmt = new npe01__OppPayment__c(npe01__Payment_Amount__c = 100.01, npe01__Opportunity__c = opp.Id);
        Test.startTest();
        insert pmt;
        Test.stopTest();

        // Check that each allocation has the correct amount and percent
        List<Allocation__c> queryAllo = getAllocationsOrderByPercent(pmt.Id, gau1.Id);
        
        // We want the unrounded percentages to compare since that is what we are storing.
        // $25 Fixed amount + $(25% * 100.01) = $50.0025 (Total Amount for GAU 1)
        Double percentGAU1 = (50.0025/100.01) * 100;
        Double percentGAU2 = (50.01/100.01) * 100;
        
        // Make sure the percent value carried through to the Payment Allocation
        System.assertEquals(percentGAU1, queryAllo[0].Percent__c, 'The allocation percentage should be 50%.');
        System.assertEquals(50, queryAllo[0].Amount__c, 'The amount of the allocation should be calculated based on the parent Opportunity allocation.');

        queryAllo = getAllocationsOrderByPercent(pmt.Id, gau2.Id);

        System.assertEquals(percentGAU2, queryAllo[0].Percent__c, 'The allocation percentage should be 50%.');
        System.assertEquals(50.01, queryAllo[0].Amount__c, 'The amount of the allocation should be calculated based on the parent Opportunity allocation.');

        queryAllo = getAllocationsOrderByPercent(pmt.Id, defaultGau.Id);
        System.assertEquals(queryAllo.size(), 0, 'This payment should be fully allocated without the Default GAU');

    }


    /*******************************************************************************************************
    * @description When changing the amount of a Payment with Allocations:
    * Increasing the amount will adjust the percentage allocations.
    * Decreasing the amount so that the total allocation amount is below the payment amount will adjust
    * the percentage allocations.
    * Decreasing the amount so that the total allocation amount is greater than the payment amount, an
    * error is thrown and the payment update is blocked.
    ********************************************************************************************************/
    static testMethod void pmtAmountChange() {
        General_Accounting_Unit__c defaultGau = new General_Accounting_Unit__c(Name='default GAU');
        insert defaultGau;

        setupSettings(new Allocations_Settings__c(
            Payment_Allocations_Enabled__c = true,
            Default_Allocations_Enabled__c = true,
            Default__c = defaultGau.Id));

        Account acc = new Account(Name='Account-pmtAmountChange');
        insert acc;
        Opportunity opp = new Opportunity(Name='Opp-pmtAmountChange', Amount = 10, AccountID=acc.Id, CloseDate=System.today(), StageName=UTIL_UnitTestData_TEST.getClosedWonStage());
        insert opp;
        npe01__OppPayment__c pmt = new npe01__OppPayment__c(npe01__Payment_Amount__c = 8, npe01__Opportunity__c = opp.Id);
        insert pmt;
        General_Accounting_Unit__c gau = new General_Accounting_Unit__c(Name='GAU-pmtAmountChange');
        insert gau;

        //resetting these manually as a test is considered a single context for static variables
        List<Allocation__c> alloForInsert = new List<Allocation__c>();

        Allocation__c percentAllo = new Allocation__c(Payment__c=pmt.id, Percent__c = 50, General_Accounting_Unit__c = gau.id);
        alloForInsert.add(percentAllo);
        Allocation__c amountAllo = new Allocation__c(Payment__c=pmt.id, Amount__c = 4, General_Accounting_Unit__c = gau.id);
        alloForInsert.add(amountAllo);
        insert alloForInsert;

        List<Allocation__c> queryAllo = getAllocationsOrderByPercent(pmt.Id, gau.Id);

        System.assertEquals(50, queryAllo[1].Percent__c, 'The percentage allocation should be 50%.');
        System.assertEquals(4, queryAllo[1].Amount__c, 'The amount of the percentage allocation should be calculated based on the Payment amount.');
        System.assertEquals(4, queryAllo[0].Amount__c, 'The amount of the standard number allocation should be 4.');

        pmt.npe01__Payment_Amount__c = 10;
        Test.startTest();
        update pmt;
        Test.stopTest();

        queryAllo = getAllocationsOrderByPercent(pmt.Id, gau.Id);
        System.assertEquals(5, queryAllo[1].Amount__c, 'The amount of the percentage allocation should increase proportionately with the Payment amount.');
        System.assertEquals(4, queryAllo[0].Amount__c, 'The amount of the standard number allocation should be unchanged at 4.');

        pmt.npe01__Payment_Amount__c = 8;
        update pmt;

        queryAllo = getAllocationsOrderByPercent(pmt.Id, gau.Id);
        System.assertEquals(4, queryAllo[1].Amount__c, 'The amount of the percentage allocation should decrease proportionately with the Payment amount.');
        System.assertEquals(4, queryAllo[0].Amount__c, 'The amount of the standard number allocation should be unchanged at 4.');

        pmt.npe01__Payment_Amount__c = 1;

        try {
            update pmt;
            System.assert(false, 'An exception should be caught.');
        } catch (Exception ex) {
            System.assert(ex.getMessage().contains(Label.alloExceedsPmtAmount), 'Error message should indicate that allocs are greater than payment amount');
        }

        List<npe01__OppPayment__c> queryPmts = [SELECT Id, npe01__Payment_Amount__c FROM npe01__OppPayment__c WHERE Id = :pmt.Id];
        System.assertEquals(8, queryPmts[0].npe01__Payment_Amount__c, 'The payment amount should remain unchanged after the exception is caught.');
    }

    /*******************************************************************************************************
    * @description Validates that when there are multiple allocations to the same GAU on the Opportunity,
    * the allocation amount will be consolidated on the payment level on insert and update. Additionally,
    * when there are multiple allocations to the same GAU on the payment level, it will be consolidated on the
    * Opportunity level (Only going from payment to opportunity, not Recurring donation/campaign to opportunity)
    ********************************************************************************************************/
    static testMethod void duplicateGAUWithPayments() {
        General_Accounting_Unit__c defaultGau = new General_Accounting_Unit__c(Name='default GAU');
        insert defaultGau;

        setupSettings(new Allocations_Settings__c(
            Payment_Allocations_Enabled__c = true,
            Default_Allocations_Enabled__c = true,
            Default__c = defaultGau.Id));

        Account acc = new Account(Name='Account-pmtAmountChange');
        insert acc;
        Opportunity opp = new Opportunity(Name='Opp-pmtAmountChange', Amount = 100, AccountID=acc.Id, CloseDate=System.today(), npe01__Do_Not_Automatically_Create_Payment__c = true, StageName=UTIL_UnitTestData_TEST.getClosedWonStage());
        insert opp;

        General_Accounting_Unit__c gau = new General_Accounting_Unit__c(Name='GAU-pmtAmountChange');
        insert gau;

        General_Accounting_Unit__c gau2 = new General_Accounting_Unit__c(Name='GAU2');
        insert gau2;



        //resetting these manually as a test is considered a single context for static variables
        List<Allocation__c> alloForInsert = new List<Allocation__c>();
        Allocation__c percentAllo = createOppAllocation(gau.Id, opp.Id, null, 75);
        alloForInsert.add(percentAllo);
        Allocation__c amountAllo = createOppAllocation(gau.Id, opp.Id, 25, null);
        alloForInsert.add(amountAllo);
        insert alloForInsert;

        // Validate the consolidation is correct on insert.
        npe01__OppPayment__c pmt = new npe01__OppPayment__c(npe01__Payment_Amount__c = 100, npe01__Opportunity__c = opp.Id);
        insert pmt;

        List<Allocation__c> queryAllo = getAllocationsOrderByPercent(pmt.Id, gau.Id);


        System.assertEquals(1, queryAllo.size(), 'There should only be one allocation');
        System.assertEquals(100, queryAllo[0].Amount__c, 'The allocation amount should be 100');

        List<Allocation__c> oppAllocationList = getAllocationsOrderByPercent(opp.Id);
        percentAllo.General_Accounting_Unit__c = gau2.Id;
        percentAllo.Percent__c = 75;
        percentAllo.Opportunity__c = opp.Id;

        amountAllo.General_Accounting_Unit__c = gau2.Id;
        amountAllo.Amount__c = 25;
        amountAllo.Opportunity__c = opp.Id;
        List<Allocation__c> alloForUpdate = new List<Allocation__c>();
        alloForUpdate.add(percentAllo);
        alloForUpdate.add(amountAllo);

        // Validate the consolidation is correct on update.
        update alloForUpdate;

        queryAllo = getAllocationsOrderByPercent(pmt.Id, gau2.Id);

        System.assertEquals(1, queryAllo.size(), 'There should only be one allocation');
        System.assertEquals(100, queryAllo[0].Amount__c, 'The allocation amount should be 100');

        // Validate that the consolidation is correct going from payment to opportunity.
        List<Allocation__c> alloForUpsert = new List<Allocation__c>();

        Allocation__c paymentAllo = new Allocation__c(Payment__c=pmt.Id, Amount__c = 25, General_Accounting_Unit__c = gau.Id);

        Allocation__c existingPaymentAllo = queryAllo[0];
        existingPaymentAllo.General_Accounting_Unit__c = gau.Id;
        existingPaymentAllo.Percent__c = 75;
        alloForUpsert.add(existingPaymentAllo);
        alloForUpsert.add(paymentAllo);
        TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.flag.ALLOC, false);

        update existingPaymentAllo;
        insert paymentAllo;

        queryAllo = getAllocationsOrderByPercent(opp.Id);

        System.assertEquals(1, queryAllo.size(), 'There should only be one allocation');
        System.assertEquals(100, queryAllo[0].Amount__c, 'The allocation amount should be 100');

    }

    /*******************************************************************************************************
    * @description When working with negative and positive Payments:
    * A mixture of positive and negative payments should be successfully inserted
    * This test was created to ensure we are not breaking Accounting Subledger functionality
    ********************************************************************************************************/
    static testMethod void pmtsWithPositiveAndNegativeAmounts() {
        Date todaysDate = System.today();
        Date tomorrowsDate = System.today().addDays(1);
        Date todayPlusOneMonthsDate = System.today().addMonths(1);
        Date todayPlusTwoMonthsDate = System.today().addMonths(2);
        Date todayPlusThreeMonthsDate = System.today().addMonths(3);

        General_Accounting_Unit__c defaultGau = new General_Accounting_Unit__c(Name='default GAU');
        insert defaultGau;

        setupSettings(new Allocations_Settings__c(
            Payment_Allocations_Enabled__c = true,
            Default_Allocations_Enabled__c = true,
            Default__c = defaultGau.Id));

        Account acc = new Account(Name='Account-pmtAmountChange');
        insert acc;

        List<General_Accounting_Unit__c> gaus = UTIL_UnitTestData_TEST.createGAUs(4);
        insert gaus;

        Opportunity opp = new Opportunity(Name='Opp-pmtAmountChange', Amount = 1000, AccountID=acc.Id, CloseDate=System.today(), StageName=UTIL_UnitTestData_TEST.getOpenStage(), npe01__Do_Not_Automatically_Create_Payment__c=true);
        insert opp;

        //Create Opportunity Allocation Defaults
        List<Allocation__c> oppAllocations = new List<Allocation__c>();
        Allocation__c opp1Allo1 = new Allocation__c(General_Accounting_Unit__c = gaus[0].Id,
                Amount__c = 200, //20%
                Opportunity__c = opp.Id);
                Allocation__c opp1Allo2 = new Allocation__c(General_Accounting_Unit__c = gaus[1].Id,
                Amount__c = 800, //80%
                Opportunity__c = opp.Id);

        oppAllocations.add(opp1Allo1);
        oppAllocations.add(opp1Allo2);

        insert oppAllocations;

        List<npe01__OppPayment__c> payments = new List<npe01__OppPayment__c>();
        npe01__OppPayment__c p1 = new npe01__OppPayment__c(npe01__Opportunity__c = opp.Id,
            npe01__Scheduled_Date__c = todaysDate, npe01__Payment_Amount__c = 400);
        npe01__OppPayment__c p2 = new npe01__OppPayment__c(npe01__Opportunity__c = opp.Id,
            npe01__Scheduled_Date__c = todayPlusOneMonthsDate, 
            npe01__Payment_Amount__c = 600);
        payments.add(p1);
        payments.add(p2);

        insert payments;

        opp.StageName = UTIL_UnitTestData_TEST.getClosedWonStage();
        update opp;

        payments = new List<npe01__OppPayment__c>();

        //Now Insert a mixture of payments
        p1 = new npe01__OppPayment__c(
                npe01__Opportunity__c = opp.Id,
                npe01__Payment_Date__c = todaysDate,
                npe01__Paid__c = true,
                npe01__Payment_Amount__c = 300);
        p2 = new npe01__OppPayment__c(
                npe01__Opportunity__c = opp.Id,
                npe01__Payment_Date__c = todayPlusOneMonthsDate,
                npe01__Paid__c = true,
                npe01__Payment_Amount__c = -200);
        npe01__OppPayment__c p3 = new npe01__OppPayment__c(
                npe01__Opportunity__c = opp.Id,
                npe01__Payment_Date__c = todayPlusTwoMonthsDate,
                npe01__Paid__c = true,
                npe01__Payment_Amount__c = 500);
        npe01__OppPayment__c p4 = new npe01__OppPayment__c(
                npe01__Opportunity__c = opp.Id,
                npe01__Payment_Date__c = todayPlusThreeMonthsDate,
                npe01__Paid__c = true,
                npe01__Payment_Amount__c = -600);

        payments.add(p1);
        payments.add(p2);
        payments.add(p3);
        payments.add(p4);

        Test.startTest();
        insert payments;
        Test.stopTest();

        List<Allocation__c> queryAllo = getAllocationsOrderByPercent(p1.Id, gaus[0].Id);
        System.assertEquals(300 * 0.2, queryAllo[0].Amount__c, 'The allocation amount should be 20% of the Payment');

        queryAllo = getAllocationsOrderByPercent(p2.Id, gaus[0].Id);
        System.assertEquals(-200 * 0.2, queryAllo[0].Amount__c, 'The allocation amount should be 20% of the Payment');

    }

    /*******************************************************************************************************
    * @description When working with negative amount Payments:
    * Updating the amount will adjust the percentage allocations.
    * Changing the amount sign from positive to negative and vice versa also flips the sign on the allocations
    * Decreasing the amount so that the total allocation amount (absolute value) is greater than the payment
    * amount, an error is thrown and the payment update is blocked.
    ********************************************************************************************************/
    static testMethod void pmtsWithNegativeAmount() {
        General_Accounting_Unit__c defaultGau = new General_Accounting_Unit__c(Name='default GAU');
        insert defaultGau;

        setupSettings(new Allocations_Settings__c(
            Payment_Allocations_Enabled__c = true,
            Default_Allocations_Enabled__c = true,
            Default__c = defaultGau.Id));

        Account acc = new Account(Name='Account-pmtAmountChange');
        insert acc;
        Opportunity opp = new Opportunity(Name='Opp-pmtAmountChange', Amount = 10, AccountID=acc.Id, CloseDate=System.today(), StageName=UTIL_UnitTestData_TEST.getClosedWonStage(), npe01__Do_Not_Automatically_Create_Payment__c=true);
        insert opp;
        npe01__OppPayment__c pmt = new npe01__OppPayment__c(npe01__Payment_Amount__c = -8, npe01__Opportunity__c = opp.Id);
        insert pmt;
        General_Accounting_Unit__c gau = new General_Accounting_Unit__c(Name='GAU-pmtAmountChange');
        insert gau;

        //resetting these manually as a test is considered a single context for static variables
        List<Allocation__c> alloForInsert = new List<Allocation__c>();

        Allocation__c percentAllo = new Allocation__c(Payment__c=pmt.Id, Percent__c = 50, General_Accounting_Unit__c = gau.Id);
        alloForInsert.add(percentAllo);
        Allocation__c amountAllo = new Allocation__c(Payment__c=pmt.Id, Amount__c = -4, General_Accounting_Unit__c = gau.Id);
        alloForInsert.add(amountAllo);
        insert alloForInsert;

        List<Allocation__c> queryAllo = [SELECT Id, Percent__c, Amount__c FROM Allocation__c WHERE Payment__c = :pmt.Id]; ///getAllocationsOrderByPercent();
        System.assertEquals(50, queryAllo[0].Percent__c, 'The percentage allocation should be 50%.');
        System.assertEquals(-4, queryAllo[0].Amount__c, 'The amount of the percentage allocation should be calculated based on the Payment amount.');
        System.assertEquals(-4, queryAllo[1].Amount__c, 'The amount of the standard number allocation should be -4.');

        pmt.npe01__Payment_Amount__c = 20;
        Test.startTest();
        update pmt;
        Test.stopTest();

        queryAllo = [SELECT Id, Percent__c, Amount__c FROM Allocation__c WHERE Payment__c = :pmt.Id]; ///getAllocationsOrderByPercent();
        System.assertEquals(10, queryAllo[0].Amount__c, 'The calculated amount of the % allocation should be positive in order to match the Payment.');
        System.assertEquals(4, queryAllo[1].Amount__c, 'The amount of the standard number allocation should be 4.');
        System.assertEquals(6, queryAllo[2].Amount__c, 'The amount of the default allocation should be to 6.');

        pmt.npe01__Payment_Amount__c = -10;
        update pmt;

        queryAllo = [SELECT Id, Percent__c, Amount__c FROM Allocation__c WHERE Payment__c = :pmt.Id]; ///getAllocationsOrderByPercent();
        System.assertEquals(-5, queryAllo[0].Amount__c, 'The amount of the percentage allocation should be updated proportionately with the Payment amount and should match the sign.');
        System.assertEquals(-4, queryAllo[1].Amount__c, 'The amount of the standard number allocation should be -4.');
        System.assertEquals(-1, queryAllo[2].Amount__c, 'The amount of the default allocation should be -1.');

        pmt.npe01__Payment_Amount__c = -1;

        try {
            update pmt;
            System.assert(false, 'An exception should be caught.');
        } catch (Exception ex) {
            System.assert(ex.getMessage().contains(Label.alloExceedsPmtAmount), 'Error message should indicate that allocs are greater than payment amount');
        }

        List<npe01__OppPayment__c> queryPmts = [SELECT Id, npe01__Payment_Amount__c FROM npe01__OppPayment__c WHERE Id = :pmt.Id];
        System.assertEquals(-10, queryPmts[0].npe01__Payment_Amount__c, 'The payment amount should remain unchanged after the exception is caught.');
    }

    /*******************************************************************************************************
    * @description With default General Accounting Units enabled, creating an Opportunity automatically
    * creates a default allocation for the full amount of the opportunity.
    * Creating a new allocation for that opportunity decreases the default fund allocation.
    * Creating an allocation for the total amount deletes the default allocation.
    ********************************************************************************************************/
    static testMethod void defaultAllocations() {
        General_Accounting_Unit__c defaultGau = new General_Accounting_Unit__c(Name='General');
        insert defaultGau;

        setupSettings(new Allocations_Settings__c(Default_Allocations_Enabled__c = true, Default__c = defaultGau.Id));

        Account acc = new Account(Name='foo');
        insert acc;
        Opportunity opp = new Opportunity(Name='foo', Amount = 8, AccountID=acc.Id, CloseDate=System.today(), StageName=UTIL_UnitTestData_TEST.getClosedWonStage());
        insert opp;

        General_Accounting_Unit__c gau = new General_Accounting_Unit__c(Name='foo');
        insert gau;

        list<Allocation__c> queryAllo = getAllocationsOrderByPercent();
        System.assertEquals(1,queryAllo.size(), 'An allocation to the default General Accounting Unit should be created.');
        System.assertEquals(8,queryAllo[0].Amount__c, 'The default allocation should be for the total amount of the Opportunity.');

        //resetting these manually as a test is considered a single context for static variables
        Allocation__c amountAllo = createOppAllocation(gau.Id, opp.Id, 6, null);
        Test.startTest();
        insert amountAllo;
        Test.stopTest();

        queryAllo = getAllocationsOrderByAmount();
        System.assertEquals(2,queryAllo[0].Amount__c, 'The default allocation should be equal to the remainder of the total Opp amount after removing the new Allocation amount: ' + queryAllo);

        amountAllo.Amount__c = 8;
        update amountAllo;

        queryAllo = getAllocationsOrderByAmount();
        System.assertEquals(1,queryAllo.size(), 'The default fund allocation should be deleted.');
    }

    /*******************************************************************************************************
    * @description Campaign Allocations test:
    * Opportunity created with campaign allocation: allocations are created, default allocation covers the
    * remainder.
    * Opportunity created where campaign allocations exceed opp amount: exception thrown, only default
    * allocation created
    ********************************************************************************************************/
    static testMethod void campaignAllocations() {
        General_Accounting_Unit__c defaultgau = new General_Accounting_Unit__c(Name='General');
        insert defaultgau;

        setupSettings(new Allocations_Settings__c(Default_Allocations_Enabled__c = true, Default__c = defaultGau.Id));

        Account acc = new Account(Name='foo');
        insert acc;
        General_Accounting_Unit__c campaigngau = new General_Accounting_Unit__c(Name='foo');
        insert campaigngau;
        Campaign cam = new Campaign(Name='Foo', IsActive=true);
        insert cam;

        list<Allocation__c> alloForInsert = new list<Allocation__c>();
        Allocation__c percentAllo = new Allocation__c(Campaign__c=cam.Id, Percent__c = 50, General_Accounting_Unit__c = campaigngau.Id);
        alloForInsert.add(percentAllo);
        Allocation__c amountAllo = new Allocation__c(Campaign__c=cam.Id, Amount__c = 4, General_Accounting_Unit__c = campaigngau.Id);
        alloForInsert.add(amountAllo);
        insert alloForInsert;

        Opportunity opp = new Opportunity(Name='success', Amount = 10, AccountID=acc.Id, CampaignId=cam.Id, CloseDate=System.today(), StageName=UTIL_UnitTestData_TEST.getClosedWonStage());
        Test.startTest();
        insert opp;
        Test.stopTest();

        //verify campaign allocation and default allocation created
        list<Allocation__c> queryAllo = getAllocationsOrderByAmount(opp.Id);
        System.assertEquals(3,queryAllo.size(), 'An allocation for the Campaign Opportunity should be created.');
        System.assertEquals(defaultgau.Id, queryAllo[0].General_Accounting_Unit__c, 'A default allocation should be created.');
        System.assertEquals(1, queryAllo[0].Amount__c, 'The default allocation should cover the remainder of the amount.');
        System.assertEquals(campaigngau.Id, queryAllo[1].General_Accounting_Unit__c, 'An allocation mirroring the Campaign Allocation should be created.');
        System.assertEquals(4, queryAllo[1].Amount__c, 'The allocation amount should mirror the Campaign allocation, and the percentage should be calculated based on the opportunity amount.');
        System.assertEquals(campaigngau.Id, queryAllo[2].General_Accounting_Unit__c, 'An allocation mirroring the Campaign Allocation should be created.');
        System.assertEquals(5, queryAllo[2].Amount__c, 'The allocation amount should mirror the Campaign allocation.');

        Opportunity opp2 = new Opportunity(Name='error', Amount = 6, AccountID=acc.Id, CampaignId=cam.Id, CloseDate=System.today(), StageName=UTIL_UnitTestData_TEST.getClosedWonStage());
        insert opp2;

        //verify percent allocation created
        queryAllo = getAllocationsOrderByPercent(opp2.Id);
        System.assertEquals(2, queryAllo.size(), 'Only the percent based allocation should be created in the case where the allocation amount exceeded the Opportunity amount.');
        System.assertEquals(3, queryAllo[0].Amount__c, 'The percent allocation should should equal half the opportunity amount.');
        System.assertEquals(3, queryAllo[1].Amount__c, 'The default allocation should cover the remainder of the amount.');

    }

    /*********************************************************************************************************
    @description
        Test Allocation on an Opportunity has the same GAU as the linked Campaign Allocation when
        NPSP Settings Default Allocations are enabled.
    verify:
        - The Campaign Allocation Amount covers Opportunity Amount
        (the Campaign Allocation Amount must be <= Opportunity Amount)
        - The Amount reminder is covered by the NPSP Default Allocation.
    **********************************************************************************************************/
    private static testMethod void testOppAllocationGauMatchesCampaignGau() {
        General_Accounting_Unit__c defaultGau = new General_Accounting_Unit__c(Name = 'Default');
        General_Accounting_Unit__c campaignGau = new General_Accounting_Unit__c(Name = 'Campaign');
        insert new General_Accounting_Unit__c[] {
            defaultGau, campaignGau
        };

        setupSettings(new Allocations_Settings__c(Default_Allocations_Enabled__c = true, Default__c = defaultGau.Id));

        Campaign campaign = new Campaign(Name = 'TestCampaign', IsActive = true);
        insert campaign;

        Allocation__c campaignAllocation = new Allocation__c(
            Campaign__c = campaign.Id, Amount__c = 100, General_Accounting_Unit__c = campaignGau.Id
        );
        insert campaignAllocation;

        Account acc = new Account(Name='TestAllocGauMatchesCampaignGau');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'InitOppWithNullAmount', AccountID = acc.Id,
            CampaignId = campaign.Id, Amount = null,
            CloseDate = System.today(), StageName = UTIL_UnitTestData_TEST.getClosedWonStage()
        );
        insert opp;

        List<Allocation__c> oppAllocations = getAllocationsOrderByAmount(opp.Id);
        System.assertEquals(0, oppAllocations.size(), 'No Allocation should be created for an Opportunity without Amount: ' + oppAllocations);

        Decimal remainder = 25;
        opp.Amount = campaignAllocation.Amount__c + remainder;

        Test.startTest();
        update opp;
        Test.stopTest();

        oppAllocations = getAllocationsOrderByAmount(opp.Id);
        System.assertEquals(2, oppAllocations.size(), 'Allocations should be created for the Opportunity that now has an Amount: ' + oppAllocations);

        System.assertEquals(remainder, oppAllocations[0].Amount__c, 'The Allocation Amount should match the remainder: ' + oppAllocations);
        System.assertEquals(defaultGau.Id, oppAllocations[0].General_Accounting_Unit__c, 'The Allocation Gau should match the Default Gau: ' + oppAllocations);

        System.assertEquals(campaignAllocation.Amount__c, oppAllocations[1].Amount__c, 'The Allocation Amount should match the Campaign Amount: ' + oppAllocations);
        System.assertEquals(campaignGau.Id, oppAllocations[1].General_Accounting_Unit__c, 'The Allocation Gau should match the Campaign Gau: ' + oppAllocations);
   }

    /*******************************************************************************************************
    * @description Recurring Donation Allocations test:
    * Create recurring donation. Pledged opportunity is generated automatically with a default allocation.
    * Create allocations for the recurring donation, verify opp allocations are created, default opp
    * allocation is deleted.
    * Set opp to closed/won, modify recurring donation allocations: closed opportunity's allocations are
    * unchanged.
    * Create new opportunity for the recurring donation schedule: RD allocations are created.
    * Create a recurring donation allocation to exceed the opportunity amount: open opportunity only gets
    * percent based allocations.
    * Remove allocation that exceed's opportunity amount: all RD allocations are created.
    * Delete a recurring donation allocation: corresponding opportunity allocation is also deleted.
    ********************************************************************************************************/
    static testMethod void recurringDonationsValidation() {
        General_Accounting_Unit__c defaultgau = new General_Accounting_Unit__c(Name='General');
        insert defaultgau;

        setupSettings(new Allocations_Settings__c(Default_Allocations_Enabled__c = true, Default__c = defaultGau.Id));

        Account acc = new Account(Name='foo');
        insert acc;
        General_Accounting_Unit__c gau = new General_Accounting_Unit__c(Name = 'foo');
        insert gau;
        npe03__Recurring_Donation__c rd = new TEST_RecurringDonationBuilder()
            .withInstallmentPeriodYearly()
            .withDateEstablished(System.today())
            .withAccount(acc.id)
            .withAmount(20)
            .withScheduleTypeMultiplyValue()
            .withOpenEndedStatusOpen()
            .build();

        // this initial creation of the RD with default allocations set up, which get copied to the opp
        // will be what we soql limit profile in this test (and thus the startTest/stopTest).
        Test.startTest();
        insert rd;
        Test.stopTest();

        //query for the opportunity automatically created by the schedule
        list<Opportunity> queryOpp = [SELECT Id, npe03__Recurring_Donation__c, Amount, CloseDate, StageName FROM Opportunity WHERE npe03__Recurring_Donation__c = :rd.Id];
        System.assertEquals(1,queryOpp.size(),'A single opportunity should be created.');

        list<Allocation__c> queryAllo = getAllocationsOrderByPercent(queryOpp[0].Id);
        System.assertEquals(1,queryAllo.size(),'A single default allocation should be created.');
        System.assertEquals(defaultgau.Id,queryAllo[0].General_Accounting_Unit__c,'The allocation should be assigned to the default General Accounting Unit.');
        System.assertEquals(20,queryAllo[0].Amount__c,'The default allocation should be for the total amount of the Opportunity.');

        list<Allocation__c> alloForInsert = new list<Allocation__c>();
        Allocation__c percentAllo = new Allocation__c(Recurring_Donation__c = rd.Id, Percent__c = 50, General_Accounting_Unit__c = gau.Id);
        alloForInsert.add(percentAllo);
        Allocation__c amountAllo = new Allocation__c(Recurring_Donation__c = rd.Id, Amount__c = 10, General_Accounting_Unit__c = gau.Id);
        alloForInsert.add(amountAllo);
        insert alloForInsert;

        queryAllo = getAllocationsOrderByPercent(queryOpp[0].Id);
        System.assertEquals(2,queryAllo.size(), 'Allocations for the open Recurring Donation Opportunity should be created automatically after they are created for the Recurring Donation.');
        System.assertEquals(gau.Id,queryAllo[0].General_Accounting_Unit__c, 'Allocations should be to the non-default GAU.');
        System.assertEquals(gau.Id,queryAllo[1].General_Accounting_Unit__c, 'Allocations should be to the non-default GAU.');
        System.assertEquals(10,queryAllo[1].Amount__c, 'The percentage based allocation amount should be set based on the opportunity amount.');

        queryOpp[0].StageName = UTIL_UnitTestData_TEST.getClosedWonStage();
        update queryOpp[0];

        percentAllo.Percent__c = 20;
        update percentAllo;
        queryAllo = getAllocationsOrderByPercent(queryOpp[0].Id);
        System.assertEquals(2,queryAllo.size(), 'Allocations for the closed/won opportunity should be unchanged.');
        System.assertEquals(50,queryAllo[1].Percent__c, 'The percentage based allocation should be unchanged.');

        Opportunity opp = new Opportunity(Name='foo', npe03__Recurring_Donation__c = rd.Id, Amount = 20, AccountID=acc.Id, CloseDate=System.today(), StageName=UTIL_UnitTestData_TEST.getOpenStage());
        insert opp;

        queryAllo = getAllocationsOrderByAmount(opp.Id);
        System.assertEquals(3,queryAllo.size(), 'Allocations for the open Recurring Donation Opportunity should be created automatically when the opportunity is created.');

        Allocation__c exceedAllo = new Allocation__c(Recurring_Donation__c = rd.Id, Amount__c = 10, General_Accounting_Unit__c = gau.Id);
        insert exceedAllo;

        queryAllo = getAllocationsOrderByPercent(opp.Id);
        System.assertEquals(2,queryAllo.size(), 'Only percent based Opportunity Allocation should exist: ' + queryAllo);
        System.assertEquals(16,queryAllo[0].Amount__c, 'The percentage based allocation amount should be set based on the opportunity amount: ' + queryAllo);

        delete exceedAllo;

        queryAllo = getAllocationsOrderByAmount(opp.Id);
        System.assertEquals(3,queryAllo.size(), 'Allocations for the open Recurring Donation Opportunity should be created automatically when the opportunity is created.');

        delete amountAllo;

        queryAllo = getAllocationsOrderByPercent(opp.Id);
        System.assertEquals(2,queryAllo.size(), 'Opportunity Allocation should be deleted along with the Recurring Donation allocation.');
        System.assertEquals(16,queryAllo[0].Amount__c, 'The percentage based allocation amount should be set based on the opportunity amount.');
    }

    /*******************************************************************************************************
    * @description Recurring Donation Allocations test:
    * Create recurring donation. Pledged opportunity is generated automatically with a default allocation.
    * Scheduled Payment created with a default allocation.
    * Create allocations for the recurring donation, verify opp allocations are created, default opp
    * allocation is deleted.  verify payment allocations are created, default opp allocation is deleted.
    * Set Payment to Written Off.  modify recurring donation allocations: Opportunity's allocations are
    * updated, but Written Off Payment's Allocations are left unchanged/
    ********************************************************************************************************/
    static testMethod void recurringDonationsPaymentAllocationValidation() {
        General_Accounting_Unit__c defaultgau = new General_Accounting_Unit__c(Name='General');
        insert defaultgau;

        setupSettings(new Allocations_Settings__c(
                        Default_Allocations_Enabled__c = true,
                        Payment_Allocations_Enabled__c = true,
                        Default__c = defaultGau.Id
        ));

        Account acc = new Account(Name='foo');
        insert acc;
        General_Accounting_Unit__c gau = new General_Accounting_Unit__c(Name = 'rdGAU1');
        General_Accounting_Unit__c gau2 = new General_Accounting_Unit__c(Name = 'rdGAU2');
        List<General_Accounting_Unit__c> gaus = new List<General_Accounting_Unit__c> {gau, gau2};

        insert gaus;


        npe03__Recurring_Donation__c rd = new TEST_RecurringDonationBuilder()
            .withInstallmentPeriodYearly()
            .withDateEstablished(System.today())
            .withAccount(acc.id)
            .withAmount(20)
            .withScheduleTypeMultiplyValue()
            .withOpenEndedStatusOpen()
            .build();

        // this initial creation of the RD with default allocations set up, which get copied to the opp
        // will be what we soql limit profile in this test (and thus the startTest/stopTest).
        Test.startTest();
        insert rd;
        Test.stopTest();

        //query for the opportunity automatically created by the schedule
        list<Opportunity> queryOpp = [SELECT Id, npe03__Recurring_Donation__c, Amount, CloseDate, StageName FROM Opportunity WHERE npe03__Recurring_Donation__c = :rd.Id];
        System.assertEquals(1,queryOpp.size(),'A single opportunity should be created.');

        list<Allocation__c> queryAllo = getAllocationsOrderByPercent(queryOpp[0].Id);
        System.assertEquals(1,queryAllo.size(),'A single default allocation should be created.');
        System.assertEquals(defaultgau.Id,queryAllo[0].General_Accounting_Unit__c,'The allocation should be assigned to the default General Accounting Unit.');
        System.assertEquals(20,queryAllo[0].Amount__c,'The default allocation should be for the total amount of the Opportunity.');

        List<npe01__OppPayment__c> pmts = [SELECT   Id,
                                                    npe01__Paid__c,
                                                    npe01__Written_Off__c
                                           FROM npe01__OppPayment__c
                                           where npe01__Opportunity__c = :queryOpp[0].Id];
        System.assertEquals(1, pmts.size(), 'A single payment should be created.');

        Map<Id, Allocation__c> pmtAllocsByGAU = getPaymentAllocationsByGAU(pmts[0].Id);
        System.assertEquals(1,pmtAllocsByGAU.size(),'A single default payment allocation should be created.');
        System.assertEquals(true, pmtAllocsByGAU.containsKey(defaultgau.Id),'The Payment allocation should be assigned to the default General Accounting Unit.');
        System.assertEquals(20, pmtAllocsByGAU.get(defaultgau.Id).Amount__c,'The default Payment allocation should be for the total amount of the Payment.');

        list<Allocation__c> alloForInsert = new list<Allocation__c>();
        Allocation__c percentAllo = new Allocation__c(Recurring_Donation__c = rd.Id, Percent__c = 50, General_Accounting_Unit__c = gau.Id);
        alloForInsert.add(percentAllo);
        Allocation__c amountAllo = new Allocation__c(Recurring_Donation__c = rd.Id, Amount__c = 10, General_Accounting_Unit__c = gau2.Id);
        alloForInsert.add(amountAllo);
        insert alloForInsert;

        // Confirm Opportunity Allocations were updated to match the Recurring Donation Allocations
        queryAllo = getAllocationsOrderByPercent(queryOpp[0].Id);
        System.assertEquals(2,queryAllo.size(), 'Allocations for the open Recurring Donation Opportunity should be created automatically after they are created for the Recurring Donation.');
        System.assertEquals(gau2.Id,queryAllo[0].General_Accounting_Unit__c, 'Allocations should be to the non-default GAU.');
        System.assertEquals(gau.Id,queryAllo[1].General_Accounting_Unit__c, 'Allocations should be to the non-default GAU.');
        System.assertEquals(10,queryAllo[0].Amount__c, 'The allocation amount should be set to a fixed amount.');
        System.assertEquals(10,queryAllo[1].Amount__c, 'The percentage based allocation amount should be set based on the opportunity amount.');

        // Confirm Payment Allocations were updated to match the Opportunity Allocations updates
        pmtAllocsByGAU = getPaymentAllocationsByGAU(pmts[0].Id);
        System.assertEquals(2, pmtAllocsByGAU.size(), 'Allocations for the scheduled Payment should be created automatically after they are updated for the Opportunity as a result of the Recurring Donation change.');
        System.assertEquals(true, pmtAllocsByGAU.containsKey(gau.Id),'Allocations should be to the non-default GAU.');
        System.assertEquals(true, pmtAllocsByGAU.containsKey(gau2.Id),'Allocations should be to the non-default GAU 2.');

        System.assertEquals(10, pmtAllocsByGAU.get(gau.Id).Amount__c,'The amount of the allocation.');
        System.assertEquals(10, pmtAllocsByGAU.get(gau2.Id).Amount__c,'The amount of the allocation.');

        // Make Payment Written Off
        pmts[0].npe01__Written_Off__c = true;
        update pmts;

        // Adjust the Recurring Donation Percent Allocation to 20%
        percentAllo.Percent__c = 20;
        update percentAllo;

        // Confirm Opportunity Allocations were updated
        queryAllo = getAllocationsOrderByPercent(queryOpp[0].Id);
        System.assertEquals(3,queryAllo.size(), 'Allocations updated for the percentage change.');

        // Confirm Payment Allocations were not updated since Payment is now Written Off
        pmtAllocsByGAU = getPaymentAllocationsByGAU(pmts[0].Id);
        System.assertEquals(2, pmtAllocsByGAU.size(), 'Allocations for the scheduled Payment should be created automatically after they are updated for the Opportunity as a result of the Recurring Donation change.');
        System.assertEquals(true, pmtAllocsByGAU.containsKey(gau.Id),'Allocations should be to the non-default GAU.');
        System.assertEquals(true, pmtAllocsByGAU.containsKey(gau2.Id),'Allocations should be to the non-default GAU 2.');

        System.assertEquals(10, pmtAllocsByGAU.get(gau.Id).Amount__c,'The amount of the allocation.');
        System.assertEquals(10, pmtAllocsByGAU.get(gau2.Id).Amount__c,'The amount of the allocation.');
    }

    /*******************************************************************************************************
    * @description Create a campaign with an allocation, and 100 opportunities, half of which are attributed
    * to the campaign. Verifies that default allocations and campaign allocations are created.
    * Updates all opportunity amounts to be equal to the campaign allocation amount, verifies that default
    * allocations were deleted when no longer needed.
    ********************************************************************************************************/
    static testMethod void bulkOppInsert() {
        General_Accounting_Unit__c defaultgau = new General_Accounting_Unit__c(Name='General');
        insert defaultgau;

        setupSettings(new Allocations_Settings__c(Default_Allocations_Enabled__c = true, Default__c = defaultGau.Id));

        Account acc = new Account(Name='foo');
        insert acc;
        General_Accounting_Unit__c campaigngau = new General_Accounting_Unit__c(Name='Campaign Allocation');
        insert campaigngau;
        Campaign cam = new Campaign(Name='Foo', IsActive=true);
        insert cam;

        list<Allocation__c> alloForInsert = new list<Allocation__c>();
        Allocation__c percentAllo = new Allocation__c(Campaign__c=cam.Id, Amount__c = 4, General_Accounting_Unit__c = campaigngau.Id);
        alloForInsert.add(percentAllo);
        insert alloForInsert;

        list<Opportunity> oppList = new list<Opportunity>();
        for (integer i=0;i<100;i++)
            oppList.add(new Opportunity(Name='opp'+i, Amount = 8, AccountID=acc.Id, CampaignId=math.mod(i,2)==0?cam.Id:null, CloseDate=System.today(), StageName=UTIL_UnitTestData_TEST.getClosedWonStage()));
        Test.startTest();
        insert oppList;
        Test.stopTest();

        list<AggregateResult> queryAggResult = [SELECT count_distinct(Id), General_Accounting_Unit__r.Name FROM Allocation__c WHERE Opportunity__r.Name LIKE 'opp%' GROUP BY General_Accounting_Unit__r.Name ORDER BY count_distinct(Id)];
        System.assertEquals(50, queryAggResult[0].get('expr0'), 'Fifty campaign allocations should be created.');
        System.assertEquals(100, queryAggResult[1].get('expr0'), 'One hundred default allocations should be created.');

        for (Opportunity opp : oppList)
            opp.Amount = 4;

        update oppList;

        queryAggResult = [SELECT count_distinct(Id), General_Accounting_Unit__r.Name FROM Allocation__c WHERE Opportunity__r.Name LIKE 'opp%' GROUP BY General_Accounting_Unit__r.Name ORDER BY count_distinct(Id)];
        System.assertEquals(50, queryAggResult[0].get('expr0'), 'Fifty campaign allocations should still exist.');
        System.assertEquals(50, queryAggResult[1].get('expr0'), 'Fifty default allocations should remain.');

    }

    /*******************************************************************************************************
    * @description Inserts opportunities which excluded types and record types. Verifies no default
    * allocations are created.
    ********************************************************************************************************/
    static testMethod void testExcludedOpps() {
        General_Accounting_Unit__c defaultgau = new General_Accounting_Unit__c(Name='General');
        insert defaultgau;

        string rtname = UTIL_RecordTypes.getRecordTypeNameForGiftsTests(Opportunity.sObjectType);
        id rtid = UTIL_RecordTypes.GetRecordTypeId(Opportunity.sObjectType,rtname);

        setupSettings(new Allocations_Settings__c(Default_Allocations_Enabled__c = true, Default__c = defaultGau.Id, Excluded_Opp_Types__c='foo;bar', Excluded_Opp_RecTypes__c=rtid));
        Account acc = new Account(Name='foo');
        insert acc;

        list<Opportunity> oppForInsert = new list<Opportunity>();
        oppForInsert.add(new Opportunity(Name='excluded type', Type='foo', Amount = 10, AccountID=acc.Id, CloseDate=System.today(), StageName=UTIL_UnitTestData_TEST.getClosedWonStage()));
        //only test the record type exclusion if one exists.
        if (rtid!=null)
            oppForInsert.add(new Opportunity(Name='excluded record type', RecordTypeId=rtid, Amount = 10, AccountID=acc.Id, CloseDate=System.today(), StageName=UTIL_UnitTestData_TEST.getClosedWonStage()));
        Test.startTest();
        insert oppForInsert;
        Test.stopTest();

        list<Allocation__c> queryAllo = getAllocationsOrderByAmount();
        System.assertEquals(0,queryAllo.size(), 'No default allocation should be created for an excluded opportunity type or an excluded opportunity record type.');

    }

    /*******************************************************************************************************
    * @description Inserts an opportunity with a null amount, verifies no default allocation is created.
    * Updates the amount, verifies default allocation was created. Nulls out the amount, verifies the
    * default allocation was deleted.
    ********************************************************************************************************/
    static testMethod void testOppNullAmount() {
        General_Accounting_Unit__c defaultgau = new General_Accounting_Unit__c(Name='General');
        insert defaultgau;

        setupSettings(new Allocations_Settings__c(Default_Allocations_Enabled__c = true, Default__c = defaultGau.Id));
        Account acc = new Account(Name='foo');
        insert acc;

        Opportunity opp = new Opportunity(Name='foo', Amount = null, AccountID=acc.Id, CloseDate=System.today(), StageName=UTIL_UnitTestData_TEST.getClosedWonStage());
        Test.startTest();
        insert opp;
        Test.stopTest();

        list<Allocation__c> queryAllo = getAllocationsOrderByAmount(opp.Id);
        System.assertEquals(0,queryAllo.size(),'No default allocation should be created for an opportunity with a null amount.');

        opp.Amount = 8;
        update opp;

        queryAllo = getAllocationsOrderByAmount(opp.Id);
        System.assertEquals(1,queryAllo.size(),'A default allocation should be created for the opportunity that now has an amount.');

        opp.Amount = null;
        update opp;

        queryAllo = getAllocationsOrderByAmount(opp.Id);
        System.assertEquals(0,queryAllo.size(),'A default allocation should be deleted for the opportunity that now has no amount.');
    }

    /*******************************************************************************************************
    * @description Creates a campaign allocation, marks that allocation's GAU as inactive. Insert an
    * opportunity assigned to the campaign, verify only default allocation is created and no error is
    * thrown. Deactivates the opportunity allocation's GAU, updates the opportunity amount, verifies the
    * allocation to the inactive GAU isn't modified.
    ********************************************************************************************************/
    static testMethod void testInactiveGAU() {
        setupSettings(null);

        Account acc = new Account(Name='foo');
        insert acc;

        list<General_Accounting_Unit__c> listGau = new list<General_Accounting_Unit__c>();
        listGau.add(new General_Accounting_Unit__c(Name='Campaign Allocation 1'));
        listGau.add(new General_Accounting_Unit__c(Name='Campaign Allocation 2'));
        insert listGau;

        Campaign cam = new Campaign(Name='Foo', IsActive=true);
        insert cam;

        list<Allocation__c> listAllo = new list<Allocation__c>();
        listAllo.add(new Allocation__c(Campaign__c=cam.Id, Amount__c = 3, General_Accounting_Unit__c = listGau[0].Id));
        listAllo.add(new Allocation__c(Campaign__c=cam.Id, Percent__c = 50, General_Accounting_Unit__c = listGau[1].Id));
        insert listAllo;

        listGau[0].Active__c = false;
        update listGau[0];

        Opportunity opp = new Opportunity(Name='foo', CampaignId=cam.Id, Amount = 8, AccountID=acc.Id, CloseDate=System.today(), StageName=UTIL_UnitTestData_TEST.getClosedWonStage());
        Test.startTest();
        insert opp;
        Test.stopTest();

        list<Allocation__c>  queryAllo = getAllocationsOrderByAmount(opp.Id);
        System.assertEquals(1,queryAllo.size(), 'A single allocation should be created.');
        System.assertEquals(listGau[1].Id, queryAllo[0].General_Accounting_Unit__c, 'The single allocation should be assigned to the active GAU.');
        System.assertEquals(50, queryAllo[0].Percent__c, 'The allocation should be percent based.');

        listGau[1].Active__c = false;
        update listGau[1];

        opp.Amount = 80;

        Exception ex = null;
        try {
            update opp;
        } catch (Exception e) {
            ex = e;
        }
        System.assertNotEquals(null, ex, 'An exception should be thrown.');

        //ensure the allocations are not changed.
        queryAllo = getAllocationsOrderByAmount(opp.Id);
        System.assertEquals(4,queryAllo[0].Amount__c, 'Allocation to inactive GAU should not be modified.');

    }

    /*******************************************************************************************************
    * @description Tests the ALLO_MakeDefaultAllocations_BATCH class. Creates two opportunities, one without
    * allocations and one with an allocation. Runs batch class. Verifies two default allocations are created;
    * one for the total amount, and one for the unallocated remainder.
    ********************************************************************************************************/
    static testMethod void testMakeDefaultAllocations() {
        General_Accounting_Unit__c defaultGau = new General_Accounting_Unit__c(Name='General');
        insert defaultGau;

        General_Accounting_Unit__c otherGau = new General_Accounting_Unit__c(Name='Other');
        insert otherGau;

        setupSettings(new Allocations_Settings__c(Default_Allocations_Enabled__c = true, Default__c = defaultGau.Id));

        // disable the allocations trigger to prevent allocations from being created at all
        TDTM_ProcessControl.toggleTriggerState('Opportunity', 'ALLO_Allocations_TDTM', false);

        Account acc = new Account(Name='foo');
        insert acc;
        Opportunity opp1 = new Opportunity(Name='foo', Amount = 8, AccountID=acc.Id, CloseDate=System.today(), StageName=UTIL_UnitTestData_TEST.getClosedWonStage());
        Opportunity opp2 = new Opportunity(Name='foo2', Amount = 8, AccountID=acc.Id, CloseDate=System.today(), StageName=UTIL_UnitTestData_TEST.getClosedWonStage());
        insert opp1;
        insert opp2;

        list<Allocation__c>  queryAllo = getAllocationsOrderByAmount();
        System.assertEquals(0,queryAllo.size(), 'No default allocation should be created.');

        Allocation__c nonDefaultAllo = createOppAllocation(otherGau.Id, opp1.Id, 4, null);
        insert nonDefaultAllo;

        Test.startTest();
        id batchProcessId = database.executeBatch(new ALLO_MakeDefaultAllocations_BATCH());
        Test.stopTest();

        queryAllo = [SELECT Id, Amount__c, Percent__c, General_Accounting_Unit__c FROM Allocation__c WHERE Opportunity__c = :opp1.Id AND General_Accounting_Unit__c = :defaultGau.Id];
        System.assertEquals(1,queryAllo.size(), 'A default allocation should be created.');
        System.assertEquals(4, queryAllo[0].Amount__c, 'The default allocation should be of the unallocated amount of the Opportunity.');

        queryAllo = getAllocationsOrderByAmount(opp2.Id);
        System.assertEquals(1,queryAllo.size(), 'A default allocation should be created.');
        System.assertEquals(8, queryAllo[0].Amount__c, 'The default allocation should be of the total amount of the Opportunity.');
    }

    /*******************************************************************************************************
    * @description Tests that the default Allocation is created with a zero amount when default
    * Allocations are created and the Opportunity Amount is 0 via ALLO_ALLOCATION_TDTM trigger
    ********************************************************************************************************/
    @isTest
    private static void defaultAllocationsForZeroAmountOpportunityShouldRemainOnCreate() {
        General_Accounting_Unit__c defaultGau = new General_Accounting_Unit__c(Name='General');
        insert defaultGau;

        General_Accounting_Unit__c otherGau = new General_Accounting_Unit__c(Name='Other');
        insert otherGau;

        setupSettings(new Allocations_Settings__c(Default_Allocations_Enabled__c = true, Default__c = defaultGau.Id));

        List<Account> accs = UTIL_UnitTestData_TEST.createMultipleTestAccounts(1, null);

        insert accs;

        List<Opportunity> opps = UTIL_UnitTestData_TEST.oppsForAccountList(accs, null, UTIL_UnitTestData_TEST.getClosedWonStage(), System.today(), 0, null, null);

        Test.startTest();

        insert opps;

        Test.stopTest();

        list<Allocation__c>  allos = getAllocationsOrderByAmount();
        System.assertEquals(1, allos.size(), 'One allocation should be present.');
        System.assertEquals(0, allos[0].Amount__c, 'Allocation Amount');
        System.assertEquals(defaultGau.Id, allos[0].General_Accounting_Unit__c, 'Allocation should be for the default');
        System.assertEquals(opps[0].Id, allos[0].Opportunity__c, 'Opportunity');
    }

    /*******************************************************************************************************
    * @description Tests that $0 Allocations (Percentage based and fixed Amount) can be added for a $0
    * Opportunity
    ********************************************************************************************************/
    @isTest
    private static void createZeroAmountAllocationsForZeroAmountOpportunity() {
        List<General_Accounting_Unit__c> gaus = new List<General_Accounting_Unit__c>();

        General_Accounting_Unit__c defaultGau = new General_Accounting_Unit__c(Name='General');
        gaus.add(defaultGAU);
        General_Accounting_Unit__c gau1 = new General_Accounting_Unit__c(Name = 'GAU 1');
        gaus.add(gau1);
        General_Accounting_Unit__c gau2 = new General_Accounting_Unit__c(Name = 'GAU 2');
        gaus.add(gau2);
        General_Accounting_Unit__c gau3 = new General_Accounting_Unit__c(Name = 'GAU 3');
        gaus.add(gau3);

        insert gaus;

        setupSettings(new Allocations_Settings__c(Default_Allocations_Enabled__c = true, Default__c = defaultGau.Id));

        List<Account> accs = UTIL_UnitTestData_TEST.createMultipleTestAccounts(1, null);

        insert accs;

        List<Opportunity> opps = UTIL_UnitTestData_TEST.oppsForAccountList(accs, null, UTIL_UnitTestData_TEST.getClosedWonStage(), System.today(), 0, null, null);

        insert opps;

        Test.startTest();

        List<Allocation__c> newAllos = new List<Allocation__c>();

        // Percentaage Allocation for 50% to GAU 1
        newAllos.add(
            createOppAllocation(gau1.Id, opps[0].Id, null, 50)
        );

        // Fix Amount Allocation for $0 to GAU 2
        newAllos.add(
            createOppAllocation(gau2.Id, opps[0].Id, 0, null)
        );

        insert newAllos;

        Test.stopTest();

        List<Allocation__c> allos = getAllocationsOrderByPercent(opps[0].Id);
        System.assertEquals (2, allos.size(), '# of Allocations');
        System.assertEquals (gau1.Name, allos[1].General_Accounting_Unit__r.Name, 'Allocation 1 - GAU');
        System.assertEquals (0, allos[1].Amount__c, 'Allocation 1 - Amount');
        System.assertEquals (50, allos[1].Percent__c, 'Allocation 1 - Percent');
        System.assertEquals (gau2.Name, allos[0].General_Accounting_Unit__r.Name, 'Allocation 0 - GAU');
        System.assertEquals (0, allos[0].Amount__c, 'Allocation 0 - Amount');
        System.assertEquals (null, allos[0].Percent__c, 'Allocation 0 - Percent');
    }

    /*******************************************************************************************************
    * @description Tests that Allocations are updated and preserved when changing an Opportunity from a
    * non zero to a zero amount
    ********************************************************************************************************/
    @isTest
    private static void chamgeOpportunityAmountFromNonZeroToZero() {
        List<General_Accounting_Unit__c> gaus = new List<General_Accounting_Unit__c>();

        General_Accounting_Unit__c defaultGau = new General_Accounting_Unit__c(Name='General');
        gaus.add(defaultGAU);
        General_Accounting_Unit__c gau1 = new General_Accounting_Unit__c(Name = 'GAU 1');
        gaus.add(gau1);
        General_Accounting_Unit__c gau2 = new General_Accounting_Unit__c(Name = 'GAU 2');
        gaus.add(gau2);
        General_Accounting_Unit__c gau3 = new General_Accounting_Unit__c(Name = 'GAU 3');
        gaus.add(gau3);

        insert gaus;

        setupSettings(new Allocations_Settings__c(Default_Allocations_Enabled__c = true, Default__c = defaultGau.Id));

        List<Account> accs = UTIL_UnitTestData_TEST.createMultipleTestAccounts(1, null);

        insert accs;

        List<Opportunity> opps = UTIL_UnitTestData_TEST.oppsForAccountList(accs, null, UTIL_UnitTestData_TEST.getClosedWonStage(), System.today(), 10, null, null);

        insert opps;

        List<Allocation__c> newAllos = new List<Allocation__c>();

        // Percentaage Allocation for 50% to GAU 1
        newAllos.add(
            createOppAllocation(gau1.Id, opps[0].Id, null, 50)
        );

        // Fix Amount Allocation for $0 to GAU 2
        newAllos.add(
            createOppAllocation(gau2.Id, opps[0].Id, 0, null)
        );

        insert newAllos;

        Test.startTest();

        for (Opportunity opp : opps) {
            opp.Amount = 0;
        }

        update opps;

        Test.stopTest();

        List<Allocation__c> allos = getAllocationsOrderByPercent(opps[0].Id);
        System.assertEquals (2, allos.size(), '# of Allocations');
        System.assertEquals (gau1.Name, allos[1].General_Accounting_Unit__r.Name, 'Allocation 1 - GAU');
        System.assertEquals (0, allos[1].Amount__c, 'Allocation 1 - Amount');
        System.assertEquals (50, allos[1].Percent__c, 'Allocation 1 - Percent');
        System.assertEquals (gau2.Name, allos[0].General_Accounting_Unit__r.Name, 'Allocation 0 - GAU');
        System.assertEquals (0, allos[0].Amount__c, 'Allocation 0 - Amount');
        System.assertEquals (null, allos[0].Percent__c, 'Allocation 0 - Percent');
    }

    /**
    * @description Tests that Allocations are updated and preserved when changing a Payment from a
    * non zero to a zero amount, and that default allocation is removed
    */
    @isTest
    private static void changePaymentAmountFromNonZeroToZeroshouldResizePercentAllocations() {
        Map<String, Object> setupResults = setupPaymentAllocationTest(10);
        List<General_Accounting_Unit__c> gaus =
            (List<General_Accounting_Unit__c>) setupResults.get(GAUS_KEY);

        General_Accounting_Unit__c defaultGau =
            (General_Accounting_Unit__c) setupResults.get(DEFAULTGAU_KEY);

        List<Opportunity> opps =
            (List<Opportunity>) setupResults.get(OPPS_KEY);

        List<npe01__OppPayment__c> pmts =
            (List<npe01__OppPayment__c>) setupResults.get(PMTS_KEY);

        List<Allocation__c> newAllos = new List<Allocation__c>();

        // Percentaage Allocation for 50% to GAU 1
        newAllos.add(
            createPmtAllocation(gaus[1].Id, pmts[0].Id, null, 50)
        );

        // Fix Amount Allocation for $0 to GAU 2
        newAllos.add(
            createPmtAllocation(gaus[2].Id, pmts[0].Id, 0, null)
        );

        insert newAllos;

        Map<Id, Allocation__c> allosByGAU = getPaymentAllocationsByGAU(pmts[0].Id);

        System.assertEquals(3, allosByGAU.size(), '# of Allocations Before Pmt Amount Changes');

        Allocation__c defAlloc = allosByGAU.get(defaultGAU.Id);
        System.assertEquals (5, defAlloc.Amount__c, 'Default Allocation Amount');

        Test.startTest();

        for (npe01__OppPayment__c pmt : pmts) {
            pmt.npe01__Payment_Amount__c = 0;
        }

        update pmts;

        Test.stopTest();

        allosByGAU = getPaymentAllocationsByGAU(pmts[0].Id);

        System.assertEquals(2, allosByGAU.size(), '# of Allocations');

        Allocation__c alloc0 = allosByGAU.get(gaus[1].Id);
        Allocation__c alloc1 = allosByGAU.get(gaus[2].Id);

        System.assertEquals(0, alloc0.Amount__c, 'Allocation 0 Amount');
        System.assertEquals(50, alloc0.Percent__c, 'Allocation 0 Percent');
        System.assertEquals(0, alloc1.Amount__c, 'Allocation 1 Amount');
        System.assertEquals(null, alloc1.Percent__c, 'Allocation 1 Percent');
    }

    /**
     * @description Tests that Default Allocation is removed if Payment Amount changes from non zero to zero
     *              and only Default Allocation was present
     */
    @isTest
    private static void changePaymentAmountFromNonZeroToZeroshouldRemoveDefaultAllocation() {
        Map<String, Object> setupResults = setupPaymentAllocationTest(10.00);

        List<General_Accounting_Unit__c> gaus =
            (List<General_Accounting_Unit__c> ) setupResults.get('gaus');

        General_Accounting_Unit__c defaultGAU =
            (General_Accounting_Unit__c) setupResults.get(DEFAULTGAU_KEY);

        List<Opportunity> opps =
            (List<Opportunity>) setupResults.get(OPPS_KEY);

        List<npe01__OppPayment__c> pmts =
            (List<npe01__OppPayment__c>) setupResults.get(PMTS_KEY);

        Map<Id, Allocation__c> allosByGAU = getPaymentAllocationsByGAU(pmts[0].Id);

        System.assertEquals(1, allosByGAU.size(), '# of Allocations Before Pmt Amount Changes');

        Allocation__c defAlloc = allosByGAU.get(defaultGAU.Id);
        System.assertEquals (10, defAlloc.Amount__c, 'Default Allocation Amount');

        Test.startTest();

        for (npe01__OppPayment__c pmt : pmts) {
            pmt.npe01__Payment_Amount__c = 0;
        }

        update pmts;

        Test.stopTest();

        allosByGAU = getPaymentAllocationsByGAU(pmts[0].Id);

        System.assertEquals(0, allosByGAU.size(), '# of Allocations');
    }

    /**
     * @description Tests that the default Allocation is created with a zero amount when default
     * Allocations are created and the Payment Amount is 0 via ALLO_ALLOCATION_TDTM trigger
     */
    @isTest
    private static void defaultAllocationsForZeroAmountPaymentShouldRemainOnCreate() {
        Map<String, Object> setupResults = setupPaymentAllocationTest(0.00);

        General_Accounting_Unit__c defaultGau =
            (General_Accounting_Unit__c) setupResults.get(DEFAULTGAU_KEY);

        General_Accounting_Unit__c otherGau =
            ((List<General_Accounting_Unit__c>) setupResults.get(GAUS_KEY))[1];

        List<Opportunity> opps =
            (List<Opportunity>) setupResults.get(OPPS_KEY);

        List<npe01__OppPayment__c> pmts =
            (List<npe01__OppPayment__c>) setupResults.get(PMTS_KEY);

        list<Allocation__c>  allos = [SELECT    Id,
                                                Amount__c,
                                                General_Accounting_Unit__c,
                                                Payment__c
                                      FROM Allocation__c
                                      WHERE Payment__c = :pmts[0].Id];
        System.assertEquals(1, allos.size(), 'One allocation should be present.');
        System.assertEquals(0, allos[0].Amount__c, 'Allocation Amount');
        System.assertEquals(defaultGau.Id, allos[0].General_Accounting_Unit__c, 'Allocation should be for the default');
        System.assertEquals(pmts[0].Id, allos[0].Payment__c, 'Payment');
    }

    /*******************************************************************************************************
    * @description Tests that an error is generated if Opportunity Amount is 0 and a non zero fixed
    * Amount Allocation is added
    ********************************************************************************************************/
    @isTest
    private static void generateErrorForNonZeroFixedAmountAllocationIfOpportunityAmountIsZero() {
        List<General_Accounting_Unit__c> gaus = new List<General_Accounting_Unit__c>();

        General_Accounting_Unit__c defaultGau = new General_Accounting_Unit__c(Name='General');
        gaus.add(defaultGAU);
        General_Accounting_Unit__c gau1 = new General_Accounting_Unit__c(Name = 'GAU 1');
        gaus.add(gau1);
        General_Accounting_Unit__c gau2 = new General_Accounting_Unit__c(Name = 'GAU 2');
        gaus.add(gau2);
        General_Accounting_Unit__c gau3 = new General_Accounting_Unit__c(Name = 'GAU 3');
        gaus.add(gau3);

        insert gaus;

        setupSettings(new Allocations_Settings__c(Default_Allocations_Enabled__c = true, Default__c = defaultGau.Id));

        List<Account> accs = UTIL_UnitTestData_TEST.createMultipleTestAccounts(1, null);

        insert accs;

        List<Opportunity> opps = UTIL_UnitTestData_TEST.oppsForAccountList(accs, null, UTIL_UnitTestData_TEST.getClosedWonStage(), System.today(), 0, null, null);

        insert opps;

        Test.startTest();

        List<Allocation__c> newAllos = new List<Allocation__c>();

        // Percentaage Allocation for 50% to GAU 1
        newAllos.add(
            createOppAllocation(gau1.Id, opps[0].Id, null, 50)
        );

        // Fix Amount Allocation for $10 to GAU 2
        newAllos.add(
            createOppAllocation(gau2.Id, opps[0].Id, 10, null)
        );

        try{
            insert newAllos;
            System.assert(false, 'Expected an exception due to Opportunity being Overallocated.');
        } catch (Exception e) {
            System.assert(e.getMessage().contains(Label.alloTotalExceedsOppAmt), 'Expected Exception Text: ' + Label.alloTotalExceedsOppAmt + '; Actual: ' + e.getMessage());
        }

        Test.stopTest();
    }

    /*******************************************************************************************************
    * @description Tests that no error is generated if Opportunity Amount becomes 0 and a non zero fixed
    * Amount Allocation exists
    ********************************************************************************************************/
    @isTest
    private static void testFixupForNonZeroFixedAmountAllocationIfOpportunityAmountIsZero() {
        List<General_Accounting_Unit__c> gaus = new List<General_Accounting_Unit__c>();

        General_Accounting_Unit__c defaultGau = new General_Accounting_Unit__c(Name='General');
        gaus.add(defaultGAU);
        General_Accounting_Unit__c gau1 = new General_Accounting_Unit__c(Name = 'GAU 1');
        gaus.add(gau1);

        insert gaus;

        setupSettings(new Allocations_Settings__c(Default_Allocations_Enabled__c = true, Default__c = defaultGau.Id));

        List<Account> accs = UTIL_UnitTestData_TEST.createMultipleTestAccounts(1, null);

        insert accs;

        List<Opportunity> opps = UTIL_UnitTestData_TEST.oppsForAccountList(accs, null, UTIL_UnitTestData_TEST.getClosedWonStage(), System.today(), 10, null, null);

        insert opps;
        Opportunity opportunity = opps[0];

        Test.startTest();

        List<Allocation__c> newAllos = new List<Allocation__c>();

        // Fix Amount Allocation for $10 to GAU 1
        newAllos.add(
            createOppAllocation(gau1.Id, opportunity.Id, 10, null)
        );

        insert newAllos;

        try {
            opportunity.Amount = 5;
            update opportunity;
            System.assert(false, 'Expected an exception due to Opportunity being Overallocated.');
        } catch (Exception e) {
            System.assert(e.getMessage().contains(Label.alloExceedsOppAmount), 'Expected Exception Text: ' + Label.alloExceedsOppAmount + '; Actual: ' + e.getMessage());
        }

        opportunity.Amount = 0;
        update opportunity;
        Map<Id, Allocation__c> oppAllos = getOpportunityAllocationsByGAU(opportunity.Id);
        for(Id gauId : oppAllos.keySet()) {
            System.assertEquals(0, oppAllos.get(gauId).Amount__c, 'Allocaiton Amount should be 0');
        }

        Test.stopTest();
    }

    /**
     * @description Tests that an error is generated if Payment Amount is 0 and a non zero fixed
     * Amount Allocation is added
     */
    @isTest
    private static void generateErrorForNonZeroFixedAmountAllocationIfPaymentAmountIsZero() {
        Map<String, Object> setupResults = setupPaymentAllocationTest(20);
        List<General_Accounting_Unit__c> gaus =
            (List<General_Accounting_Unit__c>) setupResults.get(GAUS_KEY);

        General_Accounting_Unit__c defaultGau =
            (General_Accounting_Unit__c) setupResults.get(DEFAULTGAU_KEY);

        List<Opportunity> opps =
            (List<Opportunity>) setupResults.get(OPPS_KEY);

        List<npe01__OppPayment__c> pmts =
            (List<npe01__OppPayment__c>) setupResults.get(PMTS_KEY);

        Test.startTest();

        List<Allocation__c> newAllos = new List<Allocation__c>();

        // Percentaage Allocation for 50% to GAU 1
        newAllos.add(
            createPmtAllocation(gaus[1].Id, pmts[0].Id, null, 50)
        );

        // Fix Amount Allocation for $0 to GAU 2
        newAllos.add(
            createPmtAllocation(gaus[2].Id, pmts[0].Id, 10, null)
        );

        insert newAllos;

        for (npe01__OppPayment__c pmt :pmts) {
            pmt.npe01__Payment_Amount__c = 0;
        }

        try{
            update pmts;
            System.assert(false, 'Expected an exception due to Payment being Overallocated.');
        } catch (Exception e) {
            System.assert(e.getMessage().contains(Label.alloExceedsPmtAmount), 'Expected Exception Text: ' + Label.alloExceedsPmtAmount + '; Actual: ' + e.getMessage());
        }

        Test.stopTest();
    }

    // Helpers
    ////////////

    /**
     * @description Gets a List of Allocations associated with a particular Payment
     *              and builds a map by GAU of them.  Assumes only one allocation per
     *              Payment and GAU, since it is a test
     * @param  paymentId Payment Id to retrieve Allocations for
     * @return Allocations By GAU Id
     */
    private static Map<Id, Allocation__c> getPaymentAllocationsByGAU(Id paymentId) {
        List<Allocation__c> allocs = Database.query(getPaymentAllocationsQuery(paymentId).build());
        Map<Id, Allocation__c> allocsByGAU = new Map<Id, Allocation__c>();

        for (Allocation__c alloc : allocs) {
            allocsByGAU.put(alloc.General_Accounting_Unit__c, alloc);
        }
        return allocsByGAU;
    }

        /**
     * @description Gets a List of Allocations associated with a particular Opportunity
     *              and builds a map by GAU of them.  Assumes only one allocation per
     *              Opportunity and GAU, since it is a test
     * @param  opportunityId Opportunity Id to retrieve Allocations for
     * @return Allocations By GAU Id
     */
    private static Map<Id, Allocation__c> getOpportunityAllocationsByGAU(Id opportunityId) {
        List<Allocation__c> allocs = Database.query(getAllocationsQuery(opportunityId).build());
        Map<Id, Allocation__c> allocsByGAU = new Map<Id, Allocation__c>();

        for (Allocation__c alloc : allocs) {
            allocsByGAU.put(alloc.General_Accounting_Unit__c, alloc);
        }
        return allocsByGAU;
    }

    /*********************************************************************************************************
    * @description Get all Allocations ordered by Amount
    * @return List<Allocation__c> A list of all Allocations
    **********************************************************************************************************/
    private static List<Allocation__c> getAllocationsOrderByAmount() {
        return Database.query(getAllocationsQuery().build() + ' ORDER BY Amount__c');
    }

    /*********************************************************************************************************
    * @description Get all Allocations ordered by Percent
    * @return List<Allocation__c> A list of all Allocations
    **********************************************************************************************************/
    private static List<Allocation__c> getAllocationsOrderByPercent() {
        return Database.query(getAllocationsQuery().build() + ' ORDER BY Percent__c');
    }

    /*********************************************************************************************************
    * @description Get Allocations for the Opportunity ordered by Amount
    * @param oppId An Opportunity Id
    * @return List<Allocation__c> A list of Allocations assigned to the Opportunity
    **********************************************************************************************************/
    private static List<Allocation__c> getAllocationsOrderByAmount(Id oppId) {
        return Database.query(getAllocationsQuery(oppId).build() + ' ORDER BY Amount__c');
    }

    /*********************************************************************************************************
    * @description Get Allocations for the Opportunity ordered by Percent
    * @param oppId An Opportunity Id
    * @return List<Allocation__c> A list of Allocations assigned to the Opportunity
    **********************************************************************************************************/
    private static List<Allocation__c> getAllocationsOrderByPercent(Id oppId) {
        return Database.query(getAllocationsQuery(oppId).build() + ' ORDER BY Percent__c');
    }

    /*********************************************************************************************************
    * @description Get Allocations for the Payment and GAU ordered by Percent
    * @param paymentId A npe01__OppPayment__c Id
    * @param gauId A General_Accounting_Unit__c Id
    * @return List<Allocation__c> A list of Allocations assigned to the Opportunity
    **********************************************************************************************************/
    private static List<Allocation__c> getAllocationsOrderByPercent(Id paymentId, Id gauId) {
        return Database.query(getAllocationsQuery(paymentId, gauId).build() + ' ORDER BY Percent__c');
    }

    /*********************************************************************************************************
    * @description Build query to retrieve Allocations for the Opportunity
    * @param oppId An Opportunity Id
    * @return UTIL_Query Allocation SOQL
    **********************************************************************************************************/
    private static UTIL_Query getAllocationsQuery(Id oppId) {
        return getAllocationsQuery()
            .withWhere(String.format('Opportunity__c = \'\'{0}\'\'', new String[] { oppId }));
    }

    /**
     * @description Build query to retrieve Allocation by payment Id
     * @param paymentId A npe01__OppPayment__c Id
     * @return UTIL_Query Allocation SOQL
     */
    private static UTIL_Query getPaymentAllocationsQuery(Id paymentId) {
        return getAllocationsQuery()
            .withWhere(String.format('Payment__c = \'\'{0}\'\'', new String[] { paymentId }));
    }

    /*********************************************************************************************************
    * @description Build query to retrieve Allocation by payment Id and GAU
    * @param paymentId A npe01__OppPayment__c Id
    * @param gauId A General_Accounting_Unit__c Id
    * @return UTIL_Query Allocation SOQL
    **********************************************************************************************************/
    private static UTIL_Query getAllocationsQuery(Id paymentId, Id gauId) {
        return getAllocationsQuery()
            .withWhere(String.format('Payment__c = \'\'{0}\'\'', new String[] { paymentId }))
            .withWhere(String.format('General_Accounting_Unit__c = \'\'{0}\'\'', new String[] { gauId }));
    }



    /*********************************************************************************************************
    * @description Build query to retrieve all Allocations
    * @return UTIL_Query Allocation SOQL
    **********************************************************************************************************/
    private static UTIL_Query getAllocationsQuery() {
        return new UTIL_Query()
            .withSelectFields(new String[]{
                'Opportunity__c',
                'Payment__c',
                'General_Accounting_Unit__c',
                'General_Accounting_Unit__r.Name',
                'Amount__c',
                'Percent__c',
                'CreatedDate',
                'LastModifiedDate'
            })
            .withFrom('Allocation__c');
    }



    /*********************************************************************************************************
    * @description Return a new opportunity allocation with the provided parameters
    * @param gauId A General_Accounting_Unit__c Id
    * @param oppId An Opportunity Id
    * @param amt An Allocation amount
    * @param percent An Allocation percent
    * @return Allocation__c Allocation record with provided parameters filled in
    **********************************************************************************************************/
    private static Allocation__c createOppAllocation(Id gauId, Id oppId, Decimal amt, Double percent) {
        return new Allocation__c(
            Opportunity__c = oppId,
            General_Accounting_Unit__c = gauId,
            Percent__c = percent,
            Amount__c = amt
        );
    }

    /**
     * @description Return a new payment allocation with the provided parameters
     * @param gauId A General_Accounting_Unit__c Id
     * @param pmtId A Payment Id
     * @param amt An Allocation amount
     * @param percent An Allocation percent
     * @return Allocation__c Allocation record with provided parameters filled in
     */
    private static Allocation__c createPmtAllocation(Id gauId, Id pmtId, Decimal amt, Double percent) {
        return new Allocation__c(
            Payment__c = pmtId,
            General_Accounting_Unit__c = gauId,
            Percent__c = percent,
            Amount__c = amt
        );
    }

    /**
     * @description Setups Payment Allocation Test Configuration and Some Sample Data
     *              Stores List of GAUs created
     *              Stores defaultGAU
     *              Stores opportunities created
     *              Stores payments created
     * @return Map<String, Object> Map of created records useful in tests
     */
    private static Map<String, Object> setupPaymentAllocationTest(Decimal paymentAmount) {
        Map<String, Object> setupResults = new Map<String, Object>();

        List<General_Accounting_Unit__c> gaus = UTIL_UnitTestData_TEST.createGAUs(4);
        insert gaus;

        setupResults.put(GAUS_KEY, gaus);

        setupSettings(new Allocations_Settings__c(
            Default_Allocations_Enabled__c = true,
            Default__c = gaus[0].Id,
            Payment_Allocations_Enabled__c = true
        ));

        setupResults.put(DEFAULTGAU_KEY, gaus[0]);

        List<Account> accs = UTIL_UnitTestData_TEST.createMultipleTestAccounts(1, null);
        insert accs;

        List<Opportunity> opps = UTIL_UnitTestData_TEST.oppsForAccountList(accs, null, UTIL_UnitTestData_TEST.getClosedWonStage(), System.today(), 10, null, null);

        insert opps;
        setupResults.put(OPPS_KEY, opps);

        List<npe01__OppPayment__c> pmts = new List<npe01__OppPayment__c>();

        for (Opportunity opp :opps) {
            pmts.add(
                new npe01__OppPayment__c(
                    npe01__Opportunity__c = opp.Id,
                    npe01__Payment_Amount__c = paymentAmount,
                    npe01__Scheduled_Date__c = System.today()
                )
            );
        }
        insert pmts;
        setupResults.put(PMTS_KEY, pmts);
        return setupResults;
    }
}