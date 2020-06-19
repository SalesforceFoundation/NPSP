/*
    Copyright (c) 2019, Salesforce.org
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
* @group API
* @group-content ../../ApexDocContent/API.htm
* @description Tests specific to Callable API.
*/
// isParallel is FALSE as shouldScheduleJob method touches CronJobDetail which cannot be accessed when testing in parallel
@IsTest(isParallel=false)
private with sharing class Callable_API_TEST {

    private static final String TDTM_TRIGGER_ACTION = 'TDTM.DisableAllTriggers';
    private static final String CRLP_IS_ENABLED_ACTION = 'CRLP.iscrlpenabled';
    private static final String RD2_EXECUTE_MIGRATION_ACTION = 'RD2.ExecuteDataMigration';
    private static final String RD2_ENABLE_ACTION = 'Settings.EnableEnhancedRecurringDonations';
    private static final String JOB_SCHEDULE_ACTION = 'Job.Schedule';

    /**
    * @description verify the TDTM Callable action returns an Object
    */
    @IsTest
    private static void verifyCallableReturnsAnObject() {
        // skip the test if Advancement is installed
        if (ADV_PackageInfo_SVC.useAdv()) {
            return;
        }

        Test.startTest();

        Integer accountCountBefore = Database.countQuery('SELECT COUNT() FROM Account');

        Callable npspApi = (Callable) Type.forName('Callable_API').newInstance();
        Map<String, Object> triggerArgs = new Map<String, Object>();
        Object result = npspApi.call(TDTM_TRIGGER_ACTION, triggerArgs);

        Contact contact1 = new Contact(LastName = 'CallableApi_Test');
        insert contact1;

        Test.stopTest();

        Object callResult = result;
        System.assertNotEquals(null, callResult, 'No result was returned from call');

        Integer accountCountAfter = Database.countQuery('SELECT COUNT() FROM Account');
        System.assertEquals(accountCountBefore, accountCountAfter, 'Account record was created');
    }

    /**
    * @description verify the CRLP call returns true if enabled
    */
    @isTest
    private static void verifyCrlpEnabledCallReturnsRollupEnabled() {
         UTIL_CustomSettingsFacade.getRollupSettingsForTests(new Customizable_Rollup_Settings__c (
            Customizable_Rollups_Enabled__c = true
        ));

        Test.startTest();

        Callable npspApi = (Callable) Type.forName('Callable_API').newInstance();
        Map<String, Object> args = new Map<String, Object>();
        Object result = npspApi.call(CRLP_IS_ENABLED_ACTION, args);

        Test.stopTest();

        System.assertEquals(true, (Boolean) result, 'CRLP is identified as enabled');
    }

    /**
    * @description Call the API with an invalid action text and make sure an exception is thrown
    */
    @IsTest
    private static void callableApiThrowsExceptionWhenActionIsInvalid() {

        Test.startTest();

        Callable npspApi = (Callable) Type.forName('Callable_API').newInstance();
        Map<String, Object> triggerArgs = new Map<String, Object>();

        String expectedMessagePortion = ((System.Label.CallableApiMethodNotImplemented).split('}')[1]).trim();

        try {
            Object result = npspApi.call('InvalidAction', triggerArgs);
            System.assert(false, 'The exception was not thrown');
        } catch (Callable_API.MalformedMethodInvocationException apiException) {
            System.assert(apiException.getMessage().contains(expectedMessagePortion), apiException.getMessage());
        }

        Test.stopTest();
    }

    /**
     * @description Verifies if Enhanced Recurring Donations are enabled
     */
    @IsTest
    private static void shouldEnableRD2OnEnableRD2Action() {
        RD2_EnablementService_Test.setCustomizableRollups(true);

        Test.startTest();

        Callable callableApi = (Callable) Type.forName('Callable_API').newInstance();
        Map<String, Object> args = new Map<String, Object>{ 'ScheduleJobs' => false };
        callableApi.call(RD2_ENABLE_ACTION, args);

        Test.stopTest();

        System.assertEquals(true,  STG_Panel.stgService.stgRD.IsRecurringDonations2Enabled__c);
    }

    /**
     * @description Verifies Enhanced Recurring Donations migration batch job is executed
     */
    @IsTest
    private static void shouldRunRD2DataMigrationWhenRD2IsEnabled() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        Test.startTest();

        Callable callableApi = (Callable) Type.forName('Callable_API').newInstance();
        Map<String, Object> args = new Map<String, Object>();
        Object result = callableApi.call(RD2_EXECUTE_MIGRATION_ACTION, args);

        Test.stopTest();
        
        AsyncApexJob job = new TEST_SObjectGateway.AsyncApexJobGateway()
            .getRecord('RD2_DataMigration_BATCH');
        System.assertNotEquals(null, job, 'The batch should be executed');
    }

    /**
     * @description Verifies if Scheduled Jobs are scheduled
     */
    @IsTest
    private static void shouldScheduleJob() {
        Id scheduledJobId;

        Integer nextYear = Date.today().year() + 1;
        String cronExpression = '0 0 5 1 1 ? ' + nextYear; // January 1st next year at 5AM

        Callable callableApi = (Callable) Type.forName('Callable_API').newInstance();
        Map<String, Object> args = new Map<String, Object>{ 
            'ScheduledJobName' => 'JOB.SCHEDULE TEST', // Name needs to be unique
            'ScheduledJobCronExpression' => cronExpression, 
            'ScheduledJobClass' => 'CRLP_Account_BATCH' // Any Schedulable Apex Class can be used
        };
        
        Test.startTest();

        Object scheduledJobIdObject = callableApi.call(JOB_SCHEDULE_ACTION, args);
        scheduledJobId = (Id) scheduledJobIdObject;

        Test.stopTest();

        CronTrigger cronTrigger = [SELECT Id, CronExpression, CronJobDetail.Name FROM CronTrigger WHERE Id = :scheduledJobId];
        
        // Verify that Scheduled Job is scheduled to run at the right time
        System.assertEquals(cronExpression, cronTrigger.CronExpression);

        // Verify that Scheduled Job Name is set correctly
        System.assertEquals('JOB.SCHEDULE TEST', cronTrigger.CronJobDetail.Name);

        // Scheduled Job Class cannot be verified as not available on CronTrigger or CronJobDetail
    }

    /**
     * @description Verifies error is thrown if non-existant Apex Class is used for Job.Schedule
     */
    @IsTest
    private static void shouldThrowErrorForNonExistantApexClass() {
        Test.startTest();

        Integer nextYear = Date.today().year() + 1;
        String cronExpression = '0 0 5 1 1 ? ' + nextYear; // January 1st next year at 5AM

        Callable callableApi = (Callable) Type.forName('Callable_API').newInstance();
        Map<String, Object> args = new Map<String, Object>{ 
            'ScheduledJobName' => 'JOB.SCHEDULE TEST', // Name needs to be unique
            'ScheduledJobCronExpression' => cronExpression, 
            'ScheduledJobClass' => 'DOES_NOT_EXIST'
        };
        
        String expectedMessagePortion = ((System.Label.CallableApiJobScheduleInvalidClass).split('}')[1]).trim();

        try {
            Object scheduledJobIdObject = callableApi.call(JOB_SCHEDULE_ACTION, args);
            System.assert(false, 'The exception was not thrown');
        } catch(Callable_API.MalformedMethodInvocationException apiException){
            System.assert(apiException.getMessage().contains(expectedMessagePortion), apiException.getMessage());
        }

        Test.stopTest();
    }
}
