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
@IsTest(isParallel=true)
private class RD2_DataMigration_TEST {

    private static final Date TODAY = System.today();
    private static final Date DATE_ESTABLISHED = TODAY.addMonths(-3);
    private static final Decimal AMOUNT_VALUE = 100;

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
    private static void shouldThrowExceptionAndNotConvertRecordsWhenEnablementIsOff() {
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
            'The exception message should match ' + System.Label.RD2_ErrorDataMigrationJobCannotBeRun);
    }

    /**
     * @description Verifies that the batch job ran with one record processed when
     * Enhanced Recurring Donations is enabled
     */
    @IsTest
    private static void shouldConvertRecordsWhenEnablementIsOn() {
        insert getLegacyRecurringDonationBuilder(getContact().Id)
            .withId(null)
            .build();

        runDataMigration();

        AsyncApexJob job = jobGateway.getRecord('RD2_DataMigration_BATCH');
        System.assertEquals(1, job.JobItemsProcessed,
            'The batch should have run with one child batch processed'
        );
    }

    /**
     * @description Verifies that the batch job converts Recurring Donations from legacy to enhanced format
     */
    @IsTest
    private static void shouldConvertLegacyToEnhancedRecurringDonationInTheBatch() {
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

        runDataMigration();

        npe03__Recurring_Donation__c convertedRD = getRecords()[0];

        System.assertEquals(rd.npe03__Date_Established__c, convertedRD.npe03__Date_Established__c, 'Date Established should be unchanged');
        System.assertEquals(DATE_ESTABLISHED.addMonths(1), convertedRD.StartDate__c, 'Start Date should match with the earliest Opp Close Date');
        System.assertEquals(rd.Day_of_Month__c, convertedRD.Day_of_Month__c, 'Day of Month should be unchanged');

        System.assertEquals(rd.npe03__Amount__c, convertedRD.npe03__Amount__c, 'Amount should be unchanged');
        System.assertEquals(1, convertedRD.InstallmentFrequency__c, 'Installment Frequency should match');
        System.assertEquals(RD2_Constants.INSTALLMENT_PERIOD_MONTHLY, convertedRD.npe03__Installment_Period__c,
            'Installment Period should be unchanged');

        System.assertEquals(RD2_Constants.RECURRING_TYPE_OPEN, convertedRD.RecurringType__c, 'Recurring Type should match');
        System.assertEquals(RD2_Constants.STATUS_ACTIVE, convertedRD.Status__c, 'Status should match');

        List<Error__c> errors = errorGateway.getRecords();
        System.assertEquals(0, errors.size(), 'No error should be logged: ' + errors);
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
                .withInstallmentPeriod(System.Label.npe03.RecurringDonationInstallmentPeriod1stand15th)
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
            .withInstallments(installments)
            .withScheduleType(System.Label.npe03.RecurringDonationDivideValue)
            .withOpenEndedStatusNone()
            .build();
        insert rd;

        rd = getRecords()[0];
        rd.Status__c = null;//simulate legacy Recurring Donation (Status default on insert is Active)

        npe03__Recurring_Donation__c convertedRD = new RD2_DataMigrationMapper(rd)
            .convertToEnhancedRD();

        System.assertEquals(AMOUNT_VALUE / installments, convertedRD.npe03__Amount__c, 'Amount should be copied from Installment Amount');
    }

    /**
     * @description Verifies Amount is unchanged when Schedule Type is "Multiply By"
     */
    @IsTest
    private static void shouldNotChangeAmountWhenScheduleTypeIsMultiplyBy() {

        npe03__Recurring_Donation__c convertedRD = new RD2_DataMigrationMapper(
            getLegacyRecurringDonationBuilder()
                .withScheduleTypeMultiplyValue()
                .build()
        ).convertToEnhancedRD();

        System.assertEquals(AMOUNT_VALUE, convertedRD.npe03__Amount__c, 'Amount should be unchanged');
    }


    /**
     * @description Verifies Start Date is set to Date Established when
     * the Recurring Donation does not have assigned Opportunities
     */
    @IsTest
    private static void shouldSetStartDateAsEstablishedDateWhenRDHasNoOpps() {
        npe03__Recurring_Donation__c rd = getLegacyRecurringDonationBuilder()
            .withDateEstablished(DATE_ESTABLISHED)
            .build();

        npe03__Recurring_Donation__c convertedRD = new RD2_DataMigrationMapper(rd)
            .convertToEnhancedRD();

        System.assertEquals(DATE_ESTABLISHED, convertedRD.StartDate__c,
            'Start Date should match the Recurring Donation Established Date');
    }

    /**
     * @description Verifies Start Date is set to the earliest Opp Close Date when
     * the Recurring Donation has assigned Opportunities
     */
    @IsTest
    private static void shouldSetStartDateAsTheEarliestOppCloseDate() {
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

        System.assertEquals(opps[0].CloseDate, convertedRD.StartDate__c,
            'Start Date should match the earliest Opportunity Close Date');
    }

    /**
     * @description Verifies Day of Month is unchanged when it is not the last day of month
     */
    @IsTest
    private static void shouldNotChangeDayOfMonth() {
        TEST_RecurringDonationBuilder rdBuilder = getLegacyRecurringDonationBuilder();

        for (Integer i = 1; i < 29; i++) {
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
     * @description Verifies Day of Month is set as Last Day for specific RDs
     */
    @IsTest
    private static void shouldSetDayOfMonthAsTheLastDay() {
        List<npe03__Recurring_Donation__c> convertedRDs = new List<npe03__Recurring_Donation__c>();
        TEST_RecurringDonationBuilder rdBuilder = getLegacyRecurringDonationBuilder();

        for (Integer i = 28; i <= 31; i++) {
            Boolean useLastDayOfMonth = i == 28;

            convertedRDs.add(new RD2_DataMigrationMapper(
                rdBuilder
                    .withAlwaysUseLastDayOfMonth(useLastDayOfMonth)
                    .withDayOfMonth(String.valueOf(i))
                    .build()
                ).convertToEnhancedRD()
            );
        }

        for (npe03__Recurring_Donation__c convertedRD : convertedRDs) {
            System.assertEquals(RD2_Constants.DAY_OF_MONTH_LAST_DAY, convertedRD.Day_of_Month__c,
                'Day of Month should be Last Day');
        }
    }

    /**
     * @description Verifies Day of Month is set based on the NextPaymentDate
     */
    @IsTest
    private static void shouldSetDayOfMonthUsingNextPaymentDate() {
        List<npe03__Recurring_Donation__c> convertedRDs = new List<npe03__Recurring_Donation__c>();
        TEST_RecurringDonationBuilder rdBuilder = getLegacyRecurringDonationBuilder();

        for (Integer i = 1; i <= 31; i++) {
            Boolean useLastDayOfMonth = i == 28;

            convertedRDs.add(new RD2_DataMigrationMapper(
                rdBuilder
                    .withNextPaymentDate(Date.newInstance(2019, 10, i))
                    .withDateEstablished(null)
                    .withDayOfMonth(null)
                    .build()
                ).convertToEnhancedRD()
            );
        }

        for (npe03__Recurring_Donation__c convertedRD : convertedRDs) {
            System.assertNotEquals(null, convertedRD.Day_of_Month__c, 'Day of Month should not be null');

            Integer dayOfMonth = convertedRD.npe03__Next_Payment_Date__c.day();
            if (dayOfMonth < 29) {
                System.assertEquals(dayOfMonth, Integer.valueOf(convertedRD.Day_of_Month__c),
                    'Day of Month should match the Next Payment Date day when less than 29: '
                        + JSON.serialize(convertedRD));
            } else {
                System.assertEquals(RD2_Constants.DAY_OF_MONTH_LAST_DAY, convertedRD.Day_of_Month__c,
                    'Day of Month should be Last Day');
            }
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
            Boolean useLastDayOfMonth = i == 28;

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
            System.assertNotEquals(null, convertedRD.Day_of_Month__c, 'Day of Month should not be null');

            Integer dayOfMonth = convertedRD.npe03__Date_Established__c.day();
            if (dayOfMonth < 29) {
                System.assertEquals(dayOfMonth, Integer.valueOf(convertedRD.Day_of_Month__c),
                    'Day of Month should match the Date Established day when less than 29: '
                        + JSON.serialize(convertedRD));
            } else {
                System.assertEquals(RD2_Constants.DAY_OF_MONTH_LAST_DAY, convertedRD.Day_of_Month__c,
                    'Day of Month should be Last Day');
            }
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

        Id batchJobId = runDataMigration();

        List<Error__c> errors = errorGateway.getRecords();
        System.assertEquals(1, errors.size(), 'Validation error should be logged');

        String expectedMessage = String.format(
            System.Label.RD2_DataMigrationInvalidInstallmentPeriod,
            new String[]{ installment.Name }
        );
        System.assertEquals(expectedMessage, errors[0].Full_Message__c, 'Error message should match');
        System.assertEquals(RD2_DataMigration_BATCH.LOG_EXCEPTION_ERROR_TYPE, errors[0].Error_Type__c, 'Error Type should match');
        System.assertEquals(rd.Id, errors[0].Related_Record_ID__c, 'Error related record Id should be RD Id');
        System.assertEquals(ERR_Handler.getRecordURL(rd.Id), errors[0].Record_URL__c, 'Error record URL should match');
        System.assertEquals(getExpectedLogContext(batchJobId), errors[0].Context_Type__c, 'Error Context Type should match');

        System.assertEquals(null, getRecords()[0].InstallmentFrequency__c, 'The RD should not be converted');
    }

    /**
     * @description Verifies an error is logged when legacy Recurring Donation cannot be migrated
     * due to Recurring Donation validation in trigger
     */
    @IsTest
    private static void shouldLogEnhancedRDTriggerValidationError() {
        npe03__Recurring_Donation__c rd = getLegacyRecurringDonationBuilder(getContact().Id)
            .withId(null)
            .build();
        insert rd;

        //Set legacy RD to an invalid state
        //so an error is generated later during data migration
        TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.flag.RD, true);
        rd.npe03__Contact__c = null;
        update rd;
        TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.flag.RD, false);

        Id batchJobId = runDataMigration();

        List<Error__c> errors = errorGateway.getRecords();
        System.assertEquals(1, errors.size(), 'Validation error should be logged');

        System.assertEquals(true, errors[0].Full_Message__c.contains(System.Label.RD_DonorIsRequired), 'Error message should match');
        System.assertEquals(System.Label.errErrorTypeValidationFailed, errors[0].Error_Type__c, 'Error Type should match');
        System.assertEquals(rd.Id, errors[0].Related_Record_ID__c, 'Error related record Id should be RD Id');
        System.assertEquals(ERR_Handler.getRecordURL(rd.Id), errors[0].Record_URL__c, 'Error record URL should match');
        System.assertEquals(getExpectedLogContext(batchJobId), errors[0].Context_Type__c, 'Error Context Type should match');

        System.assertEquals(null, getRecords()[0].InstallmentFrequency__c, 'The RD should not be converted');
    }

    /**
     * @description Verifies open Opportunities for a closed *just migrated* RD are processed per RD settings
     */
    @IsTest
    private static void shouldApplyCloseActionOnOpenOppsWhenMigratedRDIsClosed() {
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
                .build()
        };
        insert opps;

        runDataMigration();

        Map<Id, Opportunity> oppById = new Map<Id, Opportunity>(oppGateway.getRecords(rd));

        System.assertEquals(opps.size(), oppById.size(), 'Number of Opportunities should match');
        System.assertEquals(true, oppById.get(opps[0].Id).IsClosed && oppById.get(opps[0].Id).IsWon, 'Already Closed Won Opp should be unchanged');
        System.assertEquals(true, oppById.get(opps[1].Id).IsClosed, 'Open Opp should be closed now');
        System.assertEquals(false, oppById.get(opps[1].Id).IsWon, 'Open Opp should be lost won now');
    }


    /**
     * @description Verifies Recurring Donation with no Open Opportunity is converted successfully
     */
    @IsTest
    private static void shouldConvertRDWhenItHasNoOpenOpps() {
        setCloseActionSettingsToClosedLost();

        npe03__Recurring_Donation__c rd = createLegacyRecurringDonationNoOpps();

        insert new TEST_OpportunityBuilder()
            .withContact(rd.npe03__Contact__c)
            .withRecurringDonation(rd.Id)
            .withAmount(rd.npe03__Amount__c)
            .withCloseDate(TODAY)
            .withClosedWonStage()
            .build();

        runDataMigration();

        List<Error__c> errors = errorGateway.getRecords();
        System.assertEquals(0, errors.size(), 'No error should be logged: ' + errors);

        System.assertNotEquals(null, getRecords()[0].InstallmentFrequency__c, 'The RD should be converted');

        List<Opportunity> opps = oppGateway.getRecords(rd);
        System.assertEquals(1, opps.size(), 'Number of Opportunities should stay the same');
        System.assertEquals(true, opps[0].IsClosed && opps[0].IsWon, 'Existing Closed Won Opp should be unchanged');
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

        runDataMigration();

        List<Error__c> errors = errorGateway.getRecords();
        System.assertEquals(0, errors.size(), 'No error should be logged: ' + errors);

        System.assertNotEquals(null, getRecords()[0].InstallmentFrequency__c, 'The RD should be converted');

        Map<Id, Opportunity> oppById = new Map<Id, Opportunity>(oppGateway.getRecords(rd));
        System.assertEquals(opps.size(), oppById.size(), 'Number of Opportunities should match');
        System.assertEquals(true, oppById.get(opps[0].Id).IsClosed && oppById.get(opps[0].Id).IsWon, 'Already Closed Won Opp should be unchanged');
        System.assertEquals(false, oppById.get(opps[1].Id).IsClosed, 'Open Opp with Close Date in the past should stay open');
        System.assertEquals(false, oppById.get(opps[2].Id).IsClosed, 'Open Opp with Close Date equal to yesterday should stay open');
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
                .withCloseDate(TODAY)
                .withOpenStage()
                .build(),
            oppBuilder
                .withName()
                .withCloseDate(TODAY.addDays(1))
                .withOpenStage()
                .build()
        };
        insert opps;

        runDataMigration();

        List<Error__c> errors = errorGateway.getRecords();
        System.assertEquals(0, errors.size(), 'No error should be logged: ' + errors);

        System.assertNotEquals(null, getRecords()[0].InstallmentFrequency__c, 'The RD should be converted');

        Map<Id, Opportunity> oppById = new Map<Id, Opportunity>(oppGateway.getRecords(rd));
        System.assertEquals(opps.size(), oppById.size(), 'Number of Opportunities should match');
        System.assertEquals(true, oppById.get(opps[0].Id).IsClosed && oppById.get(opps[0].Id).IsWon, 'Already Closed Won Opp should be unchanged');
        System.assertEquals(false, oppById.get(opps[1].Id).IsClosed, 'Open Opp with Close Date in the past should stay open');
        System.assertEquals(false, oppById.get(opps[2].Id).IsClosed, 'Open Opp with Close Date equal to today should stay open');

        System.assertEquals(true, oppById.get(opps[3].Id).IsClosed && !oppById.get(opps[3].Id).IsWon,
            'The next future Open Opp should be Closed Lost');
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

        runDataMigration();

        List<Error__c> errors = errorGateway.getRecords();
        System.assertEquals(0, errors.size(), 'No error should be logged: ' + errors);

        System.assertNotEquals(null, getRecords()[0].InstallmentFrequency__c, 'The RD should be converted');

        Map<Id, Opportunity> oppById = new Map<Id, Opportunity>(oppGateway.getRecords(rd));
        System.assertEquals(opps.size(), oppById.size(), 'Number of Opportunities should match');
        System.assertEquals(true, oppById.get(opps[0].Id).IsClosed && oppById.get(opps[0].Id).IsWon, 'Already Closed Won Opp should be unchanged');
        System.assertEquals(false, oppById.get(opps[1].Id).IsClosed, 'Open Opp with Close Date in the past should stay open');
        System.assertEquals(false, oppById.get(opps[2].Id).IsClosed, 'The first future Open Opp should stay open');

        System.assertEquals(true, oppById.get(opps[3].Id).IsClosed && !oppById.get(opps[3].Id).IsWon,
            'The next future Open Opp should be Closed Lost');
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

        runDataMigration();

        List<Error__c> errors = errorGateway.getRecords();
        System.assertEquals(0, errors.size(), 'No error should be logged: ' + errors);

        System.assertNotEquals(null, getRecords()[0].InstallmentFrequency__c, 'The RD should be converted');

        Map<Id, Opportunity> oppById = new Map<Id, Opportunity>(oppGateway.getRecords(rd));
        System.assertEquals(opps.size() - 1, oppById.size(), 'The next future Open Opportunity should be deleted');
        System.assertEquals(true, oppById.get(opps[0].Id).IsClosed && oppById.get(opps[0].Id).IsWon, 'Already Closed Won Opp should be unchanged');
        System.assertEquals(false, oppById.get(opps[1].Id).IsClosed, 'Open Opp with Close Date in the past should stay open');
        System.assertEquals(false, oppById.get(opps[2].Id).IsClosed, 'The first future Open Opp should stay open');
    }

    /**
     * @description Verifies Recurring Donation with one Open Opportunity having Close Date >= today
     * is converted successfully when RD Settings close action is no action.
     */
    @IsTest
    private static void shouldConvertRDWhenItHasOneOpenFutureOppAndCloseActionIsNoAction() {
        setCloseActionSettingsToNoAction();

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
                .build()
        };
        insert opps;

        runDataMigration();

        List<Error__c> errors = errorGateway.getRecords();
        System.assertEquals(0, errors.size(), 'No error should be logged: ' + errors);

        System.assertNotEquals(null, getRecords()[0].InstallmentFrequency__c, 'The RD should be converted');

        Map<Id, Opportunity> oppById = new Map<Id, Opportunity>(oppGateway.getRecords(rd));
        System.assertEquals(opps.size(), oppById.size(), 'Number of Opportunities should match');
        System.assertEquals(true, oppById.get(opps[0].Id).IsClosed && oppById.get(opps[0].Id).IsWon, 'Already Closed Won Opp should be unchanged');
        System.assertEquals(false, oppById.get(opps[1].Id).IsClosed, 'Open Opp with Close Date in the past should stay open');
        System.assertEquals(false, oppById.get(opps[2].Id).IsClosed, 'The first future Open Opp should stay open');
    }

    /**
     * @description Verifies Recurring Donation with two or more Open Opportunities having Close Date >= today
     * fails to be converted when RD Settings close action is no action.
     */
    @IsTest
    private static void shouldNotConvertRDWhenItHasManyOpenFutureOppsAndCloseActionIsNoAction() {
        setCloseActionSettingsToNoAction();

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
                .withCloseDate(TODAY.addDays(1))
                .withOpenStage()
                .build(),
            oppBuilder
                .withName()
                .withCloseDate(TODAY.addMonths(1))
                .withOpenStage()
                .build()
        };
        insert opps;

        runDataMigration();

        List<Error__c> errors = errorGateway.getRecords();
        System.assertEquals(1, errors.size(), 'An error should be logged: ' + errors);
        System.assertEquals(System.Label.RD2_DataMigrationInvalidCloseAction, errors[0].Full_Message__c, 'Error message should match');

        System.assertEquals(null, getRecords()[0].InstallmentFrequency__c, 'The RD should not be converted');
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
            .withInstallmentPeriodMonthly()
            .withInstallmentFrequency(1)
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

    /****
    * @description Returns expected data migration log context
    * @param batchJobId Batch job Id
    * @return String
    */
    private static String getExpectedLogContext(Id batchJobId) {
        AsyncApexJob job = jobGateway.getRecord(batchJobId);

        return RD2_DataMigration_BATCH.LOG_CONTEXT_PREFIX + ' ' + String.valueOf(job.CreatedDate);
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
        Id batchJobId = Database.executeBatch(batch);
        Test.stopTest();

        return batchJobId;
    }

}