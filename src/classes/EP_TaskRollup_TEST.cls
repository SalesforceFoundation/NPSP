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
* @description Test Trigger Handler on Tasks
*/
@isTest
public class EP_TaskRollup_TEST {
            
    /*******************************************************************************************************
    * @description Insert a single Task related to an Engagement Plan
    */ 
    static testmethod void testSingleEPTask() {
        List<Engagement_Plan_Template__c> templateTests = UTIL_UnitTestData_TEST.createEPTemplates(1);
        insert templateTests;
        List<Engagement_Plan_Task__c> epTaskTests = UTIL_UnitTestData_TEST.createEPTasksForTemplates(1, templateTests);
        insert epTaskTests;
        Engagement_Plan__c epToInsert = new Engagement_Plan__c(
            Engagement_Plan_Template__c = templateTests[0].Id,
            Completed_Tasks__c = 0,
            Total_Tasks__c = 0);
        insert epToInsert;
        Task taskTest = new Task(Engagement_Plan__c = epToInsert.Id, Subject = 'Test');
        
        Test.startTest();
        insert taskTest;
        Test.stopTest();

        Engagement_Plan__c epReQueried = [SELECT Id, Completed_Tasks__c, Total_Tasks__c
            FROM Engagement_Plan__c WHERE Id = :epToInsert.Id LIMIT 1];
        System.assertEquals(1, epReQueried.Total_Tasks__c, 'The task should have created successfully and updated the Total Tasks');
        System.assertEquals(0, epReQueried.Completed_Tasks__c, 'The task was not complete 0 should still be set for Completed Tasks');
    }
    /*******************************************************************************************************
    * @description Insert multiple Task related to an Engagement Plan
    */ 
    static testmethod void testMultipleEPTask() {
        List<Engagement_Plan_Template__c> templateTests = UTIL_UnitTestData_TEST.createEPTemplates(1);
        insert templateTests;
        List<Engagement_Plan_Task__c> epTaskTests = UTIL_UnitTestData_TEST.createEPTasksForTemplates(10, templateTests);
        insert epTaskTests;
        Engagement_Plan__c epToInsert = new Engagement_Plan__c(
            Engagement_Plan_Template__c = templateTests[0].Id,
            Completed_Tasks__c = 0,
            Total_Tasks__c = 0);
        insert epToInsert;
        List<Task> taskTests = new List<Task>();
        Integer completedTasks = 0;
        for (Integer i = 0; i < epTaskTests.size(); i++) {
            Boolean markComplete = math.mod(i + 1, 2) != 0;
            completedTasks += markComplete ? 1 : 0;
            taskTests.add(new Task(
                Engagement_Plan__c = epToInsert.Id, 
                Subject = 'Test',
                Status = markComplete ? UTIL_UnitTestData_TEST.getOpenTaskStatus() : UTIL_UnitTestData_TEST.getClosedTaskStatus()));
        }
        
        Test.startTest();
        insert taskTests;
        Test.stopTest();

        Engagement_Plan__c epReQueried = [SELECT Id, Completed_Tasks__c, Total_Tasks__c
            FROM Engagement_Plan__c WHERE Id = :epToInsert.Id LIMIT 1];
        System.assertEquals(taskTests.size(), epReQueried.Total_Tasks__c, 'All tasks should have created successfully and updated the Total Tasks');
        System.assertEquals(completedTasks, epReQueried.Completed_Tasks__c, 'Completed Tasks should equal total number of tasks marked complete.');
    }
    /*******************************************************************************************************
    * @description updating multiple Task related to an Engagement Plan
    */ 
    static testmethod void testUpdateMultipleEPTask() {
        List<Engagement_Plan_Template__c> templateTests = UTIL_UnitTestData_TEST.createEPTemplates(1);
        insert templateTests;
        List<Engagement_Plan_Task__c> epTaskTests = UTIL_UnitTestData_TEST.createEPTasksForTemplates(10, templateTests);
        insert epTaskTests;
        Engagement_Plan__c epToInsert = new Engagement_Plan__c(
            Engagement_Plan_Template__c = templateTests[0].Id,
            Completed_Tasks__c = 0,
            Total_Tasks__c = 0);
        insert epToInsert;
        List<Task> taskTests = new List<Task>();
        for (Integer i = 0; i < epTaskTests.size(); i++) {
            Boolean markComplete = math.mod(i + 1, 2) != 0;
            taskTests.add(new Task(
                Engagement_Plan__c = epToInsert.Id, 
                Subject = 'Test',
                Status = markComplete ? UTIL_UnitTestData_TEST.getOpenTaskStatus() : UTIL_UnitTestData_TEST.getClosedTaskStatus()));
        }
        insert taskTests;

        for (Task taskTest : taskTests) {
            taskTest.Status = UTIL_UnitTestData_TEST.getClosedTaskStatus();
        }
        
        Test.startTest();
        update taskTests;
        Test.stopTest();

        Engagement_Plan__c epReQueried = [SELECT Id, Completed_Tasks__c, Total_Tasks__c
            FROM Engagement_Plan__c WHERE Id = :epToInsert.Id LIMIT 1];
        System.assertEquals(taskTests.size(), epReQueried.Total_Tasks__c, 'All tasks should have updated successfully and the Total Tasks should equal total inserted.');
        System.assertEquals(epReQueried.Total_Tasks__c, epReQueried.Completed_Tasks__c, 'All tasks updated to complete, total complete should equal total tasks.');
    }
    /*******************************************************************************************************
    * @description deleting a closed completed Task related to an Engagement Plan
    */ 
    static testmethod void testDeleteCompletedEPTask() {
        List<Engagement_Plan_Template__c> templateTests = UTIL_UnitTestData_TEST.createEPTemplates(1);
        insert templateTests;
        List<Engagement_Plan_Task__c> epTaskTests = UTIL_UnitTestData_TEST.createEPTasksForTemplates(10, templateTests);
        insert epTaskTests;
        Engagement_Plan__c epToInsert = new Engagement_Plan__c(
            Engagement_Plan_Template__c = templateTests[0].Id,
            Completed_Tasks__c = 0,
            Total_Tasks__c = 0);
        insert epToInsert;
        List<Task> taskTests = new List<Task>();
        Integer completedTasks = 0;
        for (Integer i = 0; i < epTaskTests.size(); i++) {
            Boolean markComplete = math.mod(i + 1, 2) != 0;
            completedTasks += markComplete ? 1 : 0;
            taskTests.add(new Task(
                Engagement_Plan__c = epToInsert.Id, 
                Subject = 'Test',
                Status = markComplete ? UTIL_UnitTestData_TEST.getOpenTaskStatus() : UTIL_UnitTestData_TEST.getClosedTaskStatus()));
        }
        insert taskTests;

        Task taskToDelete = [SELECT Id FROM Task WHERE Status = :UTIL_UnitTestData_TEST.getClosedTaskStatus() AND Engagement_Plan__c = :epToInsert.Id LIMIT 1];
        
        Test.startTest();
        delete taskToDelete;
        Test.stopTest();

        Engagement_Plan__c epReQueried = [SELECT Id, Completed_Tasks__c, Total_Tasks__c
            FROM Engagement_Plan__c WHERE Id = :epToInsert.Id LIMIT 1];
        System.assertEquals(taskTests.size() - 1, epReQueried.Total_Tasks__c, 'The total should have reduced by 1 after deletion.');
        System.assertEquals(completedTasks - 1, epReQueried.Completed_Tasks__c, 'Total complete should have reduced by 1 after deletion.');
    }
    /*******************************************************************************************************
    * @description updating a task by removing the Engagement Plan
    */ 
    static testmethod void testUnrelateEPTask() {
        List<Engagement_Plan_Template__c> templateTests = UTIL_UnitTestData_TEST.createEPTemplates(1);
        insert templateTests;
        List<Engagement_Plan_Task__c> epTaskTests = UTIL_UnitTestData_TEST.createEPTasksForTemplates(10, templateTests);
        insert epTaskTests;
        Engagement_Plan__c epToInsert = new Engagement_Plan__c(
            Engagement_Plan_Template__c = templateTests[0].Id,
            Completed_Tasks__c = 0,
            Total_Tasks__c = 0);
        insert epToInsert;
        List<Task> taskTests = new List<Task>();
        for (Integer i = 0; i < epTaskTests.size(); i++) {
            Boolean markComplete = math.mod(i + 1, 2) != 0;
            taskTests.add(new Task(
                Engagement_Plan__c = epToInsert.Id, 
                Subject = 'Test',
                Status = markComplete ? UTIL_UnitTestData_TEST.getOpenTaskStatus() : UTIL_UnitTestData_TEST.getClosedTaskStatus()));
        }
        insert taskTests;

        taskTests[0].Engagement_Plan__c = null;
        
        Test.startTest();
        update taskTests[0];
        Test.stopTest();

        Engagement_Plan__c epReQueried = [SELECT Id, Completed_Tasks__c, Total_Tasks__c
            FROM Engagement_Plan__c WHERE Id = :epToInsert.Id LIMIT 1];
        System.assertEquals(taskTests.size() - 1, epReQueried.Total_Tasks__c, 'The total should have reduced by 1 after nullifying relationship.');
    }
}