/*
    Copyright (c) 2019 Salesforce.org
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
* @group Recurring Donations
* @description Unit tests for the Enhanced RD Opportunity Evaluation Services
*
*/
@IsTest(IsParallel=true)
private class RD2_OpportunityEvaluationService_TEST {

    private static final TEST_SObjectGateway.RecurringDonationGateway rdGateway = new TEST_SObjectGateway.RecurringDonationGateway();
    private static final TEST_SObjectGateway.OpportunityGateway oppGateway = new TEST_SObjectGateway.OpportunityGateway();
    private static final TEST_SObjectGateway.ErrorGateway errorGateway = new TEST_SObjectGateway.ErrorGateway();

    private static final Date START_DATE = Date.newInstance(2019, 9, 15);

    /****
    * @description Creates data required for unit tests
    */
    @TestSetup
    private static void setUp() {
        insert UTIL_UnitTestData_TEST.getContact();
    }

    /**
     * @description Verifies that creating a new Open Recurring Donation creates an Installment Opportunity
     */
    @IsTest
    private static void shouldCreateAnInstallmentOppWhenActiveRDIsCreated() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact())
            .withDayOfMonth('20')
            .withCalculateNextDonationDate()
            .build();

        Test.startTest();
        insert rd;
        Test.stopTest();

        rd = rdGateway.getRecord(rd.Id);
        List<Opportunity> opps = oppGateway.getRecords(rd);

        System.assertEquals(1, opps.size(), 'The number of returned Opp should match');
        System.assertEquals(rd.npe03__Amount__c, opps[0].Amount, 'The Opportunity Amount does not match the RD Amount');
        System.assertEquals(rd.npe03__Contact__c, opps[0].Primary_Contact__c, 'The Opportunity Contact does not match the RD Contact');
        System.assertEquals(rd.npe03__Next_Payment_Date__c, opps[0].CloseDate, 'The Opportunity CloseDate does not match the RD NextDonationDate');
    }

    /**
     * @description Verifies that inserting a Closed Recurring Donation does not create an Installment Opportunity
     */
    @IsTest
    private static void shouldNotCreateAnInstallmentOppWhenClosedRDIsCreated() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact())
            .withStatusClosed()
            .withDayOfMonth('20')
            .withCalculateNextDonationDate()
            .build();

        Test.startTest();
        insert rd;
        Test.stopTest();

        rd = rdGateway.getRecord(rd.Id);

        List<Opportunity> opps = oppGateway.getRecords(rd);
        System.assertEquals(0, opps.size(), 'There should not have been any Installment Opps created for this RD');
    }

    /**
     * @description Verify that the Recurring Donations are NOT eligible to have an installment opportunity created
     */
    @IsTest
    private static void shouldFilterOutRDsNotEligibleForNewInstallmentOpp() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        RD2_ScheduleService scheduleService = new RD2_ScheduleService();

        // Closed Recurring Donation
        npe03__Recurring_Donation__c rd1 = getRecurringDonationBuilder()
            .withStatusClosed()
            .withDayOfMonth('20')
            .withCalculateNextDonationDate()
            .build();
        rd1 = mockRecurringDonationFullQueryResult(rd1, new List<Opportunity>(), scheduleService.getNewSchedules(rd1));

        // Recurring Donation with no Schedule records
        npe03__Recurring_Donation__c rd2 = getRecurringDonationBuilder()
            .withInstallmentPeriodWeekly()
            .withInstallmentFrequency(3)
            .withCalculateNextDonationDate()
            .build();
        rd2 = mockRecurringDonationFullQueryResult(rd2, new List<Opportunity>(), new List<RecurringDonationSchedule__c>());

        // Recurring Donation with an empty NextDonationDate
        npe03__Recurring_Donation__c rd3 = getRecurringDonationBuilder()
            .withInstallmentPeriodYearly()
            .withInstallmentFrequency(1)
            .withStartDate(Date.newInstance(2019, 6, 1))
            .withCalculateNextDonationDate()
            .build();
        rd3.npe03__Next_Payment_Date__c = null;
        rd3 = mockRecurringDonationFullQueryResult(rd3, new List<Opportunity>(), scheduleService.getNewSchedules(rd3));

        RD2_OpportunityEvaluationService evalService = new RD2_OpportunityEvaluationService();
        evalService.rds = new List<npe03__Recurring_Donation__c>{ rd1, rd2, rd3 };

        System.assertEquals(false, evalService.needNextInstallment(rd1), 'Closed RD should not be eligible for an Installment Opp');
        System.assertEquals(false, evalService.needNextInstallment(rd2), 'RD with no Schedules should not be eligible for an Installment Opp');
        System.assertEquals(false, evalService.needNextInstallment(rd3), 'RD without a Next Donation Date should not be eligible for an Installment Opp');
    }

    /**
     * @description Verify that the Recurring Donations are recognized as "New" if there are no related Opps
     * or "Not New" if there have related Opps.
     */
    @IsTest
    private static void shouldDetermineIfNewOrPreExistingRecurringDonation() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        RD2_ScheduleService scheduleService = new RD2_ScheduleService();

        // New Opp - Is New RD
        npe03__Recurring_Donation__c rdNew = getRecurringDonationBuilder()
            .withDayOfMonth('20')
            .withCalculateNextDonationDate()
            .build();
        rdNew = mockRecurringDonationFullQueryResult(rdNew, new List<Opportunity>(), scheduleService.getNewSchedules(rdNew));

        // Old Opportunity (has related Opps) - Not New RD
        npe03__Recurring_Donation__c rdOld = getRecurringDonationBuilder()
            .withInstallmentPeriodWeekly()
            .withInstallmentFrequency(3)
            .withCalculateNextDonationDate()
            .build();

        List<Opportunity> opps = new List<Opportunity>{
            getOpportunityBuilder(rdOld)
                .withAccount(rdOld.npe03__Organization__c)
                .withOpenStage()
                .withCloseDate(rdOld.npe03__Next_Payment_Date__c)
                .build()
        };
        rdOld = mockRecurringDonationFullQueryResult(rdOld, opps, scheduleService.getNewSchedules(rdOld));

        RD2_OpportunityEvaluationService evalService = new RD2_OpportunityEvaluationService();
        evalService.rds = new List<npe03__Recurring_Donation__c>{ rdNew, rdOld };

        System.assertEquals(true, evalService.needNextInstallment(rdNew), 
            'RD having Schedules and no related Opp should be eligible for an Installment Opp');

        System.assertEquals(false, evalService.needNextInstallment(rdOld), 
            'RD having Schedules and a related Opp should not be eligible for an Installment Opp');
    }

    /**
     * @description Verifies open Opportunities are marked as Closed Lost when RD is closed and
     * Recurring Donation settings Open Opportunity Behaviour is set to mark open Opps as Closed Lost
     */
    @IsTest
    private static void shouldMarkOpenOppsAsClosedLostWhenRDIsClosedAndCloseActionIsClosedLost() {        
        String closeAction = RD2_Constants.CloseActions.Mark_Opportunities_Closed_Lost.name();

        npe03__Recurring_Donation__c rd = setupDataAndCloseRD(closeAction);
        List<Opportunity> oldOpps = rd.npe03__Donations__r;

        Map<Id, Opportunity> oppById = new Map<Id, Opportunity>(oppGateway.getRecords(rd));

        System.assertEquals(oldOpps.size(), oppById.size(), 'The number of Opps should be unchanged');
        System.assertEquals(true, oppById.get(oldOpps[0].Id).isWon, 'The closed Opp should stay won');
        System.assertEquals(true, oppById.get(oldOpps[1].Id).isClosed && !oppById.get(oldOpps[1].Id).isWon, 
            'The Open Opp should be Closed Lost now');
    }

    /**
     * @description Verifies open Opportunities are deleted when RD is closed and
     * Recurring Donation settings Open Opportunity Behaviour is set to delete open Opps
     */
    @IsTest
    private static void shouldDeleteOpenOppsWhenRDIsClosedAndCloseActionIsDeletion() {
        String closeAction = RD2_Constants.CloseActions.Delete_Open_Opportunities.name();

        npe03__Recurring_Donation__c rd = setupDataAndCloseRD(closeAction);
        List<Opportunity> oldOpps = rd.npe03__Donations__r;

        List<Opportunity> opps = oppGateway.getRecords(rd);

        System.assertEquals(1, opps.size(), 'Only closed won Opp should exist: ' + opps);
        System.assertEquals(oldOpps[0].Name, opps[0].Name, 'The closed won Opp should not be deleted');
        System.assertEquals(true, opps[0].isWon, 'The closed won Opp should be unchanged');
    }

    /**
     * @description Verifies open Opportunities are unchanged when RD is closed and
     * Recurring Donation settings Open Opportunity Behaviour is set to not change open Opps
     */
    @IsTest
    private static void shouldNotChangeOpenOppsWhenRDIsClosedAndCloseActionIsNoAction() {        
        String closeAction = RD2_Constants.CloseActions.No_Action.name();

        npe03__Recurring_Donation__c rd = setupDataAndCloseRD(closeAction);
        List<Opportunity> oldOpps = rd.npe03__Donations__r;

        Map<Id, Opportunity> oppById = new Map<Id, Opportunity>(oppGateway.getRecords(rd));

        System.assertEquals(oldOpps.size(), oppById.size(), 'The number of Opps should match');
        System.assertEquals(true, oppById.get(oldOpps[0].Id).isWon, 'Closed Opp should be unchanged');
        System.assertEquals(false, oppById.get(oldOpps[1].Id).isClosed, 'Open Opp should stay open');
    }

    /**
     * @description Sets up data to test open Installment Opportunity behaviour on RD close
     * @param closeAction Recurring Donation settings Open Opportunity Behaviour close action
     * @return npe03__Recurring_Donation__c Created Recurring Donation with related Opps
     */
    private static npe03__Recurring_Donation__c setupDataAndCloseRD(String closeAction) {
        UTIL_CustomSettingsFacade.getRecurringDonationsSettingsForTest(
            new npe03__Recurring_Donations_Settings__c(
                npe03__Open_Opportunity_Behavior__c = closeAction
            )
        );

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact())
            .withDayOfMonth('20')
            .withCalculateNextDonationDate()
            .build();
        insert rd;
        
        TEST_OpportunityBuilder oppBuilder = getOpportunityBuilder(rd);

        List<Opportunity> opps = new List<Opportunity>{
            oppBuilder
                .withName()
                .withCloseDate(rd.npe03__Next_Payment_Date__c.addMonths(-1))
                .withClosedWonStage()
                .build(),
            oppBuilder
                .withName()
                .withCloseDate(rd.npe03__Next_Payment_Date__c)
                .withOpenStage()
                .build()
        };
        insert opps;

        Map<Id, Opportunity> oppById = new Map<Id, Opportunity>(oppGateway.getRecords(rd));
        System.assertEquals(2, oppById.size(), 'The number of returned Opps should match');

        opps[0] = oppById.get(opps[0].Id);
        opps[1] = oppById.get(opps[1].Id);

        System.assertEquals(true, opps[0].isClosed, 'The first Opp should be closed');
        System.assertEquals(true, opps[0].isWon, 'The first Opp should be won');
        System.assertEquals(false, opps[1].isClosed, 'The second Opp should be open');

        Test.startTest();
        rd.Status__c = RD2_Constants.STATUS_CLOSED;
        update rd;
        Test.stopTest();

        rd = mockRecurringDonationFullQueryResult(rd, oppById.values(), null);
        return rd;
    }

    /**
     * @description Verifies no exception is thrown when RD is closed and
     * has no Opportunities
     */
    @IsTest
    private static void shouldNotThrowExceptionWhenRDIsClosedAndHasNoOpp() { 
        Exception actualException;
        String closeAction = RD2_Constants.CloseActions.Mark_Opportunities_Closed_Lost.name();

        UTIL_CustomSettingsFacade.getRecurringDonationsSettingsForTest(
            new npe03__Recurring_Donations_Settings__c(
                npe03__Open_Opportunity_Behavior__c = closeAction
            )
        );

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact())
            .withDayOfMonth('20')
            .withCalculateNextDonationDate()
            .build();
        insert rd;

        Test.startTest();
        rd.Status__c = RD2_Constants.STATUS_CLOSED;
        try {
            update rd;

        } catch (Exception e) {
            actualException = e;
        }
        Test.stopTest();

        System.assertEquals(null, actualException, 'No exception should be thrown when closed RD has no Opps');
    }

    /**
     * @description Verifies Opps are not processed when override is set
     */
    @IsTest
    private static void shouldNotEvaluateOppsWhenOverrideIsSet() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        RD2_OpportunityEvaluationService.skipEvaluationService = true;

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact().Id).build();

        Test.startTest();
        insert rd;
        Test.stopTest();

        List<Opportunity> opps = oppGateway.getRecords(rd);
        System.assertEquals(0, opps.size(), 'No Installment Opp should be created if override is checked: ' + opps);

        List<Error__c> errors = errorGateway.getRecords();
        System.assertEquals(0, errors.size(), 'No error should be created: ' + errors);
    }

    /**
     * @description Verifies Opps are processed when override is not set
     */
    @IsTest
    private static void shouldEvaluateOppsWhenOverrideIsNotSet() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        System.assertEquals(false, RD2_OpportunityEvaluationService.skipEvaluationService, 'Override should be false by default');

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact().Id).build();

        Test.startTest();
        insert rd;
        Test.stopTest();

        List<Opportunity> opps = oppGateway.getRecords(rd);
        System.assertEquals(1, opps.size(), 'An Installment Opp should be created: ' + opps);

        List<Error__c> errors = errorGateway.getRecords();
        System.assertEquals(0, errors.size(), 'No error should be created: ' + errors);
    }

    /**
     * @description Verifies future open Opp is updated when an active RD is updated
     */
    @IsTest
    private static void shouldUpdateFutureOppWhenRDIsUpdated() {
        //set current date override
        final Date today = START_DATE.addDays(1);
        RD2_ScheduleService.currentDate = today;

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact().Id)        
            .withCalculateNextDonationDate()
            .build();
        insert rd;

        insert getOpportunityBuilder(rd)
            .withCloseDate(today.addDays(1))
            .withOpenStage()
            .build();

        Date nextCloseDate = today.addDays(2);
        Decimal newAmount = rd.npe03__Amount__c + 100;

        Test.startTest();
        rd.Day_Of_Month__c = String.valueOf(nextCloseDate.day());
        rd.npe03__Amount__c = newAmount;
        update rd;
        Test.stopTest();

        List<Opportunity> opps = oppGateway.getRecords(rd);
        System.assertEquals(1, opps.size(), 'An Installment Opp should exist: ' + opps);
        System.assertEquals(newAmount, opps[0].Amount, 'Amount should be updated');
        System.assertEquals(nextCloseDate, opps[0].CloseDate, 'Close Date should be updated');

        List<Error__c> errors = errorGateway.getRecords();
        System.assertEquals(0, errors.size(), 'No error should be created: ' + errors);
    }

    /**
    * @description Ensures that when the DisableRollupsWhenCreatingInstallments__c flag is NOT set
    * and CRLP is enabled, the rollups do execute properly when the RD Batch Job is run
    */
    @IsTest
    private static void shouldRecalcRollupsOnRdAfterBatchJobWithCRLP() {

        configureForBatchJobWithRollupDisableTests(false);
        npe03__Recurring_Donation__c rd = createTestDataForRollupRecalcTest();
        System.assertEquals(null, rd.npe03__Paid_Amount__c, 'The PaidAmount field should be null instead of zero');

        Database.executeBatch(new RD2_OpportunityEvaluation_BATCH());
        Test.stopTest();

        System.assertEquals(1, [SELECT Count() FROM Opportunity WHERE npe03__Recurring_Donation__c = :rd.Id],
            'There should be 1 installment Opportunities created for this RD');

        rd = rdGateway.getRecord(rd.Id);
        System.assertEquals(0, rd.npe03__Paid_Amount__c, 'The PaidAmount field should be zero instead of null');
    }

    /**
    * @description Ensures that when the DisableRollupsWhenCreatingInstallments__c flag IS set
    * and CRLP is enabled, the rollups do NOT execute when the RD Batch Job is run
    */
    @IsTest
    private static void shouldNotRecalcRollupsOnRdAfterBatchJobWithCRLP() {

        configureForBatchJobWithRollupDisableTests(true);
        npe03__Recurring_Donation__c rd = createTestDataForRollupRecalcTest();

        System.assertEquals(null, rd.npe03__Paid_Amount__c, 'The PaidAmount field should be null instead of zero');

        Database.executeBatch(new RD2_OpportunityEvaluation_BATCH());
        Test.stopTest();

        System.assertEquals(1, [SELECT Count() FROM Opportunity WHERE npe03__Recurring_Donation__c = :rd.Id],
            'There should be 1 installment Opportunities created for this RD');

        rd = rdGateway.getRecord(rd.Id);
        System.assertEquals(null, rd.npe03__Paid_Amount__c, 'The PaidAmount field should still be null instead of zero');
    }


    // Helpers
    ///////////////////

    /****
    * @description Returns contact record
    * @return Contact
    */
    private static Contact getContact() {
        return [
            SELECT FirstName, LastName, AccountId, Account.Name
            FROM Contact
            LIMIT 1
        ];
    }

    /**
     * @description Instantiate an Opp builder for the specified Recurring Donation
     * @param rd Recurring Donation
     * @return TEST_OpportunityBuilder New Opp builder
     */
    private static TEST_OpportunityBuilder getOpportunityBuilder(npe03__Recurring_Donation__c rd) {
        return new TEST_OpportunityBuilder()
            .withContact(rd.npe03__Contact__c)
            .withRecurringDonation(rd.Id)
            .withAmount(rd.npe03__Amount__c)
            .withInstallmentNumber(1);
    }

    /**
     * @description Base common RecurringDonation test structure for all test methods to start from
     * @return TEST_RecurringDonationBuilder instance
     */
    private static TEST_RecurringDonationBuilder getRecurringDonationBuilder() {
        return getRecurringDonationBuilder(UTIL_UnitTestData_TEST.mockId(Contact.SObjectType));
    }

    /**
     * @description Base common RecurringDonation test structure for all test methods to start from
     * @param c Contact
     * @return TEST_RecurringDonationBuilder instance
     */
    private static TEST_RecurringDonationBuilder getRecurringDonationBuilder(Contact c) {
        return getRecurringDonationBuilder(c.Id);
    }

    /**
     * @description Base common RecurringDonation test structure for all test methods to start from
     * @param contactId Contact Id
     * @return TEST_RecurringDonationBuilder instance
     */
    private static TEST_RecurringDonationBuilder getRecurringDonationBuilder(Id contactId) {
        return TEST_RecurringDonationBuilder.constructEnhancedBuilder()
            .withDefaultValues()
            .withContact(contactId)
            .withAmount(100)
            .withPaymentMethod('Check')
            .withDateEstablished(START_DATE)
            .withStartDate(START_DATE)
            .withCalculateNextDonationDate();
    }

    /**
     * @description Builds a fully mocked RecurringDonation record with subqueries on Opportunities and Schedules. This is
     * used to support mocked tests against the RD2_EvaluationService without having to insert any records.
     * @param rd Mocked Recurring Donation using TEST_RecurringDonationBuilder
     * @param opps Mocked Related Opportunties (or an empty collection)
     * @param schedules Mockked RecurringDonationSchedule records (can be built using the RD2_ScheduleService)
     * @return RecurringDonation with the Subqueries fully populated.
     */
    private static npe03__Recurring_Donation__c mockRecurringDonationFullQueryResult(npe03__Recurring_Donation__c rd,
            List<Opportunity> opps, List<RecurringDonationSchedule__c> schedules) {

        if (opps == null) {
            opps = new List<Opportunity>();
        }

        if (schedules == null) {
            schedules = new List<RecurringDonationSchedule__c>();
        }

        Contact contact = new Contact(
            Id = rd.npe03__Contact__c,
            AccountId = UTIL_UnitTestData_TEST.mockId(Account.SObjectType),
            LastName = UTIL_UnitTestData_TEST.getUniqueString()
        );

        rd = TEST_RecurringDonationBuilder.addForeignKey(rd, 'npe03__Contact__r', contact);
        rd = TEST_RecurringDonationBuilder.addRelatedList(rd, 'npe03__Donations__r', opps);
        rd = TEST_RecurringDonationBuilder.addRelatedList(rd, UTIL_Namespace.StrTokenNSPrefix('RecurringDonationSchedules__r'), schedules);

        return rd;
    }

    /**
    * @description Configure Settings for validating the behavior of the DisableRollupsWhenCreatingInstallments__c
    * setting in the RD Batch Job. Also mocks the CRLP settings for Enhanced Recurring Donations, and
    * disables the internal setting that would normally prevent a null field from being updated to a zero
    * value during rollups. This is used to tell that rollups did or did not run in the batch job.
    */
    private static void configureForBatchJobWithRollupDisableTests(Boolean isDisableRollups) {

        UTIL_CustomSettingsFacade.getRollupSettingsForTests(new Customizable_Rollup_Settings__c (
            Customizable_Rollups_Enabled__c = true
        ));
        CMT_UnitTestData_TEST.mockEnhancedRecurringDonationRollupCMTValues();
        CRLP_Rollup_SVC.UPDATE_NULL_TO_ZERO = true;

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        UTIL_CustomSettingsFacade.getRecurringDonationsSettingsForTest(new npe03__Recurring_Donations_Settings__c(
            DisableRollupsWhenCreatingInstallments__c = isDisableRollups,
            IsRecurringDonations2Enabled__c = true,
            npe03__Open_Opportunity_Behavior__c = RD_RecurringDonations.RecurringDonationCloseOptions.Mark_Opportunities_Closed_Lost.name(),
            npe03__Add_Campaign_to_All_Opportunites__c = true
        ));
    }

    /**
    * @description Create a single Enhanced Recurring Donation to use for validating
    * the behavior of the DisableRollupsWhenCreatingInstallments__c setting in the RD Batch Job.
    * Triggers are disabled to prevent an installment opp from being created since that is what we want to
    * test in the batch job logic. However, the schedule records still need to be created
    * @return Created Recurring Donation Record
    */
    private static npe03__Recurring_Donation__c createTestDataForRollupRecalcTest() {
        Contact c = UTIL_UnitTestData_TEST.getContact();
        insert c;

        npe03__Recurring_Donation__c rd = TEST_RecurringDonationBuilder.constructEnhancedBuilder()
            .withContact(c.Id)
            .withAmount(100)
            .withDateEstablished(Date.today())
            .withStartDate(Date.today())
            .withStatusActive()
            .withInstallmentPeriodMonthly()
            .withInstallmentFrequency(1)
            .withDayOfMonth('1')
            .withCalculateNextDonationDate()
            .build();
        rd.npe03__Installments__c = null;   // force this to null because the default is 1
        Test.startTest();

        TDTM_TriggerHandler.disableTDTM = true;
        Database.insert(rd);
        TDTM_TriggerHandler.disableTDTM = false;

        RD2_ScheduleService scheduleService = new RD2_ScheduleService();
        Database.insert(scheduleService.getNewSchedules(rd));

        System.assertEquals(0, [SELECT Count() FROM Opportunity WHERE npe03__Recurring_Donation__c = :rd.Id],
            'There should be no installment Opportunities created for this RD');
        System.assertEquals(1, [SELECT Count() FROM RecurringDonationSchedule__c WHERE RecurringDonation__c = :rd.Id],
            'There should be 1 RD Schedule record created for this RD');
        System.assertEquals(null, rd.npe03__Paid_Amount__c, 'The PaidAmount field should be null instead of zero');

        return rdGateway.getRecord(rd.Id);
    }

}