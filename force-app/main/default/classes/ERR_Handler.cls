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
    * @description Constructs errors for records that failed in the DML operation.
    * Errors are displayed on a page.
    *
    * @param dmlResults The results of a single DML operation performed using the Database class.
    * @param sObjects The records the DML operation was performed on.
    * @return Errors The errors that occurred during the DML operation performed using the Database class.
    */
    public static Errors getErrors(List<Object> dmlResults, List<SObject> sObjects) {
        return getErrors(dmlResults, sObjects, true);
    }

    /*******************************************************************************************************
    * @description Constructs errors for records that failed in the DML operation.
    * Errors are not displayed on a page.
    *
    * @param dmlResults The results of a single DML operation performed using the Database class.
    * @param sObjects The records the DML operation was performed on.
    * @return Errors The errors that occurred during the DML operation performed using the Database class.
    */
    public static Errors getErrorsOnly(List<Object> dmlResults, List<SObject> sObjects) {
        return getErrors(dmlResults, sObjects, false);
    }

    /*******************************************************************************************************
    * @description Processes the results of a single DML operation performed using the Database class to determine
    *              if errors occurred. It does not store errors or send error email notifications. These operations
    *              should be performed after the rollback.
    *
    * @param dmlResults The results of a single DML operation performed using the Database class.
    * @param sObjects The records the DML operation was performed on.
    * @param displayErrors Indicates if errors should be displayed on a page
    * @return Errors The errors that occurred during the DML operation performed using the Database class.
    */
    private static Errors getErrors(List<Object> dmlResults, List<SObject> sObjects, Boolean displayErrors) {
        Errors errors = new Errors();

        if (dmlResults == null || dmlResults.isEmpty()) {
            return errors;
        }
        for (Integer i=0; i<dmlResults.size(); i++) {
            Boolean isSuccess = true;
            if (dmlResults[i] instanceof Database.SaveResult) {
                isSuccess = ((Database.SaveResult)dmlResults[i]).isSuccess();
            } else if (dmlResults[i] instanceof Database.DeleteResult) {
                isSuccess = ((Database.DeleteResult)dmlResults[i]).isSuccess();
            } else if (dmlResults[i] instanceof Database.UndeleteResult) {
                isSuccess = ((Database.UndeleteResult)dmlResults[i]).isSuccess();
            }

            if (!isSuccess) {
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
                if (displayErrors && ApexPages.currentPage() != null) {
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
    * @param dmlResult The results of a DML batch operation performed using the Database class.
    */
    public static boolean isDmlSuccess(Object dmlResult) {
        return getDmlResultErrors(dmlResult).size() == 0;
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
    * @description Creates an error record from an exception, and return the error collection
                   This method should be used from inside the NPSP package, instead of the same one with that same name
                   that takes a String instead of an Enum as the second parameter.
    * @param e Exception to construct error record from.
    * @param context The context the exception was raised on.
    */
    public static Errors getErrorsOnly(Exception e, ERR_Handler_API.Context context) {
        Errors errors = new Errors();
        errors.errorsExist = true;
        errors.errorRecords.add(createError(e, context.name()));

        return errors;
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
    * @description Creates an error record from a String, stores it in the database (if enabled), and sends error
    *              notifications (if enabled).
    * @param msg
    * @param context The context the exception was raised on.
    */
    public static void processError(String msg, String context) {
        if (msg != null) {
            Error__c error = createError(msg, context);
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
    * Display message on the current Visualforce page (if any).
    *
    * @param errorRecords The errors to store.
    * @param context The context the errors were raised on.
    * @return void
    */
    public static void processErrors(List<Error__c> errorRecords, String context) {

        if (errorRecords != null && errorRecords.size() > 0) {
            if (ApexPages.currentPage() != null) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorRecords[0].Full_Message__c));
            }

            if (UTIL_CustomSettingsFacade.getErrorSettings().Store_Errors_On__c) {
                UTIL_Debug.debug('**** Storing errorRecords: ' + errorRecords);
                Database.insert(errorRecords, false);
            }

            //ERR_Notifier takes care of checking the settings itself.
            ERR_Notifier.sendErrorNotifications(context);
        }
    }

    /*******************************************************************************************************
    * @description Stores errors in the database (if enabled), and sends error notifications (if enabled).
    * @param errorResult The error result
    * @param context The context the errors were raised on.
    * @return void
    */
    public static void processErrorsOnly(Errors errorResult, String context) {
        if (errorResult == null || errorResult.errorsExist != true) {
            return;
        }

        for (Error__c error : errorResult.errorRecords) {
            if (String.isBlank(error.Context_Type__c)) {
                error.Context_Type__c = context;
            }
        }

        processErrorsOnly(errorResult.errorRecords, context);
    }

    /*******************************************************************************************************
    * @description Stores errors in the database (if enabled), and sends error notifications (if enabled).
    * @param errorRecords The errors to store.
    * @param context The context the errors were raised on.
    * @return void
    */
    public static void processErrorsOnly(List<Error__c> errorRecords, String context) {
        if (errorRecords == null || errorRecords.isEmpty()) {
            return;
        }

        if (UTIL_CustomSettingsFacade.getErrorSettings().Store_Errors_On__c || isRD2MigrationContext(context)) {
            Database.insert(errorRecords, false);
        }

        ERR_Notifier.sendErrorNotifications(context);
    }

    /*******************************************************************************************************
    * @description Stores errors in the database (if enabled), do not generate apex page messages and sends error notifications (if enabled).
    * @param errorRecords The errors to store.
    * @param context The context the errors were raised on.
    * @return void
    */
    public static void sendErrorNotification(Exception e, String context) {
        if (e == null) {
            return;
        }

        Error__c error = createError(e, context);
        processErrorsOnly(new List<Error__c>{ error }, context);
    }

    /***
    * @description returns true if this method is calling from data migration
    * or validate migration context
    * @param The context the errors were raised on.
    * @returns Boolean
    */
    public static Boolean isRD2MigrationContext(String context) {
        return String.isNotBlank(context)
            && (
                context.contains(RD2_DataMigrationBase_BATCH.LOG_CONTEXT_DRY_RUN)
                || context.contains(RD2_DataMigrationBase_BATCH.LOG_CONTEXT_MIGRATION)
            );
    }

    /*******************************************************************************************************
    * @description Creates an error record from a String message
    * @param msg The message to record.
    * @param context The context the exception was raised on.
    * @return Error__c Error record.
    */
    @TestVisible
    private static Error__c createError(String msg, String context) {
        Error__c error = new Error__c();
        error.Datetime__c = System.now();
        error.Error_Type__c = System.Label.errErrorTypeOther;
        error.Full_Message__c = msg;
        error.Context_Type__c = context;


        return error;
    }

    /*******************************************************************************************************
    * @description Creates an error record from an exception.
    * @param e Exception to create error record from.
    * @param context The context the exception was raised on.
    * @return Error__c Error record.
    */
    @TestVisible
    private static Error__c createError(Exception e, String context) {
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

        Id recordId = null;

        if (result instanceof Database.SaveResult) {
            Database.SaveResult saveResult = (Database.SaveResult) result;
            recordId = (saveResult.getId() != null) ? saveResult.getId() : objId;
            error.Error_Type__c = getStatusCode(saveResult.getErrors()[0].getStatusCode());
            error.Full_Message__c = saveResult.getErrors()[0].getMessage();
        } else if (result instanceof Database.DeleteResult) {
            Database.DeleteResult deleteResult = (Database.DeleteResult) result;
            recordId = (deleteResult.getId() != null) ? deleteResult.getId() : objId;
            error.Error_Type__c = getStatusCode(deleteResult.getErrors()[0].getStatusCode());
            error.Full_Message__c = deleteResult.getErrors()[0].getMessage();
        } else if (result instanceof Database.UndeleteResult) {
            Database.UndeleteResult undeleteResult = (Database.UndeleteResult) result;
            recordId = (undeleteResult.getId() != null) ? undeleteResult.getId() : objId;
            error.Error_Type__c = getStatusCode(undeleteResult.getErrors()[0].getStatusCode());
            error.Full_Message__c = undeleteResult.getErrors()[0].getMessage();
        }

        error.Related_Record_ID__c = recordId;
        error.Record_URL__c = getRecordURL(recordId);

        UTIL_Debug.debug('**** createError() returns error: ' + error);
        return error;
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
    public static String getRecordURL(Id saveResultId, Id objId) {
        Id recordId = (saveResultId != null) ? saveResultId : objId;

        return getRecordURL(recordId);
    }

    /*******************************************************************************************************
    * @description Returns the URL of a record, if available.
    * @param recordId The id of the record the DML operation was performed on.
    * @return The URL of the record. Warning: it may not necessarily be valid.
    */
    public static String getRecordURL(String recordId) {

        return (recordId != null) ? URL.getSalesforceBaseUrl().toExternalForm().replaceFirst('http:', 'https:') + '/' + recordId : null;

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
    public static String getStatusCode(system.StatusCode status) {
        if (status == system.Statuscode.REQUIRED_FIELD_MISSING) {
            return System.Label.errErrorTypeRequiredFieldMissing;
        } else if (status == system.Statuscode.FIELD_CUSTOM_VALIDATION_EXCEPTION) {
            return System.Label.errErrorTypeValidationFailed;
        } else {
            return System.Label.errErrorTypeOther;
        }
    }
}
