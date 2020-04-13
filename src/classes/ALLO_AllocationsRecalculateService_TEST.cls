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
* @description Tests for ALLO_AllocationsRecalculateService class
*/
@IsTest(isParallel=true)
public class ALLO_AllocationsRecalculateService_TEST {

     /**
     * @description Confirm Recalculate Service creates correct DML changes when
     *              Default Allocations Enabled
     *              Payment Allocations Disabled
     *              [ALLO_AllocationsRecalculateService.processOpportunityAllocations]
     */
    @isTest
    private static void confirmProcessOpportunityAllocationsCreatesCorrectPendingDMLChangesWhenDefaultAllocationsEnabledPaymentAllocationsDisabled() {
        ALLO_UnitTestHelper_TEST.AllocationSetupTest alloSetupTest = new ALLO_UnitTestHelper_TEST.AllocationSetupTest()
            .enableDefaultAllocations()
            .disableAllocationTriggers()
            .applyConfiguration();

        List<Id> oppIds = ALLO_UnitTestHelper_TEST.createTestDataAndReturnOppIds(alloSetupTest);

        Set<Id> oppIdsAsSet = new Set<Id>();
        oppIdsAsSet.addAll(oppIds);

        ALLO_AllocationsWrapper allocWrapper = new ALLO_AllocationsRetrievalService()
                                                .withOpportunities(oppIdsAsSet)
                                                .retrieveData()
                                                .allocationsWrapper;

        ALLO_AllocationsReviewService allocReviewSvc = new ALLO_AllocationsReviewService()
                                                            .withAllocationsWrapper(allocWrapper);

        Set<Id> oppIdsForReview = allocReviewSvc.evaluateAllocations();

        allocWrapper.filterTo(oppIdsForReview);

        ALLO_AllocationsRecalculateService allocRecalcSvc = new ALLO_AllocationsRecalculateService()
                                                                .withAllocationsWrapper(allocWrapper);

        ALLO_UnitTestHelper_TEST.assertSObjectList(allocWrapper.allocationsForDelete, 0, 'Before Recalculate - Delete List');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocWrapper.allocationsForInsert, 0, 'Before Recalculate - Insert List');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocWrapper.allocationsForUpdate, 0, 'Before Recalculate - Update List');

        allocRecalcSvc.processOpportunityAllocations();

        ALLO_UnitTestHelper_TEST.assertSObjectList(allocWrapper.allocationsForDelete, 1, 'After Recalculate - Delete List');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocWrapper.allocationsForInsert, 8, 'After Recalculate - Insert List');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocWrapper.allocationsForUpdate, 4, 'After Recalculate - Update List');

        Map<Id, List<Allocation__c>> allocsForDeleteByOppId = ALLO_UnitTestHelper_TEST.buildMapOfAllocationsByOpportunityId(allocWrapper.allocationsForDelete);
        Map<Id, List<Allocation__c>> allocsForInsertByOppId = ALLO_UnitTestHelper_TEST.buildMapOfAllocationsByOpportunityId(allocWrapper.allocationsForInsert);
        Map<Id, List<Allocation__c>> allocsForUpdateByOppId = ALLO_UnitTestHelper_TEST.buildMapOfAllocationsByOpportunityId(allocWrapper.allocationsForUpdate);

        List<Allocation__c> allocs = null;
        String message = '';
        Allocation__c alloc0 = null;
        Allocation__c alloc1 = null;
        List<General_Accounting_Unit__c> gaus = alloSetupTest.getGAUs();
        General_Accounting_Unit__c defaultGAU = alloSetupTest.getDefaultGAU();

        // Opportunity 0
        message = 'Opportunity 0 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByOppId.get(oppIds[0]), null, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByOppId.get(oppIds[0]), null, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByOppId.get(oppIds[0]), null, message + 'Allocations - Delete');

        // Opportunity 1
        message = 'Opportunity 1 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByOppId.get(oppIds[1]), 2, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByOppId.get(oppIds[1]), null, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByOppId.get(oppIds[1]), null, message + 'Allocations - Delete');
        allocs = allocsForInsertByOppId.get(oppIds[1]);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[0]);
        alloc1 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[1], 10, 50, gaus[0].Id, message + 'Insert - Allocation 0');
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc1, oppIds[1], 10, null, gaus[1].Id, message + 'Insert - Allocation 1');

        // Opportunity 2
        message = 'Opportunity 2 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByOppId.get(oppIds[2]), 1, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByOppId.get(oppIds[2]), null, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByOppId.get(oppIds[2]), null, message + 'Allocations - Delete');
        allocs = allocsForInsertByOppId.get(oppIds[2]);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, defaultGAU);
        alloc1 = null;
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[2], 20, null, defaultGAU.Id, message + 'Insert - Allocation 0');

        // Opportunity 3
        message = 'Opportunity 3 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByOppId.get(oppIds[3]), 1, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByOppId.get(oppIds[3]), null, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByOppId.get(oppIds[3]), null, message + 'Allocations - Delete');
        allocs = allocsForInsertByOppId.get(oppIds[3]);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, defaultGAU);
        alloc1 = null;
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[3], 10, null, defaultGAU.Id, message + 'Insert - Allocation 0');

        // Opportunity 4
        message = 'Opportunity 4 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByOppId.get(oppIds[4]), null, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByOppId.get(oppIds[4]), 1, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByOppId.get(oppIds[4]), null, message + 'Allocations - Delete');
        allocs = allocsForUpdateByOppId.get(oppIds[4]);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        alloc1 = null;
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[4], 20, 100, gaus[1].Id, message + 'Update - Allocation 0');

        // Opportunity 5
        message = 'Opportunity 5 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByOppId.get(oppIds[5]), null, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByOppId.get(oppIds[5]), 1, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByOppId.get(oppIds[5]), null, message + 'Allocations - Delete');
        allocs = allocsForUpdateByOppId.get(oppIds[5]);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        alloc1 = null;
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[5], 0, 50, gaus[1].Id, message + 'Update - Allocation 0');

        // Opportunity 6 --No changes
        message = 'Opportunity 6 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByOppId.get(oppIds[6]), null, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByOppId.get(oppIds[6]), null, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByOppId.get(oppIds[6]), null, message + 'Allocations - Delete');

        // Opportunity 7 -- No changes
        message = 'Opportunity 7 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByOppId.get(oppIds[7]), null, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByOppId.get(oppIds[7]), null, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByOppId.get(oppIds[7]), null, message + 'Allocations - Delete');

        // Opportunity 8
        message ='Opportunity 8 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByOppId.get(oppIds[8]), null, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByOppId.get(oppIds[8]), null, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByOppId.get(oppIds[8]), 1, message + 'Allocations - Delete');
        allocs = allocsForDeleteByOppId.get(oppIds[8]);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, defaultGAU);
        alloc1 = null;
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[8], 20, null, alloSetupTest.getDefaultGAU().Id, message + 'Delete - Allocation 0');

        // Opportunity 9
        message = 'Opportunity 9 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByOppId.get(oppIds[9]), 2, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByOppId.get(oppIds[9]), null, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByOppId.get(oppIds[9]), null, message + 'Allocations - Delete');
        allocs = allocsForInsertByOppId.get(oppIds[9]);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        alloc1 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, defaultGAU);
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[9], 10, null, gaus[1].Id, message + 'Insert - Allocation 0');
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc1, oppIds[9], 10, null, defaultGAU.Id, message + 'Insert - Allocation 1');

        // Opportunity 10
        message = 'Opportunity 10 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByOppId.get(oppIds[10]), null, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByOppId.get(oppIds[10]), 2, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByOppId.get(oppIds[10]), null, message + 'Allocations - Delete');
        allocs = allocsForUpdateByOppId.get(oppIds[10]);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        alloc1 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, defaultGAU);
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[10], 10, 50, gaus[1].Id, message + 'Update - Allocation 0');
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc1, oppIds[10], 10, null, defaultGAU.Id, message + 'Update - Allocation 1');

        // Opportunity 11
        message = 'Opportunity 11 - ';
        System.assertEquals(true, allocWrapper.errorsByRecordId.containsKey(oppIds[11]), message + 'Has Errors');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByOppId.get(oppIds[11]), null, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByOppId.get(oppIds[11]), null, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByOppId.get(oppIds[11]), null, message + 'Allocations - Delete');

        // Opportunity 12
        message = 'Opportunity 12 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByOppId.get(oppIds[12]), 1, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByOppId.get(oppIds[12]), null, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByOppId.get(oppIds[12]), null, message + 'Allocations - Delete');
        allocs = allocsForInsertByOppId.get(oppIds[12]);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, defaultGAU);
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[12], 0, null, defaultGAU.Id, message + 'Insert - Allocation 0');

        // Opportunity 13
        message = 'Opportunity 13 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByOppId.get(oppIds[13]), 1, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByOppId.get(oppIds[13]), null, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByOppId.get(oppIds[13]), null, message + 'Allocations - Delete');
        allocs = allocsForInsertByOppId.get(oppIds[13]);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, defaultGAU);
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[13], 20, null, defaultGAU.Id, message + 'Insert - Allocation 0');
    }

     /**
     * @description Confirm Recalculate Service creates correct DML changes when
     *              Default Allocations Disabled
     *              Payment Allocations Disabled
     *              [ALLO_AllocationsRecalculateService.processOpportunityAllocations]
     */
    @isTest
    private static void confirmProcessOpportunityAllocationsCreatesCorrectPendingDMLChangesWhenDefaultAllocationsDisabledPaymentAllocationsDisabled() {
        ALLO_UnitTestHelper_TEST.AllocationSetupTest alloSetupTest = new ALLO_UnitTestHelper_TEST.AllocationSetupTest()
            .disableAllocationTriggers()
            .applyConfiguration();

        List<Id> oppIds = ALLO_UnitTestHelper_TEST.createTestDataAndReturnOppIds(alloSetupTest);

        Set<Id> oppIdsAsSet = new Set<Id>();
        oppIdsAsSet.addAll(oppIds);

        ALLO_AllocationsWrapper allocWrapper = new ALLO_AllocationsRetrievalService()
                                                .withOpportunities(oppIdsAsSet)
                                                .retrieveData()
                                                .allocationsWrapper;

        ALLO_AllocationsReviewService allocReviewSvc = new ALLO_AllocationsReviewService()
                                                            .withAllocationsWrapper(allocWrapper);

        Set<Id> oppIdsForReview = allocReviewSvc.evaluateAllocations();

        allocWrapper.filterTo(oppIdsForReview);

        ALLO_AllocationsRecalculateService allocRecalcSvc = new ALLO_AllocationsRecalculateService()
                                                                .withAllocationsWrapper(allocWrapper);

        ALLO_UnitTestHelper_TEST.assertSObjectList(allocWrapper.allocationsForDelete, 0, 'Before Recalculate - Delete List');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocWrapper.allocationsForInsert, 0, 'Before Recalculate - Insert List');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocWrapper.allocationsForUpdate, 0, 'Before Recalculate - Update List');

        allocRecalcSvc.processOpportunityAllocations();

        ALLO_UnitTestHelper_TEST.assertSObjectList(allocWrapper.allocationsForDelete, 1, 'After Recalculate - Delete List');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocWrapper.allocationsForInsert, 3, 'After Recalculate - Insert List');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocWrapper.allocationsForUpdate, 3, 'After Recalculate - Update List');

        Map<Id, List<Allocation__c>> allocsForDeleteByOppId = ALLO_UnitTestHelper_TEST.buildMapOfAllocationsByOpportunityId(allocWrapper.allocationsForDelete);
        Map<Id, List<Allocation__c>> allocsForInsertByOppId = ALLO_UnitTestHelper_TEST.buildMapOfAllocationsByOpportunityId(allocWrapper.allocationsForInsert);
        Map<Id, List<Allocation__c>> allocsForUpdateByOppId = ALLO_UnitTestHelper_TEST.buildMapOfAllocationsByOpportunityId(allocWrapper.allocationsForUpdate);

        List<Allocation__c> allocs = null;
        String message = '';
        Allocation__c alloc0 = null;
        Allocation__c alloc1 = null;
        List<General_Accounting_Unit__c> gaus = alloSetupTest.getGAUs();
        General_Accounting_Unit__c defaultGAU = alloSetupTest.getDefaultGAU();

        // Opportunity 0
        message = 'Opportunity 0 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByOppId.get(oppIds[0]), null, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByOppId.get(oppIds[0]), null, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByOppId.get(oppIds[0]), null, message + 'Allocations - Delete');

        // Opportunity 1
        message = 'Opportunity 1 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByOppId.get(oppIds[1]), 2, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByOppId.get(oppIds[1]), null, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByOppId.get(oppIds[1]), null, message + 'Allocations - Delete');
        allocs = allocsForInsertByOppId.get(oppIds[1]);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[0]);
        alloc1 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[1], 10, 50, gaus[0].Id, message + 'Insert - Allocation 0');
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc1, oppIds[1], 10, null, gaus[1].Id, message + 'Insert - Allocation 1');

        // Opportunity 2
        message = 'Opportunity 2 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByOppId.get(oppIds[2]), null, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByOppId.get(oppIds[2]), null, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByOppId.get(oppIds[2]), null, message + 'Allocations - Delete');

        // Opportunity 3
        message = 'Opportunity 3 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByOppId.get(oppIds[3]), null, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByOppId.get(oppIds[3]), null, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByOppId.get(oppIds[3]), null, message + 'Allocations - Delete');

        // Opportunity 4
        message = 'Opportunity 4 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByOppId.get(oppIds[4]), null, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByOppId.get(oppIds[4]), 1, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByOppId.get(oppIds[4]), null, message + 'Allocations - Delete');
        allocs = allocsForUpdateByOppId.get(oppIds[4]);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        alloc1 = null;
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[4], 20, 100, gaus[1].Id, message + 'Update - Allocation 0');

        // Opportunity 5
        message = 'Opportunity 5 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByOppId.get(oppIds[5]), null, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByOppId.get(oppIds[5]), 1, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByOppId.get(oppIds[5]), null, message + 'Allocations - Delete');
        allocs = allocsForUpdateByOppId.get(oppIds[5]);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        alloc1 = null;
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[5], 0, 50, gaus[1].Id, message + 'Update - Allocation 0');

        // Opportunity 6 --No changes
        message = 'Opportunity 6 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByOppId.get(oppIds[6]), null, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByOppId.get(oppIds[6]), null, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByOppId.get(oppIds[6]), null, message + 'Allocations - Delete');

        // Opportunity 7 -- No changes
        message = 'Opportunity 7 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByOppId.get(oppIds[7]), null, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByOppId.get(oppIds[7]), null, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByOppId.get(oppIds[7]), null, message + 'Allocations - Delete');

        // Opportunity 8
        message ='Opportunity 8 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByOppId.get(oppIds[8]), null, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByOppId.get(oppIds[8]), null, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByOppId.get(oppIds[8]), 1, message + 'Allocations - Delete');
        allocs = allocsForDeleteByOppId.get(oppIds[8]);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[2]);
        alloc1 = null;
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[8], 20, 100, gaus[2].Id, message + 'Delete - Allocation 0');

        // Opportunity 9
        message = 'Opportunity 9 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByOppId.get(oppIds[9]), 1, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByOppId.get(oppIds[9]), null, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByOppId.get(oppIds[9]), null, message + 'Allocations - Delete');
        allocs = allocsForInsertByOppId.get(oppIds[9]);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        alloc1 = null;
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[9], 10, null, gaus[1].Id, message + 'Insert - Allocation 0');

        // Opportunity 10
        message = 'Opportunity 10 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByOppId.get(oppIds[10]), null, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByOppId.get(oppIds[10]), 1, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByOppId.get(oppIds[10]), null, message + 'Allocations - Delete');
        allocs = allocsForUpdateByOppId.get(oppIds[10]);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        alloc1 = null;
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[10], 10, 50, gaus[1].Id, message + 'Update - Allocation 0');

        // Opportunity 11
        message = 'Opportunity 11 - ';
        System.assertEquals(true, allocWrapper.errorsByRecordId.containsKey(oppIds[11]), message + 'Has Errors');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByOppId.get(oppIds[11]), null, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByOppId.get(oppIds[11]), null, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByOppId.get(oppIds[11]), null, message + 'Allocations - Delete');

        // Opportunity 12
        message = 'Opportunity 12 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByOppId.get(oppIds[12]), null, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByOppId.get(oppIds[12]), null, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByOppId.get(oppIds[12]), null, message + 'Allocations - Delete');

        // Opportunity 13
        message = 'Opportunity 13 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByOppId.get(oppIds[13]), null, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByOppId.get(oppIds[13]), null, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByOppId.get(oppIds[13]), null, message + 'Allocations - Delete');
    }

    /**
     * @description Confirm Recalculate Service creates correct DML changes when
     *              Default Allocations Enabled
     *              Payment Allocations Enabled
     *              [ALLO_AllocationsRecalculateService.processPaymentAllocations]
     */
    @isTest
    private static void confirmProcessOpportunityAndPaymentAllocationsCreatesCorrectPendingDMLChangesWhenDefaultAllocationsEnabledPaymentAllocationsEnabled() {
        ALLO_UnitTestHelper_TEST.AllocationSetupTest alloSetupTest = new ALLO_UnitTestHelper_TEST.AllocationSetupTest()
            .enableDefaultAllocations()
            .enablePaymentAllocations()
            .disableAllocationTriggers()
            .applyConfiguration();

        List<Id> oppIds = ALLO_UnitTestHelper_TEST.createTestDataAndReturnOppIds(alloSetupTest);

        Set<Id> oppIdsAsSet = new Set<Id>();
        oppIdsAsSet.addAll(oppIds);

        ALLO_AllocationsWrapper allocWrapper = new ALLO_AllocationsRetrievalService()
                                                .withOpportunities(oppIdsAsSet)
                                                .retrieveData()
                                                .allocationsWrapper;

        ALLO_AllocationsReviewService allocReviewSvc = new ALLO_AllocationsReviewService()
                                                            .withAllocationsWrapper(allocWrapper);

        Set<Id> oppIdsForReview = allocReviewSvc.evaluateAllocations();

        allocWrapper.filterTo(oppIdsForReview);

        ALLO_AllocationsRecalculateService allocRecalcSvc = new ALLO_AllocationsRecalculateService()
                                                                .withAllocationsWrapper(allocWrapper);

        ALLO_UnitTestHelper_TEST.assertSObjectList(allocWrapper.allocationsForDelete, 0, 'Before Recalculate - Delete List');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocWrapper.allocationsForInsert, 0, 'Before Recalculate - Insert List');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocWrapper.allocationsForUpdate, 0, 'Before Recalculate - Update List');

        allocRecalcSvc.processOpportunityAllocations();

        ALLO_UnitTestHelper_TEST.assertSObjectList(allocWrapper.allocationsForDelete, 1, 'After Recalculate - Delete List');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocWrapper.allocationsForInsert, 8, 'After Recalculate - Insert List');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocWrapper.allocationsForUpdate, 4, 'After Recalculate - Update List');

        Map<Id, List<Allocation__c>> allocsForDeleteByOppId = ALLO_UnitTestHelper_TEST.buildMapOfAllocationsByOpportunityId(allocWrapper.allocationsForDelete);
        Map<Id, List<Allocation__c>> allocsForInsertByOppId = ALLO_UnitTestHelper_TEST.buildMapOfAllocationsByOpportunityId(allocWrapper.allocationsForInsert);
        Map<Id, List<Allocation__c>> allocsForUpdateByOppId = ALLO_UnitTestHelper_TEST.buildMapOfAllocationsByOpportunityId(allocWrapper.allocationsForUpdate);

        List<Allocation__c> allocs = null;
        String message = '';
        Allocation__c alloc0 = null;
        Allocation__c alloc1 = null;
        Allocation__c alloc2 = null;
        List<General_Accounting_Unit__c> gaus = alloSetupTest.getGAUs();
        General_Accounting_Unit__c defaultGAU = alloSetupTest.getDefaultGAU();

        // Opportunity 0
        message = 'Opportunity 0 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByOppId.get(oppIds[0]), null, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByOppId.get(oppIds[0]), null, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByOppId.get(oppIds[0]), null, message + 'Allocations - Delete');

        // Opportunity 1
        message = 'Opportunity 1 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByOppId.get(oppIds[1]), 2, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByOppId.get(oppIds[1]), null, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByOppId.get(oppIds[1]), null, message + 'Allocations - Delete');
        allocs = allocsForInsertByOppId.get(oppIds[1]);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[0]);
        alloc1 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[1], 10, 50, gaus[0].Id, message + 'Insert - Allocation 0');
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc1, oppIds[1], 10, null, gaus[1].Id, message + 'Insert - Allocation 1');

        // Opportunity 2
        message = 'Opportunity 2 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByOppId.get(oppIds[2]), 1, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByOppId.get(oppIds[2]), null, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByOppId.get(oppIds[2]), null, message + 'Allocations - Delete');
        allocs = allocsForInsertByOppId.get(oppIds[2]);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, defaultGAU);
        alloc1 = null;
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[2], 20, null, defaultGAU.Id, message + 'Insert - Allocation 0');

        // Opportunity 3
        message = 'Opportunity 3 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByOppId.get(oppIds[3]), 1, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByOppId.get(oppIds[3]), null, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByOppId.get(oppIds[3]), null, message + 'Allocations - Delete');
        allocs = allocsForInsertByOppId.get(oppIds[3]);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, defaultGAU);
        alloc1 = null;
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[3], 10, null, defaultGAU.Id, message + 'Insert - Allocation 0');

        // Opportunity 4
        message = 'Opportunity 4 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByOppId.get(oppIds[4]), null, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByOppId.get(oppIds[4]), 1, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByOppId.get(oppIds[4]), null, message + 'Allocations - Delete');
        allocs = allocsForUpdateByOppId.get(oppIds[4]);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        alloc1 = null;
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[4], 20, 100, gaus[1].Id, message + 'Update - Allocation 0');

        // Opportunity 5
        message = 'Opportunity 5 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByOppId.get(oppIds[5]), null, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByOppId.get(oppIds[5]), 1, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByOppId.get(oppIds[5]), null, message + 'Allocations - Delete');
        allocs = allocsForUpdateByOppId.get(oppIds[5]);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        alloc1 = null;
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[5], 0, 50, gaus[1].Id, message + 'Update - Allocation 0');

        // Opportunity 6 --No changes
        message = 'Opportunity 6 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByOppId.get(oppIds[6]), null, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByOppId.get(oppIds[6]), null, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByOppId.get(oppIds[6]), null, message + 'Allocations - Delete');

        // Opportunity 7 -- No changes
        message = 'Opportunity 7 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByOppId.get(oppIds[7]), null, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByOppId.get(oppIds[7]), null, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByOppId.get(oppIds[7]), null, message + 'Allocations - Delete');

        // Opportunity 8
        message ='Opportunity 8 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByOppId.get(oppIds[8]), null, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByOppId.get(oppIds[8]), null, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByOppId.get(oppIds[8]), 1, message + 'Allocations - Delete');
        allocs = allocsForDeleteByOppId.get(oppIds[8]);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, defaultGAU);
        alloc1 = null;
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[8], 20, null, alloSetupTest.getDefaultGAU().Id, message + 'Delete - Allocation 0');

        // Opportunity 9
        message = 'Opportunity 9 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByOppId.get(oppIds[9]), 2, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByOppId.get(oppIds[9]), null, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByOppId.get(oppIds[9]), null, message + 'Allocations - Delete');
        allocs = allocsForInsertByOppId.get(oppIds[9]);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        alloc1 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, defaultGAU);
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[9], 10, null, gaus[1].Id, message + 'Insert - Allocation 0');
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc1, oppIds[9], 10, null, defaultGAU.Id, message + 'Insert - Allocation 1');

        // Opportunity 10
        message = 'Opportunity 10 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByOppId.get(oppIds[10]), null, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByOppId.get(oppIds[10]), 2, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByOppId.get(oppIds[10]), null, message + 'Allocations - Delete');
        allocs = allocsForUpdateByOppId.get(oppIds[10]);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        alloc1 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, defaultGAU);
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[10], 10, 50, gaus[1].Id, message + 'Update - Allocation 0');
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc1, oppIds[10], 10, null, defaultGAU.Id, message + 'Update - Allocation 1');

        // Opportunity 11
        message = 'Opportunity 11 - ';
        System.assertEquals(true, allocWrapper.errorsByRecordId.containsKey(oppIds[11]), message + 'Has Errors');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByOppId.get(oppIds[11]), null, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByOppId.get(oppIds[11]), null, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByOppId.get(oppIds[11]), null, message + 'Allocations - Delete');

        // Opportunity 12
        message = 'Opportunity 12 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByOppId.get(oppIds[12]), 1, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByOppId.get(oppIds[12]), null, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByOppId.get(oppIds[12]), null, message + 'Allocations - Delete');
        allocs = allocsForInsertByOppId.get(oppIds[12]);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, defaultGAU);
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[12], 0, null, defaultGAU.Id, message + 'Insert - Allocation 0');

        // Opportunity 13
        message = 'Opportunity 13 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByOppId.get(oppIds[13]), 1, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByOppId.get(oppIds[13]), null, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByOppId.get(oppIds[13]), null, message + 'Allocations - Delete');
        allocs = allocsForInsertByOppId.get(oppIds[13]);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, defaultGAU);
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[13], 20, null, defaultGAU.Id, message + 'Insert - Allocation 0');

        // Have to process DML before processing the Payment Allocations
        ALLO_AllocationsDMLService allocDMLSvc = new ALLO_AllocationsDMLService()
                                                        .withAllocationsWrapper(allocWrapper);
        allocDMLSvc.processAllocationResults();

        // Manually clearing pending DML
        allocWrapper.clearPendingDML();

        ALLO_UnitTestHelper_TEST.assertSObjectList(allocWrapper.allocationsForDelete, 0, 'Before Process Payment Allocations - Delete List');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocWrapper.allocationsForInsert, 0, 'Before Process Payment Allocations - Insert List');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocWrapper.allocationsForUpdate, 0, 'Before Process Payment Allocations - Update List');

        allocRecalcSvc.processPaymentAllocations();

        ALLO_UnitTestHelper_TEST.assertSObjectList(allocWrapper.allocationsForDelete, 3, 'After Process Payment Allocations - Delete List');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocWrapper.allocationsForInsert, 4, 'After Process Payment Allocations - Insert List');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocWrapper.allocationsForUpdate, 8, 'After Process Payment Allocations - Update List');

        Map<Id, Opportunity> oppsById = new Map<Id, Opportunity>([SELECT    Id,
                                                                            (SELECT     Id
                                                                            FROM npe01__OppPayment__r
                                                                            ORDER BY npe01__Scheduled_Date__c ASC
                                                                            )
                                                                FROM Opportunity
                                                                WHERE Id in :oppIds]);
        // Opportunity 6 Payments
        List<npe01__OppPayment__c> pmts = oppsById.get(oppIds[6]).npe01__OppPayment__r;
        Map<Id, List<Allocation__c>> allocsForDeleteByPmtId = ALLO_UnitTestHelper_TEST.buildMapOfAllocationsByPaymentId(allocWrapper.allocationsForDelete);
        Map<Id, List<Allocation__c>> allocsForInsertByPmtId = ALLO_UnitTestHelper_TEST.buildMapOfAllocationsByPaymentId(allocWrapper.allocationsForInsert);
        Map<Id, List<Allocation__c>> allocsForUpdateByPmtId = ALLO_UnitTestHelper_TEST.buildMapOfAllocationsByPaymentId(allocWrapper.allocationsForUpdate);

        // Opportunity 6 - Payment 0
        message = 'Opportunity 6, Payment 0 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByPmtId.get(pmts[0].Id), 1, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByPmtId.get(pmts[0].Id), null, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByPmtId.get(pmts[0].Id), null, message + 'Allocations - Delete');
        allocs = allocsForInsertByPmtId.get(pmts[0].Id);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        alloc1 = null;
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc0, pmts[0].Id, 10, 100, gaus[1].Id, message + 'Insert - Allocation 0');

        // Opportunity 6 - Payment 1
        message = 'Opportunity 6, Payment 1 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByPmtId.get(pmts[1].Id), null, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByPmtId.get(pmts[1].Id), 2, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByPmtId.get(pmts[1].Id), null, message + 'Allocations - Delete');
        allocs = allocsForUpdateByPmtId.get(pmts[1].Id);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[0]);
        alloc1 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, defaultGAU);
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc0, pmts[1].Id, 5, 50, gaus[0].Id, message + 'Update - Allocation 0');
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc1, pmts[1].Id, 4, null, defaultGAU.Id, message + 'Update - Allocation 1');

        // Opportunity 6 - Payment 2
        message = 'Opportunity 6, Payment 2 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByPmtId.get(pmts[2].Id), 1, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByPmtId.get(pmts[2].Id), null, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByPmtId.get(pmts[2].Id), null, message + 'Allocations - Delete');
        allocs = allocsForInsertByPmtId.get(pmts[2].Id);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, defaultGAU);
        alloc1 = null;
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc0, pmts[2].Id, 9, null, defaultGAU.Id, message + 'Insert - Allocation 0');

        // Opportunity 6 - Payment 3
        message = 'Opportunity 6, Payment 3 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByPmtId.get(pmts[3].Id), null, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByPmtId.get(pmts[3].Id), null, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByPmtId.get(pmts[3].Id), 1, message + 'Allocations - Delete');
        allocs = allocsForDeleteByPmtId.get(pmts[3].Id);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, defaultGAU);
        alloc1 = null;
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc0, pmts[3].Id, 10, null, defaultGAU.Id, message + 'Delete - Allocation 0');

        // Opportunity 6 - Payment 4
        message = 'Opportunity 6, Payment 4 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByPmtId.get(pmts[4].Id), null, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByPmtId.get(pmts[4].Id), 1, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByPmtId.get(pmts[4].Id), null, message + 'Allocations - Delete');
        allocs = allocsForUpdateByPmtId.get(pmts[4].Id);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, defaultGAU);
        alloc1 = null;
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc0, pmts[4].Id, 0, null, defaultGAU.Id, message + 'Update - Allocation 0');

        // Opportunity 6 - Payment 5
        message = 'Opportunity 6, Payment 5 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByPmtId.get(pmts[5].Id), null, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByPmtId.get(pmts[5].Id), 1, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByPmtId.get(pmts[5].Id), null, message + 'Allocations - Delete');
        allocs = allocsForUpdateByPmtId.get(pmts[5].Id);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, defaultGAU);
        alloc1 = null;
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc0, pmts[5].Id, 0, null, defaultGAU.Id, message + 'Update - Allocation 0');

        // Opportunity 6 - Payment 6
        message = 'Opportunity 6, Payment 6 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByPmtId.get(pmts[6].Id), null, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByPmtId.get(pmts[6].Id), 1, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByPmtId.get(pmts[6].Id), null, message + 'Allocations - Delete');
        allocs = allocsForUpdateByPmtId.get(pmts[6].Id);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[0]);
        alloc1 = null;
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc0, pmts[6].Id, 0, 10, gaus[0].Id, message + 'Update - Allocation 0');

        // Opportunity 6 - Payment 7
        message = 'Opportunity 6, Payment 7 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByPmtId.get(pmts[7].Id), null, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByPmtId.get(pmts[7].Id), 1, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByPmtId.get(pmts[7].Id), null, message + 'Allocations - Delete');
        allocs = allocsForUpdateByPmtId.get(pmts[7].Id);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[0]);
        alloc1 = null;
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc0, pmts[7].Id, 0, 10, gaus[0].Id, message + 'Update - Allocation 0');

        // Opportunity 6 - Payment 8
        message = 'Opportunity 6, Payment 8 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByPmtId.get(pmts[8].Id), null, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByPmtId.get(pmts[8].Id), 1, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByPmtId.get(pmts[8].Id), 1, message + 'Allocations - Delete');
        allocs = allocsForUpdateByPmtId.get(pmts[8].Id);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[0]);
        allocs = allocsForDeleteByPmtId.get(pmts[8].Id);
        alloc1 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, defaultGAU);
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc0, pmts[8].Id, 0, 10, gaus[0].Id, message + 'Update - Allocation 0');
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc1, pmts[8].Id, 10, null, defaultGAU.Id, message + 'Delete - Allocation 1');

        // Opportunity 6 - Payment 9
        message = 'Opportunity 6, Payment 9 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByPmtId.get(pmts[9].Id), null, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByPmtId.get(pmts[9].Id), 1, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByPmtId.get(pmts[9].Id), 1, message + 'Allocations - Delete');
        allocs = allocsForUpdateByPmtId.get(pmts[9].Id);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[0]);
        allocs = allocsForDeleteByPmtId.get(pmts[9].Id);
        alloc1 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, defaultGAU);
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc0, pmts[9].Id, 0, 10, gaus[0].Id, message + 'Update - Allocation 0');
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc1, pmts[9].Id, 10, null, defaultGAU.Id, message + 'Delete - Allocation 1');

        // Opportunity 6 - Payment 10
        message = 'Opportunity 6, Payment 10 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByPmtId.get(pmts[10].Id), 1, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByPmtId.get(pmts[10].Id), null, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByPmtId.get(pmts[10].Id), null, message + 'Allocations - Delete');
        allocs = allocsForInsertByPmtId.get(pmts[10].Id);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc0, pmts[10].Id, 0, 100, gaus[1].Id, message + 'Insert - Allocation 0');

        // Opportunity 6 - Payment 11
        message = 'Opportunity 6, Payment 11 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByPmtId.get(pmts[11].Id), 1, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByPmtId.get(pmts[11].Id), null, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByPmtId.get(pmts[11].Id), null, message + 'Allocations - Delete');
        allocs = allocsForInsertByPmtId.get(pmts[11].Id);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc0, pmts[11].Id, 0, 100, gaus[1].Id, message + 'Insert - Allocation 0');

        // Opportunity 6 - Payment 12
        message = 'Opportunity 6, Payment 12 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByPmtId.get(pmts[12].Id), null, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByPmtId.get(pmts[12].Id), null, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByPmtId.get(pmts[12].Id), null, message + 'Allocations - Delete');
        System.assertEquals(true, allocWrapper.errorsByRecordId.containsKey(oppIds[6]), 'Opportunity 6 - Error Present');

        pmts = oppsById.get(oppIds[7]).npe01__OppPayment__r;

        // Opportunity 7 - Payment 0
        message = 'Opportunity 7, Payment 0 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByPmtId.get(pmts[0].Id), null, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByPmtId.get(pmts[0].Id), null, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByPmtId.get(pmts[0].Id), null, message + 'Allocations - Delete');
    }
}