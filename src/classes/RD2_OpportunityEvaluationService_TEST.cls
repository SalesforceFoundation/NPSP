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
@IsTest(IsParallel=false)
private class RD2_OpportunityEvaluationService_TEST {

    private static final TEST_SObjectGateway.RecurringDonationGateway rdGateway = new TEST_SObjectGateway.RecurringDonationGateway();
    private static final TEST_SObjectGateway.OpportunityGateway oppGateway = new TEST_SObjectGateway.OpportunityGateway();
    private static final TEST_SObjectGateway.ErrorGateway errorGateway = new TEST_SObjectGateway.ErrorGateway();

    /***
    * @description Installment Opportunities Auto Creation Setting API value
    */
    private static final String OPTION_NAME_DISABLE_FIRST = RD2_Constants.InstallmentCreateOptions.Disable_First_Installment.name();
    private static final String OPTION_NAME_DISABLE_ALL = RD2_Constants.InstallmentCreateOptions.Disable_All_Installments.name();
    private static final String OPTION_NAME_ALWAYS_CREATE_NEXT = RD2_Constants.InstallmentCreateOptions.Always_Create_Next_Installment.name();
    private static final String MOCK_COMMITMENT_ID = RD2_ElevateIntegrationService_TEST.COMMITMENT_ID;

    private static final Date START_DATE = Date.newInstance(2019, 9, 15);
    private static final Integer MONTHS_TO_DEC = START_DATE.monthsBetween(Date.newInstance(2019, 12, 15));
    private static final Integer MONTHS_TO_YEAR_END = START_DATE.monthsBetween(Date.newInstance(2020, 1, 1));
    private static final String PAYMENT_CREDIT_CARD = 'Credit Card';
    private static final String PAYMENT_CHECK = 'Check';
    private static final Decimal RD_AMOUNT = 100;
    private static final Decimal RD_NEW_AMOUNT = 200;

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
     * @description Verifies that creating a new Lapsed Recurring Donation creates an Installment Opportunity
     */
    @IsTest
    private static void shouldCreateAnInstallmentOppWhenLapsedRDIsCreated() {
        RD2_ScheduleService.currentDate = START_DATE;
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact())
            .withDayOfMonth('20')
            .withStatusLapsed()
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

        System.assertEquals(rd.npe03__Amount__c * MONTHS_TO_YEAR_END, rd.CurrentYearValue__c,
            'Current Year Value should be calculated when RD is created');
        System.assertEquals(rd.npe03__Amount__c * 12, rd.NextYearValue__c,
            'Next Year Value should be calculated when RD is created');
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
        rd1 = TEST_RecurringDonationBuilder.mockRecurringDonationFullQueryResult(rd1, new List<Opportunity>(), scheduleService.buildNewSchedules(rd1));

        // Recurring Donation with no Schedule records
        npe03__Recurring_Donation__c rd2 = getRecurringDonationBuilder()
            .withInstallmentPeriodWeekly()
            .withInstallmentFrequency(3)
            .withCalculateNextDonationDate()
            .build();
        rd2 = TEST_RecurringDonationBuilder.mockRecurringDonationFullQueryResult(rd2, new List<Opportunity>(), new List<RecurringDonationSchedule__c>());

        // Recurring Donation with an empty NextDonationDate
        npe03__Recurring_Donation__c rd3 = getRecurringDonationBuilder()
            .withInstallmentPeriodYearly()
            .withInstallmentFrequency(1)
            .withStartDate(Date.newInstance(2019, 6, 1))
            .withCalculateNextDonationDate()
            .build();
        rd3.npe03__Next_Payment_Date__c = null;
        rd3 = TEST_RecurringDonationBuilder.mockRecurringDonationFullQueryResult(rd3, new List<Opportunity>(), scheduleService.buildNewSchedules(rd3));

        RD2_OpportunityEvaluationService evalService = new RD2_OpportunityEvaluationService();
        evalService.rds = new List<npe03__Recurring_Donation__c>{ rd1, rd2, rd3 };

        System.assertEquals(false, evalService.isNewOpportunityCandidate(rd1), 'Closed RD should not be eligible for an Installment Opp');
        System.assertEquals(false, evalService.isNewOpportunityCandidate(rd2), 'RD with no Schedules should not be eligible for an Installment Opp');
        System.assertEquals(false, evalService.isNewOpportunityCandidate(rd3), 'RD without a Next Donation Date should not be eligible for an Installment Opp');
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
        rdNew = TEST_RecurringDonationBuilder.mockRecurringDonationFullQueryResult(rdNew, new List<Opportunity>(), scheduleService.buildNewSchedules(rdNew));

        // Old Opportunity (has related Opps) - Not New RD
        npe03__Recurring_Donation__c rdOld = getRecurringDonationBuilder()
            .withInstallmentPeriodWeekly()
            .withInstallmentFrequency(3)
            .withCalculateNextDonationDate()
            .build();

        List<Opportunity> opps = new List<Opportunity>{
            TEST_OpportunityBuilder.getOpportunityBuilder(rdOld)
                .withMockId()
                .withAccount(rdOld.npe03__Organization__c)
                .withOpenStage()
                .withCloseDate(rdOld.npe03__Next_Payment_Date__c)
                .build()
        };
        rdOld = TEST_RecurringDonationBuilder.mockRecurringDonationFullQueryResult(rdOld, opps, scheduleService.buildNewSchedules(rdOld));

        RD2_OpportunityEvaluationService evalService = new RD2_OpportunityEvaluationService();
        evalService.rds = new List<npe03__Recurring_Donation__c>{ rdNew, rdOld };

        System.assertEquals(true, evalService.isNewOpportunityCandidate(rdNew),
            'RD having Schedules and no related Opp should be eligible for an Installment Opp');

        System.assertEquals(false, evalService.isNewOpportunityCandidate(rdOld),
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
        RD2_Settings_TEST.setUpConfiguration(new Map<String, Object> {
            'npe03__Open_Opportunity_Behavior__c' => closeAction,
            'InstallmentOppFirstCreateMode__c' => RD2_Constants.FirstInstallmentOppCreateOptions.ASynchronous.name()
        });
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact())
            .withDayOfMonth('20')
            .withCalculateNextDonationDate()
            .build();
        insert rd;

        TEST_OpportunityBuilder oppBuilder = TEST_OpportunityBuilder.getOpportunityBuilder(rd);

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

