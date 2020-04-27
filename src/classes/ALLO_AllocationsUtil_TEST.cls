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
* @description Tests for ALLO_AllocationsUTIL class
*/
@IsTest(isParallel=true)
public class ALLO_AllocationsUtil_TEST {

    // Callable Method Declarations
    private static final String ALLO_VALIDATE_CONFIG_ACTION = 'ALLO.ValidatePmtAllocationConfig';
    private static final String ALLO_PROCESS_OPPS_PMTS_ACTION = 'ALLO.ProcessOppsAndPmts';

    /**
     * @description Confirm it returns the Opportunity Id for the Object Passed to It
     *              [ALLO_AllocationsUtil.getOpportunityIdFor]
     */
    @isTest
    private static void confirmGetOpportunityIdForReturnsTheOpportunityIdAssociatedWithTheObject() {
        List<Contact> ctcs = UTIL_UnitTestData_TEST.createMultipleTestContacts(1);
        insert ctcs;

        List<Opportunity> opps = UTIL_UnitTestData_TEST.oppsForContactList(ctcs, null, UTIL_UnitTestDATA_TEST.getClosedWonStage(), System.today().addDays(30), 20, null, null);

        insert opps;

        List<npe01__OppPayment__c> pmts = [SELECT   Id,
                                                    npe01__Opportunity__c
                                           FROM npe01__OppPayment__c];

        System.assertEquals(opps[0].Id, ALLO_AllocationsUtil.getOpportunityIdFor(opps[0]), 'Opportunity Id for Opportunity');
        System.assertEquals(opps[0].Id, ALLO_AllocationsUtil.getOpportunityIdFor(pmts[0]), 'Opportunity Id associated with Payment');
        System.assertEquals(null, ALLO_AllocationsUtil.getOpportunityIdFor(ctcs[0]), 'Other Objects will return null');
    }

    /**
     * @description Confirm it returns the right Amount depending on whether the Opportunity or the Payment is passed.
     *              [ALLO_AllocationsUtil.getAmountFor]
     */
    @isTest
    private static void confirmGetAmountForReturnsTheCorrectAmountDependingOnTheObject() {
        List<Contact> ctcs = UTIL_UnitTestData_TEST.createMultipleTestContacts(1);
        insert ctcs;

        Opportunity testOpportunity = new Opportunity(
            Amount = 1000
        );

        npe01__OppPayment__c testPayment = new npe01__OppPayment__c(
            npe01__Payment_Amount__c = 200
        );

        System.assertEquals(testPayment.npe01__Payment_Amount__c, ALLO_AllocationsUtil.getAmountFor(testPayment), 'Confirm getAmountFor with Payment');
        System.assertEquals(testOpportunity.Amount, ALLO_AllocationsUtil.getAmountFor(testOpportunity), 'Confirm getAmountFor with Opportunity');
        System.assertEquals(null, ALLO_AllocationsUtil.getAmountFor(ctcs[0]), 'Confirm getAmountFor With Unsupported Object');
    }

    /**
     * @description Confirm it returns the right Label for each of the supported objects
     *              [ALLO_AllocationsUtil.getLabelFor]
     */
    @isTest
    private static void confirmGetLabelForReturnsTheCorrectLabelDependingOnTheObject() {
        System.assertEquals(UTIL_Describe.getObjectLabel(UTIL_Namespace.StrTokenNSPrefix('Allocation__c')), ALLO_AllocationsUtil.getLabelFor(new Allocation__c()), 'Allocation Label');
        System.assertEquals(UTIL_Describe.getObjectLabel('Opportunity'), ALLO_AllocationsUtil.getLabelFor(new Opportunity()), 'Opportunity Label');
        System.assertEquals(UTIL_Describe.getObjectLabel('npe01__OppPayment__c'), ALLO_AllocationsUtil.getLabelFor(new npe01__OppPayment__c()), 'Payment Label');
    }

