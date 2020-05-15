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
* @description Tests for ALLO_AllocationsReviewService class
*/
@IsTest(isParallel=true)
public class ALLO_AllocationsReviewService_TEST {

     /**
     * @description Confirm Review Service correctly identifies records requiring review when
     *              Default Allocations Enabled
     *              Payment Allocations Disabled
     *              [ALLO_AllocationsReviewService.evaluateAllocations]
     */
    @isTest
    private static void confirmOnlyAllocationsRequiringReviewAreIdentifiedDefaultAllocationsEnabledPaymentAllocationsDisabled() {
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

        List<Boolean> expectedValues = new List<Boolean> {
            false, // Opportunity 0 - Properly allocated, Parent Recurring Donation
            true,  // Opportunity 1 - No allocations present, Parent Recurring Donation
            true,  // Opportunity 2 - No allocations present, no parent
            true,  // Opportunity 3 - Sum of allocations < Opportunity Amount
            true,  // Opportunity 4 - Allocations with Percent and no Amount
            true,  // Opportunity 5 - Opportunity Amount 0 with non zero Allocations
            false, // Opportunity 6 - Opportunity fully allocated
            false, // Opportunity 7 - Opportunity fully allocated
            true,  // Opportunity 8 - Opportunity with Null Amount and Non Zero fixed amount for Default Allocation
            true,  // Opportunity 9 - No allocations, Parent Campaign
            true,  // Opportunity 10 - Existing Allocations, resize required
            true   // Opportunity 11 - Invalid Existing Fixed Allocation too large for Opportunity Amount
        };

        for (Integer i=0; i < expectedValues.size(); i++) {
            Id oppId = oppIds[i];
            Boolean expectedValue = expectedValues[i];
            System.assertEquals(expectedValue, oppIdsForReview.contains(oppId), 'Opportunity #' + i + ' - Flagged for Review');
        }
    }

    /**
     * @description Confirm Review Service correctly identifies records requiring review when
     *              Default Allocations Disabled
     *              Payment Allocations Disabled
     *              [ALLO_AllocationsReviewService.evaluateAllocations]
     */
    @isTest
    private static void confirmOnlyAllocationsRequiringReviewAreIdentifiedDefaultAllocationsDisabledPaymentAllocationsDisabled() {
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

        List<Boolean> expectedValues = new List<Boolean> {
            false, // Opportunity 0 - Properly allocated, Parent Recurring Donation
            true,  // Opportunity 1 - No allocations present, Parent Recurring Donation
            false,  // Opportunity 2 - No allocations present, no parent
            false,  // Opportunity 3 - Sum of allocations < Opportunity Amount
            true,  // Opportunity 4 - Allocations with Percent and no Amount
            true,  // Opportunity 5 - Opportunity Amount 0 with non zero Allocations
            false, // Opportunity 6 - Opportunity fully allocated
            false, // Opportunity 7 - Opportunity fully allocated
            true,  // Opportunity 8 - Opportunity with Null Amount and Allocation with non zero amount with percent value for GAU 2
            true,  // Opportunity 9 - No allocations, Parent Campaign
            true,  // Opportunity 10 - Existing Allocations, resize required
            true   // Opportunity 11 - Invalid Existing Fixed Allocation too large for Opportunity Amount
        };

        for (Integer i=0; i < expectedValues.size(); i++) {
            Id oppId = oppIds[i];
            Boolean expectedValue = expectedValues[i];
            System.assertEquals(expectedValue, oppIdsForReview.contains(oppId), 'Opportunity #' + i + ' - Flagged for Review');
        }
    }

    /**
     * @description Confirm Review Service correctly identifies records requiring review when
     *              Default Allocations Enabled
     *              Payment Allocations Enabled
     *              [ALLO_AllocationsReviewService.evaluateAllocations]
     */
    @isTest
    private static void confirmOnlyAllocationsRequiringReviewAreIdentifiedDefaultAllocationsEnabledPaymentAllocationsEnabled() {
        ALLO_UnitTestHelper_TEST.AllocationSetupTest alloSetupTest = new ALLO_UnitTestHelper_TEST.AllocationSetupTest()
            .disableAllocationTriggers()
            .enableDefaultAllocations()
            .enablePaymentAllocations()
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

        List<Boolean> expectedValues = new List<Boolean> {
            false, // Opportunity 0 - Properly allocated, Parent Recurring Donation
            true,  // Opportunity 1 - No allocations present, Parent Recurring Donation
            true,  // Opportunity 2 - No allocations present, no parent
            true,  // Opportunity 3 - Sum of allocations < Opportunity Amount
            true,  // Opportunity 4 - Allocations with Percent and no Amount
            true,  // Opportunity 5 - Opportunity Amount 0 with non zero Allocations
            true, // Opportunity 6 - Opportunity fully allocated, Payment Allocations require review
            false, // Opportunity 7 - Opportunity fully allocated
            true,  // Opportunity 8 - Opportunity with Null Amount and Allocation with non zero amount with percent value for GAU 2
            true,  // Opportunity 9 - No allocations, Parent Campaign
            true,  // Opportunity 10 - Existing Allocations, resize required
            true   // Opportunity 11 - Invalid Existing Fixed Allocation too large for Opportunity Amount
        };

        for (Integer i=0; i < expectedValues.size(); i++) {
            Id oppId = oppIds[i];
            Boolean expectedValue = expectedValues[i];
            System.assertEquals(expectedValue, oppIdsForReview.contains(oppId), 'Opportunity #' + i + ' - Flagged for Review');
        }
    }

