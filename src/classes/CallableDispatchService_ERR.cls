/*
    Copyright (c) 2019, Salesforce.org
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
* @date 2019
* @group API
* @group-content ../../ApexDocContent/API.htm
* @description Dispatches calls from the Callable API to the NPSP Error and RecordError APIs,
*              depending on the ActionType that is set
*/
public with sharing class CallableDispatchService_ERR {
    /*******************************************************************************************************
    * @description Exception class for Malformed Error Dispatch Method Api Exception
    ********************************************************************************************************/
    public class MalformedErrorDispatchMethodApiException extends Exception {}

    public static final String PARAM_DISPATCH_ACTION_TYPE = 'ActionType';
    public static final String PARAM_SOBJECTS = 'SObjects';

    public static final String PARAM_CONTEXT_NAME = 'Context';
    public static final String PARAM_ERR_MSGS_BY_RECORDID = 'ErrorMsgsByRecordId';
    public static final String PARAM_DML_RESULTS = 'DmlResultsByRecordId';
    public static final String PARAM_MESSAGE = 'Message';
    public static final String PARAM_EXCEPTION = 'Exception';

    /**
     * @description Dispatches invocations to the Error (ERR) Handling functionality from the Callable API to different methods
     * based on an "ActionType" parameter
     * @param CallableApiParameters paramService Parameteters passed to the Callable API as part of it's invocation
     * @return Object The result of the dispatch action's invocation
     */
    public static Object dispatch(CallableApiParameters paramService) {

        String dispatchAction = paramService.getString(PARAM_DISPATCH_ACTION_TYPE);

        String cleanDispatchAction = (String.isBlank(dispatchAction) ? '' : dispatchAction.toLowerCase());

        // Pulling Context out of switch since all the dispatch actions need the Context parameter
        String context = paramService.getString(PARAM_CONTEXT_NAME);

        switch on (cleanDispatchAction) {
            when 'adderror' { // Add Error
                return  addError(   context,
                                    paramService.getString(PARAM_MESSAGE)
                        );

            } when 'addexception' { // Add Exception
                return  addException(   context,
                                        paramService.getException(PARAM_EXCEPTION)
                        );

            } when 'addrecorderrors' { // Add Record Errors
                return  addRecordErrors(    context,
                                            paramService.getSObjects(PARAM_SOBJECTS),
                                            paramService.getStringsById(PARAM_ERR_MSGS_BY_RECORDID)
                        );

            } when 'addrecorddmlerrors' { // Add Record Dml Errors
                return  addRecordDmlErrors( context,
                                            paramService.getSObjects(PARAM_SOBJECTS),
                                            paramService.getObjects(PARAM_DML_RESULTS)
                        );

            } when 'clearrecorderrors' { // Clear Record Errors
                return  clearRecordErrors(  context,
                                            paramService.getSObjects(PARAM_SOBJECTS),
                                            paramService.getString(PARAM_MESSAGE)
                        );

            } when else { // Invalid Action Type / Action Type Not implemented
                throw new MalformedErrorDispatchMethodApiException(
                    String.format(System.Label.CallableApiMethodNotImplemented, new List<String> { 'err.dispatchaction => ' + dispatchAction})
                );
            }
        }
    }

    /**
     * @description Adds an Error Message via the ERR_Handler class.
     *              @see ERR_Handler.processError
     * @param context The context the exception should be logged under
     * @param errorMessage The Error to Log
     * @return Boolean true
     */
    private static Boolean addError(String context, String errorMessage) {
        ERR_Handler.processError(errorMessage, context);

        return true;
    }

    /**
     * @description Adds an Exception Error via the ERR_Handler class.
     *              @see ERR_Handler.processError
     * @param context The context the exception should be logged under
     * @param anException The exception to log
     * @return Boolean true
     */
    private static Boolean addException(String context, Exception anException) {
        ERR_Handler.processError(anException, context);

        return true;
    }

    /**
     * @description Adds String Error Messages as Record Errors via the ERR_RecordError class.
     *              @see ERR_RecordError.addErrors for more details
     * @param context The context the errors should be logged under
     * @param sObjects The list of SObjects to process
     * @param errorMessagesByRecordId Map of Errors Messages to add, keyed by Record Id
     * @return Boolean true
     */
    private static Boolean addRecordErrors(String context, List<SObject> sObjects, Map<Id, String> errorMessagesByRecordId) {
        Map<Id, SObject> sObjectsById = (sObjects != null) ? new Map<Id, SObject>(sObjects) : new Map<Id, SObject>();

        ERR_RecordError recordError = new ERR_RecordError(context);
        recordError.retrieveExistingErrorsFor(sObjects);

        recordError.addErrors(errorMessagesByRecordId, sObjectsById);
        recordError.processErrors();

        return true;
    }

    /**
     * @description Adds DML Based Record Errors via the ERR_RecordError class.
     *              @see ERR_RecordError.addErrors for more details
     * @param context The context the errors should be logged under
     * @param sObjects The list of SObjects to process
     * @param dmlResults List of dmlResults associated with the SObjects to process
     * @return Boolean true
     */
    private static Boolean addRecordDmlErrors(String context, List<SObject> sObjects, List<Object> dmlResults) {
        // Need to be in same order as SObjects List, so cannot construct map and use keyset()
        List<Id> idsForSObjects = buildListOfIdsForSObjects(sObjects);

        ERR_RecordError recordError = new ERR_RecordError(context);
        recordError.retrieveExistingErrorsFor(sObjects);

        recordError.addErrors(dmlResults, idsForSObjects, sObjects);
        recordError.processErrors();

        return true;
    }

    /**
     * @description Clears Record Errors via the ERR_RecordError class.
     *              @see ERR_RecordError.clearErrors for more details
     * @param context The context the errors should be logged under
     * @param sObjects The list of SObjects to process
     * @param message The message to update the Record Error with When clearing
     *                them
     * @return Boolean true
     */
    private static Boolean clearRecordErrors(String context, List<SObject> sObjects, String message) {
        Map<Id, SObject> sObjectsById = (sObjects != null) ? new Map<Id, SObject>(sObjects) : new Map<Id, SObject>();

        ERR_RecordError recordError = new ERR_RecordError(context);
        recordError.retrieveExistingErrorsFor(sObjects);

        recordError.clearErrors(sObjectsById.keySet(), message);
        recordError.processErrors();

        return true;
    }

    /**
     * @description Builds a list of SObject Ids from a List of SObjects.  The Ids are added to the List in the
     * same order as the SObjects.
     * @param sObjects List of SObjects to extract ids from
     * @return List<Id> List of Ids in same order as SObject List
     */
     private static List<Id> buildListOfIdsForSObjects(List<SObject> sObjects) {
        List<Id> idsForSObjects = new List<Id>();

        if (sObjects != null) {
            for (SObject sObj : sObjects) {
                idsForSObjects.add(sObj.Id);
            }
        }
        return idsForSObjects;
    }

}