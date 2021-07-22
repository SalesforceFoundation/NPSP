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
* @description Unit Test for the data migration batch job
*
*/
@IsTest(isParallel=false)
private class RD2_DataMigration_TEST {

    private static final Date TODAY = System.today();
    private static final Date DATE_ESTABLISHED = TODAY.addMonths(-3);
    private static final Decimal AMOUNT_VALUE = 100;
    private static String LOG_CONTEXT = 'RunDataMigrationTest';
    private static Integer MIGRATION_INSTALLMENT_NUMBER_FLAG = RD2_DataMigrationBase_BATCH.MIGRATION_INSTALLMENT_NUMBER_FLAG;

    private static final TEST_SObjectGateway.RecurringDonationGateway rdGateway = new TEST_SObjectGateway.RecurringDonationGateway();
    private static final TEST_SObjectGateway.RecurringDonationScheduleGateway rdScheduleGateway = new TEST_SObjectGateway.RecurringDonationScheduleGateway();
    private static final TEST_SObjectGateway.OpportunityGateway oppGateway = new TEST_SObjectGateway.OpportunityGateway();
    private static final TEST_SObjectGateway.AsyncApexJobGateway jobGateway = new TEST_SObjectGateway.AsyncApexJobGateway();
    private static final TEST_SObjectGateway.ErrorGateway errorGateway = new TEST_SObjectGateway.ErrorGateway();

    /****
    * @description Creates data required for unit tests
    */
    @TestSetup
    private static void setUp() {
        insert UTIL_UnitTestData_TEST.getContact();
    }

    /**
     * @description Verifies that the job should run with zero records processed when
     * Enhanced Recurring Donations is not enabled
     */
    @IsTest
    private static void shouldThrowExceptionAndNotRunMigrationWhenEnablementIsOff() {
        insert getLegacyRecurringDonationBuilder(getContact().Id)
            .withId(null)
            .build();

        Exception jobException;
        try {
            Test.startTest();
            RD2_DataMigration_BATCH batch = new RD2_DataMigration_BATCH();
            Database.executeBatch(batch);
            Test.stopTest();

        } catch (Exception ex) {
            jobException = ex;
        }

        System.assertNotEquals(null, jobException,
            'The exception should be generated because enhanced Recurring Donations setting is not enabled');

        System.assert(jobException.getMessage().containsIgnoreCase(System.Label.RD2_ErrorDataMigrationJobCannotBeRun),
            'The exception message should match. Actual message: ' + jobException.getMessage());

        assertLegacyFormat(getRecords());
    }

    /**
     * @description Verifies that the job should process records for dry run migration when
     * Enhanced Recurring Donations is not enabled
     */
    @IsTest
    private static void shouldNotThrowExceptionWhenEnablementIsOffAndModeIsDryRun() {
        insert getLegacyRecurringDonationBuilder(getContact().Id)
            .withId(null)
            .build();

        System.assertEquals(false, RD2_EnablementService.isRecurringDonations2Enabled,
            'Enhanced RDs should not be enabled');

        Exception jobException;
        try {
            Test.startTest();
            RD2_DataMigrationDryRun_BATCH batch = new RD2_DataMigrationDryRun_BATCH();
            Database.executeBatch(batch);
            Test.stopTest();

        } catch (Exception ex) {
            jobException = ex;
        }

        System.assertEquals(false, RD2_EnablementService.isRecurringDonations2Enabled,
            'Enhanced RDs should not be enabled *by* Dry Run migration');

        System.assertEquals(null, jobException,
            'No exception should be generated when enhanced RDs are not enabled in dry run mode: ' + jobException);

        AsyncApexJob job = jobGateway.getRecord('RD2_DataMigrationDryRun_BATCH');
        System.assertEquals(1, job.JobItemsProcessed,
            'The batch should have run with one child batch processed'
        );

        assertLegacyFormat(getRecords());
    }

    /**
     * @description Verifies that the job should run with zero records processed when
     * RD Settings close action is set to No_Action
     */
    @IsTest
    private static void shouldThrowExceptionAndNotRunMigrationWhenCloseActionIsNoAction() {
        setCloseActionSettingsToNoAction();

        insert getLegacyRecurringDonationBuilder(getContact().Id)
            .withId(null)
            .build();

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        Exception jobException;
        try {
            Test.startTest();
            RD2_DataMigration_BATCH batch = new RD2_DataMigration_BATCH();
            Database.executeBatch(batch);
            Test.stopTest();

        } catch (Exception ex) {
            jobException = ex;
        }

        System.assertNotEquals(null, jobException,
            'The exception should be generated because RD settings close action is set to No_Action');

        System.assert(jobException.getMessage().containsIgnoreCase(System.Label.RD2_DataMigrationInvalidCloseAction),
            'The exception message should match. Actual message: ' + jobException.getMessage());

        assertLegacyFormat(getRecords());
    }

    /**
     * @description Verifies that the job should run with zero records processed for dry run migration when
     * RD Settings close action is set to No_Action
     */
    @IsTest
    private static void shouldThrowExceptionAndNotRunMigrationWhenCloseActionIsNoActionAndModeIsDryRun() {
        setCloseActionSettingsToNoAction();

        insert getLegacyRecurringDonationBuilder(getContact().Id)
            .withId(null)
            .build();

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        Exception jobException;
        try {
            Test.startTest();
            RD2_DataMigrationDryRun_BATCH batch = new RD2_DataMigrationDryRun_BATCH();
            Database.executeBatch(batch);
            Test.stopTest();

        } catch (Exception ex) {
            jobException = ex;
        }

        System.assertNotEquals(null, jobException,
            'The exception should be generated because RD settings close action is set to No_Action');

        System.assert(jobException.getMessage().containsIgnoreCase(System.Label.RD2_DataMigrationInvalidCloseAction),
            'The exception message should match. Actual message: ' + jobException.getMessage());

        assertLegacyFormat(getRecords());
    }

    /**
     * @description Verifies that the batch job ran with one record processed when
     * Enhanced Recurring Donations is enabled
     */
    @IsTest
    private static void shouldRunMigrationWhenEnablementIsOn() {
        setCloseActionSettingsToClosedLost();

        insert getLegacyRecurringDonationBuilder(getContact().Id)
            .withId(null)
            .build();

        runDataMigration();

        AsyncApexJob job = jobGateway.getRecord('RD2_DataMigration_BATCH');
        System.assertEquals(1, job.JobItemsProcessed,
            'The batch should have run with one child batch processed'
        );

        assertEnhancedFormat(getRecords());
    }

    /**
     * @description Verifies that the batch job converts Recurring Donations from legacy to enhanced format
     */
    @IsTest
    private static void shouldConvertLegacyToEnhancedRecurringDonation() {
        npe03__Recurring_Donation__c rd = getLegacyRecurringDonationBuilder(getContact().Id)
            .withId(null)
            .withScheduleTypeMultiplyValue()
            .build();
        insert rd;

        delete oppGateway.getRecords(rd);

        TEST_OpportunityBuilder oppBuilder = new TEST_OpportunityBuilder()
            .withContact(rd.npe03__Contact__c)
            .withRecurringDonation(rd.Id)
            .withAmount(rd.npe03__Amount__c);

        insert new List<Opportunity>{
            oppBuilder
                .withName()
                .withCloseDate(DATE_ESTABLISHED.addMonths(1))
                .withClosedWonStage()
                .build(),
            oppBuilder
                .withName()
                .withCloseDate(TODAY)
                .withOpenStage()
                .build(),
            oppBuilder
                .withName()
                .withCloseDate(TODAY.addMonths(1))
                .withOpenStage()
                .build()
        };

        Id jobId = runDataMigration();

        npe03__Recurring_Donation__c convertedRD = getRecords()[0];

        System.assertEquals(rd.npe03__Date_Established__c, convertedRD.npe03__Date_Established__c, 'Date Established should be unchanged');
        System.assertEquals(DATE_ESTABLISHED, convertedRD.StartDate__c, 'Effective Date should match Date Established');
        System.assertEquals(rd.Day_of_Month__c, convertedRD.Day_of_Month__c, 'Day of Month should be unchanged');

        System.assertEquals(rd.npe03__Amount__c, convertedRD.npe03__Amount__c, 'Amount should be unchanged');
        System.assertEquals(1, convertedRD.InstallmentFrequency__c, 'Installment Frequency should match');
        System.assertEquals(RD2_Constants.INSTALLMENT_PERIOD_MONTHLY, convertedRD.npe03__Installment_Period__c,
            'Installment Period should be unchanged');

        System.assertEquals(RD2_Constants.RECURRING_TYPE_OPEN, convertedRD.RecurringType__c, 'Recurring Type should match');
        System.assertEquals(RD2_Constants.STATUS_ACTIVE, convertedRD.Status__c, 'Status should match');

        List<Error__c> errors = errorGateway.getRecords();
        System.assertEquals(0, errors.size(), 'No error should be logged: ' + errors);

        assertBatchSummarySuccess(jobId, 1);
    }


    /**
     * @description Verifies that the data migration recalculates roll ups when disable rollups is not checked
     */
    @isTest
    private static void shouldRecalcaluteRollupsOnRdWhenDisableRollupsIsNotSet() {
        setCloseActionSettingsToClosedLost();

        npe03__Recurring_Donation__c rd = getLegacyRecurringDonationBuilder(getContact().Id)
            .withId(null)
            .withDateEstablished(DATE_ESTABLISHED.addMonths(1))
            .build();
        insert rd;
        //set two opportunities in the rd to closed won for rollup calculations
        setRdOppsToClosedWonForRollupTests(rd, 2);

        rd = getRecords()[0];
        rd.npe03__Total_Paid_Installments__c = null;
        rd.npe03__Paid_Amount__c = null;
        update rd;

        RD2_OpportunityEvaluation_TEST.configureForBatchJobWithRollupDisableTests(false);

        Id jobId = runDataMigration();
        assertEnhancedFormat(getRecords());

        rd = getRecords()[0];

        RD2_DataMigrationMapper mapper = new RD2_DataMigrationMapper(rd);
        System.assertEquals(true, mapper.isConverted(),
            'This RD should be in Enhanced Recurring Donation format');
        System.assertEquals(200, rd.npe03__Paid_Amount__c,
            'The paid amount should be recalculated by CRLP to 200');
        System.assertEquals(2, rd.npe03__Total_Paid_Installments__c,
            'The total paid installments should be recalculated by CRLP to 2');

    }

    /**
     * @description Verifies that the data migration do not recalculate roll ups when disable rollups is checked
     */
    @isTest
    private static void shouldNotRecalcaluteRollupsOnRdWhenDisableRollupsIsSet() {
        setCloseActionSettingsToClosedLost();

        npe03__Recurring_Donation__c rd = getLegacyRecurringDonationBuilder(getContact().Id)
            .withId(null)
            .withDateEstablished(DATE_ESTABLISHED.addMonths(1))
            .build();
        insert rd;
        //set two opportunities in the rd to closed won for rollup calculations
        setRdOppsToClosedWonForRollupTests(rd, 2);

        rd = getRecords()[0];
        rd.npe03__Total_Paid_Installments__c = null;
        rd.npe03__Paid_Amount__c = null;
        update rd;

        RD2_OpportunityEvaluation_TEST.configureForBatchJobWithRollupDisableTests(true);

        Id jobId = runDataMigration();
        assertEnhancedFormat(getRecords());

        rd = getRecords()[0];

        RD2_DataMigrationMapper mapper = new RD2_DataMigrationMapper(rd);

        System.assertEquals(true, mapper.isConverted(),
            'This RD should be in Enhanced Recurring Donation format');
        System.assertEquals(null, rd.npe03__Paid_Amount__c,
            'The paid amount should not be recalculated by CRLP as disablerollups are set');
        System.assertEquals(null, rd.npe03__Total_Paid_Installments__c,
            'The total paid installments should not be recalculated by CRLP as disablerollups are set');

    }

    /**
     * @description Verifies that a legacy RD is recognized correctly
     */
    @IsTest
    private static void shouldRecognizeAsLegacyFormat() {
        npe03__Recurring_Donation__c rd = getLegacyRecurringDonationBuilder().build();

        RD2_DataMigrationMapper mapper = new RD2_DataMigrationMapper(rd);

        System.assertEquals(false, mapper.isConverted(),
            'This RD should be in legacy Recurring Donation format');
    }

