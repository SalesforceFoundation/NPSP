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
    * @description Empty constructor.
    */
    public UTIL_MasterSchedulableHelper() {}
    
    /*******************************************************************************************************
    * @description Abort deprecated master scheduled jobs. They are all replaced by standard scheduled jobs.
    * @return void
    */
    public static void abortOldScheduledJobs() {
        //Abort the old NPSPv3 schedulable, since we have changed the name and are using a new class now (as of July 24 2014).
        //Abort the scheduled jobs from the old NPSP packages.
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

    @testVisible
    private static List<String> jobsToAbort = new List<String>();

    /*******************************************************************************************************
    * @description This map contains all necessary information for scheduling default NPSP jobs:
    * Job name as key, and a list containing the cron expression for that job and its class name. Also builds
    * a collection of jobsToAbort - a list of job names that if exist should be aborted.
    */
    @testVisible
    public static Map<String, List<String>> defaultScheduledJobs {
        get {
            if (defaultScheduledJobs == null) {
                jobsToAbort.clear();
                defaultScheduledJobs = new Map<String, List<String>>{
                    'NPSP 00 - Error Processing'                => new List<String>{'0 0 * * * ?',  'ERR_AsyncErrors_SCHED'},
                    // Start the Recurring Donations job one hour before the Rollup jobs to avoid any conflict with
                    // the Opps that may be created/modified by the RD job.
                    'NPSP 06 - Recurring Donation Updates'      => new List<String>{'0 0 22 ? * *', 'RD_RecurringDonations_BATCH'},
                    'NPSP 07 - Seasonal Address Updates'        => new List<String>{'0 0 23 ? * *', 'ADDR_Seasonal_SCHED'},
                    'NPSP 08 - Level Assignment Updates'        => new List<String>{'0 0 4 ? * *',  'LVL_LevelAssign_SCHED'},
                    'NPSP 09 - Data Import Batch Processing'    => new List<String>{'0 0 22 ? * *', 'BDI_DataImportBatch_SCHED'}
                };
                if (CRLP_Rollup_SVC.isCustomizableRollupEngineEnabled) {
                    // When the Customizable Rollups Engine is enabled, the actual rollup job target classes change, but
                    // keep the naming similar and stagger the job start times slightly. Include a 3rd list item for the
                    // primary SObject to use when instantiating the scheduler
                    // The last parameter is set to True for LDV jobs (i.e, pass True to the CRLP_RollupScheduler() instance).
                    // Jobs are staggered by 10 minutes to hopefully improve performance when each of the jobs starts with a large query
                    defaultScheduledJobs.put('NPSP 01 - Customizable Rollups - Account Hard Credit', new List<String>{'0 0 23 ? * *', 'CRLP_RollupScheduler', 'Account', 'False'});
                    defaultScheduledJobs.put('NPSP 02 - Customizable Rollups - Contact Hard Credit', new List<String>{'0 10 23 ? * *', 'CRLP_RollupScheduler', 'Contact', 'False'});
                    defaultScheduledJobs.put('NPSP 03A - Customizable Rollups - Account Hard Credit for Large Data Volumes', new List<String>{'0 20 23 ? * *', 'CRLP_RollupScheduler', 'Account', 'True'});
                    defaultScheduledJobs.put('NPSP 03B - Customizable Rollups - Contact Hard Credit for Large Data Volumes', new List<String>{'0 30 23 ? * *', 'CRLP_RollupScheduler', 'Contact', 'True'});
                    defaultScheduledJobs.put('NPSP 04 - Customizable Rollups - Soft Credits', new List<String>{'0 50 23 ? * *', 'CRLP_RollupScheduler', SObjectType.Partial_Soft_Credit__c.getName(), 'True'});
                    defaultScheduledJobs.put('NPSP 05 - Customizable Rollups - General Allocation Units', new List<String>{'0 0 23 ? * *', 'CRLP_RollupScheduler', SObjectType.General_Accounting_Unit__c.getName(), 'True'});

                    // The following jobs should be aborted if the Customizable Rollups jobs are being enabled
                    jobsToAbort.add('NPSP 01 - Opportunity Account Rollups');
                    jobsToAbort.add('NPSP 02 - Opportunity Contact Rollups');
                    jobsToAbort.add('NPSP 03 - Opportunity Household Rollups');
                    jobsToAbort.add('NPSP 04 - Opportunity Soft Credit Rollups');
                    jobsToAbort.add('NPSP 05 - GAU Allocation Rollups');

                } else {
                    // Legacy Rollups Engine jobs are enabled
                    defaultScheduledJobs.put('NPSP 01 - Opportunity Account Rollups', new List<String>{'0 0 23 ? * *', 'RLLP_OppAccRollup_BATCH'});
                    defaultScheduledJobs.put('NPSP 02 - Opportunity Contact Rollups', new List<String>{'0 0 23 ? * *', 'RLLP_OppContactRollup_BATCH'});
                    defaultScheduledJobs.put('NPSP 03 - Opportunity Household Rollups', new List<String>{'0 0 23 ? * *', 'RLLP_OppHouseholdRollup_BATCH'});
                    defaultScheduledJobs.put('NPSP 04 - Opportunity Soft Credit Rollups', new List<String>{'0 0 23 ? * *', 'RLLP_OppSoftCreditRollup_BATCH'});
                    defaultScheduledJobs.put('NPSP 05 - GAU Allocation Rollups', new List<String>{'0 0 23 ? * *', 'ALLO_Rollup_SCHED'});

                    // The following jobs should be aborted if the Customizable Rollups jobs are NOT enabled
                    jobsToAbort.add('NPSP 01 - Customizable Rollups - Account Hard Credit');
                    jobsToAbort.add('NPSP 02 - Customizable Rollups - Contact Hard Credit');
                    jobsToAbort.add('NPSP 03A - Customizable Rollups - Account Hard Credit for Large Data Volumes');
                    jobsToAbort.add('NPSP 03B - Customizable Rollups - Contact Hard Credit for Large Data Volumes');
                    jobsToAbort.add('NPSP 04 - Customizable Rollups - Soft Credits');
                    jobsToAbort.add('NPSP 05 - Customizable Rollups - General Allocation Units');
                }
            }
            return defaultScheduledJobs;
        } private set;
    }

    /*******************************************************************************************************
    * @description Schedules all NPSP jobs that are not already scheduled, and abort any jobs that need to be
    * aborted (where User is inactive or where listed in the jobsToAbort collection).
    * @return void
    */
    public static void setScheduledJobs() {

        Map<String, CronTrigger> scheduledJobs = new Map<String, CronTrigger>();
        
        //query for all scheduled apex
        for (CronTrigger ct : [SELECT Id, CronExpression, CronJobDetail.Name, CreatedBy.Name, CreatedBy.IsActive
                FROM CronTrigger WHERE CronJobDetail.JobType = '7']) {
            scheduledJobs.put(ct.CronJobDetail.Name, ct);
        }

        for (String jobName : defaultScheduledJobs.keySet()) {
            //schedule the job if it doesn't exist and they haven't disabled auto scheduling
            if (!scheduledJobs.containsKey(jobName)) {
                if (!UTIL_CustomSettingsFacade.getOrgErrorSettings().Don_t_Auto_Schedule_Default_NPSP_Jobs__c) {
                    createJob(jobName);
                }
            } else {
                //if it's already scheduled, but the ghost user or an inactive user scheduled it,
                //then abort and reschedule
                CronTrigger currentJob = scheduledJobs.get(jobName);
                if (currentJob.CreatedBy.Name == 'Nonprofit Success Pack' || !currentJob.CreatedBy.isActive) {
                    System.abortJob(currentJob.Id);
                    
                    //reuse their CronExpression so it's scheduled at the time they chose
                    defaultScheduledJobs.get(jobName)[0] = currentJob.CronExpression;

                    createJob(jobName);
                }
            }
        }

        // Abort Jobs that need to be aborted. For example, if switching from the Legacy Rollups to the new
        // Customizable Rollups engine, the old rollup jobs need to be aborted. Same if the reverse is done.
        for (String jobName : jobsToAbort) {
            if (scheduledJobs.containsKey(jobName)) {
                CronTrigger currentJob = scheduledJobs.get(jobName);
                System.abortJob(currentJob.Id);
            }
        }
    }

    /*******************************************************************************************************
    * @description Schedules a job based on that job's name.
    * @return void
    */
    private static void createJob(String jobName) {
        String cronExpression = defaultScheduledJobs.get(jobName)[0];
        String className = defaultScheduledJobs.get(jobName)[1];

        try {
            Schedulable classInstance;
            if (className != 'CRLP_RollupScheduler') {
                classInstance = (Schedulable) Type.forName(className).newInstance();
            } else {
                // The Customizable Rollups engine scheduler class needs to have parameters passed into the
                // class instantiation. This is not possible using Type.forName().newInstance().
                String objName = defaultScheduledJobs.get(jobName)[2];
                SObjectType objType = UTIL_Describe.getSObjectType(objName);
                Boolean isLDV = defaultScheduledJobs.get(jobName)[3] == 'True';
//                classInstance = new CRLP_RollupScheduler(isLDV, objType);
            }
            System.schedule(jobName, cronExpression, classInstance);
        } catch (Exception ex) {
            ERR_Handler.processError(ex, ERR_Handler_API.Context.STTG);
        }
    }
}