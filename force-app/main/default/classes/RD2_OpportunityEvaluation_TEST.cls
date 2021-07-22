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
* @description Unit tests for the Enhanced RD Opportunity Evaluation Batch Job
*
*/
@IsTest(IsParallel=false)
public with sharing class RD2_OpportunityEvaluation_TEST {
    private static final TEST_SObjectGateway.RecurringDonationGateway rdGateway = new TEST_SObjectGateway.RecurringDonationGateway();
    private static final TEST_SObjectGateway.RecurringDonationScheduleGateway scheduleGateway = new TEST_SObjectGateway.RecurringDonationScheduleGateway();
    private static final TEST_SObjectGateway.OpportunityGateway oppGateway = new TEST_SObjectGateway.OpportunityGateway();
    private static final TEST_SObjectGateway.AsyncApexJobGateway jobGateway = new TEST_SObjectGateway.AsyncApexJobGateway();
    private static final TEST_SObjectGateway.ErrorGateway errorGateway = new TEST_SObjectGateway.ErrorGateway();

    private static final Date START_DATE = Date.newInstance(2019, 9, 15);
    private static final Integer MONTHS_TO_DEC = START_DATE.monthsBetween(Date.newInstance(2019, 12, 15));
    private static final Integer MONTHS_TO_YEAR_END = START_DATE.monthsBetween(Date.newInstance(2020, 1, 1));

    /****
    * @description Creates data required for unit tests
    */
    @TestSetup
    private static void setUp() {
        insert UTIL_UnitTestData_TEST.getContact();
    }

    /**
     * @description Verify that when Enhanced RD is NOT enabled in an org, attempting to execute the new RD2 batch
     * job throws an exception
     */
    @IsTest
    private static void shouldThrowExceptionForEnhancedRDJobIfEnhancedRDIsNotEnabled() {
        Exception actuaException = runBatch(new RD2_OpportunityEvaluation_BATCH());

        System.assertNotEquals(null, actuaException, 'An exception should have been thrown because Enhanced RD is not enabled');
        System.assert(actuaException.getMessage().containsIgnoreCase(System.Label.RD2_ErrorEnhancedRDBatchJobCannotBeRun),
            'The job cannot be executed because Enhanced RD is not enabled: ' + actuaException.getMessage());
    }

    /**
     * @description Verify that when RD2 is enabled in an org, executing the new Enhanced RD batch job does not
     * throw an exception
     */
    @IsTest
    private static void shouldNotThrowExceptionForEnhancedRDJobIfEnhancedRDIsEnabled() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        Exception actuaException = runBatch(new RD2_OpportunityEvaluation_BATCH());

        System.assertEquals(null, actuaException, 'No exception is expected because Enhanced RD is enabled');
    }

    /**
     * @description Verify that when Enhanced RD is NOT enabled in an org, executing the new Legacy RD
     * batch job does not throw an exception
     */
    @IsTest
    private static void shouldNotThrowExceptionForLegacyRDJobIfEnhancedRDIsNotEnabled() {
        Exception actuaException = runBatch(new RD_RecurringDonations_BATCH());

        System.assertEquals(null, actuaException, 'An exception is expected because Enhanced RD is not enabled');
    }

    /**
     * @description Verifies closed Recurring Donations are processed in the Opp evaluation batch
     */
    @IsTest
    private static void shouldProcessClosedRDs() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        final Date today = START_DATE.addMonths(1);
        RD2_ScheduleService.currentDate = today;

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder()
            .withStatusClosed()
            .build();
        insert rd;

        insert TEST_OpportunityBuilder.getOpportunityBuilder(rd)
            .withClosedWonStage()
            .withCloseDate(START_DATE)
            .build();

        runBatch(new RD2_OpportunityEvaluation_BATCH(today));

        assertBatchJobIteration(1);

        List<Opportunity> opps = oppGateway.getRecords(rd);
        System.assertEquals(1, opps.size(), 'No new Opp should be created: ' + opps);

        rd = rdGateway.getRecord(rd.Id);
        System.assertEquals(rd.npe03__Amount__c, rd.CurrentYearValue__c,
            'Current Year Value should be calculated for a Closed RD');
        System.assertEquals(0, rd.NextYearValue__c,
            'Next Year Value should be zero for a Closed RD');
    }


   /**
    * @description Verifies no installment Opportunity is created by the RD batch when
    * Elevate integration is enabled and Commitment Id is specified on the RD.
    */
    @IsTest
    private static void shouldNotCreateNextOppForElevateRDWhenIntegrationIsEnabled() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        final Date today = START_DATE.addMonths(1);
        RD2_ScheduleService.currentDate = today;

        PS_IntegrationServiceConfig_TEST.Stub configStub = new PS_IntegrationServiceConfig_TEST.Stub()
            .withIsIntegrationEnabled(true);
        RD2_ElevateIntegrationService.config = (PS_IntegrationServiceConfig) Test.createStub(PS_IntegrationServiceConfig.class, configStub);

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder()
            .withCommitmentId(RD2_ElevateIntegrationService_TEST.COMMITMENT_ID)
            .withPaymentMethod(RD2_Constants.PAYMENT_PICKLIST_VALUE_CARD)
            .build();
        insert rd;

        runBatch(new RD2_OpportunityEvaluation_BATCH(today));

        assertBatchJobIteration(1);

        List<Opportunity> opps = oppGateway.getRecords(rd);
        System.assertEquals(0, opps.size(),
            'No installment Opportunity should be created for the Elevate RD when integration is enabled: ' + opps);
    }

    /**
     * @description Verifies an Opp with Close Date today is not created if it already exists
     */
    @IsTest
    private static void shouldNotCreateDuplicateOppWhenNextCloseDateIsToday() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        RD2_Settings_TEST.configureForASyncFirstOpportunityCreate();

        final Date today = START_DATE.addMonths(1);
        RD2_ScheduleService.currentDate = today;

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder().build();
        insert rd;

        insert TEST_OpportunityBuilder.getOpportunityBuilder(rd)
            .withOpenStage()
            .withCloseDate(today)
            .build();

        List<Opportunity> opps = oppGateway.getRecords(rd);
        System.assertEquals(1, opps.size(), 'An Opp should exist: ' + opps);

        runBatch(new RD2_OpportunityEvaluation_BATCH(today));

        assertBatchJobIteration(1);

        opps = oppGateway.getRecords(rd);
        System.assertEquals(1, opps.size(), 'No new Opp should be created: ' + opps);
        System.assertEquals(today, opps[0].CloseDate, 'Close Date should be unchanged: ' + opps);
    }

    /**
     * @description Verifies an Opp with Close Date in future is not created if it already exists
     */
    @IsTest
    private static void shouldNotCreateDuplicateOppWhenNextCloseDateIsInFuture() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        RD2_Settings_TEST.configureForASyncFirstOpportunityCreate();

        final Date today = START_DATE.addMonths(1).addDays(1);
        final Date nextCloseDate = START_DATE.addMonths(2);
        RD2_ScheduleService.currentDate = today;

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder().build();
        insert rd;

        insert TEST_OpportunityBuilder.getOpportunityBuilder(rd)
            .withOpenStage()
            .withCloseDate(nextCloseDate)
            .build();

        List<Opportunity> opps = oppGateway.getRecords(rd);
        System.assertEquals(1, opps.size(), 'An Opp should exist: ' + opps);

        runBatch(new RD2_OpportunityEvaluation_BATCH(today));

        assertBatchJobIteration(1);

        opps = oppGateway.getRecords(rd);
        System.assertEquals(1, opps.size(), 'No new Opp should be created: ' + opps);
        System.assertEquals(nextCloseDate, opps[0].CloseDate, 'Close Date should be unchanged: ' + opps);
    }

    /**
     * @description Verifies the Next Donation Date (NDD) Opportunity is not created
     * when a user created Opp Close Date is within the next NDD +/- match days range
     */
    @IsTest
    private static void shouldNotCreateDuplicateOppWhenNextOppAlreadyExistsWithinMatchRange() {
        final Date prevCloseDate = START_DATE.addMonths(1);
        final Date nextDonationDate = START_DATE.addMonths(2);
        final Date nextCloseDate = nextDonationDate.addDays(-3);//the Opp is still within the next NDD range

        Date today = prevCloseDate.addDays(-1);
        RD2_ScheduleService.currentDate = today;
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        RD2_Settings_TEST.configureForASyncFirstOpportunityCreate();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder().build();
        insert rd;

        TEST_OpportunityBuilder oppBuilder = TEST_OpportunityBuilder.getOpportunityBuilder(rd);
        List<Opportunity> opps = new List<Opportunity>{
            oppBuilder
                .withName()
                .withCloseDate(START_DATE)
                .withClosedWonStage()
                .build(),
            oppBuilder
                .withName()
                .withCloseDate(prevCloseDate)
                .withOpenStage()
                .build(),
            oppBuilder
                .withName()
                .withCloseDate(nextCloseDate)
                .withOpenStage()
                .build()
        };
        insert opps;

        today = prevCloseDate.addDays(1);

        RD2_OpportunityEvaluation_BATCH batch = executeAndFinishBatch(rd.Id, today);

        assertRecordsFailed(batch, 0);

        Map<Id, Opportunity> oppById = new Map<Id, Opportunity>(oppGateway.getRecords(rd));
        System.assertEquals(opps.size(), oppById.size(),
            'No new Opp should be created: ' + oppById.values());
        System.assertEquals(nextCloseDate, oppById.get(opps[2].Id).CloseDate,
            'Close Date should be unchanged for the future Opp');
    }

    /**
     * @description Verifies an Opp with Close Date equal to today is created if it already does not exist
     */
    @IsTest
    private static void shouldCreateNextOppWhenCloseDateIsToday() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        RD2_Settings_TEST.configureForASyncFirstOpportunityCreate();

        final Date prevCloseDate = START_DATE.addMonths(1);
        final Date today = START_DATE.addMonths(2);
        RD2_ScheduleService.currentDate = today;

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder().build();
        insert rd;

        insert TEST_OpportunityBuilder.getOpportunityBuilder(rd)
            .withClosedWonStage()
            .withCloseDate(prevCloseDate)
            .build();

        List<Opportunity> opps = oppGateway.getRecords(rd);
        System.assertEquals(1, opps.size(), 'An Opp should exist: ' + opps);

        runBatch(new RD2_OpportunityEvaluation_BATCH(today));

        Map<Id, Opportunity> oppById = new Map<Id, Opportunity>(oppGateway.getRecords(rd));
        System.assertEquals(2, oppById.size(), 'New Opp should be created: ' + oppById.values());

        System.assertEquals(prevCloseDate, oppById.remove(opps[0].Id).CloseDate,
            'Close Date should be unchanged for the existing Opp');
        System.assertEquals(today, oppById.values()[0].CloseDate,
            'Close Date on the new Opp should match next Close Date');
    }

    /**
     * @description Verifies an Opp with Close Date equal to the Recurring Donation Next Donation Date is created
     */
    @IsTest
    private static void shouldCreateNextOppWhenRDStatusIsActive() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        RD2_Settings_TEST.configureForASyncFirstOpportunityCreate();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder().build();
        
        testNextInstallmentOppCreation(rd);
    }

    /**
     * @description Verifies next installment Opp is created for a Lapsed RD
     */
    @IsTest
    private static void shouldCreateNextOppWhenRDStatusIsLapsed() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        RD2_Settings_TEST.configureForASyncFirstOpportunityCreate();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder()
            .withStatusLapsed()
            .build();

        testNextInstallmentOppCreation(rd);
    }

    /**
     * @description Verifies the batch job will not be started with another
     * batch job with the same class name is already executing
     */
    @isTest
    private static void shouldNotRunTheBatchIfAnotherJobIsRunning() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        
        final Date prevCloseDate = START_DATE.addMonths(1);
        final Date today = prevCloseDate.addDays(1);
        final Date nextCloseDate = START_DATE.addMonths(2);
        RD2_ScheduleService.currentDate = today;

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder()
            .withStatusLapsed()
            .build();
        insert rd;

        RD2_OpportunityEvaluation_BATCH batch  = new RD2_OpportunityEvaluation_BATCH(nextCloseDate.addDays(1));
        batch.isConcurrentBatch = true;
        runBatch(batch);

        List<Error__c> errors = errorGateway.getRecords();
        System.assertEquals(1, errors.size(), 'One error should be created: ' + errors);
        
        String expectedMessage = String.format(
            System.Label.commonConcurrentBatchError,
            new String[]{ RD2_OpportunityEvaluation_BATCH.class.getName() }
        );
        System.assertEquals(expectedMessage, errors[0].Full_Message__c, 'Error message should match');
    }
    
    /**
     * @description Verifies next installment Opp is created for the next installment date
     */
    private static void testNextInstallmentOppCreation(npe03__Recurring_Donation__c rd) {
        final Date prevCloseDate = START_DATE.addMonths(1);
        final Date today = prevCloseDate.addDays(1);
        final Date nextCloseDate = START_DATE.addMonths(2);
        RD2_ScheduleService.currentDate = today;

        insert rd;

        insert TEST_OpportunityBuilder.getOpportunityBuilder(rd)
            .withOpenStage()
            .withCloseDate(prevCloseDate)
            .build();

        List<Opportunity> opps = oppGateway.getRecords(rd);
        System.assertEquals(1, opps.size(), 'An Opp should exist: ' + opps);

        runBatch(new RD2_OpportunityEvaluation_BATCH(today));

        Map<Id, Opportunity> oppById = new Map<Id, Opportunity>(oppGateway.getRecords(rd));
        System.assertEquals(2, oppById.size(), 'New Opp should be created: ' + oppById.values());

        System.assertEquals(prevCloseDate, oppById.remove(opps[0].Id).CloseDate,
            'Close Date should be unchanged for the existing Opp');
        System.assertEquals(nextCloseDate, oppById.values()[0].CloseDate,
            'Close Date on the new Opp should match next Close Date');
    }

    /**
     * @description Verifies an Opp with Close Date equal to the Recurring Donation Next Donation Date is created
     * when Installment Period is "1st and 15th"
     */
    @IsTest
    private static void shouldCreateNextOppWhenInstallmentPeriodIs1stAnd15th() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        RD2_Settings_TEST.configureForASyncFirstOpportunityCreate();

        final Date prevCloseDate = START_DATE.addMonths(1);
        final Date today = prevCloseDate.addDays(1);
        final Date nextCloseDate = START_DATE.addMonths(2).toStartOfMonth();
        RD2_ScheduleService.currentDate = today;

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder()
            .withInstallmentPeriod(RD2_Constants.INSTALLMENT_PERIOD_FIRST_AND_FIFTEENTH)
            .withDayOfMonth(null)
            .build();
        insert rd;

        insert TEST_OpportunityBuilder.getOpportunityBuilder(rd)
            .withClosedWonStage()
            .withCloseDate(prevCloseDate)
            .build();

        List<Opportunity> opps = oppGateway.getRecords(rd);
        System.assertEquals(1, opps.size(), 'An Opp should exist: ' + opps);

        runBatch(new RD2_OpportunityEvaluation_BATCH(today));

        Map<Id, Opportunity> oppById = new Map<Id, Opportunity>(oppGateway.getRecords(rd));
        System.assertEquals(2, oppById.size(), 'New Opp should be created: ' + oppById.values());

        System.assertEquals(prevCloseDate, oppById.remove(opps[0].Id).CloseDate,
            'Close Date should be unchanged for the existing Opp');
        System.assertEquals(nextCloseDate, oppById.values()[0].CloseDate,
            'Close Date on the new Opp should match next Close Date');
    }

    /**
     * @description Verifies an Opp is not created when next Close Date is the after RD Schedule End Date
     */
    @IsTest
    private static void shouldNotCreateNextOppWhenScheduleEndDateIsPassed() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        RD2_Settings_TEST.configureForASyncFirstOpportunityCreate();

        final Date today = START_DATE.addMonths(1).addDays(1);
        RD2_ScheduleService.currentDate = today;

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder().build();
        insert rd;

        List<RecurringDonationSchedule__c> rdSchedules = scheduleGateway.getRecords(rd);
        System.assertEquals(1, rdSchedules.size(), 'An RD Schedule should exist: ' + rdSchedules);

        //Set Schedule End Date to date before the next Close Date
        rdSchedules[0].EndDate__c = START_DATE.addMonths(2).addDays(-1);
        update rdSchedules[0];

        runBatch(new RD2_OpportunityEvaluation_BATCH(today));

        List<Opportunity> opps = oppGateway.getRecords(rd);
        System.assertEquals(0, opps.size(), 'No new Opp should be created: ' + opps);
    }

    /**
     * @description Verifies an Opp is created when next Close Date is the RD Schedule End Date
     */
    @IsTest
    private static void shouldCreateNextOppWhenScheduleEndDateIsNextCloseDate() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        final Date today = START_DATE.addMonths(1).addDays(1);
        RD2_ScheduleService.currentDate = today;

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder().build();
        insert rd;

        List<RecurringDonationSchedule__c> rdSchedules = scheduleGateway.getRecords(rd);
        System.assertEquals(1, rdSchedules.size(), 'An RD Schedule should exist: ' + rdSchedules);

        //Set Schedule End Date to the next Close Date
        rdSchedules[0].EndDate__c = START_DATE.addMonths(2);
        update rdSchedules[0];

        runBatch(new RD2_OpportunityEvaluation_BATCH(today));

        List<Opportunity> opps = oppGateway.getRecords(rd);
        System.assertEquals(1, opps.size(), 'A new Opportunity should be created: ' + opps);
        System.assertEquals(rdSchedules[0].EndDate__c, opps[0].CloseDate,
            'Close Date on the new Opp should match next Close Date');
    }

    /**
     * @description Verifies RD Next Donation Date is updated when it is outdated and the new Opp is created
     */
    @IsTest
    private static void shouldCreateNextOppWhenRDNextDonationDateIsOutdated() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        RD2_Settings_TEST.configureForASyncFirstOpportunityCreate();

        Date today = START_DATE.addDays(1);
        final Date nextDonationDate = START_DATE.addMonths(1);
        RD2_ScheduleService.currentDate = today;

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder().build();
        insert rd;

        insert TEST_OpportunityBuilder.getOpportunityBuilder(rd)
            .withOpenStage()
            .withCloseDate(START_DATE)
            .build();

        List<Opportunity> opps = oppGateway.getRecords(rd);
        System.assertEquals(1, opps.size(), 'An Opp should exist: ' + opps);

        rd = rdGateway.getRecord(rd.Id);
        System.assertEquals(nextDonationDate, rd.npe03__Next_Payment_Date__c, 'Next Donation Date should match');

        //Next Donation Date is outdated
        today = nextDonationDate.addDays(1);
        final Date nextCloseDate = nextDonationDate.addMonths(1);
        //need to set the Schedule Service current date due to other async jobs completing at Test.stopTest()
        RD2_ScheduleService.currentDate = today;

        runBatch(new RD2_OpportunityEvaluation_BATCH(today));

        rd = rdGateway.getRecord(rd.Id);
        System.assertEquals(nextCloseDate, rd.npe03__Next_Payment_Date__c, 'Next Donation Date should be updated');

        Map<Id, Opportunity> oppById = new Map<Id, Opportunity>(oppGateway.getRecords(rd));
        System.assertEquals(2, oppById.size(), 'New Opp should be created: ' + oppById.values());

        System.assertEquals(START_DATE, oppById.remove(opps[0].Id).CloseDate,
            'Close Date should be unchanged for the existing Opp');
        System.assertEquals(nextCloseDate, oppById.values()[0].CloseDate,
            'Close Date on the new Opp should match next Close Date after today');
    }

    /**
     * @description Verifies number of failed Opps is zero on Opp DML success
     */
    @IsTest
    private static void shouldReturnZeroRecordsFailedWhenOppDMLSucceeds() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        final Date today = START_DATE.addMonths(1).addDays(1);
        final Date nextCloseDate = START_DATE.addMonths(2);
        RD2_ScheduleService.currentDate = today;

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder().build();
        insert rd;

        RD2_OpportunityEvaluation_BATCH batch = executeAndFinishBatch(rd.Id, today);

        assertRecordsFailed(batch, 0);

        List<Opportunity> opps = oppGateway.getRecords(rd);
        System.assertEquals(1, opps.size(), 'A new Opportunity should be created: ' + opps);

        List<Error__c> errors = errorGateway.getRecords();
        System.assertEquals(0, errors.size(), 'No error should be created: ' + errors);
    }

    /**
     * @description Verifies number of failed Opps is tracked on Opp DML fail
     */
    @IsTest
    private static void shouldReturnRecordsFailedWhenOppDMLFails() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        configInvalidOppRecordTypeId();

        final Date today = START_DATE.addMonths(1).addDays(1);//after Oct Close Date
        RD2_ScheduleService.currentDate = today;

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder().build();
        insert rd;

        RD2_OpportunityEvaluation_BATCH batch = executeAndFinishBatch(rd.Id, today);

        assertRecordsFailed(batch, 1);

        List<Opportunity> opps = oppGateway.getRecords(rd);
        System.assertEquals(0, opps.size(), 'No new Opp should be created: ' + opps);

        List<Error__c> errors = errorGateway.getRecords();
        System.assertEquals(1, errors.size(), 'An error should be created: ' + errors);

        rd = rdGateway.getRecord(rd.Id);
        System.assertEquals(rd.npe03__Amount__c * 2, rd.CurrentYearValue__c,
            'Current Year Value should be calculated to include installments for the rest of the year');
        System.assertEquals(rd.npe03__Amount__c * 12, rd.NextYearValue__c,
            'Next Year Value should be calculated for the next year projected installments');
    }

    /**
    * @description Ensures that when the DisableRollupsWhenCreatingInstallments__c flag is NOT set
    * and CRLP is enabled, the rollups do execute properly when the RD Batch Job is run
    */
    @IsTest
    private static void shouldRecalcRollupsOnRdWhenDisableRollupsIsNotSet() {
        configureForBatchJobWithRollupDisableTests(false);

        npe03__Recurring_Donation__c rd = createTestDataForRollupRecalcTest();
        System.assertEquals(null, rd.npe03__Paid_Amount__c, 'The PaidAmount field should be null instead of zero');

        Database.executeBatch(new RD2_OpportunityEvaluation_BATCH());
        Test.stopTest();

        System.assertEquals(1, oppGateway.getRecords(rd).size(),
            'There should be 1 installment Opportunities created for this RD');

        rd = rdGateway.getRecord(rd.Id);
        System.assertEquals(0, rd.npe03__Paid_Amount__c, 'The PaidAmount field should be zero instead of null');
    }

    /**
    * @description Ensures that when the DisableRollupsWhenCreatingInstallments__c flag IS set
    * and CRLP is enabled, the rollups do NOT execute when the RD Batch Job is run
    */
    @IsTest
    private static void shouldNotRecalcRollupsOnRdWhenDisableRollupsIsSet() {
        configureForBatchJobWithRollupDisableTests(true);

        npe03__Recurring_Donation__c rd = createTestDataForRollupRecalcTest();
        System.assertEquals(null, rd.npe03__Paid_Amount__c, 'The PaidAmount field should be null instead of zero');

        Database.executeBatch(new RD2_OpportunityEvaluation_BATCH());
        Test.stopTest();

        System.assertEquals(1, oppGateway.getRecords(rd).size(),
            'There should be 1 installment Opportunities created for this RD');

        rd = rdGateway.getRecord(rd.Id);
        System.assertEquals(null, rd.npe03__Paid_Amount__c, 'The PaidAmount field should still be null instead of zero');
    }

    /**
     * @description Verifies an Opp with the next Close Date is created
     * when the same Close Date Opp is Closed Lost in data migration
     */
    @IsTest
    private static void shouldCreateNextOppWhenSameCloseDateOppIsClosedLostInMigration() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        RD2_Settings_TEST.configureForASyncFirstOpportunityCreate();

        final Date today = START_DATE.addDays(1);
        final Date nextCloseDate = START_DATE.addMonths(1);
        RD2_ScheduleService.currentDate = today;

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder().build();
        insert rd;

        insert TEST_OpportunityBuilder.getOpportunityBuilder(rd)
            .withInstallmentNumberMigrationFlag()
            .withClosedLostStage()
            .withCloseDate(nextCloseDate)
            .build();

        List<Opportunity> opps = oppGateway.getRecords(rd);
        System.assertEquals(1, opps.size(), 'An Opp should exist: ' + opps);

        runBatch(new RD2_OpportunityEvaluation_BATCH(today));

        Map<Id, Opportunity> oppById = new Map<Id, Opportunity>(oppGateway.getRecords(rd));
        System.assertEquals(2, oppById.size(), 'New Opp should be created: ' + oppById.values());

        for (Opportunity opp : oppById.values()) {
            System.assertEquals(nextCloseDate, opp.CloseDate, 'Both Opps should have the same next Close Date');

            if (opp.Id == opps[0].Id) {
                System.assertEquals(true, opp.isClosed && !opp.isWon, 'Existing Closed Lost Opp should stay closed');
            } else {
                System.assertEquals(false, opp.isClosed, 'New Opp should be open');
            }
        }
    }

    /**
     * @description Verifies an Opp with the next Close Date is not created
     * when the same Close Date Opp is Closed Lost outside of data migration
     */
    @IsTest
    private static void shouldNotCreateNextOppWhenSameCloseDateOppIsClosedLostOutsideMigration() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        RD2_Settings_TEST.configureForASyncFirstOpportunityCreate();

        final Date today = START_DATE.addDays(1);
        final Date nextCloseDate = START_DATE.addMonths(1);
        RD2_ScheduleService.currentDate = today;

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder().build();
        insert rd;

        Opportunity opp = TEST_OpportunityBuilder.getOpportunityBuilder(rd)
            .withClosedLostStage()
            .withCloseDate(nextCloseDate)
            .build();
        insert opp;

        runBatch(new RD2_OpportunityEvaluation_BATCH(today));

        Map<Id, Opportunity> oppById = new Map<Id, Opportunity>(oppGateway.getRecords(rd));
        System.assertEquals(2, oppById.size(),
            'New Opp should be created for the Next Donation Date offset by the closed Opp: ' + oppById.values());

        Opportunity actualOpp = oppById.remove(opp.Id);
        System.assertEquals(true, actualOpp.IsClosed && !actualOpp.IsWon, 'Existing Closed Lost Opp should stay closed');

        //verify the Next Donation Date is advanced and a new Opp is created
        actualOpp = oppById.values()[0];

        System.assertEquals(false, actualOpp.IsClosed, 'New Opp should be open: ' + actualOpp);
        System.assertEquals(nextCloseDate.addMonths(1), actualOpp.CloseDate,
            'New Opp Close Date should be the Next Donation Date after the closed Opp Close Date: ' + actualOpp);
    }

    /**
    * @description Verifies the next Opportunity on Recurring Donation is created
    * when Installment Auto Creation Setting is set to Disable First Installment.
    */
    @IsTest
    private static void shouldCreateNextOppWhenDisableFirstInstallment() {
        npe03__Recurring_Donation__c rd = runInstallmentCreateTestFor(
            RD2_Constants.InstallmentCreateOptions.Disable_First_Installment.name()
        );

        List<Opportunity> opps = oppGateway.getRecords(rd);
        System.assertEquals(1, opps.size(), 'The next installment Opp should be created: ' + opps);

        rd = rdGateway.getRecord(rd.Id);
        System.assertEquals(rd.npe03__Amount__c * MONTHS_TO_YEAR_END, rd.CurrentYearValue__c,
            'Current Year Value should be calculated for the current year');
        System.assertEquals(rd.npe03__Amount__c * 12, rd.NextYearValue__c,
            'Next Year Value should be calculated for the next year projected installments');
    }

    /**
    * @description Verifies the next Opportunity on Recurring Donation is created
    * when Installment Auto Creation Setting is set to Always Create Next Installment.
    */
    @IsTest
    private static void shouldCreateNextOppWhenAlwaysCreateNextInstallment() {
        npe03__Recurring_Donation__c rd = runInstallmentCreateTestFor(
            RD2_Constants.InstallmentCreateOptions.Always_Create_Next_Installment.name()
        );

        List<Opportunity> opps = oppGateway.getRecords(rd);
        System.assertEquals(1, opps.size(), 'The next installment Opp should be created: ' + opps);

        rd = rdGateway.getRecord(rd.Id);
        System.assertEquals(rd.npe03__Amount__c * MONTHS_TO_YEAR_END, rd.CurrentYearValue__c,
            'Current Year Value should be calculated for the current year');
        System.assertEquals(rd.npe03__Amount__c * 12, rd.NextYearValue__c,
            'Next Year Value should be calculated for the next year projected installments');
    }

    /**
    * @description Verifies the next Opportunity on Recurring Donation is not created
    * when Installment Auto Creation Setting is set to Disable All Installments.
    */
    @IsTest
    private static void shouldNotCreateNextOppWhenDisableAllInstallments() {
        npe03__Recurring_Donation__c rd = runInstallmentCreateTestFor(
            RD2_Constants.InstallmentCreateOptions.Disable_All_Installments.name()
        );

        List<Opportunity> opps = oppGateway.getRecords(rd);
        System.assertEquals(0, opps.size(), 'The next installment Opp should not be created: ' + opps);

        rd = rdGateway.getRecord(rd.Id);
        System.assertEquals(rd.npe03__Amount__c * MONTHS_TO_YEAR_END, rd.CurrentYearValue__c,
            'Current Year Value should be calculated for the current year');
        System.assertEquals(rd.npe03__Amount__c * 12, rd.NextYearValue__c,
            'Next Year Value should be calculated for the next year projected installments');
    }

    /**
    * @description Created the Recurring Donation and executes the batch for the specified RD settings option
    * @param createOption Installment Opportunity Create option
    * @return npe03__Recurring_Donation__c
    */
    private static npe03__Recurring_Donation__c runInstallmentCreateTestFor(String createOption) {
        final Date today = START_DATE;
        RD2_ScheduleService.currentDate = today;
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        RD2_Settings_TEST.setUpConfiguration(new Map<String, Object> {
            'InstallmentOppAutoCreateOption__c' => createOption
        });

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder().build();
        insert rd;

        runBatch(new RD2_OpportunityEvaluation_BATCH(today));

        return rd;
    }

    /**
    * @description Verifies Current and Next Year Values are updated by the nightly batch
    * when the current/next year changes
    */
    @IsTest
    private static void shouldUpdateYearValuesWhenYearChanges() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        Date today = START_DATE.addMonths(1);
        RD2_ScheduleService.currentDate = today;

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder().build();
        insert rd;

        insert TEST_OpportunityBuilder.getOpportunityBuilder(rd)
            .withClosedWonStage()
            .withCloseDate(START_DATE)
            .build();

        today = Date.newInstance(2020, 1, 1);//New Year
        runBatch(new RD2_OpportunityEvaluation_BATCH(today));

        assertBatchJobIteration(1);

        rd = rdGateway.getRecord(rd.Id);
        System.assertEquals(rd.npe03__Amount__c * 12, rd.CurrentYearValue__c,
            'Current Year Value should be calculated for the new current year');
        System.assertEquals(rd.npe03__Amount__c * 12, rd.NextYearValue__c,
            'Next Year Value should be calculated for the next year projected installments');
    }

    /**
     * @description The Current Year Value should exclude skipped installments within the current year.
     */
    @IsTest
    private static void shouldUpdateCurrentYearValueToExcludeSkippedInstallments() { 
        final Date startDate = Date.newInstance(2019, 6, 15);
        Date today = startDate.addMonths(1).addDays(-1);
        RD2_ScheduleService.currentDate = today;

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder()
            .withStartDate(startDate)
            .withDateEstablished(startDate)
            .build();
        insert rd;

        insert TEST_OpportunityBuilder.getOpportunityBuilder(rd)
            .withClosedWonStage()
            .withCloseDate(startDate)
            .build();

        //skip three donations
        RD2_ScheduleService_TEST.createPauseSchedule(rd.Id, Date.newInstance(2019, 9, 15), Date.newInstance(2019, 11, 15));

        runBatch(new RD2_OpportunityEvaluation_BATCH(today));

        assertBatchJobIteration(1);

        rd = rdGateway.getRecord(rd.Id);

        System.assertEquals(rd.npe03__Amount__c * 4, rd.CurrentYearValue__c,
            'Current Year Value should exclude skipped installments');
        System.assertEquals(rd.npe03__Amount__c * 12, rd.NextYearValue__c,
            'Next Year Value should include next year projected installments');
    }

    /**
     * @description The Next Year Value should exclude skipped installments within the next year.
     */
    @IsTest
    private static void shouldUpdateNextYearValueToExcludeSkippedInstallments() { 
        final Date startDate = Date.newInstance(2019, 6, 15);
        Date today = startDate.addMonths(1).addDays(-1);
        RD2_ScheduleService.currentDate = today;

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder()
            .withStartDate(startDate)
            .withDateEstablished(startDate)
            .build();
        insert rd;

        insert TEST_OpportunityBuilder.getOpportunityBuilder(rd)
            .withClosedWonStage()
            .withCloseDate(startDate)
            .build();

        //skip Sep 2019 - Feb 2020 donations
        RD2_ScheduleService_TEST.createPauseSchedule(rd.Id, Date.newInstance(2019, 9, 15), Date.newInstance(2020, 2, 15));

        runBatch(new RD2_OpportunityEvaluation_BATCH(today));

        assertBatchJobIteration(1);

        rd = rdGateway.getRecord(rd.Id);

        System.assertEquals(rd.npe03__Amount__c * 3, rd.CurrentYearValue__c,
            'Current Year Value should exclude skipped installments in the current year');
        System.assertEquals(rd.npe03__Amount__c * 10, rd.NextYearValue__c,
            'Next Year Value should exclude skipped installments in the next year');
    }

    /**
    * @description Verifies that a Fixed Length RD stays active when the number of paid installments is less
    * than the number of planned installments..
    */
    @IsTest
    private static void shouldLeaveFixedRDActiveWhenPlannedInstallmentsNotReached() {
        final Integer plannedInstallments = 5;

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder()
            .withRecurringTypeFixed()
            .withPlannedInstallments(plannedInstallments)
            .build();
        insert rd;

        insert TEST_OpportunityBuilder.getOpportunityBuilder(rd)
            .withClosedWonStage()
            .withCloseDate(START_DATE)
            .build();

        // Disable the trigger to ensure the change happens in the batch job vs. the trigger.
        TDTM_ProcessControl.toggleTriggerState('npe03__Recurring_Donation__c', 'RD2_RecurringDonations_TDTM', false);

        rd.npe03__Total_Paid_Installments__c = plannedInstallments-1;
        update rd;

        // Make sure the RD is still Active
        rd = rdGateway.getRecord(rd.Id);
        System.assertEquals(RD2_Constants.STATUS_ACTIVE, rd.Status__c,
            'The Recurring Donation should still be Active');

        runBatch(new RD2_OpportunityEvaluation_BATCH());

        assertBatchJobIteration(1);

        rd = rdGateway.getRecord(rd.Id);
        System.assertEquals(RD2_Constants.STATUS_ACTIVE, rd.Status__c,
            'The Recurring Donation should still be Active');
    }


    /**
    * @description Verifies that a Fixed Length RD is closed when the number of paid installments matches or
    * exceeds the number of planned installments.
    */
    @IsTest
    private static void shouldCloseFixedRDWhenPlannedInstallmentsReached() {
        final Integer plannedInstallments = 5;

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder()
            .withRecurringTypeFixed()
            .withPlannedInstallments(plannedInstallments)
            .build();
        insert rd;

        TEST_OpportunityBuilder oppBuilder = TEST_OpportunityBuilder.getOpportunityBuilder(rd).withClosedWonStage();
        List<Opportunity> opps = new List<Opportunity>();

        for (Integer month = 0; month < plannedInstallments; month++){
            opps.add(oppBuilder
                .withName()
                .withCloseDate(START_DATE.addMonths(month))
                .build());
        }
        insert opps;

        // Disable the trigger to ensure the change happens in the batch job vs. the trigger.
        TDTM_ProcessControl.toggleTriggerState('npe03__Recurring_Donation__c', 'RD2_RecurringDonations_TDTM', false);

        // Make sure the RD is still Active
        rd = rdGateway.getRecord(rd.Id);
        System.assertEquals(RD2_Constants.STATUS_ACTIVE, rd.Status__c,
            'The Recurring Donation should still be Active');

        runBatch(new RD2_OpportunityEvaluation_BATCH());

        assertBatchJobIteration(1);

        rd = rdGateway.getRecord(rd.Id);
        System.assertEquals(plannedInstallments, rd.npe03__Total_Paid_Installments__c,
            'The Number of Paid Installments should be the same as the Number of Planned Installments');
        System.assertEquals(RD2_Constants.STATUS_CLOSED, rd.Status__c,
            'The Recurring Donation should be Closed');
        System.assertEquals(null, rd.npe03__Next_Payment_Date__c,
            'The Next Donation Date should be null');
        System.assertEquals(RD2_Constants.FIXED_TYPE_CLOSED_REASON, rd.ClosedReason__c,
            'The Closed Reason should be set to ' + RD2_Constants.FIXED_TYPE_CLOSED_REASON);
    }

    /**
    * Verifies that no future installment will be created for a fixed length RD
    * when number of open Opps plus closed won Opps equals number of planned installments
    */
    @isTest
    private static void shouldNotCreateNextOppWhenFixedLengthRDReachedPlannedInstallmentCount() {
        final Integer plannedInstallments = 3;
        final Integer paidInstallments = 2;

        final Date startDate = Date.newInstance(2020, 1, 1);
        Date today = Date.newInstance(2020, 3, 1);
        RD2_ScheduleService.currentDate = today;

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        RD2_Settings_TEST.configureForASyncFirstOpportunityCreate();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder()
            .withStartDate(startDate)
            .withDayOfMonth('1')
            .withRecurringTypeFixed()
            .withPlannedInstallments(plannedInstallments)
            .withPaidInstallments(paidInstallments)
            .build();
        insert rd;

        List<Opportunity> opps = new List<Opportunity>();
        TEST_OpportunityBuilder oppBuilder = TEST_OpportunityBuilder.getOpportunityBuilder(rd).withClosedWonStage();
        for (Integer month = 0; month < paidInstallments; month++){
            opps.add(oppBuilder
                .withName()
                .withCloseDate(startDate.addMonths(month))
                .build());
        }
        opps.add(oppBuilder
            .withCloseDate(today.addDays(-1))//An Open Opp matching the Next Donation Date installment
            .withOpenStage()
            .build()
        );
        insert opps;

        runBatch(new RD2_OpportunityEvaluation_BATCH(today));

        assertBatchJobIteration(1);

        List<Opportunity> actualOpps = oppGateway.getRecords(rd);

        System.assertEquals(plannedInstallments, actualOpps.size(),
            'No new installment Opp should be created when: open Opps + paid Opps = planned installments. ' + actualOpps);
    }

    /**
    * @description Verifies that the next installment Opp should be created for a fixed length RD
    * when number of open Opps plus closed won Opps is less than number of planned installments
    */
    @isTest
    private static void shouldCreateNextOppWhenFixedLengthRDHasNotReachedPlannedInstallmentCount() {
        final Integer plannedInstallments = 3;
        final Integer paidInstallments = 2;

        final Date startDate = Date.newInstance(2020, 1, 1);
        Date today = Date.newInstance(2020, 3, 1);
        RD2_ScheduleService.currentDate = today;

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        RD2_Settings_TEST.configureForASyncFirstOpportunityCreate();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder()
            .withStartDate(startDate)
            .withDayOfMonth('1')
            .withRecurringTypeFixed()
            .withPlannedInstallments(plannedInstallments)
            .withPaidInstallments(paidInstallments)
            .build();
        insert rd;

        List<Opportunity> opps = new List<Opportunity>();
        TEST_OpportunityBuilder oppBuilder = TEST_OpportunityBuilder.getOpportunityBuilder(rd).withClosedWonStage();
        for (Integer month = 0; month < paidInstallments; month++){
            opps.add(oppBuilder
                .withName()
                .withCloseDate(startDate.addMonths(month))
                .build());
        }
        opps.add(oppBuilder
            .withClosedLostStage()
            .withCloseDate(today.addDays(-1))//A Closed Lost Opp matching the Next Donation Date installment
            .build()
        );
        insert opps;

        runBatch(new RD2_OpportunityEvaluation_BATCH(today));

        assertBatchJobIteration(1);

        List<Opportunity> actualOpps = oppGateway.getRecords(rd);
        System.assertEquals(plannedInstallments + 1, actualOpps.size(),
            'The next installment Opp should be created since one Opp is Closed Lost: ' + opps);

        Opportunity nextDonationDateOpp = actualOpps[actualOpps.size() - 1];
        System.assertEquals(false, nextDonationDateOpp.IsClosed,
            'The newly created Opp should be open: ' + nextDonationDateOpp);
        System.assertEquals(today.addMonths(1), nextDonationDateOpp.CloseDate,
            'The Next Donation Date should advance and the newly created Opp should match it');
    }

    /**
    * @description Verifies that RD should be Closed Automatically when End Date pass
    */
    @isTest
    private static void shouldCloseOpenRDWhenEndDatePass() {

        Date startDate = Date.newInstance(2020, 1, 1);
        Date endDate = Date.newInstance(2020, 3, 1);
        RD2_ScheduleService.currentDate = startDate;

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder()
            .withStartDate(startDate)
            .withEndDate(endDate)
            .withStatusActive()
            .build();
        insert rd;

        runBatch(new RD2_OpportunityEvaluation_BATCH(endDate.addDays(1)));

        assertBatchJobIteration(1);

        rd = rdGateway.getRecord(rd.Id);
        System.assertEquals(RD2_Constants.STATUS_CLOSED, rd.Status__c, 'RD should be updated to closed when End Date pass');

        for (Opportunity opp : oppGateway.getRecords(rd)) {
            System.assertEquals(true, opp.IsClosed, 'All Opportunities should be closed');
        }
    }


    // Helpers
    //////////////

    /**
     * @description Executes batch
     * @param batch Batch instance
     * @return Exception An Exception generated in the batch (if any)
     */
    private static Exception runBatch(Database.Batchable<SObject> batch) {
        Exception actuaException;
        try {
            Test.startTest();
            Database.executeBatch(batch);
            Test.stopTest();

        } catch (Exception ex) {
            actuaException = ex;
        }
        return actuaException;
    }

    /**
     * @description Executes execute() and finish() methods
     * @param rdId Recurring Donation Id
     * @param today Date representing today
     * @return RD2_OpportunityEvaluation_BATCH Batch instance
     */
    private static RD2_OpportunityEvaluation_BATCH executeAndFinishBatch(Id rdId, Date today) {
        UTIL_BatchJobService_TEST.MockBatchableContext batchContext = new UTIL_BatchJobService_TEST.MockBatchableContext();
        RD2_OpportunityEvaluation_BATCH batch = new RD2_OpportunityEvaluation_BATCH(today);

        batch.execute(batchContext, rdGateway.getRecords(new Set<Id>{ rdId }));
        batch.finish(batchContext);

        return batch;
    }

    /**
     * @description Instantiate an Enhanced RD format recurring donation
     * @return TEST_RecurringDonationBuilder New Recurring Donation builder
     */
    private static TEST_RecurringDonationBuilder getRecurringDonationBuilder() {
        return TEST_RecurringDonationBuilder.constructEnhancedBuilder()
            .withDefaultValues()
            .withDateEstablished(START_DATE)
            .withStartDate(START_DATE)
            .withDayOfMonth('15')
            .withContact(getContact().Id)
            .withAmount(100);
    }

    /****
    * @description Returns contact record
    * @return Contact
    */
    private static Contact getContact() {
        return [
            SELECT FirstName, LastName, AccountId
            FROM Contact
            LIMIT 1
        ];
    }

    /****
    * @description Verifies batch has run
    * @param itemsProcessed Number of batch iterations
    * @return void
    */
    private static void assertBatchJobIteration(Integer itemsProcessed) {
        AsyncApexJob job = jobGateway.getRecord('RD2_OpportunityEvaluation_BATCH');
        System.assertEquals(itemsProcessed, job.JobItemsProcessed, 'The number of batch iteration should match');
    }

    /****
    * @description Verifies records failed
    * @param batch The batch instance
    * @param recordsFailed Records failed
    * @return void
    */
    private static void assertRecordsFailed(RD2_OpportunityEvaluation_BATCH batch, Integer recordsFailed) {
        Integer recordsProcessed = 1;

        System.assertEquals(recordsProcessed, batch.recordsProcessed, 'Records Processed should be tracked');
        System.assertEquals(recordsFailed, batch.recordsFailed, 'Record Failed should match');

        npe03__Recurring_Donations_Settings__c settings = UTIL_CustomSettingsFacade.getRecurringDonationsSettings();
        System.assertEquals(recordsProcessed - recordsFailed, settings.npe03__Number_of_Successes__c,
            'Settings Number of Successes should be updated');
        System.assertEquals(recordsFailed, settings.npe03__Number_of_Failures__c,
            'Settings Number of Failures should be updated');
    }

    /****
    * @description Sets up RD settings with invalid Opp Record Type Id
    * @return void
    */
    private static void configInvalidOppRecordTypeId() {
        RD2_Settings_TEST.setUpConfiguration(new Map<String, Object>{
            'npe03__Record_Type__c' => UTIL_RecordTypes_TEST.MOCK_ID,
            'InstallmentOppFirstCreateMode__c' => RD2_Constants.FirstInstallmentOppCreateOptions.ASynchronous.name()
        });
    }

    /**
    * @description Configure Settings for validating the behavior of the DisableRollupsWhenCreatingInstallments__c
    * setting in the RD Batch Job. Also mocks the CRLP settings for Enhanced Recurring Donations, and
    * disables the internal setting that would normally prevent a null field from being updated to a zero
    * value during rollups. This is used to tell that rollups did or did not run in the batch job.
    */
    public static void configureForBatchJobWithRollupDisableTests(Boolean isDisableRollups) {

        UTIL_CustomSettingsFacade.getRollupSettingsForTests(new Customizable_Rollup_Settings__c (
            Customizable_Rollups_Enabled__c = true
        ));
        CMT_UnitTestData_TEST.mockEnhancedRecurringDonationRollupCMTValues();
        CRLP_Rollup_SVC.UPDATE_NULL_TO_ZERO = true;

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        RD2_Settings_TEST.setUpConfiguration(new Map<String, Object>{
            'DisableRollupsWhenCreatingInstallments__c' => isDisableRollups
        });
    }

    /**
    * @description Create a single Enhanced Recurring Donation to use for validating
    * the behavior of the DisableRollupsWhenCreatingInstallments__c setting in the RD Batch Job.
    * Triggers are disabled to prevent an installment opp from being created since that is what we want to
    * test in the batch job logic. However, the schedule records still need to be created
    * @return Created Recurring Donation Record
    */
    private static npe03__Recurring_Donation__c createTestDataForRollupRecalcTest() {
        npe03__Recurring_Donation__c rd = TEST_RecurringDonationBuilder.constructEnhancedBuilder()
            .withContact(getContact().Id)
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
        Database.insert(scheduleService.buildNewSchedules(rd));

        System.assertEquals(0, [SELECT Count() FROM Opportunity WHERE npe03__Recurring_Donation__c = :rd.Id],
            'There should be no installment Opportunities created for this RD');
        System.assertEquals(1, [SELECT Count() FROM RecurringDonationSchedule__c WHERE RecurringDonation__c = :rd.Id],
            'There should be 1 RD Schedule record created for this RD');
        System.assertEquals(null, rd.npe03__Paid_Amount__c, 'The PaidAmount field should be null instead of zero');

        return rdGateway.getRecord(rd.Id);
    }
}