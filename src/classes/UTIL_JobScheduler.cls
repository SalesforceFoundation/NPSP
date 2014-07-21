public without sharing class UTIL_JobScheduler {
    
    public static String scheduleJobIfNotScheduled(String JobName, String frequency, String className) {
        
        //Check if the job is already scheduled - CronJobDetail is the parent and CronTrigger is the child
        //Type '7' is for scheduled Apex
        List<CronTrigger> scheduledJobs = [select Id, CronJobDetail.Id from CronTrigger 
                    where CronJobDetail.Name = :JobName and CronJobDetail.JobType = '7'];
        
        if(scheduledJobs.size() == 0) {
            Type classType = Type.forName(className);
            
            if(classType != null) {     
               Object instance = classType.newInstance();
               if(instance instanceof Schedulable)
                   return System.schedule(JobName, frequency, (Schedulable)instance);
            }
        }
        return null;
    }
    
    public static Boolean canRunBatch() {
        Integer jobs = [Select count() From AsyncApexJob Where JobType = 'BatchApex' and (Status = 'Queued' or Status = 'Processing' 
                       or Status = 'Preparing')];
        if(jobs < 5)
            return true;
        return false;           
    }
}