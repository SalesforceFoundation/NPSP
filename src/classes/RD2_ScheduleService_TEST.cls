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

    /****
    * @description Creates data required for unit tests
    */
    @TestSetup
    private static void setUp() {
        Account acc = new Account(Name = 'RD2 Trigger Handler Account');
        insert acc;

        Contact contact = UTIL_UnitTestData_TEST.getContact();
        contact.AccountId = acc.Id;
        insert contact;
    }

    /***
    * @description Verifies details of monthly schedule creation
    */
    @isTest
    private static void shouldCreateMonthlySchedule() {

        npe03__Recurring_Donation__c rds =
            TEST_RecurringDonationBuilder.constructEnhancedBuilder()
                .withMockId()
                .withContact(UTIL_UnitTestData_TEST.mockId(Contact.SObjectType))
                .withAmount(100)
                .withPaymentMethod('Check')
                .withInstallmentPeriodMonthly()
                .withInstallmentFrequency(1)
                .withDayOfMonth('20')
                .withDateEstablished(Date.newInstance(2019, 9, 15))
                .withStartDate(Date.newInstance(2019, 9, 15))
                .build();

        List<RecurringDonationSchedule__c> schedules = new RD2_ScheduleService().getNewSchedules(rds);

        System.assertEquals(schedules.size(), 1, 'Number of RDs should be 1');
        System.assertEquals(schedules[0].InstallmentAmount__c, 100, 'Installment Amount should be 100');
        System.assertEquals(schedules[0].InstallmentFrequency__c, 1, 'Installment Frequency should be 1');
        System.assertEquals(schedules[0].InstallmentPeriod__c, RD2_Constants.INSTALLMENT_PERIOD_MONTHLY, 'Installment Period should be Monthly');
        System.assertEquals(schedules[0].PaymentMethod__c, 'Check', 'Payment Method should be check');
        System.assertEquals(schedules[0].StartDate__c, Date.newInstance(2019, 9, 15), 'Start Date should be 9/15/2019');
        System.assertEquals(schedules[0].DayOfMonth__c, '20', 'Day of Month should be 20');
        System.assertEquals(schedules[0].EndDate__c, null, 'End Date should be null');

    }

    /***
    * @description Verifies details of 1st and 15th schedule creation
    */
    @isTest
    private static void shouldCreateFirstandFifteenthSchedule() {

        npe03__Recurring_Donation__c rds =
            TEST_RecurringDonationBuilder.constructEnhancedBuilder()
                .withMockId()
                .withContact(UTIL_UnitTestData_TEST.mockId(Contact.SObjectType))
                .withAmount(200)
                .withPaymentMethod('ACH/EFT')
                .withInstallmentPeriod(RD2_Constants.INSTALLMENT_PERIOD_FIRST_AND_FIFTEENTH)
                .withInstallmentFrequency(2)
                .withDateEstablished(Date.newInstance(2019, 9, 15))
                .withStartDate(Date.newInstance(2019, 10, 1))
                .build();

        List<RecurringDonationSchedule__c> schedules = new RD2_ScheduleService().getNewSchedules(rds);

        System.assertEquals(schedules.size(), 2, 'Number of RDs should be 2');
        System.assertEquals(schedules[0].InstallmentAmount__c, 200, 'Installment Amount should be 200');
        System.assertEquals(schedules[0].InstallmentFrequency__c, 2, 'Installment Frequency should be 2');
        System.assertEquals(schedules[0].InstallmentPeriod__c, RD2_Constants.INSTALLMENT_PERIOD_FIRST_AND_FIFTEENTH, 'Installment Period should be 1st and 15th');
        System.assertEquals(schedules[0].PaymentMethod__c, 'ACH/EFT', 'Payment Method should be ACH/EFT');
        System.assertEquals(schedules[0].StartDate__c, Date.newInstance(2019, 10, 1), 'Start Date should be 10/1/2019');
        System.assertEquals(schedules[0].DayOfMonth__c, '1', 'Day of Month should be 1');
        System.assertEquals(schedules[1].DayOfMonth__c, '15', 'Day of Month should be 15');
        System.assertEquals(schedules[0].EndDate__c, null, 'End Date should be null');

    }

    /***
    * @description Verifies details of yearly schedule creation
    */
    @isTest
    private static void shouldCreateYearlySchedule() {

        npe03__Recurring_Donation__c rds =
            TEST_RecurringDonationBuilder.constructEnhancedBuilder()
                .withMockId()
                .withContact(UTIL_UnitTestData_TEST.mockId(Contact.SObjectType))
                .withAmount(300)
                .withPaymentMethod('Credit Card')
                .withInstallmentPeriodYearly()
                .withInstallmentFrequency(3)
                .withDateEstablished(Date.newInstance(2019, 9, 15))
                .withStartDate(Date.newInstance(2020, 3, 4))
                .build();

        List<RecurringDonationSchedule__c> schedules = new RD2_ScheduleService().getNewSchedules(rds);

        System.assertEquals(schedules.size(), 1, 'Number of RDs should be 1');
        System.assertEquals(schedules[0].InstallmentAmount__c, 300, 'Installment Amount should be 300');
        System.assertEquals(schedules[0].InstallmentFrequency__c, 3, 'Installment Frequency should be 3');
        System.assertEquals(schedules[0].InstallmentPeriod__c, RD2_Constants.INSTALLMENT_PERIOD_YEARLY, 'Installment Period should be Yearly');
        System.assertEquals(schedules[0].PaymentMethod__c, 'Credit Card', 'Payment Method should be credit card');
        System.assertEquals(schedules[0].StartDate__c, Date.newInstance(2020, 3, 4), 'Start Date should be 3/4/2020');
        System.assertEquals(schedules[0].DayOfMonth__c, null, 'Day of Month should be null');
        System.assertEquals(schedules[0].EndDate__c, null, 'End Date should be null');

    }

    /***
    * @description Verifies details of weekly schedule creation
    */
    @isTest
    private static void shouldCreateWeeklySchedule() {

        npe03__Recurring_Donation__c rds =
            TEST_RecurringDonationBuilder.constructEnhancedBuilder()
                .withMockId()
                .withContact(UTIL_UnitTestData_TEST.mockId(Contact.SObjectType))
                .withAmount(400)
                .withPaymentMethod('Check')
                .withInstallmentPeriodWeekly()
                .withInstallmentFrequency(13)
                .withDateEstablished(Date.newInstance(2019, 9, 15))
                .withStartDate(Date.newInstance(2019, 11, 1))
                .build();

        List<RecurringDonationSchedule__c> schedules = new RD2_ScheduleService().getNewSchedules(rds);

        System.assertEquals(schedules.size(), 1, 'Number of RDs should be 1');
        System.assertEquals(schedules[0].InstallmentAmount__c, 400, 'Installment Amount should be 400');
        System.assertEquals(schedules[0].InstallmentFrequency__c, 13, 'Installment Frequency should be 13');
        System.assertEquals(schedules[0].InstallmentPeriod__c, RD2_Constants.INSTALLMENT_PERIOD_WEEKLY, 'Installment Period should be Weekly');
        System.assertEquals(schedules[0].PaymentMethod__c, 'Check', 'Payment Method should be check');
        System.assertEquals(schedules[0].StartDate__c, Date.newInstance(2019, 11, 1), 'Start Date should be 11/1/2019');
        System.assertEquals(schedules[0].DayOfMonth__c, null, 'Day of Month should be null');
        System.assertEquals(schedules[0].EndDate__c, null, 'End Date should be null');

    }

    /***
    * @description Verifies schedule is not created when RD is closed.
    */
    @isTest
    private static void shouldNotCreateAScheduleWhenClosed() {

        npe03__Recurring_Donation__c rd =
            TEST_RecurringDonationBuilder.constructEnhancedBuilder()
                .withMockId()
                .withContact(UTIL_UnitTestData_TEST.mockId(Contact.SObjectType))
                .withAmount(400)
                .withPaymentMethod('Check')
                .withInstallmentPeriodWeekly()
                .withInstallmentFrequency(1)
                .withDateEstablished(Date.newInstance(2019, 9, 15))
                .withStartDate(Date.newInstance(2019, 11, 1))
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

        npe03__Recurring_Donation__c rd =
            TEST_RecurringDonationBuilder.constructEnhancedBuilder()
                .withMockId()
                .withContact(UTIL_UnitTestData_TEST.mockId(Contact.SObjectType))
                .withAmount(400)
                .withPaymentMethod('Check')
                .withInstallmentPeriodWeekly()
                .withInstallmentFrequency(1)
                .withDateEstablished(Date.newInstance(2019, 9, 15))
                .withStartDate(Date.newInstance(2019, 9, 15))
                .build();

        List<RecurringDonationSchedule__c> schedules = new RD2_ScheduleService().getNewSchedules(rd);

        schedules.add(schedules[0].clone());
        schedules[1].StartDate__c = Date.today().addMonths(1);
        schedules[1].InstallmentAmount__c = 500;
        schedules[0].EndDate__c = schedules[1].StartDate__c.addDays(-1);

        rd.StartDate__c = Date.today().addMonths(2);
        rd.npe03__Amount__c = 600;

        TDTM_Runnable.DMLWrapper dmlUpdates = new RD2_ScheduleService().getUpdatedSchedules(rd, schedules);

        System.assertEquals(dmlUpdates.objectsToUpdate.size(), 2, 'Number of updated schedules should equal 2');

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

        npe03__Recurring_Donation__c rd =
            TEST_RecurringDonationBuilder.constructEnhancedBuilder()
                .withMockId()
                .withContact(UTIL_UnitTestData_TEST.mockId(Contact.SObjectType))
                .withAmount(400)
                .withPaymentMethod('Check')
                .withInstallmentPeriodMonthly()
                .withDayOfMonth('23')
                .withInstallmentFrequency(1)
                .withDateEstablished(Date.newInstance(2019, 9, 15))
                .withStartDate(Date.newInstance(2019, 11, 24))
                .withStatusClosed()
                .build();

        RD2_ScheduleService service = getScheduleServiceWithCurrentDateOverride(Date.newInstance(2019, 11, 24));

        System.assertEquals(null, service.getNextDonationDate(rd), 'Next Donation Date should be null');

    }

    /***
    * @description Verifies next donation date for monthly donation when donation falls in next month.
    */
    @isTest
    private static void shouldCreateNextDonationDateInNextMonth() {

        npe03__Recurring_Donation__c rd =
            TEST_RecurringDonationBuilder.constructEnhancedBuilder()
                .withMockId()
                .withContact(UTIL_UnitTestData_TEST.mockId(Contact.SObjectType))
                .withAmount(400)
                .withPaymentMethod('Check')
                .withInstallmentPeriodMonthly()
                .withDayOfMonth('23')
                .withInstallmentFrequency(1)
                .withDateEstablished(Date.newInstance(2019, 9, 15))
                .withStartDate(Date.newInstance(2019, 11, 24))
                .build();

        RD2_ScheduleService service = getScheduleServiceWithCurrentDateOverride(Date.newInstance(2019, 11, 24));

        System.assertEquals(Date.newInstance(2019, 12, 23),
            service.getNextDonationDate(rd),
            'Next Donation Date should equal 12/23/2019');

    }

    /***
    * @description Verifies next donation date for monthly donation when donation falls in next month.
    */
    @isTest
    private static void shouldCreateNextDonationDateLastDayInFebruary() {

        npe03__Recurring_Donation__c rd =
                TEST_RecurringDonationBuilder.constructEnhancedBuilder()
                        .withMockId()
                        .withContact(UTIL_UnitTestData_TEST.mockId(Contact.SObjectType))
                        .withAmount(400)
                        .withPaymentMethod('Check')
                        .withInstallmentPeriodMonthly()
                        .withDayOfMonth(RD2_Constants.DAY_OF_MONTH_LAST_DAY)
                        .withInstallmentFrequency(1)
                        .withDateEstablished(Date.newInstance(2019, 9, 15))
                        .withStartDate(Date.newInstance(2019, 11, 30))
                        .build();

        RD2_ScheduleService service = getScheduleServiceWithCurrentDateOverride(Date.newInstance(2020, 2, 1));

        System.assertEquals(Date.newInstance(2020, 2, 29),
                service.getNextDonationDate(rd),
                'Next Donation Date should equal 2/29/2019');

    }

    /***
    * @description Verifies next donation date for monthly donation when donation falls in next month.
    */
    @isTest
    private static void shouldCreateNextDonationDateLastDayInMarch() {

        npe03__Recurring_Donation__c rd =
                TEST_RecurringDonationBuilder.constructEnhancedBuilder()
                        .withMockId()
                        .withContact(UTIL_UnitTestData_TEST.mockId(Contact.SObjectType))
                        .withAmount(400)
                        .withPaymentMethod('Check')
                        .withInstallmentPeriodMonthly()
                        .withDayOfMonth(RD2_Constants.DAY_OF_MONTH_LAST_DAY)
                        .withInstallmentFrequency(1)
                        .withDateEstablished(Date.newInstance(2019, 9, 15))
                        .withStartDate(Date.newInstance(2019, 1, 30))
                        .build();

        RD2_ScheduleService service = getScheduleServiceWithCurrentDateOverride(Date.newInstance(2019, 3, 1));

        System.assertEquals(Date.newInstance(2019, 3, 31),
                service.getNextDonationDate(rd),
                'Next Donation Date should equal 3/31/2019');

    }

    /***
    * @description Verifies next donation date for monthly donation when donation falls in current month.
    */
    @isTest
    private static void shouldCreateNextDonationDateInCurrentMonth() {

        npe03__Recurring_Donation__c rd =
            TEST_RecurringDonationBuilder.constructEnhancedBuilder()
                .withMockId()
                .withContact(UTIL_UnitTestData_TEST.mockId(Contact.SObjectType))
                .withAmount(400)
                .withPaymentMethod('Check')
                .withInstallmentPeriodMonthly()
                .withInstallmentFrequency(1)
                .withDayOfMonth('23')
                .withDateEstablished(Date.newInstance(2019, 9, 15))
                .withStartDate(Date.newInstance(2019, 11, 1))
                .build();

        RD2_ScheduleService service = getScheduleServiceWithCurrentDateOverride(Date.newInstance(2019, 11, 1));

        System.assertEquals(Date.newInstance(2019, 11, 23),
            service.getNextDonationDate(rd),
            'Next Donation Date should equal 11/23/2019');

    }

    /***
    * @description Verifies next donation date for 1st and 15th donation when donation schedules.
    */
    @isTest
    private static void shouldCreateNextDonationDateFromEarliest() {

        npe03__Recurring_Donation__c rd =
            TEST_RecurringDonationBuilder.constructEnhancedBuilder()
                .withMockId()
                .withContact(UTIL_UnitTestData_TEST.mockId(Contact.SObjectType))
                .withAmount(400)
                .withPaymentMethod('Check')
                .withInstallmentPeriod(RD2_Constants.INSTALLMENT_PERIOD_FIRST_AND_FIFTEENTH)
                .withInstallmentFrequency(1)
                .withDateEstablished(Date.newInstance(2019, 9, 15))
                .withStartDate(Date.newInstance(2019, 11, 14))
                .build();

        RD2_ScheduleService service = getScheduleServiceWithCurrentDateOverride(Date.newInstance(2019, 11, 14));

        System.assertEquals(Date.newInstance(2019, 11, 15),
            service.getNextDonationDate(rd),
            'Next Donation Date should equal 11/15/2019');

    }

    /***
    * @description Verifies next donation date for monthly donation for yearly donation.
    */
    @isTest
    private static void shouldCreateNextDonationDateFromYearlyStartDate() {

        npe03__Recurring_Donation__c rd =
            TEST_RecurringDonationBuilder.constructEnhancedBuilder()
                .withMockId()
                .withContact(UTIL_UnitTestData_TEST.mockId(Contact.SObjectType))
                .withAmount(400)
                .withPaymentMethod('Check')
                .withInstallmentPeriodYearly()
                .withInstallmentFrequency(1)
                .withDateEstablished(Date.newInstance(2019, 9, 15))
                .withStartDate(Date.newInstance(2020, 11, 1))
                .build();

        RD2_ScheduleService service = getScheduleServiceWithCurrentDateOverride(Date.newInstance(2019, 11, 1));

        System.assertEquals(Date.newInstance(2020, 11, 1),
            service.getNextDonationDate(rd),
            'Next Donation Date should equal 11/1/2020');

    }

    /***
    * @description Verifies next donation date for weekly donation.
    */
    @isTest
    private static void shouldCreateNextDonationDateFromWeeklyStartDate() {

        npe03__Recurring_Donation__c rd =
            TEST_RecurringDonationBuilder.constructEnhancedBuilder()
                .withMockId()
                .withContact(UTIL_UnitTestData_TEST.mockId(Contact.SObjectType))
                .withAmount(400)
                .withPaymentMethod('Check')
                .withInstallmentPeriodWeekly()
                .withInstallmentFrequency(1)
                .withDateEstablished(Date.newInstance(2019, 9, 15))
                .withStartDate(Date.newInstance(2018, 3, 17))
                .build();

        RD2_ScheduleService service = getScheduleServiceWithCurrentDateOverride(Date.newInstance(2018, 3, 17));

        System.assertEquals(Date.newInstance(2018, 3, 17),
            service.getNextDonationDate(rd),
            'Next Donation Date should equal 3/17/2018');

    }

    /***
    * @description Verifies next donation date for daily donation with frequency > 1.
    */
    @isTest
    private static void shouldCreateNextDonationDateWithFrequency15Days() {

        npe03__Recurring_Donation__c rd =
            TEST_RecurringDonationBuilder.constructEnhancedBuilder()
                .withMockId()
                .withContact(UTIL_UnitTestData_TEST.mockId(Contact.SObjectType))
                .withAmount(400)
                .withPaymentMethod('Check')
                .withInstallmentPeriod(RD2_Constants.INSTALLMENT_PERIOD_DAILY)
                .withInstallmentFrequency(15)
                .withDateEstablished(Date.newInstance(2019, 9, 15))
                .withStartDate(Date.newInstance(2018, 7, 1))
                .build();

        RD2_ScheduleService service = getScheduleServiceWithCurrentDateOverride(Date.newInstance(2018, 7, 17));

        System.assertEquals(Date.newInstance(2018, 7, 31),
                service.getNextDonationDate(rd),
                'Next Donation Date should equal 7/31/2018');

    }

    /***
    * @description Verifies next donation date for weekly donation with frequency > 1.
    */
    @isTest
    private static void shouldCreateNextDonationDateWithFrequency3Weeks() {

        npe03__Recurring_Donation__c rd =
            TEST_RecurringDonationBuilder.constructEnhancedBuilder()
                .withMockId()
                .withContact(UTIL_UnitTestData_TEST.mockId(Contact.SObjectType))
                .withAmount(400)
                .withPaymentMethod('Check')
                .withInstallmentPeriodWeekly()
                .withInstallmentFrequency(3)
                .withDateEstablished(Date.newInstance(2019, 9, 15))
                .withStartDate(Date.newInstance(2018, 3, 17))
                .build();

        RD2_ScheduleService service = getScheduleServiceWithCurrentDateOverride(Date.newInstance(2018, 4, 8));

        System.assertEquals(Date.newInstance(2018, 4, 28),
            service.getNextDonationDate(rd),
            'Next Donation Date should equal 4/28/2018');

    }

    /***
    * @description Verifies next donation date for monthly donation with frequency > 1.
    */
    @isTest
    private static void shouldCreateNextDonationDateWithFrequency11Months() {

        npe03__Recurring_Donation__c rd =
            TEST_RecurringDonationBuilder.constructEnhancedBuilder()
                .withMockId()
                .withContact(UTIL_UnitTestData_TEST.mockId(Contact.SObjectType))
                .withAmount(400)
                .withPaymentMethod('Check')
                .withInstallmentPeriodMonthly()
                .withInstallmentFrequency(11)
                .withDateEstablished(Date.newInstance(2019, 9, 15))
                .withStartDate(Date.newInstance(2018, 3, 17))
                .build();

        RD2_ScheduleService service = getScheduleServiceWithCurrentDateOverride(Date.newInstance(2023, 1, 18));

        System.assertEquals(Date.newInstance(2023, 9, 17),
            service.getNextDonationDate(rd),
            'Next Donation Date should equal 1/17/2020');

    }

    /***
    * @description Verifies next donation date for yearly donation with frequency > 1.
    */
    @isTest
    private static void shouldCreateNextDonationDateWithFrequency5Years() {

        npe03__Recurring_Donation__c rd =
            TEST_RecurringDonationBuilder.constructEnhancedBuilder()
                .withMockId()
                .withContact(UTIL_UnitTestData_TEST.mockId(Contact.SObjectType))
                .withAmount(400)
                .withPaymentMethod('Check')
                .withInstallmentPeriodYearly()
                .withInstallmentFrequency(5)
                .withDateEstablished(Date.newInstance(2019, 9, 15))
                .withStartDate(Date.newInstance(2018, 3, 17))
                .build();

        RD2_ScheduleService service = getScheduleServiceWithCurrentDateOverride(Date.newInstance(2023, 3, 18));

        System.assertEquals(Date.newInstance(2028, 3, 17),
            service.getNextDonationDate(rd),
            'Next Donation Date should equal 3/17/2028');

    }

    /***
    * @description Verifies next donation date for 1st and 15th donation with frequency > 1.
    */
    @isTest
    private static void shouldCreateNextDonationDateWithFrequency5FirstAndFifteenth() {

        npe03__Recurring_Donation__c rd =
            TEST_RecurringDonationBuilder.constructEnhancedBuilder()
                .withMockId()
                .withContact(UTIL_UnitTestData_TEST.mockId(Contact.SObjectType))
                .withAmount(400)
                .withPaymentMethod('Check')
                .withInstallmentPeriod(RD2_Constants.INSTALLMENT_PERIOD_FIRST_AND_FIFTEENTH)
                .withInstallmentFrequency(5)
                .withDateEstablished(Date.newInstance(2019, 9, 15))
                .withStartDate(Date.newInstance(2018, 3, 17))
                .build();

        RD2_ScheduleService service = getScheduleServiceWithCurrentDateOverride(Date.newInstance(2018, 9, 16));

        System.assertEquals(Date.newInstance(2019, 2, 1),
            service.getNextDonationDate(rd),
            'Next Donation Date should equal 2/1/2019');

    }

    /***
    * @description Verifies update is needed when status on recurring donation is changed.
    */
    @isTest
    private static void shouldDetermineUpdateNeededWhenStatusChanged() {

        npe03__Recurring_Donation__c rd =
            TEST_RecurringDonationBuilder.constructEnhancedBuilder()
                .withMockId()
                .withContact(UTIL_UnitTestData_TEST.mockId(Contact.SObjectType))
                .withAmount(400)
                .withPaymentMethod('Check')
                .withInstallmentPeriodWeekly()
                .withInstallmentFrequency(1)
                .withDateEstablished(Date.newInstance(2019, 9, 15))
                .withStartDate(Date.newInstance(2018, 3, 17))
                .withStatusClosed()
                .build();

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

        npe03__Recurring_Donation__c rd =
            TEST_RecurringDonationBuilder.constructEnhancedBuilder()
                .withMockId()
                .withContact(UTIL_UnitTestData_TEST.mockId(Contact.SObjectType))
                .withAmount(400)
                .withPaymentMethod('Check')
                .withInstallmentPeriodWeekly()
                .withInstallmentFrequency(1)
                .withDateEstablished(Date.newInstance(2019, 9, 15))
                .withStartDate(Date.newInstance(2018, 3, 17))
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

        npe03__Recurring_Donation__c rd =
            TEST_RecurringDonationBuilder.constructEnhancedBuilder()
                .withMockId()
                .withContact(UTIL_UnitTestData_TEST.mockId(Contact.SObjectType))
                .withAmount(400)
                .withPaymentMethod('Check')
                .withInstallmentPeriodWeekly()
                .withInstallmentFrequency(1)
                .withDateEstablished(Date.newInstance(2019, 9, 15))
                .withStartDate(Date.newInstance(2018, 3, 17))
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

        npe03__Recurring_Donation__c rd =
            TEST_RecurringDonationBuilder.constructEnhancedBuilder()
                .withMockId()
                .withContact(UTIL_UnitTestData_TEST.mockId(Contact.SObjectType))
                .withAmount(400)
                .withPaymentMethod('Check')
                .withInstallmentPeriodWeekly()
                .withInstallmentFrequency(1)
                .withDateEstablished(Date.newInstance(2019, 9, 15))
                .withStartDate(Date.newInstance(2018, 3, 17))
                .build();

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

        npe03__Recurring_Donation__c rd =
            TEST_RecurringDonationBuilder.constructEnhancedBuilder()
                .withMockId()
                .withContact(UTIL_UnitTestData_TEST.mockId(Contact.SObjectType))
                .withAmount(400)
                .withPaymentMethod('Check')
                .withInstallmentPeriodWeekly()
                .withInstallmentFrequency(1)
                .withInstallmentPeriod(RD2_Constants.INSTALLMENT_PERIOD_FIRST_AND_FIFTEENTH)
                .withInstallmentFrequency(5)
                .withDateEstablished(Date.newInstance(2019, 9, 15))
                .withStartDate(Date.newInstance(2018, 3, 17))
                .build();

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

        npe03__Recurring_Donation__c rd =
            TEST_RecurringDonationBuilder.constructEnhancedBuilder()
                .withMockId()
                .withContact(UTIL_UnitTestData_TEST.mockId(Contact.SObjectType))
                .withAmount(400)
                .withPaymentMethod('Check')
                .withInstallmentPeriodWeekly()
                .withInstallmentFrequency(1)
                .withDateEstablished(Date.newInstance(2019, 9, 15))
                .withStartDate(Date.newInstance(2018, 3, 17))
                .build();

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

        npe03__Recurring_Donation__c rd =
            TEST_RecurringDonationBuilder.constructEnhancedBuilder()
                .withMockId()
                .withContact(UTIL_UnitTestData_TEST.mockId(Contact.SObjectType))
                .withAmount(400)
                .withPaymentMethod('Check')
                .withInstallmentPeriodWeekly()
                .withInstallmentFrequency(1)
                .withDateEstablished(Date.newInstance(2019, 9, 15))
                .withStartDate(Date.newInstance(2018, 3, 17))
                .build();

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

        npe03__Recurring_Donation__c rd =
            TEST_RecurringDonationBuilder.constructEnhancedBuilder()
                .withMockId()
                .withContact(UTIL_UnitTestData_TEST.mockId(Contact.SObjectType))
                .withAmount(400)
                .withPaymentMethod('Check')
                .withInstallmentPeriodWeekly()
                .withInstallmentFrequency(1)
                .withDateEstablished(Date.newInstance(2019, 9, 15))
                .withStartDate(Date.newInstance(2018, 3, 17))
                .build();

        npe03__Recurring_Donation__c changeRd = rd.clone();
        changeRd.PaymentMethod__c = 'Credit Card';

        RD2_ScheduleService schedule = new RD2_ScheduleService();
        Boolean updateNeeded = schedule.isScheduleUpdateNeeded(changeRd, rd);

        System.assertEquals(true, updateNeeded, 'isScheduleUpdateNeeded should return true.');

    }

    /***
    * @description Verifies update is needed when campaign on recurring donation is changed.
    */
    @isTest
    private static void shouldDetermineUpdateNeededWhenCampaignChanged() {

        npe03__Recurring_Donation__c rd =
            TEST_RecurringDonationBuilder.constructEnhancedBuilder()
                .withMockId()
                .withContact(UTIL_UnitTestData_TEST.mockId(Contact.SObjectType))
                .withAmount(400)
                .withPaymentMethod('Check')
                .withInstallmentPeriodWeekly()
                .withInstallmentFrequency(1)
                .withDateEstablished(Date.newInstance(2019, 9, 15))
                .withStartDate(Date.newInstance(2018, 3, 17))
                .build();

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

        npe03__Recurring_Donation__c rd =
            TEST_RecurringDonationBuilder.constructEnhancedBuilder()
                .withMockId()
                .withContact(UTIL_UnitTestData_TEST.mockId(Contact.SObjectType))
                .withAmount(400)
                .withPaymentMethod('Check')
                .withInstallmentPeriodWeekly()
                .withInstallmentFrequency(1)
                .withDateEstablished(Date.newInstance(2019, 9, 15))
                .withStartDate(Date.newInstance(2018, 3, 17))
                .build();

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

        npe03__Recurring_Donation__c rd =
            TEST_RecurringDonationBuilder.constructEnhancedBuilder()
                .withMockId()
                .withContact(UTIL_UnitTestData_TEST.mockId(Contact.SObjectType))
                .withAmount(400)
                .withPaymentMethod('Check')
                .withInstallmentPeriodMonthly()
                .withDayOfMonth('20')
                .withInstallmentFrequency(1)
                .withDateEstablished(Date.newInstance(2019, 9, 15))
                .withStartDate(Date.newInstance(2018, 3, 17))
                .build();

        RD2_ScheduleService service = new RD2_ScheduleService();
        List<RecurringDonationSchedule__c> schedules = service.getNewSchedules(rd);
        rd.Day_of_Month__c = '21';

        TDTM_Runnable.DMLWrapper changes = service.getUpdatedSchedules(rd, schedules);
        System.assertEquals(Date.newInstance(2018,3,16), changes.objectsToUpdate[0].get('EndDate__c'), 'End Date should be set to 3/16/2018.');
        System.assertEquals('21', changes.objectsToInsert[0].get('DayOfMonth__c'), 'Day of month should be set to 21.');

    }

    /***
    * @description Verifies schedule is ended when RD is closed.
    */
    @isTest
    private static void shouldInactivateCurrentSchedule() {

        npe03__Recurring_Donation__c rd =
            TEST_RecurringDonationBuilder.constructEnhancedBuilder()
                .withMockId()
                .withContact(UTIL_UnitTestData_TEST.mockId(Contact.SObjectType))
                .withAmount(400)
                .withPaymentMethod('Check')
                .withInstallmentPeriodMonthly()
                .withDayOfMonth('20')
                .withInstallmentFrequency(1)
                .withDateEstablished(Date.newInstance(2019, 9, 15))
                .withStartDate(Date.newInstance(2018, 3, 17))
                .build();

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

        npe03__Recurring_Donation__c rd =
            TEST_RecurringDonationBuilder.constructEnhancedBuilder()
                .withMockId()
                .withContact(UTIL_UnitTestData_TEST.mockId(Contact.SObjectType))
                .withAmount(400)
                .withPaymentMethod('Check')
                .withInstallmentPeriod(RD2_Constants.INSTALLMENT_PERIOD_FIRST_AND_FIFTEENTH)
                .withInstallmentFrequency(1)
                .withDateEstablished(Date.newInstance(2019, 9, 15))
                .withStartDate(Date.newInstance(2018, 3, 17))
                .build();

        RD2_ScheduleService service = new RD2_ScheduleService();
        List<RecurringDonationSchedule__c> schedules = service.getNewSchedules(rd);
        rd.npe03__Installment_Period__c = RD2_Constants.INSTALLMENT_PERIOD_WEEKLY;

        TDTM_Runnable.DMLWrapper changes = service.getUpdatedSchedules(rd, schedules);
        System.assertEquals(Date.newInstance(2018,3,16), changes.objectsToUpdate[0].get('EndDate__c'), 'End Date should be set to 3/16/2018.');
        System.assertEquals(Date.newInstance(2018,3,16), changes.objectsToUpdate[1].get('EndDate__c'), 'End Date should be set to 3/16/2018.');
        System.assertEquals(RD2_Constants.INSTALLMENT_PERIOD_WEEKLY, changes.objectsToInsert[0].get('InstallmentPeriod__c'), 'Installment period should be set to weekly.');

    }

    /***
    * @description Verifies new schedule is created when new RD is lapsed
    */
    @isTest
    private static void shouldCreateNewScheduleWhenNewRDIsLapsed() {

        npe03__Recurring_Donation__c rd =
            TEST_RecurringDonationBuilder.constructEnhancedBuilder()
                .withMockId()
                .withContact(UTIL_UnitTestData_TEST.mockId(Contact.SObjectType))
                .withAmount(400)
                .withPaymentMethod('Check')
                .withInstallmentPeriod(RD2_Constants.INSTALLMENT_PERIOD_MONTHLY)
                .withDayOfMonth('5')
                .withInstallmentFrequency(1)
                .withDateEstablished(Date.newInstance(2019, 9, 15))
                .withStartDate(Date.newInstance(2018, 3, 17))
                .withStatus(RD2_Constants.STATUS_LAPSED)
                .build();

        RD2_ScheduleService service = new RD2_ScheduleService();
        List<RecurringDonationSchedule__c> schedules = service.getNewSchedules(rd);

        System.assertEquals(1, schedules.size(), '1 new schedule should be created.');
        System.assertEquals(schedules[0].StartDate__c, Date.newInstance(2018, 3, 17), 'Start date on new schedule should be 3/17/2018.');

    }

    /***
    * @description Verifies next donation date is generated when new RD is lapsed
    */
    @isTest
    private static void shouldGenerateNextDonationDateWhenNewRDIsLapsed() {

        npe03__Recurring_Donation__c rd =
            TEST_RecurringDonationBuilder.constructEnhancedBuilder()
                .withMockId()
                .withContact(UTIL_UnitTestData_TEST.mockId(Contact.SObjectType))
                .withAmount(400)
                .withPaymentMethod('Check')
                .withInstallmentPeriod(RD2_Constants.INSTALLMENT_PERIOD_DAILY)
                .withInstallmentFrequency(1)
                .withDateEstablished(Date.newInstance(2019, 9, 15))
                .withStartDate(Date.newInstance(2018, 3, 17))
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

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        Contact contact = getContact();

        npe03__Recurring_Donation__c rd =
                TEST_RecurringDonationBuilder.constructEnhancedBuilder()
                        .withContact(contact.Id)
                        .withAmount(50)
                        .withPaymentMethod('Credit Card')
                        .withInstallmentPeriodMonthly()
                        .withDayOfMonth('1')
                        .withInstallmentFrequency(1)
                        .withDateEstablished(Date.newInstance(2019, 11, 1))
                        .withStartDate(Date.newInstance(2019, 11, 1))
                        .build();

        RD2_ScheduleService service = getScheduleServiceWithCurrentDateOverride(Date.newInstance(2019, 11, 1));

        Test.startTest();
        insert rd;
        List<RD2_ScheduleService.Installment> installments = service.getVisualizedInstallments(rd, Date.newInstance(2019, 11, 1), 480, null);
        Test.stopTest();

        System.assertEquals(480, installments.size(), 'There should be 480 installments.');
        System.assertEquals(Date.newInstance(2059, 10, 1), installments[479].nextDonationDate, 'Final installment date should be 10/1/2059.');

    }

    /***
    * @description Verifies visualization does not fail when zero installments are requested
    */
    @isTest
    private static void shouldReturnZeroInstallmentsWhenZeroRequested() {

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        Contact contact = getContact();

        npe03__Recurring_Donation__c rd =
                TEST_RecurringDonationBuilder.constructEnhancedBuilder()
                        .withContact(contact.Id)
                        .withAmount(50)
                        .withPaymentMethod('Credit Card')
                        .withInstallmentPeriodMonthly()
                        .withDayOfMonth('1')
                        .withInstallmentFrequency(1)
                        .withDateEstablished(Date.newInstance(2019, 11, 1))
                        .withStartDate(Date.newInstance(2019, 11, 1))
                        .withStatusClosed()
                        .build();

        RD2_ScheduleService service = getScheduleServiceWithCurrentDateOverride(Date.newInstance(2019, 11, 1));

        Test.startTest();
        insert rd;
        List<RD2_ScheduleService.Installment> installments = service.getVisualizedInstallments(rd, Date.newInstance(2019, 11, 1), 12, null);
        Test.stopTest();

        System.assertEquals(0, installments.size(), 'There should be 0 installments.');

    }

    /***
    * @description Verifies visualization does not fail when null RD Id is used
    */
    @isTest
    private static void shouldReturnZeroInstallmentsWhenRDIdIsNull() {

        RD2_ScheduleService service = getScheduleServiceWithCurrentDateOverride(Date.newInstance(2019, 11, 1));

        Map<Id, List<RD2_ScheduleService.Installment>> installmentsByRDIds = service.getVisualizedInstallments(new List<npe03__Recurring_Donation__c>{null}, Date.newInstance(2019, 11, 1), 12, null);

        System.assertEquals(0, installmentsByRDIds.size(), 'Map of RDIds to installments should be empty.');

    }

    /***
    * @description Verifies visualization substitutes default when null start date is used
    */
    @isTest
    private static void shouldReturnRequestedInstallmentsWhenStartDateIsNull() {

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        Contact contact = getContact();

        npe03__Recurring_Donation__c rd =
                TEST_RecurringDonationBuilder.constructEnhancedBuilder()
                        .withContact(contact.Id)
                        .withAmount(50)
                        .withPaymentMethod('Credit Card')
                        .withInstallmentPeriodMonthly()
                        .withDayOfMonth('1')
                        .withInstallmentFrequency(1)
                        .withDateEstablished(Date.newInstance(2019, 11, 1))
                        .withStartDate(Date.newInstance(2019, 11, 1))
                        .build();

        RD2_ScheduleService service = getScheduleServiceWithCurrentDateOverride(Date.newInstance(2019, 11, 1));

        Test.startTest();
        insert rd;
        List<RD2_ScheduleService.Installment> installments = service.getVisualizedInstallments(rd, null, 12, null);
        Test.stopTest();

        System.assertEquals(12, installments.size(), 'There should be 12 installments.');
        System.assertEquals(Date.newInstance(2020, 10, 1), installments[11].nextDonationDate, 'Final installment date should be 10/1/2020.');

    }

    /***
    * @description Verifies visualization substitutes default when null maxDates are requested
    */
    @isTest
    private static void shouldReturn12InstallmentsWhenNumberRequestedIsNull() {

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        Contact contact = getContact();

        npe03__Recurring_Donation__c rd =
                TEST_RecurringDonationBuilder.constructEnhancedBuilder()
                        .withContact(contact.Id)
                        .withAmount(50)
                        .withPaymentMethod('Credit Card')
                        .withInstallmentPeriodMonthly()
                        .withDayOfMonth('1')
                        .withInstallmentFrequency(1)
                        .withDateEstablished(Date.newInstance(2019, 11, 1))
                        .withStartDate(Date.newInstance(2019, 11, 1))
                        .build();

        RD2_ScheduleService service = getScheduleServiceWithCurrentDateOverride(Date.newInstance(2019, 11, 1));

        Test.startTest();
        insert rd;
        List<RD2_ScheduleService.Installment> installments = service.getVisualizedInstallments(rd, Date.newInstance(2019, 11, 1), null, null);
        Test.stopTest();

        System.assertEquals(12, installments.size(), 'There should be 12 installments.');
        System.assertEquals(Date.newInstance(2020, 10, 1), installments[11].nextDonationDate, 'Final installment date should be 10/1/2020.');

    }

    /***
    * @description Verifies visualization substitutes default when null maxDates are requested
    */
    @isTest
    private static void shouldReturn12InstallmentsWhenSchedulesInjected() {

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        Contact contact = getContact();

        npe03__Recurring_Donation__c rd =
                TEST_RecurringDonationBuilder.constructEnhancedBuilder()
                        .withContact(contact.Id)
                        .withAmount(50)
                        .withPaymentMethod('Credit Card')
                        .withInstallmentPeriodMonthly()
                        .withDayOfMonth('1')
                        .withInstallmentFrequency(1)
                        .withDateEstablished(Date.newInstance(2019, 11, 1))
                        .withStartDate(Date.newInstance(2019, 11, 1))
                        .build();

        RD2_ScheduleService service = getScheduleServiceWithCurrentDateOverride(Date.newInstance(2019, 11, 1));

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

        List<RD2_ScheduleService.Installment> installments = service.getVisualizedInstallments(rd, Date.newInstance(2019, 11, 1), null, rds);
        System.assertEquals(12, installments.size(), 'There should be 12 installments.');
        System.assertEquals(Date.newInstance(2020, 10, 1), installments[11].nextDonationDate, 'Final installment date should be 10/1/2020.');

    }

    /***
    * @description Verifies visualization substitutes default when null maxDates are requested
    */
    @isTest
    private static void shouldReturn10InstallmentsWhenEndDateIsReached() {

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        Contact contact = getContact();

        npe03__Recurring_Donation__c rd =
                TEST_RecurringDonationBuilder.constructEnhancedBuilder()
                        .withContact(contact.Id)
                        .withAmount(50)
                        .withPaymentMethod('Credit Card')
                        .withInstallmentPeriodMonthly()
                        .withDayOfMonth('1')
                        .withInstallmentFrequency(1)
                        .withDateEstablished(Date.newInstance(2020, 1, 1))
                        .withStartDate(Date.newInstance(2020, 1, 1))
                        .build();

        RD2_ScheduleService service = new RD2_ScheduleService();

        Test.startTest();
        insert rd;
        Test.stopTest();

        List<RecurringDonationSchedule__c> rdSchedules = [SELECT Id, EndDate__c FROM RecurringDonationSchedule__c WHERE RecurringDonation__c = :rd.Id];
        rdSchedules[0].EndDate__c = Date.newInstance(2020, 10, 31);
        update rdSchedules;
        List<RD2_ScheduleService.Installment> installments = service.getVisualizedInstallments(rd, Date.newInstance(2020, 1, 1), 12, null);

        System.assertEquals(10, installments.size(), 'There should be 10 installments.');
        System.assertEquals(Date.newInstance(2020, 10, 1), installments[9].nextDonationDate, 'Final installment date should be 10/1/2020.');

    }

    /***
    * @description Verifies visualization substitutes default when null maxDates are requested
    */
    @isTest
    private static void shouldReturn12InstallmentsEachFor3RDsWhenNumberRequestedIsNull() {

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        Contact contact = getContact();

        List<npe03__Recurring_Donation__c> rds = new List<npe03__Recurring_Donation__c>();
        rds.add(TEST_RecurringDonationBuilder.constructEnhancedBuilder()
                .withContact(contact.Id)
                .withAmount(50)
                .withPaymentMethod('Credit Card')
                .withInstallmentPeriodMonthly()
                .withDayOfMonth('1')
                .withInstallmentFrequency(1)
                .withDateEstablished(Date.newInstance(2019, 11, 1))
                .withStartDate(Date.newInstance(2019, 11, 1))
                .build());
        rds.add(TEST_RecurringDonationBuilder.constructEnhancedBuilder()
                .withContact(contact.Id)
                .withAmount(100)
                .withPaymentMethod('Credit Card')
                .withInstallmentPeriodWeekly()
                .withInstallmentFrequency(1)
                .withDateEstablished(Date.newInstance(2019, 11, 1))
                .withStartDate(Date.newInstance(2019, 11, 1))
                .build());
        rds.add(TEST_RecurringDonationBuilder.constructEnhancedBuilder()
                .withContact(contact.Id)
                .withAmount(25)
                .withPaymentMethod('Credit Card')
                .withInstallmentPeriod('1st and 15th')
                .withInstallmentFrequency(1)
                .withDateEstablished(Date.newInstance(2019, 11, 1))
                .withStartDate(Date.newInstance(2019, 11, 1))
                .build());

        RD2_ScheduleService service = new RD2_ScheduleService();

        Test.startTest();
        insert rds;
        Map<Id, List<RD2_ScheduleService.Installment>> installmentsByRDId = service.getVisualizedInstallments(rds, Date.newInstance(2019, 11, 1), null, null);
        Test.stopTest();

        System.assertEquals(Date.newInstance(2019, 12, 1), installmentsByRDId.get(rds[0].Id)[1].nextDonationDate, 'Donation date should be 12/1/2019.');
        System.assertEquals(Date.newInstance(2020, 1, 17), installmentsByRDId.get(rds[1].Id)[11].nextDonationDate, 'Donation date should be 1/17/2020.');
        System.assertEquals(Date.newInstance(2020, 1, 15), installmentsByRDId.get(rds[2].Id)[5].nextDonationDate, 'Donation date should be 1/15/2020.');

    }

    /***
    * @description Verifies visualization does not fail when negative max dates requested
    */
    @isTest
    private static void shouldReturnZeroInstallmentsWhenNegativeNumberRequested() {

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        Contact contact = getContact();

        npe03__Recurring_Donation__c rd =
                TEST_RecurringDonationBuilder.constructEnhancedBuilder()
                        .withContact(contact.Id)
                        .withAmount(50)
                        .withPaymentMethod('Credit Card')
                        .withInstallmentPeriodMonthly()
                        .withDayOfMonth('1')
                        .withInstallmentFrequency(1)
                        .withDateEstablished(Date.newInstance(2019, 11, 1))
                        .withStartDate(Date.newInstance(2019, 11, 1))
                        .build();

        RD2_ScheduleService service = getScheduleServiceWithCurrentDateOverride(Date.newInstance(2019, 11, 1));

        Test.startTest();
        insert rd;
        List<RD2_ScheduleService.Installment> installments = service.getVisualizedInstallments(rd, Date.newInstance(2019, 11, 1), -5, null);
        Test.stopTest();

        System.assertEquals(0, installments.size(), 'There should be 0 installments.');

    }

    /***
    * @description Verifies visualization behaves as expected with 1st and 15th schedule
    */
    @isTest
    private static void shouldReturn12InstallmentsWhen1stAnd15thRequested() {

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        Contact contact = getContact();

        npe03__Recurring_Donation__c rd =
                TEST_RecurringDonationBuilder.constructEnhancedBuilder()
                        .withContact(contact.Id)
                        .withAmount(50)
                        .withPaymentMethod('Credit Card')
                        .withInstallmentPeriod('1st and 15th')
                        .withInstallmentFrequency(1)
                        .withDateEstablished(Date.newInstance(2019, 11, 1))
                        .withStartDate(Date.newInstance(2019, 11, 1))
                        .build();

        RD2_ScheduleService service = getScheduleServiceWithCurrentDateOverride(Date.newInstance(2019, 11, 1));

        Test.startTest();
        insert rd;
        List<RD2_ScheduleService.Installment> installments = service.getVisualizedInstallments(rd, Date.newInstance(2019, 11, 1), 12, null);
        Test.stopTest();

        System.assertEquals(12, installments.size(), 'There should be 12 installments.');
        System.assertEquals(Date.newInstance(2020, 4, 15), installments[11].nextDonationDate, 'Final installment date should be 4/15/2020.');

    }


        //// Helpers

    /****
    * @description Returns Schedule Service with current date override
    */
    private static RD2_ScheduleService getScheduleServiceWithCurrentDateOverride(Date currDateOverride) {

        RD2_ScheduleService scheduleService = new RD2_ScheduleService();
        scheduleService.currentDate = currDateOverride;

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