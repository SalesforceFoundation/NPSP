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
    * @description is the org on the HH Account model
    */
    public Boolean isHHAccount {
        get {
            return (STG_Panel.stgService.stgCon.npe01__Account_Processor__c == CAO_Constants.HH_ACCOUNT_PROCESSOR);
        }
        set;
    }

    /*******************************************************************************************************
    * @description is the running user an admin
    */
    public Boolean isAdmin {
        get {
            return STG_Panel.runningUserIsAdmin();
        }
        set;
    }

    /*******************************************************************************************************
    * @description the jobId of the deployment
    */
    public String jobId { get; private set; }

    /*******************************************************************************************************
    * @description the existing value of the CRLP enablement setting, cached upon entering edit mode
    */
    private Boolean cachedSetting;

    /*******************************************************************************************************
    * @description Overridden Action Method to put the current page into Edit mode and cache the existing setting
    * @return null
    */
    public virtual override PageReference editSettings() {
        STG_SettingsManager_CTRL.idPanelCurrent = idPanel();
        // cache the status of CRLP settings upon entering edit mode so we can check for no change
        cachedSetting = UTIL_CustomSettingsFacade.getOrgCustomizableRollupSettings().Customizable_Rollups_Enabled__c;
        isEditMode = true;
        return null;
    }

    /*******************************************************************************************************
    * @description Overridden Action Method to kick off CMDT deployment, save custom setting,
    * and reschedule Scheduled Jobs
    * @return void
    */
    public virtual override PageReference saveSettings() {

        STG_SettingsManager_CTRL.idPanelCurrent = idPanel();
        isEditMode = false;

        Boolean settingHasChanged = (cachedSetting != STG_Panel.stgService.stgCRLP.Customizable_Rollups_Enabled__c);

        if (settingHasChanged) {
            // we only proceed with deployment/save if they changed the checkbox.

            // if they hit edit and then they immediately hit save,
            // we do NOT want to reset their CRLP customizations (if both were true)
            // or run extraneous code (if both were false) so in that case we do nothing.
            // they have essentially hit cancel.

            Savepoint sp = Database.setSavepoint();
            try {
                if (STG_Panel.stgService.stgCRLP.Customizable_Rollups_Enabled__c) {
                    isPolling = true;
                    jobId = CRLP_DefaultConfigBuilder_SVC.convertLegacyRollupsIntoCustomizableRollups();
                    if (Test.isRunningTest()) {
                        jobId = '123';
                    }
                } else {
                    // The deployment method takes care of setting the Enabled flag to true if it succeeds.
                    // In here, we only set it to false in the case on disabling CRLPs.
                    stgService.saveAll();
                }
                UTIL_MasterSchedulableHelper.setScheduledJobs();
            } catch (Exception e) {
                Database.rollback(sp);
                ERR_Handler.processError(e, ERR_Handler_API.Context.STTG);
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
                isPolling = false;
                Customizable_Rollup_Settings__c crlpSettings = UTIL_CustomSettingsFacade.getCustomizableRollupSettings();
                crlpSettings.Customizable_Rollups_Enabled__c = !STG_Panel.stgService.stgCRLP.Customizable_Rollups_Enabled__c;
            }
        }
        return null;
    }

    /*******************************************************************************************************
    * @description Action Method to navigate to separate VF page that contains custom CMDT UI in Lightning Components
    * @return void
    */
    public PageReference navigate(){
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
        if(!String.isEmpty(newStatus) && newStatus.contains(jobId)){
            isPolling = false;
            if (newStatus.contains('Succeeded')) {
                return null;
            } else {
                crlpSettings.Customizable_Rollups_Enabled__c = false;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, newStatus +' '+ Label.stgDeploymentTryAgain));
                return null;
            }
        } else {
            return null;
        }
    }
}