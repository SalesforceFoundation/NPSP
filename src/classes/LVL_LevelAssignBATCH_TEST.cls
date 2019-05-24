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
* @group Levels
* @description test the batchable class for Level Assignments
*/

@isTest(IsParallel=true)
private class LVL_LevelAssignBATCH_TEST {

    private static Level__c lvlTin { get; set; }
    private static Level__c lvlBronze { get; set; }
    private static Level__c lvlSilver { get; set; }
    private static Level__c lvlGold { get; set; }
    private static Level__c lvlPlatinum { get; set; }
    private static Level__c lvlAcctZinc { get; set; }

    /*********************************************************************************************************
    * @description creates Bronze, Silver, and Gold Level records for test code to use.
    */
    private static void createTestLevels() {
        // create Levels
        lvlTin = new Level__c(
            Name = 'Tin',
            Target__c = 'Contact',
            Source_Field__c = 'npo02__TotalOppAmount__c',
            Level_Field__c = 'npo02__LastMembershipLevel__c',
            Previous_Level_Field__c = 'npo02__LastMembershipOrigin__c',
            Active__c = true,
            Minimum_Amount__c = null,
            Maximum_Amount__c = 100);

        lvlBronze = new Level__c(
            Name = 'Bronze',
            Target__c = 'Contact',
            Source_Field__c = 'npo02__TotalOppAmount__c',
            Level_Field__c = 'npo02__LastMembershipLevel__c',
            Previous_Level_Field__c = 'npo02__LastMembershipOrigin__c',
            Active__c = true,
            Minimum_Amount__c = 100,
            Maximum_Amount__c = 1000);

        lvlSilver = new Level__c(
            Name = 'Silver',
            Target__c = 'Contact',
            Source_Field__c = 'npo02__TotalOppAmount__c',
            Level_Field__c = 'npo02__LastMembershipLevel__c',
            Previous_Level_Field__c = 'npo02__LastMembershipOrigin__c',
            Active__c = true,
            Minimum_Amount__c = 1000,
            Maximum_Amount__c = 5000);

        lvlGold = new Level__c(
            Name = 'Gold',
            Target__c = 'Contact',
            Source_Field__c = 'npo02__TotalOppAmount__c',
            Level_Field__c = 'npo02__LastMembershipLevel__c',
            Previous_Level_Field__c = 'npo02__LastMembershipOrigin__c',
            Active__c = true,
            Minimum_Amount__c = 5000,
            Maximum_Amount__c = 90000); // consciously left 10k break for other tests to use.

        lvlPlatinum = new Level__c(
            Name = 'Platinum',
            Target__c = 'Contact',
            Source_Field__c = 'npo02__TotalOppAmount__c',
            Level_Field__c = 'npo02__LastMembershipLevel__c',
            Previous_Level_Field__c = 'npo02__LastMembershipOrigin__c',
            Active__c = true,
            Minimum_Amount__c = 100000,
            Maximum_Amount__c = null);

        lvlAcctZinc = new Level__c(
            Name = 'Zinc',
            Target__c = 'Account',
            Source_Field__c = 'npo02__TotalOppAmount__c',
            Level_Field__c = 'npo02__LastMembershipLevel__c',
            Previous_Level_Field__c = 'npo02__LastMembershipOrigin__c',
            Active__c = true,
            Minimum_Amount__c = 100,
            Maximum_Amount__c = 200);

        insert new Level__c[]{lvlTin, lvlBronze, lvlSilver, lvlGold, lvlPlatinum, lvlAcctZinc};
    }

    /*********************************************************************************************************
    * @description create and add an Engagement Plan Template to the provided Level
    */
    private static void createLevelEngagementPlan(Level__c lvl) {
        Engagement_Plan_Template__c template = new Engagement_Plan_Template__c(
            Name = 'Template',
            Skip_Weekends__c = false,
            Default_Assignee__c = EP_EngagementPlans_UTIL.BLANK_ASSIGNMENT_USER_CREATING
        );
        insert template;

        Engagement_Plan_Task__c epTask = new Engagement_Plan_Task__c(
            Name = 'Call',
            Engagement_Plan_Template__c = template.id,
            Assigned_To__c = UserInfo.getUserId(),
            Comments__c = 'This comment should be copied correctly to the Task.',
            Reminder__c = true,
            Send_Email__c = true,
            Days_After__c = 3,
            Type__c = 'Call',
            Priority__c = 'Medium'
        );
        insert epTask;

        Engagement_Plan_Task__c dependentEpTask = new Engagement_Plan_Task__c(
            Name = 'Email',
            Engagement_Plan_Template__c = template.id,
            Parent_Task__c = epTask.id,
            Comments__c = 'This comment should also be copied correctly to the Task.',
            Reminder__c = true,
            Send_Email__c = true,
            Days_After__c = 10,
            Type__c = 'Email',
            Priority__c = 'Low'
        );
        insert dependentEpTask;

        // now add the EPTemplate to the Level and update it.
        lvl.Engagement_Plan_Template__c = template.Id;
        update lvl;
    }

