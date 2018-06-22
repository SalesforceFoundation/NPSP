/*
    Copyright (c) 2014, Salesforce.org
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
* @group Settings
* @description Controller for the Batch Opp Rollups panel.
*/
public with sharing class STG_PanelOppBatch_CTRL extends STG_Panel {

    public Integer numJobSubmitted { get; private set; }

    /*********************************************************************************************************
    * @description The panel's constructor 
    */
    public STG_PanelOppBatch_CTRL() {
        this.isRunningBatch = false;
        this.numJobSubmitted = 0;
    }
    
    /*********************************************************************************************************
    * @description Returns the string Id of the Batch Opp Rollups panel. 
    */
    public override string idPanel() { return 'idPanelOppBatch'; }
    
    /*********************************************************************************************************
    * @description Whether we are currently running the batch process 
    */
    public boolean isRunningBatch { get; set; }
    
    /*********************************************************************************************************
    * @description Action Method to run the Batch Opp Rollups  
    * @return null
    */
    public PageReference runBatch() {
        isRunningBatch = true;

        if (!CRLP_Rollup_SVC.isCustomizableRollupEngineEnabled) {
            // run legacy batch rollups
            RLLP_OppRollup rg = new RLLP_OppRollup();
            rg.rollupAll();
            this.numJobSubmitted = 4; // hardcoded to match what this runs
        } else {

            // Customizable Rollup Jobs are more complicated. There are 5 base jobs, but there may be 5 more
            // Skew jobs to execute if necessary.
            List<CRLP_RollupProcessingOptions.RollupType> jobTypeList = new List<CRLP_RollupProcessingOptions.RollupType>{
                    CRLP_RollupProcessingOptions.RollupType.AccountHardCredit,
                    CRLP_RollupProcessingOptions.RollupType.ContactHardCredit,
                    CRLP_RollupProcessingOptions.RollupType.AccountContactSoftCredit,
                    CRLP_RollupProcessingOptions.RollupType.ContactSoftCredit,
                    CRLP_RollupProcessingOptions.RollupType.AccountSoftCredit,
                    CRLP_RollupProcessingOptions.RollupType.RecurringDonations
            };

            this.numJobSubmitted = 0;
            for (CRLP_RollupProcessingOptions.RollupType jobType : jobTypeList) {
                CRLP_RollupBatch_SVC.executeBatchRollupJob(jobType, CRLP_RollupProcessingOptions.BatchJobMode.NonSkewMode, null, null);
                this.numJobSubmitted++;

                // Determine if the SkewMode job is needed based on a simple count of the number of records
                // that meet the skew mode criteria.
                String objName = CRLP_RollupBatch_SVC.getSummaryObjectType(jobType).getDescribe().getName();

                String query = 'SELECT Count() FROM ' + objName + ' WHERE ' +
                        CRLP_RollupBatch_SVC.getSkewWhereClause(jobType, CRLP_RollupProcessingOptions.BatchJobMode.SkewMode) +
                        ' LIMIT 1';

                Boolean executeSkewMode = (database.countQuery(query) != 0);
                if (executeSkewMode) {
                    Database.executeBatch(new CRLP_SkewDispatcher_BATCH(jobType), CRLP_SkewDispatcher_BATCH.BATCH_SIZE);
                    this.numJobSubmitted++;
                }
            }
        }
        return null;
    }

}