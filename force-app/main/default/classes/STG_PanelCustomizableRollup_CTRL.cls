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
* @group Settings
* @group-content ../../ApexDocContent/Settings.htm
* @description Controller extension for the Customizable Rollups settings panel.
*/
public with sharing class STG_PanelCustomizableRollup_CTRL extends STG_Panel {

    /*********************************************************************************************************
    * @description Returns the string Id of the Recurring Donations panel.
    */
    public override string idPanel() { return 'idPanelCustomizableRollup'; }

    /*******************************************************************************************************
    * @description is the panel currently Polling for deployment results
    */
    public Boolean isPolling {
        get {
            if (isPolling == null) {
                return false;
            } else {
                return isPolling;
            }
        }
        private set;
    }

    /*******************************************************************************************************
    * @description Show CRLP settings if the org is on the HH Account model,
    * or if the org is on the One to One Account model and HEDA + Advancement is installed
    * @return Boolean
    */
    public Boolean showCRLPSettings {
        get {
            Boolean isHHAccountModel = STG_Panel.stgService.stgCon.npe01__Account_Processor__c == CAO_Constants.HH_ACCOUNT_PROCESSOR;
            Boolean isOneToOneModel = STG_Panel.stgService.stgCon.npe01__Account_Processor__c == CAO_Constants.ONE_TO_ONE_PROCESSOR;
            return isHHAccountModel || (ADV_PackageInfo_SVC.useAdv() && isOneToOneModel);
        }
        set;
    }

    /*******************************************************************************************************
    * @description the jobId of the deployment
    */
    public String jobId { get; private set; }

    /*******************************************************************************************************
    * @description Enable Customizable Rollups by starting the custom metadata deployment
    * @return null
    */
    public PageReference enableCRLPs() {
        STG_SettingsManager_CTRL.idPanelCurrent = idPanel();

        Savepoint sp = Database.setSavepoint();
        try {
            this.isPolling = true;
            this.jobId = new CRLP_EnablementService().enable(true);
            STG_Panel.stgService.reset(STG_Panel.stgService.stgCRLP);

        } catch (Exception e) {
            Database.rollback(sp);
            ERR_Handler.processError(e, ERR_Handler_API.Context.STTG);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
        if (this.jobId == null) {
            this.isPolling = false;
        }

        return null;
    }

    /*******************************************************************************************************
    * @description Action Method to simply redeploy/reset all CMDTs, only offered when CRLPs are enabled
    * @return void
    */

    public PageReference resetRollupsToDefaultConfig() {
        STG_SettingsManager_CTRL.idPanelCurrent = idPanel();

        Savepoint sp = Database.setSavepoint();
        try {
            this.isPolling = true;
            this.jobId = new CRLP_EnablementService().reset();
            STG_Panel.stgService.reset(STG_Panel.stgService.stgCRLP);

        } catch (Exception e) {
            Database.rollback(sp);
            ERR_Handler.processError(e, ERR_Handler_API.Context.STTG);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
        if (this.jobId == null) {
            this.isPolling = false;
        }
        return null;
    }

    /*******************************************************************************************************
    * @description Action Method to disable CMDTs, save custom setting,
    * and reschedule Scheduled Jobs
    * @return void
    */
    public PageReference disableCRLPs() {
        isPolling = false;

        STG_SettingsManager_CTRL.idPanelCurrent = idPanel();

        Savepoint sp = Database.setSavepoint();
        try {
            new CRLP_EnablementService().disable();
            STG_Panel.stgService.reset(STG_Panel.stgService.stgCRLP);

        } catch (Exception e) {
            Database.rollback(sp);
            ERR_Handler.processError(e, ERR_Handler_API.Context.STTG);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            Customizable_Rollup_Settings__c crlpSettings = UTIL_CustomSettingsFacade.getCustomizableRollupSettings();
            crlpSettings.Customizable_Rollups_Enabled__c = !STG_Panel.stgService.stgCRLP.Customizable_Rollups_Enabled__c;
        }
        return null;
    }

    /*******************************************************************************************************
    * @description Action Method to navigate to separate VF page that contains custom CMDT UI in Lightning Components
    * @return void
    */
    public PageReference navigate() {
        PageReference rollupGrid = new PageReference('/apex/CRLP_RollupSetup');
        rollupGrid.setRedirect(true);
        return rollupGrid;
    }

    /*******************************************************************************************************
    * @description Action Method used by Poller to check status of CMDT deployment
    * @return void
    */
    public PageReference checkDeploymentStatus() {
        Customizable_Rollup_Settings__c crlpSettings = UTIL_CustomSettingsFacade.getCustomizableRollupSettings();
        String newStatus = crlpSettings.CMT_API_Status__c;

        // Make sure we have a response and it's the new response.
        if (String.isEmpty(newStatus) || !newStatus.contains(jobId)) {
            return null;
        }

        isPolling = false;

        // The deployment job did not succeed
        if (!newStatus.contains(CMT_MetadataAPI.DEPLOYMENT_SUCCESS_TEXT)) {
            crlpSettings.Customizable_Rollups_Enabled__c = false;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, newStatus +' '+ Label.stgDeploymentTryAgain));
        }
        return null;
    }
}