    /*********************************************************************************************************
    * @description creates a list of Contacts with various donation totals for test code to use.
    */
    private static List<Contact> contacts { get; set; }
    private static DateTime dtCon6Modified { get; set;  }
    private static void createTestContacts() {
        // create & insert contact
        contacts = UTIL_UnitTestData_TEST.CreateMultipleTestContacts(8);
        contacts[0].npo02__TotalOppAmount__c = null;
        contacts[0].npo02__LastMembershipLevel__c = lvlTin.Id;

        contacts[1].npo02__TotalOppAmount__c = 10;
        contacts[2].npo02__TotalOppAmount__c = 100;

        contacts[3].npo02__TotalOppAmount__c = 500;
        contacts[3].npo02__LastMembershipLevel__c = lvlBronze.Id;
        contacts[3].npo02__LastMembershipOrigin__c = lvlBronze.Id;

        contacts[4].npo02__TotalOppAmount__c = 999;
        contacts[4].npo02__LastMembershipLevel__c = lvlGold.Id;

        contacts[5].npo02__TotalOppAmount__c = 1000;
        contacts[5].npo02__LastMembershipLevel__c = lvlBronze.Id;

        contacts[6].npo02__TotalOppAmount__c = 5000;

        contacts[7].npo02__TotalOppAmount__c = 100000;
        insert contacts;

        // we need to see what the LastModifiedDate is after the insert completes, in case any
        // workflow rules in the org may have ran during the insert and thus LastModifiedDate <> CreatedDate.
        // dtCon6Modified will be used in one of our asserts that this contact wasn't modified by our level batch.
         Contact c6 = [select LastModifiedDate from Contact where Id = :contacts[6].Id];
         dtCon6Modified = c6.LastModifiedDate;
    }

    /*********************************************************************************************************
    * @description creates a list of Accounts with various donation totals for test code to use.
    */
    private static List<Account> accounts { get; set; }
    private static void createTestAccounts() {
        // create & insert contact
        accounts = UTIL_UnitTestData_TEST.CreateMultipleTestAccounts(2, null);
        accounts[0].npo02__TotalOppAmount__c = 10;
        accounts[1].npo02__TotalOppAmount__c = 150;
        insert accounts;
    }

    /*********************************************************************************************************
    * @description test our batch process for assigning Levels to Contacts
    */
    @isTest
    private static void testContactLevels() {
        // create Levels
        createTestLevels();

        // add an Engagement Plan Template to Silver
        createLevelEngagementPlan(lvlSilver);

        // create test Contacts
        createTestContacts();

        String query = 'SELECT Id, Name, npo02__TotalOppAmount__c, npo02__LastMembershipLevel__c, npo02__LastMembershipOrigin__c, CreatedDate, LastModifiedDate FROM Contact';
        LVL_LevelAssign_BATCH batch = new LVL_LevelAssign_BATCH(query, 'Contact');

        Test.startTest();
        Database.executeBatch(batch);
        Test.stopTest();

        verifyContactLevels();

        Levels_Settings__c levelSettings = Levels_Settings__c.getInstance();
        System.assertEquals(null, levelSettings.LastJobStartTimeAccount__c,
            'The LastJobStartTimeAccount__c should not be populated');
        System.assertNotEquals(null, levelSettings.LastJobStartTimeContact__c,
            'The LastJobStartTimeContact__c should be populated');
    }

    /*********************************************************************************************************
    * @description test our batch process for unassigning Levels on Contacts when Levels Change
    * and they no longer meet the criteria
    */
    @isTest
    private static void testContactLevelsChange() {
        // create Levels
        createTestLevels();

        // create test Contacts
        createTestContacts();

        // modify lvl Tin
        lvlTin.Minimum_Amount__c = 10; // Contact 0 will no longer meet this criteria
        update lvlTin;

        string query = 'SELECT Id, Name, npo02__TotalOppAmount__c, npo02__LastMembershipLevel__c, npo02__LastMembershipOrigin__c, CreatedDate, LastModifiedDate FROM Contact';
        LVL_LevelAssign_BATCH batch = new LVL_LevelAssign_BATCH(query, 'Contact');

        Test.startTest();
        Database.executeBatch(batch);
        Test.stopTest();

        Contact conZero = [SELECT Id, npo02__LastMembershipLevel__c FROM Contact WHERE Id = :contacts[0].Id];
        System.assertEquals(null, conZero.npo02__LastMembershipLevel__c);
    }

