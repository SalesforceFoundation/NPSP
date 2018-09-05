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
* @description Service methods insert/update Customizable Rollups CMT data using the Metadata API
* Process:
* 1) Call one of the 3 queue() methods to add a list of CRLP_RollupCMT wrapper class instances to the static var
*    collection for deployment
* 2) Call deployedQueuedMetadataTypes() to deploy the queue. This returns a unique job Id that can be used to retrieve
*    the deployment status from the Customizable Rollups Custom Settings object
* 3) Call clearQueue() when done (unless the code execution contents changes in which case the static contents are lost)
*/
public class CRLP_ConfigBuilder_SVC {

    public static final String oppAlloAccountFilterGroup = CRLP_DefaultConfigBuilder.FilterGroup_Opps_Accounts_HC;
    public static final String oppAlloContactFilterGroup = CRLP_DefaultConfigBuilder.FilterGroup_Opps_Contacts_HC;
    public static final String paymentAlloFilterGroup = CRLP_DefaultConfigBuilder.FilterGroup_PaymentsPaid;
    public static final String paymentApiName = CRLP_DefaultConfigBuilder.paymentObject;
    public static final String opportunityApiName = STG_Panel.oppLabel;
    public static final String oppAlloAmountApiName = 'Amount';
    public static final String paymentAlloAmountApiName = 'npe01__Payment_Amount__c';
    public static final String oppAlloDateApiName = 'CloseDate';
    public static final String paymentAlloDateApiName = 'npe01__Payment_Date__c';

    /** @description Metadata queued up for deployment */
    @TestVisible
    private static List<Metadata.CustomMetadata> queuedMetadataTypes = new List<Metadata.CustomMetadata>();

    /**
     * @description Queue a list of CRLP_RollupCMT.Filter Groups instances and optionally a list of Filter Rules
     * within the Group for deployment.
     * @param groupsAndRules List<CRLP_RollupCMT.FilterGroup>
     */
    public static void queueRollupConfigForDeploy(List<CRLP_RollupCMT.FilterGroup> groupsAndRules) {

        List<Metadata.CustomMetadata> groups = new List<Metadata.CustomMetadata>();
        List<Metadata.CustomMetadata> rules = new List<Metadata.CustomMetadata>();
        for (CRLP_RollupCMT.FilterGroup fg : groupsAndRules) {
            groups.add(fg.getMetadataRecord());
            if (fg.rules != null && !fg.rules.isEmpty()) {
                for (CRLP_RollupCMT.FilterRule fr : fg.rules) {
                    fr.filterGroupRecordName = fg.recordName;
                    rules.add(fr.getMetadataRecord());
                }
            }
        }

        queuedMetadataTypes.addAll(groups);
        queuedMetadataTypes.addAll(rules);
    }

    /**
     * @description Queue a list of CRLP_RollupCMT.FilterRule instances for deployment.
     * @param rules List<CRLP_RollupCMT.FilterRule>
     */
    public static void queueRollupConfigForDeploy(List<CRLP_RollupCMT.FilterRule> rules) {
        List<Metadata.CustomMetadata> rollupMD = new List<Metadata.CustomMetadata>();
        for (CRLP_RollupCMT.FilterRule fr : rules) {
            rollupMD.add(fr.getMetadataRecord());
        }
        queuedMetadataTypes.addAll(rollupMD);
    }

    /**
     * @description Queue a list of CRLP_RollupCMT.Rollup instances for deployment.
     * @param rollups List<CRLP_RollupCMT.Rollup>
     */
    public static void queueRollupConfigForDeploy(List<CRLP_RollupCMT.Rollup> rollups) {
        List<Metadata.CustomMetadata> rollupMD = new List<Metadata.CustomMetadata>();
        for (CRLP_RollupCMT.Rollup rlp : rollups) {
            rollupMD.add(rlp.getMetadataRecord());
        }
        queuedMetadataTypes.addAll(rollupMD);
    }

    /**
     * @description Clear the queuedMetadata static var contents
     */
    public static void clearQueue() {
        queuedMetadataTypes.clear();
    }

    /**
     * @description Pass the List<CustomMetadata>> to the CMT_MetadataAPI for deployment
     * @return A unique jobId. This value is used when writing the final status to the Customizable_Rollup_Settings__c
     * object and is needed to ensure that the status retrieved from that custom settings object is for this
     * particular deployment and not a previous one.
     */
    public static String deployedQueuedMetadataTypes() {
        String jobId = getUniqueJobId();
        CMT_MetadataAPI.deployMetadata(jobId, queuedMetadataTypes.clone());
        return jobId;
    }

