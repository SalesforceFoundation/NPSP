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
* @description Tests for Manage Engagement Plan Template UI.
*/
@isTest
private with sharing class EP_ManageEPTemplate_CTRL_TEST {

    /*********************************************************************************************************
    * @description Creates a template with two tasks, one the child of the other. Tests out buttons and 
    * verifies results.
    */
    static testMethod void testDependentPlan() {
        Contact con = new Contact(LastName = 'foo');
        insert con;

        Engagement_Plan_Template__c template = createTemplate();
        Engagement_Plan_Task__c epTask = createTask(template.Id);
        Engagement_Plan_Task__c dependentEpTask = createDependentTask(template.Id, epTask.Id);

        Test.startTest();        
        setUpPage(template.Id);

        EP_ManageEPTemplate_CTRL ctrl = new EP_ManageEPTemplate_CTRL(new ApexPages.StandardController(template));

        //get the dynamic component to initialize everything
        ctrl.getTaskTree();
        Test.stopTest();

        system.assert(ctrl.mapTaskWrappers.containsKey('1'), 'EP Task with level of 1 should exist.');
        system.assert(ctrl.mapTaskWrappers.containsKey('1-1'), 'EP Task with level of 1-1 should exist.');
        system.assert(!ctrl.mapTaskWrappers.containsKey('2'), 'EP Task with level of 2 should not exist yet.');

        //add parent level task and verify it exists
        ctrl.addTask();

        //since getTaskTree() is run on every rerender, we have to run it manually to fill mapTaskWrapper
        ctrl.getTaskTree();
        system.assert(ctrl.mapTaskWrappers.containsKey('2'), 'EP Task with level of 2 should exist now.');
        ctrl.mapTaskWrappers.get('2').detail.put('Name', 'foo');

        ctrl.currentTaskLevel = '1-1';
        ctrl.addDependentTask();
        ctrl.getTaskTree();
        system.assert(ctrl.mapTaskWrappers.containsKey('1-1-1'), 'EP Task with level of 1-1-1 should be created.');
        ctrl.mapTaskWrappers.get('1-1-1').detail.put('Name', 'stuff');

        ctrl.currentTaskLevel = '1-1-1';
        ctrl.addDependentTask();
        ctrl.getTaskTree();
        system.assert(ctrl.mapTaskWrappers.containsKey('1-1-1-1'), 'EP Task with level of 1-1-1-1 should be created.');
        ctrl.mapTaskWrappers.get('1-1-1-1').detail.put('Name', 'thing');

        ctrl.currentTaskLevel = '1-1';
        ctrl.deleteTask();
        ctrl.getTaskTree();
        system.assert(!ctrl.mapTaskWrappers.containsKey('1-1-1-1'), 
            'EP Task with level of 1-1-1-1 should be gone as its grandparent was deleted.');

        ctrl.saveClose();

        Map<Id,Engagement_Plan_Task__c> results = new Map<Id,Engagement_Plan_Task__c>(
            [SELECT Id, Name FROM Engagement_Plan_Task__c]
        );

        System.assertEquals(4,results.values().size(), 'Four Engagement Plan Tasks should be saved.');
        System.assert(!results.containsKey(dependentEpTask.id), 'Deleted task should no longer exist.');

    }

    /*********************************************************************************************************
    * @description Creates a template with two tasks, one the child of the other. Clones it, and verifies
    * everything was cloned correctly.
    */
    static testMethod void testClone() {
        Contact con = new Contact(LastName = 'foo');
        insert con;

        Engagement_Plan_Template__c template = createTemplate();
        Engagement_Plan_Task__c epTask = createTask(template.Id);
        Engagement_Plan_Task__c dependentEpTask = createDependentTask(template.Id, epTask.Id);

        Test.startTest();
        PageReference pageRef = setUpPage(template.Id);
        pageRef.getParameters().put('clone', '1');

        EP_ManageEPTemplate_CTRL ctrl = new EP_ManageEPTemplate_CTRL(new ApexPages.StandardController(template));

        //get the dynamic component to initialize everything
        ctrl.getTaskTree();
        ctrl.saveClose();
        Test.stopTest();

        List<Engagement_Plan_Template__c> clonedTemplate = [SELECT Id, Name, Skip_Weekends__c, Default_Assignee__c
                                                            FROM Engagement_Plan_Template__c WHERE Id != :template.id];
        System.assertEquals(1, clonedTemplate.size(), 'A new cloned template should exist.');
        System.assert(clonedTemplate[0].Name.contains(Label.lblCloned), 'Cloned template should have the Cloned label.');
        System.assertEquals(template.Skip_Weekends__c, clonedTemplate[0].Skip_Weekends__c, 
            'Clone should have the same Skip Weekend field value as the original.');
        System.assertEquals(template.Default_Assignee__c, clonedTemplate[0].Default_Assignee__c, 
            'Cloned Template should have the same Default Assignee field value as the original.');

        List<Engagement_Plan_Task__c> tasks = [SELECT Id, Parent_Task__c, Name FROM Engagement_Plan_Task__c 
                                               WHERE Id != :epTask.id AND Id != :dependentEpTask.id 
                                               ORDER BY Parent_Task__c NULLS FIRST];
        System.assertEquals(2, tasks.size(), 'Two cloned tasks should exist. ' + epTask.id + ' ' + ctrl.mapTaskWrappers.values()[0].detail);
        System.assertEquals(epTask.Name, tasks[0].Name, 'Cloned task should have the same name as the original.');
        System.assertEquals(dependentEpTask.Name, tasks[1].Name, 
            'Cloned task should have the same name as the original.');
        System.assertEquals(tasks[0].id, tasks[1].Parent_Task__c, 
            'Dependent task should have the cloned task as parent.');
    }

    /*********************************************************************************************************
    @description 
        Test saving the Template and a new Task which has no Name
    verify:
        An error is displayed on the page since the new Task has no Name.
        The Template and Tasks are unchanged. 
    **********************************************************************************************************/ 
    private static testMethod void testSaveFailsWhenNewTaskHasNoName() {
        Engagement_Plan_Template__c template = createTemplate();
        Engagement_Plan_Task__c epTask = createTask(template.Id);

        setUpPage(template.Id);
        
        EP_ManageEPTemplate_CTRL ctrl = new EP_ManageEPTemplate_CTRL(new ApexPages.StandardController(template));

        String templateName = ctrl.template.Name;
        ctrl.template.Name += ' - Test Save';

        ctrl.getTaskTree();
        ctrl.addTask();
        ctrl.getTaskTree();

        Test.startTest();
        PageReference retPage = ctrl.saveClose();
        Test.stopTest();

        System.assertEquals(null, retPage, 'The return page on the error should be null');
        UTIL_UnitTestData_TEST.assertPageHasError(Label.NameRequired);

        Engagement_Plan_Template__c actualTemplate = [SELECT Id, Name FROM Engagement_Plan_Template__c WHERE Id = :template.Id];
        System.assertEquals(templateName, actualTemplate.Name, 'Template Name should be unchanged');

        List<Engagement_Plan_Task__c> actualTasks = new List<Engagement_Plan_Task__c>([SELECT Id, Name FROM Engagement_Plan_Task__c]);
        System.assertEquals(1, actualTasks.size(), 'Tasks should be unchanged: ' + actualTasks);
    }

    /*********************************************************************************************************
    @description 
        Test saving Template and Tasks when an exception occurs 
    verify:
        The transaction is completely rolled back and there is no partial commit.
    **********************************************************************************************************/ 
    private static testMethod void testSaveRollsBackAllDmlsOnError() {
        Engagement_Plan_Template__c template = createTemplate();
        Engagement_Plan_Task__c epTask = createTask(template.Id);
        Engagement_Plan_Task__c dependentEpTask = createDependentTask(template.Id, epTask.Id);

        setUpPage(template.Id);
        
        EP_ManageEPTemplate_CTRL ctrl = new EP_ManageEPTemplate_CTRL(new ApexPages.StandardController(template));

        String templateName = ctrl.template.Name;
        ctrl.template.Name += ' - Test Save';

        ctrl.getTaskTree();
        ctrl.addTask();
        ctrl.getTaskTree();
        ctrl.mapTaskWrappers.get('2').detail.put('Name', 'foo');

        ctrl.addTask();
        ctrl.getTaskTree();
        ctrl.mapTaskWrappers.get('3').detail.put('Name', 'bar');

        ctrl.currentTaskLevel = '1-1';
        ctrl.deleteTask();
        ctrl.getTaskTree();

        System.assertEquals(3, ctrl.mapTaskWrappers.size(), 'Dependent task should be deleted');
        
        // Cause an error on update
        ctrl.mapTaskWrappers.get('1').detail.put('Assigned_To__c', UTIL_UnitTestData_TEST.MOCK_ACCOUNT_ID);

        Test.startTest();
        PageReference retPage = ctrl.saveClose();
        Test.stopTest();

        System.assertEquals(null, retPage, 'The return page on the error should be null');
        UTIL_UnitTestData_TEST.assertPageHasError('value of incorrect type');

        Engagement_Plan_Template__c actualTemplate = [SELECT Id, Name FROM Engagement_Plan_Template__c WHERE Id = :template.Id];
        System.assertEquals(templateName, actualTemplate.Name, 'Template Name should be unchanged');

        Map<Id, Engagement_Plan_Task__c> actualTasks = new Map<Id, Engagement_Plan_Task__c>([SELECT Id, Name FROM Engagement_Plan_Task__c]);

        System.assertEquals(2, actualTasks.values().size(), 'Tasks should be unchanged: ' + actualTasks);
        System.assert(actualTasks.containsKey(epTask.Id), 'Parent Task should exist: ' + actualTasks);
        System.assert(actualTasks.containsKey(dependentEpTask.Id), 'Dependent Task should exist: ' + actualTasks);
    }

    /*********************************************************************************************************
    @description 
        Test re-saving of Template and Tasks after an error is fixed 
    verify:
        Records are saved as expected
    **********************************************************************************************************/ 
    private static testMethod void testResaveSucceedsWhenErrorIsFixed() {
        Engagement_Plan_Template__c template = createTemplate();
        Engagement_Plan_Task__c epTask = createTask(template.Id);
        Engagement_Plan_Task__c dependentEpTask = createDependentTask(template.Id, epTask.Id);

        setUpPage(template.Id);
        
        EP_ManageEPTemplate_CTRL ctrl = new EP_ManageEPTemplate_CTRL(new ApexPages.StandardController(template));

        ctrl.getTaskTree();
        ctrl.mapTaskWrappers.get('1').detail.put('Name', epTask.Name + ' - Test Update');

        // Cause an error on update
        Id parentTaskId = ctrl.mapTaskWrappers.get('1').detail.Parent_Task__c;
        ctrl.mapTaskWrappers.get('1').detail.Parent_Task__c = UTIL_UnitTestData_TEST.MOCK_ACCOUNT_ID;

        ctrl.addTask();
        ctrl.getTaskTree();
        ctrl.mapTaskWrappers.get('2').detail.put('Name', 'foo');

        ctrl.currentTaskLevel = '2';
        ctrl.addDependentTask();
        ctrl.getTaskTree();
        ctrl.mapTaskWrappers.get('2-1').detail.put('Name', 'foo-dependent');

        ctrl.addTask();
        ctrl.getTaskTree();
        ctrl.mapTaskWrappers.get('3').detail.put('Name', 'bar');

        PageReference retPage = ctrl.saveClose();

        System.assertEquals(null, retPage, 'The return page on the error should be null');
        UTIL_UnitTestData_TEST.assertPageHasError('value of incorrect type');

        //fix the error
        ctrl.getTaskTree();
        ctrl.mapTaskWrappers.get('1').detail.Parent_Task__c = parentTaskId;

        Test.startTest();
        retPage = ctrl.saveClose();
        Test.stopTest();

        System.assertNotEquals(null, retPage, 'The return page on success should be provided. Page messages: ' + ApexPages.getMessages());

        Map<Id, Engagement_Plan_Task__c> actualTasks = new Map<Id, Engagement_Plan_Task__c>();
        for (Engagement_Plan_Task__c task : [
            SELECT Id, Name, Engagement_Plan_Template__c, Parent_Task__c FROM Engagement_Plan_Task__c
        ]) {
            System.assertEquals(template.Id, task.Engagement_Plan_Template__c);
            actualTasks.put(task.Id, task);
        }

        System.assertEquals(5, actualTasks.values().size(), 'New Tasks should be added: ' + actualTasks);

        Engagement_Plan_Task__c actual = actualTasks.get(epTask.Id);
        System.assertNotEquals(null, actual, 'Existing Task should still exist');
        System.assertEquals(null, actual.Parent_Task__c, 'Parent Task should not be provided for the existing Task');

        actual = actualTasks.get(dependentEpTask.Id);
        System.assertNotEquals(null, actual, 'Dependent Task should still exist');
        System.assertEquals(epTask.Id, actual.Parent_Task__c, 'Dependent Task should have the parent Task');

        Id newParentTaskId = ctrl.mapTaskWrappers.get('2').detail.Id;
        System.assertNotEquals(null, newParentTaskId, 'New Parent Task should be created');

        actual = actualTasks.get(newParentTaskId);
        System.assertNotEquals(null, actual, 'New Parent Task should exist');
        System.assertEquals(null, actual.Parent_Task__c, 'New Parent Task should not have parent');

        actual = actualTasks.get(ctrl.mapTaskWrappers.get('2-1').detail.Id);
        System.assertNotEquals(null, actual, 'New dependent Task should exist');
        System.assertEquals(newParentTaskId, actual.Parent_Task__c, 'New dependent Task should have a parent Task');

        actual = actualTasks.get(ctrl.mapTaskWrappers.get('3').detail.Id);
        System.assertNotEquals(null, actual, 'New Task that is not parent should exist');
        System.assertEquals(null, actual.Parent_Task__c, 'New Task should not have parent Task');
    }

    // Helpers
    ///////////

    /**
     * @description Creates Template to be used in the controller
     * @return Engagement_Plan_Template__c The template
     */
    private static Engagement_Plan_Template__c createTemplate() {
        Engagement_Plan_Template__c template = new Engagement_Plan_Template__c(
            Name = 'Template',
            Skip_Weekends__c = false,
            Default_Assignee__c = EP_EngagementPlans_UTIL.BLANK_ASSIGNMENT_USER_CREATING
        );

        insert template;
        return template;
    }

    /**
     * @description Creates a Task for the Template
     * @param templateId A Template Id
     * @return Engagement_Plan_Task__c The Engagement Plan Task
     */
    private static Engagement_Plan_Task__c createTask(Id templateId) {
        Engagement_Plan_Task__c epTask = new Engagement_Plan_Task__c(
            Name = 'Call',
            Engagement_Plan_Template__c = templateId,
            Comments__c = 'This comment should be copied correctly to the Task.',
            Reminder__c = true,
            Reminder_Time__c = '660',
            Send_Email__c = true,
            Days_After__c = 3,
            Type__c = 'Call',
            Priority__c = 'Medium'
        );

        insert epTask;
        return epTask;
    }

    /**
     * @description Creates a dependent Task for the Template and Parent Task
     * @param templateId A Template Id
     * @param parentTaskId A Engagement Plan Task Id
     * @return Engagement_Plan_Task__c The dependent Engagement Plan Task
     */
    private static Engagement_Plan_Task__c createDependentTask(Id templateId, Id parentTaskId) {
        Engagement_Plan_Task__c dependentEpTask = new Engagement_Plan_Task__c(
            Name = 'Email',
            Engagement_Plan_Template__c = templateId,
            Parent_Task__c = parentTaskId,
            Comments__c = 'This comment should also be copied correctly to the Task.',
            Reminder__c = true,
            Reminder_Time__c = '780',
            Send_Email__c = true,
            Days_After__c = 10,
            Type__c = 'Email',
            Priority__c = 'Low'
        );

        insert dependentEpTask;
        return dependentEpTask;
    }

    /**
     * @description Sets up VF page for the Template
     * @param templateId A Template Id
     * @return PageReference 
     */
    private static PageReference setUpPage(Id templateId) {
        PageReference pageRef = Page.EP_ManageEPTemplate;
        pageRef.getParameters().put('id', templateId);

        Test.setCurrentPage(pageRef);

        return pageRef;
    }
}