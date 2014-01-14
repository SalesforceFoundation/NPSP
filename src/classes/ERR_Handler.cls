public with sharing class ERR_Handler {

    //@TODO: we should read this flag from a custom setting
    public static Boolean DiagnosticsEnabled = true;
    
    private List<Error__c> errors = new List<Error__c>();
    
    public Boolean processResults(List<Database.SaveResult> insertResults, List<Database.SaveResult> updateResults, 
    List<Database.DeleteResult> deleteResults, List<Database.UndeleteResult> undeleteResults, 
    List<SObject> objectsToInsert, List<SObject> objectsToUpdate, 
    List<SObject> objectsToDelete, List<SObject> objectsToUndelete) {
        
        Boolean errorsExist = false;
        	
    	Boolean errorsExistOnInserts = processResults(insertResults, objectsToInsert);  //Insert
    	Boolean errorsExistOnUpdates = processResults(updateResults, objectsToUpdate);  //Update
    	Boolean errorsExistOnDeletes = processResults(deleteResults, objectsToDelete);  //Delete
    	Boolean errorsExistOnUndeletes = processResults(undeleteResults, objectsToUndelete);  //Undelete
    	
    	if(errorsExistOnInserts || errorsExistOnUpdates || errorsExistOnDeletes || errorsExistOnUndeletes) {
    		errorsExist = true;
    	}
    	return ErrorsExist;
    }

    private Boolean processResults(List<Object> results, List<SObject> sObjects) {    	
    	Boolean errorsExist = false;
    	
    	if(results != null) {	
	    	for(Integer i=0; i<results.size(); i++) {
	        	String message;
	        	Boolean isSuccess = true;
	        	if(results[i] instanceof Database.SaveResult) {
	        		isSuccess = ((Database.SaveResult)results[i]).isSuccess();
	        		if(!isSuccess)
	        		  message = ((Database.SaveResult)results[i]).getErrors()[0].getMessage();
	        	} else if(results[i] instanceof Database.DeleteResult) {
	        		isSuccess = ((Database.DeleteResult)results[i]).isSuccess();
	        		if(!isSuccess)
	        		  message = ((Database.DeleteResult)results[i]).getErrors()[0].getMessage();
	        	} else if(results[i] instanceof Database.UndeleteResult) {
	        		isSuccess = ((Database.UndeleteResult)results[i]).isSuccess();
	        		if(!isSuccess)
	        		  message = ((Database.UndeleteResult)results[i]).getErrors()[0].getMessage();
	        	}
	        	
	        	if(!isSuccess && message != null) {
	        		errorsExist = true;
	        		//Creating error object
	                errors.add(createError(results[i], sObjects[i].getSObjectType().getDescribe().getName(), sObjects[i].Id));
	                //Adding error message to the record
	                if(sObjects != null && sObjects.size() > i)
	                   addErrorMessage(sObjects[i], message);
	        	}
	        }
    	}
    	return errorsExist;
    }
    
    /*** Error processing methods - Right now we are just saving errors to the DB, but we could do something else ***/
    public static void processError(Exception e, List<SObject> records) {
    	if(DiagnosticsEnabled && e != null) {
			if(e instanceof DmlException && records != null) {
                DmlException de = (DmlException) e;
                for(Integer i=0; i<de.getNumDml(); i++) {
                   System.debug(LoggingLevel.WARN, '****Position of failed record in original list: ' + de.getDmlIndex(i));
                   Integer failedRecordIndex = de.getDmlIndex(i); //Position of failed record in original list
                   addErrorMessage( records[failedRecordIndex], de.getDmlMessage(i));
               }
           }
           
		   Error__c error = createError(e);
	       if(DiagnosticsEnabled) {
               Database.SaveResult result = Database.insert(error, false);
               System.debug(LoggingLevel.WARN, '****Was error record inserted: ' + result.isSuccess());
               System.debug(LoggingLevel.WARN, '****Error record: ' + error);
	       }
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
    
    public void storeErrors() {
    	if(DiagnosticsEnabled) {
    		System.debug(LoggingLevel.WARN, '****Storing errors: ' + errors);
    		Database.insert(errors, false);
    	}
    }
    
    /*** Error creation methods ***/
	public static Error__c createError(Exception e) {
		Error__c error = new Error__c();
		error.Datetime__c = System.now();        
		error.Error_Type__c = e.getTypeName();
		error.Full_Message__c = e.getMessage();
		error.Stack_Trace__c = e.getStackTraceString();
		return error;
	}

    public static Error__c createError(Object result, string objectType, id objId) {
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
    
    /*** Future methods - not yet used ***/
    @future
    private static void saveErrorFuture(Datetime now, String objectType, String recordURL, String status,
    String message) {
        Error__c error = new Error__c();
        error.Datetime__c = now;
        error.Object_Type__c = objectType;
        error.Error_Type__c = status;
        error.Record_URL__c = recordURL;
        error.Full_Message__c = message;
        Database.insert(error, false);
    }
    
    @future
    private static void saveErrorFuture(Datetime now, String typeName, String stackTrace, String message) {
        Error__c error = new Error__c();
        error.Datetime__c = now;        
        error.Error_Type__c = typeName;
        error.Stack_Trace__c = stackTrace;
        error.Full_Message__c = message;
        Database.insert(error, false);
    }
}