    /*********************************************************************************************************
    * @description tests our Level Assigning when invokved through our Schedulable class.
    */
    @isTest
    private static void testLevelAssignScheduling() {
        // create Levels
        createtestLevels();

        // add an Engagement Plan Template to Silver
        createLevelEngagementPlan(lvlSilver);

        // create test Contacts
        createTestContacts();

        LVL_LevelAssign_SCHED sched = new LVL_LevelAssign_SCHED();
        Test.startTest();
        sched.runBatch();
        Test.stopTest();

        System.assertEquals(2, [SELECT COUNT() FROM AsyncApexJob WHERE JobType = 'BatchApex'],
            'Two batches should run, one for Contact and one for Account'
        );

        Levels_Settings__c levelSettings = Levels_Settings__c.getInstance();
        System.assertNotEquals(null, levelSettings.LastJobStartTimeAccount__c,
            'The LastJobStartTimeAccount__c should be populated');
        System.assertNotEquals(null, levelSettings.LastJobStartTimeContact__c,
            'The LastJobStartTimeContact__c should be populated');

        verifyContactLevels();
    }

    /*********************************************************************************************************
    * @description verify contact levels correctly set
    */
    private static void verifyContactLevels() {
        String query = 'SELECT Id, Name, npo02__TotalOppAmount__c, npo02__LastMembershipLevel__c, npo02__LastMembershipOrigin__c, CreatedDate, LastModifiedDate FROM Contact';
        contacts = Database.query(query + ' ORDER BY npo02__TotalOppAmount__c');
        System.assertEquals(lvlTin.Id, contacts[0].npo02__LastMembershipLevel__c);
        System.assertEquals(null, contacts[0].npo02__LastMembershipOrigin__c);

        System.assertEquals(lvlTin.Id, contacts[1].npo02__LastMembershipLevel__c);
        System.assertEquals(null, contacts[1].npo02__LastMembershipOrigin__c);

        System.assertEquals(lvlBronze.Id, contacts[2].npo02__LastMembershipLevel__c);
        System.assertEquals(null, contacts[2].npo02__LastMembershipOrigin__c);

        // contact3 should not be touched since it was already Bronze level.
        System.assertEquals(lvlBronze.Id, contacts[3].npo02__LastMembershipLevel__c);
        System.assertEquals(lvlBronze.Id, contacts[3].npo02__LastMembershipOrigin__c);
        System.assertEquals(dtCon6Modified, contacts[3].LastModifiedDate);

        System.assertEquals(lvlBronze.Id, contacts[4].npo02__LastMembershipLevel__c);
        System.assertEquals(lvlGold.Id, contacts[4].npo02__LastMembershipOrigin__c);

        System.assertEquals(lvlSilver.Id, contacts[5].npo02__LastMembershipLevel__c);
        System.assertEquals(lvlBronze.Id, contacts[5].npo02__LastMembershipOrigin__c);

        // check Silver's Engagement Plan got created
        List<Engagement_Plan__c> engagementPlans = [SELECT Id, Contact__c, Engagement_Plan_Template__c FROM Engagement_Plan__c];
        System.assertEquals(1, engagementPlans.size());
        System.assertEquals(contacts[5].Id, engagementPlans[0].Contact__c);
        System.assertEquals(lvlSilver.Engagement_Plan_Template__c, engagementPlans[0].Engagement_Plan_Template__c);

        System.assertEquals(lvlGold.Id, contacts[6].npo02__LastMembershipLevel__c);
        System.assertEquals(null, contacts[6].npo02__LastMembershipOrigin__c);

        System.assertEquals(lvlPlatinum.Id, contacts[7].npo02__LastMembershipLevel__c);
        System.assertEquals(null, contacts[7].npo02__LastMembershipOrigin__c);
    }

    /*********************************************************************************************************
    * @description test our batch process for assigning Levels to Accounts
    */
    @isTest
    private static void testAccountLevels() {
        // create Levels
        createTestLevels();

        // add an Engagement Plan Template to Zinc
        createLevelEngagementPlan(lvlAcctZinc);

        // create test Accounts
        createTestAccounts();

        String query = 'SELECT Id, Name, npo02__TotalOppAmount__c, npo02__LastMembershipLevel__c, ' +
            'npo02__LastMembershipOrigin__c, CreatedDate, LastModifiedDate FROM Account where npe01__SYSTEMIsIndividual__c = false ';
        LVL_LevelAssign_BATCH batch = new LVL_LevelAssign_BATCH(query, 'Account');

        Test.startTest();
        Database.executeBatch(batch);
        Test.stopTest();

        Levels_Settings__c levelSettings = Levels_Settings__c.getInstance();
        System.assertNotEquals(null, levelSettings.LastJobStartTimeAccount__c,
            'The LastJobStartTimeAccount__c should be populated');
        System.assertEquals(null, levelSettings.LastJobStartTimeContact__c,
            'The LastJobStartTimeContact__c should not be populated');

        accounts = Database.query(query + ' ORDER BY npo02__TotalOppAmount__c');
        System.assertEquals(null, accounts[0].npo02__LastMembershipLevel__c);
        System.assertEquals(null, accounts[0].npo02__LastMembershipOrigin__c);

        System.assertEquals(lvlAcctZinc.Id, accounts[1].npo02__LastMembershipLevel__c);
        System.assertEquals(null, accounts[1].npo02__LastMembershipOrigin__c);

        // check Zinc's Engagement Plan got created
        List<Engagement_Plan__c> listEP = [select Id, Account__c, Engagement_Plan_Template__c from Engagement_Plan__c];
        
        System.assertEquals(1, listEP.size());
        System.assertEquals(accounts[1].Id, listEP[0].Account__c);
        System.assertEquals(lvlAcctZinc.Engagement_Plan_Template__c, listEP[0].Engagement_Plan_Template__c);
    }

