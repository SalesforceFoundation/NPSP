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

    private static final Date DATE_ESTABLISHED = Date.newInstance(2019, 9, 15);

    /****
    * @description Creates data required for unit tests
    */
    @TestSetup
    private static void setUp() {
        Contact contact = UTIL_UnitTestData_TEST.getContact();
        insert contact;
    }

    /***
    * @description Verifies details of monthly schedule creation
    */
    @isTest
    private static void shouldCreateMonthlySchedule() {
        npe03__Recurring_Donation__c rd = getRecurringDonationMonthlyBuilder()
                .withStartDate(DATE_ESTABLISHED)
                .withPaymentMethod('Check')
                .withDayOfMonth('20')
                .build();

        List<RecurringDonationSchedule__c> schedules = new RD2_ScheduleService().getNewSchedules(rd);

        System.assertEquals(1, schedules.size(), 'Number of RDs should be 1');
        System.assertEquals(100, schedules[0].InstallmentAmount__c, 'Installment Amount should be 100');
        System.assertEquals(1, schedules[0].InstallmentFrequency__c, 'Installment Frequency should be 1');
        System.assertEquals(RD2_Constants.INSTALLMENT_PERIOD_MONTHLY, schedules[0].InstallmentPeriod__c, 'Installment Period should be Monthly');
        System.assertEquals('Check', schedules[0].PaymentMethod__c, 'Payment Method should be check');
        System.assertEquals(DATE_ESTABLISHED, schedules[0].StartDate__c, 'Start Date should be 9/15/2019');
        System.assertEquals('20', schedules[0].DayOfMonth__c, 'Day of Month should be 20');
        System.assertEquals(null, schedules[0].EndDate__c, 'End Date should be null');
    }

    /***
    * @description Verifies details of 1st and 15th schedule creation
    */
    @isTest
    private static void shouldCreateFirstandFifteenthSchedule() {
        Date startDate = Date.newInstance(2019, 10, 1);
        npe03__Recurring_Donation__c rd = getRecurringDonationFirstAndFifteenthBuilder()
                .withStartDate(startDate)
                .withPaymentMethod('ACH/EFT')
                .withAmount(200)
                .withInstallmentFrequency(2)
                .build();

        List<RecurringDonationSchedule__c> schedules = new RD2_ScheduleService().getNewSchedules(rd);

        System.assertEquals(2, schedules.size(), 'Number of RDs should be 2');
        System.assertEquals(200, schedules[0].InstallmentAmount__c, 'Installment Amount should be 200');
        System.assertEquals(2, schedules[0].InstallmentFrequency__c, 'Installment Frequency should be 2');
        System.assertEquals(RD2_Constants.INSTALLMENT_PERIOD_FIRST_AND_FIFTEENTH, schedules[0].InstallmentPeriod__c, 'Installment Period should be 1st and 15th');
        System.assertEquals('ACH/EFT', schedules[0].PaymentMethod__c, 'Payment Method should be ACH/EFT');
        System.assertEquals(startDate, schedules[0].StartDate__c, 'Start Date should be 10/1/2019');
        System.assertEquals('1', schedules[0].DayOfMonth__c, 'Day of Month should be 1');
        System.assertEquals('15', schedules[1].DayOfMonth__c, 'Day of Month should be 15');
        System.assertEquals(null, schedules[0].EndDate__c, 'End Date should be null');
    }

    /***
    * @description Verifies details of yearly schedule creation
    */
    @isTest
    private static void shouldCreateYearlySchedule() {
        Date startDate = Date.newInstance(2020, 3, 4);
        npe03__Recurring_Donation__c rd = getRecurringDonationYearlyBuilder()
                .withStartDate(startDate)
                .withAmount(300)
                .withInstallmentFrequency(3)
                .build();

        List<RecurringDonationSchedule__c> schedules = new RD2_ScheduleService().getNewSchedules(rd);

        System.assertEquals(1, schedules.size(), 'Number of RDs should be 1');
        System.assertEquals(300, schedules[0].InstallmentAmount__c, 'Installment Amount should be 300');
        System.assertEquals(3, schedules[0].InstallmentFrequency__c, 'Installment Frequency should be 3');
        System.assertEquals(RD2_Constants.INSTALLMENT_PERIOD_YEARLY, schedules[0].InstallmentPeriod__c, 'Installment Period should be Yearly');
        System.assertEquals('Credit Card', schedules[0].PaymentMethod__c, 'Payment Method should be credit card');
        System.assertEquals(startDate, schedules[0].StartDate__c, 'Start Date should be 3/4/2020');
        System.assertEquals(null, schedules[0].DayOfMonth__c, 'Day of Month should be null');
        System.assertEquals(null, schedules[0].EndDate__c, 'End Date should be null');
    }

    /***
    * @description Verifies details of weekly schedule creation
    */
    @isTest
    private static void shouldCreateWeeklySchedule() {
        Date startDate = Date.newInstance(2019, 11, 1);
        npe03__Recurring_Donation__c rd = getRecurringDonationWeeklyBuilder()
                .withStartDate(startDate)
                .withAmount(400)
                .withPaymentMethod('Check')
                .withInstallmentFrequency(13)
                .build();

        List<RecurringDonationSchedule__c> schedules = new RD2_ScheduleService().getNewSchedules(rd);

        System.assertEquals(1,schedules.size(),  'Number of RDs should be 1');
        System.assertEquals(400, schedules[0].InstallmentAmount__c, 'Installment Amount should be 400');
        System.assertEquals(13, schedules[0].InstallmentFrequency__c, 'Installment Frequency should be 13');
        System.assertEquals(RD2_Constants.INSTALLMENT_PERIOD_WEEKLY, schedules[0].InstallmentPeriod__c, 'Installment Period should be Weekly');
        System.assertEquals('Check', schedules[0].PaymentMethod__c, 'Payment Method should be check');
        System.assertEquals(startDate, schedules[0].StartDate__c, 'Start Date should be 11/1/2019');
        System.assertEquals(null, schedules[0].DayOfMonth__c, 'Day of Month should be null');
        System.assertEquals(null, schedules[0].EndDate__c, 'End Date should be null');
    }

    /***
    * @description Verifies schedule is not created when RD is closed.
    */
    @isTest
    private static void shouldNotCreateAScheduleWhenClosed() {
        npe03__Recurring_Donation__c rd = getRecurringDonationMonthlyBuilder()
                .withStatusClosed()
                .build();

        List<RecurringDonationSchedule__c> schedules = new RD2_ScheduleService().getNewSchedules(rd);

        System.assertEquals(0, schedules.size(), 'Number of schedule records should match');
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
    private static void shouldNotCalculateNextDonationDateForClosedRecurringDonation() {
        Date serviceDate = Date.newInstance(2019, 11, 24);
        npe03__Recurring_Donation__c rd = getRecurringDonationMonthlyBuilder()
                .withStatusClosed()
                .build();

        RD2_ScheduleService service = getScheduleServiceForCurrentDate(serviceDate);

        System.assertEquals(null, service.getNextDonationDate(rd), 'Next Donation Date should be null');
    }

    /***
    * @description Verifies next donation date for monthly donation when donation falls in next month.
    */
    @isTest
    private static void shouldCreateNextDonationDateInNextMonth() {
        Date startDate = Date.newInstance(2019, 11, 24);
        Date nextDonationDate = Date.newInstance(2019, 12, 23);
        npe03__Recurring_Donation__c rd = getRecurringDonationMonthlyBuilder()
                .withStartDate(startDate)
                .withDayOfMonth('23')
                .build();

        RD2_ScheduleService service = getScheduleServiceForCurrentDate(startDate);

        System.assertEquals(nextDonationDate, service.getNextDonationDate(rd), 'Next Donation Date should equal 12/23/2019');
    }

    /***
    * @description Verifies next donation date for monthly donation when donation falls in next month.
    */
    @isTest
    private static void shouldCreateNextDonationDateLastDayInFebruary() {
        Date startDate = Date.newInstance(2019, 11, 30);
        Date serviceDate = Date.newInstance(2020, 2, 10);
        Date nextDonationDate = Date.newInstance(2020, 2, 29);
        npe03__Recurring_Donation__c rd = getRecurringDonationMonthlyBuilder()
                .withStartDate(startDate)
                .withDayOfMonth(RD2_Constants.DAY_OF_MONTH_LAST_DAY)
                .build();

        RD2_ScheduleService service = getScheduleServiceForCurrentDate(serviceDate);

        System.assertEquals(nextDonationDate, service.getNextDonationDate(rd), 'Next Donation Date should equal 2/29/2020');
    }

    /***
    * @description Verifies next donation date for monthly donation when donation falls in next month.
    */
    @isTest
    private static void shouldCreateNextDonationDateLastDayInMarch() {
        Date startDate = Date.newInstance(2015, 11, 30);
        Date serviceDate = Date.newInstance(2019, 3, 1);
        Date nextDonationDate = Date.newInstance(2019, 3, 31);
        npe03__Recurring_Donation__c rd = getRecurringDonationMonthlyBuilder()
                .withStartDate(startDate)
                .withDayOfMonth(RD2_Constants.DAY_OF_MONTH_LAST_DAY)
                .build();

        RD2_ScheduleService service = getScheduleServiceForCurrentDate(serviceDate);

        System.assertEquals(nextDonationDate, service.getNextDonationDate(rd), 'Next Donation Date should equal 3/31/2019');
    }

    /***
    * @description Verifies next donation date for monthly donation when donation falls in current month.
    */
    @isTest
    private static void shouldCreateNextDonationDateInCurrentMonth() {
        Date startDate = Date.newInstance(2019, 11, 1);
        Date nextDonationDate = Date.newInstance(2019, 11, 23);
        npe03__Recurring_Donation__c rd = getRecurringDonationMonthlyBuilder()
                .withStartDate(startDate)
                .withDayOfMonth('23')
                .build();

        RD2_ScheduleService service = getScheduleServiceForCurrentDate(startDate);

        System.assertEquals(nextDonationDate, service.getNextDonationDate(rd), 'Next Donation Date should equal 11/23/2019');
    }

    /***
    * @description Verifies next donation date for 1st and 15th donation when donation schedules.
    */
    @isTest
    private static void shouldCreateNextDonationDateFromEarliest() {
        Date startDate = Date.newInstance(2019, 11, 14);
        Date nextDonationDate = Date.newInstance(2019, 11, 15);
        npe03__Recurring_Donation__c rd = getRecurringDonationFirstAndFifteenthBuilder()
                .withStartDate(startDate)
                .build();

        RD2_ScheduleService service = getScheduleServiceForCurrentDate(startDate);

        System.assertEquals(nextDonationDate, service.getNextDonationDate(rd), 'Next Donation Date should equal 11/15/2019');
    }

    /***
    * @description Verifies next donation date for monthly donation for yearly donation.
    */
    @isTest
    private static void shouldCreateNextDonationDateFromYearlyStartDate() {
        Date startDate = Date.newInstance(2020, 11, 1);
        npe03__Recurring_Donation__c rd = getRecurringDonationYearlyBuilder()
                .withStartDate(startDate)
                .build();

        RD2_ScheduleService service = getScheduleServiceForCurrentDate(startDate);

        System.assertEquals(startDate, service.getNextDonationDate(rd), 'Next Donation Date should equal 11/1/2020');
    }

    /***
    * @description Verifies next donation date for weekly donation.
    */
    @isTest
    private static void shouldCreateNextDonationDateFromWeeklyStartDate() {
        Date startDate = Date.newInstance(2018, 3, 17);
        npe03__Recurring_Donation__c rd = getRecurringDonationWeeklyBuilder()
                .withStartDate(startDate)
                .build();

        RD2_ScheduleService service = getScheduleServiceForCurrentDate(startDate);

        System.assertEquals(startDate, service.getNextDonationDate(rd), 'Next Donation Date should equal 3/17/2018');
    }

    /***
    * @description Verifies next donation date for daily donation with frequency > 1.
    */
    @isTest
    private static void shouldCreateNextDonationDateWithFrequencyFifteenDays() {
        Date startDate = Date.newInstance(2018, 7, 1);
        Date serviceDate = Date.newInstance(2018, 7, 17);
        Date nextDonationDate = Date.newInstance(2018, 7, 31);
        npe03__Recurring_Donation__c rd = getRecurringDonationDailyBuilder()
                .withStartDate(startDate)
                .withInstallmentFrequency(15)
                .build();

        RD2_ScheduleService service = getScheduleServiceForCurrentDate(serviceDate);

        System.assertEquals(nextDonationDate, service.getNextDonationDate(rd), 'Next Donation Date should equal 7/31/2018');
    }

    /***
    * @description Verifies next donation date for weekly donation with frequency > 1.
    */
    @isTest
    private static void shouldCreateNextDonationDateWithFrequencyThreeWeeks() {
        Date startDate = Date.newInstance(2018, 3, 17);
        Date serviceDate = Date.newInstance(2018, 4, 8);
        Date nextDonationDate = Date.newInstance(2018, 4, 28);
        npe03__Recurring_Donation__c rd = getRecurringDonationWeeklyBuilder()
                .withStartDate(startDate)
                .withInstallmentFrequency(3)
                .build();

        RD2_ScheduleService service = getScheduleServiceForCurrentDate(serviceDate);

        System.assertEquals(nextDonationDate, service.getNextDonationDate(rd), 'Next Donation Date should equal 4/28/2018');
    }

    /***
    * @description Verifies next donation date for monthly donation with frequency > 1.
    */
    @isTest
    private static void shouldCreateNextDonationDateWithFrequencyElevenMonths() {
        Date startDate = Date.newInstance(2018, 3, 17);
        Date serviceDate = Date.newInstance(2023, 1, 18);
        Date nextDonationDate = Date.newInstance(2023, 9, 17);
        npe03__Recurring_Donation__c rd = getRecurringDonationMonthlyBuilder()
                .withStartDate(startDate)
                .withInstallmentFrequency(11)
                .withDayOfMonth('17')
                .build();

        RD2_ScheduleService service = getScheduleServiceForCurrentDate(serviceDate);

        System.assertEquals(nextDonationDate, service.getNextDonationDate(rd), 'Next Donation Date should equal 1/17/2020');
    }

    /***
    * @description Verifies next donation date for yearly donation with frequency > 1.
    */
    @isTest
    private static void shouldCreateNextDonationDateWithFrequencyFiveYears() {
        Date startDate = Date.newInstance(2018, 3, 17);
        Date serviceDate = Date.newInstance(2023, 3, 18);
        Date nextDonationDate = Date.newInstance(2028, 3, 17);
        npe03__Recurring_Donation__c rd = getRecurringDonationYearlyBuilder()
                .withStartDate(startDate)
                .withInstallmentFrequency(5)
                .build();

        RD2_ScheduleService service = getScheduleServiceForCurrentDate(serviceDate);

        System.assertEquals(nextDonationDate, service.getNextDonationDate(rd), 'Next Donation Date should equal 3/17/2028');
    }

    /***
    * @description Verifies next donation date for 1st and 15th donation with frequency > 1.
    */
    @isTest
    private static void shouldCreateNextDonationDateWithFrequencyFiveFirstAndFifteenth() {
        Date startDate = Date.newInstance(2018, 3, 17);
        Date serviceDate = Date.newInstance(2018, 9, 16);
        Date nextDonationDate = Date.newInstance(2019, 2, 1);
        npe03__Recurring_Donation__c rd = getRecurringDonationFirstAndFifteenthBuilder()
                .withStartDate(startDate)
                .withInstallmentFrequency(5)
                .build();

        RD2_ScheduleService service = getScheduleServiceForCurrentDate(serviceDate);

        System.assertEquals(nextDonationDate, service.getNextDonationDate(rd), 'Next Donation Date should equal 2/1/2019');
    }

    /***
    * @description Verifies update is needed when status on recurring donation is changed.
    */
    @isTest
    private static void shouldDetermineUpdateNeededWhenStatusChanged() {
        npe03__Recurring_Donation__c rd = getRecurringDonationWeeklyBuilder()
                .withStatusClosed().
                build();

        npe03__Recurring_Donation__c changedRd = rd.clone();
        changedRd.Status__c = RD2_Constants.STATUS_ACTIVE;

        RD2_ScheduleService schedule = new RD2_ScheduleService();
        Boolean updateNeeded = schedule.isScheduleUpdateNeeded(changedRd, rd);

        System.assertEquals(true, updateNeeded, 'isScheduleUpdateNeeded should return true.');
    }

    /***
    * @description Verifies update is needed when status on recurring donation is changed.
    */
    @isTest
    private static void shouldDetermineUpdateNotNeededWhenStatusChanged() {
        npe03__Recurring_Donation__c rd = getRecurringDonationWeeklyBuilder()
                .withStatusActive()
                .build();

        npe03__Recurring_Donation__c changedRd = rd.clone();
        changedRd.Status__c = RD2_Constants.STATUS_LAPSED;

        RD2_ScheduleService schedule = new RD2_ScheduleService();
        Boolean updateNeeded = schedule.isScheduleUpdateNeeded(changedRd, rd);

        System.assertEquals(false, updateNeeded, 'isScheduleUpdateNeeded should return false.');
    }

    /***
    * @description Verifies update is needed when start date on recurring donation is changed.
    */
    @isTest
    private static void shouldDetermineUpdateNeededWhenStartDateChanged() {
        Date startDate = Date.newInstance(2018, 3, 17);
        npe03__Recurring_Donation__c rd = getRecurringDonationWeeklyBuilder()
                .withStartDate(startDate)
                .build();

        npe03__Recurring_Donation__c changeRd = rd.clone();
        changeRd.StartDate__c = Date.today();

        RD2_ScheduleService schedule = new RD2_ScheduleService();
        Boolean updateNeeded = schedule.isScheduleUpdateNeeded(changeRd, rd);

        System.assertEquals(true, updateNeeded, 'isScheduleUpdateNeeded should return true.');
    }

    /***
    * @description Verifies update is needed when amount on recurring donation is changed.
    */
    @isTest
    private static void shouldDetermineUpdateNeededWhenAmountChanged() {
        npe03__Recurring_Donation__c rd = getRecurringDonationWeeklyBuilder().build();

        npe03__Recurring_Donation__c changeRd = rd.clone();
        changeRd.npe03__Amount__c = 200;

        RD2_ScheduleService schedule = new RD2_ScheduleService();
        Boolean updateNeeded = schedule.isScheduleUpdateNeeded(changeRd, rd);

        System.assertEquals(true, updateNeeded, 'isScheduleUpdateNeeded should return true.');
    }

    /***
    * @description Verifies update is needed when installment period on recurring donation is changed.
    */
    @isTest
    private static void shouldDetermineUpdateNeededWhenPeriodChanged() {
        npe03__Recurring_Donation__c rd = getRecurringDonationFirstAndFifteenthBuilder().build();

        npe03__Recurring_Donation__c changeRd = rd.clone();
        changeRd.npe03__Installment_Period__c = RD2_Constants.INSTALLMENT_PERIOD_DAILY;

        RD2_ScheduleService schedule = new RD2_ScheduleService();
        Boolean updateNeeded = schedule.isScheduleUpdateNeeded(changeRd, rd);

        System.assertEquals(true, updateNeeded, 'isScheduleUpdateNeeded should return true.');
    }

    /***
    * @description Verifies update is needed when day of month on recurring donation is changed.
    */
    @isTest
    private static void shouldDetermineUpdateNeededWhenDayOfMonthChanged() {
        npe03__Recurring_Donation__c rd = getRecurringDonationMonthlyBuilder().build();

        npe03__Recurring_Donation__c changeRd = rd.clone();
        changeRd.Day_of_Month__c = '23';

        RD2_ScheduleService schedule = new RD2_ScheduleService();
        Boolean updateNeeded = schedule.isScheduleUpdateNeeded(changeRd, rd);

        System.assertEquals(true, updateNeeded, 'isScheduleUpdateNeeded should return true.');
    }

    /***
    * @description Verifies update is needed when installment frequency on recurring donation is changed.
    */
    @isTest
    private static void shouldDetermineUpdateNeededWhenFrequencyChanged() {
        npe03__Recurring_Donation__c rd = getRecurringDonationWeeklyBuilder().build();

        npe03__Recurring_Donation__c changeRd = rd.clone();
        changeRd.InstallmentFrequency__c = 5;

        RD2_ScheduleService schedule = new RD2_ScheduleService();
        Boolean updateNeeded = schedule.isScheduleUpdateNeeded(changeRd, rd);

        System.assertEquals(true, updateNeeded, 'isScheduleUpdateNeeded should return true.');
    }

    /***
    * @description Verifies update is needed when payment method on recurring donation is changed.
    */
    @isTest
    private static void shouldDetermineUpdateNeededWhenPaymentMethodChanged() {
        npe03__Recurring_Donation__c rd = getRecurringDonationMonthlyBuilder().build();

        npe03__Recurring_Donation__c changeRd = rd.clone();
        changeRd.PaymentMethod__c = 'ACH/EFT';

        RD2_ScheduleService schedule = new RD2_ScheduleService();
        Boolean updateNeeded = schedule.isScheduleUpdateNeeded(changeRd, rd);

        System.assertEquals(true, updateNeeded, 'isScheduleUpdateNeeded should return true.');
    }

    /***
    * @description Verifies update is needed when campaign on recurring donation is changed.
    */
    @isTest
    private static void shouldDetermineUpdateNeededWhenCampaignChanged() {
        npe03__Recurring_Donation__c rd = getRecurringDonationMonthlyBuilder().build();

        npe03__Recurring_Donation__c changeRd = rd.clone();
        changeRd.npe03__Recurring_Donation_Campaign__c = UTIL_UnitTestData_TEST.mockId(Campaign.getSObjectType());

        RD2_ScheduleService schedule = new RD2_ScheduleService();
        Boolean updateNeeded = schedule.isScheduleUpdateNeeded(changeRd, rd);

        System.assertEquals(true, updateNeeded, 'isScheduleUpdateNeeded should return true.');
    }

    /***
    * @description Verifies update is NOT needed when contact on recurring donation is changed.
    */
    @isTest
    private static void shouldDetermineNoUpdateNeededWhenContactChanged() {
        npe03__Recurring_Donation__c rd = getRecurringDonationMonthlyBuilder().build();

        npe03__Recurring_Donation__c changeRd = rd.clone();
        changeRd.npe03__Contact__c = UTIL_UnitTestData_TEST.mockId(Contact.getSObjectType());

        RD2_ScheduleService schedule = new RD2_ScheduleService();
        Boolean updateNeeded = schedule.isScheduleUpdateNeeded(changeRd, rd);

        System.assertEquals(false, updateNeeded, 'isScheduleUpdateNeeded should return false.');
    }

    /***
    * @description Verifies updated schedule is created when day of month is changed.
    */
    @isTest
    private static void shouldCreateNewMonthlySchedule() {
        Date startDate = Date.newInstance(2018, 3, 17);
        Date endDate = Date.newInstance(2018,3,16);
        npe03__Recurring_Donation__c rd = getRecurringDonationMonthlyBuilder()
                .withStartDate(startDate)
                .withDayOfMonth('23')
                .build();

        RD2_ScheduleService service = new RD2_ScheduleService();
        List<RecurringDonationSchedule__c> schedules = service.getNewSchedules(rd);
        rd.Day_of_Month__c = '21';

        TDTM_Runnable.DMLWrapper changes = service.getUpdatedSchedules(rd, schedules);
        System.assertEquals(endDate, changes.objectsToUpdate[0].get('EndDate__c'), 'End Date should be set to 3/16/2018.');
        System.assertEquals('21', changes.objectsToInsert[0].get('DayOfMonth__c'), 'Day of month should be set to 21.');
    }

    /***
    * @description Verifies schedule is ended when RD is closed.
    */
    @isTest
    private static void shouldInactivateCurrentSchedule() {
        npe03__Recurring_Donation__c rd = getRecurringDonationMonthlyBuilder().build();

        RD2_ScheduleService service = new RD2_ScheduleService();
        List<RecurringDonationSchedule__c> schedules = service.getNewSchedules(rd);
        rd.Status__c = RD2_Constants.STATUS_CLOSED;

        TDTM_Runnable.DMLWrapper changes = service.getUpdatedSchedules(rd, schedules);
        System.assertEquals(Date.today().addDays(-1), changes.objectsToUpdate[0].get('EndDate__c'), 'End Date should be set to yesterday.');
        System.assertEquals(0, changes.objectsToInsert.size(), 'There should be no objects to insert.');
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
        rd.npe03__Installment_Period__c = RD2_Constants.INSTALLMENT_PERIOD_WEEKLY;

        TDTM_Runnable.DMLWrapper changes = service.getUpdatedSchedules(rd, schedules);
        System.assertEquals(endDate, changes.objectsToUpdate[0].get('EndDate__c'), 'End Date should be set to 3/16/2018.');
        System.assertEquals(endDate, changes.objectsToUpdate[1].get('EndDate__c'), 'End Date should be set to 3/16/2018.');
        System.assertEquals(RD2_Constants.INSTALLMENT_PERIOD_WEEKLY, changes.objectsToInsert[0].get('InstallmentPeriod__c'), 'Installment period should be set to weekly.');
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
        System.assertEquals(startDate, schedules[0].StartDate__c, 'Start date on new schedule should be 3/17/2018.');
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
        Date nextDonation = service.getNextDonationDate(rd);

        System.assertEquals(Date.today(), nextDonation, 'Next donation date should equal today.');
    }

    /***
    * @description Verifies visualization works with a large number of installments requested
    */
    @isTest
    private static void shouldReturn480InstallmentsWhen480Requested() {
        Date startDate = Date.newInstance(2019, 11, 1);
        Date nextDonationDate = Date.newInstance(2059, 10, 1);
        npe03__Recurring_Donation__c rd = getRecurringDonationMonthlyBuilder()
                .withStartDate(startDate)
                .build();

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        RD2_ScheduleService service = getScheduleServiceForCurrentDate(startDate);

        Test.startTest();
        insert rd;
        List<RD2_ScheduleService.Installment> installments = service.getVisualizedInstallments(rd, startDate, 480, null);
        Test.stopTest();

        System.assertEquals(480, installments.size(), 'There should be 480 installments.');
        System.assertEquals(nextDonationDate, installments[479].nextDonationDate, 'Final installment date should be 10/1/2059.');
    }

    /***
    * @description Verifies visualization does not fail when zero installments are requested
    */
    @isTest
    private static void shouldReturnZeroInstallmentsWhenZeroRequested() {
        Date startDate = Date.newInstance(2019, 11, 1);
        npe03__Recurring_Donation__c rd = getRecurringDonationMonthlyBuilder()
                .withStartDate(startDate)
                .build();

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        RD2_ScheduleService service = getScheduleServiceForCurrentDate(startDate);

        Test.startTest();
        insert rd;
        List<RD2_ScheduleService.Installment> installments = service.getVisualizedInstallments(rd, startDate, 0, null);
        Test.stopTest();

        System.assertEquals(0, installments.size(), 'There should be 0 installments.');
    }

    /***
    * @description Verifies visualization does not fail when zero installments are requested
    */
    @isTest
    private static void shouldReturnZeroInstallmentsWhenStatusClosed() {
        Date startDate = Date.newInstance(2019, 11, 1);
        npe03__Recurring_Donation__c rd = getRecurringDonationMonthlyBuilder()
                .withStartDate(startDate)
                .withStatusClosed()
                .build();

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        RD2_ScheduleService service = getScheduleServiceForCurrentDate(startDate);

        Test.startTest();
        insert rd;
        List<RD2_ScheduleService.Installment> installments = service.getVisualizedInstallments(rd, startDate, 12, null);
        Test.stopTest();

        System.assertEquals(0, installments.size(), 'There should be 0 installments.');
    }

    /***
    * @description Verifies visualization does not fail when null RD Id is used
    */
    @isTest
    private static void shouldReturnZeroInstallmentsWhenRDIdIsNull() {
        Date startDate = Date.newInstance(2019, 11, 1);

        RD2_ScheduleService service = getScheduleServiceForCurrentDate(startDate);

        Map<Id, List<RD2_ScheduleService.Installment>> installmentsByRDIds = service.getVisualizedInstallments(new List<npe03__Recurring_Donation__c>{null}, startDate, 12, null);

        System.assertEquals(0, installmentsByRDIds.size(), 'Map of RDIds to installments should be empty.');
    }

    /***
    * @description Verifies visualization substitutes default when null start date is used
    */
    @isTest
    private static void shouldReturnRequestedInstallmentsWhenStartDateIsNull() {
        Date startDate = Date.newInstance(2019, 11, 1);
        Date nextDonationDate = Date.newInstance(2020, 10, 1);
        npe03__Recurring_Donation__c rd = getRecurringDonationMonthlyBuilder().build();

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        RD2_ScheduleService service = getScheduleServiceForCurrentDate(startDate);

        Test.startTest();
        insert rd;
        List<RD2_ScheduleService.Installment> installments = service.getVisualizedInstallments(rd, null, 12, null);
        Test.stopTest();

        System.assertEquals(12, installments.size(), 'There should be 12 installments.');
        System.assertEquals(nextDonationDate, installments[11].nextDonationDate, 'Final installment date should be 10/1/2020.');
    }

    /***
    * @description Verifies visualization substitutes default when null maxDates are requested
    */
    @isTest
    private static void shouldReturnTwelveInstallmentsWhenNumberRequestedIsNull() {
        Date startDate = Date.newInstance(2019, 11, 1);
        Date nextDonationDate = Date.newInstance(2020, 10, 1);
        npe03__Recurring_Donation__c rd = getRecurringDonationMonthlyBuilder()
                .withStartDate(startDate)
                .build();

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        RD2_ScheduleService service = getScheduleServiceForCurrentDate(startDate);

        Test.startTest();
        insert rd;
        List<RD2_ScheduleService.Installment> installments = service.getVisualizedInstallments(rd, startDate, null, null);
        Test.stopTest();

        System.assertEquals(12, installments.size(), 'There should be 12 installments.');
        System.assertEquals(nextDonationDate, installments[11].nextDonationDate, 'Final installment date should be 10/1/2020.');
    }

    /***
    * @description Verifies visualization substitutes default when null maxDates are requested
    */
    @isTest
    private static void shouldReturnTwelveInstallmentsWhenSchedulesInjected() {
        Date startDate = Date.newInstance(2019, 11, 1);
        Date nextDonationDate = Date.newInstance(2020, 10, 1);
        npe03__Recurring_Donation__c rd = getRecurringDonationMonthlyBuilder().build();

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        RD2_ScheduleService service = getScheduleServiceForCurrentDate(startDate);

        Test.startTest();
        insert rd;
        Test.stopTest();

        List<RecurringDonationSchedule__c> rds = [
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

        List<RD2_ScheduleService.Installment> installments = service.getVisualizedInstallments(rd, startDate, null, rds);
        System.assertEquals(12, installments.size(), 'There should be 12 installments.');
        System.assertEquals(nextDonationDate, installments[11].nextDonationDate, 'Final installment date should be 10/1/2020.');
    }

    /***
    * @description Verifies visualization substitutes default when null maxDates are requested
    */
    @isTest
    private static void shouldReturnTenInstallmentsWhenEndDateIsReached() {
        Date startDate = Date.newInstance(2020, 1, 1);
        Date endDate = Date.newInstance(2020, 10, 31);
        Date serviceDate = Date.newInstance(2020, 1, 1);
        Date nextDonationDate = Date.newInstance(2020, 10, 1);
        npe03__Recurring_Donation__c rd = getRecurringDonationMonthlyBuilder()
                .withStartDate(startDate)
                .build();

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        RD2_ScheduleService service = new RD2_ScheduleService();

        Test.startTest();
        insert rd;
        Test.stopTest();

        List<RecurringDonationSchedule__c> rdSchedules = [SELECT Id, EndDate__c FROM RecurringDonationSchedule__c WHERE RecurringDonation__c = :rd.Id];
        rdSchedules[0].EndDate__c = endDate;
        update rdSchedules;
        List<RD2_ScheduleService.Installment> installments = service.getVisualizedInstallments(rd, serviceDate, 12, null);

        System.assertEquals(10, installments.size(), 'There should be 10 installments.');
        System.assertEquals(nextDonationDate, installments[9].nextDonationDate, 'Final installment date should be 10/1/2020.');
    }

    /***
    * @description Verifies visualization substitutes default when null maxDates are requested
    */
    @isTest
    private static void shouldReturnTwelveInstallmentsEachForThreeRDsWhenNumberRequestedIsNull() {
        Date startDate = Date.newInstance(2019, 11, 1);
        Date nextDonationDate1 = Date.newInstance(2019, 12, 1);
        Date nextDonationDate2 = Date.newInstance(2020, 1, 17);
        Date nextDonationDate3 = Date.newInstance(2020, 1, 15);
        List<npe03__Recurring_Donation__c> rds = new List<npe03__Recurring_Donation__c>();
        rds.add(getRecurringDonationMonthlyBuilder()
                .withStartDate(startDate)
                .withAmount(50)
                .build());
        rds.add(getRecurringDonationWeeklyBuilder()
                .withStartDate(startDate)
                .withAmount(100)
                .build());
        rds.add(getRecurringDonationFirstAndFifteenthBuilder()
                .withStartDate(startDate)
                .withAmount(25)
                .build());

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        RD2_ScheduleService service = new RD2_ScheduleService();

        Test.startTest();
        insert rds;
        Map<Id, List<RD2_ScheduleService.Installment>> installmentsByRDId = service.getVisualizedInstallments(rds, startDate, null, null);
        Test.stopTest();

        System.assertEquals(nextDonationDate1, installmentsByRDId.get(rds[0].Id)[1].nextDonationDate, 'Donation date should be 12/1/2019.');
        System.assertEquals(nextDonationDate2, installmentsByRDId.get(rds[1].Id)[11].nextDonationDate, 'Donation date should be 1/17/2020.');
        System.assertEquals(nextDonationDate3, installmentsByRDId.get(rds[2].Id)[5].nextDonationDate, 'Donation date should be 1/15/2020.');
    }

    /***
    * @description Verifies visualization does not fail when negative max dates requested
    */
    @isTest
    private static void shouldReturnZeroInstallmentsWhenNegativeNumberRequested() {
        Date startDate = Date.newInstance(2019, 11, 1);
        npe03__Recurring_Donation__c rd = getRecurringDonationMonthlyBuilder()
                .withStartDate(startDate)
                .build();

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        RD2_ScheduleService service = getScheduleServiceForCurrentDate(startDate);

        Test.startTest();
        insert rd;
        List<RD2_ScheduleService.Installment> installments = service.getVisualizedInstallments(rd, startDate, -5, null);
        Test.stopTest();

        System.assertEquals(0, installments.size(), 'There should be 0 installments.');
    }

    /***
    * @description Verifies visualization behaves as expected with 1st and 15th schedule
    */
    @isTest
    private static void shouldReturnTwelveInstallmentsWhenFirstAndFifteenthRequested() {
        Date startDate = Date.newInstance(2019, 11, 1);
        Date nextDonationDate = Date.newInstance(2020, 4, 15);
        npe03__Recurring_Donation__c rd = getRecurringDonationFirstAndFifteenthBuilder()
                .withStartDate(startDate)
                .build();

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        RD2_ScheduleService service = getScheduleServiceForCurrentDate(startDate);

        Test.startTest();
        insert rd;
        List<RD2_ScheduleService.Installment> installments = service.getVisualizedInstallments(rd, startDate, 12, null);
        Test.stopTest();

        System.assertEquals(12, installments.size(), 'There should be 12 installments.');
        System.assertEquals(nextDonationDate, installments[11].nextDonationDate, 'Final installment date should be 4/15/2020.');
    }

    /****
    * @description Validates that 1 active schedule is returned for a new RD
    */
    @IsTest
    private static void shouldReturnOneActiveSchedulesForNewRD() {
        npe03__Recurring_Donation__c rd = getRecurringDonationMonthlyBuilder().build();

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        Test.startTest();
        insert rd;
        RD2_ScheduleService service = new RD2_ScheduleService();
        List<RD2_ScheduleService.ActiveSchedule> schedules = service.getVisualizedSchedules(rd);
        Test.stopTest();

        System.assertEquals(1, schedules.size(), 'There should be 1 schedule.');
    }

    /****
    * @description Validates that 2 active schedule are returned for an RD with current and future schedules
    */
    @IsTest
    private static void shouldReturnActiveSchedulesWhenRDHasCurrentAndFutureSchedule() {
        npe03__Recurring_Donation__c rd = getRecurringDonationMonthlyBuilder().build();

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        Test.startTest();
        insert rd;
        rd.StartDate__c = Date.today().addMonths(2);
        rd.npe03__Amount__c = 100;
        update rd;
        RD2_ScheduleService service = new RD2_ScheduleService();
        List<RD2_ScheduleService.ActiveSchedule> schedules = service.getVisualizedSchedules(rd);
        Test.stopTest();

        System.assertEquals(2, schedules.size(), 'There should be 2 schedules.');
    }

    /****
    * @description Validates that zero active schedules are returned for a closed RD
    */
    @IsTest
    private static void shouldReturnZeroActiveSchedulesForClosedRD() {
        npe03__Recurring_Donation__c rd = getRecurringDonationMonthlyBuilder()
                .withStatusClosed()
                .build();

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        Test.startTest();
        insert rd;
        RD2_ScheduleService service = new RD2_ScheduleService();
        List<RD2_ScheduleService.ActiveSchedule> schedules = service.getVisualizedSchedules(rd);
        Test.stopTest();

        System.assertEquals(0, schedules.size(), 'There should be zero schedules.');
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
                .withPaymentMethod('Credit Card')
                .withInstallmentFrequency(1)
                .withDateEstablished(DATE_ESTABLISHED)
                .withStartDate(DATE_ESTABLISHED);
    }

    /****
    * @description Returns Schedule Service with current date override
    */
    private static RD2_ScheduleService getScheduleServiceForCurrentDate(Date currentDate) {
        RD2_ScheduleService scheduleService = new RD2_ScheduleService();
        RD2_ScheduleService.currentDate = currentDate;

        return scheduleService;
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