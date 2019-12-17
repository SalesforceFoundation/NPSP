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
public with sharing class RD2_DataMigrationEnablement_TEST {

    private static final RD2_DataMigrationEnablement.BatchJob batchJob = new RD2_DataMigrationEnablement.BatchJob();
    private static final String DRY_RUN_MIGRATION_BATCH_CLASS = batchJob.DRY_RUN_MIGRATION_BATCH_CLASS;
    private static final String MIGRATION_BATCH_CLASS = batchJob.MIGRATION_BATCH_CLASS;

    /****
    * @description Creates data required for unit tests
    */
    @TestSetup
    private static void setUp() {
        insert UTIL_UnitTestData_TEST.getContact();
    }

    /**
     * @description Verifies Enhanced Recurring Donations migration batch job summary is returned
     */
    @IsTest
    private static void shouldSaveMigrationBatchJobSummary() {
        Boolean isDryRunMode = false;
        UTIL_BatchJobService.JobSummary summary =
            new UTIL_BatchJobService.JobSummary(UTIL_BatchJobService_TEST.MOCK_BATCH_ID)
            .withTotalRecords(2)
            .withTotalRecordsProcessed(2);
        
        batchJob.saveSummary(summary, isDryRunMode);

        summary = RD2_DataMigrationEnablement_TEST.getJobSummary(MIGRATION_BATCH_CLASS);
        System.assertEquals(UTIL_BatchJobService_TEST.MOCK_BATCH_ID, summary.batchId, 'Batch Id should match: ' + summary);

        summary = RD2_DataMigrationEnablement_TEST.getJobSummary(DRY_RUN_MIGRATION_BATCH_CLASS);
        System.assertEquals(null, summary, 'No dry run Job Summary instance should be returned');
    }

    /**
     * @description Verifies Enhanced Recurring Donations dry run batch job summary is returned
     */
    @IsTest
    private static void shouldSaveDryRunBatchJobSummary() {
        Boolean isDryRunMode = true;
        UTIL_BatchJobService.JobSummary summary =
            new UTIL_BatchJobService.JobSummary(UTIL_BatchJobService_TEST.MOCK_BATCH_ID)
            .withTotalRecords(2)
            .withTotalRecordsProcessed(2);
        
        batchJob.saveSummary(summary, isDryRunMode);

        summary = RD2_DataMigrationEnablement_TEST.getJobSummary(DRY_RUN_MIGRATION_BATCH_CLASS);
        System.assertEquals(UTIL_BatchJobService_TEST.MOCK_BATCH_ID, summary.batchId, 'Batch Id should match: ' + summary);

        summary = RD2_DataMigrationEnablement_TEST.getJobSummary(MIGRATION_BATCH_CLASS);
        System.assertEquals(null, summary, 'No migration Job Summary instance should be returned');
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

        UTIL_BatchJobService.JobSummary summary = RD2_DataMigrationEnablement_TEST.getJobSummary(DRY_RUN_MIGRATION_BATCH_CLASS);
        System.assertEquals(ids[0], summary.batchId, 'Dry run batch Id should match: ' + summary);

        summary = RD2_DataMigrationEnablement_TEST.getJobSummary(MIGRATION_BATCH_CLASS);
        System.assertEquals(ids[1], summary.batchId, 'Migration batch Id should match: ' + summary);


        batchJob.saveSummary(
            new UTIL_BatchJobService.JobSummary(ids[2]), 
            false
        );
        summary = RD2_DataMigrationEnablement_TEST.getJobSummary(DRY_RUN_MIGRATION_BATCH_CLASS);
        System.assertEquals(ids[0], summary.batchId, 'Dry run batch Id should not change: ' + summary);

        summary = RD2_DataMigrationEnablement_TEST.getJobSummary(MIGRATION_BATCH_CLASS);
        System.assertEquals(ids[2], summary.batchId, 'Migration batch Id should change: ' + summary);
    }




    // Helpers
    ////////////////

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
     * @description Returns batch job summary
     * @param isDryRunMode Indicates if the dry run mode is turned on 
     * @return UTIL_BatchJobService.JobSummary
     */
    public static UTIL_BatchJobService.JobSummary getJobSummary(Boolean isDryRunMode) {
        String className = isDryRunMode ? DRY_RUN_MIGRATION_BATCH_CLASS : MIGRATION_BATCH_CLASS;

        return getJobSummary(className);
    }

    /**
     * @description Returns batch job summary for the specified class name
     * @param className Class name
     * @return UTIL_BatchJobService.JobSummary
     */
    public static UTIL_BatchJobService.JobSummary getJobSummary(String className) {
        String jsonSummary = UTIL_BatchJobProgress_CTRL.loadBatchJobSummary(className);

        return String.isBlank(jsonSummary)
            ? null
            : (UTIL_BatchJobService.JobSummary) JSON.deserialize(jsonSummary, UTIL_BatchJobService.JobSummary.class);
    }


}