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
* @description test the batchable class for Level Assignments
*/

@isTest
private class LVL_LevelAssignBATCH_TEST {

    private static Level__c lvlBronze { get; set; }
    private static Level__c lvlSilver { get; set; }
    private static Level__c lvlGold { get; set; }
    private static Level__c lvlAcctZinc { get; set; }

    /*********************************************************************************************************
    * @description creates Bronze, Silver, and Gold Level records for test code to use.
    */
    static void createTestLevels() {
        // create Levels
        lvlBronze = new Level__c(
            Name = 'Bronze',
            Target__c = 'Contact',
            Source_Field__c = 'npo02__TotalOppAmount__c', 
            Level_Field__c = 'npo02__LastMembershipLevel__c', 
            Previous_Level_Field__c = 'npo02__LastMembershipOrigin__c', 
            Active__c = true, 
            Minimum_Amount__c = 100, 
            Maximum_Amount__c = 999);

        lvlSilver = new Level__c(
            Name = 'Silver',
            Target__c = 'Contact',
            Source_Field__c = 'npo02__TotalOppAmount__c', 
            Level_Field__c = 'npo02__LastMembershipLevel__c', 
            Previous_Level_Field__c = 'npo02__LastMembershipOrigin__c', 
            Active__c = true, 
            Minimum_Amount__c = 1000, 
            Maximum_Amount__c = 4999);

        lvlGold = new Level__c(
            Name = 'Gold',
            Target__c = 'Contact',
            Source_Field__c = 'npo02__TotalOppAmount__c', 
            Level_Field__c = 'npo02__LastMembershipLevel__c', 
            Previous_Level_Field__c = 'npo02__LastMembershipOrigin__c', 
            Active__c = true, 
            Minimum_Amount__c = 5000, 
            Maximum_Amount__c = 1000000);
        
        lvlAcctZinc = new Level__c(
            Name = 'Zinc',
            Target__c = 'Account',
            Source_Field__c = 'npo02__TotalOppAmount__c', 
            Level_Field__c = 'npo02__LastMembershipLevel__c', 
            Previous_Level_Field__c = 'npo02__LastMembershipOrigin__c', 
            Active__c = true, 
            Minimum_Amount__c = 100, 
            Maximum_Amount__c = 200);

        insert new Level__c[]{lvlBronze, lvlSilver, lvlGold, lvlAcctZinc};        
    }


    /*********************************************************************************************************
    * @description creates a list of Contacts with various donation totals for test code to use.
    */
    private static list<Contact> listCon { get; set; }
    static void createTestContacts() {
        // create & insert contact
        listCon = UTIL_UnitTestData_TEST.CreateMultipleTestContacts(7);
        listCon[0].npo02__TotalOppAmount__c = null;
        listCon[1].npo02__TotalOppAmount__c = 10;
        listCon[2].npo02__TotalOppAmount__c = 100;
        
        listCon[3].npo02__TotalOppAmount__c = 999;
        listCon[3].npo02__LastMembershipLevel__c = lvlGold.Id;

        listCon[4].npo02__TotalOppAmount__c = 1000;
        listCon[4].npo02__LastMembershipLevel__c = lvlBronze.Id;
        
        listCon[5].npo02__TotalOppAmount__c = 5000;

        listCon[6].npo02__TotalOppAmount__c = 500;
        listCon[6].npo02__LastMembershipLevel__c = lvlBronze.Id;
        listCon[6].npo02__LastMembershipOrigin__c = lvlBronze.Id;
        insert listCon;
    }
        
    /*********************************************************************************************************
    * @description creates a list of Accounts with various donation totals for test code to use.
    */
    private static list<Account> listAcc { get; set; }
    static void createTestAccounts() {
        // create & insert contact
        listAcc = UTIL_UnitTestData_TEST.CreateMultipleTestAccounts(2, null);
        listAcc[0].npo02__TotalOppAmount__c = 10;
        listAcc[1].npo02__TotalOppAmount__c = 150;
        insert listAcc;
    }

    /*********************************************************************************************************
    * @description test our batch process for assigning Levels to Contacts
    */
    static testMethod void testContactLevels() {
        // create Levels
        createTestLevels();
        
        // create test Contacts
        createTestContacts();
        
        string strSoql = 'SELECT Id, Name, npo02__TotalOppAmount__c, npo02__LastMembershipLevel__c, npo02__LastMembershipOrigin__c, CreatedDate, LastModifiedDate FROM Contact';
        LVL_LevelAssign_BATCH batch = new LVL_LevelAssign_BATCH(strSoql, 'Contact');
        
        Test.startTest();
        Database.executeBatch(batch);
        Test.stopTest();
        
        listCon = database.query(strSoql + ' order by FirstName');
        System.assertEquals(null, listCon[0].npo02__LastMembershipLevel__c);
        System.assertEquals(null, listCon[0].npo02__LastMembershipOrigin__c);
        
        System.assertEquals(null, listCon[1].npo02__LastMembershipLevel__c);
        System.assertEquals(null, listCon[1].npo02__LastMembershipOrigin__c);
        
        System.assertEquals(lvlBronze.Id, listCon[2].npo02__LastMembershipLevel__c);
        System.assertEquals(null, listCon[2].npo02__LastMembershipOrigin__c);
        
        System.assertEquals(lvlBronze.Id, listCon[3].npo02__LastMembershipLevel__c);
        System.assertEquals(lvlGold.Id, listCon[3].npo02__LastMembershipOrigin__c);
        
        System.assertEquals(lvlSilver.Id, listCon[4].npo02__LastMembershipLevel__c);
        System.assertEquals(lvlBronze.Id, listCon[4].npo02__LastMembershipOrigin__c);
        
        System.assertEquals(lvlGold.Id, listCon[5].npo02__LastMembershipLevel__c);
        System.assertEquals(null, listCon[5].npo02__LastMembershipOrigin__c);
        
        System.assertEquals(lvlBronze.Id, listCon[6].npo02__LastMembershipLevel__c);
        System.assertEquals(lvlBronze.Id, listCon[6].npo02__LastMembershipOrigin__c);
        System.assertEquals(listCon[6].CreatedDate, listCon[6].LastModifiedDate);
        
    }
    
