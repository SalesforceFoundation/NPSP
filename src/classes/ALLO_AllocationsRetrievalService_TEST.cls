/*
    Copyright (c) 2020, Salesforce.org
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification,Then w are permitted provided that the following conditions are met:

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
* @date 2020
* @group Allocations
* @group-content ../../ApexDocContent/Allocations.htm
* @description Tests for ALLO_AllocationsRetrievalService class
*/
@IsTest(isParallel=true)
public class ALLO_AllocationsRetrievalService_TEST {

     /**
     * @description Confirm retrieves Opportunity, Payment, and Allocations Data for the the Opportunity Ids specified
     *              into a populated ALLO_AllocationsWrapper instance
     *              [ALLO_AllocationsRetrievalService]
     */
    @isTest
    private static void confirmAllocationsWrapperIsRetrievedAndPopulatedSuccessfully() {
        ALLO_UnitTestHelper_TEST.AllocationSetupTest alloSetupTest = new ALLO_UnitTestHelper_TEST.AllocationSetupTest()
            .enableDefaultAllocations()
            .enablePaymentAllocations()
            .disableAllocationTriggers()
            .applyConfiguration();

        List<Id> oppIds = ALLO_UnitTestHelper_TEST.createTestDataAndReturnOppIds(alloSetupTest);

        Set<Id> oppIdsAsSet = new Set<Id>();
        oppIdsAsSet.addAll(oppIds);

        ALLO_AllocationsRetrievalService alloRetrievalSvc = new ALLO_AllocationsRetrievalService()
                                                                .withOpportunities(oppIdsAsSet)
                                                                .retrieveData();
        ALLO_AllocationsWrapper alloWrapper = alloRetrievalSvc.allocationsWrapper;

        Map<Id, Opportunity> oppsById = alloWrapper.oppsById;

        System.assertEquals (oppIds.size(), oppsById.size(), '# of Opportunities');

        Opportunity opp0 = oppsById.get(oppIds[0]);
        System.assertNotEquals(null, opp0.Name, 'Opportunity 0 - Name');
        System.assertEquals(UTIL_UnitTestDATA_TEST.getClosedWonStage(), opp0.StageName, 'Opportunity 0 - StageName');
        System.assertEquals(20, opp0.Amount, 'Opportunity 0 - Amount');
        System.assertEquals(null, opp0.CampaignId, 'Opportunity 0 - Campaign Id');
        System.assertNotEquals(null, opp0.npe03__Recurring_Donation__c, 'Opportunity - Recurring Donation');
        System.assertEquals(true, opp0.IsClosed, 'Opportunity 0 - IsClosed');
        System.assertNotEquals(null, opp0.LastModifiedDate, 'Opportunity 0 - LastModifiedDate');
        System.assertEquals(null, opp0.Type, 'Opportunity 0 - Type');

        Opportunity opp6 = oppsById.get(oppIds[6]);
        ALLO_UnitTestHelper_TEST.assertSObjectList(opp6.npe01__OppPayment__r, 13, 'Opportunity 6 - Payments');

        npe01__OppPayment__c opp6pmt0 = null;
        npe01__OppPayment__c opp6pmt1 = null;
        npe01__OppPayment__c opp6pmt2 = null;

        for (npe01__OppPayment__c pmt : opp6.npe01__OppPayment__r) {
            if (pmt.npe01__Scheduled_Date__c == System.today()) {
                opp6pmt0 = pmt;
            } else if (pmt.npe01__Scheduled_Date__c == System.today().addDays(1)) {
                opp6pmt1 = pmt;
            } else if (pmt.npe01__Scheduled_Date__c == System.today().addDays(2)){
                opp6pmt2 = pmt;
            }
        }

        System.assertNotEquals(null, opp6pmt0.Name, 'Opportunity 6 - Payment 0 - Name');
        System.assertEquals(10, opp6pmt0.npe01__Payment_Amount__c, 'Opportunity 6 - Payment 0 - Payment Amount');
        System.assertEquals(null, opp6pmt0.npe01__Payment_Date__c, 'Opportunity 6 - Payment 0 - Payment Date');
        System.assertEquals(System.today(), opp6pmt0.npe01__Scheduled_Date__c, 'Opportunity 6 - Payment 0 - Scheduled Date');
        System.assertEquals(false, opp6pmt0.npe01__Written_Off__c, 'Opportunity 6 - Payment 0 - Written Off');
        System.assertEquals(false, opp6pmt0.npe01__Paid__c, 'Opportunity 6 - Payment 0 - Paid');
        System.assertEquals(opp6.Id, opp6pmt0.npe01__Opportunity__c, 'Opportunity 6 - Payment 0 - Opportunity Id');
        System.assertNotEquals(null, opp6pmt0.LastModifiedDate, 'Opportunity 6 - Payment 0 - LastModifiedDate');

        System.assertNotEquals(null, opp6pmt1.Name, 'Opportunity 6 - Payment 1 - Name');
        System.assertEquals(10, opp6pmt1.npe01__Payment_Amount__c, 'Opportunity 6 - Payment 1 - Payment Amount');
        System.assertEquals(null, opp6pmt1.npe01__Payment_Date__c, 'Opportunity 6 - Payment 1 - Payment Date');
        System.assertEquals(System.today().addDays(1), opp6pmt1.npe01__Scheduled_Date__c, 'Opportunity 6 - Payment 1 - Scheduled Date');
        System.assertEquals(false, opp6pmt1.npe01__Written_Off__c, 'Opportunity 6 - Payment 1 - Written Off');
        System.assertEquals(false, opp6pmt1.npe01__Paid__c, 'Opportunity 6 - Payment 1 - Paid');
        System.assertEquals(opp6.Id, opp6pmt1.npe01__Opportunity__c, 'Opportunity 6 - Payment 1 - Opportunity Id');
        System.assertNotEquals(null, opp6pmt1.LastModifiedDate, 'Opportunity 6 - Payment 1 - LastModifiedDate');

        System.assertNotEquals(null, opp6pmt2.Name, 'Opportunity 6 - Payment 2 - Name');
        System.assertEquals(10, opp6pmt2.npe01__Payment_Amount__c, 'Opportunity 6 - Payment 2 - Payment Amount');
        System.assertEquals(null, opp6pmt2.npe01__Payment_Date__c, 'Opportunity 6 - Payment 2 - Payment Date');
        System.assertEquals(System.today().addDays(2), opp6pmt2.npe01__Scheduled_Date__c, 'Opportunity 6 - Payment 2 - Scheduled Date');
        System.assertEquals(false, opp6pmt2.npe01__Written_Off__c, 'Opportunity 6 - Payment 2 - Written Off');
        System.assertEquals(false, opp6pmt2.npe01__Paid__c, 'Opportunity 6 - Payment 2 - Paid');
        System.assertEquals(opp6.Id, opp6pmt2.npe01__Opportunity__c, 'Opportunity 6 - Payment 2 - Opportunity Id');
        System.assertNotEquals(null, opp6pmt2.LastModifiedDate, 'Opportunity 6 - Payment 2 - LastModifiedDate');

        ALLO_UnitTestHelper_TEST.assertSObjectList(alloWrapper.oppsAllocations.get(oppIds[0]), 2, 'Opportunity 0 - Allocations');
        ALLO_UnitTestHelper_TEST.assertSObjectList(alloWrapper.oppsAllocations.get(oppIds[3]), 1, 'Opportunity 3 - Allocations');
        ALLO_UnitTestHelper_TEST.assertSObjectList(alloWrapper.oppsAllocations.get(oppIds[4]), 1, 'Opportunity 4 - Allocations');
        ALLO_UnitTestHelper_TEST.assertSObjectList(alloWrapper.oppsAllocations.get(oppIds[5]), 1, 'Opportunity 5 - Allocations');
        ALLO_UnitTestHelper_TEST.assertSObjectList(alloWrapper.oppsAllocations.get(oppIds[6]), 1, 'Opportunity 6 - Allocations');
        ALLO_UnitTestHelper_TEST.assertSObjectList(alloWrapper.oppsAllocations.get(oppIds[7]), 1, 'Opportunity 7 - Allocations');

        Allocation__c alloc = alloWrapper.oppsAllocations.get(oppIds[7])[0];
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc, oppIds[7], 20, 100, 'GAU 2', 'Opportunity 7 - Allocation 0' );

