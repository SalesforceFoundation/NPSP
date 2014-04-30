@isTest
public with sharing class STG_InstallScript_TEST2 {

    //If the handlers in our default TDTM config are different from what it's in the org (either action or load order),
    //and the user did not flag them as user managed, we need to update them
    public static testmethod void handlersChanged() {
    	//Handlers that exist in the org
        List<Trigger_Handler__c> oldHandlers = new List<Trigger_Handler__c>();
        oldHandlers.add(new Trigger_Handler__c(Active__c = true, Asynchronous__c = false, 
              Class__c = 'AFFL_Affiliations_TDTM', Load_Order__c = 1, Object__c = 'Contact', 
              Trigger_Action__c = 'AfterInsert'));
        oldHandlers.add(new Trigger_Handler__c(Active__c = false, Asynchronous__c = false, 
              Class__c = 'REL_Relationships_Cm_TDTM', Load_Order__c = 1, Object__c = 'CampaignMember', 
              Trigger_Action__c = 'AfterInsert;AfterUpdate'));
        oldHandlers.add(new Trigger_Handler__c(Active__c = true, Asynchronous__c = false, 
              Class__c = 'REL_Relationships_Con_TDTM', Load_Order__c = 1, Object__c = 'Contact', 
              Trigger_Action__c = 'AfterInsert;AfterDelete'));
    	insert oldHandlers;
    	
    	//Updated handlers
    	List<Trigger_Handler__c> updatedHandlers = new List<Trigger_Handler__c>();
        updatedHandlers.add(new Trigger_Handler__c(Active__c = true, Asynchronous__c = false, 
              Class__c = 'AFFL_Affiliations_TDTM', Load_Order__c = 1, Object__c = 'Contact', 
              Trigger_Action__c = 'AfterInsert;AfterUpdate'));
        updatedHandlers.add(new Trigger_Handler__c(Active__c = true, Asynchronous__c = false, 
              Class__c = 'REL_Relationships_Cm_TDTM', Load_Order__c = 0, Object__c = 'CampaignMember', 
              Trigger_Action__c = 'AfterInsert;AfterUpdate'));
        updatedHandlers.add(new Trigger_Handler__c(Active__c = true, Asynchronous__c = false, 
              Class__c = 'REL_Relationships_Con_TDTM', Load_Order__c = 2, Object__c = 'Contact', 
              Trigger_Action__c = 'AfterInsert;AfterUpdate;AfterDelete'));
    	
    	Test.startTest();
    	STG_InstallScript.insertTdtmDefaults(updatedHandlers);
    	Test.stopTest();
    	
    	//Verify handlers have been updated
    	List<Trigger_Handler__c> newHandlers = [select Load_Order__c, Class__c, Trigger_Action__c from Trigger_Handler__c order by Load_Order__c];
        System.assertEquals(0, newHandlers[0].Load_Order__c);   
        System.assertEquals('REL_Relationships_Cm_TDTM', newHandlers[0].Class__c);   
        System.assertEquals('AfterInsert;AfterUpdate', newHandlers[0].Trigger_Action__c);
        System.assertEquals(1, newHandlers[1].Load_Order__c);   
        System.assertEquals('AFFL_Affiliations_TDTM', newHandlers[1].Class__c);   
        System.assertEquals('AfterInsert;AfterUpdate', newHandlers[1].Trigger_Action__c);  
        System.assertEquals(2, newHandlers[2].Load_Order__c);   
        System.assertEquals('REL_Relationships_Con_TDTM', newHandlers[2].Class__c);   
        System.assertEquals('AfterInsert;AfterUpdate;AfterDelete', newHandlers[2].Trigger_Action__c);    
    }
    
    //If the handlers in our default TDTM config are different from what it's in the org (either action or load order),
    //and the user flagged them as user managed, we do not need to update them
    public static testmethod void handlersChanged_UserManaged() {
        //Handlers that exist in the org
        List<Trigger_Handler__c> oldHandlers = new List<Trigger_Handler__c>();
        //Should not be modified 
        oldHandlers.add(new Trigger_Handler__c(Active__c = true, Asynchronous__c = false, 
              Class__c = 'AFFL_Affiliations_TDTM', Load_Order__c = 1, Object__c = 'Contact', 
              Trigger_Action__c = 'AfterInsert', User_Managed__c = true));
        //Should be modified
        oldHandlers.add(new Trigger_Handler__c(Active__c = false, Asynchronous__c = false, 
              Class__c = 'REL_Relationships_Cm_TDTM', Load_Order__c = 1, Object__c = 'CampaignMember', 
              Trigger_Action__c = 'AfterInsert;AfterUpdate'));
        //Should not be modified
        oldHandlers.add(new Trigger_Handler__c(Active__c = true, Asynchronous__c = false, 
              Class__c = 'REL_Relationships_Con_TDTM', Load_Order__c = 2, Object__c = 'Contact', 
              Trigger_Action__c = 'AfterInsert;AfterDelete', User_Managed__c = true));
        insert oldHandlers;
        
        //Updated handlers
        List<Trigger_Handler__c> updatedHandlers = new List<Trigger_Handler__c>();
        updatedHandlers.add(new Trigger_Handler__c(Active__c = true, Asynchronous__c = false, 
              Class__c = 'AFFL_Affiliations_TDTM', Load_Order__c = 1, Object__c = 'Contact', 
              Trigger_Action__c = 'AfterInsert;AfterUpdate'));
        updatedHandlers.add(new Trigger_Handler__c(Active__c = true, Asynchronous__c = false, 
              Class__c = 'REL_Relationships_Cm_TDTM', Load_Order__c = 0, Object__c = 'CampaignMember', 
              Trigger_Action__c = 'AfterInsert;AfterUpdate'));
        updatedHandlers.add(new Trigger_Handler__c(Active__c = true, Asynchronous__c = false, 
              Class__c = 'REL_Relationships_Con_TDTM', Load_Order__c = 1, Object__c = 'Contact', 
              Trigger_Action__c = 'AfterInsert;AfterUpdate;AfterDelete'));
        
        Test.startTest();
        STG_InstallScript.insertTdtmDefaults(updatedHandlers);
        Test.stopTest();
        
        //Verify handlers marked as "User Managed" were not modified
        List<Trigger_Handler__c> newHandlers = [select Load_Order__c, Class__c, Trigger_Action__c from Trigger_Handler__c order by Load_Order__c];
        //Should have been modified
        System.assertEquals('REL_Relationships_Cm_TDTM', newHandlers[0].Class__c);   
        System.assertEquals(0, newHandlers[0].Load_Order__c); 
        System.assertEquals('AfterInsert;AfterUpdate', newHandlers[0].Trigger_Action__c);
        //Should not have been modified  
        System.assertEquals('AFFL_Affiliations_TDTM', newHandlers[1].Class__c);   
        System.assertEquals(1, newHandlers[1].Load_Order__c);
        System.assertEquals('AfterInsert', newHandlers[1].Trigger_Action__c);  
        //Should not have been modified
        System.assertEquals('REL_Relationships_Con_TDTM', newHandlers[2].Class__c); 
        System.assertEquals(2, newHandlers[2].Load_Order__c);     
        System.assertEquals('AfterInsert;AfterDelete', newHandlers[2].Trigger_Action__c);     
    }
}