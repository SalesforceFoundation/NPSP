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
     */
    @isTest
    private static void confirmProcessRecordsUpdatesAllocationsCorrectlyWhenPaymentAllocationsAreEnabled() {
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

        // Opportunity 0 - Has Recurring Donation Parent - Allocations Already Exist - No changes
        String message = baseMessage + ' - Opportunity 0';
        allocs = allocWrapper.oppsAllocations.get(oppIds[0]);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 2, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[0]);
        alloc1 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[0], 10, 50, gaus[0].Id, message + ' - Allocation 0');
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc1, oppIds[0], 10, null, gaus[1].Id, message + ' - Allocation 1');

        // Opportunity 1 - Has Recurring Donation Parent - Allocations Do Not Exist
        message = baseMessage + ' - Opportunity 1';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocWrapper.oppsAllocations.get(oppIds[1]), 0, message);

        // Opportunity 2 - No Parent - No Allocations - Allocate from Default
        message = baseMessage + ' - Opportunity 2';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocWrapper.oppsAllocations.get(oppIds[2]), 0, message);

        // Opportunity 3 -- Sum of Allocations Amount < Opportunity Amount
        message = baseMessage + ' - Opportunity 3';
        allocs = allocWrapper.oppsAllocations.get(oppIds[3]);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[3], 10, null, gaus[1].Id, message + ' - Allocation 0');

        // Opportunity 4 -- Allocation with Percent and No Amount
        message = baseMessage + ' - Opportunity 4';
        allocs = allocWrapper.oppsAllocations.get(oppIds[4]);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[4], null, 100, gaus[1].Id, message + ' - Allocation 0');

        // Opportunity 5 - Opportunity Amount = $0, With Non Zero Percent Allocations
        message = baseMessage + ' - Opportunity 5';
        allocs = allocWrapper.oppsAllocations.get(oppIds[5]);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[5], 20, 50, gaus[1].Id, message + ' - Allocation 0');

        // Opportunity 6 - Opportunity Allocation - Has Related Payment Allocations
        message = baseMessage + ' - Opportunity 6';
        allocs = allocWrapper.oppsAllocations.get(oppIds[6]);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[6], 20, 100, gaus[1].Id, message + ' - Allocation 0');

        // Opportunity 7 - Opportunity Allocated - Has Related Payment Allocations
        message = baseMessage + ' - Opportunity 7';
        allocs = allocWrapper.oppsAllocations.get(oppIds[7]);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[7], 20, 100, gaus[1].Id, message + ' - Allocation 0');

        // Opportunity 8 - Opportunity Amount = (null), Existing Default Allocation
        message = baseMessage + ' - Opportunity 8';
        allocs = allocWrapper.oppsAllocations.get(oppIds[8]);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, defaultGAU);
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[8], 20, null, defaultGAU.Id, message + ' - Allocation 0');

        // Opportunity 9 - Has Associated Campaign - Allocations Do Not Exist
        message = baseMessage + ' - Opportunity 9';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocWrapper.oppsAllocations.get(oppIds[9]), 0, message);

        // Opportunity 10 - Existing Allocations, Resize for Opportunity Amount
        message = baseMessage + ' - Opportunity 10';
        allocs = allocWrapper.oppsAllocations.get(oppIds[10]);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 2, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        alloc1 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, defaultGAU);
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[10], 40, 50, gaus[1].Id, message + ' - Allocation 0');
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc1, oppIds[10], 40, null, defaultGAU.Id, message + ' - Allocation 1');

        // Opportunity 11 -  Invalid existing fixed allocation that is too large for the Opportunity Amount
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

        // Opportunity 0 - Has Recurring Donation Parent - Allocations Already Exist - No changes
        message = baseMessage + ' - Opportunity 0';
        allocs = allocWrapper.oppsAllocations.get(oppIds[0]);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 2, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[0]);
        alloc1 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[0], 10, 50, gaus[0].Id, message + ' - Allocation 0');
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc1, oppIds[0], 10, null, gaus[1].Id, message + ' - Allocation 1');

        // Opportunity 1 - Has Recurring Donation Parent - Allocations Do Not Exist - Allocate from Recurring Donation Parent
        message = baseMessage + ' - Opportunity 1';
        allocs = allocWrapper.oppsAllocations.get(oppIds[1]);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 2, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[0]);
        alloc1 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[1], 10, 50, gaus[0].Id, message + ' - Allocation 0');
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc1, oppIds[1], 10, null, gaus[1].Id, message + ' - Allocation 1');

        // Opportunity 2 - No Parent - No Allocations - Allocate from Default
        message = baseMessage + ' - Opportunity 2';
        allocs = allocWrapper.oppsAllocations.get(oppIds[2]);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, defaultGAU);
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[2], 20, null, defaultGAU.Id, message + ' - Allocation 0');

        // Opportunity 3 - Sum of Allocation Amount < Opportunity Amount - Add Default for Remainder
        message = baseMessage + ' - Opportunity 3';
        allocs = allocWrapper.oppsAllocations.get(oppIds[3]);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 2, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        alloc1 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, defaultGAU);
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[3], 10, null, gaus[1].Id, message + ' - Allocation 0');
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc1, oppIds[3], 10, null, defaultGAU.Id, message + ' - Allocation 1');

        // Opportunity 4 - Allocation with Percent but no Amount present
        message = baseMessage + ' - Opportunity 4';
        allocs = allocWrapper.oppsAllocations.get(oppIds[4]);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[4], 20, 100, gaus[1].Id, message + ' - Allocation 0');

        // Opportunity 5 - Opportunity with Amount 9 and non zero percent Allocations
        message = baseMessage + ' - Opportunity 5';
        allocs = allocWrapper.oppsAllocations.get(oppIds[5]);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[5], 0, 50, gaus[1].Id, message + ' - Allocation 0');

        // Opportunity 6 - Opportunity Allocated Fully
        message = baseMessage + ' - Opportunity 6';
        allocs = allocWrapper.oppsAllocations.get(oppIds[6]);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[6], 20, 100, gaus[1].Id, message + ' - Allocation 0');
        System.assertEquals(true, errorsByRecordId.containsKey(oppIds[6]), message + ' - Error Record Present');

        // Opportunity 7 Allocation(s) - Opportunity Allocated Fully
        message = baseMessage + ' - Opportunity 7';
        allocs = allocWrapper.oppsAllocations.get(oppIds[7]);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[7], 20, 100, gaus[1].Id, message + ' - Allocation 0');

        // Opportunity 8 Allocation(s) - Opportunity with null Amount
        message = baseMessage + ' - Opportunity 8';
        allocs = allocWrapper.oppsAllocations.get(oppIds[8]);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 0, message);

        // Opportunity 9 - No allocations.  Parent Campaign
        message = baseMessage + ' - Opportunity 9';
        allocs = allocWrapper.oppsAllocations.get(oppIds[9]);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 2, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        alloc1 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, defaultGAU);
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[9], 10, null, gaus[1].Id, message + ' - Allocation 0');
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc1, oppIds[9], 10, null, defaultGAU.Id, message + ' - Allocation 1');

        // Opportunity 10 - Existing allocations.  Resize for Opportunity Amount Difference
        message = baseMessage + ' - Opportunity 10';
        allocs = allocWrapper.oppsAllocations.get(oppIds[10]);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 2, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        alloc1 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, defaultGAU);
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[10], 10, 50, gaus[1].Id, message + ' - Allocation 0');
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc1, oppIds[10], 10, null, defaultGAU.Id, message + ' - Allocation 1');

        // Opportunity 11 - Invalid existing fixed allocation that is too large for the Opportunity Amount
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

        // Opportunity 0 - Has Recurring Donation Parent - Allocations Already Exist - No changes
        String message = baseMessage + ' - Opportunity 0';
        allocs = allocWrapper.oppsAllocations.get(oppIds[0]);
        ALLO_UnitTestHelper_Test.assertSObjectList(allocs, 2, message);
        alloc0 = ALLO_UnitTestHelper_Test.findByGAU(allocs, gaus[0]);
        alloc1 = ALLO_UnitTestHelper_Test.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_Test.assertOpportunityAllocation(alloc0, oppIds[0], 10, 50, gaus[0].Id, message + ' - Allocation 0');
        ALLO_UnitTestHelper_Test.assertOpportunityAllocation(alloc1, oppIds[0], 10, null, gaus[1].Id, message + ' - Allocation 1');

        // Opportunity 1 - Has Recurring Donation Parent - Allocations Do Not Exist
         message = baseMessage + ' - Opportunity 1';
         ALLO_UnitTestHelper_Test.assertSObjectList(allocWrapper.oppsAllocations.get(oppIds[1]), 0, message);

        // Opportunity 2 - No Parent - No Allocations - Allocate from Default
        message = baseMessage + ' - Opportunity 2';
        ALLO_UnitTestHelper_Test.assertSObjectList(allocWrapper.oppsAllocations.get(oppIds[2]), 0, message);

        // Opportunity 3 -- Sum of Allocations Amount < Opportunity Amount
        message = baseMessage + ' - Opportunity 3';
        allocs = allocWrapper.oppsAllocations.get(oppIds[3]);
        ALLO_UnitTestHelper_Test.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_Test.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_Test.assertOpportunityAllocation(alloc0, oppIds[3], 10, null, gaus[1].Id, message + ' - Allocation 0');

        // Opportunity 4 -- Allocation with Percent and No Amount
        message = baseMessage + ' - Opportunity 4';
        allocs = allocWrapper.oppsAllocations.get(oppIds[4]);
        ALLO_UnitTestHelper_Test.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_Test.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_Test.assertOpportunityAllocation(alloc0, oppIds[4], null, 100, gaus[1].Id, message + ' - Allocation 0');

        // Opportunity 5 - Opportunity Amount = $0, With Non Zero Percent Allocations
        message = baseMessage + ' - Opportunity 5';
        allocs = allocWrapper.oppsAllocations.get(oppIds[5]);
        ALLO_UnitTestHelper_Test.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_Test.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_Test.assertOpportunityAllocation(alloc0, oppIds[5], 20, 50, gaus[1].Id, message + ' - Allocation 0');

        // Opportunity 6 - Opportunity Allocation - Has Related Payment Allocations
        message = baseMessage + ' - Opportunity 6';
        allocs = allocWrapper.oppsAllocations.get(oppIds[6]);
        ALLO_UnitTestHelper_Test.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_Test.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_Test.assertOpportunityAllocation(alloc0, oppIds[6], 20, 100, gaus[1].Id, message + ' - Allocation 0');

        // Opportunity 7 - Opportunity Allocated - Has Related Payment Allocations
        message = baseMessage + ' - Opportunity 7';
        allocs = allocWrapper.oppsAllocations.get(oppIds[7]);
        ALLO_UnitTestHelper_Test.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_Test.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_Test.assertOpportunityAllocation(alloc0, oppIds[7], 20, 100, gaus[1].Id, message + ' - Allocation 0');

        // Opportunity 8 - Opportunity Amount = (null), Existing Default Allocation
        message = baseMessage + ' - Opportunity 8';
        allocs = allocWrapper.oppsAllocations.get(oppIds[8]);
        ALLO_UnitTestHelper_Test.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_Test.findByGAU(allocs, gaus[2]);
        ALLO_UnitTestHelper_Test.assertOpportunityAllocation(alloc0, oppIds[8], 20, 100, gaus[2].Id, message + ' - Allocation 0');

        // Opportunity 9 - Has Associated Campaign - Allocations Do Not Exist
        message = baseMessage + ' - Opportunity 9';
        ALLO_UnitTestHelper_Test.assertSObjectList(allocWrapper.oppsAllocations.get(oppIds[9]), 0, message);

        // Opportunity 10 - Existing Allocations, Resize for Opportunity Amount
        message = baseMessage + ' - Opportunity 10';
        allocs = allocWrapper.oppsAllocations.get(oppIds[10]);
        ALLO_UnitTestHelper_Test.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_Test.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_Test.assertOpportunityAllocation(alloc0, oppIds[10], 40, 50, gaus[1].Id, message + ' - Allocation 0');

        // Opportunity 11 -  Invalid existing fixed allocation that is too large for the Opportunity Amount
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

        // Opportunity 0 - Has Recurring Donation Parent - Allocations Already Exist - No changes
        message = baseMessage + ' - Opportunity 0';
        allocs = allocWrapper.oppsAllocations.get(oppIds[0]);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 2, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[0]);
        alloc1 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[0], 10, 50, gaus[0].Id, message + ' - Allocation 0');
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc1, oppIds[0], 10, null, gaus[1].Id, message + ' - Allocation 1');

        // Opportunity 1 - Has Recurring Donation Parent - Allocations Do Not Exist - Allocate from Recurring Donation Parent
        message = baseMessage + ' - Opportunity 1';
        allocs = allocWrapper.oppsAllocations.get(oppIds[1]);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 2, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[0]);
        alloc1 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[1], 10, 50, gaus[0].Id, message + ' - Allocation 0');
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc1, oppIds[1], 10, null, gaus[1].Id, message + ' - Allocation 1');

        // Opportunity 2 - No Parent - No Allocations
        message = baseMessage + ' - Opportunity 2';
        allocs = allocWrapper.oppsAllocations.get(oppIds[2]);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 0, message);

        // Opportunity 3 - Sum of Allocation Amount < Opportunity Amount
        message = baseMessage + ' - Opportunity 3';
        allocs = allocWrapper.oppsAllocations.get(oppIds[3]);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[3], 10, null, gaus[1].Id, message + ' - Allocation 0');

        // Opportunity 4 - Allocation with Percent but no Amount present
        message = baseMessage + ' - Opportunity 4';
        allocs = allocWrapper.oppsAllocations.get(oppIds[4]);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[4], 20, 100, gaus[1].Id, message + ' - Allocation 0');

        // Opportunity 5 - Opportunity with Amount 9 and non zero percent Allocations
        message = baseMessage + ' - Opportunity 5';
        allocs = allocWrapper.oppsAllocations.get(oppIds[5]);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[5], 0, 50, gaus[1].Id, message + ' - Allocation 0');

        // Opportunity 6 - Opportunity Allocated Fully
        message = baseMessage + ' - Opportunity 6';
        allocs = allocWrapper.oppsAllocations.get(oppIds[6]);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[6], 20, 100, gaus[1].Id, message + ' - Allocation 0');

        // Opportunity 7 Allocation(s) - Opportunity Allocated Fully
        message = baseMessage + ' - Opportunity 7';
        allocs = allocWrapper.oppsAllocations.get(oppIds[7]);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[7], 20, 100, gaus[1].Id, message + ' - Allocation 0');

        // Opportunity 8 Allocation(s) - Opportunity with null Amount
        message = baseMessage + ' - Opportunity 8';
        allocs = allocWrapper.oppsAllocations.get(oppIds[8]);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 0, message);

        // Opportunity 9 - No allocations.  Parent Campaign
        message = baseMessage + ' - Opportunity 9';
        allocs = allocWrapper.oppsAllocations.get(oppIds[9]);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[9], 10, null, gaus[1].Id, message + ' - Allocation 0');

        // Opportunity 10 - Existing allocations.  Resize for Opportunity Amount Difference
        message = baseMessage + ' - Opportunity 10';
        allocs = allocWrapper.oppsAllocations.get(oppIds[10]);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[10], 10, 50, gaus[1].Id, message + ' - Allocation 0');

        // Opportunity 11 - Invalid existing fixed allocation that is too large for the Opportunity Amount
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

        // Opportunity 6 - Payment 0 - No Allocations Yes
        allocs = allocsByPmtId.get(pmts[0].Id);
        message = baseMessage + 'Payment 0';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, null, message);

        // Opportunity 6 - Payment 1 - Payment Allocations, Default Allocation for $10 (Default), Percent Allocation for 50% (GAU0), Fixed for $1 (GAU1)
        message = baseMessage + 'Payment 1';
        allocs = allocsByPmtId.get(pmts[1].Id);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 3, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, defaultGAU);
        alloc1 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[0]);
        alloc2 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc0, pmts[1].Id, 10, null, defaultGAU.Id, message + ' - Allocation 0');
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc1, pmts[1].Id, null, 50, gaus[0].Id, message + ' - Allocation 1');
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc2, pmts[1].Id, 1, null, gaus[1].Id, message + ' - Allocation 2');

        // Opportunity 6 - Payment 2 - Payment Allocations, Fixed Amount Allocation for $1, GAU0
        message = baseMessage + 'Payment 2';
        allocs = allocsByPmtId.get(pmts[2].Id);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[0]);
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc0, pmts[2].Id, 1, null, gaus[0].Id, message + ' - Allocation 0');

        // Opportunity 6 - Payment 3 - Payment Allocations, 100% Allocation for GAU0, Default Allocation for $10
        message = baseMessage + 'Payment 3';
        allocs = allocsByPmtId.get(pmts[3].Id);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 2, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[0]);
        alloc1 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, defaultGAU);
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc0, pmts[3].Id, 10, 100, gaus[0].Id, message + ' - Allocation 0');
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc1, pmts[3].Id, 10, null, defaultGAU.Id, message + ' - Allocation 1');

        // Opportunity 6 - Payment 4 - Payment Allocations, Default Allocation for $10
        message = baseMessage + 'Payment 4';
        allocs = allocsByPmtId.get(pmts[4].Id);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, defaultGAU);
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc0, pmts[4].Id, 10, null, defaultGAU.Id, message + ' - Allocation 0');

        // Opportunity 6 - Payment 5 - Payment Allocations, Default Allocation for $10
        message = baseMessage + 'Payment 5';
        allocs = allocsByPmtId.get(pmts[5].Id);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, defaultGAU);
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc0, pmts[5].Id, 10, null, defaultGAU.Id, message + ' - Allocation 0');

        // Opportunity 6 - Payment 6, Amount $0 - Payment Allocations, 10% Allocation for GAU 0
        message = baseMessage + 'Payment 6';
        allocs = allocsByPmtId.get(pmts[6].Id);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[0]);
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc0, pmts[6].Id, 1, 10, gaus[0].Id, message + ' - Allocation 0');

        // Opportunity 6 - Payment 7, Amount (null) - Payment Allocations, 10% Allocation for GAU 0
        message = baseMessage + 'Payment 7';
        allocs = allocsByPmtId.get(pmts[7].Id);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[0]);
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc0, pmts[7].Id, 1, 10, gaus[0].Id, message + ' - Allocation 0');

        // Opportunity 6 - Payment 8, Amount $0 - Payment Allocations, 10% Allocation for GAU 0, $10 for Default GAU
        message = baseMessage + 'Payment 8';
        allocs = allocsByPmtId.get(pmts[8].Id);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 2, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[0]);
        alloc1 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, defaultGAU);
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc0, pmts[8].Id, 1, 10, gaus[0].Id, message + ' - Allocation 0');
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc1, pmts[8].Id, 10, null, defaultGAU.Id, message + ' - Allocation 1');

        // Opportunity 6 - Payment 9, Amount (null) - Payment Allocations, 10% Allocation for GAU 0, $10 for Default GAU
        message = baseMessage + 'Payment 9';
        allocs = allocsByPmtId.get(pmts[9].Id);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 2, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[0]);
        alloc1 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, defaultGAU);
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc0, pmts[9].Id, 1, 10, gaus[0].Id, message + ' - Allocation 0');
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc1, pmts[9].Id, 10, null, defaultGAU.Id, message + ' - Allocation 1');

        // Opportunity 6 - Payment 10, Amount $0 - Payment Allocations, 10% Allocation for GAU 0, $10 for Default GAU
        message = baseMessage + 'Payment 10';
        allocs = allocsByPmtId.get(pmts[10].Id);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, null, message);

        // Opportunity 6 - Payment 11, Amount (null) - Payment Allocations, 10% Allocation for GAU 0, $10 for Default GAU
        message = baseMessage + 'Payment 11';
        allocs = allocsByPmtId.get(pmts[11].Id);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, null, message);

        // Opportunity 6 - Payment 12, Amount ($10) - No Amount or Percent, GAU 1
        message = baseMessage + 'Payment 12';
        allocs = allocsByPmtId.get(pmts[12].Id);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc0, pmts[12].Id, null, null, gaus[1].Id, message + ' - Allocation 0');

        // Opportunity 7
        baseMessage = 'Before Processing - Opportunity 7 - ';
        pmts = oppsById.get(oppIds[7]).npe01__OppPayment__r;

        // Opportunity 7 - Payment 0, Amount ($10) - No Amount or Percent, GAU 1
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

        // Opportunity 6 - Payment 0 - Added from Parent
        allocs = allocsByPmtId.get(pmts[0].Id);
        message = baseMessage + 'Payment 0';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc0, pmts[0].Id, 10, 100, gaus[1].Id, message + ' - Allocation 0');

        // Opportunity 6 - Payment 1 - Payment Allocations, Default Allocation for $4 (Default), Percent Allocation for 50% (GAU0), Fixed for $1 (GAU1)
        message = baseMessage + 'Payment 1';
        allocs = allocsByPmtId.get(pmts[1].Id);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 3, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, defaultGAU);
        alloc1 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[0]);
        alloc2 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc0, pmts[1].Id, 4, null, defaultGAU.Id, message + ' - Allocation 0');
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc1, pmts[1].Id, 5, 50, gaus[0].Id, message + ' - Allocation 1');
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc2, pmts[1].Id, 1, null, gaus[1].Id, message + ' - Allocation 2');

        // Opportunity 6 - Payment 2 - Payment Allocations, Fixed Amount Allocation for $1, GAU0, Default Allocation for $9
        message = baseMessage + 'Payment 2';
        allocs = allocsByPmtId.get(pmts[2].Id);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 2, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[0]);
        alloc1 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, defaultGAU);
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc0, pmts[2].Id, 1, null, gaus[0].Id, message + ' - Allocation 0');
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc1, pmts[2].Id, 9, null, defaultGAU.Id, message + ' - Allocation 1');

        // Opportunity 6 - Payment 3 - Payment Allocations, 100% Allocation for GAU0
        message = baseMessage + 'Payment 3';
        allocs = allocsByPmtId.get(pmts[3].Id);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[0]);
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc0, pmts[3].Id, 10, 100, gaus[0].Id, message + ' - Allocation 0');

        // Opportunity 6 - Payment 4 - Payment Allocations, Default Allocation for $0
        message = baseMessage + 'Payment 4';
        allocs = allocsByPmtId.get(pmts[4].Id);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, defaultGAU);
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc0, pmts[4].Id, 0, null, defaultGAU.Id, message + ' - Allocation 0');

        // Opportunity 6 - Payment 5 - Payment Allocations, Default Allocation for $0
        message = baseMessage + 'Payment 5';
        allocs = allocsByPmtId.get(pmts[5].Id);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, defaultGAU);
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc0, pmts[5].Id, 0, null, defaultGAU.Id, message + ' - Allocation 0');

        // Opportunity 6 - Payment 6, Amount $0 - Payment Allocations, 10% Allocation for GAU 0
        message = baseMessage + 'Payment 6';
        allocs = allocsByPmtId.get(pmts[6].Id);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[0]);
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc0, pmts[6].Id, 0, 10, gaus[0].Id, message + ' - Allocation 0');

        // Opportunity 6 - Payment 7, Amount (null) - Payment Allocations, 10% Allocation for GAU 0
        message = baseMessage + 'Payment 7';
        allocs = allocsByPmtId.get(pmts[7].Id);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[0]);
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc0, pmts[7].Id, 0, 10, gaus[0].Id, message + ' - Allocation 0');

        // Opportunity 6 - Payment 8, Amoount $0 - Payment Allocations, 10% Allocation for GAU 0
        message = baseMessage + 'Payment 8';
        allocs = allocsByPmtId.get(pmts[8].Id);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[0]);
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc0, pmts[8].Id, 0, 10, gaus[0].Id, message + ' - Allocation 0');

        // Opportunity 6 - Payment 9, Amoount (null) - Payment Allocations, 10% Allocation for GAU 0, $10 for Default GAU
        message = baseMessage + 'Payment 9';
        allocs = allocsByPmtId.get(pmts[9].Id);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[0]);
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc0, pmts[9].Id, 0, 10, gaus[0].Id, message + ' - Allocation 0');

        // Opportunity 6 - Payment 10, Amoount $0 - Payment Allocations, 100% Allocation for GAU 1
        message = baseMessage + 'Payment 10';
        allocs = allocsByPmtId.get(pmts[10].Id);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc0, pmts[10].Id, 0, 100, gaus[1].Id, message + ' - Allocation 0');

        // Opportunity 6 - Payment 11, Amoount (null) - Payment Allocations, 100% Allocation for GAU 1
        message = baseMessage + 'Payment 11';
        allocs = allocsByPmtId.get(pmts[11].Id);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc0, pmts[11].Id, 0, 100, gaus[1].Id, message + ' - Allocation 0');

        // Opportunity 6 - Payment 12, Amoount ($10) - No Amount or Percent, GAU 1
        message = baseMessage + 'Payment 12';
        allocs = allocsByPmtId.get(pmts[12].Id);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc0, pmts[12].Id, null, null, gaus[1].Id, message + ' - Allocation 0');

        // Opportunity 7
        baseMessage = 'After Processing - Opportunity 7 - ';
        pmts = oppsById.get(oppIds[7]).npe01__OppPayment__r;

        // Opportunity 7 - Payment 0, Amoount ($10) - No Amount or Percent, GAU 1
        message = baseMessage + 'Payment 0';
        allocs = allocsByPmtId.get(pmts[0].Id);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 1, message);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc0, pmts[0].Id, 10, 100, gaus[1].Id, message + ' - Allocation 0');
    }
}