    /*********************************************************************************************************
    * @description tests our Level Validation to detect overlaps with existing levels
    */
    @isTest
    private static void testLevelValidationExistingMin() {
        // create Levels
        createtestLevels();

        Level__c lvl = new Level__c(
            Name = 'Silver Overlap',
            Target__c = 'Contact',
            Source_Field__c = 'npo02__TotalOppAmount__c',
            Level_Field__c = 'npo02__LastMembershipLevel__c',
            Previous_Level_Field__c = 'npo02__LastMembershipOrigin__c',
            Active__c = true,
            Minimum_Amount__c = 1000,
            Maximum_Amount__c = 4999);

        Test.startTest();
        try {
            insert lvl;
            System.assert(false, 'exception should have occurred');
        } catch(Exception ex) {
            System.assert(ex.getMessage().contains(lvl.Name));
        }

        // make sure null minimum also detected
        lvl.Minimum_Amount__c = null;
        try {
            insert lvl;
            System.assert(false, 'exception should have occurred');
        } catch(Exception ex) {
            System.assert(ex.getMessage().contains(lvl.Name));
        }
        Test.stopTest();

    }

    /*********************************************************************************************************
    * @description tests our Level Validation to detect overlaps with existing levels
    */
    @isTest
    private static void testLevelValidationExistingMax() {
        // create Levels
        createtestLevels();

        Level__c lvl = new Level__c(
            Name = 'Bronze Overlap',
            Target__c = 'Contact',
            Source_Field__c = 'npo02__TotalOppAmount__c',
            Level_Field__c = 'npo02__LastMembershipLevel__c',
            Previous_Level_Field__c = 'npo02__LastMembershipOrigin__c',
            Active__c = true,
            Minimum_Amount__c = 10,
            Maximum_Amount__c = 100);

        Test.startTest();
        try {
            insert lvl;
            System.assert(false, 'exception should have occurred');
        } catch(Exception ex) {
            System.assert(ex.getMessage().contains(lvl.Name));
        }

        // make sure null maximum also detected
        lvl.Maximum_Amount__c = null;
        try {
            insert lvl;
            System.assert(false, 'exception should have occurred');
        } catch(Exception ex) {
            System.assert(ex.getMessage().contains(lvl.Name));
        }
        Test.stopTest();

    }

    /*********************************************************************************************************
    * @description tests our Level Validation to detect overlaps with new levels
    */
    @isTest
    private static void testLevelValidationNewMin() {

        Level__c lvl1 = new Level__c(
            Name = 'new',
            Target__c = 'Contact',
            Source_Field__c = 'npo02__TotalOppAmount__c',
            Level_Field__c = 'npo02__LastMembershipLevel__c',
            Previous_Level_Field__c = 'npo02__LastMembershipOrigin__c',
            Active__c = true,
            Minimum_Amount__c = 10,
            Maximum_Amount__c = 100);

        Level__c lvl2 = new Level__c(
            Name = 'new2',
            Target__c = 'Contact',
            Source_Field__c = 'npo02__TotalOppAmount__c',
            Level_Field__c = 'npo02__LastMembershipLevel__c',
            Previous_Level_Field__c = 'npo02__LastMembershipOrigin__c',
            Active__c = true,
            Minimum_Amount__c = 101,
            Maximum_Amount__c = 200);

        Level__c lvl3 = new Level__c(
            Name = 'new3',
            Target__c = 'Contact',
            Source_Field__c = 'npo02__TotalOppAmount__c',
            Level_Field__c = 'npo02__LastMembershipLevel__c',
            Previous_Level_Field__c = 'npo02__LastMembershipOrigin__c',
            Active__c = true,
            Minimum_Amount__c = 50,
            Maximum_Amount__c = 75);

        try {
            Test.startTest();
            insert new Level__c[]{lvl1, lvl2, lvl3};
            Test.stopTest();
            System.assert(false, 'exception should have occurred');
        } catch(Exception ex) {
            System.assert(ex.getMessage().contains(lvl3.Name));
        }
    }

