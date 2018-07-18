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
* @description Controller for the Allocations settings page.
*/
public with sharing class STG_PanelAllocations_CTRL extends STG_Panel { 

    public static string oppAlloFilterGroupId =
        CMT_FilterRule_SEL.getFilterGroupIdByDeveloperName(CRLP_DefaultConfigBuilder.FilterGroup_Opps_Accounts_HC);
    public static string paymentAlloFilterGroupId = 
        CMT_FilterRule_SEL.getFilterGroupIdByDeveloperName(CRLP_DefaultConfigBuilder.FilterGroup_PaymentsPaid);
    public static string paymentApiName = CRLP_DefaultConfigBuilder.paymentObject;
    public static string opportunityApiName = STG_Panel.oppLabel;
    public static string oppAlloAmountField = 'Amount';
    public static string paymentAlloAmountField = 'npe01__Payment_Amount__c';
    public static string oppAlloDateField = 'CloseDate';
    public static string paymentAlloDateField = 'npe01__Payment_Date__c';

    /*********************************************************************************************************
    * @description Returns the string Id of the Allocations panel. 
    */
    public override string idPanel() { return 'idPanelAllocations'; }

    /*********************************************************************************************************
    * @description String that holds the selected Allocation Level
    */
    public String strAllocationLevel {get;set;}

    /*********************************************************************************************************
    * @description The panel's constructor.
    */
    public STG_PanelAllocations_CTRL() {
        if(STG_Panel.stgService.stgAllo.Payment_Allocations_Enabled__c){
            strAllocationLevel = paymentLabel;
        } else {
            strAllocationLevel = oppLabel;
        }
    }

    /*********************************************************************************************************
    * @description Enable or disable payment allocations based on settings selection
    */
    public void setAllocationLevel(){
        Boolean oldValue = STG_Panel.stgService.stgAllo.Payment_Allocations_Enabled__c;
        STG_Panel.stgService.stgAllo.Payment_Allocations_Enabled__c = 
            (strAllocationLevel == paymentLabel);
        if(oldValue != STG_Panel.stgService.stgAllo.Payment_Allocations_Enabled__c){
            updateAlloCustomRollups(STG_Panel.stgService.stgAllo.Payment_Allocations_Enabled__c);
        }
    }

    /*********************************************************************************************************
    * @description Method to update custom rollups based on Allocation level
    * @param usePayments Boolean if true, update to use Payment Allocations, otherwise use Opportunty
    * @return String the jobId for the custom rollup deployment
    */
    public static String updateAlloCustomRollups(Boolean usePayments){
        String oldFilter = usePayments ? oppAlloFilterGroupId : paymentAlloFilterGroupId;
        String newFilter = usePayments ? paymentAlloFilterGroupId : oppAlloFilterGroupId;
        String oldObjectLevel = usePayments ? opportunityApiName : paymentApiName;
        String newObjectLevel = usePayments ? paymentApiName : opportunityApiName;
        String oldAmountField = usePayments ? oppAlloAmountField : paymentAlloAmountField;
        String newAmountField = usePayments ? paymentAlloAmountField : oppAlloAmountField;
        String oldDateField = usePayments ? oppAlloDateField : paymentAlloDateField;
        String newDateField = usePayments ? paymentAlloDateField : oppAlloDateField;

        List<Rollup__mdt> rollupsToUpdate = new List<Rollup__mdt>();
        for(Rollup__mdt rlp : CRLP_Rollup_SEL.getRollupDefinitions()){
            if(rlp.Filter_Group__c == oldFilter 
                && rlp.Detail_Object__c == oldObjectLevel
                && rlp.Amount_Object__c == oldObjectLevel
                && rlp.Date_Object__c == oldObjectLevel){
                    rollupsToUpdate.add(rlp);
            }
        }

        if(rollupsToUpdate.isEmpty()){
            return null;
        }

        List<CRLP_RollupCMT.Rollup> rollupList = new List<CRLP_RollupCMT.Rollup>();
        for(Rollup__mdt rlp: rollupsToUpdate){
            CRLP_RollupCMT.Rollup crlp = new CRLP_RollupCMT.Rollup(rlp);
            crlp.filterGroupRecordName = newFilter;
            crlp.detailObject = newObjectLevel;
            crlp.dateObject = newObjectLevel;
            crlp.amountObject = newObjectLevel;
            crlp.amountField = newAmountField;
            crlp.detailField = newAmountField;
            crlp.dateField = newDateField;
            rollupList.add(crlp);
        }

        CRLP_ConfigBuilder_SVC.clearQueue();
        CRLP_ConfigBuilder_SVC.queueRollupConfigForDeploy(rollupList);
        String jobId = CRLP_ConfigBuilder_SVC.deployedQueuedMetadataTypes();
        return jobId;
    }

    /*********************************************************************************************************
    * @description An allocation, used to present a GAU lookup in the page to allow selecting a default GAU.
    */
    public static Allocation__c allo {
        get{
            if (allo == null) {
                allo = new Allocation__c();
                if (STG_Panel.stgService.stgAllo.Default__c!=null)
                    allo.General_Accounting_Unit__c = STG_Panel.stgService.stgAllo.Default__c;
            }
            return allo;

        }
        set;
    }

    /*********************************************************************************************************
    * @description The name of the default General Accounting Unit based on the ID stored in the custom setting.
    */
    static public string strDefaultGAUName {
        get {
            if (strDefaultGAUName == null) {
                if (!string.isBlank(STG_Panel.stgService.stgAllo.Default__c)) {
                    list<General_Accounting_Unit__c> listGAU = [select Id, Name from General_Accounting_Unit__c WHERE ID=:STG_Panel.stgService.stgAllo.Default__c];
                    if (!listGAU.isEmpty())
                        strDefaultGAUName = listGAU[0].Name;
                }
            }
            if (strDefaultGAUName == null)
                strDefaultGAUName = Label.stgLabelNone;
            return strDefaultGAUName;
        }
        private set;
    }

    /**
     * @description A user friendly rendering of record type ids by record type
     * name for Excluded Opp RecTypes
     */
    static public String strExcludedOppRecTypesReadOnly {
        get {
            if (strExcludedOppRecTypesReadOnly == null) {
                strExcludedOppRecTypesReadOnly = STG_Panel.getRecordTypeNamesFromPicklistString(
                    Opportunity.sObjectType,
                    STG_Panel.stgService.stgAllo.Excluded_Opp_RecTypes__c
                );
            }
            return strExcludedOppRecTypesReadOnly;
        }
        private set;
    }

    /*********************************************************************************************************
    * @description Action Method to save the current settings
    * If default allocations are enabled, ensure a default GAU is selected.
    * @return STG_Panel saveSettings method. 
    */
    public override PageReference saveSettings() {
        
        if (STG_Panel.stgService.stgAllo.Default_Allocations_Enabled__c && allo.General_Accounting_Unit__c==null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.alloDefaultGAUMissing));
            return null;
        }

        STG_Panel.stgService.stgAllo.Default__c = allo.General_Accounting_Unit__c;
        strDefaultGAUName = null;

        setAllocationLevel();

        if (STG_Panel.stgService.stgAllo.Payment_Allocations_Enabled__c && 
            !STG_Panel.stgService.stgAllo.Default_Allocations_Enabled__c) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.alloDefaultNotEnabled));
                return null;
        }

        return super.saveSettings();
    }
}