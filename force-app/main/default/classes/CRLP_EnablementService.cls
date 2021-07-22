/*
    Copyright (c) 2020, Salesforce.org
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
* @date 2020
* @group Customizable Rollups
* @group-content ../../ApexDocContent/Rollups2.htm
* @description Enablement Services for Customizable Rollups
*/
public inherited sharing class CRLP_EnablementService {

    private Customizable_Rollup_Settings__c crlpSettings {
        get {
            if (crlpSettings == null) {
                crlpSettings = UTIL_CustomSettingsFacade.getCustomizableRollupSettings();
            }
            return crlpSettings;
        } private set;
    }


    /*******************************************************************************************************
    * @description Fully enable Customizable Rollups by building the default configuration and deploying using
    * the Apex Metadata Api. If there are already defined rollups in the Rollup__mdt object, then just set the
    * custom settings field to true and reschedule the batch jobs (skipping the deployment step)
    * @return DeploymentJobId
    */
    public String enable(Boolean rescheduleBatchJobs) {
        verifyPermissions();

        // If there are existing Rollup__mdt records, just set the custom settings field to true, reschedule jobs, and return
        List<Rollup__mdt> existingRollups = CRLP_Rollup_SEL.cachedRollups;
        if (!existingRollups.isEmpty()) {
            crlpSettings.Customizable_Rollups_Enabled__c = true;
            Database.upsert(crlpSettings);
            if (rescheduleBatchJobs) {
                UTIL_MasterSchedulableHelper.setScheduledJobs();
            }
            UTIL_OrgTelemetry_SVC.asyncProcessNpspSettingsTelemetry();
            return null;
        }

        // Execute the full Custom Metadata Type deployment process
        String jobId = new CRLP_DefaultConfigBuilder_SVC()
            .withScheduleNpspBatchJobs(rescheduleBatchJobs)
            .convertLegacyRollupsIntoCustomizableRollups();
        if (Test.isRunningTest()) {
            jobId = '123';
        }

        return jobId;
    }

    /*******************************************************************************************************
    * @description Reset all Customizable Rollups by effectively redeploying them in their entirety
    * @return DeploymentJobId
    */
    public String reset() {
        verifyPermissions();

        // Execute the full Custom Metadata Type deployment process
        String jobId = new CRLP_DefaultConfigBuilder_SVC()
            .withScheduleNpspBatchJobs(true)
            .convertLegacyRollupsIntoCustomizableRollups();
        if (Test.isRunningTest()) {
            jobId = '123';
        }

        return jobId;
    }

    /*******************************************************************************************************
    * @description Action Method to disable Customizable Rollups and reschedule batch Jobs
    */
    public void disable() {
        verifyPermissions();

        crlpSettings.Customizable_Rollups_Enabled__c = false;
        Database.upsert(crlpSettings);

        UTIL_MasterSchedulableHelper.setScheduledJobs();
        UTIL_OrgTelemetry_SVC.asyncProcessNpspSettingsTelemetry();

        return;
    }

    /**
    * @description Verify that the current user has the appropriate permissions to Enable, Reset or Disable
    * Customizable Rollups. Throws an InsufficientPermissions exception if not.
    */
    private void verifyPermissions() {
        if (!STG_Panel.runningUserIsAdmin()) {
            throw new UTIL_Permissions.InsufficientPermissionException(System.Label.stgCRLPNonAdminError);
        }
    }

    /**
    * @description Returns a single instance of the RollupMetadataCallbackInterface
    */
    public static RollupMetadataHandler rollupHandlerInstance {
        get {
            if (rollupHandlerInstance == null) {
                rollupHandlerInstance = new RollupMetadataHandler();
            }
            return rollupHandlerInstance;
        } set;
    }

    /**************************************************************************************************************
    * @description Metadata Call back handler class to execute actions when the metadata has successfully been deployed
    * CallBackParams - pass through to the performSuccessHandler and performErrorHandler methods:
    *   - CallableApiParameters.PARAM_SCHEDULE_JOBS : true|false - to (re)schedule NPSP Batch Jobs upon completion; defaults to true
    *   - CallableApiParameters.PARAM_ROLLUP_TYPES : Pass to the DSO-Bridge Api to mark these specific types of rollups as "stale" (deprecated)
     *  -
    **/
    public class RollupMetadataHandler implements CMT_MetadataAPI.MetadataCallbackHandler {

        public Map<String, Object> params = new Map<String, Object>();

        /**********************************************************************************************************
        * @description success handler - will call the ApiService to set rollup as stale
        **/
        public void performSuccessHandler(Map<String, Object> callbackParams, String status) {
            updateDeploymentStatus(status, true);

            // Merge the exposed parameters with those passed into the method
            if (callbackParams == null) {
                callbackParams = new Map<String, Object>();
            }
            callbackParams.putAll(params);

            if (callbackParams.isEmpty()) {
                return;
            }

            CallableApiParameters paramService = new CallableApiParameters(callbackParams);

            try {
                Set<String> rollupTypes = paramService.getSetString(CallableApiParameters.PARAM_ROLLUP_TYPES);
                new CRLP_ApiService().setRollupStateAsStale(rollupTypes);
            } catch (Exception ex) {
                logError(ex);
            }

            try {
                Boolean scheduleJobsWhenComplete = paramService.getBoolean(CallableApiParameters.PARAM_SCHEDULE_JOBS, true);
                if (scheduleJobsWhenComplete) {
                    UTIL_MasterSchedulableHelper.setScheduledJobs();
                }
            } catch (Exception ex) {
                logError(ex);
            }

        }

        /**
        * @description error handler - will call the update deployment status
        */
        public void performErrorHandler(Map<String, Object> callbackParams, String status) {
            updateDeploymentStatus(status, false);
        }

        /**
        * @description write the deployment status to the custom settings object
        * @param status string of the status
        * @param isSuccess boolean that indicates if the rollups was sucessful
        */
        private void updateDeploymentStatus(String status, Boolean isSuccess) {
            Customizable_Rollup_Settings__c crlpSettings = UTIL_CustomSettingsFacade.getCustomizableRollupSettings();

            crlpSettings.CMT_API_Status__c = status;
            crlpSettings.Customizable_Rollups_Enabled__c = (isSuccess || crlpSettings.Customizable_Rollups_Enabled__c == true);

            update crlpSettings;
        }

        /**
        * @description Inserts an error log into the Error table
        * @param ex Exception object that is to be logged
        */
        private void logError(Exception ex) {
            Error__c rollupHandlerError = new Error__c(
                Error_Type__c = 'Rollup Metadata Handler Error',
                Object_Type__c = 'CustomMetadata',
                Context_Type__c = ERR_Handler_API.Context.CRLP.name(),
                Datetime__c = System.now(),
                Full_Message__c = ex.getMessage()
            );

            Database.insert(rollupHandlerError, true);
        }
    }
}