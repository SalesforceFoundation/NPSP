/*
    Copyright (c) 2013, Salesforce.org
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
* @group TDTM
* @group-content ../../ApexDocContent/TDTM.htm
* @description Class called from each of the triggers (only one per object) that follow the TDTM design. It's in 
* charge of figuring out which of the classes that do the actual work need to be called, and calling them.
*/
public class TDTM_TriggerHandler {

    public static Boolean suppressDebugAssertAfterErrorLogging = false;
    public static Boolean disableTDTM = false;

    @TestVisible
    private static Boolean isCompactLoggingEnabled = true;
    @TestVisible
    private static Boolean isMonitoringEnabled = false;

    private static Boolean defaultRecordsInserted = false;
    public static ServiceMonitor Monitor {
        get {
            if (Monitor == null) {
                Monitor = new ServiceMonitor(isCompactLoggingEnabled);
            }
            return Monitor;
        }
        set;
    }

    /*******************************************************************************************************
    * @description Method to be called from each of the triggers (only one per object) that follow the TDTM 
    * design. Figures out which classes need to be called, and calls them.
    * @param isBefore Are we in a before trigger context.
    * @param isAfter Are we in an after trigger context.
    * @param isInsert Did the trigger run in response to an insert operation.
    * @param isUpdate Did the trigger run in response to an update operation.
    * @param isDelete Did the trigger run in response to a delete operation.
    * @param isUnDelete Did the trigger run in response to an undelete operation.
    * @param newList The records that were passed to the trigger as trigger.new.
    * @param oldList The records that were passed to the trigger as trigger.old.
    * @param describeObj The type of SObject the class runs for.
    * @param triggerHandlerRepo The class that is going to retrieve all the TDTM records.
    * @return void
    */
    public static void run(
            TriggerContext context,
            TDTM_iTableDataGateway triggerHandlerRepo
    ) {

        if (disableTDTM) {
            UTIL_Debug.debug(LoggingLevel.WARN, '****TDTM Disabled: no triggers will run for this transaction.');
            return;
        }

        if (context.records != null) {
            UTIL_Debug.debug(LoggingLevel.WARN, '****Trigger.new size: ' + context.records.size());
        }

        DescribeSObjectResult describeSObjectResult = UTIL_Describe.getObjectDescribe(context.getSObjectType());
        UTIL_Debug.debug(LoggingLevel.WARN, '****ACTION: ' + context.action() + ' on ' +
                describeSObjectResult.getLabel());

        TDTM_Runnable.DmlWrapper dmlWrapper = new TDTM_Runnable.DmlWrapper();

        // If there are no records, insert the defaults.
        if (!defaultRecordsInserted && triggerHandlerRepo.isEmpty()) {
            // We will not insert the default records when Triggered by the User object to prevent MixedDML errors
            if (context.getSObjectType() == User.sObjectType) {
                return;
            }

            List<Trigger_Handler__c> defaultConfig = TDTM_DefaultConfig.getDefaultRecords();
            // Rather than insert the records in unit tests, just populate the static list
            // However to prevent any conflicts with our customers unit tests, always insert the records
            // if this is a test running in the full managed package code in a customer org.
            if (!Test.isRunningTest() || (Test.isRunningTest() && UTIL_Namespace.isCustomerOrg())) {
                insert defaultConfig;
            } else {
                TDTM_ObjectDataGateway.setDefaultHandlers(defaultConfig);
            }
            defaultRecordsInserted = true;
        }

        // Get the trigger handlers to run. Note that we are using the local object name, so
        // it works for objects
        // from Cumulus both in the package and unmanaged dev orgs.
        String objectDescribeLocalName = describeSObjectResult.getLocalName();
        TriggerHandlers triggerHandlersToRun =
                new TriggerHandlers(
                        triggerHandlerRepo.getClassesToCallForObject(
                                objectDescribeLocalName,
                                context.action()
                        )
                );
//        UTIL_Debug.debug(LoggingLevel.WARN, '****Classes To Call for ' + UTIL_Describe
//        .getObjectDescribe(context.getSObjectType())
//        .getLocalName()
//        + ': ' + JSON.serializePretty(classesToCall));

        // fixup our trigger lists to deal with workflow rules
        context.fixupOldList();

        if (triggerHandlersToRun.getRecords() != null && triggerHandlersToRun.getRecords().size() > 0) {
            //Run the relevant classes
            for (TriggerHandler triggerHandler : triggerHandlersToRun.getTriggerHandlers()) {
                if (isMonitoringEnabled) {
                    monitor.startMonitoring(triggerHandler.className(), context.action().name());
                }

                TDTM_Runnable.DmlWrapper dmlWrapperResponse = new TDTM_Runnable.DmlWrapper();
                try {
                    dmlWrapperResponse = runClass(triggerHandler, context, dmlWrapper);
                } catch (Exception ex) {
                    handleException(context.records, context.existingRecords, ex);
                }

                if (isMonitoringEnabled) {
                    monitor.stopMonitoring(triggerHandler, context);
                }

                updateDmlWrapperWithTriggerResponse(dmlWrapper, dmlWrapperResponse);

                UTIL_Debug.debugWithInfo('****Finished executing: ' + triggerHandler.className() + ' ' +
                        'for ' +
                    context.getSObjectType() + ': ' + context.action());
            }
            //Process the result
            if (dmlWrapper != null) {
                try {
                    processDML(dmlWrapper);
                } catch (Exception ex) {
                    handleException(context.records, context.existingRecords, ex);
                }
            }

            if (isMonitoringEnabled) {
                TriggerHandlerRunResults results = monitor.getResults();
                results.isCompactLoggingEnabled = isCompactLoggingEnabled;
                results.logTriggerHandlerInfo();
                results.logResults();
                results.printStack();
            }
        }
    }