    /**
     * @description - Test invoke ALLO_AllocationsService via the Callable_Api class. Assert that
     * an opportunity is processed when meeting the criteria and excluded when the criteria are not met. Also
     * ensure that a default allocation is created for any unallocated amount.
     */
    @isTest
    private static void processOppsAndPaymentAllocationsViaCallableApi() {
        ALLO_UnitTestHelper_TEST.AllocationSetupTest alloSetupTest = new ALLO_UnitTestHelper_TEST.AllocationSetupTest()
            .enableDefaultAllocations()
            .enablePaymentAllocations()
            .disableAllocationTriggers()
            .applyConfiguration();

        List<General_Accounting_Unit__c> gaus = alloSetupTest.getGAUs();

        List<Contact> ctcs = UTIL_UnitTestData_TEST.createMultipleTestContacts(2);
        insert ctcs;

        List<Opportunity> opps = UTIL_UnitTestData_TEST.oppsForContactList(ctcs, null, UTIL_UnitTestDATA_TEST.getClosedWonStage(), System.today().addDays(30), 1000, null, null);
        insert opps;

        List<npe01__OppPayment__c> pmtsProcess = [select Id from npe01__OppPayment__c where npe01__Opportunity__c = :opps[0].Id];
        List<npe01__OppPayment__c> pmtsExclude = [select Id from npe01__OppPayment__c where npe01__Opportunity__c = :opps[1].Id];
        List<npe01__OppPayment__c> pmtsResizeDefault = [select Id from npe01__OppPayment__c where npe01__Opportunity__c = :opps[1].Id];

        List<Allocation__c> allosForInsert = new list<Allocation__c>();

        // Opportunity Allocations
        Allocation__c percentAlloOppProcess = new Allocation__c(Opportunity__c = opps[0].Id, Percent__c = 50, General_Accounting_Unit__c = gaus[0].Id);
        allosForInsert.add(percentAlloOppProcess);

        Allocation__c amountAlloOppProcess = new Allocation__c(Opportunity__c = opps[0].Id, Amount__c = 10, General_Accounting_Unit__c = gaus[1].id);
        allosForInsert.add(amountAlloOppProcess);

        Allocation__c percentAlloOppExclude = new Allocation__c(Opportunity__c = opps[1].Id, Percent__c = null, General_Accounting_Unit__c = gaus[0].Id);
        allosForInsert.add(percentAlloOppExclude);

        Allocation__c amountAlloOppExclude = new Allocation__c(Opportunity__c = opps[1].Id, Amount__c = null, General_Accounting_Unit__c = gaus[1].id);
        allosForInsert.add(amountAlloOppExclude);

        // Payment Allocations
        Allocation__c percentAlloPmtProcess = new Allocation__c(Payment__c = pmtsProcess[0].Id, Percent__c = 50, General_Accounting_Unit__c = gaus[0].Id);
        allosForInsert.add(percentAlloPmtProcess);

        Allocation__c amountAlloPmtProcess = new Allocation__c(Payment__c = pmtsProcess[0].Id, Amount__c = 10, General_Accounting_Unit__c = gaus[1].id);
        allosForInsert.add(amountAlloPmtProcess);

        Allocation__c percentAlloPmtExclude = new Allocation__c(Payment__c = pmtsExclude[0].Id, Percent__c = null, General_Accounting_Unit__c = gaus[0].Id);
        allosForInsert.add(percentAlloPmtExclude);

        Allocation__c amountAlloPmtExclude = new Allocation__c(Payment__c = pmtsExclude[0].Id, Amount__c = null, General_Accounting_Unit__c = gaus[1].id);
        allosForInsert.add(amountAlloPmtExclude);

        insert allosForInsert;

        Set<Id> oppIds = new Set<Id>();
        oppIds.add(opps[0].id);

        Test.startTest();

        Map<String, Object> npspApiParams = new Map<String, Object> {
                'OpportunityIds' => oppIds,
                'ContextType' => 'testContext',
                'DisableAllocationTriggers' => true
            };

        Callable npspApi = (Callable) Type.forName('Callable_API').newInstance();
        Set<Id> sucessfullyProcessedOpps = (Set<Id>)npspApi.call(ALLO_PROCESS_OPPS_PMTS_ACTION, npspApiParams);

        List<Allocation__c> pmtAllocations = [
            SELECT Id, General_Accounting_Unit__c, Amount__c, Payment__c, Percent__c, Opportunity__c
            FROM Allocation__c
            WHERE Payment__c = :pmtsProcess[0].Id and General_Accounting_Unit__c = :gaus[2].id];

        Test.stopTest();

        System.debug(pmtAllocations);

        System.assert(sucessfullyProcessedOpps.contains(opps[0].id), 'Opportunity 0 was not processed successfully.');
        System.assertEquals(490.00, pmtAllocations[0].Amount__c, 'Payment Default Allocation Amount');
        System.assert(!sucessfullyProcessedOpps.contains(opps[1].id), 'Oppportunity 1 was processed and should have been excluded');
    }

    /**
     * @description Test validating the Payment Allocation Configuration via Callable_Api when the settings
     * are configured properly.
     */
    @isTest
    private static void validatePaymentAllocationConfigurationViaCallableApiNoErrors() {
        Test.startTest();

        ALLO_UnitTestHelper_TEST.AllocationSetupTest alloSetupTest = new ALLO_UnitTestHelper_TEST.AllocationSetupTest()
            .enableDefaultAllocations()
            .enablePaymentAllocations()
            .applyConfiguration();

        Callable npspApi = (Callable) Type.forName('Callable_API').newInstance();
        Map<String, Object> npspApiParams = new Map<String, Object>();
        List<String> configProblems = (List<String>)npspApi.call(ALLO_VALIDATE_CONFIG_ACTION, npspApiParams);

        Test.stopTest();

        System.assertEquals(true, configProblems.isEmpty(), 'Payment Allocation configuration check returned errors');
    }

    /**
     * @description Test validating the Payment Allocation Configuration via Callable_Api when the settings
     * are not configured properly.
     */
    @isTest
    private static void validatePaymentAllocationConfigurationViaCallableApiWithErrors() {
        Test.startTest();

        Callable npspApi = (Callable) Type.forName('Callable_API').newInstance();
        Map<String, Object> npspApiParams = new Map<String, Object>();
        List<String> configProblems = (List<String>)npspApi.call(ALLO_VALIDATE_CONFIG_ACTION, npspApiParams);

        Test.stopTest();

        System.assertEquals(false, configProblems.isEmpty(), 'Payment Allocation configuration validated - Errors were expected');
    }
}