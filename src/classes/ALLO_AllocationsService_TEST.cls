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
* @description Tests for ALLO_AllocationsService class
*/
@IsTest(isParallel=true)
public class ALLO_AllocationsService_TEST {
    /**
     * @description Executes various Opportunity and Payment Allocation Scenarios when
     *              Payment and Default Allocations are enabled
     *              [ALLO_AllocationsService.processRecords]
     *
     *              Parent Allocation Data:
     *              Recurring Donation - Allocations (GAU0, 50%), (GAU1, $10)
     *              Campaign - Allocations (GAU1, $10)
     *
     *              Test Data & Results:
     *              Opportunity 0  - $20, Recurring Donation Parent, Fully allocated
     *                               Opportunity Allocations (GAU0, 50%, $10), (GAU1, $10)
     *                               Result: No Change
     *              Opportunity 1  - $20, Recurring Donation Parent, No Allocations present
     *                               Result: Opportunity Allocations (GAU0, 50%, $10), (GAU1, $10)
     *              Opportunity 2  - $20, No Allocations present
     *                               Result: (Default GAU, $20)
     *              Opportunity 3  - $20, Sum of Allocations < Opportunity Amount
     *                               Opportunity Allocations (GAU1, $10)
     *                               Result: Opportunity Allocations (GAU 1, $10), (Default GAU, $10)
     *              Opportunity 4  - $20, Allocation has percent but not amount
     *                               Opportunity Allocations (GAU1, 100%, (null))
     *                               Result: Opportunity Allocations (GAU1, 100%, $20)
     *              Opportunity 5  - $0, Percent Allocation with non zero amount
     *                               Opportunity Allocations (GAU1, 50%, $20)
     *                               Result: Opportunity Allocations (GAU1, 50%, $0)
     *              Opportunity 6  - $20, Fully allocated at Opportunity level
     *                               Opportunity Allocations (GAU1, 100%, $20)
     *                               Result: No change to Opportunity Allocations
     *              Opportunity 7  - $20, Fully allocated at Opportunity level
     *                               Opportunity Allocations (GAU1, 100%, $20)
     *                               Result: No change to Opportunity Allocations
     *              Opportunity 8  - (null), Opportunity Allocations (Default GAU, $20)
     *                               Result: Opportunity Allocations Deleted
     *              Opportunity 9  - $20, Campaign Parent, No Allocations Present
     *                               Result: Opportunity Allocations (GAU1, $10), (Default GAU, $10)
     *              Opportunity 10 - $20, Allocations need resizing
     *                               Opportunity Allocations (GAU1, 50%, $40), (Default GAU, $40)
     *                               Result: Opportunity Allocations (GAU1, 50%, $10), (Default GAU, $10)
     *              Opportunity 11 - $20, Invalid Allocation that cannot be corrected
     *                               Opportunity Allocations (GAU1, $40)
     *                               Result: Error is added, because overallocated, and cannot fix automatically
     *              Opportunity 6, Payment 0  - No Allocations are present
     *                                          Result: Payment Allocations (GAU1, 100%, $10)
     *              Opportunity 6, Payment 1  - $10, Allocations Need Resizing
     *                                          Payment Allocations (GAU0, 50%), (GAU1, $1). (Default GAU, $10)
     *                                          Result: Payment Allocations (GAU0, 50%, $5), (GAU1, $1), (Default GAU, $4)
     *              Opportunity 6, Payment 2  - $10, Needs Default Allocation
     *                                          Payment Allocations (GAU0, $1)
     *                                          Result: Payment Allocations (GAU0, $1), (Default GAU, $9)
     *              Opportunity 6, Payment 3  - $10, Remove Default Allocation Because Fully Allocated
     *                                          Payment Allocations (GAU0, 100%, $10), (Default GAU, $10)
     *                                          Result: Payment Allocations (GAU0, 100%, $10)
     *              Opportunity 6, Payment 4  - $0, Default Allocation needs resizing
     *                                          Payment Allocations (Default GAU, $10)
     *                                          Result: Payment Allocations (Default GAU, $0)
     *              Opportunity 6, Payment 5  - (null), Default Allocation needs resizing
     *                                          Payment Allocations (Default GAU, $10)
     *                                          Result: Payment Allocations (Default GAU, $0)
     *              Opportunity 6, Payment 6  - $0, Percent Allocation to update
     *                                          Payment Allocations (GAU0, 10%, $1)
     *                                          Result: Payment Allocations (GAU0, 10%, $0)
     *              Opportunity 6, Payment 7  - (null), Percent Allocation to update
     *                                          Payment Allocations (GAU0, 10%, $1)
     *                                          Result: Payment Allocations (GAU0, 10%, $0)
     *              Opportunity 6, Payment 8  - $0, Percent Allocation to update, Default Allocation to remove
     *                                          Payment Allocations (GAU0, 10%, $1), (Default GAU, $10)
     *                                          Result: Payment Allocations (GAU0, 10%, $0)
     *              Opportunity 6, Payment 9  - (null), Percent Allocation to update, Default Allocation to remove
     *                                          Payment Allocations (GAU0, 10%, $1), (Default GAU, $10)
     *                                          Result: Payment Allocations (GAU0, 10%, $0)
     *              Opportunity 6, Payment 10 - $0, Needs Allocations
     *                                          Result: Payment Allocations (GAU1, 100%, $0)
     *              Opportunity 6, Payment 11 - (null), Needs Allocations
     *                                          Result: Payment Allocations (GAU1, 100%, $0)
     *              Opportunity 6, Payment 12 - $10, Invalid Allocation (no amount or percent)
     *                                          Payment Allocations (GAU1)
     *                                          Result: Error added, no change to Payment Allocations
     *              Opportunity 7, Payment 0  - $10, Fully allocated
     *                                          Result: No change to Allocations
     *
     */
    @isTest
    private static void confirmAllocationServiceUpdatesAllocationsCorrectlyWhenPaymentAllocationsAreEnabled() {
        ALLO_UnitTestHelper_TEST.AllocationSetupTest alloSetupTest = new ALLO_UnitTestHelper_TEST.AllocationSetupTest()
            .enableDefaultAllocations()
            .enablePaymentAllocations()
            .disableAllocationTriggers()
            .applyConfiguration();

        List<General_Accounting_Unit__c> gaus = alloSetupTest.getGAUs();
        General_Accounting_Unit__c defaultGAU = alloSetupTest.getDefaultGAU();

        List<Id> oppIds = ALLO_UnitTestHelper_TEST.createTestDataAndReturnOppIds(alloSetupTest);

        Id campaignId = [SELECT Id FROM Campaign LIMIT 1].Id;
        Id rdId = [SELECT Id FROM npe03__Recurring_Donation__c LIMIT 1].Id;

        Set<Id> oppIdsAsSet = new Set<Id>();
        oppIdsAsSet.addAll(oppIds);

        ALLO_AllocationsWrapper allocWrapper = new ALLO_AllocationsRetrievalService()
                                                        .withOpportunities(oppIdsAsSet)
                                                        .retrieveData()
                                                        .allocationsWrapper;

        String baseMessage = 'Before Processing';
        List<Allocation__c> allocs = null;
        Allocation__c alloc0 = null;
        Allocation__c alloc1 = null;
        Allocation__c alloc2 = null;

        // Opportunity 0  - $20, Recurring Donation Parent, Fully allocated
        //                  Opportunity Allocations (GAU0, 50%, $10), (GAU1, $10)
           String message = baseMessage + ' - Opportunity 0';
        allocs = allocWrapper.oppsAllocations.get(oppIds[0]);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 2, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[0]);
        alloc1 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[0], 10, 50, gaus[0].Id, message + ' - Allocation 0');
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc1, oppIds[0], 10, null, gaus[1].Id, message + ' - Allocation 1');

        // Opportunity 1  - $20, Recurring Donation Parent, No Allocations present
        message = baseMessage + ' - Opportunity 1';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocWrapper.oppsAllocations.get(oppIds[1]), 0, message);

        // Opportunity 2  - $20, No Allocations present
        message = baseMessage + ' - Opportunity 2';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocWrapper.oppsAllocations.get(oppIds[2]), 0, message);

        // Opportunity 3  - $20, Sum of Allocations < Opportunity Amount
        //                  Opportunity Allocations (GAU1, $10)
        message = baseMessage + ' - Opportunity 3';
        allocs = allocWrapper.oppsAllocations.get(oppIds[3]);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[3], 10, null, gaus[1].Id, message + ' - Allocation 0');

        // Opportunity 4  - $20, Allocation has percent but not amount
        //                  Opportunity Allocations (GAU1, 100%, (null))
        message = baseMessage + ' - Opportunity 4';
        allocs = allocWrapper.oppsAllocations.get(oppIds[4]);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[4], null, 100, gaus[1].Id, message + ' - Allocation 0');

        // Opportunity 5  - $0, Percent Allocation with non zero amount
        //                      Opportunity Allocations (GAU1, 50%, $20)
        message = baseMessage + ' - Opportunity 5';
        allocs = allocWrapper.oppsAllocations.get(oppIds[5]);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[5], 20, 50, gaus[1].Id, message + ' - Allocation 0');

        // Opportunity 6  - $20, Fully allocated at Opportunity level
        //                  Opportunity Allocations (GAU1, 100%, $20)
        message = baseMessage + ' - Opportunity 6';
        allocs = allocWrapper.oppsAllocations.get(oppIds[6]);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[6], 20, 100, gaus[1].Id, message + ' - Allocation 0');

        // Opportunity 7  - $20, Fully allocated at Opportunity level
        //                  Opportunity Allocations (GAU1, 100%, $20)
        message = baseMessage + ' - Opportunity 7';
        allocs = allocWrapper.oppsAllocations.get(oppIds[7]);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[7], 20, 100, gaus[1].Id, message + ' - Allocation 0');

        // Opportunity 8  - (null), Opportunity Allocations (Default GAU, $20)
        message = baseMessage + ' - Opportunity 8';
        allocs = allocWrapper.oppsAllocations.get(oppIds[8]);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, defaultGAU);
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[8], 20, null, defaultGAU.Id, message + ' - Allocation 0');

        // Opportunity 9  - $20, Campaign Parent, No Allocations Present
        message = baseMessage + ' - Opportunity 9';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocWrapper.oppsAllocations.get(oppIds[9]), 0, message);

        // Opportunity 10 - $20, Allocations need resizing
        //                  Opportunity Allocations (GAU1, 50%, $40), (Default GAU, $40)
        message = baseMessage + ' - Opportunity 10';
        allocs = allocWrapper.oppsAllocations.get(oppIds[10]);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 2, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        alloc1 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, defaultGAU);
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[10], 40, 50, gaus[1].Id, message + ' - Allocation 0');
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc1, oppIds[10], 40, null, defaultGAU.Id, message + ' - Allocation 1');

        // Opportunity 11 - $20, Invalid Allocation that cannot be corrected
        //                  Opportunity Allocations (GAU1, $40)
        message = baseMessage + ' - Opportunity 11';
        allocs = allocWrapper.oppsAllocations.get(oppIds[11]);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[11], 40, null, gaus[1].Id, message + ' - Allocation 0');

        // Recurring Donation - Allocations
        message = baseMessage + ' - Recurring Donation';
        List<Allocation__c> rdAllocs = allocWrapper.recurringDonationAllocations.get(rdId);
        ALLO_UnitTestHelper_TEST.assertSObjectList(rdAllocs, 2, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(rdAllocs, gaus[0]);
        alloc1 = ALLO_UnitTestHelper_TEST.findByGAU(rdAllocs, gaus[1]);
        ALLO_UnitTestHelper_TEST.assertRecurringDonationAllocation(alloc0, rdId, null, 50, gaus[0].Id, message + ' - Allocation 0');
        ALLO_UnitTestHelper_TEST.assertRecurringDonationAllocation(alloc1, rdId, 10, null, gaus[1].Id, message + ' - Allocation 1');

        // Campaign - Allocations
        message = baseMessage + ' - Campaign';
        List<Allocation__c> campAllocs = allocWrapper.campaignAllocations.get(campaignId);
        ALLO_UnitTestHelper_TEST.assertSObjectList(campAllocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(campAllocs, gaus[1]);
        ALLO_UnitTestHelper_TEST.assertCampaignAllocation(alloc0, campaignId, 10, null, gaus[1].Id, message + ' - Allocation 0');

        if (alloSetupTest.isPaymentAllocationsEnabled()) {
            assertPaymentAllocationsBeforeProcessing(allocWrapper.paymentAllocations, oppIds, gaus, defaultGAU);
        }
        Test.startTest();

        ALLO_AllocationsService allocService = new ALLO_AllocationsService()
                                                    .withAllocationTriggersDisabled(true)
                                                    .withCommitAndClearRecordsEnabled(true)
                                                    .withAlternateContextType('Test');

        // Process Allocations for Opportunities
        Set<Id> successfullyProcessedOppIds = allocService.processRecords(oppIdsAsSet);

        Test.stopTest();

        // Two Opportunities are expected to be dropped with errors
        System.assertEquals (oppIdsAsSet.size() - 2, successfullyProcessedOppIds.size(), 'Expected number of records to be successfully processed');

        baseMessage = 'After Processing';

        allocWrapper = new ALLO_AllocationsRetrievalService()
                        .withOpportunities(oppIdsAsSet)
                        .retrieveData()
                        .allocationsWrapper;

        // Retrieve Errors...
        Map<Id, Error__c> errorsByRecordId = ALLO_UnitTestHelper_TEST.getErrorsByRecordId();

        // Opportunity 0  - $20, Recurring Donation Parent, Fully allocated
        //                  Opportunity Allocations (GAU0, 50%, $10), (GAU1, $10)
        //                  Result: No Change
        message = baseMessage + ' - Opportunity 0';
        allocs = allocWrapper.oppsAllocations.get(oppIds[0]);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 2, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[0]);
        alloc1 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[0], 10, 50, gaus[0].Id, message + ' - Allocation 0');
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc1, oppIds[0], 10, null, gaus[1].Id, message + ' - Allocation 1');

        // Opportunity 1  - $20, Recurring Donation Parent, No Allocations present
        //                  Result: Opportunity Allocations (GAU0, 50%, $10), (GAU1, $10)
        message = baseMessage + ' - Opportunity 1';
        allocs = allocWrapper.oppsAllocations.get(oppIds[1]);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 2, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[0]);
        alloc1 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[1], 10, 50, gaus[0].Id, message + ' - Allocation 0');
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc1, oppIds[1], 10, null, gaus[1].Id, message + ' - Allocation 1');

        // Opportunity 2  - $20, No Allocations present
        //                  Result: (Default GAU, $20)
        message = baseMessage + ' - Opportunity 2';
        allocs = allocWrapper.oppsAllocations.get(oppIds[2]);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, defaultGAU);
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[2], 20, null, defaultGAU.Id, message + ' - Allocation 0');

        // Opportunity 3  - $20, Sum of Allocations < Opportunity Amount
        //                  Opportunity Allocations (GAU1, $10)
        //                  Result: Opportunity Allocations (GAU 1, $10), (Default GAU, $10)
        message = baseMessage + ' - Opportunity 3';
        allocs = allocWrapper.oppsAllocations.get(oppIds[3]);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 2, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        alloc1 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, defaultGAU);
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[3], 10, null, gaus[1].Id, message + ' - Allocation 0');
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc1, oppIds[3], 10, null, defaultGAU.Id, message + ' - Allocation 1');

        // Opportunity 4  - $20, Allocation has percent but not amount
        //                  Opportunity Allocations (GAU1, 100%, (null))
        //                  Result: Opportunity Allocations (GAU1, 100%, $20)
        message = baseMessage + ' - Opportunity 4';
        allocs = allocWrapper.oppsAllocations.get(oppIds[4]);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[4], 20, 100, gaus[1].Id, message + ' - Allocation 0');

        // Opportunity 5  - $0, Percent Allocation with non zero amount
        //                  Opportunity Allocations (GAU1, 50%, $20)
        //                  Result: Opportunity Allocations (GAU1, 50%, $0)
        message = baseMessage + ' - Opportunity 5';
        allocs = allocWrapper.oppsAllocations.get(oppIds[5]);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[5], 0, 50, gaus[1].Id, message + ' - Allocation 0');

        // Opportunity 6  - $20, Fully allocated at Opportunity level
        //                  Opportunity Allocations (GAU1, 100%, $20)
        //                  Result: No change to Opportunity Allocations
        message = baseMessage + ' - Opportunity 6';
        allocs = allocWrapper.oppsAllocations.get(oppIds[6]);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[6], 20, 100, gaus[1].Id, message + ' - Allocation 0');
        System.assertEquals(true, errorsByRecordId.containsKey(oppIds[6]), message + ' - Error Record Present');

        // Opportunity 7  - $20, Fully allocated at Opportunity level
        //                  Opportunity Allocations (GAU1, 100%, $20)
        //                  Result: No change to Opportunity Allocations
        message = baseMessage + ' - Opportunity 7';
        allocs = allocWrapper.oppsAllocations.get(oppIds[7]);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[7], 20, 100, gaus[1].Id, message + ' - Allocation 0');

        // Opportunity 8  - (null), If Default Allocations Enabled, Allocation (Default GAU, $20)
        //                          Else Allocation (GAU2, 100%, $20)
        //                  Result: Opportunity Allocations Deleted
        message = baseMessage + ' - Opportunity 8';
        allocs = allocWrapper.oppsAllocations.get(oppIds[8]);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 0, message);

        // Opportunity 9  - $20, Campaign Parent, No Allocations Present
        //                  Result: Opportunity Allocations (GAU1, $10), (Default GAU, $10)
        message = baseMessage + ' - Opportunity 9';
        allocs = allocWrapper.oppsAllocations.get(oppIds[9]);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 2, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        alloc1 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, defaultGAU);
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[9], 10, null, gaus[1].Id, message + ' - Allocation 0');
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc1, oppIds[9], 10, null, defaultGAU.Id, message + ' - Allocation 1');

        // Opportunity 10 - $20, Allocations need resizing
        //                  Opportunity Allocations (GAU1, 50%, $40), (Default GAU, $40)
        //                  Result: Opportunity Allocations (GAU1, 50%, $10), (Default GAU, $10)
        message = baseMessage + ' - Opportunity 10';
        allocs = allocWrapper.oppsAllocations.get(oppIds[10]);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 2, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        alloc1 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, defaultGAU);
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[10], 10, 50, gaus[1].Id, message + ' - Allocation 0');
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc1, oppIds[10], 10, null, defaultGAU.Id, message + ' - Allocation 1');

        // Opportunity 11 - $20, Invalid Allocation that cannot be corrected
        //                  Opportunity Allocations (GAU1, $40)
        //                  Result: Error is added, because overallocated, and cannot fix automatically
        message = baseMessage + ' - Opportunity 11';
        allocs = allocWrapper.oppsAllocations.get(oppIds[11]);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[11], 40, null, gaus[1].Id, message + ' - Allocation 0');
        System.assertEquals(true, errorsByRecordId.containsKey(oppIds[11]), message + ' - Error Record Present');

        // Recurring Donation - Allocations
        message = baseMessage + ' - Recurring Donation';
        rdAllocs = allocWrapper.recurringDonationAllocations.get(rdId);
        ALLO_UnitTestHelper_TEST.assertSObjectList(rdAllocs, 2, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(rdAllocs, gaus[0]);
        alloc1 = ALLO_UnitTestHelper_TEST.findByGAU(rdAllocs, gaus[1]);
        ALLO_UnitTestHelper_TEST.assertRecurringDonationAllocation(alloc0, rdId, null, 50, gaus[0].Id, message + ' - Allocation 0');
        ALLO_UnitTestHelper_TEST.assertRecurringDonationAllocation(alloc1, rdId, 10, null, gaus[1].Id, message + ' - Allocation 1');

        // Campaign - Allocations
        message = baseMessage + ' - Campaign';
        campAllocs = allocWrapper.campaignAllocations.get(campaignId);
        ALLO_UnitTestHelper_TEST.assertSObjectList(campAllocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(campAllocs, gaus[1]);
        ALLO_UnitTestHelper_TEST.assertCampaignAllocation(alloc0, campaignId, 10, null, gaus[1].Id, message + ' - Allocation 0');

        if (alloSetupTest.isPaymentAllocationsEnabled()) {
            assertPaymentAllocationsAfterProcessing(allocWrapper.paymentAllocations, oppIds, gaus, defaultGAU);
        }
    }

    /**
     * @description Executes various Opportunity and Payment Allocation Scenarios when
     *              Payment and Default Allocations are not
     *              [ALLO_AllocationsService.processRecords]
     *
     *              Parent Allocation Data:
     *              Recurring Donation - Allocations (GAU0, 50%), (GAU1, $10)
     *              Campaign - Allocations (GAU1, $10)
     *
     *              Test Data & Result1:
     *              Opportunity 0  - $20, Recurring Donation Parent, Fully allocated
     *                               Opportunity Allocations (GAU0, 50%, $10), (GAU1, $10)
     *                               Result: No Change
     *              Opportunity 1  - $20, Recurring Donation Parent, No Allocations present
     *                               Result: Opportunity Allocations (GAU0, 50%, $10), (GAU1, $10)
     *              Opportunity 2  - $20, No Allocations present
     *                               Result: No Change
     *              Opportunity 3  - $20, Sum of Allocations < Opportunity Amount
     *                               Opportunity Allocations (GAU1, $10)
     *                               Result: No Change
     *              Opportunity 4  - $20, Allocation has percent but not amount
     *                               Opportunity Allocations (GAU1, 100%, (null))
     *                               Result: Opportunity Allocations (GAU1, 100%, $20)
     *              Opportunity 5  - $0, Percent Allocation with non zero amount
     *                               Opportunity Allocations (GAU1, 50%, $20)
     *                               Result: Opportunity Allocations (GAU1, 50%, $0)
     *              Opportunity 6  - $20, Fully allocated at Opportunity level
     *                               Opportunity Allocations (GAU1, 100%, $20)
     *                               Result: No change to Opportunity Allocations
     *              Opportunity 7  - $20, Fully allocated at Opportunity level
     *                               Opportunity Allocations (GAU1, 100%, $20)
     *                               Result: No change to Opportunity Allocations
     *              Opportunity 8  - (null), Allocates to remove for (null) Opportunity Amount
     *                               Opportunity Allocations (GAU2, 100%, $20)
     *                               Result: Opportunity Allocations Deleted
     *              Opportunity 9  - $20, Campaign Parent, No Allocations Present
     *                               Result: Opportunity Allocations (GAU1, $10)
     *              Opportunity 10 - $20, Allocations need resizing
     *                               Opportunity Allocations (GAU1, 50%, $40)
     *                               Result: Opportunity Allocations (GAU1, 50%, $10)
     *              Opportunity 11 - $20, Invalid Allocation that cannot be corrected
     *                               Opportunity Allocations (GAU1, $40)
     *                               Result: Error is added, because overallocated, and cannot fix automatically
     */
    @isTest
    private static void confirmAllocationsServiceUpdatesAllocationsCorrectlyWhenDefaultAllocationsAreNotEnabled() {
        ALLO_UnitTestHelper_TEST.AllocationSetupTest alloSetupTest = new ALLO_UnitTestHelper_TEST.AllocationSetupTest()
        .disableAllocationTriggers()
        .applyConfiguration();

        List<General_Accounting_Unit__c> gaus = alloSetupTest.getGAUs();
        General_Accounting_Unit__c defaultGAU = alloSetupTest.getDefaultGAU();

        List<Id> oppIds = ALLO_UnitTestHelper_TEST.createTestDataAndReturnOppIds(alloSetupTest);

        Id campaignId = [SELECT Id FROM Campaign LIMIT 1].Id;
        Id rdId = [SELECT Id FROM npe03__Recurring_Donation__c LIMIT 1].Id;

        Set<Id> oppIdsAsSet = new Set<Id>();
        oppIdsAsSet.addAll(oppIds);

        ALLO_AllocationsWrapper allocWrapper = new ALLO_AllocationsRetrievalService()
                                                        .withOpportunities(oppIdsAsSet)
                                                        .retrieveData()
                                                        .allocationsWrapper;

        String baseMessage = 'Before Processing';
        List<Allocation__c> allocs = null;
        Allocation__c alloc0 = null;
        Allocation__c alloc1 = null;
        Allocation__c alloc2 = null;

        // Opportunity 0  - $20, Recurring Donation Parent, Fully allocated
        //                  Opportunity Allocations (GAU0, 50%, $10), (GAU1, $10)
        String message = baseMessage + ' - Opportunity 0';
        allocs = allocWrapper.oppsAllocations.get(oppIds[0]);
        ALLO_UnitTestHelper_Test.assertSObjectList(allocs, 2, message);
        alloc0 = ALLO_UnitTestHelper_Test.findByGAU(allocs, gaus[0]);
        alloc1 = ALLO_UnitTestHelper_Test.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_Test.assertOpportunityAllocation(alloc0, oppIds[0], 10, 50, gaus[0].Id, message + ' - Allocation 0');
        ALLO_UnitTestHelper_Test.assertOpportunityAllocation(alloc1, oppIds[0], 10, null, gaus[1].Id, message + ' - Allocation 1');

        // Opportunity 1  - $20, Recurring Donation Parent, No Allocations present
        message = baseMessage + ' - Opportunity 1';
        ALLO_UnitTestHelper_Test.assertSObjectList(allocWrapper.oppsAllocations.get(oppIds[1]), 0, message);

        // Opportunity 2  - $20, No Allocations present
         message = baseMessage + ' - Opportunity 2';
        ALLO_UnitTestHelper_Test.assertSObjectList(allocWrapper.oppsAllocations.get(oppIds[2]), 0, message);

        // Opportunity 3  - $20, Sum of Allocations < Opportunity Amount
        //                  Opportunity Allocations (GAU1, $10)
        message = baseMessage + ' - Opportunity 3';
        allocs = allocWrapper.oppsAllocations.get(oppIds[3]);
        ALLO_UnitTestHelper_Test.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_Test.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_Test.assertOpportunityAllocation(alloc0, oppIds[3], 10, null, gaus[1].Id, message + ' - Allocation 0');

        // Opportunity 4  - $20, Allocation has percent but not amount
        //                  Opportunity Allocations (GAU1, 100%, (null))
        message = baseMessage + ' - Opportunity 4';
        allocs = allocWrapper.oppsAllocations.get(oppIds[4]);
        ALLO_UnitTestHelper_Test.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_Test.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_Test.assertOpportunityAllocation(alloc0, oppIds[4], null, 100, gaus[1].Id, message + ' - Allocation 0');

        // Opportunity 5  - $0, Percent Allocation with non zero amount
        //                  Opportunity Allocations (GAU1, 50%, $20)
        message = baseMessage + ' - Opportunity 5';
        allocs = allocWrapper.oppsAllocations.get(oppIds[5]);
        ALLO_UnitTestHelper_Test.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_Test.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_Test.assertOpportunityAllocation(alloc0, oppIds[5], 20, 50, gaus[1].Id, message + ' - Allocation 0');

        // Opportunity 6  - $20, Fully allocated at Opportunity level
        //                  Opportunity Allocations (GAU1, 100%, $20)
        message = baseMessage + ' - Opportunity 6';
        allocs = allocWrapper.oppsAllocations.get(oppIds[6]);
        ALLO_UnitTestHelper_Test.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_Test.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_Test.assertOpportunityAllocation(alloc0, oppIds[6], 20, 100, gaus[1].Id, message + ' - Allocation 0');

        // Opportunity 7  - $20, Fully allocated at Opportunity level
        //                  Opportunity Allocations (GAU1, 100%, $20)
        message = baseMessage + ' - Opportunity 7';
        allocs = allocWrapper.oppsAllocations.get(oppIds[7]);
        ALLO_UnitTestHelper_Test.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_Test.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_Test.assertOpportunityAllocation(alloc0, oppIds[7], 20, 100, gaus[1].Id, message + ' - Allocation 0');

        // Opportunity 8  - (null), Allocates to remove for (null) Opportunity Amount
        //                  Opportunity Allocations (GAU2, 100%, $20)
        message = baseMessage + ' - Opportunity 8';
        allocs = allocWrapper.oppsAllocations.get(oppIds[8]);
        ALLO_UnitTestHelper_Test.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_Test.findByGAU(allocs, gaus[2]);
        ALLO_UnitTestHelper_Test.assertOpportunityAllocation(alloc0, oppIds[8], 20, 100, gaus[2].Id, message + ' - Allocation 0');

        // Opportunity 9  - $20, Campaign Parent, No Allocations Present
        message = baseMessage + ' - Opportunity 9';
        ALLO_UnitTestHelper_Test.assertSObjectList(allocWrapper.oppsAllocations.get(oppIds[9]), 0, message);

        // Opportunity 10 - $20, Allocations need resizing
        //                  Opportunity Allocations (GAU1, 50%, $40)
        message = baseMessage + ' - Opportunity 10';
        allocs = allocWrapper.oppsAllocations.get(oppIds[10]);
        ALLO_UnitTestHelper_Test.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_Test.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_Test.assertOpportunityAllocation(alloc0, oppIds[10], 40, 50, gaus[1].Id, message + ' - Allocation 0');

        // Opportunity 11 - $20, Invalid Allocation that cannot be corrected
        //                  Opportunity Allocations (GAU1, $40)
        message = baseMessage + ' - Opportunity 11';
        allocs = allocWrapper.oppsAllocations.get(oppIds[11]);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[11], 40, null, gaus[1].Id, message + ' - Allocation 0');

        // Recurring Donation - Allocations
        message = baseMessage + ' - Recurring Donation';
        System.assertEquals(1, allocWrapper.rdIdToOppIds.keySet().size(), message + ' - 1 Recurring Donation Present');
        List<Allocation__c> rdAllocs = allocWrapper.recurringDonationAllocations.get(rdId);
        ALLO_UnitTestHelper_TEST.assertSObjectList(rdAllocs, 2, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(rdAllocs, gaus[0]);
        alloc1 = ALLO_UnitTestHelper_TEST.findByGAU(rdAllocs, gaus[1]);
        ALLO_UnitTestHelper_TEST.assertRecurringDonationAllocation(alloc0, rdId, null, 50, gaus[0].Id, message + ' - Allocation 0');
        ALLO_UnitTestHelper_TEST.assertRecurringDonationAllocation(alloc1, rdId, 10, null, gaus[1].Id, message + ' - Allocation 1');

        // Campaign - Allocations
        message = baseMessage + ' - Campaign';
        System.assertEquals(1, allocWrapper.campaignIdToOppIds.keySet().size(), message + ' - 1 Campaign(s) Present');
        List<Allocation__c> campAllocs = allocWrapper.campaignAllocations.get(campaignId);
        ALLO_UnitTestHelper_TEST.assertSObjectList(campAllocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(campAllocs, gaus[1]);
        ALLO_UnitTestHelper_TEST.assertCampaignAllocation(alloc0, campaignId, 10, null, gaus[1].Id, message + ' - Allocation 0');

        Test.startTest();

        ALLO_AllocationsService allocService = new ALLO_AllocationsService()
                                                    .withAllocationTriggersDisabled(true)
                                                    .withCommitAndClearRecordsEnabled(true)
                                                    .withAlternateContextType('Test');

        // Process Allocations for Opportunities
        Set<Id> successfullyProcessedOppIds = allocService.processRecords(oppIdsAsSet);

        Test.stopTest();

        // One Opportunities are expected to be dropped with errors
        System.assertEquals (oppIdsAsSet.size() - 1, successfullyProcessedOppIds.size(), 'Expected number of records to be successfully processed');

        baseMessage = 'After Processing';

        allocWrapper = new ALLO_AllocationsRetrievalService()
                        .withOpportunities(oppIdsAsSet)
                        .retrieveData()
                        .allocationsWrapper;

        // Retrieve Errors...
        Map<Id, Error__c> errorsByRecordId = ALLO_UnitTestHelper_TEST.getErrorsByRecordId();

        // Opportunity 0  - $20, Recurring Donation Parent, Fully allocated
        //                  Opportunity Allocations (GAU0, 50%, $10), (GAU1, $10)
        //                  Result: No Change
           message = baseMessage + ' - Opportunity 0';
        allocs = allocWrapper.oppsAllocations.get(oppIds[0]);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 2, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[0]);
        alloc1 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[0], 10, 50, gaus[0].Id, message + ' - Allocation 0');
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc1, oppIds[0], 10, null, gaus[1].Id, message + ' - Allocation 1');

        // Opportunity 1  - $20, Recurring Donation Parent, No Allocations present
        //                  Result: Opportunity Allocations (GAU0, 50%, $10), (GAU1, $10)
        message = baseMessage + ' - Opportunity 1';
        allocs = allocWrapper.oppsAllocations.get(oppIds[1]);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 2, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[0]);
        alloc1 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[1], 10, 50, gaus[0].Id, message + ' - Allocation 0');
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc1, oppIds[1], 10, null, gaus[1].Id, message + ' - Allocation 1');

        // Opportunity 2  - $20, No Allocations present
        //                  Result: No Change
        message = baseMessage + ' - Opportunity 2';
        allocs = allocWrapper.oppsAllocations.get(oppIds[2]);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 0, message);

        // Opportunity 3  - $20, Sum of Allocations < Opportunity Amount
        //                  Opportunity Allocations (GAU1, $10)
        //                  Result: No Change
        message = baseMessage + ' - Opportunity 3';
        allocs = allocWrapper.oppsAllocations.get(oppIds[3]);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[3], 10, null, gaus[1].Id, message + ' - Allocation 0');

        // Opportunity 4  - $20, Allocation has percent but not amount
        //                  Opportunity Allocations (GAU1, 100%, (null))
        //                  Result: Opportunity Allocations (GAU1, 100%, $20)
        message = baseMessage + ' - Opportunity 4';
        allocs = allocWrapper.oppsAllocations.get(oppIds[4]);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[4], 20, 100, gaus[1].Id, message + ' - Allocation 0');

        // Opportunity 5  - $0, Percent Allocation with non zero amount
        //                  Opportunity Allocations (GAU1, 50%, $20)
        //                  Result: Opportunity Allocations (GAU1, 50%, $0)
        message = baseMessage + ' - Opportunity 5';
        allocs = allocWrapper.oppsAllocations.get(oppIds[5]);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[5], 0, 50, gaus[1].Id, message + ' - Allocation 0');

        // Opportunity 6  - $20, Fully allocated at Opportunity level
        //                  Opportunity Allocations (GAU1, 100%, $20)
        //                  Result: No change to Opportunity Allocations
        message = baseMessage + ' - Opportunity 6';
        allocs = allocWrapper.oppsAllocations.get(oppIds[6]);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[6], 20, 100, gaus[1].Id, message + ' - Allocation 0');

        // Opportunity 7  - $20, Fully allocated at Opportunity level
        //                  Opportunity Allocations (GAU1, 100%, $20)
        //                  Result: No change to Opportunity Allocations
        message = baseMessage + ' - Opportunity 7';
        allocs = allocWrapper.oppsAllocations.get(oppIds[7]);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[7], 20, 100, gaus[1].Id, message + ' - Allocation 0');

        // Opportunity 8  - (null), Allocates to remove for (null) Opportunity Amount
        //                  Opportunity Allocations (GAU2, 100%, $20)
        //                  Result: Opportunity Allocations Deleted
        message = baseMessage + ' - Opportunity 8';
        allocs = allocWrapper.oppsAllocations.get(oppIds[8]);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 0, message);

        // Opportunity 9  - $20, Campaign Parent, No Allocations Present
        //                  Result: Opportunity Allocations (GAU1, $10)
        message = baseMessage + ' - Opportunity 9';
        allocs = allocWrapper.oppsAllocations.get(oppIds[9]);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[9], 10, null, gaus[1].Id, message + ' - Allocation 0');

        // Opportunity 10 - $20, Allocations need resizing
        //                  Opportunity Allocations (GAU1, 50%, $40)
        //                  Result: Opportunity Allocations (GAU1, 50%, $10)
        message = baseMessage + ' - Opportunity 10';
        allocs = allocWrapper.oppsAllocations.get(oppIds[10]);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[10], 10, 50, gaus[1].Id, message + ' - Allocation 0');

        // Opportunity 11 - $20, Invalid Allocation that cannot be corrected
        //                  Opportunity Allocations (GAU1, $40)
        //                  Result: Error is added, because overallocated, and cannot fix automatically
        message = baseMessage + ' - Opportunity 11';
        allocs = allocWrapper.oppsAllocations.get(oppIds[11]);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[11], 40, null, gaus[1].Id, message + ' - Allocation 0');
        System.assertEquals(true, errorsByRecordId.containsKey(oppIds[11]), message + ' - Error Record Present');

        // Recurring Donation - Allocations
        message = baseMessage + ' - Recurring Donation';
        System.assertEquals(1, allocWrapper.recurringDonationAllocations.keySet().size(), message + ' - 1 Recurring Donation Present');
        rdAllocs = allocWrapper.recurringDonationAllocations.get(rdId);
        ALLO_UnitTestHelper_TEST.assertSObjectList(rdAllocs, 2, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(rdAllocs, gaus[0]);
        alloc1 = ALLO_UnitTestHelper_TEST.findByGAU(rdAllocs, gaus[1]);
        ALLO_UnitTestHelper_TEST.assertRecurringDonationAllocation(alloc0, rdId, null, 50, gaus[0].Id, message + ' - Allocation 0');
        ALLO_UnitTestHelper_TEST.assertRecurringDonationAllocation(alloc1, rdId, 10, null, gaus[1].Id, message + ' - Allocation 1');

        // Campaign - Allocations
        message = baseMessage + ' - Campaign';
        System.assertEquals(1, allocWrapper.campaignAllocations.keySet().size(), message + ' - 1 Campaign(s) Present');
        campAllocs = allocWrapper.campaignAllocations.get(campaignId);
        ALLO_UnitTestHelper_TEST.assertSObjectList(campAllocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(campAllocs, gaus[1]);
        ALLO_UnitTestHelper_TEST.assertCampaignAllocation(alloc0, campaignId, 10, null, gaus[1].Id, message + ' - Allocation 0');
    }

    /**
     * @description Confirm can use alternate Record Error Logger
     *              [ALLO_AllocationsService.withAlternateRecordErrorsLogger]
     */
    @isTest
    private static void confirmCanProvideAlternateRecordErrorLogger() {
        ALLO_AllocationsService allocSvc = new ALLO_AllocationsService();

        ERR_RecordError recErrs = new ERR_RecordError('Test');
        System.assertEquals(null, allocSvc.recErrs, 'Record Errors is null until processRecords runs, or one is provided');
        allocSvc.withAlternateRecordErrorsLogger(recErrs);
        System.assertEquals(recErrs, allocSvc.recErrs, 'Record Errors should be same as test one');
    }

     /**
     * @description Asserts that the Payment Allocations are correct before processing (called
     *              from confirmProcessRecordsUpdatesAllocationsCorrectlyWhenPaymentAllocationsAreEnabled)
     *              This is so that we can make sure nothing else is modifying them on insertion
     * @param allocsByPmtId A map of a list of Payment Allocations, organized by Payment Id
     * @param oppIds The Opportunity Ids used in the test, in insertion order
     * @param gaus The list of test gaus in insertion order
     * @param defaultGAU The default GAU
     */
    private static void assertPaymentAllocationsBeforeProcessing(Map<Id, List<Allocation__c>> allocsByPmtId, List<Id> oppIds, List<General_Accounting_Unit__c> gaus, General_Accounting_Unit__c defaultGAU) {
        Map<Id, Opportunity> oppsById = new Map<Id, Opportunity>([SELECT    Id,
                                                                            (SELECT     Id
                                                                            FROM npe01__OppPayment__r
                                                                            ORDER BY npe01__Scheduled_Date__c ASC
                                                                            )
                                                                FROM Opportunity
                                                                WHERE Id in :oppIds]);
        // Opportunity 6
        List<npe01__OppPayment__c> pmts = oppsById.get(oppIds[6]).npe01__OppPayment__r;

        String baseMessage = 'Before Processing - Opportunity 6 - ';
        String message = '';
        List<Allocation__c> allocs = null;
        Allocation__c alloc0 = null;
        Allocation__c alloc1 = null;
        Allocation__c alloc2 = null;

        // Opportunity 6, Payment 0  - No Allocations are present
           message = baseMessage + 'Payment 0';
        allocs = allocsByPmtId.get(pmts[0].Id);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, null, message);

        // Opportunity 6, Payment 1  - $10, Allocations Need Resizing
        //                             Payment Allocations (GAU0, 50%), (GAU1, $1). (Default GAU, $10)
        message = baseMessage + 'Payment 1';
        allocs = allocsByPmtId.get(pmts[1].Id);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 3, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, defaultGAU);
        alloc1 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[0]);
        alloc2 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc0, pmts[1].Id, 10, null, defaultGAU.Id, message + ' - Allocation 0');
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc1, pmts[1].Id, null, 50, gaus[0].Id, message + ' - Allocation 1');
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc2, pmts[1].Id, 1, null, gaus[1].Id, message + ' - Allocation 2');

        // Opportunity 6, Payment 2  - $10, Needs Default Allocation
        //                             Payment Allocations (GAU0, $1)
        message = baseMessage + 'Payment 2';
        allocs = allocsByPmtId.get(pmts[2].Id);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[0]);
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc0, pmts[2].Id, 1, null, gaus[0].Id, message + ' - Allocation 0');

        // Opportunity 6, Payment 3  - $10, Remove Default Allocation Because Fully Allocated
        //                             Payment Allocations (GAU0, 100%, $10), (Default GAU, $10)
        message = baseMessage + 'Payment 3';
        allocs = allocsByPmtId.get(pmts[3].Id);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 2, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[0]);
        alloc1 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, defaultGAU);
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc0, pmts[3].Id, 10, 100, gaus[0].Id, message + ' - Allocation 0');
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc1, pmts[3].Id, 10, null, defaultGAU.Id, message + ' - Allocation 1');

        // Opportunity 6, Payment 4  - $0, Default Allocation needs resizing
        //                             Payment Allocations (Default GAU, $10)
        message = baseMessage + 'Payment 4';
        allocs = allocsByPmtId.get(pmts[4].Id);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, defaultGAU);
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc0, pmts[4].Id, 10, null, defaultGAU.Id, message + ' - Allocation 0');

        // Opportunity 6, Payment 5  - (null), Default Allocation needs resizing
        //                             Payment Allocations (Default GAU, $10)
        message = baseMessage + 'Payment 5';
        allocs = allocsByPmtId.get(pmts[5].Id);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, defaultGAU);
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc0, pmts[5].Id, 10, null, defaultGAU.Id, message + ' - Allocation 0');

        // Opportunity 6, Payment 6  - $0, Percent Allocation to update
        //                             Payment Allocations (GAU0, 10%, $1)
        message = baseMessage + 'Payment 6';
        allocs = allocsByPmtId.get(pmts[6].Id);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[0]);
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc0, pmts[6].Id, 1, 10, gaus[0].Id, message + ' - Allocation 0');

        // Opportunity 6, Payment 7  - (null), Percent Allocation to update
        //                             Payment Allocations (GAU0, 10%, $1)
        message = baseMessage + 'Payment 7';
        allocs = allocsByPmtId.get(pmts[7].Id);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[0]);
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc0, pmts[7].Id, 1, 10, gaus[0].Id, message + ' - Allocation 0');

        // Opportunity 6, Payment 8  - $0, Percent Allocation to update, Default Allocation to remove
        //                             Payment Allocations (GAU0, 10%, $1), (Default GAU, $10)
        message = baseMessage + 'Payment 8';
        allocs = allocsByPmtId.get(pmts[8].Id);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 2, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[0]);
        alloc1 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, defaultGAU);
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc0, pmts[8].Id, 1, 10, gaus[0].Id, message + ' - Allocation 0');
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc1, pmts[8].Id, 10, null, defaultGAU.Id, message + ' - Allocation 1');

        // Opportunity 6, Payment 9  - (null), Percent Allocation to update, Default Allocation to remove
        //                             Payment Allocations (GAU0, 10%, $1), (Default GAU, $10)
        message = baseMessage + 'Payment 9';
        allocs = allocsByPmtId.get(pmts[9].Id);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 2, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[0]);
        alloc1 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, defaultGAU);
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc0, pmts[9].Id, 1, 10, gaus[0].Id, message + ' - Allocation 0');
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc1, pmts[9].Id, 10, null, defaultGAU.Id, message + ' - Allocation 1');

        // Opportunity 6, Payment 10 - $0, Needs Allocations
        message = baseMessage + 'Payment 10';
        allocs = allocsByPmtId.get(pmts[10].Id);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, null, message);

        // Opportunity 6, Payment 11 - (null), Needs Allocations
        message = baseMessage + 'Payment 11';
        allocs = allocsByPmtId.get(pmts[11].Id);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, null, message);

        // Opportunity 6, Payment 12 - $10, Invalid Allocation (no amount or percent)
        //                             Payment Allocations (GAU1)
        message = baseMessage + 'Payment 12';
        allocs = allocsByPmtId.get(pmts[12].Id);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc0, pmts[12].Id, null, null, gaus[1].Id, message + ' - Allocation 0');

        // Opportunity 7
        baseMessage = 'Before Processing - Opportunity 7 - ';
        pmts = oppsById.get(oppIds[7]).npe01__OppPayment__r;

        // Opportunity 7, Payment 0  - $10, Fully allocated
        message = baseMessage + 'Payment 0';
        allocs = allocsByPmtId.get(pmts[0].Id);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc0, pmts[0].Id, 10, 100, gaus[1].Id, message + ' - Allocation 0');
    }

     /**
     * @description Asserts that the Payment Allocations are correct after processing (called
     *              from confirmProcessRecordsUpdatesAllocationsCorrectlyWhenPaymentAllocationsAreEnabled)
     * @param allocsByPmtId A map of a list of Payment Allocations, organized by Payment Id
     * @param oppIds The Opportunity Ids used in the test, in insertion order
     * @param gaus The list of test gaus in insertion order
     * @param defaultGAU The default GAU
     */
    private static void assertPaymentAllocationsAfterProcessing(Map<Id, List<Allocation__c>> allocsByPmtId, List<Id> oppIds, List<General_Accounting_Unit__c> gaus, General_Accounting_Unit__c defaultGAU) {
        Map<Id, Opportunity> oppsById = new Map<Id, Opportunity>([SELECT    Id,
                                                                            (SELECT     Id
                                                                            FROM npe01__OppPayment__r
                                                                            ORDER BY npe01__Scheduled_Date__c ASC
                                                                            )
                                                                FROM Opportunity
                                                                WHERE Id in :oppIds]);
        // Opportunity 6
        List<npe01__OppPayment__c> pmts = oppsById.get(oppIds[6]).npe01__OppPayment__r;

        String baseMessage = 'After Processing - Opportunity 6 - ';
        String message = '';
        List<Allocation__c> allocs = null;

        Allocation__c alloc0 = null;
        Allocation__c alloc1 = null;
        Allocation__c alloc2 = null;

        // Opportunity 6, Payment 0  - No Allocations are present
        //                             Result: Payment Allocations (GAU1, 100%, $10)
        allocs = allocsByPmtId.get(pmts[0].Id);
        message = baseMessage + 'Payment 0';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc0, pmts[0].Id, 10, 100, gaus[1].Id, message + ' - Allocation 0');

        // Opportunity 6, Payment 1  - $10, Allocations Need Resizing
        //                             Payment Allocations (GAU0, 50%), (GAU1, $1). (Default GAU, $10)
        //                             Result: Payment Allocations (GAU0, 50%, $5), (GAU1, $1), (Default GAU, $4)
        message = baseMessage + 'Payment 1';
        allocs = allocsByPmtId.get(pmts[1].Id);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 3, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, defaultGAU);
        alloc1 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[0]);
        alloc2 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc0, pmts[1].Id, 4, null, defaultGAU.Id, message + ' - Allocation 0');
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc1, pmts[1].Id, 5, 50, gaus[0].Id, message + ' - Allocation 1');
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc2, pmts[1].Id, 1, null, gaus[1].Id, message + ' - Allocation 2');

        // Opportunity 6, Payment 2  - $10, Needs Default Allocation
        //                             Payment Allocations (GAU0, $1)
        //                             Result: Payment Allocations (GAU0, $1), (Default GAU, $9)
        message = baseMessage + 'Payment 2';
        allocs = allocsByPmtId.get(pmts[2].Id);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 2, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[0]);
        alloc1 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, defaultGAU);
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc0, pmts[2].Id, 1, null, gaus[0].Id, message + ' - Allocation 0');
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc1, pmts[2].Id, 9, null, defaultGAU.Id, message + ' - Allocation 1');

        // Opportunity 6, Payment 3  - $10, Remove Default Allocation Because Fully Allocated
        //                             Payment Allocations (GAU0, 100%, $10), (Default GAU, $10)
        //                             Result: Payment Allocations (GAU0, 100%, $10)
        message = baseMessage + 'Payment 3';
        allocs = allocsByPmtId.get(pmts[3].Id);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[0]);
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc0, pmts[3].Id, 10, 100, gaus[0].Id, message + ' - Allocation 0');

        // Opportunity 6, Payment 4  - $0, Default Allocation needs resizing
        //                             Payment Allocations (Default GAU, $10)
        //                             Result: Payment Allocations (Default GAU, $0)
        message = baseMessage + 'Payment 4';
        allocs = allocsByPmtId.get(pmts[4].Id);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, defaultGAU);
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc0, pmts[4].Id, 0, null, defaultGAU.Id, message + ' - Allocation 0');

        // Opportunity 6, Payment 5  - (null), Default Allocation needs to be deleted
        //                             Payment Allocations (Default GAU, $10)
        //                             Result: Allocation Deleted
        message = baseMessage + 'Payment 5';
        allocs = allocsByPmtId.get(pmts[5].Id);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, null, message);

        // Opportunity 6, Payment 6  - $0, Percent Allocation to update
        //                             Payment Allocations (GAU0, 10%, $1)
        //                             Result: Payment Allocations (GAU0, 10%, $0)
        message = baseMessage + 'Payment 6';
        allocs = allocsByPmtId.get(pmts[6].Id);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[0]);
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc0, pmts[6].Id, 0, 10, gaus[0].Id, message + ' - Allocation 0');

        // Opportunity 6, Payment 7  - (null), Percent Allocation present
        //                             Payment Allocations (GAU0, 10%, $1)
        //                             Result: Payment Allocation removed
        message = baseMessage + 'Payment 7';
        allocs = allocsByPmtId.get(pmts[7].Id);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, null, message);

        // Opportunity 6, Payment 8  - $0, Percent Allocation to update, Default Allocation to remove
        //                             Payment Allocations (GAU0, 10%, $1), (Default GAU, $10)
        //                             Result: Payment Allocations (GAU0, 10%, $0)
        message = baseMessage + 'Payment 8';
        allocs = allocsByPmtId.get(pmts[8].Id);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[0]);
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc0, pmts[8].Id, 0, 10, gaus[0].Id, message + ' - Allocation 0');

        // Opportunity 6, Payment 9  - (null), Percent Allocation to update, Default Allocation to remove
        //                             Payment Allocations (GAU0, 10%, $1), (Default GAU, $10)
        //                             Result: Payment Allocations removed
        message = baseMessage + 'Payment 9';
        allocs = allocsByPmtId.get(pmts[9].Id);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, null, message);

        // Opportunity 6, Payment 10 - $0, Needs Allocations
        //                             Result: Payment Allocations (GAU1, 100%, $0)
        message = baseMessage + 'Payment 10';
        allocs = allocsByPmtId.get(pmts[10].Id);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc0, pmts[10].Id, 0, 100, gaus[1].Id, message + ' - Allocation 0');

        // Opportunity 6, Payment 11 - (null), No allocations present
        //                             Result: No change
        message = baseMessage + 'Payment 11';
        allocs = allocsByPmtId.get(pmts[11].Id);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, null, message);

        // Opportunity 6, Payment 12 - $10, Invalid Allocation (no amount or percent)
        //                             Payment Allocations (GAU1)
        //                             Result: Error added, no change to Payment Allocations
        message = baseMessage + 'Payment 12';
        allocs = allocsByPmtId.get(pmts[12].Id);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc0, pmts[12].Id, null, null, gaus[1].Id, message + ' - Allocation 0');

        // Opportunity 7
        baseMessage = 'After Processing - Opportunity 7 - ';
        pmts = oppsById.get(oppIds[7]).npe01__OppPayment__r;

        // Opportunity 7, Payment 0  - $10, Fully allocated
        //                             Result: No change to Allocations
        message = baseMessage + 'Payment 0';
        allocs = allocsByPmtId.get(pmts[0].Id);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc0, pmts[0].Id, 10, 100, gaus[1].Id, message + ' - Allocation 0');
    }
}