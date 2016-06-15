/*
    Copyright (c) 2016 Salesforce.org
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
* @description Trigger Handler on Engagement Plan Tasks 
*/
public class EP_TaskDpendencyCheck_TDTM extends TDTM_Runnable {

    /** @description maximum number of tasks to check in a dependency chain */
    public static Integer maxCount = 500;
    
    /*******************************************************************************************************
    * @description Trigger Handler on Engagement Plan Tasks that prevents recursion on dependent tasks.
    * @param listNew the list of Engagement Plan Tasks from trigger new. 
    * @param listOld the list of Engagement Plan Tasks from trigger old. 
    * @param triggerAction which trigger event (BeforeInsert, AfterInsert, etc.). 
    * @param objResult the describe for Engagement Plan Tasks 
    * @return dmlWrapper.  
    ********************************************************************************************************/
    public override DmlWrapper run(List<SObject> listNew, List<SObject> listOld, 
        TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {
        /*********************************************************************************************************
        * @description A list of the tasks that require validation.
        */
        List<Engagement_Plan_Task__c> listToValidate = new List<Engagement_Plan_Task__c>();

        // AFTER INSERT
        if (triggerAction == TDTM_Runnable.Action.AfterInsert) {
            for (SObject newSO : listNew) {
                Engagement_Plan_Task__c newEPTask = (Engagement_Plan_Task__c)newSO;
                if (newEPTask.Dependent_Task__c != null) {
                    listToValidate.add(newEPTask);
                }
            }
            if (listToValidate.size() > 0) {
                validateTasks(listToValidate);
            }
        }

        // AFTER UPDATE
        if (triggerAction == TDTM_Runnable.Action.AfterUpdate) {
            Map<Id, Engagement_Plan_Task__c> mapOld = new Map<Id, Engagement_Plan_Task__c>((List<Engagement_Plan_Task__c>)listOld);

            for (SObject newSO : listNew) {
                Engagement_Plan_Task__c newEPTask = (Engagement_Plan_Task__c)newSO;
                Engagement_Plan_Task__c oldEPTask = mapOld.get(newEPTask.Id);

                if ((newEPTask.Dependent_Task__c != null
                    && newEPTask.Dependent_Task__c != oldEPTask.Dependent_Task__c)
                        || newEPTask.Engagement_Plan_Template__c != oldEPTask.Engagement_Plan_Template__c) {
                        listToValidate.add(newEPTask);
                }
            }
            if (listToValidate.size() > 0) {
                validateTasks(listToValidate);
            }
        }

        return null;
    }

    /*******************************************************************************************************
    * @description For the Tasks that are new or where the EP Template or Dependency has changed,
    * prevent cross dependencies and mismatched templates
    * @param listPSCNew the list of PSCs from trigger new. 
    * @param listPSCOld the list of PSCs from trigger old.
    * @return void.  
    ********************************************************************************************************/
    public static void validateTasks(List<Engagement_Plan_Task__c> listToValidate) {
        // A set of the Engagement Plan Template Ids related to the tasks.
        Set<Id> templateIds = new Set<Id>();        
        // Engagement Plan Task mapped to the template and all the template's related tasks
        Map<Id, Engagement_Plan_Template__c> mapTaskIdToTemplate = new Map<Id, Engagement_Plan_Template__c>();
        // Engagement Plan Task mapped to tasks that are dependent on it to check for template mismatch
        Map<Id, List<Engagement_Plan_Task__c>> mapTaskIdToChildren = new Map<Id, List<Engagement_Plan_Task__c>>();

        for (Engagement_Plan_Task__c newEPTask : listToValidate) {
            templateIds.add(newEPTask.Engagement_Plan_Template__c);
        }

        for (Engagement_Plan_Template__c template : [SELECT Id, (SELECT Id, Dependent_Task__c,
                Dependent_Task__r.Engagement_Plan_Template__c, Engagement_Plan_Template__c FROM Engagement_Plan_Tasks__r)
                FROM Engagement_Plan_Template__c WHERE Id IN :templateIds]) {
            for (Engagement_Plan_Task__c templateTask : template.Engagement_Plan_Tasks__r) {
                mapTaskIdToTemplate.put(templateTask.Id, template);
            }
        }

        for (Engagement_Plan_Task__c childTask : [SELECT Id, Dependent_Task__c, Engagement_Plan_Template__c
                FROM Engagement_Plan_Task__c WHERE Dependent_Task__c IN : listToValidate]) {
            if (mapTaskIdToChildren.containsKey(childTask.Dependent_Task__c)) {
                mapTaskIdToChildren.get(childTask.Dependent_Task__c).add(childTask);
            } else {
                List<Engagement_Plan_Task__c> childTasks = new List<Engagement_Plan_Task__c>();
                childTasks.add(childTask);
                mapTaskIdToChildren.put(childTask.Dependent_Task__c, childTasks);
            }
        }

        for (Engagement_Plan_Task__c newEPTask : listToValidate) {
            Map<Id, Engagement_Plan_Task__c> mapExistingEPTasks =
                new Map<Id, Engagement_Plan_Task__c>(mapTaskIdToTemplate.get(newEPTask.Id).Engagement_Plan_Tasks__r);
            if (newEPTask.Dependent_Task__c != null) {
                if (!mapExistingEPTasks.containsKey(newEPTask.Dependent_Task__c)) {
                    newEPTask.addError(Label.EPTaskTemplate);
                } else {
                    Set<Id> taskIds = new Set<Id>{newEPTask.Id};
                    Engagement_Plan_Task__c dependentTask = mapExistingEPTasks.get(newEPTask.Dependent_Task__c);
                    Integer count = 0;
                    while (dependentTask.Dependent_Task__c != null
                            && mapExistingEPTasks.containsKey(dependentTask.Dependent_Task__c)
                            && count < maxCount) {
                        if (taskIds.contains(dependentTask.Dependent_Task__c)) {
                            newEPTask.addError(Label.EPTaskDependency);
                            break;
                        }
                        taskIds.add(dependentTask.Dependent_Task__c);
                        dependentTask = mapExistingEPTasks.get(dependentTask.Dependent_Task__c);
                        count++;
                    }
                }
            }
            if (mapTaskIdToChildren.containsKey(newEPTask.Id)) {
                for (Engagement_Plan_Task__c childTask : mapTaskIdToChildren.get(newEPTask.Id)) {
                    if (childTask.Engagement_Plan_Template__c != newEPTask.Engagement_Plan_Template__c) {
                        newEPTask.addError(Label.EPTaskTemplate);
                    }
                }
            }
        }
    }
}