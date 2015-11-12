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
    * Neither the name of the Salesforce.org nor the names of
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
* @description The UTIL_JobScheduler class is deprecated.
*/
public with sharing class UTIL_JobScheduler {
    
    /*******************************************************************************************************
    * @description Schedules a class that implements the Schedulable interface, if it's not already scheduled.
    * @param JobName The name to give the scheduled job.
    * @param frequency The frequency to schedule the job at.
    * @param className The class to schedule. Should implement the Schedulable interface.
    * @return The ID of the scheduled job.
    */
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
    
    /*******************************************************************************************************
    * @description Whether the system can run another batch job at the time, without hitting a limit.
    */
    public static Boolean canRunBatch() {
        Integer jobs = [Select count() From AsyncApexJob Where JobType = 'BatchApex' and (Status = 'Queued' or Status = 'Processing' 
                       or Status = 'Preparing')];
        if(jobs < 5)
            return true;
        return false;           
    }
}
