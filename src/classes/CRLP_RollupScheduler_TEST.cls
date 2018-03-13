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
* @description Unit Test for the Customizable Rollups Scheduler class
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
                        Rollups_Limit_on_Attached_Opps_for_LDV__c = 150,
                        Rollups_Account_Batch_Size__c = 100,
                        Rollups_Contact_Batch_Size__c = 100,
                        Rollups_Allocation_Batch_Size__c = 100,
                        Rollups_Account_LDV_Batch_Size__c = 1000,
                        Rollups_Contact_LDV_Batch_Size__c = 1000,
                        Rollups_Soft_Credit_Batch_Size__c = 1000
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
            if (UTIL_MasterSchedulableHelper.defaultScheduledJobs.get(jobName)[1] == 'CRLP_RollupScheduler') {
                jobCount++;
            }
        }
        System.assertNotEquals(0, jobCount, 'There should be more than one default job for CRLP_RollupScheduler');

        // Verify that the correct number of jobs has been scheduled
        List<AsyncApexJob> scheduledJobs = [SELECT Id, JobType, Status, ApexClass.Name FROM AsyncApexJob
                                WHERE JobType = 'ScheduledApex' AND Status != 'Aborted' AND ApexClass.Name = 'CRLP_RollupScheduler'];
        System.assertEquals(jobCount, scheduledJobs.size(),
            'There should be ' + jobCount + ' jobs scheduled using the CRLP_RollupScheduler interface');

        // Reset the defaultScheduledJobs collection
        UTIL_MasterSchedulableHelper.defaultScheduledJobs = null;

        // Turn off Customizable Rollups
        UTIL_CustomSettingsFacade.getCustomizableRollupSettings().Customizable_Rollups_Enabled__c = false;
        UTIL_MasterSchedulableHelper.setScheduledJobs();

        System.assertEquals(0, [SELECT count() FROM AsyncApexJob
            WHERE JobType = 'ScheduledApex' AND ApexClass.Name = 'CRLP_RollupScheduler' AND Status != 'Aborted'],
            'There should be zero jobs scheduled using the CRLP_RollupScheduler interface');
    }

    /**
     * @description Test scheduling a single non-LDV job
     */
    static testMethod void test_Scheduled_CRLP_Rollup_Job() {

        // Enable Customizable Rollups
        UTIL_CustomSettingsFacade.getRollupSettingsForTests(
                new Customizable_Rollup_Settings__c (
                        Customizable_Rollups_Enabled__c = true,
                        Rollups_Limit_on_Attached_Opps_for_LDV__c = 150,
                        Rollups_Account_Batch_Size__c = 100,
                        Rollups_Contact_Batch_Size__c = 100,
                        Rollups_Allocation_Batch_Size__c = 100,
                        Rollups_Account_LDV_Batch_Size__c = 1000
                ));

        // Delete all currently scheduled jobs
        List<CronTrigger> jobs = [SELECT Id FROM CronTrigger];
        for (CronTrigger eachJob : jobs) {
            System.abortJob(eachJob.Id);
        }

        // Insert a dummy Contact and 100 Opportunity records
        Contact c = new Contact(LastName = 'UNITTEST', FirstName = 'TEST');
        insert c;

        Test.startTest();
        // Schedule an instance of the job. Actual schedule doesn't really matter here.
        System.schedule('TESTING', '0 0 23 ? * *', new CRLP_RollupScheduler(CRLP_RollupProcessingOptions.RollupType.AccountHardCredit));
        // StopTest to allow the job to execute
        Test.stopTest();

        // It's not possible to verify that the scheduled job actually ran unfortunately other than to see if
        // the rollup job actually rolled anything up, but there are no rollups in this particular test.
    }

    /**
     * @description Test scheduling a single LDV job
     */
    static testMethod void test_Scheduled_CRLP_Rollup_Skew_Job() {

        // Enable Customizable Rollups
        UTIL_CustomSettingsFacade.getRollupSettingsForTests(
                new Customizable_Rollup_Settings__c (
                        Customizable_Rollups_Enabled__c = true,
                        Rollups_Limit_on_Attached_Opps_for_LDV__c = 1,
                        Rollups_Account_Batch_Size__c = 100,
                        Rollups_Contact_Batch_Size__c = 100,
                        Rollups_Allocation_Batch_Size__c = 100,
                        Rollups_Account_LDV_Batch_Size__c = 1000
                ));

        // Delete all currently scheduled jobs
        List<CronTrigger> jobs = [SELECT Id FROM CronTrigger];
        for (CronTrigger eachJob : jobs) {
            System.abortJob(eachJob.Id);
        }

        // Insert a dummy Contact and 100 Opportunity records
        Contact c = new Contact(LastName = 'UNITTEST', FirstName = 'TEST');
        insert c;

        Opportunity opp =new Opportunity (
                Name = 'Test Opp ' + c.FirstName + ' ' + c.LastName,
                Amount = 500,
                CloseDate = Date.Today().addDays(1),
                StageName = UTIL_UnitTestData_TEST.getClosedWonStage(),
                Primary_Contact__c = c.Id
        );
        insert opp;

        Test.startTest();
        // Schedule an instance of the job. Actual schedule doesn't really matter here.
        System.schedule('TESTING', '0 0 23 ? * *', new CRLP_RollupScheduler(CRLP_RollupProcessingOptions.RollupType.AccountHardCredit));
        // StopTest to allow the job to execute
        Test.stopTest();

        // It's not possible to verify that the scheduled job actually ran unfortunately other than to see if
        // the rollup job actually rolled anything up, but there are no rollups in this particular test.
    }
}