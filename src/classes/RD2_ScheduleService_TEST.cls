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

        npe03__Recurring_Donation__c rds =
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

        List<RecurringDonationSchedule__c> schedules = new RD2_ScheduleService().getNewSchedules(rds);

        System.assertEquals(schedules.size(), 0, 'Number of RDs should be 0');

    }

}