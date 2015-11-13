/*
    Copyright (c) 2014 Salesforce.org
    All rights reserved.
    
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
    
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Salesforce.org nor the names of
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
* @date 2014 
* @group Utilities
* @description Tests for the job scheduler.
*/
@isTest
public with sharing class UTIL_JobScheduler_TEST {
   
    public static testmethod void scheduleJobOnce() {
        
        String fireTime = '0 15 23 * * ?';
        String jobName = 'testJob';
        String className = 'UTIL_MasterSchedulable';
    
        Test.startTest();
        //Schedule a job
        String jobId1 = UTIL_JobScheduler.scheduleJobIfNotScheduled(jobName, fireTime, className);
        Test.stopTest();
        
        List<CronTrigger> triggers = [select Id, CronExpression, TimesTriggered from CronTrigger 
                            where CronJobDetail.Name = :jobName and CronJobDetail.JobType = '7'];
        
        //Verify it was added to the queue                    
        System.assertEquals(1, triggers.size());
        
        //Verify the expressions are the same
        System.assertEquals(fireTime, triggers[0].CronExpression);               
    }
    
    public static testmethod void scheduleJobOnceTwice() {
        
        String fireTime = '0 15 23 * * ?';
        String jobName = 'testJob';
        String className = 'UTIL_MasterSchedulable';
    
        //Schedule a job
        String jobId1 = UTIL_JobScheduler.scheduleJobIfNotScheduled(jobName, fireTime, className);
        
        Test.startTest();
        //Try scheduling the same job again
        String jobId2 = UTIL_JobScheduler.scheduleJobIfNotScheduled(jobName, fireTime, className);
        Test.stopTest();
        
        List<CronTrigger> triggers = [select Id, CronExpression, TimesTriggered from CronTrigger 
                    where CronJobDetail.Name = :jobName and CronJobDetail.JobType = '7'];
                            
        //Verify it was NOT added to the queue. Size is 1 and no exception was thrown                    
        System.assertEquals(1, triggers.size());
        System.assertEquals(null, jobId2);                 
    }
}
