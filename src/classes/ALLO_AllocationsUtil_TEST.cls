/*
    Copyright (c) 2019, Salesforce.org
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
* @date 2019
* @group Allocations
* @group-content ../../ApexDocContent/Allocations.htm
* @description Tests for ALLO_AllocationsUTIL class
*/
@IsTest(isParallel=true)
public class ALLO_AllocationsUtil_TEST {

    // Callable Method Declarations
    private static final String ALLO_VALIDATE_CONFIG_ACTION = 'ALLO.ValidatePmtAllocationConfig';
    private static final String ALLO_PROCESS_OPPS_PMTS_ACTION = 'ALLO.ProcessOppsAndPmts';

    private static final Integer NUMBER_OF_CONTACTS_AND_OPPORTUNITIES = 13;
    /*******************************************************************************************************
     * RecordExclusions Inner Class Tests
     ********************************************************************************************************/

    /* @description Test 1 - Add Exclusion (Add and Confirm Individal Exlusions
                    [ALLO_AllocationsUtil.RecordExclusions.addExclusion] */
    @isTest private static void addIndividualRecordExclusions() {
        ALLO_AllocationsUTIL.RecordExclusions recExcl = new ALLO_AllocationsUTIL.RecordExclusions();

        // Since we are not restricting to the Opportunity Id, we will just use the User Id as the Record Id as
        // is not a core part of this test
        recExcl.addExclusion (UserInfo.getUserId(), ALLO_AllocationsUtil.PROCESS_DEF.OPP_AMT_UPD);

        System.assertEquals (true, recExcl.exclusionsByRecordId.containsKey(UserInfo.getUserId()), 'User Id is present in the Exclusions By Record Id Map');
        Set<ALLO_AllocationsUtil.PROCESS_DEF> excls = recExcl.exclusionsByRecordId.get(UserInfo.getUserId());
        System.assertEquals(1, excls.size(), '# of Exclusions Present after adding first exclusion');

        System.assertEquals(true, excls.contains(ALLO_AllocationsUtil.PROCESS_DEF.OPP_AMT_UPD), 'Exclusion ' + ALLO_AllocationsUtil.PROCESS_DEF.OPP_AMT_UPD + ' should be present');

        // Add additional Exclusion
        recExcl.addExclusion(UserInfo.getUserId(), ALLO_AllocationsUtil.PROCESS_DEF.OPP_ALLOC_UPD);

        System.assertEquals (true, recExcl.exclusionsByRecordId.containsKey(UserInfo.getUserId()), 'User Id is present in the Exclusions By Record Id Map');
        excls = recExcl.exclusionsByRecordId.get(UserInfo.getUserId());
        System.assertEquals(2, excls.size(), '# of Exclusions Present after adding second exclusion');
        System.assertEquals(true, excls.contains(ALLO_AllocationsUtil.PROCESS_DEF.OPP_AMT_UPD), 'Exclusion ' + ALLO_AllocationsUtil.PROCESS_DEF.OPP_AMT_UPD + ' should be present');
        System.assertEquals(true, excls.contains(ALLO_AllocationsUtil.PROCESS_DEF.OPP_ALLOC_UPD), 'Exclusion ' + ALLO_AllocationsUtil.PROCESS_DEF.OPP_ALLOC_UPD + ' should be present');

        // Test Adding Same Exclusion
        recExcl.addExclusion(UserInfo.getUserId(), ALLO_AllocationsUtil.PROCESS_DEF.OPP_ALLOC_UPD);
        excls = recExcl.exclusionsByRecordId.get(UserInfo.getUserId());
        System.assertEquals(2, excls.size(), '# of Exclusions Present after adding same exclusion again');
    }


    /* @description Test 2 - Add Set of Exclusions) (Add Set of Exclusions and Confirm)
                    [ALLO_AllocationsUtil.RecordExclusions.addExclusions] */
    @isTest private static void addSetOfRecordExclusions() {
        ALLO_AllocationsUtil.RecordExclusions recExcl = new ALLO_AllocationsUTIL.RecordExclusions();

        // Since we are not restricting to the Opportunity Id, we will just use the User Id as the Record Id as
        // is not a core part of this test
        recExcl.addExclusions (UserInfo.getUserId(), new Set<ALLO_AllocationsUtil.PROCESS_DEF> { ALLO_AllocationsUtil.PROCESS_DEF.OPP_AMT_UPD, ALLO_AllocationsUtil.PROCESS_DEF.OPP_ALLOC_UPD});
        System.assertEquals (true, recExcl.exclusionsByRecordId.containsKey(UserInfo.getUserId()), 'User Id is present in the Exclusions By Record Id Map');
        Set<ALLO_AllocationsUtil.PROCESS_DEF> excls = recExcl.exclusionsByRecordId.get(UserInfo.getUserId());
        System.assertEquals(2, excls.size(), '# of Exclusions Present after adding exclusion set');

        System.assertEquals(true, excls.contains(ALLO_AllocationsUtil.PROCESS_DEF.OPP_AMT_UPD), 'Exclusion ' + ALLO_AllocationsUtil.PROCESS_DEF.OPP_AMT_UPD + ' should be present');
        System.assertEquals(true, excls.contains(ALLO_AllocationsUtil.PROCESS_DEF.OPP_ALLOC_UPD), 'Exclusion ' + ALLO_AllocationsUtil.PROCESS_DEF.OPP_ALLOC_UPD + ' should be present');

        recExcl.addExclusions(UserInfo.getUserId(), new Set<ALLO_AllocationsUtil.PROCESS_DEF> {ALLO_AllocationsUtil.PROCESS_DEF.PMT_ALLOC, ALLO_AllocationsUtil.PROCESS_DEF.PMT_ALLOC_INITIALIZE});
        excls = recExcl.exclusionsByRecordId.get(UserInfo.getUserId());
        System.assertEquals(4, excls.size(), '# of Exclusions Present after adding additional set of exclusions');

        System.assertEquals(true, excls.contains(ALLO_AllocationsUtil.PROCESS_DEF.OPP_AMT_UPD), 'Exclusion ' + ALLO_AllocationsUtil.PROCESS_DEF.OPP_AMT_UPD + ' should be present');
        System.assertEquals(true, excls.contains(ALLO_AllocationsUtil.PROCESS_DEF.OPP_ALLOC_UPD), 'Exclusion ' + ALLO_AllocationsUtil.PROCESS_DEF.OPP_ALLOC_UPD + ' should be present');
        System.assertEquals(true, excls.contains(ALLO_AllocationsUtil.PROCESS_DEF.PMT_ALLOC), 'Exclusion ' + ALLO_AllocationsUtil.PROCESS_DEF.PMT_ALLOC + ' should be present');
        System.assertEquals(true, excls.contains(ALLO_AllocationsUtil.PROCESS_DEF.PMT_ALLOC_INITIALIZE), 'Exclusion ' + ALLO_AllocationsUtil.PROCESS_DEF.PMT_ALLOC_INITIALIZE + ' should be present');
    }

     /* @description Test 3 - Verify Exclusion via "Has Exclusion"
                     [ALLO_AllocationsUtil.RecordExclusions.hasExclusion] */
    @isTest private static void addExclusionsAndConfirmHasExclusions() {
        ALLO_AllocationsUtil.RecordExclusions recExcl = new ALLO_AllocationsUTIL.RecordExclusions();

        // Since we are not restricting to the Opportunity Id, we will just use the User Id as the Record Id as
        // is not a core part of this test
        recExcl.addExclusions (UserInfo.getUserId(), new Set<ALLO_AllocationsUtil.PROCESS_DEF> { ALLO_AllocationsUtil.PROCESS_DEF.OPP_AMT_UPD, ALLO_AllocationsUtil.PROCESS_DEF.OPP_ALLOC_UPD});
        System.assertEquals(true, recExcl.hasExclusion(UserInfo.getUserId(), ALLO_AllocationsUtil.PROCESS_DEF.OPP_AMT_UPD), 'Exclusion should be present for' + ALLO_AllocationsUtil.PROCESS_DEF.OPP_AMT_UPD);
        System.assertEquals(true, recExcl.hasExclusion(UserInfo.getUserId(), ALLO_AllocationsUtil.PROCESS_DEF.OPP_ALLOC_UPD), 'Exclusion should be present for' + ALLO_AllocationsUtil.PROCESS_DEF.OPP_ALLOC_UPD);
        System.assertEquals(false, recExcl.hasExclusion(UserInfo.getUserId(), ALLO_AllocationsUtil.PROCESS_DEF.ALL), 'Exclusion should not be present for' + ALLO_AllocationsUtil.PROCESS_DEF.ALL);
    }

    /* @description Test 4 - Verify Has No Exclusions is true when no exclusions are present. call
                    [ALLO_AllocationsUtil.RecordExclusions.hasNoExclusions] */
    @isTest private static void confirmHasNoExclusionsIsTrueWhenExclusionsAreNotPresentAndIsFalseWhenPresent() {
        ALLO_AllocationsUtil.RecordExclusions recExcl = new ALLO_AllocationsUTIL.RecordExclusions();

        // Since we are not restricting to the Opportunity Id, we will just use the User Id as the Record Id as
        // is not a core part of this test
        System.assertEquals(true, recExcl.hasNoExclusions(UserInfo.getUserId()), 'Should be no exclusions initially');

        recExcl.addExclusion(UserInfo.getUserId(), ALLO_AllocationsUtil.PROCESS_DEF.ALL);
        System.assertEquals(false, recExcl.hasNoExclusions(UserInfo.getUserId()), 'Should be exclusions present after adding on for current user');
        System.assertEquals(true, recExcl.hasNoExclusions(UserInfo.getOrganizationId()), 'Should be no exclusions for Organization Id');
    }

    /*******************************************************************************************************
     * AllocationResults Inner Class Tests
     ********************************************************************************************************/
    /* @description Test 1 - Test Add an Error
                    [ALLO_AllocationsUtil.AllocationResults.addError] */
    @isTest private static void addErrorsIndividuallyToTheAllocationsResultsAndConfirmResult() {

        ALLO_AllocationsUtil.AllocationResults allocResults = new ALLO_AllocationsUtil.AllocationResults();

        // Since we are not restricting to the Opportunity Id, we will just use the User Id as the Record Id as
        // is not a core part of this test
        allocResults.addError(UserInfo.getUserId(), 'Test Error');

        System.assertEquals (true, allocResults.errorsByRecordId.containsKey(UserInfo.getUserId()), 'Errors are present for ' + UserInfo.getUserId());
        System.assertEquals (1, allocResults.errorsByRecordId.get(UserInfo.getUserId()).size(), '1 Error is present for ' + UserInfo.getUserId());

        allocResults.addError(UserInfo.getUserId(), 'Test Error 2');
        System.assertEquals (2, allocResults.errorsByRecordId.get(UserInfo.getUserId()).size(), '2 Errors are present for ' + UserInfo.getUserId());

        System.assertEquals (false, allocResults.errorsByRecordId.containsKey(UserInfo.getOrganizationId()), 'No Errors are present for ' + UserInfo.getOrganizationId());
    }

    /* @description Test 2 - Test Add Errors
                    [ALLO_AllocationsUtil.AllocationResults.addAllErrors] */
    @isTest private static void addMultipleErrorsToTheAllocationsResultsAndConfirmResult() {
        ALLO_AllocationsUtil.AllocationResults allocResults = new ALLO_AllocationsUtil.AllocationResults();

        // Since we are not restricting to the Opportunity Id, we will just use the User Id as the Record Id as
        // is not a core part of this test
        allocResults.addAllErrors(UserInfo.getUserId(), new List<String> {'Test 1 Error', 'Test 2 Error'});

        System.assertEquals (true, allocResults.errorsByRecordId.containsKey(UserInfo.getUserId()), 'Errors are present for ' + UserInfo.getUserId());
        System.assertEquals (2, allocResults.errorsByRecordId.get(UserInfo.getUserId()).size(), '# of Errors present for ' + UserInfo.getUserId());

        allocResults.addAllErrors(UserInfo.getUserId(), new List<String> {'Test 3 Error', 'Test 4 Error'});
        System.assertEquals (4, allocResults.errorsByRecordId.get(UserInfo.getUserId()).size(), '4 Errors are present for ' + UserInfo.getUserId());

        System.assertEquals (false, allocResults.errorsByRecordId.containsKey(UserInfo.getOrganizationId()), 'No Errors are present for ' + UserInfo.getOrganizationId());
    }

    /*******************************************************************************************************
     * RecordsForReview Inner Class Tests
     ********************************************************************************************************/

