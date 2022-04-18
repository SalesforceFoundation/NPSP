/*
    Copyright (c) 2022, Salesforce.org
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
* @date 2022
* @group Recurring Donations
* @description Test class for RD2_StatusAutomationService
*/
@IsTest
public class RD2_StatusAutomationService_TEST {
    private static final Integer DAYS_FOR_LAPSED = 15;
    private static final Integer DAYS_FOR_CLOSED = 20;

    @IsTest
    private static void verifyCorrectViewIsRetrieve() {
        RD2_StatusAutomationService.statusMapper = (RD2_StatusMapper) Test.createStub(
            RD2_StatusMapper.Class,
            new RD2_StatusMapper_TEST.Stub().withDefaultMapping()
        );

        UTIL_CustomSettingsFacade.getRecurringDonationsSettingsForTest(
            new npe03__Recurring_Donations_Settings__c(
                    IsRecurringDonations2Enabled__c = true,
                    StatusAutomationDaysForLapsed__c = DAYS_FOR_LAPSED,
                    StatusAutomationDaysForClosed__c = DAYS_FOR_CLOSED,
                    StatusAutomationLapsedValue__c = RD2_Constants.STATUS_LAPSED,
                    StatusAutomationClosedValue__c = RD2_Constants.STATUS_CLOSED
            )
        );

        Test.startTest();
        RD2_StatusAutomationService service = new RD2_StatusAutomationService();
        RD2_StatusAutomationView view = service.getStatusAutomationView();
        Test.stopTest();

        RD2_StatusMapper statusMapper = new RD2_StatusMapper();
        Set<String> lapsedStatusValues = statusMapper.getLapsedStatusValues();
        Set<String> closedStatusValues = statusMapper.getClosedStatusValues();
        String lapsedStatusLabel =  UTIL_Describe.getTranslatedPicklistLabel(
            npe03__Recurring_Donation__c.SObjectType, npe03__Recurring_Donation__c.Status__c, RD2_Constants.STATUS_LAPSED
        );
        String closedStatusLabel =  UTIL_Describe.getTranslatedPicklistLabel(
            npe03__Recurring_Donation__c.SObjectType, npe03__Recurring_Donation__c.Status__c, RD2_Constants.STATUS_CLOSED
        );
        
        System.assertEquals(true, view.rd2Enabled, 'RD2 should be enabled');
        System.assertEquals(DAYS_FOR_LAPSED, view.numberOfDaysForLapsed,
            'The view state should retrieve the correct number of days for Lapsed');
        System.assertEquals(DAYS_FOR_CLOSED, view.numberOfDaysForClosed,
            'The view state should retrieve the correct number of days for Closed');
        System.assertEquals(lapsedStatusLabel, view.lapsedStatus,
            'The view state should retrieve the correct Automation Lapsed Status');
        System.assertEquals(closedStatusLabel, view.closedStatus,
            'The view state should retrieve the correct Automation Closed Status');

        for (PicklistOptionView pickListOption : view.lapsedStatusOption) {
            System.assert(lapsedStatusValues.contains(pickListOption.value),
                'Only Status mapped to Lapsed State should be in the Lapsed Status Option');
        }
        for (PicklistOptionView pickListOption : view.closedStatusOption) {
            System.assert(closedStatusValues.contains(pickListOption.value),
                'Only Status mapped to Closed State should be in the Closed Status Option');
        }
    }

    @IsTest
    private static void verifyDaysForLapsedCannotBeLargerThanDaysForClosed() {
        RD2_StatusAutomationService service = new RD2_StatusAutomationService();

        Test.startTest();
        String errorMessage = service.validateSetting(service.buildStatusAutomationSettings(5, 3, null, null));
        Test.stopTest();

        System.assertEquals(System.label.RD2_StatusAutomationInvalidNumberOfDays, errorMessage,
        'Invalid Number of Days message should be returned.');
    }

    @IsTest
    private static void verifyDaysForLapsedCannotBeNegative() {
        RD2_StatusAutomationService.statusMapper = (RD2_StatusMapper) Test.createStub(
            RD2_StatusMapper.Class,
            new RD2_StatusMapper_TEST.Stub().withDefaultMapping()
        );
        RD2_StatusAutomationService service = new RD2_StatusAutomationService();

        Test.startTest();
        String errorMessage = service.validateSetting(service.buildStatusAutomationSettings(-5, null, RD2_Constants.STATUS_LAPSED, null));
        Test.stopTest();

        System.assertEquals(System.label.RD2_StatusAutomationNegativeNumberOfDays, errorMessage,
        'Number of Days for Lapsed cannot be negative.');
    }

