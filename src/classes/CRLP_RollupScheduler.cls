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
* @description Customizable Rollups Scheduler Service for all Batch Rollup Jobs
*/
public class CRLP_RollupScheduler implements Schedulable {

    /** @description The job type for this batch job -- AccountHardCredit, AccountSoftCredit, etc. */
    private CRLP_RollupProcessingOptions.RollupType jobType;

    /** @description Rollup Schedule Options - TBD */
    public Enum RollupSchedule {
        Daily,
        Weekly_Friday,
        Weekly_Sunday,
        Month_LastDay,
        Month_FirstDay,
        Year_LastDay,
        Year_FirstDay,
        Never
    }

    /**
     * @description Constructor
     * @param jobType Enum for the type of job to execute.
     */
    public CRLP_RollupScheduler(CRLP_RollupProcessingOptions.RollupType jobType) {
        this.jobType = jobType;
    }

    /**
     * @description Scheduler Framework for ALL Customizable Rollup batch jobs. Queues the appropriate Batch Job
     * for Rollups based on the instance vars passed into the Scheduler Constructor. Only executes the LDV batch
     * job if there is at least one Account record that meets the minimum number of attached opps criteria value.
     */
    public void execute(SchedulableContext context) {

        if (!CRLP_Rollup_SVC.isCustomizableRollupEngineEnabled) {
            // if customizable rollups are not enabled, then do nothing. This is a failsafe in case the
            // customizable rollups engine is disabled after the new jobs have been scheduled.

        } else {

            Boolean executeSkewMode = (this.jobType == CRLP_RollupProcessingOptions.RollupType.GAU);

            // Account and Contact Hard/Soft Credit Rollups will always execute the non-skew model batch job
            // first, and then determine if the skew mode batch job is needed in addition.
            if (this.jobType == CRLP_RollupProcessingOptions.RollupType.AccountHardCredit ||
                    this.jobType == CRLP_RollupProcessingOptions.RollupType.AccountSoftCredit ||
                    this.jobType == CRLP_RollupProcessingOptions.RollupType.ContactHardCredit ||
                    this.jobType == CRLP_RollupProcessingOptions.RollupType.ContactSoftCredit) {

                // Execute the main Non-Skew mode job
                CRLP_RollupBatch_SVC.executeBatchRollupJob(this.jobType, CRLP_RollupProcessingOptions.BatchJobMode.NonSkewMode, null, null);

                try {
                    // Determine if the SkewMode job is needed based on a simple count of the number of records
                    // that meet the skew mode criteria.
                    String objName = (this.jobType == CRLP_RollupProcessingOptions.RollupType.AccountHardCredit ||
                            this.jobType == CRLP_RollupProcessingOptions.RollupType.AccountSoftCredit ? 'Account' : 'Contact');

                    String query = 'SELECT Count() FROM ' + objName + ' WHERE ' +
                            CRLP_RollupBatch_SVC.getSkewWhereClause(this.jobType, CRLP_RollupProcessingOptions.BatchJobMode.SkewMode) +
                            ' LIMIT 1';

                    executeSkewMode = (database.countQuery(query) != 0);
                } catch (Exception ex) {
                    ERR_Handler.processError(ex, ERR_Handler_API.Context.CRLP);
                }
            }
            
            if (executeSkewMode) {
                Database.executeBatch(new CRLP_SkewDispatcher_BATCH(this.jobType), CRLP_SkewDispatcher_BATCH.BATCH_SIZE);
            }
        }
    }
}