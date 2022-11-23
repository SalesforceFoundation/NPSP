/*
    Copyright (c) 2020 Salesforce.org
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
* @date 2020
* @group Recurring Donations
* @description Unit tests for the Pause Recurring Donation feature
*
*/
@IsTest(IsParallel=false)
public with sharing class RD2_PauseForm_TEST {

    private static final TEST_SObjectGateway.RecurringDonationGateway rdGateway = new TEST_SObjectGateway.RecurringDonationGateway();
    private static final TEST_SObjectGateway.RecurringDonationScheduleGateway scheduleGateway = new TEST_SObjectGateway.RecurringDonationScheduleGateway();
    private static final TEST_SObjectGateway.OpportunityGateway oppGateway = new TEST_SObjectGateway.OpportunityGateway();

    private static final Integer DAY_OF_MONTH = 15;
    private static final Date START_DATE = Date.newInstance(2019, 3, DAY_OF_MONTH);
    private static final String PAYMENT_CHECK = 'Check';
    private static final Integer MAX_ROW_DISPLAY = 12;
    private static final String PAUSED_REASON_VALUE = 'Financial Difficulty';

    /****
    * @description Creates data required for unit tests
    */
    @TestSetup
    private static void setUp() {
        RD2_ScheduleService.currentDate = START_DATE;
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        Contact contact = UTIL_UnitTestData_TEST.getContact();
        insert contact;

        insert getRecurringDonationBuilder(contact.Id)
            .withCalculateNextDonationDate()
            .build();
    }

    /****
    * @description Verifies Pause Data contains property indicating the Recurring Donation is not closed
    */
    @isTest
    private static void shouldReturnPauseDataWhenRDIsNotClosed() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        RD2_PauseForm_CTRL.PauseData pause = getPauseData(rdGateway.getRecords()[0].Id);
        System.assertEquals(false, pause.isRDClosed, 'The Recurring Donation should not be closed');
        System.assertEquals(true, pause.hasAccess, 'The user should have access');

        System.assertNotEquals(null, pause.pausedReason, 'The Paused Reason should be initialized');
        System.assertEquals(System.Label.RD2_PausedReasonLabel, pause.pausedReason.label,
            'The Paused Reason label should match');
        System.assertNotEquals(null, pause.pausedReason.options,
            'The Paused Reason options should be retrieved');
        System.assertEquals(System.Label.commonSelectOptionPlaceholder, pause.pausedReason.placeholder,
            'The Paused Reason label should match');
        System.assertEquals(null, pause.pausedReason.value,
            'The Paused Reason value should be empty when no pause exists on the RD');
    }

    /****
    * @description Verifies Pause Data contains property indicating the Recurring Donation is closed
    */
    @isTest
    private static void shouldReturnOnlyRequiredPauseDataWhenRDIsClosed() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder()
            .withStatusClosed()
            .build();
        insert rd;

        RD2_PauseForm_CTRL.PauseData pause = getPauseData(rd.Id);
        System.assertEquals(true, pause.isRDClosed, 'The Recurring Donation should be closed');
        System.assertEquals(true, pause.hasAccess, 'The user should have access');
        System.assertEquals(null, pause.pausedReason, 'The Paused Reason should not be initialized for a closed RD');
    }

    /****
    * @description Verifies full Pause Data is not returned when user does not have Create and Edit
    * permissions on the Recurring Donation SObject
    */
    @isTest
    private static void shouldNotReturnPauseDataWhenUserDoesNotHaveCreateAndEditPermissions() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        RD2_ScheduleService.currentDate = START_DATE;

        npe03__Recurring_Donation__c rd = rdGateway.getRecords()[0];
        RecurringDonationSchedule__c pauseSchedule = createPauseSchedule(rd.Id);

        User readOnlyUser = UTIL_UnitTestData_TEST.createUser(UTIL_UnitTestData_TEST.PROFILE_READONLY_USER);
        System.runAs(readOnlyUser) {
            RD2_ScheduleService.currentDate = pauseSchedule.StartDate__c.addDays(1);

            RD2_PauseForm_CTRL.PauseData pause = getPauseData(rd.Id);
            System.assertEquals(false, pause.hasAccess, 'The user should not have access: ' + pause);
            System.assertEquals(null, pause.isRDClosed, 'The Recurring Donation closed status should not be specified');
            System.assertEquals(null, pause.startDate, 'The Pause Start Date should not be set');
            System.assertEquals(null, pause.resumeAfterDate, 'The Pause Resume After Date should not be set');
            System.assertEquals(null, pause.pausedReason, 'The Paused Reason should not be initialized');
        }
    }

    /****
    * @description Verifies the pause on Recurring Donation is saved
    */
    @isTest
    private static void shouldSavePause() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        RD2_ScheduleService.currentDate = START_DATE.addDays(1);

        npe03__Recurring_Donation__c rd = rdGateway.getRecords()[0];

        Integer totalSkipped = 4;
        Test.startTest();
        Date pauseStartDate = START_DATE.addMonths(3);
        Date pauseEndDate = START_DATE.addMonths(6);
        RD2_PauseForm_CTRL.PauseData pause = savePauseOnTheForm(rd.Id, pauseStartDate, pauseEndDate);
        Test.stopTest();

        List<RecurringDonationSchedule__c> pauseSchedules = getPauseSchedules(rd);
        System.assertEquals(1, pauseSchedules.size(), 'There should be one pause schedule');
        assertPauseSchedule(pause, pauseSchedules[0]);

        Date nextDonationDate = START_DATE.addMonths(1);
        assertNextDonationDateAndYearValues(rd.Id, totalSkipped, nextDonationDate);
    }

    @IsTest
    private static void shouldSavePauseWhenRDIsElevateRecord() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        RD2_ElevateIntegrationService_TEST.enableElevateUserPermissions();
        PS_IntegrationService.setConfiguration(PS_IntegrationServiceConfig_TEST.testConfig);

        npe03__Recurring_Donation__c recurringDonation = rdGateway.getRecords()[0];
        recurringDonation.CommitmentId__c = 'TEST COMMITMENT';
        recurringDonation.PaymentMethod__c = RD2_Constants.PAYMENT_PICKLIST_VALUE_CARD;
        update recurringDonation;

        RD2_PauseForm_CTRL.PauseData pause = new RD2_PauseForm_CTRL.PauseData();
        pause.rdId = recurringDonation.Id;
        pause.startDate = START_DATE.addMonths(3);
        pause.resumeAfterDate = START_DATE.addMonths(6);
        pause.pausedReason = new RD2_PauseForm_CTRL.PausedReason();
        pause.pausedReason.value = 'Unknown';

        Test.startTest();

        mockRecordCreatedCalloutResponse();

        Exception auraEx;

        try {
            RD2_PauseForm_CTRL.savePause(JSON.serialize(pause));
        } catch (Exception ex) {
            auraEx = ex;
        }

        Test.stopTest();

        RecurringDonationSchedule__c schedule = [SELECT Id FROM RecurringDonationSchedule__c][0];
        System.assertEquals(null, auraEx, 'No exception was thrown as a result of the callout');
        System.assertNotEquals(null, schedule, 'The Commitment response should be returned');
    }


    @IsTest
    private static void shouldThrowExceptionWhenPauseStartDateIsOnedayFromNextInstallment() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        RD2_ElevateIntegrationService_TEST.enableElevateUserPermissions();
        PS_IntegrationService.setConfiguration(PS_IntegrationServiceConfig_TEST.testConfig);
        RD2_PauseForm_CTRL.currentDate = START_DATE.addDays(-1);
        npe03__Recurring_Donation__c recurringDonation = rdGateway.getRecords()[0];
        recurringDonation.CommitmentId__c = 'TEST COMMITMENT';
        recurringDonation.PaymentMethod__c = RD2_Constants.PAYMENT_PICKLIST_VALUE_CARD;
        update recurringDonation;

        RD2_PauseForm_CTRL.PauseData pause = new RD2_PauseForm_CTRL.PauseData();
        pause.rdId = recurringDonation.Id;
        pause.startDate = START_DATE;
        pause.resumeAfterDate = pause.startDate.addMonths(6);
        pause.pausedReason = new RD2_PauseForm_CTRL.PausedReason();
        pause.pausedReason.value = 'Unknown';

        Test.startTest();

        mockRecordCreatedCalloutResponse();

        Exception auraEx;

        try {
            RD2_PauseForm_CTRL.savePause(JSON.serialize(pause));
        } catch (Exception ex) {
            auraEx = ex;

        }

        Test.stopTest();

        System.assertEquals(System.Label.RD2_ElevatePauseInstallmentDateErrorMessage,
            auraEx.getMessage(), 'An exception should be thrown');

    }


    @IsTest
    private static void shouldSavePauseWhenRDIsElevateRecordAndPauseIsRemoved() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        RD2_ElevateIntegrationService_TEST.enableElevateUserPermissions();
        PS_IntegrationService.setConfiguration(PS_IntegrationServiceConfig_TEST.testConfig);

        npe03__Recurring_Donation__c recurringDonation = rdGateway.getRecords()[0];
        recurringDonation.CommitmentId__c = 'TEST COMMITMENT';
        recurringDonation.PaymentMethod__c = RD2_Constants.PAYMENT_PICKLIST_VALUE_CARD;
        update recurringDonation;

        RD2_PauseForm_CTRL.PauseData pause = new RD2_PauseForm_CTRL.PauseData();
        pause.rdId = recurringDonation.Id;
        pause.startDate = null;
        pause.resumeAfterDate = null;
        pause.pausedReason = new RD2_PauseForm_CTRL.PausedReason();
        pause.pausedReason.value = 'Unknown';

        Test.startTest();

        UTIL_Http_TEST.mockNoContentCalloutResponse();

        Exception auraEx;

        try {
            RD2_PauseForm_CTRL.savePause(JSON.serialize(pause));
        } catch (Exception ex) {
            auraEx = ex;
        }

        Test.stopTest();

        RecurringDonationSchedule__c schedule = [SELECT Id, EndDate__c FROM RecurringDonationSchedule__c][0];
        System.assertEquals(null, auraEx, 'No exception was thrown as a result of the callout');
        System.assertNotEquals(null, schedule, 'The Commitment response should be returned');
        System.assertEquals(START_DATE.addDays(-1), schedule.EndDate__c, 'The End Date should be backdated');
    }

    private static void mockRecordCreatedCalloutResponse() {
        UTIL_Http_TEST.mockRecordCreatedCalloutResponse(mockSuccessResponseBody());
    }


    private static String mockSuccessResponseBody() {
        return '{' +
            '"startTimestamp":"' + System.today()  +'",' +
            '"endTimestamp":"' + System.today().addDays(5) + '",' +
            '"reason":"' + PAUSED_REASON_VALUE +
            '"}' ;
    }

    /****
    * @description Verifies the existing pause is deactivated when a new one is created
    */
    @isTest
    private static void shouldDeactivateExistingPauseWhenANewOneIsCreated() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        npe03__Recurring_Donation__c rd = rdGateway.getRecords()[0];

        RecurringDonationSchedule__c existingPause = createPauseSchedule(rd.Id);

        final Date today = existingPause.StartDate__c.addMonths(1).addDays(1);
        RD2_ScheduleService.currentDate = today;

        //Extend the pause for the next two months
        Integer totalSkipped = 4;
        Test.startTest();
        Date pauseStartDate = existingPause.StartDate__c.addMonths(2);
        Date pauseEndDate = existingPause.EndDate__c.addMonths(2);
        RD2_PauseForm_CTRL.PauseData pause = savePauseOnTheForm(rd.Id, pauseStartDate, pauseEndDate);
        Test.stopTest();

        Map<Id, RecurringDonationSchedule__c> pauseScheduleById = new Map<Id, RecurringDonationSchedule__c>(getPauseSchedules(rd));
        System.assertEquals(2, pauseScheduleById.size(), 'There should be one decativated and one new pause schedule');

        existingPause = pauseScheduleById.remove(existingPause.Id);
        System.assertEquals(today.addDays(-1), existingPause.EndDate__c,
            'Existing pause schedule End Date should be yesterday');

        assertPauseSchedule(pause, pauseScheduleById.values()[0]);

        Date nextDonationDate = pause.resumeAfterDate.addMonths(1);
        assertNextDonationDateAndYearValues(rd.Id, totalSkipped, nextDonationDate);
    }

    /****
    * @description Verifies the existing pause is deactivated
    * and no new pause schedule created when passed in data does not have
    * Start and End Date set.
    */
    @isTest
    private static void shouldDeactivateExistingPauseWhenUserDeselectsAllInstallments() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        npe03__Recurring_Donation__c rd = rdGateway.getRecords()[0];

        RecurringDonationSchedule__c existingPause = createPauseSchedule(rd.Id);

        final Date today = existingPause.StartDate__c.addMonths(1).addDays(1);
        RD2_ScheduleService.currentDate = today;

        // Pass in PauseData without setting Start and End Dates since
        // no installment is selected and the current pause is deactivated.
        Test.startTest();
        Date pauseStartDate = null;
        Date pauseEndDate = null;
        savePauseOnTheForm(rd.Id, pauseStartDate, pauseEndDate);
        Test.stopTest();

        Map<Id, RecurringDonationSchedule__c> pauseScheduleById = new Map<Id, RecurringDonationSchedule__c>(getPauseSchedules(rd));
        System.assertEquals(1, pauseScheduleById.size(), 'No new schedule should be created');

        existingPause = pauseScheduleById.remove(existingPause.Id);
        System.assertEquals(today.addDays(-1), existingPause.EndDate__c,
            'Existing pause schedule End Date should be yesterday');

        Integer totalSkipped = 0;
        Date nextDonationDate = Date.newInstance(today.year(), today.month() + 1, DAY_OF_MONTH);
        assertNextDonationDateAndYearValues(rd.Id, totalSkipped, nextDonationDate);
    }

    /****
    * @description Verifies the the existing Opp Close Date is updated to the Next Donation Date
    * when the new Pause Schedule date range includes the Opp Close Date
    */
    @isTest
    private static void shouldUpdateOppCloseDateToNewNextDonationDateWhenWithinPauseDateRange() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        RD2_ScheduleService.currentDate = START_DATE.addDays(1);
        Date nextDonationDate = START_DATE.addMonths(1);

        npe03__Recurring_Donation__c rd = rdGateway.getRecords()[0];

        Opportunity nextDonationOpp = TEST_OpportunityBuilder.getOpportunityBuilder(rd)
            .withOpenStage()
            .withCloseDate(nextDonationDate)
            .build();
        insert nextDonationOpp;

        Integer oppCount = 2;
        Integer totalSkipped = 3;

        Test.startTest();
        savePauseOnTheForm(rd.Id, nextDonationDate, nextDonationDate.addMonths(2));
        Test.stopTest();

        rd = rdGateway.getRecords()[0];

        nextDonationDate = nextDonationDate.addMonths(totalSkipped);
        assertNextDonationDateAndYearValues(rd.Id, totalSkipped, nextDonationDate);
        
        Map<Id, Opportunity> oppById = new Map<Id, Opportunity>(oppGateway.getRecords(rd));
        System.assertEquals(oppCount, oppById.size(),
            'No new Opp should be created: ' + oppById.values());
        System.assertEquals(nextDonationDate, oppById.get(nextDonationOpp.Id).CloseDate, 
            'Close Date on the open Opp should be changed to the new Next Donation Date');
    }

    /****
    * @description Verifies the pause schedule is not returned when
    * its End Date is passed
    */
    @isTest
    private static void shouldNotReturnPauseScheduleIdWhenPauseHasEnded() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        npe03__Recurring_Donation__c rd = rdGateway.getRecords()[0];

        RecurringDonationSchedule__c existingPause = createPauseSchedule(rd.Id);

        RD2_ScheduleService.currentDate = existingPause.EndDate__c;
        RD2_PauseForm_CTRL.PauseData pause = getPauseData(rd.Id);
        System.assertEquals(existingPause.Id, pause.scheduleId, 'The pause schedule should be returned on its End Date');
        System.assertEquals(existingPause.Statusreason__c, pause.pausedReason.value, 'Paused Reason should be specified');

        RD2_ScheduleService.currentDate = existingPause.EndDate__c.addDays(1);
        pause = getPauseData(rd.Id);
        System.assertEquals(null, pause.scheduleId, 'No pause schedule should be returned passed its End Date');
        System.assertEquals(null, pause.pausedReason.value, 'Paused Reason should not have value');
    }

    /****
    * @description Verifies installments are returned and not skipped for the Recurring Donation
    * not having any pause created for it
    */
    @isTest
    private static void shouldNotSkipInstallmentsWhenPauseDoesNotExist() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        RD2_ScheduleService.currentDate = START_DATE;

        Id rdId = rdGateway.getRecords()[0].Id;
        List<RD2_VisualizeScheduleController.Installment> installments = getInstallments(rdId);
        System.assertEquals(MAX_ROW_DISPLAY, installments.size(), 'Number of installments should match');

        for (RD2_VisualizeScheduleController.Installment installment : installments) {
            System.assertEquals(false, installment.isSkipped,
                'No installment should be skipped when no pause exists');
        }
    }

    /****
    * @description Verifies installments within the active future pause Start and End Dates are skipped
    */
    @isTest
    private static void shouldSkipInstallmentsWithinFuturePauseStartAndEndDates() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        RD2_ScheduleService.currentDate = START_DATE.addDays(1);

        npe03__Recurring_Donation__c rd = rdGateway.getRecords()[0];
        RecurringDonationSchedule__c existingPause = createPauseSchedule(rd.Id);

        Integer isSkippedCounter = 0;
        for (RD2_VisualizeScheduleController.Installment installment : getInstallments(rd.Id)) {

            Boolean isSkipped = existingPause.StartDate__c <= installment.donationDate
                && installment.donationDate <= existingPause.EndDate__c;

            System.assertEquals(isSkipped, installment.isSkipped,
                'Installment isSkipped flag should match: ' + installment);

            if (isSkipped) {
                isSkippedCounter++;
            }
        }

        System.assertEquals(4, isSkippedCounter, 'Number of skipped installments should match');
    }

    /****
    * @description Verifies installments within the active current pause Start and End Dates are skipped
    */
    @isTest
    private static void shouldSkipInstallmentsWithinCurrentPauseStartAndEndDates() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        RD2_ScheduleService.currentDate = START_DATE.addDays(1);

        npe03__Recurring_Donation__c rd = rdGateway.getRecords()[0];
        RecurringDonationSchedule__c existingPause = createPauseSchedule(rd.Id);

        RD2_ScheduleService.currentDate = existingPause.StartDate__c.addDays(1);

        Integer isSkippedCounter = 0;
        for (RD2_VisualizeScheduleController.Installment installment : getInstallments(rd.Id)) {

            Boolean isSkipped = existingPause.StartDate__c <= installment.donationDate
                && installment.donationDate <= existingPause.EndDate__c;

            System.assertEquals(isSkipped, installment.isSkipped,
                'Installment isSkipped flag should match: ' + installment);

            if (isSkipped) {
                isSkippedCounter++;
            }
        }

        System.assertEquals(3, isSkippedCounter, 'Number of skipped installments should match');
    }

    /****
    * @description Verifies installments are not skipped when an active current pause is deactivated
    */
    @isTest
    private static void shouldNotSkipInstallmentsAfterDateThePauseIsDeactivated() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        RD2_ScheduleService.currentDate = START_DATE.addDays(1);

        npe03__Recurring_Donation__c rd = rdGateway.getRecords()[0];
        RecurringDonationSchedule__c existingPause = createPauseSchedule(rd.Id);

        // the pause has started and one installment is skipped
        final Date today = existingPause.StartDate__c.addDays(1);
        RD2_ScheduleService.currentDate = today;

        //Deactivate the current Pause
        Test.startTest();
        RD2_PauseForm_CTRL.PauseData pause = new RD2_PauseForm_CTRL.PauseData();
        pause.rdId = rd.Id;
        pause.startDate = null;
        pause.resumeAfterDate = null;
        RD2_PauseForm_CTRL.savePause(JSON.serialize(pause));
        Test.stopTest();

        for (RD2_VisualizeScheduleController.Installment installment : getInstallments(rd.Id)) {
            System.assertEquals(false, installment.isSkipped,
                'No installment should be skipped when the pause is deactivated');
        }

        Integer totalSkipped = 0;
        Date nextDonationDate = Date.newInstance(today.year(), today.month() + 1, DAY_OF_MONTH);
        assertNextDonationDateAndYearValues(rd.Id, totalSkipped, nextDonationDate);
    }

    /****
    * @description Verifies installments are not skipped when the pause is completed
    */
    @isTest
    private static void shouldNotSkipInstallmentsWhenPauseHasEnded() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        RD2_ScheduleService.currentDate = START_DATE.addDays(1);

        npe03__Recurring_Donation__c rd = rdGateway.getRecords()[0];
        RecurringDonationSchedule__c existingPause = createPauseSchedule(rd.Id);

        RD2_ScheduleService.currentDate = existingPause.EndDate__c.addDays(1);

        for (RD2_VisualizeScheduleController.Installment installment : getInstallments(rd.Id)) {
            System.assertEquals(false, installment.isSkipped,
                'No installment should be skipped when the pause is passed');
        }
    }

    /****
    * @description Verifies the error generated when no installments is returned
    * is propagated to the calling method.
    */
    @isTest
    private static void shouldPropagateExceptionGeneratedWhenNoInstallmentIsReturned() {
        Exception actualException;

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        RD2_ScheduleService.currentDate = START_DATE.addDays(-1);
        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder()
            .withRecurringTypeFixed()
            .withPlannedInstallments(1)
            .build();
        insert rd;

        RD2_ScheduleService.currentDate = START_DATE.addDays(1);
        try {
            RD2_PauseForm_CTRL.getInstallments(rd.Id, MAX_ROW_DISPLAY);

        } catch (Exception e) {
            actualException = e;
        }

        System.assertNotEquals(null, actualException,
            'Exception should be generated when no installment is returned');
        System.assertEquals(System.Label.RD2_ScheduleVisualizerMessageNoSchedule, actualException.getMessage(),
            'Exception message should match');
    }

    /****
    * @description Verifies Pause Data contains property indicating the Recurring Donation is not an elevated record
    */
    @isTest
    private static void shouldReturnPauseDataWhenRDIsNotElevateRecord() {
        RD2_ElevateIntegrationService_TEST.enableElevateUserPermissions();
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        RD2_PauseForm_CTRL.PauseData pause = getPauseData(rdGateway.getRecords()[0].Id);
        System.assertEquals(false, pause.isElevateRecord, 'The Recurring Donation should not be a elevate record');
        System.assertEquals(true, pause.hasAccess, 'The user should have access');

        System.assertNotEquals(null, pause.pausedReason, 'The Paused Reason should be initialized');
        System.assertEquals(System.Label.RD2_PausedReasonLabel, pause.pausedReason.label,
            'The Paused Reason label should match');
        System.assertNotEquals(null, pause.pausedReason.options,
            'The Paused Reason options should be retrieved');
        System.assertEquals(System.Label.commonSelectOptionPlaceholder, pause.pausedReason.placeholder,
            'The Paused Reason label should match');
        System.assertEquals(null, pause.pausedReason.value,
            'The Paused Reason value should be empty when no pause exists on the RD');
    }

    /****
    * @description Verifies Pause Data contains property indicating the Recurring Donation is an elevated record
    */
    @isTest
    private static void shouldReturnPauseDataForRdWithCommitmentIdWhenElevateIsNotEnabled() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = rdGateway.getRecords()[0];
        rd.CommitmentId__c = 'TEST COMMITMENT';
        update rd;

        RD2_PauseForm_CTRL.PauseData pause = getPauseData(rd.Id);

        System.assertEquals(false, pause.isElevateRecord, 'The Recurring Donation should not be a elevate record');
        System.assertEquals(true, pause.hasAccess, 'The user should have access');

        System.assertNotEquals(null, pause.pausedReason, 'The Paused Reason should be initialized');
        System.assertEquals(System.Label.RD2_PausedReasonLabel, pause.pausedReason.label,
            'The Paused Reason label should match');
        System.assertNotEquals(null, pause.pausedReason.options,
            'The Paused Reason options should be retrieved');
        System.assertEquals(System.Label.commonSelectOptionPlaceholder, pause.pausedReason.placeholder,
            'The Paused Reason label should match');
        System.assertEquals(null, pause.pausedReason.value,
            'The Paused Reason value should be empty when no pause exists on the RD');
    }

    /***
    * @description Verifies the open Opp Close Date is correctly updated when
    * the RD has a current/future closed Opp and a future open Opp
    * and the Pause is modified
    */
    @isTest
    private static void shouldUpdateOpenOppCloseDateWhenPauseIsModified() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        RD2_ScheduleService.currentDate = START_DATE;

        Test.startTest();

        npe03__Recurring_Donation__c rd = rdGateway.getRecords()[0];

        //skip second and third installments
        Date pauseStartDate = START_DATE.addMonths(1);
        Date pauseEndDate = pauseStartDate.addMonths(1);
        RD2_ScheduleService_TEST.createPauseSchedule(rd.Id, pauseStartDate, pauseEndDate);

        //Close the first Opp and create an open Opp after the pause ends
        List<Opportunity> opps = oppGateway.getRecords(rd);
        System.assertEquals(1, opps.size(), 'One Opp should exist: ' + opps);
        opps[0].StageName = UTIL_UnitTestData_TEST.getClosedWonStage();
        update opps[0];

        Opportunity openOpp = TEST_OpportunityBuilder.getOpportunityBuilder(rd)
            .withCloseDate(pauseEndDate.addMonths(1))
            .withOpenStage()
            .build();
        insert openOpp;

        opps = oppGateway.getRecords(rd);
        System.assertEquals(2, opps.size(), 'Number of expected Opps should match: ' + opps);

        //deselect the third installment and keep the second as paused
        savePauseOnTheForm(rd.Id, pauseStartDate, pauseStartDate);
        Test.stopTest();

        rd = rdGateway.getRecord(rd.Id);
        Date nextDonationDate = pauseStartDate.addMonths(1);
        System.assertEquals(nextDonationDate, rd.npe03__Next_Payment_Date__c, 
            'Next Donation Date should be the first installment after the pause');

        Map<Id, Opportunity> oppById = new Map<Id, Opportunity>(oppGateway.getRecords(rd));
        System.assertEquals(2, oppById.size(),
            'Number of expected Opps should match: ' + oppById.values());
        System.assertEquals(nextDonationDate, oppById.get(openOpp.Id).CloseDate, 
            'Close Date on the open Opp should be changed to the new Next Donation Date');
    }

    /***
    * @description Verifies the open Opp Close Date is correctly updated when
    * the RD has a current/future closed Opp and a future open Opp
    * and the Pause is deactivated
    */
    @isTest
    private static void shouldUpdateOpenOppCloseDateWhenPauseIsDeactivated() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        RD2_ScheduleService.currentDate = START_DATE;

        Test.startTest();

        npe03__Recurring_Donation__c rd = rdGateway.getRecords()[0];

        //skip second and third installments
        Date pauseStartDate = START_DATE.addMonths(1);
        Date pauseEndDate = pauseStartDate.addMonths(1);
        RD2_ScheduleService_TEST.createPauseSchedule(rd.Id, pauseStartDate, pauseEndDate);

        //Close the first Opp and create an open Opp after the pause ends
        List<Opportunity> opps = oppGateway.getRecords(rd);
        System.assertEquals(1, opps.size(), 'One Opp should exist: ' + opps);
        opps[0].StageName = UTIL_UnitTestData_TEST.getClosedWonStage();
        update opps[0];

        Opportunity openOpp = TEST_OpportunityBuilder.getOpportunityBuilder(rd)
            .withCloseDate(pauseEndDate.addMonths(1))
            .withOpenStage()
            .build();
        insert openOpp;

        opps = oppGateway.getRecords(rd);
        System.assertEquals(2, opps.size(), 'Number of expected Opps should match: ' + opps);

        //deactivate the current pause
        pauseStartDate = null;
        pauseEndDate = null;
        savePauseOnTheForm(rd.Id, pauseStartDate, pauseStartDate);
        Test.stopTest();

        rd = rdGateway.getRecord(rd.Id);
        Date nextDonationDate = START_DATE.addMonths(1);
        System.assertEquals(nextDonationDate, rd.npe03__Next_Payment_Date__c, 
            'Next Donation Date should be the second installment date');

        Map<Id, Opportunity> oppById = new Map<Id, Opportunity>(oppGateway.getRecords(rd));
        System.assertEquals(2, oppById.size(),
            'Number of expected Opps should match: ' + oppById.values());
        System.assertEquals(nextDonationDate, oppById.get(openOpp.Id).CloseDate, 
            'Close Date on the open Opp should be changed to the new Next Donation Date');
    }





    //Helpers
    /////////////

    /**
     * @description Saves the pause
     * @param rdId Recurring Donation Id
     * @param pauseStartDate Pause Start Date
     * @param pauseEndDate Pause End Date
     * @return RD2_PauseForm_CTRL.PauseData
     */
    private static RD2_PauseForm_CTRL.PauseData savePauseOnTheForm(Id rdId, Date pauseStartDate, Date pauseEndDate) {
        RD2_PauseForm_CTRL.PauseData pause = new RD2_PauseForm_CTRL.PauseData();
        pause.rdId = rdId;
        pause.startDate = pauseStartDate;
        pause.resumeAfterDate = pauseEndDate;
        pause.pausedReason = new RD2_PauseForm_CTRL.PausedReason();
        pause.pausedReason.value = PAUSED_REASON_VALUE;

        RD2_QueueableService.alreadyEnqueuedIds = null;
        RD2_PauseForm_CTRL.savePause(JSON.serialize(pause));

        return pause;
    }

    /**
     * @description Retrieves pause data
     * @param rdId Recurring Donation Id
     * @return RD2_PauseForm_CTRL.PauseData
     */
    private static RD2_PauseForm_CTRL.PauseData getPauseData(Id rdId) {
        String jsonPause = RD2_PauseForm_CTRL.getPauseData(rdId);
        return (RD2_PauseForm_CTRL.PauseData) JSON.deserialize(jsonPause, RD2_PauseForm_CTRL.PauseData.class);
    }

    /**
     * @description Retrieves active and inactive pause schedules
     * @param rdId Recurring Donation Id
     * @return RecurringDonationSchedule__c
     */
    private static List<RecurringDonationSchedule__c> getPauseSchedules(npe03__Recurring_Donation__c rd) {
        List<RecurringDonationSchedule__c> pauseSchedules = new List<RecurringDonationSchedule__c>();

        for (RecurringDonationSchedule__c schedule : scheduleGateway.getRecords(rd)) {
            if (schedule.IsPause__c) {
                pauseSchedules.add(schedule);
            }
        }
        return pauseSchedules;
    }

    /**
     * @description Asserts the pause schedule has expected values
     * @param pause Expected PauseData
     * @param schedule Actual schedule
     * @return void
     */
    private static void assertPauseSchedule(RD2_PauseForm_CTRL.PauseData pause, RecurringDonationSchedule__c schedule) {
        System.assertEquals(true, schedule.IsPause__c, 'Pause Schedule Start Date should match');
        System.assertEquals(pause.startDate, schedule.StartDate__c, 'Pause Schedule Start Date should match');
        System.assertEquals(pause.resumeAfterDate, schedule.EndDate__c, 'Pause Schedule End Date should match');
        System.assertEquals(pause.pausedReason.value, schedule.StatusReason__c, 'Paused Reason should be saved');
    }

    /**
     * @description Creates test pause schedule
     * @param rdId Recurring Donation Id
     * @return RecurringDonationSchedule__c
     */
    private static RecurringDonationSchedule__c createPauseSchedule(Id rdId) {
        return RD2_ScheduleService_TEST.createPauseSchedule(rdId, START_DATE.addMonths(3), START_DATE.addMonths(6));
    }

    /**
     * @description Retrieves installments
     * @param rdId Recurring Donation Id
     * @return List<RD2_VisualizeScheduleController.Installment>
     */
    private static List<RD2_VisualizeScheduleController.Installment> getInstallments(Id rdId) {
        Map<String, Object> datatableByKey = RD2_PauseForm_CTRL.getInstallments(rdId, MAX_ROW_DISPLAY);

        System.assertEquals(1, datatableByKey.size(), 'Installments should be returned');

        RD2_VisualizeScheduleController.DataTable dataTable =
            (RD2_VisualizeScheduleController.DataTable) datatableByKey.values()[0];

        List<RD2_VisualizeScheduleController.Installment> installments = new List<RD2_VisualizeScheduleController.Installment>();
        for (Object record : dataTable.getRecords()) {
            installments.add((RD2_VisualizeScheduleController.Installment) record);
        }

        System.assertEquals(MAX_ROW_DISPLAY, installments.size(), 'Number of installments should match');

        return installments;
    }

    /**
     * @description Build open Recurring Donation
     * @return TEST_RecurringDonationBuilder instance
     */
    private static TEST_RecurringDonationBuilder getRecurringDonationBuilder() {
        return getRecurringDonationBuilder(getContact().Id);
    }

    /**
     * @description Base common Recurring Donation record
     * @param contactId Contact Id
     * @return TEST_RecurringDonationBuilder instance
     */
    private static TEST_RecurringDonationBuilder getRecurringDonationBuilder(Id contactId) {
        return TEST_RecurringDonationBuilder.constructEnhancedBuilder()
            .withDefaultValues()
            .withContact(contactId)
            .withAmount(100)
            .withPaymentMethod(PAYMENT_CHECK)
            .withDateEstablished(START_DATE)
            .withStartDate(START_DATE);
    }

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

    /****
    * @description Verifies Current/Next Year Value fields on the Recurring Donation
    * @param rdId Recurring Donation Id
    * @param totalSkipped Number of skipped installments
    * @param nextDonationDate The expected Next Donation Date
    * @return void
    */
    private static void assertNextDonationDateAndYearValues(Id rdId, Integer totalSkipped, Date nextDonationDate) {
        final Date today = RD2_ScheduleService.currentDate;
        npe03__Recurring_Donation__c rd = rdGateway.getRecord(rdId);

        Integer projectedMonths = today.monthsBetween(
            Date.newInstance(today.year(), 12, DAY_OF_MONTH)
        );

        System.assertEquals(rd.npe03__Amount__c * (1 + projectedMonths - totalSkipped), rd.CurrentYearValue__c,
            'Current Year Value should include current year Opp and active projected installments: ' + getInstallments(rdId));
        System.assertEquals(rd.npe03__Amount__c * 12, rd.NextYearValue__c,
            'Next Year Value should include next year projected installments');

        System.assertEquals(nextDonationDate, rd.npe03__Next_Payment_Date__c, 
            'Next Donation Date should be in future from today: ' + today);
    }

}