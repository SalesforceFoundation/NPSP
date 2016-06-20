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

    /** @description Map of all EP Tasks from templates associated to the trigger set. */
    private Map<Id, Engagement_Plan_Task__c> taskMap = new Map<Id, Engagement_Plan_Task__c>();
    /** @description MAp of all templates from the trigger set and their associated EP Tasks.*/
    private Map<Id, Engagement_Plan_Template__c> templateMap = new Map<Id, Engagement_Plan_Template__c>();
    /** @description EP_Utils class for calculating which lookup field Engagement Plans use and related operations.*/
    private EP_Utils util;

    /*******************************************************************************************************
    * @description Inserts Tasks based on the insert of Engagement Plan objects.
    * @param engagementPlans A list of Engagement Plans to create Tasks for.
    * @return void This method inserts Task objects directly, as DML options are needed on certain Tasks
    * for sending emails.
    ********************************************************************************************************/
    public void insertTasks(List<Engagement_Plan__c> engagementPlans) {
        List<Task> taskInsertEmail = new List<Task>();
        List<Task> taskInsertNoEmail = new List<Task>();

        buildMaps(engagementPlans);
        util = new EP_Utils(engagementPlans);

        for (Engagement_Plan__c engagementPlan : engagementPlans) {
            Engagement_Plan_Template__c template = templateMap.get(engagementPlan.Engagement_Plan_Template__c);
            for (Engagement_Plan_Task__c epTask : template.Engagement_Plan_Tasks__r) {
                Task newTask = createTask(epTask);
                assignTask(newTask, util.targetObjectIdMap.get(engagementPlan.id));

                //newTask.Engagement_Plan__c = engagementPlan.Id;

                //assign owner based on template setting
                if (newTask.OwnerId == null) {
                    if (template.Blank_Assignment_Rule__c == 'User Creating Action Plan') {
                        newTask.OwnerId = UserInfo.getUserId();
                    } else {
                        //get the owner of the record this engagement plan is being applied to
                        newTask.OwnerId = util.targetOwnerMap.get(engagementPlan.id);
                    }
                }

                //add to appropriate list based on the email setting.
                if (epTask.Send_Email__c && epTask.Dependent_Task__c == null) {
                    taskInsertEmail.add(newTask);
                } else {
                    taskInsertNoEmail.add(newTask);
                }
            }
        }

        Database.DMLOptions options = new Database.DMLOptions();

        if (!taskInsertEmail.isEmpty()) {
            options.EmailHeader.triggerUserEmail = true;
            List<Database.SaveResult> results = Database.insert(taskInsertEmail, options);
        }

        if (!taskInsertNoEmail.isEmpty()) {
            options.EmailHeader.triggerUserEmail = false;
            List<Database.SaveResult> results = Database.insert(taskInsertNoEmail, options);
        }
    }

    /*******************************************************************************************************
    * @description Queries and builds maps for templates and template tasks related to a list engagement plans.
    * @param engagementPlans a list of Engagement Plans to query and build maps for.
    * @return void This method updates class properties.
    ********************************************************************************************************/
    private void buildMaps(List<Engagement_Plan__c> engagementPlans) {
        //collect template IDs and target objects from the engagement plans
        for (Engagement_Plan__c engagementPlan : engagementPlans) {
            templateMap.put(engagementPlan.Engagement_Plan_Template__c, null);
        }

        //query for templates and related engagement plan tasks
        templateMap = new Map<Id, Engagement_Plan_Template__c>(
            [SELECT Id, Name, Skip_Weekends__c, Skip_Day__c, Delay_Type__c, Blank_Assignment_Rule__c,
                (SELECT Id, Name, Engagement_Plan_Template__c, Assigned_To__c, Comments__c, Days_After__c, 
                Dependent_Task__c, Priority__c, Reminder__c, Reminder_Minutes__c, Send_Email__c, Type__c, 
                Status__c FROM Engagement_Plan_Tasks__r)
            FROM Engagement_Plan_Template__c WHERE Id IN :templateMap.keySet()]
        );

        //build a task map for retreiving dependent task information
        for (Engagement_Plan_Template__c template : templateMap.values()) {
            for (Engagement_Plan_Task__c epTask : template.Engagement_Plan_Tasks__r) {
                taskMap.put(epTask.Id, epTask);
            }
        }
    }

    /*******************************************************************************************************
    * @description Creates a Task based on an Engagement Plan Task. Copies fields, sets up dependent tasks
    * by providing a special status and determining delay in due date based on dependent tasks.
    * @param epTask An Engagement Plan Task from which to copy fields.
    * @return void This method updates class properties.
    ********************************************************************************************************/
    private Task createTask(Engagement_Plan_Task__c epTask) {
        Engagement_Plan_Template__c template = templateMap.get(epTask.Engagement_Plan_Template__c);

        Map<String,String> taskAPTaskFieldMap = new Map<String,String>();
        //Task field name -> Engagement_Plan_Task__c field name
        taskAPTaskFieldMap.put('Engagement_Plan_Task__c', 'Id');
        taskAPTaskFieldMap.put('Subject', 'Name');
        taskAPTaskFieldMap.put('Priority', 'Priority__c');
        taskAPTaskFieldMap.put('OwnerId', 'Assigned_To__c');
        taskAPTaskFieldMap.put('Description', 'Comments__c');
        taskAPTaskFieldMap.put('Type', 'Type__c');
        taskAPTaskFieldMap.put('Status', 'Status__c');

        //copy fields
        Task taskResult = new Task();
        for (String taskField : taskAPTaskFieldMap.keySet()) {
            taskResult.put(taskField, epTask.get(taskAPTaskFieldMap.get(taskField)));
        }

        taskResult.ActivityDate = calcActivityDate(epTask);

        //Non Dependent Task defaults
        if (epTask.Dependent_Task__c == null) {
            if (String.isBlank(taskResult.Status)) {
                taskResult.Status = 'Not Started';
            }
            if (epTask.Reminder__c) {
                taskResult.IsReminderSet = true;

                Integer reminderMinutes;
                if (String.isBlank(epTask.Reminder_Minutes__c)) {
                    //default to noon, i.e. 12*60
                    reminderMinutes = 720;
                } else {
                    reminderMinutes = Integer.valueOf(epTask.Reminder_Minutes__c);
                }

                //We've already calculated the the activity date, including offset and skip weekend setting
                //so we'll use that date for ReminderDateTime as well
                taskResult.ReminderDateTime = Datetime.newInstance(taskResult.ActivityDate.year(), taskResult.ActivityDate.month(), taskResult.ActivityDate.day());
                taskResult.ReminderDateTime = taskResult.ReminderDateTime.addMinutes(reminderMinutes);
            }
        //Dependent Task defaults
        //Don't set reminder for dependent tasks; it will be set once the dependent task is complete.
        } else {
            taskResult.Status = 'Waiting on Dependent Task';
        }

        return taskResult;
    }

    /*******************************************************************************************************
    * @description For a given Task and an Id of the record to assign the task to, determines if the Id is
    * a Lead or Contact, in which case the Task field WhoId is used. Otherwise, uses WhatId for assignemnt.
    * @param taskToAssign The Task object needing assignment.
    * @param objectId The object to assign the Task to.
    * @return void This method edits the Task parameter directly.
    ********************************************************************************************************/
    private void assignTask(Task taskToAssign, Id objectId) {
        if (taskToAssign == null || objectId == null) {
            return;
        }
        if (objectId.getSobjectType() == Contact.sObjectType 
            || objectId.getSobjectType() == Lead.sObjectType) {
            taskToAssign.WhoId = objectId;
        } else {
            taskToAssign.WhatId = objectId;
        }
    }

    /*******************************************************************************************************
    * @description For a given EP Task and a date, calculates the number of days delay including dependent
    * tasks delay, and skips weekends based on the template settings.
    * @param epTask An Engagement Plan Task to calculate the delay for.
    * @return Date The calculated date including the delay and skip weekends setting.
    ********************************************************************************************************/
    private Date calcActivityDate(Engagement_Plan_Task__c epTask) {

        Engagement_Plan_Template__c template = templateMap.get(epTask.Engagement_Plan_Template__c);
        Engagement_Plan_Task__c currentTask = epTask;

        Integer daysDelay = 0;
        if (currentTask.Days_After__c != null) {
            daysDelay += (Integer)currentTask.Days_After__c;
        }

        //follow the dependency chain to get the total number of days delay
        //an uppber bounds of 500 is a safeguard against infinite recursion
        Integer counter = 0;
        while (currentTask.Dependent_Task__c != null && counter < 500) {
            currentTask = taskMap.get(currentTask.Dependent_Task__c);
            if (currentTask.Days_After__c != null) {
                daysDelay += (Integer)currentTask.Days_After__c;
            }
            counter+=1;
        }

        Date result = System.today().addDays(daysDelay);

        if (template.Skip_Weekends__c) {
            result = skipWeekend(result, template.Skip_Day__c);
        }

        return result;
    }

    /*******************************************************************************************************
    * @description For a given date and skip day setting, moves dates that land on a weekend to either 
    * the previous Friday or the following Monday.
    * @param originalDate The date that may be on a weekend.
    * @param skipDay Which day to move the date to: Friday or Monday.
    * @return Date The original date moved to Friday or Monday.
    ********************************************************************************************************/
    private Date skipWeekend(Date originalDate, String skipDay) {
        // find if the due date falls on a Saturday or Sunday; add 1 day for Sunday and 2 for Saturday
        Date result = originalDate;
        Date refDate = Date.newInstance(1900, 1, 7);  // Jan 7 1900 = Sunday
        Integer dayOfWeek = Math.mod(refDate.daysBetween(originalDate), 7); // 0 = Sunday ... 6 = Saturday
        
        if (skipDay == 'Friday') {
            //subtract days to Friday
            if (dayOfWeek == 0) {
                result = result.addDays(-2);
            } else if (dayOfWeek == 6) {
                result = result.addDays(-1);
            }
        } else {
            //add days to Monday
            if (dayOfWeek == 0) {
                result = result.addDays(1);
            } else if (dayOfWeek == 6) {
                result = result.addDays(2);
            }
        }
        return result;
    }
}