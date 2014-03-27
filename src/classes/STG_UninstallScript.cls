global with sharing class STG_UninstallScript implements UninstallHandler {

    global void onUninstall(UninstallContext context) {
    		
    	List<CronTrigger> scheduledJobs = [select Id, CronJobDetail.Id from CronTrigger 
    	   where CronJobDetail.Name = :UTIL_GlobalSchedulable.jobName and CronJobDetail.JobType = '7'];
    	
    	if(scheduledJobs.size() > 0)   
    	   System.abortJob(scheduledJobs[0].Id);
    }
}