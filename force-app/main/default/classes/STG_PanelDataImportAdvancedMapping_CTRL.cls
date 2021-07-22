/*
    Copyright (c) 2019, Salesforce.org
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
* @date 2019
* @group Settings
* @group-content ../../ApexDocContent/Settings.htm
* @description Controller extension for the Data Import Fied Mapping settings panel.
*/
public with sharing class STG_PanelDataImportAdvancedMapping_CTRL extends STG_Panel {
    /*********************************************************************************************************
    * @description URL of the Advanced Mapping Custom UI aura component container
    */
    public static String componentUrl = '/lightning/cmp/npsp__BDI_ManageAdvancedMapping';

    /*********************************************************************************************************
    * @description Returns the string Id of the Data Import Advanced Mapping panel
    */
    public override String idPanel() { return 'idPanelDataImportAdvancedMapping'; }

    /*******************************************************************************************************
    * @description Partial url path and parameters for building a link to a deployment status page
    */
    private final String DEPLOYMENT_STATUS_PAGE_PATH = '/lightning/setup/DeployStatus/page?' +
        'address=/changemgmt/monitorDeploymentsDetails.apexp?asyncId=';

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
    private Data_Import_Settings__c dataImportSettings { get; set; }

    private Gift_Entry_Settings__c giftEntrySettings { get; set; }

    /*******************************************************************************************************
    * @description Boolean used for the Advanced Mapping toggle value in the visualforce page
    */
    public Boolean isAdvancedMappingEnabled {
        get {
            if (dataImportSettings.Field_Mapping_Method__c == BDI_MigrationMappingUtility.DATA_IMPORT_FIELD_MAPPING) {
                return true;
            }
            return false;
        }
        set;
    }

    /*******************************************************************************************************
    * @description Boolean used for the Gift Entry toggle value in the visualforce page
    */
    public Boolean isGiftEntryEnabled {
        get {
            giftEntrySettings = GE_GiftEntryController.getGiftEntrySettings();
            return giftEntrySettings.Enable_Gift_Entry__c;
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
    private Metadata.DeployResult deploymentResult { get; set; }

    /*******************************************************************************************************
    * @description Boolean that determines if the toggle should be disabled
    */
    public Boolean hasDeploymentInProgress {
        get {
            if (deploymentResult != null) {
                hasDeploymentInProgress = deploymentResult.status == Metadata.DeployStatus.INPROGRESS
                    || deploymentResult.status == Metadata.DeployStatus.PENDING
                    || deploymentResult.status == Metadata.DeployStatus.CANCELING;
                return hasDeploymentInProgress;
            }
            return false;
        }
        set;
    }

    /*******************************************************************************************************
    * @description Instance of BDI_MigrationMappingUtility
    */
    public BDI_MigrationMappingUtility migrationMappingUtility { get; set; }

    /*******************************************************************************************************
    * @description Constructor for STG_PanelDataImportAdvancedMapping_CTRL class
    */
    public STG_PanelDataImportAdvancedMapping_CTRL() {
        this.migrationMappingUtility = new BDI_MigrationMappingUtility(new BDI_MigrationMappingHelper());
        refreshCustomSettings();
        setDeploymentStatus();
    }

    /*******************************************************************************************************
    * @description Action Method to navigate to separate VF page that contains custom Advanced Mapping UI in
    * Aura and Lightning
    *
    * @return PageReference
    */
    public PageReference navigate() {
        String namespace = UTIL_Namespace.getNamespace();
        String newPrefix;

        //If the namespace being used is not npsp then replace with the current namespace if there is one
        if (UTIL_Namespace.shouldAlignNamespace) {
            if (!String.isBlank(namespace)) {
                newPrefix = namespace;
            } else {
                newPrefix = 'c';
            }
            componentUrl = componentUrl.replace(UTIL_Namespace.HARDCODED_NPSP_NAMESPACE + '__', newPrefix + '__');
        }

        PageReference advancedMapping = new PageReference(componentUrl);
        advancedMapping.setRedirect(true);
        return advancedMapping;
    }

    /*******************************************************************************************************
    * @description Action Method to enable Custom Metadata mapping and update data import custom settings
    * @return null
    */
    public PageReference enableDataImportFieldMapping() {
        STG_SettingsManager_CTRL.idPanelCurrent = idPanel();

        // Check the deployment status and set hasDeploymentInProgress value
        refreshCustomSettings();
        setDeploymentStatus();

        if (hasDeploymentInProgress == true) {
            addPageMessage(ApexPages.Severity.WARNING, Label.bdiDeploymentInProgress);
        } else {
            Savepoint sp = Database.setSavepoint();
            try {
                isPolling = true;

                // Start the migration, collect help text mappings, and compare against existing cmt mappings
                migrationMappingUtility.migrateHelpTextToCustomMetadata();

                Id deploymentId = CMT_MetadataAPI.deployMetadata(
                    migrationMappingUtility.queuedMetadataTypesForDeploy,
                    new BDI_MigrationMappingUtility.DeploymentCallback());

                saveDeploymentId(deploymentId);

            } catch (Exception e) {
                Database.rollback(sp);
                addPageMessage(ApexPages.Severity.ERROR, Label.bdiErrorDeploymentFailed + ' ' + e.getMessage());

                isPolling = false;
                BDI_MigrationMappingUtility.updateCustomSettings(BDI_MigrationMappingUtility.HELP_TEXT,
                    e.getMessage());
            }
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
                BDI_MigrationMappingUtility.updateCustomSettings(BDI_MigrationMappingUtility.HELP_TEXT,
                    String.valueOf(Metadata.DeployStatus.Succeeded));
            disableGiftEntry();
            addPageMessage(ApexPages.Severity.INFO, Label.stgDeploymentHelpTextMappingEnabled);
        } catch (Exception e) {
            addPageMessage(ApexPages.Severity.ERROR,
                Label.bdiErrorDataImportCustomSettings + ' ' + e.getMessage());

            isPolling = false;
            BDI_MigrationMappingUtility.updateCustomSettings(BDI_MigrationMappingUtility.HELP_TEXT,
                e.getMessage());
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
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
                Label.bdiErrorDataImportCustomSettings + ' ' + e.getMessage()));
        }
    }

    /*******************************************************************************************************
    * @description Action Method used by Poller to check status of CMDT deployment
    * @return void
    */
    public PageReference startPolling() {
        timeoutCount++;

        refreshCustomSettings();
        setDeploymentStatus();

        if (deploymentResult != null) {
            // We had a migration that contained CMT records to insert
            Boolean isSuccess = deploymentResult.status == Metadata.DeployStatus.Succeeded
                && dataImportSettings.Field_Mapping_Method__c == BDI_MigrationMappingUtility.DATA_IMPORT_FIELD_MAPPING;

            if (isSuccess) {
                isPolling = false;
                successMessage();
            } else if (deploymentResult.status == Metadata.DeployStatus.FAILED) {
                isPolling = false;
                addPageMessage(ApexPages.Severity.ERROR,
                    Label.bdiErrorDeploymentFailed + ' ' +
                    deploymentStatusUrl());
            }

        } else if (deploymentResult == null
                   && dataImportSettings.Field_Mapping_Method__c == BDI_MigrationMappingUtility.DATA_IMPORT_FIELD_MAPPING) {
            // We had a migration that didn't contain CMT records to insert
            // DeploymentContainer was empty which means we're using our standard field mapping set
            // Org had no conflicting field mappings nor any net new field mappings in their Data Import help text
            isPolling = false;
            successMessage();
        }

        if (timeoutCount > MAX_TIME_OUT && isPolling == true) {
            isPolling = false;
            addPageMessage(ApexPages.Severity.WARNING,
                Label.stgDeploymentTimedOut + ' ' +
                Label.bdiMigrationLongDeployment + ' ' +
                deploymentStatusUrl());
        }

        return null;
    }

    /*******************************************************************************************************
    * @description Display successful enablement of Advanced Mapping based on if there were some invalid
    * help text mappings
    */
    private void successMessage() {
        if (migrationMappingUtility.badHelpTextMappings.size() > 0) {
            addPageMessage(ApexPages.Severity.WARNING, Label.stgDeploymentHasInvalidHelpTextMappings);
        } else {
            addPageMessage(ApexPages.Severity.CONFIRM, Label.stgDeploymentCustomMetadataMappingEnabled);
        }
    }

    /*******************************************************************************************************
    * @description Builds the message with a url to deployment status that we display when a deployment
    * times out.
    */
    private String deploymentStatusUrl() {
        String href = DEPLOYMENT_STATUS_PAGE_PATH + deploymentResult.id;
        String url = String.format(
            label.bdiErrorDeploymentFailedLink,
            new String[]{ String.valueOf(href) });

        return url;
    }

    /*******************************************************************************************************
    * @description Checks to see if we have a saved custom metadata deployment id and sets deploymentResult
    */
    private void setDeploymentStatus() {
        if (dataImportSettings.CMT_Deployment_ID__c != null) {
            try {
                deploymentResult =
                    CMT_MetadataAPI.getDeploymentResult(dataImportSettings.CMT_Deployment_ID__c);
            } catch (Exception e) {
                deploymentResult = null;
            }
        }
    }

    /*******************************************************************************************************
    * @description Checks to see if we have a saved custom metadata deployment id,
    * inspects the deployment status, and sets the hasDeploymentInProgress boolean
    */
    private void refreshCustomSettings() {
        dataImportSettings = Data_Import_Settings__c.getInstance();
    }

    /*******************************************************************************************************
    * @description Adds a message to the Page
    *
    * @param severity: Severity level of message
    * @param message: Text to be displayed
    */
    private void addPageMessage(ApexPages.Severity severity, String message) {
        ApexPages.addMessage(new ApexPages.Message(severity, message));
    }

    /*******************************************************************************************************
    * @description Action Method to enable Gift Entry
    * @return null
    */
    public PageReference enableGiftEntry() {
        Gift_Entry_Settings__c giftEntrySettings =
                GE_GiftEntryController.getGiftEntrySettings();
        if (!giftEntrySettings.Enable_Gift_Entry__c) {
                giftEntrySettings.Enable_Gift_Entry__c = true;
            try {
                upsert giftEntrySettings;
                addPageMessage(ApexPages.Severity.CONFIRM, System.Label.geEnableGiftEntrySuccess);
            } catch(DmlException e) {
                addPageMessage(ApexPages.Severity.ERROR,
                        e.getDmlMessage(0));
            }
        }
        return null;
    }

    /*******************************************************************************************************
    * @description Action Method to disable Gift Entry
    * @return null
    */
    public PageReference disableGiftEntry() {
        Gift_Entry_Settings__c giftEntrySettings =
                GE_GiftEntryController.getGiftEntrySettings();
        if (giftEntrySettings.Enable_Gift_Entry__c) {
                giftEntrySettings.Enable_Gift_Entry__c = false;
            try {
                upsert giftEntrySettings;
                addPageMessage(ApexPages.Severity.INFO, System.Label.geDisableGiftEntryInfo);
            } catch(DmlException e) {
                addPageMessage(ApexPages.Severity.ERROR,
                        e.getDmlMessage(0));
            }
        }
        return null;
    }
}
