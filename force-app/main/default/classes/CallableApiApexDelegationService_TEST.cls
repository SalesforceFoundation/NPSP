/*
    Copyright (c) 2021, Salesforce.org
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
* @date 2021
* @group API
* @group-content ../../ApexDocContent/API.htm
* @description Tests specific to CallableApiApexDelegationService.
*/
// isParallel is FALSE as shouldScheduleJob method touches CronJobDetail which cannot be accessed when testing in parallel
@IsTest(isParallel=false)
private with sharing class CallableApiApexDelegationService_TEST {

    private static final String JOB_SCHEDULE_ACTION = 'Apex.ScheduleJob';

    /**
     * @description Verifies that job is scheduled
     */
    @IsTest
    private static void shouldScheduleJob() {
        Id scheduledJobId;
        String jobName = 'JOB.SCHEDULE TEST';

        Integer nextYear = Date.today().year() + 1;
        String cronExpression = '0 0 5 1 1 ? ' + nextYear; // January 1st next year at 5AM

        Callable callableApi = (Callable) Type.forName('Callable_API').newInstance();
        Map<String, Object> args = new Map<String, Object>{
                'JobName' => jobName,
                'CronExpression' => cronExpression,
                'ApexClass' => 'CRLP_Account_BATCH'
        };

        Test.startTest();
        scheduledJobId = (Id) callableApi.call(JOB_SCHEDULE_ACTION, args);
        Test.stopTest();

        CronTrigger cronTrigger = [SELECT Id, CronExpression, CronJobDetail.Name FROM CronTrigger WHERE Id = :scheduledJobId];

        System.assertEquals(cronExpression, cronTrigger.CronExpression,
                'CronExpression retrieved from CronTrigger should equal input ScheduledJobCronExpression');
        System.assertEquals(jobName, cronTrigger.CronJobDetail.Name,
                'Job name retrieved from CronTrigger should equal input ScheduledJobName');
    }

    /**
     * @description Verifies meaningful error is thrown if nonexistent Apex Class is used for Job.Schedule
     */
    @IsTest
    private static void shouldThrowErrorForNonExistentApexClass() {
        String expectedMessagePortion = (System.Label.CallableApiJobScheduleInvalidClass).split('\\{0\\}')[0].trim();
        String jobName = 'JOB.SCHEDULE TEST';
        String className = 'DOES_NOT_EXIST';

        Integer nextYear = Date.today().year() + 1;
        String cronExpression = '0 0 5 1 1 ? ' + nextYear; // January 1st next year at 5AM

        String errorMessage = getErrorMessageFromCallableAPI(jobName, cronExpression, className);
        System.assert(errorMessage.contains(expectedMessagePortion), 'No exception thrown for nonexistent apex class');
    }

    /**
     * @description Verifies meaningful error is thrown if nonexistent Apex Class is used for Job.Schedule
     */
    @IsTest
    private static void shouldThrowErrorForEmptyJobName() {
        String expectedMessagePortion = (System.Label.CallableApiParameterError).split('\\{0\\}')[0].trim();
        String jobName = '   ';
        String className = 'CRLP_Account_BATCH';

        Integer nextYear = Date.today().year() + 1;
        String cronExpression = '0 0 5 1 1 ? ' + nextYear; // January 1st next year at 5AM

        String errorMessage = getErrorMessageFromCallableAPI(jobName, cronExpression, className);
        System.assert(errorMessage.contains(expectedMessagePortion), 'No exception thrown for blank job name');
    }

    /**
     * @description Verifies meaningful error is thrown if nonexistent Apex Class is used for Job.Schedule
     */
    @IsTest
    private static void shouldThrowErrorForBlankCronExpression() {
        String expectedMessagePortion = (System.Label.CallableApiParameterError).split('\\{0\\}')[0].trim();
        String jobName = 'JOB.SCHEDULE TEST';
        String className = 'CRLP_Account_BATCH';
        String cronExpression = '   ';

        String errorMessage = getErrorMessageFromCallableAPI(jobName, cronExpression, className);
        System.assert(errorMessage.contains(expectedMessagePortion), 'No exception thrown for blank cron expression');
    }

    // helpers
    private static String getErrorMessageFromCallableAPI(String jobName, String cronExpression, String apexClass) {
        String errorMessage = '';

        Callable callableApi = (Callable) Type.forName('Callable_API').newInstance();
        Map<String, Object> args = new Map<String, Object>{
                'JobName' => jobName,
                'CronExpression' => cronExpression,
                'ApexClass' => apexClass
        };

        Test.startTest();
        try {
            callableApi.call(JOB_SCHEDULE_ACTION, args);

        } catch(Exception e){
            errorMessage = e.getMessage();
        }
        Test.stopTest();

        return errorMessage;
    }
}