        rd = TEST_RecurringDonationBuilder.mockRecurringDonationFullQueryResult(rd, oppById.values(), null);
        return rd;
    }

    /**
    * @description Verifies on installment Opportunity is created on RD insert
    * when Installment Auto Creation Setting is set to Disable First Installment.
    */
    @IsTest
    private static void shouldNotCreateOppOnRDInsertWhenDisableFirstInstallment() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        RD2_Settings_TEST.setUpConfiguration(new Map<String, Object> {
            'InstallmentOppAutoCreateOption__c' => OPTION_NAME_DISABLE_FIRST
        });

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact()).build();

        Test.startTest();
        insert rd;
        Test.stopTest();

        List<Opportunity> opps = oppGateway.getRecords(rd);

        System.assertEquals(0, opps.size(),
            'No installment Opportunity should be created: ' + opps);
    }

    /**
    * @description Verifies on installment Opportunity is not created on RD insert
    * when Installment Auto Creation Setting is set to Disable All Installments.
    */
    @IsTest
    private static void shouldNotCreateOppOnRDInsertWhenDisableAllInstallments() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        RD2_Settings_TEST.setUpConfiguration(new Map<String, Object> {
            'InstallmentOppAutoCreateOption__c' => OPTION_NAME_DISABLE_ALL
        });

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact()).build();

        Test.startTest();
        insert rd;
        Test.stopTest();

        List<Opportunity> opps = oppGateway.getRecords(rd);

        System.assertEquals(0, opps.size(),
            'No installment Opportunity should be created: ' + opps);
    }

    /**
    * @description Verifies on installment Opportunity is created
    * when RD is updated, there is already a Closed current Opp
    * and Installment Auto Creation Setting is set to Disable First Installment.
    */
    @IsTest
    private static void shouldCreateOppOnRDUpdateWhenClosedOppExistsAndDisableFirstInstallment() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        RD2_Settings_TEST.setUpConfiguration(new Map<String, Object> {
            'InstallmentOppAutoCreateOption__c' => OPTION_NAME_DISABLE_FIRST
        });

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact()).build();
        insert rd;

        insert TEST_OpportunityBuilder.getOpportunityBuilder(rd)
            .withName()
            .withCloseDate(START_DATE.addMonths(1))
            .withClosedWonStage()
            .build();

        rd.npe03__Amount__c = 2000;

        Test.startTest();
        update rd;
        Test.stopTest();

        List<Opportunity> opps = oppGateway.getRecords(rd);

        System.assertEquals(2, opps.size(),
            'A new Opportunity should be created: ' + opps);
    }

    /**
    * @description Verifies on installment Opportunity is created on RD insert
    * when Installment Auto Creation Setting is set to Always Create Next Installment.
    */
    @IsTest
    private static void shouldCreateOppOnRDInsertWhenAlwaysCreateNextInstallment() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        RD2_Settings_TEST.setUpConfiguration(new Map<String, Object> {
            'InstallmentOppAutoCreateOption__c' => OPTION_NAME_ALWAYS_CREATE_NEXT
        });

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact()).build();

        Test.startTest();
        insert rd;
        Test.stopTest();

        List<Opportunity> opps = oppGateway.getRecords(rd);

        System.assertEquals(1, opps.size(),
            'The installment Opportunity should be created: ' + opps);
    }


    /**
    * @description Verifies no installment Opportunity is created on RD insert when
    * Elevate integration is enabled and Commitment Id is specified on the RD.
    */
    @IsTest
    private static void shouldNotCreateOppOnElevateRdInsertWhenIntegrationIsEnabled() {
        PS_IntegrationServiceConfig_TEST.Stub configStub = new PS_IntegrationServiceConfig_TEST.Stub()
            .withIsIntegrationEnabled(true);

        npe03__Recurring_Donation__c rd = setUpElevateTestData(configStub, MOCK_COMMITMENT_ID);
        List<Opportunity> opps = oppGateway.getRecords(rd);

        System.assertEquals(0, opps.size(),
            'No installment Opportunity should be created for the Elevate RD when integration is enabled: ' + opps);
    }

    /**
    * @description Verifies an installment Opportunity is created on RD insert when
    * Elevate integration is enabled and Commitment Id is not specified on the RD.
    */
    @IsTest
    private static void shouldCreateOppOnNonElevateRDInsertWhenIntegrationIsEnabled() {
        PS_IntegrationServiceConfig_TEST.Stub configStub = new PS_IntegrationServiceConfig_TEST.Stub()
            .withIsIntegrationEnabled(true);

        npe03__Recurring_Donation__c rd = setUpElevateTestData(configStub, null);
        List<Opportunity> opps = oppGateway.getRecords(rd);

        System.assertEquals(1, opps.size(),
            'An installment Opportunity should be created for the non-Elevate RD: ' + opps);
    }

    /**
    * @description Verifies an installment Opportunity is created on RD insert when
    * Elevate integration is disabled and Commitment Id is specified on the RD.
    */
    @IsTest
    private static void shouldCreateOppOnElevateRDInsertWhenIntegrationIsDisabled() {
        PS_IntegrationServiceConfig_TEST.Stub configStub = new PS_IntegrationServiceConfig_TEST.Stub()
            .withIsIntegrationEnabled(false);

        npe03__Recurring_Donation__c rd = setUpElevateTestData(configStub, MOCK_COMMITMENT_ID);
        List<Opportunity> opps = oppGateway.getRecords(rd);

        System.assertEquals(1, opps.size(),
            'An installment Opportunity should be created for the Elevate RD when integration is disabled: ' + opps);
    }

    /***
    * @description Verifies on installment Opportunity is created on RD insert
    * when Installment Auto Creation Setting is a random string that does not matched against any of the
    * default value. The auto creation process will be treated the same as Always Create Next Installment.
    */
    @IsTest
    private static void shouldCreateOppOnRDInsertWhenInstallmentCreateOptionIsRandomText() {
        String randomText = 'RANDOM';

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        RD2_Settings_TEST.setUpConfiguration(new Map<String, Object> {
            'InstallmentOppAutoCreateOption__c' => randomText
        });

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact()).build();

        Test.startTest();
        insert rd;
        Test.stopTest();

        List<Opportunity> opps = oppGateway.getRecords(rd);

        System.assertEquals(1, opps.size(),
            'The installment Opportunity should be created: ' + opps);
    }

    /**
     * @description Verifies no exception is thrown when RD is closed and
     * has no Opportunities
     */
    @IsTest
    private static void shouldNotThrowExceptionWhenRDIsClosedAndHasNoOpp() {
        Exception actualException;

        RD2_Settings_TEST.setUpConfiguration(new Map<String, Object> {
            'npe03__Open_Opportunity_Behavior__c' => RD2_Constants.CloseActions.Mark_Opportunities_Closed_Lost.name()
        });

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
     * @description Verifies Opps are processed when currency on RD is changed only
     */
    @IsTest
    private static void shouldEvaluateOppsWhenRDCurrencyIsChanged() {
        if (!UserInfo.isMultiCurrencyOrganization()) {
            return;
        }

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact().Id)
            .withCurrencyIsoCode('CAD')
            .build();

        Test.startTest();
        insert rd;
        Test.stopTest();

        npe03__Recurring_Donation__c updatedRD = rd.clone();
        rd.put(UTIL_Currency.CURRENCY_ISO_CODE_FIELD, 'USD');

        RD2_OpportunityEvaluationService evalService = new RD2_OpportunityEvaluationService();
        System.assertEquals(true, evalService.hasKeyFieldChanged(updatedRd, rd),
            'Opps should be evaluated when currency on related RD is changed only');
    }

    /**
     * @description Verifies future open Opp is updated when an active RD is updated
     */
    @IsTest
    private static void shouldUpdateFutureOpenOppWhenActiveRDIsUpdated() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        RD2_Settings_TEST.configureForASyncFirstOpportunityCreate();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact().Id).build();

        testFutureOppUpdateOnRDUpdate(rd);
    }

    /**
     * @description Verifies future open Opp is updated when a Lapsed RD is updated
     */
    @IsTest
    private static void shouldUpdateFutureOpenOppWhenLapsedRDIsUpdated() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        RD2_Settings_TEST.configureForASyncFirstOpportunityCreate();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact().Id)
            .withStatusLapsed()
            .build();

        testFutureOppUpdateOnRDUpdate(rd);
    }

    /**
     * @description Verifies future open Opp is updated when the RD is updated
     * @param rd Recurring Donation
     * @return void
     */
    private static void testFutureOppUpdateOnRDUpdate(npe03__Recurring_Donation__c rd) {
        //set current date override
        final Date today = START_DATE.addDays(1);
        RD2_ScheduleService.currentDate = today;

        insert rd;

        insert TEST_OpportunityBuilder.getOpportunityBuilder(rd)
            .withCloseDate(today.addDays(1))
            .withOpenStage()
            .build();

        Date nextCloseDate = today.addDays(2);

        Test.startTest();
        rd.Day_Of_Month__c = String.valueOf(nextCloseDate.day());
        rd.npe03__Amount__c = RD_NEW_AMOUNT;
        update rd;
        Test.stopTest();

        List<Opportunity> opps = oppGateway.getRecords(rd);
        System.assertEquals(1, opps.size(), 'An Installment Opp should exist: ' + opps);
        System.assertEquals(RD_NEW_AMOUNT, opps[0].Amount, 'Amount should be updated');
        System.assertEquals(nextCloseDate, opps[0].CloseDate, 'Close Date should be updated');

        List<Error__c> errors = errorGateway.getRecords();
        System.assertEquals(0, errors.size(), 'No error should be created: ' + errors);
    }

    /**
     * @description Verifies past open Opp matching future projected installment
     * is not updated when an active RD is updated
     */
    @IsTest
    private static void shouldNotUpdatePastOpenOppMatchingFutureInstallmentWhenRDIsUpdated() {
        //set current date override
        final Date today = START_DATE.addDays(1);
        RD2_ScheduleService.currentDate = today;

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        RD2_Settings_TEST.configureForASyncFirstOpportunityCreate();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact().Id)
            .withCalculateNextDonationDate()
            .build();
        insert rd;

        insert TEST_OpportunityBuilder.getOpportunityBuilder(rd)
            .withCloseDate(START_DATE)
            .withOpenStage()
            .build();

        Test.startTest();
        rd.Day_Of_Month__c = String.valueOf(today.addDays(1).day());
        rd.npe03__Amount__c = RD_NEW_AMOUNT;
        update rd;
        Test.stopTest();

        List<Opportunity> opps = oppGateway.getRecords(rd);
        System.assertEquals(1, opps.size(), 'No new Opp should be created: ' + opps);
        System.assertEquals(RD_AMOUNT, opps[0].Amount, 'Amount should not be updated on a past open Opp');
        System.assertEquals(START_DATE, opps[0].CloseDate, 'Close Date should not be updated on a past open Opp');

        List<Error__c> errors = errorGateway.getRecords();
        System.assertEquals(0, errors.size(), 'No error should be created: ' + errors);
    }

    /**
     * @description Verifies future open Opp is updated when an active RD is updated.
     * The future Closed Won Opp is not updated.
     */
    @IsTest
    private static void shouldNotUpdateFutureOpenOppCloseDateWhenRDNextDonationDateIsNotUpdated() {
        //set current date override
        final Date today = START_DATE.addDays(-1);
        RD2_ScheduleService.currentDate = today;

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        RD2_Settings_TEST.configureForASyncFirstOpportunityCreate();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact().Id).build();
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
                .withCloseDate(START_DATE.addMonths(1))
                .withOpenStage()
                .build()
        };
        insert opps;

        Test.startTest();
        rd.npe03__Amount__c = RD_NEW_AMOUNT;
        rd.StartDate__c = START_DATE;
        update rd;
        Test.stopTest();

        Map<Id, Opportunity> oppById = new Map<Id, Opportunity>(oppGateway.getRecords(rd));
        System.assertEquals(opps.size(), oppById.size(), 'The number of returned Opps should match');

        Opportunity opp = oppById.get(opps[0].Id);
        System.assertEquals(true, opp.isClosed && opp.isWon, 'The first Opp should stay Closed Won');
        System.assertEquals(START_DATE, opp.CloseDate, 'The first Opp Close Date should be unchanged');
        System.assertEquals(RD_AMOUNT, opp.Amount, 'The first Opp Amount should be unchanged');

        opp = oppById.get(opps[1].Id);
        System.assertEquals(false, opp.isClosed, 'The second Opp should stay open');
        System.assertEquals(START_DATE.addMonths(1), opp.CloseDate, 'The second Opp Close Date should be unchanged');
        System.assertEquals(RD_NEW_AMOUNT, opp.Amount, 'The second Opp Amount should be updated');

        List<Error__c> errors = errorGateway.getRecords();
        System.assertEquals(0, errors.size(), 'No error should be created: ' + errors);
    }

    /**
     * @description Verifies the calendar Current and Next Year Values
     * should be calculated when a Recurring Donation is created
     */
    @IsTest
    private static void yearValuesShouldBeCalculatedWhenRDIsCreated() {
        //set current date override
        final Date today = START_DATE;
        RD2_ScheduleService.currentDate = today;

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact().Id).build();

        Test.startTest();
        insert rd;
        Test.stopTest();

        rd = rdGateway.getRecord(rd.Id);

        System.assertEquals(rd.npe03__Amount__c * MONTHS_TO_YEAR_END, rd.CurrentYearValue__c,
            'Current Year Value should be calculated when RD is created');
        System.assertEquals(rd.npe03__Amount__c * 12, rd.NextYearValue__c,
            'Next Year Value should be calculated when RD is created');
    }

    /**
     * @description The Current and Next Year Value should include past/future Closed Won and Open Opps.
     * The value in this test is calculated when Recurring Donation is updated.
     */
    @IsTest
    private static void yearValuesShouldIncludeOpenAndClosedWonOpps() {
        //set current date override
        final Date today = START_DATE.addMonths(MONTHS_TO_DEC).addDays(-1);
        RD2_ScheduleService.currentDate = today;

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact().Id).build();
        insert rd;

        TEST_OpportunityBuilder oppBuilder = TEST_OpportunityBuilder.getOpportunityBuilder(rd);
        List<Opportunity> opps = new List<Opportunity>();
        for (Integer i = 0; i < MONTHS_TO_YEAR_END + 2; i++) {
            oppBuilder = oppBuilder
                .withName()
                .withCloseDate(START_DATE.addMonths(i));

            if (i < MONTHS_TO_DEC || i == MONTHS_TO_YEAR_END + 1) {
                opps.add(
                    oppBuilder.withClosedWonStage().build()
                );
            } else {
                opps.add(
                    oppBuilder.withOpenStage().build()
                );
            }
        }
        insert opps;

        Test.startTest();
        rd.npe03__Amount__c = RD_NEW_AMOUNT;
        rd.StartDate__c = today;
        update rd;
        Test.stopTest();

        rd = rdGateway.getRecord(rd.Id);

        System.assertEquals(RD_AMOUNT * MONTHS_TO_DEC + RD_NEW_AMOUNT, rd.CurrentYearValue__c,//Open Opp in Dec has the new amount applied
            'Current Year Value should include current year past and future Open/Closed Won Opps');
        System.assertEquals(RD_AMOUNT + RD_NEW_AMOUNT * 11, rd.NextYearValue__c,//Closed Won Opp in Jan has the old amount
            'Next Year Value should include next year Open/Closed Won Opps and projected installments');
    }

    /**
     * @description Current and Next Year Value should exclude past and future Closed Lost Opps.
     * The value in this test is calculated when Recurring Donation is updated.
     */
    @IsTest
    private static void yearValuesShouldExcludeClosedLostOpps() {
        //set current date override
        final Date today = START_DATE.addMonths(MONTHS_TO_DEC).addDays(-1);
        RD2_ScheduleService.currentDate = today;

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        RD2_Settings_TEST.configureForASyncFirstOpportunityCreate();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact().Id).build();
        insert rd;

        TEST_OpportunityBuilder oppBuilder = TEST_OpportunityBuilder.getOpportunityBuilder(rd);
        List<Opportunity> opps = new List<Opportunity>();
        for (Integer i = 0; i < MONTHS_TO_YEAR_END + 1; i++) {
            oppBuilder = oppBuilder
                .withName()
                .withCloseDate(START_DATE.addMonths(i));

            if (i < MONTHS_TO_DEC) {
                opps.add(
                    oppBuilder.withClosedWonStage().build()
                );
            } else {
                opps.add(
                    oppBuilder.withClosedLostStage().build()
                );
            }
        }
        insert opps;

        Test.startTest();
        rd.npe03__Amount__c = RD_NEW_AMOUNT;
        rd.StartDate__c = today;
        update rd;
        Test.stopTest();

        rd = rdGateway.getRecord(rd.Id);

        System.assertEquals(RD_AMOUNT * MONTHS_TO_DEC, rd.CurrentYearValue__c,
            'Current Year Value should exclude current year Closed Lost Opps');
        System.assertEquals(RD_NEW_AMOUNT * 11, rd.NextYearValue__c,
            'Next Year Value should exclude next year Closed Lost Opps');
    }

    /**
     * @description Current and Next Year Value should ignore Closed Lost Opps during data migration.
     * The value in this test is calculated when Recurring Donation is updated.
     */
    @IsTest
    private static void yearValuesShouldIgnoreClosedLostOppsInDataMigration() {
        final Integer monthsToMigration = 1;
        final Date today = START_DATE.addMonths(MONTHS_TO_DEC).addDays(-1);
        RD2_ScheduleService.currentDate = today;

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact().Id).build();
        insert rd;

        TEST_OpportunityBuilder oppBuilder = TEST_OpportunityBuilder.getOpportunityBuilder(rd);
        List<Opportunity> opps = new List<Opportunity>{
            oppBuilder
                .withName()
                .withCloseDate(START_DATE)//Sep Closed Won Opp
                .withClosedWonStage()
                .build(),
            oppBuilder
                .withName()
                .withCloseDate(START_DATE.addMonths(monthsToMigration))//Oct Closed Lost Opp
                .withClosedLostStage()
                .build(),
            oppBuilder
                .withName()
                .withCloseDate(START_DATE.addMonths(monthsToMigration + 1))//Nov Open Opp
                .withOpenStage()
                .build()
        };
        for (Integer i = monthsToMigration; i < MONTHS_TO_YEAR_END + 2; i++) {//data migration applied in Oct
            opps.add(oppBuilder
                .withName()
                .withCloseDate(START_DATE.addMonths(i))
                .withClosedLostStage()
                .withInstallmentNumberMigrationFlag()
                .build()
            );
        }
        insert opps;

        Test.startTest();
        rd.npe03__Amount__c = RD_NEW_AMOUNT;
        rd.StartDate__c = today;
        update rd;
        Test.stopTest();

        rd = rdGateway.getRecord(rd.Id);

        System.assertEquals(RD_AMOUNT * 2 + RD_NEW_AMOUNT, rd.CurrentYearValue__c, //Sep/Nov amounts + Dec new amount
            'Current Year Value should ignore Closed Lost Opps in data migration');
        System.assertEquals(RD_NEW_AMOUNT * 12, rd.NextYearValue__c,
            'Next Year Value should ignore Closed Lost Opps in data migration');
    }

    /**
     * @description The Current Year Value should include current year Opps and projected installments.
     * It should exclude previous year Opps and the future year projected installments.
     */
    @IsTest
    private static void yearValueCurrentShouldIncludeOppsAndInstallmentsWithinCurrentYear() {
        //set current date override
        final Date startDate = Date.newInstance(2018, 9, 1);
        final Date today = Date.newInstance(2019, 3, 1);
        RD2_ScheduleService.currentDate = today;

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        RD2_Settings_TEST.configureForASyncFirstOpportunityCreate();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact().Id)
            .withDateEstablished(startDate)
            .withStartDate(startDate)
            .withDayOfMonth(String.valueOf(startDate.day()))
            .build();
        insert rd;

        TEST_OpportunityBuilder oppBuilder = TEST_OpportunityBuilder.getOpportunityBuilder(rd);
        List<Opportunity> opps = new List<Opportunity>();

        Date closeDate = startDate;
        while (closeDate <= today) {
            opps.add(oppBuilder
                .withName()
                .withCloseDate(closeDate)
                .withClosedWonStage()
                .build()
            );
            closeDate = closeDate.addMonths(1);
        }
        System.assertEquals(7, opps.size(),
            'There should be four past and three current year Closed Won Opps: ' + opps);
        insert opps;

        Test.startTest();
        rd.npe03__Amount__c = RD_NEW_AMOUNT;
        rd.StartDate__c = today;
        update rd;
        Test.stopTest();

        rd = rdGateway.getRecord(rd.Id);

        System.assertEquals(RD_AMOUNT * 3 + RD_NEW_AMOUNT * 9, rd.CurrentYearValue__c,
            'Current Year Value should include current year Opps and projected installments');
        System.assertEquals(RD_NEW_AMOUNT * 12, rd.NextYearValue__c,
            'Next Year Value should include next year projected installments');
    }

    /**
     * @description The Current and Next Year Value should not double count existing future Opps
     * with their matching projected installments
     */
    @IsTest
    private static void yearValuesShouldNotDoubleCountInstallmentWhenMatchingOppExists() {
        //set current date override
        final Date nextCloseDate = START_DATE.addMonths(MONTHS_TO_DEC);
        final Date today = nextCloseDate.addDays(-1);
        RD2_ScheduleService.currentDate = today;

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        RD2_Settings_TEST.configureForASyncFirstOpportunityCreate();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact().Id).build();
        insert rd;

        TEST_OpportunityBuilder oppBuilder = TEST_OpportunityBuilder.getOpportunityBuilder(rd);
        List<Opportunity> opps = new List<Opportunity>();
        for (Integer i = 0; i < MONTHS_TO_YEAR_END + 2; i++) {
            oppBuilder = oppBuilder
                .withName()
                .withCloseDate(START_DATE.addMonths(i));

            if (i < MONTHS_TO_DEC) {
                opps.add(
                    oppBuilder.withClosedWonStage().build()
                );
            } else {
                opps.add(
                    oppBuilder.withOpenStage().build()
                );
            }
        }
        insert opps;

        Test.startTest();
        rd.npe03__Amount__c = RD_NEW_AMOUNT;
        rd.Day_of_Month__c = String.valueOf(nextCloseDate.addDays(1).day());
        rd.StartDate__c = today;
        update rd;
        Test.stopTest();

        rd = rdGateway.getRecord(rd.Id);

        System.assertEquals(RD_AMOUNT * MONTHS_TO_DEC + RD_NEW_AMOUNT, rd.CurrentYearValue__c,//Open Opp in Dec has the new amount applied
            'Current Year Value should not double count an installment when the matching Opp exists');
        System.assertEquals(RD_NEW_AMOUNT * 12, rd.NextYearValue__c,
            'Next Year Value should not double count an installment when the matching Opp exists');
    }

    /**
     * @description The Current and Next Year Value should exclude future Closed Lost Opps.
     */
    @IsTest
    private static void yearValuesShouldExcludeFutureClosedLostOpp() {
        //set current date override
        final Date today = START_DATE.addMonths(1).addDays(1);
        RD2_ScheduleService.currentDate = today;

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        RD2_Settings_TEST.configureForASyncFirstOpportunityCreate();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact().Id).build();
        insert rd;

        TEST_OpportunityBuilder oppBuilder = TEST_OpportunityBuilder.getOpportunityBuilder(rd);
        List<Opportunity> opps = new List<Opportunity>{
            oppBuilder
                .withName()
                .withCloseDate(START_DATE.addMonths(1))//past Opp
                .withOpenStage()
                .build(),
            oppBuilder
                .withName()
                .withCloseDate(START_DATE.addMonths(2))//future Opp but Closed Lost
                .withClosedLostStage()
                .build(),
            oppBuilder
                .withName()
                .withCloseDate(START_DATE.addMonths(3))//Dec Opp
                .withOpenStage()
                .build()
        };
        insert opps;

        Test.startTest();
        rd.npe03__Amount__c = RD_NEW_AMOUNT;
        rd.StartDate__c = today;
        update rd;
        Test.stopTest();

        rd = rdGateway.getRecord(rd.Id);

        Decimal expectedValue = RD_AMOUNT//Opp with the past Close Date is not updated
            + 0//the next future Closed Lost Opp is excluded
            + RD_NEW_AMOUNT;//future Opp with Close Date in Dec is updated

        System.assertEquals(expectedValue, rd.CurrentYearValue__c,
            'Current Year Value should not include future Closed Lost Opp');
        System.assertEquals(RD_NEW_AMOUNT * 12, rd.NextYearValue__c,
            'Next Year Value should not double count an installment when the matching Opp exists');
    }

    /**
     * @description The calendar Current and Next Year Value should not count projected installments after RD is Closed
     */
    @IsTest
    private static void yearValuesShouldExcludeInstallmentsWhenRDIsClosed() {
        //set current date override
        final Date today = START_DATE.addMonths(MONTHS_TO_DEC);
        RD2_ScheduleService.currentDate = today;

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact().Id).build();
        insert rd;

        TEST_OpportunityBuilder oppBuilder = TEST_OpportunityBuilder.getOpportunityBuilder(rd).withClosedWonStage();
        List<Opportunity> opps = new List<Opportunity>();
        for (Integer i = 0; i < MONTHS_TO_YEAR_END; i++) { //create closed own opps till the end of the year
            opps.add(oppBuilder
                .withName()
                .withCloseDate(START_DATE.addMonths(i).addDays(-2))
                .build()
            );
        }
        opps.add(oppBuilder
            .withName()
            .withCloseDate(START_DATE.addMonths(MONTHS_TO_YEAR_END + 1))//Open Opp in Feb next year
            .withOpenStage()
            .build()
        );
        insert opps;

        Test.startTest();
        rd.Status__c = RD2_Constants.STATUS_CLOSED;
        update rd;
        Test.stopTest();

        rd = rdGateway.getRecord(rd.Id);

        System.assertEquals(rd.npe03__Amount__c * MONTHS_TO_YEAR_END, rd.CurrentYearValue__c,
            'Current Year Value should include current year Closed Won amounts when RD is Closed');
        System.assertEquals(0, rd.NextYearValue__c,//Open Opp in Feb is voided when RD is closed
            'Next Year Value should not include future Open Opp');
    }

    /**
     * @description Verifies the fiscal year Current and Next Year Values
     * should be calculated when custom settings Use Fiscal Year is checked
     * and a Recurring Donation is created
     */
    @IsTest
    private static void fiscalYearValuesShouldBeCalculatedWhenConfiguredAndRDIsCreated() {
        final Date today = START_DATE;
        RD2_ScheduleService.currentDate = today;
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        setUpUseFiscalYear(true);
        UTIL_FiscalYearInfo.fiscalYearInfo = new UTIL_FiscalYearInfo(11, true);

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact().Id).build();

        Test.startTest();
        insert rd;
        Test.stopTest();

        rd = rdGateway.getRecord(rd.Id);

        System.assertEquals(rd.npe03__Amount__c * 2, rd.CurrentYearValue__c,
            'Current Year Value should be calculated when RD is created');
        System.assertEquals(rd.npe03__Amount__c * 12, rd.NextYearValue__c,
            'Next Year Value should be calculated when RD is created');
    }

    /**
     * @description Verifies the fiscal year Current and Next Year Values
     * should be calculated when custom settings Use Fiscal Year is checked
     * and a Recurring Donation is updated
     */
    @IsTest
    private static void fiscalYearValuesShouldBeCalculatedWhenConfiguredAndRDIsUpdated() {
        //set current date override
        final Date startDate = Date.newInstance(2019, 7, 1);
        final Date today = Date.newInstance(2020, 1, 15);
        RD2_ScheduleService.currentDate = today;

        setUpUseFiscalYear(true);
        UTIL_FiscalYearInfo.fiscalYearInfo = new UTIL_FiscalYearInfo(4, true);

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact().Id)
            .withDateEstablished(startDate)
            .withStartDate(startDate)
            .withDayOfMonth(String.valueOf(startDate.day()))
            .build();
        insert rd;

        TEST_OpportunityBuilder oppBuilder = TEST_OpportunityBuilder.getOpportunityBuilder(rd).withClosedWonStage();
        List<Opportunity> opps = new List<Opportunity>();

        Date closeDate = startDate;
        while (closeDate <= Date.newInstance(2019, 11, 1)) {
            opps.add(oppBuilder
                .withName()
                .withCloseDate(closeDate)
                .build()
            );
            closeDate = closeDate.addMonths(1);
        }
        opps.add(oppBuilder
            .withName()
            .withAmount(RD_AMOUNT + 10)//$10 more donated for a past closed Opp
            .withCloseDate(Date.newInstance(2019, 12, 1))
            .build()
        );
        opps.add(oppBuilder
            .withName()
            .withAmount(RD_AMOUNT)
            .withCloseDate(Date.newInstance(2020, 1, 1))//past open Opp
            .withOpenStage()
            .build()
        );
        opps.add(oppBuilder
            .withName()
            .withCloseDate(Date.newInstance(2020, 2, 1))//future open Opp
            .build()
        );
        insert opps;

        Test.startTest();
        rd.npe03__Amount__c = RD_NEW_AMOUNT;
        rd.StartDate__c = today;
        update rd;
        Test.stopTest();

        rd = rdGateway.getRecord(rd.Id);

        System.assertEquals(RD_AMOUNT * 7 + 10 + RD_NEW_AMOUNT * 2, rd.CurrentYearValue__c,
            'Current Year Value should include July 2019 - Jan 2020 past Opps, '
                + 'a Feb 2020 open Opp with updated Amount and March 1st projected installment '
                + 'for the current fiscal year ending on March 31, 2020');
        System.assertEquals(RD_NEW_AMOUNT * 12, rd.NextYearValue__c,
            'Next Year Value should include next fiscal year projected installments');
    }

    /**
     * @description The fiscal Current and Next Year Value should not count projected installments after RD is Closed
     */
    @IsTest
    private static void fiscalYearValuesShouldExcludeInstallmentsWhenRDIsClosed() {
        //set current date override
        final Date today = START_DATE.addMonths(1).addDays(1);
        RD2_ScheduleService.currentDate = today;

        setUpUseFiscalYear(true);
        UTIL_FiscalYearInfo.fiscalYearInfo = new UTIL_FiscalYearInfo(11, true);

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact().Id).build();
        insert rd;

        TEST_OpportunityBuilder oppBuilder = TEST_OpportunityBuilder.getOpportunityBuilder(rd).withClosedWonStage();
        List<Opportunity> opps = new List<Opportunity>();
        for (Integer i = 0; i < 2; i++) {
            opps.add(oppBuilder
                .withName()
                .withCloseDate(START_DATE.addMonths(i))
                .build()
            );
        }
        opps.add(oppBuilder
            .withName()
            .withCloseDate(today.addDays(1))//Open Opp in the future
            .withOpenStage()
            .build()
        );
        insert opps;

        Test.startTest();
        rd.Status__c = RD2_Constants.STATUS_CLOSED;
        update rd;
        Test.stopTest();

        rd = rdGateway.getRecord(rd.Id);

        System.assertEquals(rd.npe03__Amount__c * 2, rd.CurrentYearValue__c,
            'Current Year Value should include Sep-Oct 2019 Opps for the current fiscal year ending on Oct 31, 2019');
        System.assertEquals(0, rd.NextYearValue__c,//Open Opp in Feb is voided when RD is closed
            'Next Year Value should not include the future open Opps');
    }

    /**
     * @description Verifies the calendar year Current and Next Year Values
     * should be calculated when custom settings Use Fiscal Year is unchecked
     */
    @IsTest
    private static void calendarYearValuesShouldBeCalculatedWhenFiscalYearIsNotConfigured() {
        final Date today = START_DATE;
        RD2_ScheduleService.currentDate = today;
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        setUpUseFiscalYear(false);//do not use fiscal year
        UTIL_FiscalYearInfo.fiscalYearInfo = new UTIL_FiscalYearInfo(11, true);

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact().Id).build();

        Test.startTest();
        insert rd;
        Test.stopTest();

        rd = rdGateway.getRecord(rd.Id);

        System.assertEquals(rd.npe03__Amount__c * MONTHS_TO_YEAR_END, rd.CurrentYearValue__c,
            'Current Year Value should be calculated when RD is created');
        System.assertEquals(rd.npe03__Amount__c * 12, rd.NextYearValue__c,
            'Next Year Value should be calculated when RD is created');
    }

    /**
     * @description Verifies the calendar year Current and Next Year Values
     * should be calculated when custom settings Use Fiscal Year is checked
     * but the custom fiscal year has been enabled
     */
    @IsTest
    private static void calendarYearValuesShouldBeCalculatedWhenCustomFiscalYearIsEnabled() {
        final Date today = START_DATE;
        RD2_ScheduleService.currentDate = today;
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        setUpUseFiscalYear(true);//configuration is set to use the fiscal year
        UTIL_FiscalYearInfo.fiscalYearInfo = new UTIL_FiscalYearInfo(11, true);
        //however, the custom (not standard) fiscal year is enabled
        UTIL_FiscalYearInfo.fiscalYearInfo.isCustomFiscalYearEnabled = true;

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact().Id).build();

        Test.startTest();
        insert rd;
        Test.stopTest();

        rd = rdGateway.getRecord(rd.Id);

        //values are calculated as per calendar year, since RD2 does not support the custom fiscal year
        System.assertEquals(rd.npe03__Amount__c * MONTHS_TO_YEAR_END, rd.CurrentYearValue__c,
            'Current Year Value should be calculated when RD is created');
        System.assertEquals(rd.npe03__Amount__c * 12, rd.NextYearValue__c,
            'Next Year Value should be calculated when RD is created');
    }

    /**
     * @description Verifies the fiscal/calendar year Current and Next Year Values
     * should be calculated based on the Opp Close Date even though it matches a
     * projected installment in the next year
     */
    @IsTest
    private static void yearValuesShouldMatchByActualDateWhenOppIsMatchedWithInstallmentOutsideOfTheYear() {
        //set current date override
        final Date startDate = Date.newInstance(2020, 1, 1);
        final Date today = Date.newInstance(2020, 4, 1);//the next fiscal year is starting today
        RD2_ScheduleService.currentDate = today;

        setUpUseFiscalYear(true);
        UTIL_FiscalYearInfo.fiscalYearInfo = new UTIL_FiscalYearInfo(4, true);

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact().Id)
            .withStartDate(startDate)
            .withDateEstablished(startDate)
            .withDayOfMonth('1')
            .build();
        insert rd;

        TEST_OpportunityBuilder oppBuilder = TEST_OpportunityBuilder.getOpportunityBuilder(rd).withClosedWonStage();
        List<Opportunity> opps = new List<Opportunity>();
        for (Integer month = 1; month <= 3; month++) {
            opps.add(oppBuilder
                .withName()
                .withCloseDate(Date.newInstance(2020, month, 1))
                .build()
            );
        }
        //add an Opp with Close Date March 31 instead of the April 1
        opps.add(oppBuilder
            .withName()
            .withCloseDate(Date.newInstance(2020, 3, 31))
            .withOpenStage()
            .build()
        );
        insert opps;

        new RD2_OpportunityEvaluationService()
            .withRds(new Set<Id>{ rd.Id })
            .evaluateOpportunities();
        rd = rdGateway.getRecord(rd.Id);

        System.assertEquals(RD_AMOUNT * 11, rd.CurrentYearValue__c,
            'Current Year Value should exclude April 1 installment Opp since it was included in the past Year Value');
        System.assertEquals(RD_AMOUNT * 12, rd.NextYearValue__c,
            'Next Year Value should match with projected installments');
    }

    /**
     * @description Verifies field values from Recurring Donation
     * are copied into mapped fields on Opportunity record when RD is created
     */
    @IsTest
    private static void shouldPopulateOppFieldsOnRDInsertWhenCustomFieldMappingIsDefined() {
        final Date today = START_DATE;
        RD2_ScheduleService.currentDate = today;

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        RD2_CustomFieldMapper_TEST.createCustomFieldMapping('Name', 'Description');

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact()).build();

        Test.startTest();
        insert rd;
        Test.stopTest();

        rd = rdGateway.getRecord(rd.Id);
        List<Opportunity> opps = oppGateway.getRecords(rd);

        System.assertEquals(1, opps.size(), 'The number of returned Opps should match');
        System.assertEquals(rd.Name, opps[0].Description,
            'The RD Name should be copied into the Opportunity record Description field');
    }

    /**
     * @description Verifies field values from Recurring Donation
     * are copied into mapped fields on Opportunity record when RD is updated
    */
    @IsTest
    private static void shouldPopulateOppFieldsOnRDUpdateWhenCustomFieldMappingIsDefined() {
        final Date today = START_DATE;
        RD2_ScheduleService.currentDate = today;

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        RD2_Settings_TEST.configureForASyncFirstOpportunityCreate();
        RD2_CustomFieldMapper_TEST.createCustomFieldMapping('Name', 'Description');

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact()).build();
        insert rd;

        insert TEST_OpportunityBuilder.getOpportunityBuilder(rd)
            .withName()
            .withCloseDate(START_DATE.addMonths(1))
            .withOpenStage()
            .build();

        List<Opportunity> opps = oppGateway.getRecords(rd);
        System.assert(String.isBlank(opps[0].Description), 'Description should not be specified');

        Test.startTest();
        rd.npe03__Amount__c = 2000;
        update rd;
        Test.stopTest();

        opps = oppGateway.getRecords(rd);
        System.assertEquals(1, opps.size(), 'The number of returned Opps should match');
        System.assertEquals(rd.Name, opps[0].Description,
            'The RD Name should be copied into the Opportunity record Description field');
    }

    /**
    * Verifies the Current and Next Year Values are calculated based on on planned and paid installments
    * when there are Closed Won Opportunities for a fixed-length Recurring Donation
    */
    @isTest
    private static void yearValuesShouldMatchFixedLengthRDPlannedInstallments() {
        final Integer paidInstallments = 4;
        //set current date override
        final Date startDate = Date.newInstance(2019, 12, 1);
        Date today = Date.newInstance(2020, 3, 2);
        RD2_ScheduleService.currentDate = today;

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact().Id)
            .withStartDate(startDate)
            .withDayOfMonth('1')
            .withRecurringTypeFixed()
            .withPlannedInstallments(20)
            .withPaidInstallments(paidInstallments)
            .build();
        insert rd;

        TEST_OpportunityBuilder oppBuilder = TEST_OpportunityBuilder.getOpportunityBuilder(rd).withClosedWonStage();
        List<Opportunity> opps = new List<Opportunity>();
        for (Integer month = 0; month < paidInstallments; month++){
            opps.add(oppBuilder
                .withName()
                .withCloseDate(startDate.addMonths(month))
                .build());
        }
        insert opps;

        Test.startTest();
        new RD2_OpportunityEvaluationService()
            .withRds(new Set<Id>{ rd.Id })
            .evaluateOpportunities();
        Test.stopTest();

        rd = rdGateway.getRecord(rd.Id);
        System.assertEquals(RD_AMOUNT * 12, rd.CurrentYearValue__c,
            'Current Year Value should include actual and planned installment amounts');
        System.assertEquals(RD_AMOUNT * 7, rd.NextYearValue__c,
            'Next Year Value should match the expected planned installment amount');
    }

    /**
    * Verifies the Current and Next Year Values are calculated based on on planned and paid installments
    * when there is an open Opportunity for a fixed-length Recurring Donation
    */
    @isTest
    private static void yearValuesShouldCountOpenFutureOppWhenRDIsFixedLength() {
        final Integer paidInstallments = 4;
        //set current date override
        final Date startDate = Date.newInstance(2019, 12, 1);
        Date today = Date.newInstance(2020, 3, 2);
        RD2_ScheduleService.currentDate = today;

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact().Id)
            .withStartDate(startDate)
            .withDayOfMonth('1')
            .withRecurringTypeFixed()
            .withPlannedInstallments(20)
            .withPaidInstallments(paidInstallments)
            .build();
        insert rd;

        TEST_OpportunityBuilder oppBuilder = TEST_OpportunityBuilder.getOpportunityBuilder(rd).withClosedWonStage();
        List<Opportunity> opps = new List<Opportunity>();

        for (Integer month = 0; month < paidInstallments; month++){
            opps.add(oppBuilder
                .withName()
                .withCloseDate(startDate.addMonths(month))
                .build());
        }

        //Create an Opp not matching the schedule installment in the next year
        Decimal extraOppAmount = 5000;
        opps.add(oppBuilder
            .withName()
            .withCloseDate(today.addYears(1).addDays(15))
            .withOpenStage()
            .withAmount(extraOppAmount)
            .build()
        );
        insert opps;

        Test.startTest();
        new RD2_OpportunityEvaluationService()
            .withRds(new Set<Id>{ rd.Id })
            .evaluateOpportunities();
        Test.stopTest();

        rd = rdGateway.getRecord(rd.Id);
        System.assertEquals(paidInstallments, rd.npe03__Total_Paid_Installments__c,
            'Number of paid installments should match the RD field');

        System.assertEquals(RD_AMOUNT * 12, rd.CurrentYearValue__c,
            'Current Year Value should include actual and planned installment amounts');
        System.assertEquals(RD_AMOUNT * 6 + extraOppAmount, rd.NextYearValue__c,
            'Next Year Value should match the expected planned installment and the future open Opp amounts');
    }

    /**
     * @description Verifies that inserting Recurring Donation with status mapped to Active will creates an Installment Opportunity
     */
    @IsTest
    private static void shouldCreateAnInstallmentOppWhenRDStatusIsMappedToActive() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        String newStatus = 'New';

        RD2_StatusMapper_TEST.Stub mapperStub = new RD2_StatusMapper_TEST.Stub()
            .withMapping(newStatus, RD2_Constants.STATUS_ACTIVE);
        RD2_StatusMapper.statusMapper = (RD2_StatusMapper) Test.createStub(
            RD2_StatusMapper.Class,
            mapperStub
        );

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact())
            .withDayOfMonth('20')
            .withStatus(newStatus)
            .withCalculateNextDonationDate()
            .build();

        rd = TEST_RecurringDonationBuilder.mockRecurringDonationFullQueryResult(rd, new List<Opportunity>(), new RD2_ScheduleService().buildNewSchedules(rd));

        Test.startTest();
        RD2_OpportunityEvaluationService evalService = new RD2_OpportunityEvaluationService();
        evalService.rds = new List<npe03__Recurring_Donation__c>{ rd};
        Test.stopTest();

        System.assertEquals(true, evalService.isNewOpportunityCandidate(rd),
            'RD with status mapped to Active should be considered as new opportunity candidate');
    }

    /**
     * @description Verifies that inserting a Recurring Donation with Status mapped to Closed does not create an Installment Opportunity
     */
    @IsTest
    private static void shouldNotCreateAnInstallmentOppWhenRDStatusIsMappedToClosed() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        String newStatus = 'Canceled';

        RD2_StatusMapper_TEST.Stub mapperStub = new RD2_StatusMapper_TEST.Stub()
            .withMapping(newStatus, RD2_Constants.STATUS_CLOSED);
        RD2_StatusMapper.statusMapper = (RD2_StatusMapper) Test.createStub(
            RD2_StatusMapper.Class,
            mapperStub
        );

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact())
            .withStatus(newStatus)
            .withDayOfMonth('20')
            .withCalculateNextDonationDate()
            .build();

        rd = TEST_RecurringDonationBuilder.mockRecurringDonationFullQueryResult(rd, new List<Opportunity>(), new RD2_ScheduleService().buildNewSchedules(rd));

        Test.startTest();
        RD2_OpportunityEvaluationService evalService = new RD2_OpportunityEvaluationService();
        evalService.rds = new List<npe03__Recurring_Donation__c>{ rd};
        Test.stopTest();

        System.assertEquals(false, evalService.isNewOpportunityCandidate(rd),
            'RD with status mapped to Closed state should not have a new installment Opp created');
    }

    /**
     * @description Verifies that an open Opportunity representing the next installment
     * has its CloseDate changed when the Recurring Donation schedule changes to a date
     * outside the default match range.
     */
    @IsTest
    private static void shouldUpdateOppCloseDateWhenNextDonationChangedFromCurrentDate() {
        //set current date override
        final Date today = Date.newInstance(2020, 3, 20);
        final Date newCloseDate = Date.newInstance(2020, 4, 1);
        final String dayOfMonthOriginal = '20';
        final String dayOfMonthNew = '1';
        RD2_ScheduleService.currentDate = today;

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        RD2_Settings_TEST.configureForASyncFirstOpportunityCreate();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact().Id)
            .withDayOfMonth(dayOfMonthOriginal)
            .build();
        insert rd;
        rd.npe03__Next_Payment_Date__c = today;
        update rd;

        TEST_OpportunityBuilder oppBuilder = TEST_OpportunityBuilder.getOpportunityBuilder(rd);
        List<Opportunity> opps = new List<Opportunity>{
            oppBuilder
                .withName()
                .withCloseDate(today)
                .withOpenStage()
                .build()
        };
        insert opps;

        Test.startTest();

        rd.StartDate__c = today;
        rd.Day_of_Month__c = dayOfMonthNew;
        update rd;

        Test.stopTest();

        List<Opportunity> opportunities = oppGateway.getRecords(rd);

        System.assertEquals(1, opportunities.size(), 'The number of returned Opps should match');

        Opportunity opp = opportunities[0];
        System.assertEquals(false, opp.isClosed, 'The Opp should stay open');
        System.assertEquals(newCloseDate, opp.CloseDate, 'The Opp close date should match the new date');
        System.assertEquals(RD_AMOUNT, opp.Amount, 'The Opp Amount should be unchanged');

        List<Error__c> errors = errorGateway.getRecords();
        System.assertEquals(0, errors.size(), 'No error should be created: ' + errors);
    }

    /**
     * @description Verifies that the next open Opportunity has its CloseDate changed
     * when a Recurring Donation is changed to a date less than its original date
     * when it is outside the normal match window.
     */
    @IsTest
    private static void shouldUpdateOppCloseDateWhenNextDonationChangedFromFutureDate() {
        //set current date override
        final Date today = Date.newInstance(2020, 3, 20);
        final Date nextDonationDate = Date.newInstance(2020, 4, 20);
        final Date newCloseDate = Date.newInstance(2020, 4, 1);
        final String dayOfMonthOriginal = '20';
        final String dayOfMonthNew = '1';
        RD2_ScheduleService.currentDate = today;

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        RD2_Settings_TEST.configureForASyncFirstOpportunityCreate();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact().Id)
            .withDayOfMonth(dayOfMonthOriginal)
            .build();
        insert rd;
        rd.npe03__Next_Payment_Date__c = nextDonationDate;
        update rd;

        TEST_OpportunityBuilder oppBuilder = TEST_OpportunityBuilder.getOpportunityBuilder(rd);
        List<Opportunity> opps = new List<Opportunity>{
            oppBuilder
                .withName()
                .withCloseDate(today)
                .withClosedWonStage()
                .build(),
            oppBuilder
                .withName()
                .withCloseDate(nextDonationDate)
                .withOpenStage()
                .build()
        };
        insert opps;

        Test.startTest();

        rd.StartDate__c = today;
        rd.Day_of_Month__c = dayOfMonthNew;
        update rd;

        Test.stopTest();

        Map<Id, Opportunity> oppById = new Map<Id, Opportunity>(oppGateway.getRecords(rd));

        System.assertEquals(2, oppById.size(), 'The number of returned Opps should match');

        Opportunity opp = oppById.get(opps[0].Id);
        System.assertEquals(true, opp.isClosed && opp.isWon, 'The first Opp should stay Closed Won');
        System.assertEquals(today, opp.CloseDate, 'The first Opp Close Date should be unchanged');
        System.assertEquals(RD_AMOUNT, opp.Amount, 'The first Opp Amount should be unchanged');

        opp = oppById.get(opps[1].Id);
        System.assertEquals(false, opp.isClosed, 'The second Opp should stay open');
        System.assertEquals(newCloseDate, opp.CloseDate, 'The second Opp Close Date should match the new date');
        System.assertEquals(RD_AMOUNT, opp.Amount, 'The second Opp Amount should be unchanged');

        List<Error__c> errors = errorGateway.getRecords();
        System.assertEquals(0, errors.size(), 'No error should be created: ' + errors);
    }

    /**
     * @description Verifies that an Opportunity representing the next installment is
     * changed when a schedule changes when two open opportunities exist.
     */
    @IsTest
    private static void shouldUpdateOppCloseDateWhenTwoOpenOpportunitiesExist() {
        //set current date override
        final Date today = Date.newInstance(2020, 3, 20);
        final Date manualDonationDate = Date.newInstance(2020, 3, 25);
        final Date newCloseDate = Date.newInstance(2020, 4, 1);
        final String dayOfMonthOriginal = '20';
        final String dayOfMonthNew = '1';
        RD2_ScheduleService.currentDate = today;

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        RD2_Settings_TEST.configureForASyncFirstOpportunityCreate();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact().Id)
            .withDayOfMonth(dayOfMonthOriginal)
            .build();
        insert rd;
        rd.npe03__Next_Payment_Date__c = today;
        update rd;

        TEST_OpportunityBuilder oppBuilder = TEST_OpportunityBuilder.getOpportunityBuilder(rd);
        List<Opportunity> opps = new List<Opportunity>{
            oppBuilder
                .withName()
                .withCloseDate(today)
                .withOpenStage()
                .build(),
            oppBuilder
                .withName()
                .withCloseDate(manualDonationDate)
                .withOpenStage()
                .build()
        };
        insert opps;

        Test.startTest();

        rd.StartDate__c = today;
        rd.Day_of_Month__c = dayOfMonthNew;
        update rd;

        Test.stopTest();

        Map<Id, Opportunity> oppById = new Map<Id, Opportunity>(oppGateway.getRecords(rd));

        System.assertEquals(2, oppById.size(), 'The number of returned Opps should match');

        Opportunity opp = oppById.get(opps[0].Id);
        System.assertEquals(false, opp.isClosed, 'The first Opp should stay open');
        System.assertEquals(newCloseDate, opp.CloseDate, 'The first Opp Close Date should match the new date');
        System.assertEquals(RD_AMOUNT, opp.Amount, 'The first Opp Amount should be unchanged');

        opp = oppById.get(opps[1].Id);
        System.assertEquals(false, opp.isClosed, 'The second Opp should stay open');
        System.assertEquals(manualDonationDate, opp.CloseDate, 'The second Opp Close Date should be unchanged');
        System.assertEquals(RD_AMOUNT, opp.Amount, 'The second Opp Amount should be unchanged');

        List<Error__c> errors = errorGateway.getRecords();
        System.assertEquals(0, errors.size(), 'No error should be created: ' + errors);
    }

    /**
    * @description Verifies that only fields in Custom Field Mapper or is mandatory for calculation should be included
    */
    @IsTest
    private static void shouldOnlyQueryMandatoryAndCustomFieldMappingFields() {
        RD2_CustomFieldMapper_TEST.createCustomFieldMapping(
            String.valueOf(npe03__Recurring_Donation__c.npe03__Open_Ended_Status__c)
            ,String.valueOf(Opportunity.Name)
        );

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact().Id)
            .build();

        insert rd;
                
        Test.startTest();
        RD2_OpportunityEvaluationService service = new RD2_OpportunityEvaluationService().withRds(new Set<Id>{rd.Id});
        Set<String> queriedFields = service.rds[0].getPopulatedFieldsAsMap().keySet();
        Test.stopTest();

        System.assert(queriedFields.contains(String.valueOf(npe03__Recurring_Donation__c.npe03__Open_Ended_Status__c)),
            'RD field used in the custom mapping should be queried.');
        System.assert(queriedFields.contains(String.valueOf(npe03__Recurring_Donation__c.RecurringType__c)),
            'RD field that is mandatory for calculation should be queried by default.');
        System.assert(queriedFields.contains('npe03__Schedule_Type__c') == false,
            'RD legacy field not used in the custom mapping should not be queried.');
        
    }

    /**
    * @description Verifies no Opportunity is created when "Disable First Installment" on RD is true,
    * and the org setting NPSP Installment Auto Creation is "Always Create Next Installment".
    */
    @IsTest
    private static void shouldNotCreateFirstInstallmentWhenDisableFirstInstallmentIsTrue() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        RD2_Settings_TEST.setUpConfiguration(new Map<String, Object> {
            'InstallmentOppAutoCreateOption__c' => OPTION_NAME_ALWAYS_CREATE_NEXT
        });

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact().Id)
            .withFirstInstallmentDisabled()
            .build();

        Test.startTest();
        insert rd;
        Test.stopTest();

        rd = rdGateway.getRecord(rd.Id);
        List<Opportunity> opportunities = oppGateway.getRecords(rd);

        System.assert(rd.DisableFirstInstallment__c, 'Disable First Installment should be true');
        System.assert(opportunities.isEmpty(),
            'No Opportunity should be created when the Disable First Installment is true');
    }

    /**
    * @description Verifies that when RD's next installment is skipped(paused),
    * the RD status will be updated to Pause when the nightly batch job runs
    */
    @isTest
    private static void shouldUpdateRDToPauseStatusWhenNextInstallmentIsPaused() {
        Date today = Date.newInstance(2020, 1, 1);
        Date pauseDate = Date.newInstance(2020, 2, 1);
        RD2_ScheduleService.currentDate = today;

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact().Id)
            .withDayOfMonth('1')
            .build();

        insert rd;

        RD2_ScheduleService_TEST.createPauseSchedule(rd.Id, pauseDate, pauseDate);

        Test.startTest();
        new RD2_OpportunityEvaluationService()
            .withRds(new Set<Id>{ rd.Id })
            .withCurrentDate(today.addDays(10))
            .evaluateOpportunities();
        Test.stopTest();

        rd = rdGateway.getRecord(rd.Id);

        System.assertEquals(RD2_Constants.STATUS_PAUSED, rd.Status__c,
            'Rd status should be paused when the next installment is paused');
        System.assertEquals(RD2_ScheduleService_TEST.PAUSE_REASON, rd.ClosedReason__c,
            'The pause reason shuold be updated according to the user selection');
    }

    /**
    * @description Verifies that when the RD is in the middle of pause period
    * the RD status should stay as Paused when the nightly batch job runs
    */
    @isTest
    private static void shouldStayInPauseWhenRDIsInPausedPeriod() {
        Date today = Date.newInstance(2020, 1, 1);
        Date pauseStartDate = Date.newInstance(2020, 2, 1);
        Date pauseEndDate = Date.newInstance(2020, 3, 1);
        RD2_ScheduleService.currentDate = today;

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact().Id)
            .withDayOfMonth('1')
            .withStatusPaused()
            .build();

        insert rd;

        RD2_ScheduleService_TEST.createPauseSchedule(rd.Id, pauseStartDate, pauseEndDate);

        Test.startTest();
        new RD2_OpportunityEvaluationService()
            .withRds(new Set<Id>{ rd.Id })
            .withCurrentDate(pauseStartDate.addDays(10))
            .evaluateOpportunities();
        Test.stopTest();

        rd = rdGateway.getRecord(rd.Id);

        System.assertEquals(RD2_Constants.STATUS_PAUSED, rd.Status__c,
            'Rd status should be paused when the next installment is paused');
        System.assertEquals(RD2_ScheduleService_TEST.PAUSE_REASON, rd.ClosedReason__c,
            'The pause reason shuold be updated according to the user selection');
    }

    /**
    * @description Verifies that when RD pause period is over,
    * RD status should be updated to Active when the nightly batch job runs
    */
    @isTest
    private static void shouldUpdateRDToActiveWhenPausedPeriodIsOver() {
        Date today = Date.newInstance(2020, 1, 1);
        Date pauseStartDate = Date.newInstance(2020, 2, 1);
        Date pauseEndDate = Date.newInstance(2020, 3, 1);
        RD2_ScheduleService.currentDate = today;

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact().Id)
            .withDayOfMonth('1')
            .withStatusPaused()
            .build();

        insert rd;

        RD2_ScheduleService_TEST.createPauseSchedule(rd.Id, pauseStartDate, pauseEndDate);

        Test.startTest();
        new RD2_OpportunityEvaluationService()
            .withRds(new Set<Id>{ rd.Id })
            .withCurrentDate(pauseEndDate.addDays(1))
            .evaluateOpportunities();
        Test.stopTest();

        rd = rdGateway.getRecord(rd.Id);

        System.assertEquals(RD2_Constants.STATUS_ACTIVE, rd.Status__c,
            'Rd status should be updated to Active when the next pause is over');
        System.assertEquals(null, rd.ClosedReason__c,
            'The pause reason shuold be clear out when pause is over');
    }

        /**
    * @description Verifies that when RD is entering the paused,
    * the next installment will be created with close date after the pause
    */
    @isTest
    private static void shouldSkippedPausedInstallmentsWhenRDStatusIsPause() {
        Date today = Date.newInstance(2020, 1, 1);
        Date pauseStartDate = Date.newInstance(2020, 2, 1);
        Date pauseEndDate = Date.newInstance(2020, 3, 1);
        RD2_ScheduleService.currentDate = today;

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact().Id)
            .withDayOfMonth('1')
            .withStatusPaused()
            .build();

        insert rd;
        RD2_ScheduleService_TEST.createPauseSchedule(rd.Id, pauseStartDate, pauseEndDate);

        Test.startTest();
        new RD2_OpportunityEvaluationService()
            .withRds(new Set<Id>{ rd.Id })
            .withCurrentDate(today.addDays(1))
            .evaluateOpportunities();
        Test.stopTest();

        rd = rdGateway.getRecord(rd.Id);
        List<Opportunity> installments = oppGateway.getRecords(rd);
        Set<Datetime> installmentsClosedDate = UTIL_SObject.extractDatetime(installments, Opportunity.CloseDate);

        System.assert(installmentsClosedDate.contains(pauseEndDate.addMonths(1)),
            'An installment with close date after pause shuold be created');

            System.assert(!installmentsClosedDate.contains(pauseStartDate),
            'No installment should be created with close date during the pause');
    }

    /**
    * @description Verifies that when the Open Opportunity Behavior is set to Closed Lost,
    * All mathcing installments should be set to Closed Lost when RD is converted to Elevate
    */
    @isTest
    private static void shouldCloseAllOpportunitiesForConvertedElevateRDWhenAutoSettingIsClosed() {
        RD2_ScheduleService.currentDate = START_DATE;

        RD2_Settings_TEST.setUpConfiguration(new Map<String, Object> {
            'npe03__Open_Opportunity_Behavior__c' => RD2_Constants.CloseActions.Mark_Opportunities_Closed_Lost.name()
        });

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        PS_IntegrationServiceConfig_TEST.Stub configStub = new PS_IntegrationServiceConfig_TEST.Stub()
            .withIsIntegrationEnabled(true);

        setUpElevateIntegration(configStub);
        

        npe03__Recurring_Donation__c recurringDonation = getRecurringDonationBuilder(getContact())
            .withDayOfMonth(String.valueOf(START_DATE.day()))
            .withPaymentMethod(RD2_Constants.PAYMENT_PICKLIST_VALUE_CARD)
            .build();
        insert recurringDonation;

        TEST_OpportunityBuilder oppBuilder = TEST_OpportunityBuilder.getOpportunityBuilder(recurringDonation);
        List<Opportunity> opportunities = new List<Opportunity>{
            oppBuilder
                .withName()
                .withCloseDate(START_DATE.addMonths(1)) //match nex month installment
                .withOpenStage()
                .build(),
            oppBuilder
                .withName()
                .withCloseDate(START_DATE.addMonths(1).addDays(15)) //unmatch
                .withOpenStage()
                .build(),
            oppBuilder
                .withName()
                .withCloseDate(START_DATE.addMonths(1).addDays(10)) //unmatch
                .withOpenStage()
                .build()
        };
        insert opportunities;

        recurringDonation.CommitmentId__c = MOCK_COMMITMENT_ID;

        Test.startTest();
        update recurringDonation;
        Test.stopTest();

        List<Opportunity> queriedOpportunities = oppGateway.getRecords(recurringDonation);

        System.assertEquals(4, queriedOpportunities.size(), 'There should be total of 3 future opps on the RD');

        for (Opportunity queriedOpportunity : queriedOpportunities) {
            System.assertEquals('Closed Lost', queriedOpportunity.StageName,
                'The matching installment opportunity should be mark as close lost');
        }
    }

    /**
    * @description Verifies that when the Open Opportunity Behavior is set to Delete,
    * All matching installments should be Delete when RD is converted to Elevate
    */
    @isTest
    private static void shouldDeleteAllOpportunitiesForConvertedElevateRDWhenAutoSettingIsDelete() {
        RD2_ScheduleService.currentDate = START_DATE;

        RD2_Settings_TEST.setUpConfiguration(new Map<String, Object> {
            'npe03__Open_Opportunity_Behavior__c' => RD2_Constants.CloseActions.Delete_Open_Opportunities.name()
        });

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        PS_IntegrationServiceConfig_TEST.Stub configStub = new PS_IntegrationServiceConfig_TEST.Stub()
            .withIsIntegrationEnabled(true);

        setUpElevateIntegration(configStub);
        

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact())
            .withDayOfMonth(String.valueOf(START_DATE.day()))
            .withPaymentMethod('Credit Card')
            .build();
        insert rd;

        TEST_OpportunityBuilder oppBuilder = TEST_OpportunityBuilder.getOpportunityBuilder(rd);
        List<Opportunity> opps = new List<Opportunity>{
            oppBuilder
                .withName()
                .withCloseDate(START_DATE.addMonths(1)) //match nex month installment
                .withOpenStage()
                .build(),
            oppBuilder
                .withName()
                .withCloseDate(START_DATE.addMonths(1).addDays(15)) //unmatch
                .withOpenStage()
                .build(),
            oppBuilder
                .withName()
                .withCloseDate(START_DATE.addMonths(1).addDays(10)) //unmatch
                .withOpenStage()
                .build()
        };
        insert opps;

        rd.CommitmentId__c = MOCK_COMMITMENT_ID;

        Test.startTest();
        update rd;
        Test.stopTest();

        List<Opportunity> queriedOpps = oppGateway.getRecords(rd);

        System.assertEquals(0, queriedOpps.size(), 'There should be no opportunities left on the RD');
    }

    /**
    * @description Verifies that when the Open Opportunity Behavior is set to No Action,
    * All matching installments should stay the same when RD is converted to Elevate
    */
    @isTest
    private static void shouldLeaveInstallmentMatchingOppsUntouchForConvertedElevateRDWhenAutoSettingIsNoAction() {
        RD2_ScheduleService.currentDate = START_DATE;

        RD2_Settings_TEST.setUpConfiguration(new Map<String, Object> {
            'npe03__Open_Opportunity_Behavior__c' => RD2_Constants.CloseActions.No_Action.name()
        });

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        PS_IntegrationServiceConfig_TEST.Stub configStub = new PS_IntegrationServiceConfig_TEST.Stub()
            .withIsIntegrationEnabled(true);

        setUpElevateIntegration(configStub);
        

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact())
            .withDayOfMonth(String.valueOf(START_DATE.day()))
            .withPaymentMethod('Credit Card')
            .build();
        insert rd;

        TEST_OpportunityBuilder oppBuilder = TEST_OpportunityBuilder.getOpportunityBuilder(rd);
        List<Opportunity> opps = new List<Opportunity>{
            oppBuilder
                .withName()
                .withCloseDate(START_DATE.addMonths(1)) //match nex month installment
                .withOpenStage()
                .build(),
            oppBuilder
                .withName()
                .withCloseDate(START_DATE.addMonths(1).addDays(15)) //unmatch
                .withOpenStage()
                .build(),
            oppBuilder
                .withName()
                .withCloseDate(START_DATE.addMonths(1).addDays(10)) //unmatch
                .withOpenStage()
                .build()
        };
        insert opps;

        rd.CommitmentId__c = MOCK_COMMITMENT_ID;

        Test.startTest();
        update rd;
        Test.stopTest();

        List<Opportunity> queriedOpps = oppGateway.getRecords(rd);

        System.assertEquals(4, queriedOpps.size(), 'There should be total of 4 future opps on the RD');
        
        
        System.assertEquals(false, queriedOpps[0].IsClosed,
            'The matching installment opportunity should stay open');
        System.assertEquals(false, queriedOpps[1].IsClosed,
            'The matching installment opportunity should stay open');
        System.assertEquals(false, queriedOpps[2].IsClosed,
            'The non matching installment opportunity should stay open');
        System.assertEquals(false, queriedOpps[3].IsClosed,
            'The non matching installment opportunity should stay open');
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
            .withAmount(RD_AMOUNT)
            .withPaymentMethod(PAYMENT_CHECK)
            .withDateEstablished(START_DATE)
            .withStartDate(START_DATE)
            .withCalculateNextDonationDate();
    }

    /**
     * @description Sets up fiscal year usage configuration
     * @param isEnabled Indicates if the fiscal year should used in the calculations
     * @return void
     */
    private static void setUpUseFiscalYear(Boolean isEnabled) {
        RD2_Settings_TEST.setUpConfiguration(
            new Map<String, Object>{
                'UseFiscalYearForRecurringDonationValue__c' => isEnabled,
                'InstallmentOppFirstCreateMode__c' => RD2_Constants.FirstInstallmentOppCreateOptions.ASynchronous.name()
            }
        );
    }

    /****
    * @description Sets up a Recurring Donation used in the Elevate tests
    * @param configStub Elevate Integration Service configuration stub
    * @param commitmentId RD Commitment Id
    * @return npe03__Recurring_Donation__c
    */
    private static npe03__Recurring_Donation__c setUpElevateTestData(PS_IntegrationServiceConfig_TEST.Stub configStub, String commitmentId) {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        setUpElevateIntegration(configStub);

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact())
            .withDayOfMonth('20')
            .withCommitmentId(commitmentId)
            .withPaymentMethod('Credit Card')
            .build();

        Test.startTest();
        insert rd;
        Test.stopTest();

        return rd;
    }

    /****
    * @description Sets up Elevate environment
    * @param configStub Elevate Integration Service configuration stub
    */
    private static void setUpElevateIntegration(PS_IntegrationServiceConfig_TEST.Stub configStub) {
        RD2_ElevateIntegrationService.config = (PS_IntegrationServiceConfig) Test.createStub(PS_IntegrationServiceConfig.class, configStub);
    }
}