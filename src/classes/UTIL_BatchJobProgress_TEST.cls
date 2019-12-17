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

    /****
    * @description Creates data required for unit tests
    */
    @TestSetup
    private static void setUp() {
        insert UTIL_UnitTestData_TEST.getContact();
    }

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

        String className = 'UTIL_OrgTelemetry_SObject_BATCH';

        String jsonBatchJob = UTIL_BatchJobProgress_CTRL.loadBatchJob(className);
        System.assert(String.isNotBlank(jsonBatchJob), 'Batch job details should be retrieved');

        UTIL_BatchJobService.BatchJob batchJob = (UTIL_BatchJobService.BatchJob) JSON.deserialize(
            jsonBatchJob, UTIL_BatchJobService.BatchJob.class
        );
        System.assertNotEquals(null, batchJob, 'BatchJob instance should be returned');
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

        UTIL_BatchJobService.JobSummary summary = RD2_DataMigrationEnablement_TEST.getJobSummary('RD2_DataMigration_BATCH');
        System.assertEquals(jobId, summary.batchId, 'Batch Id should match: ' + summary);
        System.assertEquals(1, summary.total, 'Total Records should match: ' + summary);
        System.assertEquals(1, summary.processed, 'Total Records Processed should match: ' + summary);
        System.assertEquals(0, summary.failed, 'Total Records Failed should match: ' + summary);
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
        
        UTIL_BatchJobService.JobSummary summary = RD2_DataMigrationEnablement_TEST.getJobSummary('RD2_DataMigrationDryRun_BATCH');
        System.assertEquals(jobId, summary.batchId, 'Batch Id should match: ' + summary);
        System.assertEquals(1, summary.total, 'Total Records should match: ' + summary);
        System.assertEquals(1, summary.processed, 'Total Records Processed should match: ' + summary);
        System.assertEquals(0, summary.failed, 'Total Records Failed should match: ' + summary);
    }


    // HELPER METHODS
    //////////////////////

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

}