        System.assertEquals(11, alloWrapper.paymentAllocations.size(), 'Payment Allocations');

        Opportunity opp7 = oppsById.get(oppIds[7]);

        alloc = alloWrapper.paymentAllocations.get(opp7.npe01__OppPayment__r[0].Id)[0];
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc, opp7.npe01__OppPayment__r[0].Id, 10, 100, 'GAU 2', 'Opportunity 7 - Payment 0 - Allocation 0');

        Id recurringDonationId = [SELECT    Id
                                  FROM npe03__Recurring_Donation__c
                                  LIMIT 1].Id;

        System.assertEquals(2, alloWrapper.recurringDonationAllocations.get(recurringDonationId).size(), 'Recurring Donation Allocations');
        alloc = alloWrapper.recurringDonationAllocations.get(recurringDonationId)[0];
        Allocation__c alloc2 = null;
        if (alloc.Percent__c != null) {
            alloc2 = alloWrapper.recurringDonationAllocations.get(recurringDonationId)[1];
        } else {
            alloc2 = alloc;
            alloc = alloWrapper.recurringDonationAllocations.get(recurringDonationId)[1];
        }
        ALLO_UnitTestHelper_TEST.assertRecurringDonationAllocation(alloc, recurringDonationId, null, 50, 'GAU 1', 'Recurring Donation - Allocation 0');
        ALLO_UnitTestHelper_TEST.assertRecurringDonationAllocation(alloc2, recurringDonationId, 10, null, 'GAU 2', 'Recurring Donation - Allocation 1');
    }

    /**
     * @description Confirm retrieves Allocation Data for the Opportunities, Payments, Recurring Donations, and
     *              Campaigns specified (via Ids)
     *              [ALLO_AllocationsRetrievalService.AllocationsQuery,
     *               ALLO_AllocationsRetrievalService.OpportunityQuery]
     */
    @isTest
    private static void confirmOpportunityAndAllocationsAreRetrievedSuccessfullyViaQueryClasses() {
        ALLO_UnitTestHelper_TEST.AllocationSetupTest alloSetupTest = new ALLO_UnitTestHelper_TEST.AllocationSetupTest()
            .enableDefaultAllocations()
            .enablePaymentAllocations()
            .disableAllocationTriggers()
            .applyConfiguration();

        List<Id> oppIds = ALLO_UnitTestHELPER_TEST.createTestDataAndReturnOppIds(alloSetupTest);
        Set<Id> oppIdsAsSet = new Set<Id>();
        oppIdsAsSet.addAll(oppIds);

        Map<Id, Opportunity> oppsById = new ALLO_AllocationsRetrievalService.OpportunitiesQuery()
                                            .withOpportunities(oppIdsAsSet)
                                            .query();
        System.assertEquals (oppIds.size(), oppsById.size(), '# of Opportunities');

        Opportunity opp0 = oppsById.get(oppIds[0]);
        System.assertNotEquals(null, opp0.Name, 'Opportunity 0 - Name');
        System.assertEquals(UTIL_UnitTestDATA_TEST.getClosedWonStage(), opp0.StageName, 'Opportunity 0 - StageName');
        System.assertEquals(20, opp0.Amount, 'Opportunity 0 - Amount');
        System.assertEquals(null, opp0.CampaignId, 'Opportunity 0 - Campaign Id');
        System.assertNotEquals(null, opp0.npe03__Recurring_Donation__c, 'Opportunity - Recurring Donation');
        System.assertEquals(true, opp0.IsClosed, 'Opportunity 0 - IsClosed');
        System.assertNotEquals(null, opp0.LastModifiedDate, 'Opportunity 0 - LastModifiedDate');
        System.assertEquals(null, opp0.Type, 'Opportunity 0 - Type');

        Opportunity opp6 = oppsById.get(oppIds[6]);
        ALLO_UnitTestHelper_TEST.assertSObjectList(opp6.npe01__OppPayment__r, 13, 'Opportunity 6 - Payments');

        npe01__OppPayment__c opp6pmt0 = null;
        npe01__OppPayment__c opp6pmt1 = null;
        npe01__OppPayment__c opp6pmt2 = null;

        for (npe01__OppPayment__c pmt : opp6.npe01__OppPayment__r) {
            if (pmt.npe01__Scheduled_Date__c == System.today()) {
                opp6pmt0 = pmt;
            } else if (pmt.npe01__Scheduled_Date__c == System.today().addDays(1)) {
                opp6pmt1 = pmt;
            } else if (pmt.npe01__Scheduled_Date__c == System.today().addDays(2)){
                opp6pmt2 = pmt;
            }
        }

        System.assertNotEquals(null, opp6pmt0.Name, 'Opportunity 6 - Payment 0 - Name');
        System.assertEquals(10, opp6pmt0.npe01__Payment_Amount__c, 'Opportunity 6 - Payment 0 - Payment Amount');
        System.assertEquals(null, opp6pmt0.npe01__Payment_Date__c, 'Opportunity 6 - Payment 0 - Payment Date');
        System.assertEquals(System.today(), opp6pmt0.npe01__Scheduled_Date__c, 'Opportunity 6 - Payment 0 - Scheduled Date');
        System.assertEquals(false, opp6pmt0.npe01__Written_Off__c, 'Opportunity 6 - Payment 0 - Written Off');
        System.assertEquals(false, opp6pmt0.npe01__Paid__c, 'Opportunity 6 - Payment 0 - Paid');
        System.assertEquals(opp6.Id, opp6pmt0.npe01__Opportunity__c, 'Opportunity 6 - Payment 0 - Opportunity Id');
        System.assertNotEquals(null, opp6pmt0.LastModifiedDate, 'Opportunity 6 - Payment 0 - LastModifiedDate');

        System.assertNotEquals(null, opp6pmt1.Name, 'Opportunity 6 - Payment 1 - Name');
        System.assertEquals(10, opp6pmt1.npe01__Payment_Amount__c, 'Opportunity 6 - Payment 1 - Payment Amount');
        System.assertEquals(null, opp6pmt1.npe01__Payment_Date__c, 'Opportunity 6 - Payment 1 - Payment Date');
        System.assertEquals(System.today().addDays(1), opp6pmt1.npe01__Scheduled_Date__c, 'Opportunity 6 - Payment 1 - Scheduled Date');
        System.assertEquals(false, opp6pmt1.npe01__Written_Off__c, 'Opportunity 6 - Payment 1 - Written Off');
        System.assertEquals(false, opp6pmt1.npe01__Paid__c, 'Opportunity 6 - Payment 1 - Paid');
        System.assertEquals(opp6.Id, opp6pmt1.npe01__Opportunity__c, 'Opportunity 6 - Payment 1 - Opportunity Id');
        System.assertNotEquals(null, opp6pmt1.LastModifiedDate, 'Opportunity 6 - Payment 1 - LastModifiedDate');

        System.assertNotEquals(null, opp6pmt2.Name, 'Opportunity 6 - Payment 2 - Name');
        System.assertEquals(10, opp6pmt2.npe01__Payment_Amount__c, 'Opportunity 6 - Payment 2 - Payment Amount');
        System.assertEquals(null, opp6pmt2.npe01__Payment_Date__c, 'Opportunity 6 - Payment 2 - Payment Date');
        System.assertEquals(System.today().addDays(2), opp6pmt2.npe01__Scheduled_Date__c, 'Opportunity 6 - Payment 2 - Scheduled Date');
        System.assertEquals(false, opp6pmt2.npe01__Written_Off__c, 'Opportunity 6 - Payment 2 - Written Off');
        System.assertEquals(false, opp6pmt2.npe01__Paid__c, 'Opportunity 6 - Payment 2 - Paid');
        System.assertEquals(opp6.Id, opp6pmt2.npe01__Opportunity__c, 'Opportunity 6 - Payment 2 - Opportunity Id');
        System.assertNotEquals(null, opp6pmt2.LastModifiedDate, 'Opportunity 6 - Payment 2 - LastModifiedDate');

        Set<Id> campaignIds = new Set<Id>();
        Set<Id> recurringDonationIds = new Set<Id>();
        Set<Id> pmtIds = new Set<Id>();
        Id recurringDonationId = null;
        for (Opportunity opp : oppsById.values()) {
            if (opp.CampaignId != null) {
                campaignIds.add(opp.CampaignId);
            }
            if (opp.npe03__Recurring_Donation__c != null) {
                recurringDonationIds.add(opp.npe03__Recurring_Donation__c);
                recurringDonationId = opp.npe03__Recurring_Donation__c;
            }
            for (npe01__OppPayment__c pmt : opp.npe01__OppPayment__r) {
                pmtIds.add(pmt.Id);
            }
        }

        List<Allocation__c> allocs = new ALLO_AllocationsRetrievalService.AllocationsQuery()
                                        .withOpportunities(oppIdsAsSet)
                                        .withPayments(pmtIds)
                                        .withCampaigns(campaignIds)
                                        .withRecurringDonations(recurringDonationIds)
                                        .query();

        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 30, 'Allocations');

        ALLO_AllocationsWrapper allocWrapper = new ALLO_AllocationsWrapper();

        for (Allocation__c alloc : allocs) {
            allocWrapper.addAllocationByType(alloc);
        }
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocWrapper.oppsAllocations.get(oppIds[0]), 2, 'Opportunity 0 - Allocations');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocWrapper.oppsAllocations.get(oppIds[3]), 1, 'Opportunity 3 - Allocations');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocWrapper.oppsAllocations.get(oppIds[4]), 1, 'Opportunity 4 - Allocations');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocWrapper.oppsAllocations.get(oppIds[5]), 1, 'Opportunity 5 - Allocations');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocWrapper.oppsAllocations.get(oppIds[6]), 1, 'Opportunity 6 - Allocations');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocWrapper.oppsAllocations.get(oppIds[7]), 1, 'Opportunity 7 - Allocations');

        Allocation__c alloc = allocWrapper.oppsAllocations.get(oppIds[7])[0];
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc, oppIds[7], 20, 100, 'GAU 2', 'Opportunity 7 - Allocation 0' );

        System.assertEquals(11, allocWrapper.paymentAllocations.size(), 'Payment Allocations');

        Opportunity opp7 = oppsById.get(oppIds[7]);

        alloc = allocWrapper.paymentAllocations.get(opp7.npe01__OppPayment__r[0].Id)[0];
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc, opp7.npe01__OppPayment__r[0].Id, 10, 100, 'GAU 2', 'Opportunity 7 - Payment 0 - Allocation 0');

        System.assertEquals(2, allocWrapper.recurringDonationAllocations.get(recurringDonationId).size(), 'Recurring Donation Allocations');
        alloc = allocWrapper.recurringDonationAllocations.get(recurringDonationId)[0];
        Allocation__c alloc2 = null;
        if (alloc.Percent__c != null) {
            alloc2 = allocWrapper.recurringDonationAllocations.get(recurringDonationId)[1];
        } else {
            alloc2 = alloc;
            alloc = allocWrapper.recurringDonationAllocations.get(recurringDonationId)[1];
        }
        ALLO_UnitTestHelper_TEST.assertRecurringDonationAllocation(alloc, recurringDonationId, null, 50, 'GAU 1', 'Recurring Donation - Allocation 0');
        ALLO_UnitTestHelper_TEST.assertRecurringDonationAllocation(alloc2, recurringDonationId, 10, null, 'GAU 2', 'Recurring Donation - Allocation 1');
    }
}