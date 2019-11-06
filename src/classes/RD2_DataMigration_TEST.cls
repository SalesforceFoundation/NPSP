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

    private static final Date DATE_ESTABLISHED = Date.newInstance(2010, 12, 23);
    private static final Decimal AMOUNT_VALUE = 100;

    /**
     * @description Verifies that the job should run with zero records processed when
     * Enhanced Recurring Donations is not enabled
     */
    @IsTest
    private static void shouldLaunchBatchJobWithNothingProcessed() {
        Contact contact = UTIL_UnitTestData_TEST.getContact();
        insert contact;

        insert getLegacyRecurringDonationBuilder(contact.Id)
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
    private static void shouldLaunchBatchJobWithOneRecordProcessed() {
        Contact contact = UTIL_UnitTestData_TEST.getContact();
        insert contact;

        insert getLegacyRecurringDonationBuilder(contact.Id)
            .withId(null)
            .build();

        //enablement should be done after the legacy Recurring Donation has been created
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        RD2_EnablementService_TEST.configureRecurringDonations2Enabled();

        Test.startTest();
        RD2_DataMigration_BATCH batch = new RD2_DataMigration_BATCH();
        Database.executeBatch(batch);
        Test.stopTest();

        AsyncApexJob job = [SELECT Id, JobItemsProcessed FROM AsyncApexJob
            WHERE JobType = 'BatchApex'
            AND ApexClass.Name = 'RD2_DataMigration_BATCH'
            LIMIT 1];
        System.assertEquals(1, job.JobItemsProcessed,
            'The batch should have run with one child batch processed'
        );
    }

    /**
     * @description Verifies that the batch job converts Recurring Donations from legacy to enhanced format
     */
    @IsTest
    private static void shouldConvertLegacyToEnhancedRecurringDonationInTheBatch() {
        Contact contact = UTIL_UnitTestData_TEST.getContact();
        insert contact;

        npe03__Recurring_Donation__c rd = getLegacyRecurringDonationBuilder(contact.Id)
            .withId(null)
            .withScheduleTypeMultiplyValue()
            .build();
        insert rd;

        //enablement should be done after the legacy Recurring Donation has been created
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        RD2_EnablementService_TEST.configureRecurringDonations2Enabled();

        Test.startTest();
        RD2_DataMigration_BATCH batch = new RD2_DataMigration_BATCH();
        batch.execute(null, new List<npe03__Recurring_Donation__c>{ rd });
        Test.stopTest();

        npe03__Recurring_Donation__c convertedRD = getRecords()[0];
        Date minCloseDate = (Date) [
            SELECT MIN(CloseDate) minCloseDate
            FROM Opportunity
            WHERE npe03__Recurring_Donation__c = :rd.Id
            GROUP BY rollup(npe03__Recurring_Donation__c)
        ][0].get('minCloseDate');

        System.assertEquals(rd.npe03__Date_Established__c, convertedRD.npe03__Date_Established__c, 'Date Established should be unchanged');
        System.assertEquals(minCloseDate, convertedRD.StartDate__c, 'Start Date should match with the earliest Opp Close Date');
        System.assertEquals(rd.Day_of_Month__c, convertedRD.Day_of_Month__c, 'Day of Month should be unchanged');

        System.assertEquals(rd.npe03__Amount__c, convertedRD.npe03__Amount__c, 'Amount should be unchanged');
        System.assertEquals(1, convertedRD.InstallmentFrequency__c, 'Installment Frequency should match');
        System.assertEquals(RD2_Constants.INSTALLMENT_PERIOD_MONTHLY, convertedRD.npe03__Installment_Period__c,
            'Installment Period should be unchanged');

        System.assertEquals(RD2_Constants.RECURRING_TYPE_OPEN, convertedRD.RecurringType__c, 'Recurring Type should match');
        System.assertEquals(RD2_Constants.STATUS_ACTIVE, convertedRD.Status__c, 'Status should match');
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

        Contact contact = UTIL_UnitTestData_TEST.getContact();
        insert contact;

        npe03__Recurring_Donation__c rd = getLegacyRecurringDonationBuilder(contact.Id)
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
                rdBuilder
                    .withOpenEndedStatusOpen()
                    .build()
            ).convertToEnhancedRD(),

            new RD2_DataMigrationMapper(
                rdBuilder
                    .withOpenEndedStatusNone()
                    .build()
            ).convertToEnhancedRD(),

            new RD2_DataMigrationMapper(
                rdBuilder
                    .withOpenEndedStatus(null)
                    .build()
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
     * @description Verifies that a schedule record is created for Enhanced Recurring Donation record.
     */
    @IsTest
    private static void shouldCreateScheduleForActiveEnhancedRDs() {
        List<RecurringDonationSchedule__c> rdSchedules  = new List<RecurringDonationSchedule__c>();
        Id contactId = UTIL_UnitTestData_TEST.mockId(Contact.SObjectType);
        npe03__Recurring_Donation__c rd = getLegacyRecurringDonationBuilder(contactId).build();

        RD2_DataMigrationMapper mapper = new RD2_DataMigrationMapper(rd);
        mapper.convertToEnhancedRD();

        rdSchedules = mapper.getScheduleRecords();

        System.assertEquals(1, rdSchedules.size(), 'Number of Schedules should be 1');
        System.assertEquals(100, rdSchedules[0].InstallmentAmount__c, 'Installment Amount should be 100');
        System.assertEquals('1', rdSchedules[0].DayOfMonth__c,  'Day of Month should be 1');
    }

    /**
     * @description Verifies that a schedule record is not created for Closed Enhanced Recurring Donation record.
     */
    @IsTest
    private static void shouldNotCreateScheduleForClosedEnhancedRDs() {

        List<RecurringDonationSchedule__c> rdSchedules  = new List<RecurringDonationSchedule__c>();
        Id contactId = UTIL_UnitTestData_TEST.mockId(Contact.SObjectType);

        npe03__Recurring_Donation__c rd = getLegacyRecurringDonationBuilder(contactId)
            .withOpenEndedStatusClosed()
            .build();

        RD2_DataMigrationMapper mapper = new RD2_DataMigrationMapper(rd);
        mapper.convertToEnhancedRD();

        rdSchedules = mapper.getScheduleRecords();

        System.assertEquals(0, rdSchedules.size(), 'Number of Schedules should be 0');
    }

    // HELPER METHODS

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

}