    /*******************************************************************************************************
    * @description Performs pending DML operations, on the records stored in the DMLWrapper that it gets as parameter.
    * We want this method to be static so that it can be called from the future method in TDTM_Runnable.
    * @param dmlWrapper The class that contains the records that need to have DML performed on.
    * @return void
    */
    public static void processDML(TDTM_Runnable.DmlWrapper dmlWrapper) {
        processDMLAllOrNothing(dmlWrapper, true);
    }

    /*******************************************************************************************************
    * @description Performs pending DML operations, on the records stored in the DMLWrapper that it gets as parameter.
    * We want this method to be static so that it can be called from the future method in TDTM_Runnable.
    * @param dmlWrapper The class that contains the records that need to have DML performed on.
    * @param allOrNothing whether all objects must save successfully.  if true, and there is an error, an exception
    * will be thrown.  If false, then inspect the error collection to see what failed
    * @return Errors Object with list of Error objects
    */

    public static ERR_Handler.Errors processDMLAllOrNothing(TDTM_Runnable.DmlWrapper dmlWrapper, Boolean allOrNothing) {
        if (dmlWrapper == null) {
            return null;
        }

        dmlWrapper.groupByType(); //sort thyself!

        /**We keep the Database methods with the opt_allOrNone flag set to false to be able to alert the client
        process of all the errors that occurred in the context **/
        List<Database.SaveResult> insertResults;
        if (!dmlWrapper.objectsToInsert.isEmpty()) {
            insertResults = UTIL_DMLService.insertRecords(dmlWrapper.objectsToInsert, allOrNothing);
        }
        List<Database.SaveResult> updateResults;
        if (!dmlWrapper.objectsToUpdate.isEmpty()) {
            updateResults = UTIL_DMLService.updateRecords(dmlWrapper.objectsToUpdate, allOrNothing);
        }
        List<Database.DeleteResult> deleteResults = Database.delete(dmlWrapper.objectsToDelete, allOrNothing);
        List<Database.UndeleteResult> undeleteResults = Database.undelete(dmlWrapper.objectsToUndelete, allOrNothing); //Not yet using this one, afaik, but no reason not to support it.

        //@TODO: We cannot support upsert because you cannot do upsert on SObject. You have to specify the actual type.
        //Also, should we support Database.merge?

        //Process the results.
        ERR_Handler.Errors errors = ERR_Handler.getErrors(insertResults, updateResults, deleteResults, undeleteResults,
                dmlWrapper.objectsToInsert, dmlWrapper.objectsToUpdate, dmlWrapper.objectsToDelete,
                dmlWrapper.objectsToUndelete);

        return errors;
    }

