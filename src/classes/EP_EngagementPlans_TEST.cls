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
@isTest
private with sharing class EP_EngagementPlans_TEST {

    /*********************************************************************************************************
    * @description Creates a template with two EP Tasks, one of them dependent on the other. Then creates an
    * Engagement Plan using that template. Verifies that tasks are created, that fields are copied over, and
    * that both non-dependent and dependent tasks use the correct defaults.
    */
    static testMethod void testDependentPlan() {

        Id otherUserId = getOtherUserId();

        Contact con = new Contact(LastName = 'foo');
        insert con;

        Engagement_Plan_Template__c template = new Engagement_Plan_Template__c(
            Name = 'Template',
            Skip_Weekends__c = false,
            Blank_Assignment_Rule__c = 'User Creating Action Plan'
        );
        insert template;

        Engagement_Plan_Task__c epTask = new Engagement_Plan_Task__c(
            Name = 'Call',
            Engagement_Plan_Template__c = template.id,
            Assigned_To__c = otherUserId,
            Comments__c = 'This comment should be copied correctly to the Task.',
            Reminder__c = true,
            Reminder_Minutes__c = '660',
            Send_Email__c = true,
            Type__c = 'Call',
            Priority__c = 'Medium'
        );
        insert epTask;

        Engagement_Plan_Task__c dependentEpTask = new Engagement_Plan_Task__c(
            Name = 'Email',
            Engagement_Plan_Template__c = template.id,
            Dependent_Task__c = epTask.id,
            Comments__c = 'This comment should also be copied correctly to the Task.',
            Reminder__c = true,
            Reminder_Minutes__c = '780',
            Send_Email__c = true,
            Days_After__c = 3,
            Type__c = 'Email',
            Priority__c = 'Low'
        );
        insert dependentEpTask;

        Engagement_Plan__c plan = new Engagement_Plan__c(
            Contact__c = con.id,
            Engagement_Plan_Template__c = template.id
        );

        Test.startTest();
        insert plan;
        Test.stopTest();

        List<Task> results = [SELECT Id, OwnerId, WhoId, Type, Status, Subject, ActivityDate, Priority, Description,
                            IsReminderSet, ReminderDateTime FROM Task WHERE WhoId = :con.id ORDER BY ActivityDate];
        System.assertEquals(2, results.size(), 'Two tasks should be created.');

        System.assertEquals(results[0].Subject, 'Call', 'Subject field should be set based on EP Task Name.');
        System.assertEquals(results[0].Description, 'This comment should be copied correctly to the Task.');
        
        System.assertEquals(results[0].ActivityDate, System.Today(), 'Activity Date should be set today.');
        System.assert(results[0].IsReminderSet, 'Reminder should be set.');
        System.assertEquals(results[0].ReminderDateTime.Date(), System.Today(), 'Reminder should be set today.');
        System.assertEquals(results[0].Priority, 'Medium', 'Priority field should be set based on EP Task Priority.');
        System.assertEquals(results[0].OwnerId, otherUserId, 'Task owner should be based on EP Task Assigned To field.');

        System.assertEquals(results[1].Subject, 'Email', 'Subject field should be set based on EP Task Name.');
        System.assertEquals(results[1].Description, 'This comment should also be copied correctly to the Task.');
        System.assertEquals(results[1].ActivityDate, System.Today().addDays(3), 'Activity Date should be set three days from now.');
        System.assert(!results[1].IsReminderSet, 'Reminder should not be set for a dependent task.');
        System.assertEquals(results[1].Priority, 'Low', 'Priority field should be set based on EP Task Priority.');
        System.assertEquals(results[1].OwnerId, UserInfo.getUserId(), 'Task owner left blank should be based on running user.');
    }

    /*********************************************************************************************************
    * @description 
    */
    static testMethod void testSkipWeekends() {

        Integer daysUntilWeekend = getDaysUntilWeekend(System.today());
        
        Contact con = new Contact(LastName = 'foo');
        insert con;

        Engagement_Plan_Template__c template = new Engagement_Plan_Template__c(
            Name = 'TemplateSkipWeekends',
            Skip_Weekends__c = true,
            Skip_Day__c = 'Monday',
            Blank_Assignment_Rule__c = 'User Creating Action Plan'
        );
        insert template;

        Engagement_Plan_Task__c epTask = new Engagement_Plan_Task__c(
            Name = 'Call',
            Engagement_Plan_Template__c = template.id,
            Comments__c = 'This comment should be copied correctly to the Task.',
            Reminder__c = true,
            Reminder_Minutes__c = '660',
            Type__c = 'Call',
            Priority__c = 'Medium',
            //use the number of days until the weekend for the delay of this task
            Days_After__c = daysUntilWeekend
        );
        insert epTask;

        Engagement_Plan__c plan = new Engagement_Plan__c(
            Contact__c = con.id,
            Engagement_Plan_Template__c = template.id
        );

        Test.startTest();
        insert plan;
        Test.stopTest();

        List<Task> results = [SELECT Id, OwnerId, WhoId, Type, Status, Subject, ActivityDate, Priority, Description,
                            IsReminderSet, ReminderDateTime FROM Task WHERE WhoId = :con.id ORDER BY ActivityDate];
        System.assertEquals(1, results.size(), 'A task should be created.');

        System.assertEquals(results[0].Subject, 'Call', 'Subject field should be set based on EP Task Name.');
        System.assertEquals(results[0].Description, 'This comment should be copied correctly to the Task.');
        
        System.assert(
            results[0].ActivityDate > System.today().addDays(daysUntilWeekend), 
            'Activity Date ('+results[0].ActivityDate+') should be set after the weekend. ' + System.today().addDays(daysUntilWeekend)
        );
        System.assert(results[0].IsReminderSet, 'Reminder should be set.');
        System.assert(results[0].ReminderDateTime.Date() > System.now().addDays(daysUntilWeekend), 'Reminder should be set after the weekend.');
        System.assertEquals(results[0].Priority, 'Medium', 'Priority field should be set based on EP Task Priority.');
    }

    /*********************************************************************************************************
    * @description Inserts an Engagement Plan without an object lookup, verifies exception is thrown.
    */
    static testMethod void testPlanWithoutLookup() {

        Engagement_Plan_Template__c template = new Engagement_Plan_Template__c(Name = 'Template');
        insert template;

        Engagement_Plan__c plan = new Engagement_Plan__c(
            Engagement_Plan_Template__c = template.id
        );

        Exception caughtException;
        Test.startTest();
        try {
            insert plan;
        } catch (Exception ex) {
            caughtException = ex;
        }
        Test.stopTest();

        System.assertNotEquals(null, caughtException, 'An exception should be caught.');
        System.assert(caughtException.getMessage().contains(Label.engagementPlanNoLookups));
    }

    /*********************************************************************************************************
    * @description Inserts an Engagement Plan with two object lookups, verifies exception is thrown.
    */
    static testMethod void testPlanWithTwoLookups() {

        Account acc = new Account(Name='foo');
        insert acc;
        Contact con = new Contact(LastName='foo', AccountId = acc.id);
        insert con;
        Engagement_Plan_Template__c template = new Engagement_Plan_Template__c(Name = 'Template');
        insert template;

        Engagement_Plan__c plan = new Engagement_Plan__c(
            Engagement_Plan_Template__c = template.id,
            Contact__c = con.id,
            Account__c = acc.id
        );

        Exception caughtException;
        Test.startTest();
        try {
            insert plan;
        } catch (Exception ex) {
            caughtException = ex;
        }
        Test.stopTest();

        System.assertNotEquals(null, caughtException, 'An exception should be caught.');
        System.assert(caughtException.getMessage().contains(Label.engagementPlanTwoLookups));
    }

    /*********************************************************************************************************
    * @description Returns the user id of an active user other than the current one if one exists, 
    * otherwise returns the current user id.
    */
    private static Id getOtherUserId() {
        List<User> otherUsers = [SELECT Id FROM User WHERE IsActive = true AND Id != :UserInfo.getUserId()];
        if (otherUsers.isEmpty()) {
            return UserInfo.getUserId();
        } else {
            return otherUsers[0].Id;
        }
    }

    /*********************************************************************************************************
    * @description Calculates the number of days from today until the weekend.
    **/
    private static Integer getDaysUntilWeekend(Date originalDate) {
        Date refDate = Date.newInstance(1900, 1, 7);  // Jan 7 1900 = Sunday
        Integer dayOfWeek = Math.mod(refDate.daysBetween(originalDate), 7); // 0 = Sunday ... 6 = Saturday
        //if we're already on a saturday or sunday, no offset is needed
        if (dayOfWeek == 0 || dayOfWeek == 6) {
            return 0;
        //otherwise, return the number of days until Saturday
        } else {
            return 6 - dayOfWeek;
        }
    }
}