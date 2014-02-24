public with sharing class UTIL_GlobalSchedulableHelper {

    public enum SchedFrequency { HOURLY, DAILY, WEEKLY, MONTHLY, QUARTERLY }
    
    public static void runJobs(SchedulableContext context) {
    	
    	List<Schedulable__c> jobs = [select Name, Class_Name__c from Schedulable__c where Active__c = true];
        if(jobs.size() == 0) {
            jobs.add(new Schedulable__c(Name = 'Recurring Donation Updates', Class_Name__c = 'RD_RecurringDonations_SCHED', Active__c = true));
            jobs.add(new Schedulable__c(Name = 'Opportunity Rollups', Class_Name__c = 'RLLP_OppRollup_SCHED', Active__c = true));
            insert jobs;
        }
        
        List<Schedulable__c> jobsToUpdate = new List<Schedulable__c>();
        
        for(Schedulable__c job : jobs) {
            Type classType = Type.forName(job.Class_Name__c);
            Datetime lastTimeRun = job.Last_Time_Run__c;
            String frequency = job.Frequency__c;
            
            Boolean shouldRun = false;
            if(lastTimeRun == null) {
                shouldRun = true;
            } else if(frequency == SchedFrequency.HOURLY.name() && lastTimeRun.addHours(1) < System.now()) {
                shouldRun = true;
            } else if(frequency == SchedFrequency.DAILY.name() && lastTimeRun.addDays(1) < System.now()) {
                shouldRun = true;
            } else if(frequency == SchedFrequency.WEEKLY.name() && lastTimeRun.addDays(7) < System.now()) {
                shouldRun = true;
            } else if(frequency == SchedFrequency.MONTHLY.name() && lastTimeRun.addMonths(1) < System.now()) {
                shouldRun = true;
            } else if(frequency == SchedFrequency.QUARTERLY.name() && lastTimeRun.addMonths(4) < System.now()) {
                shouldRun = true;
            }
            
            if(classType != null && shouldRun) {     
               Object instance = classType.newInstance();
               if(instance instanceof UTIL_GlobalSchedulable.IScheduled)
                   //@TODO: do we need to check for the max number of jobs that can be scheduled and make 
                   //sure we don't go over the limit?
                   ((UTIL_GlobalSchedulable.IScheduled)instance).execute(context);
                   //Update last time run
                   job.Last_Time_Run__c = System.now();
                   jobsToUpdate.add(job);
            }
        }
        update jobsToUpdate;
    }
}