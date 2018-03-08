/**
* Created by randi.wilson on 12/20/17.
*/

public with sharing class STG_PanelCustomizableRollup_CTRL extends STG_Panel {

    /*******************************************************************************************************
    * @description Action Method to save all settings changes in the Settings Service.
    * @return void
    */
    public Boolean isPolling {
        get {
            if (isPolling == null) {
                return false;
            } else {
                return isPolling;
            }
        }
        set;
    }

    public String status {public get; set;}

    public virtual override PageReference saveSettings() {
        STG_SettingsManager_CTRL.idPanelCurrent = idPanel();
        Savepoint sp = Database.setSavepoint();
        try {
            if (STG_Panel.stgService.stgCRLP.Customizable_Rollups_Enabled__c) {
                String oldStatus = STG_Panel.stgService.stgCRLP.CMT_API_Status__c;
                system.debug(oldStatus);
                // only start polling if the last deployment wasn't a success
                if(String.isEmpty(oldStatus) || !oldStatus.contains('Succeeded')) {
                    isPolling = true;
                }
                CRLP_DefaultConfigBuilder_SVC.convertLegacyRollupsIntoCustomizableRollups();
            } else {
                // The deployment method takes care of setting the Enabled flag to true if it succeeds.
                // In here, we only set it to false.
                stgService.saveAll();
            }
            isEditMode = false;
        } catch (Exception e) {
            Database.rollback(sp);
            ERR_Handler.processError(e, ERR_Handler_API.Context.STTG);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
        return null;
    }

    public PageReference navigate(){

        //TODO: check this will work with upcoming URL changes
        PageReference rollupGrid = new PageReference('/apex/CRLP_RollupSetup');
        rollupGrid.setRedirect(true);
        return rollupGrid;
    }

    public PageReference checkDeploymentStatus() {
        // would this be cached? might have to re-query differently
        System.debug('+++++status: '+status);
        Customizable_Rollup_Settings__c crlpSettings = UTIL_CustomSettingsFacade.getCustomizableRollupSettings();
        status = crlpSettings.CMT_API_Status__c;
        System.debug('+++++status: '+status);
        if (!String.isEmpty(status)) {
            System.debug('+++++Turning polling off');
            isPolling = false;
        }
        if (status.contains('Succeeded')) {
            PageReference pr = new PageReference('/apex/STG_SettingsManager');
            pr.getParameters().put('panel','idPanelCustomizableRollup');
            pr.setRedirect(true);
            return pr;
        } else {
            crlpSettings.Customizable_Rollups_Enabled__c = false;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, status));
            return null;
        }
        return null;
    }

    public PageReference refreshPage() {
        PageReference pr = new PageReference('/apex/STG_SettingsManager');
        pr.getParameters().put('panel','idPanelCustomizableRollup');
        pr.setRedirect(true);
        return pr;
    }

    //APEX:ACTIONPOLLER SAMPLE METHODS BELOW
    //TODO: remove these

    Integer count = 0;

    public PageReference incrementCounter() {
        count++;
        return null;
    }

    public Integer getCount() {
        return count;
    }

}