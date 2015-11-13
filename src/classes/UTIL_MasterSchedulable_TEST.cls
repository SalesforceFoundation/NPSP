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
@isTest
public with sharing class UTIL_MasterSchedulable_TEST {

    // if you only want to run one test in this class, fill in its name here.
    // if you want to run all tests, then use '*'
    private static string strTestOnly = '*';
    
    public static testmethod void scheduleJob() {
        if (strTestOnly != '*' && strTestOnly != 'scheduleJob') return;
        
        List<Schedulable__c> jobs = new List<Schedulable__c>();
        jobs.add(new Schedulable__c(Name = 'Recurring Donation Updates', Class_Name__c = 'RD_RecurringDonations_BATCH', Active__c = true));
        jobs.add(new Schedulable__c(Name = 'Opportunity Rollups', Class_Name__c = 'RLLP_OppAccRollup_BATCH', Active__c = true));
        insert jobs;
    
        Test.startTest();
        //Schedule a job
        String jobName = 'Global Scheduler'; 
        String fireTime = '0 15 23 * * ?';
        System.schedule(jobName, fireTime, new UTIL_MasterSchedulable());
        
        List<CronTrigger> triggers = [select Id, CronExpression, TimesTriggered from CronTrigger 
                            where CronJobDetail.Name = :jobName and CronJobDetail.JobType = '7'];
        
        //Verify it was added to the queue                    
        System.assertEquals(1, triggers.size());
        
        //Verify the expressions are the same
        System.assertEquals(fireTime, triggers[0].CronExpression);  
        
        // Verify the job has not run
        System.assertEquals(0, triggers[0].TimesTriggered); 
        
        Test.stopTest();        
    }
    
    public static testmethod void neverRun() {
        if (strTestOnly != '*' && strTestOnly != 'needsToRun') return;
        
        List<Schedulable__c> jobs = new List<Schedulable__c>();
        jobs.add(new Schedulable__c(Name = 'Recurring Donation Updates', Class_Name__c = 'RD_RecurringDonations_BATCH', 
                    Active__c = true, Frequency__c = 'Hourly'));
        jobs.add(new Schedulable__c(Name = 'Opportunity Rollups', Class_Name__c = 'RLLP_OppAccRollup_BATCH', 
                Active__c = true, Frequency__c = 'Daily'));
        insert jobs;
        
        Test.startTest();
        UTIL_MasterSchedulable.execute(null);
        Test.stopTest();
        
        jobs = [select Last_Time_Run__c from Schedulable__c];
        System.assertEquals(2, jobs.size());
        
        for(Schedulable__c job : jobs) {
            //Check that lastTimeRun has been modified
            System.assertNotEquals(null, job.Last_Time_Run__c);
        }
        
    }
    
    public static testmethod void needsToRun() {
        if (strTestOnly != '*' && strTestOnly != 'needsToRun') return;
        
        List<Schedulable__c> jobs = new List<Schedulable__c>();
        jobs.add(new Schedulable__c(Name = 'Recurring Donation Updates', Class_Name__c = 'RD_RecurringDonations_BATCH', 
                    Active__c = true, Frequency__c = 'Hourly', Last_Time_Run__c = System.now().addHours(-2)));
        jobs.add(new Schedulable__c(Name = 'Opportunity Account Rollups', Class_Name__c = 'RLLP_OppAccRollup_BATCH', 
                Active__c = true, Frequency__c = 'Daily', Last_Time_Run__c = System.now().addDays(-2)));
        insert jobs;
        
        Test.startTest();
        UTIL_MasterSchedulable.execute(null);
        Test.stopTest();
        
        jobs = [select Last_Time_Run__c from Schedulable__c];
        System.assertEquals(2, jobs.size());
        
        for(Schedulable__c job : jobs) {
            UTIL_Debug.debug('****needsToRun - Last time run: ' + job.Last_Time_Run__c);
            //Check that lastTimeRun has been modified - should have run in the last 5 mins
            System.assert(job.Last_Time_Run__c > System.now().addMinutes(-5));
        }
    }
    
    public static testmethod void doesNotNeedToRun() {
        if (strTestOnly != '*' && strTestOnly != 'doesNotNeedToRun') return;
        
        List<Schedulable__c> jobs = new List<Schedulable__c>();
        Datetime lastTimeRun = System.now().addMinutes(-30);
        jobs.add(new Schedulable__c(Name = 'Recurring Donation Updates', Class_Name__c = 'RD_RecurringDonations_BATCH', 
                    Active__c = true, Frequency__c = 'Hourly', Last_Time_Run__c = lastTimeRun));
        jobs.add(new Schedulable__c(Name = 'Opportunity Rollups', Class_Name__c = 'RLLP_OppAccRollup_BATCH', 
                Active__c = true, Frequency__c = 'Daily', Last_Time_Run__c = lastTimeRun));
        insert jobs;
        
        Test.startTest();
        UTIL_MasterSchedulable.execute(null);
        Test.stopTest();
        
        jobs = [select Last_Time_Run__c from Schedulable__c];
        System.assertEquals(2, jobs.size());
        
        for(Schedulable__c job : jobs) {
            UTIL_Debug.debug('****doesNotNeedToRun - Last time run: ' + job.Last_Time_Run__c);
            //Check that lastTimeRun has been modified - should not have run since last time
            System.assertEquals(lastTimeRun, job.Last_Time_Run__c);
        }
    }
}