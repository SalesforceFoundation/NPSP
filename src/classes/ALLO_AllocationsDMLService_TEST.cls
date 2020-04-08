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


    @isTest
    private static void confirmProcessAllocationsResultsExecutesDMLWherePossibleAndGeneratesErrorsWhereNot() {
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

        String message = null;
        Allocation__c alloc0 = null;
        Allocation__c alloc1 = null;

        List<Allocation__c> allocs = allocWrapper.oppsAllocations.get(oppIds[0]);
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[0]);
        alloc1 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        alloc1.Amount__c = 20;
        allocWrapper.allocationsForUpdate.add(alloc1);
        allocWrapper.allocationsForDelete.add(alloc0);
        // Should cause an issue, rollback, and remove oppIds[6] related DML....
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

        ALLO_AllocationsDMLService allocDMLSvc = new ALLO_AllocationsDMLService()
                                                    .withAllocationsWrapper(allocWrapper);

        allocDMLSvc.processAllocationResults();

        // Re-retrieve Data after DML
        allocWrapper = new ALLO_AllocationsRetrievalService()
                                                        .withOpportunities(oppIdsAsSet)
                                                        .retrieveData()
                                                        .allocationsWrapper;


        message = 'Opportunity 2 - ';
        allocs = allocWrapper.oppsAllocations.get(oppIds[2]);
        ALLO_UnitTestHelper_TEST.assertSObjectList(allocs, 2, message + 'Allocations');
        alloc0 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, gaus[1]);
        alloc1 = ALLO_UnitTestHelper_TEST.findByGAU(allocs, defaultGAU);
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc0, oppIds[2], 10, 50, gaus[1].Id, message + 'Allocation 0');
        ALLO_UnitTestHelper_TEST.assertOpportunityAllocation(alloc1, oppIds[2], 10, null, defaultGAU.Id, message + 'Allocation 1');
    }


}