    /* @description Test 1 - Test adding different types of Allocations
                    [ALLO_AllocationsUtil.RecordsForReview.addAllocationByType] */
    @isTest private static void addAllocationByTypeToRecordsForReviewAndConfirmAddedToCorrectList() {
        AllocationSetupTest alloSetupTest = new AllocationSetupTest()
        .enableDefaultAllocations()
        .enablePaymentAllocations()
        .disableAllocationTriggers()
        .applyConfiguration();

        List<General_Accounting_Unit__c> gaus = alloSetupTest.getGAUs();

        ALLO_AllocationsUtil.RecordsForReview recsForRev = new ALLO_AllocationsUtil.RecordsForReview();

        List<Account> accs = UTIL_UnitTestData_TEST.createMultipleTestAccounts(1, null);
        insert accs;

        npe03__Recurring_Donation__c rd = new TEST_RecurringDonationBuilder()
            .withInstallmentPeriodYearly()
            .withDateEstablished(Date.newInstance(1984,01,29))
            .withAccount(accs[0].Id)
            .withAmount(20)
            .withScheduleTypeMultiplyValue()
            .withOpenEndedStatusOpen()
            .build();
        insert rd;

        Campaign cam = new Campaign(Name='Test Campaign: ' + UTIL_UnitTestData_TEST.getUniqueString(), IsActive=true);
        insert cam;

        List<Contact> ctcs = UTIL_UnitTestData_TEST.createMultipleTestContacts(3);
        insert ctcs;

        List<Opportunity> opps = UTIL_UnitTestData_TEST.oppsForContactList(ctcs, null, UTIL_UnitTestDATA_TEST.getClosedWonStage(), System.today().addDays(30), 1000, null, null);
        insert opps;

        List<npe01__OppPayment__c> pmts = [select Id from npe01__OppPayment__c where npe01__Opportunity__c = :opps[1].Id];

        List<Allocation__c> allosForInsert = new list<Allocation__c>();
        // Recurring Donation Allocations
        Allocation__c percentAlloRd = new Allocation__c(Recurring_Donation__c = rd.id, Percent__c = 50, General_Accounting_Unit__c = gaus[0].id);
        allosForInsert.add(percentAlloRd);

        Allocation__c amountAlloRd = new Allocation__c(Recurring_Donation__c = rd.id, Amount__c = 10, General_Accounting_Unit__c = gaus[1].id);
        allosForInsert.add(amountAlloRd);

        // Opportunity Allocations
        Allocation__c percentAlloOpp = new Allocation__c(Opportunity__c = opps[0].Id, Percent__c = 50, General_Accounting_Unit__c = gaus[0].Id);
        allosForInsert.add(percentAlloOpp);

        Allocation__c amountAlloOpp = new Allocation__c(Opportunity__c = opps[0].Id, Amount__c = 10, General_Accounting_Unit__c = gaus[1].id);
        allosForInsert.add(amountAlloOpp);

        // Payment Allocations
        Allocation__c percentAlloPmt = new Allocation__c(Payment__c = pmts[0].Id, Percent__c = 50, General_Accounting_Unit__c = gaus[0].Id);
        allosForInsert.add(percentAlloPmt);

        Allocation__c amountAlloPmt = new Allocation__c(Payment__c = pmts[0].Id, Amount__c = 10, General_Accounting_Unit__c = gaus[1].id);
        allosForInsert.add(amountAlloPmt);

        // Campaign Allocations
        Allocation__c percentAlloCam = new Allocation__c(Campaign__c = cam.Id, Percent__c = 50, General_Accounting_Unit__c = gaus[0].Id);
        allosForInsert.add(percentAlloCam);

        Allocation__c amountAlloCam = new Allocation__c(Campaign__c = cam.Id, Amount__c = 10, General_Accounting_Unit__c = gaus[1].id);
        allosForInsert.add(amountAlloCam);

        insert allosForInsert;

        // Recurring Donation Allocation Tests
        assertRecsForReviewAllocations(recsForRev, 'Before adding allocations', 0, 0, 0, 0);
        recsForRev.addAllocationByType(allosForInsert[0]);
        assertRecsForReviewAllocations(recsForRev, 'After adding Recurring Donation allocation', 0, 0, 1, 0);
        System.assertEquals(1, recsForRev.recurringDonationAllocations.get(rd.Id).size(), 'Recurring Donations Allocation List Size after First Add');
        recsForRev.addAllocationByType(allosForInsert[1]);
        assertRecsForReviewAllocations(recsForRev, 'After adding 2nd Recurring Donation allocation', 0, 0, 1, 0);
        System.assertEquals(2, recsForRev.recurringDonationAllocations.get(rd.Id).size(), 'Recurring Donations Allocation List Size after Second Add');
        System.assertEquals (allosForInsert[0].Id, recsForRev.recurringDonationAllocations.get(rd.Id)[0].Id, 'Recurring Donations Allocation 0');
        System.assertEquals (allosForInsert[1].Id, recsForRev.recurringDonationAllocations.get(rd.Id)[1].Id, 'Recurring Donations Allocation 1');

        // Opportunity Allocation Tests
        recsForRev.addAllocationByType(allosForInsert[2]);
        assertRecsForReviewAllocations(recsForRev, 'After adding 1st Opportunity allocation', 1, 0, 1, 0);
        System.assertEquals(1, recsForRev.oppsAllocations.get(opps[0].Id).size(), 'Opportunity Allocation List Size after First Add');
        recsForRev.addAllocationByType(allosForInsert[3]);
        assertRecsForReviewAllocations(recsForRev, 'After adding 2nd Opportunity allocation', 1, 0, 1, 0);
        System.assertEquals(2, recsForRev.oppsAllocations.get(opps[0].Id).size(), 'Opportunity Allocation List Size after Second Add');
        System.assertEquals (allosForInsert[2].Id, recsForRev.oppsAllocations.get(opps[0].Id)[0].Id, 'Opportunity Allocation 0');
        System.assertEquals (allosForInsert[3].Id, recsForRev.oppsAllocations.get(opps[0].Id)[1].Id, 'Opportunity Allocation 1');

        // Payment Allocation Tests
        recsForRev.addAllocationByType(allosForInsert[4]);
        assertRecsForReviewAllocations(recsForRev, 'After adding 1st Payment allocation', 1, 1, 1, 0);
        System.assertEquals(1, recsForRev.paymentAllocations.get(pmts[0].Id).size(), 'Payment Allocation List Size after First Add');
        recsForRev.addAllocationByType(allosForInsert[5]);
        assertRecsForReviewAllocations(recsForRev, 'After adding 2nd Payment allocation', 1, 1, 1, 0);
        System.assertEquals(2, recsForRev.paymentAllocations.get(pmts[0].Id).size(), 'Payment Allocation List Size after Second Add');
        System.assertEquals (allosForInsert[4].Id, recsForRev.paymentAllocations.get(pmts[0].Id)[0].Id, 'Payment Allocation 0');
        System.assertEquals (allosForInsert[5].Id, recsForRev.paymentAllocations.get(pmts[0].Id)[1].Id, 'Payment Allocation 1');

        // Campaign Allocation Tests
        recsForRev.addAllocationByType(allosForInsert[6]);
        assertRecsForReviewAllocations(recsForRev, 'After adding 1st Campaign allocation', 1, 1, 1, 1);
        System.assertEquals(1, recsForRev.campaignAllocations.get(cam.Id).size(), 'Campaign Allocation List Size after First Add');
        recsForRev.addAllocationByType(allosForInsert[7]);
        assertRecsForReviewAllocations(recsForRev, 'After adding 2nd Campaign allocation', 1, 1, 1, 1);
        System.assertEquals(2, recsForRev.campaignAllocations.get(cam.Id).size(), 'Campaign Allocation List Size after Second Add');
        System.assertEquals (allosForInsert[6].Id, recsForRev.campaignAllocations.get(cam.Id)[0].Id, 'Campaign Allocation 0');
        System.assertEquals (allosForInsert[7].Id, recsForRev.campaignAllocations.get(cam.Id)[1].Id, 'Campaign Allocation 1');

    }

    /*******************************************************************************************************
    * @description Asserts the list sizes for each of the allocations list in the RecordsForReview
    *              class
    * @param recsForRev A populated Record For Review Structure
    * @param addtlMsg Text that will be displayed in addition to the list type if an assert fails
    * @param oppsAllocSize The exepected size of the Opportunity Allocations Map
    * @param pmtAllocSize The expected size of the Payment Allocations Map
    * @param rdAllocSize The expected size of the Recurring Donations Allocations Map
    * @param campAllocSize The expected size of the Campaign Allocations Map
    ********************************************************************************************************/
     private static void assertRecsForReviewAllocations(ALLO_AllocationsUtil.RecordsForReview recsForRev, String addtlMsg, Integer oppsAllocSize, Integer pmtAllocSize, Integer rdAllocSize, Integer campAllocSize) {
        System.assertEquals (oppsAllocSize, recsForRev.oppsAllocations.size(), addtlMsg + ': Opportunity Allocations Map Size');
        System.assertEquals (pmtAllocSize, recsForRev.paymentAllocations.size(), addtlMsg + ': Payment Allocations Map Size');
        System.assertEquals (rdAllocSize, recsForRev.recurringDonationAllocations.size(), addtlMsg + ': Recurring Donation Allocations Map Size');
        System.assertEquals (campAllocSize, recsForRev.campaignAllocations.size(), addtlMsg + ': Campaign Allocations Map Size');
    }

   /* @Description Test 2 - Test method to identify Opportunities require Review
                   [ALLO_AllocationsUtil.RecordsForReview.isOpportunityRequiresReview] */
    @isTest private static void confirmReturnsTrueWhenOpportunityRequiresReviewAndFalseOtherwise() {

        AllocationSetupTest alloSetupTest = new AllocationSetupTest()
        .enableDefaultAllocations()
        .enablePaymentAllocations()
        .disableAllocationTriggers()
        .applyConfiguration();

        List<General_Accounting_Unit__c> gaus = alloSetupTest.getGAUs();

        ALLO_AllocationsUtil.RecordsForReview recsForRev = new ALLO_AllocationsUtil.RecordsForReview();

        List<Account> accs = UTIL_UnitTestData_TEST.createMultipleTestAccounts(1, null);
        insert accs;

        npe03__Recurring_Donation__c rd = new TEST_RecurringDonationBuilder()
            .withInstallmentPeriodYearly()
            .withDateEstablished(Date.newInstance(1984,01,29))
            .withAccount(accs[0].Id)
            .withAmount(20)
            .withScheduleTypeMultiplyValue()
            .withOpenEndedStatusOpen()
            .build();
        insert rd;

        Campaign cam = new Campaign(Name='Test Campaign: ' + UTIL_UnitTestData_TEST.getUniqueString(), IsActive=true);
        insert cam;


        List<Contact> ctcs = UTIL_UnitTestData_TEST.createMultipleTestContacts(3);
        insert ctcs;

        List<Opportunity> opps = UTIL_UnitTestData_TEST.oppsForContactList(ctcs, null, UTIL_UnitTestDATA_TEST.getClosedWonStage(), System.today().addDays(30), 1000, null, null);
        opps[0].npe03__Recurring_Donation__c = rd.Id;
        opps[1].npe03__Recurring_Donation__c = rd.Id;
        insert opps;

        List<Allocation__c> allosForInsert = new list<Allocation__c>();
        // Recurring Donation Allocations
        Allocation__c percentAlloRd = new Allocation__c(Recurring_Donation__c = rd.id, Percent__c = 50, General_Accounting_Unit__c = gaus[0].id);
        allosForInsert.add(percentAlloRd);

        Allocation__c amountAlloRd = new Allocation__c(Recurring_Donation__c = rd.id, Amount__c = 10, General_Accounting_Unit__c = gaus[1].id);
        allosForInsert.add(amountAlloRd);

        // Opportunity Allocations
        Allocation__c percentAlloOpp = new Allocation__c(Opportunity__c = opps[0].Id, Percent__c = 50, General_Accounting_Unit__c = gaus[0].Id);
        allosForInsert.add(percentAlloOpp);

        Allocation__c amountAlloOpp = new Allocation__c(Opportunity__c = opps[0].Id, Amount__c = 10, General_Accounting_Unit__c = gaus[1].id);
        allosForInsert.add(amountAlloOpp);

        insert allosForInsert;

        for (Allocation__c alloc : allosForInsert) {
            recsForRev.addAllocationByType(alloc);
        }

        System.assertEquals (false, recsForRev.isOpportunityWithParentAndNoAllocations(opps[0]), '1st Opportunity should have parent and Amount and allocations');
        System.assertEquals (true, recsForRev.isOpportunityWithParentAndNoAllocations(opps[1]), '2nd Opportunity should have parent and Amount and no allocations');
        System.assertEquals (false, recsForRev.isOpportunityWithParentAndNoAllocations(opps[2]), '3rd Opportunity should have no parent And Amount and no allocations');
    }

    /* @description Test 3 - Test initialize Errors [ALLO_AllocationsUtil.RecordsForReview.initializeErrors]
        // Should test both passing in an existing ERR_RecordErrors instance, and initializing from the Opportunities
        // in the RecordsForReview variable oppsById */
    @isTest private static void initializeErrorsStructureSuccessfully() {
        AllocationSetupTest alloSetupTest = new AllocationSetupTest()
            .enableDefaultAllocations()
            .enablePaymentAllocations()
            .disableAllocationTriggers()
            .applyConfiguration();

        List<Contact> ctcs = UTIL_UnitTestData_TEST.createMultipleTestContacts(3);
        insert ctcs;

        List<Opportunity> opps = UTIL_UnitTestData_TEST.oppsForContactList(ctcs, null, UTIL_UnitTestDATA_TEST.getClosedWonStage(), System.today().addDays(30), 1000, null, null);
        insert opps;

        ERR_RecordError recErrs = new ERR_RecordError('Test');
        recErrs.addError(opps[0].Id, 'Test Error', opps[0]);
        recErrs.processErrors();

        Test.startTest();

        ALLO_AllocationsUtil.RecordsForReview recsForRev = new ALLO_AllocationsUtil.RecordsForReview();

        // First Initialize with existing recErrs
        recsForRev.initializeErrors('Test', recErrs);

        System.assertNotEquals(null, recsForRev.recErrs.get(opps[0].Id), 'Error For First Opportunity should be present');

        // Next Initialize and tell it to retrieve recErrs from scratch
        ALLO_AllocationsUtil.RecordsForReview recsForRev2 = new ALLO_AllocationsUtil.RecordsForReview();
        for (Opportunity opp : opps) {
            recsForRev2.opps.add (opp);
            recsForRev2.oppsById.put(opp.Id, opp);
        }

        // This time, it will initialize the errors from scratch and query the Error__c object
        recsForRev2.initializeErrors('Test', null);

        System.assertNotEquals(null, recsForRev2.recErrs.get(opps[0].Id), 'Error For First Opportunity should be present (retrieved from Error__c object)');

    }

