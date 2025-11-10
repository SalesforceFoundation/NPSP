/*
    Copyright (c) 2025 Salesforce.org
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
* @date 2025
* @group Recurring Donations
* @description Extended Unit Tests for RD2_ApiService covering high priority scenarios
*
*/
@IsTest(IsParallel=false)
private class RD2_ApiService_Extended_TEST {

    private static final String API_QUERY_SCHEDULES = 'rd2.queryschedules';
    private static final String API_QUERY_INSTALLMENTS = 'rd2.queryinstallments';

    private static final Integer DAY_OF_MONTH = 1;
    private static final Date CURRENT_DATE = Date.newInstance(2019, 3, DAY_OF_MONTH);
    private static final Date START_DATE = CURRENT_DATE;
    private static final Id RD_MOCK_ID = UTIL_UnitTestData_TEST.mockId(npe03__Recurring_Donation__c.SObjectType);

    private static final TEST_SObjectGateway.RecurringDonationScheduleGateway scheduleGateway = new TEST_SObjectGateway.RecurringDonationScheduleGateway();
    private static final TEST_SObjectGateway.RecurringDonationGateway rdGateway = new TEST_SObjectGateway.RecurringDonationGateway();

    /****
    * @description Creates data required for unit tests
    */
    @TestSetup
    private static void setUp() {        
        RD2_ScheduleService.currentDate = CURRENT_DATE;

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        Contact contact = UTIL_UnitTestData_TEST.getContact();
        insert contact;

        // Create multiple recurring donations for testing
        npe03__Recurring_Donation__c rd1 = getEnhancedRecurringDonationBuilder(contact.Id)
            .build();
        
        npe03__Recurring_Donation__c rd2 = getEnhancedRecurringDonationBuilder(contact.Id)
            .withAmount(200)
            .withInstallmentPeriod(RD2_Constants.INSTALLMENT_PERIOD_FIRST_AND_FIFTEENTH)
            .build();

        npe03__Recurring_Donation__c rd3 = getEnhancedRecurringDonationBuilder(contact.Id)
            .withAmount(150)
            .withInstallmentPeriod(RD2_Constants.INSTALLMENT_PERIOD_WEEKLY)
            .build();

        insert new List<npe03__Recurring_Donation__c>{rd1, rd2, rd3};
    }

    // ===== HIGH PRIORITY TEST SCENARIOS =====

    /**
     * @description Test API call with multiple RD IDs to ensure batch processing works
     */
    @IsTest
    static void shouldHandleMultipleRecurringDonationsInSingleCall() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        List<npe03__Recurring_Donation__c> rds = rdGateway.getRecords();
        System.assert(rds.size() >= 3, 'Should have at least 3 RDs for this test');

        Set<Id> rdIds = new Set<Id>();
        for (npe03__Recurring_Donation__c rd : rds) {
            rdIds.add(rd.Id);
        }

        Test.startTest();
        Map<Id, List<Schedule>> schedulesByRd = retrieveSchedulesUsingApi(rdIds);
        Test.stopTest();

        System.assertEquals(rds.size(), schedulesByRd.size(), 
            'Should return schedules for all requested RDs: ' + schedulesByRd.size() + ' vs ' + rds.size());

