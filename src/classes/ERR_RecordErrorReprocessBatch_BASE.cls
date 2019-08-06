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
* @description Abstract Base class to facilitate reprocessing of records
* @group ErrorHandling
*/
public abstract inherited sharing class ERR_RecordErrorReprocessBatch_BASE extends UTIL_AbstractCommon_BATCH {

    private DateTime boundary;

    public ERR_RecordErrorReprocessBatch_Base() {
        super();
        this.boundary = System.now();
    }

    public ERR_RecordErrorReprocessBatch_Base(DateTime boundary) {
        super();
        this.boundary = boundary;
    }

    public ERR_RecordErrorReprocessBatch_Base(Integer batchSize, DateTime boundary) {
        super(batchSize);
        this.boundary = boundary;
    }

    public override void doExecute(Database.BatchableContext bc, List<SObject>records ) {
        List<Error__c> errors = (List<Error__c>) records;

        ERR_RecordError recErrs = new ERR_RecordError(getContextType());
        List<Error__c> errsToProcess = new List<Error__c>();
        Set<Id> recIds = new Set<Id>();

        for (SObject rec : records) {
            if ((Datetime) rec.get('LastModifiedDate') <= boundary) {
                recIds.add (rec.Id);
                errsToProcess.add((Error__c) rec);
            }
        }
        recErrs.withExistingErrors(errsToProcess);
        if (!recIds.isEmpty()) {
            Set<Id> successfullyReprocessed = reprocessRecords(recIds, recErrs);

            recErrs.clearErrors(recIds, this.getSuccessMessage());
            recErrs.processErrors();
        }
    }

    public override SObjectType getSObjectType() {
        return Error__c.getSObjectType();
    }

    /**
     * Overridable test Where Clause to add to the inner query, or non LDV query, if not running in LDV/Chunking mode
     * @return String ''
     */
    public override String getWhereClause() {
        return 'Context_Type__c = \'' + getContextType() + '\' and Retry_Pending__c = true and Record_Id__c != null';
    }

    public virtual String getSuccessMessage() {
        return Label.errErrorRecordRetrySuccessful;
    }

    public abstract String getContextType();
    public abstract Set<Id> reprocessRecords(Set<Id> recordIds, ERR_RecordError recErrs);


}