    /*******************************************************************************************************
     * Main Class Tests [Critical Path is covering as many as possible in this section]
     ********************************************************************************************************/
    //TODO: Method: determineRecordsRequiringReview, isRequiresReview, isExcluded, getExcludedOpportunityRecordtypes, getExcludedOpportunityTypes
    /**
     * @description Test 1 - Confirm  that isExcluded returns true for Opportunites that should be excluded based on type and
     *              false for ones that should not be excluded.
     *              [ALLO_AllocationsUtil.isExcluded, ALLO_AllocationsUtil.getExcludedOpportunityRecordTypes,
     *               ALLO_AllocationsUtil.getExcludedOpportunityTypes]
     */
    @isTest private static void excludeOpportunitiesForTypeAndRecordtype() {
        AllocationSetupTest alloSetupTest = new AllocationSetupTest()
            .enableDefaultAllocations()
            .enablePaymentAllocations()
            .withAllocationSettings(
                new Allocations_Settings__c(
                    Excluded_Opp_Types__c = 'Test;Test2',
                    // Just need valid ids for unit test.  Will not actually use as recordtype id
                    Excluded_Opp_RecTypes__c = UserInfo.getOrganizationId() + ';' + UserInfo.getUserId()
                )
            )
            .disableAllocationTriggers()
            .applyConfiguration();

        // Opportunities to test.  Not inserting, and only populating the required field for the test
        List<Opportunity> oppsToTest = new List<Opportunity> {
            new Opportunity(Type = 'Test'),
            new Opportunity(Type = 'Include'),
            new Opportunity(Type = 'Test2'),
            new Opportunity(),
            new Opportunity(Type = ''),
            new Opportunity(RecordtypeId = UserInfo.getUserId()),
            new Opportunity(RecordtypeId = UserInfo.getProfileId()),
            new Opportunity(RecordTypeId = UserInfo.getOrganizationId())
        };

        List<Boolean> expectedResults = new List<Boolean> {
            true,
            false,
            true,
            false,
            false,
            true,
            false,
            true
        };

        for (Integer i = 0; i < oppsToTest.size(); i++) {
            System.assertEquals(expectedResults[i], ALLO_AllocationsUtil.isExcluded(oppsToTest[i]), 'Opportunity with Type value of \'' + oppsToTest[i].Type + '\' and RecordtypeId value of ' + oppsToTest[i].RecordtypeId + ' should be ' + (expectedResults[i] ? 'excluded' : 'included'));
        }
    }

    /**
     * @description Test 2 - Confirm returns true for all scenarios it should with Default Allocations Enabled
     *
     *              Scenario 1 - Confirm that Opportunities Modified Since Boundary Date are flagged for review
     *              Scenario 2 - Confirm that Properly Allocated Opportunities Not Modified After Boundary Date
     *                           are not flagged for review
     *              Scenario 3 - Confirm that Opportunities are flagged for review if Boundary Date is null
     *              Scenario 4 - Confirm that Opportunities with non null/zero Amount and no allocations are
     *                           flagged for review [Only if Default Allocations Are Enabled]
     *              Scenario 5 - Confirm that Opportunities with Amount that does not match sum of Allocations
     *                           are flagged for review [Only if Default Allocations Are Enabled]
     *              Scenario 6 - Confirm Opportunity with Payments with non null/zero Amount and no Allocations
     *                           are flagged for review
     *              Scenario 7 - Confirm Opportunity with Payments with non null/zero Amount and valid
     *                           Allocations are not flagged for review
     *              [ALLO_AllocationsUtil.isRequiresReview]
     */
    @isTest private static void confirmOnlyOppsNeedingReviewAreFlaggedWhenDefaultAllocEnabled() {
        AllocationSetupTest alloSetupTest = new AllocationSetupTest()
            .enableDefaultAllocations()
            .enablePaymentAllocations()
            .disableAllocationTriggers()
            .applyConfiguration();

        List<Id> oppIds = createTestDataAndReturnOppIds(alloSetupTest.getGAUs(), alloSetupTest.getDefaultGAU());

        Set<Id> oppIdsAsSet = new Set<Id>();
        oppIdsAsSet.addAll(oppIds);

        Map<Id, Opportunity> oppsById = ALLO_AllocationsUtil.retrieveOpportunities(oppIdsAsSet);

        Set<Id> pmtIds = new Set<Id>();
        for (Opportunity opp : oppsById.values()) {
            for (npe01__OppPayment__c pmt : opp.npe01__OppPayment__r) {
                pmtIds.add(pmt.Id);
            }
        }

        List<Allocation__c> allocs = ALLO_AllocationsUtil.retrieveAllocations(oppIdsAsSet, pmtIds, new Set<Id>(), new Set<Id>());

        ALLO_AllocationsUtil.RecordsForReview recsForRev = new ALLO_AllocationsUtil.RecordsForReview();

        for (Allocation__c alloc : allocs) {
            recsForRev.addAllocationByType(alloc);
        }

        Opportunity opp0 = oppsById.get(oppIds[0]);
        Opportunity opp1 = oppsById.get(oppIds[1]);
        Opportunity opp2 = oppsById.get(oppIds[2]);
        Opportunity opp3 = oppsById.get(oppIds[3]);
        Opportunity opp4 = oppsById.get(oppIds[4]);
        Opportunity opp5 = oppsById.get(oppIds[5]);
        Opportunity opp6 = oppsById.get(oppIds[6]);
        Opportunity opp7 = oppsById.get(oppIds[7]);

        // Confirm that Opportunities are flagged for review if Boundary Date is null
        System.assertEquals(true, ALLO_AllocationsUtil.isRequiresReview(opp0, recsForRev.oppsAllocations.get(opp0.Id), null), 'Opportunity 0, no boundary date');
        // Confirm that Opportunities Not Modified Since Boundary Date are not flagged for review
        System.assertEquals(false, ALLO_AllocationsUtil.isRequiresReview(opp0, recsForRev.oppsAllocations.get(opp0.Id), System.now().addDays(1)), 'Opportunity 0, boundary date of tomorrow');
        // Confirm that Opportunities Modified Since Boundary Date are flagged for review
        System.assertEquals(true, ALLO_AllocationsUtil.isRequiresReview(opp0, recsForRev.oppsAllocations.get(opp0.Id), System.now().addDays(-1)), 'Opportunity 0, boundary date of yesterday');
        // Confirm that Opportunities with non null/zero Amount and no allocations are flagged for review [Only if Default Allocations Are Enabled]
        System.assertEquals(true, ALLO_AllocationsUtil.isRequiresReview(opp1, recsForRev.oppsAllocations.get(opp1.Id), System.now().addDays(1)), 'Opportunity 1, boundary date of tomorrow');
        // Confirm that Opportunities with non null/zero Amount and no allocations are flagged for review [Only if Default Allocations Are Enabled]
        System.assertEquals(true, ALLO_AllocationsUtil.isRequiresReview(opp2, recsForRev.oppsAllocations.get(opp2.Id), System.now().addDays(1)), 'Opportunity 2, boundary date of tomorrow');
        // Confirm that Opportunities with Amount that does not match sum of Allocations are flagged for review [Only if Default Allocations Are Enabled]
        System.assertEquals(true, ALLO_AllocationsUtil.isRequiresReview(opp3, recsForRev.oppsAllocations.get(opp3.Id), System.now().addDays(1)), 'Opportunity 3, boundary date of tomorrow');
        // Confirm that Opportunities with non null/zero Amount and Allocations with null/0 amount are flagged for review
        System.assertEquals(true, ALLO_AllocationsUtil.isRequiresReview(opp4, recsForRev.oppsAllocations.get(opp4.Id), System.now().addDays(1)), 'Opportunity 4, boundary date of tomorrow');
        // Confirm that Opportunities with null/0 Amount and Allocations with non null/0 amount are flagged for review
        System.assertEquals(true, ALLO_AllocationsUtil.isRequiresReview(opp5, recsForRev.oppsAllocations.get(opp5.Id), System.now().addDays(1)), 'Opportunity 5, boundary date of tomorrow');
        // Confirm Opportunity with Payments with non null/zero Amount and no Allocations are flagged for review [Only if Default Allocations Are Enabled]
        System.assertEquals(true, ALLO_AllocationsUtil.isRequiresReview(opp6.npe01__OppPayment__r[0], recsForRev.paymentAllocations.get(opp6.npe01__OppPayment__r[0].Id), System.now().addDays(1)), 'Opportunity 6 - Payment 0, boundary date of tomorrow');
        // Confirm Opportunity with Payments with non null/zero Amount and valid Allocations are not flagged for review
        System.assertEquals(false, ALLO_AllocationsUtil.isRequiresReview(opp7.npe01__OppPayment__r[0], recsForRev.paymentAllocations.get(opp7.npe01__OppPayment__r[0].Id), System.now().addDays(1)), 'Opportunity 7 - Payment 0, boundary date of tomorrow');
    }

    /**
     * @description Test 3 - Confirm returns true for all scenarios it should with Default Allocations Not Enabled
     *
     *              Scenario 1 - Confirm that Opportunities Modified Since Boundary Date are flagged for review
     *              Scenario 2 - Confirm that Properly Allocated Opportunities Not Modified After Boundary Date
     *                           are not flagged for review
     *              Scenario 3 - Confirm that Opportunities are flagged for review if Boundary Date is null
     *              Scenario 4 - Confirm that Opportunities with non null/zero Amount and no allocations are not
     *                           flagged for review
     *              Scenario 5 - Confirm that Opportunities with Amount that does not match sum of Allocations
     *                           are not flagged for review
     *              Scenario 6 - Confirm Opportunity with Payments with non null/zero Amount and no Allocations
     *                           are not flagged for review
     *              Scenario 7 - Confirm Opportunity with Payments with non null/zero Amount and valid
     *                           Allocations are not flagged for review

     *              [ALLO_AllocationsUtil.isRequiresReview]
     */
    @isTest private static void confirmOnlyOppsNeedingReviewAreFlaggedWhenDefaultAllocNotEnabled() {
        AllocationSetupTest alloSetupTest = new AllocationSetupTest()
            .disableAllocationTriggers()
            .applyConfiguration();

        List<Id> oppIds = createTestDataAndReturnOppIds(alloSetupTest.getGAUs(), alloSetupTest.getDefaultGAU());

        Set<Id> oppIdsAsSet = new Set<Id>();
        oppIdsAsSet.addAll(oppIds);

        Map<Id, Opportunity> oppsById = ALLO_AllocationsUtil.retrieveOpportunities(oppIdsAsSet);

        Set<Id> pmtIds = new Set<Id>();
        for (Opportunity opp : oppsById.values()) {
            for (npe01__OppPayment__c pmt : opp.npe01__OppPayment__r) {
                pmtIds.add(pmt.Id);
            }
        }

        List<Allocation__c> allocs = ALLO_AllocationsUtil.retrieveAllocations(oppIdsAsSet, pmtIds, new Set<Id>(), new Set<Id>());

        ALLO_AllocationsUtil.RecordsForReview recsForRev = new ALLO_AllocationsUtil.RecordsForReview();

        for (Allocation__c alloc : allocs) {
            recsForRev.addAllocationByType(alloc);
        }

        Opportunity opp0 = oppsById.get(oppIds[0]);
        Opportunity opp1 = oppsById.get(oppIds[1]);
        Opportunity opp2 = oppsById.get(oppIds[2]);
        Opportunity opp3 = oppsById.get(oppIds[3]);
        Opportunity opp4 = oppsById.get(oppIds[4]);
        Opportunity opp5 = oppsById.get(oppIds[5]);
        Opportunity opp6 = oppsById.get(oppIds[6]);
        Opportunity opp7 = oppsById.get(oppIds[7]);

   		// Confirm that Opportunities are flagged for review if Boundary Date is null
        System.assertEquals(true, ALLO_AllocationsUtil.isRequiresReview(opp0, recsForRev.oppsAllocations.get(opp0.Id), null), 'Opportunity 0, no boundary date');
        // Confirm that Opportunities Not Modified Since Boundary Date are not flagged for review
        System.assertEquals(false, ALLO_AllocationsUtil.isRequiresReview(opp0, recsForRev.oppsAllocations.get(opp0.Id), System.now().addDays(1)), 'Opportunity 0, boundary date of tomorrow');
        // Confirm that Opportunities Modified Since Boundary Date are flagged for review
        System.assertEquals(true, ALLO_AllocationsUtil.isRequiresReview(opp0, recsForRev.oppsAllocations.get(opp0.Id), System.now().addDays(-1)), 'Opportunity 0, boundary date of yesterday');
        // Confirm that Opportunities with non null/zero Amount and no allocations are not flagged for review [If Default Allocations Are Not Enabled]
        System.assertEquals(false, ALLO_AllocationsUtil.isRequiresReview(opp1, recsForRev.oppsAllocations.get(opp1.Id), System.now().addDays(1)), 'Opportunity 1, boundary date of tomorrow');
        // Confirm that Opportunities with non null/zero Amount and no allocations are not flagged for review [Only if Default Allocations Are Not Enabled]
        System.assertEquals(false, ALLO_AllocationsUtil.isRequiresReview(opp2, recsForRev.oppsAllocations.get(opp2.Id), System.now().addDays(1)), 'Opportunity 2, boundary date of tomorrow');
        // Confirm that Opportunities with Amount that does not match sum of Allocations are not flagged for review [Only if Default Allocations Are Not Enabled]
        System.assertEquals(false, ALLO_AllocationsUtil.isRequiresReview(opp3, recsForRev.oppsAllocations.get(opp3.Id), System.now().addDays(1)), 'Opportunity 3, boundary date of tomorrow');
        // Confirm that Opportunities with non null/zero Amount and Allocations with null/0 amount are flagged for review
        System.assertEquals(true, ALLO_AllocationsUtil.isRequiresReview(opp4, recsForRev.oppsAllocations.get(opp4.Id), System.now().addDays(1)), 'Opportunity 4, boundary date of tomorrow');
        // Confirm that Opportunities with null/0 Amount and Allocations with non null/0 amount are flagged for review
        System.assertEquals(true, ALLO_AllocationsUtil.isRequiresReview(opp5, recsForRev.oppsAllocations.get(opp5.Id), System.now().addDays(1)), 'Opportunity 5, boundary date of tomorrow');
        // Confirm Opportunity with Payments with non null/zero Amount and no Allocations are not flagged for review [Only if Default Allocations Are Not Enabled]
        System.assertEquals(false, ALLO_AllocationsUtil.isRequiresReview(opp6.npe01__OppPayment__r[0], recsForRev.paymentAllocations.get(opp6.npe01__OppPayment__r[0].Id), System.now().addDays(1)), 'Opportunity 6 - Payment 0, boundary date of tomorrow');
        // Confirm Opportunity with Payments with non null/zero Amount and valid Allocations are not flagged for review
        System.assertEquals(false, ALLO_AllocationsUtil.isRequiresReview(opp7.npe01__OppPayment__r[0], recsForRev.paymentAllocations.get(opp7.npe01__OppPayment__r[0].Id), System.now().addDays(1)), 'Opportunity 7 - Payment 0, boundary date of tomorrow');
    }