    @IsTest
    private static void verifyDaysForClosedCannotBeNegative() {
        RD2_StatusAutomationService.statusMapper = (RD2_StatusMapper) Test.createStub(
            RD2_StatusMapper.Class,
            new RD2_StatusMapper_TEST.Stub().withDefaultMapping()
        );
        RD2_StatusAutomationService service = new RD2_StatusAutomationService();

        Test.startTest();
        String errorMessage = service.validateSetting(service.buildStatusAutomationSettings(null, -3, null, RD2_Constants.STATUS_CLOSED));
        Test.stopTest();

        System.assertEquals(System.label.RD2_StatusAutomationNegativeNumberOfDays, errorMessage,
        'Number of Days for Lapsed cannot be negative.');
    }

    @IsTest
    private static void verifyClosedStatusShouldMappedToClosedState() {
        RD2_StatusAutomationService.statusMapper = (RD2_StatusMapper) Test.createStub(
            RD2_StatusMapper.Class,
            new RD2_StatusMapper_TEST.Stub().withDefaultMapping()
        );
        RD2_StatusAutomationService service = new RD2_StatusAutomationService();

        Test.startTest();
        String errorMessage = service.validateSetting(service.buildStatusAutomationSettings(null, 3, null, 'random'));
        Test.stopTest();

        System.assertEquals(System.label.RD2_StatusAutomationInvalidClosedStatus, errorMessage,
        'Invalid Closed Status error message should be returned.');
    }

    @IsTest
    private static void verifyLapsedStatusShouldMappedToLapsedState() {
        RD2_StatusAutomationService.statusMapper = (RD2_StatusMapper) Test.createStub(
            RD2_StatusMapper.Class,
            new RD2_StatusMapper_TEST.Stub().withDefaultMapping()
        );
        RD2_StatusAutomationService service = new RD2_StatusAutomationService();

        Test.startTest();
        String errorMessage = service.validateSetting(service.buildStatusAutomationSettings(2, null, 'random', null));
        Test.stopTest();

        System.assertEquals(System.label.RD2_StatusAutomationInvalidLapsedStatus, errorMessage,
        'Invalid Lapsed Status error message should be returned.');
    }

    @IsTest
    private static void verifyEmptyNumberOfDaysWillNotGetValidated() {
        RD2_StatusAutomationService.statusMapper = (RD2_StatusMapper) Test.createStub(
            RD2_StatusMapper.Class,
            new RD2_StatusMapper_TEST.Stub().withDefaultMapping()
        );
        RD2_StatusAutomationService service = new RD2_StatusAutomationService();

        Test.startTest();
        String errorMessage = service.validateSetting(service.buildStatusAutomationSettings(null, null, 'random', 'random'));
        Test.stopTest();

        System.assertEquals(null, errorMessage,
        'no error message should be returned because the feature is off when Number of Days is null.');
    }

    @Istest
    private static void verifyStatusAutomationShouldNotMarkRDToLapsedOnTheThresholdDay() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        setupStatusAutomationSettings(15, 20);
        RD2_ScheduleService scheduleService = new RD2_ScheduleService();
        RD2_StatusAutomationService automationService = new RD2_StatusAutomationService();

        npe03__Recurring_Donation__c rd = TEST_RecurringDonationBuilder.constructEnhancedBuilder()
            .withInstallmentPeriodMonthly()
            .withStatusActive()
            .withDayOfMonth('1')
            .withInstallmentFrequency(1)
            .withStartDate(Date.newInstance(2019, 6, 10))
            .withCalculateNextDonationDate()
            .build();

        rd = TEST_RecurringDonationBuilder.mockRecurringDonationFullQueryResult(rd, new List<Opportunity>(), scheduleService.buildNewSchedules(rd));
        RD2_ScheduleService.currentDate = Date.newInstance(2019, 7, 16);

        RD2_RecurringDonation rdRecord = new RD2_RecurringDonation(rd);
        Test.startTest();
        Boolean shouldMarkAsLapsed = automationService.shouldMarkRDAsLapsed(rdRecord, scheduleService);
        Test.stopTest();

