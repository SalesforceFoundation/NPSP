public with sharing class ERR_Handler {

    //@TODO: we should read this from a custom setting
    public static Boolean DiagnosticsEnabled = true;
    
    List<SObject> newList;
    List<SObject> oldList;
    Map<Id, SObject> newMap = new Map<Id, SObject>();
    Map<Id, SObject> oldMap = new Map<Id, SObject>();
    //Stores the error associated with the list position of the SObjInsLIST to the triggering ID 
    public static MAP<integer, string>sObjInsErrMAP = new MAP<integer, string>();
    //Stores the error associated with the list position of the SObjUpdLIST to the triggering ID
    public static MAP<integer, string>sObjUpdErrMAP = new MAP<integer, string>();
    
    public void processResults(List<Database.SaveResult> insertResults, List<Database.SaveResult> updateResults, 
    List<Database.DeleteResult> deleteResults, List<Database.UndeleteResult> undeleteResults, 
    List<SObject> newList, List<SObject> oldList) {
        
        if(DiagnosticsEnabled) {
        	
        	this.newList = newList;
            this.oldList = oldList;
            
            for(SObject record : newList)
            	if(record.Id != null) newMap.put(record.Id, record);
            
            for(SObject record : oldList)
                if(record.Id != null) oldMap.put(record.Id, record);
        
            Map<String, String> errorMap = new Map<string, string>();
            
            List<Error__c> errors = new List<Error__c>();
            //INSERT
            if(insertResults != null && insertResults.size() > 0) {
                Integer i = 0;
                for(Database.SaveResult saveResult : insertResults) {
                    if (!saveResult.isSuccess()) { //If there was an error
                    	errors.add(createError(saveResult, 'Unknown Object Type', saveResult.getId()));
                    	System.debug('****Putting key in errorMap: ' + sObjInsErrMAP.get(i));
                        errorMap.put(sObjInsErrMAP.get(i), saveResult.getErrors()[0].getMessage());
                    }
                    i++;
                }
            }
            
            //UPDATE
            if(updateResults != null && updateResults.size() > 0) {
                Integer i = 0;
                for(Database.SaveResult saveResult : updateResults) {
                    if (!saveResult.isSuccess()) { //If there was an error
                        errors.add(createError(saveResult, 'Unknown Object Type', saveResult.getId()));
                        System.debug('****Putting key in errorMap: ' + sObjUpdErrMAP.get(i));
                        errorMap.put(sObjUpdErrMAP.get(i), saveResult.getErrors()[0].getMessage());
                    }
                    i++;
                }
            }
            
            //DELETE
            if(deleteResults != null && deleteResults.size() > 0) {
                for(Database.DeleteResult result : deleteResults) {
                    
                }
            }
            
            //UNDELETE
            if(undeleteResults != null && undeleteResults.size() > 0) {
                for(Database.UndeleteResult result : undeleteResults) {
                    
                }
            }
            
            processErrorMap(errorMap);
            //Database.insert(errors, false);
        }
    }
    
    /**
     * Adds the errors to the matching trigger records.
     */
    private void processErrorMap(Map<String, String> errorMap) {
        
        if(errorMap != null && errorMap.size() > 0) {
            Integer i = 0;
            for (string strErrorId : errorMap.keySet()) {
                
                //One advantage of the TriggerHandler not being static is that each instance of it 
                //should have its own Trigger.now and Trigger.old available in its stack to be able 
                //to add errors to.
                if (strErrorId.isNumeric()) {
                	System.debug('****Numeric key in error map: ' + strErrorId);
                    i = integer.valueOf(strErrorID);
                    newList[i].addError(errorMap.get(strErrorID));
                } else {
                	System.debug('****Non-Numeric key in error map: ' + strErrorId);
                    if (trigger.isDelete) {
                        oldMap.get(strErrorID).addError(errorMap.get(strErrorID));
                    } else {
                        newMap.get(strErrorID).addError(errorMap.get(strErrorID));
                    }
                }
                i++;
            }
        }
    }
    
    public static void saveError(Exception e) {
    	if(DiagnosticsEnabled) {
	    	//if(!System.isFuture() && Limits.getFutureCalls() < Limits.getLimitFutureCalls()) {
	    	//	saveErrorFuture(e.getTypeName(), e.getMessage(), e.getStackTraceString(), System.now());
	    	//} else if(Limits.getDMLStatements() < Limits.getLimitQueries()) {
				Error__c error = new Error__c();
		        error.Datetime__c = System.now();        
		        error.Type__c = e.getTypeName();
		        error.Full_Message__c = e.getMessage();
		        error.Stack_Trace__c = e.getStackTraceString();
		        System.debug('****Saving error caused by exception');
		        insert error;
	    	//}
    	}
    }
    
    @future
    private static void saveErrorFuture(String typeName, String message, String stackTrace, Datetime now) {
        Error__c error = new Error__c();
        error.Datetime__c = now;        
        error.Type__c = typeName;
        error.Full_Message__c = message;
        error.Stack_Trace__c = stackTrace;
        insert error;
    } 

    public static void saveError(Database.SaveResult saveResult, String objectType, Id objId) {
    	if(DiagnosticsEnabled) {        
	        //if(!System.isFuture() && Limits.getFutureCalls() < Limits.getLimitFutureCalls()) {
	    	//   saveErrorFuture(System.now(), objectType, getRecordURL(saveResult.getId(), objId), 
	    	//        getStatusCode(saveResult.getErrors()[0].getStatusCode()), saveResult.getErrors()[0].getMessage());
	    	//} else if(Limits.getDMLStatements() < Limits.getLimitQueries()) {
	           Error__c error = new Error__c();
		       error.Datetime__c = System.now();
		       error.Object_Type__c = objectType;
		       error.Full_Message__c = saveResult.getErrors()[0].getMessage();
		       error.Error_Type__c = getStatusCode(saveResult.getErrors()[0].getStatusCode());
		       error.Record_URL__c = getRecordURL(saveResult.getId(), objId);        		
		       insert error;
	    	//}
    	}
    }
    
    @future
    private static void saveErrorFuture(Datetime now, String objectType, String recordURL, String status,
    String message) {
    	Error__c error = new Error__c();
	    error.Datetime__c = now;
        error.Object_Type__c = objectType;
        error.Full_Message__c = message;
        error.Error_Type__c = status;
        error.Record_URL__c = recordURL;
	    insert error;
    }
    
	public static Error__c createError(Exception e){
		Error__c error = new Error__c();
		error.Datetime__c = System.now();        
		error.Type__c = e.getTypeName();
		error.Full_Message__c = e.getMessage();
		error.Stack_Trace__c = e.getStackTraceString();
		return error;
	}

    public static Error__c createError(Database.SaveResult saveResult, string objectType, id objId){
        Error__c error = new Error__c();
        error.Datetime__c = System.now();
        error.Object_Type__c = objectType;   
        error.Record_URL__c = getRecordURL(saveResult.getId(), objId);
        error.Error_Type__c = getStatusCode(saveResult.getErrors()[0].getStatusCode());
        error.Full_Message__c = saveResult.getErrors()[0].getMessage();
        return error;
    }
    
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