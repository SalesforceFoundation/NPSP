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
public with sharing class ERR_Handler {
    
    private List<Error__c> errors = new List<Error__c>();
   
    public enum Context {AFFL, ALLO, BDE, CON, CONV, HH, LD, OPP, PMT, REL, RD, RLLP, STTG, TDTM, SCH, ADDR, BDI}
    
    private static String stackTrace;
    
    public Boolean processResults(List<Database.SaveResult> insertResults, List<Database.SaveResult> updateResults, 
    List<Database.DeleteResult> deleteResults, List<Database.UndeleteResult> undeleteResults, 
    List<SObject> objectsToInsert, List<SObject> objectsToUpdate, 
    List<SObject> objectsToDelete, List<SObject> objectsToUndelete) {
    	
    	return processResults(insertResults, updateResults, deleteResults, undeleteResults, objectsToInsert, objectsToUpdate, 
    	               objectsToDelete, objectsToUndelete, null);
    }
    
    public Boolean processInsertResults(List<Database.SaveResult> insertResults, List<SObject> objectsToInsert, 
    ERR_Handler.Context context) {
    	return processResults(insertResults, null, null, null, objectsToInsert, null, null, null, context);
    }
    
    public Boolean processUpdateResults(List<Database.SaveResult> updateResults, List<SObject> objectsToUpdate, 
    ERR_Handler.Context context) {
        return processResults(null, updateResults, null, null, null, objectsToUpdate, null, null, context);
    }
    
    public Boolean processResults(List<Database.SaveResult> insertResults, List<Database.SaveResult> updateResults, 
    List<Database.DeleteResult> deleteResults, List<Database.UndeleteResult> undeleteResults, 
    List<SObject> objectsToInsert, List<SObject> objectsToUpdate, 
    List<SObject> objectsToDelete, List<SObject> objectsToUndelete, ERR_Handler.Context context) {
                    
        Boolean errorsExist = false;
        	
    	Boolean errorsExistOnInserts = processResults(insertResults, objectsToInsert);  //Insert
    	Boolean errorsExistOnUpdates = processResults(updateResults, objectsToUpdate);  //Update
    	Boolean errorsExistOnDeletes = processResults(deleteResults, objectsToDelete);  //Delete
    	Boolean errorsExistOnUndeletes = processResults(undeleteResults, objectsToUndelete);  //Undelete
    	
    	if(errorsExistOnInserts || errorsExistOnUpdates || errorsExistOnDeletes || errorsExistOnUndeletes) {
    		errorsExist = true;
    	}
    	
    	/*** We do NOT want to call storeErrors here. We want to be able to manually do that after a rollback.***/
    	
    	if(UTIL_CustomSettingsFacade.getErrorSettings().Error_Notifications_On__c && errorsExist) {
           UTIL_Debug.debug('****Errors exist - calling Error Notifier');
           ERR_Notifier.sendErrorNotifications(context);
    	}
           
    	return ErrorsExist;
    }

    private Boolean processResults(List<Object> results, List<SObject> sObjects) {    	
    	Boolean errorsExist = false;
    	
    	if(results != null) {	
	    	for(Integer i=0; i<results.size(); i++) {
	        	String message;
	        	Boolean isSuccess = true;
	        	List<Object> resultErrors;
	        	if(results[i] instanceof Database.SaveResult) {
	        		isSuccess = ((Database.SaveResult)results[i]).isSuccess();
	        		if(!isSuccess) {
	        		  message = ((Database.SaveResult)results[i]).getErrors()[0].getMessage();
	        		  resultErrors = ((Database.SaveResult)results[i]).getErrors();
	        		}
	        	} else if(results[i] instanceof Database.DeleteResult) {
	        		isSuccess = ((Database.DeleteResult)results[i]).isSuccess();
	        		if(!isSuccess) {
	        		  message = ((Database.DeleteResult)results[i]).getErrors()[0].getMessage();
	        		  resultErrors = ((Database.DeleteResult)results[i]).getErrors();
	        		}
	        	} else if(results[i] instanceof Database.UndeleteResult) {
	        		isSuccess = ((Database.UndeleteResult)results[i]).isSuccess();
	        		if(!isSuccess) {
	        		  message = ((Database.UndeleteResult)results[i]).getErrors()[0].getMessage();
	        		  resultErrors = ((Database.UndeleteResult)results[i]).getErrors();
	        		}
	        	}
	        	
	        	if(!isSuccess && message != null) {
	        		UTIL_Debug.debug('****Process result errors: ' + JSON.serializePretty(resultErrors));
	        		errorsExist = true;
	        		//Creating error object
	        		Error__c err = createError(results[i], sObjects[i].getSObjectType().getDescribe().getName(), sObjects[i].Id);
	                errors.add(err);
	                //Adding error message to the record
	                /* If we use addError on a record the whole transaction will be rolled back, and no error record will be saved,
                     or error notification sent.
	                if(sObjects != null && sObjects.size() > i)
	                   addErrorMessage(sObjects[i], message);*/
	                if(ApexPages.currentPage() != null)
	                   ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, err.Full_Message__c)); 
	        	}
	        }
    	}
    	return errorsExist;
    }
    
    /*** Error processing methods - Right now we are just saving errors to the DB, but we could do something else ***/
    public static void processError(Exception e, ERR_Handler.Context context) {
        processError(e, new List<SObject>(), context);
    }
    
    public static void processError(Exception e, SObject record, ERR_Handler.Context context) {
    	processError(e, new SObject[]{record}, context);
    }
    
    public static void processError(Exception e, List<SObject> records, ERR_Handler.Context context) {
    	
    	if(e != null) {
    		UTIL_Debug.debug(LoggingLevel.WARN, '****Exception to process: ' + e.getMessage() + '\n\nStack trace: ' + e.getStackTraceString());
			if(e instanceof DmlException && records != null && records.size() > 0) {
                DmlException de = (DmlException) e;
                for(Integer i=0; i<de.getNumDml(); i++) {
                   UTIL_Debug.debug(LoggingLevel.WARN, '****Position of failed record in original list: ' + de.getDmlIndex(i));
                   Integer failedRecordIndex = de.getDmlIndex(i); //Position of failed record in original list
                   /*If we use addError on a record the whole transaction will be rolled back, and no error record will be saved,
                     or error notification sent. 
                   addErrorMessage(records[failedRecordIndex], de.getDmlMessage(i)); */
                   if(ApexPages.currentPage() != null)
                       ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
               }
           }
           
           if(UTIL_CustomSettingsFacade.getErrorSettings().Store_Errors_On__c) {
               Error__c error = createError(e);
               UTIL_Debug.debug(LoggingLevel.WARN, '****Error record to store: ' + JSON.serializePretty(error));
               Database.SaveResult result = Database.insert(error, false);
           }
    	}
    	
    	if(UTIL_CustomSettingsFacade.getErrorSettings().Error_Notifications_On__c) {
    	   UTIL_Debug.debug('****Sending error notification');
           ERR_Notifier.sendErrorNotifications(context);
    	}
    }
    
    private static void addErrorMessage(SObject record, String defaultMessage) {
    	String message = '';
    	if(record.getSObjectType().getDescribe().getName() != null)
            message = 'Error on record of type ' + record.getSObjectType().getDescribe().getName() + ' - ';
    	if(record.get('Id') != null)
            message = message + 'Record ID: ' + record.get('Id') + ' - ';
        if(record.get('Name') != null)
            message = message + 'Record Name: ' + record.get('Name') + ' - ';
        message = message + '"' + defaultMessage + '"';
        record.addError(message);
    }
    
    /*** We want this method to be public to be able to explicitly call it after a rollback. ***/
    public void storeErrors() {        
        if(UTIL_CustomSettingsFacade.getErrorSettings().Store_Errors_On__c) {
		  UTIL_Debug.debug(LoggingLevel.WARN, '****Storing errors: ' + JSON.serializePretty(errors));
		  Database.insert(errors, false);
        }
    }
    
    /*** Error creation methods ***/
	private static Error__c createError(Exception e) {
		Error__c error = new Error__c();
		error.Datetime__c = System.now();        
		error.Error_Type__c = e.getTypeName();
		error.Full_Message__c = e.getMessage();
		//Putting it into a local string to see if that helps storing the stack trace when we
		//are in a managed package.
		stackTrace = e.getStackTraceString();
		if(stackTrace == null || stackTrace == '(npsp)') {
			stackTrace = 'No stacktrace available at the time of saving the record. ';
		} else {
			stackTrace = 'Stacktrace available at the time of saving the record - ';
		}
		error.Stack_Trace__c = stacktrace + e.getStackTraceString();
		return error;
	}

    public void queueError(string objectType, Id objId, String errMessage, String errType, String stkTrace) {
        Error__c error = new Error__c();
        error.Datetime__c = System.now();
        error.Object_Type__c = objectType;
        error.Record_URL__c = getRecordURL(null, objId);
        error.Error_Type__c = errType;
        error.Full_Message__c = errMessage;
        error.Stack_Trace__c = stkTrace;
        errors.add(error);
    }

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
    
    /*** Helper methods ***/
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
    
    private static String getStatusCode(system.StatusCode status) {
    	if (status == system.Statuscode.REQUIRED_FIELD_MISSING)
            return 'Required Field Missing';   
        else if (status == system.Statuscode.FIELD_CUSTOM_VALIDATION_EXCEPTION)
            return 'Custom Validation Rule Failed';
        else
            return 'Other';
    }
}