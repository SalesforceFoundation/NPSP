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
* @description Controller extension for the Data Import Fied Mapping settings panel.
*/
public with sharing class STG_PanelDataImportMapping_CTRL extends STG_Panel {

    /*********************************************************************************************************
    * @description Returns the string Id of the Data Import Mapping panel
    */
    public override string idPanel() { return 'idPanelDataImportMapping'; }

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
    * @description Maximum timeout for page polling, 12 = 1 minute
    */
    private static final Integer MAX_TIME_OUT = 12;

    /*******************************************************************************************************
    * @description ActionPoller count
    */
    private Integer timeoutCount = 0;

    /*******************************************************************************************************
    * @description Get custom data import settings
    */
    public Data_Import_Settings__c dataImportSettings = UTIL_CustomSettingsFacade.getDataImportSettings();

    /*******************************************************************************************************
    * @description Return boolean for the current field mapping method
    */
    public Boolean isDataImportFieldMapping {
        get {
            return dataImportSettings.Field_Mapping_Method__c == 'Data Import Field Mapping' ? true : false;
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
    * @description List of help text mappings that conflicts with our packaged default custom metatadata type mappings
    */
    public List<BDI_HelpTextCMT.DataImportFieldMapping> conflictingCMTs {
        get {
            if (conflictingCMTs == null) {
                return new List<BDI_HelpTextCMT.DataImportFieldMapping>();
            } else {
                return conflictingCMTs;
            }
        }
        set;
    }

    /*******************************************************************************************************
    * @description List of custom metatadata type mappings pending deployment
    */
    public List<BDI_HelpTextCMT.DataImportFieldMapping> pendingCMTs {
        get {
            if (pendingCMTs == null) {
                return new List<BDI_HelpTextCMT.DataImportFieldMapping>();
            } else {
                return pendingCMTs;
            }
        }
        set;
    }

    /*******************************************************************************************************
    * @description Action Method to enable CMDT mapping, save custom setting
    * @return null
    */
    public PageReference enableDataImportFieldMapping() {
        STG_SettingsManager_CTRL.idPanelCurrent = idPanel();

        Savepoint sp = Database.setSavepoint();
        try {
            isPolling = true;
            conflictingCMTs.clear();
            pendingCMTs.clear();

            BDI_MigrationMappingUtility migrationMappingUtility = new BDI_MigrationMappingUtility();

            // Check to see if we have any existing help text mappings that conflict with our default cmt mappings
            migrationMappingUtility.buildCustomMetadataRecordsFromHelpText();

            if (!migrationMappingUtility.conflictingCMTs.isEmpty()) {
                isPolling = false;
                conflictingCMTs = migrationMappingUtility.conflictingCMTs;
                pendingCMTs = migrationMappingUtility.pendingCMTs;
                // TODO turn into custom label, placeholder warning message
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'We\'ve found some conflicts. Please resolve them before proceeding.'));
            } else {
                jobId = migrationMappingUtility.convertLegacyHelpTextToCustomMetadata();
            }

            if (Test.isRunningTest()) {
                jobId = '123';
            }
        } catch (Exception e) {
            Database.rollback(sp);
            ERR_Handler.processError(e, ERR_Handler_API.Context.STTG);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
        return null;
    }

    /*******************************************************************************************************
    * @description Action Method to disable CMDT mapping, save custom setting
    * @return void
    */
    public PageReference disableDataImportFieldMapping() {
        STG_SettingsManager_CTRL.idPanelCurrent = idPanel();

        try {
            isPolling = true;
            conflictingCMTs.clear();
            pendingCMTs.clear();

            BDI_MigrationMappingUtility migrationMappingUtility = new BDI_MigrationMappingUtility();

            Map<String, String> statusMap = new Map<String, String>{migrationMappingUtility.jobId => 'Data Import Field Mapping Disabled'};
            dataImportSettings = CMT_MetadataAPI.setHelpTextMigrationSettings(statusMap, false);

        } catch (Exception e) {
            ERR_Handler.processError(e, ERR_Handler_API.Context.STTG);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
        return null;
    }

    /*******************************************************************************************************
    * @description Action Method used by Poller to check status of CMDT deployment
    * @return void
    */
    public PageReference checkDeploymentStatus() {
        timeoutCount++;

        dataImportSettings = UTIL_CustomSettingsFacade.getDataImportSettings();
        String newStatus = dataImportSettings.CMT_API_Status__c;

        if (timeoutCount > MAX_TIME_OUT) {
            isPolling = false;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.stgDeploymentTimedOut + ' ' + Label.stgDeploymentTryAgain));
            return null;
        }

        if (newStatus != null && !String.isEmpty(newStatus)) {
            isPolling = false;

            if (newStatus.contains('Succeeded') || newStatus.contains('empty')) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, Label.stgDeploymentCustomMetadataMappingEnabled));
            } else if (newStatus.contains('Disabled')) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, Label.stgDeploymentHelpTextMappingEnabled));
            } else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, newStatus +' '+ Label.stgDeploymentTryAgain));
            }

            return null;
        }

        return null;
    }
}