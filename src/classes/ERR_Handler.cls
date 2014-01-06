public with sharing class ERR_Handler {

    //@TODO: we should read this flag from a custom setting
    public static Boolean DiagnosticsEnabled = true;
    
    List<Error__c> errors = new List<Error__c>();
    
    public void processResults(List<Database.SaveResult> insertResults, List<Database.SaveResult> updateResults, 
    List<Database.DeleteResult> deleteResults, List<Database.UndeleteResult> undeleteResults, 
    List<SObject> objectsToInsert, List<SObject> objectsToUpdate, 
    //List<SObject> objectsToDelete, List<SObject> objectsToUndelete
    List<Id> objectsToDelete, List<Id> objectsToUndelete
    ) {

    	processInsertUpdateResults(insertResults, objectsToInsert);  //Insert
    	processInsertUpdateResults(updateResults, objectsToUpdate);  //Update
    	//processDeleteResults(deleteResults, objectsToDelete);  //Delete
    	//processUndeleteResults(undeleteResults, objectsToUndelete);  //Undelete
    	
    	storeErrors(errors);
    }
    
    /*** The following three methods are identical, but unfortunately we couldn't have only one because no parent
        class of Database.SaveResult, Database.DeleteResult and Database.UndeleteResult was provided in the API ***/
    private void processInsertUpdateResults(List<Database.SaveResult> results, List<SObject> objects) {
    	for(Integer i=0; i<results.size(); i++) {
            if(!results[i].isSuccess()) {
                //Adding error message to the record
                System.debug(LoggingLevel.WARN, '****Adding error message "' + results[i].getErrors()[0].getMessage() 
                + ' to this record: ' + objects[i]);
                objects[i].addError(results[i].getErrors()[0].getMessage());
                //Creating error object
                errors.add(createError(results[i], objects[i].getSObjectType().getDescribe().getName(), objects[i].Id));
            } else {
            	System.debug(LoggingLevel.WARN, '****Successful SaveResult: ' + results[i].getId());
            }
        }
    }
    /* The problem wih delete and undelete is that we only have the IDs, not the object. Changing to objects would
    mean a lot of work through the whole app. Might not even be doable...
    private void processDeleteResults(List<Database.DeleteResult> results, List<SObject> objects) {
        for(Integer i=0; i<results.size(); i++) {
            if(!results[i].isSuccess()) {
                //Adding error message to the record
                objects[i].addError(results[i].getErrors()[0].getMessage());
                //Creating error object
                errors.add(createError(results[i], objects[i].getSObjectType().getDescribe().getName(), objects[i].Id));
            }
        }
    }
    
    private void processUndeleteResults(List<Database.UndeleteResult> results, List<SObject> objects) {
        for(Integer i=0; i<results.size(); i++) {
            if(!results[i].isSuccess()) {
                //Adding error message to the record
                objects[i].addError(results[i].getErrors()[0].getMessage());
                //Creating error object
                errors.add(createError(results[i], objects[i].getSObjectType().getDescribe().getName(), objects[i].Id));
            }
        }
    }*/
    
    /*** Error processing methods - Right now we are just saving errors to the DB, but we could do something else ***/
    public static void processError(Exception e, List<SObject> records) {
    	if(DiagnosticsEnabled && e != null) {
			if(e instanceof DmlException && records != null) {
                DmlException de = (DmlException) e;
                for(Integer i=0; i<de.getNumDml(); i++) {
                   System.debug(LoggingLevel.WARN, '****Position of failed record in original list: ' + de.getDmlIndex(i));
                   Integer failedRecordIndex = de.getDmlIndex(i); //Position of failed record in original list
                   records[failedRecordIndex].addError(de.getDmlMessage(i));
               }
           }
           
		   Error__c error = createError(e);
	       storeErrors(new Error__c[]{error}); 
    	}
    }
    
    private static void storeErrors(List<Error__c> errors) {
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

    /*** This is the same issue as above. Ideally we would only need 1 method, but since no interface was provided
    for Database.SaveResult, Database.DeleteResult and Database.UndeleteResult ***/
    public static Error__c createError(Database.SaveResult result, string objectType, id objId) {
        Error__c error = new Error__c();
        error.Datetime__c = System.now();
        error.Object_Type__c = objectType;   
        error.Record_URL__c = getRecordURL(result.getId(), objId);
        error.Error_Type__c = getStatusCode(result.getErrors()[0].getStatusCode());
        error.Full_Message__c = result.getErrors()[0].getMessage();
        return error;
    }
    /*
    public static Error__c createError(Database.DeleteResult result, string objectType, id objId) {
        Error__c error = new Error__c();
        error.Datetime__c = System.now();
        error.Object_Type__c = objectType;   
        error.Record_URL__c = getRecordURL(result.getId(), objId);
        error.Error_Type__c = getStatusCode(result.getErrors()[0].getStatusCode());
        error.Full_Message__c = result.getErrors()[0].getMessage();
        return error;
    }
    
    public static Error__c createError(Database.UndeleteResult result, string objectType, id objId) {
        Error__c error = new Error__c();
        error.Datetime__c = System.now();
        error.Object_Type__c = objectType;   
        error.Record_URL__c = getRecordURL(result.getId(), objId);
        error.Error_Type__c = getStatusCode(result.getErrors()[0].getStatusCode());
        error.Full_Message__c = result.getErrors()[0].getMessage();
        return error;
    }*/
    
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