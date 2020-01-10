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
* @description Unit tests for the Enhanced RD Opportunity Evaluation Batch Job
*
*/
@IsTest(IsParallel=true)
private class RD2_OpportunityEvaluation_TEST {
    private static final TEST_SObjectGateway.RecurringDonationGateway rdGateway = new TEST_SObjectGateway.RecurringDonationGateway();
    private static final TEST_SObjectGateway.RecurringDonationScheduleGateway scheduleGateway = new TEST_SObjectGateway.RecurringDonationScheduleGateway();
    private static final TEST_SObjectGateway.OpportunityGateway oppGateway = new TEST_SObjectGateway.OpportunityGateway();
    private static final TEST_SObjectGateway.AsyncApexJobGateway jobGateway = new TEST_SObjectGateway.AsyncApexJobGateway();
    private static final TEST_SObjectGateway.ErrorGateway errorGateway = new TEST_SObjectGateway.ErrorGateway();

    private static final Date START_DATE = Date.newInstance(2019, 9, 15);

    public static final Integer MIGRATION_INSTALLMENT_NUMBER_FLAG = RD2_OpportunityService.MIGRATION_INSTALLMENT_NUMBER_FLAG;

    /****
    * @description Creates data required for unit tests
    */
    @TestSetup
    private static void setUp() {
        insert UTIL_UnitTestData_TEST.getContact();
    }

    /**
     * @description Verify that when Enhanced RD is NOT enabled in an org, attempting to execute the new RD2 batch
     * job throws an exception
     */
    @IsTest
    private static void shouldThrowExceptionForEnhancedRDJobIfEnhancedRDIsNotEnabled() {        
        Exception actuaException = runBatch(new RD2_OpportunityEvaluation_BATCH());

        System.assertNotEquals(null, actuaException, 'An exception should have been thrown because Enhanced RD is not enabled');
        System.assert(actuaException.getMessage().containsIgnoreCase(System.Label.RD2_ErrorEnhancedRDBatchJobCannotBeRun),
            'The job cannot be executed because Enhanced RD is not enabled: ' + actuaException.getMessage());
    }

    /**
     * @description Verify that when RD2 is enabled in an org, executing the new Enhanced RD batch job does not
     * throw an exception
     */
    @IsTest
    private static void shouldNotThrowExceptionForEnhancedRDJobIfEnhancedRDIsEnabled() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        Exception actuaException = runBatch(new RD2_OpportunityEvaluation_BATCH());