    private static void handleException(List<SObject> newList, List<SObject> oldList, Exception ex) {
        //use the correct list
        List<SObject> populatedList = newList == null || newList.isEmpty() ? oldList : newList;
        //if we're only doing DML on one object and the caught exception is handled,
        //trap the error and add the message to the page.
        if (populatedList.size() == 1 && ERR_ExceptionHandler.isHandledException(ex)) {
            ERR_ExceptionHandler.beautifyExceptionMessage(ex);
            populatedList[0].addError(ex);
            return;
        } else {
            throw ex;
        }
    }

    /*******************************************************************************************************
     * @description Given a specific TriggerHandler record linked to the current trigger event, execute the
     * specified class based on the type of class instance it represents.
     * @param classToRunRecord Trigger_Handler__c record
     * @param newList Collection of Trigger.New
     * @param oldList Collection of Trigger.Old
     * @param thisAction Trigger Event (Insert, Update, Delete, ...)
     * @param describeObj SObjectDescribe of the target object
     * @param dmlWrapper The DmlWrapper instance for the current processing
     * @return An updated DML Wrapper instance (or null)
     */
    private static TDTM_Runnable.DmlWrapper runClass(TriggerHandler triggerHandler,
            TriggerContext context, TDTM_Runnable.DmlWrapper dmlWrapper) {
        Type classType = getTypeForClassNamed(triggerHandler.className());
        if (classType == null) {
            UTIL_Debug.debug(LoggingLevel.WARN, '****ClassType was null.');
            return dmlWrapper;
        }

        Object classInstance = classType.newInstance();
        //The objects we create dynamically need to implement the TDTM_Runnable interface
        if (classInstance instanceof TDTM_Runnable) {
            TDTM_Runnable classToRun = (TDTM_Runnable) classInstance;

            //A class can only run asynchronously (calling a future) if we have the ids of the
            //records we want to affect. This means we can only run it for after in insert.
            //Also,a future cannot be called from a future or batch method.
            if (triggerHandler.isAsync() && !context.isBefore() && canRunAsync()) {
                reportDebugMessageAsync(triggerHandler, context);

                runAsync(classToRun, triggerHandler.className(), context);
            } else {
                reportDebugMessageSync(triggerHandler, context);

                return classToRun.run(context);
            }
        } else if (classInstance instanceof TDTM_RunnableMutable) {
            // alternatively, objects created dynamically can implement the TDTM_RunnableMutable
            // interface if the class intends to directly modify the global DmlWrappper
            TDTM_RunnableMutable classToRun = (TDTM_RunnableMutable) classInstance;

            reportDebugMessageWithInfo(triggerHandler, context);

            // we do not check whether class is identified as Asynchronous__c because the
            // underlying assumption to mutating DmlWrapper is that the class modifies
            // the collection directly, and TDTM_TriggerHandler.run will perform DML on
            // whatever exists in the collection after iterating through all classes to run
            classToRun.run(context, dmlWrapper);
        } else {
            UTIL_Debug.debug(LoggingLevel.WARN, '****The class does not implement the required interface.');
        }

        return null;
    }

    private static void reportDebugMessageWithInfo(TriggerHandler triggerHandler, TriggerContext context) {
        UTIL_Debug.debugWithInfo('****Calling synchronously: ' + triggerHandler.className() + ' for ' +
                context.getSObjectType() + ': ' + context.action() +
                ' ' +
                'with ' + (context.records != null ? context.records : context.existingRecords).size() + ' records');
    }