    /**
     * @description Verifies that an Enhanced Recurring Donations format RD is recognized correctly
     */
    @IsTest
    private static void shouldRecognizeAsEnhancedFormat() {
        npe03__Recurring_Donation__c rd = getEnhancedRecurringDonationBuilder().build();

        RD2_DataMigrationMapper mapper = new RD2_DataMigrationMapper(rd);

        System.assertEquals(true, mapper.isConverted(),
            'This RD should be in Enhanced Recurring Donation format');
    }

    /**
     * @description Verifies that converted Recurring Donation is in enhanced Recurring Donation format
     */
    @IsTest
    private static void shouldRecognizeConvertedRDAsEnhancedFormat() {
        npe03__Recurring_Donation__c rd = getLegacyRecurringDonationBuilder().build();

        RD2_DataMigrationMapper mapper = new RD2_DataMigrationMapper(rd);
        mapper.convertToEnhancedRD();

        System.assertEquals(true, mapper.isConverted(),
            'This RD should be in Enhanced Recurring Donation format');
    }

    /**
     * @description Verifies Installment Frequency is set to 3 when Installment Period is Quarterly
     */
    @IsTest
    private static void shouldSetInstallmentFrequencyToThreeWhenInstallmentPeriodIsQuarterly() {

        npe03__Recurring_Donation__c convertedRD = new RD2_DataMigrationMapper(
            getLegacyRecurringDonationBuilder()
                .withInstallmentPeriodQuarterly()
                .build()
        ).convertToEnhancedRD();

        System.assertEquals(3, convertedRD.InstallmentFrequency__c, 'Installment Frequency should match');
        System.assertEquals(RD2_Constants.INSTALLMENT_PERIOD_MONTHLY, convertedRD.npe03__Installment_Period__c,
            'Installment Period should match');

        convertedRD = new RD2_DataMigrationMapper(convertedRD).convertToEnhancedRD();
        System.assertEquals(3, convertedRD.InstallmentFrequency__c,
            'Should not change Installment Frequency when the converted RD is picked up by data migration again');
    }

    /**
     * @description Verifies Installment Frequency is set to 1 when Installment Period is Yearly
     */
    @IsTest
    private static void shouldSetInstallmentFrequencyToOneWhenInstallmentPeriodIsYearly() {

        npe03__Recurring_Donation__c convertedRD = new RD2_DataMigrationMapper(
            getLegacyRecurringDonationBuilder()
                .withInstallmentPeriodYearly()
                .build()
        ).convertToEnhancedRD();

        System.assertEquals(1, convertedRD.InstallmentFrequency__c, 'Installment Frequency should match');
        System.assertEquals(RD2_Constants.INSTALLMENT_PERIOD_YEARLY, convertedRD.npe03__Installment_Period__c,
            'Installment Period should be unchanged');
    }

    /**
     * @description Verifies Installment Frequency is set to 1 when Installment Period is Monthly
     */
    @IsTest
    private static void shouldSetInstallmentFrequencyToOneWhenInstallmentPeriodIsMonthly() {

        npe03__Recurring_Donation__c convertedRD = new RD2_DataMigrationMapper(
            getLegacyRecurringDonationBuilder()
                .withInstallmentPeriodMonthly()
                .build()
        ).convertToEnhancedRD();

        System.assertEquals(1, convertedRD.InstallmentFrequency__c, 'Installment Frequency should match');
        System.assertEquals(RD2_Constants.INSTALLMENT_PERIOD_MONTHLY, convertedRD.npe03__Installment_Period__c,
            'Installment Period should be unchanged');
    }

    /**
     * @description Verifies Installment Frequency is set to 1 when Installment Period is Weekly
     */
    @IsTest
    private static void shouldSetInstallmentFrequencyToOneWhenInstallmentPeriodIsWeekly() {

        npe03__Recurring_Donation__c convertedRD = new RD2_DataMigrationMapper(
            getLegacyRecurringDonationBuilder()
                .withInstallmentPeriodWeekly()
                .build()
        ).convertToEnhancedRD();

        System.assertEquals(1, convertedRD.InstallmentFrequency__c, 'Installment Frequency should match');
        System.assertEquals(RD2_Constants.INSTALLMENT_PERIOD_WEEKLY, convertedRD.npe03__Installment_Period__c,
            'Installment Period should be unchanged');
    }

    /**
     * @description Verifies Installment Frequency is set to 1 when Installment Period is "1st and 15th"
     */
    @IsTest
    private static void shouldSetInstallmentFrequencyToOneWhenInstallmentPeriodIs1stAnd15th() {

        npe03__Recurring_Donation__c convertedRD = new RD2_DataMigrationMapper(
            getLegacyRecurringDonationBuilder()
                .withInstallmentPeriod(RD_Constants.INSTALLMENT_PERIOD_FIRST_AND_FIFTEENTH)
                .build()
        ).convertToEnhancedRD();

        System.assertEquals(1, convertedRD.InstallmentFrequency__c, 'Installment Frequency should match');
    }

    /**
     * @description Verifies an exception is thrown when Installment Period cannot be converted
     */
    @IsTest
    private static void shouldThrowExceptionWhenInstallmentPeriodCannotBeConverted() {
        String installmentPeriod = 'foo';

        npe03__Recurring_Donation__c rd = getLegacyRecurringDonationBuilder()
            .withInstallmentPeriod(installmentPeriod)
            .build();

        Exception actualException;
        try {
            rd = new RD2_DataMigrationMapper(rd).convertToEnhancedRD();

        } catch (Exception e) {
            actualException = e;
        }

        String expectedMessage = String.format(
            System.Label.RD2_DataMigrationInvalidInstallmentPeriod,
            new String[]{ installmentPeriod }
        );

        System.assertNotEquals(null, actualException, 'An exception should be generated');
        System.assertEquals(expectedMessage, actualException.getMessage(), 'An exception message should match');
        System.assertEquals(null, rd.InstallmentFrequency__c, 'Installment Frequency should not be set');
    }

    /**
     * @description Verifies custom Installment Period "Days" is converted
     */
    @IsTest
    private static void shouldConvertCustomInstallmentIncrementDays() {
        String installmentIncrement = 'Days';
        Integer installmentFrequency = 4;

        testCustomInstallmentConversion(installmentIncrement, installmentFrequency, RD2_Constants.INSTALLMENT_PERIOD_DAILY);
    }
    /**
     * @description Verifies custom Installment Period "Weeks" is converted
     */
    @IsTest
    private static void shouldConvertCustomInstallmentIncrementWeeks() {
        String installmentIncrement = 'Weeks';
        Integer installmentFrequency = 3;

        testCustomInstallmentConversion(installmentIncrement, installmentFrequency, RD2_Constants.INSTALLMENT_PERIOD_WEEKLY);
    }

    /**
     * @description Verifies custom Installment Period "Months" is converted
     */
    @IsTest
    private static void shouldConvertCustomInstallmentIncrementMonths() {
        String installmentIncrement = 'Months';
        Integer installmentFrequency = 2;

        testCustomInstallmentConversion(installmentIncrement, installmentFrequency, RD2_Constants.INSTALLMENT_PERIOD_MONTHLY);
    }

    /**
     * @description Verifies custom Installment Period "Years" is converted
     */
    @IsTest
    private static void shouldConvertCustomInstallmentIncrementYears() {
        String installmentIncrement = 'Years';
        Integer installmentFrequency = 1;

        testCustomInstallmentConversion(installmentIncrement, installmentFrequency, RD2_Constants.INSTALLMENT_PERIOD_YEARLY);
    }

    /**
     * @description Verifies custom Installment Period is converted
     * @param installmentIncrement Custom Installment Increment
     * @param installmentFrequency Custom Installment Frequency
     * @param expectedInstallmentPeriod Expected converted Installment Period
     * @return void
     */
    private static void testCustomInstallmentConversion(String installmentIncrement, Integer installmentFrequency, String expectedInstallmentPeriod) {

        npe03__Custom_Installment_Settings__c installment = createCustomInstallmentSettings(installmentIncrement, installmentFrequency);

        npe03__Recurring_Donation__c convertedRD = new RD2_DataMigrationMapper(
            getLegacyRecurringDonationBuilder()
                .withInstallmentPeriod(installment.Name)
                .build()
        ).convertToEnhancedRD();

        System.assertEquals(expectedInstallmentPeriod, convertedRD.npe03__Installment_Period__c, 'Installment Period should match');
        System.assertEquals(installmentFrequency, convertedRD.InstallmentFrequency__c, 'Installment Frequency should match');
    }

    /**
     * @description Verifies Amount is set from Installment Amount when Schedule Type is "Divide By"
     */
    @IsTest
    private static void shouldSetAmountFromInstallmentAmountWhenScheduleTypeIsDivideBy() {
        Integer installments = 4;
        npe03__Recurring_Donation__c rd = getLegacyRecurringDonationBuilder(getContact().Id)
            .withId(null)
            .withInstallmentPeriodYearly()
            .withPlannedInstallments(installments)
            .withScheduleType(RD_Constants.SCHEDULE_TYPE_DIVIDE_BY)
            .withOpenEndedStatusNone()
            .build();
        insert rd;

        npe03__Recurring_Donation__c convertedRD = new RD2_DataMigrationMapper(getRecords()[0])
            .convertToEnhancedRD();

        System.assertEquals(AMOUNT_VALUE / installments, convertedRD.npe03__Amount__c, 'Amount should be copied from Installment Amount');
        System.assertEquals(RD2_Constants.RECURRING_TYPE_FIXED, convertedRD.RecurringType__c, 'Recurring Type should be Fixed');
        System.assertEquals(installments, convertedRD.npe03__Installments__c, 'Number of Planned Installments should be unchanged');
    }

    /**
     * @description Verifies Amount is unchanged when Schedule Type is "Multiply By"
     */
    @IsTest
    private static void shouldNotChangeAmountWhenScheduleTypeIsMultiplyBy() {
        Integer installments = 4;
        npe03__Recurring_Donation__c rd = getLegacyRecurringDonationBuilder(getContact().Id)
            .withId(null)
            .withInstallmentPeriodYearly()
            .withPlannedInstallments(installments)
            .withScheduleType(RD_Constants.SCHEDULE_TYPE_MULTIPLY_BY)
            .withOpenEndedStatusNone()
            .build();
        insert rd;

        npe03__Recurring_Donation__c convertedRD = new RD2_DataMigrationMapper(getRecords()[0])
            .convertToEnhancedRD();

        System.assertEquals(AMOUNT_VALUE, convertedRD.npe03__Amount__c, 'Amount should be unchanged');
        System.assertEquals(RD2_Constants.RECURRING_TYPE_FIXED, convertedRD.RecurringType__c, 'Recurring Type should be Fixed');
        System.assertEquals(installments, convertedRD.npe03__Installments__c, 'Number of Planned Installments should be unchanged');
    }

    /**
     * @description Verifies Amount is set from Installment Amount when Schedule Type is null
     */
    @IsTest
    private static void shouldSetAmountFromInstallmentAmountWhenScheduleTypeIsNull() {
        Integer installments = 4;
        npe03__Recurring_Donation__c rd = getLegacyRecurringDonationBuilder(getContact().Id)
            .withId(null)
            .withInstallmentPeriodYearly()
            .withPlannedInstallments(installments)
            .withScheduleType(null)
            .withOpenEndedStatusNone()
            .build();
        insert rd;

        npe03__Recurring_Donation__c convertedRD = new RD2_DataMigrationMapper(getRecords()[0])
            .convertToEnhancedRD();

        System.assertEquals(AMOUNT_VALUE / installments, convertedRD.npe03__Amount__c, 'Amount should be copied from Installment Amount');
        System.assertEquals(RD2_Constants.RECURRING_TYPE_FIXED, convertedRD.RecurringType__c, 'Recurring Type should be Fixed');
        System.assertEquals(installments, convertedRD.npe03__Installments__c, 'Number of Planned Installments should be unchanged');
    }