    /*********************************************************************************************************
    * @description tests our Level Validation to detect overlaps with new levels
    */
    @isTest
    private static void testLevelValidationNewMax() {

        Level__c lvl1 = new Level__c(
            Name = 'new',
            Target__c = 'Contact',
            Source_Field__c = 'npo02__TotalOppAmount__c',
            Level_Field__c = 'npo02__LastMembershipLevel__c',
            Previous_Level_Field__c = 'npo02__LastMembershipOrigin__c',
            Active__c = true,
            Minimum_Amount__c = 10,
            Maximum_Amount__c = 100);

        Level__c lvl2 = new Level__c(
            Name = 'new2',
            Target__c = 'Contact',
            Source_Field__c = 'npo02__TotalOppAmount__c',
            Level_Field__c = 'npo02__LastMembershipLevel__c',
            Previous_Level_Field__c = 'npo02__LastMembershipOrigin__c',
            Active__c = true,
            Minimum_Amount__c = 101,
            Maximum_Amount__c = 200);

        Level__c lvl3 = new Level__c(
            Name = 'new3',
            Target__c = 'Contact',
            Source_Field__c = 'npo02__TotalOppAmount__c',
            Level_Field__c = 'npo02__LastMembershipLevel__c',
            Previous_Level_Field__c = 'npo02__LastMembershipOrigin__c',
            Active__c = true,
            Minimum_Amount__c = 5,
            Maximum_Amount__c = 75);

        try {
            Test.startTest();
            insert new Level__c[]{lvl1, lvl2, lvl3};
            Test.stopTest();
            System.assert(false, 'exception should have occurred');
        } catch(Exception ex) {
            System.assert(ex.getMessage().contains(lvl3.Name));
        }
    }

    /*********************************************************************************************************
    * @description tests our Level Validation to detect duplicate names with existing levels
    */
    @isTest
    private static void testLevelValidationExistingNames() {
        // create Levels
        createtestLevels();

        Level__c lvl = new Level__c(
            Name = 'Gold',
            Target__c = 'Contact',
            Source_Field__c = 'npo02__TotalOppAmount__c',
            Level_Field__c = 'npo02__LastMembershipLevel__c',
            Previous_Level_Field__c = 'npo02__LastMembershipOrigin__c',
            Active__c = true,
            Minimum_Amount__c = 90000,
            Maximum_Amount__c = 90001);

        Test.startTest();
        try {
            insert lvl;
            System.assert(false, 'exception should have occurred');
        } catch(Exception ex) {
            System.assert(ex.getMessage().contains(lvl.Name));
        }

        // make sure rename also detected
        lvlSilver.Name = 'Gold';
        try {
            insert lvl;
            System.assert(false, 'exception should have occurred');
        } catch(Exception ex) {
            System.assert(ex.getMessage().contains(lvl.Name));
        }
        Test.stopTest();
    }

    /*********************************************************************************************************
    * @description tests our Level Validation to detect duplicate names with new levels
    */
    @isTest
    private static void testLevelValidationNewNames() {

        Level__c lvl1 = new Level__c(
            Name = 'new',
            Target__c = 'Contact',
            Source_Field__c = 'npo02__TotalOppAmount__c',
            Level_Field__c = 'npo02__LastMembershipLevel__c',
            Previous_Level_Field__c = 'npo02__LastMembershipOrigin__c',
            Active__c = true,
            Minimum_Amount__c = 10,
            Maximum_Amount__c = 100);

        Level__c lvl2 = new Level__c(
            Name = 'new',
            Target__c = 'Contact',
            Source_Field__c = 'npo02__TotalOppAmount__c',
            Level_Field__c = 'npo02__LastMembershipLevel__c',
            Previous_Level_Field__c = 'npo02__LastMembershipOrigin__c',
            Active__c = true,
            Minimum_Amount__c = 101,
            Maximum_Amount__c = 200);

        try {
            Test.startTest();
            insert new Level__c[]{lvl1, lvl2};
            Test.stopTest();
            System.assert(false, 'exception should have occurred');
        } catch(Exception ex) {
            System.assert(ex.getMessage().contains(lvl1.Name));
        }
    }

    /*********************************************************************************************************
    * @description tests our Level Validation to detect min/max overlap within a new level
    */
    @isTest
    private static void testLevelValidationMinMaxOverlap() {

        Level__c lvl1 = new Level__c(
            Name = 'new',
            Target__c = 'Contact',
            Source_Field__c = 'npo02__TotalOppAmount__c',
            Level_Field__c = 'npo02__LastMembershipLevel__c',
            Previous_Level_Field__c = 'npo02__LastMembershipOrigin__c',
            Active__c = true,
            Minimum_Amount__c = 101,
            Maximum_Amount__c = 100);

        try {
            Test.startTest();
            insert lvl1;
            Test.stopTest();
            System.assert(false, 'exception should have occurred');
        } catch(Exception ex) {
            System.assert(ex.getMessage().contains(lvl1.Name));
        }
    }

    /*********************************************************************************************************
    * @description tests our Level Validation to detect no min & max specified
    */
    @isTest
    private static void testLevelValidationMinMaxMustExist() {

        Level__c lvl1 = new Level__c(
            Name = 'new',
            Target__c = 'Contact',
            Source_Field__c = 'npo02__TotalOppAmount__c',
            Level_Field__c = 'npo02__LastMembershipLevel__c',
            Previous_Level_Field__c = 'npo02__LastMembershipOrigin__c',
            Active__c = true);

        try {
            Test.startTest();
            insert lvl1;
            Test.stopTest();
            System.assert(false, 'exception should have occurred');
        } catch(Exception ex) {
            System.assert(ex.getMessage().contains(lvl1.Name));
        }
    }

