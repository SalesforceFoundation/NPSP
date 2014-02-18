public with sharing class UTIL_JobScheduler {
	
	// checks whether night batches should be enabled and set up
    public static void scheduleRecurringDonationsUpdate() {
        
        //Flag turn off by default on install 
        if (!STG_Panel.stgService.stgRD.npe03__Disable_Nightly_Job__c) {
            
            //@TODO: why the limit?
            Integer scheduledJobLimit = 25; 
            boolean alreadyScheduled = false;            
            
            List<CronTrigger> scheduledUpdates = [SELECT Id FROM CronTrigger limit :scheduledJobLimit];
            
            //Flag left empty by default on install
            if (STG_Panel.stgService.stgRD.npe03__Nightly_Update_ID__c != null) {
                for (CronTrigger thisScheduledJob : scheduledUpdates) { 
                    if (thisScheduledJob.id == STG_Panel.stgService.stgRD.npe03__Nightly_Update_ID__c) {
                        alreadyScheduled = true;
                        break;
                    }
                }
            }
                        
            if (!alreadyScheduled) {
                if (scheduledUpdates.size() < scheduledJobLimit) {     
                    
                    RD_RecurringDonations_SCHED nightlyJob = new RD_RecurringDonations_SCHED(); 
                    //need to check for already scheduled job
                    String sch='17 11 3 * * ?'; 
                    scheduledUpdates.clear();
                    scheduledUpdates = [SELECT Id FROM CronTrigger where cronExpression = :sch];
                    if (scheduledUpdates.size()==0) {
                        String jobId = system.schedule('Recurring Donation Updates', sch ,nightlyJob);
                        STG_Panel.stgService.stgRD.npe03__Nightly_Update_ID__c = jobId;
                    }
                    else {
                        STG_Panel.stgService.stgRD.npe03__Nightly_Update_ID__c = scheduledUpdates[0].Id;
                    }
                    //if we update page settings, we need to call a redirect
                    update STG_Panel.stgService.stgRD;
                } 
            }    
        }
    }
    
    public static void scheduleJobIfNotScheduled(String JobName, String frequency, String className) {
        
        //Check if the job is already scheduled - CronJobDetail is the parent and CronTrigger is the child
        //Type '7' is for scheduled Apex
        List<CronTrigger> scheduledJobs = [select Id, CronJobDetail.Id from CronTrigger 
                    where CronJobDetail.Name = :JobName and CronJobDetail.JobType = '7'];
        
        if(scheduledJobs.size() == 0) {
        	Type classType = Type.forName(className);
            
            if(classType != null) {     
               Object instance = classType.newInstance();
               if(instance instanceof Schedulable)
        	       System.schedule(JobName, frequency, (Schedulable)instance);
            }
        }
    }

}