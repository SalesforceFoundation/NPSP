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
* @description Customizable Rollups Scheduler for all Batch Rollup Jobs
*/
public class CRLP_RollupScheduler implements Schedulable {

    /** @description The job type for this batch job -- AccountHardCredit, AccountSoftCredit, etc. */
    private CRLP_RollupProcessingOptions.RollupType jobType;

    /** @description The batch job mode - Skew (LDV) or Non-Skew */
    private CRLP_RollupProcessingOptions.BatchJobMode jobMode = CRLP_RollupProcessingOptions.BatchJobMode.NonSkewMode;

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
     * @param isLDV Boolean True to queue an LDV Batch Job versus the standard batch job.
     * @param objType SObjectType for the standard rollup
     */
    public CRLP_RollupScheduler(CRLP_RollupProcessingOptions.RollupType jobType, CRLP_RollupProcessingOptions.BatchJobMode jobMode) {
        this.jobType = jobType;
        this.jobMode = jobMode;
    }

    /**
     * @description Scheduler Framework for ALL Customizable Rollup batch jobs. Queues the appropriate Batch Job
     * for Rollups based on the instance vars passed into the Scheduler Constructor. Only executes the LDV batch
     * job if there is at least one Account record that meets the minimum number of attached opps criteria value.
     */
    public void execute(SchedulableContext context) {

        Integer batchSize = CRLP_Rollup_SVC.getBatchSize(this.jobType, this.jobMode);

        if (!CRLP_Rollup_SVC.isCustomizableRollupEngineEnabled) {
            // if customizable rollups are not enabled, then do nothing. This is a failsafe in case the
            // customizable rollups engine is disabled after the new jobs have been scheduled.

        } else if (jobMode == CRLP_RollupProcessingOptions.BatchJobMode.NonSkewMode) {
            // Non-LDV Batch Rollup for the specified Summary SObject
//            Database.executeBatch(new CRLP_Rollup_BATCH(this.rollupObjectType), batchSize);

        } else {
            // LDV Batch Rollup for the specified Summary SObject
            Boolean hasLDVAccounts = true;
            if (this.jobType == CRLP_RollupProcessingOptions.RollupType.AccountHardCredit ||
                    this.jobType == CRLP_RollupProcessingOptions.RollupType.ContactHardCredit) {
                // For Account & Contact rollups, only execute the batch job if there is at least one Account
                // record with the minimum number of attached Opportunities.
                Integer maxRelatedOppsForNonSkewMode = CRLP_Rollup_SVC.getMaxRelatedOppsForNonSkewMode();
                // TODO -- Fix this query
                hasLDVAccounts = [SELECT Count() FROM Account
                        WHERE Number_of_Opportunities__c >= :maxRelatedOppsForNonSkewMode
                        LIMIT 1] > 0;
            }

            // If there is at least one LDV Account to roll up, execute this batch job
            if (this.jobType == CRLP_RollupProcessingOptions.RollupType.ContactSoftCredit ||
                    this.jobType == CRLP_RollupProcessingOptions.RollupType.AccountSoftCredit) {
//                Database.executeBatch(new CRLP_Rollup_SoftCredit_LDV_BATCH(), batchSize);
            } else if (hasLDVAccounts) {
//                Database.executeBatch(new CRLP_Batch_Base_Skew(this.rollupObjectType), batchSize);
            }
        }
    }
}