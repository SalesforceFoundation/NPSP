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
*              depending on the ActionType that is set.
*             This method is to be used only by Salesforce.org apps and is subject to change at
*             any time. Do NOT call this method.  If you do so, your functionality can break
*             without any warning or liability from Salesforce.
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
    public static final String PARAM_DML_RESULTS = 'DmlResults';
    public static final String PARAM_MESSAGE = 'Message';
    public static final String PARAM_EXCEPTION = 'Exception';

    private CallableApiParameters paramService;

    /**
     * @description private no argument constructor
     * @param CallableApiParameters paramService Parameteters passed to the Callable API as part of it's invocation
     */
    private CallableDispatchService_ERR(CallableApiParameters paramService) {
        this.paramService = paramService;
    }

    /**
     * @description Returns an instance of the CallableDispatchService_ERR class, initialized with the
     * parameters passed to it.
     *            This method is to be used only by Salesforce.org apps and is subject to change at
     *            any time. Do NOT call this method.  If you do so, your functionality can break
     *            without any warning or liability from Salesforce.     
     * @param CallableApiParameters paramService Parameteters passed to the Callable API as part of it's invocation
     * @return CallableDispatchService_ERR instance ready to use
     */
    public static CallableDispatchService_ERR getInstanceOf(CallableApiParameters paramService) {
        return new CallableDispatchService_ERR(paramService);
    }

    /**
     * @description Dispatches invocations to the Error (ERR) Handling functionality from the Callable API to different methods
     * based on an "ActionType" parameter
     *            This method is to be used only by Salesforce.org apps and is subject to change at
     *            any time. Do NOT call this method.  If you do so, your functionality can break
     *            without any warning or liability from Salesforce.     
     * @return Object The result of the dispatch action's invocation
     */
    public Object dispatch() {

        String dispatchAction = this.paramService.getString(PARAM_DISPATCH_ACTION_TYPE);

        String cleanDispatchAction = (String.isBlank(dispatchAction) ? '' : dispatchAction.toLowerCase());

        // Pulling Context out of switch since all the dispatch actions need the Context parameter
        String context = this.paramService.getString(PARAM_CONTEXT_NAME);

        switch on (cleanDispatchAction) {
            when 'adderror' { // Add Error
                addError(   context,
                            this.paramService.getString(PARAM_MESSAGE)
                );

            } when 'addexception' { // Add Exception
                addException(   context,
                                this.paramService.getException(PARAM_EXCEPTION)
                );

            } when 'addrecorderrors' { // Add Record Errors
                addRecordErrors(    context,
                                    this.paramService.getSObjects(PARAM_SOBJECTS),
                                    this.paramService.getStringsById(PARAM_ERR_MSGS_BY_RECORDID)
                );

            } when 'addrecorddmlerrors' { // Add Record Dml Errors
                addRecordDmlErrors( context,
                                    this.paramService.getSObjects(PARAM_SOBJECTS),
                                    this.paramService.getObjects(PARAM_DML_RESULTS)
                );

            } when 'clearrecorderrors' { // Clear Record Errors
                clearRecordErrors(  context,
                                    this.paramService.getSObjects(PARAM_SOBJECTS),
                                    this.paramService.getString(PARAM_MESSAGE)
                );

            } when else { // Invalid Action Type / Action Type Not implemented
                throw new MalformedErrorDispatchMethodApiException(
                    String.format(System.Label.CallableApiMethodNotImplemented, new List<String> { 'err.dispatchaction => ' + dispatchAction})
                );
            }
        }

        // if the action does not return a value then return success
        return true;
    }

    /**
     * @description Adds an Error Message via the ERR_Handler class.
     *              @see ERR_Handler.processError
     * @param context The context the exception should be logged under
     * @param errorMessage The Error to Log
     */
    private void addError(String context, String errorMessage) {
        ERR_Handler.processError(errorMessage, context);
    }

    /**
     * @description Adds an Exception Error via the ERR_Handler class.
     *              @see ERR_Handler.processError
     * @param context The context the exception should be logged under
     * @param anException The exception to log
     */
    private void addException(String context, Exception anException) {
        ERR_Handler.processError(anException, context);
    }

    /**
     * @description Adds String Error Messages as Record Errors via the ERR_RecordError class.
     *              @see ERR_RecordError.addErrors for more details
     * @param context The context the errors should be logged under
     * @param sObjects The list of SObjects to process
     * @param errorMessagesByRecordId Map of Errors Messages to add, keyed by Record Id
     * @return Boolean true
     */
    private void addRecordErrors(String context, List<SObject> sObjects, Map<Id, String> errorMessagesByRecordId) {
        Map<Id, SObject> sObjectsById = (sObjects != null) ? new Map<Id, SObject>(sObjects) : new Map<Id, SObject>();

        ERR_RecordError recordError = new ERR_RecordError(context);
        recordError.retrieveExistingErrorsFor(sObjects);

        recordError.addErrors(errorMessagesByRecordId, sObjectsById);
        recordError.processErrors();
    }

    /**
     * @description Adds DML Based Record Errors via the ERR_RecordError class.
     *              @see ERR_RecordError.addErrors for more details
     * @param context The context the errors should be logged under
     * @param sObjects The list of SObjects to process
     * @param dmlResults List of dmlResults associated with the SObjects to process
     */
    private void addRecordDmlErrors(String context, List<SObject> sObjects, List<Object> dmlResults) {
        // Need to be in same order as SObjects List, so cannot construct map and use keyset()
        List<Id> idsForSObjects = buildListOfIdsForSObjects(sObjects);

        ERR_RecordError recordError = new ERR_RecordError(context);
        recordError.retrieveExistingErrorsFor(sObjects);

        recordError.addErrors(dmlResults, idsForSObjects, sObjects);
        recordError.processErrors();
    }

    /**
     * @description Clears Record Errors via the ERR_RecordError class.
     *              @see ERR_RecordError.clearErrors for more details
     * @param context The context the errors should be logged under
     * @param sObjects The list of SObjects to process
     * @param message The message to update the Record Error with When clearing
     *                them
     */
    private void clearRecordErrors(String context, List<SObject> sObjects, String message) {
        Map<Id, SObject> sObjectsById = (sObjects != null) ? new Map<Id, SObject>(sObjects) : new Map<Id, SObject>();

        ERR_RecordError recordError = new ERR_RecordError(context);
        recordError.retrieveExistingErrorsFor(sObjects);

        recordError.clearErrors(sObjectsById.keySet(), message);
        recordError.processErrors();
    }

    /**
     * @description Builds a list of SObject Ids from a List of SObjects.  The Ids are added to the List in the
     * same order as the SObjects.
     * @param sObjects List of SObjects to extract ids from
     * @return List<Id> List of Ids in same order as SObject List
     */
     private List<Id> buildListOfIdsForSObjects(List<SObject> sObjects) {
        List<Id> idsForSObjects = new List<Id>();

        if (sObjects != null) {
            for (SObject sObj : sObjects) {
                idsForSObjects.add(sObj.Id);
            }
        }
        return idsForSObjects;
    }

}
