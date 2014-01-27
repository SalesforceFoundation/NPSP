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
public with sharing class ERR_Handler {

    public static Boolean storeErrors = null;
    public static Boolean sendEmailNotifications = null;
    public static String mailList = null;
    
    private List<Error__c> errors = new List<Error__c>();
    
    public enum Context {AFFL, BDE, CON, HH, LD, OPP, PMT, REL, RD, RLLP, STTG, TDTM}
    
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
        
        if(storeErrors == null || sendEmailNotifications == null)
            setOrgSettings();
            
        Boolean errorsExist = false;
        	
    	Boolean errorsExistOnInserts = processResults(insertResults, objectsToInsert);  //Insert
    	Boolean errorsExistOnUpdates = processResults(updateResults, objectsToUpdate);  //Update
    	Boolean errorsExistOnDeletes = processResults(deleteResults, objectsToDelete);  //Delete
    	Boolean errorsExistOnUndeletes = processResults(undeleteResults, objectsToUndelete);  //Undelete
    	
    	if(errorsExistOnInserts || errorsExistOnUpdates || errorsExistOnDeletes || errorsExistOnUndeletes) {
    		errorsExist = true;
    	}
    	
    	/*** We do NOT want to call storeErrors here. We want to be able to manually do that after a rollback.
    	if(storeErrors)
    	   storeErrors(); ***/
    	
    	if(SendEmailNotifications)
    	   sendEmailNotifications(context);
    	
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
    public static void processError(Exception e, ERR_Handler.Context context) {
        processError(e, new List<SObject>(), context);
    }
    
    public static void processError(Exception e, SObject record, ERR_Handler.Context context) {
    	processError(e, new SObject[]{record}, context);
    }
    
    public static void processError(Exception e, List<SObject> records, ERR_Handler.Context context) {
    	
    	if(storeErrors == null || sendEmailNotifications == null)
            setOrgSettings();
    	
    	if(e != null) {
			if(e instanceof DmlException && records != null && records.size() > 0) {
                DmlException de = (DmlException) e;
                for(Integer i=0; i<de.getNumDml(); i++) {
                   System.debug(LoggingLevel.WARN, '****Position of failed record in original list: ' + de.getDmlIndex(i));
                   Integer failedRecordIndex = de.getDmlIndex(i); //Position of failed record in original list
                   addErrorMessage(records[failedRecordIndex], de.getDmlMessage(i));
               }
           }
           
           if(storeErrors) {
               Error__c error = createError(e);
               Database.SaveResult result = Database.insert(error, false);
               System.debug(LoggingLevel.WARN, '****Error record: ' + JSON.serializePretty(error));
           }
    	}
    	
    	if(SendEmailNotifications)
    	   sendEmailNotifications(context);
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
    
    /*** NOTE: we want this method to be public to be able to explicitly call it after a rollback. ***/
    public void storeErrors() {
    	if(storeErrors == null)
            setOrgSettings();
            
        if(storeErrors) {
		  System.debug(LoggingLevel.WARN, '****Storing errors: ' + JSON.serializePretty(errors));
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
    
    /** Email methods **/
    public static void sendEmailNotifications(ERR_Handler.Context context) {
        if(context != null && context == ERR_Handler.Context.RD) {
            if (!system.isBatch() && !RD_ProcessControl.batchButton && !system.isFuture()) {
                ERR_Handler.sendErrorQueueEmailNotificationFuture();
            } else if (system.isFuture()){
                ERR_Handler.sendErrorQueueEmailNotification();
            }  
        }	
    }
    
    @future
    public static void sendErrorQueueEmailNotificationFuture(){sendErrorQueueEmailNotification();}
    
    public static void sendErrorQueueEmailNotification(){
        map<Id, Error__c> rdeqMap = new Map<Id, Error__c>([select Id, Record_URL__c, Full_Message__c from Error__c]);
        
        if(SendEmailNotifications == null)
            setOrgSettings();
        
        if (!rdeqMap.isEmpty()){
            Messaging.SingleEmailMessage sme = createEmailMessage(rdeqMap.values());
            if (!test.isRunningTest())
                Messaging.sendEmail(new Messaging.SingleEmailMessage[]{sme});
        }
        //clear the queue if not in a batch, otherwise, save them 
        if (!system.isBatch() && !RD_ProcessControl.batchButton)           
           delete [select id from Error__c];
    } 

    private static Messaging.SingleEmailMessage createEmailMessage(list<Error__c> rdeqList){
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setUseSignature(false);
        mail.setSenderDisplayName('Salesforce Recurring Donations');
        mail.setSubject('Salesforce Recurring Donations Errors');
        string bodyString = '';
        bodyString += system.label.npe03.RecurringDonationErrorEmailBody;
        bodyString += '\n\nErrors:';
        for (Error__c rdeq : rdeqlist){
            bodyString += '\n' + rdeq.Record_URL__c;
            bodystring += ' Error Message: ' + rdeq.Full_Message__c;           
        }        
        mail.setPlainTextBody(bodyString);
        list<string> sendList = new list<string>();
        //user, sysadmins or PG
        if(mailList == null)
            setOrgSettings();
        
        if (mailList.startsWith('005')) {
            sendList.add([select email from User where id = :mailList].email);
        } else if(mailList == 'All Sys Admins'){
            list<User> sysadminlist = [select email from User where User.Profile.Name = 'System Administrator'];
            for (User u : sysadminlist) {
                sendList.add(u.email);              
            }           
        } else if(mailList.startsWith('00G')) {
            list<GroupMember> groupUsers = [select g.UserOrGroupId from GroupMember g where GroupId = :mailList];
            set<id> userIDs = new set<id>();
            for (GroupMember g : groupUsers)
               userIDs.add(g.UserOrGroupId);
            list<User> userList = [select email from User where id IN :userIDs];
            for (User u : userList){
                sendList.add(u.email);
            }
        }        
        mail.setToAddresses(sendList);                   

        return mail;        
    }
    
    /*** Helper methods ***/
    private static void setOrgSettings() {
    	Error_Settings__c orgErrorSettings = Error_Settings__c.getOrgDefaults();
    	storeErrors = orgErrorSettings.Store_Errors__c;
    	SendEmailNotifications = orgErrorSettings.Email_Notifications__c;
    	mailList = orgErrorSettings.Email_List__c;
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
    
    /*** Future methods - not yet used 
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
    }***/
}