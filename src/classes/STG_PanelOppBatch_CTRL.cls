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
        } else {
            Integer batchSizeAcct = CRLP_Rollup_SVC.getBatchSize(CRLP_RollupProcessingOptions.RollupType.AccountHardCredit, CRLP_RollupProcessingOptions.BatchJobMode.NonSkewMode);
            Integer batchSizeCntct = CRLP_Rollup_SVC.getBatchSize(CRLP_RollupProcessingOptions.RollupType.ContactHardCredit, CRLP_RollupProcessingOptions.BatchJobMode.NonSkewMode);

//            Database.executeBatch(new CRLP_Rollup_BATCH(Account.SObjectType), batchSizeAcct);
//            Database.executeBatch(new CRLP_Rollup_BATCH(Contact.SObjectType), batchSizeCntct);
            this.numJobSubmitted = 2;

            Integer maxRelatedOppsForNonLDVMode = CRLP_Rollup_SVC.getMaxRelatedOppsForNonSkewMode();
            // TODO -- FIX THIS QUERY
            Boolean hasLDVAccounts = [SELECT Count() FROM Account WHERE Number_of_Opportunities__c >= :maxRelatedOppsForNonLDVMode LIMIT 1] > 0;

            // If there is at least one LDV Account to roll up, execute this batch job
            if (hasLDVAccounts) {
                batchSizeAcct = CRLP_Rollup_SVC.getBatchSize(CRLP_RollupProcessingOptions.RollupType.AccountHardCredit, CRLP_RollupProcessingOptions.BatchJobMode.SkewMode);
                batchSizeCntct = CRLP_Rollup_SVC.getBatchSize(CRLP_RollupProcessingOptions.RollupType.ContactHardCredit, CRLP_RollupProcessingOptions.BatchJobMode.SkewMode);
//                Database.executeBatch(new CRLP_Batch_Base_Skew(Account.SObjectType), batchSizeAcct);
//                Database.executeBatch(new CRLP_Batch_Base_Skew(Contact.SObjectType), batchSizeCntct);
                this.numJobSubmitted += 2;
            }

//            Database.executeBatch(new CRLP_Rollup_SoftCredit_LDV_BATCH(), CRLP_Rollup_SVC.getLDVBatchSize(Partial_Soft_Credit__c.SObjectType));
            this.numJobSubmitted++;

        }
        return null;
    }

}