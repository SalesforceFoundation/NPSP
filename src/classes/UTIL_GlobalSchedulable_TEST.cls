@isTest
public with sharing class UTIL_GlobalSchedulable_TEST {

    // if you only want to run one test in this class, fill in its name here.
    // if you want to run all tests, then use '*'
    private static string strTestOnly = '*';
    
    public static testmethod void scheduleJob() {
        if (strTestOnly != '*' && strTestOnly != 'scheduleJob') return;
        
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
    }
    
    public static testmethod void neverRun() {
        if (strTestOnly != '*' && strTestOnly != 'needsToRun') return;
        
        List<Schedulable__c> jobs = new List<Schedulable__c>();
        jobs.add(new Schedulable__c(Name = 'Recurring Donation Updates', Class_Name__c = 'RD_RecurringDonations_SCHED', 
                    Active__c = true, Frequency__c = 'Hourly'));
        jobs.add(new Schedulable__c(Name = 'Opportunity Rollups', Class_Name__c = 'RLLP_OppRollup_SCHED', 
                Active__c = true, Frequency__c = 'Daily'));
        insert jobs;
        
        Test.startTest();
        UTIL_GlobalSchedulable.execute(null);
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
        jobs.add(new Schedulable__c(Name = 'Recurring Donation Updates', Class_Name__c = 'RD_RecurringDonations_SCHED', 
                    Active__c = true, Frequency__c = 'Hourly', Last_Time_Run__c = System.now().addHours(-2)));
        jobs.add(new Schedulable__c(Name = 'Opportunity Rollups', Class_Name__c = 'RLLP_OppRollup_SCHED', 
                Active__c = true, Frequency__c = 'Daily', Last_Time_Run__c = System.now().addDays(-2)));
        insert jobs;
        
        Test.startTest();
        UTIL_GlobalSchedulable.execute(null);
        Test.stopTest();
        
        jobs = [select Last_Time_Run__c from Schedulable__c];
        System.assertEquals(2, jobs.size());
        
        for(Schedulable__c job : jobs) {
            System.debug('****needsToRun - Last time run: ' + job.Last_Time_Run__c);
            //Check that lastTimeRun has been modified - should have run in the last 5 mins
            System.assert(job.Last_Time_Run__c > System.now().addMinutes(-5));
        }
    }
    
    public static testmethod void doesNotNeedToRun() {
        if (strTestOnly != '*' && strTestOnly != 'doesNotNeedToRun') return;
        
        List<Schedulable__c> jobs = new List<Schedulable__c>();
        Datetime lastTimeRun = System.now().addMinutes(-30);
        jobs.add(new Schedulable__c(Name = 'Recurring Donation Updates', Class_Name__c = 'RD_RecurringDonations_SCHED', 
                    Active__c = true, Frequency__c = 'Hourly', Last_Time_Run__c = lastTimeRun));
        jobs.add(new Schedulable__c(Name = 'Opportunity Rollups', Class_Name__c = 'RLLP_OppRollup_SCHED', 
                Active__c = true, Frequency__c = 'Daily', Last_Time_Run__c = lastTimeRun));
        insert jobs;
        
        Test.startTest();
        UTIL_GlobalSchedulable.execute(null);
        Test.stopTest();
        
        jobs = [select Last_Time_Run__c from Schedulable__c];
        System.assertEquals(2, jobs.size());
        
        for(Schedulable__c job : jobs) {
            System.debug('****doesNotNeedToRun - Last time run: ' + job.Last_Time_Run__c);
            //Check that lastTimeRun has been modified - should not have run since last time
            System.assertEquals(lastTimeRun, job.Last_Time_Run__c);
        }
    }
}