    private static void reportDebugMessageSync(TriggerHandler triggerHandler,TriggerContext context) {
        UTIL_Debug.debug(LoggingLevel.WARN, '****Calling synchronously: ' + triggerHandler.className() + ' for ' +
                context.getSObjectType() + ': ' + context.action() +
                '' +
                ' ' +
                'with ' +
                getRecords(context).size() + ' records');
    }

    private static void reportDebugMessageAsync(TriggerHandler triggerHandler, TriggerContext context) {
        UTIL_Debug.debug(LoggingLevel.WARN, '****Calling asynchronously: ' + triggerHandler.className() + ' for ' +
                context.getSObjectType() + ': ' + context.action() +
                '' +
                ' ' +
                'with ' +
                getRecords(context).size() + ' records');
    }

    private static List<SObject> getRecords(TriggerContext context) {
        return (context.records != null ?
                context.records : context.existingRecords);
    }

    private static Boolean canRunAsync() {
        return (!System.isFuture() && !System.isBatch());
    }

    private static Map<String, Type> typeMap = new Map<String, Type>();
    private static Type getTypeForClassNamed(String str) {
        str = str.toLowerCase();
        if (typeMap.get(str) == null) {
            Type typeInst = Type.forName(str);
            typeMap.put(str, typeInst);
        }
        return typeMap.get(str);
    }

    /*******************************************************************************************************
     * @description Given a specific TriggerHandler record linked to the current trigger event, execute the
     * specified class based on the type of class instance it represents.
     * @param classToRun Instance of class that implements the TDTM_Runnable interface
     * @param classToRunName The name of the class to be executed
     * @param newList Collection of Trigger.New
     * @param oldList Collection of Trigger.Old
     * @param thisAction Trigger Event (Insert, Update, Delete, ...)
     * @param describeObj SObjectDescribe of the target object
     */
    private static void runAsync(TDTM_Runnable classToRun, String classToRunName,
            TriggerContext context) {

       Set<Id> setNewId;
       if (context.records != null) {
           Map<Id,SObject> nm = new Map<Id,SObject>(context.records);
           setNewId = new Set<Id>(nm.keySet());
       }

       Set<Id> setOldId;
       if (context.existingRecords != null) {
           Map<Id,SObject> om = new Map<Id,SObject>(context.existingRecords);
           setOldId = new Set<Id>(om.keySet());
       }

       classToRun.runFutureNonStatic(setNewId, setOldId, context.action().name(),
               String.valueOf(context.getSObjectType()), classToRunName);
    }

    /**
     * @description Combine the DmlWrapper instance returned from an individual TriggerHandler run() call into
     * the DmlWrapper instance for the entire TriggerHandler.run() method.
     * @param dmlWrapper The shared instance
     * @param dmlWrapperLocal The single instance returned from a TriggerHandler call.
     */
    private static void updateDmlWrapperWithTriggerResponse(TDTM_Runnable.DmlWrapper dmlWrapper, TDTM_Runnable.DmlWrapper dmlWrapperLocal) {
        if (dmlWrapperLocal == null) {
            return;
        }
        if (dmlWrapperLocal.objectsToInsert != null && !dmlWrapperLocal.objectsToInsert.isEmpty()) {
            dmlWrapper.objectsToInsert.addAll(dmlWrapperLocal.objectsToInsert);
        }
        if (dmlWrapperLocal.objectsToUpdate != null && !dmlWrapperLocal.objectsToUpdate.isEmpty()) {
            dmlWrapper.objectsToUpdate.addAll(dmlWrapperLocal.objectsToUpdate);
        }
        if (dmlWrapperLocal.objectsToDelete != null && !dmlWrapperLocal.objectsToDelete.isEmpty()) {
            dmlWrapper.objectsToDelete.addAll(dmlWrapperLocal.objectsToDelete);
        }
        if (dmlWrapperLocal.objectsToUndelete != null && !dmlWrapperLocal.objectsToUndelete.isEmpty()) {
            dmlWrapper.objectsToUndelete.addAll(dmlWrapperLocal.objectsToUndelete);
        }
    }
}
