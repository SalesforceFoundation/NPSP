/*
    Copyright (c) 2018, Salesforce.org
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
* @date 2018
* @group Rollups
* @group-content ../../ApexDocContent/Rollups2.htm
* @description Batch class that is the overall iterator for Skew mode rollup operations. This class queries Account, Contact
* or GAU records in small groups (as a single batch iteration) and submits those record Ids to the rollup batch job class
* for final processing.
*/
public class CRLP_SkewDispatcher_BATCH implements Database.Batchable<SObject>, Database.Stateful {

    /** @description Batch size for Apex Job. Uses default of 300 if Custom Setting is null. */
    public static Integer BATCH_SIZE = (UTIL_CustomSettingsFacade.getCustomizableRollupSettings().Rollups_Skew_Dispatcher_Batch_Size__c != null) ?
            UTIL_CustomSettingsFacade.getCustomizableRollupSettings().Rollups_Skew_Dispatcher_Batch_Size__c.intValue() : 300;

    /** @description Default job filter (not yet implemented */
    private CRLP_RollupProcessingOptions.RollupTypeFilter jobFilter = CRLP_RollupProcessingOptions.RollupTypeFilter.All;

    /** @description The job type for this batch job -- AccountHardCredit, AccountSoftCredit, etc. */
    private CRLP_RollupProcessingOptions.RollupType jobType;

    private SObjectType summaryObjectType;
    private Id lastIdProcessed;
    private List<Id> recordIds;

    /**
     * @description Constructor
     * @param jobType Enum for the type of job to execute.
     */
    public CRLP_SkewDispatcher_BATCH(CRLP_RollupProcessingOptions.RollupType jobType) {
        this.jobType = jobType;
        this.summaryObjectType = CRLP_RollupBatch_SVC.getSummaryObjectType(jobType);
    }

    /**
     * @description Constructor
     * @param jobType Enum for the type of job to execute.
     */
    public CRLP_SkewDispatcher_BATCH(CRLP_RollupProcessingOptions.RollupType jobType, CRLP_RollupProcessingOptions.RollupTypeFilter jobFilter) {
        this(jobType);
        this.jobFilter = jobFilter;
    }

    /**
     * @description Constructor
     * @param jobType Enum for the type of job to execute.
     * @param lastIdProcessed The last Id processed by the calling batch job. This job will query for Id > lastIdProcessed
     */
    public CRLP_SkewDispatcher_BATCH(CRLP_RollupProcessingOptions.RollupType jobType, CRLP_RollupProcessingOptions.RollupTypeFilter jobFilter, Id lastIdProcessed) {
        this(jobType, jobFilter);
        this.lastIdProcessed = lastIdProcessed;
    }

    /**
     * @description Query records to be rolled up using Skew Mode
     */
    public database.Querylocator start(Database.BatchableContext bc) {
        String query;
        try {
            Boolean hasActiveRollups = false;

            // Build a query string of the target Summary object.
            query = 'SELECT Id FROM ' + this.summaryObjectType.getDescribe().getName();
            String skewFilter = CRLP_RollupBatch_SVC.getSkewWhereClause(this.jobType, CRLP_RollupProcessingOptions.BatchJobMode.SkewMode);
            if (!String.isEmpty(skewFilter)) {
                query += ' WHERE ' + skewFilter;
            }

            // If the Summary Object is the Account, then filter on Accounts that have at least a single
            // Opportunity attached. This is helpful to reduce the overall query size.
            // To handle a scenario where an attached Oppportunity was deleted, but the record not recalculated
            // also include any records where the TotalGifts or TotalMemberships fields are not zero
            if (this.jobType == CRLP_RollupProcessingOptions.RollupType.ContactHardCredit ||
                    this.jobType == CRLP_RollupProcessingOptions.RollupType.AccountHardCredit) {
                hasActiveRollups = CRLP_Rollup_SVC.hasActiveRollupsForSObject(this.summaryObjectType);

            } else if (this.jobType == CRLP_RollupProcessingOptions.RollupType.ContactSoftCredit) {
                hasActiveRollups = CRLP_Rollup_SVC.hasActivePartialSoftCreditRollupsForSObject(this.summaryObjectType);

            } else if (this.jobType == CRLP_RollupProcessingOptions.RollupType.GAU) {
                hasActiveRollups = CRLP_Rollup_SVC.hasActiveRollupsForSObject(this.summaryObjectType);
            }

            if (hasActiveRollups == true) {
                // Chunking logic: Filter for Id greater than the last Id processed, sort by Id, and limit the number of records
                if (this.lastIdProcessed != null) {
                    query += (query.contains(' WHERE ') ? ' AND' : ' WHERE') + ' Id > \'' + this.lastIdProcessed + '\'';
                }
                query += ' ORDER BY Id ASC';

                // If there are no active rollups for the object type, then force the query to return zero records.
                query += ' LIMIT ' + BATCH_SIZE;
            } else {
                // This is needed because can't return null as a valid iterator.
                query += ' LIMIT 0';
            }

            return Database.getQueryLocator(query);

        } catch (Exception ex) {
            ex.setMessage(ex.getMessage() + '\n' + query);
            ERR_Handler.processError(ex, ERR_Handler_API.Context.CRLP.name() + '.' + this.jobType);
        }

        return Database.getQueryLocator([SELECT Id FROM Account LIMIT 0]); // return a generic empty data set rather than null
    }

    /**
     * @description Convert the scope of records into a simple list of Id's
     */
    public void execute(Database.BatchableContext bc, List<SObject> summaryRecords) {
        if (!summaryRecords.isEmpty()) {
            Map<Id, SObject> summaryMap = new Map<Id, SObject>(summaryRecords);
            this.recordIds = new List<Id>(summaryMap.keySet());
            this.lastIdProcessed = this.recordIds[summaryRecords.size() - 1];
        }
    }

    /**
     * @description Pass the collected Record Id's into the appropriate batch job class
     */
    public void finish(Database.BatchableContext bc) {
        if (this.recordIds != null && !this.recordIds.isEmpty()) {
            CRLP_RollupBatch_SVC.executeBatchRollupJob(this.jobType, CRLP_RollupProcessingOptions.BatchJobMode.SkewMode,
                this.recordIds, this.lastIdProcessed);
        }
    }
}