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
        Date serviceDate = Date.newInstance(1968, 7, 19);
        Date installment5Date = Date.newInstance(1968,12,1);
        Date installment10Date = Date.newInstance(1969,5,1);
        npe03__Recurring_Donation__c rd = getRecurringDonationMonthlyBuilder()
            .withStartDate(startDate)
            .build();

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        Test.startTest();
        insert rd;
        List<RD2_VisualizeScheduleController.Installment> schedules =
            RD2_VisualizeScheduleController.getInstallments(rd.Id, numberOfInstallments);
        Test.stopTest();

        setScheduleServiceDate(serviceDate);
        List<RD2_VisualizeScheduleController.Installment> installments = RD2_VisualizeScheduleController.getInstallments(rd.Id, numberOfInstallments);

        System.assertEquals(numberOfInstallments, schedules.size(), 'Number of installments should match');
        System.assertEquals(installment10Date, installments[9].donationDate, 'Donation date should be 5/1/1969.');
        System.assertEquals(installment5Date, installments[4].donationDate, 'Donation date should be 12/1/1968.');
        System.assertEquals('Credit Card', installments[3].paymentMethod, 'Payment Method should be Credit Card.');
        System.assertEquals('Credit Card', installments[6].paymentMethod, 'Payment Method should be Credit Card.');
        System.assertEquals(100, installments[11].amount, 'Amount should be 100.');
        System.assertEquals(100, installments[2].amount, 'Amount should be 100.');
    }

    /****
    * @description Validates that 2 active schedules are returned for a valid non-closed RD
    */
    @IsTest
    private static void shouldReturnTwoActiveSchedulesForValidNonClosedRD() {
        Date startDate = Date.newInstance(2019,6,1);
        Date newStartDate = Date.newInstance(2019,10,15);
        Date serviceDate = Date.newInstance(2019,7,31);
        Date endDate = Date.newInstance(2019,10,14);
        npe03__Recurring_Donation__c rd = getRecurringDonationMonthlyBuilder()
                .withStartDate(startDate)
                .build();

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        Test.startTest();
        insert rd;
        rd.PaymentMethod__c = 'Check';
        rd.StartDate__c = newStartDate;
        update rd;
        setScheduleServiceDate(serviceDate);
        List<RD2_VisualizeScheduleController.Schedule> schedules = RD2_VisualizeScheduleController.getSchedules(rd.Id);
        Test.stopTest();

        System.assertEquals(2, schedules.size(), 'There should be 2 schedules.');
        System.assertEquals(true, schedules[0].isCurrent, 'isCurrent should be true.');
        System.assertEquals(false, schedules[1].isCurrent, 'isCurrent should be false.');
        System.assertEquals('Credit Card', schedules[0].paymentMethod, 'Payment Method should be Credit Card.');
        System.assertEquals('Check', schedules[1].paymentMethod, 'Payment Method should be Check.');
        System.assertEquals(startDate, schedules[0].startDate, 'Start Date should be 6/1/2019.');
        System.assertEquals(newStartDate, schedules[1].startDate, 'Start Date should be 10/15/2019.');
        System.assertEquals(endDate, schedules[0].endDate, 'End Date should be 10/14/2019.');
        System.assertEquals(null, schedules[1].endDate, 'End Date should be null.');
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
        Date startDate = Date.newInstance(2018,2,1);
        Date serviceDate = Date.newInstance(2019,7,31);
        String dayOfMonth = '12';
        npe03__Recurring_Donation__c rd = getRecurringDonationMonthlyBuilder()
                .withStartDate(startDate)
                .withDayOfMonth(dayOfMonth)
                .build();

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        Test.startTest();
        insert rd;
        setScheduleServiceDate(serviceDate);
        List<RD2_VisualizeScheduleController.Schedule> schedules = RD2_VisualizeScheduleController.getSchedules(rd.Id);
        Test.stopTest();

        System.assertEquals(1, schedules.size(), 'There should be 1 schedule.');
        System.assertEquals(true, schedules[0].isCurrent, 'isCurrent should be true.');
        System.assertEquals(100, schedules[0].amount, 'Amount should be 100.');
        System.assertEquals(startDate, schedules[0].startDate, 'Start Date should be 2/1/2018.');
        System.assertEquals(null, schedules[0].endDate, 'End Date should be null.');
        System.assertEquals(RD2_Constants.INSTALLMENT_PERIOD_MONTHLY, schedules[0].period, 'Period should be monthly.');
        System.assertEquals(dayOfMonth, schedules[0].dayOfMonth, 'Day of month should be 12.');
    }

    /****
    * @description Validates that 2 active schedule are returned for an RD with current and future schedules
    */
    @IsTest
    private static void shouldReturnActiveSchedulesWhenRDHasCurrentAndFutureSchedule() {
        Date startDate = Date.newInstance(2018,2,1);
        Date newStartDate = Date.newInstance(2018,4,1);
        Date serviceDate = Date.newInstance(2018,3,1);
        Date endDate = Date.newInstance(2018,3,31);
        String dayOfMonth = '12';
        npe03__Recurring_Donation__c rd = getRecurringDonationMonthlyBuilder()
                .withStartDate(startDate)
                .withDayOfMonth(dayOfMonth)
                .build();

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        Test.startTest();
        insert rd;
        rd.StartDate__c = newStartDate;
        rd.npe03__Amount__c = 200;
        update rd;
        setScheduleServiceDate(serviceDate);
        List<RD2_VisualizeScheduleController.Schedule> schedules = RD2_VisualizeScheduleController.getSchedules(rd.Id);
        Test.stopTest();

        System.assertEquals(2, schedules.size(), 'There should be 2 schedules.');
        System.assertEquals(true, schedules[0].isCurrent, 'isCurrent should be true.');
        System.assertEquals(false, schedules[1].isCurrent, 'isCurrent should be false.');
        System.assertEquals(100, schedules[0].amount, 'Amount should be 100.');
        System.assertEquals(200, schedules[1].amount, 'Amount should be 200.');
        System.assertEquals(startDate, schedules[0].startDate, 'Start Date should be 2/1/2018.');
        System.assertEquals(newStartDate, schedules[1].startDate, 'Start Date should be 4/1/2018.');
        System.assertEquals(endDate, schedules[0].endDate, 'End Date should be 3/31/2018.');
        System.assertEquals(null, schedules[1].endDate, 'End Date should be null.');
        System.assertEquals(RD2_Constants.INSTALLMENT_PERIOD_MONTHLY, schedules[0].period, 'Period should be monthly.');
        System.assertEquals(RD2_Constants.INSTALLMENT_PERIOD_MONTHLY, schedules[1].period, 'Period should be monthly.');
        System.assertEquals(dayOfMonth, schedules[0].dayOfMonth, 'Day of month should be 12.');
        System.assertEquals(dayOfMonth, schedules[1].dayOfMonth, 'Day of month should be 12.');
    }

    /****
    * @description Validates that zero active schedules are returned for a closed RD
    */
    @IsTest
    private static void shouldThrowAuraHandledExceptionRDIsClosed() {
        Exception actualException;
        npe03__Recurring_Donation__c rd = getRecurringDonationMonthlyBuilder()
                .withStatusClosed()
                .withDayOfMonth('12')
                .build();

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

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
        Date startDate = Date.newInstance(2018,2,1);
        Date newStartDate = Date.newInstance(2018,4,1);
        Date serviceDate = Date.newInstance(2018,3,1);
        Date endDate = Date.newInstance(2018,3,31);
        String dayOfMonth = '12';
        npe03__Recurring_Donation__c rd = getRecurringDonationFirstAndFifteenthBuilder()
                .withStartDate(startDate)
                .withDayOfMonth(dayOfMonth)
                .build();

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        Test.startTest();
        insert rd;
        rd.StartDate__c = newStartDate;
        rd.npe03__Amount__c = 200;
        rd.npe03__Installment_Period__c = RD2_Constants.INSTALLMENT_PERIOD_MONTHLY;
        update rd;
        setScheduleServiceDate(serviceDate);
        List<RD2_VisualizeScheduleController.Schedule> schedules = RD2_VisualizeScheduleController.getSchedules(rd.Id);
        Test.stopTest();

        System.assertEquals(2, schedules.size(), 'There should be 2 schedules.');
        System.assertEquals(true, schedules[0].isCurrent, 'isCurrent should be true.');
        System.assertEquals(false, schedules[1].isCurrent, 'isCurrent should be false.');
        System.assertEquals(100, schedules[0].amount, 'Amount should be 100.');
        System.assertEquals(200, schedules[1].amount, 'Amount should be 200.');
        System.assertEquals(startDate, schedules[0].startDate, 'Start Date should be 2/1/2018.');
        System.assertEquals(newStartDate, schedules[1].startDate, 'Start Date should be 4/1/2018.');
        System.assertEquals(endDate, schedules[0].endDate, 'End Date should be 3/31/2018.');
        System.assertEquals(null, schedules[1].endDate, 'End Date should be null.');
        System.assertEquals(RD2_Constants.INSTALLMENT_PERIOD_FIRST_AND_FIFTEENTH, schedules[0].period, 'Period should be 1st and 15th.');
        System.assertEquals(RD2_Constants.INSTALLMENT_PERIOD_MONTHLY, schedules[1].period, 'Period should be monthly.');
        System.assertEquals(null, schedules[0].dayOfMonth, 'Day of month should be null.');
        System.assertEquals(dayOfMonth, schedules[1].dayOfMonth, 'Day of month should be 12.');
    }

    /****
    * @description Validates that Schedule values are as expected when moving from 1st and 15th to monthly period
    */
    @IsTest
    private static void shouldDisplayExpectedValuesWhenChangingFromMonthlyToFirstAndFifteenth() {
        Date startDate = Date.newInstance(2018,2,1);
        Date newStartDate = Date.newInstance(2018,4,1);
        Date serviceDate = Date.newInstance(2018,3,1);
        Date endDate = Date.newInstance(2018,3,31);
        String dayOfMonth = '12';
        npe03__Recurring_Donation__c rd = getRecurringDonationMonthlyBuilder()
                .withStartDate(startDate)
                .withDayOfMonth(dayOfMonth)
                .build();

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        Test.startTest();
        insert rd;
        rd.StartDate__c = newStartDate;
        rd.npe03__Amount__c = 200;
        rd.npe03__Installment_Period__c = RD2_Constants.INSTALLMENT_PERIOD_FIRST_AND_FIFTEENTH;
        update rd;
        setScheduleServiceDate(serviceDate);
        List<RD2_VisualizeScheduleController.Schedule> schedules = RD2_VisualizeScheduleController.getSchedules(rd.Id);
        Test.stopTest();

        System.assertEquals(2, schedules.size(), 'There should be 1 schedule.');
        System.assertEquals(true, schedules[0].isCurrent, 'isCurrent should be true.');
        System.assertEquals(false, schedules[1].isCurrent, 'isCurrent should be false.');
        System.assertEquals(100, schedules[0].amount, 'Amount should be 100.');
        System.assertEquals(200, schedules[1].amount, 'Amount should be 200.');
        System.assertEquals(startDate, schedules[0].startDate, 'Start Date should be 2/1/2018.');
        System.assertEquals(newStartDate, schedules[1].startDate, 'Start Date should be 4/1/2018.');
        System.assertEquals(endDate, schedules[0].endDate, 'End Date should be 3/31/2018.');
        System.assertEquals(null, schedules[1].endDate, 'End Date should be null.');
        System.assertEquals(RD2_Constants.INSTALLMENT_PERIOD_MONTHLY, schedules[0].period, 'Period should be monthly.');
        System.assertEquals(RD2_Constants.INSTALLMENT_PERIOD_FIRST_AND_FIFTEENTH, schedules[1].period, 'Period should be 1st and 15th.');
        System.assertEquals(dayOfMonth, schedules[0].dayOfMonth, 'Day of month should be 12.');
        System.assertEquals(null, schedules[1].dayOfMonth, 'Day of month should be null.');
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
                .withPaymentMethod('Credit Card')
                .withInstallmentFrequency(1)
                .withDateEstablished(DATE_ESTABLISHED)
                .withStartDate(DATE_ESTABLISHED);
    }

    /****
    * @description Sets schedule service current date for testing
    */
    private static void setScheduleServiceDate (Date currentDate) {
        RD2_ScheduleService.currentDate = currentDate;
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
}