    /*********************************************************************************************************
    @description
        Execute Level Assign Batch on Contacts having Source Field value outside of all levels
    verify:
        The Level Field is changed to blank.
        The Previous Level Field is populated with the Level Field as it was before the batch has been run.
    **********************************************************************************************************/
    @isTest
    private static void previousLevelShouldBePopulatedWhenCurrentLevelIsChangedToBlank() {
        Level__c[] levels = new Level__c[] {
            new Level__c(
                Name = 'Tin',
                Target__c = 'Contact',
                Source_Field__c = 'npo02__TotalOppAmount__c',
                Level_Field__c = 'npo02__LastMembershipLevel__c',
                Previous_Level_Field__c = 'npo02__LastMembershipOrigin__c',
                Active__c = true,
                Minimum_Amount__c = 20,
                Maximum_Amount__c = 100
            ),
            new Level__c(
                Name = 'Bronze',
                Target__c = 'Contact',
                Source_Field__c = 'npo02__TotalOppAmount__c',
                Level_Field__c = 'npo02__LastMembershipLevel__c',
                Previous_Level_Field__c = 'npo02__LastMembershipOrigin__c',
                Active__c = true,
                Minimum_Amount__c = 100,
                Maximum_Amount__c = 1000
            )
        };
        insert levels;

        Contact[] contacts = new Contact[] {
            new Contact(
                LastName = 'PreviousLevelIsPopulated',
                npo02__LastMembershipLevel__c = levels[0].id,
                npo02__LastMembershipOrigin__c = levels[1].id,
                npo02__TotalOppAmount__c = 10
            ),
            new Contact(
                LastName = 'PreviousLevelIsBlank',
                npo02__LastMembershipLevel__c = levels[1].id,
                npo02__LastMembershipOrigin__c = null,
                npo02__TotalOppAmount__c = 2000
            )
        };
        insert contacts;

        executeLevelAssignBatchForContact();

        Map<Id, Contact> actualContactsById = new Map<Id, Contact>(getContacts());

        for (Contact c : contacts) {
            Contact actual = actualContactsById.get(c.Id);

            //Level Field is blank since the value is outside of defined levels
            System.assertEquals(null, actual.npo02__LastMembershipLevel__c);

            //Previous Level Field is populated and equals to the Level Field before the batch has been run
            System.assertNotEquals(null, actual.npo02__LastMembershipOrigin__c);
            System.assertEquals(c.npo02__LastMembershipLevel__c, actual.npo02__LastMembershipOrigin__c);
        }
    }

    /*********************************************************************************************************
    @description
        Execute Level Assign Batch on Contacts having Source Field value
        either in the same level or outside of all levels
    verify:
        Level Field and Previous Level Field values are not changed
    **********************************************************************************************************/
    @isTest
    private static void previousLevelShouldNotChangeWhenCurrentLevelDoesNotChange() {
        Level__c[] levels = new Level__c[] {
            new Level__c(
                Name = 'Tin',
                Target__c = 'Contact',
                Source_Field__c = 'npo02__TotalOppAmount__c',
                Level_Field__c = 'npo02__LastMembershipLevel__c',
                Previous_Level_Field__c = 'npo02__LastMembershipOrigin__c',
                Active__c = true,
                Minimum_Amount__c = 20,
                Maximum_Amount__c = 100
            ),
            new Level__c(
                Name = 'Bronze',
                Target__c = 'Contact',
                Source_Field__c = 'npo02__TotalOppAmount__c',
                Level_Field__c = 'npo02__LastMembershipLevel__c',
                Previous_Level_Field__c = 'npo02__LastMembershipOrigin__c',
                Active__c = true,
                Minimum_Amount__c = 100,
                Maximum_Amount__c = 1000
            )
        };
        insert levels;

        Contact[] contacts = new Contact[] {
            new Contact(
                LastName = 'PreviousLevelIsPopulated',
                npo02__LastMembershipLevel__c = null,
                npo02__LastMembershipOrigin__c = levels[0].id,
                npo02__TotalOppAmount__c = 10
            ),
            new Contact(
                LastName = 'PreviousLevelIsBlank',
                npo02__LastMembershipLevel__c = null,
                npo02__LastMembershipOrigin__c = null,
                npo02__TotalOppAmount__c = 2000
            ),
            new Contact(
                LastName = 'BothLevelsAreProvided',
                npo02__LastMembershipLevel__c = levels[0].id,
                npo02__LastMembershipOrigin__c = levels[1].id,
                npo02__TotalOppAmount__c = 50
            )
        };
        insert contacts;

        executeLevelAssignBatchForContact();

        Map<Id, Contact> actualContactsById = new Map<Id, Contact>(getContacts());

        for (Contact c : contacts) {
            Contact actual = actualContactsById.get(c.Id);

            //Level Field is unchanged
            System.assertEquals(c.npo02__LastMembershipLevel__c, actual.npo02__LastMembershipLevel__c);

            //Previous Level Field is unchanged
            System.assertEquals(c.npo02__LastMembershipOrigin__c, actual.npo02__LastMembershipOrigin__c);
        }
    }