    /**
     * @description Verifies Start Date is set to Created Date when Date Established is null
     */
    @IsTest
    private static void shouldSetStartDateAsCreatedDateWhenDateEstablishedIsNull() {
        Date createdOn = DATE_ESTABLISHED;

        npe03__Recurring_Donation__c rd = getLegacyRecurringDonationBuilder()
            .withCreatedDate(createdOn)
            .withDateEstablished(null)
            .build();

        npe03__Recurring_Donation__c convertedRD = new RD2_DataMigrationMapper(rd)
            .convertToEnhancedRD();

        System.assertEquals(createdOn, convertedRD.StartDate__c, 'Effective Date should match Created Date');
    }

    /**
     * @description Verifies Start Date is set to Established Date when
     * the Recurring Donation has assigned Opportunities
     */
    @IsTest
    private static void shouldSetStartDateAsEstablishedDate() {
        Id accId = UTIL_UnitTestData_TEST.mockId(Account.SObjectType);

        npe03__Recurring_Donation__c rd = getLegacyRecurringDonationBuilder()
            .withDateEstablished(DATE_ESTABLISHED)
            .build();

        TEST_OpportunityBuilder oppBuilder = getOpportunityBuilder(accId, rd.Id);

        List<Opportunity> opps = new List<Opportunity>{
            oppBuilder
                .withCloseDate(DATE_ESTABLISHED.addDays(10))
                .withClosedLostStage()
                .build(),
            oppBuilder
                .withCloseDate(DATE_ESTABLISHED.addDays(20))
                .withOpenStage()
                .build(),
            oppBuilder
                .withCloseDate(DATE_ESTABLISHED.addDays(30))
                .withClosedWonStage()
                .build()
        };

        npe03__Recurring_Donation__c convertedRD = new RD2_DataMigrationMapper(rd)
            .withRelatedOpportunities(opps)
            .convertToEnhancedRD();

        System.assertEquals(DATE_ESTABLISHED, convertedRD.StartDate__c, 'Effective Date should match Date Established');
    }

    /**
     * @description Verifies Day of Month is unchanged when it is not the last day of month
     */
    @IsTest
    private static void shouldNotChangeDayOfMonthWhenDayOfMonthIsNot31() {
        TEST_RecurringDonationBuilder rdBuilder = getLegacyRecurringDonationBuilder();

        for (Integer i = 1; i < 31; i++) {
            String dayOfMonth = String.valueOf(i);

            npe03__Recurring_Donation__c convertedRD = new RD2_DataMigrationMapper(
                rdBuilder
                    .withAlwaysUseLastDayOfMonth(false)
                    .withDayOfMonth(dayOfMonth)
                    .build()
            ).convertToEnhancedRD();

            System.assertEquals(dayOfMonth, convertedRD.Day_of_Month__c, 'Day of Month should be unchanged');
        }
    }

    /**
     * @description Verifies Day of Month is set as Last Day when Day of Month has "31" as the value
     */
    @IsTest
    private static void shouldSetDayOfMonthAsTheLastDayWhenDayOfMonthIs31() {
        npe03__Recurring_Donation__c convertedRD = new RD2_DataMigrationMapper(
                getLegacyRecurringDonationBuilder()
                    .withAlwaysUseLastDayOfMonth(false)
                    .withDayOfMonth(String.valueOf('31'))
                    .build()
            ).convertToEnhancedRD();

        System.assertEquals(RD2_Constants.DAY_OF_MONTH_LAST_DAY, convertedRD.Day_of_Month__c,
            'Day of Month should be Last Day when original value is "31"');
    }

    /**
     * @description Verifies Day of Month is set based on the NextPaymentDate
     */
    @IsTest
    private static void shouldSetDayOfMonthUsingNextPaymentDate() {
        List<npe03__Recurring_Donation__c> convertedRDs = new List<npe03__Recurring_Donation__c>();
        TEST_RecurringDonationBuilder rdBuilder = getLegacyRecurringDonationBuilder();

        for (Integer i = 1; i <= 31; i++) {
            convertedRDs.add(new RD2_DataMigrationMapper(
                rdBuilder
                    .withNextPaymentDate(Date.newInstance(2019, 10, i))
                    .withDateEstablished(null)
                    .withCreatedDate(DATE_ESTABLISHED)
                    .withDayOfMonth(null)
                    .build()
                ).convertToEnhancedRD()
            );
        }

        for (npe03__Recurring_Donation__c convertedRD : convertedRDs) {
            assertDayOfMonth(convertedRD, convertedRD.npe03__Next_Payment_Date__c.day());
        }
    }

    /**
     * @description Verifies Day of Month is set based on the DateEstablished
     */
    @IsTest
    private static void shouldSetDayOfMonthUsingDateEstablished() {
        List<npe03__Recurring_Donation__c> convertedRDs = new List<npe03__Recurring_Donation__c>();
        TEST_RecurringDonationBuilder rdBuilder = getLegacyRecurringDonationBuilder();

        for (Integer i = 1; i <= 31; i++) {
            convertedRDs.add(new RD2_DataMigrationMapper(
                rdBuilder
                    .withDateEstablished(Date.newInstance(2019, 10, i))
                    .withNextPaymentDate(null)
                    .withDayOfMonth(null)
                    .build()
                ).convertToEnhancedRD()
            );
        }

        for (npe03__Recurring_Donation__c convertedRD : convertedRDs) {
            assertDayOfMonth(convertedRD, convertedRD.npe03__Date_Established__c.day());
        }
    }

    /**
     * @description Verifies Status field is set to Active when Open Ended Status is not Closed
     */
    @IsTest
    private static void shouldSetStatusAsActiveWhenOpenEndedStatusIsNotClosed() {
        TEST_RecurringDonationBuilder rdBuilder = getLegacyRecurringDonationBuilder();

        List<npe03__Recurring_Donation__c> convertedRDs = new List<npe03__Recurring_Donation__c>{
            new RD2_DataMigrationMapper(
                rdBuilder.withOpenEndedStatusOpen().build()
            ).convertToEnhancedRD(),

            new RD2_DataMigrationMapper(
                rdBuilder.withOpenEndedStatusNone().build()
            ).convertToEnhancedRD(),

            new RD2_DataMigrationMapper(
                rdBuilder.withOpenEndedStatus(null).build()
            ).convertToEnhancedRD()
        };

        for (npe03__Recurring_Donation__c convertedRD : convertedRDs) {
            System.assertEquals(RD2_Constants.STATUS_ACTIVE, convertedRD.Status__c, 'Status should match');
        }
    }

    /**
     * @description Verifies Status field is set to Closed when Open Ended Status is Closed
     */
    @IsTest
    private static void shouldSetStatusAsClosedWhenOpenEndedStatusIsClosed() {

        npe03__Recurring_Donation__c convertedRD = new RD2_DataMigrationMapper(
            getLegacyRecurringDonationBuilder()
                .withOpenEndedStatusClosed()
                .build()
        ).convertToEnhancedRD();

        System.assertEquals(RD2_Constants.STATUS_CLOSED, convertedRD.Status__c, 'Status should match');
    }

    /**
     * @description Verifies an exception is thrown when Open Ended Status cannot be converted
     */
    @IsTest
    private static void shouldThrowExceptionWhenOpenEndedStatusCannotBeConverted() {
        String invalidOpenEndedStatus = 'foo';

        npe03__Recurring_Donation__c rd = getLegacyRecurringDonationBuilder()
            .withOpenEndedStatus(invalidOpenEndedStatus)
            .build();

        Exception actualException;
        try {
            rd = new RD2_DataMigrationMapper(rd).convertToEnhancedRD();

        } catch (Exception e) {
            actualException = e;
        }

        String expectedMessage = String.format(
            System.Label.RD2_DataMigrationInvalidOpenEndedStatus,
            new String[]{ invalidOpenEndedStatus }
        );

        System.assertNotEquals(null, actualException, 'An exception should be generated');
        System.assertEquals(expectedMessage, actualException.getMessage(), 'An exception message should match');
    }

    /**
     * @description Verifies a schedule record is created for Enhanced Recurring Donation record.
     */
    @IsTest
    private static void shouldCreateScheduleForActiveEnhancedRDs() {
        npe03__Recurring_Donation__c rd = getLegacyRecurringDonationBuilder(getContact().Id).withId(null).build();
        insert rd;
        rd = getRecords()[0];

        List<RecurringDonationSchedule__c> rdSchedules = rdScheduleGateway.getRecords(rd);
        System.assertEquals(0, rdSchedules.size(), 'No Schedule should be created');

        List<Opportunity> opps = oppGateway.getRecords(rd);

        runDataMigration();

        rdSchedules = rdScheduleGateway.getRecords(rd);

        System.assertEquals(1, rdSchedules.size(), 'Number of Schedules should match');
        System.assertEquals(rd.Id, rdSchedules[0].RecurringDonation__c, 'Schedule Recurring Donation should be set');
        System.assertEquals(rd.npe03__Amount__c, rdSchedules[0].InstallmentAmount__c, 'RD and Schedule Amounts should match');
        System.assertEquals('1', rdSchedules[0].DayOfMonth__c,  'Day of Month should match');

        System.assertEquals(opps.size(), oppGateway.getRecords(rd).size(),  'No new Opportunity should be created during data migration');
    }

    /**
     * @description Verifies a schedule record is not created for Closed Enhanced Recurring Donation record.
     */
    @IsTest
    private static void shouldNotCreateScheduleForClosedEnhancedRDs() {
        npe03__Recurring_Donation__c rd = getLegacyRecurringDonationBuilder(getContact().Id)
            .withId(null)
            .withOpenEndedStatusClosed()
            .build();
        insert rd;
        rd = getRecords()[0];

        List<RecurringDonationSchedule__c> rdSchedules = rdScheduleGateway.getRecords(rd);
        System.assertEquals(0, rdSchedules.size(), 'No Schedule should be created');

        runDataMigration();

        rdSchedules = rdScheduleGateway.getRecords(rd);

        System.assertEquals(0, rdSchedules.size(), 'No Schedule should be created');
    }

    /**
     * @description Verifies an error is logged when legacy Recurring Donation cannot be migrated
     * due to a migration validation error
     */
    @IsTest
    private static void shouldLogDataMigrationValidationError() {
        npe03__Custom_Installment_Settings__c installment = createCustomInstallmentSettings('Months', 1);

        npe03__Recurring_Donation__c rd = getLegacyRecurringDonationBuilder(getContact().Id)
            .withId(null)
            .withInstallmentPeriod(installment.Name)
            .build();
        insert rd;

        installment.npe03__Increment__c = 'foo';
        update installment;

        //reset custom settings static var
        UTIL_ListCustomSettingsFacade.mapCustomInstallmentSettings = null;

        Id jobId = runDataMigration();

        List<Error__c> errors = errorGateway.getRecords();
        System.assertEquals(1, errors.size(), 'Validation error should be logged');

        String expectedMessage = String.format(
            System.Label.RD2_DataMigrationInvalidInstallmentPeriod,
            new String[]{ installment.Name }
        );
        System.assertEquals(expectedMessage, errors[0].Full_Message__c, 'Error message should match');
        System.assertEquals(RD2_DataMigrationBase_BATCH.LOG_EXCEPTION_ERROR_TYPE, errors[0].Error_Type__c, 'Error Type should match');
        System.assertEquals(rd.Id, errors[0].Related_Record_ID__c, 'Error related record Id should be RD Id');
        System.assertEquals(ERR_Handler.getRecordURL(rd.Id), errors[0].Record_URL__c, 'Error record URL should match');
        System.assertEquals(getLogContextMigration(jobId), errors[0].Context_Type__c, 'Error Context Type should match');

        assertLegacyFormat(getRecords());

        assertBatchSummaryFailed(jobId, 1);
    }

