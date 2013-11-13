@isTest
public with sharing class TDTM_CustomSettingPerf_TEST {

    public static testmethod void beforeInsert() {
        //Define which classes (and in which order) should run when a change is made to
        //a record our test trigger is pointing to
        List<Trigger_Handler_Setting__c> handlers = new List<Trigger_Handler_Setting__c>();
        
        //This one is synchronous
        handlers.add(new Trigger_Handler_Setting__c(Name = 'Test1', Active__c = true, Asynchronous__c = false, 
              Class__c = 'TDTM_Runnable_Impl', Load_Order__c = 1, Object__c = 'Campaign', 
              Trigger_Action__c = 'BeforeInsert')); 
        
        //This one is asynchronous
        handlers.add(new Trigger_Handler_Setting__c(Name = 'Test2', Active__c = true, Asynchronous__c = true, 
              Class__c = 'TDTM_Runnable_Impl', Load_Order__c = 1, Object__c = 'Campaign', 
              Trigger_Action__c = 'BeforeInsert')); 

        insert handlers;
        
        //Make a change that makes our test trigger run
        Test.startTest();
        insert new Campaign(Name='CustomSettingTest');
        Test.stopTest();
        
        //Verify that the class run - that is, that the database change that the class makes was 
        //performed. There should be two record inserted, one for the sync call and one for the
        //async call
        List<Contact> contacts = [select FirstName, LastName from Contact];
        System.assertEquals(2, contacts.size());
    }
    
    public static testmethod void beforeInsertEdgeCases() {
        //Define which classes (and in which order) should run when a change is made to
        //a record our test trigger is pointing to
        List<Trigger_Handler_Setting__c> handlers = new List<Trigger_Handler_Setting__c>();
              
        //This one points to a class that doesn't exist
        handlers.add(new Trigger_Handler_Setting__c(Name = 'Test3', Active__c = true, Asynchronous__c = false, 
              Class__c = 'TDTM_FakeRunnable_Impl', Load_Order__c = 1, Object__c = 'Campaign', 
              Trigger_Action__c = 'BeforeInsert')); 
        
        //This one points to a class that exists but does not implement the right interface
        handlers.add(new Trigger_Handler_Setting__c(Name = 'Test4', Active__c = true, Asynchronous__c = false, 
              Class__c = 'TDTM_ObjectDataGateway', Load_Order__c = 1, Object__c = 'Campaign', 
              Trigger_Action__c = 'BeforeInsert')); 
              
        //This one points to an object that doesn't exist
        handlers.add(new Trigger_Handler_Setting__c(Name = 'Test5', Active__c = true, Asynchronous__c = false, 
              Class__c = 'TDTM_Runnable_Impl', Load_Order__c = 1, Object__c = 'FakeCampaign', 
              Trigger_Action__c = 'BeforeInsert')); 
        
        insert handlers;
        
        //Make a change that makes our test trigger run
        Test.startTest();
        insert new Campaign(Name='CustomSettingTest');
        Test.stopTest();
        
        //Verify that the class run - that is, that the database change that the class makes was 
        //performed. There should be two record inserted, one for the sync call and one for the
        //async call
        List<Contact> contacts = [select FirstName, LastName from Contact];
        System.assertEquals(0, contacts.size());
    }
}