    /*********************************************************************************************************
    * @description Confirms that Ladder constructor sets target correctly
    */
    @isTest
    private static void ladderConstructorShouldSetTarget() {
        LVL_LevelAssign_BATCH.Ladder ladder = new LVL_LevelAssign_BATCH.Ladder('Contact');

        System.assertEquals('Contact', ladder.target, 'The target attribute should be set correctly');
    }

    /*********************************************************************************************************
    * @description Confirms that Ladder can build a SOQL query
    */
    @isTest
    private static void shouldBuildQueryForLevel() {
        Level__c paperLevel = new Level__c(
            Name = 'Paper',
            Target__c = 'Contact',
            Source_Field__c = 'npo02__TotalOppAmount__c',
            Level_Field__c = 'npo02__LastMembershipLevel__c',
            Previous_Level_Field__c = 'npo02__LastMembershipOrigin__c'
        );

        Level__c rockLevel = new Level__c(
            Name = 'Rock',
            Target__c = 'Contact',
            Source_Field__c = 'npo02__TotalOppAmount__c',
            Level_Field__c = 'npo02__LastMembershipLevel__c',
            Previous_Level_Field__c = 'npo02__LastMembershipOrigin__c'
        );

        LVL_LevelAssign_BATCH.Ladder ladder = new LVL_LevelAssign_BATCH.Ladder('Contact');
        ladder.addLevel(paperLevel);
        ladder.addLevel(rockLevel);

        Test.startTest();
        String soqlQuery = ladder.buildQuery();
        Test.stopTest();

        System.assert(soqlQuery.contains('npo02__TotalOppAmount__c'),
            'The query should contain the Source_Field__c value');
        System.assert(soqlQuery.contains('npo02__LastMembershipLevel__c'),
            'The query should contain the Level_Field__c value');
        System.assert(soqlQuery.contains('npo02__LastMembershipOrigin__c'),
            'The query should contain the Previous_Level_Field__c value');
        System.assert(soqlQuery.contains('FROM Contact'),
            'The query should query from the correct target SObject');
        System.assert(!soqlQuery.contains('WHERE SystemModStamp >= '),
            'The query should not include a SystemModStamp filter when there is no last run time setting');

        QueryException unexpectedException;
        try {
            List<Contact> queriedContacts = Database.query(soqlQuery);
        } catch(QueryException ex) {
            unexpectedException = ex;
        }

        System.assertEquals(null, unexpectedException, 'The SOQL query should be valid');
    }

    /*********************************************************************************************************
    * @description Confirms that Ladder builds SOQL query with SystemModStamp filter
    */
    @isTest
    private static void shouldBuildQueryWithLastRunFilter() {
        Datetime contactDatetime = Datetime.now();
        Datetime accountDatetime = Datetime.now().addDays(-10);

        LVL_LevelAssign_BATCH.levelsSettings = new Levels_Settings__c(
            LastJobStartTimeContact__c = contactDatetime,
            LastJobStartTimeAccount__c = accountDatetime
        );

        Level__c contactLevel = new Level__c(
            Target__c = 'Contact',
            Source_Field__c = 'npo02__TotalOppAmount__c',
            Level_Field__c = 'npo02__LastMembershipLevel__c',
            Previous_Level_Field__c = 'npo02__LastMembershipOrigin__c'
        );

        Level__c accountLevel = new Level__c(
            Target__c = 'Account',
            Source_Field__c = 'npo02__TotalOppAmount__c',
            Level_Field__c = 'npo02__LastMembershipLevel__c',
            Previous_Level_Field__c = 'npo02__LastMembershipOrigin__c'
        );

        LVL_LevelAssign_BATCH.Ladder contactLadder = new LVL_LevelAssign_BATCH.Ladder('Contact')
            .addLevel(contactLevel);

        LVL_LevelAssign_BATCH.Ladder accountLadder = new LVL_LevelAssign_BATCH.Ladder('Account')
            .addLevel(accountLevel);

        Test.startTest();
        String contactSoqlQuery = contactLadder.buildQuery();
        String accountSoqlQuery = accountLadder.buildQuery();
        Test.stopTest();

        String formattedDatetime = contactDatetime.formatGMT(LVL_LevelAssign_BATCH.DATETIME_SOQL_FORMAT);
        System.assert(contactSoqlQuery.endsWith('WHERE SystemModStamp >= ' + formattedDatetime),
            'The query should a filter on SystemModStamp with the correct datetime');

        formattedDatetime = accountDatetime.formatGMT(LVL_LevelAssign_BATCH.DATETIME_SOQL_FORMAT);
        System.assert(accountSoqlQuery.endsWith('WHERE SystemModStamp >= ' + formattedDatetime),
            'The query should a filter on SystemModStamp with the correct datetime');

        QueryException unexpectedException;
        try {
            List<Contact> queriedContacts = Database.query(contactSoqlQuery);
            List<Account> queriedAccounts = Database.query(accountSoqlQuery);
        } catch(QueryException ex) {
            unexpectedException = ex;
        }

        System.assertEquals(null, unexpectedException, 'The SOQL queries should be valid');
    }

