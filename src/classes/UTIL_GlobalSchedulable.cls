/*
    Copyright (c) 2014 Salesforce.com Foundation
    All rights reserved.
    
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
    
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Salesforce.com Foundation nor the names of
      its contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.
 
    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS 
    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE 
    COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, 
    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT 
    LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN 
    ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
    POSSIBILITY OF SUCH DAMAGE.
*/
/**
* @author Salesforce.com Foundation
* @date 2014 
* @description Global Schedulable for the NPSP package. This will be the only
* schedulable that exists in the package.
*/
public with sharing class UTIL_GlobalSchedulable implements Schedulable {
	
	public static String jobName = 'NPSP Global Scheduler';
    
    public enum SchedFrequency { HOURLY, DAILY, WEEKLY, MONTHLY, QUARTERLY }
    
    public static void execute(SchedulableContext context) {
        
        List<Schedulable__c> jobs = [select Name, Class_Name__c, Last_Time_Run__c, Frequency__c 
                                       from Schedulable__c where Active__c = true];
        
        List<Schedulable__c> jobsToUpdate = new List<Schedulable__c>();
        
        for(Schedulable__c job : jobs) {
            Type classType = Type.forName(job.Class_Name__c);
            Datetime lastTimeRun = job.Last_Time_Run__c;
            String frequency = job.Frequency__c;
            
            Boolean shouldRun = false;
            if(lastTimeRun == null) {
                shouldRun = true;
            } else if(frequency == SchedFrequency.HOURLY.name() && (lastTimeRun == null || lastTimeRun.addHours(1) < System.now())) {
                shouldRun = true;
            } else if(frequency == SchedFrequency.DAILY.name() && (lastTimeRun == null || lastTimeRun.addDays(1) < System.now())) {
                shouldRun = true;
            } else if(frequency == SchedFrequency.WEEKLY.name() && (lastTimeRun == null || lastTimeRun.addDays(7) < System.now())) {
                shouldRun = true;
            } else if(frequency == SchedFrequency.MONTHLY.name() && (lastTimeRun == null || lastTimeRun.addMonths(1) < System.now())) {
                shouldRun = true;
            } else if(frequency == SchedFrequency.QUARTERLY.name() && (lastTimeRun == null || lastTimeRun.addMonths(3) < System.now())) {
                shouldRun = true;
            }
            
            if(classType != null && shouldRun) {     
               Object instance = classType.newInstance();
               if(instance instanceof UTIL_IScheduled)
                   try {
                       ((UTIL_IScheduled)instance).execute(context);
                       //Update last time run
                       job.Last_Time_Run__c = System.now();
                       jobsToUpdate.add(job);
                   } catch (Exception e) {
                       //The class itself should handle any errors. We don't want to have a reference to ERR_Handler
                       //here because then we won't be able to push updates that modify it if the job is scheduled
                   }
            }
        }
        update jobsToUpdate;
    }
    
    // verify that our Global Scheduler is actually scheduled, and that all of the entries are valid - called by HealthCheck
    public static void verifyScheduledJobs(STG_PanelHealthCheck_CTRL ctrl) {
    	
    	// make sure the Global Job is scheduduled
        List<CronTrigger> scheduledJobs = [select Id, CronJobDetail.Id from CronTrigger 
           where CronJobDetail.Name = :UTIL_GlobalSchedulable.jobName and CronJobDetail.JobType = '7'];        
        if (scheduledJobs.size() == 0) {
            ctrl.createDR('NPSP Global Scheduler', 'Error', 'The NPSP Global Scheduled class is not scheduled.', 
                'You must schedule the class UTIL_GlobalSchedulable to run daily with the job name ' + UTIL_GlobalSchedulable.jobName + '.');
            return;            
        }

        // make sure the entries we expect are there.
        Integer numOfJobs = [select count() from Schedulable__c where Class_Name__c IN ('RD_RecurringDonations_SCHED','RLLP_OppRollup_SCHED','ADDR_SEASONAL_SCHED')];
        if (numOfJobs != 3) {
            ctrl.createDR('NPSP Global Scheduler', 'Error', 
                'One or more of the Opportunity Rollup, Recurring Donation, and Seasonal Address jobs are missing from the Schedulable__c object.', 
                'You must add records for RLLP_OppRollup_SCHED, RD_RecurringDonations_SCHED, and ADDR_SEASONAL_SCHED to Schedulable__c in order for these features to work correctly.');
            return;            
        }
         
        // now make sure all entries are valid
        boolean isValidAll = true;
        List<Schedulable__c> jobs = [select Name, Class_Name__c, Last_Time_Run__c, Frequency__c from Schedulable__c where Active__c = true];
        for (Schedulable__c job : jobs) {
            Type classType = Type.forName(job.Class_Name__c);
            if (classType != null) {
                Object instance = classType.newInstance();
                if (instance != null) {
					if (instance instanceof UTIL_IScheduled) {
						// this entry is good!
						continue;
					}
                }
            }
            isValidAll = false;
            ctrl.createDR('NPSP Global Scheduler', 'Error', 
                'The record ' + job.Class_Name__c + ' in the Schedulable__c object is not valid.', 
                'You must update the record to have a valid Class the implements the UTIL_IScheduled interface.');
        }            
         
        if (isValidAll) {
            ctrl.createDR('NPSP Global Scheduler', 'Success', null, null);
        }  	
    	
    }
}