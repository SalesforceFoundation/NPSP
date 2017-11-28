/**
 * Created by smithmichael on 11/27/17.
 */

@isTest
private class CRLP_RollupScheduler_TEST {

    /**
     * @description Tests if System Administrator is the owner of Scheduled Jobs and calls the methods that
     *              log an error and send an email.
     */
    static testMethod void test_scheduleCRLPJobs() {

        // Enable Customizable Rollups
        UTIL_CustomSettingsFacade.getHouseholdsSettingsForTests(
                new npo02__Households_Settings__c (
                        npo02__Household_Rules__c = HH_Households.ALL_PROCESSOR,
                        Customizable_Rollups_Enabled__c = true,
                        Rollups_Limit_on_Attached_Opps_for_LDV__c = 150,
                        Rollups_Account_Batch_Size__c = 100,
                        Rollups_Contact_Batch_Size__c = 100,
                        Rollups_Allocation_Batch_Size__c = 100,
                        Rollups_LDV_Batch_Size__c = 1000
                ));

        // Delete all currently scheduled jobs
        List<CronTrigger> jobs = [SELECT Id FROM CronTrigger];
        for (CronTrigger eachJob : jobs) {
            System.abortJob(eachJob.Id);
        }

        Test.startTest();
        UTIL_MasterSchedulableHelper.setScheduledJobs();
        Test.stopTest();

        System.assert([SELECT count() FROM AsyncApexJob
            WHERE JobType = 'ScheduledApex' AND ApexClass.Name = 'CRLP_RollupScheduler'] > 0,
            'There should be multiple jobs scheduled using the CRLP_RollupScheduler interface\n' +
                    JSON.serializePretty([SELECT Id, ApexClass.name FROM AsyncApexJob
                    WHERE JobType = 'ScheduledApex']));
    }
}