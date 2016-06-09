/*
    Copyright (c) 2016, Salesforce.org
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
* @date 2016
* @group Engagement Plans
* @group-content ../../ApexDocContent/EngagementPlans.htm
* @description 
*/
public with sharing class EP_TaskCreator {

    private Map<Id, Engagement_Plan_Task__c> taskMap = new Map<Id, Engagement_Plan_Task__c>();
    private Map<Id, Engagement_Plan_Template__c> templateMap = new Map<Id, Engagement_Plan_Template__c>();
    private Map<Id, Id> targetObjectMap = new Map<Id, Id>();

    public void insertTasks(List<Engagement_Plan__c> engagementPlans) {
        List<Task> taskInsertEmail = new List<Task>();
        List<Task> taskInsertNoEmail = new List<Task>();

        buildMaps(engagementPlans);

        for (Engagement_Plan__c engagementPlan : engagementPlans) {
            Engagement_Plan_Template__c template = templateMap.get(engagementPlan.Engagement_Plan_Template__c);
            for (Engagement_Plan_Task__c epTask : (List<Engagement_Plan_Task__c>)template.getSObjects('Engagement_Plan_Tasks')) {
                Task newTask = createTask(epTask);
                
                if (epTask.Send_Email__c) {
                    taskInsertEmail.add(newTask);
                } else {
                    taskInsertNoEmail.add(newTask);
                }
            }
        }

        Database.DMLOptions options = new Database.DMLOptions();

        if (!taskInsertEmail.isEmpty()) {
            options.EmailHeader.triggerUserEmail = true;
            Database.insert(taskInsertEmail, options);
        }

        if (!taskInsertNoEmail.isEmpty()) {
            options.EmailHeader.triggerUserEmail = false;
            Database.insert(taskInsertNoEmail, options);
        }
    }

    private void buildMaps(List<Engagement_Plan__c> engagementPlans) {
        //collect template IDs and target objects from the engagement plans
        for (Engagement_Plan__c engagementPlan : engagementPlans) {
            templateMap.put(engagementPlan.Engagement_Plan_Template__c, null);
            targetObjectMap.put(engagementPlan.Id, EP_Utils.getTargetObject(engagementPlan));
        }

        //query for templates and related engagement plan tasks
        templateMap = new Map<Id, Engagement_Plan_Template__c>(
            [SELECT Id, Name, Skip_Weekends__c,
                (SELECT Id, Name, Engagement_Plan_Template__c, Engagement_Plan_Template__r.Skip_Weekends__c, 
                Assigned_To__c, Comments__c, Days_After__c, Delay_Type__c, Dependent_Task__c, Priority__c,
                Reminder__c, Send_Email__c, Type__c FROM Engagement_Plan_Tasks__r) 
            FROM Engagement_Plan_Template__c WHERE Id IN :templateMap.keySet()]
        );

        //build a task map for retreiving dependent task information
        for (Engagement_Plan_Template__c template : templateMap.values()) {
            for (Engagement_Plan_Task__c epTask : (List<Engagement_Plan_Task__c>)template.getSObjects('Engagement_Plan_Tasks')) {
                taskMap.put(epTask.Id, epTask);
            }
        }
    }

    public Task createTask(Engagement_Plan_Task__c epTask) {
        Date today = System.Today();
        
        Map<String,String> taskAPTaskFieldMap = new Map<String,String>();
        //Task field name -> Engagement_Plan_Task__c field name
        taskAPTaskFieldMap.put('Engagement_Plan_Task__c', 'Id');
        taskAPTaskFieldMap.put('Subject', 'Name');
        taskAPTaskFieldMap.put('Engagement_Plan_Task__c', 'Engagement_Plan_Template__c');
        taskAPTaskFieldMap.put('Priority', 'Priority__c');
        taskAPTaskFieldMap.put('OwnerId', 'Assigned_To__c');
        taskAPTaskFieldMap.put('Description', 'Comments__c');
        taskAPTaskFieldMap.put('Type', 'Type__c');
        taskAPTaskFieldMap.put('Status', 'Status__c');

        //copy fields
        Task result = new Task();
        for (String taskField : taskAPTaskFieldMap.keySet()) {
            result.put(taskField, taskAPTaskFieldMap.get(taskField));
        }

        //Non Dependent Task defaults
        if (epTask.Dependent_Task__c == null) {
            result.ActivityDate = today;
            if (String.isBlank(result.Status)) {
                result.Status = 'Not Started';
            }
            if (epTask.Reminder__c) {
                result.IsReminderSet = true;
                result.ReminderDateTime = Datetime.newInstance(today.year(), today.month(), today.day());
                result.ReminderDateTime = result.ReminderDateTime.addMinutes(Integer.valueOf(epTask.Reminder_Minutes__c));
            }
        //Dependent Task defaults
        } else {
            
            result.ActivityDate = calcDependentTaskDelay(epTask, today);
            result.Status = 'Waiting on Dependent Task';
        }

        return result;
    }

    private Date calcDependentTaskDelay(Engagement_Plan_Task__c epTask, Date startDate) {
        Integer daysDelay = 0;
        Engagement_Plan_Task__c currentTask = epTask;
        
        while (currentTask.Dependent_Task__c != null) {
            if (currentTask.Days_After__c != null) {
                daysDelay += (Integer)currentTask.Days_After__c;
            }
            currentTask = taskMap.get(currentTask.Dependent_Task__c);
        }

        Date result = startDate.addDays(daysDelay);

        if (epTask.Engagement_Plan_Template__r.Skip_Weekends__c) {
            result = skipWeekend(result);
        } 

        return result;
    }

    private Date skipWeekend(Date originalDate) {
        // find if the due date falls on a Saturday or Sunday; add 1 day for Sunday and 2 for Saturday
        Date result = originalDate;
        Date refDate = Date.newInstance(1900, 1, 7);  // Jan 7 1900 = Sun
        Integer dayOfWeek = Math.mod(refDate.daysBetween(originalDate), 7); // 0 = Sun ... 6 = Sat
        
        if (dayOfWeek == 0) {
            result.addDays(1);
        } else if (dayOfWeek == 6) {
            result.addDays(2);
        }
        return result;
    }
}