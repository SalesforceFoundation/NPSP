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
    * @description is there a conflict between the org's help text mappings and the standard custom metadata
    * type mappings
    */
    public Boolean isConflict { get; set; }

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
    public List<Metadata.CustomMetadata> createdMappings {
        get {
            if (createdMappings == null) {
                createdMappings = new List<Metadata.CustomMetadata>();
            }
            return createdMappings;
        }
        set;
    }

    /*******************************************************************************************************
    * @description List of help text mappings that conflicts with our packaged default custom metatadata type mappings
    */
    public List<BDI_HelpTextCMT.DataImportFieldMapping> conflictingMappings {
        get {
            if (conflictingMappings == null) {
                conflictingMappings = new List<BDI_HelpTextCMT.DataImportFieldMapping>();
            }
            return conflictingMappings;
        }
        set;
    }

    /*******************************************************************************************************
    * @description List of custom metatadata type mappings pending deployment
    */
    public List<BDI_HelpTextCMT.DataImportFieldMapping> pendingMappings {
        get {
            if (pendingMappings == null) {
                pendingMappings = new List<BDI_HelpTextCMT.DataImportFieldMapping>();
            }
            return pendingMappings;
        }
        set;
    }

    public BDI_MigrationMappingUtility migrationMappingUtility {
        get {
            if (migrationMappingUtility == null) {
                migrationMappingUtility = new BDI_MigrationMappingUtility();
            }
            return migrationMappingUtility;
        }
        set;
    }

    public BDI_MigrationMappingHelper migrationMappingHelper {
        get {
            if (migrationMappingHelper == null) {
                migrationMappingHelper = new BDI_MigrationMappingHelper();
            }
            return migrationMappingHelper;
        }
        set;
    }

    private final String MIGRATED_CUSTOM_FIELD_MAPPING_SET_NAME = 'Migrated_Custom_Mapping_Set';

    /*******************************************************************************************************
    * @description Action Method to enable CMDT mapping, save custom setting
    * @return null
    */
    public PageReference enableDataImportFieldMapping() {
        STG_SettingsManager_CTRL.idPanelCurrent = idPanel();

        Savepoint sp = Database.setSavepoint();
        try {
            isPolling = true;
            createdMappings.clear();
            conflictingMappings.clear();
            pendingMappings.clear();

            // Check to see if we have any existing help text mappings that conflict with our default cmt mappings
            migrationMappingUtility.buildCustomMetadataRecordsFromHelpText(migrationMappingHelper, 'Default_Field_Mapping_Set');

            if (!migrationMappingUtility.conflictingMappings.isEmpty()) {
                isConflict = true;
                isPolling = false;
                conflictingMappings = migrationMappingUtility.conflictingMappings;
                pendingMappings = migrationMappingUtility.pendingMappings;
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
            createdMappings.clear();
            conflictingMappings.clear();
            pendingMappings.clear();

            Map<String, String> statusMap = new Map<String, String>{migrationMappingUtility.jobId => 'Data Import Field Mapping Disabled'};
            dataImportSettings = BDI_MigrationMappingUtility.updateDataImportCustomSettings(statusMap, false, null);
            jobId = migrationMappingUtility.jobId;

        } catch (Exception e) {
            ERR_Handler.processError(e, ERR_Handler_API.Context.STTG);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
        return null;
    }

    /*******************************************************************************************************
    * @description Action Method to discard help text Conflicts and continue to deploy
    * @return void
    */
    public PageReference keepConflicts() {
        System.debug('VFP keepConflicts');
        STG_SettingsManager_CTRL.idPanelCurrent = idPanel();

        Savepoint sp = Database.setSavepoint();
        try {
            isConflict = false;
            isPolling = true;

            createdMappings.clear();

            jobId = migrationMappingUtility.keepConflicts(migrationMappingHelper);

            if (Test.isRunningTest()) {
                jobId = '123';
            }
        } catch (Exception e) {
            System.debug('Got an error');
            Database.rollback(sp);
            ERR_Handler.processError(e, ERR_Handler_API.Context.STTG);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
        return null;
    }

    /*******************************************************************************************************
    * @description Action Method to discard help text Conflicts and continue to deploy
    * @return void
    */
    public PageReference discardConflicts() {
        STG_SettingsManager_CTRL.idPanelCurrent = idPanel();

        Savepoint sp = Database.setSavepoint();
        try {
            conflictingMappings.clear();
            isConflict = false;
            isPolling = true;

            jobId = migrationMappingUtility.discardConflicts();

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
    * @description Action Method used by Poller to check status of CMDT deployment
    * @return void
    */
    public PageReference checkDeploymentStatus() {
        System.debug('VFP checkDeploymentStatus');
        System.debug('VFP jobId: ' + jobId);
        timeoutCount++;

        dataImportSettings = UTIL_CustomSettingsFacade.getDataImportSettings();
        String newStatus = dataImportSettings.CMT_API_Status__c;
        System.debug(newStatus);

        if (timeoutCount > MAX_TIME_OUT) {
            createdMappings.clear();
            conflictingMappings.clear();
            pendingMappings.clear();

            isPolling = false;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.stgDeploymentTimedOut + ' ' + Label.stgDeploymentTryAgain));
            return null;
        }

        if (newStatus != null && !String.isEmpty(newStatus) && jobId != null && newStatus.contains(jobId)) {
            isPolling = false;

            if (newStatus.contains('Succeeded') || newStatus.contains('empty')) {
                System.debug('Success');
                System.debug(migrationMappingUtility.queuedMetadataTypesForDeploy);
                createdMappings = migrationMappingUtility.queuedMetadataTypesForDeploy;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, Label.stgDeploymentCustomMetadataMappingEnabled));
            } else if (newStatus.contains('Disabled')) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, Label.stgDeploymentHelpTextMappingEnabled));
            } else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, newStatus +' '+ Label.stgDeploymentTryAgain));
            }

            createdMappings.clear();
            conflictingMappings.clear();
            pendingMappings.clear();
            migrationMappingUtility = new BDI_MigrationMappingUtility();

            return null;
        }

        return null;
    }
}