@isTest
public with sharing class CONV_Account_Conversion_CTRL_TEST {
    public static testmethod void testConversionCtrl() {

        //set account model to 1:1 for the test and enable household creation
        CONV_Account_Conversion_BATCH_TEST.setPreHHAccountModel(true);

        Contact c = new Contact(LastName = 'Contact', FirstName = 'Test');
        insert c;
        system.assertEquals(1, [select count() from Account where Name = 'Test Contact' and npe01__One2OneContact__c = :c.id]);
        String HHName = 'Contact ' + system.label.npo02.DefaultHouseholdName;
        system.assertEquals(1, [select count() from npo02__Household__c where Name = :HHName]);

        //add an oppty to the Contact as well
        Opportunity o = new Opportunity(Name = 'Test Oppty', Amount = 1000, StageName = UTIL_UnitTestData_TEST.getClosedWonStage(), CloseDate = system.today(), npe01__Contact_Id_For_Role__c = c.Id);
        insert o;
        system.assertEquals(1, [select count() from OpportunityContactRole where isPrimary = true and ContactId = :c.Id]);

        Test.startTest();

        // create the page 
        PageReference pageRef=Page.CONV_Account_Conversion; 
        Test.setCurrentPage(pageRef); 

        // instantiate the controller
        CONV_Account_Conversion_CTRL controller = new CONV_Account_Conversion_CTRL();
        AsyncApexJob aaj = controller.apexjob;
        system.assertEquals(null, aaj);
        List<SelectOption> testList = controller.getTargetAccountFields();

        // convert up everyone
        controller.convert();
        controller.cancel();

        Test.stopTest();

        aaj = controller.apexjob;
        system.assertNotEquals(null, aaj.Id);
        system.assertEquals('Completed', aaj.Status);
        Boolean testBool;
        testBool = CONV_Account_Conversion_CTRL.verifyFieldTypeForIds('garbagefield');
        system.assertEquals(false, testBool);

        testBool = CONV_Account_Conversion_CTRL.verifyFieldTypeForIds('Name');
        system.assert(testBool);
    }

    public static testMethod void testConversionCTRLErrorState(){

        //set account model to 1:1 for the test and enable household creation
        CONV_Account_Conversion_BATCH_TEST.setPreHHAccountModel(true);
        //create a new user w/ sysadmin profile
        Id sysadminId = [select id from Profile where Name = 'System Administrator' limit 1].Id;
        User u = new User(LastName = 'TestUser', Email = 'UserEmail@email.com', ProfileId = sysadminId, 
                            isActive = true, UserName = 'UserEmail@email.com',
                            Alias = 'tu093521', TimeZoneSidKey = 'America/Los_Angeles', 
                            LocaleSidKey = 'en_US', LanguageLocaleKey = 'en_US',
                            EmailEncodingKey = 'ISO-8859-1');
        insert u;

        Contact c = new Contact(LastName = 'Contact', FirstName = 'Test', OwnerId = u.Id);
        insert c;

        Account a = new Account(OwnerId = u.Id, Name= 'Test Account');
        insert a;

        Task t = new Task(WhatId = a.Id, OwnerId = u.Id, Status = 'Completed', Subject = 'Other');
        insert t;

        system.assertEquals(u.Id, [select OwnerId from Account where Id = :a.Id].OwnerId);
        system.assertEquals(u.Id, [select OwnerId from Contact where Id = :c.Id].OwnerId);
        system.assertEquals(u.Id, [select OwnerId from Task where Id = :t.Id].OwnerId);

        //add an oppty to the Contact as well
        Opportunity o = new Opportunity(OwnerId = u.Id, Name = 'Test Oppty', Amount = 1000, StageName = UTIL_UnitTestData_TEST.getClosedWonStage(), CloseDate = system.today(), npe01__Contact_Id_For_Role__c = c.Id);
        insert o;
        system.assertEquals(1, [select count() from OpportunityContactRole where isPrimary = true and ContactId = :c.Id]);

        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

       // Insert account as current user context
        System.runAs (thisUser) {

            Test.startTest();
            //inactive the user
            u.isActive = false;
            update u;

            // create the page 
            PageReference pageRef=Page.CONV_Account_Conversion; 
            Test.setCurrentPage(pageRef); 

            // instantiate the controller
            CONV_Account_Conversion_CTRL controller = new CONV_Account_Conversion_CTRL();
            controller.runCheck();

            Test.stopTest();

            //assert the warning exists
            system.assertEquals(true, controller.runCheckErrorState);
        }
    }
}