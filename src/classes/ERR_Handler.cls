/*
    Copyright (c) 2014, Salesforce.com Foundation
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

/**
* @author Salesforce.com Foundation
* @date 2014
* @description Helps to determine if errors occurred during the DML operations, and with the necessary
               storing and notification of these errors. 
*/
public with sharing class ERR_Handler {
       
    /*******************************************************************************************************
    * @description Enum used to categorize errors as coming from specific functionality. Each enum value matches 
    *              one of the prefixes used throughout the package.
    */
    public enum Context { AFFL, ALLO, BDE, CON, CONV, HH, LD, OPP, PMT, REL, RD, RLLP, STTG, TDTM, SCH, ADDR, BDI }
    
    /*******************************************************************************************************
    * @description
    */
    public class Errors {
    	/*
        * @description True if errors occurred in one of the DML operations. False otherwise.
        */
    	public Boolean errorsExist = false;
        /*
        * @description Error records.
        */
    	public List<Error__c> errorRecords = new List<Error__c>();
    }
    
    
    /*******************************************************************************************************
    * @description Processes the result of multiple DML operations performed using the Database class, to determine 
    *              if errors occurred. It does not store errors or send error email notifications. These operations
    *              should be performed after the rollback.
    *
    * @param insertResults The result of a Database.Insert operation.
    * @param updateResults The result of a Database.Update operation.
    * @param deleteResults The result of a Database.Delete operation.
    * @param undeleteResults The result of a Database.Undelete operation.
    * @param insertedObjects Objects that were inserted in the Database.Insert operation.
    * @param updatedObjects Objects that were updated in the Database.Update operation.
    * @param deletedObjects Objects that were deleted in the Database.Delete operation.
    * @param undeletedObjects Objects that were Undeleted in the Database.Undelete operation.
    *
    * @return Errors Combined result od all the DML operations.
    */
    public static Errors getErrors(
    List<Database.SaveResult> insertResults, List<Database.SaveResult> updateResults, 
    List<Database.DeleteResult> deleteResults, List<Database.UndeleteResult> undeleteResults, 
    List<SObject> insertedObjects, List<SObject> updatedObjects, 
    List<SObject> deletedObjects, List<SObject> undeletedObjects) {
                    
        Errors errors = new Errors();
        	
    	Errors insertErrors = getErrors(insertResults, insertedObjects);  //Insert
    	Errors updateErrors = getErrors(updateResults, updatedObjects);  //Update
    	Errors deleteErrors = getErrors(deleteResults, deletedObjects);  //Delete
    	Errors undeleteErrors= getErrors(undeleteResults, undeletedObjects);  //Undelete
    	
    	if(insertErrors.errorsExist || updateErrors.errorsExist || deleteErrors.errorsExist || undeleteErrors.errorsExist) {
    		errors.errorsExist = true;
    		errors.errorRecords.addAll(insertErrors.errorRecords);
    		errors.errorRecords.addAll(updateErrors.errorRecords);
    		errors.errorRecords.addAll(deleteErrors.errorRecords);
    		errors.errorRecords.addAll(undeleteErrors.errorRecords);
    	}
    	
    	// We do NOT want to try to store errors or send error email notifications here. We want to be able to 
    	//manually do that after the rollback.
 
    	return errors;
    }

    /*******************************************************************************************************
    * @description Processes the results of a single DML operation performed using the Database class to determine 
    *              if errors occurred. It does not store errors or send error email notifications. These operations
    *              should be performed after the rollback. 
    */    
    public static Errors getErrors(List<Object> results, List<SObject> sObjects) {    	
    	Errors errors = new Errors();
    	
    	if(results != null) {	
	    	for(Integer i=0; i<results.size(); i++) {
	        	Boolean isSuccess = true;
	        	if(results[i] instanceof Database.SaveResult) {
	        		isSuccess = ((Database.SaveResult)results[i]).isSuccess();
	        	} else if(results[i] instanceof Database.DeleteResult) {
	        		isSuccess = ((Database.DeleteResult)results[i]).isSuccess();
	        	} else if(results[i] instanceof Database.UndeleteResult) {
	        		isSuccess = ((Database.UndeleteResult)results[i]).isSuccess();
	        	}
	        	
	        	if(!isSuccess) {
	        		errors.errorsExist = true;
	        		
	        		//Creating error object
	        		Error__c err = createError(results[i], sObjects[i].getSObjectType().getDescribe().getName(), sObjects[i].Id);
	                errors.errorRecords.add(err);
	                
	                //We cannot use addError on the record here, because if we do, the whole transaction will be rolled back, and 
	                //no error record will be saved,or error notification sent.
	                
	                //Displaying an error message to the user
	                if(ApexPages.currentPage() != null)
	                   ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, err.Full_Message__c)); 
	                
	                //Bubbling the exception, if necessary.   
                    if (TDTM_TriggerHandler.isPropogateErrorsFromTrigger) {
                        UTIL_Debug.debug('**** isPropogateErrorsFromTrigger is true, so wanted to addError to: ' + sObjects[i]);
                        throw new PropogateException(err.Full_Message__c);
                    }
	        	}
	        }
    	}
    	return errors;
    }
    
    /*******************************************************************************************************
    * @description 
    * @param
    * @return 
    */
    private class PropogateException extends Exception {}
    
    /*******************************************************************************************************
    * @description 
    * @param
    * @return 
    */
    public static void processError(Exception e, ERR_Handler.Context context) {
    	
    	if(e != null) {
    		UTIL_Debug.debug(LoggingLevel.WARN, '****Exception to process: ' + e.getMessage() + '\n\nStack trace: ' + e.getStackTraceString());
			
			if(ApexPages.currentPage() != null)
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
           
           if(UTIL_CustomSettingsFacade.getErrorSettings().Store_Errors_On__c) {
               Error__c error = createError(e);
               Database.SaveResult result = Database.insert(error, false);
           }
    	}
           
        ERR_Notifier.sendErrorNotifications(context);
    }

    /*******************************************************************************************************
    * @description We want this method to be public to be able to explicitly call it after a rollback.
    * @param
    * @return 
    */
    public static void storeErrors(List<Error__c> errorRecords) {        
        if(UTIL_CustomSettingsFacade.getErrorSettings().Store_Errors_On__c) {
		  UTIL_Debug.debug(LoggingLevel.WARN, '****Storing errors: ' + JSON.serializePretty(errorRecords));
		  Database.insert(errorRecords, false);
        }
    }
    
    /*******************************************************************************************************
    * @description
    * @param
    * @return 
    */
	private static Error__c createError(Exception e) {
		Error__c error = new Error__c();
		error.Datetime__c = System.now();        
		error.Error_Type__c = e.getTypeName();
		error.Full_Message__c = e.getMessage();
		//Putting it into a local string to see if that helps storing the stack trace when we
		//are in a managed package.
		String stackTrace = e.getStackTraceString();
		String message;
		if(String.isBlank(stackTrace) || stackTrace == '(npsp)') {
			message = 'No stacktrace available at the time of saving the record. ';
		} else {
			message = 'Stacktrace available at the time of saving the record - ';
		}
		error.Stack_Trace__c = message + stackTrace;
		return error;
	}

    /*******************************************************************************************************
    * @description
    * @param
    * @return 
    */
    private static Error__c createError(Object result, string objectType, id objId) {
    	Error__c error = new Error__c();
        error.Datetime__c = System.now();
        error.Object_Type__c = objectType;
        
    	if(result instanceof Database.SaveResult) {
    		Database.SaveResult saveResult = (Database.SaveResult) result;
    		error.Record_URL__c = getRecordURL(saveResult.getId(), objId);
	        error.Error_Type__c = getStatusCode(saveResult.getErrors()[0].getStatusCode());
	        error.Full_Message__c = saveResult.getErrors()[0].getMessage();	
    	} else if(result instanceof Database.DeleteResult) {
    		Database.DeleteResult deleteResult = (Database.DeleteResult) result;
            error.Record_URL__c = getRecordURL(deleteResult.getId(), objId);
            error.Error_Type__c = getStatusCode(deleteResult.getErrors()[0].getStatusCode());
            error.Full_Message__c = deleteResult.getErrors()[0].getMessage();
    	} else if(result instanceof Database.UndeleteResult) {
    		Database.UndeleteResult undeleteResult = (Database.UndeleteResult) result;
            error.Record_URL__c = getRecordURL(undeleteResult.getId(), objId);
            error.Error_Type__c = getStatusCode(undeleteResult.getErrors()[0].getStatusCode());
            error.Full_Message__c = undeleteResult.getErrors()[0].getMessage();
    	}
    
        return error;
    }
    
    /*******************************************************************************************************
    * @description
    * @param
    * @return 
    */
    private static String getRecordURL(Id saveResultId, Id objId) {
    	String recordURL = URL.getSalesforceBaseUrl().toExternalForm() + '/';
        if (saveResultId != null)
            recordURL += saveResultId;
        else            
            recordURL += objId;
                     
        if (recordURL.startsWith('http:'))
            recordURL = recordURL.replaceFirst('http:', 'https:');
            
        return recordURL;
    }
    
    /*******************************************************************************************************
    * @description
    * @param
    * @return 
    */
    private static String getStatusCode(system.StatusCode status) {
    	if (status == system.Statuscode.REQUIRED_FIELD_MISSING)
            return 'Required Field Missing';   
        else if (status == system.Statuscode.FIELD_CUSTOM_VALIDATION_EXCEPTION)
            return 'Custom Validation Rule Failed';
        else
            return 'Other';
    }
}