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
@IsTest(IsParallel=false)
private with sharing class RD2_VisualizeScheduleController_TEST {

    private static final Date DATE_ESTABLISHED = Date.newInstance(2019, 11, 1);

    private static final String INSTALLMENT_DONATION_DATE = 'donationDate';
    private static final String INSTALLMENT_AMOUNT = 'amount';
    private static final String INSTALLMENT_PAYMENT_METHOD = 'paymentMethod';

    private static final String SCHEDULE_IS_CURRENT = 'isCurrent';
    private static final String SCHEDULE_AMOUNT = 'amount';
    private static final String SCHEDULE_PAYMENT_METHOD = 'paymentMethod';
    private static final String SCHEDULE_CAMPAIGN = 'campaign';
    private static final String SCHEDULE_START_DATE = 'startDate';
    private static final String SCHEDULE_END_DATE = 'endDate';
    private static final String SCHEDULE_PERIOD = 'period';
    private static final String SCHEDULE_FREQUENCY = 'frequency';
    private static final String SCHEDULE_DAY_OF_MONTH = 'dayOfMonth';

    private static final String DATA_TYPE_TEXT = 'text';
    private static final String DATA_TYPE_NUMBER = 'number';
    private static final String DATA_TYPE_CURRENCY = 'currency';
    private static final String DATA_TYPE_DATE = 'date-local';
    private static final String DATA_TYPE_CHECKBOX = 'checkbox';

    private static final String PAYMENT_CREDIT_CARD_LABEL = UTIL_Describe.getTranslatedPicklistLabel(
        npe03__Recurring_Donation__c.SObjectType,
        npe03__Recurring_Donation__c.PaymentMethod__c,
        'Credit Card');

    private static final String PAYMENT_CHECK_LABEL = UTIL_Describe.getTranslatedPicklistLabel(
        npe03__Recurring_Donation__c.SObjectType,
        npe03__Recurring_Donation__c.PaymentMethod__c,
        'Check');

    private static final String INSTALLMENT_PERIOD_MONTHLY_LABEL = UTIL_Describe.getTranslatedPicklistLabel(
        npe03__Recurring_Donation__c.SObjectType,
        npe03__Recurring_Donation__c.npe03__Installment_Period__c,
        RD2_Constants.INSTALLMENT_PERIOD_MONTHLY);

    private static final String INSTALLMENT_PERIOD_FIRST_AND_FIFTEENTH_LABEL = UTIL_Describe.getTranslatedPicklistLabel(
        npe03__Recurring_Donation__c.SObjectType,
        npe03__Recurring_Donation__c.npe03__Installment_Period__c,
        RD2_Constants.INSTALLMENT_PERIOD_FIRST_AND_FIFTEENTH);


    private static final TEST_SObjectGateway.RecurringDonationGateway rdGateway = new TEST_SObjectGateway.RecurringDonationGateway();


    /****
    * @description Creates data required for unit tests
    */
    @TestSetup
    private static void setUp() {
        RD2_ScheduleService.currentDate = DATE_ESTABLISHED;
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        Contact contact = UTIL_UnitTestData_TEST.getContact();
        insert contact;

        insert getRecurringDonationBaseBuilder(contact.Id)
            .withInstallmentPeriodMonthly()
            .withDayOfMonth('1')
            .build();
    }


    /****
    * @description Validates that AuraHandledException is thrown when RD Id is null
    */
    @IsTest
    private static void shouldThrowAuraHandledExceptionWhenRDIdIsNull() {
        Exception actualException;
        Integer numberOfInstallments = null;
        Id rdId = null;

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        try {
            RD2_VisualizeScheduleController.getInstallments(rdId, numberOfInstallments);
        } catch (Exception e) {
            actualException = e;
        }

        assertComponentOnInvalidPageException(actualException);
    }

    /****
    * @description Validates that AuraHandledException is thrown when zero installments are requested
    */
    @IsTest
    private static void shouldThrowExceptionWhenZeroInstallmentsRequested() {
        Exception actualException;
        Integer numberOfInstallments = 0;
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = rdGateway.getRecords()[0];

        try {
            RD2_VisualizeScheduleController.getInstallments(rd.Id, numberOfInstallments);
        } catch (Exception e) {
            actualException = e;
        }

        assertNoInstallmentReturnedException(actualException);
    }

    /****
    * @description Validates that AuraHandledException is thrown when negative number of installments are requested
    */
    @IsTest
    private static void shouldThrowExceptionWhenNegativeNumberOfInstallmentsRequested() {
        Exception actualException;
        Integer numberOfInstallments = -5;
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = rdGateway.getRecords()[0];

        try {
            RD2_VisualizeScheduleController.getInstallments(rd.Id, numberOfInstallments);
        } catch (Exception e) {
            actualException = e;
        }

        assertNoInstallmentReturnedException(actualException);
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
        List<RD2_VisualizeScheduleController.Installment> installments = getInstallments(rd.Id, numberOfInstallments);

        System.assertEquals(numberOfInstallments, installments.size(), 'Number of installments should match');

        for (RD2_VisualizeScheduleController.Installment installment : installments) {
            System.assertEquals(PAYMENT_CREDIT_CARD_LABEL, installment.paymentMethod, 'Payment Method should be Credit Card.');
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
        Date today = DATE_ESTABLISHED.addMonths(1);
        Date newStartDate =  DATE_ESTABLISHED.addMonths(3);

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = rdGateway.getRecords()[0];

        Test.startTest();
        rd.PaymentMethod__c = 'Check';
        rd.StartDate__c = newStartDate;
        update rd;
        Test.stopTest();

        RD2_ScheduleService.currentDate = today;
        List<RD2_VisualizeScheduleController.Schedule> schedules = getSchedules(rd.Id);

        assertScheduleDates(schedules, DATE_ESTABLISHED, newStartDate);

        System.assertEquals(PAYMENT_CREDIT_CARD_LABEL, schedules[0].paymentMethod, 'First schedule Payment Method should be Credit Card.');
        System.assertEquals(PAYMENT_CHECK_LABEL, schedules[1].paymentMethod, 'Second schedule Payment Method should be Check.');
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

        assertRD2IsNotEnabledException(actualException);
    }

    /****
    * @description Validates that AuraHandledException is thrown when incorrect SObject Id is used
    */
    @IsTest
    private static void shouldThrowAuraHandledExceptionWhenNonRDSObjectUsed() {
        Exception actualException;
        Integer numberOfInstallments = 12;
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        Account acc = UTIL_UnitTestData_TEST.buildHouseholdAccount();
        insert acc;

        try {
            RD2_VisualizeScheduleController.getInstallments(acc.Id, numberOfInstallments);
        } catch (Exception e) {
            actualException = e;
        }

        assertComponentOnInvalidPageException(actualException);
    }

    /****
    * @description Validates that 1 active schedule is returned for a new RD
    */
    @IsTest
    private static void shouldReturnOneActiveScheduleForNewRD() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = rdGateway.getRecords()[0];

        RD2_ScheduleService.currentDate = DATE_ESTABLISHED.addMonths(3).addMonths(3);
        List<RD2_VisualizeScheduleController.Schedule> schedules = getSchedules(rd.Id);

        System.assertEquals(1, schedules.size(), 'There should be 1 schedule.');
        System.assertEquals(true, schedules[0].isCurrent, 'Schedule should be current');
        System.assertEquals(rd.npe03__Amount__c, schedules[0].amount, 'Schedule Amount should match RD Amount');
        System.assertEquals(INSTALLMENT_PERIOD_MONTHLY_LABEL, schedules[0].period, 'Schedule Period should match RD Installment Period');
        System.assertEquals('1', schedules[0].dayOfMonth, 'Schedule Day of Month should match');
        System.assertEquals(rd.StartDate__c, schedules[0].startDate, 'Schedule Start Date should be RD Effective Date');
        System.assertEquals(null, schedules[0].endDate, 'Schedule End Date should be undefined');
    }

    /****
    * @description Validates that 2 active schedule are returned for an RD with current and future schedules
    */
    @IsTest
    private static void shouldReturnActiveSchedulesWhenRDHasCurrentAndFutureSchedule() {
        Date newStartDate = DATE_ESTABLISHED.addMonths(4);

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = rdGateway.getRecords()[0];

        Decimal newAmount = rd.npe03__Amount__c + 100;

        Test.startTest();
        rd.StartDate__c = newStartDate;
        rd.npe03__Amount__c = newAmount;
        update rd;
        Test.stopTest();

        RD2_ScheduleService.currentDate = DATE_ESTABLISHED.addMonths(2);
        List<RD2_VisualizeScheduleController.Schedule> schedules = getSchedules(rd.Id);

        assertScheduleDates(schedules, DATE_ESTABLISHED, newStartDate);

        System.assertEquals(100, schedules[0].amount, 'First schedule Amount should be old Amount');
        System.assertEquals(newAmount, schedules[1].amount, 'Second schedule Amount should be new Amount');

        System.assertEquals(INSTALLMENT_PERIOD_MONTHLY_LABEL, schedules[0].period, 'First schedule Period should be unchanged');
        System.assertEquals(INSTALLMENT_PERIOD_MONTHLY_LABEL, schedules[1].period, 'Second schedule Period should match');

        System.assertEquals(rd.Day_of_Month__c, schedules[0].dayOfMonth, 'First schedule Day of Month should be unchanged');
        System.assertEquals(rd.Day_of_Month__c, schedules[1].dayOfMonth, 'Second schedule Day of Month should match');
    }

    /****
    * @description Validates that zero active schedules are returned for a closed RD
    */
    @IsTest
    private static void shouldThrowAuraHandledExceptionRDIsClosed() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = rdGateway.getRecords()[0];

        Test.startTest();
        rd.Status__c = RD2_Constants.STATUS_CLOSED;
        rd.EndDate__c = Date.today();
        update rd;
        Test.stopTest();

        Exception actualException;
        try {
            RD2_VisualizeScheduleController.getSchedules(rd.Id);
        } catch (Exception e) {
            actualException = e;
        }

        assertNoActiveScheduleReturnedException(actualException);
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
        List<RD2_VisualizeScheduleController.Schedule> schedules = getSchedules(rd.Id);

        assertScheduleDates(schedules, startDate, newStartDate);

        System.assertEquals(100, schedules[0].amount, 'First schedule Amount should be old Amount');
        System.assertEquals(newAmount, schedules[1].amount, 'Second schedule Amount should be new Amount');

        System.assertEquals(INSTALLMENT_PERIOD_FIRST_AND_FIFTEENTH_LABEL, schedules[0].period, 'First schedule Period should be 1st and 15th.');
        System.assertEquals(INSTALLMENT_PERIOD_MONTHLY_LABEL, schedules[1].period, 'Second schedule Period should be monthly.');

        System.assertEquals(null, schedules[0].dayOfMonth, 'First schedule Day of Month should be undefined');
        System.assertEquals(dayOfMonth, schedules[1].dayOfMonth, 'Second schedule Day of Month should match');
    }

    /****
    * @description Validates that Schedule values are as expected when moving from 1st and 15th to monthly period
    */
    @IsTest
    private static void shouldDisplayExpectedValuesWhenChangingFromMonthlyToFirstAndFifteenth() {
        Date newStartDate = DATE_ESTABLISHED.addMonths(3);

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = rdGateway.getRecords()[0];

        Decimal newAmount = rd.npe03__Amount__c + 100;

        Test.startTest();
        rd.StartDate__c = newStartDate;
        rd.npe03__Amount__c = newAmount;
        rd.npe03__Installment_Period__c = RD2_Constants.INSTALLMENT_PERIOD_FIRST_AND_FIFTEENTH;
        update rd;
        Test.stopTest();

        RD2_ScheduleService.currentDate = DATE_ESTABLISHED.addMonths(1);
        List<RD2_VisualizeScheduleController.Schedule> schedules = getSchedules(rd.Id);

        assertScheduleDates(schedules, DATE_ESTABLISHED, newStartDate);

        System.assertEquals(100, schedules[0].amount, 'First schedule Amount should be old Amount');
        System.assertEquals(newAmount, schedules[1].amount, 'Second schedule Amount should be new Amount');

        System.assertEquals(INSTALLMENT_PERIOD_MONTHLY_LABEL, schedules[0].period, 'First schedule Period should be monthly.');
        System.assertEquals(INSTALLMENT_PERIOD_FIRST_AND_FIFTEENTH_LABEL, schedules[1].period, 'Second schedule Period should be 1st and 15th.');

        System.assertEquals(rd.Day_of_Month__c, schedules[0].dayOfMonth, 'First schedule Day of Month should match');
        System.assertEquals(null, schedules[1].dayOfMonth, 'Second schedule Day of Month should be undefined');
    }

    /***
    * @description Validates that only expected amount of future installments should be return for fixed length RD
    */
    @IsTest
    private static void shouldDisplayFutureInstallmentsWhenRDIsFixedLength() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        RD2_Settings_TEST.configureForASyncFirstOpportunityCreate();

        Date startDate = Date.newInstance(2018, 2, 1);
        Date today = Date.newInstance(2018, 4, 2);
        RD2_ScheduleService.currentDate = today;

        Integer maxInstallments = 100;
        Integer plannedInstallments = 10;
        Integer paidInstallments = 3;

        npe03__Recurring_Donation__c rd = getRecurringDonationMonthlyBuilder()
            .withRecurringTypeFixed()
            .withPlannedInstallments(plannedInstallments)
            .withPaidInstallments(paidInstallments)
            .withStartDate(startDate)
            .withDayOfMonth(String.valueOf(startDate.day()))
            .build();
        insert rd;

        List<Opportunity> opps = new List<Opportunity>();
        TEST_OpportunityBuilder oppBuilder = new TEST_OpportunityBuilder()
            .withContact(rd.npe03__Contact__c)
            .withRecurringDonation(rd.Id)
            .withAmount(rd.npe03__Amount__c)
            .withClosedWonStage()
            .withInstallmentNumber(1);

        //add past paid Closed Won Opps
        for (Integer month = 0; month < paidInstallments; month++) {
            opps.add(oppBuilder
                .withName()
                .withCloseDate(startDate.addMonths(month))
                .build()
            );
        }
        //add an open Opp matching the Next Donation Date future installment
        opps.add(oppBuilder
            .withName()
            .withCloseDate(Date.newInstance(2018, 5, 1))
            .withOpenStage()
            .build()
        );
        insert opps;

        Test.startTest();
        List<Object> installments = getInstallments(rd.Id, maxInstallments);
        Test.stopTest();

        System.assertEquals(plannedInstallments - paidInstallments, installments.size(),
            'Should only return definite number of future installments for fixed length RD: ' + installments);
    }

    /***
    * @description Verifies a field value is set to null when the field is not accessible
    */
    @IsTest
    private static void shouldNullValueWhenAnInstallmentFieldIsNotAccessible() {
        Integer numberOfInstallments = 3;
        Date today = DATE_ESTABLISHED.addMonths(2);
        RD2_ScheduleService.currentDate = today;
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationMonthlyBuilder().build();

        RD2_VisualizeScheduleController.DataTable dataTable = new RD2_VisualizeScheduleController.DataTable();
        for (String fieldName : new String[] {
            INSTALLMENT_DONATION_DATE,
            INSTALLMENT_AMOUNT,
            INSTALLMENT_PAYMENT_METHOD
        }) {
            dataTable.addColumn(new RD2_VisualizeScheduleController.DataTableColumn()
                .withFieldName(fieldname)
                .withIsAccessible(fieldName != INSTALLMENT_AMOUNT)
            );
        }

        dataTable.setRecords(buildInstallments(rd, numberOfInstallments));

        System.assertEquals(numberOfInstallments, dataTable.getRecords().size(), 'Number of records should match');
        for (Object obj : dataTable.getRecords()) {
            RD2_VisualizeScheduleController.Installment record = (RD2_VisualizeScheduleController.Installment) obj;
            System.assertNotEquals(null, record.amount, 'Amount should be specified');
        }

        RD2_VisualizeScheduleController.sanitizeInstallments(dataTable);

        for (Object obj : dataTable.getRecords()) {
            RD2_VisualizeScheduleController.Installment record = (RD2_VisualizeScheduleController.Installment) obj;
            System.assertNotEquals(null, record.donationDate, 'Date should be specified');
            System.assertEquals(null, record.amount, 'Amount should be sanitized');
            System.assertNotEquals(null, record.paymentMethod, 'PaymentMethod should be specified');
        }
    }

    /***
    * @description Verifies all field values are set to null when no field is accessible
    */
    @IsTest
    private static void shouldNullValueWhenAllInstallmentFieldsAreNotAccessible() {
        Integer numberOfInstallments = 3;
        Date today = DATE_ESTABLISHED.addMonths(2);
        RD2_ScheduleService.currentDate = today;
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationMonthlyBuilder().build();

        Boolean isAccessible = false;
        RD2_VisualizeScheduleController.DataTable dataTable = buildInstallmentDataTable(isAccessible);

        dataTable.setRecords(buildInstallments(rd, numberOfInstallments));
        System.assertEquals(numberOfInstallments, dataTable.getRecords().size(), 'Number of records should match');
        for (Object obj : dataTable.getRecords()) {
            RD2_VisualizeScheduleController.Installment record = (RD2_VisualizeScheduleController.Installment) obj;
            System.assertNotEquals(null, record.donationDate, 'Date should be specified');
            System.assertNotEquals(null, record.amount, 'Amount should be specified');
            System.assertNotEquals(null, record.paymentMethod, 'Payment Method should be specified');
        }

        RD2_VisualizeScheduleController.sanitizeInstallments(dataTable);

        for (Object obj : dataTable.getRecords()) {
            RD2_VisualizeScheduleController.Installment record = (RD2_VisualizeScheduleController.Installment) obj;
            System.assertEquals(null, record.donationDate, 'Date should be sanitized');
            System.assertEquals(null, record.amount, 'Amount should be sanitized');
            System.assertEquals(null, record.paymentMethod, 'PaymentMethod should be sanitized');
        }
    }

    /***
    * @description Verifies a field value is left as is when the field is accessible
    */
    @IsTest
    private static void shouldLeaveValueAsIsWhenAllInstallmentFieldsAreAccessible() {
        Integer numberOfInstallments = 3;
        Date today = DATE_ESTABLISHED.addMonths(2);
        RD2_ScheduleService.currentDate = today;
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationMonthlyBuilder().build();

        RD2_VisualizeScheduleController.DataTable dataTable = RD2_VisualizeScheduleController.buildInstallmentDataTable(rd);

        dataTable.setRecords(buildInstallments(rd, numberOfInstallments));
        System.assertEquals(numberOfInstallments, dataTable.getRecords().size(), 'Number of records should match');

        RD2_VisualizeScheduleController.sanitizeInstallments(dataTable);

        for (Object obj : dataTable.getRecords()) {
            RD2_VisualizeScheduleController.Installment record = (RD2_VisualizeScheduleController.Installment) obj;
            System.assertNotEquals(null, record.donationDate, 'Date should be specified');
            System.assertNotEquals(null, record.amount, 'Amount should be specified');
            System.assertNotEquals(null, record.paymentMethod, 'PaymentMethod should be specified');
        }
    }

    /***
    * @description Verifies expected columns are added to the installment data table
    */
    @IsTest
    private static void shouldAddInstallmentObjectColumnsIntoInstallmentDataTable() {
        Date today = DATE_ESTABLISHED.addMonths(2);
        RD2_ScheduleService.currentDate = today;
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationMonthlyBuilder().build();

        RD2_VisualizeScheduleController.DataTable dataTable = RD2_VisualizeScheduleController.buildInstallmentDataTable(rd);

        System.assertEquals(3, dataTable.getColumns().size(), 'Number of columns should match');

        RD2_VisualizeScheduleController.DataTableColumn column = dataTable.getColumn(INSTALLMENT_DONATION_DATE);
        System.assertNotEquals(null, column, 'DonationDate column should exist in data table');
        System.assertEquals(System.Label.RD2_ScheduleVisualizerColumnDate, column.label, 'DonationDate label should match');
        System.assertEquals(DATA_TYPE_DATE, column.type, 'DonationDate type should match');

        column = dataTable.getColumn(INSTALLMENT_AMOUNT);
        System.assertNotEquals(null, column, 'Amount column should exist in data table');
        System.assertEquals(DATA_TYPE_CURRENCY, column.type, 'Amount type should match');

        column = dataTable.getColumn(INSTALLMENT_PAYMENT_METHOD);
        System.assertNotEquals(null, column, 'PaymentMethod column should exist in data table');
        System.assertEquals(DATA_TYPE_TEXT, column.type, 'PaymentMethod type should match');
    }

    /***
    * @description Verifies expected columns are added to the schedule data table
    */
    @IsTest
    private static void shouldAddScheduleColumnsIntoScheduleDataTable() {
        Date today = DATE_ESTABLISHED.addMonths(2);
        RD2_ScheduleService.currentDate = today;
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationMonthlyBuilder().build();

        RD2_VisualizeScheduleController.DataTable dataTable = RD2_VisualizeScheduleController.buildScheduleDataTable(rd);

        System.assertEquals(9, dataTable.getColumns().size(), 'Number of columns should match');

        RD2_VisualizeScheduleController.DataTableColumn column = dataTable.getColumn(SCHEDULE_IS_CURRENT);
        System.assertNotEquals(null, column, 'IsCurrent column should exist in data table');
        System.assertEquals(DATA_TYPE_CHECKBOX, column.type, 'IsCurrent type should match');

        column = dataTable.getColumn(SCHEDULE_AMOUNT);
        System.assertNotEquals(null, column, 'Amount column should exist in data table');
        System.assertEquals(DATA_TYPE_CURRENCY, column.type, 'Amount type should match');

        column = dataTable.getColumn(SCHEDULE_PAYMENT_METHOD);
        System.assertNotEquals(null, column, 'PaymentMethod column should exist in data table');
        System.assertEquals(DATA_TYPE_TEXT, column.type, 'PaymentMethod type should match');

        column = dataTable.getColumn(SCHEDULE_CAMPAIGN);
        System.assertNotEquals(null, column, 'Campaign column should exist in data table');
        System.assertEquals(DATA_TYPE_TEXT, column.type, 'Campaign type should match');

        column = dataTable.getColumn(SCHEDULE_START_DATE);
        System.assertNotEquals(null, column, 'StartDate column should exist in data table');
        System.assertEquals(DATA_TYPE_DATE, column.type, 'StartDate type should match');

        column = dataTable.getColumn(SCHEDULE_END_DATE);
        System.assertNotEquals(null, column, 'EndDate column should exist in data table');
        System.assertEquals(DATA_TYPE_DATE, column.type, 'EndDate type should match');

        column = dataTable.getColumn(SCHEDULE_PERIOD);
        System.assertNotEquals(null, column, 'Period column should exist in data table');
        System.assertEquals(DATA_TYPE_TEXT, column.type, 'Period type should match');

        column = dataTable.getColumn(SCHEDULE_FREQUENCY);
        System.assertNotEquals(null, column, 'Frequency column should exist in data table');
        System.assertEquals(DATA_TYPE_NUMBER, column.type, 'Frequency type should match');

        column = dataTable.getColumn(SCHEDULE_DAY_OF_MONTH);
        System.assertNotEquals(null, column, 'DayOfMonth column should exist in data table');
        System.assertEquals(DATA_TYPE_TEXT, column.type, 'DayOfMonth type should match');
    }

    /***
    * @description Verifies a field value is left as is when the field is accessible
    */
    @IsTest
    private static void shouldLeaveValueAsIsWhenAllScheduleFieldsAreAccessible() {
        Date today = DATE_ESTABLISHED.addMonths(2);
        RD2_ScheduleService.currentDate = today;
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationMonthlyBuilder().build();

        RD2_VisualizeScheduleController.DataTable dataTable = RD2_VisualizeScheduleController.buildScheduleDataTable(rd);

        dataTable.setRecords(buildSchedules(rd));
        System.assertEquals(1, dataTable.getRecords().size(), 'Number of records should match');

        RD2_VisualizeScheduleController.sanitizeSchedules(dataTable);

        RD2_VisualizeScheduleController.Schedule record = (RD2_VisualizeScheduleController.Schedule) dataTable.getRecords()[0];
        System.assertEquals(true, record.isCurrent, 'IsCurrent should match');
        System.assertNotEquals(null, record.amount, 'Amount should be specified');
        System.assertNotEquals(null, record.paymentMethod, 'PaymentMethod should be specified');
        System.assertNotEquals(null, record.paymentMethod, 'PaymentMethod should be specified');
        System.assertNotEquals(null, record.startDate, 'StartDate should be specified');
        System.assertEquals(null, record.endDate, 'EndDate should be null since this is one and only active schedule');
        System.assertNotEquals(null, record.period, 'Period should be specified');
        System.assertNotEquals(null, record.frequency, 'Frequency should be specified');
        System.assertNotEquals(null, record.dayOfMonth, 'DayOfMonth should be specified');
    }

    /***
    * @description Verifies all field values are set to null when no field is accessible
    */
    @IsTest
    private static void shouldNullValueWhenAllScheduleFieldsAreNotAccessible() {
        Date today = DATE_ESTABLISHED.addMonths(2);
        RD2_ScheduleService.currentDate = today;
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationMonthlyBuilder().build();

        Boolean isAccessible = false;
        RD2_VisualizeScheduleController.DataTable dataTable = buildScheduleDataTable(isAccessible);

        dataTable.setRecords(buildSchedules(rd));
        System.assertEquals(1, dataTable.getRecords().size(), 'Number of records should match');

        RD2_VisualizeScheduleController.sanitizeSchedules(dataTable);

        RD2_VisualizeScheduleController.Schedule record = (RD2_VisualizeScheduleController.Schedule) dataTable.getRecords()[0];
        System.assertEquals(true, record.isCurrent, 'IsCurrent should match');
        System.assertEquals(null, record.amount, 'Amount should be sanitized');
        System.assertEquals(null, record.paymentMethod, 'PaymentMethod should be sanitized');
        System.assertEquals(null, record.startDate, 'StartDate should be sanitized');
        System.assertEquals(null, record.endDate, 'EndDate should be sanitized');
        System.assertEquals(null, record.period, 'Period should be sanitized');
        System.assertEquals(null, record.frequency, 'Frequency should be sanitized');
        System.assertEquals(null, record.dayOfMonth, 'DayOfMonth should be sanitized');
    }

    /***
    * @description Verifies a field value is set to null when the field is not accessible
    */
    @IsTest
    private static void shouldNullValueWhenAScheduleFieldIsNotAccessible() {
        Date today = DATE_ESTABLISHED.addMonths(2);
        RD2_ScheduleService.currentDate = today;
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationMonthlyBuilder().build();

        RD2_VisualizeScheduleController.DataTable dataTable = new RD2_VisualizeScheduleController.DataTable();
        for (String fieldName : new String[] {
            SCHEDULE_IS_CURRENT,
            SCHEDULE_AMOUNT,
            SCHEDULE_PAYMENT_METHOD,
            SCHEDULE_CAMPAIGN,
            SCHEDULE_START_DATE,
            SCHEDULE_END_DATE,
            SCHEDULE_PERIOD,
            SCHEDULE_FREQUENCY,
            SCHEDULE_DAY_OF_MONTH
        }) {
            dataTable.addColumn(new RD2_VisualizeScheduleController.DataTableColumn()
                .withFieldName(fieldname)
                .withIsAccessible(fieldName != SCHEDULE_AMOUNT && fieldName != SCHEDULE_PERIOD)
            );
        }

        dataTable.setRecords(buildSchedules(rd));
        System.assertEquals(1, dataTable.getRecords().size(), 'Number of records should match');

        RD2_VisualizeScheduleController.sanitizeSchedules(dataTable);

        RD2_VisualizeScheduleController.Schedule record = (RD2_VisualizeScheduleController.Schedule) dataTable.getRecords()[0];
        System.assertEquals(true, record.isCurrent, 'IsCurrent should match');
        System.assertEquals(null, record.amount, 'Amount should be sanitized');
        System.assertNotEquals(null, record.paymentMethod, 'PaymentMethod should be specified');
        System.assertNotEquals(null, record.startDate, 'StartDate should be specified');
        System.assertEquals(null, record.endDate, 'EndDate should be null since this is one and only active schedule');
        System.assertEquals(null, record.period, 'Period should be sanitized');
        System.assertNotEquals(null, record.frequency, 'Frequency should be specified');
        System.assertNotEquals(null, record.dayOfMonth, 'DayOfMonth should be specified');
    }

    /****
    * @description Validates that a active schedule is returned for when RD Status is mapped to Active
    */
    @IsTest
    private static void shouldReturnActiveScheduleWhenRDStatusIsMappedToActive() {
        String newStatus = 'New';

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        RD2_StatusMapper_TEST.Stub mapperStub = new RD2_StatusMapper_TEST.Stub()
            .withMapping(newStatus, RD2_Constants.STATUS_ACTIVE);
        RD2_StatusMapper.statusMapper = (RD2_StatusMapper) Test.createStub(
            RD2_StatusMapper.Class,
            mapperStub
        );

        npe03__Recurring_Donation__c rd = rdGateway.getRecords()[0];
        rd.Status__c = newStatus;
        rd = TEST_RecurringDonationBuilder.mockRecurringDonationFullQueryResult(rd, new List<Opportunity>(), new RD2_ScheduleService().buildNewSchedules(rd));

        RD2_VisualizeScheduleController.cachedRd = new RD2_RecurringDonation(rd);
        RD2_ScheduleService.currentDate = DATE_ESTABLISHED.addMonths(2);

        Test.startTest();
        List<RD2_VisualizeScheduleController.Schedule> schedules = getSchedules(rd.Id);
        Test.stopTest();

        System.assertEquals(newStatus, RD2_VisualizeScheduleController.cachedRd.getSObject().Status__c, 'Cached RD status should be New');
        System.assertEquals(RD2_Constants.STATUS_ACTIVE, RD2_VisualizeScheduleController.cachedRd.getState(), 'RD state should be mapped to Active');
        System.assertEquals(1, schedules.size(), 'There should be 1 schedule.');
        System.assertEquals(true, schedules[0].isCurrent, 'Schedule should be current');
        System.assertEquals(rd.npe03__Amount__c, schedules[0].amount, 'Schedule Amount should match RD Amount');
        System.assertEquals(INSTALLMENT_PERIOD_MONTHLY_LABEL, schedules[0].period, 'Schedule Period should match RD Installment Period');
        System.assertEquals(rd.Day_of_Month__c, schedules[0].dayOfMonth, 'Schedule Day of Month should match');
        System.assertEquals(rd.StartDate__c, schedules[0].startDate, 'Schedule Start Date should be RD Effective Date');
        System.assertEquals(null, schedules[0].endDate, 'Schedule End Date should be undefined');
    }

    /****
    * @description Validates that zero active schedules are returned for a RD where status is mapped to Closed
    */
    @IsTest
    private static void shouldThrowAuraHandledExceptionRDStatusIsMappedClosed() {
        Exception actualException;
        String newStatus = 'End';
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationMonthlyBuilder()
            .withStatus(newStatus)
            .withDayOfMonth('12')
            .withMockId()
            .build();

        RD2_StatusMapper_TEST.Stub mapperStub = new RD2_StatusMapper_TEST.Stub()
            .withMapping(newStatus, RD2_Constants.STATUS_CLOSED);
        RD2_StatusMapper.statusMapper = (RD2_StatusMapper) Test.createStub(
            RD2_StatusMapper.Class,
            mapperStub
        );

        rd = TEST_RecurringDonationBuilder.mockRecurringDonationFullQueryResult(rd, new List<Opportunity>(), new RD2_ScheduleService().buildNewSchedules(rd));
        RD2_VisualizeScheduleController.cachedRd = new RD2_RecurringDonation(rd);

        Test.startTest();
        try {
            RD2_VisualizeScheduleController.getSchedules(rd.Id);
        } catch (Exception e) {
            actualException = e;
        }
        Test.stopTest();

        assertNoActiveScheduleReturnedException(actualException);
    }

    /***
    * @description Verifies schedule end date is populate with RD end date
    */
    @isTest
    private static void shouldSetEndDateOnScheduleWhenRDEndDateIsSet() {
        Date startDate = Date.newInstance(2018, 2, 1);
        Date today = Date.newInstance(2019, 7, 31);
        Date endDate = today.addMonths(10);
        String dayOfMonth = '12';
        RD2_ScheduleService.currentDate = today;

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationMonthlyBuilder()
            .withStartDate(startDate)
            .withDayOfMonth(dayOfMonth)
            .withEndDate(endDate)
            .build();

        Test.startTest();
        insert rd;
        Test.stopTest();

        List<RD2_VisualizeScheduleController.Schedule> schedules = getSchedules(rd.Id);

        System.assertEquals(1, schedules.size(), 'There should be 1 schedule.');
        System.assertEquals(true, schedules[0].isCurrent, 'Schedule should be current');
        System.assertEquals(startDate, schedules[0].startDate, 'Schedule Start Date should be RD Effective Date');
        System.assertEquals(endDate, schedules[0].endDate, 'Schedule End Date should be undefined');
    }

    //// Helpers
    //////////////////////////

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
    * @return TEST_RecurringDonationBuilder
    */
    private static TEST_RecurringDonationBuilder getRecurringDonationBaseBuilder() {
        return getRecurringDonationBaseBuilder(getContact().Id);
    }


    /****
    * @description Returns Recurring Donation with default values
    * @param contactId Contact Id
    * @return TEST_RecurringDonationBuilder
    */
    private static TEST_RecurringDonationBuilder getRecurringDonationBaseBuilder(Id contactId) {
        return TEST_RecurringDonationBuilder.constructEnhancedBuilder()
            .withContact(contactId)
            .withAmount(100)
            .withPaymentMethod('Credit Card')
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
    * @description Executes RD Schedule Visualizer to return installments
    * @param rdId Recurring Donation Id
    * @param numberOfInstallments Maximum number of installments to return
    * @return List<RD2_VisualizeScheduleController.Installment>
    */
    private static List<RD2_VisualizeScheduleController.Installment> getInstallments(Id rdId, Integer numberOfInstallments) {
        RD2_VisualizeScheduleController.DataTable dataTable = (RD2_VisualizeScheduleController.DataTable)
            RD2_VisualizeScheduleController.getInstallments(rdId, numberOfInstallments).values()[0];

        List<RD2_VisualizeScheduleController.Installment> installments = new List<RD2_VisualizeScheduleController.Installment>();
        for (Object record : dataTable.getRecords()) {
            installments.add((RD2_VisualizeScheduleController.Installment) record);
        }

        return installments;
    }

    /****
    * @description Executes RD Schedule Visualizer to return active schedules
    * @param rdId Recurring Donation Id
    * @return List<RD2_VisualizeScheduleController.Schedule>
    */
    private static List<RD2_VisualizeScheduleController.Schedule> getSchedules(Id rdId) {
        RD2_VisualizeScheduleController.DataTable dataTable = (RD2_VisualizeScheduleController.DataTable)
            RD2_VisualizeScheduleController.getSchedules(rdId).values()[0];

        List<RD2_VisualizeScheduleController.Schedule> schedules = new List<RD2_VisualizeScheduleController.Schedule>();
        for (Object record : dataTable.getRecords()) {
            schedules.add((RD2_VisualizeScheduleController.Schedule) record);
        }

        return schedules;
    }

    /****
    * @description Builds projected installments for the Recurring Donation
    * @param rd Recurring Donation
    * @param numberOfInstallments Number of installments to return
    * @return List<RD2_VisualizeScheduleController.Installment>
    */
    private static List<RD2_VisualizeScheduleController.Installment> buildInstallments(npe03__Recurring_Donation__c rd, Integer numberOfInstallments) {
        Integer counter = 0;
        RD2_ScheduleService scheduleService = new RD2_ScheduleService();
        List<RD2_VisualizeScheduleController.Installment> installments = new List<RD2_VisualizeScheduleController.Installment>();

        for (RD2_ScheduleService.Installment installment : scheduleService.getVisualizedInstallments(
            RD2_ScheduleService.currentDate, numberOfInstallments, scheduleService.buildNewSchedules(rd)
        )) {
            installments.add(new RD2_VisualizeScheduleController.Installment(counter++, installment));
        }

        return installments;
    }

    /****
    * @description Builds schedules for the Recurring Donation
    * @param rd Recurring Donation
    * @return List<RD2_VisualizeScheduleController.Schedule>
    */
    private static List<RD2_VisualizeScheduleController.Schedule> buildSchedules(npe03__Recurring_Donation__c rd) {
        Integer counter = 0;
        RD2_ScheduleService scheduleService = new RD2_ScheduleService();
        List<RD2_VisualizeScheduleController.Schedule> schedules = new List<RD2_VisualizeScheduleController.Schedule>();

        for (RecurringDonationSchedule__c schedule : scheduleService.buildNewSchedules(rd)) {
            schedules.add(new RD2_VisualizeScheduleController.Schedule(
                counter++, new RD2_ScheduleService.ActiveSchedule(schedule, rd)
            ));
        }

        return schedules;
    }

    /****
    * @description Builds installment data table
    * @param isAccessible Sets isAccessible field attribute based on the input argument value
    * @return RD2_VisualizeScheduleController.DataTable
    */
    private static RD2_VisualizeScheduleController.DataTable buildInstallmentDataTable(Boolean isAccessible) {
        RD2_VisualizeScheduleController.DataTable dataTable = new RD2_VisualizeScheduleController.DataTable();
        for (String fieldName : new String[] {
            INSTALLMENT_DONATION_DATE,
            INSTALLMENT_AMOUNT,
            INSTALLMENT_PAYMENT_METHOD
        }) {
            dataTable.addColumn(new RD2_VisualizeScheduleController.DataTableColumn()
                .withFieldName(fieldname)
                .withIsAccessible(isAccessible)
            );
        }

        return dataTable;
    }

    /****
    * @description Builds schedule data table
    * @param isAccessible Sets isAccessible field attribute based on the input argument value
    * @return RD2_VisualizeScheduleController.DataTable
    */
    private static RD2_VisualizeScheduleController.DataTable buildScheduleDataTable(Boolean isAccessible) {
        RD2_VisualizeScheduleController.DataTable dataTable = new RD2_VisualizeScheduleController.DataTable();
        for (String fieldName : new String[] {
            SCHEDULE_IS_CURRENT,
            SCHEDULE_AMOUNT,
            SCHEDULE_PAYMENT_METHOD,
            SCHEDULE_CAMPAIGN,
            SCHEDULE_START_DATE,
            SCHEDULE_END_DATE,
            SCHEDULE_PERIOD,
            SCHEDULE_FREQUENCY,
            SCHEDULE_DAY_OF_MONTH
        }) {
            dataTable.addColumn(new RD2_VisualizeScheduleController.DataTableColumn()
                .withFieldName(fieldname)
                .withIsAccessible(isAccessible)
            );
        }

        return dataTable;
    }

    /****
    * @description Asserts schedules and installments cannot be displayed
    * when RD2 is not enabled.
    * @param actualException Actual exception (if any)
    * @return void
    */
    private static void assertRD2IsNotEnabledException(Exception actualException) {
        // The label name does not match the label value.
        // The label value: "You must enable Enhanced Recurring Donations to use this component."
        // This switch will be fixed in another WI.
        System.assertNotEquals(null, actualException, 'An exception should be generated');

        System.assertEquals(System.Label.RD2_ScheduleVisualizerErrorInvalidUsage, actualException.getMessage(),
            'Exception message should match');
    }

    /****
    * @description Asserts the schedule or installment component is added on a detail page
    * that is not a Recurring Donation detail page.
    * @param actualException Actual exception (if any)
    * @return void
    */
    private static void assertComponentOnInvalidPageException(Exception actualException) {
        // The label name does not match the label value.
        // The label value: "This component must be used on a Recurring Donations record page."
        // This switch will be fixed in another WI.
        System.assertNotEquals(null, actualException, 'An exception should be generated');

        System.assertEquals(System.Label.RD2_ScheduleVisualizerErrorEnhancedRDNot, actualException.getMessage(),
            'Exception message should match');
    }

    /****
    * @description Asserts error message indicating no active schedule can be displayed on the component
    * @param actualException Actual exception (if any)
    * @return void
    */
    private static void assertNoActiveScheduleReturnedException(Exception actualException) {
        System.assertNotEquals(null, actualException, 'An exception should be generated');

        System.assertEquals(System.Label.RD2_ScheduleVisualizerMessageNoActiveSchedule, actualException.getMessage(),
            'Exception message should match');
    }

    /****
    * @description Asserts error message indicating no installment can be displayed on the component
    * @param actualException Actual exception (if any)
    * @return void
    */
    private static void assertNoInstallmentReturnedException(Exception actualException) {
        System.assertNotEquals(null, actualException, 'An exception should be generated');

        System.assertEquals(System.Label.RD2_ScheduleVisualizerMessageNoSchedule, actualException.getMessage(),
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