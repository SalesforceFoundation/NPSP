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
* @description Recurring Donations enablement data migration tests
*
*/
@isTest(IsParallel=true)
private with sharing class RD2_DataMigrationEnablement_TEST {

    private static final RD2_DataMigrationEnablement.BatchJob batchJob = new RD2_DataMigrationEnablement.BatchJob();
    private static final String DRY_RUN_MIGRATION_BATCH_CLASS = batchJob.DRY_RUN_MIGRATION_BATCH_CLASS;
    private static final String MIGRATION_BATCH_CLASS = batchJob.MIGRATION_BATCH_CLASS;
    private static final Id BATCH_ID = UTIL_BatchJobService_TEST.MOCK_BATCH_ID;
    private static final Datetime MIGRATION_TIME = Datetime.newInstance(2021, 2, 2);

    /**
     * @description Verifies Enhanced Recurring Donations migration batch job summary is returned
     */
    @IsTest
    private static void shouldSaveMigrationBatchJobSummary() {
        Boolean isDryRunMode = false;
        UTIL_BatchJobService.JobSummary summary =
            new UTIL_BatchJobService.JobSummary(BATCH_ID)
            .withTotalRecordsProcessed(2);
        
        batchJob.saveSummary(summary, isDryRunMode);

        summary = batchJob.getSummary(BATCH_ID, MIGRATION_BATCH_CLASS);
        System.assertNotEquals(null, summary, 'Summary should be returned');
        System.assertEquals(BATCH_ID, summary.batchId, 'Batch Id should match: ' + summary);
        System.assertEquals(2, summary.processed, 'Processed records should match: ' + summary);

        summary = batchJob.getSummary(BATCH_ID, DRY_RUN_MIGRATION_BATCH_CLASS);
        System.assertEquals(null, summary, 'Summary should not exist for dry run');
    }

    /**
     * @description Verifies Enhanced Recurring Donations dry run batch job summary is returned
     */
    @IsTest
    private static void shouldSaveDryRunBatchJobSummary() {
        Boolean isDryRunMode = true;
        UTIL_BatchJobService.JobSummary summary =
            new UTIL_BatchJobService.JobSummary(BATCH_ID)
            .withTotalRecordsProcessed(2)
            .withCompletedDate(MIGRATION_TIME);
        
        batchJob.saveSummary(summary, isDryRunMode);

        summary = batchJob.getSummary(BATCH_ID, DRY_RUN_MIGRATION_BATCH_CLASS);
        System.assertNotEquals(null, summary, 'Summary should be returned');
        System.assertEquals(BATCH_ID, summary.batchId, 'Batch Id should match: ' + summary);
        System.assertEquals(2, summary.processed, 'Processed records should match: ' + summary);
        System.assertEquals(MIGRATION_TIME, summary.completedDate, 'Completed time shhould match: ' + summary);

        summary = batchJob.getSummary(BATCH_ID, MIGRATION_BATCH_CLASS);
        System.assertEquals(null, summary, 'Summary should not exist for migration');
    }

    /**
     * @description Verifies Enhanced Recurring Donations batch summary overrides the summary of the same type
     */
    @IsTest
    private static void shouldOverrideSummaryForTheSameType() {
        List<Id> ids = UTIL_UnitTestData_TEST.mockIds(Account.SObjectType, 3);        
        batchJob.saveSummary(
            new UTIL_BatchJobService.JobSummary(ids[0]), 
            true
        );
        batchJob.saveSummary(
            new UTIL_BatchJobService.JobSummary(ids[1]), 
            false
        );

        UTIL_BatchJobService.JobSummary summary = batchJob.getSummary(ids[0], DRY_RUN_MIGRATION_BATCH_CLASS);
        System.assertNotEquals(null, summary, 'Summary should be returned');
        System.assertEquals(ids[0], summary.batchId, 'Dry run batch Id should match: ' + summary);

        summary = batchJob.getSummary(ids[1], MIGRATION_BATCH_CLASS);
        System.assertNotEquals(null, summary, 'Summary should be returned');
        System.assertEquals(ids[1], summary.batchId, 'Migration batch Id should match: ' + summary);

        //overwrite the summary for the migration
        batchJob.saveSummary(
            new UTIL_BatchJobService.JobSummary(ids[2]), 
            false
        );
        summary = batchJob.getSummary(ids[0], DRY_RUN_MIGRATION_BATCH_CLASS);
        System.assertNotEquals(null, summary, 'Summary should be returned');
        System.assertEquals(ids[0], summary.batchId, 'Dry run batch Id should not change: ' + summary);

        summary = batchJob.getSummary(ids[1], MIGRATION_BATCH_CLASS);
        System.assertEquals(null, summary, 'Summary should not exist for the old batch Id');

        summary = batchJob.getSummary(ids[2], MIGRATION_BATCH_CLASS);
        System.assertNotEquals(null, summary, 'Summary should be returned');
        System.assertEquals(ids[2], summary.batchId, 'Migration batch Id should change: ' + summary);
    }

}