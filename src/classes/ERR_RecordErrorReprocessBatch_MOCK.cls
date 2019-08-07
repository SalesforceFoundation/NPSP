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
* @description Mock Test Implementation of ERR_RecordErrorReprocessBatch_BASE
* @group ErrorHandling
*/
@IsTest
public inherited sharing class ERR_RecordErrorReprocessBatch_MOCK extends ERR_RecordErrorReprocessBatch_BASE {

    /* @description Name of the Context Type this Processes Errors will be stored under, and retrieved from. */
    public static final String PROCESS_NAME = 'TEST PROCESS';

    /** @description Set of Ids that will be returned as Successes when reprocessRecords is invoked, if record is in this set and the batch being processed */
    private Set<Id> fixedIds;

    /*******************************************************************************************************
     * @description Constructor
    *******************************************************************************************************/
    public ERR_RecordErrorReprocessBatch_MOCK() {
        super();
    }

    /*******************************************************************************************************
     * @description Constructor
     * @param DateTime boundary Only records whose LastModifiedDate <= boundary will
     *        be processed
    *******************************************************************************************************/
    public ERR_RecordErrorReprocessBatch_MOCK(DateTime boundary) {
        super(boundary);
    }

    /*******************************************************************************************************
     * @description Constructor
     * @param Integer batchSize # of records to be returned per batch
     * @param DateTime boundary Only records whose LastModifiedDate <= boundary will
     *        be processed
    *******************************************************************************************************/
    public ERR_RecordErrorReprocessBatch_MOCK(Integer batchSize, DateTime boundary) {
        super(batchSize, boundary);
    }

    /*******************************************************************************************************
     * @description The Context Type (Error__c.Context_Type__c value) the Record Errors are stored under.
     *              (Child class must implement this method, and should not be blank/null)
     * @return String Context Type
    *******************************************************************************************************/
    public override String getContextType() {
        return PROCESS_NAME;
    }

    /*******************************************************************************************************
     * @description Mocks a reprocessing result by indicating which of the Ids passed to the reprocessed
     * records method should be considered successful.
     * @param Set<Id> fixedIds The set of Ids considered to be treated as resolved when reprocessing.
    *******************************************************************************************************/
    public void setFixedIds(Set<Id> fixedIds) {
        this.fixedIds = fixedIds;
    }

    /*******************************************************************************************************
     * @description Test Implementation of Reprocess Records.  Doesn't do anything except check to see if
     * Id is in the "fixedIds" set.  If it is, it will return it as successfully processed.  If not, it
     * will add an error for it.
     * @param Set<Id> recordIds The recordIds requiring reprocessing
     * @param ERR_RecordError instance of ERR_RecordError initialized with records to be processed so
     *        the Retry_Pending__c flag can be cleared, or additional errors can be logged.
     * @return Set<Id> A set of Ids (Subset of the Ids passed to this method) that were successfully
     *         reprocessed.
    *******************************************************************************************************/
    public override Set<Id> reprocessRecords(Set<Id> recordIds, ERR_RecordError recErrs) {
        Set<Id> successfullyReprocessedRecords = new Set<Id>();
        for (Id recordId : recordIds) {
            if (this.fixedIds != null && this.fixedIds.contains(recordId)) {
                successfullyReprocessedRecords.add(recordId);
            } else {
                recErrs.addError(recordId, 'Mock Error for ' + recordId, new Account());
            }
        }
        return successfullyReprocessedRecords;
    }

}