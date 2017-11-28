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

    /*******************************************************************************************************
    * @description This map contains all necessary information for scheduling default NPSP jobs:
    * Job name as key, and a list containing the cron expression for that job and its class name.
    */
    public static Map<String, List<String>> defaultScheduledJobs {
        get {
            if (defaultScheduledJobs == null) {
                defaultScheduledJobs = new Map<String, List<String>>{
                    'NPSP 00 - Error Processing'                => new List<String>{'0 0 * * * ?',  'ERR_AsyncErrors_SCHED'},
                    'NPSP 06 - Recurring Donation Updates'      => new List<String>{'0 0 23 ? * *', 'RD_RecurringDonations_BATCH'},
                    'NPSP 07 - Seasonal Address Updates'        => new List<String>{'0 0 23 ? * *', 'ADDR_Seasonal_SCHED'},
                    'NPSP 08 - Level Assignment Updates'        => new List<String>{'0 0 4 ? * *',  'LVL_LevelAssign_SCHED'},
                    'NPSP 09 - Data Import Batch Processing'    => new List<String>{'0 0 22 ? * *', 'BDI_DataImportBatch_SCHED'}
                };
                if (CRLP_Rollup_SVC.isCustomizableRollupEngineEnabled) {
                    // When the Customizable Rollups Engine is enabled, the actual rollup job target classes change, but
                    // keep the naming similar and stagger the job start times slightly. Include a 3rd list item for the
                    // primary SObject to use when instantiating the scheduler
                    // TODO Discuss the staggered schedule. Thee main concern is SoftCredit job overlapping with the main jobs
                    defaultScheduledJobs.put('NPSP 01 - Opportunity Account Rollups (New)', new List<String>{'0 0 23 ? * *', 'CRLP_RollupScheduler', 'Account'});
                    defaultScheduledJobs.put('NPSP 02 - Opportunity Contact Rollups (New)', new List<String>{'0 10 23 ? * *', 'CRLP_RollupScheduler', 'Contact'});
                    defaultScheduledJobs.put('NPSP 03 - Opportunity Account LDV Rollups (New)', new List<String>{'0 20 23 ? * *', 'CRLP_RollupScheduler', 'Account'});
                    defaultScheduledJobs.put('NPSP 03 - Opportunity Contact LDV Rollups (New)', new List<String>{'0 30 23 ? * *', 'CRLP_RollupScheduler', 'Contact'});
                    // TODO Finalize SoftCredit rollups
                    // defaultScheduledJobs.put('NPSP 04 - Opportunity Soft Credit Rollups (New)', new List<String>{'0 50 23 ? * *', 'CRLP_RollupScheduler', 'TODO'});
                    defaultScheduledJobs.put('NPSP 05 - GAU Allocation LDV Rollups (New)', new List<String>{'0 0 23 ? * *', 'CRLP_RollupScheduler', SObjectType.General_Accounting_Unit__c.getName()});

                } else {
                    // Legacy Rollups Engine jobs
                    defaultScheduledJobs.put('NPSP 01 - Opportunity Account Rollups', new List<String>{'0 0 23 ? * *', 'RLLP_OppAccRollup_BATCH'});
                    defaultScheduledJobs.put('NPSP 02 - Opportunity Contact Rollups', new List<String>{'0 0 23 ? * *', 'RLLP_OppContactRollup_BATCH'});
                    defaultScheduledJobs.put('NPSP 03 - Opportunity Household Rollups', new List<String>{'0 0 23 ? * *', 'RLLP_OppHouseholdRollup_BATCH'});
                    defaultScheduledJobs.put('NPSP 04 - Opportunity Soft Credit Rollups', new List<String>{'0 0 23 ? * *', 'RLLP_OppSoftCreditRollup_BATCH'});
                    defaultScheduledJobs.put('NPSP 05 - GAU Allocation Rollups', new List<String>{'0 0 23 ? * *', 'ALLO_Rollup_SCHED'});
                }
            }
            return defaultScheduledJobs;
        } private set;
    }

    /*******************************************************************************************************
    * @description Schedules all NPSP jobs that are not already scheduled.
    * @return void
    */
    public static void setScheduledJobs() {

        Map<String, CronTrigger> scheduledJobs = new Map<String, CronTrigger>();
        
        //query for all scheduled apex
        for (CronTrigger ct : [SELECT Id, CronExpression, CronJobDetail.Name, CreatedBy.Name, CreatedBy.IsActive FROM CronTrigger WHERE CronJobDetail.JobType = '7']) {
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
                // Scheduler Instantiation. This is not possible using Type.forName().newInstance().
                String objName = defaultScheduledJobs.get(jobName)[2];
                system.debug('>> ObjectName = ' + jobName + ' / ' + objName);
                SObjectType objType = UTIL_Describe.getSObjectType(objName);
                Boolean isLDV = jobName.contains('LDV');
                classInstance = new CRLP_RollupScheduler(isLDV, objType);
            }
            System.schedule(jobName, cronExpression, classInstance);
        } catch (Exception ex) {
            ERR_Handler.processError(ex, ERR_Handler_API.Context.STTG);
        }
    }
}