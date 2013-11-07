@isTest
public with sharing class TDTM_ObjectPerf_TEST {

     public static testmethod void beforeInsert() {
        //Define which classes (and in which order) should run when a change is made to
        //a record our test trigger is pointing to
        List<SubsystemModule__c> ssms = new List<SubsystemModule__c>();
        
        //This one is synchronous
        ssms.add(new SubsystemModule__c(Active__c = true, Asynchronous__c = false, 
              Class__c = 'TDTM_Runnable_Impl', Load_Order__c = 1, Object__c = 'Campaign', 
              Trigger_Actions__c = 'BeforeInsert')); 
        
        //This one is asynchronous
        ssms.add(new SubsystemModule__c(Active__c = true, Asynchronous__c = true, 
              Class__c = 'TDTM_Runnable_Impl', Load_Order__c = 1, Object__c = 'Campaign', 
              Trigger_Actions__c = 'BeforeInsert')); 
        
        insert ssms;
        
        //Make a change that makes our test trigger run
        Test.startTest();
        insert new Campaign(Name='ObjectTest');
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
        List<SubsystemModule__c> ssms = new List<SubsystemModule__c>();

        //This one points to a class that doesn't exist
        ssms.add(new SubsystemModule__c(Active__c = true, Asynchronous__c = false, 
              Class__c = 'TDTM_FakeRunnable_Impl', Load_Order__c = 1, Object__c = 'Campaign', 
              Trigger_Actions__c = 'BeforeInsert')); 
              
        //This one points to an object that doesn't exist
        ssms.add(new SubsystemModule__c(Active__c = true, Asynchronous__c = false, 
              Class__c = 'TDTM_Runnable_Impl', Load_Order__c = 1, Object__c = 'FakeCampaign', 
              Trigger_Actions__c = 'BeforeInsert')); 
        
        insert ssms;
        
        //Make a change that makes our test trigger run
        Test.startTest();
        insert new Campaign(Name='ObjectTest');
        Test.stopTest();
        
        //Verify that the class run - that is, that the database change that the class makes was 
        //performed. There should be two record inserted, one for the sync call and one for the
        //async call
        List<Contact> contacts = [select FirstName, LastName from Contact];
        System.assertEquals(0, contacts.size());
    }
}