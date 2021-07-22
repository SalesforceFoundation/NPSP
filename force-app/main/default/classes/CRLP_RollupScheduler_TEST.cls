/*
    Copyright (c) 2018, Salesforce.org
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
* @date 2018
* @group Customizable Rollups Operations Services
* @description Unit Test for the Customizable Rollups Batch Schedules
*/
@isTest
private class CRLP_RollupScheduler_TEST {

    /**
     * @description Test that when Customizable Rollups is enabled, the correct number of jobs are scheduled for
     * the CRLP_RollupScheduler class.
     */
    static testMethod void test_schedule_CRLPJobs() {

        // Enable Customizable Rollups
        UTIL_CustomSettingsFacade.getRollupSettingsForTests(
                new Customizable_Rollup_Settings__c (
                        Customizable_Rollups_Enabled__c = true,
                        Rollups_Limit_on_Attached_Opps_for_Skew__c = 150,
                        Rollups_Account_Batch_Size__c = 100,
                        Rollups_Contact_Batch_Size__c = 100,
                        Rollups_GAU_Batch_Size__c = 100,
                        Rollups_Account_SkewMode_Batch_Size__c = 1000,
                        Rollups_Contact_SkewMode_Batch_Size__c = 1000,
                        Rollups_Contact_Soft_Credit_Batch_Size__c = 1000
                ));

        // Delete all currently scheduled jobs
        List<CronTrigger> jobs = [SELECT Id FROM CronTrigger];
        for (CronTrigger eachJob : jobs) {
            System.abortJob(eachJob.Id);
        }

        Test.startTest();
        UTIL_MasterSchedulableHelper.setScheduledJobs();

        // Count the number of jobs using the CRLP_RollupScheduler class
        Integer jobCount = 0;
        for (String jobName : UTIL_MasterSchedulableHelper.defaultScheduledJobs.keySet()) {
            if (UTIL_MasterSchedulableHelper.defaultScheduledJobs.get(jobName)[1].startsWith('CRLP_')) {
                jobCount++;
            }
        }
        System.assertNotEquals(0, jobCount, 'There should be more than one default job for CRLP_RollupScheduler');

        // Verify that the correct number of jobs has been scheduled
        List<AsyncApexJob> scheduledJobs = [SELECT Id, JobType, Status, ApexClass.Name FROM AsyncApexJob
                                WHERE JobType = 'ScheduledApex' AND Status != 'Aborted' AND ApexClass.Name LIKE 'CRLP_%'];
        System.assertEquals(jobCount, scheduledJobs.size(),
            'There should be ' + jobCount + ' jobs scheduled using the CRLP_RollupScheduler interface');

        // Reset the defaultScheduledJobs collection
        UTIL_MasterSchedulableHelper.defaultScheduledJobs = null;

        // Turn off Customizable Rollups
        UTIL_CustomSettingsFacade.getCustomizableRollupSettings().Customizable_Rollups_Enabled__c = false;
        UTIL_MasterSchedulableHelper.setScheduledJobs();

        System.assertEquals(0, [SELECT count() FROM AsyncApexJob
            WHERE JobType = 'ScheduledApex' AND ApexClass.Name LIKE 'CRLP_%' AND Status != 'Aborted'],
            'There should be zero jobs scheduled using the CRLP_RollupScheduler interface');
    }

