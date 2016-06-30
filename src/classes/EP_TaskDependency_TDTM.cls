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
* @description When a Task created by an Engagement Plan is given a Closed status, checks for dependent Tasks
* and updates them by changing the status, updating the due date, and sending email.
*/
public with sharing class EP_TaskDependency_TDTM extends TDTM_Runnable {

    /*******************************************************************************************************
    * @description Trigger Handler on Task that checks for dependent Tasks based on EP Task dependencies,
    * updating the dependent task status and date, setting reminders, and sending email.
    * @param listNew the list of Engagement Plans from trigger new. 
    * @param listOld the list of Engagement Plans from trigger old. 
    * @param triggerAction which trigger event (BeforeInsert, AfterInsert, etc.). 
    * @param objResult the describe for Engagement Plans 
    * @return dmlWrapper.  
    ********************************************************************************************************/
    public override DmlWrapper run(List<SObject> newlist, List<SObject> oldlist, 
        TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {
        
        List<Task> tasksToCheckDependencies = new List<Task>();

        for (Integer i=0; i < newList.size(); i++) {
            Task newTask = (Task) newList[i];
            Task oldTask = (Task) oldList[i];
            if (newTask.Engagement_Plan_Task__c!=null && newTask.isClosed && !oldTask.isClosed) {
                tasksToCheckDependencies.add(newTask);
            }
        }

        if (!tasksToCheckDependencies.isEmpty()) {
            updateDependentTasks(tasksToCheckDependencies);
        }

        return null;
    }

    /** @description Map of EP Tasks that are direct dependents of Tasks in the trigger set, i.e. children. */
    private Map<Id, Engagement_Plan_Task__c> directDependentEPTasks = new Map<Id, Engagement_Plan_Task__c>();
    /** @description Map of EP Tasks that are indirect dependents of Tasks in the trigger set, i.e. grandchildren. */
    private Map<Id, Engagement_Plan_Task__c> indirectDependentEPTasks = new Map<Id, Engagement_Plan_Task__c>();
    /** @description Task utilities class. */
    private EP_Task_UTIL taskCreator;

    /*******************************************************************************************************
    * @description For a list of Tasks that have just been given a closed status, queries for all tasks
    * that are dependent on these tasks, activating direct children and updating the activity date of
    * indirect children.
    * @param tasksWithDependencies The tasks that have just been marked complete.
    * @return void This method inserts and updates Tasks directly, as DML options are needed for email sends.
    ********************************************************************************************************/
    private void updateDependentTasks(List<Task> tasksWithDependencies) {
        taskCreator = new EP_Task_UTIL(tasksWithDependencies);

        List<Task> taskUpdateEmail = new List<Task>();
        List<Task> taskUpdateNoEmail = new List<Task>();

        //gather all EP tasks that are direct children of EP tasks in the current trigger set
        //these will have their status, date, and reminder modified
        for (Task parentTask : tasksWithDependencies) {
            Engagement_Plan_Task__c parentEPTask = taskCreator.taskMap.get(parentTask.Engagement_Plan_Task__c);
            for (Engagement_Plan_Task__c childEPTask : parentEPTask.Engagement_Plan_Tasks__r) {
                directDependentEPTasks.put(childEPTask.id, taskCreator.taskMap.get(childEPTask.id));
            }
        }

        //gather all EP tasks that are down the dependency chain, but not direct children of the current trigger set
        //these will just have their dates updated
        for (Engagement_Plan_Task__c parentTask : directDependentEPTasks.values()) {
            addChildrenRecursive(parentTask);
        }

        //query for all tasks that are dependent on the current trigger set of tasks
        //since multiple Tasks can point toward a single EP Task, 
        //we need to deal with lists of Tasks for each EP Task id.
        Map<Id, List<Task>> mapEpTaskIdTasks = new Map<Id, List<Task>>();
        for (Task taskForUpdate :  [SELECT Id, ActivityDate, Engagement_Plan_Task__c, Engagement_Plan__c
                                    FROM Task WHERE Engagement_Plan_Task__c IN :directDependentEPTasks.values() OR 
                                    Engagement_Plan_Task__c IN :indirectDependentEPTasks.values()]) {
            if (!mapEpTaskIdTasks.containsKey(taskForUpdate.Engagement_Plan_Task__c)) {
                mapEpTaskIdTasks.put(taskForUpdate.Engagement_Plan_Task__c, new List<Task>{taskForUpdate});
            } else {
                mapEpTaskIdTasks.get(taskForUpdate.Engagement_Plan_Task__c).add(taskForUpdate);
            }
        }
        
        //update directly dependent tasks that are now active; send email per the template setting
        for (Engagement_Plan_Task__c epTask : directDependentEPTasks.values()) {
            Engagement_Plan_Template__c template = taskCreator.templateMap.get(epTask.Engagement_Plan_Template__c);
            
            for (Task taskForUpdate : mapEpTaskIdTasks.get(epTask.Id)) {

                taskCreator.updateActivateTask(taskForUpdate);

                if (epTask.Send_Email__c) {
                    taskUpdateEmail.add(taskForUpdate);
                } else {
                    taskUpdateNoEmail.add(taskForUpdate);
                }

                //if the template has selected to update task dates based on when the parent task was completed, 
                //we'll follow the dependency chain and calculate dates
                if (template.Delay_Type__c == 'After Date Completed') {
                    Engagement_Plan_Task__c currentEPTask = epTask;
                    Date parentDate = taskForUpdate.ActivityDate;

                    while (currentEPTask.Dependent_Task__c != null && 
                            indirectDependentEPTasks.containsKey(currentEPTask.Dependent_Task__c)) {

                        //get the dependent EP Task and Task
                        //need to follow in the other direction
                        currentEPTask = indirectDependentEPTasks.get(currentEPTask.Dependent_Task__c);
                        for (Task indirectDependentTask : mapEpTaskIdTasks.get(currentEPTask.id)) {
                            
                            //calculate the activity date based on the parent's date
                            indirectDependentTask.ActivityDate = taskCreator.calcActivityDate(currentEPTask, parentDate);
                            //remember the parent date for the next child task
                            parentDate = indirectDependentTask.ActivityDate;

                            //insert without email regardless of setting, since we're still waiting on a dependent task
                            taskUpdateNoEmail.add(indirectDependentTask);
                        }
                    }
                }
            }
        }

        //update indirect dependent Tasks if the template's delay type says to
        for (Engagement_Plan_Task__c epTask : indirectDependentEPTasks.values()) {
            Engagement_Plan_Template__c template = taskCreator.templateMap.get(epTask.Engagement_Plan_Template__c);
            if (template.Delay_Type__c == 'After Date Completed') {
                for (Task indirectDependentTask : mapEpTaskIdTasks.get(epTask.id)) {
                    taskCreator.updateInactiveTask(indirectDependentTask);
                    taskUpdateNoEmail.add(indirectDependentTask);
                }
            }
        }

        Database.DMLOptions options = new Database.DMLOptions();

        if (!taskUpdateEmail.isEmpty()) {
            options.EmailHeader.triggerUserEmail = true;
            List<Database.SaveResult> results = Database.update(taskUpdateEmail, options);
        }

        if (!taskUpdateNoEmail.isEmpty()) {
            options.EmailHeader.triggerUserEmail = false;
            List<Database.SaveResult> results = Database.update(taskUpdateNoEmail, options);
        }
    }

    /*******************************************************************************************************
    * @description Follows the dependency chain of a given EP Task, adding its children to the map
    * indirectDependentEPTasks.
    * @param parentEPTask The task whose children should be added to the indirectDependentEPTasks map
    * @return void This method adds children tasks to the indirectDependentEPTasks map and returns nothing.
    ********************************************************************************************************/
    private void addChildrenRecursive(Engagement_Plan_Task__c parentEPTask) {
        for (Engagement_Plan_Task__c childEPTask : parentEPTask.Engagement_Plan_Tasks__r) {
            Engagement_Plan_Task__c epTask = taskCreator.taskMap.get(childEPTask.id);

            //use the days after field to calculate the total delay in memory; 
            //we won't be committing these results, just using them for updating Tasks
            if (epTask.Days_After__c == null) {
                epTask.Days_After__c = 0;
            }

            if (parentEPTask.Days_After__c == null) {
                parentEPTask.Days_After__c = 0;
            }

            epTask.Days_After__c += parentEPTask.Days_After__c;

            indirectDependentEPTasks.put(epTask.id, epTask);
            addChildrenRecursive(epTask);
        }
    }
}