    /**
     * @description Confirm Review Service flags Opportunity for Allocation when
     *              Payment Amount is null and no Allocations are present for Payment and Payment Allocations are enabled
     *              Fix for W-041448
     *              Default Allocations Enabled
     *              Payment Allocations Enabled
     *              [ALLO_AllocationsReviewService.evaluateAllocations]
     */
    @isTest
    private static void confirmReviewRequiredForPaymentAllocationsWhenAmountIsNullAndNoPaymentAllocationsArePresent() {
        ALLO_UnitTestHelper_TEST.AllocationSetupTest alloSetupTest = new ALLO_UnitTestHelper_TEST.AllocationSetupTest()
            .disableAllocationTriggers()
            .enableDefaultAllocations()
            .enablePaymentAllocations()
            .applyConfiguration();

            List<Contact> ctcs = UTIL_UnitTestData_TEST.createMultipleTestContacts(2);
            insert ctcs;

            List<Opportunity> opps = UTIL_UnitTestData_TEST.oppsForContactList(ctcs, null, UTIL_UnitTestDATA_TEST.getClosedWonStage(), System.today().addDays(30), 20, null, null);
            opps[0].npe01__Do_Not_Automatically_Create_Payment__c = true;
            opps[1].npe01__Do_Not_Automatically_Create_Payment__c = true;

            insert opps;

            List<npe01__OppPayment__c> pmts = new List<npe01__OppPayment__c> {
                new npe01__OppPayment__c(
                    npe01__Payment_Amount__c = null,
                    npe01__Opportunity__c = opps[0].Id,
                    npe01__Scheduled_Date__c = System.today()
                ),
                new npe01__OppPayment__c(
                    npe01__Payment_Amount__c = null,
                    npe01__Opportunity__c = opps[1].Id,
                    npe01__Scheduled_Date__c = System.today().addDays(1)
                )
            };

            insert pmts;

            List<General_Accounting_Unit__c> gaus = alloSetupTest.getGAUs();

            List<Allocation__c> allosForInsert = new list<Allocation__c> {
                new Allocation__c(
                    Opportunity__c = opps[0].Id, Amount__c = 20, Percent__c = 100, General_Accounting_Unit__c = gaus[1].id
                ),
                new Allocation__c(
                    Opportunity__c = opps[1].Id, Amount__c = 20, General_Accounting_Unit__c = gaus[1].id
                )
            };

            insert allosForInsert;


        Set<Id> oppIdsAsSet = new Set<Id>();
        oppIdsAsSet.add(opps[0].Id);
        oppIdsAsSet.add(opps[1].Id);

        ALLO_AllocationsWrapper allocWrapper = new ALLO_AllocationsRetrievalService()
                                                .withOpportunities(oppIdsAsSet)
                                                .retrieveData()
                                                .allocationsWrapper;

        ALLO_AllocationsReviewService allocReviewSvc = new ALLO_AllocationsReviewService()
                                                            .withAllocationsWrapper(allocWrapper);

        Set<Id> oppIdsForReview = allocReviewSvc.evaluateAllocations();

        Set<Id> expectedOppIdsForReview = new Set<Id> {opps[0].Id, opps[1].Id};

        System.assertEquals(true, oppIdsForReview.contains(opps[0].Id), 'Opportunity 0 - Opportunity Allocation 100% GAU1, Null Payment Amount, No Payment Allocations');
        System.assertEquals(true, oppIdsForReview.contains(opps[1].Id), 'Opportunity 1 - Opportunity Allocation $20 GAU1, Null Payment Amount, No Payment Allocations');
    }
}