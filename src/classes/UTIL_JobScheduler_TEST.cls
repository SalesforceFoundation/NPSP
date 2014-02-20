@isTest
public with sharing class UTIL_JobScheduler_TEST {
   
    public static testmethod void scheduleJob() {
    	
    	String fireTime = '0 15 23 * * ?';
        String jobName = 'testJob';
        String className = 'RLLP_OppRollup_SCHED';
    
        Test.startTest();
        //Schedule a job
        String jobId1 = UTIL_JobScheduler.scheduleJobIfNotScheduled(jobName, fireTime, className);
        
        List<CronTrigger> triggers = [select Id, CronExpression, TimesTriggered from CronTrigger 
                            where CronJobDetail.Name = :jobName and CronJobDetail.JobType = '7'];
        
        //Verify it was added to the queue                    
        System.assertEquals(1, triggers.size());
        
        //Verify the expressions are the same
        System.assertEquals(fireTime, triggers[0].CronExpression);  
        
        // Verify the job has not run
        System.assertEquals(0, triggers[0].TimesTriggered);
        
        //Try scheduling the same job again
        String jobId2 = UTIL_JobScheduler.scheduleJobIfNotScheduled(jobName, fireTime, className);
        
        triggers = [select Id, CronExpression, TimesTriggered from CronTrigger 
                    where CronJobDetail.Name = :jobName and CronJobDetail.JobType = '7'];
                            
        //Verify it was NOT added to the queue. Size is still 1 and no exception was thrown                    
        System.assertEquals(1, triggers.size());
        System.assertEquals(null, jobId2);
        
        Test.stopTest();                  
    }
}