        System.assertEquals(null, actuaException, 'No exception is expected because Enhanced RD is enabled');
    }

    /**
     * @description Verify that when Enhanced RD is NOT enabled in an org, executing the new Legacy RD
     * batch job does not throw an exception
     */
    @IsTest
    private static void shouldNotThrowExceptionForLegacyRDJobIfEnhancedRDIsNotEnabled() {
        Exception actuaException = runBatch(new RD_RecurringDonations_BATCH());

        System.assertEquals(null, actuaException, 'An exception is expected because Enhanced RD is not enabled');
    }

    /**
     * @description Verifies closed Recurring Donations are not processed in the Opp evaluation batch
     */
    @IsTest
    private static void shouldNotProcessClosedRDs() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder()
            .withStatusClosed()
            .build();
        insert rd;

        runBatch(new RD2_OpportunityEvaluation_BATCH());

        assertBatchJobIteration(0);
    }

    /**
     * @description Verifies an Opp with Close Date today is not created if it already exists
     */
    @IsTest
    private static void shouldNotCreateDuplicateOppWhenNextCloseDateIsToday() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        final Date today = START_DATE.addMonths(1);
        RD2_ScheduleService.currentDate = today;

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder().build();
        insert rd;

        insert getOpportunityBuilder(rd)
            .withOpenStage()
            .withCloseDate(today)
            .build();
        
        List<Opportunity> opps = oppGateway.getRecords(rd);
        System.assertEquals(1, opps.size(), 'An Opp should exist: ' + opps);

        runBatch(new RD2_OpportunityEvaluation_BATCH(today));

        assertBatchJobIteration(1);

        opps = oppGateway.getRecords(rd);
        System.assertEquals(1, opps.size(), 'No new Opp should be created: ' + opps);
        System.assertEquals(today, opps[0].CloseDate, 'Close Date should be unchanged: ' + opps);
    }

    /**
     * @description Verifies an Opp with Close Date in future is not created if it already exists
     */
    @IsTest
    private static void shouldNotCreateDuplicateOppWhenNextCloseDateIsInFuture() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        final Date today = START_DATE.addMonths(1).addDays(1);
        final Date nextCloseDate = START_DATE.addMonths(2);
        RD2_ScheduleService.currentDate = today;

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder().build();
        insert rd;

        insert getOpportunityBuilder(rd)
            .withOpenStage()
            .withCloseDate(nextCloseDate)
            .build();
        
        List<Opportunity> opps = oppGateway.getRecords(rd);
        System.assertEquals(1, opps.size(), 'An Opp should exist: ' + opps);

        runBatch(new RD2_OpportunityEvaluation_BATCH(today));

        assertBatchJobIteration(1);

        opps = oppGateway.getRecords(rd);
        System.assertEquals(1, opps.size(), 'No new Opp should be created: ' + opps);
        System.assertEquals(nextCloseDate, opps[0].CloseDate, 'Close Date should be unchanged: ' + opps);
    }

    /**
     * @description Verifies an Opp with Close Date equal to today is created if it already does not exist
     */
    @IsTest
    private static void shouldCreateNextOppWhenCloseDateIsToday() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        final Date prevCloseDate = START_DATE.addMonths(1);
        final Date today = START_DATE.addMonths(2);
        RD2_ScheduleService.currentDate = today;

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder().build();
        insert rd;

        insert getOpportunityBuilder(rd)
            .withClosedWonStage()
            .withCloseDate(prevCloseDate)
            .build();
        
        List<Opportunity> opps = oppGateway.getRecords(rd);
        System.assertEquals(1, opps.size(), 'An Opp should exist: ' + opps);

        runBatch(new RD2_OpportunityEvaluation_BATCH(today));

        Map<Id, Opportunity> oppById = new Map<Id, Opportunity>(oppGateway.getRecords(rd));
        System.assertEquals(2, oppById.size(), 'New Opp should be created: ' + oppById.values());

        System.assertEquals(prevCloseDate, oppById.remove(opps[0].Id).CloseDate, 
            'Close Date should be unchanged for the existing Opp');
        System.assertEquals(today, oppById.values()[0].CloseDate, 
            'Close Date on the new Opp should match next Close Date');
    }

    /**
     * @description Verifies an Opp with Close Date equal to the Recurring Donation Next Donation Date is created
     */
    @IsTest
    private static void shouldCreateNextOppWhenCloseDateIsInFuture() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        final Date prevCloseDate = START_DATE.addMonths(1);
        final Date today = prevCloseDate.addDays(1);
        final Date nextCloseDate = START_DATE.addMonths(2);
        RD2_ScheduleService.currentDate = today;

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder().build();
        insert rd;

        insert getOpportunityBuilder(rd)
            .withOpenStage()
            .withCloseDate(prevCloseDate)
            .build();
        
        List<Opportunity> opps = oppGateway.getRecords(rd);
        System.assertEquals(1, opps.size(), 'An Opp should exist: ' + opps);

        runBatch(new RD2_OpportunityEvaluation_BATCH(today));

        Map<Id, Opportunity> oppById = new Map<Id, Opportunity>(oppGateway.getRecords(rd));
        System.assertEquals(2, oppById.size(), 'New Opp should be created: ' + oppById.values());

        System.assertEquals(prevCloseDate, oppById.remove(opps[0].Id).CloseDate, 
            'Close Date should be unchanged for the existing Opp');
        System.assertEquals(nextCloseDate, oppById.values()[0].CloseDate, 
            'Close Date on the new Opp should match next Close Date');
    }

    /**
     * @description Verifies an Opp with Close Date equal to the Recurring Donation Next Donation Date is created
     * when Installment Period is "1st and 15th"
     */
    @IsTest
    private static void shouldCreateNextOppWhenInstallmentPeriodIs1stAnd15th() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        final Date prevCloseDate = START_DATE.addMonths(1);
        final Date today = prevCloseDate.addDays(1);
        final Date nextCloseDate = START_DATE.addMonths(2).toStartOfMonth();
        RD2_ScheduleService.currentDate = today;

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder()
            .withInstallmentPeriod(RD2_Constants.INSTALLMENT_PERIOD_FIRST_AND_FIFTEENTH)
            .withDayOfMonth(null)
            .build();
        insert rd;

        insert getOpportunityBuilder(rd)
            .withClosedWonStage()
            .withCloseDate(prevCloseDate)
            .build();
        
        List<Opportunity> opps = oppGateway.getRecords(rd);
        System.assertEquals(1, opps.size(), 'An Opp should exist: ' + opps);

        runBatch(new RD2_OpportunityEvaluation_BATCH(today));

        Map<Id, Opportunity> oppById = new Map<Id, Opportunity>(oppGateway.getRecords(rd));
        System.assertEquals(2, oppById.size(), 'New Opp should be created: ' + oppById.values());

        System.assertEquals(prevCloseDate, oppById.remove(opps[0].Id).CloseDate, 
            'Close Date should be unchanged for the existing Opp');
        System.assertEquals(nextCloseDate, oppById.values()[0].CloseDate, 
            'Close Date on the new Opp should match next Close Date');
    }

    /**
     * @description Verifies an Opp is not created when next Close Date is the after RD Schedule End Date
     */
    @IsTest
    private static void shouldNotCreateNextOppWhenScheduleEndDateIsPassed() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        final Date today = START_DATE.addMonths(1).addDays(1);
        RD2_ScheduleService.currentDate = today;

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder().build();
        insert rd;
        
        List<RecurringDonationSchedule__c> rdSchedules = scheduleGateway.getRecords(rd);  
        System.assertEquals(1, rdSchedules.size(), 'An RD Schedule should exist: ' + rdSchedules);   

        //Set Schedule End Date to date before the next Close Date
        rdSchedules[0].EndDate__c = START_DATE.addMonths(2).addDays(-1);
        update rdSchedules[0];

        runBatch(new RD2_OpportunityEvaluation_BATCH(today));

        List<Opportunity> opps = oppGateway.getRecords(rd);
        System.assertEquals(0, opps.size(), 'No new Opp should be created: ' + opps);
    }

    /**
     * @description Verifies an Opp is created when next Close Date is the RD Schedule End Date
     */
    @IsTest
    private static void shouldCreateNextOppWhenScheduleEndDateIsNextCloseDate() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        final Date today = START_DATE.addMonths(1).addDays(1);
        RD2_ScheduleService.currentDate = today;

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder().build();
        insert rd;
        
        List<RecurringDonationSchedule__c> rdSchedules = scheduleGateway.getRecords(rd);  
        System.assertEquals(1, rdSchedules.size(), 'An RD Schedule should exist: ' + rdSchedules);   

        //Set Schedule End Date to the next Close Date
        rdSchedules[0].EndDate__c = START_DATE.addMonths(2);
        update rdSchedules[0];

        runBatch(new RD2_OpportunityEvaluation_BATCH(today));

        List<Opportunity> opps = oppGateway.getRecords(rd);
        System.assertEquals(1, opps.size(), 'A new Opportunity should be created: ' + opps);
        System.assertEquals(rdSchedules[0].EndDate__c, opps[0].CloseDate, 
            'Close Date on the new Opp should match next Close Date');
    }

    /**
     * @description Verifies RD Next Donation Date is updated when it is outdated and the new Opp is created
     */
    @IsTest
    private static void shouldCreateNextOppWhenRDNextDonationDateIsOutdated() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        final Date prevCloseDate = START_DATE;
        Date today = prevCloseDate.addDays(1);
        final Date nextDonationDate = prevCloseDate.addMonths(1);
        RD2_ScheduleService.currentDate = today;

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder().build();
        insert rd;

        insert getOpportunityBuilder(rd)
            .withOpenStage()
            .withCloseDate(prevCloseDate)
            .build();
        
        List<Opportunity> opps = oppGateway.getRecords(rd);
        System.assertEquals(1, opps.size(), 'An Opp should exist: ' + opps);

        rd = rdGateway.getRecord(rd.Id);
        System.assertEquals(nextDonationDate, rd.npe03__Next_Payment_Date__c, 'Next Donation Date should match');

        //Next Donation Date is outdated
        today = nextDonationDate.addDays(1);
        final Date nextCloseDate = nextDonationDate.addMonths(1);
        //need to set the Schedule Service current date due to other async jobs completing at Test.stopTest()
        RD2_ScheduleService.currentDate = today;

        runBatch(new RD2_OpportunityEvaluation_BATCH(today));

        rd = rdGateway.getRecord(rd.Id);
        System.assertEquals(nextCloseDate, rd.npe03__Next_Payment_Date__c, 'Next Donation Date should match');

        Map<Id, Opportunity> oppById = new Map<Id, Opportunity>(oppGateway.getRecords(rd));
        System.assertEquals(2, oppById.size(), 'New Opp should be created: ' + oppById.values());

        System.assertEquals(prevCloseDate, oppById.remove(opps[0].Id).CloseDate, 
            'Close Date should be unchanged for the existing Opp');
        System.assertEquals(nextCloseDate, oppById.values()[0].CloseDate, 
            'Close Date on the new Opp should match next Close Date after today');
    }

    /**
     * @description Verifies number of failed Opps is zero on Opp DML success
     */
    @IsTest
    private static void shouldReturnZeroRecordsFailedWhenOppDMLSucceeds() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        final Date today = START_DATE.addMonths(1).addDays(1);
        final Date nextCloseDate = START_DATE.addMonths(2);
        RD2_ScheduleService.currentDate = today;

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder().build();
        insert rd;

        RD2_OpportunityEvaluation_BATCH batch = executeAndFinishBatch(rd.Id, today);

        assertRecordsFailed(batch, 0);

        List<Opportunity> opps = oppGateway.getRecords(rd);
        System.assertEquals(1, opps.size(), 'A new Opportunity should be created: ' + opps);

        List<Error__c> errors = errorGateway.getRecords();
        System.assertEquals(0, errors.size(), 'No error should be created: ' + errors);
    }

    /**
     * @description Verifies number of failed Opps is tracked on Opp DML fail
     */
    @IsTest
    private static void shouldReturnRecordsFailedWhenOppDMLFails() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        configInvalidOppRecordTypeId();

        final Date today = START_DATE.addMonths(1).addDays(1);
        final Date nextCloseDate = START_DATE.addMonths(2);
        RD2_ScheduleService.currentDate = today;

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder().build();
        insert rd;

        RD2_OpportunityEvaluation_BATCH batch = executeAndFinishBatch(rd.Id, today);

        assertRecordsFailed(batch, 1);

        List<Opportunity> opps = oppGateway.getRecords(rd);
        System.assertEquals(0, opps.size(), 'No new Opp should be created: ' + opps);

        List<Error__c> errors = errorGateway.getRecords();
        System.assertEquals(1, errors.size(), 'An error should be created: ' + errors);
    }

    /**
     * @description Verifies an Opp with the next Close Date is created
     * when the same Close Date Opp is Closed Lost in data migration
     */
    @IsTest
    private static void shouldCreateNextOppWhenSameCloseDateOppIsClosedLostInMigration() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        final Date today = START_DATE.addDays(1);
        final Date nextCloseDate = START_DATE.addMonths(1);
        RD2_ScheduleService.currentDate = today;

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder().build();
        insert rd;

        insert getOpportunityBuilder(rd)
            .withInstallmentNumber(MIGRATION_INSTALLMENT_NUMBER_FLAG)
            .withClosedLostStage()
            .withCloseDate(nextCloseDate)
            .build();
        
        List<Opportunity> opps = oppGateway.getRecords(rd);
        System.assertEquals(1, opps.size(), 'An Opp should exist: ' + opps);

        runBatch(new RD2_OpportunityEvaluation_BATCH(today));

        Map<Id, Opportunity> oppById = new Map<Id, Opportunity>(oppGateway.getRecords(rd));
        System.assertEquals(2, oppById.size(), 'New Opp should be created: ' + oppById.values());

        for (Opportunity opp : oppById.values()) {
            System.assertEquals(nextCloseDate, opp.CloseDate, 'Both Opps should have the same next Close Date');

            if (opp.Id == opps[0].Id) {
                System.assertEquals(true, opp.isClosed && !opp.isWon, 'Existing Closed Lost Opp should stay closed');
            } else {
                System.assertEquals(false, opp.isClosed, 'New Opp should be open');
            }
        }
    }

    /**
     * @description Verifies an Opp with the next Close Date is not created
     * when the same Close Date Opp is Closed Lost outside of data migration
     */
    @IsTest
    private static void shouldNotCreateNextOppWhenSameCloseDateOppIsClosedLostOutsideMigration() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        final Date today = START_DATE.addDays(1);
        final Date nextCloseDate = START_DATE.addMonths(1);
        RD2_ScheduleService.currentDate = today;

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder().build();
        insert rd;

        insert getOpportunityBuilder(rd)
            .withClosedLostStage()
            .withCloseDate(nextCloseDate)
            .build();

        runBatch(new RD2_OpportunityEvaluation_BATCH(today));

        List<Opportunity> opps = oppGateway.getRecords(rd);
        System.assertEquals(1, opps.size(), 'No new Opp should be created: ' + opps);        
        System.assertEquals(true, opps[0].isClosed && !opps[0].isWon, 'Existing Closed Lost Opp should stay closed');
    }

    

    // Helpers
    //////////////

    /**
     * @description Executes batch
     * @param batch Batch instance
     * @return Exception An Exception generated in the batch (if any)
     */
    private static Exception runBatch(Database.Batchable<SObject> batch) {
        Exception actuaException;
        try {
            Test.startTest();
            Database.executeBatch(batch);
            Test.stopTest();

        } catch (Exception ex) {
            actuaException = ex;
        }
        return actuaException;
    }

    /**
     * @description Executes execute() and finish() methods
     * @param rdId Recurring Donation Id
     * @param today Date representing today
     * @return RD2_OpportunityEvaluation_BATCH Batch instance
     */
    private static RD2_OpportunityEvaluation_BATCH executeAndFinishBatch(Id rdId, Date today) {
        UTIL_BatchJobService_TEST.MockBatchableContext batchContext = new UTIL_BatchJobService_TEST.MockBatchableContext();
        RD2_OpportunityEvaluation_BATCH batch = new RD2_OpportunityEvaluation_BATCH(today);

        batch.execute(batchContext, rdGateway.getRecords(new Set<Id>{ rdId }));
        batch.finish(batchContext);

        return batch;
    }

    /**
     * @description Instantiate an Enhanced RD format recurring donation 
     * @return TEST_RecurringDonationBuilder New Recurring Donation builder
     */
    private static TEST_RecurringDonationBuilder getRecurringDonationBuilder() {
        return TEST_RecurringDonationBuilder.constructEnhancedBuilder()
            .withDefaultValues()
            .withDateEstablished(START_DATE)
            .withStartDate(START_DATE)
            .withDayOfMonth('15')
            .withContact(getContact().Id)
            .withAmount(100);
    }

    /**
     * @description Instantiate an Opp builder for the specified Recurring Donation
     * @param rd Recurring Donation
     * @return TEST_OpportunityBuilder New Opportunity builder
     */
    private static TEST_OpportunityBuilder getOpportunityBuilder(npe03__Recurring_Donation__c rd) {
        return new TEST_OpportunityBuilder()
            .withContact(rd.npe03__Contact__c)
            .withRecurringDonation(rd.Id)
            .withAmount(rd.npe03__Amount__c)
            .withInstallmentNumber(1);
    }

    /****
    * @description Returns contact record
    * @return Contact
    */
    private static Contact getContact() {
        return [
            SELECT FirstName, LastName, AccountId
            FROM Contact
            LIMIT 1
        ];
    }

    /****
    * @description Verifies batch has run
    * @param itemsProcessed Number of batch iterations
    * @return void
    */
    private static void assertBatchJobIteration(Integer itemsProcessed) {
        AsyncApexJob job = jobGateway.getRecord('RD2_OpportunityEvaluation_BATCH');
        System.assertEquals(itemsProcessed, job.JobItemsProcessed, 'The number of batch iteration should match');
    }

    /****
    * @description Verifies records failed
    * @param batch The batch instance
    * @param recordsFailed Records failed
    * @return void
    */
    private static void assertRecordsFailed(RD2_OpportunityEvaluation_BATCH batch, Integer recordsFailed) {
        Integer recordsProcessed = 1;

        System.assertEquals(recordsProcessed, batch.recordsProcessed, 'Records Processed should be tracked');
        System.assertEquals(recordsFailed, batch.recordsFailed, 'Record Failed should match');

        npe03__Recurring_Donations_Settings__c settings = UTIL_CustomSettingsFacade.getRecurringDonationsSettings();
        System.assertEquals(recordsProcessed - recordsFailed, settings.npe03__Number_of_Successes__c, 
            'Settings Number of Successes should be updated');
        System.assertEquals(recordsFailed, settings.npe03__Number_of_Failures__c, 
            'Settings Records Failed should be updated');
    }

    /****
    * @description Sets up RD settings with invalid Opp Record Type Id
    * @return void
    */
    private static void configInvalidOppRecordTypeId() {
        npe03__Recurring_Donations_Settings__c rdSetting = new npe03__Recurring_Donations_Settings__c(
            IsRecurringDonations2Enabled__c = true,
            npe03__Open_Opportunity_Behavior__c = RD2_Constants.CloseActions.Mark_Opportunities_Closed_Lost.name(),
            npe03__Record_Type__c = UTIL_RecordTypes_TEST.MOCK_ID
        );
        UTIL_CustomSettingsFacade.reloadCustomSettingsOnRecordTypeCleanup();
        UTIL_CustomSettingsFacade.getRecurringDonationsSettingsForTest(rdSetting);
    }


}