    // [DEFERRED] isRequiresReview: Confirm that Opportunities with Allocations Modified Since Boundary are flagged for review
        // (TODO: Determine viable approach...Difficult to make work with limitations of setting LastModified versus boundary date in tests distinct for Allocations versus Opportunity)

     /**
     * @description Confirm determines necessary Allocations changes, as well as errors based
     *              on records passed to processOpportunityAllocations
     *              [ALLO_AllocationsUtil.processOpportunityAllocations]
     *
     *      * Scenarios Covered (Default Allocation Enabled):
     * - Opportunity 0 - Opportunity with allocations and Recurring Donation Parent
     *         - Result - No Changes
     * - Opportunity 1- Opportunity without allocations and with Recurring Donation Parent
     *         - Result - Recurring Donation Allocations propogated to Opportunity as inserts
     * - Opportunity 2 - No Allocations, No Parent
     *         - Result - Default Allocation created for Amount Of Opportunity
     * - Opportunity 3 - Sum of Allocation Amounts < Opportunity Amount
     *         - Result - Default Allocation is Created for Difference between Sum of Non Default Alloc Amounts & Opp Amount
     * - Opportunity 4 - Allocation Present with Percent and No Amount
     *         - Result - Update of Allocation to set Amount
     * - Opportunity 5 - Opportunity with Amount 0 and non zero Allocations
     *         - Result - Converts to Percent Allocation with 0 Amount.
     * - Opportunity 6 - Opportunity Allocations up to date
     *         - Result - No changes
     * - Opportunity 7 - Opportunity Allocations up to date
     *         - Result - No changes
     * - Opportunity 8 - Opportunity with null Amount and non zero Default Allocation
     *         - Result - Default Allocation is Deleted
     * - Opportunity 9 - Opportunity has no allocations. Is part of a Campaign with Allocations
     *         - Result - Campaign Allocations copied to Opportunity
     * - Opportunity 10 - Existing Percentage Allocation for Amount $40, And Default Allocation, also for $40.  Opportunity Amount is $20
     *         - Result - Allocation is resized/recalculated using the Opportunity Amount and the Allocation Percentage.  Default Allocation is resized to $10
     * - Opportunity 11 - Existing Fixed Amount Allocation and Default Allocation each for Amount $40, Opportunity Amount is $20
     *         - Result - Allocation cannot be resized and is larger than Opportunity Amount.  Error is generated
     * - Opportunity 12 - Opportunity for Amount 0 with no Allocations
     *         - Result - Default Allocation is Created for $0
     */
    @isTest private static void confirmProcessingOfOpportunitiesWhenDefaultAllocEnabled() {
        AllocationSetupTest alloSetupTest = new AllocationSetupTest()
            .enableDefaultAllocations()
            .enablePaymentAllocations()
            .disableAllocationTriggers()
            .applyConfiguration();

        List<Id> oppIds = createTestDataAndReturnOppIds(alloSetupTest.getGAUs(), alloSetupTest.getDefaultGAU());

        Set<Id> oppIdsAsSet = new Set<Id>();
        oppIdsAsSet.addAll(oppIds);

        Map<Id, Opportunity> oppsById = ALLO_AllocationsUtil.retrieveOpportunities(oppIdsAsSet);
        Set<Id> campaignIds = new Set<Id>();
        Set<Id> recurringDonationIds = new Set<Id>();
        Set<Id> pmtIds = new Set<Id>();

        for (Opportunity opp : oppsById.values()) {
            if (opp.CampaignId != null) {
                campaignIds.add(opp.CampaignId);
            }
            if (opp.npe03__Recurring_Donation__c != null) {
                recurringDonationIds.add(opp.npe03__Recurring_Donation__c);
            }
            for (npe01__OppPayment__c pmt : opp.npe01__OppPayment__r) {
                pmtIds.add(pmt.Id);
            }
        }

        List<Allocation__c> allocs = ALLO_AllocationsUtil.retrieveAllocations(oppIdsAsSet, pmtIds, campaignIds, recurringDonationIds);

        ALLO_AllocationsUtil.RecordsForReview recsForRev = new ALLO_AllocationsUtil.RecordsForReview();

        for (Allocation__c alloc : allocs) {
            recsForRev.addAllocationByType(alloc);
        }

         // Will track exclusions across processes
         ALLO_AllocationsUtil.RecordExclusions recExcl = new ALLO_AllocationsUtil.RecordExclusions();

        // Process Opportunity Allocations
        ALLO_AllocationsUtil.AllocationResults allocResults = ALLO_AllocationsUtil.processOpportunityAllocations(oppsById, recsForRev.oppsAllocations, recsForRev.campaignAllocations, recsForRev.recurringDonationAllocations, recExcl);

        Map<Id, List<Allocation__c>> deleteAllocsByOppId = buildMapOfAllocationsByOpportunityId(allocResults.allocationsForDelete);
        Map<Id, List<Allocation__c>> insertAllocsByOppId = buildMapOfAllocationsByOpportunityId(allocResults.allocationsForInsert);
        Map<Id, List<Allocation__c>> updateAllocsByOppId = buildMapOfAllocationsByOpportunityId(allocResults.allocationsForUpdate);

        // Opportunity 0 will have no changes
        System.assertEquals(false, insertAllocsByOppId.containsKey(oppIds[0]), 'Opportunity 0 - Found in Insert Allocations List');
        System.assertEquals(false, updateAllocsByOppId.containsKey(oppIds[0]), 'Opportunity 0 - Found in Update Allocations List');
        System.assertEquals(false, deleteAllocsByOppId.containsKey(oppIds[0]), 'Opportunity 0 - Found in Delete Allocations List');

        // Opportunity 1 will be allocated from Recurring Donation parent
        System.assertEquals(true, insertAllocsByOppId.containsKey(oppIds[1]), 'Opportunity 1 Found in Insert Allocations List');
        System.assertEquals(2, insertAllocsByOppId.get(oppIds[1]).size(), 'Opportunity 1 - # of Allocations to Insert');

        // Opportunity 2 will be allocated from Default Allocation
        System.assertEquals(true, insertAllocsByOppId.containsKey(oppIds[2]), 'Opportunity 2 should have allocations in the insert list');
        System.assertEquals(1, insertAllocsByOppId.get(oppIds[2]).size(), 'Opportunity 2 - # of Allocations to Insert');

        // Opportunity 3 Allocation(s) - Default allocation will need to be added
        System.assertEquals(true, insertAllocsByOppId.containsKey(oppIds[3]), 'Opportunity 3 should have allocations in the insert list');
        System.assertEquals(1, insertAllocsByOppId.get(oppIds[3]).size(), 'Opportunity 3 - # of Allocations to Insert');
        assertOpportunityAllocation(insertAllocsByOppId.get(oppIds[3])[0], oppIds[3], 10, null, alloSetupTest.getDefaultGAU().Id, 'Opportunity 3 - Allocation 0');

        // Opportunity 4 Allocation(s) - Allocation with Percent and No Amount
        System.assertEquals(true, updateAllocsByOppId.containsKey(oppIds[4]), 'Opportunity 4 should have allocations in the update list');
        System.assertEquals(1, updateAllocsByOppId.get(oppIds[4]).size(), 'Opportunity 4 - # of Allocations to Update');
        assertOpportunityAllocation(updateAllocsByOppId.get(oppIds[4])[0], oppIds[4], 20, 100, alloSetupTest.getGAUs()[1].Id, 'Opportunity 4 - Allocation 0');

        // Opportunity 5 Allocation(s) - Opportunity with Amount 0 and non zero Allocations
        System.assertEquals(true, updateAllocsByOppId.containsKey(oppIds[5]), 'Opportunity 5 should have allocations in the update list');
        System.assertEquals(1, updateAllocsByOppId.get(oppIds[5]).size(), 'Opportunity 5 - # of Allocations to Update');
        assertOpportunityAllocation(updateAllocsByOppId.get(oppIds[5])[0], oppIds[5], 0, 50, alloSetupTest.getGAUs()[1].Id, 'Opportunity 5 - Allocation 0');

        // Opportunity 6 will have no changes
        System.assertEquals(false, insertAllocsByOppId.containsKey(oppIds[6]), 'Opportunity 6 - Found in Insert Allocations List');
        System.assertEquals(false, updateAllocsByOppId.containsKey(oppIds[6]), 'Opportunity 6 - Found in Update Allocations List');
        System.assertEquals(false, deleteAllocsByOppId.containsKey(oppIds[6]), 'Opportunity 6 - Found in Delete Allocations List');

        // Opportunity 7 will have no changes
        System.assertEquals(false, insertAllocsByOppId.containsKey(oppIds[7]), 'Opportunity 7 - Found in Insert Allocations List');
        System.assertEquals(false, updateAllocsByOppId.containsKey(oppIds[7]), 'Opportunity 7 - Found in Update Allocations List');
        System.assertEquals(false, deleteAllocsByOppId.containsKey(oppIds[7]), 'Opportunity 7 - Found in Delete Allocations List');

        // Opportunity 8 will delete allocation for default
        System.assertEquals (true, deleteAllocsByOppId.containsKey(oppIds[8]), 'Allocation for Opportunity 8 should be in the delete list');
        assertOpportunityAllocation(deleteAllocsByOppId.get(oppIds[8])[0], oppIds[8], 20, null, alloSetupTest.getGAUs()[2].Id, 'Opportunity 8 - Allocation 0');

        // Opportunity 9 will insert 1 allocation for $10 for GAU 1 from Campaign (Parent)
        System.assertEquals (true, insertAllocsByOppId.containsKey(oppIds[9]), 'Opportunity 9 - Found in Insert Allocations List');
        System.assertEquals(2, insertAllocsByOppId.get(oppIds[9]).size(), 'Opportunity 9 - # of Allocations to Insert');

        // Necessary to handle fact that they could be in either order
        Id gauAlloc0 = (insertAllocsByOppId.get(oppIds[9])[0].General_Accounting_Unit__c == alloSetupTest.getDefaultGAU().Id) ? alloSetupTest.getDefaultGAU().Id : alloSetupTest.getGAUs()[1].Id;
        Id gauAlloc1 = (gauAlloc0 == alloSetupTest.getDefaultGAU().Id) ? alloSetupTest.getGAUs()[1].Id : alloSetupTest.getDefaultGAU().Id;

        assertOpportunityAllocation(insertAllocsByOppId.get(oppIds[9])[0], oppIds[9], 10, null, gauAlloc0, 'Opportunity 9 - Allocation 0');
        assertOpportunityAllocation(insertAllocsByOppId.get(oppIds[9])[1], oppIds[9], 10, null, gauAlloc1, 'Opportunity 9 - Allocation 1');

        // Opportunity 10 will resize 1 allocation from $40 to $10 for GAU 1 (Simulates Opportunity Amount change from $80 to $20)
        System.assertEquals (true, updateAllocsByOppId.containsKey(oppIds[10]), 'Opportunity 10 - Found in Update Allocations List');
        System.assertEquals(2, updateAllocsByOppId.get(oppIds[10]).size(), 'Opportunity 10 - # of Allocations to Update');

        gauAlloc0 = (updateAllocsByOppId.get(oppIds[10])[0].General_Accounting_Unit__c == alloSetupTest.getDefaultGAU().Id) ? alloSetupTest.getDefaultGAU().Id : alloSetupTest.getGAUs()[1].Id;
        Decimal percentAlloc0 = (gauAlloc0 == alloSetupTest.getDefaultGAU().Id) ? null : 50;
        gauAlloc1 = (gauAlloc0 == alloSetupTest.getDefaultGAU().Id) ? alloSetupTest.getGAUs()[1].Id : alloSetupTest.getDefaultGAU().Id;
        Decimal percentAlloc1 = (gauAlloc0 == alloSetupTest.getDefaultGAU().Id) ? 50 : null;

        assertOpportunityAllocation(updateAllocsByOppId.get(oppIds[10])[0], oppIds[10], 10.00, percentAlloc0, gauAlloc0, 'Opportunity 10 - Allocation 0');
        assertOpportunityAllocation(updateAllocsByOppId.get(oppIds[10])[1], oppIds[10], 10.00, percentAlloc1, gauAlloc1, 'Opportunity 10 - Allocation 1');

        // Opportunity 11 will generate an error for a fixed allocation that is too large for the Opportunity Amount
        System.assertEquals(true, allocResults.errorsByRecordId.containsKey(oppIds[11]), 'Opportunity 11 - Error is Present');
        System.assertEquals(1, allocResults.errorsByRecordId.get(oppIds[11]).size(), 'Opportunity 11 - Number of Errors Present');
        System.assertEquals(false, insertAllocsByOppId.containsKey(oppIds[11]), 'Opportunity 11 - Found in Insert Allocations List');
        System.assertEquals(false, updateAllocsByOppId.containsKey(oppIds[11]), 'Opportunity 11 - Found in Update Allocations List');
        System.assertEquals(false, deleteAllocsByOppId.containsKey(oppIds[11]), 'Opportunity 11 - Found in Delete Allocations List');

        // Opportunity 12 will have a default allocation for $0.
        System.assertEquals(true, insertAllocsByOppId.containsKey(oppIds[12]), 'Opportunity 12 - Found in Insert Allocations List');
        System.assertEquals(1, insertAllocsByOppId.get(oppIds[12]).size(), 'Opportunity 12 - # of Allocations to Insert');
        assertOpportunityAllocation(insertAllocsByOppId.get(oppIds[12])[0], oppIds[12], 0, null, alloSetupTest.getDefaultGAU().Id, 'Opportunity 12 - Allocation 0');
    }

