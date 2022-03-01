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
* @group Batch Job
* @description Batch job service test class
*
*/
@isTest(IsParallel=true)
public with sharing class UTIL_BatchJobService_TEST {
    public static final Id MOCK_BATCH_ID = '707f100007HyXHJAA3';
	private static final String TIME_ELAPSED_DAYS = System.Label.BatchProgressTimeElapsedDays;

    /****
    * @description Creates data required for unit tests
    */
    @TestSetup
    private static void setUp() {
        insert UTIL_UnitTestData_TEST.getContact();
    }

    /***
    * @description Verifies the constructor throws an error when the batch job input argument is null
    */
    @isTest
    private static void shouldThrowExceptionWhenBatchIsNull() {
        Exception actual;

        try {
            UTIL_BatchJobService.BatchJob batchJob = new UTIL_BatchJobService.BatchJob(null);
        } catch(Exception e) {
            actual = e;
        }

        System.assertNotEquals(null, actual, 'An exception should be thrown');
        System.assertEquals(UTIL_BatchJobService.BATCH_JOB_REQUIRED,
            actual.getMessage(), 'Exception message should match');
    }

    /***
    * @description Verifies the constructor sets the BatchJob properties
    */
    @isTest
    private static void shouldSetBatchJobProperties() {
        AsyncApexJob job = buildAsyncApexJob();
        UTIL_BatchJobService.BatchJob batchJob = new UTIL_BatchJobService.BatchJob(job);

        System.assertEquals(MOCK_BATCH_ID, batchJob.batchId);
        System.assertEquals(job.CreatedDate, batchJob.createdDate);
        System.assertEquals(job.Status, batchJob.status);
        System.assertEquals(null, batchJob.extendedStatus);
        System.assertEquals(job.CompletedDate, batchJob.completedDate);
        System.assertEquals(job.jobItemsProcessed, batchJob.jobItemsProcessed);
        System.assertEquals(job.totalJobItems, batchJob.totalJobItems);
        System.assertEquals('3 ' + TIME_ELAPSED_DAYS + ' 00:00:00', batchJob.timeElapsed);
        System.assertEquals(100, batchJob.percentComplete);
        System.assertEquals(false, batchJob.isInProgress);

        System.assertEquals(UTIL_BatchJobService.MAX_DAYS_EXCEEDED, batchJob.completedDaysBetween,
            'Should reported the max days between instead of actual number since it is not relevant for any further calculations');
    }

    /***
    * @description Verifies batch job elapsed time is calculated as difference between start and completion date.
    * If the completion date is null, the difference is calculated using the current datetime.
    */
    @isTest
    private static void shouldCalculateTimeElapsed() {
        AsyncApexJob job = buildAsyncApexJob();
        UTIL_BatchJobService.BatchJob batchJob = new UTIL_BatchJobService.BatchJob(job);

        DateTime startDate = DateTime.newInstance(2018, 01, 30, 15, 20, 40);
        DateTime endDate = DateTime.newInstance(2018, 01, 30, 18, 20, 40);
        System.assertEquals('03:00:00', batchJob.calcTimeElapsed(startDate, endDate));

        startDate = DateTime.newInstance(2018, 01, 30, 15, 20, 40);
        endDate = DateTime.newInstance(2018, 01, 31, 18, 20, 40);
        System.assertEquals('1 ' + TIME_ELAPSED_DAYS + ' 03:00:00', batchJob.calcTimeElapsed(startDate, endDate));

        startDate = DateTime.newInstance(2018, 01, 30, 15, 20, 40);
        endDate = DateTime.newInstance(2018, 02, 1, 18, 20, 40);
        System.assertEquals('2 ' + TIME_ELAPSED_DAYS + ' 03:00:00', batchJob.calcTimeElapsed(startDate, endDate));

        startDate = DateTime.newInstance(2018, 01, 30, 15, 15, 50);
        endDate = DateTime.newInstance(2018, 02, 1, 18, 20, 40);
        System.assertEquals('2 ' + TIME_ELAPSED_DAYS + ' 03:04:50', batchJob.calcTimeElapsed(startDate, endDate));
    }

    /***
    * @description Verifies batch job end date is set to DateTime.now() when the batch is in progress
    */
    @isTest
    private static void shouldUseCurrentDateToCalculateTimeElapsedForInProgressBatch() {
        AsyncApexJob job = buildAsyncApexJob();
        UTIL_BatchJobService.BatchJob batchJob = new UTIL_BatchJobService.BatchJob(job);

        DateTime startDate = DateTime.newInstance(2018, 01, 30, 15, 20, 40);
        DateTime endDate = null;
        String actual = batchJob.calcTimeElapsed(startDate, endDate);

        System.assertNotEquals(null, actual);
    }

    /***
    * @description Verifies batch job end date is set to DateTime.now() when the batch is in progress
    */
    @isTest
    private static void shouldCalculatePercentageComplete() {
        final Integer defaultPercentage = 5;

        AsyncApexJob job = buildAsyncApexJob();
        UTIL_BatchJobService.BatchJob batchJob = new UTIL_BatchJobService.BatchJob(job);

        Integer jobItemsProcessed = 0;
        Integer totalJobItems = 100;

        String status = UTIL_BatchJobService.ApexJobStatus.HOLDING.name();
        Long percentComplete = batchJob.calcPercentComplete(jobItemsProcessed, totalJobItems, status);
        System.assertEquals(defaultPercentage, percentComplete);

        status = UTIL_BatchJobService.ApexJobStatus.QUEUED.name();
        percentComplete = batchJob.calcPercentComplete(jobItemsProcessed, totalJobItems, status);
        System.assertEquals(defaultPercentage, percentComplete);

        status = UTIL_BatchJobService.ApexJobStatus.PREPARING.name();
        percentComplete = batchJob.calcPercentComplete(jobItemsProcessed, totalJobItems, status);
        System.assertEquals(10, percentComplete);

        jobItemsProcessed = 75;
        status = UTIL_BatchJobService.ApexJobStatus.PROCESSING.name();
        percentComplete = batchJob.calcPercentComplete(jobItemsProcessed, totalJobItems, status);
        System.assertEquals(75, percentComplete);

        status = UTIL_BatchJobService.ApexJobStatus.ABORTED.name();
        percentComplete = batchJob.calcPercentComplete(jobItemsProcessed, totalJobItems, status);
        System.assertEquals(75, percentComplete);

        status = UTIL_BatchJobService.ApexJobStatus.FAILED.name();
        percentComplete = batchJob.calcPercentComplete(jobItemsProcessed, totalJobItems, status);
        System.assertEquals(0, percentComplete);

        jobItemsProcessed = 100;
        status = UTIL_BatchJobService.ApexJobStatus.COMPLETED.name();
        percentComplete = batchJob.calcPercentComplete(jobItemsProcessed, totalJobItems, status);
        System.assertEquals(100, percentComplete);
    }

    /***
    * @description Verifies days between is calculated correctly
    */
    @isTest
    private static void shouldSetDaysBetween() {
        TestAsyncApexJob jobBuilder = new TestAsyncApexJob()
            .withId(MOCK_BATCH_ID)
            .withCreatedBy(getUser());

        UTIL_BatchJobService.BatchJob batchJob = new UTIL_BatchJobService.BatchJob(
            jobBuilder.withCompletedDate(Datetime.now()).build()
        );
        System.assertEquals(0, batchJob.completedDaysBetween, 
            'Days between should be zero when batch job is completed today');
        
        batchJob = new UTIL_BatchJobService.BatchJob(
            jobBuilder.withCompletedDate(Datetime.now().addDays(-2)).build()
        );        
        System.assertEquals(2, batchJob.completedDaysBetween, 
            'Days between should be a positive number when batch job is completed in past');
    }

    /***
    * @description Verifies batch job summary is set correctly
    */
    @isTest
    private static void shouldSetBatchJobSummary() {
        Integer total = 100;
        Integer processed = 80;
        Integer failed = 20;
        Datetime completedTime = Datetime.newInstance(2021, 2, 2);

        UTIL_BatchJobService.JobSummary summary =
            new UTIL_BatchJobService.JobSummary(MOCK_BATCH_ID)
            .withTotalRecordsProcessed(processed)
            .withTotalRecordsFailed(failed)
            .withCompletedDate(completedTime);

        System.assertEquals(MOCK_BATCH_ID, summary.batchId, 'Batch Id should match');
        System.assertEquals(processed, summary.processed, 'Total Records Processed should match');
        System.assertEquals(failed, summary.failed, 'Total Records Failed should match');
        System.assertEquals(completedTime, summary.completedDate, 'Completed Date should match');
    }

    /**
     * @description Verifies Enhanced Recurring Donations migration batch job summary is returned
     */
    @IsTest
    private static void shouldReturnEnhancedRDMigrationSummary() {
        setRDSettings();

        insert getLegacyRecurringDonationBuilder(getContact().Id).build();

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        Test.startTest();
        Id jobId = Database.executeBatch(new RD2_DataMigration_BATCH());
        Test.stopTest();

        assertBatchJobSummary(jobId, 'RD2_DataMigration_BATCH');
    }

    /**
     * @description Verifies Enhanced Recurring Donations dry run migration batch job summary is returned
     */
    @IsTest
    private static void shouldReturnEnhancedRDDryRunMigrationSummary() {
        setRDSettings();

        insert getLegacyRecurringDonationBuilder(getContact().Id).build();

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        Test.startTest();
        Id jobId = Database.executeBatch(new RD2_DataMigrationDryRun_BATCH());
        Test.stopTest();

        assertBatchJobSummary(jobId, 'RD2_DataMigrationDryRun_BATCH');
    }

    /***
    * @description Asserts batch job summary
    * @param className Class Name
    * @return void
    */
    private static void assertBatchJobSummary(Id jobId, String className) {
        UTIL_BatchJobService.BatchJob batchJob = getBatchJob(className);
        System.assertNotEquals(null, batchJob, 'Batch Job should be returned');
        System.assertNotEquals(null, batchJob.summary, 'Batch Job summary should be returned');

        System.assertEquals(jobId, batchJob.summary.batchId, 'Batch Id should match: ' + batchJob.summary);
        System.assertEquals(1, batchJob.summary.processed, 'Total Records Processed should match: ' + batchJob.summary);
        System.assertEquals(0, batchJob.summary.failed, 'Total Records Failed should match: ' + batchJob.summary);
        System.assertNotEquals(null, batchJob.summary.completedDate, 'The completed time should be stored');
    }


    /***
    * @description Builds an AsyncApexJob and sets attributes that are not writable otherwise
    */
    public class TestAsyncApexJob {
        private Map<String, Object> valuesByFieldName;

        /***
        * @description Constructor sets default values
        */
        public TestAsyncApexJob() {
            valuesByFieldName = new Map<String, Object>();

            //defaults
            valuesByFieldName.put('Status', UTIL_BatchJobService.ApexJobStatus.COMPLETED.name());
            valuesByFieldName.put('CreatedDate', DateTime.newInstance(2018, 01, 31, 15, 10, 45));
            valuesByFieldName.put('CompletedDate', DateTime.newInstance(2018, 2, 3, 15, 10, 45));
            valuesByFieldName.put('JobItemsProcessed', 75);
            valuesByFieldName.put('TotalJobItems', 75);
        }

        /***
        * @description Sets the batch job Id to the Mock Id
        * @return TestAsyncApexJob
        */
        public TestAsyncApexJob withMockId() {
            return withId(MOCK_BATCH_ID);
        }

        /***
        * @description Sets the batch job Id
        * @param batchId
        * @return TestAsyncApexJob
        */
        public TestAsyncApexJob withId(Id batchId) {
            valuesByFieldName.put('Id', batchId);
            return this;
        }

        /***
        * @description Sets Created By for the batch job
        * @param usr
        * @return TestAsyncApexJob
        */
        public TestAsyncApexJob withCreatedBy(User usr) {
            valuesByFieldName.put('CreatedBy', usr);
            return this;
        }

        /***
        * @description Sets the batch status
        * @param status
        * @return TestAsyncApexJob
        */
        public TestAsyncApexJob withStatus(String status) {
            valuesByFieldName.put('Status', status);
            return this;
        }

        /***
        * @description Sets the batch completed date
        * @param completedDate
        * @return TestAsyncApexJob
        */
        public TestAsyncApexJob withCompletedDate(DateTime completedDate) {
            valuesByFieldName.put('CompletedDate', completedDate);
            return this;
        }

        /***
        * @description Builds AsyncApexJob SObject based on the provided values
        * @return TestAsyncApexJob
        */
        public AsyncApexJob build() {
            String jsonString = JSON.serialize(valuesByFieldName);

            return (AsyncApexJob) JSON.deserialize(jsonString, AsyncApexJob.class);
        }
    }

    /***
    * @description Database.BatchableContext Mock class
    */
    public class MockBatchableContext implements Database.BatchableContext {
        private Id jobId;
        private Id childJobId;

        public MockBatchableContext() {
            jobId = MOCK_BATCH_ID;
        }

        public MockBatchableContext returnJobId(Id jobId) {
            this.jobId = jobId;
            return this;
        }

        public MockBatchableContext returnChildJobId(Id childJobId) {
            this.childJobId = childJobId;
            return this;
        }

        public Id getJobId() {
            return jobId;
        }

        public Id getChildJobId() {
            return childJobId;
        }
    }

    /***
    * @description Stub for the batch job service
    */
    public class Stub implements System.StubProvider {
        private Boolean isInProgress = false;
        private Integer completedDaysBetween = 0;
        private AsyncApexJob asyncJob;

        /***
        * @description Sets the batch job to be in progress
        */
        public Stub withIsInProgress() {
            isInProgress = true;
            return this;
        }

        /***
        * @description Sets number of days passed since the batch job has completed
        */
        public Stub withCompletedDaysBetween(Integer completedDaysBetween) {
            this.completedDaysBetween = completedDaysBetween;
            return this;
        }

        /***
        * @description Sets the AsyncApexJob to return
        */
        public Stub withAsyncApexJob(AsyncApexJob asyncJob) {
            this.asyncJob = asyncJob;
            return this;
        }

        /***
        * @description Stubs class methods
        */
        public Object handleMethodCall(
            Object stubbedObject,
            String methodName,
            Type returnType,
            List<Type> paramTypes,
            List<String> paramNames,
            List<Object> args
        ) {
            switch on methodName {
                when 'isInProgress' {
                    return isInProgress;

                } when 'getCompletedDaysByClassName' {
                    return completedDaysBetween;

                } when 'getCompletedDaysByBatchId' {
                    return completedDaysBetween;

                } when 'getAsyncApexJob' {
                    return asyncJob;

                } when else {
                    return null;
                }
            }
        }
    }


    // Helpers
    /////////////

    /***
    * @description Builds a batch AsyncApexJob
    * @return AsyncApexJob
    */
    private static AsyncApexJob buildAsyncApexJob() {
        return new TestAsyncApexJob()
            .withId(MOCK_BATCH_ID)
            .withCreatedBy(getUser())
            .build();
    }

    /***
    * @description Retrieves the current user info
    * @return User
    */
    private static User getUser() {
        return [SELECT Id, Name FROM User WHERE Id = :UserInfo.getUserId()];
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

    /**
     * @description Sets RD Settings 
     * @return void
     */
    private static void setRDSettings() {
        UTIL_CustomSettingsFacade.getRecurringDonationsSettingsForTest(
            new npe03__Recurring_Donations_Settings__c(
                npe03__Open_Opportunity_Behavior__c = RD2_Constants.CloseActions.Mark_Opportunities_Closed_Lost.name(),
                npe03__Maximum_Donations__c = 50,
                npe03__Opportunity_Forecast_Months__c = 6
            )
        );
    }

    /**
     * @description Instantiate a legacy recurring donation for a specific ContactId
     * @param contactId
     * @return TEST_RecurringDonationBuilder New Recurring Donation builder
     */
    private static TEST_RecurringDonationBuilder getLegacyRecurringDonationBuilder(Id contactId) {
        return TEST_RecurringDonationBuilder.constructLegacyBuilder()
            .withId(null)
            .withDateEstablished(Date.today().addMonths(-1))
            .withOpenEndedStatusOpen()
            .withContact(contactId)
            .withAmount(100)
            .withInstallmentPeriodMonthly()
            .withDayOfMonth('1');
    }

    /**
     * @description Returns batch job wrapper
     * @param className Class name
     * @return UTIL_BatchJobService.BatchJob
     */
    private static UTIL_BatchJobService.BatchJob getBatchJob(String className) {
        String jsonBatchJob = UTIL_BatchJobProgress_CTRL.loadBatchJob(className);
        System.assert(String.isNotBlank(jsonBatchJob), 'Batch job details should be retrieved');

        return (UTIL_BatchJobService.BatchJob) JSON.deserialize(
            jsonBatchJob, UTIL_BatchJobService.BatchJob.class
        );
    }


}