    /*********************************************************************************************************
    * @description Confirms that filter is not used when a source field is a formula field
    */
    @isTest
    private static void shouldExcludeFilterWhenSourceIsFormula() {
        Level__c formulaLevel = new Level__c(
            Target__c = 'Contact',
            Source_Field__c = 'npo02__LastCloseDateHH__c',
            Level_Field__c = 'npo02__LastMembershipLevel__c',
            Previous_Level_Field__c = 'npo02__LastMembershipOrigin__c'
        );

        Level__c nonFormulaLevel = new Level__c(
            Target__c = 'Contact',
            Source_Field__c = 'npo02__TotalOppAmount__c',
            Level_Field__c = 'npo02__LastMembershipLevel__c',
            Previous_Level_Field__c = 'npo02__LastMembershipOrigin__c'
        );

        LVL_LevelAssign_BATCH.Ladder ladder = new LVL_LevelAssign_BATCH.Ladder('Contact')
            .addLevel(formulaLevel)
            .addLevel(nonFormulaLevel);

        Test.startTest();
        String soqlQuery = ladder.buildQuery();
        Test.stopTest();

        System.assert(!soqlQuery.contains('WHERE SystemModStamp >= '),
            'The query should not include a SystemModStamp filter when the source field is a formula');
    }

    /*********************************************************************************************************
    * @description Confirms that filter is not used when any Level record is updated after the last run
    */
    @isTest
    private static void shouldExcludeFilterWhenAnyLevelIsUpdatedAfterLastRun() {
        LVL_LevelAssign_BATCH.levelsSettings = new Levels_Settings__c(
            LastJobStartTimeContact__c = Datetime.now().addDays(-10)
        );

        Level__c oldLevel = new Level__c(
            Name = 'Paper',
            Target__c = 'Contact',
            Source_Field__c = 'npo02__TotalOppAmount__c',
            Level_Field__c = 'npo02__LastMembershipLevel__c',
            Previous_Level_Field__c = 'npo02__LastMembershipOrigin__c',
            Minimum_Amount__c = null,
            Maximum_Amount__c = 1000
        );

        Level__c updatedLevel = new Level__c(
            Name = 'Rock',
            Target__c = 'Contact',
            Source_Field__c = 'npo02__TotalOppAmount__c',
            Level_Field__c = 'npo02__LastMembershipLevel__c',
            Previous_Level_Field__c = 'npo02__LastMembershipOrigin__c',
            Minimum_Amount__c = 1000,
            Maximum_Amount__c = 5000
        );

        insert new List<Level__c>{ oldLevel, updatedLevel };
        Test.setCreatedDate(oldLevel.Id, Datetime.now().addDays(-20));

        List<Level__c> requeriedLevels = [
            SELECT Target__c, Source_Field__c, Level_Field__c, Previous_Level_Field__c, LastModifiedDate
            FROM Level__c
        ];

        LVL_LevelAssign_BATCH.Ladder ladder = new LVL_LevelAssign_BATCH.Ladder('Contact');

        for (Level__c level : requeriedLevels) {
            ladder.addLevel(level);
        }

        Test.startTest();
        String soqlQuery = ladder.buildQuery();
        Test.stopTest();

        System.assert(!soqlQuery.contains('WHERE SystemModStamp >= '),
            'The query should not include a SystemModStamp filter when a level record is updated after last run date');
    }

    // Helpers
    ////////////

    /*********************************************************************************************************
    * @description Executes Level Assign Batch for Contact Sobject
    * @return void
    **********************************************************************************************************/
    private static void executeLevelAssignBatchForContact() {
        String soql = 'SELECT Id, Name, npo02__TotalOppAmount__c, npo02__LastMembershipLevel__c, npo02__LastMembershipOrigin__c, CreatedDate, LastModifiedDate FROM Contact';

        executeLevelAssignBatch(soql, 'Contact');
    }

    /*********************************************************************************************************
    * @description Executes Level Assign Batch
    * @param soql String representing query to be executed in the batch
    * @param sobjectType String representing the Sobject API Name
    * @return void
    **********************************************************************************************************/
    private static void executeLevelAssignBatch(String soql, String sobjectType) {
        LVL_LevelAssign_BATCH batch = new LVL_LevelAssign_BATCH(soql, sobjectType);

        Test.startTest();
        Database.executeBatch(batch);
        Test.stopTest();
    }

    /*********************************************************************************************************
    * @description Retrieves all Contacts from database
    * @return Contact[] List of all Contacts
    **********************************************************************************************************/
    private static Contact[] getContacts() {
        return [
            SELECT Id, Name, npo02__TotalOppAmount__c, npo02__LastMembershipLevel__c, npo02__LastMembershipOrigin__c
            FROM Contact
        ];
    }

}