     /**
     * @description Confirm determines necessary Allocations changes, as well as errors based
     *              on records passed to processOpportunityAllocations
     *              [ALLO_AllocationsUtil.processOpportunityAllocations]
     *
     *      * Scenarios Covered (Default Allocation Enabled):
     * - Opportunity 0 - Opportunity with allocations and Recurring Donation Parent
     *         - Result - No Changes
     * - Opportunity 1- Opportunity without allocations and with Recurring Donation Parent
     *         - Result - Recurring Donation Allocations propogated to Opportunity as inserts
     * - Opportunity 2 - No Allocations, No Parent
     *         - Result - Default Allocation created for Amount Of Opportunity
     * - Opportunity 3 - Sum of Allocation Amounts < Opportunity Amount
     *         - Result - Default Allocation is Created for Difference between Sum of Non Default Alloc Amounts & Opp Amount
     * - Opportunity 4 - Allocation Present with Percent and No Amount
     *         - Result - Update of Allocation to set Amount
     * - Opportunity 5 - Opportunity with Amount 0 and non zero Allocations
     *         - Result - Converts to Percent Allocation with 0 Amount.
     * - Opportunity 6 - Opportunity Allocations up to date
     *         - Result - No changes
     * - Opportunity 7 - Opportunity Allocations up to date
     *         - Result - No changes
     * - Opportunity 8 - Opportunity with null Amount and non zero Default Allocation
     *         - Result - Default Allocation is Deleted
     * - Opportunity 9 - Opportunity has no allocations. Is part of a Campaign with Allocations
     *         - Result - Campaign Allocations copied to Opportunity
     * - Opportunity 10 - Existing Percentage Allocation for Amount $40, And Default Allocation, also for $40.  Opportunity Amount is $20
     *         - Result - Allocation is resized/recalculated using the Opportunity Amount and the Allocation Percentage.  Default Allocation is resized to $10
     * - Opportunity 11 - Existing Fixed Amount Allocation and Default Allocation each for Amount $40, Opportunity Amount is $20
     *         - Result - Allocation cannot be resized and is larger than Opportunity Amount.  Error is generated
     * - Opportunity 12 - Opportunity for Amount 0 with no Allocations
     *         - Result - Default Allocation is Created for $0
     */
    @isTest private static void confirmProcessingOfPaymentAllocations() {
        AllocationSetupTest alloSetupTest = new AllocationSetupTest()
            .enableDefaultAllocations()
            .enablePaymentAllocations()
            .disableAllocationTriggers()
            .applyConfiguration();

        List<Id> oppIds = createTestDataAndReturnOppIds(alloSetupTest.getGAUs(), alloSetupTest.getDefaultGAU());

        Set<Id> oppIdsAsSet = new Set<Id>();
        oppIdsAsSet.addAll(oppIds);

        Map<Id, Opportunity> oppsById = ALLO_AllocationsUtil.retrieveOpportunities(oppIdsAsSet);
        Set<Id> campaignIds = new Set<Id>();
        Set<Id> recurringDonationIds = new Set<Id>();
        Set<Id> pmtIds = new Set<Id>();

        for (Opportunity opp : oppsById.values()) {
            if (opp.CampaignId != null) {
                campaignIds.add(opp.CampaignId);
            }
            if (opp.npe03__Recurring_Donation__c != null) {
                recurringDonationIds.add(opp.npe03__Recurring_Donation__c);
            }
            for (npe01__OppPayment__c pmt : opp.npe01__OppPayment__r) {
                pmtIds.add(pmt.Id);
            }
        }

        List<Allocation__c> allocs = ALLO_AllocationsUtil.retrieveAllocations(oppIdsAsSet, pmtIds, campaignIds, recurringDonationIds);

        ALLO_AllocationsUtil.RecordsForReview recsForRev = new ALLO_AllocationsUtil.RecordsForReview();

        for (Allocation__c alloc : allocs) {
            recsForRev.addAllocationByType(alloc);
        }

         // Will track exclusions across processes
         ALLO_AllocationsUtil.RecordExclusions recExcl = new ALLO_AllocationsUtil.RecordExclusions();

        // Process Opportunity Allocations
        ALLO_AllocationsUtil.AllocationResults allocResults = ALLO_AllocationsUtil.processPaymentAllocations(oppsById, recsForRev.oppsAllocations, recsForRev.paymentAllocations, recExcl);

        Map<Id, List<Allocation__c>> deleteAllocsByPmtId = buildMapOfAllocationsByPaymentId(allocResults.allocationsForDelete);
        Map<Id, List<Allocation__c>> insertAllocsByPmtId = buildMapOfAllocationsByPaymentId(allocResults.allocationsForInsert);
        Map<Id, List<Allocation__c>> updateAllocsByPmtId = buildMapOfAllocationsByPaymentId(allocResults.allocationsForUpdate);


        List<npe01__OppPayment__c> opp6Pmts = [SELECT   Id,
                                                        npe01__Opportunity__c,
                                                        npe01__Scheduled_Date__c
                                               FROM npe01__OppPayment__c
                                               WHERE    npe01__Opportunity__c = :oppIds[6]
                                               ORDER BY npe01__Scheduled_Date__c ASC];

        // Opportunity 6 - Payment 0 [100% GAU1 Allocation Added for $10 (from Opportunity)
        System.assertEquals(true, insertAllocsByPmtId.containsKey(opp6Pmts[0].Id), 'Opportunity 6 - Payment 0 - Allocations found in Insert list');
        System.assertEquals(1, insertAllocsByPmtId.get(opp6Pmts[0].Id).size(), 'Opportunity 6 - Payment 0 - # of Allocations to Insert');
        assertPaymentAllocation(insertAllocsByPmtId.get(opp6Pmts[0].Id)[0], opp6Pmts[0].Id, 10, 100, alloSetupTest.getGAUs()[1].Id, 'Opportunity 6 - Payment 0 - Insert List - Allocation 0');

        // Opportunity 7- Payment 1 [$4 Default GAU, 50% GAU0 Amount 5, $1 GAU1]
        System.assertEquals(true, updateAllocsByPmtId.containsKey(opp6Pmts[1].Id), 'Opportunity 6 - Payment 1 - Allocations found in Update list');
        System.assertEquals(2, updateAllocsByPmtId.get(opp6Pmts[1].Id).size(), 'Opportunity 6 - Payment 1 - # of Allocations to Insert');

        Allocation__c defAlloc = null;
        Allocation__c gau0Alloc = null;
        Allocation__c gau1Alloc = null;

        for (Allocation__c alloc :updateAllocsByPmtId.get(opp6Pmts[1].Id)) {
            if (alloc.General_Accounting_Unit__c == alloSetupTest.getDefaultGAU().Id) {
                defAlloc = alloc;
            } else if (alloc.General_Accounting_Unit__c == alloSetupTest.getGAUs()[0].Id) {
                gau0Alloc = alloc;
            } else if (alloc.General_Accounting_Unit__c == alloSetupTest.getGAUs()[1].Id) {
                gau1Alloc = alloc;
            }
        }

        assertPaymentAllocation(defAlloc, opp6Pmts[1].Id, 4, null, alloSetupTest.getDefaultGAU().Id, 'Opportunity 6 - Payment 1 - Update List - Default Allocation');
        assertPaymentAllocation(gau0Alloc, opp6Pmts[1].Id, 5, 50, alloSetupTest.getGAUs()[0].Id, 'Opportunity 6 - Payment 1 - Update List - GAU 0 Allocation');
        System.assertEquals(null, gau1Alloc, 'Opportunity 6 - Payment 1 - GAU 1 should not be present in Update List');

        // Opportunity 7- Payment 2 [$1 GAU0]
        System.assertEquals(true, insertAllocsByPmtId.containsKey(opp6Pmts[2].Id), 'Opportunity 6 - Payment 2 - Allocations found in Insert list');
        System.assertEquals(1, insertAllocsByPmtId.get(opp6Pmts[2].Id).size(), 'Opportunity 6 - Payment 2 - # of Allocations to Insert');
        assertPaymentAllocation(insertAllocsByPmtId.get(opp6Pmts[2].Id)[0], opp6Pmts[2].Id, 9, null, alloSetupTest.getDefaultGAU().Id, 'Opportunity 6 - Payment 2 - Insert List - Allocation 0');



    }

