/*
    Copyright (c) 2019, Salesforce.org
    All rights reserved.
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
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
    
    private static final String ALLO_VALIDATE_CONFIG_ACTION = 'ALLO.ValidatePmtAllocationConfig';
    private static final String ALLO_PROCESS_OPPS_PMTS_ACTION = 'ALLO.ProcessOppsAndPmts';

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
        ALLO_AllocationsUtil.RecordsForReview recsForRev = new ALLO_AllocationsUtil.RecordsForReview();

        List<Account> accs = UTIL_UnitTestData_TEST.createMultipleTestAccounts(1, null);
        insert accs;

        List<General_Accounting_Unit__c> gaus = UTIL_UnitTestData_TEST.createGAUs(3);
        gaus[2].Name = 'Default GAU';
        General_Accounting_Unit__c defaultGau = gaus[2];
        insert gaus;

        setupSettings(new Allocations_Settings__c(
            Payment_Allocations_Enabled__c = true,
            Default_Allocations_Enabled__c = true,
            Default__c = defaultGau.Id));

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

        ALLO_AllocationsUtil.RecordsForReview recsForRev = new ALLO_AllocationsUtil.RecordsForReview();

        List<Account> accs = UTIL_UnitTestData_TEST.createMultipleTestAccounts(1, null);
        insert accs;

        List<General_Accounting_Unit__c> gaus = UTIL_UnitTestData_TEST.createGAUs(3);
        gaus[2].Name = 'Default GAU';
        General_Accounting_Unit__c defaultGau = gaus[2];
        insert gaus;

        setupSettings(new Allocations_Settings__c(
            Payment_Allocations_Enabled__c = true,
            Default_Allocations_Enabled__c = true,
            Default__c = defaultGau.Id));

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

        // Turn Off Allocation Triggers
        ALLO_AllocationsUtil.disableAllocationTriggers();

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
        List<General_Accounting_Unit__c> gaus = UTIL_UnitTestData_TEST.createGAUs(3);
        gaus[2].Name = 'Default GAU';
        General_Accounting_Unit__c defaultGau = gaus[2];
        insert gaus;

        setupSettings(new Allocations_Settings__c(
            Payment_Allocations_Enabled__c = true,
            Default_Allocations_Enabled__c = true,
            Default__c = defaultGau.Id));


        List<Contact> ctcs = UTIL_UnitTestData_TEST.createMultipleTestContacts(3);
        insert ctcs;

        // Turn Off Allocation Triggers
        ALLO_AllocationsUtil.disableAllocationTriggers();

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
    // Confirm that Opportunities that are excluded for either RecordType or Type are not processed/included
    // Confirm that Opportunities Modified Since Boundary Date are flagged for review
    // Confirm that Opportunities are flagged for review if Boundary Date is null
    // Confirm that Opportunities with non null/zero Amount and no allocations are flagged for review [Only if Default Allocations Are Enabled]
    // Confirm that Opportunities Associated with Campaign or Recurring Donation with non null/zero Amount and no allocations are flagged for review (Present to cover circumstance when Default Allocations Are Not Enabled)
    // Confirm that Opportunities with Amount that does not match sum of Allocations are flagged for review [Only if Default Allocations Are Enabled]
    // Confirm that Opportunities with Allocations Modified Since Boundary are flagged for review
    // Confirm that Opportunities with non null/zero Amount and Allocations with null/0 amount are flagged for review
    // Confirm that Opportunities with null/0 Amount and Allocations with non null/0 amount are flagged for review
    // Confirm that Opportunities with Payments that match any of the following conditions are flagged for review [If Payment Allocations Enabled]
            // Any Payments with non null/zero Amount and no allocations [Only if Default Allocations Are Enabled]
            // Any Payments with Amount that does not match sum of Allocations [Only if Default Allocations Are Enabled]
            // Any Payments with Allocations Modified Since Boundary
            // Any Payments with non null/zero Amount and Allocations with null/0 amount
            // Any Payments with null/0 Amount and Allocations with non null/0 amount

    //TODO: Method: processOpportunityAllocations
    // Identify Opportunities with no allocations, and allocate from the Default (No Parent)
    // Identify Opportunities with no allocations, and allocate from Recurring Donations Allocations (Recurring Donation Parent)
    // Identify Opportunities with no allocations, and allocate from Campaign Allocations (Campaign Allocation Parent)
    // Identify Opportunites with existing allocations, resize if Opportunity Amount Changed (confirm Default Allocation recalculated)
    // Identify Opportunities with existing allocations, calculate/recalculate Amounts for Percentage Allocations with no invalid Amounts (confirm Default Allocation recalculated)

    // TODO: Method: processPaymentAllocations
    // Identify Payments with no allocations, and allocate from the Parent (confirm Default Allocation recalculated)
    // Identify Payments with existing allocations, and resize if Payment Amount Changed (Confirm Default Allocation recalculated)
    // Identify Payments with existing allocations, calculate/recalculate Amounts for Percentage Allocations with no invalid Amounts (confirm Default Allocations recalculated)

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
    // TODO: Method: retrieveOpportunities
    // Confirm retrieves Opportunity and Payment Data for the the Opportunity Ids specified

    // TODO: Method: retrieveAllocations
    // Confirm retrieves Allocation Data for the Opportunities, Payments, Recurring Donations, and Campaigns specified (via Ids)

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

        List<General_Accounting_Unit__c> gaus = UTIL_UnitTestData_TEST.createGAUs(3);
        gaus[2].Name = 'Default GAU';
        General_Accounting_Unit__c defaultGau = gaus[2];
        insert gaus;

        setupSettings(new Allocations_Settings__c(
            Payment_Allocations_Enabled__c = true,
            Default_Allocations_Enabled__c = true,
            Default__c = defaultGau.Id));

        List<Contact> ctcs = UTIL_UnitTestData_TEST.createMultipleTestContacts(2);
        insert ctcs;

        // Turn Off Allocation Triggers
        ALLO_AllocationsUtil.disableAllocationTriggers();

        List<Opportunity> opps = UTIL_UnitTestData_TEST.oppsForContactList(ctcs, null, UTIL_UnitTestDATA_TEST.getClosedWonStage(), System.today().addDays(30), 1000, null, null);
        insert opps;

        List<npe01__OppPayment__c> pmtsProcess = [select Id from npe01__OppPayment__c where npe01__Opportunity__c = :opps[0].Id];
        List<npe01__OppPayment__c> pmtsExclude = [select Id from npe01__OppPayment__c where npe01__Opportunity__c = :opps[1].Id];

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

        List<General_Accounting_Unit__c> gaus = UTIL_UnitTestData_TEST.createGAUs(3);
        gaus[2].Name = 'Default GAU';
        General_Accounting_Unit__c defaultGau = gaus[2];
        insert gaus;

        setupSettings(new Allocations_Settings__c(
            Payment_Allocations_Enabled__c = true,
            Default_Allocations_Enabled__c = true,
            Default__c = defaultGau.Id));

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


    /*******************************************************************************************************
    * @description Setup of allocations settings.
    * @param alloset An instance of Allocations_Settings__c custom setting. Calling this method with a null
    * parameter uses default settings.
    * @return void Modifies settings, returns nothing.
    ********************************************************************************************************/
    private static void setupSettings (Allocations_Settings__c alloset) {
        //set running user to avoid dml issue
        System.runAs(new User(id = UserInfo.getUserId())){
            if (alloset!=null)
                UTIL_CustomSettingsFacade.getAllocationsSettingsForTests(alloset);
            else
                UTIL_CustomSettingsFacade.getAllocationsSettingsForTests(new Allocations_Settings__c());

        }
    }


}