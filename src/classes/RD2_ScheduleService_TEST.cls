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
* @description Enhanced Recurring Donations Schedule Service unit tests
*
*/
@isTest(IsParallel=true)
private with sharing class RD2_ScheduleService_TEST {

    private static final TEST_SObjectGateway.RecurringDonationScheduleGateway scheduleGateway = new TEST_SObjectGateway.RecurringDonationScheduleGateway();
    private static final Date DATE_ESTABLISHED = Date.newInstance(2019, 9, 15);
    private static final String PAYMENT_CREDIT_CARD = 'Credit Card';
    private static final String PAYMENT_CHECK = 'Check';
    private static final String PAYMENT_ACH_EFT = 'ACH/EFT';


    /****
    * @description Creates data required for unit tests
    */
    @TestSetup
    private static void setUp() {
        insert UTIL_UnitTestData_TEST.getContact();
    }

    /***
    * @description Verifies details of monthly schedule creation
    */
    @isTest
    private static void shouldCreateMonthlySchedule() {
        String dayOfMonth = '20';
        npe03__Recurring_Donation__c rd = getRecurringDonationMonthlyBuilder()
            .withPaymentMethod(PAYMENT_CHECK)
            .withDayOfMonth(dayOfMonth)
            .build();

        List<RecurringDonationSchedule__c> schedules = new RD2_ScheduleService().getNewSchedules(rd);

        System.assertEquals(1, schedules.size(), 'One schedule should exist for a new monthly RD');
        System.assertEquals(rd.npe03__Amount__c, schedules[0].InstallmentAmount__c, 'Installment Amount should match RD Amount');
        System.assertEquals(PAYMENT_CHECK, schedules[0].PaymentMethod__c, 'Payment Method should match RD Payment Method');
        System.assertEquals(rd.InstallmentFrequency__c, schedules[0].InstallmentFrequency__c, 'Installment Frequency should match RD Installment Frequency');
        System.assertEquals(RD2_Constants.INSTALLMENT_PERIOD_MONTHLY, schedules[0].InstallmentPeriod__c, 'Installment Period should match RD Installment Period');
        System.assertEquals(dayOfMonth, schedules[0].DayOfMonth__c, 'Day of Month should be 20');
        System.assertEquals(DATE_ESTABLISHED, schedules[0].StartDate__c, 'Start Date should match RD Established Date');
        System.assertEquals(null, schedules[0].EndDate__c, 'End Date should be undefined');
    }

    /***
    * @description Verifies details of 1st and 15th schedule creation
    */
    @isTest
    private static void shouldCreateFirstandFifteenthSchedule() {
        Date startDate = Date.newInstance(2019, 10, 1);

        npe03__Recurring_Donation__c rd = getRecurringDonationFirstAndFifteenthBuilder()
            .withStartDate(startDate)
            .withPaymentMethod(PAYMENT_ACH_EFT)
            .withInstallmentFrequency(2)
            .build();

        List<RecurringDonationSchedule__c> schedules = new RD2_ScheduleService().getNewSchedules(rd);

        System.assertEquals(2, schedules.size(), 'Two schedules should exist for Installment Period 1st and 15th');        
        for (RecurringDonationSchedule__c schedule : schedules) {
            System.assertEquals(rd.npe03__Amount__c, schedule.InstallmentAmount__c, 'Installment Amount should match RD Amount');
            System.assertEquals(PAYMENT_ACH_EFT, schedule.PaymentMethod__c, 'Payment Method should match RD Payment Method');
            System.assertEquals(rd.InstallmentFrequency__c, schedule.InstallmentFrequency__c, 'Installment Frequency should match RD Installment Frequency');
            System.assertEquals(RD2_Constants.INSTALLMENT_PERIOD_FIRST_AND_FIFTEENTH, schedule.InstallmentPeriod__c, 'Installment Period should be 1st and 15th');
            System.assertEquals(startDate, schedule.StartDate__c, 'Schedule Start Date should be RD Effective Date');
            System.assertEquals(null, schedule.EndDate__c, 'Schedule End Date should be undefined');
        }

        System.assertEquals('1', schedules[0].DayOfMonth__c, 'First schedule Day of Month should be 1');
        System.assertEquals('15', schedules[1].DayOfMonth__c, 'Second schedule Day of Month should be 15');
    }

    /***
    * @description Verifies details of yearly schedule creation
    */
    @isTest
    private static void shouldCreateYearlySchedule() {
        Date startDate = Date.newInstance(2020, 3, 4);
        Integer installmentFrequency = 3;

        npe03__Recurring_Donation__c rd = getRecurringDonationYearlyBuilder()
            .withStartDate(startDate)
            .withInstallmentFrequency(installmentFrequency)
            .build();

        List<RecurringDonationSchedule__c> schedules = new RD2_ScheduleService().getNewSchedules(rd);
        System.assertEquals(1, schedules.size(), 'One schedule should exist for a new yearly RD');
        RecurringDonationSchedule__c schedule = schedules[0];

        System.assertEquals(rd.npe03__Amount__c, schedule.InstallmentAmount__c, 'Installment Amount should match RD Amount');
        System.assertEquals(PAYMENT_CREDIT_CARD, schedule.PaymentMethod__c, 'Payment Method should match RD Payment Method');
        System.assertEquals(installmentFrequency, schedule.InstallmentFrequency__c, 'Installment Frequency should match RD Installment Frequency');
        System.assertEquals(RD2_Constants.INSTALLMENT_PERIOD_YEARLY, schedule.InstallmentPeriod__c, 'Installment Period should be Yearly');
        System.assertEquals(null, schedule.DayOfMonth__c, 'Day of Month should be undefined');
        System.assertEquals(startDate, schedule.StartDate__c, 'Start Date should be RD Effective Date');
        System.assertEquals(null, schedule.EndDate__c, 'End Date should be undefined');
    }

    /***
    * @description Verifies details of weekly schedule creation
    */
    @isTest
    private static void shouldCreateWeeklySchedule() {
        Date startDate = Date.newInstance(2019, 11, 1);
        Integer installmentFrequency = 13;

        npe03__Recurring_Donation__c rd = getRecurringDonationWeeklyBuilder()
            .withStartDate(startDate)
            .withPaymentMethod(PAYMENT_CHECK)
            .withInstallmentFrequency(installmentFrequency)
            .build();

        List<RecurringDonationSchedule__c> schedules = new RD2_ScheduleService().getNewSchedules(rd);
        System.assertEquals(1, schedules.size(), 'One schedule should exist for a new weekly RD');
        RecurringDonationSchedule__c schedule = schedules[0];

        System.assertEquals(rd.npe03__Amount__c, schedule.InstallmentAmount__c, 'Installment Amount should match RD Amount');
        System.assertEquals(PAYMENT_CHECK, schedule.PaymentMethod__c, 'Payment Method should match RD Payment Method');
        System.assertEquals(installmentFrequency, schedule.InstallmentFrequency__c, 'Installment Frequency should match RD Installment Frequency');
        System.assertEquals(RD2_Constants.INSTALLMENT_PERIOD_WEEKLY, schedule.InstallmentPeriod__c, 'Installment Period should be Yearly');
        System.assertEquals(null, schedule.DayOfMonth__c, 'Day of Month should be undefined');
        System.assertEquals(startDate, schedule.StartDate__c, 'Start Date should be RD Effective Date');
        System.assertEquals(null, schedule.EndDate__c, 'End Date should be undefined');
    }

    /***
    * @description Verifies schedule is not created when RD is closed.
    */
    @isTest
    private static void shouldNotCreateScheduleWhenRDIsClosed() {
        npe03__Recurring_Donation__c rd = getRecurringDonationMonthlyBuilder()
            .withStatusClosed()
            .build();

        List<RecurringDonationSchedule__c> schedules = new RD2_ScheduleService().getNewSchedules(rd);

        System.assertEquals(0, schedules.size(), 'No schedule should be returned for a Closed RD');
    }

    /***
    * @description Verifies new schedule is created when new RD is lapsed
    */
    @isTest
    private static void shouldCreateNewScheduleWhenNewRDIsLapsed() {
        Date startDate = Date.newInstance(2018, 3, 17);
        npe03__Recurring_Donation__c rd = getRecurringDonationMonthlyBuilder()
            .withStartDate(startDate)
            .withStatus(RD2_Constants.STATUS_LAPSED)
            .build();

        RD2_ScheduleService service = new RD2_ScheduleService();
        List<RecurringDonationSchedule__c> schedules = service.getNewSchedules(rd);

        System.assertEquals(1, schedules.size(), '1 new schedule should be created.');
        System.assertEquals(startDate, schedules[0].StartDate__c, 'Start date on new schedule should match');
    }

    /***
    * @description Verifies only future schedule is created when RD is edited twice with future schedules
    */
    @isTest
    private static void shouldCreateOneCurrentAndOneFutureSchedule() {
        npe03__Recurring_Donation__c rd = getRecurringDonationMonthlyBuilder().build();

        List<RecurringDonationSchedule__c> schedules = new RD2_ScheduleService().getNewSchedules(rd);

        schedules.add(schedules[0].clone());
        schedules[1].StartDate__c = Date.today().addMonths(1);
        schedules[1].InstallmentAmount__c = 500;
        schedules[0].EndDate__c = schedules[1].StartDate__c.addDays(-1);

        rd.StartDate__c = Date.today().addMonths(2);
        rd.npe03__Amount__c = 600;

        TDTM_Runnable.DMLWrapper dmlUpdates = new RD2_ScheduleService().getUpdatedSchedules(rd, schedules);

        System.assertEquals(2, dmlUpdates.objectsToUpdate.size(), 'Number of updated schedules should equal 2');

        System.assertEquals(
            ((RecurringDonationSchedule__c)dmlUpdates.objectsToInsert[0]).StartDate__c.addDays(-1),
            ((RecurringDonationSchedule__c)dmlUpdates.objectsToUpdate[0]).EndDate__c,
            'End date should be one day earlier than Start Date of new donation');

        System.assertEquals(
            ((RecurringDonationSchedule__c)dmlUpdates.objectsToUpdate[1]).StartDate__c.addDays(-1),
            ((RecurringDonationSchedule__c)dmlUpdates.objectsToUpdate[1]).EndDate__c,
            'End date should be one day earlier than Start Date of the same donation');

        System.assertEquals(
            ((RecurringDonationSchedule__c)dmlUpdates.objectsToInsert[0]).EndDate__c, null,
            'End date should be null on new donation');
    }

    /***
    * @description Verifies next donation date is not calculated for closed recurring donation.
    */
    @isTest
    private static void shouldNotGenerateNextDonationDateWhenRDIsClosed() {
        Date today = Date.newInstance(2019, 11, 24);
        RD2_ScheduleService service = getScheduleServiceForCurrentDate(today);

        npe03__Recurring_Donation__c rd = getRecurringDonationMonthlyBuilder()
            .withStatusClosed()
            .build();

        System.assertEquals(null, service.getNextDonationDate(rd), 'Next Donation Date should be null');
    }

    /***
    * @description Verifies next donation date for monthly donation when donation falls in next month.
    */
    @isTest
    private static void shouldGenerateNextDonationDateInNextMonth() {
        Date startDate = Date.newInstance(2019, 11, 24);
        Date nextDonationDate = Date.newInstance(2019, 12, 23);

        npe03__Recurring_Donation__c rd = getRecurringDonationMonthlyBuilder()
            .withStartDate(startDate)
            .withDayOfMonth('23')
            .build();

        RD2_ScheduleService service = getScheduleServiceForCurrentDate(startDate);

        System.assertEquals(nextDonationDate, service.getNextDonationDate(rd), 'Next Donation Date should match');
    }

    /***
    * @description Verifies next donation date for monthly donation when donation falls in next month.
    */
    @isTest
    private static void shouldGenerateNextDonationDateLastDayInFebruaryLeapYear() {
        Date startDate = Date.newInstance(2019, 11, 30);
        Date today = Date.newInstance(2020, 2, 10);
        Date nextDonationDate = Date.newInstance(2020, 2, 29);

        npe03__Recurring_Donation__c rd = getRecurringDonationMonthlyBuilder()
            .withStartDate(startDate)
            .withDayOfMonth(RD2_Constants.DAY_OF_MONTH_LAST_DAY)
            .build();

        RD2_ScheduleService service = getScheduleServiceForCurrentDate(today);

        System.assertEquals(nextDonationDate, service.getNextDonationDate(rd), 'Next Donation Date should match');
    }

    /***
    * @description Verifies next donation date for monthly donation when donation falls in next month.
    */
    @isTest
    private static void shouldGenerateNextDonationDateLastDayInMarch() {
        Date startDate = Date.newInstance(2015, 11, 30);
        Date today = Date.newInstance(2019, 3, 1);
        Date nextDonationDate = Date.newInstance(2019, 3, 31);

        npe03__Recurring_Donation__c rd = getRecurringDonationMonthlyBuilder()
            .withStartDate(startDate)
            .withDayOfMonth(RD2_Constants.DAY_OF_MONTH_LAST_DAY)
            .build();

        RD2_ScheduleService service = getScheduleServiceForCurrentDate(today);

        System.assertEquals(nextDonationDate, service.getNextDonationDate(rd), 'Next Donation Date should match');
    }

    /***
    * @description Verifies next donation date for monthly donation when donation falls in current month.
    */
    @isTest
    private static void shouldGenerateNextDonationDateInCurrentMonth() {
        Date startDate = Date.newInstance(2019, 11, 1);
        Date nextDonationDate = Date.newInstance(2019, 11, 23);

        npe03__Recurring_Donation__c rd = getRecurringDonationMonthlyBuilder()
            .withStartDate(startDate)
            .withDayOfMonth('23')
            .build();

        RD2_ScheduleService service = getScheduleServiceForCurrentDate(startDate);

        System.assertEquals(nextDonationDate, service.getNextDonationDate(rd), 'Next Donation Date should match');
    }

    /***
    * @description Verifies next donation date for 1st and 15th donation when donation schedules.
    */
    @isTest
    private static void shouldGenerateNextDonationDateFromEarliest() {
        Date startDate = Date.newInstance(2019, 11, 14);
        Date nextDonationDate = Date.newInstance(2019, 11, 15);

        npe03__Recurring_Donation__c rd = getRecurringDonationFirstAndFifteenthBuilder()
            .withStartDate(startDate)
            .build();

        RD2_ScheduleService service = getScheduleServiceForCurrentDate(startDate);

        System.assertEquals(nextDonationDate, service.getNextDonationDate(rd), 'Next Donation Date should match');
    }

    /***
    * @description Verifies next donation date for monthly donation for yearly donation.
    */
    @isTest
    private static void shouldGenerateNextDonationDateFromYearlyStartDate() {
        Date startDate = Date.newInstance(2020, 11, 1);
        npe03__Recurring_Donation__c rd = getRecurringDonationYearlyBuilder()
            .withStartDate(startDate)
            .build();

        RD2_ScheduleService service = getScheduleServiceForCurrentDate(startDate);

        System.assertEquals(startDate, service.getNextDonationDate(rd), 'Next Donation Date should match');
    }

    /***
    * @description Verifies next donation date for weekly donation.
    */
    @isTest
    private static void shouldGenerateNextDonationDateFromWeeklyStartDate() {
        Date startDate = Date.newInstance(2018, 3, 17);
        npe03__Recurring_Donation__c rd = getRecurringDonationWeeklyBuilder()
            .withStartDate(startDate)
            .build();

        RD2_ScheduleService service = getScheduleServiceForCurrentDate(startDate);

        System.assertEquals(startDate, service.getNextDonationDate(rd), 'Next Donation Date should match');
    }

    /***
    * @description Verifies next donation date for daily donation with frequency > 1.
    */
    @isTest
    private static void shouldGenerateNextDonationDateWhenFrequencyFifteenDays() {
        Date startDate = Date.newInstance(2018, 7, 1);
        Date today = Date.newInstance(2018, 7, 17);
        Date nextDonationDate = Date.newInstance(2018, 7, 31);

        npe03__Recurring_Donation__c rd = getRecurringDonationDailyBuilder()
            .withStartDate(startDate)
            .withInstallmentFrequency(15)
            .build();

        RD2_ScheduleService service = getScheduleServiceForCurrentDate(today);

        System.assertEquals(nextDonationDate, service.getNextDonationDate(rd), 'Next Donation Date should match');
    }

    /***
    * @description Verifies next donation date for weekly donation with frequency > 1.
    */
    @isTest
    private static void shouldGenerateNextDonationDateWhenFrequencyThreeWeeks() {
        Date startDate = Date.newInstance(2018, 3, 17);
        Date today = Date.newInstance(2018, 4, 8);
        Date nextDonationDate = Date.newInstance(2018, 4, 28);

        npe03__Recurring_Donation__c rd = getRecurringDonationWeeklyBuilder()
            .withStartDate(startDate)
            .withInstallmentFrequency(3)
            .build();

        RD2_ScheduleService service = getScheduleServiceForCurrentDate(today);

        System.assertEquals(nextDonationDate, service.getNextDonationDate(rd), 'Next Donation Date should match');
    }

    /***
    * @description Verifies next donation date for monthly donation with frequency > 1.
    */
    @isTest
    private static void shouldGenerateNextDonationDateWhenFrequencyElevenMonths() {
        Date startDate = Date.newInstance(2018, 3, 17);
        Date today = Date.newInstance(2023, 1, 18);
        Date nextDonationDate = Date.newInstance(2023, 9, 17);

        npe03__Recurring_Donation__c rd = getRecurringDonationMonthlyBuilder()
            .withStartDate(startDate)
            .withInstallmentFrequency(11)
            .withDayOfMonth('17')
            .build();

        RD2_ScheduleService service = getScheduleServiceForCurrentDate(today);

        System.assertEquals(nextDonationDate, service.getNextDonationDate(rd), 'Next Donation Date should match');
    }

    /***
    * @description Verifies next donation date for yearly donation with frequency > 1.
    */
    @isTest
    private static void shouldGenerateNextDonationDateWhenFrequencyFiveYears() {
        Date startDate = Date.newInstance(2018, 3, 17);
        Date today = Date.newInstance(2023, 3, 18);
        Date nextDonationDate = Date.newInstance(2028, 3, 17);

        npe03__Recurring_Donation__c rd = getRecurringDonationYearlyBuilder()
            .withStartDate(startDate)
            .withInstallmentFrequency(5)
            .build();

        RD2_ScheduleService service = getScheduleServiceForCurrentDate(today);

        System.assertEquals(nextDonationDate, service.getNextDonationDate(rd), 'Next Donation Date should match');
    }

    /***
    * @description Verifies next donation date for 1st and 15th donation with frequency > 1.
    */
    @isTest
    private static void shouldGenerateNextDonationDateWhenFrequencyFiveFirstAndFifteenth() {
        Date startDate = Date.newInstance(2018, 3, 17);
        Date today = Date.newInstance(2018, 9, 16);
        Date nextDonationDate = Date.newInstance(2019, 2, 1);

        npe03__Recurring_Donation__c rd = getRecurringDonationFirstAndFifteenthBuilder()
            .withStartDate(startDate)
            .withInstallmentFrequency(5)
            .build();

        RD2_ScheduleService service = getScheduleServiceForCurrentDate(today);

        System.assertEquals(nextDonationDate, service.getNextDonationDate(rd), 'Next Donation Date should match');
    }

    /***
    * @description Verifies next donation date is generated when new RD is lapsed
    */
    @isTest
    private static void shouldGenerateNextDonationDateWhenNewRDIsLapsed() {
        Date startDate = Date.newInstance(2018, 3, 17);
        npe03__Recurring_Donation__c rd = getRecurringDonationDailyBuilder()
            .withStartDate(startDate)
            .withStatus(RD2_Constants.STATUS_LAPSED)
            .build();

        RD2_ScheduleService service = new RD2_ScheduleService();
        System.assertEquals(Date.today(), service.getNextDonationDate(rd), 'Next donation date should equal today.');
    }

    /***
    * @description Verifies update is needed when RD Status is changed to Active Status
    */
    @isTest
    private static void shouldUpdateScheduleWhenClosedStatusIsChangedToActive() {
        npe03__Recurring_Donation__c rd = getRecurringDonationWeeklyBuilder()
            .withStatusClosed()
            .build();

        npe03__Recurring_Donation__c changedRd = rd.clone();
        changedRd.Status__c = RD2_Constants.STATUS_ACTIVE;

        RD2_ScheduleService schedule = new RD2_ScheduleService();
        Boolean updateNeeded = schedule.isScheduleUpdateNeeded(changedRd, rd);

        System.assertEquals(true, updateNeeded, 'Schedule update is required when Status is changed to Active');
    }

    /***
    * @description Verifies update is not needed when RD Status is changed from Active to Lapsed
    */
    @isTest
    private static void shouldNotUpdateScheduleWhenActiveStatusIsChangedToLapsed() {
        npe03__Recurring_Donation__c rd = getRecurringDonationWeeklyBuilder()
            .withStatusActive()
            .build();

        npe03__Recurring_Donation__c changedRd = rd.clone();
        changedRd.Status__c = RD2_Constants.STATUS_LAPSED;

        RD2_ScheduleService schedule = new RD2_ScheduleService();
        Boolean updateNeeded = schedule.isScheduleUpdateNeeded(changedRd, rd);

        System.assertEquals(false, updateNeeded, 'Schedule update is not required when Status is changed to Lapsed');
    }

    /***
    * @description Verifies update is needed when start date on recurring donation is changed.
    */
    @isTest
    private static void shouldUpdateScheduleWhenStartDateChanged() {
        Date startDate = Date.newInstance(2018, 3, 17);
        npe03__Recurring_Donation__c rd = getRecurringDonationWeeklyBuilder()
            .withStartDate(startDate)
            .build();

        npe03__Recurring_Donation__c changeRd = rd.clone();
        changeRd.StartDate__c = Date.today();

        RD2_ScheduleService schedule = new RD2_ScheduleService();
        Boolean updateNeeded = schedule.isScheduleUpdateNeeded(changeRd, rd);

        System.assertEquals(true, updateNeeded, 'Schedule update is required when Start Date is changed');
    }

    /***
    * @description Verifies update is needed when amount on recurring donation is changed.
    */
    @isTest
    private static void shouldUpdateScheduleWhenAmountChanged() {
        npe03__Recurring_Donation__c rd = getRecurringDonationWeeklyBuilder().build();

        npe03__Recurring_Donation__c changeRd = rd.clone();
        changeRd.npe03__Amount__c = 200;

        RD2_ScheduleService schedule = new RD2_ScheduleService();
        Boolean updateNeeded = schedule.isScheduleUpdateNeeded(changeRd, rd);

        System.assertEquals(true, updateNeeded, 'Schedule update is required when Amount is changed');
    }

    /***
    * @description Verifies update is needed when installment period on recurring donation is changed.
    */
    @isTest
    private static void shouldUpdateScheduleWhenInstallmentPeriodChanged() {
        npe03__Recurring_Donation__c rd = getRecurringDonationFirstAndFifteenthBuilder().build();

        npe03__Recurring_Donation__c changeRd = rd.clone();
        changeRd.npe03__Installment_Period__c = RD2_Constants.INSTALLMENT_PERIOD_DAILY;

        RD2_ScheduleService schedule = new RD2_ScheduleService();
        Boolean updateNeeded = schedule.isScheduleUpdateNeeded(changeRd, rd);

        System.assertEquals(true, updateNeeded, 'Schedule update is required when Installment Period is changed');
    }

    /***
    * @description Verifies update is needed when day of month on recurring donation is changed.
    */
    @isTest
    private static void shouldUpdateScheduleWhenDayOfMonthChanged() {
        npe03__Recurring_Donation__c rd = getRecurringDonationMonthlyBuilder().build();

        npe03__Recurring_Donation__c changeRd = rd.clone();
        changeRd.Day_of_Month__c = '23';

        RD2_ScheduleService schedule = new RD2_ScheduleService();
        Boolean updateNeeded = schedule.isScheduleUpdateNeeded(changeRd, rd);

        System.assertEquals(true, updateNeeded, 'Schedule update is required when Day of Month is changed');
    }

    /***
    * @description Verifies update is needed when installment frequency on recurring donation is changed.
    */
    @isTest
    private static void shouldUpdateScheduleWhenInstallmentFrequencyChanged() {
        npe03__Recurring_Donation__c rd = getRecurringDonationWeeklyBuilder().build();

        npe03__Recurring_Donation__c changeRd = rd.clone();
        changeRd.InstallmentFrequency__c = 5;

        RD2_ScheduleService schedule = new RD2_ScheduleService();
        Boolean updateNeeded = schedule.isScheduleUpdateNeeded(changeRd, rd);

        System.assertEquals(true, updateNeeded, 'Schedule update is required when Installment Frequency is changed');
    }

    /***
    * @description Verifies update is needed when payment method on recurring donation is changed.
    */
    @isTest
    private static void shouldUpdateScheduleWhenPaymentMethodChanged() {
        npe03__Recurring_Donation__c rd = getRecurringDonationMonthlyBuilder().build();

        npe03__Recurring_Donation__c changeRd = rd.clone();
        changeRd.PaymentMethod__c = PAYMENT_ACH_EFT;

        RD2_ScheduleService schedule = new RD2_ScheduleService();
        Boolean updateNeeded = schedule.isScheduleUpdateNeeded(changeRd, rd);

        System.assertEquals(true, updateNeeded, 'Schedule update is required when Payment Method is changed');
    }

    /***
    * @description Verifies update is needed when campaign on recurring donation is changed.
    */
    @isTest
    private static void shouldUpdateScheduleWhenCampaignChanged() {
        npe03__Recurring_Donation__c rd = getRecurringDonationMonthlyBuilder().build();

        npe03__Recurring_Donation__c changeRd = rd.clone();
        changeRd.npe03__Recurring_Donation_Campaign__c = UTIL_UnitTestData_TEST.mockId(Campaign.getSObjectType());

        RD2_ScheduleService schedule = new RD2_ScheduleService();
        Boolean updateNeeded = schedule.isScheduleUpdateNeeded(changeRd, rd);

        System.assertEquals(true, updateNeeded, 'Schedule update is required when Campaign is changed');
    }

    /***
    * @description Verifies update is NOT needed when contact on recurring donation is changed.
    */
    @isTest
    private static void shouldNotUpdateScheduleWhenContactChanged() {
        npe03__Recurring_Donation__c rd = getRecurringDonationMonthlyBuilder().build();

        npe03__Recurring_Donation__c changeRd = rd.clone();
        changeRd.npe03__Contact__c = UTIL_UnitTestData_TEST.mockId(Contact.getSObjectType());

        RD2_ScheduleService schedule = new RD2_ScheduleService();
        Boolean updateNeeded = schedule.isScheduleUpdateNeeded(changeRd, rd);

        System.assertEquals(false, updateNeeded, 'Schedule update is not required when Contact donor is changed');
    }

    /***
    * @description Verifies updated schedule is created when day of month is changed.
    */
    @isTest
    private static void shouldCreateNewMonthlySchedule() {
        Date startDate = Date.newInstance(2018, 3, 17);
        npe03__Recurring_Donation__c rd = getRecurringDonationMonthlyBuilder()
            .withStartDate(startDate)
            .withDayOfMonth('23')
            .build();

        RD2_ScheduleService service = new RD2_ScheduleService();
        List<RecurringDonationSchedule__c> schedules = service.getNewSchedules(rd);

        //RD update
        String dayOfMonth = '21';
        rd.Day_of_Month__c = dayOfMonth;

        TDTM_Runnable.DMLWrapper changes = service.getUpdatedSchedules(rd, schedules);
        System.assertEquals(startDate.addDays(-1), changes.objectsToUpdate[0].get('EndDate__c'), 'Existing schedule End Date should invalidate the schedule');
        System.assertEquals(dayOfMonth, changes.objectsToInsert[0].get('DayOfMonth__c'), 'New schedule Day of month should be match');
    }

    /***
    * @description Verifies schedule is ended when RD is closed.
    */
    @isTest
    private static void shouldInactivateCurrentScheduleWhenRDIsClosed() {
        npe03__Recurring_Donation__c rd = getRecurringDonationMonthlyBuilder().build();
        RD2_ScheduleService service = new RD2_ScheduleService();
        List<RecurringDonationSchedule__c> schedules = service.getNewSchedules(rd);

        //RD update
        rd.Status__c = RD2_Constants.STATUS_CLOSED;

        TDTM_Runnable.DMLWrapper changes = service.getUpdatedSchedules(rd, schedules);
        System.assertEquals(Date.today().addDays(-1), changes.objectsToUpdate[0].get('EndDate__c'), 'Existing schedule End Date should be set to yesterday.');
        System.assertEquals(0, changes.objectsToInsert.size(), 'There should be no schedules to insert.');
    }

    /***
    * @description Verifies new weekly schedule is created on change from 1st and 15th
    */
    @isTest
    private static void shouldChangeFromFirstAndFifteenthToWeekly() {
        Date startDate = Date.newInstance(2018, 3, 17);
        Date endDate = Date.newInstance(2018, 3, 16);

        npe03__Recurring_Donation__c rd = getRecurringDonationFirstAndFifteenthBuilder()
            .withStartDate(startDate)
            .build();

        RD2_ScheduleService service = new RD2_ScheduleService();
        List<RecurringDonationSchedule__c> schedules = service.getNewSchedules(rd);

        //RD update
        rd.npe03__Installment_Period__c = RD2_Constants.INSTALLMENT_PERIOD_WEEKLY;

        TDTM_Runnable.DMLWrapper changes = service.getUpdatedSchedules(rd, schedules);
        System.assertEquals(startDate.addDays(-1), changes.objectsToUpdate[0].get('EndDate__c'), 'First schedule End Date should be updated');
        System.assertEquals(startDate.addDays(-1), changes.objectsToUpdate[1].get('EndDate__c'), 'Second schedule End Date should be updated');
        System.assertEquals(RD2_Constants.INSTALLMENT_PERIOD_WEEKLY, changes.objectsToInsert[0].get('InstallmentPeriod__c'), 'New schedule Installment Period should match');
    }

    /***
    * @description Verifies visualization works with a large number of installments requested
    */
    @isTest
    private static void shouldReturn480InstallmentsWhen480Requested() {
        final Integer numberOfInstallments = 480;
        final Date startDate = Date.newInstance(2019, 11, 1);
        final Date nextDonationDate = Date.newInstance(2059, 10, 1);

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        RD2_ScheduleService service = getScheduleServiceForCurrentDate(startDate);

        npe03__Recurring_Donation__c rd = getRecurringDonationMonthlyBuilder()
            .withDateEstablished(startDate)
            .withStartDate(startDate)
            .build();

        Test.startTest();
        insert rd;
        Test.stopTest();

        List<RD2_ScheduleService.Installment> installments = service.getVisualizedInstallments(
            new List<npe03__Recurring_Donation__c>{ rd }, startDate, numberOfInstallments, null
        ).values()[0];

        System.assertEquals(numberOfInstallments, installments.size(), 'Number of Installments should match');
        System.assertEquals(nextDonationDate, installments[numberOfInstallments - 1].nextDonationDate, 
            'Final installment date should match RD Next Donation Date');
    }

    /***
    * @description Verifies visualization does not fail when zero installments are requested
    */
    @isTest
    private static void shouldReturnZeroInstallmentsWhenZeroRequested() {
        final Integer numberOfInstallments = 0;
        final Date startDate = Date.newInstance(2019, 11, 1);

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        RD2_ScheduleService service = getScheduleServiceForCurrentDate(startDate);

        npe03__Recurring_Donation__c rd = getRecurringDonationMonthlyBuilder()
            .withDateEstablished(startDate)
            .withStartDate(startDate)
            .build();

        Test.startTest();
        insert rd;
        Test.stopTest();

        List<RD2_ScheduleService.Installment> installments = service.getVisualizedInstallments(
            new List<npe03__Recurring_Donation__c>{ rd }, startDate, numberOfInstallments, null
        ).values()[0];

        System.assertEquals(0, installments.size(), 'There should be 0 installments.');
    }

    /***
    * @description Verifies visualization does not fail when zero installments are requested
    */
    @isTest
    private static void shouldReturnZeroInstallmentsWhenStatusClosed() {
        final Integer numberOfInstallments = 12;
        Date startDate = Date.newInstance(2019, 11, 1);

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        RD2_ScheduleService service = getScheduleServiceForCurrentDate(startDate);

        npe03__Recurring_Donation__c rd = getRecurringDonationMonthlyBuilder()
            .withStartDate(startDate)
            .withStatusClosed()
            .build();

        Test.startTest();
        insert rd;
        Test.stopTest();

        List<RD2_ScheduleService.Installment> installments = service.getVisualizedInstallments(
            new List<npe03__Recurring_Donation__c>{ rd }, startDate, numberOfInstallments, null
        ).values()[0];

        System.assertEquals(0, installments.size(), 'There should be 0 installments.');
    }

    /***
    * @description Verifies visualization does not fail when Recurring Donation is not provided
    */
    @isTest
    private static void shouldReturnZeroInstallmentsWhenRDIsNull() {
        final Integer numberOfInstallments = 12;
        final Date startDate = Date.newInstance(2019, 11, 1);

        RD2_ScheduleService service = getScheduleServiceForCurrentDate(startDate);

        Map<Id, List<RD2_ScheduleService.Installment>> installmentsByRDId = service.getVisualizedInstallments(
            new List<npe03__Recurring_Donation__c>{ null }, startDate, numberOfInstallments, null
        );

        System.assertEquals(0, installmentsByRDId.size(), 'No installment should be returned when RD is not provided');
    }

    /***
    * @description Verifies visualization substitutes default when null start date is used
    */
    @isTest
    private static void shouldReturnRequestedInstallmentsWhenStartDateIsNull() {
        final Integer numberOfInstallments = 12;
        final Date startDate = Date.newInstance(2019, 11, 1);
        Date nextDonationDate = Date.newInstance(2020, 10, 1);

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        RD2_ScheduleService service = getScheduleServiceForCurrentDate(startDate);

        npe03__Recurring_Donation__c rd = getRecurringDonationMonthlyBuilder().build();        

        Test.startTest();
        insert rd;
        Test.stopTest();

        List<RD2_ScheduleService.Installment> installments = service.getVisualizedInstallments(
            new List<npe03__Recurring_Donation__c>{ rd }, null, numberOfInstallments, null
        ).values()[0];

        System.assertEquals(numberOfInstallments, installments.size(), 'There should be 12 installments.');
        System.assertEquals(nextDonationDate, installments[numberOfInstallments - 1].nextDonationDate,
            'Final installment date should be 10/1/2020.');
    }

    /***
    * @description Verifies visualization substitutes default when null maxDates are requested
    */
    @isTest
    private static void shouldReturnTwelveInstallmentsWhenNumberRequestedIsNull() {
        final Date startDate = Date.newInstance(2019, 11, 1);
        Date nextDonationDate = Date.newInstance(2020, 10, 1);

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        RD2_ScheduleService service = getScheduleServiceForCurrentDate(startDate);

        npe03__Recurring_Donation__c rd = getRecurringDonationMonthlyBuilder()
            .withStartDate(startDate)
            .build();

        Test.startTest();
        insert rd;
        Test.stopTest();

        List<RD2_ScheduleService.Installment> installments = service.getVisualizedInstallments(
            new List<npe03__Recurring_Donation__c>{ rd }, startDate, null, null
        ).values()[0];

        Integer expectedNumber = 12;
        System.assertEquals(expectedNumber, installments.size(), 'There should be 12 installments.');
        System.assertEquals(nextDonationDate, installments[expectedNumber - 1].nextDonationDate, 
            'Final installment date should be 10/1/2020.');
    }

    /***
    * @description Verifies visualization substitutes default when null maxDates are requested
    */
    @isTest
    private static void shouldReturnTwelveInstallmentsWhenSchedulesInjected() {
        final Date startDate = Date.newInstance(2019, 11, 1);
        Date nextDonationDate = Date.newInstance(2020, 10, 1);

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        RD2_ScheduleService service = getScheduleServiceForCurrentDate(startDate);
        
        npe03__Recurring_Donation__c rd = getRecurringDonationMonthlyBuilder().build();

        Test.startTest();
        insert rd;
        Test.stopTest();

        List<RecurringDonationSchedule__c> schedules = [
            SELECT
                Campaign__c,
                Campaign__r.Name,
                DayOfMonth__c,
                EndDate__c,
                InstallmentAmount__c,
                InstallmentFrequency__c,
                InstallmentPeriod__c,
                PaymentMethod__c,
                RecurringDonation__c,
                StartDate__c
            FROM RecurringDonationSchedule__c
            WHERE RecurringDonation__c = :rd.Id
            AND Active__c = true];

        List<RD2_ScheduleService.Installment> installments = service.getVisualizedInstallments(
            new List<npe03__Recurring_Donation__c>{ rd }, startDate, null, new Map<Id, List<RecurringDonationSchedule__c>>{ rd.Id => schedules }
        ).values()[0];

        Integer expectedNumber = 12;
        System.assertEquals(expectedNumber, installments.size(), 'There should be 12 installments.');
        System.assertEquals(nextDonationDate, installments[ expectedNumber - 1].nextDonationDate, 
            'Final installment date should be 10/1/2020.');
    }

    /***
    * @description Verifies visualization substitutes default when null maxDates are requested
    */
    @isTest
    private static void shouldReturnTenInstallmentsWhenEndDateIsReached() {
        final Integer numberOfInstallments = 12;
        final Date startDate = Date.newInstance(2020, 1, 1);
        final Date endDate = Date.newInstance(2020, 10, 31);
        Date nextDonationDate = Date.newInstance(2020, 10, 1);

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        RD2_ScheduleService service = new RD2_ScheduleService();

        npe03__Recurring_Donation__c rd = getRecurringDonationMonthlyBuilder()
            .withStartDate(startDate)
            .build();

        Test.startTest();
        insert rd;
        Test.stopTest();

        List<RecurringDonationSchedule__c> rdSchedules = scheduleGateway.getRecords(rd);
        rdSchedules[0].EndDate__c = endDate;
        update rdSchedules;

        List<RD2_ScheduleService.Installment> installments = service.getVisualizedInstallments(
            new List<npe03__Recurring_Donation__c>{ rd }, startDate, numberOfInstallments, null
        ).values()[0];

        Integer expectedNumber = 10;
        System.assertEquals(expectedNumber, installments.size(), 'There should be 10 installments.');
        System.assertEquals(nextDonationDate, installments[expectedNumber - 1].nextDonationDate, 
            'Final installment date should be 10/1/2020.');
    }

    /***
    * @description Verifies visualization substitutes default when null maxDates are requested
    */
    @isTest
    private static void shouldReturnTwelveInstallmentsEachForThreeRDsWhenNumberRequestedIsNull() {
        final Integer numberOfInstallments = null;
        final Date startDate = Date.newInstance(2019, 11, 1);
        Date nextDonationDate1 = Date.newInstance(2019, 12, 1);
        Date nextDonationDate2 = Date.newInstance(2020, 1, 17);
        Date nextDonationDate3 = Date.newInstance(2020, 1, 15);

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        RD2_ScheduleService service = new RD2_ScheduleService();

        List<npe03__Recurring_Donation__c> rds = new List<npe03__Recurring_Donation__c>{
            getRecurringDonationMonthlyBuilder()
                .withStartDate(startDate)
                .withAmount(50)
                .build(),
            getRecurringDonationWeeklyBuilder()
                .withStartDate(startDate)
                .withAmount(100)
                .build(),
            getRecurringDonationFirstAndFifteenthBuilder()
                .withStartDate(startDate)
                .withAmount(25)
                .build()
        };

        Test.startTest();
        insert rds;
        Test.stopTest();

        Map<Id, List<RD2_ScheduleService.Installment>> installmentsByRDId = service.getVisualizedInstallments(
            rds, startDate, numberOfInstallments, null
        );

        System.assertEquals(nextDonationDate1, installmentsByRDId.get(rds[0].Id)[1].nextDonationDate, 'Donation date should be 12/1/2019.');
        System.assertEquals(nextDonationDate2, installmentsByRDId.get(rds[1].Id)[11].nextDonationDate, 'Donation date should be 1/17/2020.');
        System.assertEquals(nextDonationDate3, installmentsByRDId.get(rds[2].Id)[5].nextDonationDate, 'Donation date should be 1/15/2020.');
    }

    /***
    * @description Verifies visualization does not fail when negative max dates requested
    */
    @isTest
    private static void shouldReturnZeroInstallmentsWhenNegativeNumberRequested() {
        final Integer numberOfInstallments = -5;
        final Date startDate = Date.newInstance(2019, 11, 1);

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        RD2_ScheduleService service = getScheduleServiceForCurrentDate(startDate);

        npe03__Recurring_Donation__c rd = getRecurringDonationMonthlyBuilder()
            .withStartDate(startDate)
            .build();

        Test.startTest();
        insert rd;
        Test.stopTest();

        List<RD2_ScheduleService.Installment> installments = service.getVisualizedInstallments(
            new List<npe03__Recurring_Donation__c>{ rd }, startDate, numberOfInstallments, null
        ).values()[0];

        System.assertEquals(0, installments.size(), 'There should be 0 installments.');
    }

    /***
    * @description Verifies visualization behaves as expected with 1st and 15th schedule
    */
    @isTest
    private static void shouldReturnTwelveInstallmentsWhenFirstAndFifteenthRequested() {
        final Integer numberOfInstallments = 12;
        final Date startDate = Date.newInstance(2019, 11, 1);
        Date nextDonationDate = Date.newInstance(2020, 4, 15);

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        RD2_ScheduleService service = getScheduleServiceForCurrentDate(startDate);

        npe03__Recurring_Donation__c rd = getRecurringDonationFirstAndFifteenthBuilder()
            .withStartDate(startDate)
            .build();

        Test.startTest();
        insert rd;
        Test.stopTest();

        List<RD2_ScheduleService.Installment> installments = service.getVisualizedInstallments(
            new List<npe03__Recurring_Donation__c>{ rd }, startDate, numberOfInstallments, null
        ).values()[0];

        System.assertEquals(numberOfInstallments, installments.size(), 'Number of Installments should match');
        System.assertEquals(nextDonationDate, installments[numberOfInstallments - 1].nextDonationDate, 
            'Final installment date should be 4/15/2020.');
    }

    /****
    * @description Validates that 1 active schedule is returned for a new RD
    */
    @IsTest
    private static void shouldReturnOneActiveSchedulesForNewRD() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        RD2_ScheduleService service = new RD2_ScheduleService();

        npe03__Recurring_Donation__c rd = getRecurringDonationMonthlyBuilder().build();

        Test.startTest();
        insert rd;
        Test.stopTest();

        List<RD2_ScheduleService.ActiveSchedule> schedules = service.getVisualizedSchedules(rd);
        System.assertEquals(1, schedules.size(), 'There should be 1 schedule.');
    }

    /****
    * @description Validates that 2 active schedule are returned for an RD with current and future schedules
    */
    @IsTest
    private static void shouldReturnActiveSchedulesWhenRDHasCurrentAndFutureSchedule() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        RD2_ScheduleService service = new RD2_ScheduleService();

        npe03__Recurring_Donation__c rd = getRecurringDonationMonthlyBuilder().build();

        Test.startTest();
        insert rd;
        rd.StartDate__c = Date.today().addMonths(2);
        rd.npe03__Amount__c = 100;
        update rd;
        Test.stopTest();

        List<RD2_ScheduleService.ActiveSchedule> schedules = service.getVisualizedSchedules(rd);
        System.assertEquals(2, schedules.size(), 'There should be 2 schedules.');
    }

    /****
    * @description Validates that zero active schedules are returned for a closed RD
    */
    @IsTest
    private static void shouldReturnZeroActiveSchedulesForClosedRD() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        RD2_ScheduleService service = new RD2_ScheduleService();

        npe03__Recurring_Donation__c rd = getRecurringDonationMonthlyBuilder()
            .withStatusClosed()
            .build();

        Test.startTest();
        insert rd;
        Test.stopTest();

        List<RD2_ScheduleService.ActiveSchedule> schedules = service.getVisualizedSchedules(rd);
        System.assertEquals(0, schedules.size(), 'There should be zero schedules.');
    }

    /****
    * @description Validates the RD past Effective Date is unchanged when Amount is changed
    * and schedule is marked for update.
    */
    @IsTest
    private static void shouldMarkRDForScheduleUpdateWhenStartDateIsInPast() {
        Date startDate = Date.newInstance(2019, 11, 1);
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        List<npe03__Recurring_Donation__c> oldRds = new List<npe03__Recurring_Donation__c>{
                getRecurringDonationMonthlyBuilder()
                        .withStartDate(startDate)
                        .withMockId()
                        .build()
        };

        Decimal newAmount = 250;
        List<npe03__Recurring_Donation__c> updatedRds = new List<npe03__Recurring_Donation__c>{
                oldRds[0].clone(true)
        };
        updatedRds[0].npe03__Amount__c = newAmount;

        RD2_ScheduleService service = new RD2_ScheduleService();
        Map<Id, npe03__Recurring_Donation__c> rdsNeedUpdate = service.getRecurringDonationsNeedingScheduleUpdates(
                updatedRds, oldRds, TDTM_Runnable.Action.BeforeUpdate
        );

        System.assertEquals(1, rdsNeedUpdate.size(), 'Recurring Donation should be marked for update');
        System.assertEquals(newAmount, rdsNeedUpdate.get(updatedRds[0].Id).npe03__Amount__c, 'Updated amount should match');
        System.assertEquals(startDate, rdsNeedUpdate.get(updatedRds[0].Id).StartDate__c, 'RD Effective Date should be unchanged');
    }

    /****
    * @description Validates start date on RD with unmodified future start date
    */
    @IsTest
    private static void shouldApplyRDChangesIfFutureStartDateUnchanged() {
        Date startDate = Date.today().addYears(12);
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        List<npe03__Recurring_Donation__c> oldRds = new List<npe03__Recurring_Donation__c>{
                getRecurringDonationMonthlyBuilder()
                        .withStartDate(startDate)
                        .withMockId()
                        .build()
        };

        Decimal newAmount = 250;
        List<npe03__Recurring_Donation__c> updatedRds = new List<npe03__Recurring_Donation__c>{
                oldRds[0].clone(true)
        };
        updatedRds[0].npe03__Amount__c = newAmount;

        RD2_ScheduleService service = new RD2_ScheduleService();
        Map<Id, npe03__Recurring_Donation__c> rdsNeedUpdate = service.getRecurringDonationsNeedingScheduleUpdates(
                updatedRds, oldRds, TDTM_Runnable.Action.BeforeUpdate
        );

        System.assertEquals(1, rdsNeedUpdate.size(), 'Recurring Donation should be marked for update');
        System.assertEquals(250, rdsNeedUpdate.get(updatedRds[0].Id).npe03__Amount__c, 'Updated amount should match');
        System.assertEquals(startDate, rdsNeedUpdate.get(updatedRds[0].Id).StartDate__c, 'Start date should be 12 years from today\'s date');
    }


    //// Helpers

    /****
    * @description Returns Recurring Donation with Yearly Installment Period
    */
    private static TEST_RecurringDonationBuilder getRecurringDonationYearlyBuilder() {
        return getRecurringDonationBaseBuilder()
            .withInstallmentPeriodYearly();
    }

    /****
    * @description Returns Recurring Donation with Monthly Installment Period
    */
    private static TEST_RecurringDonationBuilder getRecurringDonationMonthlyBuilder() {
        return getRecurringDonationBaseBuilder()
            .withInstallmentPeriodMonthly()
            .withDayOfMonth('1');
    }

    /****
    * @description Returns Recurring Donation with Weekly Installment Period
    */
    private static TEST_RecurringDonationBuilder getRecurringDonationWeeklyBuilder() {
        return getRecurringDonationBaseBuilder()
            .withInstallmentPeriodWeekly();
    }

    /****
    * @description Returns Recurring Donation with Daily Installment Period
    */
    private static TEST_RecurringDonationBuilder getRecurringDonationDailyBuilder() {
        return getRecurringDonationBaseBuilder()
            .withInstallmentPeriod(RD2_Constants.INSTALLMENT_PERIOD_DAILY);
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
    * @description Returns Schedule Service with current date override
    */
    private static RD2_ScheduleService getScheduleServiceForCurrentDate(Date currentDate) {
        RD2_ScheduleService.currentDate = currentDate;

        return new RD2_ScheduleService();
    }

    /****
    * @description Returns contact record
    */
    private static Contact getContact() {
        return [
            SELECT FirstName, LastName, AccountId, Account.Name
            FROM Contact
            LIMIT 1
        ];
    }
}