    /**
     * @description Confirm determines necessary Allocations changes, as well as errors based
     *              on records passed to processOpportunityAllocations
     *              [ALLO_AllocationsUtil.processOpportunityAllocations]
     *
     * Scenarios Covered (Default Allocation Not Enabled):
     * - Opportunity 0 - Opportunity with allocations and Recurring Donation Parent
     *         - Result - No Changes
     * - Opportunity 1- Opportunity without allocations and with Recurring Donation Parent
     *         - Result - Recurring Donation Allocations propogated to Opportunity as inserts
     * - Opportunity 2 - No Allocations, No Parent
     *         - Result - No Changes
     * - Opportunity 3 - Sum of Allocation Amounts < Opportunity Amount
     *         - Result - No Changes
     * - Opportunity 4 - Allocation Present with Percent and No Amount
     *         - Result - Update of Allocation to set Amount
     * - Opportunity 5 - Opportunity with Amount 0 and non zero Allocations
     *         - Result - Converts to Percent Allocation with 0 Amount.  Might not make sense for when Default Allocations Not Enabled, since
     *                    Amount could have been < Original Opp Amount.  TODO: Review, Determine if change required/what change would be
     * - Opportunity 6 - Opportunity Allocations up to date
     *         - Result - No changes
     * - Opportunity 7 - Opportunity Allocations up to date
     *         - Result - No changes
     * - Opportunity 8 - Opportunity with null Amount and non zero Allocation
     *         - Result - Should be deleted
     * - Opportunity 9 - Opportunity has no allocations. Is part of a Campaign with Allocations
     *         - Result - Campaign Allocations copied to Opportunity
     * - Opportunity 10 - Existing Percentage Allocation for Amount $40, Opportunity Amount is $20
     *         - Result - Allocation is resized/recalculated using the Opportunity Amount and the Allocation Percentage
     * - Opportunity 11 - Existing Fixed Amount Allocation for Amount $40, Opportunity Amount is $20
     *         - Result - Allocation cannot be resized and is larger than Opportunity Amount.  Error is generated
     * - Opportunity 12 - Opportunity for Amount 0 with no Allocations
     *         - Result - No changes
     */
    @isTest private static void confirmProcessingOfOpportunitiesWhenDefaultAllocNotEnabled() {
        AllocationSetupTest alloSetupTest = new AllocationSetupTest()
            .disableAllocationTriggers()
            .applyConfiguration();

        List<Id> oppIds = createTestDataAndReturnOppIds(alloSetupTest.getGAUs(), alloSetupTest.getDefaultGAU());

        Set<Id> oppIdsAsSet = new Set<Id>();
        oppIdsAsSet.addAll(oppIds);

        Map<Id, Opportunity> oppsById = ALLO_AllocationsUtil.retrieveOpportunities(oppIdsAsSet);
        Set<Id> campaignIds = new Set<Id>();
        Set<Id> recurringDonationIds = new Set<Id>();
        Set<Id> pmtIds = new Set<Id>();

        for (Opportunity opp : oppsById.values()) {
            if (opp.CampaignId != null) {
                campaignIds.add(opp.CampaignId);
            }
            if (opp.npe03__Recurring_Donation__c != null) {
                recurringDonationIds.add(opp.npe03__Recurring_Donation__c);
            }
            for (npe01__OppPayment__c pmt : opp.npe01__OppPayment__r) {
                pmtIds.add(pmt.Id);
            }
        }

        List<Allocation__c> allocs = ALLO_AllocationsUtil.retrieveAllocations(oppIdsAsSet, pmtIds, campaignIds, recurringDonationIds);

        ALLO_AllocationsUtil.RecordsForReview recsForRev = new ALLO_AllocationsUtil.RecordsForReview();

        for (Allocation__c alloc : allocs) {
            recsForRev.addAllocationByType(alloc);
        }

         // Will track exclusions across processes
         ALLO_AllocationsUtil.RecordExclusions recExcl = new ALLO_AllocationsUtil.RecordExclusions();

        // Process Opportunity Allocations
        ALLO_AllocationsUtil.AllocationResults allocResults = ALLO_AllocationsUtil.processOpportunityAllocations(oppsById, recsForRev.oppsAllocations, recsForRev.campaignAllocations, recsForRev.recurringDonationAllocations, recExcl);

        Map<Id, List<Allocation__c>> deleteAllocsByOppId = buildMapOfAllocationsByOpportunityId(allocResults.allocationsForDelete);
        Map<Id, List<Allocation__c>> insertAllocsByOppId = buildMapOfAllocationsByOpportunityId(allocResults.allocationsForInsert);
        Map<Id, List<Allocation__c>> updateAllocsByOppId = buildMapOfAllocationsByOpportunityId(allocResults.allocationsForUpdate);

        // Opportunity 0 will have no changes
        System.assertEquals(false, insertAllocsByOppId.containsKey(oppIds[0]), 'Opportunity 0 - Found in Insert Allocations List');
        System.assertEquals(false, updateAllocsByOppId.containsKey(oppIds[0]), 'Opportunity 0 - Found in Update Allocations List');
        System.assertEquals(false, deleteAllocsByOppId.containsKey(oppIds[0]), 'Opportunity 0 - Found in Delete Allocations List');

        // Opportunity 1 will be allocated from Recurring Donation parent
        System.assertEquals(true, insertAllocsByOppId.containsKey(oppIds[1]), 'Opportunity 1 Found in Insert Allocations List');
        System.assertEquals(2, insertAllocsByOppId.get(oppIds[1]).size(), 'Opportunity 1 - # of Allocations to Insert');

        // Opportunity 2 will not be allocated, no parent
        System.assertEquals(false, insertAllocsByOppId.containsKey(oppIds[2]), 'Opportunity 2 - Found in Insert Allocations List');
        System.assertEquals(false, updateAllocsByOppId.containsKey(oppIds[2]), 'Opportunity 2 - Found in Update Allocations List');
        System.assertEquals(false, deleteAllocsByOppId.containsKey(oppIds[2]), 'Opportunity 2 - Found in Delete Allocations List');

        // Opportunity 3 Allocation(s) - will not be allocated, sum of alloc amount < Opp Amount, but no default alloc
        System.assertEquals(false, insertAllocsByOppId.containsKey(oppIds[3]), 'Opportunity 3 - Found in Insert Allocations List');
        System.assertEquals(false, updateAllocsByOppId.containsKey(oppIds[3]), 'Opportunity 3 - Found in Update Allocations List');
        System.assertEquals(false, deleteAllocsByOppId.containsKey(oppIds[3]), 'Opportunity 3 - Found in Delete Allocations List');

        // Opportunity 4 Allocation(s) - Allocation with Percent and No Amount
        System.assertEquals(true, updateAllocsByOppId.containsKey(oppIds[4]), 'Opportunity 4 should have allocations in the update list');
        System.assertEquals(1, updateAllocsByOppId.get(oppIds[4]).size(), 'Opportunity 4 - # of Allocations to Update');
        assertOpportunityAllocation(updateAllocsByOppId.get(oppIds[4])[0], oppIds[4], 20, 100, alloSetupTest.getGAUs()[1].Id, 'Opportunity 4 - Allocation 0');

        // Opportunity 5 Allocation(s) - Opportunity with Amount 0 and non zero Allocations
        System.assertEquals(true, updateAllocsByOppId.containsKey(oppIds[5]), 'Opportunity 5 should have allocations in the update list');
        System.assertEquals(1, updateAllocsByOppId.get(oppIds[5]).size(), 'Opportunity 5 - # of Allocations to Update');
        assertOpportunityAllocation(updateAllocsByOppId.get(oppIds[5])[0], oppIds[5], 0, 50, alloSetupTest.getGAUs()[1].Id, 'Opportunity 5 - Allocation 0');

        // Opportunity 6 will have no changes
        System.assertEquals(false, insertAllocsByOppId.containsKey(oppIds[6]), 'Opportunity 6 - Found in Insert Allocations List');
        System.assertEquals(false, updateAllocsByOppId.containsKey(oppIds[6]), 'Opportunity 6 - Found in Update Allocations List');
        System.assertEquals(false, deleteAllocsByOppId.containsKey(oppIds[6]), 'Opportunity 6 - Found in Delete Allocations List');

        // Opportunity 7 will have no changes
        System.assertEquals(false, insertAllocsByOppId.containsKey(oppIds[7]), 'Opportunity 7 - Found in Insert Allocations List');
        System.assertEquals(false, updateAllocsByOppId.containsKey(oppIds[7]), 'Opportunity 7 - Found in Update Allocations List');
        System.assertEquals(false, deleteAllocsByOppId.containsKey(oppIds[7]), 'Opportunity 7 - Found in Delete Allocations List');

        // Opportunity 8 will delete allocation (since Opportunity Amount is null)
        System.assertEquals(true, deleteAllocsByOppId.containsKey(oppIds[8]), 'Opportunity 8 - Found in Delete Allocations List');
        assertOpportunityAllocation(deleteAllocsByOppId.get(oppIds[8])[0], oppIds[8], 20, 100, alloSetupTest.getGAUs()[2].Id, 'Opportunity 8 - Allocation 0');

        // Opportunity 9 will insert 1 allocation for $10 for GAU 1 from Campaign (Parent)
        System.assertEquals(true, insertAllocsByOppId.containsKey(oppIds[9]), 'Opportunity 9 - Found in Insert Allocations List');
        System.assertEquals(1, insertAllocsByOppId.get(oppIds[9]).size(), 'Opportunity 9 - # of Allocations to Insert');
        assertOpportunityAllocation(insertAllocsByOppId.get(oppIds[9])[0], oppIds[9], 10, null, alloSetupTest.getGAUs()[1].Id, 'Opportunity 9 - Allocation 0');

        // Opportunity 10 will resize 1 allocation from $40 to $10 for GAU 1 (Simulates Opportunity Amount change from $80 to $20)
        System.assertEquals(true, updateAllocsByOppId.containsKey(oppIds[10]), 'Opportunity 10 - Found in Update Allocations List');
        System.assertEquals(1, updateAllocsByOppId.get(oppIds[10]).size(), 'Opportunity 10 - # of Allocations to Update');
        assertOpportunityAllocation(updateAllocsByOppId.get(oppIds[10])[0], oppIds[10], 10.00, 50, alloSetupTest.getGAUs()[1].Id, 'Opportunity 10 - Allocation 0');

        // Opportunity 11 will generate an error for a fixed allocation that is too large for the Opportunity Amount
        System.assertEquals(true, allocResults.errorsByRecordId.containsKey(oppIds[11]), 'Opportunity 11 - Error is Present');
        System.assertEquals(1, allocResults.errorsByRecordId.get(oppIds[11]).size(), 'Opportunity 11 - Number of Errors Present');
        System.assertEquals(false, insertAllocsByOppId.containsKey(oppIds[11]), 'Opportunity 11 - Found in Insert Allocations List');
        System.assertEquals(false, updateAllocsByOppId.containsKey(oppIds[11]), 'Opportunity 11 - Found in Update Allocations List');
        System.assertEquals(false, deleteAllocsByOppId.containsKey(oppIds[11]), 'Opportunity 11 - Found in Delete Allocations List');

        // Opportunity 12 will have a default allocation for $0.
        System.assertEquals(false, insertAllocsByOppId.containsKey(oppIds[12]), 'Opportunity 12 - Found in Insert Allocations List');
        System.assertEquals(false, updateAllocsByOppId.containsKey(oppIds[12]), 'Opportunity 12 - Found in Update Allocations List');
        System.assertEquals(false, deleteAllocsByOppId.containsKey(oppIds[12]), 'Opportunity 12 - Found in Delete Allocations List');
    }

    // TODO: Add Multicurrency Tests to run conditionally


    // TODO: Method: processAllocationResults (also will cover processAllocationDeleteResults, processAllocationInsertResults, processAllocationUpdateResults, processFunctionalErrors)
    // Pass Allocation Records, To be Inserted, Updated, and Deletes, as well as functional errors to be added
    // Must have a populated RecordsForReview object with the records that will be updated
    // Should confirm that the Allocation Maps are updated afterward for the Inserts, Updates, and Deletes
    // Should confirm functional errors are added, and exclusions should be added
    // Confirm at least update errors are handled (by attempting to update an Allocation without an Id)

    // TODO: Method: determineSuccessfullyProcessedRecords
    // Confirm any records without exclusions are returned as Successful

    // TODO: Method: copyAllocationsToTarget
    // Do not copy Allocations to target, or calculate the Default Allocation if the Parent Amount is null/zero
    // Confirm copies from Parent (Use Opportunity and Payment)
        // Confirm percent based Allocations are scaled to amount
        // Confirm amount based Allocations are converted to percent if convertToPercentages is true
        // Confirm amount based Allocations are not converted to percentage if convertToPercentages is false
        // Confirm amount based Allocations are dropped if total with amount based Allocations exceeds target Amount (convertToPercentages is false)
        // Confirm amount based allocations are converted to percent
        // Confirm works with positive and negative payment amounts
        // Confirm default is only created when there is room for default
        // Confirm Inactive Allocations are only copied if copyInactiveAllocation is true
            // Create Opportunity with Allocations.  Make one of the Allocations GAU's inactive.  Do tests to confirm both not copied, and copied to Payment depending on this value.

    //TODO: Method: resizeAllocationsAsNeeded
    // Should attempt to convert all allocations (except the default allocation) to percentages and set the Allocation Amount to null/0 if target amount is null/0
    // Should recalculate percentage based allocations and validate allocations if amount is non null/zero
        // Should confirm success case where fixed amount and percent amount are resized successfully and default is recalculated, as well as error case where total exceeds new amount because of fixed allocation amount
        // Should also do a test where percentages total above 100%

    // TODO: Method: clearAllocations
    // Confirm converts Amount Allocations to Percent, Nulls All Amounts, and Deletes the Default Allocation
    // Confirm if errors are present, deletes all allocations.  Insert fixed Allocation with Amount of 100, and other Percent Allocations with percentage of 10 and amount of 0.  This will error.
    // Confirm errors if Allocations present with amount 0 and no percentage (Add only allocations with Amount 0, and one or more percentages not filled out

    // TODO: Method: processDefaultAllocations
    // Confirm adds default if parent amount is positive and parent amount is > Allocation amount > 0 and Default Allocation is not present in defaultAllocations list
    // Confirm adds default if parent amount is negative and parent amount is < Allocation amount < 0 and Default Allocation is not present in defaultAllocations list
    // Confirm if multiple Allocations for default are present in defaultAllocations list, and a Default Allocation is still needed, it deletes all but the first, and resizes that Allocation
    // Confirm if Default Allocation is present, and is no longer needed (Parent amount = Allocation amount)

    // TODO: Method: makeDefaultAllocation
    // Confirm creates an Allocation associated with the Default for the specified Amount

    /*******************************************************************************************************
     * Helper Methods - Record Retrieval Tests
     ********************************************************************************************************/

     /**
     * @description Confirm retrieves Opportunity and Payment Data for the the Opportunity Ids specified
     *              [ALLO_AllocationsUtil.retrieveOpportunities]
     */
    @isTest private static void confirmOpportunitiesInSetAreRetrievedSuccessfully() {
        AllocationSetupTest alloSetupTest = new AllocationSetupTest()
            .enableDefaultAllocations()
            .disableAllocationTriggers()
            .applyConfiguration();

        List<Id> oppIds = createTestDataAndReturnOppIds(alloSetupTest.getGAUs(), alloSetupTest.getDefaultGAU());

        Set<Id> oppIdsAsSet = new Set<Id>();
        oppIdsAsSet.addAll(oppIds);

        Map<Id, Opportunity> oppsById = ALLO_AllocationsUtil.retrieveOpportunities(oppIdsAsSet);

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
        System.assertEquals (3, opp6.npe01__OppPayment__r.size(), 'Opportunity 6 - # of Payments');

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
    }

