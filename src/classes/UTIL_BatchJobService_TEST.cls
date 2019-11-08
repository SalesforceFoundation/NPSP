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
        * @description Builds AsyncApexJob SObject based on the provided values
        * @return TestAsyncApexJob
        */
        public AsyncApexJob build() {
            String jsonString = JSON.serialize(valuesByFieldName);
                
            return (AsyncApexJob) JSON.deserialize(jsonString, AsyncApexJob.class);
        }

    }

}