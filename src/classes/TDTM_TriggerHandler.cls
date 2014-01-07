/*
    Copyright (c) 2013, Salesforce.com Foundation
    All rights reserved.
    
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
    
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Salesforce.com Foundation nor the names of
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
public with sharing class TDTM_TriggerHandler {

    private List<Sobject> newList;
    private List<Sobject> oldList; 
    private TDTM_TriggerActionHelper.Action thisAction;
    private Schema.DescribeSobjectResult obj;

    private static Boolean defaultRecordsInserted = false;
    
    public void initialize(Boolean isBefore, Boolean isAfter, Boolean isInsert, Boolean isUpdate,
    Boolean isDelete, Boolean isUnDelete, List<Sobject> newList, List<Sobject> oldList, 
    Schema.DescribeSobjectResult describeobj) {
        
        this.newList = newList;
        this.oldList = oldList;

        thisAction = TDTM_TriggerActionHelper.determineTriggerAction(isBefore, isAfter, isInsert, isUpdate,
                                                                        isDelete, isUnDelete);
        System.debug(LoggingLevel.WARN, '****ACTION: ' + thisAction + ' on ' + describeobj.getLabel());
        obj = describeobj;
    }
    
    public void runClasses(TDTM_iTableDataGateway dao) {
        TDTM_Runnable.DmlWrapper dmlWrapper = new TDTM_Runnable.DmlWrapper();
        
        //If there are no records insert the defaults.
        if(!defaultRecordsInserted && dao.isEmpty()) {
        	insertDefaultRecords();
        }
        
        //Get the classes to run
        List<SObject> classesToCall = dao.getclassesToCallForObject(obj.getName(), thisAction);
        System.debug(LoggingLevel.WARN, '****Classes To Call for ' + obj.getName() + ': ' + classesToCall);
        
        if(classesToCall != null && classesToCall.size() > 0) {
            //Run the relevant classes
            for (SObject classToCall : classesToCall) {
                TDTM_Runnable.DmlWrapper dmlWrapperLocal = new TDTM_Runnable.DmlWrapper();
                try {
                	dmlWrapperLocal = runClass(classToCall);
                } catch(Exception e) {
                	System.debug(LoggingLevel.WARN, '****Exception caught in TDTM_TriggerHandler.runClasses: ' + e);
                	dmlWrapper.objectsToInsert.add(ERR_Handler.createError(e));
                }
                if(dmlWrapperLocal != null) {
                	if(dmlWrapperLocal.objectsToInsert != null && !dmlWrapperLocal.objectsToInsert.isEmpty())
                        dmlWrapper.objectsToInsert.addAll(dmlWrapperLocal.objectsToInsert);
                    if(dmlWrapperLocal.objectsToUpdate != null && !dmlWrapperLocal.objectsToUpdate.isEmpty())
                        dmlWrapper.objectsToUpdate.putAll(dmlWrapperLocal.objectsToUpdate);
                    if(dmlWrapperLocal.objectsToDelete != null && !dmlWrapperLocal.objectsToDelete.isEmpty())
                        dmlWrapper.objectsToDelete.addAll(dmlWrapperLocal.objectsToDelete);
                    if(dmlWrapperLocal.objectsToUndelete != null && !dmlWrapperLocal.objectsToUndelete.isEmpty())
                        dmlWrapper.objectsToUndelete.addAll(dmlWrapperLocal.objectsToUndelete);
                }          
            }
                         
            //Process the result
            processDML(dmlWrapper);
        }
    }
    
    private TDTM_Runnable.DmlWrapper runClass(SObject classToRunRecord) {
    	        
        if(classToRunRecord != null) {
	        String classToRunName = String.valueOf(classToRunRecord.get('Class__c'));
	        Type classType = Type.forName(classToRunName);
	        
	        if(classType != null) {   	
	        	Object classInstance = classType.newInstance();
	        	
	        	//The objects we create dynamically need to implement the TDTM_Runnable interface
	        	if(classInstance instanceof TDTM_Runnable) {
			        TDTM_Runnable classToRun = (TDTM_Runnable)classInstance;
			        Boolean async = Boolean.valueOf(classToRunRecord.get('Asynchronous__c'));
			        String action = String.valueOf(classToRunRecord.get('Trigger_Action__c'));
			        
			        //A class can only run asynchronously (calling a future) if we have the ids of the
                    //records we want to affect. This means we can only run it for after in insert. 
                    //Also,a future cannot be called from a future or batch method.
			        if(async && action != 'BeforeInsert' && !System.isFuture() && !System.isBatch()) {
			        	System.debug(LoggingLevel.WARN, '****Calling asynchronously: ' + classToRunName);
			        	runAsync(classToRun, classToRunName);
			        } else {
			        	System.debug(LoggingLevel.WARN, '****Calling synchronously: ' + classToRunName);
                        return classToRun.run(newlist, oldlist, thisAction, obj);
			        }
	        	} else {
	        		System.debug(LoggingLevel.WARN, '****The class does not implement the required interface.');
	        	}
	        } else {
	        	System.debug(LoggingLevel.WARN, '****ClassType was null.');
	        }
        } else {
        	System.debug(LoggingLevel.WARN, '****ClassToCall was null');
        }
        return null;
    }
    
    private void runAsync(TDTM_Runnable classToRun, String classToRunName) {
       Map<Id,Sobject> nm = new Map<Id,Sobject>(newlist);
       
       Map<Id,Sobject> om;
       if(oldlist != null) om = new Map<Id,SObject>(oldlist);
       else om = new Map<Id, SObject>();
       
       classToRun.runFutureNonStatic(nm.keySet(), om.keySet(), thisAction.name(), obj.getName(), classToRunName);
    }
    
    //We want this method to be static so that it can be called from the future method in TDTM_Runnable
    public static void processDML(TDTM_Runnable.DmlWrapper dmlWrapper) {
    	ERR_Handler errorHandler = new ERR_Handler();

        System.debug(LoggingLevel.WARN, '****Final objects to insert: ' + dmlWrapper.objectsToInsert);
        List<Database.SaveResult> insertResults = Database.insert(dmlWrapper.objectsToInsert, false);
        
        System.debug(LoggingLevel.WARN, '****Final objects to update: ' + dmlWrapper.objectsToUpdate.values());
        List<Database.SaveResult> updateResults = Database.update(dmlWrapper.objectsToUpdate.values(), false);
        
        System.debug(LoggingLevel.WARN, '****Final objects to delete: ' + dmlWrapper.objectsToDelete);
        List<Database.DeleteResult> deleteResults = Database.delete(dmlWrapper.objectsToDelete, false);        
        
        //Not yet using this one, as far as I know, but no reason not to support them
        System.debug(LoggingLevel.WARN, '****Final objects to undelete: ' + dmlWrapper.objectsToUndelete);
        List<Database.UndeleteResult> undeleteResults = Database.undelete(dmlWrapper.objectsToUndelete, false);
        
        /** We cannot support upsert because you cannot do upsert on SObject. You have to specify the actual type.        
         *  Also, should we support Database.merge? */
        
        //Process the results
        errorHandler.processResults(insertResults, updateResults, deleteResults, undeleteResults, 
            dmlWrapper.objectsToInsert, dmlWrapper.objectsToUpdate.values(), dmlWrapper.objectsToDelete, 
            dmlWrapper.objectsToUndelete);
    }
    
    //@TODO: read from text file
    private void insertDefaultRecords() {
        //***If we use Objects***       
        List<Trigger_Handler__c> handlers = new List<Trigger_Handler__c>();
        
        //Affiliations on Contact
        handlers.add(new Trigger_Handler__c(Active__c = true, Asynchronous__c = false, 
              Class__c = 'AFFL_Affiliations_TDTM', Load_Order__c = 1, Object__c = 'Contact', 
              Trigger_Action__c = 'AfterInsert;AfterUpdate'));
                    
        //Affiliations on Affiliation
        handlers.add(new Trigger_Handler__c(Active__c = true, Asynchronous__c = false, 
              Class__c = 'AFFL_Affiliations_TDTM', Load_Order__c = 1, Object__c = 'npe5__Affiliation__c', 
              Trigger_Action__c = 'AfterInsert;AfterUpdate'));
                    
        //Relationships on CampaignMember
        handlers.add(new Trigger_Handler__c(Active__c = true, Asynchronous__c = false, 
              Class__c = 'REL_Relationships_TDTM', Load_Order__c = 1, Object__c = 'CampaignMember', 
              Trigger_Action__c = 'AfterInsert;AfterUpdate'));
        
        //Relationships on Contact
        handlers.add(new Trigger_Handler__c(Active__c = true, Asynchronous__c = false, 
              Class__c = 'REL_Relationships_TDTM', Load_Order__c = 1, Object__c = 'Contact', 
              Trigger_Action__c = 'AfterInsert;AfterUpdate;AfterDelete'));
        
        //Relationships on npe4__Relationship__c
        handlers.add(new Trigger_Handler__c(Active__c = true, Asynchronous__c = false, 
              Class__c = 'REL_Relationships_TDTM', Load_Order__c = 1, Object__c = 'npe4__Relationship__c', 
              Trigger_Action__c = 'BeforeInsert;BeforeUpdate;AfterInsert;AfterUpdate;AfterDelete'));
                                         
        //Account Management on Contact
        handlers.add(new Trigger_Handler__c(Active__c = true, Asynchronous__c = false, 
              Class__c = 'ACCT_IndividualAccounts_TDTM', Load_Order__c = 1, Object__c = 'Contact', 
              Trigger_Action__c = 'BeforeInsert;BeforeUpdate;AfterInsert;AfterUpdate;AfterDelete'));

        // OpportunityContactRole support
        handlers.add(new Trigger_Handler__c(Active__c = true, Asynchronous__c = false, 
              Class__c = 'HH_OppContactRoles_TDTM', Load_Order__c = 1, Object__c = 'Opportunity', 
              Trigger_Action__c = 'AfterInsert'));

        // HH Object support
        handlers.add(new Trigger_Handler__c(Active__c = true, Asynchronous__c = false, 
              Class__c = 'HH_HHObject_TDTM', Load_Order__c = 1, Object__c = 'npo02__Household__c', 
              Trigger_Action__c = 'BeforeUpdate;AfterUpdate'));

        // HH Object contact trigger support
        handlers.add(new Trigger_Handler__c(Active__c = true, Asynchronous__c = false, 
              Class__c = 'HH_Households_TDTM', Load_Order__c = 0, Object__c = 'Contact', 
              Trigger_Action__c = 'AfterInsert;AfterUpdate;AfterDelete'));
                
        // RecurringDonations on Opportunity
        handlers.add(new Trigger_Handler__c(Active__c = true, Asynchronous__c = false, 
              Class__c = 'RD_RecurringDonations_TDTM', Load_Order__c = 1, Object__c = 'Opportunity', 
              Trigger_Action__c = 'AfterUpdate'));

        // RecurringDonations on RecurringDonations
        handlers.add(new Trigger_Handler__c(Active__c = true, Asynchronous__c = false, 
              Class__c = 'RD_RecurringDonations_TDTM', Load_Order__c = 1, Object__c = 'npe03__Recurring_Donation__c', 
              Trigger_Action__c = 'BeforeInsert;BeforeDelete;AfterInsert;AfterUpdate;'));
        
        // OppRollups on Opportunity
        handlers.add(new Trigger_Handler__c(Active__c = true, Asynchronous__c = false, 
              Class__c = 'RLLP_OppRollup_TDTM', Load_Order__c = 1, Object__c = 'Opportunity', 
              Trigger_Action__c = 'AfterInsert;AfterUpdate;AfterDelete'));

        // Payments on Opportunity
        handlers.add(new Trigger_Handler__c(Active__c = true, Asynchronous__c = false, 
              Class__c = 'PMT_Payment_TDTM', Load_Order__c = 1, Object__c = 'Opportunity', 
              Trigger_Action__c = 'AfterInsert;AfterUpdate'));

        // OpportunityContactRoles on Opportunity
        handlers.add(new Trigger_Handler__c(Active__c = true, Asynchronous__c = false, 
              Class__c = 'OPP_OpportunityContactRoles_TDTM', Load_Order__c = 0, Object__c = 'Opportunity', 
              Trigger_Action__c = 'BeforeInsert;AfterInsert'));

        //***Sample of how to use Custom Settings***
        /*List<Trigger_Handler_Setting__c> handlers = new List<Trigger_Handler_Setting__c>();
              
        handlers.add(new Trigger_Handler_Setting__c(Name = 'AFF_Contact_AI', Active__c = true, Asynchronous__c = false, 
              Class__c = 'AFFL_Affiliations_TDTM', Load_Order__c = 1, Object__c = 'Contact', 
              Trigger_Action__c = 'AfterInsert'));
                    
        handlers.add(new Trigger_Handler_Setting__c(Name = 'AFF_Contact_AU', Active__c = true, Asynchronous__c = false, 
              Class__c = 'AFFL_Affiliations_TDTM', Load_Order__c = 1, Object__c = 'Contact', 
              Trigger_Action__c = 'AfterUpdate'));
        */            
        insert handlers;
        defaultRecordsInserted = true;        
    }
}