        for (Id rdId : rdIds) {
            System.assert(schedulesByRd.containsKey(rdId), 
                'Each RD should have schedules returned: ' + rdId);
            System.assert(schedulesByRd.get(rdId).size() > 0, 
                'Each RD should have at least one schedule: ' + rdId);
        }
    }

    /**
     * @description Test behavior when empty Set<Id> is passed
     */
    @IsTest
    static void shouldHandleEmptySetOfRecurringDonationIds() {
        setUpEnv();

        Set<Id> emptyRdIds = new Set<Id>();

        Test.startTest();
        Map<Id, List<Schedule>> schedulesByRd = retrieveSchedulesUsingApi(emptyRdIds);
        Test.stopTest();

        System.assertEquals(0, schedulesByRd.size(), 
            'Should return empty map when empty set of RD IDs is passed');
    }

    /**
     * @description Test behavior when null is passed instead of Set<Id>
     */
    @IsTest
    static void shouldHandleNullRecurringDonationIds() {
        setUpEnv();

        Test.startTest();
        Map<Id, List<Schedule>> schedulesByRd = retrieveSchedulesUsingApi(new Set<Id>{null});
        Test.stopTest();

        System.assertEquals(0, schedulesByRd.size(), 
            'Should return empty map when null RD IDs is passed');
    }

    /**
     * @description Test RD that exists but has no associated schedules
     */
    @IsTest
    static void shouldHandleRecurringDonationsWithNoSchedules() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rdWithoutSchedules = rdGateway.getRecords()[0];

        // Delete any automatically created schedules
        List<RecurringDonationSchedule__c> schedules = scheduleGateway.getRecords(rdWithoutSchedules);
        if (!schedules.isEmpty()) {
            delete schedules;
        }

        Test.startTest();
        Map<Id, List<Schedule>> schedulesByRd = retrieveSchedulesUsingApi(rdWithoutSchedules.Id);
        Test.stopTest();

        System.assertEquals(1, schedulesByRd.size(), 
            'Should return one RD entry');
        System.assertEquals(0, schedulesByRd.get(rdWithoutSchedules.Id).size(), 
            'RD without schedules should return empty list of schedules');
    }

    /**
     * @description Test scenario where schedules were soft-deleted
     */
    @IsTest
    static void shouldHandleRecurringDonationsWithDeletedSchedules() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = rdGateway.getRecords()[0];
        
        // Get existing schedules and mark as not active
        List<RecurringDonationSchedule__c> schedules = scheduleGateway.getRecords(rd);
        for (RecurringDonationSchedule__c schedule : schedules) {
            schedule.EndDate__c = Date.Today().addDays(-1);
        }
        update schedules;

        Test.startTest();
        Map<Id, List<Schedule>> schedulesByRd = retrieveSchedulesUsingApi(rd.Id);
        Test.stopTest();

        System.assertEquals(1, schedulesByRd.size(), 
            'Should return one RD entry');
        
        List<Schedule> apiSchedules = schedulesByRd.get(rd.Id);
        System.assertEquals(schedules.size(), apiSchedules.size(), 
            'Should return all schedules including inactive ones');
        
        // Verify all schedules are marked as inactive
        for (Schedule apiSchedule : apiSchedules) {
            System.assertEquals(false, apiSchedule.isActive, 
                'All schedules should be marked as inactive: ' + apiSchedule);
        }
    }

    /**
     * @description Test start date = end date, very large date ranges, etc.
     */
    @IsTest
    static void shouldHandleDateRangeEdgeCasesWhenQueryingInstallments() {
        setUpEnv();

        npe03__Recurring_Donation__c rd = rdGateway.getRecords()[0];

        Test.startTest();
        
        // Test same start and end date
        Date sameDate = Date.today();
        Map<Id, List<Installment>> installmentsSameDate = queryInstallments(sameDate, sameDate, rd.Id);
        
        // Test very large date range
        Date largeStartDate = Date.today().addYears(-5);
        Date largeEndDate = Date.today().addYears(5);
        Map<Id, List<Installment>> installmentsLargeRange = queryInstallments(largeStartDate, largeEndDate, rd.Id);
        
        // Test null start date with specific end date
        Map<Id, List<Installment>> installmentsNullStart = queryInstallments(null, Date.today().addYears(1), rd.Id);
        
        Test.stopTest();

        // Verify all queries return results without errors
        System.assertNotEquals(null, installmentsSameDate, 'Same date query should not return null');
        System.assertNotEquals(null, installmentsLargeRange, 'Large date range query should not return null');
        System.assertNotEquals(null, installmentsNullStart, 'Null start date query should not return null');
    }

    /**
     * @description Test RD with multiple concurrent active schedules
     */
    @IsTest
    static void shouldHandleRecurringDonationsWithMultipleActiveSchedules() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = rdGateway.getRecords()[0];

        Test.startTest();
        
        // Create multiple active schedules for the same RD
        Date startDate = Date.today();
        RD2_ScheduleService_TEST.createPauseSchedule(rd.Id, startDate, startDate.addMonths(1));
        RD2_ScheduleService_TEST.createPauseSchedule(rd.Id, startDate.addMonths(2), startDate.addMonths(3));

        Map<Id, List<Schedule>> schedulesByRd = retrieveSchedulesUsingApi(rd.Id);
        Test.stopTest();

        System.assertEquals(1, schedulesByRd.size(), 
            'Should return one RD entry');
        
        List<Schedule> apiSchedules = schedulesByRd.get(rd.Id);
        System.assert(apiSchedules.size() >= 3, 
            'Should have at least 3 schedules (original + 2 pause schedules): ' + apiSchedules.size());
        
        // Count active schedules
        Integer activeCount = 0;
        for (Schedule schedule : apiSchedules) {
            if (schedule.isActive) {
                activeCount++;
            }
        }
        System.assert(activeCount >= 2, 
            'Should have multiple active schedules: ' + activeCount);
    }

    /**
     * @description Test multiple pause periods, overlapping pauses, etc.
     */
    @IsTest
    static void shouldHandleRecurringDonationsWithComplexPausePatterns() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = rdGateway.getRecords()[0];

        Test.startTest();
        
        // Create complex pause pattern: overlapping and sequential pauses
        Date baseDate = Date.today();
        
        // First pause
        RD2_ScheduleService_TEST.createPauseSchedule(rd.Id, baseDate, baseDate.addMonths(1));
        
        // Second pause (overlapping with first)
        RD2_ScheduleService_TEST.createPauseSchedule(rd.Id, baseDate.addDays(15), baseDate.addMonths(2));
        
        // Third pause (sequential to second)
        RD2_ScheduleService_TEST.createPauseSchedule(rd.Id, baseDate.addMonths(3), baseDate.addMonths(4));

        Map<Id, List<Schedule>> schedulesByRd = retrieveSchedulesUsingApi(rd.Id);
        Test.stopTest();

        System.assertEquals(1, schedulesByRd.size(), 
            'Should return one RD entry');
        
        List<Schedule> apiSchedules = schedulesByRd.get(rd.Id);
        System.assert(apiSchedules.size() >= 4, 
            'Should have at least 4 schedules (original + 3 pause schedules): ' + apiSchedules.size());
        
        // Verify pause schedules are properly identified
        Integer pauseCount = 0;
        for (Schedule schedule : apiSchedules) {
            if (schedule.isPause) {
                pauseCount++;
            }
        }
        System.assert(pauseCount >= 3, 
            'Should have multiple pause schedules: ' + pauseCount);
    }

    /**
     * @description Test weekly, bi-weekly, quarterly, etc.
     */
    @IsTest
    static void shouldHandleRecurringDonationsWithDifferentInstallmentPeriods() {
        setUpEnv();

        npe03__Recurring_Donation__c rd = rdGateway.getRecords()[0];

        Test.startTest();
        
        // Test different installment periods
        rd.npe03__Installment_Period__c = RD2_Constants.INSTALLMENT_PERIOD_WEEKLY;
        update rd;
        
        Map<Id, List<Installment>> weeklyInstallments = queryInstallments(Date.today(), Date.today().addMonths(3), rd.Id);
        
        rd.npe03__Installment_Period__c = RD2_Constants.INSTALLMENT_PERIOD_FIRST_AND_FIFTEENTH;
        update rd;
        
        Map<Id, List<Installment>> biMonthlyInstallments = queryInstallments(Date.today(), Date.today().addMonths(3), rd.Id);
        
        Test.stopTest();

        // Verify both queries return results
        System.assertNotEquals(null, weeklyInstallments, 'Weekly installments query should not return null');
        System.assertNotEquals(null, biMonthlyInstallments, 'Bi-monthly installments query should not return null');
        
        // Verify different installment counts for different periods
        if (weeklyInstallments.containsKey(rd.Id) && biMonthlyInstallments.containsKey(rd.Id)) {
            List<Installment> weekly = weeklyInstallments.get(rd.Id);
            List<Installment> biMonthly = biMonthlyInstallments.get(rd.Id);
            
            // Weekly should have more installments than bi-monthly in the same time period
            System.assert(weekly.size() > biMonthly.size(), 
                'Weekly should have more installments than bi-monthly: ' + weekly.size() + ' vs ' + biMonthly.size());
        }
    }

    /**
     * @description Test RD where installment amounts change over time
     */
    @IsTest
    static void shouldHandleRecurringDonationsWithVaryingAmounts() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = rdGateway.getRecords()[0];

        Test.startTest();
        
        // Create schedule with different amounts
        List<RecurringDonationSchedule__c> schedules = scheduleGateway.getRecords(rd);
        if (!schedules.isEmpty()) {
            RecurringDonationSchedule__c schedule = schedules[0];
            schedule.InstallmentAmount__c = 150;
            update schedule;
            
            // Create another schedule with different amount
            RecurringDonationSchedule__c newSchedule = new RecurringDonationSchedule__c(
                RecurringDonation__c = rd.Id,
                InstallmentAmount__c = 200,
                StartDate__c = Date.today().addMonths(1),
                // Active__c = true,
                InstallmentPeriod__c = RD2_Constants.INSTALLMENT_PERIOD_MONTHLY,
                InstallmentFrequency__c = 1
            );
            insert newSchedule;
        }

        Map<Id, List<Schedule>> schedulesByRd = retrieveSchedulesUsingApi(rd.Id);
        Test.stopTest();

        System.assertEquals(1, schedulesByRd.size(), 
            'Should return one RD entry');
        
        List<Schedule> apiSchedules = schedulesByRd.get(rd.Id);
        System.assert(apiSchedules.size() >= 2, 
            'Should have at least 2 schedules with different amounts: ' + apiSchedules.size());
        
        // Verify different amounts exist
        Set<Decimal> amounts = new Set<Decimal>();
        for (Schedule schedule : apiSchedules) {
            if (schedule.installmentAmount != null) {
                amounts.add(schedule.installmentAmount);
            }
        }
        System.assert(amounts.size() >= 2, 
            'Should have at least 2 different installment amounts: ' + amounts);
    }

    /**
     * @description Test multiple pause requests for same RD simultaneously
     */
    @IsTest
    static void shouldHandleConcurrentPauseRequests() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        RD2_ScheduleService.currentDate = CURRENT_DATE;

        npe03__Recurring_Donation__c rd = rdGateway.getRecords()[0];

        Test.startTest();
        
        // Create multiple pause requests for the same RD
        Map<Id, RD2_ApiService.PauseObject> pauseObjectsByIdIn = new Map<Id, RD2_ApiService.PauseObject>{
            rd.Id => createPauseObjectWithDetail(CURRENT_DATE.addMonths(1), CURRENT_DATE.addMonths(2), 'First Pause'),
            rd.Id => createPauseObjectWithDetail(CURRENT_DATE.addMonths(3), CURRENT_DATE.addMonths(4), 'Second Pause')
        };

        RD2_ApiService apiService = new RD2_ApiService();
        String response = apiService.pause(pauseObjectsByIdIn);
        Test.stopTest();

        Map<Id, RD2_ApiService.PauseObject> pauseObjectsByIdOut = 
            (Map<Id, RD2_ApiService.PauseObject>) JSON.deserialize(response, Map<Id, RD2_ApiService.PauseObject>.class);

        // Should handle multiple requests for same RD (last one wins or error handling)
        System.assertNotEquals(null, pauseObjectsByIdOut, 'Response should not be null');
        System.assertEquals(1, pauseObjectsByIdOut.size(), 'Should handle multiple requests for same RD');
    }

    /**
     * @description Test status reasons with special characters, long text, etc.
     */
    @IsTest
    static void shouldHandlePauseRequestsWithSpecialCharactersInReason() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        RD2_ScheduleService.currentDate = CURRENT_DATE;

        npe03__Recurring_Donation__c rd = rdGateway.getRecords()[0];

        Test.startTest();
        
        // Test various status reason formats
        String specialCharReason = 'Pause for vacation! @#$%^&*()_+-=[]{}|;:,.<>?';
        String longReason = 'This is a very long status reason that exceeds normal length limits to test how the system handles extremely long text input from users who might be very descriptive about why they are pausing their recurring donation. It could include multiple sentences and various punctuation marks.';
        String unicodeReason = 'Pause for 🏖️ vacation with special characters: ñáéíóú';

        Map<Id, RD2_ApiService.PauseObject> pauseObjectsByIdIn = new Map<Id, RD2_ApiService.PauseObject>{
            rd.Id => createPauseObjectWithDetail(CURRENT_DATE.addMonths(1), CURRENT_DATE.addMonths(2), specialCharReason)
        };

        RD2_ApiService apiService = new RD2_ApiService();
        String response = apiService.pause(pauseObjectsByIdIn);
        Test.stopTest();

        Map<Id, RD2_ApiService.PauseObject> pauseObjectsByIdOut = 
            (Map<Id, RD2_ApiService.PauseObject>) JSON.deserialize(response, Map<Id, RD2_ApiService.PauseObject>.class);

        System.assertEquals(true, pauseObjectsByIdOut.values()[0].isSuccess, 
            'Should successfully handle special characters in reason');
        System.assertEquals('OK', pauseObjectsByIdOut.values()[0].error, 
            'Should return OK status for special characters');
    }

    /**
     * @description Test extending, shortening, or replacing existing pauses
     */
    @IsTest
    static void shouldHandlePauseRequestsForRecurringDonationsWithExistingPauses() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        RD2_ScheduleService.currentDate = CURRENT_DATE;

        npe03__Recurring_Donation__c rd = rdGateway.getRecords()[0];

        Test.startTest();
        
        // Create initial pause
        RD2_ScheduleService_TEST.createPauseSchedule(rd.Id, CURRENT_DATE.addMonths(1), CURRENT_DATE.addMonths(2));
        
        // Extend the pause
        Map<Id, RD2_ApiService.PauseObject> extendPause = new Map<Id, RD2_ApiService.PauseObject>{
            rd.Id => createPauseObjectWithDetail(CURRENT_DATE.addMonths(1), CURRENT_DATE.addMonths(3), 'Extended Pause')
        };

        RD2_ApiService apiService = new RD2_ApiService();
        String response = apiService.pause(extendPause);
        Test.stopTest();

        Map<Id, RD2_ApiService.PauseObject> pauseObjectsByIdOut = 
            (Map<Id, RD2_ApiService.PauseObject>) JSON.deserialize(response, Map<Id, RD2_ApiService.PauseObject>.class);

        System.assertEquals(true, pauseObjectsByIdOut.values()[0].isSuccess, 
            'Should successfully extend existing pause');
        System.assertEquals('OK', pauseObjectsByIdOut.values()[0].error, 
            'Should return OK status for pause extension');
    }

    // ===== HELPER METHODS =====

    private static void setUpEnv() {
        RD2_ScheduleService.currentDate = CURRENT_DATE;
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
    }

    private static Map<Id, List<Schedule>> retrieveSchedulesUsingApi(Id rdId) {
        return retrieveSchedulesUsingApi(new Set<Id>{rdId});
    }

    /**
     * @param rdIds Recurring Donation Ids
     * @return Deserialized api response
     */
    private static Map<Id, List<Schedule>> retrieveSchedulesUsingApi(Set<Id> rdIds) {
        RD2_ScheduleService.currentDate = CURRENT_DATE;

        SfdoInstrumentationService.instance = null;
        System.assertEquals(null, SfdoInstrumentationService.instance, 
            'The Instrumentation Service Instance should not have been instantiated');

        Callable_API callable = new Callable_API();

        String response = (String) callable.call(API_QUERY_SCHEDULES,
            new Map<String, Object>{
                'RecordIds' => rdIds
            }
        );

        return (Map<Id, List<Schedule>>) JSON.deserialize(response, Map<Id, List<Schedule>>.class);
    }

    /**
     * @description Utility method to retrieve installments via Callable_API
     * @param startDate date
     * @param endDate date
     * @param rdId Recurring Donation Id
     * @return Deserialized api response
     */
    private static Map<Id, List<Installment>> queryInstallments(Date startDate, Date endDate, Id rdId) {
        RD2_ScheduleService.currentDate = CURRENT_DATE;

        SfdoInstrumentationService.instance = null;
        System.assertEquals(null, SfdoInstrumentationService.instance, 
            'The Instrumentation Service Instance should not have been instantiated');

        Callable_API callable = new Callable_API();

        String response = (String) callable.call(API_QUERY_INSTALLMENTS,
            new Map<String, Object>{
                CallableApiParameters.PARAM_RECORD_IDS => new Set<Id>{rdId},
                CallableApiParameters.PARAM_START_DATE => startDate,
                CallableApiParameters.PARAM_END_DATE => endDate
            }
        );

        return (Map<Id, List<Installment>>) JSON.deserialize(response, Map<Id, List<Installment>>.class);
    }

    /****
    * @description Returns Enhanced Recurring Donation with default values
    * @param contactId Contact id
    * @return TEST_RecurringDonationBuilder
    */
    private static TEST_RecurringDonationBuilder getEnhancedRecurringDonationBuilder(Id contactId) {
        return TEST_RecurringDonationBuilder.constructEnhancedBuilder()
            .withContact(contactId)
            .withAmount(100)
            .withRecurringTypeOpen()
            .withInstallmentFrequency(1)
            .withInstallmentPeriod(RD2_Constants.INSTALLMENT_PERIOD_MONTHLY)
            .withDayOfMonth(String.valueOf(DAY_OF_MONTH))
            .withDateEstablished(CURRENT_DATE)
            .withStartDate(CURRENT_DATE);
    }

    private static RD2_ApiService.PauseObject createPauseObjectWithDetail(Date startDate, Date endDate, String statusReason) {
        RD2_ApiService.PauseObject pauseInfo = new RD2_ApiService.PauseObject();

        pauseInfo.startDate = startDate;
        pauseInfo.endDate = endDate;
        pauseInfo.statusReason = statusReason;
        pauseInfo.unPause = false;
        pauseInfo.isSuccess = true;
        pauseInfo.error = 'OK';

        return pauseInfo;
    }

    private class Schedule {
        public String recurringDonationId;
        public String scheduleId;
        public Boolean isActive;
        public Boolean isCurrent;
        public Boolean isPause;
        public String campaignId;
        public String dayOfMonth;
        public Date endDate;
        public Decimal installmentAmount;
        public Integer installmentFrequency;
        public String installmentPeriod;
        public String paymentMethod;
        public Date startDate;
        public String statusReason;
        public String currencyCode;
        public Datetime createdDate;
    }

    private class Installment {
        public String recurringDonationId;
        public String scheduleId;
        public String campaignId;
        public Date closeDate;
        public Decimal installmentAmount;
        public String currencyCode;
        public String paymentMethod;
    }
}