    /**
     * @description Confirm retrieves Allocation Data for the Opportunities, Payments, Recurring Donations, and
     *              Campaigns specified (via Ids)
     *              [ALLO_AllocationsUtil.retrieveAllocations]
     */
    @isTest private static void confirmAllocationsAreRetrievedSuccessfully() {
        AllocationSetupTest alloSetupTest = new AllocationSetupTest()
            .enableDefaultAllocations()
            .disableAllocationTriggers()
            .applyConfiguration();

        List<Id> oppIds = createTestDataAndReturnOppIds(alloSetupTest.getGAUs(), alloSetupTest.getDefaultGAU());
        Set<Id> oppIdsAsSet = new Set<Id>();
        oppIdsAsSet.addAll(oppIds);

        Map<Id, Opportunity> oppsById = ALLO_AllocationsUtil.retrieveOpportunities(oppIdsAsSet);

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

        List<Allocation__c> allocs = ALLO_AllocationsUtil.retrieveAllocations(oppIdsAsSet, pmtIds, campaignIds, recurringDonationIds);

        assertSObjectList(allocs, 19, 'Allocations');

        ALLO_AllocationsUtil.RecordsForReview recsForRev = new ALLO_AllocationsUtil.RecordsForReview();

        for (Allocation__c alloc : allocs) {
            recsForRev.addAllocationByType(alloc);
        }
        assertSObjectList(recsForRev.oppsAllocations.get(oppIds[0]), 2, 'Opportunity 0 - Allocations');
        assertSObjectList(recsForRev.oppsAllocations.get(oppIds[3]), 1, 'Opportunity 3 - Allocations');
        assertSObjectList(recsForRev.oppsAllocations.get(oppIds[4]), 1, 'Opportunity 4 - Allocations');
        assertSObjectList(recsForRev.oppsAllocations.get(oppIds[5]), 1, 'Opportunity 5 - Allocations');
        assertSObjectList(recsForRev.oppsAllocations.get(oppIds[6]), 1, 'Opportunity 6 - Allocations');
        assertSObjectList(recsForRev.oppsAllocations.get(oppIds[7]), 1, 'Opportunity 7 - Allocations');

        Allocation__c alloc = recsForRev.oppsAllocations.get(oppIds[7])[0];
        assertOpportunityAllocation(alloc, oppIds[7], 20, 100, 'GAU 2', 'Opportunity 7 - Allocation 0' );

        System.assertEquals(3, recsForRev.paymentAllocations.size(), 'Payment Allocations');

        Opportunity opp7 = oppsById.get(oppIds[7]);

        alloc = recsForRev.paymentAllocations.get(opp7.npe01__OppPayment__r[0].Id)[0];
        assertPaymentAllocation(alloc, opp7.npe01__OppPayment__r[0].Id, 10, 100, 'GAU 2', 'Opportunity 7 - Payment 0 - Allocation 0');

        System.assertEquals(2, recsForRev.recurringDonationAllocations.get(recurringDonationId).size(), 'Recurring Donation Allocations');
        alloc = recsForRev.recurringDonationAllocations.get(recurringDonationId)[0];
        Allocation__c alloc2 = null;
        if (alloc.Percent__c != null) {
            alloc2 = recsForRev.recurringDonationAllocations.get(recurringDonationId)[1];
        } else {
            alloc2 = alloc;
            alloc = recsForRev.recurringDonationAllocations.get(recurringDonationId)[1];
        }
        assertRecurringDonationAllocation(alloc, recurringDonationId, null, 50, 'GAU 1', 'Recurring Donation - Allocation 0');
        assertRecurringDonationAllocation(alloc2, recurringDonationId, 10, null, 'GAU 2', 'Recurring Donation - Allocation 1');
    }

    /*******************************************************************************************************
     * Helper Methods - Allocation Triggers
     ********************************************************************************************************/

    // TODO: Method: disableAllocationTriggers, updateAllocationTriggersState
    // Confirm the state of the following triggers is False
        // ALLO_Allocations_TDTM (Allocation__c, Opportunity, npe01__OppPayment__c Objects)
        // ALLO_PaymentSync_TDTM (Allocation__c)

    // TODO: Method: enableAllocationTriggers, updateAllocationTriggersState
    // Confirm the state of the following triggers is False
        // ALLO_Allocations_TDTM (Allocation__c, Opportunity, npe01__OppPayment__c Objects)
        // ALLO_PaymentSync_TDTM (Allocation__c)

    /*****************************************
     * Helper Methods - Process Exclusions Tests
     *****************************************/

    // TODO: Method: getProcessExclusions
    // Confirm it allocates and returns a Map of Set of PROCESS_DEF records, keyed by PROCESS_DEF.  It should only allocate it once, no matter how many times it is called

    // TODO: Method: getProcessExclusionsFor
    // Confirm it returns the Set of Process Exclusions for a specific Process

    /*****************************************
     * Helper Methods - Allocation Maps
     *****************************************/

    // TODO: Method: add (Id to parentId to Children(Ids))
    // Confirm it adds a child Id to a parent, creating a new Set if necessary, and adding to the Set if not

    // TODO: Method: add (Allocation to a Map of a List of Allocations by parent's Id)
    // Confirm it adds an allocation to a list of allocations in a map, keyed by the parents id, creating a new list if necessary, and adding to the list if not

    // TODO: Method: remove (Allocation from a Map of a List of Allocations by parent's Id)
    // Confirm it will remove an allocation from a List of Allocations by parent, if present

    // TODO: Method: replace (Allocation in a Map of a List of Allocations by parent's Id)
    // Confirm it will find an Allocation in a List of Allocations, keyed by Parent Id, and replace it with the latest version.  It is added to the end if the Allocation is not already in the list

    /*****************************************
     * Helper Methods - Record Review Methods
     *****************************************/

    // TODO: Method: removeIfNotForReview (Parent to Set of Opportunities)
    // Confirm records in allocationByParentId are removed if none of the Opportunities the Parent references are not in the oppsById keyset

    // TODO: Method: set1ContainsAnyInSet2
    // Confirm returns true if one or more members of set2 are present in set1, and false otherwise

    // TODO: Method: removeIfNotForReview (Parent to Opp)
    // Confirms records in allocationsByParentId are removed if the Opportunity that Parent references is not in the oppsById keyset

    // TODO: Method: removeIfNotForReview (Opp)
    // Confirms records in allocationsByParentId are removed if the Allocation Parent Id is not in the oppsById keyset

    /*****************************************
     * Helper Methods - Allocation Validation Tests
     *****************************************/

    // TODO: Method: validatePaymentAllocationsConfiguration
    // Validate that if the configuration is correct, no errors are returned
    // Validate that it checks correctly for Payment Allocations Not Enabled, Default Allocations Not Enabled, Default Allocation not configured, Default Allocation not exist, Default Allocation Not Active

    // TODO: Method: validateAllocation, validateAllocationHasParentError
    // Validate that Allocation with no or multiple parents returns error
    // Validate that Allocation with neither amount nor percent returns error
    // Validate that Only Allocations Associated with a Payment can be negative
    // Validate that Allocation cannot have a negative percent

    /***************************
     * Helper Methods - Error Tests
     ***************************/

    // TODO: Method: assembleAllocationError
    // Confirm it builds a properly formatted error message (associated with a parent and allocation)

    // TODO: Method: assembleRecordError
    // Confirm it builds a properly formatted error message (associated with a parent)

    /***************************
     * Helper Methods - General Tests
     ***************************/

    // TODO: Method: getOpportunityIdFor
    // Confirm it returns the Record Id if it is passed an Opportunity Id or the value in the field npe01__Opportunity__c if passed a payment

    // TODO: Method: getAmountFor
    // Confirm it returns the value in the Amount field if passed an Opportunity, and the value in npe01__Payment_Amount__c if passed a Payment

    // TODO: Method: getLabelFor, getOpportunityLabel, getPaymentLabel
    // Confirm it returns the Opportunity Label if passed an Opportunity Record, and the Payment Label if Passed a Payment object
    // Note: Describe call is only done once

    // TODO: Method: getAllocationLabel
    // Confirm it returns the Allocation Object Label
    // Note: Describe call is only done once

    /***************************
     * Helper Methods - Callable Support
     ***************************/

