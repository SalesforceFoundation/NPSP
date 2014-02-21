public with sharing class UTIL_JobScheduler implements Schedulable {
    
    public Interface IScheduled {
    	void execute(SchedulableContext context);
    }
    
    public void execute(SchedulableContext context) {
        
        List<Schedulable__c> jobs = [select Name, Class_Name__c from Schedulable__c where Active__c = true];
        if(jobs.size() == 0) {
	        jobs.add(new Schedulable__c(Name = 'Recurring Donation Updates', Class_Name__c = 'RD_RecurringDonations_SCHED', Active__c = true));
	        jobs.add(new Schedulable__c(Name = 'Opportunity Rollups', Class_Name__c = 'RLLP_OppRollup_SCHED', Active__c = true));
	        insert jobs;
        }
        
        for(Schedulable__c job : jobs) {
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