    /**
     * @description Verifies an error is logged when legacy Recurring Donation cannot be migrated
     * due to Recurring Donation validation in trigger
     */
    @IsTest
    private static void shouldLogTriggerValidationError() {
        npe03__Recurring_Donation__c rd = getLegacyRecurringDonationBuilder(getContact().Id)
            .withId(null)
            .build();
        insert rd;

        //Set legacy RD to an invalid state
        //so an error is generated during data migration later on
        TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.flag.RD, true);
        rd.npe03__Contact__c = null;
        update rd;
        TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.flag.RD, false);

        Id jobId = runDataMigration();

        assertDonorIsRequiredError(jobId, rd);

        assertLegacyFormat(getRecords());

        assertBatchSummaryFailed(jobId, 1);
    }

    /**
     * @description Verifies an error is created when store error in error log settings is disabled
     * and migration is run in dry run mode
     */
    @IsTest
    private static void shouldLogDryRunErrorWhenStoreErrorIsDisabled() {

        disableStoreErrorSettings();

        npe03__Recurring_Donation__c rd = getLegacyRecurringDonationBuilder(getContact().Id)
            .withId(null)
            .build();
        insert rd;

        //Make sure an error is generated when dry run is run
        TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.flag.RD, true);
        rd.npe03__Contact__c = null;
        update rd;
        TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.flag.RD, false);

        Id jobId = executeAndFinishDryRun();

        assertDonorIsRequiredError(jobId, rd);

        assertLegacyFormat(getRecords());

        assertBatchSummaryFailed(jobId, 1);

    }

     /**
     * @description Verifies an error is created when store error in error log settings is disabled
     * and data migration is run.
     */
    @IsTest
    private static void shouldLogDataMigrationErrorWhenStoreErrorIsDisabled() {

        disableStoreErrorSettings();

        npe03__Recurring_Donation__c rd = getLegacyRecurringDonationBuilder(getContact().Id)
            .withId(null)
            .build();
        insert rd;

       //Make sure an error is generated when data migration is run
        TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.flag.RD, true);
        rd.npe03__Contact__c = null;
        update rd;
        TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.flag.RD, false);

        Id jobId = runDataMigration();

        assertDonorIsRequiredError(jobId, rd);

        assertLegacyFormat(getRecords());

        assertBatchSummaryFailed(jobId, 1);

    }

    /**
     * @description Verifies open Opportunities for a closed RD are unchanged
     */
    @IsTest
    private static void shouldNotVoidOpenOppWhenRDIsClosed() {
        setCloseActionSettingsToClosedLost();

        npe03__Recurring_Donation__c rd = getLegacyRecurringDonationBuilder(getContact().Id)
            .withId(null)
            .withOpenEndedStatusClosed()
            .build();
        insert rd;

        TEST_OpportunityBuilder oppBuilder = new TEST_OpportunityBuilder()
            .withContact(rd.npe03__Contact__c)
            .withRecurringDonation(rd.Id)
            .withAmount(rd.npe03__Amount__c);

        List<Opportunity> opps = new List<Opportunity>{
            oppBuilder
                .withName()
                .withCloseDate(DATE_ESTABLISHED)
                .withClosedWonStage()
                .build(),
            oppBuilder
                .withName()
                .withCloseDate(DATE_ESTABLISHED.addMonths(1))
                .withOpenStage()
                .build(),
            oppBuilder
                .withName()
                .withCloseDate(TODAY)
                .withOpenStage()
                .build(),
            oppBuilder
                .withName()
                .withCloseDate(TODAY.addMonths(1))
                .withOpenStage()
                .build()
        };
        insert opps;

        Id jobId = runDataMigration();

        assertEnhancedFormat(getRecords());

        Map<Id, Opportunity> oppById = new Map<Id, Opportunity>(oppGateway.getRecords(rd));

        System.assertEquals(opps.size(), oppById.size(), 'Number of Opportunities should match');
        System.assertEquals(true, oppById.get(opps[0].Id).IsClosed && oppById.get(opps[0].Id).IsWon, 'Already Closed Won Opp should be unchanged');
        System.assertEquals(false, oppById.get(opps[1].Id).IsClosed, 'Open Opp with Close Date in past should stay open');
        System.assertEquals(false, oppById.get(opps[2].Id).IsClosed, 'Open Opp with Close Date equal to today should stay open');
        System.assertEquals(false, oppById.get(opps[3].Id).IsClosed, 'Open Opp with Close Date in future should stay open');

        assertBatchSummarySuccess(jobId, 1);
    }

    /**
     * @description Verifies all open Opportunities stay open when RD Open Ended Status is not Closed or Open
     */
    @IsTest
    private static void shouldNotVoidOpenOppWhenRDOpenEndedStatusIsNotOpen() {
        setCloseActionSettingsToClosedLost();

        npe03__Recurring_Donation__c rd = getLegacyRecurringDonationBuilder(getContact().Id)
            .withId(null)
            .withOpenEndedStatusNone()
            .withPlannedInstallments(12)
            .build();
        insert rd;

        delete oppGateway.getRecords(rd);

        TEST_OpportunityBuilder oppBuilder = new TEST_OpportunityBuilder()
            .withContact(rd.npe03__Contact__c)
            .withRecurringDonation(rd.Id)
            .withAmount(rd.npe03__Amount__c);

        List<Opportunity> opps = new List<Opportunity>{
            oppBuilder
                .withName()
                .withCloseDate(DATE_ESTABLISHED)
                .withClosedWonStage()
                .build(),
            oppBuilder
                .withName()
                .withCloseDate(DATE_ESTABLISHED.addMonths(1))
                .withOpenStage()
                .build(),
            oppBuilder
                .withName()
                .withCloseDate(TODAY)
                .withOpenStage()
                .build(),
            oppBuilder
                .withName()
                .withCloseDate(TODAY.addMonths(1))
                .withOpenStage()
                .build()
        };
        insert opps;

        Id jobId = runDataMigration();

        assertEnhancedFormat(getRecords());

        Map<Id, Opportunity> oppById = new Map<Id, Opportunity>(oppGateway.getRecords(rd));

        System.assertEquals(opps.size(), oppById.size(), 'Number of Opportunities should match');
        System.assertEquals(true, oppById.get(opps[0].Id).IsClosed && oppById.get(opps[0].Id).IsWon, 'Already Closed Won Opp should be unchanged');
        System.assertEquals(false, oppById.get(opps[1].Id).IsClosed, 'Open Opp with Close Date in past should stay open');
        System.assertEquals(false, oppById.get(opps[2].Id).IsClosed, 'Open Opp with Close Date equal to today should stay open');
        System.assertEquals(false, oppById.get(opps[3].Id).IsClosed, 'Open Opp with Close Date in future should stay open');

        assertBatchSummarySuccess(jobId, 1);
    }

    /**
     * @description Verifies Recurring Donation with no Open Opportunity is converted successfully
     */
    @IsTest
    private static void shouldNotVoidClosedWonOpps() {
        setCloseActionSettingsToClosedLost();

        npe03__Recurring_Donation__c rd = createLegacyRecurringDonationNoOpps();

        insert new TEST_OpportunityBuilder()
            .withContact(rd.npe03__Contact__c)
            .withRecurringDonation(rd.Id)
            .withAmount(rd.npe03__Amount__c)
            .withCloseDate(TODAY)
            .withClosedWonStage()
            .build();

        Id jobId = runDataMigration();

        List<Error__c> errors = errorGateway.getRecords();
        System.assertEquals(0, errors.size(), 'No error should be logged: ' + errors);

        assertEnhancedFormat(getRecords());

        List<Opportunity> opps = oppGateway.getRecords(rd);
        System.assertEquals(1, opps.size(), 'Number of Opportunities should stay the same');
        System.assertEquals(true, opps[0].IsClosed && opps[0].IsWon, 'Existing Closed Won Opp should be unchanged');

        assertBatchSummarySuccess(jobId, 1);
    }

    /**
     * @description Verifies Open Opportunities having Close Date < today are not voided
     */
    @IsTest
    private static void shouldNotVoidOpenOppWhenCloseDateIsInPast() {
        setCloseActionSettingsToClosedLost();

        npe03__Recurring_Donation__c rd = createLegacyRecurringDonationNoOpps();

        TEST_OpportunityBuilder oppBuilder = new TEST_OpportunityBuilder()
            .withContact(rd.npe03__Contact__c)
            .withRecurringDonation(rd.Id)
            .withAmount(rd.npe03__Amount__c);

        List<Opportunity> opps = new List<Opportunity>{
            oppBuilder
                .withName()
                .withCloseDate(DATE_ESTABLISHED)
                .withClosedWonStage()
                .build(),
            oppBuilder
                .withName()
                .withCloseDate(TODAY.addMonths(-1))
                .withOpenStage()
                .build(),
            oppBuilder
                .withName()
                .withCloseDate(TODAY.addDays(-1))
                .withOpenStage()
                .build()
        };
        insert opps;

        Id jobId = runDataMigration();

        List<Error__c> errors = errorGateway.getRecords();
        System.assertEquals(0, errors.size(), 'No error should be logged: ' + errors);

        assertEnhancedFormat(getRecords());

        Map<Id, Opportunity> oppById = new Map<Id, Opportunity>(oppGateway.getRecords(rd));
        System.assertEquals(opps.size(), oppById.size(), 'Number of Opportunities should match');
        System.assertEquals(true, oppById.get(opps[0].Id).IsClosed && oppById.get(opps[0].Id).IsWon, 'Already Closed Won Opp should be unchanged');
        System.assertEquals(false, oppById.get(opps[1].Id).IsClosed, 'Open Opp with Close Date in the past should stay open');
        System.assertEquals(false, oppById.get(opps[2].Id).IsClosed, 'Open Opp with Close Date equal to yesterday should stay open');

        assertBatchSummarySuccess(jobId, 1);
    }

    /**
     * @description Verifies if the earliest future Open Opportunity has Close Date = today,
     * it stays open and other future Open Opportunities are voided.
     */
    @IsTest
    private static void shouldNotVoidFirstFutureOpenOppWhenCloseDateIsToday() {
        setCloseActionSettingsToClosedLost();

        npe03__Recurring_Donation__c rd = createLegacyRecurringDonationNoOpps();

        TEST_OpportunityBuilder oppBuilder = new TEST_OpportunityBuilder()
            .withContact(rd.npe03__Contact__c)
            .withRecurringDonation(rd.Id)
            .withAmount(rd.npe03__Amount__c);

        List<Opportunity> opps = new List<Opportunity>{
            oppBuilder
                .withName()
                .withInstallmentNumber(1)
                .withCloseDate(DATE_ESTABLISHED)
                .withClosedWonStage()
                .build(),
            oppBuilder
                .withName()
                .withInstallmentNumber(2)
                .withCloseDate(TODAY.addDays(-1))
                .withOpenStage()
                .build(),
            oppBuilder
                .withName()
                .withInstallmentNumber(3)
                .withCloseDate(TODAY)
                .withOpenStage()
                .build(),
            oppBuilder
                .withName()
                .withInstallmentNumber(4)
                .withCloseDate(TODAY.addDays(1))
                .withOpenStage()
                .build()
        };
        insert opps;

        Id jobId = runDataMigration();

        List<Error__c> errors = errorGateway.getRecords();
        System.assertEquals(0, errors.size(), 'No error should be logged: ' + errors);

        assertEnhancedFormat(getRecords());

        Map<Id, Opportunity> oppById = new Map<Id, Opportunity>(oppGateway.getRecords(rd));
        System.assertEquals(opps.size(), oppById.size(), 'Number of Opportunities should match');

        Opportunity opp = oppById.get(opps[0].Id);
        System.assertEquals(true, opp.IsClosed && opp.IsWon, 'Already Closed Won Opp should be unchanged');
        System.assertEquals(opps[0].Recurring_Donation_Installment_Number__c, opp.Recurring_Donation_Installment_Number__c,
            'The Opp Installment Number should be unchanged');

        opp = oppById.get(opps[1].Id);
        System.assertEquals(false, opp.IsClosed, 'Open Opp with Close Date in the past should stay open');
        System.assertEquals(opps[1].Recurring_Donation_Installment_Number__c, opp.Recurring_Donation_Installment_Number__c,
            'The Opp Installment Number should be unchanged');

        opp = oppById.get(opps[2].Id);
        System.assertEquals(false, opp.IsClosed, 'Open Opp with Close Date equal to today should stay open');
        System.assertEquals(opps[2].Recurring_Donation_Installment_Number__c, opp.Recurring_Donation_Installment_Number__c,
            'The Opp Installment Number should be unchanged');

        opp = oppById.get(opps[3].Id);
        System.assertEquals(true, opp.IsClosed && !opp.IsWon, 'The next future Open Opp should be Closed Lost');
        System.assertEquals(MIGRATION_INSTALLMENT_NUMBER_FLAG, opp.Recurring_Donation_Installment_Number__c,
            'The Closed Lost Opp should have the Installment Number overriden');
        System.assertEquals(getLogContextMigration(jobId), opp.Closed_Lost_Reason__c, 'Closed Lost Reason should indicate migration');

        assertBatchSummarySuccess(jobId, 1);
    }

    /**
     * @description Verifies if the earliest future Open Opportunity has Close Date > today,
     * and there is no Open Opp with Close = today, then the Open Opp stays open
     * and other future Open Opportunities are voided.
     */
    @IsTest
    private static void shouldNotVoidFirstFutureOpenOpp() {
        setCloseActionSettingsToClosedLost();

        npe03__Recurring_Donation__c rd = createLegacyRecurringDonationNoOpps();

        TEST_OpportunityBuilder oppBuilder = new TEST_OpportunityBuilder()
            .withContact(rd.npe03__Contact__c)
            .withRecurringDonation(rd.Id)
            .withAmount(rd.npe03__Amount__c);

        List<Opportunity> opps = new List<Opportunity>{
            oppBuilder
                .withName()
                .withInstallmentNumber(1)
                .withCloseDate(DATE_ESTABLISHED)
                .withClosedWonStage()
                .build(),
            oppBuilder
                .withName()
                .withInstallmentNumber(2)
                .withCloseDate(TODAY.addDays(-1))
                .withOpenStage()
                .build(),
            oppBuilder
                .withName()
                .withInstallmentNumber(3)
                .withCloseDate(TODAY.addDays(1))
                .withOpenStage()
                .build(),
            oppBuilder
                .withName()
                .withInstallmentNumber(4)
                .withCloseDate(TODAY.addDays(2))
                .withOpenStage()
                .build()
        };
        insert opps;

        Id jobId = runDataMigration();

        List<Error__c> errors = errorGateway.getRecords();
        System.assertEquals(0, errors.size(), 'No error should be logged: ' + errors);

        assertEnhancedFormat(getRecords());

        Map<Id, Opportunity> oppById = new Map<Id, Opportunity>(oppGateway.getRecords(rd));
        System.assertEquals(opps.size(), oppById.size(), 'Number of Opportunities should match');
        System.assertEquals(true, oppById.get(opps[0].Id).IsClosed && oppById.get(opps[0].Id).IsWon, 'Already Closed Won Opp should be unchanged');
        System.assertEquals(false, oppById.get(opps[1].Id).IsClosed, 'Open Opp with Close Date in the past should stay open');

        Opportunity opp = oppById.get(opps[2].Id);
        System.assertEquals(false, opp.IsClosed, 'The first future Open Opp should stay open');
        System.assertEquals(opps[2].Recurring_Donation_Installment_Number__c, opp.Recurring_Donation_Installment_Number__c,
            'The Opp Installment Number should be unchanged');

        opp = oppById.get(opps[3].Id);
        System.assertEquals(true, opp.IsClosed && !opp.IsWon, 'The next future Open Opp should be Closed Lost');
        System.assertEquals(MIGRATION_INSTALLMENT_NUMBER_FLAG, opp.Recurring_Donation_Installment_Number__c,
            'The Closed Lost Opp should have the Installment Number overriden');
        System.assertEquals(getLogContextMigration(jobId), opp.Closed_Lost_Reason__c, 'Closed Lost Reason should indicate migration');

        assertBatchSummarySuccess(jobId, 1);
    }

    /**
     * @description Verifies the earliest Open Opportunity having Close Date >= today stays open
     * and other future Open Opportunities are deleted when RD Settings close action is deletion.
     */
    @IsTest
    private static void shouldDeleteFutureOpenOppsWhenCloseActionIsDeletion() {
        setCloseActionSettingsToDelete();

        npe03__Recurring_Donation__c rd = createLegacyRecurringDonationNoOpps();

        TEST_OpportunityBuilder oppBuilder = new TEST_OpportunityBuilder()
            .withContact(rd.npe03__Contact__c)
            .withRecurringDonation(rd.Id)
            .withAmount(rd.npe03__Amount__c);

        List<Opportunity> opps = new List<Opportunity>{
            oppBuilder
                .withName()
                .withCloseDate(DATE_ESTABLISHED)
                .withClosedWonStage()
                .build(),
            oppBuilder
                .withName()
                .withCloseDate(TODAY.addDays(-1))
                .withOpenStage()
                .build(),
            oppBuilder
                .withName()
                .withCloseDate(TODAY.addDays(1))
                .withOpenStage()
                .build(),
            oppBuilder
                .withName()
                .withCloseDate(TODAY.addDays(2))
                .withOpenStage()
                .build()
        };
        insert opps;

        Id jobId = runDataMigration();

        List<Error__c> errors = errorGateway.getRecords();
        System.assertEquals(0, errors.size(), 'No error should be logged: ' + errors);

        assertEnhancedFormat(getRecords());

        Map<Id, Opportunity> oppById = new Map<Id, Opportunity>(oppGateway.getRecords(rd));
        System.assertEquals(opps.size() - 1, oppById.size(), 'The next future Open Opportunity should be deleted');
        System.assertEquals(true, oppById.get(opps[0].Id).IsClosed && oppById.get(opps[0].Id).IsWon, 'Already Closed Won Opp should be unchanged');
        System.assertEquals(false, oppById.get(opps[1].Id).IsClosed, 'Open Opp with Close Date in the past should stay open');
        System.assertEquals(false, oppById.get(opps[2].Id).IsClosed, 'The first future Open Opp should stay open');

        assertBatchSummarySuccess(jobId, 1);
    }

    /**
     * @description Verifies Recurring Donations and their Open Opportunities are migrated together successfully
     */
    @IsTest
    private static void shouldVoidOpenOppsInBulk() {
        setCloseActionSettingsToClosedLost();

        List<npe03__Recurring_Donation__c> rds = createLegacyRecurringDonationsNoOpps(2);

        List<Opportunity> opps = new List<Opportunity>();
        for (npe03__Recurring_Donation__c rd : rds) {
            TEST_OpportunityBuilder oppBuilder = new TEST_OpportunityBuilder()
                .withContact(rd.npe03__Contact__c)
                .withRecurringDonation(rd.Id)
                .withAmount(rd.npe03__Amount__c)
                .withOpenStage();

            opps.add(oppBuilder
                .withName()
                .withCloseDate(TODAY)
                .build()
            );
            opps.add(oppBuilder
                .withName()
                .withCloseDate(TODAY.addMonths(1))
                .build()
            );
        }
        insert opps;

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        Id jobId = executeAndFinishMigration();

        List<Error__c> errors = errorGateway.getRecords();
        System.assertEquals(0, errors.size(), 'No error should be logged: ' + errors);

        assertEnhancedFormat(getRecords());

        Map<Id, Opportunity> oppById = new Map<Id, Opportunity>(oppGateway.getRecords(rds));
        System.assertEquals(opps.size(), oppById.size(), 'Number of Opps should match: ' + oppById.values());

        System.assertEquals(false, oppById.get(opps[0].Id).IsClosed,
            'First RD: Open Opp with Close Date today should stay open');
        System.assertEquals(true, oppById.get(opps[1].Id).IsClosed && !oppById.get(opps[1].Id).IsWon,
            'First RD: Open Opp with Close Date in future should be Closed Lost');
        System.assertEquals(false, oppById.get(opps[2].Id).IsClosed,
            'Second RD: Open Opp with Close Date today should stay open');
        System.assertEquals(true, oppById.get(opps[3].Id).IsClosed && !oppById.get(opps[3].Id).IsWon,
            'Second RD: Open Opp with Close Date in future should be Closed Lost');

        assertBatchSummarySuccess(jobId, rds.size());
    }

    /**
     * @description Verifies Recurring Donations and their Open Opportunities are not migrated
     * when DML fails on an Open Opportunity
     */
    @IsTest
    private static void shouldRollbackMigrationWhenAnErrorOccursOnOppDML() {
        setCloseActionSettingsToClosedLost();

        List<npe03__Recurring_Donation__c> rds = createLegacyRecurringDonationsNoOpps(2);

        List<Opportunity> opps = new List<Opportunity>();
        for (npe03__Recurring_Donation__c rd : rds) {
            TEST_OpportunityBuilder oppBuilder = new TEST_OpportunityBuilder()
                .withContact(rd.npe03__Contact__c)
                .withRecurringDonation(rd.Id)
                .withAmount(rd.npe03__Amount__c)
                .withOpenStage();

            opps.add(oppBuilder
                .withName()
                .withCloseDate(TODAY)
                .build()
            );
            opps.add(oppBuilder
                .withName()
                .withCloseDate(TODAY.addMonths(1))
                .build()
            );
        }
        insert opps;

        //simulate an error on a DML other than DML on a Recurring Donation
        RD2_DataMigrationBase_BATCH.Logger logger = new RD2_DataMigrationBase_BATCH.Logger(LOG_CONTEXT);
        List<Database.SaveResult> dmlResults = new List<Database.SaveResult>{ mockErrorDMLResult() };
        logger.addErrors(dmlResults, new List<Opportunity>{ new Opportunity() });

        //try to update converted Recurring Donations and void Open Opps as Closed Lost
        List<npe03__Recurring_Donation__c> convertedRDs = new List<npe03__Recurring_Donation__c>();
        for (npe03__Recurring_Donation__c rd : getRecords()) {
            convertedRDs.add(new RD2_DataMigrationMapper(rd).convertToEnhancedRD());
        }

        Map<Id, List<Opportunity>> voidOppsByRDId = new Map<Id, List<Opportunity>>{
            rds[0].Id => new List<Opportunity>{ opps[1] },
            rds[1].Id => new List<Opportunity>{ opps[3] }
        };

        RD2_DataMigration_BATCH batch = new RD2_DataMigration_BATCH();
        batch.handleSaveAndLogging(convertedRDs, voidOppsByRDId, logger);

        //assert Recurring Donations are not converted to enhanced format and an error is logged
        List<Error__c> errors = errorGateway.getRecords();
        System.assertEquals(1, errors.size(), 'An error should be logged: ' + errors);
        System.assertEquals(dmlResults[0].getErrors()[0].getMessage(), errors[0].Full_Message__c, 'Error message should match');

        assertLegacyFormat(getRecords());

        List<Opportunity> actualOpps = oppGateway.getRecords(rds);
        System.assertEquals(opps.size(), actualOpps.size(), 'Number of Opps should match: ' + actualOpps);

        for (Opportunity opp : actualOpps) {
            System.assertEquals(false, opp.IsClosed, 'Open Opp should be unchanged');
        }

        System.assertEquals(rds.size(), batch.totalRecordsFailed, 'Total Records Failed should match');
    }

    /**
     * @description Verifies Open Opps are voided only for RDs that have been converted to the enhanced format
     */
    @IsTest
    private static void shouldNotVoidOpenOppsWhenRelatedRDIsNotConverted() {
        setCloseActionSettingsToClosedLost();

        List<npe03__Recurring_Donation__c> rds = createLegacyRecurringDonationsNoOpps(2);

        List<Opportunity> opps = new List<Opportunity>();
        for (npe03__Recurring_Donation__c rd : rds) {
            TEST_OpportunityBuilder oppBuilder = new TEST_OpportunityBuilder()
                .withContact(rd.npe03__Contact__c)
                .withRecurringDonation(rd.Id)
                .withAmount(rd.npe03__Amount__c)
                .withOpenStage();

            opps.add(oppBuilder
                .withName()
                .withCloseDate(TODAY)
                .build()
            );
            opps.add(oppBuilder
                .withName()
                .withCloseDate(TODAY.addMonths(1))
                .build()
            );
        }
        insert opps;

        //convert only one RD to the enhanced format
        List<npe03__Recurring_Donation__c> convertedRDs = new List<npe03__Recurring_Donation__c>{
            new RD2_DataMigrationMapper(rds[1]).convertToEnhancedRD()
        };

        //open Opps collection contains Opps to void for all RDs in the transaction
        Map<Id, List<Opportunity>> voidOppsByRDId = new Map<Id, List<Opportunity>>{
            rds[0].Id => new List<Opportunity>{ opps[1] },
            rds[1].Id => new List<Opportunity>{ opps[3] }
        };

        RD2_DataMigration_BATCH batch = new RD2_DataMigration_BATCH();
        RD2_DataMigrationBase_BATCH.Logger logger = new RD2_DataMigrationBase_BATCH.Logger(LOG_CONTEXT);
        batch.handleSaveAndLogging(convertedRDs, voidOppsByRDId, logger);

        List<Error__c> errors = errorGateway.getRecords();
        System.assertEquals(0, errors.size(), 'No error should be logged: ' + errors);

        Map<Id, npe03__Recurring_Donation__c> rdById = new Map<Id, npe03__Recurring_Donation__c>(getRecords());
        assertLegacyFormat(new List<npe03__Recurring_Donation__c>{ rdById.get(rds[0].Id) });
        assertEnhancedFormat(new List<npe03__Recurring_Donation__c>{ rdById.get(rds[1].Id) });

        Map<Id, Opportunity> oppById = new Map<Id, Opportunity>(oppGateway.getRecords(rds));
        System.assertEquals(opps.size(), oppById.size(), 'Number of Opps should match: ' + oppById.values());

        Opportunity opp = oppById.get(voidOppsByRDId.get(rds[0].Id)[0].Id);
        System.assertEquals(false, opp.IsClosed, 'Open Opp for the legacy RD should stay open');

        opp = oppById.get(voidOppsByRDId.get(rds[1].Id)[0].Id);
        System.assertEquals(true, opp.IsClosed && !opp.IsWon, 'Open Opp for the enhanced RD should be Closed Lost');

        System.assertEquals(0, batch.totalRecordsFailed, 'Total Records Failed should match');
    }

    /**
     * @description Verifies Recurring Donation with no Open Opportunity
     * does not have new Opps created during data migration
     */
    @IsTest
    private static void shouldNotCreateNewOppWhenActiveRDHasNoOpp() {
        setCloseActionSettingsToClosedLost();

        npe03__Recurring_Donation__c rd = createLegacyRecurringDonationNoOpps();

        Id jobId = runDataMigration();

        List<Error__c> errors = errorGateway.getRecords();
        System.assertEquals(0, errors.size(), 'No error should be logged: ' + errors);

        List<Opportunity> opps = oppGateway.getRecords(rd);
        System.assertEquals(0, opps.size(), 'No Opportunity should be created: ' + opps);

        assertEnhancedFormat(getRecords());

        assertBatchSummarySuccess(jobId, 1);
    }

    /**
     * @description Verifies a closed Recurring Donation with
     * empty Date Established and Next Donation Date fields can be converted to the enhanced format
     */
    @IsTest
    private static void shouldConvertClosedRDWhenDateEstablishedAndNextDonationDateAreEmpty() {
        npe03__Recurring_Donation__c rd = TEST_RecurringDonationBuilder.constructLegacyBuilder()
            .withContact(getContact().Id)
            .withAmount(AMOUNT_VALUE)
            .withInstallmentPeriodMonthly()
            .withDateEstablished(null)
            .withNextDonationDate(null)
            .withDayOfMonth(null)
            .withOpenEndedStatusClosed()
            .build();
        insert rd;

        Id jobId = runDataMigration();

        List<Error__c> errors = errorGateway.getRecords();
        System.assertEquals(0, errors.size(), 'No error should be logged: ' + errors);

        assertEnhancedFormat(getRecords());

        assertBatchSummarySuccess(jobId, 1);
    }

    /**
     * @description Verifies an open Recurring Donation with
     * empty Date Established can be converted to the enhanced format
     */
    @IsTest
    private static void shouldConvertOpenRDWhenDateEstablishedIsEmpty() {
        final Date nextDonationDate = TODAY.addMonths(1);
        npe03__Recurring_Donation__c rd = TEST_RecurringDonationBuilder.constructLegacyBuilder()
            .withContact(getContact().Id)
            .withAmount(AMOUNT_VALUE)
            .withInstallmentPeriodMonthly()
            .withDateEstablished(null)
            .withNextDonationDate(nextDonationDate)
            .withDayOfMonth(null)
            .withOpenEndedStatusOpen()
            .build();
        insert rd;

        //ensure Effective Date is not specified to simulate an RD created before
        //the field is created in the codebase and defaulted to today if empty
        rd.StartDate__c = null;
        update rd;
        System.assertEquals(null, getRecords()[0].StartDate__c, 'Effective Date should not be specified');

        Id jobId = runDataMigration();

        List<Error__c> errors = errorGateway.getRecords();
        if (isDayOfMonthRestrictedPicklistError(errors)) {
            return;//the org does not have the Last Day picklist added, so return from the test
        }

        System.assertEquals(0, errors.size(), 'No error should be logged: ' + errors);

        rd = getRecords()[0];
        assertEnhancedFormat(new List<npe03__Recurring_Donation__c>{ rd });

        System.assertEquals(nextDonationDate, rd.StartDate__c,
            'Effective Date should equal to the Next Donation Date when the RD has no related Opp');

        assertDayOfMonth(rd, nextDonationDate.day());

        assertBatchSummarySuccess(jobId, 1);
    }

    /**
     * @description Verifies an open Recurring Donation with
     * empty Next Donation Date can be converted to the enhanced format
     */
    @IsTest
    private static void shouldConvertOpenRDWhenNextDonationDateIsEmpty() {
        npe03__Recurring_Donation__c rd = TEST_RecurringDonationBuilder.constructLegacyBuilder()
            .withContact(getContact().Id)
            .withAmount(AMOUNT_VALUE)
            .withInstallmentPeriodMonthly()
            .withDateEstablished(DATE_ESTABLISHED)
            .withNextDonationDate(null)
            .withDayOfMonth(null)
            .withOpenEndedStatusOpen()
            .build();
        insert rd;

        //ensure Effective Date is not specified to simulate an RD created before
        //the field is created in the codebase and defaulted to today if empty
        rd.StartDate__c = null;
        rd.npe03__Next_Payment_Date__c = null;
        update rd;
        System.assertEquals(null, getRecords()[0].StartDate__c, 'Effective Date should not be specified');

        Id jobId = runDataMigration();

        List<Error__c> errors = errorGateway.getRecords();
        if (isDayOfMonthRestrictedPicklistError(errors)) {
            return;//the org does not have the Last Day picklist added, so return from the test
        }

        System.assertEquals(0, errors.size(), 'No error should be logged: ' + errors);

        rd = getRecords()[0];
        assertEnhancedFormat(new List<npe03__Recurring_Donation__c>{ rd });

        System.assertEquals(DATE_ESTABLISHED, rd.StartDate__c,
            'Effective Date should equal to the Date Established when the RD has no related Opp');
        System.assertNotEquals(null, rd.npe03__Next_Payment_Date__c,
            'Next Donation Date should be calculated');

        assertDayOfMonth(rd, DATE_ESTABLISHED.day());

        assertBatchSummarySuccess(jobId, 1);
    }

    /**
     * @description Verifies Recurring Donations and their Open Opportunities are attempted to be migrated
     * successfully when migration is run in the dry run mode
     */
    @IsTest
    private static void shouldRollbackSuccessfulMigrationWhenDryRunMode() {
        setCloseActionSettingsToClosedLost();

        List<npe03__Recurring_Donation__c> rds = createLegacyRecurringDonationsNoOpps(2);

        List<Opportunity> opps = new List<Opportunity>();
        for (npe03__Recurring_Donation__c rd : rds) {
            TEST_OpportunityBuilder oppBuilder = new TEST_OpportunityBuilder()
                .withContact(rd.npe03__Contact__c)
                .withRecurringDonation(rd.Id)
                .withAmount(rd.npe03__Amount__c)
                .withOpenStage();

            opps.add(oppBuilder
                .withName()
                .withCloseDate(TODAY)
                .build()
            );
            opps.add(oppBuilder
                .withName()
                .withCloseDate(TODAY.addMonths(1))
                .build()
            );
        }
        insert opps;

        System.assertEquals(false, RD2_EnablementService.isRecurringDonations2Enabled,
            'Enhanced RDs should not be enabled');

        Id jobId = executeAndFinishDryRun();

        System.assertEquals(false, RD2_EnablementService.isRecurringDonations2Enabled,
            'Enhanced RDs should not be enabled *by* Dry Run migration');

        List<Error__c> errors = errorGateway.getRecords();
        System.assertEquals(0, errors.size(), 'No error should be logged: ' + errors);

        assertLegacyFormat(getRecords());

        List<Opportunity> actualOpps = oppGateway.getRecords(rds);
        System.assertEquals(opps.size(), actualOpps.size(), 'Number of Opps should match: ' + actualOpps);

        for (Opportunity opp : actualOpps) {
            System.assertEquals(false, opp.IsClosed, 'Open Opp should be unchanged');
        }

        assertBatchSummarySuccess(jobId, rds.size());
    }

    /**
     * @description Verifies an error is logged when legacy Recurring Donation cannot be migrated
     * due to a migration validation error in a dry run mode
     */
    @IsTest
    private static void shouldRollbackMigrationWhenRDFailsConversionInDryRunMode() {
        npe03__Custom_Installment_Settings__c installment = createCustomInstallmentSettings('Months', 1);

        List<Contact> contacts = new List<Contact> {
            UTIL_UnitTestData_TEST.getContact(),
            UTIL_UnitTestData_TEST.getContact()
        };
        insert contacts;

        List<npe03__Recurring_Donation__c> rds = new List<npe03__Recurring_Donation__c>();
        for (Contact contact : contacts) {
            rds.add(getLegacyRecurringDonationBuilder(contact.Id).withId(null).build());
        }
        rds[0].npe03__Installment_Period__c = installment.Name;

        Test.startTest();
        insert rds;
        Test.stopTest();

        installment.npe03__Increment__c = 'foo';
        update installment;

        //reset custom settings static var
        UTIL_ListCustomSettingsFacade.mapCustomInstallmentSettings = null;

        System.assertEquals(false, RD2_EnablementService.isRecurringDonations2Enabled,
            'Enhanced RDs should not be enabled');

        Id jobId = executeAndFinishDryRun();

        System.assertEquals(false, RD2_EnablementService.isRecurringDonations2Enabled,
            'Enhanced RDs should not be enabled *by* the Dry Run batch');

        List<Error__c> errors = errorGateway.getRecords();
        System.assertEquals(1, errors.size(), 'An error should be logged: ' + errors);
        System.assertEquals(rds[0].Id, errors[0].Related_Record_ID__c, 'Error related record Id should be RD Id');
        System.assertEquals(getLogContextDryRun(jobId), errors[0].Context_Type__c, 'Error Context Type should match');

        assertLegacyFormat(getRecords());

        UTIL_BatchJobService.JobSummary expectedSummary =
            new UTIL_BatchJobService.JobSummary(jobId)
                .withTotalRecords(2)
                .withTotalRecordsProcessed(1)
                .withTotalRecordsFailed(1);

        assertBatchSummary(expectedSummary);
    }

    /**
     * @description Verifies no error is logged when legacy Recurring Donation has Day Of Month "31" and
     * when migration is run in a dry run mode
     */
    @IsTest
    private static void shouldNotLogErrorWhenDayOfMonthIsLastDayInDryRunMode() {
        final String dayOfMonth = '31';
        npe03__Recurring_Donation__c rd = getLegacyRecurringDonationBuilder(getContact().Id)
            .withId(null)
            .withDayOfMonth(dayOfMonth)
            .build();

        Exception actualException;
        try {
            insert rd;
        } catch (Exception e) {
            if (e.getMessage().contains('INVALID_OR_NULL_FOR_RESTRICTED_PICKLIST')) {
                return; //do not execute the test when the org has RD2 config deployed
            } else {
                actualException = e;
            }
        }
        System.assertEquals(null, actualException, 'No Exception should be generated: ' + actualException);

        Id jobId = executeAndFinishDryRun();

        List<Error__c> errors = errorGateway.getRecords();
        System.assertEquals(0, errors.size(), 'No error should be logged: ' + errors);

        List<npe03__Recurring_Donation__c> rds = getRecords();
        System.assertEquals(dayOfMonth, rds[0].Day_of_Month__c, 'Day of Month should not change');
        assertLegacyFormat(rds);

        assertBatchSummarySuccess(jobId, 1);
    }

    /**
     * @description Verifies that a Legacy Fixed Length RD is converted properly.
     */
    @IsTest
    private static void shouldConvertFixedLengthRecurringDonation() {
        final Integer installments = 12;

        npe03__Recurring_Donation__c rd = getLegacyRecurringDonationBuilder()
            .withOpenEndedStatusNone()
            .withPlannedInstallments(installments)
            .withDateEstablished(DATE_ESTABLISHED)
            .build();

        npe03__Recurring_Donation__c convertedRD = new RD2_DataMigrationMapper(rd)
            .convertToEnhancedRD();

        System.assertEquals(installments, convertedRD.npe03__Installments__c,
            'Number of Planned Installments should be set to ' + installments);
        System.assertEquals(RD2_Constants.RECURRING_TYPE_FIXED, convertedRD.RecurringType__c,
            'The RecurringType should be fixed');
        System.assertEquals(RD2_Constants.STATUS_ACTIVE, convertedRD.Status__c,
            'The Recurring Donation Status should be active');
    }

    /**
     * @description Verifies that the NumberOfPlannedInstallments field is set to null when converting an open ended RD
     */
    @IsTest
    private static void shouldSetNumberOfPlannedInstallmentsToNullForOpenEndedRD() {
        npe03__Recurring_Donation__c rd = getLegacyRecurringDonationBuilder()
            .withOpenEndedStatusOpen()
            .withPlannedInstallments(12)
            .withDateEstablished(DATE_ESTABLISHED)
            .build();

        npe03__Recurring_Donation__c convertedRD = new RD2_DataMigrationMapper(rd)
            .convertToEnhancedRD();

        System.assertEquals(null, convertedRD.npe03__Installments__c,
            'Number of Planned Installments should be set to null');
    }

    /**
     * @description Verifies RD is successfully converted when Amount can be calculated for an
     * RD with Open Ended Status set to Closed
     */
    @IsTest
    private static void shouldConvertWhenOpenEndedStatusClosedAmountCanBeCalculated() {
        npe03__Recurring_Donation__c rd = getLegacyRecurringDonationBuilder()
            .withOpenEndedStatusClosed()
            .withPlannedInstallments(1)
            .withDateEstablished(DATE_ESTABLISHED)
            .build();

        npe03__Recurring_Donation__c convertedRD = new RD2_DataMigrationMapper(rd)
            .convertToEnhancedRD();
        System.assertNotEquals(null, convertedRD, 'RD should be successfully converted');

        rd.npe03__Installments__c = 0;
        convertedRD = new RD2_DataMigrationMapper(rd)
            .convertToEnhancedRD();
        System.assertNotEquals(null, convertedRD, 'RD should be successfully converted');

        rd.npe03__Installments__c = -1;
        convertedRD = new RD2_DataMigrationMapper(rd)
            .convertToEnhancedRD();
        System.assertNotEquals(null, convertedRD, 'RD should be successfully converted');

        rd.npe03__Installments__c = 12;
        rd.npe03__Schedule_Type__c = RD_Constants.SCHEDULE_TYPE_MULTIPLY_BY;
        convertedRD = new RD2_DataMigrationMapper(rd)
            .convertToEnhancedRD();
        System.assertNotEquals(null, convertedRD, 'RD should be successfully converted');
    }

    /**
     * @description Verifies Exception is thrown when Amount cannot be calculated for an
     * RD with Open Ended Status set to Closed
     */
    @IsTest
    private static void shouldThrowExceptionWhenOpenEndedStatusClosedAmountCannotBeCalculated() {
        npe03__Recurring_Donation__c rd = getLegacyRecurringDonationBuilder()
            .withOpenEndedStatusClosed()
            .withPlannedInstallments(12)
            .withDateEstablished(DATE_ESTABLISHED)
            .build();

        npe03__Recurring_Donation__c convertedRD;
        Exception actualException = null;
        try {
            convertedRD = new RD2_DataMigrationMapper(rd)
                .convertToEnhancedRD();
        }
        catch (RD2_DataMigrationMapper.MigrationException e) {
            actualException = e;
        }

        System.assertEquals(true,
            actualException.getMessage()
                .contains(System.Label.RD2_DataMigrationInvalidPlannedInstallments));
        System.assertEquals(null, convertedRD, 'RD should not be converted');

        actualException = null;
        rd.npe03__Installments__c = -12;
        try {
            convertedRD = new RD2_DataMigrationMapper(rd)
                .convertToEnhancedRD();
        }
        catch (RD2_DataMigrationMapper.MigrationException e) {
            actualException = e;
        }

        System.assertEquals(true,
            actualException.getMessage()
                .contains(System.Label.RD2_DataMigrationInvalidPlannedInstallments));
        System.assertEquals(null, convertedRD, 'RD should not be converted');
    }

    /**
     * @description Verifies Account on RD is populated when it is not already specified
     */
    @IsTest
    private static void shouldPopulateAccountOnRDWhenContactIsSpecified() {
        npe03__Recurring_Donation__c rd = getLegacyRecurringDonationBuilder(getContact().Id)
            .withId(null)
            .withAccount(null)
            .build();
        insert rd;

        Id jobId = runDataMigration();

        rd = getRecords()[0];

        System.assertNotEquals(null, rd.npe03__Organization__c,
             'Account on RD should be populated:' + rd);
        System.assertEquals(getContact().AccountId, rd.npe03__Organization__c,
            'Account on RD should be the Account associated with the Contact:' + rd);

   }

    /**
     * @description Verifies Account on RD is populated when it is not already specified
     * and there is a closed Opp on the RD
    */
    @IsTest
    private static void shouldPopulateAccountOnRDWhenContactIsSpecifiedAndRDHasClosedOpp() {
        npe03__Recurring_Donation__c rd = getLegacyRecurringDonationBuilder(getContact().Id)
            .withId(null)
            .withAccount(null)
            .build();

        insert rd;

        insert new TEST_OpportunityBuilder()
            .withContact(rd.npe03__Contact__c)
            .withRecurringDonation(rd.Id)
            .withAmount(rd.npe03__Amount__c)
            .withCloseDate(TODAY)
            .withClosedWonStage()
            .build();

        Id jobId = runDataMigration();

        rd = getRecords()[0];

        System.assertNotEquals(null, rd.npe03__Organization__c,
            'Account on RD should be populated:' + rd);
        System.assertEquals(getContact().AccountId, rd.npe03__Organization__c,
            'Account on RD should be the Account associated with the Contact:' + rd );
    }

    /**
 * @description Verifies that a Legacy Fixed Length RD is converted without metadata for Fixed type.
 */
    @IsTest
    private static void shouldConvertFixedLengthRDWithoutFixedPicklistOption() {
        final Integer installments = 12;

        List<npe03__Recurring_Donation__c> rdList = new List<npe03__Recurring_Donation__c>{
            getLegacyRecurringDonationBuilder()
                .withOpenEndedStatusNone()
                .withPlannedInstallments(installments)
                .withDateEstablished(DATE_ESTABLISHED)
                .build()
        };
        rdList.add(rdList[0].clone());
        rdList[1].npe03__Open_Ended_Status__c = null;

        RD2_EnablementService.fixedOptionAvailable = false;
        RD2_EnablementService.isRecurringDonations2EnabledOverride = true;
        for (npe03__Recurring_Donation__c rd : rdList) {
            npe03__Recurring_Donation__c convertedRD = new RD2_DataMigrationMapper(rd, true)
                .convertToEnhancedRD();
            System.assertEquals(true, RD2_EnablementService.isFixedLength(convertedRD),
                'The converted donation should be identified as fixed');
            System.assertEquals(RD2_Constants.RECURRING_TYPE_OPEN, convertedRD.RecurringType__c,
                'The RecurringType should be open');
        }
    }



    // HELPER METHODS
    //////////////////////

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

    /**
     * @description Creates a Recurring Donation without any Opportunity
     * @return npe03__Recurring_Donation__c
     */
    private static npe03__Recurring_Donation__c createLegacyRecurringDonationNoOpps() {
        npe03__Recurring_Donation__c rd = getLegacyRecurringDonationBuilder(getContact().Id)
            .withId(null)
            .build();
        insert rd;

        delete oppGateway.getRecords(rd);

        return rd;
    }

    /**
     * @description Creates Recurring Donations without any Opportunity
     * @param size Number of Recurring Donations to create
     * @return List<npe03__Recurring_Donation__c>
     */
    private static List<npe03__Recurring_Donation__c> createLegacyRecurringDonationsNoOpps(Integer size) {
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < size; i++) {
            contacts.add(UTIL_UnitTestData_TEST.getContact());
        }
        insert contacts;

        List<npe03__Recurring_Donation__c> rds = new List<npe03__Recurring_Donation__c>();
        for (Contact contact : contacts) {
            rds.add(getLegacyRecurringDonationBuilder(contact.Id).withId(null).build());
        }

        //It is required to execute RD bulk insert in a Test.start/stopTest()
        //so all async legacy RD methods are completed.
        Test.startTest();
        insert rds;
        Test.stopTest();

        delete oppGateway.getRecords(rds);

        return rds;
    }

    /**
     * @description Instantiate a legacy recurring donation for a specific ContactId
     * @return TEST_RecurringDonationBuilder New Recurring Donation builder
     */
    private static TEST_RecurringDonationBuilder getLegacyRecurringDonationBuilder() {
        Id contactId = UTIL_UnitTestData_TEST.mockId(Contact.SObjectType);

        return getLegacyRecurringDonationBuilder(contactId);
    }

    /**
     * @description Instantiate a legacy recurring donation for a specific ContactId
     * @param contactId
     * @return TEST_RecurringDonationBuilder New Recurring Donation builder
     */
    private static TEST_RecurringDonationBuilder getLegacyRecurringDonationBuilder(Id contactId) {
        return TEST_RecurringDonationBuilder.constructLegacyBuilder()
            .withMockId()
            .withDateEstablished(DATE_ESTABLISHED)
            .withCreatedDate(DATE_ESTABLISHED)
            .withOpenEndedStatusOpen()
            .withContact(contactId)
            .withAmount(AMOUNT_VALUE)
            .withInstallmentPeriodMonthly()
            .withDayOfMonth('1');
    }

    /**
     * @description Instantiate an Enhanced RD format recurring donation for a specific ContactId
     * @return TEST_RecurringDonationBuilder New Recurring Donation builder
     */
    private static TEST_RecurringDonationBuilder getEnhancedRecurringDonationBuilder() {
        Id contactId = UTIL_UnitTestData_TEST.mockId(Contact.SObjectType);

        return getEnhancedRecurringDonationBuilder(contactId);
    }

    /**
     * @description Instantiate an Enhanced RD format recurring donation for a specific ContactId
     * @param contactId
     * @return TEST_RecurringDonationBuilder New Recurring Donation builder
     */
    private static TEST_RecurringDonationBuilder getEnhancedRecurringDonationBuilder(Id contactId) {
        return TEST_RecurringDonationBuilder.constructEnhancedBuilder()
            .withMockId()
            .withDefaultValues()
            .withContact(contactId)
            .withAmount(AMOUNT_VALUE)
            .withDayOfMonth('1');
    }

    /**
     * @description Instantiate an Opportunity specific AccountId and Recurring Donation Id
     * @param acctId AccountId
     * @param rdId RecurringDonationId
     * @return TEST_OpportunityBuilder New Opportunity builder
     */
    private static TEST_OpportunityBuilder getOpportunityBuilder(Id acctId, Id rdId) {
        return new TEST_OpportunityBuilder()
            .withMockId()
            .withRecurringDonation(rdId)
            .withAmount(AMOUNT_VALUE)
            .withAccount(acctId)
            .withClosedWonStage();
    }

    /**
     * @description Returns Recurring Donation records' fields
     * @return List<npe03__Recurring_Donation__c>
     */
    private static List<npe03__Recurring_Donation__c> getRecords() {
        return Database.query(new RD2_DataMigration_BATCH().getRDMigrationQuery());
    }

    /**
     * @description Creates custom installment period settings
     * @param installmentIncrement Installment Increment (Days, Weeks, Months, Years)
     * @param installmentFrequency Frequency for the specific custom Installment Period
     * @return npe03__Custom_Installment_Settings__c Custom installment settings
     */
    private static npe03__Custom_Installment_Settings__c createCustomInstallmentSettings(
        String installmentIncrement, Integer installmentFrequency
    ) {
        npe03__Custom_Installment_Settings__c installment = new npe03__Custom_Installment_Settings__c(
            npe03__Increment__c = installmentIncrement,
            npe03__Value__c = installmentFrequency,
            Name = installmentIncrement + UTIL_UnitTestData_TEST.getUniqueString()
        );

        insert installment;
        return installment;
    }

    /**
     * @description Sets RD Settings Opportunity Close Action to Closed Lost
     * @return void
     */
    private static void setCloseActionSettingsToClosedLost() {
        String closeAction = RD2_Constants.CloseActions.Mark_Opportunities_Closed_Lost.name();

        setCloseActionSettings(closeAction);
    }

    /**
     * @description Sets RD Settings Opportunity Close Action to Deletion
     * @return void
     */
    private static void setCloseActionSettingsToDelete() {
        String closeAction = RD2_Constants.CloseActions.Delete_Open_Opportunities.name();

        setCloseActionSettings(closeAction);
    }

    /**
     * @description Sets RD Settings Opportunity Close Action to No Action
     * @return void
     */
    private static void setCloseActionSettingsToNoAction() {
        String closeAction = RD2_Constants.CloseActions.No_Action.name();

        setCloseActionSettings(closeAction);
    }

    /**
     * @description Sets RD Settings Opportunity Close Action to the specified action
     * @param closeAction Close action
     * @return void
     */
    private static void setCloseActionSettings(String closeAction) {
        UTIL_CustomSettingsFacade.getRecurringDonationsSettingsForTest(
            new npe03__Recurring_Donations_Settings__c(
                npe03__Open_Opportunity_Behavior__c = closeAction,
                npe03__Maximum_Donations__c = 50,
                npe03__Opportunity_Forecast_Months__c = 6
            )
        );
    }

    /**
     * @description Sets store errors in error settings to false
     * @return void
     */
    private static void disableStoreErrorSettings() {
        setStoreErrorSettings(false);

    }

    /**
     * @description Sets store settings to enable or disable in error settings
     * @param isEnabled true or false
     * @return void
     */
    private static void setStoreErrorSettings(Boolean isEnabled) {
        UTIL_CustomSettingsFacade.getErrorSettingsForTests(
            new Error_Settings__c(
                Error_Notifications_On__c = false,
                Store_Errors_On__c = isEnabled
            )
        );
    }

    /****
    * @description Returns expected data migration log context
    * @param jobId Batch job Id
    * @return String
    */
    private static String getLogContextMigration(Id jobId) {
        return getLogContext(jobId, false);
    }

    /****
    * @description Returns expected data migration log context
    * @param jobId Batch job Id
    * @return String
    */
    private static String getLogContextDryRun(Id jobId) {
        return getLogContext(jobId, true);
    }

    /****
    * @description Returns expected data migration log context
    * @param isDryRunMode Indicates if the batch runs in dry run mode
    * @param jobId Batch job Id
    * @return String
    */
    private static String getLogContext(Id jobId, Boolean isDryRunMode) {
        AsyncApexJob job = jobGateway.getRecord(jobId);

        String logContext = isDryRunMode
            ? RD2_DataMigrationBase_BATCH.LOG_CONTEXT_DRY_RUN
            : RD2_DataMigrationBase_BATCH.LOG_CONTEXT_MIGRATION;

        return logContext + (job == null ? '' : (' ' + String.valueOf(job.CreatedDate)));
    }

    /****
    * @description Executes data migration batch
    * @return Id Batch job Id
    */
    private static Id runDataMigration() {
        //enablement should be done after the legacy Recurring Donation has been created
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        Test.startTest();
        RD2_DataMigration_BATCH batch = new RD2_DataMigration_BATCH();
        Id jobId = Database.executeBatch(batch);
        Test.stopTest();

        return jobId;
    }

    /****
    * @description Executes data migration batch execute() and finish() methods
    * @return Id Batch job Id
    */
    private static Id executeAndFinishMigration() {
        return executeAndFinishBatch(new RD2_DataMigration_BATCH());
    }

    /****
    * @description Executes dry run migration batch execute() and finish() methods
    * @return Id Batch job Id
    */
    private static Id executeAndFinishDryRun() {
        return executeAndFinishBatch(new RD2_DataMigrationDryRun_BATCH());
    }

    /****
    * @description Executes batch execute() and finish() methods
    * @return Id Batch job Id
    */
    private static Id executeAndFinishBatch(RD2_DataMigrationBase_BATCH batch) {
        UTIL_BatchJobService_TEST.MockBatchableContext batchContext = new UTIL_BatchJobService_TEST.MockBatchableContext();

        batch.execute(batchContext, getRecords());
        batch.finish(batchContext);

        return batchContext.getJobId();
    }

    /****
    * @description Verifies batch summary where all records are processed
    * @param jobId Batch job Id
    * @param totalProcessed Number of processed records
    * @return void
    */
    private static void assertBatchSummarySuccess(Id jobId, Integer totalProcessed) {
        UTIL_BatchJobService.JobSummary expectedSummary =
            new UTIL_BatchJobService.JobSummary(jobId)
                .withTotalRecords(totalProcessed)
                .withTotalRecordsProcessed(totalProcessed)
                .withTotalRecordsFailed(0);

        assertBatchSummary(expectedSummary);
    }

    /****
    * @description Verifies batch summary where all records failed
    * @param jobId Batch job Id
    * @param totalProcessed Number of processed records
    * @return void
    */
    private static void assertBatchSummaryFailed(Id jobId, Integer totalFailed) {
        UTIL_BatchJobService.JobSummary expectedSummary =
            new UTIL_BatchJobService.JobSummary(jobId)
                .withTotalRecords(totalFailed)
                .withTotalRecordsProcessed(0)
                .withTotalRecordsFailed(totalFailed);

        assertBatchSummary(expectedSummary);
    }

    /****
    * @description Verifies batch summary created after data migration completes
    * @return void
    */
    private static void assertBatchSummary(UTIL_BatchJobService.JobSummary expectedSummary) {
        String migrationState = UTIL_CustomSettingsFacade.getRecurringDonationsSettings().RecurringDonations2MigrationState__c;
        Map<String, UTIL_BatchJobService.JobSummary> summaryByType = String.isBlank(migrationState)
            ? new Map<String, UTIL_BatchJobService.JobSummary>()
            : (Map<String, UTIL_BatchJobService.JobSummary>) JSON.deserialize(migrationState, Map<String, UTIL_BatchJobService.JobSummary>.class);

        System.assertNotEquals(null, summaryByType, 'Batch summary should be created');
        System.assertEquals(1, summaryByType.values().size(), 'Batch summary should be created');

        UTIL_BatchJobService.JobSummary summary = summaryByType.values()[0];
        System.assertEquals(expectedSummary.batchId, summary.batchId, 'Batch Id should match: ' + summary);
        System.assertEquals(expectedSummary.total, summary.total, 'Total Records should match: ' + summary);
        System.assertEquals(expectedSummary.processed, summary.processed, 'Total Records Processed should match: ' + summary);
        System.assertEquals(expectedSummary.failed, summary.failed, 'Total Records Failed should match: ' + summary);
    }

    /****
    * @description Assert Recurring Donations are converted from legacy to the enhanced format
    * @param rds Recurring Donations
    * @return void
    */
    private static void assertEnhancedFormat(List<npe03__Recurring_Donation__c> rds) {
        for (npe03__Recurring_Donation__c rd : rds) {
            System.assertNotEquals(null, rd.InstallmentFrequency__c, 'The RD should be converted: ' + rd);
        }
    }

    /****
    * @description Asserts Recurring Donations are still in the legacy format
    * @param rds Recurring Donations
    * @return void
    */
    private static void assertLegacyFormat(List<npe03__Recurring_Donation__c> rds) {
        for (npe03__Recurring_Donation__c rd : rds) {
            System.assertEquals(null, rd.InstallmentFrequency__c, 'The RD should not be converted: ' + rd);
        }
    }

    /****
    * @description Asserts Recurring Donation Day Of Month field value
    * @param rd Recurring Donation
    * @param expectedDayOfMonth Expected Day of Month value
    * @return void
    */
    private static void assertDayOfMonth(npe03__Recurring_Donation__c rd, Integer expectedDayOfMonth) {
        System.assertNotEquals(null, rd.Day_of_Month__c, 'Day of Month should not be null');

        if (expectedDayOfMonth < 31) {
            System.assertEquals(expectedDayOfMonth, Integer.valueOf(rd.Day_of_Month__c),
                'Day of Month should match the expected day when less than 31: '+ JSON.serialize(rd));
        } else {
            System.assertEquals(RD2_Constants.DAY_OF_MONTH_LAST_DAY, rd.Day_of_Month__c,
                'Day of Month should be set as the Last Day');
        }
    }

    /****
    * @description Asserts if the error message contain message about Donor being required on the RD
    * @param jobId Batch job Id
    * @param rd Recurring Donation record
    * @return void
    */
    private static void assertDonorIsRequiredError(Id jobId, npe03__Recurring_Donation__c rd) {
        List<Error__c> errors = errorGateway.getRecords();
        System.assertEquals(1, errors.size(), 'Validation error should be logged');

        System.assertEquals(true, errors[0].Full_Message__c.contains(System.Label.RD_DonorIsRequired), 'Error message should match');
        System.assertEquals(System.Label.errErrorTypeValidationFailed, errors[0].Error_Type__c, 'Error Type should match');
        System.assertEquals(rd.Id, errors[0].Related_Record_ID__c, 'Error related record Id should be RD Id');
        System.assertEquals(ERR_Handler.getRecordURL(rd.Id), errors[0].Record_URL__c, 'Error record URL should match');

        if (errors[0].Context_Type__c.contains(RD2_DataMigrationBase_BATCH.LOG_CONTEXT_DRY_RUN)) {
            System.assertEquals(getLogContextDryRun(jobId), errors[0].Context_Type__c, 'Error Context Type should match');
        } else {
            System.assertEquals(getLogContextMigration(jobId), errors[0].Context_Type__c, 'Error Context Type should match');
        }
    }

    /****
    * @description Checks if the logged error is generated on a day > 28 in the month
    * and the RD2 metadata has not been deployed
    * @param List<Error__c> Errors (if any)
    * @return Boolean
    */
    private static Boolean isDayOfMonthRestrictedPicklistError(List<Error__c> errors) {
        return !errors.isEmpty()
            && errors[0].Full_Message__c.contains(
                Schema.npe03__Recurring_Donation__c.Day_of_Month__c.getDescribe().getLabel()
            );
    }

    /***
    * @description Generates error Database.SaveResult
    */
    private static Database.SaveResult mockErrorDMLResult() {
        return Database.insert(new Opportunity(), false);
    }

    /***
    * @description Updates first two opportunities in the recurring donation to closed won for calculating rollups
    */
    private static void setRdOppsToClosedWonForRollupTests(npe03__Recurring_Donation__c rd, Integer numOpps) {
        List<Opportunity> oppToUpdate = new List<Opportunity>();
        List<Opportunity> rdOpps =  oppGateway.getRecordsByCloseDate(rd);

         for (Integer i = 0; i < numOpps; i++) {
            rdOpps[i].StageName = UTIL_UnitTestData_TEST.getClosedWonStage();
            oppToUpdate.add(rdOpps[i]);
        }

        update oppToUpdate;
    }

}