    /*********************************************************************************************************
    * @description test our batch process for assigning Levels to Accounts
    */
    static testMethod void testAccountLevels() {
        // create Levels
        createTestLevels();
        
        // create test Accounts
        createTestAccounts();
        
        string strSoql = 'SELECT Id, Name, npo02__TotalOppAmount__c, npo02__LastMembershipLevel__c, ' +
            'npo02__LastMembershipOrigin__c, CreatedDate, LastModifiedDate FROM Account where npe01__SYSTEMIsIndividual__c = false ';
        LVL_LevelAssign_BATCH batch = new LVL_LevelAssign_BATCH(strSoql, 'Account');
        
        Test.startTest();
        Database.executeBatch(batch);
        Test.stopTest();
        
        listAcc = database.query(strSoql + ' order by Name');
        System.assertEquals(null, listAcc[0].npo02__LastMembershipLevel__c);
        System.assertEquals(null, listAcc[0].npo02__LastMembershipOrigin__c);
        
        System.assertEquals(lvlAcctZinc.Id, listAcc[1].npo02__LastMembershipLevel__c);
        System.assertEquals(null, listAcc[1].npo02__LastMembershipOrigin__c);
    }

    /*********************************************************************************************************
    * @description tests our Level Assigning when invokved through our Schedulable class.
    */
    static testMethod void testLevelAssignScheduling() {
        // create Levels
        createtestLevels();

        // create test Contacts
        createTestContacts();

        LVL_LevelAssign_SCHED sched = new LVL_LevelAssign_SCHED();
        Test.startTest();
        sched.executeReturnStatus();
        Test.stopTest();
        
        string strSoql = 'SELECT Id, Name, npo02__TotalOppAmount__c, npo02__LastMembershipLevel__c, npo02__LastMembershipOrigin__c, CreatedDate, LastModifiedDate FROM Contact';
        listCon = database.query(strSoql + ' order by FirstName');
        system.assertEquals(7, listCon.size());
        System.assertEquals(null, listCon[0].npo02__LastMembershipLevel__c);
        System.assertEquals(null, listCon[0].npo02__LastMembershipOrigin__c);
        
        System.assertEquals(null, listCon[1].npo02__LastMembershipLevel__c);
        System.assertEquals(null, listCon[1].npo02__LastMembershipOrigin__c);
        
        System.assertEquals(lvlBronze.Id, listCon[2].npo02__LastMembershipLevel__c);
        System.assertEquals(null, listCon[2].npo02__LastMembershipOrigin__c);
        
        System.assertEquals(lvlBronze.Id, listCon[3].npo02__LastMembershipLevel__c);
        System.assertEquals(lvlGold.Id, listCon[3].npo02__LastMembershipOrigin__c);
        
        System.assertEquals(lvlSilver.Id, listCon[4].npo02__LastMembershipLevel__c);
        System.assertEquals(lvlBronze.Id, listCon[4].npo02__LastMembershipOrigin__c);
        
        System.assertEquals(lvlGold.Id, listCon[5].npo02__LastMembershipLevel__c);
        System.assertEquals(null, listCon[5].npo02__LastMembershipOrigin__c);
        
        System.assertEquals(lvlBronze.Id, listCon[6].npo02__LastMembershipLevel__c);
        System.assertEquals(lvlBronze.Id, listCon[6].npo02__LastMembershipOrigin__c);
        System.assertEquals(listCon[6].CreatedDate, listCon[6].LastModifiedDate);
    }
    
    /*********************************************************************************************************
    * @description tests our Level Validation to detect overlaps with existing levels
    */
    static testMethod void testLevelValidationExistingMin() {
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
            
        try {
            Test.startTest();
            insert lvl;
            Test.stopTest();
            system.assert(false, 'exception should have occurred');
        } catch(Exception ex) {
            system.assert(ex.getMessage().contains(lvl.Name));
        }
    }

    /*********************************************************************************************************
    * @description tests our Level Validation to detect overlaps with existing levels
    */
    static testMethod void testLevelValidationExistingMax() {
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
            
        try {
            Test.startTest();
            insert lvl;
            Test.stopTest();
            system.assert(false, 'exception should have occurred');
        } catch(Exception ex) {
            system.assert(ex.getMessage().contains(lvl.Name));
        }
    }

    /*********************************************************************************************************
    * @description tests our Level Validation to detect overlaps with new levels
    */
    static testMethod void testLevelValidationNewMin() {
        
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
            system.assert(false, 'exception should have occurred');
        } catch(Exception ex) {
            system.assert(ex.getMessage().contains(lvl3.Name));
        }
    }

    /*********************************************************************************************************
    * @description tests our Level Validation to detect overlaps with new levels
    */
    static testMethod void testLevelValidationNewMax() {
        
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
            system.assert(false, 'exception should have occurred');
        } catch(Exception ex) {
            system.assert(ex.getMessage().contains(lvl3.Name));
        }
    }
}