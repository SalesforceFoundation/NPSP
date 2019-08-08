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
* @description Abstract Base Batch class to facilitate reprocessing of records
*              Classes that extend from this can expect to be able to reprocess
*              record errors recorded via ERR_RecordError  by implementing the
*              getContextType method (to indicate which Context Type value) the
*              Record Errors are associated with, and the reprocessRecords method
*              (where the actual logic of reprocessing the Errored records will occur).
*              The batch will automatically remove Retry_Pending__c from any record Ids
*              returned from the reprocessRecords call, as these are assumed to be
*              successes.
*              Optionally, the getSuccessMessage can be overriden to provide a closing message
*              other than the default one if desired.
*              Record Errors will be retrieved using the following Criteria (anded):
*                     - ContextType = <<getContextType>>
*                     - Retry_Pending__c = true
*                     - Related_Record_Id__c != null
*              Any Record Errors returned will be compared to the boundary dateTime value, if specified,
*              or will assume all records if not.
* @group ErrorHandling
*/
public abstract inherited sharing class ERR_RecordErrorReprocessBatch_BASE extends UTIL_AbstractCommon_BATCH {

    @testVisible private DateTime boundary;

    /*******************************************************************************************************
     * @description Constructor
    *******************************************************************************************************/
    public ERR_RecordErrorReprocessBatch_Base() {
        super();
        this.boundary = System.now().addDays(1);
    }

    /*******************************************************************************************************
     * @description Constructor
     * @param DateTime boundary Only records whose LastModifiedDate <= boundary will
     *        be processed
    *******************************************************************************************************/
    public ERR_RecordErrorReprocessBatch_Base(DateTime boundary) {
        super();
        this.boundary = (boundary != null) ? boundary :System.now().addDays(1);
    }

    /*******************************************************************************************************
     * @description Constructor
     * @param Integer batchSize # of records to be returned per batch
     * @param DateTime boundary Only records whose LastModifiedDate <= boundary will
     *        be processed
    *******************************************************************************************************/
    public ERR_RecordErrorReprocessBatch_Base(Integer batchSize, DateTime boundary) {
        super(batchSize);
        this.boundary = (boundary != null) ? boundary : System.now().addDays(1);
    }

    /*******************************************************************************************************
     * @description Executes the pre and post steps for each batch of errors:
     *              Step 1: Confirm which records meet the criteria and build set/smaps
     *              Step 2: Initialize ERR_RecordErrors class with Errors
     *              Step 3: Invoke reprocessRecords method, passing set of Record Ids, and ERR_RecordErrors
     *                      class as parameters
     *              Step 4: Call ERR_RecordErrors clearErrors method passing in the Set of Ids returned
     *                      reprocessRecords (all Ids returned are considered success) and the message to
     *                      store with this change
     *              Step 5: Call ERR_RecordErrors.processErrors() method, to commit any new Errors to the
     *                      System, and to clear any that were marked as successful
     * @param Database.BatchableContext bc Represents the Parameter Type of a Batch Job Method, and
     *        contains the batch job Id
     * @param List<SObject> the list of records found in this batch
    *******************************************************************************************************/
    public override void doExecute(Database.BatchableContext bc, List<SObject> records ) {
        List<Error__c> errors = (List<Error__c>) records;


        ERR_RecordError recErrs = new ERR_RecordError(getContextType());
        List<Error__c> errsToProcess = new List<Error__c>();
        Set<Id> recIds = new Set<Id>();

        for (SObject rec : records) {
                Id recId = convertToIdFromString((String)rec.get('Related_Record_Id__c'));
                if (recId != null) {
                    recIds.add (recId);
                    errsToProcess.add((Error__c) rec);
                }
        }
        recErrs.withExistingErrors(errsToProcess);
        if (!recIds.isEmpty()) {
            Set<Id> successfullyReprocessed = reprocessRecords(recIds, recErrs);
            recErrs.clearErrors(successfullyReprocessed, this.getSuccessMessage());
            recErrs.processErrors();
        }
    }

    /*******************************************************************************************************
     * @description Attempts to convert a String value to a Salesforce Id.  If there are errors, it will
     *              return null
     * @param String idVal String value of Id
     * @return Converted Id (if successful) or null (if unsuccessful)
    *******************************************************************************************************/
    @testVisible private static String convertToIdFromString(String idVal) {
        Id cvtId = null;
        try {
            cvtId = idVal;
        } catch (Exception e) {

        }
        return cvtId;
    }

    /*******************************************************************************************************
     * @description SObjectType of the Main SObject the SOQL query will retrieve data from
     * @return SObjectType SObjectType of Object to Query
    *******************************************************************************************************/
    public override SObjectType getSObjectType() {
        return Error__c.getSObjectType();
    }

    /*******************************************************************************************************
     * @description Fields to retrieve for the batch
     * @return String Part of select statement between Select and From
    *******************************************************************************************************/
    public override String getSOQLFullQueryFieldList() {
        return  'Id, ' +
                'Context_Type__c, ' +
                'Datetime__c, ' +
                'Error_Type__c, ' +
                'Full_Message__c, ' +
                'Object_Type__c, ' +
                'Related_Record_Id__c, ' +
                'Record_URL__c, ' +
                'Retry_Pending__c';
    }

    /*******************************************************************************************************
     * @description Where clause to find Record Errors for the specified Process Pending Retry
     * @return String Where Clause
    *******************************************************************************************************/
    public override String getWhereClause() {
        String whereClause = 'Context_Type__c = \'' + getContextType() + '\' AND ' +
        'Retry_Pending__c = true AND ' +
        ' Related_Record_Id__c != null AND ' +
        ' LastModifiedDate <= ' + boundary.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        return whereClause;
    }

    /*******************************************************************************************************
     * @description The Success Message to be written to the Error record when clearing the
     *              Retry_Pending__c value for successfully reprocessed records
     * @return String Success Message Text
    *******************************************************************************************************/
    public virtual String getSuccessMessage() {
        return Label.errErrorRecordRetrySuccessful;
    }

    /*******************************************************************************************************
     * @description The Context Type (Error__c.Context_Type__c value) the Record Errors are stored under.
     *              (Child class must implement this method, and should not be blank/null)
     * @return String Context Type
    *******************************************************************************************************/
    public abstract String getContextType();

    /*******************************************************************************************************
     * @description The logic that must be reprocessed, associated with the Record Errors.
     *              (Child class must implement this method).  The set of Ids returned by this method call
     *              are assumed to have been successfully reprocessed, and are cleared with a "retry
     *              successful message.  Any errors added via the ERR_RecordError instance are also
     *              written out to the Error__c object.
     * @param Set<Id> recordIds The recordIds requiring reprocessing
     * @param ERR_RecordError instance of ERR_RecordError initialized with records to be processed so
     *        the Retry_Pending__c flag can be cleared, or additional errors can be logged.
     * @return Set<Id> A set of Ids (Subset of the Ids passed to this method) that were successfully
     *         reprocessed.
    *******************************************************************************************************/
    public abstract Set<Id> reprocessRecords(Set<Id> recordIds, ERR_RecordError recErrs);

}