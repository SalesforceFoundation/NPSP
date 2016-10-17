/*
    Copyright (c) 2014 Salesforce.org
    All rights reserved.
    
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
    
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Salesforce.org nor the names of
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
* @author Salesforce.org
* @date 2014 
* @group Utilities
* @description Calls all classes to execute at a specific run of the master scheduler.
*/
public without sharing class UTIL_MasterSchedulableHelper {

    /*******************************************************************************************************
    * @description The interface classes to be run by the master schedulable (the only one that runs scheduled 
    * classes in the package) should implement.
    */
    public interface UTIL_IRecurring {
        Boolean executeReturnStatus();
    }

    /*******************************************************************************************************
    * @description The frequency options.
    */
    public enum SchedFrequency { HOURLY, DAILY, WEEKLY, MONTHLY, QUARTERLY }
    
    /*******************************************************************************************************
    * @description The classes to be run by the master schedulable.
    */
    public static List<String> scheduledClasses = new List<String> {'RD_RecurringDonations_BATCH', 'RLLP_OppAccRollup_BATCH', 'RLLP_OppContactRollup_BATCH', 
    	'RLLP_OppHouseholdRollup_BATCH', 'RLLP_OppSoftCreditRollup_BATCH', 'ADDR_SEASONAL_SCHED', 'ALLO_Rollup_SCHED', 'LVL_LevelAssign_SCHED', 'ERR_AsyncErrors'};
    
    /*******************************************************************************************************
    * @description The name to give to the instance of the master schedulable.
    */
    public static final String scheduledJobName = 'NPSP Scheduler';
    
    /*******************************************************************************************************
    * @description Constructor that calls the method that runs the classes.
    */
    public UTIL_MasterSchedulableHelper() {
        runRecurringJobs();
    }
    
    /*******************************************************************************************************
    * @description Runs the class, as scheduled.
    * @param context The system context. Provided by the platform.
    * @return void
    */
    public void runRecurringJobs() {
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
            } else if(frequency.equalsIgnoreCase(SchedFrequency.HOURLY.name()) && (lastTimeRun == null || lastTimeRun.addHours(1) < System.now())) {
                shouldRun = true;
            } else if(frequency.equalsIgnoreCase(SchedFrequency.DAILY.name()) && (lastTimeRun == null || lastTimeRun.addDays(1) < System.now())) {
                shouldRun = true;
            } else if(frequency.equalsIgnoreCase(SchedFrequency.WEEKLY.name()) && (lastTimeRun == null || lastTimeRun.addDays(7) < System.now())) {
                shouldRun = true;
            } else if(frequency.equalsIgnoreCase(SchedFrequency.MONTHLY.name()) && (lastTimeRun == null || lastTimeRun.addMonths(1) < System.now())) {
                shouldRun = true;
            } else if(frequency.equalsIgnoreCase(SchedFrequency.QUARTERLY.name()) && (lastTimeRun == null || lastTimeRun.addMonths(3) < System.now())) {
                shouldRun = true;
            }
            
            if(classType != null && shouldRun) {     
               Object instance = classType.newInstance(); 
               if(instance instanceof UTIL_IRecurring) {
                   UTIL_Debug.debug(LoggingLevel.WARN, '****Running ' + instance);
                   Boolean wasRun = ((UTIL_IRecurring)instance).executeReturnStatus();
                   //Update last time run
                   if(wasRun) {
                       job.Last_Time_Run__c = System.now();
                       jobsToUpdate.add(job);
                   }
               }
            }
        }
        if (!jobsToUpdate.isEmpty()) {
            update jobsToUpdate;
        }
    }
    
    /*******************************************************************************************************
    * @description Aborst deprecated scheduled jobs. They are all replaced by the master schedulable.
    * @return void
    */
    public static void abortOldScheduledJobs() {
        //Abort the old NPSPv3 schedulable, since we have changed the name and are using a new class now (as of July 24 2014).
        //Abort the scheduled jobs from the old NPSP packages.
        //Abort the "new" scheduled jobs so that they get rescheduled again from the settings page. We just changed the name
        //slightly (added a space) so that they get rescheduled (with different name when a user visits the settings page).
        List<String> jobNames = new List<String>{'NPSP Global Scheduler', 'Nightly Opportunity Roll Up', 'Recurring Donation Updates', 
            'NPSP Scheduler1', 'NPSP Scheduler2', 'NPSP Scheduler3', 'NPSP Scheduler 1', 'NPSP Scheduler 2', 'NPSP Scheduler 3'};
        List<CronTrigger> oldScheduledJobs = [select Id, CronJobDetail.Id from CronTrigger 
           where CronJobDetail.Name IN :jobNames and CronJobDetail.JobType = '7'];
        if(oldScheduledJobs != null && oldScheduledJobs.size() > 0) {
            for(CronTrigger job : oldScheduledJobs) {
                 System.abortJob(job.Id);
            }
        }   
    }
    
    /*******************************************************************************************************
    * @description Populates the table that contains the data on the classes to be run by the master schedulable with the defaults.
    * @return void
    */
    public static void setSchedulableTable() {
    	
    	List<Schedulable__c> existingSchedClasses = [select Id from Schedulable__c where Class_Name__c IN :scheduledClasses];
    	
    	if(existingSchedClasses.size() != scheduledClasses.size()) {
	        // clean table, in case it's a push upgrate and we have added or removed entries from the table.
	        delete existingSchedClasses;
	        
	        // create records for the jobs that are to run recursively
	        List<Schedulable__c> jobs = new List<Schedulable__c>();
	        jobs.add(new Schedulable__c(Name = 'Recurring Donation Updates', Class_Name__c = scheduledClasses[0], 
	                    Active__c = true, Frequency__c = 'Daily'));
	        jobs.add(new Schedulable__c(Name = 'Opportunity Account Rollups', Class_Name__c = scheduledClasses[1], 
	                Active__c = true, Frequency__c = 'Daily'));
	        jobs.add(new Schedulable__c(Name = 'Opportunity Contact Rollups', Class_Name__c = scheduledClasses[2], 
	                Active__c = true, Frequency__c = 'Daily'));
	        jobs.add(new Schedulable__c(Name = 'Opportunity Household Rollups', Class_Name__c = scheduledClasses[3], 
	                Active__c = true, Frequency__c = 'Daily'));
	        jobs.add(new Schedulable__c(Name = 'Opportunity Soft Credit Rollups', Class_Name__c = scheduledClasses[4], 
	                Active__c = true, Frequency__c = 'Daily'));
	        jobs.add(new Schedulable__c(Name = 'Seasonal Address Updates', Class_Name__c = scheduledClasses[5],
	                Active__c = true, Frequency__c = 'Daily'));
            jobs.add(new Schedulable__c(Name = 'GAU Allocations Rollups', Class_Name__c = scheduledClasses[6],
                    Active__c = true, Frequency__c = 'Daily'));
            jobs.add(new Schedulable__c(Name = 'Level Assignment Batch', Class_Name__c = scheduledClasses[7],
                    Active__c = true, Frequency__c = 'Daily'));
            jobs.add(new Schedulable__c(Name = 'Asynchronous Error Processing', Class_Name__c = scheduledClasses[8],
                    Active__c = true, Frequency__c = 'Hourly'));
	        insert jobs;
    	}    
    }
    
    /*******************************************************************************************************
    * @description Schedules the necessary instances of the master schedulable, to make sure all classes that need
    * to run periodically have the chance to run in the specified time interval.
    * @return void
    */
    public static void scheduleMasterJobs() {
        // schedule master cron jobs.
        // NOTE: if more jobs are added to this list, they must also be added to the code in
        // STG_PanelHealthCheck_CTRL.verifyScheduledJobs() so that HealthCheck will include
        // verifying they exist.
        UTIL_JobScheduler.scheduleJobIfNotScheduled(scheduledJobName, '0 0 * * * ?', 'UTIL_MasterSchedulable');
    }
}