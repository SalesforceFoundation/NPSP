public with sharing class UTIL_JobScheduler implements Schedulable {
    
    public Interface IScheduled {
    	void execute(SchedulableContext context);
    }
    
    public void execute(SchedulableContext context) {
        
        List<Schedulable__c> jobs = [select Name, Class_Name__c from Schedulable__c where Active__c = true];
        
        for(Schedulable__c job : jobs) {
	        //Check if the job is already scheduled - CronJobDetail is the parent and CronTrigger is the child
	        //Type '7' is for scheduled Apex
	        List<CronTrigger> scheduledJobs = [select Id, CronJobDetail.Id from CronTrigger 
	                    where CronJobDetail.Name = :job.Name and CronJobDetail.JobType = '7'];
	        
	        if(scheduledJobs.size() == 0) {
	        	Type classType = Type.forName(job.Class_Name__c);
	            
	            if(classType != null) {     
	               Object instance = classType.newInstance();
	               if(instance instanceof IScheduled)
	                   //@TODO: do we need to check for the ma number of jobs that can be scheduled and make 
	                   //sure we don't go over the limit?
	        	       ((IScheduled)instance).execute(context);
	            }
	        }
        }
    }

}