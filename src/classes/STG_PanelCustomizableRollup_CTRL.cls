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
    * @description action method run on page load to check account model and admin status of running user
    * and add pagemessages as needed
    */
    public void checkPermissions() {
        // throw an error if the org isn't on HH account model
        if (!isHHAccount) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.stgCRLPHouseholdAccountError));
        }
        // throw an error if the user isn't an admin
        if (!isAdmin) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.stgCRLPNonAdminError));
        }
    }

    /*******************************************************************************************************
    * @description Overridden Action Method to kick off CMDT deployment, save custom setting,
    * and reschedule Scheduled Jobs
    * @return void
    */
    public virtual override PageReference saveSettings() {

        STG_SettingsManager_CTRL.idPanelCurrent = idPanel();
        Customizable_Rollup_Settings__c crlpSettings = UTIL_CustomSettingsFacade.getCustomizableRollupSettings();
        Savepoint sp = Database.setSavepoint();
        isEditMode = false;
        try {
            if (STG_Panel.stgService.stgCRLP.Customizable_Rollups_Enabled__c) {
                String oldStatus = STG_Panel.stgService.stgCRLP.CMT_API_Status__c;
                // Only start polling if it's their first time or the last deployment wasn't a success
                if(String.isEmpty(oldStatus) || !oldStatus.contains('Succeeded')) {
                    isPolling = true;
                }
                // This method includes committing Customizable_Rollups_Enabled__c as true if the deployment succeeds
                jobId = CRLP_DefaultConfigBuilder_SVC.convertLegacyRollupsIntoCustomizableRollups();
                if (Test.isRunningTest()) {
                    jobId = '123';
                }
            } else {
                // The deployment method takes care of setting the Enabled flag to true if it succeeds.
                // In here, we only set it to false.
                stgService.saveAll();
            }
            UTIL_MasterSchedulableHelper.setScheduledJobs();
        } catch (Exception e) {
            Database.rollback(sp);
            ERR_Handler.processError(e, ERR_Handler_API.Context.STTG);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            isPolling = false;
            crlpSettings.Customizable_Rollups_Enabled__c = !STG_Panel.stgService.stgCRLP.Customizable_Rollups_Enabled__c;
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