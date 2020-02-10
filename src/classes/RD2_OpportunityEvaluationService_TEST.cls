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

    /***
    * @description Installment Opportunities Auto Creation Setting API value 
    */
    private static final String OPTION_NAME_DISABLE_FIRST = RD2_Constants.InstallmentCreateOptions.Disable_First_Installment.name();
    private static final String OPTION_NAME_DISABLE_ALL = RD2_Constants.InstallmentCreateOptions.Disable_All_Installments.name();
    private static final String OPTION_NAME_ALWAYS_CREATE_NEXT = RD2_Constants.InstallmentCreateOptions.Always_Create_Next_Installment.name();

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
            'npe03__Open_Opportunity_Behavior__c' => closeAction
        });

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

        insert getOpportunityBuilder(rd)
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
    private static void shouldUpdateFutureOpenOppWhenRDIsUpdated() {
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
     * @description Verifies future open Opp is updated when an active RD is updated.
     * The future Closed Won Opp is not updated.
     */
    @IsTest
    private static void shouldNotUpdateFutureOpenOppCloseDateWhenRDNextDonationDateIsNotUpdated() {
        //set current date override
        final Date today = START_DATE.addDays(-1);
        RD2_ScheduleService.currentDate = today;

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact().Id).build();
        insert rd;

        TEST_OpportunityBuilder oppBuilder = getOpportunityBuilder(rd);
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
     * @description The Current and Next Year Value should be calculated when a Recurring Donation is created
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

        TEST_OpportunityBuilder oppBuilder = getOpportunityBuilder(rd);
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

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact().Id).build();
        insert rd;

        TEST_OpportunityBuilder oppBuilder = getOpportunityBuilder(rd);
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

        TEST_OpportunityBuilder oppBuilder = getOpportunityBuilder(rd);
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

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact().Id)
            .withDateEstablished(startDate)
            .withStartDate(startDate)
            .withDayOfMonth(String.valueOf(startDate.day()))
            .build();
        insert rd;

        TEST_OpportunityBuilder oppBuilder = getOpportunityBuilder(rd);
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
    private static void yearValuesShouldExcludeInstallmentWhenMatchingOppExists() {        
        //set current date override
        final Date nextCloseDate = START_DATE.addMonths(MONTHS_TO_DEC);
        final Date today = nextCloseDate.addDays(-1);
        RD2_ScheduleService.currentDate = today;

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact().Id).build();
        insert rd;

        TEST_OpportunityBuilder oppBuilder = getOpportunityBuilder(rd);
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

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact().Id).build();
        insert rd;

        TEST_OpportunityBuilder oppBuilder = getOpportunityBuilder(rd);
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
        final Date today = START_DATE.addMonths(MONTHS_TO_DEC).addDays(-1);
        RD2_ScheduleService.currentDate = today;

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact().Id).build();
        insert rd;

        TEST_OpportunityBuilder oppBuilder = getOpportunityBuilder(rd).withClosedWonStage();
        List<Opportunity> opps = new List<Opportunity>();
        for (Integer i = 0; i < MONTHS_TO_YEAR_END + 1; i++) {
            opps.add(oppBuilder
                .withName()
                .withCloseDate(START_DATE.addMonths(i))
                .build()
            );
        }
        opps.add(oppBuilder
            .withName()
            .withCloseDate(START_DATE.addMonths(MONTHS_TO_YEAR_END + 2))//Open Opp in Feb next year
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
        System.assertEquals(rd.npe03__Amount__c, rd.NextYearValue__c,//Open Opp in Feb is voided when RD is closed
            'Next Year Value should include next year Closed Won amounts when RD is Closed');
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
            .withAmount(RD_AMOUNT)
            .withPaymentMethod(PAYMENT_CHECK)
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
}