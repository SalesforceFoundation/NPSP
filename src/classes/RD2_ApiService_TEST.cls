/*
    Copyright (c) 2020 Salesforce.org
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
* @date 2020
* @group Recurring Donations
* @description Unit Tests specific to Enhanced Recurring Donation Api's
*
*/
@IsTest(IsParallel=false)
private class RD2_ApiService_TEST {

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

        insert getEnhancedRecurringDonationBuilder(contact.Id)
            .build();
    }


    /**
     * @description Validate the correct schedules response from rd2.queryschedules api call
     */
    @isTest
    static void shouldReturnValidSerializedSchedules() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = rdGateway.getRecords()[0];

        Test.startTest();
        // Update the period to be 1st&15th starting in two months
        rd.npe03__Installment_Period__c = RD2_Constants.INSTALLMENT_PERIOD_FIRST_AND_FIFTEENTH;
        rd.StartDate__c = Date.today().addMonths(2).toStartOfMonth();
        update rd;

        List<RecurringDonationSchedule__c> schedules = scheduleGateway.getRecords(rd);
        System.assertEquals(3, schedules.size(), 'Actual schedules should match: ' + schedules);

        Map<Id, List<Schedule>> schedulesByRd = retrieveSchedulesUsingApi(rd.Id);
        Test.stopTest();

        System.assertEquals(1, schedulesByRd.size(), 'One RD should be returned: ' + schedulesByRd);

        List<RD2_ApiService_TEST.Schedule> apiSchedules = schedulesByRd.get(rd.Id);
        System.assertEquals(3, apiSchedules.size(), 'Number of API returned schedules should match: ' + apiSchedules);

        Integer currentCount = 0;
        for (Schedule s : apiSchedules) {
            System.assertEquals(true, s.isActive, 'Every schedule should be active: ' + s);

            if (s.isCurrent) {
                currentCount++;
            }
        }

        System.assertEquals(1, currentCount, 'There should be one current schedule: ' + apiSchedules);
    }

    /**
     * @description Validate the correct schedules response from rd2.queryschedules api call
     */
    @isTest
    static void shouldReturnEmptySerializedSchedulesWithInvalidRdId() {
        setUpEnv();

        Map<Id, List<Schedule>> schedulesByRd = retrieveSchedulesUsingApi(RD_MOCK_ID);

        System.assertEquals(0, schedulesByRd.size(), 'There should be no recurring donation records returned');
    }

    /**
     * @description Validate an exception thrown if the RecordIds parameter is missing in the api call
     */
    @isTest
    static void shouldReturnEmptySerializedSchedulesWithMissingParameter() {
        setUpEnv();

        Callable_API callable = new Callable_API();
        Exception actualException;
        try {
            String response = (String) callable.call(API_QUERY_SCHEDULES,
                new Map<String, Object>{
                    'Bad_Parameter' => new Set<Id>{ RD_MOCK_ID }
                }
            );
        } catch (Exception e) {
            actualException = e;
        }
        System.assertNotEquals(null, actualException, 'An exception should have been thrown for a missing parameter');
        System.assert(actualException.getMessage().contains(CallableApiParameters.PARAM_RECORD_IDS),
            'The exception should reference the missing parameter by name');
    }

    /**
     * @description Validate an exception thrown if the RecordIds parameter contains a non Set<Id> value
     */
    @isTest
    static void shouldReturnEmptySerializedSchedulesWithInvalidParameter() {
        setUpEnv();

        Callable_API callable = new Callable_API();
        Exception actualException;
        try {
            String response = (String) callable.call(API_QUERY_SCHEDULES,
                new Map<String, Object>{
                    CallableApiParameters.PARAM_RECORD_IDS => RD_MOCK_ID
                }
            );
        } catch (Exception e) {
            actualException = e;
        }

        System.assertNotEquals(null, actualException, 'An exception should have been thrown for a missing parameter');
        System.assert(actualException.getMessage().contains(CallableApiParameters.PARAM_RECORD_IDS),
            'The exception should reference the missing parameter by name');
    }

    /**
     * @description Validate an empty schedule response from the rd2.queryschedules API call
     * when RD2 is not enabled
     */
    @isTest
    static void shouldReturnEmptyResponseWhenRd2NotEnabled() {
        npe03__Recurring_Donation__c rd = rdGateway.getRecords()[0];

        Test.startTest();
        Map<Id, List<Schedule>> schedulesByRd = retrieveSchedulesUsingApi(rd.Id);
        Test.stopTest();

        System.assertEquals(0, schedulesByRd.size(), 'There should be nothing returned when RD2 is not enabled');
    }

    /**
     * @description Validate a Paused RD returns the expected api response with active/paused/inactive
     * schedules when the pause is current as of today
     */
    @IsTest
    private static void shouldReturnValidResponseWithActivePausedRd() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = rdGateway.getRecords()[0];

        Test.startTest();
        Date startDate = Date.today();
        RD2_ScheduleService_TEST.createPauseSchedule(rd.Id, startDate, startDate.addMonths(2));

        System.assertEquals(2,scheduleGateway.getRecords(rd).size(), 'There should be two schedule records returned');

        Map<Id, List<Schedule>> schedulesByRd = retrieveSchedulesUsingApi(rd.Id);
        Test.stopTest();

        System.assertEquals(1,schedulesByRd.size(), 'There should be one recurring donation records returned');
        System.assertEquals(2,schedulesByRd.get(rd.Id).size(), 'There should be two schedule records on the rd returned');

        Integer inactiveCount = 0;
        Integer activePausedCount = 0;
        Integer activeNotPausedCount = 0;

        for (Schedule s : schedulesByRd.get(rd.Id)) {
            if (s.isActive && s.isPause) {
                activePausedCount++;

            } else if (s.isActive && !s.isPause) {
                activeNotPausedCount++;

            } else if (!s.isActive) {
                inactiveCount++;
            }
        }

        System.assertEquals(1, activePausedCount, 'There should be one active paused schedules returned');
        System.assertEquals(1, activeNotPausedCount, 'There should be one active not paused schedules returned');
        System.assertEquals(0, inactiveCount, 'There should be zero in-active schedules returned');
    }


    /**
     * @description Validate a Paused RD returns the expected api response with
     * active/paused/inactive schedules when the pause is in the future
     */
    @IsTest
    private static void shouldReturnValidResponseWithFuturePausedRd() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = rdGateway.getRecords()[0];

        Test.startTest();
        Date startDate = Date.today();
        RD2_ScheduleService_TEST.createPauseSchedule(rd.Id, startDate.addMonths(1), startDate.addMonths(2));

        System.assertEquals(2,scheduleGateway.getRecords(rd).size(), 'There should be two schedule records returned');

        Map<Id, List<Schedule>> schedulesByRd = retrieveSchedulesUsingApi(rd.Id);
        Test.stopTest();

        System.assertEquals(1,schedulesByRd.size(), 'There should be one recurring donation records returned');
        System.assertEquals(2,schedulesByRd.get(rd.Id).size(), 'There should be two schedule records on the rd returned');

        Integer isActiveNotCurrentPaused = 0;
        Integer isActiveCurrentPausedCount = 0;
        Integer isActiveCurrentNotPaused = 0;
        
        for (Schedule s : schedulesByRd.get(rd.Id)) {
            if (s.isActive && s.isPause && s.isCurrent) {
                isActiveCurrentPausedCount++;

            } else if (s.isActive && s.isCurrent && !s.isPause) {
                isActiveCurrentNotPaused++;

            } else if (s.isActive && s.isPause) {
                isActiveNotCurrentPaused++;
            }
        }

        System.assertEquals(0, isActiveCurrentPausedCount, 'There should be no current paused schedules returned');
        System.assertEquals(1, isActiveNotCurrentPaused, 'There should be one active not current paused schedules returned');
        System.assertEquals(1, isActiveCurrentNotPaused, 'There should be one active and current unpaused schedules returned');
    }

    /**
     * @description Validate an empty installment response when RD2 is not enabled
     */
    @IsTest
    private static void shouldReturnNoInstallmentsWhenRD2NotEnabled() {
        RD2_ScheduleService.currentDate = CURRENT_DATE;

        npe03__Recurring_Donation__c rd = rdGateway.getRecords()[0];

        Map<Id, List<Installment>> installmentsByRd = queryInstallments(
            START_DATE, START_DATE.addYears(2), rd.Id
        );

        System.assertEquals(0, installmentsByRd.size(),
            'There should be no recurring donation installments returned when RD2 is not enabled');
    }

    /**
     * @description Validate an empty installment response when invalid RD Id is passed in
     */
    @IsTest
    private static void shouldReturnNoInstallmentsWithInvalidRDId() {
        setUpEnv();

        Date endDate = START_DATE.addYears(2);
        Map<Id, List<Installment>> installmentsByRd = queryInstallments(START_DATE, endDate, RD_MOCK_ID);

        System.assertEquals(0, installmentsByRd.size(),
            'There should be no recurring donation installments returned when RD Id is invalid');
    }

    /**
     * @description Validate an empty installment response when empty RD Id set is passed in
     */
    @IsTest
    private static void shouldReturnNoInstallmentsWithEmptyRDIdSet() {
        setUpEnv();

        Date endDate = START_DATE.addYears(2);
        Map<Id, List<Installment>> installmentsByRd = queryInstallments(START_DATE, endDate, null);

        System.assertEquals(0, installmentsByRd.size(),
            'There should be no recurring donation installments returned when RD Id Set is empty');
    }

    /**
     * @description Validate a valid installment response when start date is not passed in
     */
    @IsTest
    private static void shouldReturnValidInstallmentsWithDefaultStartDate() {
        setUpEnv();

        final Integer installmentCount = 24;
        npe03__Recurring_Donation__c rd = rdGateway.getRecords()[0];

        Date endDate = START_DATE.addYears(2).addDays(-1);
        Map<Id, List<Installment>> installmentsByRd = queryInstallments(null, endDate, rd.Id);

        System.assertEquals(installmentCount, installmentsByRd.get(rd.Id).size(),
            'With default start date, ' + installmentCount + ' Recurring donation installments should be returned');
    }

    /**
     * @description Validate a valid installment response when End Date is missing
     */
    @IsTest
    private static void shouldReturnOneYearOfInstallmentsWithMissingEndDate() {
        setUpEnv();
        
        final Integer installmentCount = 12;
        npe03__Recurring_Donation__c rd = rdGateway.getRecords()[0];

        Map<Id, List<Installment>> installmentsByRd = queryInstallments(START_DATE, null, rd.Id);

        System.assertEquals(installmentCount, installmentsByRd.get(rd.Id).size(),
            'Number of installments should match when end date is default: ' + installmentsByRd.values());
    }

    /**
     * @description Validate a valid installment response when default dates are used
     */
    @IsTest
    private static void shouldReturnValidInstallmentsWithDefaultStartDateAndEndDate() {
        setUpEnv();

        final Integer installmentCount = 12;
        npe03__Recurring_Donation__c rd = rdGateway.getRecords()[0];

        Map<Id, List<Installment>> installmentsByRd = queryInstallments(null, null, rd.Id);

        System.assertEquals(installmentCount, installmentsByRd.get(rd.Id).size(),
            'Number of installments should match when start and end date are default: ' + installmentsByRd.values());
    }

    /**
     * @description Validate a valid installment response when valid parameters passed in
     */
    @IsTest
    private static void shouldReturnValidInstallmentsWhenPauseScheduleIsActive() {
        final Integer unpausedCount = 25;
        final Integer pausedCount = 22;
        final Date startDate = Date.newInstance(2018, 11, 1);
        final Date endDate = Date.newInstance(2020, 11, 1);
        final Date pauseStart = Date.newInstance(2019, 12, 1);
        final Date pauseEnd = Date.newInstance(2020, 2, 1);

        setUpEnv();
        npe03__Recurring_Donation__c rd = rdGateway.getRecords()[0];

        Test.startTest();
        rd.npe03__Date_Established__c = startDate;
        rd.StartDate__c = startDate;
        update rd;
        Test.stopTest();

        Map<Id, List<Installment>> installmentsByRd = queryInstallments(
            startDate,
            endDate,
            rd.Id);
        System.assertEquals(unpausedCount, installmentsByRd.get(rd.Id).size(),
            unpausedCount + ' Recurring donation installments should be returned when there is no pause schedule');

        RD2_ScheduleService_TEST.createPauseSchedule(rd.Id, pauseStart, pauseEnd);
        installmentsByRd = queryInstallments(startDate, endDate, rd.Id);

        System.assertEquals(pausedCount, installmentsByRd.get(rd.Id).size(),
            pausedCount + ' Recurring donation installments should be returned when there is a three month pause');
    }


    //// Helpers
    //////////////////////////

    private static void setUpEnv() {
        RD2_ScheduleService.currentDate = CURRENT_DATE;

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
    }


    /**
     * @param rdId Recurring Donation Id
     * @return Deserialized api response
     */
    private static Map<Id, List<Schedule>> retrieveSchedulesUsingApi(Id rdId) {
        RD2_ScheduleService.currentDate = CURRENT_DATE;

        Callable_API callable = new Callable_API();

        String response = (String) callable.call(API_QUERY_SCHEDULES,
            new Map<String, Object>{
                'RecordIds' => new Set<Id>{
                    rdId
                }
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