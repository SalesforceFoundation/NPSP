@isTest
public with sharing class TDTM_CustomSettingPerf_Batch_TEST {

    public static testmethod void manyClassesOneRecordChange() {
        //Define which classes (and in which order) should run when a change is made to
        //a record our test trigger is pointing to
        List<Trigger_Handler_Setting__c> handlers = new List<Trigger_Handler_Setting__c>();
        
        //Create some synchronous classes
        for(Integer i=0; i<10; i++) {
            handlers.add(new Trigger_Handler_Setting__c(Name = 'TestSync' + i, Active__c = true, 
                Asynchronous__c = false, Class__c = 'TDTM_Runnable_Impl', Load_Order__c = i, 
                Object__c = 'Campaign', Trigger_Actions__c = 'BeforeInsert'));
        } 
        
        //Create some asynchronous classes
        for(Integer i=0; i<10; i++) {
        handlers.add(new Trigger_Handler_Setting__c(Name = 'TestAsync' + i, Active__c = true, 
                Asynchronous__c = false, Class__c = 'TDTM_Runnable_Impl', Load_Order__c = i, 
                Object__c = 'Campaign', Trigger_Actions__c = 'BeforeInsert')); 
        }
        
        insert handlers;
        
        //Make a change that makes our test trigger run
        Test.startTest();
        insert new Campaign(Name='CustomSettingTest');
        Test.stopTest();
        
        //Verify that the class run - that is, that the database change that the class makes was 
        //performed. There should be two record inserted, one for the sync call and one for the
        //async call
        List<Contact> contacts = [select FirstName, LastName from Contact];
        System.assertEquals(20, contacts.size());
    }
    
    public static testmethod void manyRecordChangesOneClass() {
        //Define which classes (and in which order) should run when a change is made to
        //a record our test trigger is pointing to
        List<Trigger_Handler_Setting__c> handlers = new List<Trigger_Handler_Setting__c>();
        
        //This one is synchronous
        handlers.add(new Trigger_Handler_Setting__c(Name = 'Test1', Active__c = true, 
                Asynchronous__c = false, Class__c = 'TDTM_Runnable_Impl', Load_Order__c = 1, 
                Object__c = 'Campaign', Trigger_Actions__c = 'BeforeInsert')); 
        
        insert handlers;
        
        List<Campaign> campaigns = new List<Campaign>();
        for(Integer i=0; i<200; i++) {
            campaigns.add(new Campaign(Name='CustomSettingTest' + i));
        }
        
        //Make a change that makes our test trigger run
        Test.startTest();
        insert campaigns;
        Test.stopTest();
        
        //Verify that the class run - that is, that the database change that the class makes was 
        //performed. There should be two record inserted, one for the sync call and one for the
        //async call
        List<Contact> contacts = [select FirstName, LastName from Contact];
        System.assertEquals(200, contacts.size());
    }
}