        System.assertNotEquals(true, shouldMarkAsLapsed,
            'Should not mark RD as Lasped when threshold days has not passed (15 days) since the expected donation on 2019/7/1 is missing');
    }

    @Istest
    private static void verifyStatusAutomationShouldMarkRDToLapsedAfterThresholdDay() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        setupStatusAutomationSettings(15, 20);
        RD2_ScheduleService scheduleService = new RD2_ScheduleService();
        RD2_StatusAutomationService automationService = new RD2_StatusAutomationService();

        npe03__Recurring_Donation__c rd = TEST_RecurringDonationBuilder.constructEnhancedBuilder()
            .withInstallmentPeriodMonthly()
            .withStatusActive()
            .withDayOfMonth('1')
            .withInstallmentFrequency(1)
            .withStartDate(Date.newInstance(2019, 6, 10))
            .withCalculateNextDonationDate()
            .build();

        rd = TEST_RecurringDonationBuilder.mockRecurringDonationFullQueryResult(rd, new List<Opportunity>(), scheduleService.buildNewSchedules(rd));
        RD2_ScheduleService.currentDate = Date.newInstance(2019, 7, 17);

        RD2_RecurringDonation rdRecord = new RD2_RecurringDonation(rd);
        Test.startTest();
        Boolean shouldMarkAsLapsed = automationService.shouldMarkRDAsLapsed(rdRecord, scheduleService);
        Test.stopTest();

        System.assertEquals(true, shouldMarkAsLapsed,
            'Should mark RD as Lapsed when threshold days has passed (15 days) since the expected donation on 2019/7/1 is missing');
    }

    @Istest
    private static void verifyStatusAutomationShouldNotMarkRDToClosedOnThresholdDay() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        setupStatusAutomationSettings(15, 20);
        RD2_ScheduleService scheduleService = new RD2_ScheduleService();
        RD2_StatusAutomationService automationService = new RD2_StatusAutomationService();

        npe03__Recurring_Donation__c rd = TEST_RecurringDonationBuilder.constructEnhancedBuilder()
            .withInstallmentPeriodWeekly()
            .withStatusActive()
            .withInstallmentFrequency(1)
            .withStartDate(Date.newInstance(2019, 6, 10))
            .withCalculateNextDonationDate()
            .withLastPaymentDate(Date.newinstance(2019, 7, 16))
            .build();

        rd = TEST_RecurringDonationBuilder.mockRecurringDonationFullQueryResult(rd, new List<Opportunity>(), scheduleService.buildNewSchedules(rd));
        RD2_ScheduleService.currentDate = Date.newinstance(2019, 8, 11);

        RD2_RecurringDonation rdRecord = new RD2_RecurringDonation(rd);
        Test.startTest();
        Boolean shouldMarkAsClosed = automationService.shouldMarkRDAsClosed(rdRecord, scheduleService);
        Test.stopTest();

        System.assertEquals(false, shouldMarkAsClosed,
            'Should not mark RD as Closed when threshold days has not passed (8/11/2019 - 20 days) since the expected donation on 7/22/2019 is missing');
    }

    @Istest
    private static void verifyStatusAutomationShouldNotRDToClosedOnThresholdDay() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        setupStatusAutomationSettings(15, 20);
        RD2_ScheduleService scheduleService = new RD2_ScheduleService();
        RD2_StatusAutomationService automationService = new RD2_StatusAutomationService();

        npe03__Recurring_Donation__c rd = TEST_RecurringDonationBuilder.constructEnhancedBuilder()
            .withInstallmentPeriodYearly()
            .withStatusActive()
            .withInstallmentFrequency(1)
            .withStartDate(Date.newInstance(2019, 6, 10))
            .withCalculateNextDonationDate()
            .withLastPaymentDate(Date.newinstance(2020, 7, 1))
            .build();

        rd = TEST_RecurringDonationBuilder.mockRecurringDonationFullQueryResult(rd, new List<Opportunity>(), scheduleService.buildNewSchedules(rd));
        RD2_ScheduleService.currentDate = Date.newInstance(2021, 7, 1);

        RD2_RecurringDonation rdRecord = new RD2_RecurringDonation(rd);
        Test.startTest();
        Boolean shouldMarkAsClosed = automationService.shouldMarkRDAsClosed(rdRecord, scheduleService);
        Test.stopTest();

        System.assertEquals(true, shouldMarkAsClosed,
            'Should mark RD as Closed when threshold days has passed (20 days) since the expected donation on 2020/6/10 is missing');
    }

    public static void setupStatusAutomationSettings(Integer daysForLapsed, Integer daysForClosed) {
        RD2_Settings_TEST.setUpConfiguration(
            new Map<String, Object>{
                'StatusAutomationDaysForLapsed__c' => daysForLapsed,
                'StatusAutomationDaysForClosed__c' => daysForClosed,
                'StatusAutomationLapsedValue__c' => RD2_Constants.STATUS_LAPSED,
                'StatusAutomationClosedValue__c' => RD2_Constants.STATUS_CLOSED
            }
        );
    }

}
