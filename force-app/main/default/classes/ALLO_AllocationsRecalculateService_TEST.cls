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
     *
     *              Parent Allocation Data:
     *              Recurring Donation - Allocations (GAU0, 50%), (GAU1, $10)
     *              Campaign - Allocations (GAU1, $10)
     *
     *              Test Data & Results:
     *              Opportunity 0  - $20, Recurring Donation Parent, Fully allocated
     *                               Opportunity Allocations (GAU0, 50%, $10), (GAU1, $10)
     *                               Proposed Allocation DML: None
     *              Opportunity 1  - $20, Recurring Donation Parent, No Allocations present
     *                               Proposed Allocation DML: Inserts (GAU0, 50%, $10), (GAU1, $10)
     *              Opportunity 2  - $20, No Allocations present
     *                               Proposed Allocation DML: Inserts (Default GAU, $20)
     *              Opportunity 3  - $20, Sum of Allocations < Opportunity Amount
     *                               Proposed Allocation DML: Inserts (Default GAU, $10)
     *              Opportunity 4  - $20, Allocation has percent but not amount
     *                               Opportunity Allocations (GAU1, 100%, (null))
     *                               Proposed Allocation DML: Updates (GAU1, 100%, $20)
     *              Opportunity 5  - $0, Percent Allocation with non zero amount
     *                               Opportunity Allocations (GAU1, 50%, $20)
     *                               Proposed Allocation DML: Updates (GAU1, 50%, $0)
     *              Opportunity 6  - $20, Fully allocated at Opportunity level
     *                               Opportunity Allocations (GAU1, 100%, $20)
     *                               Proposed Allocation DML: None
     *              Opportunity 7  - $20, Fully allocated at Opportunity level
     *                               Opportunity Allocations (GAU1, 100%, $20)
     *                               Proposed Allocation DML: None
     *              Opportunity 8  - (null), Opportunity Allocations (Default GAU, $20)
     *                               Proposed Allocation DML: Deletes (Default GAU, $20)
     *              Opportunity 9  - $20, Campaign Parent, No Allocations Present
     *                               Proposed Allocation DML: Inserts (GAU1, $10), (Default GAU, $10)
     *              Opportunity 10 - $20, Allocations need resizing
     *                               Opportunity Allocations (GAU1, 50%, $40), (Default GAU, $40)
     *                               Proposed Allocation DML: Updates (GAU1, 50%, $10), (Default GAU, $10)
     *              Opportunity 11 - $20, Invalid Allocation that cannot be corrected
     *                               Opportunity Allocations (GAU1, $40)
     *                               Result: Pending Error is added, because overallocated, and cannot fix automatically
     *              Opportunity 12 - $0, No Allocations (Default Allocation Handling)
     *                               Proposed Allocation DML: Insert (Default GAU, $0)
     *              Opportunity 13 - $20, No Allocations (Default Allocation Handling)
     *                               Proposed Allocation DML: Insert (Default GAU, $20)
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

        // Opportunity 0  - $20, Recurring Donation Parent, Fully allocated
        //                  Opportunity Allocations (GAU0, 50%, $10), (GAU1, $10)
        //                  Proposed Allocation DML: None
        message = 'Opportunity 0 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByOppId.get(oppIds[0]), null, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByOppId.get(oppIds[0]), null, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByOppId.get(oppIds[0]), null, message + 'Allocations - Delete');

        // Opportunity 1  - $20, Recurring Donation Parent, No Allocations present
        //                  Proposed Allocation DML: Inserts (GAU0, 50%, $10), (GAU1, $10)
        message = 'Opportunity 1 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByOppId.get(oppIds[1]), 2, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByOppId.get(oppIds[1]), null, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByOppId.get(oppIds[1]), null, message + 'Allocations - Delete');
        allocs = allocsForInsertByOppId.get(oppIds[1]);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[0]);
        alloc1 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[1], 10, 50, gaus[0].Id, message + 'Insert - Allocation 0');
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc1, oppIds[1], 10, null, gaus[1].Id, message + 'Insert - Allocation 1');

        // Opportunity 2  - $20, No Allocations present
        //                  Proposed Allocation DML: Inserts (Default GAU, $20)
        message = 'Opportunity 2 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByOppId.get(oppIds[2]), 1, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByOppId.get(oppIds[2]), null, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByOppId.get(oppIds[2]), null, message + 'Allocations - Delete');
        allocs = allocsForInsertByOppId.get(oppIds[2]);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, defaultGAU);
        alloc1 = null;
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[2], 20, null, defaultGAU.Id, message + 'Insert - Allocation 0');

        // Opportunity 3  - $20, Sum of Allocations < Opportunity Amount
        //                  Proposed Allocation DML: Inserts (Default GAU, $10)
        message = 'Opportunity 3 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByOppId.get(oppIds[3]), 1, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByOppId.get(oppIds[3]), null, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByOppId.get(oppIds[3]), null, message + 'Allocations - Delete');
        allocs = allocsForInsertByOppId.get(oppIds[3]);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, defaultGAU);
        alloc1 = null;
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[3], 10, null, defaultGAU.Id, message + 'Insert - Allocation 0');

        // Opportunity 4  - $20, Allocation has percent but not amount
        //                  Opportunity Allocations (GAU1, 100%, (null))
        //                  Proposed Allocation DML: Updates (GAU1, 100%, $20)
        message = 'Opportunity 4 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByOppId.get(oppIds[4]), null, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByOppId.get(oppIds[4]), 1, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByOppId.get(oppIds[4]), null, message + 'Allocations - Delete');
        allocs = allocsForUpdateByOppId.get(oppIds[4]);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        alloc1 = null;
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[4], 20, 100, gaus[1].Id, message + 'Update - Allocation 0');

        // Opportunity 5  - $0, Percent Allocation with non zero amount
        //                  Opportunity Allocations (GAU1, 50%, $20)
        //                  Proposed Allocation DML: Updates (GAU1, 50%, $0)
        message = 'Opportunity 5 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByOppId.get(oppIds[5]), null, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByOppId.get(oppIds[5]), 1, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByOppId.get(oppIds[5]), null, message + 'Allocations - Delete');
        allocs = allocsForUpdateByOppId.get(oppIds[5]);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        alloc1 = null;
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[5], 0, 50, gaus[1].Id, message + 'Update - Allocation 0');

        // Opportunity 6  - $20, Fully allocated at Opportunity level
        //                  Opportunity Allocations (GAU1, 100%, $20)
        //                  Proposed Allocation DML: None
        message = 'Opportunity 6 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByOppId.get(oppIds[6]), null, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByOppId.get(oppIds[6]), null, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByOppId.get(oppIds[6]), null, message + 'Allocations - Delete');

        // Opportunity 7  - $20, Fully allocated at Opportunity level
        //                  Opportunity Allocations (GAU1, 100%, $20)
        //                  Proposed Allocation DML: None
        message = 'Opportunity 7 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByOppId.get(oppIds[7]), null, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByOppId.get(oppIds[7]), null, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByOppId.get(oppIds[7]), null, message + 'Allocations - Delete');

        // Opportunity 8  - (null), Opportunity Allocations (Default GAU, $20)
        //                  Proposed Allocation DML: Deletes (Default GAU, $20)
        message ='Opportunity 8 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByOppId.get(oppIds[8]), null, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByOppId.get(oppIds[8]), null, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByOppId.get(oppIds[8]), 1, message + 'Allocations - Delete');
        allocs = allocsForDeleteByOppId.get(oppIds[8]);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, defaultGAU);
        alloc1 = null;
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[8], 20, null, alloSetupTest.getDefaultGAU().Id, message + 'Delete - Allocation 0');

        // Opportunity 9  - $20, Campaign Parent, No Allocations Present
        //                  Proposed Allocation DML: Inserts (GAU1, $10), (Default GAU, $10)
        message = 'Opportunity 9 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByOppId.get(oppIds[9]), 2, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByOppId.get(oppIds[9]), null, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByOppId.get(oppIds[9]), null, message + 'Allocations - Delete');
        allocs = allocsForInsertByOppId.get(oppIds[9]);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        alloc1 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, defaultGAU);
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[9], 10, null, gaus[1].Id, message + 'Insert - Allocation 0');
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc1, oppIds[9], 10, null, defaultGAU.Id, message + 'Insert - Allocation 1');

        // Opportunity 10 - $20, Allocations need resizing
        //                  Opportunity Allocations (GAU1, 50%, $40), (Default GAU, $40)
        //                  Proposed Allocation DML: Updates (GAU1, 50%, $10), (Default GAU, $10)
        message = 'Opportunity 10 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByOppId.get(oppIds[10]), null, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByOppId.get(oppIds[10]), 2, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByOppId.get(oppIds[10]), null, message + 'Allocations - Delete');
        allocs = allocsForUpdateByOppId.get(oppIds[10]);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        alloc1 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, defaultGAU);
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[10], 10, 50, gaus[1].Id, message + 'Update - Allocation 0');
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc1, oppIds[10], 10, null, defaultGAU.Id, message + 'Update - Allocation 1');

        // Opportunity 11 - $20, Invalid Allocation that cannot be corrected
        //                  Opportunity Allocations (GAU1, $40)
        //                  Result: Pending Error is added, because overallocated, and cannot fix automatically
        message = 'Opportunity 11 - ';
        System.assertEquals(true, allocWrapper.errorsByRecordId.containsKey(oppIds[11]), message + 'Has Errors');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByOppId.get(oppIds[11]), null, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByOppId.get(oppIds[11]), null, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByOppId.get(oppIds[11]), null, message + 'Allocations - Delete');

        // Opportunity 12 - $0, No Allocations (Default Allocation Handling)
        //                  Proposed Allocation DML: Insert (Default GAU, $0)
        message = 'Opportunity 12 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByOppId.get(oppIds[12]), 1, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByOppId.get(oppIds[12]), null, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByOppId.get(oppIds[12]), null, message + 'Allocations - Delete');
        allocs = allocsForInsertByOppId.get(oppIds[12]);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, defaultGAU);
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[12], 0, null, defaultGAU.Id, message + 'Insert - Allocation 0');

        // Opportunity 13 - $20, No Allocations (Default Allocation Handling)
        //                  Proposed Allocation DML: Insert (Default GAU, $20)
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
     *
     *              Parent Allocation Data:
     *              Recurring Donation - Allocations (GAU0, 50%), (GAU1, $10)
     *              Campaign - Allocations (GAU1, $10)
     *
     *              Test Data & Results:
     *              Opportunity 0  - $20, Recurring Donation Parent, Fully allocated
     *                               Opportunity Allocations (GAU0, 50%, $10), (GAU1, $10)
     *                               Proposed Allocation DML: None
     *              Opportunity 1  - $20, Recurring Donation Parent, No Allocations present
     *                               Proposed Allocation DML: Inserts (GAU0, 50%, $10), (GAU1, $10)
     *              Opportunity 2  - $20, No Allocations present
     *                               Proposed Allocation DML: None
     *              Opportunity 3  - $20, Sum of Allocations < Opportunity Amount
     *                               Proposed Allocation DML: None
     *              Opportunity 4  - $20, Allocation has percent but not amount
     *                               Opportunity Allocations (GAU1, 100%, (null))
     *                               Proposed Allocation DML: Updates (GAU1, 100%, $20)
     *              Opportunity 5  - $0, Percent Allocation with non zero amount
     *                               Opportunity Allocations (GAU1, 50%, $20)
     *                               Proposed Allocation DML: Updates (GAU1, 50%, $0)
     *              Opportunity 6  - $20, Fully allocated at Opportunity level
     *                               Opportunity Allocations (GAU1, 100%, $20)
     *                               Proposed Allocation DML: None
     *              Opportunity 7  - $20, Fully allocated at Opportunity level
     *                               Opportunity Allocations (GAU1, 100%, $20)
     *                               Proposed Allocation DML: None
     *              Opportunity 8  - (null), Opportunity Allocation (GAU2, 100%, $20)
     *                               Proposed Allocation DML: Deletes (GAU2, $20)
     *              Opportunity 9  - $20, Campaign Parent, No Allocations Present
     *                               Proposed Allocation DML: Inserts (GAU1, $10)
     *              Opportunity 10 - $20, Allocations need resizing
     *                               Opportunity Allocations (GAU1, 50%, $40)
     *                               Proposed Allocation DML: Updates (GAU1, 50%, $10)
     *              Opportunity 11 - $20, Invalid Allocation that cannot be corrected
     *                               Opportunity Allocations (GAU1, $40)
     *                               Result: Pending Error is added, because overallocated, and cannot fix automatically
     *              Opportunity 12 - $0, No Allocations
     *                               Proposed Allocation DML: None
     *              Opportunity 13 - $20, No Allocations
     *                               Proposed Allocation DML: None
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

        // Opportunity 0  - $20, Recurring Donation Parent, Fully allocated
        //                  Opportunity Allocations (GAU0, 50%, $10), (GAU1, $10)
        //                  Proposed Allocation DML: None
        message = 'Opportunity 0 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByOppId.get(oppIds[0]), null, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByOppId.get(oppIds[0]), null, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByOppId.get(oppIds[0]), null, message + 'Allocations - Delete');

        // Opportunity 1  - $20, Recurring Donation Parent, No Allocations present
        //                  Proposed Allocation DML: Inserts (GAU0, 50%, $10), (GAU1, $10)
        message = 'Opportunity 1 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByOppId.get(oppIds[1]), 2, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByOppId.get(oppIds[1]), null, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByOppId.get(oppIds[1]), null, message + 'Allocations - Delete');
        allocs = allocsForInsertByOppId.get(oppIds[1]);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[0]);
        alloc1 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[1], 10, 50, gaus[0].Id, message + 'Insert - Allocation 0');
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc1, oppIds[1], 10, null, gaus[1].Id, message + 'Insert - Allocation 1');

        // Opportunity 2  - $20, No Allocations present
        //                  Proposed Allocation DML: None
        message = 'Opportunity 2 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByOppId.get(oppIds[2]), null, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByOppId.get(oppIds[2]), null, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByOppId.get(oppIds[2]), null, message + 'Allocations - Delete');

        // Opportunity 3  - $20, Sum of Allocations < Opportunity Amount
        //                  Proposed Allocation DML: None
        message = 'Opportunity 3 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByOppId.get(oppIds[3]), null, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByOppId.get(oppIds[3]), null, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByOppId.get(oppIds[3]), null, message + 'Allocations - Delete');

        // Opportunity 4  - $20, Allocation has percent but not amount
        //                  Opportunity Allocations (GAU1, 100%, (null))
        //                  Proposed Allocation DML: Updates (GAU1, 100%, $20)
        message = 'Opportunity 4 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByOppId.get(oppIds[4]), null, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByOppId.get(oppIds[4]), 1, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByOppId.get(oppIds[4]), null, message + 'Allocations - Delete');
        allocs = allocsForUpdateByOppId.get(oppIds[4]);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        alloc1 = null;
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[4], 20, 100, gaus[1].Id, message + 'Update - Allocation 0');

        // Opportunity 5  - $0, Percent Allocation with non zero amount
        //                  Opportunity Allocations (GAU1, 50%, $20)
        //                  Proposed Allocation DML: Updates (GAU1, 50%, $0)
        message = 'Opportunity 5 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByOppId.get(oppIds[5]), null, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByOppId.get(oppIds[5]), 1, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByOppId.get(oppIds[5]), null, message + 'Allocations - Delete');
        allocs = allocsForUpdateByOppId.get(oppIds[5]);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        alloc1 = null;
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[5], 0, 50, gaus[1].Id, message + 'Update - Allocation 0');

        // Opportunity 6  - $20, Fully allocated at Opportunity level
        //                  Opportunity Allocations (GAU1, 100%, $20)
        //                  Proposed Allocation DML: None
        message = 'Opportunity 6 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByOppId.get(oppIds[6]), null, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByOppId.get(oppIds[6]), null, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByOppId.get(oppIds[6]), null, message + 'Allocations - Delete');

        // Opportunity 7  - $20, Fully allocated at Opportunity level
        //                  Opportunity Allocations (GAU1, 100%, $20)
        //                  Proposed Allocation DML: None
        message = 'Opportunity 7 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByOppId.get(oppIds[7]), null, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByOppId.get(oppIds[7]), null, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByOppId.get(oppIds[7]), null, message + 'Allocations - Delete');

        // Opportunity 8  - (null), Opportunity Allocation (GAU2, 100%, $20)
        //                  Proposed Allocation DML: Deletes (GAU2, $20)
        message ='Opportunity 8 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByOppId.get(oppIds[8]), null, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByOppId.get(oppIds[8]), null, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByOppId.get(oppIds[8]), 1, message + 'Allocations - Delete');
        allocs = allocsForDeleteByOppId.get(oppIds[8]);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[2]);
        alloc1 = null;
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[8], 20, 100, gaus[2].Id, message + 'Delete - Allocation 0');

        // Opportunity 9  - $20, Campaign Parent, No Allocations Present
        //                  Proposed Allocation DML: Inserts (GAU1, $10)
        message = 'Opportunity 9 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByOppId.get(oppIds[9]), 1, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByOppId.get(oppIds[9]), null, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByOppId.get(oppIds[9]), null, message + 'Allocations - Delete');
        allocs = allocsForInsertByOppId.get(oppIds[9]);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        alloc1 = null;
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[9], 10, null, gaus[1].Id, message + 'Insert - Allocation 0');

        // Opportunity 10 - $20, Allocations need resizing
        //                  Opportunity Allocations (GAU1, 50%, $40)
        //                  Proposed Allocation DML: Updates (GAU1, 50%, $10)
        message = 'Opportunity 10 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByOppId.get(oppIds[10]), null, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByOppId.get(oppIds[10]), 1, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByOppId.get(oppIds[10]), null, message + 'Allocations - Delete');
        allocs = allocsForUpdateByOppId.get(oppIds[10]);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        alloc1 = null;
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[10], 10, 50, gaus[1].Id, message + 'Update - Allocation 0');

        // Opportunity 11 - $20, Invalid Allocation that cannot be corrected
        //                  Opportunity Allocations (GAU1, $40)
        //                  Result: Pending Error is added, because overallocated, and cannot fix automatically
        message = 'Opportunity 11 - ';
        System.assertEquals(true, allocWrapper.errorsByRecordId.containsKey(oppIds[11]), message + 'Has Errors');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByOppId.get(oppIds[11]), null, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByOppId.get(oppIds[11]), null, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByOppId.get(oppIds[11]), null, message + 'Allocations - Delete');

        // Opportunity 12 - $0, No Allocations
        //                  Proposed Allocation DML: None
        message = 'Opportunity 12 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByOppId.get(oppIds[12]), null, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByOppId.get(oppIds[12]), null, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByOppId.get(oppIds[12]), null, message + 'Allocations - Delete');

        // Opportunity 13 - $20, No Allocations
        //                  Proposed Allocation DML: None
        message = 'Opportunity 13 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByOppId.get(oppIds[13]), null, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByOppId.get(oppIds[13]), null, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByOppId.get(oppIds[13]), null, message + 'Allocations - Delete');
    }

    /**
     * @description Defaults Payment Allocations from Parent Opportunity.  Payment Allocation Percentages are Irrational
     *              Default Allocations Enabled
     *              Payment Allocations Enabled
     *              [ALLO_AllocationsRecalculateService.processPaymentAllocations]
     *              
     *              Opportunity Amount $100.01
     *                  Opportunity Allocation 1 for GAU 1, $50.00
     *                  Opportunity Allocation 2 for GAU 2, $50.01
     * 
     *              No allocations created on payment that is autocreated
     * 
     *              Run RecalculateService, confirm Payment Allocations created with Appropriate Irrational Percentages
     * 
     */ 
    @isTest 
    private static void confirmRecalculateServicePreservesFullPercentageWhenDefaultingPaymentAllocationsFromParent() {
        ALLO_UnitTestHelper_TEST.AllocationSetupTest alloSetupTest = new ALLO_UnitTestHelper_TEST.AllocationSetupTest()
            .enableDefaultAllocations()
            .enablePaymentAllocations()
            .disableAllocationTriggers()
            .applyConfiguration();

        List<Contact> ctcs = UTIL_UnitTestData_TEST.createMultipleTestContacts(1);
        insert ctcs;

        Opportunity opp = new Opportunity(
            Name = 'Opp-recalcPmtAlloPercentCheck',
            Amount = 100.01,
            ContactID = ctcs[0].Id,
            CloseDate = System.today(),
            StageName = UTIL_UnitTestData_TEST.getClosedWonStage()
        );
        insert opp;


        List<General_Accounting_Unit__c> gaus = alloSetupTest.getGAUs();
        General_Accounting_Unit__c defaultGAU = alloSetupTest.getDefaultGAU();

        // Setup irregular Allocations
        List<Allocation__c> alloForInsert = new List<Allocation__c>{
            new Allocation__c (General_Accounting_Unit__c = gaus[0].Id, Opportunity__c = opp.Id, Amount__c = 50, Percent__c = null),
            new Allocation__c (General_Accounting_Unit__c = gaus[1].Id, Opportunity__c = opp.Id, Amount__c = 50.01, Percent__c = null)
        };
        insert alloForInsert;

        List<npe01__OppPayment__c> pmts = [SELECT   Id,
                                                    Name
                                           FROM npe01__OppPayment__c
                                           WHERE    npe01__Opportunity__c = :opp.Id];

        System.assertEquals (1, pmts.size(), '# of Payments Present');

        List<Allocation__c> pmtAllocs = [SELECT     Id,
                                                    General_Accounting_Unit__c,
                                                    Percent__c,
                                                    Amount__c
                                         FROM Allocation__c
                                         WHERE Payment__c = :pmts[0].Id];
        System.assertEquals(0, pmtAllocs.size(), 'No Allocations since allocations triggers are off');

        Set<Id> oppIdsAsSet = new Set<Id>();
        oppIdsAsSet.add(opp.Id);

        ALLO_AllocationsWrapper allocWrapper = new ALLO_AllocationsRetrievalService()
                                                .withOpportunities(oppIdsAsSet)
                                                .retrieveData()
                                                .allocationsWrapper;

        ALLO_AllocationsReviewService allocReviewSvc = new ALLO_AllocationsReviewService()
                                                            .withAllocationsWrapper(allocWrapper);
                                                            
        ALLO_AllocationsRecalculateService allocRecalcSvc = new ALLO_AllocationsRecalculateService()
                                                                .withAllocationsWrapper(allocWrapper);

        ALLO_UnitTestHelper_TEST.assertSObjectList(allocWrapper.allocationsForDelete, 0, 'Before Recalculate - Delete List');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocWrapper.allocationsForInsert, 0, 'Before Recalculate - Insert List');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocWrapper.allocationsForUpdate, 0, 'Before Recalculate - Update List');

        allocRecalcSvc.processOpportunityAllocations();

        ALLO_UnitTestHelper_TEST.assertSObjectList(allocWrapper.allocationsForDelete, 0, 'After Recalculate - Delete List');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocWrapper.allocationsForInsert, 0, 'After Recalculate - Insert List');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocWrapper.allocationsForUpdate, 0, 'After Recalculate - Update List');

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

        ALLO_UnitTestHelper_TEST.assertSObjectList(allocWrapper.allocationsForDelete, 0, 'After Process Payment Allocations - Delete List');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocWrapper.allocationsForInsert, 2, 'After Process Payment Allocations - Insert List');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocWrapper.allocationsForUpdate, 0, 'After Process Payment Allocations - Update List');

        Allocation__c pmtAlloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocWrapper.allocationsForInsert, gaus[0]);
        Allocation__c pmtAlloc1 = ALLO_UnitTestHelper_TEST.findByGAU(allocWrapper.allocationsForInsert, gaus[1]);

        // Calculate irrational compare percentages
        Double percentGAU1 = (50.0/100.01) * 100;
        Double percentGAU2 = (50.01/100.01) * 100;

        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(pmtAlloc0, pmts[0].Id, 50, percentGAU1, gaus[0].Id, 'Payment Allocation For GAU[0]');
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(pmtAlloc1, pmts[0].Id, 50.01, percentGAU2, gaus[1].Id, 'Payment Allocation For GAU[1]');
    }

    /**
     * @description Confirm Recalculate Service creates correct DML changes when
     *              Default Allocations Enabled
     *              Payment Allocations Enabled
     *              [ALLO_AllocationsRecalculateService.processPaymentAllocations]
     *
     *              Parent Allocation Data:
     *              Recurring Donation - Allocations (GAU0, 50%), (GAU1, $10)
     *              Campaign - Allocations (GAU1, $10)
     *
     *              Test Data & Results:
     *              Opportunity 0  - $20, Recurring Donation Parent, Fully allocated
     *                               Opportunity Allocations (GAU0, 50%, $10), (GAU1, $10)
     *                               Proposed Allocation DML: None
     *              Opportunity 1  - $20, Recurring Donation Parent, No Allocations present
     *                               Proposed Allocation DML: Inserts (GAU0, 50%, $10), (GAU1, $10)
     *              Opportunity 2  - $20, No Allocations present
     *                               Proposed Allocation DML: Inserts (Default GAU, $20)
     *              Opportunity 3  - $20, Sum of Allocations < Opportunity Amount
     *                               Proposed Allocation DML: Inserts (Default GAU, $10)
     *              Opportunity 4  - $20, Allocation has percent but not amount
     *                               Opportunity Allocations (GAU1, 100%, (null))
     *                               Proposed Allocation DML: Updates (GAU1, 100%, $20)
     *              Opportunity 5  - $0, Percent Allocation with non zero amount
     *                               Opportunity Allocations (GAU1, 50%, $20)
     *                               Proposed Allocation DML: Updates (GAU1, 50%, $0)
     *              Opportunity 6  - $20, Fully allocated at Opportunity level
     *                               Opportunity Allocations (GAU1, 100%, $20)
     *                               Proposed Allocation DML: None
     *              Opportunity 7  - $20, Fully allocated at Opportunity level
     *                               Opportunity Allocations (GAU1, 100%, $20)
     *                               Proposed Allocation DML: None
     *              Opportunity 8  - (null), Opportunity Allocations (Default GAU, $20)
     *                               Proposed Allocation DML: Deletes (Default GAU, $20)
     *              Opportunity 9  - $20, Campaign Parent, No Allocations Present
     *                               Proposed Allocation DML: Inserts (GAU1, $10), (Default GAU, $10)
     *              Opportunity 10 - $20, Allocations need resizing
     *                               Opportunity Allocations (GAU1, 50%, $40), (Default GAU, $40)
     *                               Proposed Allocation DML: Updates (GAU1, 50%, $10), (Default GAU, $10)
     *              Opportunity 11 - $20, Invalid Allocation that cannot be corrected
     *                               Opportunity Allocations (GAU1, $40)
     *                               Result: Pending Error is added, because overallocated, and cannot fix automatically
     *              Opportunity 12 - $0, No Allocations (Default Allocation Handling)
     *                               Proposed Allocation DML: Insert (Default GAU, $0)
     *              Opportunity 13 - $20, No Allocations (Default Allocation Handling)
     *                               Proposed Allocation DML: Insert (Default GAU, $20)
     *              Opportunity 6, Payment 0  - No Allocations are present
     *                                          Proposed Allocation DML: Inserts (GAU1, 100%, $10)
     *              Opportunity 6, Payment 1  - $10, Allocations Need Resizing
     *                                          Payment Allocations (GAU0, 50%), (GAU1, $1). (Default GAU, $10)
     *                                          Proposed Allocation DML: Updates (GAU0, 50%, $5), (Default GAU, $4)
     *              Opportunity 6, Payment 2  - $10, Needs Default Allocation
     *                                          Payment Allocations (GAU0, $1)
     *                                          Proposed Allocation DML: Inserts (Default GAU, $9)
     *              Opportunity 6, Payment 3  - $10, Remove Default Allocation Because Fully Allocated
     *                                          Payment Allocations (GAU0, 100%, $10), (Default GAU, $10)
     *                                          Proposed Allocation DML: Deletes (Default GAU, $10)
     *              Opportunity 6, Payment 4  - $0, Default Allocation needs resizing
     *                                          Payment Allocations (Default GAU, $10)
     *                                          Proposed Allocation DML: Updates (Default GAU, $0)
     *              Opportunity 6, Payment 5  - (null), Default Allocation needs resizing
     *                                          Payment Allocations (Default GAU, $10)
     *                                          Proposed Allocation DML: Updates (Default GAU, $0)
     *              Opportunity 6, Payment 6  - $0, Percent Allocation to update
     *                                          Payment Allocations (GAU0, 10%, $1)
     *                                          Proposed Allocation DML: Updates (GAU0, 10%, $0)
     *              Opportunity 6, Payment 7  - (null), Percent Allocation to update
     *                                          Payment Allocations (GAU0, 10%, $1)
     *                                          Proposed Allocation DML: Updates (GAU0, 10%, $0)
     *              Opportunity 6, Payment 8  - $0, Percent Allocation to update, Default Allocation to remove
     *                                          Payment Allocations (GAU0, 10%, $1), (Default GAU, $10)
     *                                          Proposed Allocation DML: Updates (GAU0, 10%, $0); Deletes (Default GAU, $10)
     *              Opportunity 6, Payment 9  - (null), Percent Allocation to update, Default Allocation to remove
     *                                          Payment Allocations (GAU0, 10%, $1), (Default GAU, $10)
     *                                          Proposed Allocation DML: Updates (GAU0, 10%, $0); Deletes (Default GAU, $10)
     *              Opportunity 6, Payment 10 - $0, Needs Allocations
     *                                          Proposed Allocation DML: Inserts (GAU1, 100%, $0)
     *              Opportunity 6, Payment 11 - (null), Needs Allocations
     *                                          Proposed Allocation DML: Inserts (GAU1, 100%, $0)
     *              Opportunity 6, Payment 12 - $10, Invalid Allocation (no amount or percent)
     *                                          Payment Allocations (GAU1)
     *                                          Result: Pending Error added, no proposed changes
     *              Opportunity 7, Payment 0  - $10, Fully allocated
     *                                          Proposed Allocation DML: None
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

        // Opportunity 0  - $20, Recurring Donation Parent, Fully allocated
        //                  Opportunity Allocations (GAU0, 50%, $10), (GAU1, $10)
        //                  Proposed Allocation DML: None
        message = 'Opportunity 0 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByOppId.get(oppIds[0]), null, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByOppId.get(oppIds[0]), null, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByOppId.get(oppIds[0]), null, message + 'Allocations - Delete');

        // Opportunity 1  - $20, Recurring Donation Parent, No Allocations present
        //                  Proposed Allocation DML: Inserts (GAU0, 50%, $10), (GAU1, $10)
        message = 'Opportunity 1 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByOppId.get(oppIds[1]), 2, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByOppId.get(oppIds[1]), null, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByOppId.get(oppIds[1]), null, message + 'Allocations - Delete');
        allocs = allocsForInsertByOppId.get(oppIds[1]);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[0]);
        alloc1 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[1], 10, 50, gaus[0].Id, message + 'Insert - Allocation 0');
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc1, oppIds[1], 10, null, gaus[1].Id, message + 'Insert - Allocation 1');

        // Opportunity 2  - $20, No Allocations present
        //                  Proposed Allocation DML: Inserts (Default GAU, $20)
        message = 'Opportunity 2 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByOppId.get(oppIds[2]), 1, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByOppId.get(oppIds[2]), null, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByOppId.get(oppIds[2]), null, message + 'Allocations - Delete');
        allocs = allocsForInsertByOppId.get(oppIds[2]);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, defaultGAU);
        alloc1 = null;
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[2], 20, null, defaultGAU.Id, message + 'Insert - Allocation 0');

        // Opportunity 3  - $20, Sum of Allocations < Opportunity Amount
        //                  Proposed Allocation DML: Inserts (Default GAU, $10)
        message = 'Opportunity 3 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByOppId.get(oppIds[3]), 1, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByOppId.get(oppIds[3]), null, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByOppId.get(oppIds[3]), null, message + 'Allocations - Delete');
        allocs = allocsForInsertByOppId.get(oppIds[3]);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, defaultGAU);
        alloc1 = null;
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[3], 10, null, defaultGAU.Id, message + 'Insert - Allocation 0');

        // Opportunity 4  - $20, Allocation has percent but not amount
        //                  Opportunity Allocations (GAU1, 100%, (null))
        //                  Proposed Allocation DML: Updates (GAU1, 100%, $20)
        message = 'Opportunity 4 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByOppId.get(oppIds[4]), null, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByOppId.get(oppIds[4]), 1, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByOppId.get(oppIds[4]), null, message + 'Allocations - Delete');
        allocs = allocsForUpdateByOppId.get(oppIds[4]);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        alloc1 = null;
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[4], 20, 100, gaus[1].Id, message + 'Update - Allocation 0');

        // Opportunity 5  - $0, Percent Allocation with non zero amount
        //                  Opportunity Allocations (GAU1, 50%, $20)
        //                  Proposed Allocation DML: Updates (GAU1, 50%, $0)
        message = 'Opportunity 5 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByOppId.get(oppIds[5]), null, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByOppId.get(oppIds[5]), 1, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByOppId.get(oppIds[5]), null, message + 'Allocations - Delete');
        allocs = allocsForUpdateByOppId.get(oppIds[5]);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        alloc1 = null;
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[5], 0, 50, gaus[1].Id, message + 'Update - Allocation 0');

        // Opportunity 6  - $20, Fully allocated at Opportunity level
        //                  Opportunity Allocations (GAU1, 100%, $20)
        //                  Proposed Allocation DML: None
        message = 'Opportunity 6 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByOppId.get(oppIds[6]), null, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByOppId.get(oppIds[6]), null, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByOppId.get(oppIds[6]), null, message + 'Allocations - Delete');

        // Opportunity 7  - $20, Fully allocated at Opportunity level
        //                  Opportunity Allocations (GAU1, 100%, $20)
        //                  Proposed Allocation DML: None
        message = 'Opportunity 7 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByOppId.get(oppIds[7]), null, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByOppId.get(oppIds[7]), null, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByOppId.get(oppIds[7]), null, message + 'Allocations - Delete');

        // Opportunity 8  - (null), Opportunity Allocations (Default GAU, $20)
        //                  Proposed Allocation DML: Deletes (Default GAU, $20)
        message ='Opportunity 8 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByOppId.get(oppIds[8]), null, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByOppId.get(oppIds[8]), null, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByOppId.get(oppIds[8]), 1, message + 'Allocations - Delete');
        allocs = allocsForDeleteByOppId.get(oppIds[8]);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, defaultGAU);
        alloc1 = null;
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[8], 20, null, alloSetupTest.getDefaultGAU().Id, message + 'Delete - Allocation 0');

        // Opportunity 9  - $20, Campaign Parent, No Allocations Present
        //                  Proposed Allocation DML: Inserts (GAU1, $10), (Default GAU, $10)
        message = 'Opportunity 9 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByOppId.get(oppIds[9]), 2, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByOppId.get(oppIds[9]), null, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByOppId.get(oppIds[9]), null, message + 'Allocations - Delete');
        allocs = allocsForInsertByOppId.get(oppIds[9]);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        alloc1 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, defaultGAU);
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[9], 10, null, gaus[1].Id, message + 'Insert - Allocation 0');
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc1, oppIds[9], 10, null, defaultGAU.Id, message + 'Insert - Allocation 1');

        // Opportunity 10 - $20, Allocations need resizing
        //                  Opportunity Allocations (GAU1, 50%, $40), (Default GAU, $40)
        //                  Proposed Allocation DML: Updates (GAU1, 50%, $10), (Default GAU, $10)
        message = 'Opportunity 10 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByOppId.get(oppIds[10]), null, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByOppId.get(oppIds[10]), 2, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByOppId.get(oppIds[10]), null, message + 'Allocations - Delete');
        allocs = allocsForUpdateByOppId.get(oppIds[10]);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        alloc1 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, defaultGAU);
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[10], 10, 50, gaus[1].Id, message + 'Update - Allocation 0');
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc1, oppIds[10], 10, null, defaultGAU.Id, message + 'Update - Allocation 1');

        // Opportunity 11 - $20, Invalid Allocation that cannot be corrected
        //                  Opportunity Allocations (GAU1, $40)
        //                  Result: Pending Error is added, because overallocated, and cannot fix automatically
        message = 'Opportunity 11 - ';
        System.assertEquals(true, allocWrapper.errorsByRecordId.containsKey(oppIds[11]), message + 'Has Errors');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByOppId.get(oppIds[11]), null, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByOppId.get(oppIds[11]), null, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByOppId.get(oppIds[11]), null, message + 'Allocations - Delete');

        // Opportunity 12 - $0, No Allocations (Default Allocation Handling)
        //                  Proposed Allocation DML: Insert (Default GAU, $0)
        message = 'Opportunity 12 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByOppId.get(oppIds[12]), 1, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByOppId.get(oppIds[12]), null, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByOppId.get(oppIds[12]), null, message + 'Allocations - Delete');
        allocs = allocsForInsertByOppId.get(oppIds[12]);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, defaultGAU);
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[12], 0, null, defaultGAU.Id, message + 'Insert - Allocation 0');

        // Opportunity 13 - $20, No Allocations (Default Allocation Handling)
        //                  Proposed Allocation DML: Insert (Default GAU, $20)
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

        ALLO_UnitTestHelper_TEST.assertSObjectList(allocWrapper.allocationsForDelete, 6, 'After Process Payment Allocations - Delete List');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocWrapper.allocationsForInsert, 3, 'After Process Payment Allocations - Insert List');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocWrapper.allocationsForUpdate, 5, 'After Process Payment Allocations - Update List');

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

        // Opportunity 6, Payment 0  - No Allocations are present
        //                             Proposed Allocation DML: Inserts (GAU1, 100%, $10)
        message = 'Opportunity 6, Payment 0 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByPmtId.get(pmts[0].Id), 1, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByPmtId.get(pmts[0].Id), null, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByPmtId.get(pmts[0].Id), null, message + 'Allocations - Delete');
        allocs = allocsForInsertByPmtId.get(pmts[0].Id);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        alloc1 = null;
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc0, pmts[0].Id, 10, 100, gaus[1].Id, message + 'Insert - Allocation 0');

        // Opportunity 6, Payment 1  - $10, Allocations Need Resizing
        //                             Payment Allocations (GAU0, 50%), (GAU1, $1). (Default GAU, $10)
        //                             Proposed Allocation DML: Updates (GAU0, 50%, $5), (Default GAU, $4)
        message = 'Opportunity 6, Payment 1 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByPmtId.get(pmts[1].Id), null, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByPmtId.get(pmts[1].Id), 2, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByPmtId.get(pmts[1].Id), null, message + 'Allocations - Delete');
        allocs = allocsForUpdateByPmtId.get(pmts[1].Id);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[0]);
        alloc1 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, defaultGAU);
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc0, pmts[1].Id, 5, 50, gaus[0].Id, message + 'Update - Allocation 0');
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc1, pmts[1].Id, 4, null, defaultGAU.Id, message + 'Update - Allocation 1');

        // Opportunity 6, Payment 2  - $10, Needs Default Allocation
        //                             Payment Allocations (GAU0, $1)
        //                             Proposed Allocation DML: Inserts (Default GAU, $9)
        message = 'Opportunity 6, Payment 2 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByPmtId.get(pmts[2].Id), 1, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByPmtId.get(pmts[2].Id), null, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByPmtId.get(pmts[2].Id), null, message + 'Allocations - Delete');
        allocs = allocsForInsertByPmtId.get(pmts[2].Id);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, defaultGAU);
        alloc1 = null;
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc0, pmts[2].Id, 9, null, defaultGAU.Id, message + 'Insert - Allocation 0');

        // Opportunity 6, Payment 3  - $10, Remove Default Allocation Because Fully Allocated
        //                             Payment Allocations (GAU0, 100%, $10), (Default GAU, $10)
        //                             Proposed Allocation DML: Deletes (Default GAU, $10)
        message = 'Opportunity 6, Payment 3 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByPmtId.get(pmts[3].Id), null, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByPmtId.get(pmts[3].Id), null, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByPmtId.get(pmts[3].Id), 1, message + 'Allocations - Delete');
        allocs = allocsForDeleteByPmtId.get(pmts[3].Id);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, defaultGAU);
        alloc1 = null;
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc0, pmts[3].Id, 10, null, defaultGAU.Id, message + 'Delete - Allocation 0');

        // Opportunity 6, Payment 4  - $0, Default Allocation needs resizing
        //                             Payment Allocations (Default GAU, $10)
        //                             Proposed Allocation DML: Updates (Default GAU, $0)
        message = 'Opportunity 6, Payment 4 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByPmtId.get(pmts[4].Id), null, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByPmtId.get(pmts[4].Id), 1, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByPmtId.get(pmts[4].Id), null, message + 'Allocations - Delete');
        allocs = allocsForUpdateByPmtId.get(pmts[4].Id);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, defaultGAU);
        alloc1 = null;
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc0, pmts[4].Id, 0, null, defaultGAU.Id, message + 'Update - Allocation 0');

        // Opportunity 6, Payment 5  - (null), Default Allocation to remove
        //                             Payment Allocations (Default GAU, $10)
        //                             Proposed Allocation DML: Updates (Default GAU, $0)
        message = 'Opportunity 6, Payment 5 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByPmtId.get(pmts[5].Id), null, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByPmtId.get(pmts[5].Id), null, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByPmtId.get(pmts[5].Id), 1, message + 'Allocations - Delete');
        allocs = allocsForDeleteByPmtId.get(pmts[5].Id);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, defaultGAU);
        alloc1 = null;
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc0, pmts[5].Id, 10, null, defaultGAU.Id, message + 'Delete - Allocation 0');

        // Opportunity 6, Payment 6  - $0, Percent Allocation to update
        //                             Payment Allocations (GAU0, 10%, $1)
        //                             Proposed Allocation DML: Updates (GAU0, 10%, $0)
        message = 'Opportunity 6, Payment 6 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByPmtId.get(pmts[6].Id), null, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByPmtId.get(pmts[6].Id), 1, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByPmtId.get(pmts[6].Id), null, message + 'Allocations - Delete');
        allocs = allocsForUpdateByPmtId.get(pmts[6].Id);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[0]);
        alloc1 = null;
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc0, pmts[6].Id, 0, 10, gaus[0].Id, message + 'Update - Allocation 0');

        // Opportunity 6, Payment 7  - (null), Percent Allocation to delete
        //                             Payment Allocations (GAU0, 10%, $1)
        //                             Proposed Allocation DML: Updates (GAU0, 10%, $0)
        message = 'Opportunity 6, Payment 7 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByPmtId.get(pmts[7].Id), null, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByPmtId.get(pmts[7].Id), null, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByPmtId.get(pmts[7].Id), 1, message + 'Allocations - Delete');
        allocs = allocsForDeleteByPmtId.get(pmts[7].Id);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[0]);
        alloc1 = null;
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc0, pmts[7].Id, 1, 10, gaus[0].Id, message + 'Delete - Allocation 0');

        // Opportunity 6, Payment 8  - $0, Percent Allocation to update, Default Allocation to remove
        //                             Payment Allocations (GAU0, 10%, $1), (Default GAU, $10)
        //                             Proposed Allocation DML: Updates (GAU0, 10%, $0); Deletes (Default GAU, $10)
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

        // Opportunity 6, Payment 9  - (null), Allocations to remove
        //                             Payment Allocations (GAU0, 10%, $1), (Default GAU, $10)
        //                             Proposed Allocation DML: Updates (GAU0, 10%, $0); Deletes (Default GAU, $10)
        message = 'Opportunity 6, Payment 9 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByPmtId.get(pmts[9].Id), null, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByPmtId.get(pmts[9].Id), null, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByPmtId.get(pmts[9].Id), 2, message + 'Allocations - Delete');
        allocs = allocsForDeleteByPmtId.get(pmts[9].Id);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[0]);
        alloc1 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, defaultGAU);
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc0, pmts[9].Id, 1, 10, gaus[0].Id, message + 'Delete - Allocation 0');
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc1, pmts[9].Id, 10, null, defaultGAU.Id, message + 'Delete - Allocation 1');

        // Opportunity 6, Payment 10 - $0, Needs Allocations
        //                             Proposed Allocation DML: Inserts (GAU1, 100%, $0)
        message = 'Opportunity 6, Payment 10 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByPmtId.get(pmts[10].Id), 1, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByPmtId.get(pmts[10].Id), null, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByPmtId.get(pmts[10].Id), null, message + 'Allocations - Delete');
        allocs = allocsForInsertByPmtId.get(pmts[10].Id);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc0, pmts[10].Id, 0, 100, gaus[1].Id, message + 'Insert - Allocation 0');

        // Opportunity 6, Payment 11 - (null), No changes required
        //                             Proposed Allocation DML: Inserts (GAU1, 100%, $0)
        message = 'Opportunity 6, Payment 11 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByPmtId.get(pmts[11].Id), null, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByPmtId.get(pmts[11].Id), null, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByPmtId.get(pmts[11].Id), null, message + 'Allocations - Delete');

        // Opportunity 6, Payment 12 - $10, Invalid Allocation (no amount or percent)
        //                             Payment Allocations (GAU1)
        //                             Result: Pending Error added, no proposed changes
        message = 'Opportunity 6, Payment 12 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByPmtId.get(pmts[12].Id), null, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByPmtId.get(pmts[12].Id), null, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByPmtId.get(pmts[12].Id), null, message + 'Allocations - Delete');
        System.assertEquals(true, allocWrapper.errorsByRecordId.containsKey(oppIds[6]), 'Opportunity 6 - Error Present');

        pmts = oppsById.get(oppIds[7]).npe01__OppPayment__r;

        // Opportunity 7, Payment 0  - $10, Fully allocated
        //                             Proposed Allocation DML: None
        message = 'Opportunity 7, Payment 0 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForInsertByPmtId.get(pmts[0].Id), null, message + 'Allocations - Insert');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForUpdateByPmtId.get(pmts[0].Id), null, message + 'Allocations - Update');
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocsForDeleteByPmtId.get(pmts[0].Id), null, message + 'Allocations - Delete');
    }

}