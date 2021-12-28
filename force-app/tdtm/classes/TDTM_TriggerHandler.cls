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
    
    private static Boolean defaultRecordsInserted = false;
    
    public static Boolean suppressDebugAssertAfterErrorLogging = false;

    public static Boolean disableTDTM = false;
    private static Map<String, Integer> classNameToTimesCalled =
            new Map<String, Integer>();
    private static Map<String, Integer> classNameToNumberOfQueries =
            new Map<String, Integer>();
    private static Map<String, Map<String, Integer>> classNameToTimesCalledByContext =
            new Map<String, Map<String, Integer>>();
    private static Boolean isCompactLoggingEnabled = true;

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
    * @param dao The class that is going to retrieve all the TDTM records.
    * @return void
    */
    public static void run(
            TriggerContext context,
            Schema.DescribeSObjectResult describeObj,
            TDTM_iTableDataGateway dao
    ) {

        if (disableTDTM) {
           UTIL_Debug.debug(LoggingLevel.WARN, '****TDTM Disabled: no triggers will run for this transaction.');
           return;
        }

        if (context.records != null) {
           UTIL_Debug.debug(LoggingLevel.WARN, '****Trigger.new size: ' + context.records.size());
        }

        TDTM_Runnable.Action thisAction = context.action();
        UTIL_Debug.debug(LoggingLevel.WARN, '****ACTION: ' + thisAction + ' on ' + describeObj.getLabel());

        TDTM_Runnable.DmlWrapper dmlWrapper = new TDTM_Runnable.DmlWrapper();

        // If there are no records, insert the defaults.
        if (!defaultRecordsInserted && dao.isEmpty()) {
            // We will not insert the default records when Triggered by the User object to prevent MixedDML errors
            if (describeObj.getsObjectType() == User.sObjectType) {
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

        // Get the classes to run. Note that we are using the local object name, so it works for objects
        // from Cumulus both in the package and unmanaged dev orgs.
        List<SObject> classesToCall = dao.getClassesToCallForObject(describeObj.getLocalName(), thisAction);
//        UTIL_Debug.debug(LoggingLevel.WARN, '****Classes To Call for ' + describeObj.getLocalName() + ': ' + JSON.serializePretty(classesToCall));

        // fixup our trigger lists to deal with workflow rules
        context.existingRecords = fixupOldList(thisAction, context.records, context.existingRecords, describeObj);

        if (classesToCall != null && classesToCall.size() > 0) {
            //Run the relevant classes
            for (SObject classToCall : classesToCall) {
                String className = (String) classToCall.get('Class__c');
                Integer timesCalled = classNameToTimesCalled.get(className);
                Integer queries = classNameToNumberOfQueries.get(className) == null
                        ? 0
                        : classNameToNumberOfQueries.get(className);
                Integer queriesUsed = Limits.getQueries();
                Map<String, Integer> timesCalledByContext = classNameToTimesCalledByContext.get(className);
                if (timesCalledByContext == null) {
                    classNameToTimesCalledByContext.put(
                            className,
                            new Map<String, Integer>{
                                    thisAction.name() => 1
                            });
                } else {
                    Integer timesForContext = timesCalledByContext.get(thisAction.name());
                    if (timesForContext == null) {
                        timesCalledByContext.put(thisAction.name(), 1);
                    } else {
                        timesCalledByContext.put(thisAction.name(), timesForContext + 1);
                    }
                }

                if (timesCalled == null) {
                    classNameToTimesCalled.put(className, 1);
                } else {
                    classNameToTimesCalled.put(className, timesCalled + 1);
                }

                TDTM_Runnable.DmlWrapper dmlWrapperResponse = new TDTM_Runnable.DmlWrapper();

                try {
                    dmlWrapperResponse = runClass(classToCall, context, describeObj, dmlWrapper);
                } catch (Exception ex) {
                    handleException(context.records, context.existingRecords, ex);
                }

                classNameToNumberOfQueries.put(
                        className,
                        queries + (Limits.getQueries() - queriesUsed));

                updateDmlWrapperWithTriggerResponse(dmlWrapper, dmlWrapperResponse);

                UTIL_Debug.debugWithInfo('****Finished executing: ' + classToCall.get('Class__c') + ' for ' +
                    describeObj.getName() + ': ' + thisAction);
            }
            
            //Process the result
            if (dmlWrapper != null) {
                try {
                    processDML(dmlWrapper);
                } catch (Exception ex) {
                    handleException(context.records, context.existingRecords, ex);
                }
            }
            logTriggerHandlerInfo();
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

    private static void logTriggerHandlerInfo() {
        UTIL_Debug.debug(LoggingLevel.ERROR, '*** Number of Times Run by Trigger ' +
                'Handler: ' +
                stringVersionOf(classNameToTimesCalled));

        UTIL_Debug.debug(LoggingLevel.ERROR, '*** Number of Times Run by Trigger ' +
                'Handler ' +
                'by Context: ' +
                stringVersionOf(classNameToTimesCalledByContext));

        UTIL_Debug.debug(LoggingLevel.ERROR, '*** Number of Queries used by Trigger ' +
                'Handler: ' +
                stringVersionOf(classNameToNumberOfQueries));

        UTIL_Debug.debug(LoggingLevel.ERROR, '*** totalQueries(): ' + totalQueries());
    }

    private static String stringVersionOf(Object o) {
        return isCompactLoggingEnabled
        ? JSON.serialize(o)
        : JSON.serializePretty(o);
    }

    private static Integer totalQueries() {
        Integer total = 0;
        for (String str : classNameToNumberOfQueries.keySet()) {
            total = total + classNameToNumberOfQueries.get(str);
        }
        return total;
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
    private static TDTM_Runnable.DmlWrapper runClass(SObject classToRunRecord,
            TriggerContext context, Schema.DescribeSObjectResult describeObj, TDTM_Runnable.DmlWrapper dmlWrapper) {
        if (classToRunRecord == null) {
            UTIL_Debug.debug(LoggingLevel.WARN, '****ClassToCall was null');
            return dmlWrapper;
        }

        TriggerHandler triggerHandler = new TriggerHandler(classToRunRecord);
        Type classType = getTypeForClassNamed(triggerHandler.name());
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
                reportDebugMessageAsync(triggerHandler, describeObj, context);

                runAsync(classToRun, triggerHandler.name(), context, describeObj);
            } else {
                reportDebugMessageSync(triggerHandler, describeObj, context);

                return classToRun.run(context, describeObj);
            }
        } else if (classInstance instanceof TDTM_RunnableMutable) {
            // alternatively, objects created dynamically can implement the TDTM_RunnableMutable
            // interface if the class intends to directly modify the global DmlWrappper
            TDTM_RunnableMutable classToRun = (TDTM_RunnableMutable) classInstance;

            reportDebugMessageWithInfo(triggerHandler, describeObj, context);

            // we do not check whether class is identified as Asynchronous__c because the
            // underlying assumption to mutating DmlWrapper is that the class modifies
            // the collection directly, and TDTM_TriggerHandler.run will perform DML on
            // whatever exists in the collection after iterating through all classes to run
            classToRun.run(context, describeObj, dmlWrapper);
        } else {
            UTIL_Debug.debug(LoggingLevel.WARN, '****The class does not implement the required interface.');
        }

        return null;
    }

    private static void reportDebugMessageWithInfo(TriggerHandler triggerHandler, DescribeSObjectResult describeObj, TriggerContext context) {
        UTIL_Debug.debugWithInfo('****Calling synchronously: ' + triggerHandler.name() + ' for ' +
                describeObj.getName() + ': ' + context.action() + ' with ' + (context.records !=
                null ? context.records : context.existingRecords).size() + ' records');
    }

    private static void reportDebugMessageSync(TriggerHandler triggerHandler, DescribeSObjectResult describeObj, TriggerContext context) {
        UTIL_Debug.debug(LoggingLevel.WARN, '****Calling synchronously: ' + triggerHandler.name() + ' for ' +
                describeObj.getName() + ': ' + context.action() + ' with ' +
                getRecords(context).size() + ' records');
    }

    private static void reportDebugMessageAsync(TriggerHandler triggerHandler, DescribeSObjectResult describeObj, TriggerContext context) {
        UTIL_Debug.debug(LoggingLevel.WARN, '****Calling asynchronously: ' + triggerHandler.name() + ' for ' +
                describeObj.getName() + ': ' + context.action() + ' with ' +
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
            TriggerContext context, Schema.DescribeSObjectResult describeObj) {

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
               describeObj.getName(), classToRunName);
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

    /*******************************************************************************************************
    * @description a cache of SObject maps for each object type, used by FixupOldList()
    */
    private static Map<Schema.DescribeSobjectResult, Map<Id, SObject>> mapDescObjToMapOldForUpdates = new Map<Schema.DescribeSobjectResult, Map<Id, SObject>>();

    /*******************************************************************************************************
    * @description Returns the correct old list of objects for the trigger, for the current context.  By
    * caching the newList in all After triggers, it can provide the correct oldList in BeforeUpdate and
    * AfterUpdate, that the system will incorrectly peg to the original execution context, rather than what
    * state those objects are already in from preceding DML in the execution context.  Specifically, works
    * around the issue that a workflow rule that runs after any of our inserts or update to objects, will
    * contain the original state of those objects, rather than the current state.  This is a known system
    * 'by design' feature that prevents our triggers from doing the right thing.
    *
    * @param triggerAction which trigger event (BeforeInsert, AfterInsert, etc.).
    * @param newList the list of SObjects from trigger new.
    * @param oldList the list of SObjects from trigger old.
    * @param describeObj the describe for the SObject
    * @return list<SObject> the correct oldList for the current trigger
    */
    private static List<SObject> fixupOldList(TDTM_Runnable.Action triggerAction, List<SObject> newList, List<SObject> oldList,
        Schema.DescribeSObjectResult describeObj) {

        // return cached objects if we have them
        if (triggerAction == TDTM_Runnable.Action.AfterUpdate || triggerAction == TDTM_Runnable.Action.BeforeUpdate) {
            List<SObject> listSObj = new List<SObject>();
            Map<Id, SObject> mapIdToSObj = mapDescObjToMapOldForUpdates.get(describeObj);
            if (mapIdToSObj != null) {

                for (SObject sobj : oldList) {
                    SObject sobjCached = mapIdToSObj.get(sobj.Id);
                    if (sobjCached != null) {
                        listSObj.add(sobjCached);
                    } else {
                        listSObj.add(sobj);
                    }
                }

                // update oldList with the correct cached state of the objects
                oldList = listSObj;
                //UTIL_Debug.debug(LoggingLevel.WARN, '**** fixup oldList to : ' + oldList);
            } else {
                //UTIL_Debug.debug(LoggingLevel.WARN, '**** fixup not done since mapIdToSobj was null. mapDescObjToMapOldForUpdates:  ' + mapDescObjToMapOldForUpdates);
            }
        }

        // now cache objects for future Update calls
        if (triggerAction == TDTM_Runnable.Action.AfterInsert || triggerAction == TDTM_Runnable.Action.AfterUpdate) {
            mapDescObjToMapOldForUpdates.put(describeObj, new Map<Id, SObject>(newList));
            //UTIL_Debug.debug(LoggingLevel.WARN, '**** cached newList: ' + newList);
        }

        return oldList;
    }

    @TestVisible
    private static Object timesRun(String className, String context) {
        return classNameToTimesCalledByContext.get(className).get(context);
    }
}
