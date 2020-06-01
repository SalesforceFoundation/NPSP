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
* @description Tests for ALLO_AllocationsDMLService class
*/
@IsTest(isParallel=true)
public class ALLO_AllocationsDMLService_TEST {

    /**
     * @description Confirms DML Processing with partial success
     *              [ALLO_AllocationsDMLService.processAllocationResults]
     */
    @isTest
    private static void confirmProcessOpportunityAllocationsResultsWithFailingAndSuccessfulDML() {
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

        List<General_Accounting_Unit__c> gaus = alloSetupTest.getGAUs();
        General_Accounting_Unit__c defaultGAU = alloSetupTest.getDefaultGAU();

        List<Allocation__c> allocs = null;
        String message = null;
        Allocation__c alloc0 = null;
        Allocation__c alloc1 = null;

        String baseMessage = 'Before DML - ';
        // Confirming state before DML Execution
        message = baseMessage + 'Opportunity 0 - ';
        allocs = allocWrapper.oppsAllocations.get(oppIds[0]);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 2, message + 'Allocations');
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[0]);
        alloc1 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[0], 10, 50, gaus[0].Id, message + 'Allocation 0');
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc1, oppIds[0], 10, null, gaus[1].Id, message + 'Allocation 1');

        // Confirming state before DML Execution
        message = baseMessage + 'Opportunity 2 - ';
        allocs = allocWrapper.oppsAllocations.get(oppIds[2]);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 0, message + 'Allocations');

        message = baseMessage + 'Opportunity 6 - ';
        allocs = allocWrapper.oppsAllocations.get(oppIds[6]);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 1, message + 'Allocations');
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        alloc1 = null;
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[6], 20, 100, gaus[1].Id, message + 'Allocation 0');

        Map<Id, Error__c> errsByRecordId = ALLO_UnitTestHelper_TEST.getErrorsByRecordId();
        System.assertEquals(0, errsByRecordId.size(), 'No Errors Present');

        // Added Update for Opportunity 0 Allocation 1, and Delete for Opportunity 0 Allocation 0
        allocs = allocWrapper.oppsAllocations.get(oppIds[0]);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[0]);
        alloc1 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        alloc1.Amount__c = 20;
        allocWrapper.allocationsForUpdate.add(alloc1);
        allocWrapper.allocationsForDelete.add(alloc0);

        // Adding Test Functional Errors for Opportunity 1
        allocWrapper.errorsByRecordId.put(oppIds[1], new List<String> {'Test Error 1', 'Test Error 2'});

        // Adding additional records to insert for Opportunity 2
        allocWrapper.allocationsForInsert.add(
            new Allocation__c(
                Opportunity__c = oppIds[2],
                Amount__c = 10,
                Percent__c = 50,
                General_Accounting_Unit__c = gaus[1].Id
            )
        );
        allocWrapper.allocationsForInsert.add(
            new Allocation__c(
                Opportunity__c = oppIds[2],
                Amount__c = 10,
                Percent__c = null,
                General_Accounting_Unit__c = defaultGAU.Id
            )
        );

        // Added both a valid and an invalid allocation for Opportunity 6, with a valid insert Allocation,
        // and an invalid update Allocation
        allocWrapper.allocationsForInsert.add(
            new Allocation__c(
                Opportunity__c = oppIds[6],
                Amount__c = 0,

                General_Accounting_Unit__c = defaultGAU.Id
            )
        );
        allocWrapper.allocationsForUpdate.add(
            new Allocation__c(
                Opportunity__c = oppIds[6],
                Amount__c = 0,
                General_Accounting_Unit__c = defaultGAU.Id
            )
        );

        Set<ALLO_AllocationsService.processDefinitionType> processExclusions = ALLO_AllocationsService.processExclusions.get(ALLO_AllocationsService.processDefinitionType.OPP_ALLOC_UPD);

        Test.startTest();
        ERR_RecordError recErr = new ERR_RecordError('Test');
        ALLO_AllocationsDMLService allocDMLSvc = new ALLO_AllocationsDMLService()
                                                    .withAllocationsWrapper(allocWrapper)
                                                    .withProcessExclusions(processExclusions)
                                                    .withAlternateRecordErrorsLogger(recErr);
        allocDMLSvc.processAllocationResults();
        Test.stopTest();

        // Clear internal variables
        message = 'After Reset - ';
        allocDMLSvc.reset();
        message = 'After Reset';
        System.assertEquals(0, allocDMLSvc.recordIdsWithErrors.size(), message + '# of Record Ids With Errors');
        System.assertEquals(0, allocDMLSvc.allRecordIdsWithDML.size(), message + '# of Record Ids With DML');
        System.assertEquals(null, allocDMLSvc.allocationsWrapper, message + 'Allocation Wrapper');
        System.assertEquals(0, allocDMLSvc.processExclusions.size(), message + 'Process Exclusions');

        // Commit Record Errors
        recErr.processErrors();

        // Confirm exclusions before re-retrieving data
        Set<Id> oppIdsWithExcl = new Set<Id> { oppIds[1], oppIds[6]};

        Integer idx =0;
        for (Id oppId : oppIds) {
            Boolean exclPresent = oppIdsWithExcl.contains(oppId);
            for (ALLO_AllocationsService.processDefinitionType excl : processExclusions) {
                System.assertEquals (exclPresent, allocWrapper.hasExclusion(oppId, excl), 'Opportunity ' + idx + ', Has Exclusion: ' + excl);
            }
            idx++;
        }

        // Re-retrieve Data after DML
        allocWrapper = new ALLO_AllocationsRetrievalService()
                            .withOpportunities(oppIdsAsSet)
                            .retrieveData()
                            .allocationsWrapper;

        baseMessage = 'After DML - ';

        // Was allowed to update 1 record and delete the other during retry since no Allocation errors relating to Opp #0 occurred
        message = baseMessage + 'Opportunity 0 - ';
        allocs = allocWrapper.oppsAllocations.get(oppIds[0]);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 1, message + 'Allocations');
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[0], 20, null, gaus[1].Id, message + 'Allocation 0');

        // Was allowed to insert during retry since no Allocation errors relating to Opp #2 occurred
        message = baseMessage + 'Opportunity 2 - ';
        allocs = allocWrapper.oppsAllocations.get(oppIds[2]);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 2, message + 'Allocations');
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        alloc1 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, defaultGAU);
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[2], 10, 50, gaus[1].Id, message + 'Allocation 0');
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc1, oppIds[2], 10, null, defaultGAU.Id, message + 'Allocation 1');

        // Failed, and was removed on retry because of invalid update.
        message = baseMessage + 'Opportunity 6 - ';
        allocs = allocWrapper.oppsAllocations.get(oppIds[6]);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 1, message + 'Allocations');
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        alloc1 = null;
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[6], 20, 100, gaus[1].Id, message + 'Allocation 0');

        errsByRecordId = ALLO_UnitTestHelper_TEST.getErrorsByRecordId();
        System.assertEquals (2, errsByRecordId.size(), baseMessage + '# of Errors');
        System.assertEquals(true, errsByRecordId.containsKey(oppIds[1]), baseMessage + 'Error is present for Opportunity 1');
        Error__c opp0Err = errsByRecordId.get(oppIds[1]);
        System.assertEquals(true, opp0Err.Full_Message__c.contains('Test Error 1'), 'Functional Error 1 for Opportunity 1');
        System.assertEquals(true, opp0Err.Full_Message__c.contains('Test Error 2'), 'Functional Error 2 for Opportunity 1');
        System.assertEquals(true, errsByRecordId.containsKey(oppIds[6]), baseMessage + 'Error is present for Opportunity 6');
    }

    /**
     * @description Confirms DML Processing With Failures and Retries Exceeded
     *              [ALLO_AllocationsDMLService.processAllocationResults]
     */
    @isTest
    private static void confirmProcessOpportunityAllocationsResultsWithFailingAndRetriesExceeded() {
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


        List<General_Accounting_Unit__c> gaus = alloSetupTest.getGAUs();
        General_Accounting_Unit__c defaultGAU = alloSetupTest.getDefaultGAU();

        List<Allocation__c> allocs = null;
        String message = null;
        Allocation__c alloc0 = null;
        Allocation__c alloc1 = null;

        String baseMessage = 'Before DML - ';
        // Confirming state before DML Execution
        message = baseMessage + 'Opportunity 0 - ';
        allocs = allocWrapper.oppsAllocations.get(oppIds[0]);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 2, message + 'Allocations');
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[0]);
        alloc1 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[0], 10, 50, gaus[0].Id, message + 'Allocation 0');
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc1, oppIds[0], 10, null, gaus[1].Id, message + 'Allocation 1');

        // Confirming state before DML Execution
        message = baseMessage + 'Opportunity 2 - ';
        allocs = allocWrapper.oppsAllocations.get(oppIds[2]);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 0, message + 'Allocations');

        message = baseMessage + 'Opportunity 6 - ';
        allocs = allocWrapper.oppsAllocations.get(oppIds[6]);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 1, message + 'Allocations');
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        alloc1 = null;
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[6], 20, 100, gaus[1].Id, message + 'Allocation 0');

        Map<Id, Error__c> errsByRecordId = ALLO_UnitTestHelper_TEST.getErrorsByRecordId();
        System.assertEquals(0, errsByRecordId.size(), 'No Errors Present');

        // Added Update for Opportunity 0 Allocation 1, and Delete for Opportunity 0 Allocation 0
        allocs = allocWrapper.oppsAllocations.get(oppIds[0]);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[0]);
        alloc1 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        alloc1.Amount__c = 20;
        allocWrapper.allocationsForUpdate.add(alloc1);
        allocWrapper.allocationsForDelete.add(alloc0);

        // Adding Test Functional Errors for Opportunity 1
        allocWrapper.errorsByRecordId.put(oppIds[1], new List<String> {'Test Error 1', 'Test Error 2'});

        // Adding additional records to insert for Opportunity 2
        allocWrapper.allocationsForInsert.add(
            new Allocation__c(
                Opportunity__c = oppIds[2],
                Amount__c = 10,
                Percent__c = 50,
                General_Accounting_Unit__c = gaus[1].Id
            )
        );
        allocWrapper.allocationsForInsert.add(
            new Allocation__c(
                Opportunity__c = oppIds[2],
                Amount__c = 10,
                Percent__c = null,
                General_Accounting_Unit__c = defaultGAU.Id
            )
        );

        // Added both a valid and an invalid allocation for Opportunity 6, with a valid insert Allocation,
        // and an invalid update Allocation
        allocWrapper.allocationsForInsert.add(
            new Allocation__c(
                Opportunity__c = oppIds[6],
                Amount__c = 0,

                General_Accounting_Unit__c = defaultGAU.Id
            )
        );
        allocWrapper.allocationsForUpdate.add(
            new Allocation__c(
                Opportunity__c = oppIds[6],
                Amount__c = 0,
                General_Accounting_Unit__c = defaultGAU.Id
            )
        );

        Set<ALLO_AllocationsService.processDefinitionType> processExclusions = ALLO_AllocationsService.processExclusions.get(ALLO_AllocationsService.processDefinitionType.OPP_ALLOC_UPD);

        Test.startTest();
        ERR_RecordError recErr = new ERR_RecordError('Test');
        ALLO_AllocationsDMLService allocDMLSvc = new ALLO_AllocationsDMLService()
                                                    .withAllocationsWrapper(allocWrapper)
                                                    .withProcessExclusions(processExclusions)
                                                    .withAlternateRecordErrorsLogger(recErr);
        ALLO_AllocationsDMLService.numberOfDatabaseRetries = 0;
        allocDMLSvc.processAllocationResults();
        Test.stopTest();

        // Commit RecordErrrors
        recErr.processErrors();

        Integer idx =0;
        for (Id oppId : oppIds) {
            // All Opportunities should have exclusions
            Boolean exclPresent = true;
            for (ALLO_AllocationsService.processDefinitionType excl : processExclusions) {
                System.assertEquals (exclPresent, allocWrapper.hasExclusion(oppId, excl), 'Opportunity ' + idx + ', Has Exclusion: ' + excl);
            }
            idx++;
        }

        // Re-retrieve Data after DML
        allocWrapper = new ALLO_AllocationsRetrievalService()
                            .withOpportunities(oppIdsAsSet)
                            .retrieveData()
                            .allocationsWrapper;

        baseMessage = 'After DML - ';

        message = baseMessage + 'Opportunity 0 - ';
        allocs = allocWrapper.oppsAllocations.get(oppIds[0]);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 2, message + 'Allocations');
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[0]);
        alloc1 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[0], 10, 50, gaus[0].Id, message + 'Allocation 0');
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc1, oppIds[0], 10, null, gaus[1].Id, message + 'Allocation 1');

        // Confirming state before DML Execution
        message = baseMessage + 'Opportunity 2 - ';
        allocs = allocWrapper.oppsAllocations.get(oppIds[2]);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 0, message + 'Allocations');

        message = baseMessage + 'Opportunity 6 - ';
        allocs = allocWrapper.oppsAllocations.get(oppIds[6]);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 1, message + 'Allocations');
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        alloc1 = null;
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[6], 20, 100, gaus[1].Id, message + 'Allocation 0');

        errsByRecordId = ALLO_UnitTestHelper_TEST.getErrorsByRecordId();
        // All Opportunities will have one or more errors.
        System.assertEquals (14, errsByRecordId.size(), baseMessage + '# of Errors');
        Error__c opp0Err = errsByRecordId.get(oppIds[1]);
        System.assertEquals(true, opp0Err.Full_Message__c.contains('Test Error 1'), 'Functional Error 1 for Opportunity 1');
        System.assertEquals(true, opp0Err.Full_Message__c.contains('Test Error 2'), 'Functional Error 2 for Opportunity 1');
    }

    /**
     * @description Confirms DML Processing of Payment Allocations with partial success
     *              [ALLO_AllocationsDMLService.processAllocationResults]
     */
    @isTest
    private static void confirmProcessPaymentAllocationsResultsWithFailingAndSuccessfulDML() {
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

        List<General_Accounting_Unit__c> gaus = alloSetupTest.getGAUs();
        General_Accounting_Unit__c defaultGAU = alloSetupTest.getDefaultGAU();

        List<Allocation__c> allocs;
        Allocation__c alloc0;
        Allocation__c alloc1;
        Allocation__c alloc2;
        String baseMessage = 'Before Update';
        String message;

        Map<Id, Opportunity> oppsById = new Map<Id, Opportunity>([SELECT    Id,
                                                                            (SELECT     Id
                                                                            FROM npe01__OppPayment__r
                                                                            ORDER BY npe01__Scheduled_Date__c ASC
                                                                            )
                                                                    FROM Opportunity
                                                                    WHERE Id in :oppIds]);

        List<npe01__OppPayment__c> pmts = oppsById.get(oppIds[6]).npe01__OppPayment__r;

        // Opportunity 6 - Payment 0
        allocWrapper.allocationsForInsert.add(
            new Allocation__c(
                Payment__c=pmts[0].Id, Amount__c = 20, Percent__c = 100, General_Accounting_Unit__c = gaus[1].Id
            )
        );

        // Opportunity 6 - Payment 1 (Will change Default Alloc and GAU 0 to $5, and delete the $1 Allocation for GAU1)
        allocs = allocWrapper.paymentAllocations.get(pmts[1].Id);
        message = baseMessage + 'Opportunity 6 - Payment 1 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 3, message + 'Allocations');
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[0]);
        alloc1 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        alloc2 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, defaultGAU);

        alloc0.Amount__c = 5;
        allocWrapper.allocationsForUpdate.add(alloc0);
        allocWrapper.allocationsForDelete.add(alloc1);
        alloc2.Amount__c = 5;
        allocWrapper.allocationsForUpdate.add(alloc2);

        // Opportunity 6 - Payment 3 (Changing 1st allocation to GAU[1], Deleting 2nd allocation, and attempting an invalid update)
        message = baseMessage + 'Opportunity 6 - Payment 3 - ';
        allocs = allocWrapper.paymentAllocations.get(pmts[3].Id);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 2, message + 'Allocations');
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[0]);
        alloc1 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, defaultGAU);
        alloc2 = null;

        alloc0.General_Accounting_Unit__c = gaus[1].Id;
        allocWrapper.allocationsForUpdate.add(alloc0);
        allocWrapper.allocationsForDelete.add(alloc1);
        allocWrapper.allocationsForUpdate.add(
            new Allocation__c(
                Payment__c = pmts[3].Id,
                Amount__c = 10,
                General_Accounting_Unit__c = defaultGAU.Id
            )
        );

        Set<ALLO_AllocationsService.processDefinitionType> processExclusions = ALLO_AllocationsService.processExclusions.get(ALLO_AllocationsService.processDefinitionType.PMT_ALLOC);

        Test.startTest();
        ERR_RecordError recErr = new ERR_RecordError('Test');
        ALLO_AllocationsDMLService allocDMLSvc = new ALLO_AllocationsDMLService()
                                                    .withAllocationsWrapper(allocWrapper)
                                                    .withProcessExclusions(processExclusions)
                                                    .withAlternateRecordErrorsLogger(recErr);
        allocDMLSvc.processAllocationResults();
        Test.stopTest();

        // Clear internal variables
        message = 'After Reset - ';
        allocDMLSvc.reset();
        message = 'After Reset';
        System.assertEquals(0, allocDMLSvc.recordIdsWithErrors.size(), message + '# of Record Ids With Errors');
        System.assertEquals(0, allocDMLSvc.allRecordIdsWithDML.size(), message + '# of Record Ids With DML');
        System.assertEquals(null, allocDMLSvc.allocationsWrapper, message + 'Allocation Wrapper');
        System.assertEquals(0, allocDMLSvc.processExclusions.size(), message + 'Process Exclusions');

        // Commit Record Errors
        recErr.processErrors();

        // Confirm exclusions before re-retrieving data
        Set<Id> oppIdsWithExcl = new Set<Id> { oppIds[6] };

        Integer idx =0;
        for (Id oppId : oppIds) {
            Boolean exclPresent = oppIdsWithExcl.contains(oppId);
            for (ALLO_AllocationsService.processDefinitionType excl : processExclusions) {
                System.assertEquals (exclPresent, allocWrapper.hasExclusion(oppId, excl), 'Opportunity ' + idx + ', Has Exclusion: ' + excl);
            }
            idx++;
        }

        // Re-retrieve Data after DML
        allocWrapper = new ALLO_AllocationsRetrievalService()
                            .withOpportunities(oppIdsAsSet)
                            .retrieveData()
                            .allocationsWrapper;

        baseMessage = 'After DML - ';

        // Opportunity 6 - Payment 0
        message = baseMessage + 'Opportunity 6 - Payment 0 - ';
        allocs = allocWrapper.paymentAllocations.get(pmts[0].Id);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 1, message + 'Allocations');
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        alloc1 = null;
        alloc2 = null;
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc0, pmts[0].Id, 20, 100, gaus[1].Id, message + 'Allocation 0');

        // Opportunity 6 - Payment 1
        allocs = allocWrapper.paymentAllocations.get(pmts[1].Id);
        message = baseMessage + 'Opportunity 6 - Payment 1 - ';
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 2, message + 'Allocations');
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[0]);
        alloc1 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, defaultGAU);
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc0, pmts[1].Id, 5, 50, gaus[0].Id, message + 'Allocation 0');
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc1, pmts[1].Id, 5, null, defaultGAU.Id, message + 'Allocation 0');

        // Opportunity 6 - Payment 3 - No changes.  Error should be present
        message = baseMessage + 'Opportunity 6 - Payment 3 - ';
        allocs = allocWrapper.paymentAllocations.get(pmts[3].Id);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 2, message + 'Allocations');
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[0]);
        alloc1 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, defaultGAU);
        alloc2 = null;
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc0, pmts[3].Id, 10, 100, gaus[0].Id, message + 'Allocation 0');
        ALLO_UnitTestHelper_TEST.assertPaymentAllocation(alloc1, pmts[3].Id, 10, null, defaultGAU.Id, message + 'Allocation 1');

        Map<Id, Error__c> errsByRecordId = ALLO_UnitTestHelper_TEST.getErrorsByRecordId();
        System.assertEquals (1, errsByRecordId.size(), baseMessage + '# of Errors');
        System.assertEquals(true, errsByRecordId.containsKey(pmts[3].Id), baseMessage + 'Error is present for Opportunity 6 - Payment 3');
    }
}