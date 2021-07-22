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
* @group Recurring Donations
* @description Controller extension for enhanced Recurring Donation enablement panel
*/
public with sharing class RD2_EnablementDelegate_CTRL extends STG_Panel {

    /***
    * @description Indicates how many days dry validation is valid after completion
    */
    @TestVisible
    private static final Integer DRY_RUN_VALID_DAYS = 7;

    /***
    * @description Enablement service
    */
    @TestVisible
    private static RD2_EnablementService service {
        get {
            if (service == null) {
                service = new RD2_EnablementService();
            }
            return service;
        }
        set;
    }

    /***
    * @description The batch job service
    */
    @TestVisible
    private static UTIL_BatchJobService batchJobService {
        get {
            if (batchJobService == null) {
                batchJobService = new UTIL_BatchJobService();
            }
            return batchJobService;
        }
        set;
    }

    /***
    * @description Returns Day of Month field picklist value specific to enhanced Recurring Donations
    */
    @TestVisible
    private static String dayOfMonthPicklistValue {
        get {
            if (dayOfMonthPicklistValue == null) {
                dayOfMonthPicklistValue = RD2_Constants.DAY_OF_MONTH_LAST_DAY;
            }
            return dayOfMonthPicklistValue;
        }
        set;
    }

    /***
    * @description Indicates if the simple or the full enablement page version should be displayed
    */
    public static Boolean isSimpleVersion {
        get {
            if (isSimpleVersion == null) {
                isSimpleVersion = isSimplePageCandidate();
            }
            return isSimpleVersion;
        }
        set;
    }

    /***
    * @description A unique enhanced Recurring Donation enablement panel Id
    */
    public override String idPanel() {
        return 'idPanelRD2Enablement';
    }

    /***
    * @description An empty method called from actionFunction to reRender panels when it completes
    */
    public void refreshPanels() {

    }


    /***
    * @description Loads the enablement state so the current completed and pending options can be displayed
    * @return String JSON representation of the current EnablementState
    */
    @AuraEnabled(cacheable=false)
    public static String loadState() {
        EnablementState state = getEnablementState();

        if (!state.isEnabled && state.isConfirmed && isDryRunOutdated(state)) {
            state.isConfirmed = false;
        }

        return JSON.serialize(state);
    }

    /***
    * @description Retrieves the current enablement state
    * @return EnablementState
    */
    @TestVisible
    private static EnablementState getEnablementState() {
        EnablementState state = new EnablementState();

        try {
            String jsonState = UTIL_CustomSettingsFacade.getRecurringDonationsSettings().RecurringDonations2EnablementState__c;

            if (String.isNotBlank(jsonState)) {
                state = (EnablementState) JSON.deserialize(jsonState, EnablementState.class);
            }

            //do not use the enablement values from the settings but refresh them based on the configuration
            state.isReady = service.isRecurringDonations2Ready();
            state.isEnabled = service.isRecurringDonations2Enabled();

            if (String.isBlank(jsonState)) {
                state.isConfirmed = false;
                state.isMetaLaunched = false;
                state.isMetaConfirmed = false;
            } else {
                state.isMetaLaunched = state.isMetaLaunched && state.isEnabled;
                state.isMetaConfirmed = state.isMetaConfirmed && state.isMetaLaunched && hasMetaDeployCompleted();
            }

            state.dryRunLimit = getDryRunLimit(state);

        } catch (Exception e) {
            throwAuraHandledException(e.getMessage());
        }

        return state;
    }

    /***
    * @description Determines if the dry run is outdated.  When no legacy RD exists,
    * the validation is skipped and no warning should be displayed about outdated validation.
    * @param state Enablement state
    * @return Boolean
    */
    private static Boolean isDryRunOutdated(EnablementState state) {
        return (isSimpleVersion)
            ? false
            : batchJobService.getCompletedDaysBetween('RD2_DataMigrationDryRun_BATCH') > state.dryRunLimit;
    }

    /***
    * @description Retrieves number of days that dry run is valid after completion
    * @param state Enablement state
    * @return Integer
    */
    private static Integer getDryRunLimit(EnablementState state) {
        Integer dryRunLimit = DRY_RUN_VALID_DAYS;//default

        //if this is a scratch org, enable override for testing purposes
        if (UTIL_Namespace.isScratchOrg()) {
            try {
                if (state.dryRunLimit != null && state.dryRunLimit > 0) {
                    dryRunLimit = state.dryRunLimit;
                }
            } catch (Exception e) {}
        }

        return dryRunLimit;
    }

    /***
    * @description Tracks the enablement confirmation user action
    * @return void
    */
    @AuraEnabled
    public static void confirmEnablement() {
        EnablementState state = getEnablementState();

        if (isDryRunOutdated(state)) {
            throwAuraHandledException(System.Label.RD2_EnablementDryRunOutdatedError);
        }

        state.isConfirmed = true;
        saveEnablementState(state);
    }

    /***
    * @description Tracks the enhanced Recurring Donation enablement user action.
    * When the org does not have any RD record, a simple enablement page version is displayed,
    * and enablement will automatically set Enable Confirmation checkbox required
    * for the next metadata deploy step.
    * @return void
    */
    @AuraEnabled
    public static void enableEnhancement() {
        EnablementState state = getEnablementState();

        if (isDryRunOutdated(state)) {
            throwAuraHandledException(System.Label.RD2_EnablementDryRunOutdatedError);
        }

        if (isSimpleVersion) {
            state.isConfirmed = true;
            saveEnablementState(state);
        }

        try {
            Boolean shouldRescheduleJobs = true;
            enableEnhancement(shouldRescheduleJobs);

        } catch (Exception e) {
            throwAuraHandledException(e.getMessage());
        }
    }


    /***
    * @description Enables enhanced Recurring Donation feature from the callable API
    * @return void
    */
    public static void callableApiEnableEnhancement(Boolean rescheduleBatchJobs) {
        if (!STG_Panel.runningUserIsAdmin()) {
            throw new UTIL_Permissions.InsufficientPermissionException(System.Label.RD2_EnablementPermissionRequired);
        }

        Boolean isCrlpEnabled = new CRLP_ApiService().isCrlpEnabled();
        if (!isCrlpEnabled) {
            throw new EnablementException(System.Label.CRLP_DisabledMessage);
        }

        enableEnhancement(rescheduleBatchJobs);

        EnablementState state = getEnablementState();
        state.isConfirmed = true;

        if (hasMetaDeployCompleted()) {
            state.isMetaConfirmed = true;
            state.isMetaLaunched = true;
        }

        saveEnablementState(state);

        System.enqueueJob(new EnablementQueueable(QueueableMode.DisableRollup));
    }

    /***
    * @description Enables enhanced Recurring Donations feature.
    * Processes the NPSP Settings telemetry type asynchronously.
    * Reschedules scheduled jobs if they should be rescheduled.
    * @param shouldRescheduleJobs Indicates if scheduled jobs should be rescheduled
    * @return void
    */
    private static void enableEnhancement(Boolean shouldRescheduleJobs) {
        STG_Panel.stgService.stgRD.IsRecurringDonations2Enabled__c = true;

        if (!Test.isRunningTest()) {
            upsert STG_Panel.stgService.stgRD;
            UTIL_OrgTelemetry_SVC.asyncProcessNpspSettingsTelemetry();
        }

        if (shouldRescheduleJobs) {
            System.enqueueJob(new EnablementQueueable(QueueableMode.ScheduleJobs));
        }
    }

    /***
    * @description Returns metadata deploy link
    * @return String MetaDeploy URL
    */
    @AuraEnabled(cacheable=false)
    public static String getMetaDeployURL() {
        String urlFormat = 'https://install.salesforce.org/products/npsp/{0}enhanced-recurring-donations';
        String version;

        if (UTIL_Namespace.isCustomerOrg()) {
            UTIL_Version_API versionAPI = new UTIL_Version_API();

            //Note: the exception cannot be caught in Apex
            version = String.valueOf(versionAPI.requestVersion());
        }

        version = String.isBlank(version) ? '' : (version + '/');

        return String.format(
            urlFormat,
            new String[]{ version }
        );
    }

    /***
    * @description Tracks the MetaDeploy link click user action
    * @return void
    */
    @AuraEnabled
    public static void launchMetaDeploy() {
        EnablementState state = getEnablementState();
        state.isMetaLaunched = true;

        saveEnablementState(state);

        System.enqueueJob(new EnablementQueueable(QueueableMode.DisableRollup));

        if (!Test.isRunningTest()) {
            UTIL_OrgTelemetry_SVC.asyncProcessNpspSettingsTelemetry();
        }
    }

    /***
    * @description Tracks the MetaDeploy install confirmation user action.
    * @return void
    */
    @AuraEnabled
    public static void confirmMetaDeploy() {
        if (!hasMetaDeployCompleted()) {
            throwAuraHandledException(System.Label.RD2_EnablementMetaDeployConfirmError);
        }

        EnablementState state = getEnablementState();
        state.isMetaConfirmed = true;

        saveEnablementState(state);

        if (!Test.isRunningTest()) {
            UTIL_OrgTelemetry_SVC.asyncProcessNpspSettingsTelemetry();
        }
    }

    /***
    * @description Checks if MetaDeploy has completed
    * @return Boolean
    */
    private static Boolean hasMetaDeployCompleted() {
        List<SelectOption> lastDayOfMonthOptions = UTIL_Describe.getSelectOptions(
            String.valueOf(npe03__Recurring_Donation__c.SObjectType),
            SObjectType.npe03__Recurring_Donation__c.fields.Day_Of_Month__c.Name
        );

        for (SelectOption option : lastDayOfMonthOptions) {
            if (option.getValue() == dayOfMonthPicklistValue) {
                return true;
            }
        }
        return false;
    }

    /***
    * @description Skips dry run and moves straight to the migration
    * @return void
    */
    @AuraEnabled
    public static void skipDryRun() {
        setMigrationEnabled(true);
    }

    /***
    * @description Skips migration and moves back to the dry run
    * @return void
    */
    @AuraEnabled
    public static void skipMigration() {
        setMigrationEnabled(false);
    }

    /***
    * @description Sets migration enabled state
    * @param isMigrationEnabled Indicates if migration is enabled
    * @return void
    */
    private static void setMigrationEnabled(Boolean isMigrationEnabled) {
        EnablementState state = getEnablementState();
        state.isMigrationEnabled = isMigrationEnabled;

        saveEnablementState(state);
    }

    /***
    * @description Starts the dry run data migration
    * @return Id Batch Job Id
    */
    @AuraEnabled
    public static Id runDryRun() {
        Id jobId;

        try {
            Boolean isStateUpdate = false;
            EnablementState state = getEnablementState();

            if (state.isMetaConfirmed) {
                state.isDryRun2 = true;
                isStateUpdate = true;

            } else if (!state.isEnabled && state.isConfirmed) {
                state.isConfirmed = false;
                isStateUpdate = true;
            }

            if (isStateUpdate) {
                saveEnablementState(state);
            }

            RD2_DataMigrationDryRun_BATCH batch = new RD2_DataMigrationDryRun_BATCH();
            jobId = Database.executeBatch(batch, batch.batchSize);

        } catch (Exception e) {
            throwAuraHandledException(e.getMessage());
        }

        return jobId;
    }

    /***
    * @description Starts the data migration batch
    * @return Id Batch Job Id
    */
    @AuraEnabled
    public static Id runMigration() {
        Id jobId;
        try {
            RD2_DataMigration_BATCH batch = new RD2_DataMigration_BATCH();
            jobId = Database.executeBatch(batch, batch.batchSize);

        } catch (Exception e) {
            throwAuraHandledException(e.getMessage());
        }

        return jobId;
    }

    /***
    * @description Starts the data migration batch based onthe the Callable API request
    * @return Id Batch Job Id
    */
    public static Id callableApiRunMigration() {
        if (!RD2_EnablementService.getInstance().isRecurringDonations2Enabled()) {
            throw new EnablementException(System.Label.RD2_ErrorDataMigrationJobCannotBeRun);
        }

        if (!STG_Panel.runningUserIsAdmin()) {
            throw new UTIL_Permissions.InsufficientPermissionException(System.Label.RD2_EnablementPermissionRequired);
        }

        setMigrationEnabled(true);

        RD2_DataMigration_BATCH batch = new RD2_DataMigration_BATCH();
        return Database.executeBatch(batch, batch.batchSize);
    }

    /***
    * @description Saves the current enablement state
    * @param state Enablement state
    * @return void
    */
    private static void saveEnablementState(EnablementState state) {
        try {
            //save the state
            STG_Panel.stgService.stgRD.RecurringDonations2EnablementState__c = JSON.serialize(state);

            if (!Test.isRunningTest()) {
                upsert STG_Panel.stgService.stgRD;
            }

        } catch (Exception e) {
            throwAuraHandledException(e.getMessage());
        }
    }

    /***
    * @description Stops the archive batch process
    */
    @AuraEnabled
    public static void stopProcessing(Id batchId) {
        if (batchId == null) {
            return;
        }

        try {
            System.abortJob(batchId);

        } catch (Exception e) {
            throwAuraHandledException(e.getMessage());
        }
    }

    /***
    * @description Throws AuraHandledException
    * @param errMessage
    * @return void
    */
    private static void throwAuraHandledException(String errMessage) {
        AuraHandledException e = new AuraHandledException(errMessage);
        e.setMessage(errMessage);
        throw e;
    }

    /***
    * @description Determine if the enablement page should be in simple or full version
    * @return Boolean
    */
    private static Boolean isSimplePageCandidate() {
        Boolean noLegacyRd = [
            SELECT Id
            FROM npe03__Recurring_Donation__c
            WHERE (Status__c = null OR InstallmentFrequency__c = null)
            LIMIT 1].isEmpty();

        Boolean noMigrationRan = String.isBlank(UTIL_CustomSettingsFacade.getRecurringDonationsSettings().RecurringDonations2MigrationState__c);

        return noLegacyRd && noMigrationRan;
    }


    /***
    * @description Represents enhanced Recurring Donation options and status
    */
    public class EnablementState {
        public Boolean isReady = false;
        public Boolean isConfirmed = false;
        public Boolean isEnabled = false;
        public Boolean isMetaLaunched = false;
        public Boolean isMetaConfirmed = false;
        public Boolean isDryRun2 = false;
        public Boolean isMigrationEnabled = false;
        public Integer dryRunLimit = DRY_RUN_VALID_DAYS;
    }

    /**
    * @description Defines the modes that the Queueable enablement job runs in
    */
    public enum QueueableMode {
        ScheduleJobs,
        DisableRollup
    }

    /**
     * @description Queueable to schedule the new RD Job OR to disable a legacy CRLP
     * rollup for Recurring Donations. Queueable needed to avoid a Mixed DML Operation error.
     */
    private class EnablementQueueable implements Queueable {

        private QueueableMode mode;

        /**
        * @description Constructor
        * @param mode Job Mode
        */
        public EnablementQueueable(QueueableMode mode) {
            this.mode = mode;
        }

        /**
        * @description Execute for the queueable. Delegates processing to the appropriate service
        */
        public void execute(QueueableContext context) {

            switch on (mode) {
                when ScheduleJobs {
                    if (!Test.isRunningTest()) {
                        UTIL_MasterSchedulableHelper.setScheduledJobs();
                    }
                }

                when DisableRollup {
                    disableNextPaymentDateRollup();
                }
            }

        }

        /**
        * @description When Enhanced Recurring Donations is enabled, the "Next Donation Date" field
        * (npe03__Next_Payment_Date__c) is no longer calculated as a rollup, but instead is calculated
        * as a service process in many places during Enhanced Recurring Donations automation. The previous
        * rollup was inaccurate in what it calculated relative to the field label. In legacy RD, this
        * field actually contained the CloseDate of the earliest open Opportunity associated with the RD.
        * In Enhanced Recurring Donations this field will contain the "next" expected installment due date
        * where "next" means always in the future.
        */
        private void disableNextPaymentDateRollup() {
            List<Rollup__mdt> rdRollups = CRLP_Rollup_SEL.getRollupsBySummaryType().get(npe03__Recurring_Donation__c.SObjectType);
            if (rdRollups == null) {
                return;
            }

            CRLP_RollupCMT.Rollup cmtRollup;
            for (Rollup__mdt rlp : rdRollups) {
                if (rlp.Summary_Field__r.QualifiedApiName == 'npe03__Next_Payment_Date__c') {
                    cmtRollup  = new CRLP_RollupCMT.Rollup(rlp);
                    break;
                }
            }

            if (cmtRollup == null) {
                return;
            }

            // Disable/Hide the rollup and update the Description on the rollup to reflect the change
            cmtRollup.isDeleted = true;
            cmtRollup.isActive = false;
            cmtRollup.description += '\nThis rollup was disabled automatically when Enhanced Recurring Donations was enabled.';

            List<CRLP_RollupCMT.Rollup> rollups = new List<CRLP_RollupCMT.Rollup>{ cmtRollup };
            CRLP_EnablementService.RollupMetadataHandler changeHandler = new CRLP_ApiService()
                .sendChangeEvent(rollups)
                .getCallbackHandler();

            CRLP_ConfigBuilder_SVC.queueRollupConfigForDeploy(rollups);
            CRLP_ConfigBuilder_SVC.deployedQueuedMetadataTypes(changeHandler, changeHandler.params);
        }
    }

    /**
    * @description Custom enablement exception
    */
    private class EnablementException extends Exception { }
    
}
