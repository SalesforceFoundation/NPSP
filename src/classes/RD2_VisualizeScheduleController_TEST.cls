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
* @description Enhanced Recurring Donations Visualize Schedule Controller unit tests
*
*/
@IsTest(IsParallel=true)
private with sharing class RD2_VisualizeScheduleController_TEST {

    private static final Date DATE_ESTABLISHED = Date.newInstance(2019, 11, 1);
    private static final String PAYMENT_CREDIT_CARD = 'Credit Card';
    private static final String PAYMENT_CHECK = 'Check';

    /****
    * @description Creates data required for unit tests
    */
    @TestSetup
    private static void setUp() {
        insert UTIL_UnitTestData_TEST.getContact();
    }


    /****
    * @description Validates that AuraHandledException is thrown when RD Id is null
    */
    @IsTest
    private static void shouldThrowAuraHandledExceptionWhenRDIdIsNull() {
        Exception actualException;
        Integer numberOfInstallments = null;
        Id rdId = null;

        try {
            RD2_VisualizeScheduleController.getInstallments(rdId, numberOfInstallments);
        } catch (Exception e) {
            actualException = e;
        }

        assertScheduleVisualizerException(actualException);
    }

    /****
    * @description Validates that AuraHandledException is thrown when zero installments are requested
    */
    @IsTest
    private static void shouldThrowAuraHandledExceptionWhenZeroInstallmentsRequested() {
        Exception actualException;
        Integer numberOfInstallments = 0;
        npe03__Recurring_Donation__c rd = getRecurringDonationMonthlyBuilder().build();

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        Test.startTest();
        insert rd;
        Test.stopTest();

        try {
            RD2_VisualizeScheduleController.getInstallments(rd.Id, numberOfInstallments);
        } catch (Exception e) {
            actualException = e;
        }

        assertScheduleVisualizerException(actualException);
    }

    /****
    * @description Validates that AuraHandledException is thrown when negative number of installments are requested
    */
    @IsTest
    private static void shouldThrowAuraHandledExceptionWhenNegativeNumberOfInstallmentsRequested() {
        Exception actualException;
        Integer numberOfInstallments = -5;
        npe03__Recurring_Donation__c rd = getRecurringDonationMonthlyBuilder().build();

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        Test.startTest();
        insert rd;
        Test.stopTest();

        try {
            RD2_VisualizeScheduleController.getInstallments(rd.Id, numberOfInstallments);
        } catch (Exception e) {
            actualException = e;
        }

        assertScheduleVisualizerException(actualException);
    }

    /****
    * @description Validates that specified number of installments are returned as requested for a valid active RD
    */
    @IsTest
    private static void shouldReturnSpecifiedInstallmentsForValidActiveRD() {
        Integer numberOfInstallments = 12;
        Date startDate = Date.newInstance(1950, 1, 1);
        Date today = Date.newInstance(1968, 7, 19);
        Date installment5Date = Date.newInstance(1968, 12, 1);
        Date installment10Date = Date.newInstance(1969, 5, 1);
  
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationMonthlyBuilder()
            .withDateEstablished(startDate)
            .withStartDate(startDate)
            .build();

        Test.startTest();
        insert rd;
        Test.stopTest();

        RD2_ScheduleService.currentDate = today;      
        List<RD2_VisualizeScheduleController.Installment> installments = RD2_VisualizeScheduleController.getInstallments(rd.Id, numberOfInstallments);
        System.assertEquals(numberOfInstallments, installments.size(), 'Number of installments should match');

        for (RD2_VisualizeScheduleController.Installment installment : installments) {
            System.assertEquals(PAYMENT_CREDIT_CARD, installment.paymentMethod, 'Payment Method should be Credit Card.');
            System.assertEquals(rd.npe03__Amount__c, installment.amount, 'Installment Amount should match RD Amount.');
        }
        System.assertEquals(installment5Date, installments[4].donationDate, 'Donation date should be 12/1/1968.');
        System.assertEquals(installment10Date, installments[9].donationDate, 'Donation date should be 5/1/1969.');
    }

    /****
    * @description Validates that 2 active schedules are returned for a valid non-closed RD
    */
    @IsTest
    private static void shouldReturnTwoActiveSchedulesForValidNonClosedRD() {
        Date startDate = Date.newInstance(2019, 6, 1);
        Date today = Date.newInstance(2019, 7, 31);
        Date newStartDate = Date.newInstance(2019, 10, 15);

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationMonthlyBuilder()
            .withDateEstablished(startDate)
            .withStartDate(startDate)
            .build();
        insert rd;

        Test.startTest();
        rd.PaymentMethod__c = PAYMENT_CHECK;
        rd.StartDate__c = newStartDate;
        update rd;
        Test.stopTest();

        RD2_ScheduleService.currentDate = today;
        List<RD2_VisualizeScheduleController.Schedule> schedules = RD2_VisualizeScheduleController.getSchedules(rd.Id);

        assertScheduleDates(schedules, startDate, newStartDate);

        System.assertEquals(PAYMENT_CREDIT_CARD, schedules[0].paymentMethod, 'First schedule Payment Method should be Credit Card.');
        System.assertEquals(PAYMENT_CHECK, schedules[1].paymentMethod, 'Second schedule Payment Method should be Check.');
    }

    /****
    * @description Validates that AuraHandledException is thrown when Enhanced RD is not enabled
    */
    @IsTest
    private static void shouldThrowAuraHandledExceptionWhenEnhancedRDNotEnabled() {
        Exception actualException;
        Integer numberOfInstallments = 12;

        npe03__Recurring_Donation__c rd = TEST_RecurringDonationBuilder.constructLegacyBuilder()
            .withContact(getContact().Id)
            .withAmount(50)
            .withDateEstablished(DATE_ESTABLISHED)
            .build();

        Test.startTest();
        insert rd;
        Test.stopTest();

        try {
            RD2_VisualizeScheduleController.getInstallments(rd.Id, numberOfInstallments);
        } catch (Exception e) {
            actualException = e;
        }

        assertScheduleVisualizerException(actualException);
    }

    /****
    * @description Validates that AuraHandledException is thrown when incorrect SObject Id is used
    */
    @IsTest
    private static void shouldThrowAuraHandledExceptionWhenNonRDSObjectUsed() {
        Exception actualException;
        Integer numberOfInstallments = 12;

        Account acc = UTIL_UnitTestData_TEST.buildHouseholdAccount();
        insert acc;

        try {
            RD2_VisualizeScheduleController.getInstallments(acc.Id, numberOfInstallments);
        } catch (Exception e) {
            actualException = e;
        }

        assertScheduleVisualizerException(actualException);
    }

    /****
    * @description Validates that 1 active schedule is returned for a new RD
    */
    @IsTest
    private static void shouldReturnOneActiveScheduleForNewRD() {
        Date startDate = Date.newInstance(2018, 2, 1);
        Date today = Date.newInstance(2019, 7, 31);
        String dayOfMonth = '12';

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationMonthlyBuilder()
            .withStartDate(startDate)
            .withDayOfMonth(dayOfMonth)
            .build();

        Test.startTest();
        insert rd;
        Test.stopTest();

        RD2_ScheduleService.currentDate = today;
        List<RD2_VisualizeScheduleController.Schedule> schedules = RD2_VisualizeScheduleController.getSchedules(rd.Id);

        System.assertEquals(1, schedules.size(), 'There should be 1 schedule.');
        System.assertEquals(true, schedules[0].isCurrent, 'Schedule should be current');
        System.assertEquals(rd.npe03__Amount__c, schedules[0].amount, 'Schedule Amount should match RD Amount');
        System.assertEquals(RD2_Constants.INSTALLMENT_PERIOD_MONTHLY, schedules[0].period, 'Schedule Period should match RD Installment Period');
        System.assertEquals(dayOfMonth, schedules[0].dayOfMonth, 'Schedule Day of Month should match');
        System.assertEquals(startDate, schedules[0].startDate, 'Schedule Start Date should be RD Effective Date');
        System.assertEquals(null, schedules[0].endDate, 'Schedule End Date should be undefined');
    }

    /****
    * @description Validates that 2 active schedule are returned for an RD with current and future schedules
    */
    @IsTest
    private static void shouldReturnActiveSchedulesWhenRDHasCurrentAndFutureSchedule() {
        Date startDate = Date.newInstance(2018, 2, 1);
        Date today = Date.newInstance(2018, 3, 1);
        Date newStartDate = Date.newInstance(2018, 4, 1);
        String dayOfMonth = '12';

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationMonthlyBuilder()
            .withStartDate(startDate)
            .withDayOfMonth(dayOfMonth)
            .build();
        insert rd;

        Decimal newAmount = rd.npe03__Amount__c + 100;
        Test.startTest();
        rd.StartDate__c = newStartDate;
        rd.npe03__Amount__c = newAmount;
        update rd;
        Test.stopTest();

        RD2_ScheduleService.currentDate = today;
        List<RD2_VisualizeScheduleController.Schedule> schedules = RD2_VisualizeScheduleController.getSchedules(rd.Id);

        assertScheduleDates(schedules, startDate, newStartDate);

        System.assertEquals(100, schedules[0].amount, 'First schedule Amount should be old Amount');
        System.assertEquals(newAmount, schedules[1].amount, 'Second schedule Amount should be new Amount');

        System.assertEquals(RD2_Constants.INSTALLMENT_PERIOD_MONTHLY, schedules[0].period, 'First schedule Period should be unchanged');
        System.assertEquals(RD2_Constants.INSTALLMENT_PERIOD_MONTHLY, schedules[1].period, 'Second schedule Period should match');

        System.assertEquals(dayOfMonth, schedules[0].dayOfMonth, 'First schedule Day of Month should be unchanged');
        System.assertEquals(dayOfMonth, schedules[1].dayOfMonth, 'Second schedule Day of Month should match');
    }

    /****
    * @description Validates that zero active schedules are returned for a closed RD
    */
    @IsTest
    private static void shouldThrowAuraHandledExceptionRDIsClosed() {
        Exception actualException;
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationMonthlyBuilder()
            .withStatusClosed()
            .withDayOfMonth('12')
            .build();

        Test.startTest();
        insert rd;
        Test.stopTest();

        try {
            List<RD2_VisualizeScheduleController.Schedule> schedules = RD2_VisualizeScheduleController.getSchedules(rd.Id);
        } catch (Exception e) {
            actualException = e;
        }

        assertScheduleVisualizerException(actualException);
    }

    /****
    * @description Validates that Schedule values are as expected when moving from monthly to 1st and 15th period
    */
    @IsTest
    private static void shouldDisplayExpectedValuesWhenChangingFromFirstAndFifteenthToMonthly() {
        Date startDate = Date.newInstance(2018, 2, 1);
        Date today = Date.newInstance(2018, 3, 1);
        Date newStartDate = Date.newInstance(2018, 4, 1);
        String dayOfMonth = '12';

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationFirstAndFifteenthBuilder()
            .withStartDate(startDate)
            .withDayOfMonth(dayOfMonth)
            .build();
        insert rd;

        Decimal newAmount = rd.npe03__Amount__c + 100;
        Test.startTest();
        rd.StartDate__c = newStartDate;
        rd.npe03__Amount__c = newAmount;
        rd.npe03__Installment_Period__c = RD2_Constants.INSTALLMENT_PERIOD_MONTHLY;
        update rd;
        Test.stopTest();

        RD2_ScheduleService.currentDate = today;
        List<RD2_VisualizeScheduleController.Schedule> schedules = RD2_VisualizeScheduleController.getSchedules(rd.Id);

        assertScheduleDates(schedules, startDate, newStartDate);

        System.assertEquals(100, schedules[0].amount, 'First schedule Amount should be old Amount');
        System.assertEquals(newAmount, schedules[1].amount, 'Second schedule Amount should be new Amount');

        System.assertEquals(RD2_Constants.INSTALLMENT_PERIOD_FIRST_AND_FIFTEENTH, schedules[0].period, 'First schedule Period should be 1st and 15th.');
        System.assertEquals(RD2_Constants.INSTALLMENT_PERIOD_MONTHLY, schedules[1].period, 'Second schedule Period should be monthly.');

        System.assertEquals(null, schedules[0].dayOfMonth, 'First schedule Day of Month should be undefined');
        System.assertEquals(dayOfMonth, schedules[1].dayOfMonth, 'Second schedule Day of Month should match');
    }

    /****
    * @description Validates that Schedule values are as expected when moving from 1st and 15th to monthly period
    */
    @IsTest
    private static void shouldDisplayExpectedValuesWhenChangingFromMonthlyToFirstAndFifteenth() {
        Date startDate = Date.newInstance(2018, 2, 1);
        Date today = Date.newInstance(2018, 3, 1);
        Date newStartDate = Date.newInstance(2018, 4, 1);
        String dayOfMonth = '12';

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationMonthlyBuilder()
            .withStartDate(startDate)
            .withDayOfMonth(dayOfMonth)
            .build();
        insert rd;

        Decimal newAmount = rd.npe03__Amount__c + 100;
        Test.startTest();
        rd.StartDate__c = newStartDate;
        rd.npe03__Amount__c = newAmount;
        rd.npe03__Installment_Period__c = RD2_Constants.INSTALLMENT_PERIOD_FIRST_AND_FIFTEENTH;
        update rd;
        Test.stopTest();

        RD2_ScheduleService.currentDate = today;
        List<RD2_VisualizeScheduleController.Schedule> schedules = RD2_VisualizeScheduleController.getSchedules(rd.Id);

        assertScheduleDates(schedules, startDate, newStartDate);

        System.assertEquals(100, schedules[0].amount, 'First schedule Amount should be old Amount');
        System.assertEquals(newAmount, schedules[1].amount, 'Second schedule Amount should be new Amount');

        System.assertEquals(RD2_Constants.INSTALLMENT_PERIOD_MONTHLY, schedules[0].period, 'First schedule Period should be monthly.');
        System.assertEquals(RD2_Constants.INSTALLMENT_PERIOD_FIRST_AND_FIFTEENTH, schedules[1].period, 'Second schedule Period should be 1st and 15th.');

        System.assertEquals(dayOfMonth, schedules[0].dayOfMonth, 'First schedule Day of Month should match');
        System.assertEquals(null, schedules[1].dayOfMonth, 'Second schedule Day of Month should be undefined');
    }



    //// Helpers

    /****
    * @description Returns Recurring Donation with Monthly Installment Period
    */
    private static TEST_RecurringDonationBuilder getRecurringDonationMonthlyBuilder() {
        return getRecurringDonationBaseBuilder()
            .withInstallmentPeriodMonthly()
            .withDayOfMonth('1');
    }

    /****
    * @description Returns Recurring Donation with 1st and 15th Installment Period
    */
    private static TEST_RecurringDonationBuilder getRecurringDonationFirstAndFifteenthBuilder() {
        return getRecurringDonationBaseBuilder()
            .withInstallmentPeriod(RD2_Constants.INSTALLMENT_PERIOD_FIRST_AND_FIFTEENTH);
    }


    /****
    * @description Returns Recurring Donation with default values
    */
    private static TEST_RecurringDonationBuilder getRecurringDonationBaseBuilder() {
        return TEST_RecurringDonationBuilder.constructEnhancedBuilder()
            .withContact(getContact().Id)
            .withAmount(100)
            .withPaymentMethod(PAYMENT_CREDIT_CARD)
            .withInstallmentFrequency(1)
            .withDateEstablished(DATE_ESTABLISHED)
            .withStartDate(DATE_ESTABLISHED);
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
    * @description Verifies exception has been generated and its type and message are as expected
    * @param actualException Actual exception (if any)
    * @return void
    */
    private static void assertScheduleVisualizerException(Exception actualException) {
        Exception expectedException = new AuraHandledException(System.Label.RD2_ScheduleVisualizerErrorEnhancedRDNot);

        System.assertNotEquals(null, actualException, 'An exception should be generated');
        System.assertEquals(expectedException.getTypeName(), actualException.getTypeName(),
                'Exception type should be System.AuraHandledException');
        System.assertEquals(expectedException.getMessage(), actualException.getMessage(),
                'Exception message should match');
    }

    /****
    * @description Verifies schedules
    * @param schedules RD Schedules
    * @param startDate First schedule start date
    * @param newStartDate Second schedule start date
    * @return void
    */
    private static void assertScheduleDates(List<RD2_VisualizeScheduleController.Schedule> schedules, Date startDate, Date newStartDate) {
        System.assertEquals(2, schedules.size(), 'There should be 2 schedules.');

        System.assertEquals(true, schedules[0].isCurrent, 'First schedule should be current');
        System.assertEquals(false, schedules[1].isCurrent, 'Second schedule should not be current');
        
        System.assertEquals(startDate, schedules[0].startDate, 'First schedule Start Date should be unchanged');
        System.assertEquals(newStartDate.addDays(-1), schedules[0].endDate, 'First schedule should end before the second starts');
        System.assertEquals(newStartDate, schedules[1].startDate, 'Second schedule Start Date should be new Effective Date');
        System.assertEquals(null, schedules[1].endDate, 'Second schedule End Date should be undefined');
    }
}