/*
    Copyright (c) 2019, Salesforce.org
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
* @date 2019
* @group Allocations
* @group-content ../../ApexDocContent/Allocations.htm
* @description Tests specific to Allocations trigger based functionality.
*/
@isTest
private with sharing  class ALLO_PaymentSync_TEST {

    static General_Accounting_Unit__c defaultGau;
    static List<General_Accounting_Unit__c> gaus = new List<General_Accounting_Unit__c>();

    static Opportunity opportunity;
    static List<npe01__OppPayment__c> payments = new List<npe01__OppPayment__c>();

    @testSetup
    static void setup() {
        General_Accounting_Unit__c gau = new General_Accounting_Unit__c(Name='Default GAU');
        insert gau;

        Account account = new Account(Name='Account');
        insert account;

        Opportunity opportunity = new Opportunity(
            Name = 'Opp',
            Amount = 1000,
            AccountID = account.Id,
            CloseDate = System.today(),
            StageName = UTIL_UnitTestData_TEST.getClosedWonStage(),
            npe01__Do_Not_Automatically_Create_Payment__c = true
        );
        insert opportunity;

    }

    /*******************************************************************************************************
    * @description When changing the amount of a Payment with Allocations:
    * Increasing the amount will adjust the percentage allocations.
    * Decreasing the amount so that the total allocation amount is below the payment amount will adjust
    * the percentage allocations.
    * Decreasing the amount so that the total allocation amount is greater than the payment amount, an
    * error is thrown and the payment update is blocked.
    ********************************************************************************************************/
    @isTest
    static void syncPaymentToOpportunity() {
        setupForTests();
        makePayments(1000, 1);
        makeGAUs(2);

        System.assert(UTIL_CustomSettingsFacade.getAllocationsSettings().Payment_Allocations_Enabled__c, UTIL_CustomSettingsFacade.getAllocationsSettings());

        //resetting these manually as a test is considered a single context for static variables
        List<Allocation__c> alloForInsert = new List<Allocation__c>();

        alloForInsert.add(new Allocation__c(Payment__c=payments[0].Id, Percent__c = 50, General_Accounting_Unit__c = gaus[0].Id));
        alloForInsert.add(new Allocation__c(Payment__c=payments[0].Id, Amount__c = 300, General_Accounting_Unit__c = gaus[1].Id));
        insert alloForInsert;

        List<Allocation__c> queryAllocations = getAllocationsOrderByAmount();
        System.assertEquals(6, queryAllocations.size(), 'Six opportunity allocations should exist.');
        //synced opportunity allocations
        assertAllocation(queryAllocations[0], 200, defaultGau.Id, true);
        assertAllocation(queryAllocations[1], 300, gaus[1].Id, true);
        assertAllocation(queryAllocations[2], 500, gaus[0].Id, true);
        //original payment allocations
        assertAllocation(queryAllocations[3], 200, defaultGau.Id, false);
        assertAllocation(queryAllocations[4], 300, gaus[1].Id, false);
        assertAllocation(queryAllocations[5], 500, gaus[0].Id, false);
    }

    /*******************************************************************************************************
    * @description When changing the Allocation amount of an Opportunity with Payments:
    * Increasing the amount will adjust the percentage allocations.
    * Decreasing the amount so that the total allocation amount is below the payment amount will adjust
    * the percentage allocations.
    * Decreasing the amount so that the total allocation amount is greater than the payment amount, an
    * error is thrown and the payment update is blocked.
    ********************************************************************************************************/
    @isTest
    static void syncOpportunityToPayment() {
        setupForTests();
        makePayments(1000, 1);
        makeGAUs(2);

        List<Allocation__c> alloForInsert = new List<Allocation__c>();

        alloForInsert.add(new Allocation__c(Opportunity__c=opportunity.Id, Percent__c = 50, General_Accounting_Unit__c = gaus[0].Id));
        alloForInsert.add(new Allocation__c(Opportunity__c=opportunity.Id, Amount__c = 300, General_Accounting_Unit__c = gaus[1].Id));
        insert alloForInsert;

        List<Allocation__c> queryAllocations = getAllocationsOrderByAmount();
        System.assertEquals(6, queryAllocations.size(), 'Six allocations should exist.');
        //original opportunity allocations
        assertAllocation(queryAllocations[0], 200, defaultGau.Id, true);
        assertAllocation(queryAllocations[1], 300, gaus[1].Id, true);
        assertAllocation(queryAllocations[2], 500, gaus[0].Id, true);
        //synced payment allocations
        assertAllocation(queryAllocations[3], 200, defaultGau.Id, false);
        assertAllocation(queryAllocations[4], 300, gaus[1].Id, false);
        assertAllocation(queryAllocations[5], 500, gaus[0].Id, false);
    }

    /*******************************************************************************************************
    * @description When changing the Allocation amount of an Opportunity with overscheduled Payments:
    * (i.e. the sum of unpaid and paid payments exceeds the opportunity amount)
    * Increasing the amount will adjust the percentage allocations.
    * Decreasing the amount so that the total allocation amount is below the payment amount will adjust
    * the percentage allocations.
    * Decreasing the amount so that the total allocation amount is greater than the payment amount, an
    * error is thrown and the payment update is blocked.
    ********************************************************************************************************/
    @isTest
    static void syncOpportunityToOverscheduledPayments() {
        setupForTests();
        makePayments(1100, 2);
        makeGAUs(2);

        List<Allocation__c> alloForInsert = new List<Allocation__c>();

        alloForInsert.add(new Allocation__c(Opportunity__c=opportunity.Id, Percent__c = 10, General_Accounting_Unit__c = gaus[0].Id));
        alloForInsert.add(new Allocation__c(Opportunity__c=opportunity.Id, Percent__c = 20, General_Accounting_Unit__c = gaus[1].Id));
        insert alloForInsert;

        List<Allocation__c> queryAllocations = getAllocationsOrderByAmount();
        System.assertEquals(9, queryAllocations.size(), 'Nine allocations should exist.');

        //original opportunity allocations
        assertAllocation(queryAllocations[0], 100, gaus[0].Id, true);
        assertAllocation(queryAllocations[1], 200, gaus[1].Id, true);
        assertAllocation(queryAllocations[2], 700, defaultGau.Id, true);
        //synced payment allocations
        assertAllocation(queryAllocations[3], 55, gaus[0].Id, false);
        assertAllocation(queryAllocations[4], 55, gaus[0].Id, false);
        assertAllocation(queryAllocations[5], 110, gaus[1].Id, false);
        assertAllocation(queryAllocations[6], 110, gaus[1].Id, false);
        assertAllocation(queryAllocations[7], 385, defaultGau.Id, false);
        assertAllocation(queryAllocations[8], 385, defaultGau.Id, false);

        alloForInsert[1].Percent__c = 30;
        update alloForInsert[1];

        queryAllocations = getAllocationsOrderByAmount();
        System.assertEquals(9, queryAllocations.size(), 'Nine allocations should still exist.');

        //original opportunity allocations
        assertAllocation(queryAllocations[0], 100, gaus[0].Id, true);
        assertAllocation(queryAllocations[1], 300, gaus[1].Id, true);
        assertAllocation(queryAllocations[2], 600, defaultGau.Id, true);
        //synced payment allocations
        assertAllocation(queryAllocations[3], 55, gaus[0].Id, false);
        assertAllocation(queryAllocations[4], 55, gaus[0].Id, false);
        assertAllocation(queryAllocations[5], 165, gaus[1].Id, false);
        assertAllocation(queryAllocations[6], 165, gaus[1].Id, false);
        assertAllocation(queryAllocations[7], 330, defaultGau.Id, false);
        assertAllocation(queryAllocations[8], 330, defaultGau.Id, false);
    }

    /*******************************************************************************************************
    * @description When changing the Allocation amount of an Opportunity with Payments:
    * Increasing the amount will adjust the percentage allocations.
    * Decreasing the amount so that the total allocation amount is below the payment amount will adjust
    * the percentage allocations.
    * Decreasing the amount so that the total allocation amount is greater than the payment amount, an
    * error is thrown and the payment update is blocked.
    ********************************************************************************************************/
    @isTest
    static void syncOpportunityToPaymentsWithWriteoffs() {
        setupForTests();
        makePayments(1000, 2);
        makeGAUs(2);

        List<Allocation__c> alloForInsert = new List<Allocation__c>();

        alloForInsert.add(new Allocation__c(Opportunity__c=opportunity.Id, Amount__c = 500, General_Accounting_Unit__c = gaus[0].Id));
        alloForInsert.add(new Allocation__c(Opportunity__c=opportunity.Id, Amount__c = 300, General_Accounting_Unit__c = gaus[1].Id));
        insert alloForInsert;

        List<Allocation__c> queryAllocations = getAllocationsOrderByAmount();
        System.assertEquals(9, queryAllocations.size(), 'Nine allocations should exist.');
        //original opportunity allocations
        assertAllocation(queryAllocations[0], 200, defaultGau.Id, true);
        assertAllocation(queryAllocations[1], 300, gaus[1].Id, true);
        assertAllocation(queryAllocations[2], 500, gaus[0].Id, true);
        //synced payment allocations
        assertAllocation(queryAllocations[3], 100, defaultGau.Id, false);
        assertAllocation(queryAllocations[4], 100, defaultGau.Id, false);
        assertAllocation(queryAllocations[5], 150, gaus[1].Id, false);
        assertAllocation(queryAllocations[6], 150, gaus[1].Id, false);
        assertAllocation(queryAllocations[7], 250, gaus[0].Id, false);
        assertAllocation(queryAllocations[8], 250, gaus[0].Id, false);

        payments[0].npe01__Paid__c = true;
        update payments[0];

        alloForInsert[0].Amount__c = 250;
    }

    /*******************************************************************************************************
    * @description When changing the amount of a Written off Payment with Allocations:
    * Changes to the payment values will not change the opportunity allocations
    ********************************************************************************************************/
    @isTest
    static void doNotSyncWrittenOffPaymentToOpportunity() {
        setupForTests();
        makePayments(1000, 1);
        for(npe01__OppPayment__c payment: payments) {
            payment.npe01__Written_Off__c = true;
        }
        update payments;
        makeGAUs(2);

        System.assert(UTIL_CustomSettingsFacade.getAllocationsSettings().Payment_Allocations_Enabled__c,
            UTIL_CustomSettingsFacade.getAllocationsSettings());

        //resetting these manually as a test is considered a single context for static variables
        List<Allocation__c> alloForInsert = new List<Allocation__c>();

        alloForInsert.add(new Allocation__c(Payment__c=payments[0].Id, Percent__c = 50, General_Accounting_Unit__c = gaus[0].Id));
        alloForInsert.add(new Allocation__c(Payment__c=payments[0].Id, Amount__c = 300, General_Accounting_Unit__c = gaus[1].Id));
        insert alloForInsert;

        // The default allocation will not go away or shrink because it stops being updated once it is marked "Written Off"
        List<Allocation__c> queryAllocations = getAllocationsOrderByAmount();
        System.assertEquals(3, queryAllocations.size(), 'Three allocations should exist.');

        // no allocations should have been created for opportunity
        System.assertEquals(null, queryAllocations[0].Opportunity__c, 'Only Payment allocations should have been created');
        System.assertEquals(null, queryAllocations[1].Opportunity__c, 'Only Payment allocations should have been created');
        System.assertEquals(null, queryAllocations[2].Opportunity__c, 'Only Payment allocations should have been created');

        //original payment allocations
        assertAllocation(queryAllocations[1], 300, gaus[1].Id, false);
        assertAllocation(queryAllocations[2], 500, gaus[0].Id, false);
    }

    /*******************************************************************************************************
    * @description When changing the amount of Opportunity allocations connected to paid payments
    * Payment Allocations for paid payments will not be changed
    ********************************************************************************************************/
    @isTest
    static void doNotUpdatePaidPaymentsWithOpportunityChanges() {
        setupForTests();
        makePayments(1000, 1);
        makeGAUs(2);

        // mark payments as paid
        for(npe01__OppPayment__c payment: payments) {
            payment.npe01__Paid__c = true;
        }
        update payments;

        System.assert(UTIL_CustomSettingsFacade.getAllocationsSettings().Payment_Allocations_Enabled__c,
            UTIL_CustomSettingsFacade.getAllocationsSettings());

        List<Allocation__c> queryAllocations = getAllocationsOrderByAmount();
        System.assertEquals(1, queryAllocations.size(), 'One allocation should exist.');
        assertAllocation(queryAllocations[0], 1000, defaultGau.Id, false);

        Decimal origAllocAmount = queryAllocations[0].Amount__c;
        Decimal origAllocPercent = queryAllocations[0].Percent__c;

        //resetting these manually as a test is considered a single context for static variables
        List<Allocation__c> alloForInsert = new List<Allocation__c>();

        alloForInsert.add(new Allocation__c(Opportunity__c=opportunity.Id, Percent__c = 50, General_Accounting_Unit__c = gaus[0].Id));
        alloForInsert.add(new Allocation__c(Opportunity__c=opportunity.Id, Amount__c = 300, General_Accounting_Unit__c = gaus[1].Id));
        insert alloForInsert;

        queryAllocations = getAllocationsOrderByAmount();

        System.assertEquals(4, queryAllocations.size(), 'Four allocations should exist.');

        //original payment allocations
        assertAllocation(queryAllocations[0], 200, defaultGau.Id, true);
        assertAllocation(queryAllocations[1], 300, gaus[1].Id, true);
        assertAllocation(queryAllocations[2], 500, gaus[0].Id, true);
        assertAllocation(queryAllocations[3], origAllocAmount, defaultGau.Id, false);
    }

    /*******************************************************************************************************
    * @description When attempting to lower or delete an opp allocation for a GAU that has paid payment allocations:
    * Changes to Opportunity allocations will be blocked by error
    ********************************************************************************************************/
    @isTest
    static void doNotAllowLowerOrDeleteOfOpportunityAllocationWithPaidPayments() {
        setupForTests();
        makePayments(1000, 1);
        makeGAUs(2);

        List<Allocation__c> alloForInsert = new List<Allocation__c>();

        alloForInsert.add(new Allocation__c(Opportunity__c=opportunity.Id, Percent__c = 50, General_Accounting_Unit__c = gaus[0].Id));
        alloForInsert.add(new Allocation__c(Opportunity__c=opportunity.Id, Amount__c = 300, General_Accounting_Unit__c = gaus[1].Id));
        insert alloForInsert;

        List<Allocation__c> queryAllocations = getAllocationsOrderByAmount();
        System.assertEquals(6, queryAllocations.size(), 'Six allocations should exist.');
        //original opportunity allocations
        assertAllocation(queryAllocations[0], 200, defaultGau.Id, true);
        assertAllocation(queryAllocations[1], 300, gaus[1].Id, true);
        assertAllocation(queryAllocations[2], 500, gaus[0].Id, true);
        //synced payment allocations
        assertAllocation(queryAllocations[3], 200, defaultGau.Id, false);
        assertAllocation(queryAllocations[4], 300, gaus[1].Id, false);
        assertAllocation(queryAllocations[5], 500, gaus[0].Id, false);

        // mark payments as paid
        for(npe01__OppPayment__c payment: payments) {
            payment.npe01__Paid__c = true;
        }
        update payments;

        String errMessage = '';
        try {
            delete queryAllocations[1];
        } catch (Exception e) {
            errMessage = e.getMessage();
        }

        String labelMsg = String.format(System.Label.alloRemoveOppWithPmt, new String[] {opportunity.Name, opportunity.Id, queryAllocations[1].Name, queryAllocations[1].Id});
        System.assert(errMessage.contains(labelMsg),
            'Failure message should contain ' + labelMsg);

        errMessage = '';

        try {
            Allocation__c allocationToUpdate = queryAllocations[1];
            allocationToUpdate.General_Accounting_Unit__c = gaus[0].Id;
            update allocationToUpdate;
        } catch (Exception e) {
            errMessage = e.getMessage();
        }

        labelMsg = String.format(System.Label.alloRemoveOppWithPmt, new String[] {opportunity.Name, opportunity.Id, queryAllocations[1].Name, queryAllocations[1].Id});
        System.assert(errMessage.contains(labelMsg),
                'Failure message should contain ' + labelMsg);

        errMessage = '';
        try {
            queryAllocations[2].Amount__c = 200;
            queryAllocations[2].Percent__c = 20.0;
            update queryAllocations[2];
        } catch (Exception e) {
            errMessage = e.getMessage();
        }

        labelMsg = String.format(System.Label.alloPaidPmtsExceedsOpp, new String[] {opportunity.Name, opportunity.Id, queryAllocations[2].Name, queryAllocations[2].Id});

        System.Assert(errMessage.contains(labelMsg),
            'Failure message should contain ' + labelMsg);
    }

    /*******************************************************************************************************
    * @description Updating paid Payment Allocations updates Opportunity Allocations
    ********************************************************************************************************/
    @isTest
    private static void validateUpdatingPmtAllocUpdatesOppAllocs() {
        setupForTests();
        makePayments(1000, 1);
        makeGAUs(2);

        List<Allocation__c> alloForInsert = new List<Allocation__c>();

        alloForInsert.add(new Allocation__c(Opportunity__c=opportunity.Id, Amount__c = 500, General_Accounting_Unit__c = gaus[0].Id));
        alloForInsert.add(new Allocation__c(Opportunity__c=opportunity.Id, Amount__c = 300, General_Accounting_Unit__c = gaus[1].Id));
        insert alloForInsert;

        List<Allocation__c> allocations = getAllocationsOrderByAmount();
        System.assertEquals(6, allocations.size(), '6 allocations should exist.');

        List<Allocation__c> pmtAllocs = new List<Allocation__c>();

        for (Allocation__c alloc : allocations) {
            if (alloc.Payment__c != null) {
                pmtAllocs.add(alloc);
            }
        }

        pmtAllocs[1].Amount__c= 350;
        pmtAllocs[1].Percent__c = 35;
        pmtAllocs[2].Amount__c = 450;
        pmtAllocs[2].Percent__c = 45;

        update pmtAllocs;

        allocations = getAllocationsOrderByAmount();

        assertAllocation(allocations[0], 200, defaultGau.Id, true);
        assertAllocation(allocations[1], 350, gaus[1].Id, true);
        assertAllocation(allocations[2], 450, gaus[0].Id, true);

}

    /*******************************************************************************************************
    * @description Validate null and zero amount Opportunities have proper allocations
    ********************************************************************************************************/
     @isTest
    private static void validateNullAndZeroAmountsForOpps() {
        setupForTests();

        Account acct = [select  Id
                        from Account];

        List<Opportunity> opps = new List<Opportunity>();

        Opportunity opp = new Opportunity(
            Name = 'Opp',
            Amount = 0,
            AccountID = acct.Id,
            CloseDate = System.today(),
            StageName = UTIL_UnitTestData_TEST.getClosedWonStage(),
            npe01__Do_Not_Automatically_Create_Payment__c = false
        );

        opps.add (opp);
        Opportunity opp2 = new Opportunity(
            Name = 'Opp2',
            Amount = null,
            AccountID = acct.Id,
            CloseDate = System.today(),
            StageName = UTIL_UnitTestData_TEST.getClosedWonStage(),
            npe01__Do_Not_Automatically_Create_Payment__c = false
        );
        opps.add(opp2);

        insert opps;

        Set<Id> oppIds = new Set<Id>();
        for (Opportunity anOpp : opps) {
            oppIds.add(anOpp.id);
        }

        List<Allocation__c> allocs = [select    Id,
                                                Opportunity__c,
                                                Payment__c,
                                                General_Accounting_Unit__c,
                                                General_Accounting_Unit__r.Name,
                                                Amount__c,
                                                Percent__c
                                        from Allocation__c
                                        where Opportunity__c in :oppIds
        ];

        System.assertEquals(1, allocs.size(), 'One allocation should be present.');

        for (Allocation__c alloc : allocs) {
            assertAllocation(alloc, 0, defaultGau.Id, true);
            System.assertEquals (opp.Id, alloc.Opportunity__c, 'Allocation Opportunity');
        }

        for (Integer i = 0; i < opps.size(); i++) {
            opps[i].Amount = 1000;
        }
        update opps;

        allocs = [select    Id,
                            Opportunity__c,
                            Payment__c,
                            General_Accounting_Unit__c,
                            General_Accounting_Unit__r.Name,
                            Amount__c,
                            Percent__c
                  from Allocation__c
                  where Opportunity__c in :oppIds
        ];

        System.assertEquals (2, allocs.size(), 'Default Allocs for Opportunity should now be present.');

        //TODO: Restore this part of the test once the modifications for Payment Allocations, in terms of $0 Payments Amounts is corrected so the Default Allocation will still be present for $0 Amounts (if no other allocations are present)
        /*
        opps[0].Amount = 0;
        opps[1].Amount = null;
        update opps;

        allocs = [select    Id,
                            Opportunity__c,
                            Payment__c,
                            General_Accounting_Unit__c,
                            General_Accounting_Unit__r.Name,
                            Amount__c,
                            Percent__c
                  from Allocation__c
                  where Opportunity__c in :oppIds
        ];

        System.assertEquals(1, allocs.size(), 'One allocation should be present');

        for (Allocation__c alloc : allocs) {
            assertAllocation(alloc, 0, defaultGau.Id, true);
            System.assertEquals (opp.Id, alloc.Opportunity__c, 'Allocation Opportunity');
        }
        */
    }

    /*******************************************************************************************************
    * @description Validate null and zero amount payments have proper payment allocations
    * Should test insertion, as well as updates to and from null and negative values
    ********************************************************************************************************/
    @isTest
    private static void validateNullAndZeroAmountsForPayments() {
        setupForTests();
        makePayments(1000, 1);
        makeGAUs(2);

        List<Allocation__c> alloForInsert = new List<Allocation__c>();

        alloForInsert.add(new Allocation__c(Opportunity__c=opportunity.Id, Amount__c = 500, General_Accounting_Unit__c = gaus[0].Id));
        alloForInsert.add(new Allocation__c(Opportunity__c=opportunity.Id, Amount__c = 300, General_Accounting_Unit__c = gaus[1].Id));
        insert alloForInsert;

        List<Allocation__c> allocations = getAllocationsOrderByAmount();
        System.assertEquals(6, allocations.size(), '6 allocations should exist.');

        npe01__OppPayment__c payment = [select Id, npe01__Payment_Amount__c from npe01__OppPayment__c where npe01__Opportunity__c = :opportunity.Id];

        payment.npe01__Payment_Amount__c = null;
        update payment;
        allocations = [select Id from Allocation__c where Payment__c=:payment.Id];
        System.assertEquals (0, allocations.size(), 'No payment allocations should exist');

        payment.npe01__Payment_Amount__c = 1000;
        update payment;
        allocations = [select Id from Allocation__c where Payment__c=:payment.Id];
        System.assertEquals (3, allocations.size(), 'Three payment allocations should exist');
    }

    /*******************************************************************************************************
    * @description Validate Payments with negative amounts inserted, or updated to negative
    * amount creates the proper allocations
    ********************************************************************************************************/
    @isTest
    private static void validateNegativePaymentAmounts() {
        setupForTests();
        makeGAUs(2);

        List<Allocation__c> alloForInsert = new List<Allocation__c>();
        opportunity = [SELECT Id, Name, Amount FROM Opportunity LIMIT 1];

        alloForInsert.add(new Allocation__c(Opportunity__c=opportunity.Id, Amount__c = 500, General_Accounting_Unit__c = gaus[0].Id));
        alloForInsert.add(new Allocation__c(Opportunity__c=opportunity.Id, Amount__c = 300, General_Accounting_Unit__c = gaus[1].Id));
        insert alloForInsert;

        List<Allocation__c> allocations = getAllocationsOrderByAmount();

        makePayments(-1000, 1);

        npe01__OppPayment__c payment = [select Id, npe01__Payment_Amount__c from npe01__OppPayment__c where npe01__Opportunity__c = :opportunity.Id];

        allocations = [select   Id,
                                Opportunity__c,
                                Payment__c,
                                General_Accounting_Unit__c,
                                General_Accounting_Unit__r.Name,
                                Amount__c,
                                Percent__c
                       from Allocation__c
                       where Payment__c = :payment.Id
                       order by Amount__c DESC];

        System.assertEquals(3, allocations.size());
        System.assertEquals(-200, allocations[0].Amount__c, 'Allocation Amount for Default GAU');
        System.assertEquals(defaultGAU.Id, allocations[0].General_Accounting_Unit__c, 'Default GAU');
        System.assertEquals(-300, allocations[1].Amount__c, 'Allocation Amount for GAU 2');
        System.assertEquals(gaus[1].Id, allocations[1].General_Accounting_Unit__c, 'GAU 2');
        System.assertEquals(-500, allocations[2].Amount__c, 'Allocation Amount for GAU 1');
        System.assertEquals(gaus[0].Id, allocations[2].General_Accounting_Unit__c, 'GAU 1');

        // Confirm payment allocations for update to negative payment are correct
        payment.npe01__Payment_Amount__c = -100;
        update payment;

        allocations = [select   Id,
                                Opportunity__c,
                                Payment__c,
                                General_Accounting_Unit__c,
                                General_Accounting_Unit__r.Name,
                                Amount__c,
                                Percent__c
                       from Allocation__c
                       where Payment__c = :payment.Id
                       order by Amount__c DESC];

        System.assertEquals(3, allocations.size());

        System.assertEquals(-20, allocations[0].Amount__c, 'Allocation Amount for Default GAU');
        System.assertEquals(defaultGAU.Id, allocations[0].General_Accounting_Unit__c, 'Default GAU');
        System.assertEquals(-30, allocations[1].Amount__c, 'Allocation Amount for GAU 2');
        System.assertEquals(gaus[1].Id, allocations[1].General_Accounting_Unit__c, 'GAU 2');
        System.assertEquals(-50, allocations[2].Amount__c, 'Allocation Amount for GAU 1');
        System.assertEquals(gaus[0].Id, allocations[2].General_Accounting_Unit__c, 'GAU 1');
    }
    /*******************************************************************************************************
    * @description Prevent creating or modifying Opportunity and Payment Allocations for the same Opportunity
    * in the same transaction.
    ********************************************************************************************************/
    @isTest
    private static void validateOverlappingChanges() {
        setupForTests();
        makePayments(1000, 1);
        makeGAUs(2);

        List<Allocation__c> alloForInsert = new List<Allocation__c>();

        alloForInsert.add(new Allocation__c(Opportunity__c=opportunity.Id, Percent__c = 50, General_Accounting_Unit__c = gaus[0].Id));
        alloForInsert.add(new Allocation__c(Payment__c=payments[0].Id, Amount__c = 300, General_Accounting_Unit__c = gaus[1].Id));

        String error;
        try {
            insert alloForInsert;
        } catch (Exception ex) {
            error = ex.getMessage();
        }
        System.assert(error != null && error.contains(System.Label.alloPmtOppSingleTransaction),
            'Inserting or updating opportunity and payment allocations for the same opportunity failed to cause the expected exception.');
    }

    /*******************************************************************************************************
    * @description Test when an opportunity is over scheduled, has payment level allocations changed to the non default GAU,
    * then opportunity level allocations is increased. This validates that the payment allocation gets scaled properly
    * when over scheduled. Setting the opportunity allocation to an increased amount validates that the scaling happens properly when going
    * from the opportunity to the payment. Updating the opportunity level allocation should also overwrite the
    * payment level allocations.
    ********************************************************************************************************/
    @isTest
    private static void testAllocationAmountIncreasedOnOpportunityOverScheduled() {
        setupForTests();
        makePayments(5000, 10);
        makeGAUs(2);
        Id GAUId = gaus[1].Id;
        List<Allocation__c> alloForInsert = new List<Allocation__c>();

        alloForInsert.add(new Allocation__c(Payment__c=payments[0].Id, Percent__c = 50, General_Accounting_Unit__c = GAUId));

        insert alloForInsert;

        Allocation__c oppAllocation = [select Id,
                                Opportunity__c,
                                Payment__c,
                                General_Accounting_Unit__c,
                                General_Accounting_Unit__r.Name,
                                Amount__c,
                                Percent__c
                       from Allocation__c
                       where Opportunity__c = :opportunity.Id
                       AND General_Accounting_Unit__c =: GAUId
                       order by Amount__c DESC];

        System.assert(oppAllocation.Percent__c == 5, 'This is the opportunity allocation amount: ' + oppAllocation.percent__c);

        oppAllocation.Percent__c = 50;
        Test.startTest();
        update oppAllocation;

        Allocation__c paymentAllocation = [select Id,
                                Opportunity__c,
                                Payment__c,
                                General_Accounting_Unit__c,
                                General_Accounting_Unit__r.Name,
                                Amount__c,
                                Percent__c
                       from Allocation__c
                       where Payment__c = :payments[0].Id
                       AND General_Accounting_Unit__c =: GAUId
                       order by Amount__c DESC];

        System.assert(paymentAllocation.Percent__c == 50, 'The allocation percent is incorrect. It should be 50, but it is actually: ' + paymentAllocation);
        Test.stopTest();
    }

    /*******************************************************************************************************
    * @description Test when an opportunity is under scheduled, has payment level allocations changed to the non default GAU,
    * then the opportunity level allocations is increased. This validates that the allocations are properly scaled when under scheduled.
    * Setting the opportunity level allocation to an increased amount validates that it is properly scaled going
    * from the opportunity to the payment. Updating the opportunity level allocation should also overwrite the payment level allocations.
    ********************************************************************************************************/
    @isTest
    private static void testAllocationAmountIncreasedOnOpportunityUnderScheduled() {
        setupForTests();
        makePayments(600, 10);
        makeGAUs(2);
        Id GAUId = gaus[1].Id;
        List<Allocation__c> alloForInsert = new List<Allocation__c>();

        alloForInsert.add(new Allocation__c(Payment__c=payments[0].Id, Percent__c = 50, General_Accounting_Unit__c = GAUId));

        insert alloForInsert;

        Allocation__c oppAllocation = [select Id,
                                Opportunity__c,
                                Payment__c,
                                General_Accounting_Unit__c,
                                General_Accounting_Unit__r.Name,
                                Amount__c,
                                Percent__c
                       from Allocation__c
                       where Opportunity__c = :opportunity.Id
                       AND General_Accounting_Unit__c =: GAUId
                       order by Amount__c DESC];

        System.assert(oppAllocation.Percent__c == 5, 'This is the opportunity allocation amount: ' + oppAllocation.percent__c);

        oppAllocation.Percent__c = 50;

        Test.startTest();
        update oppAllocation;

        Allocation__c paymentAllocation = [select Id,
                                Opportunity__c,
                                Payment__c,
                                General_Accounting_Unit__c,
                                General_Accounting_Unit__r.Name,
                                Amount__c,
                                Percent__c
                       from Allocation__c
                       where Payment__c = :payments[0].Id
                       AND General_Accounting_Unit__c =: GAUId
                       order by Amount__c DESC];

        System.assert(paymentAllocation.Percent__c == 50, 'The allocation percent is incorrect. It should be 50, but it is actually: ' + paymentAllocation);
        Test.stopTest();
    }

    /*******************************************************************************************************
    * @description Test when an opportunity is under scheduled, has payment level allocations changed to the non default GAU,
    * then the opportunity level allocation is decreased. This validates that the allocations are properly scaled
    * when under scheduled. Setting the opportunity level allocation to a lower amount validates that it is scaled
    * properly when decreasing the amount, going from the opportunity to the payment.
    * Updating the opportunity level allocation should also overwrite the payment level allocations.
    ********************************************************************************************************/
    @isTest
    private static void testAllocationAmountDecreasedOnOpportunityUnderScheduled() {
        setupForTests();
        makePayments(600, 10);
        makeGAUs(2);
        Id GAUId = gaus[1].Id;
        List<Allocation__c> alloForInsert = new List<Allocation__c>();

        alloForInsert.add(new Allocation__c(Payment__c=payments[0].Id, Percent__c = 50, General_Accounting_Unit__c = GAUId));

        insert alloForInsert;

        Allocation__c oppAllocation = [select Id,
                                Opportunity__c,
                                Payment__c,
                                General_Accounting_Unit__c,
                                General_Accounting_Unit__r.Name,
                                Amount__c,
                                Percent__c
                       from Allocation__c
                       where Opportunity__c = :opportunity.Id
                       AND General_Accounting_Unit__c =: GAUId
                       order by Amount__c DESC];

        System.assert(oppAllocation.Percent__c == 5, 'This is the opportunity allocation amount: ' + oppAllocation.percent__c);

        oppAllocation.Percent__c = 2;

        Test.startTest();
        update oppAllocation;

        Allocation__c paymentAllocation = [select Id,
                                Opportunity__c,
                                Payment__c,
                                General_Accounting_Unit__c,
                                General_Accounting_Unit__r.Name,
                                Amount__c,
                                Percent__c
                       from Allocation__c
                       where Payment__c = :payments[0].Id
                       AND General_Accounting_Unit__c =: GAUId
                       order by Amount__c DESC];

        System.assert(paymentAllocation.Percent__c == 2, 'The allocation percent is incorrect. It should be 2, but it is actually: ' + paymentAllocation);
        Test.stopTest();
    }

    /*******************************************************************************************************
    * @description Test when an opportunity is over scheduled, has payment level allocations changed,
    * then opportunity level allocations decreases. This validates that the payment allocation gets scaled properly
    * when over scheduled. Setting the opportunity allocation to a lower amount validates that the scaling happens properly when going
    * from the opportunity to the payment. Updating the opportunity level allocation should also overwrite the
    * payment level allocations.
    ********************************************************************************************************/
    @isTest
    private static void testAllocationAmountDecreasedOnOpportunityOverScheduled() {
        setupForTests();
        makePayments(5000, 10);
        makeGAUs(2);
        Id GAUId = gaus[1].Id;
        List<Allocation__c> alloForInsert = new List<Allocation__c>();

        alloForInsert.add(new Allocation__c(Payment__c=payments[0].Id, Percent__c = 50, General_Accounting_Unit__c = GAUId));

        insert alloForInsert;

        Allocation__c oppAllocation = [select Id,
                                Opportunity__c,
                                Payment__c,
                                General_Accounting_Unit__c,
                                General_Accounting_Unit__r.Name,
                                Amount__c,
                                Percent__c
                       from Allocation__c
                       where Opportunity__c = :opportunity.Id
                       AND General_Accounting_Unit__c =: GAUId
                       order by Amount__c DESC];

        System.assert(oppAllocation.Percent__c == 5, 'This is the opportunity allocation amount: ' + oppAllocation.percent__c);

        oppAllocation.Percent__c = 2;

        Test.startTest();
        update oppAllocation;

        Allocation__c paymentAllocation = [select Id,
                                Opportunity__c,
                                Payment__c,
                                General_Accounting_Unit__c,
                                General_Accounting_Unit__r.Name,
                                Amount__c,
                                Percent__c
                       from Allocation__c
                       where Payment__c = :payments[0].Id
                       AND General_Accounting_Unit__c =: GAUId
                       order by Amount__c DESC];

        System.assert(paymentAllocation.Percent__c == 2, 'The allocation percent is incorrect. It should be 2, but it is actually: ' + paymentAllocation);
        Test.stopTest();
    }

    /*******************************************************************************************************
    * @description Test when an opportunity is fully scheduled with one paid payment and one scheduled payment,
    * updating the allocations should not change the paid payment allocation. However, it should update the
    * schedule payment's allocations.
    ********************************************************************************************************/
    @isTest
    private static void testSyncOpportunityToPaymentWithFullyScheduledPartiallyPaid() {
        setupForTests();
        makeGAUs(1);
        opportunity = [SELECT Id, Name, Amount FROM Opportunity LIMIT 1];
        List<Allocation__c> alloForInsert = new List<Allocation__c>();

        alloForInsert.add(new Allocation__c(Opportunity__c=opportunity.Id, Percent__c = 100, General_Accounting_Unit__c = gaus[0].Id));
        insert alloForInsert;

        makePayments(1000, 2);

        npe01__OppPayment__c paidPayment = new npe01__OppPayment__c(Id = payments[0].Id, npe01__Paid__c = true);
        update paidPayment;

        Allocation__c oppAllocation = [select Id,
                Opportunity__c,
                Payment__c,
                General_Accounting_Unit__c,
                General_Accounting_Unit__r.Name,
                Amount__c,
                Percent__c
        from Allocation__c
        where Opportunity__c = :opportunity.Id
        AND General_Accounting_Unit__c =: gaus[0].Id
        order by Amount__c DESC];

        oppAllocation.Percent__c = 50;

        Test.startTest();
        update oppAllocation;

        List<Allocation__c> paidPaymentAllocations = new List<Allocation__c>([select Id,
                Opportunity__c,
                Payment__c,
                Payment__r.npe01__Paid__c,
                General_Accounting_Unit__c,
                General_Accounting_Unit__r.Name,
                Amount__c,
                Percent__c
        from Allocation__c
        where Payment__c = :payments[0].Id
        order by Amount__c DESC]);

        System.assertEquals(1, paidPaymentAllocations.size(), 'Paid Payment Allocation size');
        System.assertEquals(500, paidPaymentAllocations[0].Amount__c, 'Paid Payment amount');

        List<Allocation__c> secondPaymentAllocations = new List<Allocation__c>([select Id,
                Opportunity__c,
                Payment__c,
                Payment__r.npe01__Paid__c,
                General_Accounting_Unit__c,
                General_Accounting_Unit__r.Name,
                Amount__c,
                Percent__c
        from Allocation__c
        where Payment__c = :payments[1].Id
        order by Amount__c DESC]);

        System.assertEquals(2, secondPaymentAllocations.size(), 'Payment Allocation size');
        System.assertEquals(250, secondPaymentAllocations[0].Amount__c, 'Payment amount');
        System.assertEquals(250, secondPaymentAllocations[1].Amount__c, 'Payment amount');


        Test.stopTest();
    }

    private static void setupForTests() {
        defaultGau = [SELECT Id FROM General_Accounting_Unit__c WHERE Name = 'Default GAU' LIMIT 1];
        UTIL_CustomSettingsFacade.getAllocationsSettingsForTests(
            new Allocations_Settings__c(
                Payment_Allocations_Enabled__c = true,
                Default_Allocations_Enabled__c = true,
                Default__c = defaultGau.Id
            )
        );
    }

    /*******************************************************************************************************
    * @description Test when changing the amount of a Payment with Allocations that if GAU is Default GAU then 
    * percent is not populated.
    ********************************************************************************************************/
    @isTest
    private static void testNoPercentOnDefaultGAU(){
        setupForTests();
        makePayments(2000, 2);
        makeGAUs(1);  
        List<Allocation__c> alloForInsert = new List<Allocation__c>();
        List<Allocation__c> pmtAllocs = new List<Allocation__c>();

        alloForInsert.add(new Allocation__c(Opportunity__c=opportunity.Id, Percent__c = 100, General_Accounting_Unit__c = gaus[0].Id));
        insert alloForInsert;

        List<Allocation__c> allocations = getAllocationsOrderByAmount();    

        for (Allocation__c alloc : allocations) {
            if (alloc.Payment__c != null) {
                pmtAllocs.add(alloc);
            }
        }

        pmtAllocs[1].Percent__c = 50;
        update pmtAllocs;

        Allocation__c oppAllocation = [select Id,
                                Opportunity__c,
                                Payment__c,
                                General_Accounting_Unit__c,
                                General_Accounting_Unit__r.Name,
                                Amount__c,
                                Percent__c
                       from Allocation__c
                       where Opportunity__c = :opportunity.Id
                       AND General_Accounting_Unit__c =: defaultGau.id
                       order by Amount__c DESC];

        System.assertEquals(null, oppAllocation.Percent__c, 'Default Allocation Percentage');
    }
    
    /*******************************************************************************************************
    * @description Test specific for rounding bug in allocation sync reported in W-9271810. Irrational
    * numbers extended out to 31 digits led to a rounding error in the last 2 digits.
    ********************************************************************************************************/
    @isTest
    static void confirmGeneratedAllocationIsProperlyRoundedForIrrationalNumbers() {
        setupForTests();
        opportunity = [SELECT Id, Amount FROM Opportunity WHERE Name = 'Opp' LIMIT 1];
        opportunity.Amount = 32200;
        update(opportunity);
        
        makePayments(32200, 1);
        makeGAUs(3);

        List<Allocation__c> alloForInsert = new List<Allocation__c>();

        alloForInsert.add(new Allocation__c(Opportunity__c=opportunity.Id, Amount__c = 2000, General_Accounting_Unit__c = gaus[0].Id));
        alloForInsert.add(new Allocation__c(Opportunity__c=opportunity.Id, Amount__c = 5000, General_Accounting_Unit__c = gaus[1].Id));
        alloForInsert.add(new Allocation__c(Opportunity__c=opportunity.Id, Amount__c = 25200, General_Accounting_Unit__c = gaus[2].Id));
        insert alloForInsert;

        List<Allocation__c> queryAllocations = getAllocationsOrderByAmount();
        System.assertEquals(6, queryAllocations.size(), 'Six allocations should exist.');
        
        //original opportunity allocations
        assertAllocation(queryAllocations[0], 2000, gaus[0].Id, true);
        assertAllocation(queryAllocations[1], 5000, gaus[1].Id, true);
        assertAllocation(queryAllocations[2], 25200, gaus[2].Id, true);
        //synced payment allocations
        assertAllocation(queryAllocations[3], 2000, gaus[0].Id, false);
        assertAllocation(queryAllocations[4], 5000, gaus[1].Id, false);
        assertAllocation(queryAllocations[5], 25200, gaus[2].Id, false);
        
        Id paymentId = [SELECT Id FROM npe01__OppPayment__c LIMIT 1].Id;
        
        delete([SELECT Id FROM Allocation__c WHERE Payment__c =: paymentId]);
        alloForInsert = new List<Allocation__c>();
        alloForInsert.add(new Allocation__c(Payment__c = paymentId, Amount__c = 2000, General_Accounting_Unit__c = gaus[0].Id));
        alloForInsert.add(new Allocation__c(Payment__c = paymentId, Amount__c = 5000, General_Accounting_Unit__c = gaus[1].Id));
        alloForInsert.add(new Allocation__c(Payment__c = paymentId, Amount__c = 25200, General_Accounting_Unit__c = gaus[2].Id));
        insert alloForInsert;
        
        queryAllocations = getAllocationsOrderByAmount();
        System.assertEquals(6, queryAllocations.size(), 'Six allocations should exist.');
        
        //opportunity allocations
        assertAllocation(queryAllocations[0], 2000, gaus[0].Id, true);
        assertAllocation(queryAllocations[1], 5000, gaus[1].Id, true);
        assertAllocation(queryAllocations[2], 25200, gaus[2].Id, true);
        //payment allocations
        assertAllocation(queryAllocations[3], 2000, gaus[0].Id, false);
        assertAllocation(queryAllocations[4], 5000, gaus[1].Id, false);
        assertAllocation(queryAllocations[5], 25200, gaus[2].Id, false);
        
    }

    /*** Helpers ***/

    private static void makePayments(Decimal totalAmount, Integer numberOfPayments) {
        defaultGau = [SELECT Id FROM General_Accounting_Unit__c WHERE Name = 'Default GAU' LIMIT 1];
        opportunity = [SELECT Id, Name, Amount FROM Opportunity LIMIT 1];

        for (Integer i=0; i<numberOfPayments; i++) {
            payments.add(new npe01__OppPayment__c(
                npe01__Payment_Amount__c = totalAmount / numberOfPayments,
                npe01__Opportunity__c = opportunity.Id,
                npe01__Payment_Date__c = System.today()
            ));
        }
        insert payments;
    }

    private static void makeGAUs(Integer numberOfGAUs) {
        for (Integer i=0; i<numberOfGAUs; i++) {
            gaus.add(new General_Accounting_Unit__c(Name='GAU' + i));
        }
        insert gaus;
    }

    private static void assertAllocation(Allocation__c allocation, Decimal amount, Id gau, Boolean isOpportunityAllocation) {
        System.assertEquals(gau, allocation.General_Accounting_Unit__c, 'Allocation GAU mismatch: ' + allocation);
        System.assertEquals(amount, allocation.Amount__c, 'Allocation amount mismatch: ' + allocation);
        System.assertEquals(isOpportunityAllocation, allocation.Opportunity__c != null, 'Allocation type mismatch: ' + allocation);
    }

    /*********************************************************************************************************
    * @description Get all Allocations ordered by Amount
    * @return List<Allocation__c> A list of all Allocations
    **********************************************************************************************************/
    private static List<Allocation__c> getAllocationsOrderByAmount() {
        return Database.query(getAllocationsQuery().build() + ' ORDER BY Opportunity__c NULLS LAST, Amount__c, General_Accounting_Unit__c');
    }

    /*********************************************************************************************************
    * @description Build query to retrieve all Allocations
    * @return UTIL_Query Allocation SOQL
    **********************************************************************************************************/
    private static UTIL_Query getAllocationsQuery() {
        return new UTIL_Query()
            .withSelectFields(new String[]{
                'Name',
                'Opportunity__c',
                'Payment__c',
                'General_Accounting_Unit__c',
                'General_Accounting_Unit__r.Name',
                'Amount__c',
                'Percent__c'
            })
            .withFrom('Allocation__c');
    }

}