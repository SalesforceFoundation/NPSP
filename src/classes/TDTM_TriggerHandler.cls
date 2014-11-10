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

    private static Boolean defaultRecordsInserted = false;
    
    public static boolean suppressDebugAssertAfterErrorLogging = false;
    
    public void run(Boolean isBefore, Boolean isAfter, Boolean isInsert, Boolean isUpdate,
    Boolean isDelete, Boolean isUnDelete, List<Sobject> newList, List<Sobject> oldList, 
    Schema.DescribeSobjectResult describeObj, TDTM_iTableDataGateway dao) {
    	if(newList != null)
    	   UTIL_Debug.debug(LoggingLevel.WARN, '****Trigger.new size: ' + newList.size());
    	/** This solves the problem of not being able to save error records if everything gets rolled back. 
        TDTM_TriggerHandler is taking care of saving error records if there is any error when performing 
        DML operations. It also takes care of rolling everything back in that case, just so there are no 
        issues (side effects) with re-entrant flags. **/
    	Savepoint sp = Database.setSavepoint();
    	
    	try {
    		TDTM_Runnable.Action thisAction = TDTM_TriggerActionHelper.determineTriggerAction(isBefore, 
    		                                              isAfter, isInsert, isUpdate, isDelete, isUnDelete);
            UTIL_Debug.debugWithInfo('****ACTION: ' + thisAction + ' on ' + describeObj.getLabel());
        
	        TDTM_Runnable.DmlWrapper dmlWrapper = new TDTM_Runnable.DmlWrapper();
	        
	        //If there are no records insert the defaults.
	        if(!defaultRecordsInserted && dao.isEmpty()) {
	        	List<Trigger_Handler__c> defaultConfig = TDTM_DefaultConfig.getDefaultRecords();
	        	insert defaultConfig;
	        	defaultRecordsInserted = true;
	        }
	        
	        //Get the classes to run
            // note that we are using the local object name, so it works for objects from Cumulus both in the package and unmanaged dev orgs.
	        List<SObject> classesToCall = dao.getclassesToCallForObject(describeObj.getLocalName(), thisAction);
	        UTIL_Debug.debug(LoggingLevel.WARN, '****Classes To Call for ' + describeObj.getLocalName() + ': ' + JSON.serializePretty(classesToCall));
	        
	        if(classesToCall != null && classesToCall.size() > 0) {
	            //Run the relevant classes
	            for (SObject classToCall : classesToCall) {
	                TDTM_Runnable.DmlWrapper dmlWrapperLocal = new TDTM_Runnable.DmlWrapper();
	                dmlWrapperLocal = runClass(classToCall, newList, OldList, thisAction, describeObj);
	                if(dmlWrapperLocal != null) {
	                	if(dmlWrapperLocal.objectsToInsert != null && !dmlWrapperLocal.objectsToInsert.isEmpty())
	                        dmlWrapper.objectsToInsert.addAll(dmlWrapperLocal.objectsToInsert);
	                    if(dmlWrapperLocal.objectsToUpdate != null && !dmlWrapperLocal.objectsToUpdate.isEmpty())
	                        dmlWrapper.objectsToUpdate.addAll(dmlWrapperLocal.objectsToUpdate);
	                    if(dmlWrapperLocal.objectsToDelete != null && !dmlWrapperLocal.objectsToDelete.isEmpty())
	                        dmlWrapper.objectsToDelete.addAll(dmlWrapperLocal.objectsToDelete);
	                    if(dmlWrapperLocal.objectsToUndelete != null && !dmlWrapperLocal.objectsToUndelete.isEmpty())
	                        dmlWrapper.objectsToUndelete.addAll(dmlWrapperLocal.objectsToUndelete);
	                }          
                    UTIL_Debug.debugWithInfo('****Finished executing: ' + classToCall.get('Class__c'));
	            }
	                         
	            //Process the result
	            if(dmlWrapper != null)
	               processDML(dmlWrapper);
	        }
	    } catch(Exception e) {
	    	UTIL_Debug.debug(LoggingLevel.WARN, '****Exception caught in run method of TDTM_TriggerHandler: ' + e.getMessage());
            Database.rollback(sp);
            ERR_Handler.processError(e, ERR_Handler.Context.TDTM);
            /** We don't need to mark the record(s) with an error (with addError) because the application does it automatically 
            for us (IF they are part of the DML performed in our processDML method). If we mark it with an error the transaction 
            will be rolled back by the platform, and our error record won't be saved or error notifications sent. **/ 
            
            // but we do want our tests to fail if they encountered this error!
            // we do need to allow some specific tests that are testing our error handling
            // to avoid the assert, because by allowing it to throw an exception within our catch, it
            // changes system behavior.
            if (Test.isRunningTest() && !suppressDebugAssertAfterErrorLogging)
                system.assertEquals(null, e.getMessage()); 
        }
    }
    
    private TDTM_Runnable.DmlWrapper runClass(SObject classToRunRecord, List<Sobject> newList, List<Sobject> oldList, 
    TDTM_Runnable.Action thisAction, Schema.DescribeSobjectResult describeObj) {
    	        
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
			        	UTIL_Debug.debug(LoggingLevel.WARN, '****Calling asynchronously: ' + classToRunName);
			        	runAsync(classToRun, classToRunName, newList, oldList, thisAction, describeObj);
			        } else {
			        	UTIL_Debug.debugWithInfo('****Calling synchronously: ' + classToRunName);
                        return classToRun.run(newlist, oldlist, thisAction, describeObj);
			        }
	        	} else {
	        		UTIL_Debug.debug(LoggingLevel.WARN, '****The class does not implement the required interface.');
	        	}
	        } else {
	        	UTIL_Debug.debug(LoggingLevel.WARN, '****ClassType was null.');
	        }
        } else {
        	UTIL_Debug.debug(LoggingLevel.WARN, '****ClassToCall was null');
        }
        return null;
    }
    
    private void runAsync(TDTM_Runnable classToRun, String classToRunName, List<Sobject> newList, 
    List<Sobject> oldList, TDTM_Runnable.Action thisAction, Schema.DescribeSobjectResult describeObj) {
       Map<Id,Sobject> nm = new Map<Id,Sobject>(newlist);
       
       Map<Id,Sobject> om;
       if(oldlist != null) om = new Map<Id,SObject>(oldlist);
       else om = new Map<Id, SObject>();
       
       classToRun.runFutureNonStatic(nm.keySet(), om.keySet(), thisAction.name(), describeObj.getName(), classToRunName);
    }
    
    //We want this method to be static so that it can be called from the future method in TDTM_Runnable
    public static void processDML(TDTM_Runnable.DmlWrapper dmlWrapper) {
    	ERR_Handler errorHandler = new ERR_Handler();

        //Create transaction
        Savepoint sp = Database.setSavepoint();
        
        dmlWrapper.groupByType(); //sort thyself!
        
        /**We keep the Database methods with the opt_allOrNone flag set to false to be able to alert the client 
        process of all the errors that occurred in the context **/
        //UTIL_Debug.debug(LoggingLevel.WARN, '****Final objects to insert: ' + JSON.serializePretty(dmlWrapper.objectsToInsert));
        List<Database.SaveResult> insertResults = Database.insert(dmlWrapper.objectsToInsert, false);
        
        //UTIL_Debug.debug(LoggingLevel.WARN, '****Final objects to update: ' + JSON.serializePretty(dmlWrapper.objectsToUpdate));
        List<Database.SaveResult> updateResults = Database.update(dmlWrapper.objectsToUpdate, false);
        
        //UTIL_Debug.debug(LoggingLevel.WARN, '****Final objects to delete: ' + JSON.serializePretty(dmlWrapper.objectsToDelete));
        List<Database.DeleteResult> deleteResults = Database.delete(dmlWrapper.objectsToDelete, false);        
        
        //Not yet using this one, as far as I know, but no reason not to support them
        //UTIL_Debug.debug(LoggingLevel.WARN, '****Final objects to undelete: ' + JSON.serializePretty(dmlWrapper.objectsToUndelete));
        List<Database.UndeleteResult> undeleteResults = Database.undelete(dmlWrapper.objectsToUndelete, false);
        
        //@TODO: We cannot support upsert because you cannot do upsert on SObject. You have to specify the actual type.        
        //Also, should we support Database.merge?
        
        //Process the results
        Boolean errorsExist = errorHandler.processResults(insertResults, updateResults, deleteResults, undeleteResults, 
            dmlWrapper.objectsToInsert, dmlWrapper.objectsToUpdate, dmlWrapper.objectsToDelete, 
            dmlWrapper.objectsToUndelete, ERR_Handler.Context.TDTM);
            
        if(errorsExist) {
        	UTIL_Debug.debug(LoggingLevel.WARN, '****Error found when processing DML');
            Database.rollback(sp);
            errorHandler.storeErrors();
        }
    }
}