    /**
     * @description It's not actually possible to test whether a job was executed or not, but we need to ensure
     * code coverage on each of these Batch Classes. The actual rollup logic in the batch classes is covered
     * by each of the individual tests for the related rollup. Plus, because tests are limited to a single batch
     * iteration, the only way this method can schedule and execute multiple batches is if there is no data to
     * query/process.
     */
    static testMethod void test_scheduled_jobs() {
        // Start by enabling Customizable Rollups (which disables all legacy rollup operations)
        UTIL_CustomSettingsFacade.getRollupSettingsForTests(new Customizable_Rollup_Settings__c (
                Customizable_Rollups_Enabled__c = true
        ));

        Test.startTest();

        System.schedule('UNITTEST-GAU', '0 0 23 ? * *', new CRLP_GAU_BATCH(CRLP_RollupProcessingOptions.RollupTypeFilter.All));
        System.schedule('UNITTEST-ACCOUNT', '0 0 23 ? * *', new CRLP_Account_BATCH(CRLP_RollupProcessingOptions.RollupTypeFilter.All));
        System.schedule('UNITTEST-CONTACT', '0 0 23 ? * *', new CRLP_Contact_BATCH(CRLP_RollupProcessingOptions.RollupTypeFilter.All));
        System.schedule('UNITTEST-SOFTCREDIT-ACCOUNT-CON', '0 0 23 ? * *', new CRLP_Account_SoftCredit_BATCH(CRLP_RollupProcessingOptions.RollupTypeFilter.All));
        System.schedule('UNITTEST-SOFTCREDIT-ACCOUNT', '0 0 23 ? * *', new CRLP_Account_AccSoftCredit_BATCH(CRLP_RollupProcessingOptions.RollupTypeFilter.All));
        System.schedule('UNITTEST-SOFTCREDIT-CONTACT', '0 0 23 ? * *', new CRLP_Contact_SoftCredit_BATCH(CRLP_RollupProcessingOptions.RollupTypeFilter.All));
        System.schedule('UNITTEST-ACCOUNT-SKEW', '0 0 23 ? * *', new CRLP_AccountSkew_BATCH(CRLP_RollupProcessingOptions.RollupTypeFilter.All));
        System.schedule('UNITTEST-CONTACT-SKEW', '0 0 23 ? * *', new CRLP_ContactSkew_BATCH(CRLP_RollupProcessingOptions.RollupTypeFilter.All));
        System.schedule('UNITTEST-ACCOUNT-CONSOFTCREDIT-SKEW', '0 0 23 ? * *', new CRLP_AccountSkew_SoftCredit_BATCH(CRLP_RollupProcessingOptions.RollupTypeFilter.All));
        System.schedule('UNITTEST-ACCOUNT-SOFTCREDIT-SKEW', '0 0 23 ? * *', new CRLP_AccountSkew_AccSoftCredit_BATCH(CRLP_RollupProcessingOptions.RollupTypeFilter.All));
        System.schedule('UNITTEST-CONTACT-SOFTCREDIT-SKEW', '0 0 23 ? * *', new CRLP_ContactSkew_SoftCredit_BATCH(CRLP_RollupProcessingOptions.RollupTypeFilter.All));

        System.assertEquals(11, [SELECT count() FROM AsyncApexJob
        WHERE JobType = 'ScheduledApex' AND ApexClass.Name LIKE 'CRLP_%' AND Status != 'Aborted'],
                'There should be eleven jobs scheduled using the CRLP_RollupScheduler interface');

        Test.stopTest();
    }

    /**
     * @description Simple test to ensure that the SkewDispatcher batch job executes. Due to Test limitations
     * with the number of batch iterations, it's not possible to have this job execute and then call another
     * batch job to execute that will actually roll up data.
     */
    static testMethod void test_skewdispatcher_job() {

        // Start by enabling Customizable Rollups (which disables all legacy rollup operations)
        UTIL_CustomSettingsFacade.getRollupSettingsForTests(new Customizable_Rollup_Settings__c (
                Customizable_Rollups_Enabled__c = true,
                Rollups_Limit_on_Attached_Opps_for_Skew__c = 0,
                Rollups_Skew_Dispatcher_Batch_Size__c = 200
        ));

        // Create a single rollup definition
        String rollupsJSON = '[' +
                CMT_UnitTestData_TEST.createRollupRecord('Total Donations All Time', '',
                        CMT_UnitTestData_TEST.RollupRecordType.OppToContact,
                        'npo02__TotalOppAmount__c', CRLP_Operation.RollupType.SUM, 'Amount') +
                ']';

        // Deserialize the rollups to use for testing
        CRLP_Rollup_SEL.cachedRollups = (List<Rollup__mdt>) JSON.deserialize(rollupsJSON, List<Rollup__mdt>.class);

        Contact c = UTIL_UnitTestData_TEST.getContact();
        insert c;

        Test.startTest();

        Database.executeBatch(new CRLP_SkewDispatcher_BATCH(CRLP_RollupProcessingOptions.RollupType.ContactHardCredit,
        CRLP_RollupProcessingOptions.RollupTypeFilter.All));

        Test.stopTest();
    }
}