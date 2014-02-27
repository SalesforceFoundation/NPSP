public with sharing class UTIL_JobScheduler {
    
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
    
}