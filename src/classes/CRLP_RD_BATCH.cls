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
* @description Recurring Donations Rollup Batch Job
*/
public class CRLP_RD_BATCH extends CRLP_Batch_Base_NonSkew implements Database.Batchable<SObject>, Database.Stateful, Schedulable {

    public CRLP_RD_BATCH() { }

    /*******************************************************************************************************
     * @description Constructs the class - Rollup all Recurring Donations that meet the "Non Skew" criteria
     * @param jobType Defines the type of rollup job
     * @param jobFilter Allows for filtering the rollups on N-Day, Memberships, etc.
     */
    public CRLP_RD_BATCH(CRLP_RollupProcessingOptions.RollupTypeFilter jobFilter) {
        super(CRLP_RollupProcessingOptions.RollupType.RecurringDonations, jobFilter);
    }

    /*******************************************************************************************************
     * @description Constructs the class - Rollup is for a specific set of RD Id's
     * @param jobType Defines the type of rollup job
     * @param jobFilter Allows for filtering the rollups on N-Day, Memberships, etc.
     */
    public CRLP_RD_BATCH(List<Id> recordIds) {
        super(CRLP_RollupProcessingOptions.RollupType.RecurringDonations, recordIds);
    }

    /**
     * @description Scheduler execute method to support scheduling this job directly from the UI
     */
    public void execute(SchedulableContext context) {
        String className = CRLP_RD_BATCH.class.getName();
        if (CRLP_Rollup_SVC.isCustomizableRollupEngineEnabled) {
            if (!UTIL_MasterSchedulableHelper.hasRunningJob(className)) {
                CRLP_RollupBatch_SVC.executeBatchRollupJob(CRLP_RollupProcessingOptions.RollupType.RecurringDonations,
                        CRLP_RollupProcessingOptions.BatchJobMode.NonSkewMode);
            } else {
                logDuplicateBatchError(className);
            }
        }
    }
}