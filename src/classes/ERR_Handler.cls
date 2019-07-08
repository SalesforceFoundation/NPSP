/*
    Copyright (c) 2014, Salesforce.org
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Salesforce.org nor the names of
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
* @author Salesforce.org
* @date 2014
* @description Helps determine if errors occurred during the DML operations performed during the transaction, and with
* the necessary storing and notification of these errors.
* @group ErrorHandling
* @group-content ../../ApexDocContent/ErrorHandling.htm
*/
public class ERR_Handler {

    private static final String STATUS_CODE_OTHER_VAL = 'Other';

    /*******************************************************************************************************
    * @description Inner class that groups the result of processing the result of multiple DML operations performed
    *              using the Database class.
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

    public class RecordErrors {
        private Map<String, Error__c> existingErrorsByRecordId = new Map<String, Error__c>();

        private String context;

        private Map<String, Error__c> insRecordErrors = new Map<String, Error__c>();
        private Map<String, Error__c> updRecordErrors = new Map<String, Error__c>();

        public RecordErrors (String context) {
            this.context = context;
        }

        public RecordErrors withExistingErrors(Map<String, Error__c> existingErrorsByRecordId) {
            this.existingErrorsByRecordId = existingErrorsByRecordId;
            return this;
        }

        public void retrieveExistingErrorsFor (List<SObject> sObjects) {
            Set<String> ids = new Set<String>();

            for (SObject so : sObjects) {
                ids.add((String)so.Id);
            }

            List<Error__c> errors = [Select     Id,
                                                Context_Type__c,
                                                Datetime__c,
                                                Error_Type__c,
                                                Full_Message__c,
                                                Object_Type__c,
                                                Record_Id__c,
                                                Record_URL__c,
                                                Retry_Pending__c
                                    from Error__c
                                    where      Record_Id__c in :ids and
                                                Context_Type__c = :context
                                    ];

            for (Error__c error : errors) {
                existingErrorsByRecordId.put(error.Record_Id__c, error);
            }
        }

        public Boolean isNewErrorsPresent() {
            return (!insRecordErrors.isEmpty() || !updRecordErrors.isEmpty());
        }

        private List<Error__c> getErrorsForInsert() {
            return this.insRecordErrors.values();
        }

        private List<Error__c> getErrorsForUpdate() {
            return this.updRecordErrors.values();
        }

        @testVisible private Error__c get(String recordId) {
            if (updRecordErrors.containsKey(recordId)) {
                return updRecordErrors.get(recordId);
            } else if (existingErrorsByRecordId.containsKey(recordId)) {
                return existingErrorsByRecordId.get(recordId);
            } else if (insRecordErrors.containsKey(recordId)) {
                return insRecordErrors.get(recordId);
            } else {
                return null;
            }
        }

        @testVisible private void put(String recordId, Error__c error) {
            if (error.Id != null) {
                updRecordErrors.put (recordId, error);
            } else {
                insRecordErrors.put (recordId, error);
            }
        }

        public void addError(String soId, Object dmlResult, SObject sObj) {
            if (!isDmlResultSuccess(dmlResult)) {
                // Checks to see if this in already in the Record Errors List
                Error__c err = this.get(soId);

                if (err == null) {
                    // Create Error record
                    err = createRecordError(
                        dmlResult,
                        (sObj != null) ? sObj.getSObjectType().getDescribe().getName() : null,
                        soId,
                        context
                    );
                } else {
                    // Existing Error associated with record exists, update.
                    err = updateRecordError(
                        err,
                        dmlResult
                    );
                }

                // Put into inserts or updates list, depending on requirements
                this.put(soId, err);
            }
        }

        public void addErrors(List<Object> dmlResults, List<Id> errorIdForSObject, List<SObject> sObjects) {
            if (dmlResults != null && !dmlResults.isEmpty()) {
                for(Integer i=0; i < dmlResults.size(); i++) {
                    addError(errorIdForSObject[i], dmlResults[i], sObjects[i]);
                }
            }
        }

        public void addError(String soId, String errorMessage, SObject sObj) {
            // Checks to see if this in already in the Record Errors List
            Error__c err = this.get(soId);

            if (err == null) {
                // Create Error record
                err = createRecordError(
                    errorMessage,
                    STATUS_CODE_OTHER_VAL,
                    (sObj != null) ? sObj.getSObjectType().getDescribe().getName() : null,
                    soId,
                    context
                );
            } else {
                // Existing Error associated with record exists, update.
                err = updateRecordError(
                    err,
                    errorMessage,
                    STATUS_CODE_OTHER_VAL
                );
            }

            // Put into inserts or updates list, depending on requirements
            this.put(soId, err);
        }

        public void addErrors(Map<String, String> errorMessagesByRecordId, Map<String, SObject> sObjects) {
            if (errorMessagesByRecordId != null && !errorMessagesByRecordId.isEmpty()) {
                for(String soId :errorMessagesByRecordId.keySet()) {
                    addError(soId, errorMessagesByRecordId.get(soId), sObjects.get(soId));
                }
            }
        }

        public void processErrors() {
            List<Error__c> errsForIns = getErrorsForInsert();
            if (errsForIns != null && !errsForIns.isEmpty()) {
                ERR_Handler.processErrors(errsForIns, context, true);

                // Refresh existing Errors Map
                refreshExistingErrorsMap(errsForIns);

                insRecordErrors.clear();
            }

            List<Error__c> errsForUpd = getErrorsForUpdate();
            if (errsForUpd != null && !errsForUpd.isEmpty()) {
                ERR_Handler.processErrors(errsForUpd, context, true);

                // Refresh existing Errors Map
                refreshExistingErrorsMap(errsForUpd);

                updRecordErrors.clear();
            }
        }

        private void refreshExistingErrorsMap(List<Error__c> errs) {
            for (Error__c err : errs) {
                this.existingErrorsByRecordId.put (err.Record_Id__c, err);
            }
        }

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
    * @return Errors Combined result of all the DML operations.
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

        if (insertErrors.errorsExist || updateErrors.errorsExist || deleteErrors.errorsExist || undeleteErrors.errorsExist) {
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
    *
    * @param dmlResults The results of a single DML operation performed using the Database class.
    * @param sObjects The records the DML operation was performed on.
    * @return Errors The errors that occurred during the DML operation performed using the Database class.
    */
    public static Errors getErrors(List<Object> dmlResults, List<SObject> sObjects) {
        Errors errors = new Errors();

        if (dmlResults == null || dmlResults.isEmpty()) {
            return errors;
        }
        for (Integer i=0; i<dmlResults.size(); i++) {
            if (!isDmlResultSuccess(dmlResults[i])) {
                errors.errorsExist = true;

                //Creating error object
                Error__c err = createError(
                    dmlResults[i],
                    sObjects[i].getSObjectType().getDescribe().getName(),
                    sObjects[i].Id,
                    null
                );
                errors.errorRecords.add(err);

                //We cannot use addError on the record here, because if we do, the whole transaction will be rolled back, and
                //no error record will be saved, or error notification sent.

                //Displaying an error message to the user
                if (ApexPages.currentPage() != null) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, err.Full_Message__c));
                }
            }
        }
        return errors;
    }

    /*******************************************************************************************************
    * @description Processes the results of a group DML operations caused by a batch, future, or queued job and performed
    * using the Database class to determine if errors occurred. It does not store errors or send error email
    * notifications. These operations should be performed after the rollback.
    *
    * @param dmlResults The results of a DML batch operation performed using the Database class.
    * @param sObjects The records the DML operation was performed on.
    * @return Errors The errors with a single list that occurred during a batch DML operation performed using the Database class.
    */
    public static Errors getJobErrors(List<Object> dmlResults, List<SObject> sObjects, String context) {
        Errors errors = new Errors();
        List<String> errorsFound = new List<String>();

        if (dmlResults != null) {
            for (Integer i=0; i<dmlResults.size(); i++) {

                Boolean isSuccess = isDmlSuccess(dmlResults[i]);

                if (!isSuccess) {
                    List<Database.Error> errList = getDmlResultErrors(dmlResults[i]);
                    List<String> errDetailsMessage = new List<String>();

                    for (Database.Error err : errList) {
                        errDetailsMessage.add(err.getStatusCode() + '- ' + ERR_ExceptionHandler.beautifyExceptionMessage(err.getMessage()));
                    }

                    String fullObjectErrMessage = sObjects[i].Id + ': ' + String.join(errDetailsMessage, '; ');

                    errorsFound.add(fullObjectErrMessage);
                }
            }
            if (errorsFound.size() > 0){
                String errorMessage = 'There were one more errors updating or inserting the following records: ' + '\n* ' + String.join(errorsFound, '\n* ');
                errors.errorsExist = true;

                String objectType = sObjects[0].getSObjectType().getDescribe().getName();
                Boolean match = areSObjectsSameType(sObjects);

                Error__c err = match ? createJobError(errorMessage, context, objectType): createJobError(errorMessage, context);

                errors.errorRecords.add(err);

                //We cannot use addError on the record here, because if we do, the whole transaction will be rolled back, and
                //no error record will be saved, or error notification sent.
            }
        }
        return errors;
    }

    /*******************************************************************************************************
    * @description Checks if a given DML operation has succeeded depending on the type of DML result.
    * @param Boolean true, if no errors are present
    */
    public static boolean isDmlSuccess(Object dmlResult) {
        return getDmlResultErrors(dmlResult).size() == 0;
    }

    /*******************************************************************************************************
    * @description Checks if a given DML operation has succeeded depending on the type of DML result.  Use the
    * isSuccess() method of the result.
    * @param Boolean true if isSuccess() was true
    */
    @testVisible private static boolean isDmlResultSuccess(Object dmlResult) {
        if (dmlResult instanceof Database.SaveResult) {
            return ((Database.SaveResult)dmlResult).isSuccess();
        } else if (dmlResult instanceof Database.DeleteResult) {
            return ((Database.DeleteResult)dmlResult).isSuccess();
        } else if (dmlResult instanceof Database.UndeleteResult) {
            return ((Database.UndeleteResult)dmlResult).isSuccess();
        }
        return true;
    }

    /*******************************************************************************************************
    * @description Retrieves errors from a DML operation depending on the type of DML result.
    * @param dmlResult The result of a DML batch operation performed using the Database class.
    * @return isSuccess Returns true if all DML operations passed successful; returns false if there was a DML exception.
    */
    public static List<Database.Error> getDmlResultErrors(Object dmlResult) {
        List<Database.Error> errList = new List<Database.Error>();

        if (dmlResult instanceof Database.SaveResult) {
            errList = ((Database.SaveResult)dmlResult).getErrors();
        } else if (dmlResult instanceof Database.DeleteResult) {
            errList = ((Database.DeleteResult)dmlResult).getErrors();
        } else if (dmlResult instanceof Database.UndeleteResult) {
            errList = ((Database.UndeleteResult)dmlResult).getErrors();
        }

        return errList;

    }
    /*******************************************************************************************************
    * @description Retrieves errors from a DML operation depending on the type of DML result.
    * @param sObjects List of generic sObjects
    * @return match Returns true if all objects are the same sObject type.
    */
    public static Boolean areSObjectsSameType(List<SObject> sObjects){
        Boolean match = true;

        Schema.SObjectType firstSObjectType = sObjects[0].getSObjectType();

        for (sObject s: sObjects){
            Schema.SObjectType nextSObjectType = s.getSObjectType();
            if (firstSObjectType != nextSObjectType){
                match = false;
                break;
            }
        }

        return match;

    }

    /*******************************************************************************************************
    * @description Creates an error record from an exception, stores it in the database (if enabled), and sends error
    *              notifications (if enabled).
                   This method should be used from inside the NPSP package, instead of the same one with that same name
                   that takes a String instead of an Enum as the second parameter.
    * @param e Exception to create error record from.
    * @param context The context the exception was raised on.
    */
    public static void processError(Exception e, ERR_Handler_API.Context context) {
        processError(e, context.name());
    }


    /*******************************************************************************************************
    * @description Creates an error record from an exception, stores it in the database (if enabled), and sends error
    *              notifications (if enabled).
    * @param e Exception to create error record from.
    * @param context The context the exception was raised on.
    */
    public static void processError(Exception e, String context) {
        if (e != null) {
            Error__c error = createError(e, context);
            processErrors(new Error__c[]{error}, context);
        }
    }


    /*******************************************************************************************************
    * @description Creates error records from passed in exceptions.
    *   If the Error Settings is enabled, errors are stored in the database.
    *   If the Error Settings has notification enabled, an email notificiation is sent.
    * @param exceptions List of exceptions.
    * @param context The context the exception was raised on.
    * @return void
    */
    public static void processErrors(List<Exception> exceptions, ERR_Handler_API.Context context) {
        List<Error__c> errors = new List<Error__c>();
        for (Exception e : exceptions) {
            errors.add(createError(e, context.name()));
        }

        processErrors(errors, context.name());
    }

    /*******************************************************************************************************
    * @description Stores errors in the database (if enabled), and sends error notifications (if enabled).
    * @param errorRecords The errors to store.
    * @param context The context the errors were raised on.
    * @return void
    */
    public static void processErrors(List<Error__c> errorRecords, String context) {
        processErrors(errorRecords, context, false);
    }

    /*******************************************************************************************************
    * @description Stores errors in the database (if enabled), and sends error notifications (if enabled).
    * @param errorRecords The errors to store.
    * @param context The context the errors were raised on.
    * @param ignoreStoreErrorsSetting Will overridethe Error Setting that controls whether Errors are stored or not.  There are certain errors that must be stored no matter what.
    * @return void
    */
    public static void processErrors(List<Error__c> errorRecords, String context, Boolean ignoreStoreErrorsSetting) {

        if (errorRecords != null && errorRecords.size() > 0) {
            if (ApexPages.currentPage() != null) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorRecords[0].Full_Message__c));
            }

            if (UTIL_CustomSettingsFacade.getErrorSettings().Store_Errors_On__c || ignoreStoreErrorsSetting) {
                List<Error__c> errsToInsert = new List<Error__c>();

                // Using Map to eliminate duplicate records from map
                Map<Id, Error__c> errsToUpdate = new Map<Id, Error__c>();

                for (Error__c err : errorRecords) {
                    if (err.Id == null) {
                        errsToInsert.add (err);
                    } else { // Looks like we need to update this error, not insert it
                        errsToUpdate.put (err.Id, err);
                    }
                }

                UTIL_Debug.debug('**** Storing errorRecords: ' + errorRecords);

                if (!errsToInsert.isEmpty()) { // New Errprs
                    Database.insert(errsToInsert, false);
                }
                if (!errsToUpdate.isEmpty()) { // Updated Errors
                    Database.update(errsToUpdate.values(), false);
                }
            }

            //ERR_Notifier takes care of checking the settings itself.
            ERR_Notifier.sendErrorNotifications(context);
        }
    }

    /*******************************************************************************************************
    * @description Creates an error record from an exception.
    * @param e Exception to create error record from.
    * @param context The context the exception was raised on.
    * @return Error__c Error record.
    */
    @testVisible private static Error__c createError(Exception e, String context) {
        Error__c error = new Error__c();
        error.Datetime__c = System.now();
        error.Error_Type__c = e.getTypeName();
        error.Full_Message__c = e.getMessage();
        error.Context_Type__c = context;

        //Putting it into a local string to see if that helps storing the stack trace when we
        //are in a managed package.
        String stackTrace = e.getStackTraceString();
        UTIL_Debug.debug('****Stack trace: ' + stackTrace);

        String message;
        if (String.isBlank(stackTrace) || stackTrace == '('+UTIL_Namespace.getNamespace()+')' || stackTrace == UTIL_Namespace.getNamespace()) {
            message = 'No stacktrace available at the time of saving the record. ';
        } else {
            message = 'Stacktrace available at the time of saving the record - ';
        }
        error.Stack_Trace__c = message + stackTrace;

        return error;
    }

    /*******************************************************************************************************
    * @description Creates an error record from the result of a DML operation performed through the Database class.
    * @param result The result of the Database DML operation. It cannot be more specific than Object, because the result of
    *               the different DML operations that the Database class can perform don't have a common parent.
    * @param objectType The name of the type of object that caused the error.
    * @param objId The id of the record that caused the error.
    * @param context The context the exception was raised on.
    * @return The error record.
    */
    private static Error__c createError(Object result, String objectType, Id objId, String context) {
        Error__c error = new Error__c();
        error.Datetime__c = System.now();
        error.Object_Type__c = objectType;
        error.Context_Type__c = context;

        if (result instanceof Database.SaveResult) {
            Database.SaveResult saveResult = (Database.SaveResult) result;
            error.Record_URL__c = getRecordURL(saveResult.getId(), objId);
            error.Error_Type__c = getStatusCode(saveResult.getErrors()[0].getStatusCode());
            error.Full_Message__c = saveResult.getErrors()[0].getMessage();
        } else if (result instanceof Database.DeleteResult) {
            Database.DeleteResult deleteResult = (Database.DeleteResult) result;
            error.Record_URL__c = getRecordURL(deleteResult.getId(), objId);
            error.Error_Type__c = getStatusCode(deleteResult.getErrors()[0].getStatusCode());
            error.Full_Message__c = deleteResult.getErrors()[0].getMessage();
        } else if (result instanceof Database.UndeleteResult) {
            Database.UndeleteResult undeleteResult = (Database.UndeleteResult) result;
            error.Record_URL__c = getRecordURL(undeleteResult.getId(), objId);
            error.Error_Type__c = getStatusCode(undeleteResult.getErrors()[0].getStatusCode());
            error.Full_Message__c = undeleteResult.getErrors()[0].getMessage();
        }
        UTIL_Debug.debug('**** createError() returns error: ' + error);
        return error;
    }

    /*******************************************************************************************************
    * @description Creates a error record associated with a specific context and record from the result of a DML
    * operation performed through the Database class.
    * @param result The result of the Database DML operation. It cannot be more specific than Object, because the result of
    *               the different DML operations that the Database class can perform don't have a common parent.
    * @param objectType The name of the type of object that caused the error.
    * @param objId The id of the record that caused the error.
    * @param context The context the exception was raised on.
    * @return The error record.
    */
    private static Error__c createRecordError(Object result, String objectType, Id objId, String context) {
        Error__c error = new Error__c();
        error.Datetime__c = System.now();
        error.Object_Type__c = objectType;
        error.Context_Type__c = context;
        error.Retry_Pending__c = true;

        Database.Error dmlError;

        if (result instanceof Database.SaveResult) {
            Database.SaveResult saveResult = (Database.SaveResult) result;
            dmlError = saveResult.getErrors()[0];
            error.Record_Id__c = (saveResult.getId() != null) ? saveResult.getId() : objId;
        } else if (result instanceof Database.DeleteResult) {
            Database.DeleteResult deleteResult = (Database.DeleteResult) result;
            dmlError = deleteResult.getErrors()[0];
            error.Record_Id__c = (deleteResult.getId() != null) ? deleteResult.getId() : objId;
        } else if (result instanceof Database.UndeleteResult) {
            Database.UndeleteResult undeleteResult = (Database.UndeleteResult) result;
            dmlError = undeleteResult.getErrors()[0];
            error.Record_Id__c = (undeleteResult.getId() != null) ? undeleteResult.getId() : objId;
        }

        error.Record_URL__c = getRecordURL(error.Record_Id__c);
        error.Error_Type__c = getStatusCode(dmlError.getStatusCode());
        error.Full_Message__c = updateFullMessage(error.Datetime__c, '', dmlError.getMessage());

        UTIL_Debug.debug('**** createRecordError() returns error: ' + error);
        return error;
    }

    /*******************************************************************************************************
    * @description Creates a error record associated with a specific context and record with the message
    * passed to the method.
    * @param message The full message of all the errors for a given job and compiled IDs.
    * @param statusCode The code associated with the error
    * @param objectType The name of the type of object that caused the error.
    * @param objId The id of the record that caused the error.
    * @param context The context the exception was raised on.
    * @return The error record.
    */
    private static Error__c createRecordError(String message, String statusCode, String objectType, Id objId, String context) {
        Error__c error = new Error__c();
        error.Datetime__c = System.now();
        error.Object_Type__c = objectType;
        error.Context_Type__c = context;
        error.Retry_Pending__c = true;

        error.Record_Id__c = objId;
        error.Record_URL__c = getRecordURL(error.Record_Id__c);
        error.Error_Type__c = statusCode;
        error.Full_Message__c = updateFullMessage(error.Datetime__c, '', message);
        return error;
    }

    /*******************************************************************************************************
    * @description Updates an existing error record associated with a specific context and record from the result of a DML
    * operation performed through the Database class.  Full_Message__c will be prepended with the latest message and timestamp, and
    * truncated to 5K.  The Error Type will be updated based on the StatusCode of the Result.  The Datetime field will be updated
    * to the current timestamp.  Retry_Pending__c will be set to true, indicated it should try the record again, if possible.
    * @param error The error record to be updated.
    * @param result The result of the Database DML operation. It cannot be more specific than Object, because the result of
    *               the different DML operations that the Database class can perform don't have a common parent.
    * @return The error record.
    */
    private static Error__c updateRecordError(Error__c error, Object result) {

        error.Datetime__c = System.now();
        error.Retry_Pending__c = true;

        Database.Error dmlError;

        if (result instanceof Database.SaveResult) {
            Database.SaveResult saveResult = (Database.SaveResult) result;
            dmlError = saveResult.getErrors()[0];
        } else if (result instanceof Database.DeleteResult) {
            Database.DeleteResult deleteResult = (Database.DeleteResult) result;
            dmlError = deleteResult.getErrors()[0];
        } else if (result instanceof Database.UndeleteResult) {
            Database.UndeleteResult undeleteResult = (Database.UndeleteResult) result;
            dmlError = undeleteResult.getErrors()[0];
        }

        error.Error_Type__c = getStatusCode(dmlError.getStatusCode());
        error.Full_Message__c = updateFullMessage(error.Datetime__c, '', dmlError.getMessage());

        return error;
    }

    /*******************************************************************************************************
    * @description Updates an existing error record associated with a specific context and record from the result of a DML
    * operation performed through the Database class.  Full_Message__c will be prepended with the latest message and timestamp, and
    * truncated to 5K.  The Error Type will be updated based on the StatusCode of the Result.  The Datetime field will be updated
    * to the current timestamp.  Retry_Pending__c will be set to true, indicated it should try the record again, if possible.
    * @param error The error record to be updated.
    * @param message The full message of all the errors for a given job and compiled IDs.
    * @param statusCode The code associated with the error
    * @return The error record.
    */
    private static Error__c updateRecordError (Error__c error, String message, String statusCode) {
        error.Datetime__c = System.now();
        error.Retry_Pending__c = true;
        error.Error_Type__c = statusCode;
        error.Full_Message__c = updateFullMessage(error.Datetime__c, '', message);

        return error;
    }

    /*******************************************************************************************************
    * @description For existing error records, it will concatenate the new message, and any existing text with a separator in between.
    * @param ts The timestamp the associated
    * @param context The context the exception was raised on.
    * @param objectType The type of all records in the job, only to be passed in if they all match.
    * @return The error record.
    */
    private static String updateFullMessage(Datetime ts, String existingMessage, String message) {

        String updatedMessage = ts.format() + ':\r\n' + message;

        if (String.isNotBlank(existingMessage)) {
            updatedMessage += '\r\n' + '========================================\r\n' + existingMessage;
            // Limit to 5K worth of Message History
            updatedMessage = updatedMessage.abbreviate(0, 5120);
        }

        return updatedMessage;
    }

    /*******************************************************************************************************
    * @description Creates a single error record from a Database class DML operation in a batch, future or queued job.
    * @param message The full message of all the errors for a given job and compiled IDs.
    * @param context The context the exception was raised on.
    * @param objectType The type of all records in the job, only to be passed in if they all match.
    * @return The error record.
    */
    private static Error__c createJobError(String message, String context, String objectType) {
        Error__c error = new Error__c();
        error.Datetime__c = System.now();
        error.Full_Message__c = message;
        error.Error_Type__c = 'Job Error';
        error.Object_Type__c = objectType;
        error.Context_Type__c = context;

        UTIL_Debug.debug('**** createBatchError() returns error: ' + error);
        return error;
    }

    /*******************************************************************************************************
    * @description Creates a single error record from a Database class DML operation in a batch, future or queued job.
    * @param message The full message of all the errors for a given job and compiled IDs.
    * @param context The context the exception was raised on.
    * @return The error record.
    */
    private static Error__c createJobError(String message, String context) {
        Error__c error = new Error__c();
        error.Datetime__c = System.now();
        error.Full_Message__c = message;
        error.Error_Type__c = 'Job Error';
        error.Context_Type__c = context;

        UTIL_Debug.debug('**** createBatchError() returns error: ' + error);
        return error;
    }

    /*******************************************************************************************************
    * @description Returns the URL of a record, if available.
    * @param saveResultId The id resulting from a DML operation of the Database class.
    * @param objId The id of the record the DML operation was performed on.
    * @return The URL of the record. Warning: it may not necessarily be valid.
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
    * @description Returns the URL of a record, if available.
    * @param recordId The id of the record associated with the error
    * @return The URL of the record. Warning: it may not necessarily be valid.
    */
    private static String getRecordURL(String recordId) {
        String recordURL = URL.getSalesforceBaseUrl().toExternalForm() + '/' + recordId;

        if (recordURL.startsWith('http:'))
            recordURL = recordURL.replaceFirst('http:', 'https:');

        return recordURL;
    }

    /*******************************************************************************************************
    * @description Returns the ID of the object the error is about if available.
    * @param error. The Error object.
    * @return ID the object's Id if available, otherwise null.
    */
    public static ID getErrorObjectId(Error__c error) {
        if (error.Record_URL__c != null) {
            return error.Record_URL__c.substringAfterLast('/');
        }
        return null;
    }

    /*******************************************************************************************************
    * @description Returns the status of the error that happened as a result of a DML operation performed through
    *              the Database class as a string.
    * @param status The status code.
    * @return The error status as a string.
    */
    private static String getStatusCode(system.StatusCode status) {
        if (status == system.Statuscode.REQUIRED_FIELD_MISSING)
            return 'Required Field Missing';
        else if (status == system.Statuscode.FIELD_CUSTOM_VALIDATION_EXCEPTION)
            return 'Custom Validation Rule Failed';
        else
            return STATUS_CODE_OTHER_VAL;
    }
}