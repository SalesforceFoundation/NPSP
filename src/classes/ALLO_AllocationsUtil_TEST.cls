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

    // Number of Contacts and Opportunities to Create In the Main Create Test Data Method
    private static final Integer NUMBER_OF_CONTACTS_AND_OPPORTUNITIES = 14;

    /*******************************************************************************************************
     * RecordExclusions Inner Class Tests
     ********************************************************************************************************/

    /**
     * @description Test 1 - Add Exclusion (Add and Confirm Individal Exlusions
     *              [ALLO_AllocationsUtil.RecordExclusions.addExclusion]
     */
    @isTest
    private static void addIndividualRecordExclusions() {
/*        ALLO_AllocationsUTIL.RecordExclusions recExcl = new ALLO_AllocationsUTIL.RecordExclusions();

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
    */    }

    /**
     * @description Test 2 - Add Set of Exclusions) (Add Set of Exclusions and Confirm)
     *              [ALLO_AllocationsUtil.RecordExclusions.addExclusions]
     */
    @isTest
    private static void addSetOfRecordExclusions() {
/*        ALLO_AllocationsUtil.RecordExclusions recExcl = new ALLO_AllocationsUTIL.RecordExclusions();

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
    */    }

     /**
      * @description Test 3 - Verify Exclusion via "Has Exclusion"
      *              [ALLO_AllocationsUtil.RecordExclusions.hasExclusion]
      */
    @isTest
    private static void addExclusionsAndConfirmHasExclusions() {
/*        ALLO_AllocationsUtil.RecordExclusions recExcl = new ALLO_AllocationsUTIL.RecordExclusions();

        // Since we are not restricting to the Opportunity Id, we will just use the User Id as the Record Id as
        // is not a core part of this test
        recExcl.addExclusions (UserInfo.getUserId(), new Set<ALLO_AllocationsUtil.PROCESS_DEF> { ALLO_AllocationsUtil.PROCESS_DEF.OPP_AMT_UPD, ALLO_AllocationsUtil.PROCESS_DEF.OPP_ALLOC_UPD});
        System.assertEquals(true, recExcl.hasExclusion(UserInfo.getUserId(), ALLO_AllocationsUtil.PROCESS_DEF.OPP_AMT_UPD), 'Exclusion should be present for' + ALLO_AllocationsUtil.PROCESS_DEF.OPP_AMT_UPD);
        System.assertEquals(true, recExcl.hasExclusion(UserInfo.getUserId(), ALLO_AllocationsUtil.PROCESS_DEF.OPP_ALLOC_UPD), 'Exclusion should be present for' + ALLO_AllocationsUtil.PROCESS_DEF.OPP_ALLOC_UPD);
        System.assertEquals(false, recExcl.hasExclusion(UserInfo.getUserId(), ALLO_AllocationsUtil.PROCESS_DEF.ALL), 'Exclusion should not be present for' + ALLO_AllocationsUtil.PROCESS_DEF.ALL);
    */    }

    /**
     * @description Test 4 - Verify Has No Exclusions is true when no exclusions are present. call
     *               [ALLO_AllocationsUtil.RecordExclusions.hasNoExclusions]
     */
    @isTest
    private static void confirmHasNoExclusionsIsTrueWhenExclusionsAreNotPresentAndIsFalseWhenPresent() {
/*        ALLO_AllocationsUtil.RecordExclusions recExcl = new ALLO_AllocationsUTIL.RecordExclusions();

        // Since we are not restricting to the Opportunity Id, we will just use the User Id as the Record Id as
        // is not a core part of this test
        System.assertEquals(true, recExcl.hasNoExclusions(UserInfo.getUserId()), 'Should be no exclusions initially');

        recExcl.addExclusion(UserInfo.getUserId(), ALLO_AllocationsUtil.PROCESS_DEF.ALL);
        System.assertEquals(false, recExcl.hasNoExclusions(UserInfo.getUserId()), 'Should be exclusions present after adding on for current user');
        System.assertEquals(true, recExcl.hasNoExclusions(UserInfo.getOrganizationId()), 'Should be no exclusions for Organization Id');
    */    }

    /*******************************************************************************************************
     * AllocationResults Inner Class Tests
     ********************************************************************************************************/

     /**
      * @description Test 1 - Test Add an Error
      *              [ALLO_AllocationsUtil.AllocationResults.addError]
      */
    @isTest
    private static void addErrorsIndividuallyToTheAllocationsResultsAndConfirmResult() {
/*        ALLO_AllocationsUtil.AllocationResults allocResults = new ALLO_AllocationsUtil.AllocationResults();

        // Since we are not restricting to the Opportunity Id, we will just use the User Id as the Record Id as
        // is not a core part of this test
        allocResults.addError(UserInfo.getUserId(), 'Test Error');

        System.assertEquals (true, allocResults.errorsByRecordId.containsKey(UserInfo.getUserId()), 'Errors are present for ' + UserInfo.getUserId());
        System.assertEquals (1, allocResults.errorsByRecordId.get(UserInfo.getUserId()).size(), '1 Error is present for ' + UserInfo.getUserId());

        allocResults.addError(UserInfo.getUserId(), 'Test Error 2');
        System.assertEquals (2, allocResults.errorsByRecordId.get(UserInfo.getUserId()).size(), '2 Errors are present for ' + UserInfo.getUserId());

        System.assertEquals (false, allocResults.errorsByRecordId.containsKey(UserInfo.getOrganizationId()), 'No Errors are present for ' + UserInfo.getOrganizationId());
    */    }

    /**
     * @description Test 2 - Test Add Errors
     *              [ALLO_AllocationsUtil.AllocationResults.addAllErrors]
     */
    @isTest
    private static void addMultipleErrorsToTheAllocationsResultsAndConfirmResult() {
/*        ALLO_AllocationsUtil.AllocationResults allocResults = new ALLO_AllocationsUtil.AllocationResults();

        // Since we are not restricting to the Opportunity Id, we will just use the User Id as the Record Id as
        // is not a core part of this test
        allocResults.addAllErrors(UserInfo.getUserId(), new List<String> {'Test 1 Error', 'Test 2 Error'});

        System.assertEquals (true, allocResults.errorsByRecordId.containsKey(UserInfo.getUserId()), 'Errors are present for ' + UserInfo.getUserId());
        System.assertEquals (2, allocResults.errorsByRecordId.get(UserInfo.getUserId()).size(), '# of Errors present for ' + UserInfo.getUserId());

        allocResults.addAllErrors(UserInfo.getUserId(), new List<String> {'Test 3 Error', 'Test 4 Error'});
        System.assertEquals (4, allocResults.errorsByRecordId.get(UserInfo.getUserId()).size(), '4 Errors are present for ' + UserInfo.getUserId());

        System.assertEquals (false, allocResults.errorsByRecordId.containsKey(UserInfo.getOrganizationId()), 'No Errors are present for ' + UserInfo.getOrganizationId());
    */    }

    /*******************************************************************************************************
     * RecordsForReview Inner Class Tests
     ********************************************************************************************************/

    /**
     * @description Test 1 - Test adding different types of Allocations
     *               [ALLO_AllocationsUtil.RecordsForReview.addAllocationByType]
     */
    @isTest
    private static void addAllocationByTypeToRecordsForReviewAndConfirmAddedToCorrectList() {
/*        AllocationSetupTest alloSetupTest = new AllocationSetupTest()
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
    */    }

   /**
    * @Description Test 2 - Test method to identify Opportunities require Review
    *              [ALLO_AllocationsUtil.RecordsForReview.isOpportunityRequiresReview]
    */
    @isTest
    private static void confirmReturnsTrueWhenOpportunityRequiresReviewAndFalseOtherwise() {
/*        AllocationSetupTest alloSetupTest = new AllocationSetupTest()
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
    */    }

    /**
     * @description Test 3 - Test initialize Errors [ALLO_AllocationsUtil.RecordsForReview.initializeErrors]
     *              Should test both passing in an existing ERR_RecordErrors instance, and initializing from the Opportunities
     *              in the RecordsForReview variable oppsById
     */
    @isTest
    private static void initializeErrorsStructureSuccessfully() {
    /*    AllocationSetupTest alloSetupTest = new AllocationSetupTest()
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
    */}

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
    @isTest
    private static void excludeOpportunitiesForTypeAndRecordtype() {
    /*    AllocationSetupTest alloSetupTest = new AllocationSetupTest()
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
    */}

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
    @isTest
    private static void confirmOnlyOppsNeedingReviewAreFlaggedWhenDefaultAllocEnabled() {
    /*    AllocationSetupTest alloSetupTest = new AllocationSetupTest()
            .enableDefaultAllocations()
            .enablePaymentAllocations()
            .disableAllocationTriggers()
            .applyConfiguration();

        List<Id> oppIds = createTestDataAndReturnOppIds(alloSetupTest);

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

        // Find Earliest Payment for Opportunity 6
        npe01__OppPayment__c opp6pmt0 = null;
        for (npe01__OppPayment__c pmt: opp6.npe01__OppPayment__r) {
            if (pmt.npe01__Scheduled_Date__c == System.today()) {
                opp6pmt0 = pmt;
            }
        }

        // Confirm Opportunity with Payments with non null/zero Amount and no Allocations are flagged for review [Only if Default Allocations Are Enabled]
        System.assertEquals(true, ALLO_AllocationsUtil.isRequiresReview(opp6pmt0, recsForRev.paymentAllocations.get(opp6pmt0.Id), System.now().addDays(1)), 'Opportunity 6 - Payment 0, boundary date of tomorrow');
        // Confirm Opportunity with Payments with non null/zero Amount and valid Allocations are not flagged for review
        System.assertEquals(false, ALLO_AllocationsUtil.isRequiresReview(opp7.npe01__OppPayment__r[0], recsForRev.paymentAllocations.get(opp7.npe01__OppPayment__r[0].Id), System.now().addDays(1)), 'Opportunity 7 - Payment 0, boundary date of tomorrow');
    */}

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
    @isTest
    private static void confirmOnlyOppsNeedingReviewAreFlaggedWhenDefaultAllocNotEnabled() {
    /*    AllocationSetupTest alloSetupTest = new AllocationSetupTest()
            .disableAllocationTriggers()
            .applyConfiguration();

        List<Id> oppIds = createTestDataAndReturnOppIds(alloSetupTest);

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
    */}

    // [DEFERRED] isRequiresReview: Confirm that Opportunities with Allocations Modified Since Boundary are flagged for review
    // TODO: Determine viable approach...Difficult to make work with limitations of setting LastModified versus boundary date in tests distinct for Allocations versus Opportunity

    /**
     * @description Executes various Opportunity and Payment Allocation Scenarios when
     *              Payment and Default Allocations are enabled
     *              [ALLO_AllocationsUtil.processOpportunityAllocations]
     *
     */
    @isTest
    private static void confirmProcessRecordsUpdatesAllocationsCorrectlyWhenPaymentAllocationsAreEnabled() {
    /*    AllocationSetupTest alloSetupTest = new AllocationSetupTest()
        .enableDefaultAllocations()
        .enablePaymentAllocations()
        .disableAllocationTriggers()
        .applyConfiguration();

        List<General_Accounting_Unit__c> gaus = alloSetupTest.getGAUs();
        General_Accounting_Unit__c defaultGAU = alloSetupTest.getDefaultGAU();

        List<Id> oppIds = createTestDataAndReturnOppIds(alloSetupTest);

        Set<Id> oppIdsAsSet = new Set<Id>();
        oppIdsAsSet.addAll(oppIds);

        Map<Id, Opportunity> oppsById = ALLO_AllocationsUtil.retrieveOpportunities(oppIdsAsSet);
        Set<Id> campaignIds = new Set<Id>();
        Set<Id> recurringDonationIds = new Set<Id>();
        Set<Id> pmtIds = new Set<Id>();
        Id rdId = null;
        Id campaignId = null;

        for (Opportunity opp : oppsById.values()) {
            if (opp.CampaignId != null) {
                campaignIds.add(opp.CampaignId);
                campaignId = opp.CampaignId;
            }
            if (opp.npe03__Recurring_Donation__c != null) {
                recurringDonationIds.add(opp.npe03__Recurring_Donation__c);
                rdId = opp.npe03__Recurring_Donation__c;
            }
            for (npe01__OppPayment__c pmt : opp.npe01__OppPayment__r) {
                pmtIds.add(pmt.Id);
            }
        }

        List<Allocation__c> allAllocs = ALLO_AllocationsUtil.retrieveAllocations(oppIdsAsSet, pmtIds, campaignIds, recurringDonationIds);

        Map<Id, List<Allocation__c>> allocsByOppId = buildMapOfAllocationsByOpportunityId(allAllocs);
        Map<Id, List<Allocation__c>> allocsByPmtId = buildMapOfAllocationsByPaymentId(allAllocs);
        Map<Id, List<Allocation__c>> allocsByRDId = buildMapOfAllocationsByRecurringDonationId(allAllocs);
        Map<Id, List<Allocation__c>> allocsByCampaignId = buildMapOfAllocationsByCampaignId(allAllocs);

        String baseMessage = 'Before Processing';

        // Opportunity 0 - Has Recurring Donation Parent - Allocations Already Exist - No changes
        String message = baseMessage + ' - Opportunity 0';
        List<Allocation__c> allocs = allocsByOppId.get(oppIds[0]);
        assertSObjectList(allocs, 2, message);
        assertOpportunityAllocation(findByGAU(allocs, gaus[0]), oppIds[0], 10, 50, gaus[0].Id, message + ' - Allocation 0');
        assertOpportunityAllocation(findByGAU(allocs, gaus[1]), oppIds[0], 10, null, gaus[1].Id, message + ' - Allocation 1');

        // Opportunity 1 - Has Recurring Donation Parent - Allocations Do Not Exist
         message = baseMessage + ' - Opportunity 1';
        assertSObjectList(allocsByOppId.get(oppIds[1]), null, message);

        // Opportunity 2 - No Parent - No Allocations - Allocate from Default
        message = baseMessage + ' - Opportunity 2';
        assertSObjectList(allocsByOppId.get(oppIds[2]), null, message);

        // Opportunity 3 -- Sum of Allocations Amount < Opportunity Amount
        message = baseMessage + ' - Opportunity 3';
        allocs = allocsByOppId.get(oppIds[3]);
        assertSObjectList(allocs, 1, message);
        assertOpportunityAllocation(findByGAU(allocs, gaus[1]), oppIds[3], 10, null, gaus[1].Id, message + ' - Allocation 0');

        // Opportunity 4 -- Allocation with Percent and No Amount
        message = baseMessage + ' - Opportunity 4';
        allocs = allocsByOppId.get(oppIds[4]);
        assertSObjectList(allocs, 1, message);
        assertOpportunityAllocation(findByGAU(allocs, gaus[1]), oppIds[4], null, 100, gaus[1].Id, message + ' - Allocation 0');

        // Opportunity 5 - Opportunity Amount = $0, With Non Zero Percent Allocations
        message = baseMessage + ' - Opportunity 5';
        allocs = allocsByOppId.get(oppIds[5]);
        assertSObjectList(allocs, 1, message);
        assertOpportunityAllocation(findByGAU(allocs, gaus[1]), oppIds[5], 20, 50, gaus[1].Id, message + ' - Allocation 0');

        // Opportunity 6 - Opportunity Allocation - Has Related Payment Allocations
        message = baseMessage + ' - Opportunity 6';
        allocs = allocsByOppId.get(oppIds[6]);
        assertSObjectList(allocs, 1, message);
        assertOpportunityAllocation(findByGAU(allocs, gaus[1]), oppIds[6], 20, 100, gaus[1].Id, message + ' - Allocation 0');

        // Opportunity 7 - Opportunity Allocated - Has Related Payment Allocations
        message = baseMessage + ' - Opportunity 7';
        allocs = allocsByOppId.get(oppIds[7]);
        assertSObjectList(allocs, 1, message);
        assertOpportunityAllocation(findByGAU(allocs, gaus[1]), oppIds[7], 20, 100, gaus[1].Id, message + ' - Allocation 0');

        // Opportunity 8 - Opportunity Amount = (null), Existing Default Allocation
        message = baseMessage + ' - Opportunity 8';
        allocs = allocsByOppId.get(oppIds[8]);
        assertSObjectList(allocs, 1, message);
        assertOpportunityAllocation(findByGAU(allocs, defaultGAU), oppIds[8], 20, null, defaultGAU.Id, message + ' - Allocation 0');

        // Opportunity 9 - Has Associated Campaign - Allocations Do Not Exist
        message = baseMessage + ' - Opportunity 9';
        assertSObjectList(allocsByOppId.get(oppIds[9]), null, message);

        // Opportunity 10 - Existing Allocations, Resize for Opportunity Amount
        message = baseMessage + ' - Opportunity 10';
        allocs = allocsByOppId.get(oppIds[10]);
        assertSObjectList(allocs, 2, message);
        assertOpportunityAllocation(findByGAU(allocs, gaus[1]), oppIds[10], 40, 50, gaus[1].Id, message + ' - Allocation 0');
        assertOpportunityAllocation(findByGAU(allocs, defaultGAU), oppIds[10], 40, null, defaultGAU.Id, message + ' - Allocation 1');

        // Opportunity 11 -  Invalid existing fixed allocation that is too large for the Opportunity Amount
        message = baseMessage + ' - Opportunity 11';
        allocs = allocsByOppId.get(oppIds[11]);
        assertSObjectList(allocs, 1, message);
        assertOpportunityAllocation(findByGAU(allocs, gaus[1]), oppIds[11], 40, null, gaus[1].Id, message + ' - Allocation 0');

        // Recurring Donation - Allocations
        message = baseMessage + ' - Recurring Donation';
        System.assertEquals(1, recurringDonationIds.size(), message + ' - 1 Recurring Donation Present');
        List<Allocation__c> rdAllocs = allocsByRDId.get(rdId);
        assertSObjectList(rdAllocs, 2, message);
        assertRecurringDonationAllocation(findByGAU(rdAllocs, gaus[0]), rdId, null, 50, gaus[0].Id, message + ' - Allocation 0');
        assertRecurringDonationAllocation(findByGAU(rdAllocs, gaus[1]), rdId, 10, null, gaus[1].Id, message + ' - Allocation 1');

        // Campaign - Allocations
        message = baseMessage + ' - Campaign';
        System.assertEquals(1, campaignIds.size(), message + ' - 1 Campaign(s) Present');
        List<Allocation__c> campAllocs = allocsByCampaignId.get(campaignId);
        assertSObjectList(campAllocs, 1, message);
        assertCampaignAllocation(findByGAU(campAllocs, gaus[1]), campaignId, 10, null, gaus[1].Id, message + ' - Allocation 0');

        if (alloSetupTest.isPaymentAllocationsEnabled()) {
            assertPaymentAllocationsBeforeProcessing(allocsByPmtId, oppIds, gaus, defaultGAU);
        }

        Test.startTest();
        // Process Allocations for Opportunities
        Set<Id> successfullyProcessedOppIds = ALLO_AllocationsUtil.processRecords('TEST', oppIdsAsSet, null, null, true, true);
        Test.stopTest();

        // Two Opportunities are expected to be dropped with errors
        System.assertEquals (oppIdsAsSet.size() - 2, successfullyProcessedOppIds.size(), 'Expected number of records to be successfully processed');

        List<Allocation__c> allocsAfterProcessing = ALLO_AllocationsUtil.retrieveAllocations(oppIdsAsSet, pmtIds, campaignIds, recurringDonationIds);

        allocsByOppId = buildMapOfAllocationsByOpportunityId(allocsAfterProcessing);
        allocsByPmtId = buildMapOfAllocationsByPaymentId(allocsAfterProcessing);
        allocsByRDId = buildMapOfAllocationsByRecurringDonationId(allocsAfterProcessing);
        allocsByCampaignId = buildMapOfAllocationsByCampaignId(allocsAfterProcessing);
        Map<Id, Error__c> errorsByOppId = getErrorsByRecordId();

        baseMessage = 'After Processing';

        // Opportunity 0 - Has Recurring Donation Parent - Allocations Already Exist - No changes
        message = baseMessage + ' - Opportunity 0';
        allocs = allocsByOppId.get(oppIds[0]);
        assertSObjectList(allocs, 2, message);
        assertOpportunityAllocation(findByGAU(allocs, gaus[0]), oppIds[0], 10, 50, gaus[0].Id, message + ' - Allocation 0');
        assertOpportunityAllocation(findByGAU(allocs, gaus[1]), oppIds[0], 10, null, gaus[1].Id, message + ' - Allocation 1');

        // Opportunity 1 - Has Recurring Donation Parent - Allocations Do Not Exist - Allocate from Recurring Donation Parent
        message = baseMessage + ' - Opportunity 1';
        allocs = allocsByOppId.get(oppIds[1]);
        assertSObjectList(allocs, 2, message);
        assertOpportunityAllocation(findByGAU(allocs, gaus[0]), oppIds[1], 10, 50, gaus[0].Id, message + ' - Allocation 0');
        assertOpportunityAllocation(findByGAU(allocs, gaus[1]), oppIds[1], 10, null, gaus[1].Id, message + ' - Allocation 1');

        // Opportunity 2 - No Parent - No Allocations - Allocate from Default
        message = baseMessage + ' - Opportunity 2';
        allocs = allocsByOppId.get(oppIds[2]);
        assertSObjectList(allocs, 1, message);
        assertOpportunityAllocation(findByGAU(allocs, defaultGAU), oppIds[2], 20, null, defaultGAU.Id, message + ' - Allocation 0');

        // Opportunity 3 - Sum of Allocation Amount < Opportunity Amount - Add Default for Remainder
        message = baseMessage + ' - Opportunity 3';
        allocs = allocsByOppId.get(oppIds[3]);
        assertSObjectList(allocs, 2, message);
        assertOpportunityAllocation(findByGAU(allocs, gaus[1]), oppIds[3], 10, null, gaus[1].Id, message + ' - Allocation 0');
        assertOpportunityAllocation(findByGAU(allocs, defaultGAU), oppIds[3], 10, null, defaultGAU.Id, message + ' - Allocation 1');

        // Opportunity 4 - Allocation with Percent but no Amount present
        message = baseMessage + ' - Opportunity 4';
        allocs = allocsByOppId.get(oppIds[4]);
        assertSObjectList(allocs, 1, message);
        assertOpportunityAllocation(findByGAU(allocs, gaus[1]), oppIds[4], 20, 100, gaus[1].Id, message + ' - Allocation 0');

        // Opportunity 5 - Opportunity with Amount 9 and non zero percent Allocations
        message = baseMessage + ' - Opportunity 5';
        allocs = allocsByOppId.get(oppIds[5]);
        assertSObjectList(allocs, 1, message);
        assertOpportunityAllocation(findByGAU(allocs, gaus[1]), oppIds[5], 0, 50, gaus[1].Id, message + ' - Allocation 0');

        // Opportunity 6 - Opportunity Allocated Fully
        message = baseMessage + ' - Opportunity 6';
        allocs = allocsByOppId.get(oppIds[6]);
        assertSObjectList(allocs, 1, message);
        assertOpportunityAllocation(findByGAU(allocs, gaus[1]), oppIds[6], 20, 100, gaus[1].Id, message + ' - Allocation 0');
        System.assertEquals(true, errorsByOppId.containsKey(oppIds[6]), message + ' - Error Record Present');

        // Opportunity 7 Allocation(s) - Opportunity Allocated Fully
        message = baseMessage + ' - Opportunity 7';
        allocs = allocsByOppId.get(oppIds[7]);
        assertSObjectList(allocs, 1, message);
        assertOpportunityAllocation(findByGAU(allocs, gaus[1]), oppIds[7], 20, 100, gaus[1].Id, message + ' - Allocation 0');

        // Opportunity 8 Allocation(s) - Opportunity with null Amount
        message = baseMessage + ' - Opportunity 8';
        allocs = allocsByOppId.get(oppIds[8]);
        assertSObjectList(allocs, null, message);

        // Opportunity 9 - No allocations.  Parent Campaign
        message = baseMessage + ' - Opportunity 9';
        allocs = allocsByOppId.get(oppIds[9]);
        assertSObjectList(allocs, 2, message);
        assertOpportunityAllocation(findByGAU(allocs, gaus[1]), oppIds[9], 10, null, gaus[1].Id, message + ' - Allocation 0');
        assertOpportunityAllocation(findByGAU(allocs, defaultGAU), oppIds[9], 10, null, defaultGAU.Id, message + ' - Allocation 1');

        // Opportunity 10 - Existing allocations.  Resize for Opportunity Amount Difference
        message = baseMessage + ' - Opportunity 10';
        allocs = allocsByOppId.get(oppIds[10]);
        assertSObjectList(allocs, 2, message);
        assertOpportunityAllocation(findByGAU(allocs, gaus[1]), oppIds[10], 10, 50, gaus[1].Id, message + ' - Allocation 0');
        assertOpportunityAllocation(findByGAU(allocs, defaultGAU), oppIds[10], 10, null, defaultGAU.Id, message + ' - Allocation 1');

        // Opportunity 11 - Invalid existing fixed allocation that is too large for the Opportunity Amount
        message = baseMessage + ' - Opportunity 11';
        allocs = allocsByOppId.get(oppIds[11]);
        assertSObjectList(allocs, 1, message);
        assertOpportunityAllocation(findByGAU(allocs, gaus[1]), oppIds[11], 40, null, gaus[1].Id, message + ' - Allocation 0');
        System.assertEquals(true, errorsByOppId.containsKey(oppIds[11]), message + ' - Error Record Present');

        // Recurring Donation - Allocations
        message = baseMessage + ' - Recurring Donation';
        System.assertEquals(1, recurringDonationIds.size(), message + ' - 1 Recurring Donation Present');
        rdAllocs = allocsByRDId.get(rdId);
        assertSObjectList(rdAllocs, 2, message);
        assertRecurringDonationAllocation(findByGAU(rdAllocs, gaus[0]), rdId, null, 50, gaus[0].Id, message + ' - Allocation 0');
        assertRecurringDonationAllocation(findByGAU(rdAllocs, gaus[1]), rdId, 10, null, gaus[1].Id, message + ' - Allocation 1');

        // Campaign - Allocations
        message = baseMessage + ' - Campaign';
        System.assertEquals(1, campaignIds.size(), message + ' - 1 Campaign(s) Present');
        campAllocs = allocsByCampaignId.get(campaignId);
        assertSObjectList(campAllocs, 1, message);
        assertCampaignAllocation(findByGAU(campAllocs, gaus[1]), campaignId, 10, null, gaus[1].Id, message + ' - Allocation 0');

        if (alloSetupTest.isPaymentAllocationsEnabled()) {
            assertPaymentAllocationsAfterProcessing(allocsByPmtId, oppIds, gaus, defaultGAU);
        }
    */}

    /**
     * @description Executes various Opportunity and Payment Allocation Scenarios when
     *              Payment and Default Allocations are not
     *              [ALLO_AllocationsUtil.processOpportunityAllocations]
     */
    @isTest
    private static void confirmProcessRecordsUpdatesAllocationsCorrectlyWhenDefaultAllocationsAreNotEnabled() {
    /*    AllocationSetupTest alloSetupTest = new AllocationSetupTest()
        .disableAllocationTriggers()
        .applyConfiguration();

        List<General_Accounting_Unit__c> gaus = alloSetupTest.getGAUs();
        General_Accounting_Unit__c defaultGAU = alloSetupTest.getDefaultGAU();

        List<Id> oppIds = createTestDataAndReturnOppIds(alloSetupTest);

        Set<Id> oppIdsAsSet = new Set<Id>();
        oppIdsAsSet.addAll(oppIds);

        Map<Id, Opportunity> oppsById = ALLO_AllocationsUtil.retrieveOpportunities(oppIdsAsSet);
        Set<Id> campaignIds = new Set<Id>();
        Set<Id> recurringDonationIds = new Set<Id>();
        Set<Id> pmtIds = new Set<Id>();
        Id rdId = null;
        Id campaignId = null;

        for (Opportunity opp : oppsById.values()) {
            if (opp.CampaignId != null) {
                campaignIds.add(opp.CampaignId);
                campaignId = opp.CampaignId;
            }
            if (opp.npe03__Recurring_Donation__c != null) {
                recurringDonationIds.add(opp.npe03__Recurring_Donation__c);
                rdId = opp.npe03__Recurring_Donation__c;
            }
            for (npe01__OppPayment__c pmt : opp.npe01__OppPayment__r) {
                pmtIds.add(pmt.Id);
            }
        }

        List<Allocation__c> allAllocs = ALLO_AllocationsUtil.retrieveAllocations(oppIdsAsSet, pmtIds, campaignIds, recurringDonationIds);

        Map<Id, List<Allocation__c>> allocsByOppId = buildMapOfAllocationsByOpportunityId(allAllocs);
        Map<Id, List<Allocation__c>> allocsByPmtId = buildMapOfAllocationsByPaymentId(allAllocs);
        Map<Id, List<Allocation__c>> allocsByRDId = buildMapOfAllocationsByRecurringDonationId(allAllocs);
        Map<Id, List<Allocation__c>> allocsByCampaignId = buildMapOfAllocationsByCampaignId(allAllocs);

        String baseMessage = 'Before Processing';

        // Opportunity 0 - Has Recurring Donation Parent - Allocations Already Exist - No changes
        String message = baseMessage + ' - Opportunity 0';
        List<Allocation__c> allocs = allocsByOppId.get(oppIds[0]);
        assertSObjectList(allocs, 2, message);
        assertOpportunityAllocation(findByGAU(allocs, gaus[0]), oppIds[0], 10, 50, gaus[0].Id, message + ' - Allocation 0');
        assertOpportunityAllocation(findByGAU(allocs, gaus[1]), oppIds[0], 10, null, gaus[1].Id, message + ' - Allocation 1');

        // Opportunity 1 - Has Recurring Donation Parent - Allocations Do Not Exist
         message = baseMessage + ' - Opportunity 1';
        assertSObjectList(allocsByOppId.get(oppIds[1]), null, message);

        // Opportunity 2 - No Parent - No Allocations - Allocate from Default
        message = baseMessage + ' - Opportunity 2';
        assertSObjectList(allocsByOppId.get(oppIds[2]), null, message);

        // Opportunity 3 -- Sum of Allocations Amount < Opportunity Amount
        message = baseMessage + ' - Opportunity 3';
        allocs = allocsByOppId.get(oppIds[3]);
        assertSObjectList(allocs, 1, message);
        assertOpportunityAllocation(findByGAU(allocs, gaus[1]), oppIds[3], 10, null, gaus[1].Id, message + ' - Allocation 0');

        // Opportunity 4 -- Allocation with Percent and No Amount
        message = baseMessage + ' - Opportunity 4';
        allocs = allocsByOppId.get(oppIds[4]);
        assertSObjectList(allocs, 1, message);
        assertOpportunityAllocation(findByGAU(allocs, gaus[1]), oppIds[4], null, 100, gaus[1].Id, message + ' - Allocation 0');

        // Opportunity 5 - Opportunity Amount = $0, With Non Zero Percent Allocations
        message = baseMessage + ' - Opportunity 5';
        allocs = allocsByOppId.get(oppIds[5]);
        assertSObjectList(allocs, 1, message);
        assertOpportunityAllocation(findByGAU(allocs, gaus[1]), oppIds[5], 20, 50, gaus[1].Id, message + ' - Allocation 0');

        // Opportunity 6 - Opportunity Allocation - Has Related Payment Allocations
        message = baseMessage + ' - Opportunity 6';
        allocs = allocsByOppId.get(oppIds[6]);
        assertSObjectList(allocs, 1, message);
        assertOpportunityAllocation(findByGAU(allocs, gaus[1]), oppIds[6], 20, 100, gaus[1].Id, message + ' - Allocation 0');

        // Opportunity 7 - Opportunity Allocated - Has Related Payment Allocations
        message = baseMessage + ' - Opportunity 7';
        allocs = allocsByOppId.get(oppIds[7]);
        assertSObjectList(allocs, 1, message);
        assertOpportunityAllocation(findByGAU(allocs, gaus[1]), oppIds[7], 20, 100, gaus[1].Id, message + ' - Allocation 0');

        // Opportunity 8 - Opportunity Amount = (null), Existing Default Allocation
        message = baseMessage + ' - Opportunity 8';
        allocs = allocsByOppId.get(oppIds[8]);
        assertSObjectList(allocs, 1, message);
        assertOpportunityAllocation(findByGAU(allocs, gaus[2]), oppIds[8], 20, 100, gaus[2].Id, message + ' - Allocation 0');

        // Opportunity 9 - Has Associated Campaign - Allocations Do Not Exist
        message = baseMessage + ' - Opportunity 9';
        assertSObjectList(allocsByOppId.get(oppIds[9]), null, message);

        // Opportunity 10 - Existing Allocations, Resize for Opportunity Amount
        message = baseMessage + ' - Opportunity 10';
        allocs = allocsByOppId.get(oppIds[10]);
        assertSObjectList(allocs, 1, message);
        assertOpportunityAllocation(findByGAU(allocs, gaus[1]), oppIds[10], 40, 50, gaus[1].Id, message + ' - Allocation 0');

        // Opportunity 11 -  Invalid existing fixed allocation that is too large for the Opportunity Amount
        message = baseMessage + ' - Opportunity 11';
        allocs = allocsByOppId.get(oppIds[11]);
        assertSObjectList(allocs, 1, message);
        assertOpportunityAllocation(findByGAU(allocs, gaus[1]), oppIds[11], 40, null, gaus[1].Id, message + ' - Allocation 0');

        // Recurring Donation - Allocations
        message = baseMessage + ' - Recurring Donation';
        System.assertEquals(1, recurringDonationIds.size(), message + ' - 1 Recurring Donation Present');
        List<Allocation__c> rdAllocs = allocsByRDId.get(rdId);
        assertSObjectList(rdAllocs, 2, message);
        assertRecurringDonationAllocation(findByGAU(rdAllocs, gaus[0]), rdId, null, 50, gaus[0].Id, message + ' - Allocation 0');
        assertRecurringDonationAllocation(findByGAU(rdAllocs, gaus[1]), rdId, 10, null, gaus[1].Id, message + ' - Allocation 1');

        // Campaign - Allocations
        message = baseMessage + ' - Campaign';
        System.assertEquals(1, campaignIds.size(), message + ' - 1 Campaign(s) Present');
        List<Allocation__c> campAllocs = allocsByCampaignId.get(campaignId);
        assertSObjectList(campAllocs, 1, message);
        assertCampaignAllocation(findByGAU(campAllocs, gaus[1]), campaignId, 10, null, gaus[1].Id, message + ' - Allocation 0');

        Test.startTest();
        // Process Allocations for Opportunities
        Set<Id> successfullyProcessedOppIds = ALLO_AllocationsUtil.processRecords('TEST', oppIdsAsSet, null, null, true, true);
        Test.stopTest();

        // One Opportunities are expected to be dropped with errors
        System.assertEquals (oppIdsAsSet.size() - 1, successfullyProcessedOppIds.size(), 'Expected number of records to be successfully processed');

        List<Allocation__c> allocsAfterProcessing = ALLO_AllocationsUtil.retrieveAllocations(oppIdsAsSet, pmtIds, campaignIds, recurringDonationIds);

        allocsByOppId = buildMapOfAllocationsByOpportunityId(allocsAfterProcessing);
        allocsByPmtId = buildMapOfAllocationsByPaymentId(allocsAfterProcessing);
        allocsByRDId = buildMapOfAllocationsByRecurringDonationId(allocsAfterProcessing);
        allocsByCampaignId = buildMapOfAllocationsByCampaignId(allocsAfterProcessing);
        Map<Id, Error__c> errorsByOppId = getErrorsByRecordId();

        baseMessage = 'After Processing';

        // Opportunity 0 - Has Recurring Donation Parent - Allocations Already Exist - No changes
        message = baseMessage + ' - Opportunity 0';
        allocs = allocsByOppId.get(oppIds[0]);
        assertSObjectList(allocs, 2, message);
        assertOpportunityAllocation(findByGAU(allocs, gaus[0]), oppIds[0], 10, 50, gaus[0].Id, message + ' - Allocation 0');
        assertOpportunityAllocation(findByGAU(allocs, gaus[1]), oppIds[0], 10, null, gaus[1].Id, message + ' - Allocation 1');

        // Opportunity 1 - Has Recurring Donation Parent - Allocations Do Not Exist - Allocate from Recurring Donation Parent
        message = baseMessage + ' - Opportunity 1';
        allocs = allocsByOppId.get(oppIds[1]);
        assertSObjectList(allocs, 2, message);
        assertOpportunityAllocation(findByGAU(allocs, gaus[0]), oppIds[1], 10, 50, gaus[0].Id, message + ' - Allocation 0');
        assertOpportunityAllocation(findByGAU(allocs, gaus[1]), oppIds[1], 10, null, gaus[1].Id, message + ' - Allocation 1');

        // Opportunity 2 - No Parent - No Allocations
        message = baseMessage + ' - Opportunity 2';
        allocs = allocsByOppId.get(oppIds[2]);
        assertSObjectList(allocs, null, message);

        // Opportunity 3 - Sum of Allocation Amount < Opportunity Amount
        message = baseMessage + ' - Opportunity 3';
        allocs = allocsByOppId.get(oppIds[3]);
        assertSObjectList(allocs, 1, message);
        assertOpportunityAllocation(findByGAU(allocs, gaus[1]), oppIds[3], 10, null, gaus[1].Id, message + ' - Allocation 0');

        // Opportunity 4 - Allocation with Percent but no Amount present
        message = baseMessage + ' - Opportunity 4';
        allocs = allocsByOppId.get(oppIds[4]);
        assertSObjectList(allocs, 1, message);
        assertOpportunityAllocation(findByGAU(allocs, gaus[1]), oppIds[4], 20, 100, gaus[1].Id, message + ' - Allocation 0');

        // Opportunity 5 - Opportunity with Amount 9 and non zero percent Allocations
        message = baseMessage + ' - Opportunity 5';
        allocs = allocsByOppId.get(oppIds[5]);
        assertSObjectList(allocs, 1, message);
        assertOpportunityAllocation(findByGAU(allocs, gaus[1]), oppIds[5], 0, 50, gaus[1].Id, message + ' - Allocation 0');

        // Opportunity 6 - Opportunity Allocated Fully
        message = baseMessage + ' - Opportunity 6';
        allocs = allocsByOppId.get(oppIds[6]);
        assertSObjectList(allocs, 1, message);
        assertOpportunityAllocation(findByGAU(allocs, gaus[1]), oppIds[6], 20, 100, gaus[1].Id, message + ' - Allocation 0');

        // Opportunity 7 Allocation(s) - Opportunity Allocated Fully
        message = baseMessage + ' - Opportunity 7';
        allocs = allocsByOppId.get(oppIds[7]);
        assertSObjectList(allocs, 1, message);
        assertOpportunityAllocation(findByGAU(allocs, gaus[1]), oppIds[7], 20, 100, gaus[1].Id, message + ' - Allocation 0');

        // Opportunity 8 Allocation(s) - Opportunity with null Amount
        message = baseMessage + ' - Opportunity 8';
        allocs = allocsByOppId.get(oppIds[8]);
        assertSObjectList(allocs, null, message);

        // Opportunity 9 - No allocations.  Parent Campaign
        message = baseMessage + ' - Opportunity 9';
        allocs = allocsByOppId.get(oppIds[9]);
        assertSObjectList(allocs, 1, message);
        assertOpportunityAllocation(findByGAU(allocs, gaus[1]), oppIds[9], 10, null, gaus[1].Id, message + ' - Allocation 0');

        // Opportunity 10 - Existing allocations.  Resize for Opportunity Amount Difference
        message = baseMessage + ' - Opportunity 10';
        allocs = allocsByOppId.get(oppIds[10]);
        assertSObjectList(allocs, 1, message);
        assertOpportunityAllocation(findByGAU(allocs, gaus[1]), oppIds[10], 10, 50, gaus[1].Id, message + ' - Allocation 0');

        // Opportunity 11 - Invalid existing fixed allocation that is too large for the Opportunity Amount
        message = baseMessage + ' - Opportunity 11';
        allocs = allocsByOppId.get(oppIds[11]);
        assertSObjectList(allocs, 1, message);
        assertOpportunityAllocation(findByGAU(allocs, gaus[1]), oppIds[11], 40, null, gaus[1].Id, message + ' - Allocation 0');
        System.assertEquals(true, errorsByOppId.containsKey(oppIds[11]), message + ' - Error Record Present');

        // Recurring Donation - Allocations
        message = baseMessage + ' - Recurring Donation';
        System.assertEquals(1, recurringDonationIds.size(), message + ' - 1 Recurring Donation Present');
        rdAllocs = allocsByRDId.get(rdId);
        assertSObjectList(rdAllocs, 2, message);
        assertRecurringDonationAllocation(findByGAU(rdAllocs, gaus[0]), rdId, null, 50, gaus[0].Id, message + ' - Allocation 0');
        assertRecurringDonationAllocation(findByGAU(rdAllocs, gaus[1]), rdId, 10, null, gaus[1].Id, message + ' - Allocation 1');

        // Campaign - Allocations
        message = baseMessage + ' - Campaign';
        System.assertEquals(1, campaignIds.size(), message + ' - 1 Campaign(s) Present');
        campAllocs = allocsByCampaignId.get(campaignId);
        assertSObjectList(campAllocs, 1, message);
        assertCampaignAllocation(findByGAU(campAllocs, gaus[1]), campaignId, 10, null, gaus[1].Id, message + ' - Allocation 0');
    */}

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
    /*    Map<Id, Opportunity> oppsById = new Map<Id, Opportunity>([SELECT    Id,
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

        // Opportunity 6 - Payment 0 - No Allocations Yes
        allocs = allocsByPmtId.get(pmts[0].Id);
        message = baseMessage + 'Payment 0';
        assertSObjectList(allocs, null, message);

        // Opportunity 6 - Payment 1 - Payment Allocations, Default Allocation for $10 (Default), Percent Allocation for 50% (GAU0), Fixed for $1 (GAU1)
        message = baseMessage + 'Payment 1';
        allocs = allocsByPmtId.get(pmts[1].Id);
        assertSObjectList(allocs, 3, message);
        assertPaymentAllocation(findByGAU(allocs, defaultGAU), pmts[1].Id, 10, null, defaultGAU.Id, message + ' - Allocation 0');
        assertPaymentAllocation(findByGAU(allocs, gaus[0]), pmts[1].Id, null, 50, gaus[0].Id, message + ' - Allocation 1');
        assertPaymentAllocation(findByGAU(allocs, gaus[1]), pmts[1].Id, 1, null, gaus[1].Id, message + ' - Allocation 2');

        // Opportunity 6 - Payment 2 - Payment Allocations, Fixed Amount Allocation for $1, GAU0
        message = baseMessage + 'Payment 2';
        allocs = allocsByPmtId.get(pmts[2].Id);
        assertSObjectList(allocs, 1, message);
        assertPaymentAllocation(findByGAU(allocs, gaus[0]), pmts[2].Id, 1, null, gaus[0].Id, message + ' - Allocation 0');

        // Opportunity 6 - Payment 3 - Payment Allocations, 100% Allocation for GAU0, Default Allocation for $10
        message = baseMessage + 'Payment 3';
        allocs = allocsByPmtId.get(pmts[3].Id);
        assertSObjectList(allocs, 2, message);
        assertPaymentAllocation(findByGAU(allocs, gaus[0]), pmts[3].Id, 10, 100, gaus[0].Id, message + ' - Allocation 0');
        assertPaymentAllocation(findByGAU(allocs, defaultGAU), pmts[3].Id, 10, null, defaultGAU.Id, message + ' - Allocation 1');

        // Opportunity 6 - Payment 4 - Payment Allocations, Default Allocation for $10
        message = baseMessage + 'Payment 4';
        allocs = allocsByPmtId.get(pmts[4].Id);
        assertSObjectList(allocs, 1, message);
        assertPaymentAllocation(findByGAU(allocs, defaultGAU), pmts[4].Id, 10, null, defaultGAU.Id, message + ' - Allocation 0');

        // Opportunity 6 - Payment 5 - Payment Allocations, Default Allocation for $10
        message = baseMessage + 'Payment 5';
        allocs = allocsByPmtId.get(pmts[5].Id);
        assertSObjectList(allocs, 1, message);
        assertPaymentAllocation(findByGAU(allocs, defaultGAU), pmts[5].Id, 10, null, defaultGAU.Id, message + ' - Allocation 0');

        // Opportunity 6 - Payment 6, Amount $0 - Payment Allocations, 10% Allocation for GAU 0
        message = baseMessage + 'Payment 6';
        allocs = allocsByPmtId.get(pmts[6].Id);
        assertSObjectList(allocs, 1, message);
        assertPaymentAllocation(findByGAU(allocs, gaus[0]), pmts[6].Id, 1, 10, gaus[0].Id, message + ' - Allocation 0');

        // Opportunity 6 - Payment 7, Amount (null) - Payment Allocations, 10% Allocation for GAU 0
        message = baseMessage + 'Payment 7';
        allocs = allocsByPmtId.get(pmts[7].Id);
        assertSObjectList(allocs, 1, message);
        assertPaymentAllocation(findByGAU(allocs, gaus[0]), pmts[7].Id, 1, 10, gaus[0].Id, message + ' - Allocation 0');

        // Opportunity 6 - Payment 8, Amoount $0 - Payment Allocations, 10% Allocation for GAU 0, $10 for Default GAU
        message = baseMessage + 'Payment 8';
        allocs = allocsByPmtId.get(pmts[8].Id);
        assertSObjectList(allocs, 2, message);
        assertPaymentAllocation(findByGAU(allocs, gaus[0]), pmts[8].Id, 1, 10, gaus[0].Id, message + ' - Allocation 0');
        assertPaymentAllocation(findByGAU(allocs, defaultGAU), pmts[8].Id, 10, null, defaultGAU.Id, message + ' - Allocation 1');

        // Opportunity 6 - Payment 9, Amoount (null) - Payment Allocations, 10% Allocation for GAU 0, $10 for Default GAU
        message = baseMessage + 'Payment 9';
        allocs = allocsByPmtId.get(pmts[9].Id);
        assertSObjectList(allocs, 2, message);
        assertPaymentAllocation(findByGAU(allocs, gaus[0]), pmts[9].Id, 1, 10, gaus[0].Id, message + ' - Allocation 0');
        assertPaymentAllocation(findByGAU(allocs, defaultGAU), pmts[9].Id, 10, null, defaultGAU.Id, message + ' - Allocation 1');

        // Opportunity 6 - Payment 10, Amoount $0 - Payment Allocations, 10% Allocation for GAU 0, $10 for Default GAU
        message = baseMessage + 'Payment 10';
        allocs = allocsByPmtId.get(pmts[10].Id);
        assertSObjectList(allocs, null, message);

        // Opportunity 6 - Payment 11, Amoount (null) - Payment Allocations, 10% Allocation for GAU 0, $10 for Default GAU
        message = baseMessage + 'Payment 11';
        allocs = allocsByPmtId.get(pmts[11].Id);
        assertSObjectList(allocs, null, message);

        // Opportunity 6 - Payment 12, Amoount ($10) - No Amount or Percent, GAU 1
        message = baseMessage + 'Payment 12';
        allocs = allocsByPmtId.get(pmts[12].Id);
        assertSObjectList(allocs, 1, message);
        assertPaymentAllocation(findByGAU(allocs, gaus[1]), pmts[12].Id, null, null, gaus[1].Id, message + ' - Allocation 0');

        // Opportunity 7
        baseMessage = 'Before Processing - Opportunity 7 - ';
        pmts = oppsById.get(oppIds[7]).npe01__OppPayment__r;

        // Opportunity 7 - Payment 0, Amoount ($10) - No Amount or Percent, GAU 1
        message = baseMessage + 'Payment 0';
        allocs = allocsByPmtId.get(pmts[0].Id);
        assertSObjectList(allocs, 1, message);
        assertPaymentAllocation(findByGAU(allocs, gaus[1]), pmts[0].Id, 10, 100, gaus[1].Id, message + ' - Allocation 0');
    */}

     /**
     * @description Asserts that the Payment Allocations are correct after processing (called
     *              from confirmProcessRecordsUpdatesAllocationsCorrectlyWhenPaymentAllocationsAreEnabled)
     * @param allocsByPmtId A map of a list of Payment Allocations, organized by Payment Id
     * @param oppIds The Opportunity Ids used in the test, in insertion order
     * @param gaus The list of test gaus in insertion order
     * @param defaultGAU The default GAU
     */
    private static void assertPaymentAllocationsAfterProcessing(Map<Id, List<Allocation__c>> allocsByPmtId, List<Id> oppIds, List<General_Accounting_Unit__c> gaus, General_Accounting_Unit__c defaultGAU) {
    /*    Map<Id, Opportunity> oppsById = new Map<Id, Opportunity>([SELECT    Id,
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

        // Opportunity 6 - Payment 0 - Added from Parent
        allocs = allocsByPmtId.get(pmts[0].Id);
        message = baseMessage + 'Payment 0';
        assertSObjectList(allocs, 1, message);
        assertPaymentAllocation(findByGAU(allocs, gaus[1]), pmts[0].Id, 10, 100, gaus[1].Id, message + ' - Allocation 0');

        // Opportunity 6 - Payment 1 - Payment Allocations, Default Allocation for $4 (Default), Percent Allocation for 50% (GAU0), Fixed for $1 (GAU1)
        message = baseMessage + 'Payment 1';
        allocs = allocsByPmtId.get(pmts[1].Id);
        assertSObjectList(allocs, 3, message);
        assertPaymentAllocation(findByGAU(allocs, defaultGAU), pmts[1].Id, 4, null, defaultGAU.Id, message + ' - Allocation 0');
        assertPaymentAllocation(findByGAU(allocs, gaus[0]), pmts[1].Id, 5, 50, gaus[0].Id, message + ' - Allocation 1');
        assertPaymentAllocation(findByGAU(allocs, gaus[1]), pmts[1].Id, 1, null, gaus[1].Id, message + ' - Allocation 2');

        // Opportunity 6 - Payment 2 - Payment Allocations, Fixed Amount Allocation for $1, GAU0, Default Allocation for $9
        message = baseMessage + 'Payment 2';
        allocs = allocsByPmtId.get(pmts[2].Id);
        assertSObjectList(allocs, 2, message);
        assertPaymentAllocation(findByGAU(allocs, gaus[0]), pmts[2].Id, 1, null, gaus[0].Id, message + ' - Allocation 0');
        assertPaymentAllocation(findByGAU(allocs, defaultGAU), pmts[2].Id, 9, null, defaultGAU.Id, message + ' - Allocation 1');

        // Opportunity 6 - Payment 3 - Payment Allocations, 100% Allocation for GAU0
        message = baseMessage + 'Payment 3';
        allocs = allocsByPmtId.get(pmts[3].Id);
        assertSObjectList(allocs, 1, message);
        assertPaymentAllocation(findByGAU(allocs, gaus[0]), pmts[3].Id, 10, 100, gaus[0].Id, message + ' - Allocation 0');

        // Opportunity 6 - Payment 4 - Payment Allocations, Default Allocation for $0
        message = baseMessage + 'Payment 4';
        allocs = allocsByPmtId.get(pmts[4].Id);
        assertSObjectList(allocs, 1, message);
        assertPaymentAllocation(findByGAU(allocs, defaultGAU), pmts[4].Id, 0, null, defaultGAU.Id, message + ' - Allocation 0');

        // Opportunity 6 - Payment 5 - Payment Allocations, Default Allocation for $0
        message = baseMessage + 'Payment 5';
        allocs = allocsByPmtId.get(pmts[5].Id);
        assertSObjectList(allocs, 1, message);
        assertPaymentAllocation(findByGAU(allocs, defaultGAU), pmts[5].Id, 0, null, defaultGAU.Id, message + ' - Allocation 0');

        // Opportunity 6 - Payment 6, Amount $0 - Payment Allocations, 10% Allocation for GAU 0
        message = baseMessage + 'Payment 6';
        allocs = allocsByPmtId.get(pmts[6].Id);
        assertSObjectList(allocs, 1, message);
        assertPaymentAllocation(findByGAU(allocs, gaus[0]), pmts[6].Id, 0, 10, gaus[0].Id, message + ' - Allocation 0');

        // Opportunity 6 - Payment 7, Amount (null) - Payment Allocations, 10% Allocation for GAU 0
        message = baseMessage + 'Payment 7';
        allocs = allocsByPmtId.get(pmts[7].Id);
        assertSObjectList(allocs, 1, message);
        assertPaymentAllocation(findByGAU(allocs, gaus[0]), pmts[7].Id, 0, 10, gaus[0].Id, message + ' - Allocation 0');

        // Opportunity 6 - Payment 8, Amoount $0 - Payment Allocations, 10% Allocation for GAU 0
        message = baseMessage + 'Payment 8';
        allocs = allocsByPmtId.get(pmts[8].Id);
        assertSObjectList(allocs, 1, message);
        assertPaymentAllocation(findByGAU(allocs, gaus[0]), pmts[8].Id, 0, 10, gaus[0].Id, message + ' - Allocation 0');

        // Opportunity 6 - Payment 9, Amoount (null) - Payment Allocations, 10% Allocation for GAU 0, $10 for Default GAU
        message = baseMessage + 'Payment 9';
        allocs = allocsByPmtId.get(pmts[9].Id);
        assertSObjectList(allocs, 1, message);
        assertPaymentAllocation(findByGAU(allocs, gaus[0]), pmts[9].Id, 0, 10, gaus[0].Id, message + ' - Allocation 0');

        // Opportunity 6 - Payment 10, Amoount $0 - Payment Allocations, 100% Allocation for GAU 1
        message = baseMessage + 'Payment 10';
        allocs = allocsByPmtId.get(pmts[10].Id);
        assertSObjectList(allocs, 1, message);
        assertPaymentAllocation(findByGAU(allocs, gaus[1]), pmts[10].Id, 0, 100, gaus[1].Id, message + ' - Allocation 0');

        // Opportunity 6 - Payment 11, Amoount (null) - Payment Allocations, 100% Allocation for GAU 1
        message = baseMessage + 'Payment 11';
        allocs = allocsByPmtId.get(pmts[11].Id);
        assertSObjectList(allocs, 1, message);
        assertPaymentAllocation(findByGAU(allocs, gaus[1]), pmts[11].Id, 0, 100, gaus[1].Id, message + ' - Allocation 0');

        // Opportunity 6 - Payment 12, Amoount ($10) - No Amount or Percent, GAU 1
        message = baseMessage + 'Payment 12';
        allocs = allocsByPmtId.get(pmts[12].Id);
        assertSObjectList(allocs, 1, message);
        assertPaymentAllocation(findByGAU(allocs, gaus[1]), pmts[12].Id, null, null, gaus[1].Id, message + ' - Allocation 0');

        // Opportunity 7
        baseMessage = 'After Processing - Opportunity 7 - ';
        pmts = oppsById.get(oppIds[7]).npe01__OppPayment__r;

        // Opportunity 7 - Payment 0, Amoount ($10) - No Amount or Percent, GAU 1
        message = baseMessage + 'Payment 0';
        allocs = allocsByPmtId.get(pmts[0].Id);
        assertSObjectList(allocs, 1, message);
        assertPaymentAllocation(findByGAU(allocs, gaus[1]), pmts[0].Id, 10, 100, gaus[1].Id, message + ' - Allocation 0');
    */}

     /**
     * @description Finds an Allocation in a List of Allocations by GAU
     * @param allocs The list of Allocations to search through
     * @param gau The gau to look for
     * @return Allocation__c The first matching Allocation By GAU, or null
     */
    private static Allocation__c findByGAU(List<Allocation__c> allocs, General_Accounting_Unit__c gau) {

        if (allocs != null) {
            for (Allocation__c alloc :allocs) {
                if (alloc.General_Accounting_Unit__c == gau.Id) {
                    return alloc;
                }
            }
        }
        // Didn't find any, return null
        return null;
    }

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
    @isTest
    private static void confirmOpportunitiesInSetAreRetrievedSuccessfully() {
    /*    AllocationSetupTest alloSetupTest = new AllocationSetupTest()
            .enableDefaultAllocations()
            .disableAllocationTriggers()
            .applyConfiguration();

        List<Id> oppIds = createTestDataAndReturnOppIds(alloSetupTest);

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
        assertSObjectList(opp6.npe01__OppPayment__r, 13, 'Opportunity 6 - Payments');

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
    */}

    /**
     * @description Confirm retrieves Allocation Data for the Opportunities, Payments, Recurring Donations, and
     *              Campaigns specified (via Ids)
     *              [ALLO_AllocationsUtil.retrieveAllocations]
     */
    @isTest
    private static void confirmAllocationsAreRetrievedSuccessfully() {
    /*    AllocationSetupTest alloSetupTest = new AllocationSetupTest()
            .enableDefaultAllocations()
            .enablePaymentAllocations()
            .disableAllocationTriggers()
            .applyConfiguration();

        List<Id> oppIds = createTestDataAndReturnOppIds(alloSetupTest);
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

        assertSObjectList(allocs, 30, 'Allocations');

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

        System.assertEquals(11, recsForRev.paymentAllocations.size(), 'Payment Allocations');

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
    */}

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

    /**
     * @description Confirms that the Validate Allocation Method returns the errors for the scenarios that should error, and
     *              an empty list if no validation errors are present
     */
    @isTest
    private static void confirmInvalidAllocationReturnErrors() {
    /*    List<Contact> ctcs = UTIL_UnitTestData_TEST.createMultipleTestContacts(1);
        insert ctcs;

        List<Opportunity> opps = UTIL_UnitTestData_TEST.oppsForContactList(ctcs, null, UTIL_UnitTestDATA_TEST.getClosedWonStage(), System.today().addDays(30), 20, null, null);

        insert opps;

        List<npe01__OppPayment__c> pmts = [SELECT   Id,
                                                    npe01__Opportunity__c
                                           FROM npe01__OppPayment__c];

        Id oppId = opps[0].Id;
        Id pmtId = pmts[0].Id;

        List<Allocation__c> testAllos = new List<Allocation__c> {
            new Allocation__c (Opportunity__c = oppId, Percent__c = 50),
            new Allocation__c (Payment__c = pmtId, Amount__c = -100),
            new Allocation__c (Payment__c = pmtId, Opportunity__c = oppId, Amount__c = 100 ),
            new Allocation__c (Opportunity__c = oppId),
            new Allocation__c (Opportunity__c = oppId, Amount__c = -100),
            new Allocation__c (Opportunity__c = oppId, Amount__c = 100, Percent__c = -100)
        };

        List<Integer> testResults = new List<Integer> {
            0,
            0,
            1,
            1,
            1,
            1
        };

        List<SObject> testParentSobjs = new List<SObject> {
            opps[0],
            pmts[0],
            pmts[0],
            opps[0],
            opps[0],
            opps[0]
        };

        for (Integer i = 0; i < testAllos.size(); i++) {
            SObject parentObj = testParentSObjs[i];
            List<String> errors = ALLO_AllocationsUtil.validateAllocation(parentObj,testAllos[i]);
            System.assertEquals(testResults[i], errors.size(), 'Validation Test # ' + (i + 1));
        }
    */}

    /******************************************************
     * Helper Methods - Error Tests
     ******************************************************/

    // TODO: Method: assembleAllocationError
    // Confirm it builds a properly formatted error message (associated with a parent and allocation)

    // TODO: Method: assembleRecordError
    // Confirm it builds a properly formatted error message (associated with a parent)

    /******************************************************
     * Helper Methods - General Tests
     ******************************************************/

    /**
     * @description Confirm it returns the Opportunity Id for the Object Passed to It
     *              [ALLO_AllocationsUtil.getOpportunityIdFor]
     */
    @isTest
    private static void confirmGetOpportunityIdForReturnsTheOpportunityIdAssociatedWiththeTheObject() {
    /*    List<Contact> ctcs = UTIL_UnitTestData_TEST.createMultipleTestContacts(1);
        insert ctcs;

        List<Opportunity> opps = UTIL_UnitTestData_TEST.oppsForContactList(ctcs, null, UTIL_UnitTestDATA_TEST.getClosedWonStage(), System.today().addDays(30), 20, null, null);

        insert opps;

        List<npe01__OppPayment__c> pmts = [SELECT   Id,
                                                    npe01__Opportunity__c
                                           FROM npe01__OppPayment__c];

        System.assertEquals(opps[0].Id, ALLO_AllocationsUtil.getOpportunityIdFor(opps[0]), 'Opportunity Id for Opportunity');
        System.assertEquals(opps[0].Id, ALLO_AllocationsUtil.getOpportunityIdFor(pmts[0]), 'Opportunity Id associated with Payment');
        System.assertEquals(null, ALLO_AllocationsUtil.getOpportunityIdFor(ctcs[0]), 'Other Objects will return null');
    */}

    /**
     * @description Confirm it returns the right Amount depending on whether the Opportunity or the Payment is passed.
     *              [ALLO_AllocationsUtil.getAmountFor]
     */
    @isTest
    private static void confirmGetAmountForReturnsTheCorrectAmountDependingOnTheObject() {
    /*    List<Contact> ctcs = UTIL_UnitTestData_TEST.createMultipleTestContacts(1);
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
    */}

    /**
     * @description Confirm it returns the right Label for each of the supported objects
     *              [ALLO_AllocationsUtil.getLabelFor]
     */
    @isTest
    private static void confirmGetLabelForReturnsTheCorrectLabelDependingOnTheObject() {
        System.assertEquals(UTIL_Describe.getObjectLabel('Allocation__c'), ALLO_AllocationsUtil.getLabelFor(new Allocation__c()), 'Allocation Label');
        System.assertEquals(UTIL_Describe.getObjectLabel('Opportunity'), ALLO_AllocationsUtil.getLabelFor(new Opportunity()), 'Opportunity Label');
        System.assertEquals(UTIL_Describe.getObjectLabel('npe01__OppPayment__c'), ALLO_AllocationsUtil.getLabelFor(new npe01__OppPayment__c()), 'Payment Label');
    }

    /******************************************************
     * Helper Methods - Callable Support
     ******************************************************/

    /*******************************************************************************************************
     * @description - Test calling ALLO_UpdPaymentAllocations_BATCH via the Callable_Api class. Assert that
     * an opportunity is processed when meeting the criteria and excluded when the criteria are not met. Also
     * ensure that a default allocation is created for any unallocated amount.
     ********************************************************************************************************/
    @isTest
    private static void processOppsAndPaymentAllocationsViaCallableApi() {
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
    @isTest
    private static void validatePaymentAllocationConfigurationViaCallableApiNoErrors() {
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
    @isTest
    private static void validatePaymentAllocationConfigurationViaCallableApiWithErrors() {
        Test.startTest();

        Callable npspApi = (Callable) Type.forName('Callable_API').newInstance();
        Map<String, Object> npspApiParams = new Map<String, Object>();
        List<String> configProblems = (List<String>)npspApi.call(ALLO_VALIDATE_CONFIG_ACTION, npspApiParams);

        Test.stopTest();

        System.assertEquals(false, configProblems.isEmpty(), 'Payment Allocation configuration validated - Errors were expected');
    }

    /******************************************************
     * Helper Methods - Test Data
     ******************************************************/

    /*******************************************************************************************************
     * @description Supports certain tests, creating Opportunities and Related Information
     * @param paymentAllocationsEnabled Boolean if true, Payment Allocations will be enabled
     * @param defaultAllocationsEnabled Boolean if true, Default Allocations will be enabled
     * @return List<Id> List of Opportunities Ids, in the order they were inserted
     ********************************************************************************************************/
    /*private static List<Id> createTestDataAndReturnOppIds(AllocationSetupTest alloSetupTest) {
        List<General_Accounting_Unit__c> gaus = alloSetupTest.getGAUs();
        General_Accounting_Unit__c defaultGAU = (alloSetupTest.isDefaultAllocationsEnabled()) ? alloSetupTest.getDefaultGAU() : null;

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
        pmts.add(
            new npe01__OppPayment__c(
                npe01__Payment_Amount__c = 10,
                npe01__Opportunity__c = opps[6].Id,
                npe01__Scheduled_Date__c = System.today().addDays(3)
            )
        );
        pmts.add(
            new npe01__OppPayment__c(
                npe01__Payment_Amount__c = 0,
                npe01__Opportunity__c = opps[6].Id,
                npe01__Scheduled_Date__c = System.today().addDays(4)
            )
        );
        pmts.add(
            new npe01__OppPayment__c(
                npe01__Payment_Amount__c = null,
                npe01__Opportunity__c = opps[6].Id,
                npe01__Scheduled_Date__c = System.today().addDays(5)
            )
        );
        pmts.add(
            new npe01__OppPayment__c(
                npe01__Payment_Amount__c = 0,
                npe01__Opportunity__c = opps[6].Id,
                npe01__Scheduled_Date__c = System.today().addDays(6)
            )
        );
        pmts.add(
            new npe01__OppPayment__c(
                npe01__Payment_Amount__c = null,
                npe01__Opportunity__c = opps[6].Id,
                npe01__Scheduled_Date__c = System.today().addDays(7)
            )
        );
        pmts.add(
            new npe01__OppPayment__c(
                npe01__Payment_Amount__c = 0,
                npe01__Opportunity__c = opps[6].Id,
                npe01__Scheduled_Date__c = System.today().addDays(8)
            )
        );
        pmts.add(
            new npe01__OppPayment__c(
                npe01__Payment_Amount__c = null,
                npe01__Opportunity__c = opps[6].Id,
                npe01__Scheduled_Date__c = System.today().addDays(9)
            )
        );
        pmts.add(
            new npe01__OppPayment__c(
                npe01__Payment_Amount__c = 0,
                npe01__Opportunity__c = opps[6].Id,
                npe01__Scheduled_Date__c = System.today().addDays(10)
            )
        );
        pmts.add(
            new npe01__OppPayment__c(
                npe01__Payment_Amount__c = null,
                npe01__Opportunity__c = opps[6].Id,
                npe01__Scheduled_Date__c = System.today().addDays(11)
            )
        );
        pmts.add(
            new npe01__OppPayment__c(
                npe01__Payment_Amount__c = 10,
                npe01__Opportunity__c = opps[6].Id,
                npe01__Scheduled_Date__c = System.today().addDays(12)
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

        if (alloSetupTest.isPaymentAllocationsEnabled()) { // Only if Payment Allocations are Enabled
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

            // Opportunity 6 - Payment 3 - 100% Allocation for GAU0, Default Allocation for $10
            allosForInsert.add(
                new Allocation__c(
                    Payment__c = pmts[4].Id,
                    Amount__c = 10,
                    Percent__c = 100,
                    General_Accounting_Unit__c = gaus[0].Id
                )
            );
            allosForInsert.add(
                new Allocation__c(
                    Payment__c = pmts[4].Id,
                    Amount__c = 10,
                    General_Accounting_Unit__c = defaultGau.Id
                )
            );

            // Opportunity 6 - Payment 4 ($0) - $10, Default GAU
            allosForInsert.add(
                new Allocation__c(
                    Payment__c = pmts[5].Id,
                    Amount__c = 10,
                    General_Accounting_Unit__c = defaultGAU.Id
                )
            );

            // Opportunity 6 - Payment 5 (null) - $10, Default GAU
            allosForInsert.add(
                new Allocation__c(
                    Payment__c = pmts[6].Id,
                    Amount__c = 10,
                    General_Accounting_Unit__c = defaultGAU.Id
                )
            );

            // Opportunity 6 - Payment 6 ($0) - 10%, GAU 0
            allosForInsert.add(
                new Allocation__c(
                    Payment__c = pmts[7].Id,
                    Amount__c = 1,
                    Percent__c = 10,
                    General_Accounting_Unit__c = gaus[0].Id
                )
            );

            // Opportunity 6 - Payment 7 (null) - 10%, GAU 0
            allosForInsert.add(
                new Allocation__c(
                    Payment__c = pmts[8].Id,
                    Amount__c = 1,
                    Percent__c = 10,
                    General_Accounting_Unit__c = gaus[0].Id
                )
            );
            // Opportunity 6 - Payment 8 ($0) - 10%, GAU 0, 10 Default GAU
            allosForInsert.add(
                new Allocation__c(
                    Payment__c = pmts[9].Id,
                    Amount__c = 1,
                    Percent__c = 10,
                    General_Accounting_Unit__c = gaus[0].Id
                )
            );
            allosForInsert.add(
                new Allocation__c(
                    Payment__c = pmts[9].Id,
                    Amount__c = 10,
                    Percent__c = null,
                    General_Accounting_Unit__c = defaultGAU.Id
                )
            );
            // Opportunity 6 - Payment 9 (null) - 10%, GAU 0, 10 Default GAU
            allosForInsert.add(
                new Allocation__c(
                    Payment__c = pmts[10].Id,
                    Amount__c = 1,
                    Percent__c = 10,
                    General_Accounting_Unit__c = gaus[0].Id
                )
            );
            // Opportunity 6 - Payment 9 (null) - 10%, GAU 0
            allosForInsert.add(
                new Allocation__c(
                    Payment__c = pmts[10].Id,
                    Amount__c = 10,
                    Percent__c = null,
                    General_Accounting_Unit__c = defaultGAU.Id
                )
            );

            // Opportunity 6 - Payment 13 ($10) - No Amount or Percent, GAU 0
            allosForInsert.add(
                new Allocation__c(
                    Payment__c = pmts[13].Id,
                    Amount__c = null,
                    Percent__c = null,
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

        // Opportunity 8 Allocation(s) - Opportunity with null Amount
        //      If Default Allocations Enabled, non zero fixed amount for Default Allocation
        //      If Default Allocations Disabled non zero amount with percent value for gau 2
        allosForInsert.add(
            new Allocation__c(
                Opportunity__c=opps[8].Id,
                Amount__c = 20,
                Percent__c = (defaultGau != null) ? null : 100,
                General_Accounting_Unit__c = (alloSetupTest.isDefaultAllocationsEnabled()) ? defaultGau.Id : gaus[2].Id
            )
        );

        // Opportunity 9 - No allocations.  Parent Campaign

        // Opportunity 10 - Existing Allocations, Resize for Opportunity Amount Difference
        if (alloSetupTest.isDefaultAllocationsEnabled()) { // Only if defaults enabled...
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
    }*/

    /*******************************************************************************************************
     * @description Asserts the list sizes for each of the allocations list in the RecordsForReview
     *              class
     *              [ALLO_AllocationsUtil.RecordsForReview]
     * @param recsForRev A populated Record For Review Structure
     * @param addtlMsg Text that will be displayed in addition to the list type if an assert fails
     * @param oppsAllocSize The exepected size of the Opportunity Allocations Map
     * @param pmtAllocSize The expected size of the Payment Allocations Map
     * @param rdAllocSize The expected size of the Recurring Donations Allocations Map
     * @param campAllocSize The expected size of the Campaign Allocations Map
     ********************************************************************************************************/
    /*private static void assertRecsForReviewAllocations(ALLO_AllocationsUtil.RecordsForReview recsForRev, String addtlMsg, Integer oppsAllocSize, Integer pmtAllocSize, Integer rdAllocSize, Integer campAllocSize) {
        System.assertEquals (oppsAllocSize, recsForRev.oppsAllocations.size(), addtlMsg + ': Opportunity Allocations Map Size');
        System.assertEquals (pmtAllocSize, recsForRev.paymentAllocations.size(), addtlMsg + ': Payment Allocations Map Size');
        System.assertEquals (rdAllocSize, recsForRev.recurringDonationAllocations.size(), addtlMsg + ': Recurring Donation Allocations Map Size');
        System.assertEquals (campAllocSize, recsForRev.campaignAllocations.size(), addtlMsg + ': Campaign Allocations Map Size');
    }*/

    /*******************************************************************************************************
     * @description Asserts the various expected field values of an Opportunity Allocation__c record
     * @param alloc The allocation to assert
     * @param opportunityId Expected Opportunity__c value
     * @param amount Expected Amount__c
     * @param percentage Expected Percent__c value
     * @param gauId Will assert value against General_Accounting_Unit__c
     * @param message The text to put on the front on the assertion message text
     ********************************************************************************************************/
    private static void assertOpportunityAllocation(Allocation__c alloc, Id opportunityId, Decimal amount, Decimal percentage, Id gauId, String message) {
        assertAllocation(alloc, opportunityId, null, null, null, amount, percentage, null, gauId, message);
    }

    /*******************************************************************************************************
     * @description Asserts the various expected field values of an Opportunity Allocation__c record
     * @param alloc The allocation to assert
     * @param opportunityId Expected Opportunity__c value
     * @param amount Expected Amount__c
     * @param percentage Expected Percent__c value
     * @param gauName Will assert value against General_Accounting_Unit__r.Name
     * @param message The text to put on the front on the assertion message text
     ********************************************************************************************************/
    private static void assertOpportunityAllocation(Allocation__c alloc, Id opportunityId, Decimal amount, Decimal percentage, String gauName, String message) {
        assertAllocation(alloc, opportunityId, null, null, null, amount, percentage, gauName, null, message);
    }

    /*******************************************************************************************************
     * @description Asserts the various expected field values of a Payment Allocation__c record
     * @param alloc The allocation to assert
     * @param paymentId Expected Payment__c value
     * @param amount Expected Amount__c
     * @param percentage Expected Percent__c value
     * @param gauName Will assert value against General_Accounting_Unit__r.Name
     * @param message The text to put on the front on the assertion message text
     ********************************************************************************************************/
    private static void assertPaymentAllocation(Allocation__c alloc, Id paymentId, Decimal amount, Decimal percentage, String gauName, String message) {
        assertAllocation(alloc, null, paymentId, null, null, amount, percentage, gauName, null, message);
    }

    /*******************************************************************************************************
     * @description Asserts the various expected field values of a Payment Allocation__c record
     * @param alloc The allocation to assert
     * @param paymentId Expected Payment__c value
     * @param amount Expected Amount__c
     * @param percentage Expected Percent__c value
     * @param gauId Will assert value against General_Accounting_Unit__c
     * @param message The text to put on the front on the assertion message text
     ********************************************************************************************************/
    private static void assertPaymentAllocation(Allocation__c alloc, Id paymentId, Decimal amount, Decimal percentage, Id gauId, String message) {
        assertAllocation(alloc, null, paymentId, null, null, amount, percentage, null, gauId, message);
    }

    /*******************************************************************************************************
     * @description Asserts the various expected field values of a Recurring Donation Allocation__c record
     * @param alloc The allocation to assert
     * @param recurringDonationId Expected Recurring_Donation__c value
     * @param amount Expected Amount__c
     * @param percentage Expected Percent__c value
     * @param gauName Will assert value against General_Accounting_Unit__r.Name
     * @param message The text to put on the front on the assertion message text
     ********************************************************************************************************/
    private static void assertRecurringDonationAllocation(Allocation__c alloc, Id recurringDonationId, Decimal amount, Decimal percentage, String gauName, String message) {
        assertAllocation(alloc, null, null, recurringDonationId, null, amount, percentage, gauName, null, message);
    }

    /*******************************************************************************************************
     * @description Asserts the various expected field values of a Recurring Donations Allocation__c record
     * @param alloc The allocation to assert
     * @param recurringDonationId Expected Recurring_Donation__c value
     * @param amount Expected Amount__c
     * @param percentage Expected Percent__c value
     * @param gauId Will assert value against General_Accounting_Unit__c
     * @param message The text to put on the front on the assertion message text
     ********************************************************************************************************/
    private static void assertRecurringDonationAllocation(Allocation__c alloc, Id recurringDonationId, Decimal amount, Decimal percentage, Id gauId, String message) {
        assertAllocation(alloc, null, null, recurringDonationId, null, amount, percentage, null, gauId, message);
    }

    /*******************************************************************************************************
     * @description Asserts the various expected field values of a Campaign Allocation__c record
     * @param alloc The allocation to assert
     * @param campaignId Expected Campaign__c value
     * @param amount Expected Amount__c
     * @param percentage Expected Percent__c value
     * @param gauName Will assert value against General_Accounting_Unit__r.Name
     * @param message The text to put on the front on the assertion message text
     ********************************************************************************************************/
    private static void assertCampaignAllocation(Allocation__c alloc, Id campaignId, Decimal amount, Decimal percentage, String gauName, String message) {
        assertAllocation(alloc, null, null, null, campaignId, amount, percentage, gauName, null, message);
    }

    /*******************************************************************************************************
     * @description Asserts the various expected field values of a Campaign Allocation__c record
     * @param alloc The allocation to assert
     * @param campaignId Expected Campaign__c value
     * @param amount Expected Amount__c
     * @param percentage Expected Percent__c value
     * @param gauId Will assert value against General_Accounting_Unit__c
     * @param message The text to put on the front on the assertion message text
     ********************************************************************************************************/
    private static void assertCampaignAllocation(Allocation__c alloc, Id campaignId, Decimal amount, Decimal percentage, Id gauId, String message) {
        assertAllocation(alloc, null, null, null, campaignId, amount, percentage, null, gauId, message);
    }

    /*******************************************************************************************************
     * @description Asserts the various expected field values of an Allocation__c record
     * @param alloc The allocation to assert
     * @param opportunityId Expected Opportunity__c value
     * @param paymentId Expected Payment__c value
     * @param recurringDonationId Expected Recurring_Donation__c value
     * @param campaignId Expected Campaign__c value
     * @param amount Expected Amount__c
     * @param percentage Expected Percent__c value
     * @param gauName If not null, will assert value against General_Accounting_Unit__r.Name
     * @param gauId If not null, will assert value against General_Accounting_Unit__c
     * @param message The text to put on the front on the assertion message text
     ********************************************************************************************************/
    private static void assertAllocation(Allocation__c alloc, Id opportunityId, Id paymentId, Id recurringDonationId, Id campaignId, Decimal amount, Decimal percentage, String gauName, Id gauId, String message) {
        System.assertNotEquals(null, alloc, message + ' - Not Null');
        System.assertEquals(opportunityId, alloc.Opportunity__c, message + ' - Opportunity' );
        System.assertEquals(paymentId, alloc.Payment__c, message + ' - Payment');
        System.assertEquals(recurringDonationId, alloc.Recurring_Donation__c, message + ' - Recurring Donation');
        System.assertEquals(campaignId, alloc.Campaign__c, message + ' - Campaign');
        System.assertEquals(amount, alloc.Amount__c, message + ' - Amount');
        System.assertEquals(percentage, alloc.Percent__c, message + ' - Percent');
        if (gauName != null) {
            System.assertEquals(gauName, alloc.General_Accounting_Unit__r.Name, message + ' - GAU (Name)');
        }
        if (gauId != null) {
            System.assertEquals(gauId, alloc.General_Accounting_Unit__c, message + ' - GAU (Id)');
        }
    }

    /*******************************************************************************************************
     * @description Asserts basic characteristics of a List of SObjects, including whether or not it is
     *              null, and the size
     * @param sObjs The List of SObjects to assert
     * @param expectedCount The number of expected records, or null, if the list should be null
     * @param message The text to put on the front on the assertion message text
     ********************************************************************************************************/
    private static void assertSObjectList(List<SObject> sObjs, Integer expectedCount, String message) {
        if (expectedCount == null) {
            System.assertEquals(null, sObjs, message + ' - List');
        } else {
            System.assertNotEquals(null, sObjs, message + ' - List');
            System.assertEquals(expectedCount, sObjs.size(), message + ' - List size');
        }
    }

    /*******************************************************************************************************
     * @description Builds a map of a List of Recurring Donation Allocation__c records, keyed by
     *              Recurring Donation Id
     * @param allocs The list of allocs to process into a Map of a List of Recurring Donation Allocations,
     *        By Recurring Donation Id
     * @return Map of a List of Recurring Donations Allocations By Recurring Donations Id
     ********************************************************************************************************/
    private static Map<Id, List<Allocation__c>> buildMapOfAllocationsByRecurringDonationId(List<Allocation__c> allocs) {
        Map<Id, List<Allocation__c>> allocsByRDId = new Map<Id, List<Allocation__c>>();

        for (Allocation__c alloc : allocs) {
            if (alloc.Recurring_Donation__c != null) {
                List<Allocation__c> allocs2 = allocsByRDId.containsKey(alloc.Recurring_Donation__c) ? allocsByRDId.get(alloc.Recurring_Donation__c) : new List<Allocation__c>();
                allocs2.add(alloc);
                allocsByRDId.put(alloc.Recurring_Donation__c, allocs2);
            }
        }

        return allocsByRDId;
    }

    /*******************************************************************************************************
     * @description Builds a map of a List of Campaign Allocation__c records, keyed by Campaign Id
     * @param allocs The list of allocs to process into a Map of a List of Campaign Allocations,
     *        By Campaign Id
     * @return Map of a List of Campaign Allocations By Campaign Id
     ********************************************************************************************************/
    private static Map<Id, List<Allocation__c>> buildMapOfAllocationsByCampaignId(List<Allocation__c> allocs) {
        Map<Id, List<Allocation__c>> allocsByCampaignId = new Map<Id, List<Allocation__c>>();

        for (Allocation__c alloc : allocs) {
            if (alloc.Campaign__c != null) {
                List<Allocation__c> allocs2 = allocsByCampaignId.containsKey(alloc.Campaign__c) ? allocsByCampaignId.get(alloc.Campaign__c) : new List<Allocation__c>();
                allocs2.add(alloc);
                allocsByCampaignId.put(alloc.Campaign__c, allocs2);
            }
        }

        return allocsByCampaignId;
    }

    /*******************************************************************************************************
     * @description Builds a map of a List of Opportunity Allocation__c records, keyed by Opportunity Id
     * @param allocs The list of allocs to process into a Map of a List of Opportunity Allocations,
     *        By Opportunity Id
     * @return Map of a List of Opportunity Allocations By Opportunity Id
     ********************************************************************************************************/
    private static Map<Id, List<Allocation__c>> buildMapOfAllocationsByOpportunityId(List<Allocation__c> allocs) {
        Map<Id, List<Allocation__c>> allocsByOppId = new Map<Id, List<Allocation__c>>();

        for (Allocation__c alloc : allocs) {
            if (alloc.Opportunity__c != null) {
                List<Allocation__c> allocs2 = allocsByOppId.containsKey(alloc.Opportunity__c) ? allocsByOppId.get(alloc.Opportunity__c) : new List<Allocation__c>();
                allocs2.add(alloc);
                allocsByOppId.put(alloc.Opportunity__c, allocs2);
            }
        }

        return allocsByOppId;
    }

    /*******************************************************************************************************
     * @description Builds a map of a List of Payment Allocation__c records, keyed by Payment Id
     * @param allocs The list of allocs to process into a Map of a List of Payment Allocations,
     *        By Payment Id
     * @return Map of a List of Payment Allocations By Payment Id
     ********************************************************************************************************/
    private static Map<Id, List<Allocation__c>> buildMapOfAllocationsByPaymentId(List<Allocation__c> allocs) {
        Map<Id, List<Allocation__c>> allocsByPmtId = new Map<Id, List<Allocation__c>>();

        for (Allocation__c alloc : allocs) {
            if (alloc.Payment__c != null) {
                List<Allocation__c> allocs2 = allocsByPmtId.containsKey(alloc.Payment__c) ? allocsByPmtId.get(alloc.Payment__c) : new List<Allocation__c>();
                allocs2.add(alloc);
                allocsByPmtId.put(alloc.Payment__c, allocs2);
            }
        }

        return allocsByPmtId;
    }

    /**
     * @description Helper method to retrieve all error records into a Map by Salesforce Id
     * @return Map of Error__c records by Related Record ID
     */
    private static Map<Id, Error__c> getErrorsByRecordId() {
        List<Error__c> errs =  [SELECT  Id,
                                        Context_Type__c,
                                        Datetime__c,
                                        Error_Type__c,
                                        Full_Message__c,
                                        Object_Type__c,
                                        Related_Record_ID__c,
                                        Record_URL__c,
                                        Retry_Pending__c
                                FROM Error__c];

        Map<Id, Error__c> errsByRecordId = new Map<Id, Error__c>();

        for (Error__c err : errs) {
            errsByRecordId.put (err.Related_Record_ID__c, err);
        }

        return errsByRecordId;
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
        private Boolean multiCurrencyEnabled = false;
        private String defaultIsoCode = null;
        private String nonDefaultIsoCode = null;

        /*******************************************************************************************************
         * @description Default constructor for AllocationSetupTest class
         ********************************************************************************************************/
        public AllocationSetupTest() {

        }

        /*******************************************************************************************************
         * @description Pass in existing allocation settings for use in configuration
         * @param allocationSettings An instance of Allocation_Settings__c
         * @return class instance
         ********************************************************************************************************/
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

            configureForMultiCurrencyIfPossible();

            if (this.disableAllocationTriggers) {
                // Turn Off Allocation Triggers
                ALLO_AllocationsUtil.disableAllocationTriggers();
            }

            return this;
        }

        /*******************************************************************************************************
         * @description Configures some additional local variables if in a MultiCurrency Enabled Org
         ********************************************************************************************************/
        private void configureForMultiCurrencyIfPossible() {
            if (UserInfo.isMultiCurrencyOrganization()) {

                ALLO_Multicurrency_TEST.setupISOCodes();
                this.multiCurrencyEnabled = (ALLO_Multicurrency_TEST.nonDefaultCurrencyType != null && ALLO_Multicurrency_TEST.defaultCurrencyType != null);
                if (this.multiCurrencyEnabled) {
                    this.defaultIsoCode = (String) ALLO_Multicurrency_TEST.defaultCurrencyType.get('IsoCode');
                    this.nonDefaultIsoCode = (String) ALLO_Multicurrency_TEST.nonDefaultCurrencyType.get('IsoCode');
                }
            }
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

        /*******************************************************************************************************
         * @description Returns the list of General_Accounting_Unit__c records created during configuration for
         *              use in the tests
         * @return List of General_Accounting_Unit__c records created while applying the AllocationSetupTest
         ********************************************************************************************************/
        public List<General_Accounting_Unit__c> getGAUs() {
            return this.gaus;
        }

        /*******************************************************************************************************
         * @description Returns the General_Accounting_Unit__C record assigned to be the "Default GAU", if
         *              Default Allocations were enabled
         * @return Default General_Accounting_Unit__c record, if default allocations are enabled and one was
         *         assigned
         ********************************************************************************************************/
        public General_Accounting_Unit__c getDefaultGAU() {
            return this.defaultGAU;
        }

        /*******************************************************************************************************
         * @description Returns whether Default Allocations were enabled
         * @return true if enabled
         ********************************************************************************************************/
        public Boolean isDefaultAllocationsEnabled() {
            return this.defaultAllocations == true;
        }

        /*******************************************************************************************************
         * @description Returns whether Payment Allocations were enabled
         * @return true if enabled
         ********************************************************************************************************/
        public Boolean isPaymentAllocationsEnabled() {
            return this.paymentAllocations == true;
        }

        /*******************************************************************************************************
         * @description Returns whether MultiCurrency Tests can be executed or not
         * @return true if MultiCurrency is Enabled in the Org with a Corporate Currency and at least one other
         *         Currency enabled
         ********************************************************************************************************/
        public Boolean isMultiCurrencyConfiguredForTesting() {
            return this.multiCurrencyEnabled;
        }

        /*******************************************************************************************************
         * @description Returns the Corporate (Default) Currency ISO Code (if possible)
         * @return String either null or the ISO Code associated with the Corporate Currency
         ********************************************************************************************************/
        public String getDefaultIsoCode() {
            return this.defaultIsoCode;
        }

        /*******************************************************************************************************
         * @description Returns the Non Default (Not Corporate) Currency ISO Code (if possible)
         * @return String either null or the ISO Code associated with an enabled Currency other than the
         *         Corporate (Default) Currency
         ********************************************************************************************************/
        public String getNonDefaultIsoCode() {
            return this.nonDefaultIsoCode;
        }
    }
}