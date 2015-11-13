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
    
}