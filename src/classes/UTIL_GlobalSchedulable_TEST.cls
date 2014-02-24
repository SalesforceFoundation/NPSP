@isTest
public with sharing class UTIL_GlobalSchedulable_TEST {

    public static testmethod void scheduleJob() {
        
        List<Schedulable__c> jobs = new List<Schedulable__c>();
        jobs.add(new Schedulable__c(Name = 'Recurring Donation Updates', Class_Name__c = 'RD_RecurringDonations_SCHED', Active__c = true));
        jobs.add(new Schedulable__c(Name = 'Opportunity Rollups', Class_Name__c = 'RLLP_OppRollup_SCHED', Active__c = true));
        insert jobs;
    
        Test.startTest();
        //Schedule a job
        String jobName = 'Global Scheduler'; 
        String fireTime = '0 15 23 * * ?';
        System.schedule(jobName, fireTime, new UTIL_GlobalSchedulable());
        
        List<CronTrigger> triggers = [select Id, CronExpression, TimesTriggered from CronTrigger 
                            where CronJobDetail.Name = :jobName and CronJobDetail.JobType = '7'];
        
        //Verify it was added to the queue                    
        System.assertEquals(1, triggers.size());
        
        //Verify the expressions are the same
        System.assertEquals(fireTime, triggers[0].CronExpression);  
        
        // Verify the job has not run
        System.assertEquals(0, triggers[0].TimesTriggered); 
        
        Test.stopTest();  
        
        //@TODO: Should we verify that the same Schedulable__c is not going to be called more than once by UTIL_JobScheduler? How?                
    }
}