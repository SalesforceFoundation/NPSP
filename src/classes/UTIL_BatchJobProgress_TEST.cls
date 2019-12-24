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
* @description Batch job progress component controller test class
*
*/
@isTest(IsParallel=true)
private with sharing class UTIL_BatchJobProgress_TEST {

    /***
    * @description Verifies batch job details are retrieved
    */
    @isTest
    private static void shouldLoadBatchJob() {
        UTIL_OrgTelemetry_SObject_BATCH telemetryBatch = new UTIL_OrgTelemetry_SObject_BATCH(
            UTIL_OrgTelemetry_SObject_BATCH.TelemetryBatchJobMode.RECURRING_DONATIONS
        );

        telemetryBatch.featureManager = (UTIL_FeatureManagement) Test.createStub(
            UTIL_FeatureManagement.class,
            new UTIL_FeatureManagement_TEST.Mock()
        );

        Test.startTest();
        Database.executeBatch(telemetryBatch);
        Test.stopTest();

        UTIL_BatchJobService.BatchJob batchJob = getBatchJob('UTIL_OrgTelemetry_SObject_BATCH');
        System.assertNotEquals(null, batchJob, 'Batch Job should be returned');
    }


    // HELPER METHODS
    //////////////////////

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