    /**
     * @return A 10 character unique 'jobId' to use for
     */
    private static String getUniqueJobId() {
        return UserInfo.getUserId().left(15).right(4).toUpperCase() +
                String.valueOf(Integer.valueOf(math.rint(math.random()*5000000))).right(6);
    }

    /*********************************************************************************************************
    * @description Method to update custom rollups based on Allocation level
    * set as a future method to not interfere with setup object DML operations
    * @param usePayments Boolean if true, update to use Payment Allocations, otherwise use Opportunty
    */
    @future
    public static void updateCustomRollupsAlloLevel(Boolean usePayments){
        String oldAcctFilter = usePayments ? oppAlloAccountFilterGroup : paymentAlloFilterGroup;
        String oldContactFilter = usePayments ? oppAlloContactFilterGroup : paymentAlloFilterGroup;
        String newAcctFilter = usePayments ? paymentAlloFilterGroup : oppAlloAccountFilterGroup;
        String newContactFilter = usePayments ? paymentAlloFilterGroup : oppAlloContactFilterGroup;
        Id oldAccountFilterId = 
            CMT_FilterRule_SEL.getFilterGroupIdByDeveloperName(oldAcctFilter);
        Id oldContactFilterId = 
            CMT_FilterRule_SEL.getFilterGroupIdByDeveloperName(oldContactFilter);
        Id newAccountFilterId = 
            CMT_FilterRule_SEL.getFilterGroupIdByDeveloperName(newAcctFilter);
        Id newContactFilterId = 
            CMT_FilterRule_SEL.getFilterGroupIdByDeveloperName(newContactFilter);
        String oldObjectLevel = usePayments ? opportunityApiName : paymentApiName;
        String newObjectLevel = usePayments ? paymentApiName : opportunityApiName;
        String oldAmountField = usePayments ? oppAlloAmountApiName : paymentAlloAmountApiName;
        String newAmountField = usePayments ? paymentAlloAmountApiName : oppAlloAmountApiName;
        String oldDateField = usePayments ? oppAlloDateApiName : paymentAlloDateApiName;
        String newDateField = usePayments ? paymentAlloDateApiName : oppAlloDateApiName;

        List<Rollup__mdt> rollupsToUpdate = new List<Rollup__mdt>();
        for (Rollup__mdt rlp : CRLP_Rollup_SEL.getRollupDefinitions()){
            if ((rlp.Filter_Group__c == newAccountFilterId 
                    || rlp.Filter_Group__c == newContactFilterId 
                    || rlp.Filter_Group__c == oldAccountFilterId 
                    || rlp.Filter_Group__c == oldContactFilterId)
                && rlp.Detail_Object__r.QualifiedApiName == oldObjectLevel
                && rlp.Amount_Object__r.QualifiedApiName == oldObjectLevel
                && rlp.Date_Object__r.QualifiedApiName == oldObjectLevel){
                    rollupsToUpdate.add(rlp);
            }
        }

        if (rollupsToUpdate.isEmpty()){
            return;
        }

        List<CRLP_RollupCMT.Rollup> rollups = new List<CRLP_RollupCMT.Rollup>();
        for (Rollup__mdt rlp: rollupsToUpdate){
            CRLP_RollupCMT.Rollup crlp = new CRLP_RollupCMT.Rollup(rlp);
            // In case legacy Rollup Settings are different for Contacts versus Accounts
            if(crlp.summaryObject == 'Contact'){
                crlp.filterGroupRecordName = newContactFilter;
            } else {
                crlp.filterGroupRecordName = newAcctFilter;
            }

            // The detail object depends on the operation
            if(crlp.operation == 'First' 
                || crlp.operation == 'Last'){
                    crlp.detailField = newDateField;
            } else if(crlp.operation == 'Average'
                || crlp.operation == 'Best_Year' 
                || crlp.operation == 'Best_Year_Total'){
                    crlp.detailField = null;
            } else {
                crlp.detailField = newAmountField;
            }

            crlp.detailObject = newObjectLevel;
            crlp.dateObject = newObjectLevel;
            crlp.amountObject = newObjectLevel;
            crlp.amountField = newAmountField;
            crlp.dateField = newDateField;
            rollups.add(crlp);
        }

        clearQueue();
        queueRollupConfigForDeploy(rollups);
        deployedQueuedMetadataTypes();
    }

}