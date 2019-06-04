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
public with sharing class STG_PanelDataImportAdvancedMapping_CTRL extends STG_Panel {

    /*********************************************************************************************************
    * @description Returns the string Id of the Data Import Mapping panel
    */
    public override string idPanel() { return 'idPanelDataImportMapping'; }

    /**
    * @description Name of default packaged Field Mapping Set
    */
    private static final String DEFAULT_FIELD_MAPPING_SET_RECORD_NAME =
        'Default_Field_Mapping_Set';

    /**
    * @description Name of custom Field Mapping Set
    */
    private static final String MIGRATED_CUSTOM_FIELD_MAPPING_SET_RECORD_NAME =
        'Migrated_Custom_Mapping_Set';

    /*******************************************************************************************************
    * @description Value for Data Import custom settings Field Mapping Method
    */
    private static final String DATA_IMPORT_FIELD_MAPPING =
        'Data Import Field Mapping';

    /*******************************************************************************************************
    * @description Value for Data Import custom settings Field Mapping Method
    */
    private static final String HELP_TEXT =
        'Help Text';

    /*******************************************************************************************************
    * @description String to determine value of Data Import custom settings field Default Data Import Field
    * Mapping Set
    */
    private static final String DEFAULT_MAPPING =
        'default';

    /*******************************************************************************************************
    * @description String to determine value of Data Import custom settings field Default Data Import Field
    * Mapping Set
    */
    private static final String CUSTOM_MAPPING =
        'custom';

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
    public Data_Import_Settings__c dataImportSettings { get; set; }

    /*******************************************************************************************************
    * @description Return boolean for the current field mapping method
    */
    public Boolean isDataImportFieldMapping {
        get {
            return dataImportSettings.Field_Mapping_Method__c == DATA_IMPORT_FIELD_MAPPING ? true : false;
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
    * @description Custom metadata deployment result
    */
    public Metadata.DeployResult deployment { get; set; }

    /*******************************************************************************************************
    * @description Boolean that determines if the toggle should be disabled
    */
    public Boolean toggleDisabled { get; set; }

    /*******************************************************************************************************
    * @description Instance of BDI_MigrationMappingUtility
    */
    public BDI_MigrationMappingUtility migrationMappingUtility { get; set; }

    /*******************************************************************************************************
    * @description Constructor for STG_PanelDataImportAdvancedMapping_CTRL class
    */
    public STG_PanelDataImportAdvancedMapping_CTRL() {
        this.migrationMappingUtility = new BDI_MigrationMappingUtility(new BDI_MigrationMappingHelper());
        this.dataImportSettings = UTIL_CustomSettingsFacade.getDataImportSettings();
        this.deployment = checkDeploymentStatus();
    }

    /*******************************************************************************************************
    * @description Action Method to enable CMDT mapping, save custom setting
    * @return null
    */
    public PageReference enableDataImportFieldMapping() {
        STG_SettingsManager_CTRL.idPanelCurrent = idPanel();

        // Check the deployment status and set toggleDisabled value
        deployment = checkDeploymentStatus();

        if (toggleDisabled == false || toggleDisabled == null) {
            Savepoint sp = Database.setSavepoint();
            try {
                isPolling = true;

                // Collect and inspect Help Text mappings
                // This method will populate the lists pendingMappings, pendingStandardMappings, and conflictingMappings
                //migrationMappingUtility.buildCustomMetadataRecordsFromHelpText(DEFAULT_FIELD_MAPPING_SET_RECORD_NAME);

                if (migrationMappingUtility.customFieldMappingSetExists == true) {
                    // Custom field mapping set exists
                    migrationMappingUtility.buildCustomMetadataRecordsFromHelpText(MIGRATED_CUSTOM_FIELD_MAPPING_SET_RECORD_NAME);
                } else {
                    // Custom field mapping set doesn't exist
                    migrationMappingUtility.buildCustomMetadataRecordsFromHelpText(DEFAULT_FIELD_MAPPING_SET_RECORD_NAME);
                }

                // Create Custom Field Mapping Set
                isPolling = true;

                // Start the migration, collect help text mappings, and compare against existing cmt mappings
                migrationMappingUtility.startMigration();

                // Add standard field mappings
                migrationMappingUtility.handleStandardMappings();

                // Add net new field mappings
                migrationMappingUtility.handleNewMappings();

                // Add special cased mappings (GAU and Opportunity Contact Role)
                migrationMappingUtility.handleSpecialCasedMappings();

                // Add conflicting mappings
                migrationMappingUtility.handleOverwriteConflictingMappings();

                Id deploymentId = migrationMappingUtility.deployCustomMetadata();
                saveDeploymentId(deploymentId);

            } catch (Exception e) {
                Database.rollback(sp);
                ERR_Handler.processError(e, ERR_Handler_API.Context.STTG);
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));

                isPolling = false;
                BDI_MigrationMappingUtility.upsertCustomSettings(
                    HELP_TEXT,
                    e.getMessage()
                );
            }
        } else {
            ApexPages.addMessage(
                new ApexPages.Message(
                    ApexPages.Severity.WARNING,
                    'There is a deployment currently in progess.'
                )
            );
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
            dataImportSettings =
                BDI_MigrationMappingUtility.upsertCustomSettings(
                    HELP_TEXT,
                    String.valueOf(Metadata.DeployStatus.Succeeded)
                );
            ApexPages.addMessage(
                new ApexPages.Message(
                    ApexPages.Severity.CONFIRM,
                    Label.stgDeploymentHelpTextMappingEnabled
                )
            );
        } catch (Exception e) {
            ERR_Handler.processError(e, ERR_Handler_API.Context.STTG);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));

            isPolling = false;
            BDI_MigrationMappingUtility.upsertCustomSettings(
                HELP_TEXT,
                e.getMessage()
            );
        }
        return null;
    }

    /**
     * @description Save the metadata deployment id in data import custom settings
     * @param deploymentId Metadata deployment id
     */
    @future
    public static void saveDeploymentId(String deploymentId) {
        Data_Import_Settings__c dataImportSettings = UTIL_CustomSettingsFacade.getDataImportSettings();
        dataImportSettings.CMT_Deployment_ID__c = deploymentId;

        try {
            upsert dataImportSettings;
        } catch (Exception e) {
            ERR_Handler.processError(e, ERR_Handler_API.Context.STTG);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
    }

    /*******************************************************************************************************
    * @description Action Method used by Poller to check status of CMDT deployment
    * @return void
    */
    public PageReference startPolling() {
        timeoutCount++;

        deployment = checkDeploymentStatus();
        dataImportSettings = UTIL_CustomSettingsFacade.getDataImportSettings();

        if (deployment != null) {
            Boolean isSuccess = deployment.status == Metadata.DeployStatus.Succeeded
                && dataImportSettings.Field_Mapping_Method__c == DATA_IMPORT_FIELD_MAPPING;

            if (isSuccess) {
                isPolling = false;
                ApexPages.addMessage(
                    new ApexPages.Message(
                        ApexPages.Severity.CONFIRM,
                        Label.stgDeploymentCustomMetadataMappingEnabled
                    )
                );
            } else if (deployment.status == Metadata.DeployStatus.FAILED) {
                isPolling = false;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.stgDeploymentTryAgain));
            }

        } else if (deployment == null && dataImportSettings.Field_Mapping_Method__c == DATA_IMPORT_FIELD_MAPPING) {
            isPolling = false;
            ApexPages.addMessage(
                new ApexPages.Message(
                    ApexPages.Severity.CONFIRM,
                    Label.stgDeploymentCustomMetadataMappingEnabled
                )
            );
        }

        if (timeoutCount > MAX_TIME_OUT) {
            // Reset instance of migration mapping utility
            migrationMappingUtility = new BDI_MigrationMappingUtility(new BDI_MigrationMappingHelper());
            isPolling = false;
            ApexPages.addMessage(
                new ApexPages.Message(
                    ApexPages.Severity.WARNING,
                    Label.stgDeploymentTimedOut + ' ' + Label.stgDeploymentTryAgain
                )
            );
            return null;
        }

        return null;
    }

    /*******************************************************************************************************
    * @description Method checks to see if we have a saved custom metadata deployment id,
    * inspects the deployment status, and sets the page's toggle status
    * @return Metadata.DeployResult
    */
    private Metadata.DeployResult checkDeploymentStatus() {
        dataImportSettings = UTIL_CustomSettingsFacade.getDataImportSettings();

        if (dataImportSettings.CMT_Deployment_ID__c != null) {
            String response = migrationMappingUtility.checkDeployStatus(dataImportSettings.CMT_Deployment_ID__c);
            DeployResultWrapper responseWrapper =
                (DeployResultWrapper)JSON.deserialize(response, DeployResultWrapper.class);

            if (responseWrapper != null && responseWrapper.deployResult != null) {
                updateToggleStatus(responseWrapper.deployResult.status);
            }

            return responseWrapper.deployResult;
        }
        return null;
    }

    /*******************************************************************************************************
    * @description Sets toggleDisabled boolean, should be disabled if we have an active deployment.
    * @return Metadata.DeployStatus
    */
    private void updateToggleStatus(Metadata.DeployStatus deploymentStatus) {
        if (deploymentStatus != null) {
            Boolean disabled = deploymentStatus == Metadata.DeployStatus.INPROGRESS
                || deploymentStatus == Metadata.DeployStatus.PENDING
                || deploymentStatus == Metadata.DeployStatus.CANCELING;

            if (disabled) {
                toggleDisabled = true;
            } else {
                toggleDisabled = false;
            }
        } else {
            toggleDisabled = false;
        }
    }

    /*******************************************************************************************************
    * @description Wrapper for Metadata.DeployResult
    */
    public class DeployResultWrapper {
        public Id id { get; set; }
        public Metadata.DeployResult deployResult { get; set; }
    }
}
