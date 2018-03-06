/**
* Created by randi.wilson on 12/20/17.
*/

public with sharing class STG_PanelCustomizableRollup_CTRL extends STG_Panel {

    /*******************************************************************************************************
    * @description Action Method to save all settings changes in the Settings Service.
    * @return void
    */
    public virtual override PageReference saveSettings() {
        STG_SettingsManager_CTRL.idPanelCurrent = idPanel();
        Savepoint sp = Database.setSavepoint();
        try {
            CRLP_DefaultConfigBuilder_SVC.convertLegacyRollupsIntoCustomizableRollupsFuture();
            stgService.saveAll();
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

}