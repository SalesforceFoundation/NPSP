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
@isTest
public class EP_TaskDependencyCheck_TEST {
    
    /*******************************************************************************************************
    * @description Setup Test Data to be used by the various test methods
    */
    @testSetup static void generateTestData() {
        List<Engagement_Plan_Template__c> templateTests = new List<Engagement_Plan_Template__c>();
        List<Engagement_Plan_Task__c> taskTests = new List<Engagement_Plan_Task__c>();

        for (integer i = 1; i <= 10; i++) {
            templateTests.add(new Engagement_Plan_Template__c(Name = 'Test ' + i));
        }
        insert templateTests;

        for (Engagement_Plan_Template__c templateTest : templateTests) {
            for (integer i = 1; i <= 10; i++) {
                taskTests.add(new Engagement_Plan_Task__c(Engagement_Plan_Template__c = templateTest.Id));
            }
        }
        insert taskTests;
    }
            
    /*******************************************************************************************************
    * @description Insert a single Engagment Plan Task Dependent on an existing task.
    */ 
    static testmethod void testSingleEPDependentTask() {
        Engagement_Plan_Template__c templateTest = [SELECT Id, (SELECT Id FROM Engagement_Plan_Tasks__r LIMIT 1) FROM Engagement_Plan_Template__c LIMIT 1];
        Engagement_Plan_Task__c taskTest = new Engagement_Plan_Task__c(Engagement_Plan_Template__c = templateTest.Id, Dependent_Task__c = templateTest.Engagement_Plan_Tasks__r[0].Id);
        
        Test.startTest();
        insert taskTest;
        Test.stopTest();

        System.assertNotEquals(null, taskTest.Id, 'The EP task is valid and when inserted should have returned an Id.');
    }

    /*******************************************************************************************************
    * @description Insert multiple Engagment Plan Tasks Dependent on an existing task.
    */ 
    static testmethod void testMultipleEPDependentTask() {
        Engagement_Plan_Template__c templateTest = [SELECT Id, (SELECT Id, Name FROM Engagement_Plan_Tasks__r) FROM Engagement_Plan_Template__c LIMIT 1];
        List<Engagement_Plan_Task__c> taskTests = new List<Engagement_Plan_Task__c>();
        for (Engagement_Plan_Task__c taskTest : templateTest.Engagement_Plan_Tasks__r) {
            taskTests.add(new Engagement_Plan_Task__c(
                Name = taskTest.Name + ' Dependent',
                Engagement_Plan_Template__c = templateTest.Id,
                Dependent_Task__c = taskTest.Id));
        }

        Test.startTest();
        insert taskTests;
        Test.stopTest();

        List<Engagement_Plan_Task__c> taskTestsNew = [SELECT Id, (SELECT Id FROM Engagement_Plan_Tasks__r)
            FROM Engagement_Plan_Template__c LIMIT 1].Engagement_Plan_Tasks__r;
        System.assertEquals(taskTests.size() * 2, taskTestsNew.size(), 'The total task size should have doubled.');
    }

    /*******************************************************************************************************
    * @description Update EP Tasks with redundant dependencies. e.g. task A is dependent on C, which is
    * dependent on B which is dependent on A
    */ 
    static testmethod void testRedundantEPDependentTask() {
        Engagement_Plan_Template__c templateTest = [SELECT Id, (SELECT Id, Dependent_Task__c
            FROM Engagement_Plan_Tasks__r LIMIT 4) FROM Engagement_Plan_Template__c LIMIT 1];
        Engagement_Plan_Task__c taskTestA = templateTest.Engagement_Plan_Tasks__r[0];
        Engagement_Plan_Task__c taskTestB = templateTest.Engagement_Plan_Tasks__r[1];
        Engagement_Plan_Task__c taskTestC = templateTest.Engagement_Plan_Tasks__r[2];
        taskTestA.Dependent_Task__c = taskTestC.Id;
        update taskTestA;
        taskTestB.Dependent_Task__c = taskTestA.Id;
        update taskTestB;
        taskTestC.Dependent_Task__c = taskTestB.Id;

        Test.startTest();
        try {
            update taskTestC;
            System.assert(false, 'An EP task with a circular dependency should fail insert.');
        } catch (Exception e) {
            System.assert(e.getMessage().contains(Label.EPTaskDependency));
        }
        Test.stopTest();
    }

    /*******************************************************************************************************
    * @description Insert EP Tasks with dependency task from a different template.
    */ 
    static testmethod void testCrossTemplateEPDependentTask() {
        List<Engagement_Plan_Template__c> templateTests = [SELECT Id, (SELECT Id FROM Engagement_Plan_Tasks__r LIMIT 1)
            FROM Engagement_Plan_Template__c LIMIT 2];
        Engagement_Plan_Task__c taskTestA = templateTests[0].Engagement_Plan_Tasks__r[0];
        Engagement_Plan_Task__c taskTestB = new Engagement_Plan_Task__c(Engagement_Plan_Template__c = templateTests[1].Id, Dependent_Task__c = templateTests[0].Engagement_Plan_Tasks__r[0].Id);
        update taskTestA;

        Test.startTest();
        try {
            insert taskTestB;
            System.assert(false, 'An EP task should fail if dependent task belongs to a different template.');
        } catch (Exception e) {
            System.assert(e.getMessage().contains(Label.EPTaskTemplate));
        }
        Test.stopTest();
    }

    /*******************************************************************************************************
    * @description Update EP Task that other tasks are dependent on and change its template.
    */ 
    static testmethod void testUpdateCrossTemplateEPDependentTask() {
        List<Engagement_Plan_Template__c> templateTests = [SELECT Id, (SELECT Id FROM Engagement_Plan_Tasks__r LIMIT 3)
            FROM Engagement_Plan_Template__c LIMIT 2];
        Engagement_Plan_Task__c taskTestA = templateTests[0].Engagement_Plan_Tasks__r[0];
        Engagement_Plan_Task__c taskTestB = templateTests[0].Engagement_Plan_Tasks__r[1];
        Engagement_Plan_Task__c taskTestC = templateTests[0].Engagement_Plan_Tasks__r[2];
        taskTestA.Dependent_Task__c = taskTestC.Id;
        update taskTestA;
        taskTestB.Dependent_Task__c = taskTestC.Id;
        update taskTestB;
        taskTestC.Engagement_Plan_Template__c = templateTests[1].Id;

        Test.startTest();
        try {
            update taskTestC;
            System.assert(false, 'An EP task should fail if tasks that are dependent on it belongs to a different template.');
        } catch (Exception e) {
            System.assert(e.getMessage().contains(Label.EPTaskTemplate));
        }
        Test.stopTest();
    }
}