    /*******************************************************************************************************
    * @description - Test calling ALLO_UpdPaymentAllocations_BATCH via the Callable_Api class. Assert that
    * an opportunity is processed when meeting the criteria and excluded when the criteria are not met. Also
    * ensure that a default allocation is created for any unallocated amount.
    ********************************************************************************************************/
    @isTest private static void processOppsAndPaymentAllocationsViaCallableApi() {

        AllocationSetupTest alloSetupTest = new AllocationSetupTest()
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
                'ProcessingBoundary' => null,
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

    /*******************************************************************************************************
    * @description Test validating the Payment Allocation Configuration via Callable_Api when the settings
    * are configured properly.
    ********************************************************************************************************/
    @isTest private static void validatePaymentAllocationConfigurationViaCallableApiNoErrors() {

        Test.startTest();

        AllocationSetupTest alloSetupTest = new AllocationSetupTest()
            .enableDefaultAllocations()
            .enablePaymentAllocations()
            .applyConfiguration();

        Callable npspApi = (Callable) Type.forName('Callable_API').newInstance();
        Map<String, Object> npspApiParams = new Map<String, Object>();
        List<String> configProblems = (List<String>)npspApi.call(ALLO_VALIDATE_CONFIG_ACTION, npspApiParams);

        Test.stopTest();

        System.assertEquals(true, configProblems.isEmpty(), 'Payment Allocation configuration check returned errors');
    }

    /*******************************************************************************************************
    * @description Test validating the Payment Allocation Configuration via Callable_Api when the settings
    * are not configured properly.
    ********************************************************************************************************/
    @isTest private static void validatePaymentAllocationConfigurationViaCallableApiWithErrors() {

        Test.startTest();

        Callable npspApi = (Callable) Type.forName('Callable_API').newInstance();
        Map<String, Object> npspApiParams = new Map<String, Object>();
        List<String> configProblems = (List<String>)npspApi.call(ALLO_VALIDATE_CONFIG_ACTION, npspApiParams);

        Test.stopTest();

        System.assertEquals(false, configProblems.isEmpty(), 'Payment Allocation configuration validated - Errors were expected');
    }

    /***************************
     * Helper Methods - Test Data
     ***************************/

    /**
     * @description Supports certain tests, creating Opportunities and Related Information
     * @param paymentAllocationsEnabled Boolean if true, Payment Allocations will be enabled
     * @param defaultAllocationsEnabled Boolean if true, Default Allocations will be enabled
     * @return List<Id> List of Opportunities Ids, in the order they were inserted
     */
    private static List<Id> createTestDataAndReturnOppIds(List<General_Accounting_Unit__c> gaus, General_Accounting_Unit__c defaultGAU) {
        List<Account> accs = UTIL_UnitTestData_TEST.createMultipleTestAccounts(1, null);
        insert accs;

        npe03__Recurring_Donation__c rd = new TEST_RecurringDonationBuilder()
            .withInstallmentPeriodYearly()
            .withDateEstablished(Date.newInstance(1984,01,29))
            .withAccount(accs[0].Id)
            .withAmount(20)
            .withScheduleTypeMultiplyValue()
            .withOpenEndedStatusOpen()
            .build();
        insert rd;

        Campaign cam = new Campaign(Name='Test Campaign: ' + UTIL_UnitTestData_TEST.getUniqueString(), IsActive=true);
        insert cam;

        List<Contact> ctcs = UTIL_UnitTestData_TEST.createMultipleTestContacts(NUMBER_OF_CONTACTS_AND_OPPORTUNITIES);
        insert ctcs;

        List<Opportunity> opps = UTIL_UnitTestData_TEST.oppsForContactList(ctcs, null, UTIL_UnitTestDATA_TEST.getClosedWonStage(), System.today().addDays(30), 20, null, null);
        opps[0].npe03__Recurring_Donation__c = rd.Id;
        opps[1].npe03__Recurring_Donation__c = rd.Id;
        opps[5].Amount = 0;
        opps[8].Amount = null;
        opps[9].CampaignId = cam.Id;
        opps[12].Amount = 0;

        for (Opportunity opp : opps) {
            opp.npe01__Do_Not_Automatically_Create_Payment__c = true;
        }
        insert opps;

        List<npe01__OppPayment__c> pmts = new List<npe01__OppPayment__c>();

        pmts.add(
            new npe01__OppPayment__c(
                npe01__Payment_Amount__c = 10,
                npe01__Opportunity__c = opps[6].Id,
                npe01__Scheduled_Date__c = System.today()
            )
        );
        pmts.add(
            new npe01__OppPayment__c(
                npe01__Payment_Amount__c = 10,
                npe01__Opportunity__c = opps[7].Id,
                npe01__Scheduled_Date__c = System.today()
            )
        );
        pmts.add(
            new npe01__OppPayment__c(
                npe01__Payment_Amount__c = 10,
                npe01__Opportunity__c = opps[6].Id,
                npe01__Scheduled_Date__c = System.today().addDays(1)
            )
        );
        pmts.add(
            new npe01__OppPayment__c(
                npe01__Payment_Amount__c = 10,
                npe01__Opportunity__c = opps[6].Id,
                npe01__Scheduled_Date__c = System.today().addDays(2)
            )
        );

        insert pmts;

        List<Allocation__c> allosForInsert = new list<Allocation__c>();
        // Recurring Donation Allocations
        allosForInsert.add(
            new Allocation__c(
                Recurring_Donation__c = rd.id,
                Percent__c = 50,
                General_Accounting_Unit__c = gaus[0].id
            )
        );


        allosForInsert.add(
            new Allocation__c(
                Recurring_Donation__c = rd.id,
                Amount__c = 10,
                General_Accounting_Unit__c = gaus[1].id
            )
        );

        // Campaign Allocation
        allosForInsert.add(
            new Allocation__c(
                Campaign__c = cam.id,
                Amount__c = 10,
                General_Accounting_Unit__c = gaus[1].id
            )
        );

        // Opportunity 0 Allocation(s) - Properly Allocated, parent Recurring Donation
        allosForInsert.add(
            new Allocation__c(
                Opportunity__c = opps[0].Id,
                Amount__c = 10,
                Percent__c = 50,
                General_Accounting_Unit__c = gaus[0].Id
            )
        );

        allosForInsert.add(
            new Allocation__c(
                Opportunity__c = opps[0].Id,
                Amount__c = 10,
                General_Accounting_Unit__c = gaus[1].id
            )
        );

        // Opportunity 1 Allocation(s) - No Allocations present, parent Recurring Donation

        // Opportunity 2 Allocation(s) - No Allocations present, no parent

        // Opportunity 3 Allocation(s) - Sum of Allocations Amount < Opp Amount
        allosForInsert.add(
            new Allocation__c(
                Opportunity__c=opps[3].Id,
                Amount__c = 10,
                General_Accounting_Unit__c = gaus[1].Id
                )
        );

        // Opportunity 4 Allocation(s) - Allocation with Percent and No Amount
        allosForInsert.add(
            new Allocation__c(
                Opportunity__c=opps[4].Id,
                Percent__c = 100,
                General_Accounting_Unit__c = gaus[1].Id
            )
        );

        // Opportunity 5 Allocation(s) - Opportunity with Amount 0 and non zero Allocations
        allosForInsert.add(
            new Allocation__c(
                Opportunity__c=opps[5].Id,
                Amount__c = 20,
                Percent__c = 50,
                General_Accounting_Unit__c = gaus[1].Id
            )
        );

        // Opportunity 6 Allocation(s) - Opportunity Allocated, Related Payment 0 not Allocated
        allosForInsert.add(
            new Allocation__c(
                Opportunity__c=opps[6].Id,
                Amount__c = 20,
                Percent__c = 100,
                General_Accounting_Unit__c = gaus[1].Id
            )
        );

        if (defaultGau != null) { // Only if defaults enabled...)
            // Opportunity 6, Payment 1 - Payment Allocations, Default Allocation for $10 (Default), Percent Allocation for 50% (GAU0), Fixed for $1 (GAU1)
            allosForInsert.add(
                new Allocation__c(
                    Payment__c = pmts[2].Id,
                    Amount__c = 10,
                    General_Accounting_Unit__c = defaultGau.Id
                )
            );


            allosForInsert.add(
                new Allocation__c(
                    Payment__c = pmts[2].Id,
                    Percent__c = 50,
                    General_Accounting_Unit__c = gaus[0].Id
                )
            );
            allosForInsert.add(
                new Allocation__c(
                    Payment__c = pmts[2].Id,
                    Amount__c = 1,
                    General_Accounting_Unit__c = gaus[1].Id
                )
            );

            // Opportunity 6 - Payment 2 - Fixed Amount Allocation for $1, GAU0
            allosForInsert.add(
                new Allocation__c(
                    Payment__c = pmts[3].Id,
                    Amount__c = 1,
                    General_Accounting_Unit__c = gaus[0].Id
                )
            );

            // Add Test where Payment has $1 Fixed Alloc for GAU1 to confirm $9 Default Allocation is Added
            // Add Test where Payment has 100% Allocation for GAU0 and Default Allocation for $10 to confirm Default Allocation is removed.
            // Add Test where Payment is $0, with GAUs confirm behavior with percentage allocation
            // Add test where Payment is null, with GAUs confirm behavior with percentage allocation

        }
        // Opportunity 7 Allocation(s) - Opportunity Allocated, Related Payment Allocated
        allosForInsert.add(
            new Allocation__c(
                Opportunity__c=opps[7].Id,
                Amount__c = 20,
                Percent__c = 100,
                General_Accounting_Unit__c = gaus[1].Id
            )
        );

        // Opportunity 7, Payment Allocation(s) - Payment Properly Allocated
        allosForInsert.add(
            new Allocation__c(
                Payment__c = pmts[1].Id,
                Amount__c = 10,
                Percent__c = 100,
                General_Accounting_Unit__c = gaus[1].Id
            )
        );

        // Opportunity 8 Allocation(s) - Opportunity with null Amount
        //      If Default Allocations Enabled, non zero fixed amount for Default Allocation
        //      If Default Allocations Disabled non zero amount with percent value for gau 2
        allosForInsert.add(
            new Allocation__c(
                Opportunity__c=opps[8].Id,
                Amount__c = 20,
                Percent__c = (defaultGau != null) ? null : 100,
                General_Accounting_Unit__c = (defaultGau != null) ? defaultGau.Id : gaus[2].Id
            )
        );

        // Opportunity 9 - No allocations.  Parent Campaign

        // Opportunity 10 - Existing Allocations, Resize for Opportunity Amount Difference
        if (defaultGau != null) { // Only if defaults enabled...
            allosForInsert.add(
                new Allocation__c(
                    Opportunity__c=opps[10].Id,
                    Amount__c = 40,
                    Percent__c = null,
                    General_Accounting_Unit__c = defaultGau.Id
                )
            );
        }

        allosForInsert.add(
            new Allocation__c(
                Opportunity__c=opps[10].Id,
                Amount__c = 40,
                Percent__c = 50,
                General_Accounting_Unit__c = gaus[1].Id
            )
        );

        // Opportunity 11 - Invalid existing fixed allocation that is too large for the Opportunity Amount
        allosForInsert.add(
            new Allocation__c(
                Opportunity__c=opps[11].Id,
                Amount__c = 40,
                Percent__c = null,
                General_Accounting_Unit__c = gaus[1].Id
            )
        );


        insert allosForInsert;

        // Need to query data so critical fields like LastModifiedDate are populated
        List<Id> oppIds = new List<Id>();
        for (Opportunity opp : opps) {
            oppIds.add(opp.Id);
        }

        return oppIds;
    }

    private static void assertOpportunityAllocation(Allocation__c alloc, Id opportunityId, Decimal amount, Decimal percentage, Id gauId, String message) {
        assertAllocation(alloc, opportunityId, null, null, null, amount, percentage, null, gauId, message);
    }


    private static void assertOpportunityAllocation(Allocation__c alloc, Id opportunityId, Decimal amount, Decimal percentage, String gauName, String message) {
        assertAllocation(alloc, opportunityId, null, null, null, amount, percentage, gauName, null, message);
    }

    private static void assertPaymentAllocation(Allocation__c alloc, Id paymentId, Decimal amount, Decimal percentage, String gauName, String message) {
        assertAllocation(alloc, null, paymentId, null, null, amount, percentage, gauName, null, message);
    }

    private static void assertPaymentAllocation(Allocation__c alloc, Id paymentId, Decimal amount, Decimal percentage, Id gauId, String message) {
        assertAllocation(alloc, null, paymentId, null, null, amount, percentage, null, gauId, message);
    }

    private static void assertRecurringDonationAllocation(Allocation__c alloc, Id recurringDonationId, Decimal amount, Decimal percentage, String gauName, String message) {
        assertAllocation(alloc, null, null, recurringDonationId, null, amount, percentage, gauName, null, message);
    }

    private static void assertCampaignAllocation(Allocation__c alloc, Id campaignId, Decimal amount, Decimal percentage, String gauName, String message) {
        assertAllocation(alloc, null, null, null, campaignId, amount, percentage, gauName, null, message);
    }

    private static void assertAllocation(Allocation__c alloc, Id opportunityId, Id paymentId, Id recurringDonationId, Id campaignId, Decimal amount, Decimal percentage, String gauName, Id gauId, String message) {
        System.assertNotEquals(null, alloc, message + ' - Not Null');
        System.assertEquals(opportunityId, alloc.Opportunity__c, message + 'Opportunity' );
        System.assertEquals(paymentId, alloc.Payment__c, message + 'Payment');
        System.assertEquals(recurringDonationId, alloc.Recurring_Donation__c, message + 'Recurring Donation');
        System.assertEquals(campaignId, alloc.Campaign__c, message + 'Campaign');
        System.assertEquals(amount, alloc.Amount__c, message + ' - Amount');
        System.assertEquals(percentage, alloc.Percent__c, message + ' - Percent');
        if (gauName != null) {
            System.assertEquals(gauName, alloc.General_Accounting_Unit__r.Name, message + '- GAU (Name)');
        }
        if (gauId != null) {
            System.assertEquals(gauId, alloc.General_Accounting_Unit__c, message + '- GAU (Id)');
        }
    }

    private static void assertSObjectList(List<SObject> sObjs, Integer expectedCount, String message) {
        if (expectedCount == null) {
            System.assertEquals(null, sObjs, message + ' - List');
        } else {
            System.assertNotEquals(null, sObjs, message + ' - List');
            System.assertEquals(expectedCount, sObjs.size(), message + ' - List size');
        }
    }

    private static Map<Id, List<Allocation__c>> buildMapOfAllocationsByOpportunityId(List<Allocation__c> allocs) {
        Map<Id, List<Allocation__c>> allocsByOppId = new Map<Id, List<Allocation__c>>();

        for (Allocation__c alloc : allocs) {
            List<Allocation__c> allocs2 = allocsByOppId.containsKey(alloc.Opportunity__c) ? allocsByOppId.get(alloc.Opportunity__c) : new List<Allocation__c>();
            allocs2.add(alloc);
            allocsByOppId.put(alloc.Opportunity__c, allocs2);
        }

        return allocsByOppId;
    }

    private static Map<Id, List<Allocation__c>> buildMapOfAllocationsByPaymentId(List<Allocation__c> allocs) {
        Map<Id, List<Allocation__c>> allocsByPmtId = new Map<Id, List<Allocation__c>>();

        for (Allocation__c alloc : allocs) {
            List<Allocation__c> allocs2 = allocsByPmtId.containsKey(alloc.Payment__c) ? allocsByPmtId.get(alloc.Payment__c) : new List<Allocation__c>();
            allocs2.add(alloc);
            allocsByPmtId.put(alloc.Payment__c, allocs2);
        }

        return allocsByPmtId;
    }


        /*******************************************************************************************************
        * @description Inner class to facilitate applying different configuration/environmental options for
        *              Test execution
        ********************************************************************************************************/
        public class AllocationSetupTest {

        private List<General_Accounting_Unit__c> gaus = null;
        private General_Accounting_Unit__c defaultGAU = null;
        private Allocations_Settings__c allocationSettings = null;

        private Boolean defaultAllocations = false;
        private Boolean paymentAllocations = false;
        private Boolean disableAllocationTriggers = false;

        /*******************************************************************************************************
        * @description Default constructor for AllocationSetupTest class
        ********************************************************************************************************/
        public AllocationSetupTest() {

        }

        public AllocationSetupTest withAllocationSettings(Allocations_Settings__c allocationSettings) {
            this.allocationSettings = allocationSettings;
            return this;
        }

        /*******************************************************************************************************
        * @description Sets Disable Allocations Triggers Configuration to true
        * @return class instance
        ********************************************************************************************************/
        public AllocationSetupTest disableAllocationTriggers() {
            this.disableAllocationTriggers = true;
            return this;
        }

        /*******************************************************************************************************
        * @description Sets Payment Allocations Configuration and Default Allocations Configuration to true
        * @return class instance
        ********************************************************************************************************/
        public AllocationSetupTest enablePaymentAllocations() {
            this.paymentAllocations = true;
            this.defaultAllocations = true;
            return this;
        }

        /*******************************************************************************************************
        * @description Sets Default Allocations Configuration to true
        * @return class instance
        ********************************************************************************************************/
        public AllocationSetupTest enableDefaultAllocations() {
            this.defaultAllocations = true;
            return this;
        }

        /*******************************************************************************************************
        * @description Apply setup for test from configuration of member variables
        * @return class instance
        ********************************************************************************************************/
        public AllocationSetupTest applyConfiguration() {
            setupGAUs();

            if (this.allocationSettings == null) {
                this.allocationSettings = new Allocations_Settings__c();
            }

            this.allocationSettings.Payment_Allocations_Enabled__c = paymentAllocations;
            this.allocationSettings.Default_Allocations_Enabled__c = defaultAllocations;
            this.allocationSettings.Default__c = defaultAllocations ? defaultGAU.Id : null;

            setupSettings(allocationSettings);

            if (this.disableAllocationTriggers) {
                // Turn Off Allocation Triggers
                ALLO_AllocationsUtil.disableAllocationTriggers();
            }

            return this;
        }

        /*******************************************************************************************************
        * @description Setup of GAUs for testing
        ********************************************************************************************************/
        private void setupGAUs() {
            if (this.gaus == null) {
                this.gaus = UTIL_UnitTestData_TEST.createGAUs(3);
                this.gaus[0].Name = 'GAU 1';
                this.gaus[1].Name = 'GAU 2';
                if (this.defaultAllocations) {
                    this.gaus[2].Name = 'Default GAU';
                    this.defaultGAU = gaus[2];
                } else {
                    this.gaus[2].Name = 'GAU 3';
                }
                insert gaus;
            } else {
                if (this.defaultAllocations) {
                    this.gaus[2].Name = 'Default GAU';
                    this.defaultGAU = gaus[2];
                } else {
                    this.gaus[2].Name = 'GAU 3';
                    this.defaultGAU = null;
                }
                update gaus;
            }
        }

        /*******************************************************************************************************
        * @description Setup of allocations settings.
        * @param alloset An instance of Allocations_Settings__c custom setting. Calling this method with a null
        * parameter uses default settings.
        * @return void Modifies settings, returns nothing.
        ********************************************************************************************************/
        private void setupSettings (Allocations_Settings__c alloset) {
            //set running user to avoid dml issue
            System.runAs(new User(id = UserInfo.getUserId())){
                if (alloset!=null)
                    UTIL_CustomSettingsFacade.getAllocationsSettingsForTests(alloset);
                else
                    UTIL_CustomSettingsFacade.getAllocationsSettingsForTests(new Allocations_Settings__c());

            }
        }

        public List<General_Accounting_Unit__c> getGAUs() {
            return this.gaus;
        }

        public General_Accounting_Unit__c getDefaultGAU() {
            return this.defaultGAU;
        }
    }
}