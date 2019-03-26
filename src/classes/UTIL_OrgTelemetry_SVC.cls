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
* @group Utilities
* @description Return some basic org and NPSP telemetry data to the License Management Application to assist with
* better understanding of how our customers use our application.
* This logic is called in two places:
*   1) When Customizable Rollups is enabled or disabled
*   2) During the Post-Install Script as part of a Package Update
* Note: FeatureManagement operations are subject to MIXED_DML errors and must be conducted asynchronously
* Uses "without sharing" so that it has full rights to query all records in all objects. This is needed to ensure a
* consistent return of telemetry data even if the process is called by different users with different permissions.
* Specific PII info is never queried or returned by this class.
*/
public without sharing class UTIL_OrgTelemetry_SVC {

    /**
     * @description A complete list of the Telemetry Types (at a high level) that are handled by this service class.
     * These are used by the batch job to process feature parameters in asynchronous groups to avoid governor
     * limit issues. The concept is that by separating each of these into smaller groupings that are processed
     * as separate child batch iterations, the entire process can complete even if for some reason one of the queries
     * against a table (such as a really huge Opportunity object) were to fail.
     */
    public enum TelemetryBatchCategory {
        NPSP_Settings,
        Org_Environment,
        Data_MaxNumRelatedOpps,
        Data_CountRdOpps,
        Data_CountRecurringDonations,
        Data_CountRds,
        Data_CountErrorLog
    }

    /**
     * @description Each of these corresponds to the exact name of a FeatureParameter in the managed package.
     */
    public enum TelemetryParameterName {
        IsEnabled_HouseholdAcctModel,
        IsEnabled_AddressVerification,
        IsEnabled_AutomaticPayments,
        IsEnabled_CustomizableRollups,
        IsEnabled_DefaultGAU,
        Data_CountErrorLog,
        Data_CountRdOppsAll,
        Data_CountRdOppsOpenEnded,
        Data_CountRdsWithDiffAmount,
        Data_CountRecurringDonationsAll,
        Data_MaxNumRelatedOpps,
        HasUserManagedTDTM,
        Org_CountNonEnglishLanguages,
        Org_IsEnabled_AdvancedMultiCurrency,
        Org_LongestRunningBatchLast7Days,
        Org_CountTimedOutBatchJobsLast7Days
    }

    @TestVisible
    private UTIL_FeatureManagement featureManager = new UTIL_FeatureManagement();

    /**
     * @description Execute the batch job that will process each telemetry featureParameter type one at a time
     * as individual batch iterations. This process has to be asynchronous to handle governor limits against
     * huge queries as well as to avoid MixedDML errors in case a calling process were to modify a record.
     */
    public static void dispatchTelemetryBatchJob() {
        Database.executeBatch(new UTIL_OrgTelemetry_BATCH(), 1);
    }

    /**
     * @description Called by the NPSP Settings Page to subject the current state of NPSP Settings related telemetry
     * data if it has been changed in the NPSP Settings page.
     * @param telemetryType
     */
    @Future
    public static void asyncProcessNpspSettingsTelemetry() {
        UTIL_OrgTelemetry_SVC telemetrySvc = new UTIL_OrgTelemetry_SVC();
        telemetrySvc.processTelemetryType(TelemetryBatchCategory.NPSP_Settings);
    }

    /**
     * @description Called by the batch job to process an individual telemetry type
     * Submits specific feature teletry statistics back to the License Management Org to assist
     * with understanding how our customers are using NPSP functionality.
     * Each feature below must be matched to a SubscriberToLmo feature of the same name.
     * @param telemetryCategory
     */
    public void processTelemetryType(TelemetryBatchCategory telemetryCategory) {

        switch on (telemetryCategory) {

            // Simple Boolean FeatureParameters based strictly on NPSP Settings that can be processed in a single
            // operation.
            when NPSP_Settings {
                handleNPSPSettings();
            }

            // Simple FeatureParameters based on the current organization configuration that can be processed
            // in a single operation.
            when Org_Environment {
                handleIsAdvancedMulticurrencyEnabled();
                handleNonEnglishLanguageCount();
                handleLongestRunningBatchLast7Days();
                handleCountTimedOutBatchJobsLast7Days();
            }

            when Data_MaxNumRelatedOpps {
                handleMaxNumRelatedOpps();
            }

            when Data_CountRdOpps {
                // Default these to -1 so we can determine (in the LMO) if there was an error retrieving them
                featureManager.setPackageIntegerValue(TelemetryParameterName.Data_CountRdOppsAll.name(), -1);
                featureManager.setPackageIntegerValue(TelemetryParameterName.Data_CountRdOppsOpenEnded.name(), -1);
            }

            when Data_CountRecurringDonations {
                // Default these to -1 so we can determine (in the LMO) if there was an error retrieving them
                featureManager.setPackageIntegerValue(TelemetryParameterName.Data_CountRecurringDonationsAll.name(), -1);
                featureManager.setPackageIntegerValue(TelemetryParameterName.Data_CountRdsWithDiffAmount.name(), -1);
            }

            when Data_CountErrorLog {
                handleErrorLogCount();
            }
        }
    }


    /**
     * @description Simple Boolean FeatureParameters based strictly on NPSP Settings that can be processed in a
     * operation.
     */
    private void handleNPSPSettings() {
        STG_SettingsService stgSvc = new STG_SettingsService();
        Addr_Verification_Settings__c addrVerifSettings = UTIL_CustomSettingsFacade.getAddressVerificationSettings();

        featureManager.setPackageBooleanValue(TelemetryParameterName.IsEnabled_HouseholdAcctModel.name(),
                stgSvc.stgCon.npe01__Account_Processor__c == CAO_Constants.HH_ACCOUNT_PROCESSOR);
        featureManager.setPackageBooleanValue(TelemetryParameterName.IsEnabled_AutomaticPayments.name(),
                (stgSvc.stgCon.npe01__Payments_Enabled__c == true));
        featureManager.setPackageBooleanValue(TelemetryParameterName.IsEnabled_DefaultGAU.name(),
                stgSvc.stgAllo.Default__c != null);
        featureManager.setPackageBooleanValue(TelemetryParameterName.IsEnabled_AddressVerification.name(),
                (addrVerifSettings.Enable_Automatic_Verification__c == true));
        featureManager.setPackageBooleanValue(TelemetryParameterName.IsEnabled_CustomizableRollups.name(),
                (stgSvc.stgCRLP.Customizable_Rollups_Enabled__c == true));
        if (!Test.isRunningTest()) {
            handleHasUserManagedTriggers();
        }
    }

    /**
     * @description Count the number of DatedConversionRate records with an effective date in the last 180 days.
     * If greater than 0, then consider AdvancedMultiCurrency to be enabled within an organization. This accounts for
     * the fact that this object is always visible, but may not actually have any valid/recent data in it; and because
     * there is no plan for core to ever fix this bug.
     */
    private void handleIsAdvancedMulticurrencyEnabled() {
        Boolean isEnabled=false;
        if (UserInfo.isMultiCurrencyOrganization() == true) {
            try {
                Integer count = Database.query('SELECT Id FROM DatedConversionRate WHERE StartDate = LAST_N_DAYS:180 LIMIT 1').size();
                if (count == 1) {
                    isEnabled = true;
                }
            } catch (Exception e) { }
        }
        featureManager.setPackageBooleanValue(TelemetryParameterName.Org_IsEnabled_AdvancedMultiCurrency.name(), isEnabled);
    }

    /**
     * @description Count the number of non-english languages associated with active standard users.
     */
    private void handleNonEnglishLanguageCount() {
        Set<String> languages = new Set<String>();
        for (User u : [SELECT LanguageLocaleKey
                FROM User
                WHERE IsActive = TRUE
                AND UserType = 'Standard'
                AND LanguageLocaleKey != 'en_US'
                ORDER BY LanguageLocaleKey]
        ) {
            if (u.LanguageLocaleKey != null && !u.LanguageLocaleKey.startsWithIgnoreCase('en_')) {
                languages.add(u.LanguageLocaleKey);
            }
        }
        featureManager.setPackageIntegerValue(TelemetryParameterName.Org_CountNonEnglishLanguages.name(), languages.size());
    }

    /**
     * @description Captures the longest running batch time in minutes of the last 7 days.
     */
    private void handleLongestRunningBatchLast7Days() {
        Integer longestJobLength = 0;

        for (AsyncApexJob job : [
            SELECT CreatedDate, CompletedDate
            FROM AsyncApexJob
            WHERE CreatedDate = LAST_N_DAYS:7
                AND JobType = 'BatchApex'
                AND Status IN ('Aborted', 'Completed', 'Failed')
                AND ApexClass.NamespacePrefix IN ('npsp', 'npe01', 'npo02', 'npe03', 'npe4', 'npe5')
        ]) {

            Integer jobLength = getMinutesBetween(job.CreatedDate, job.CompletedDate);
            longestJobLength = jobLength > longestJobLength ? jobLength : longestJobLength;

        }

        featureManager.setPackageIntegerValue(TelemetryParameterName.Org_LongestRunningBatchLast7Days.name(), longestJobLength);
    }

    /**
     * @description Calculates the number of minutes between two date times
     */
    @TestVisible
    private Integer getMinutesBetween(DateTime startDateTime, DateTime endDateTime) {
        Long startTime = startDateTime.addDays(-1).getTime();
        Long endTime = endDateTime.getTime();

        Long milliseconds = endTime - startTime;
        Long seconds = milliseconds / 1000;
        return Integer.valueOf(seconds / 60);
    }

    /**
     * @description Counts the number of batches that have a time out error within the last 7 days
     */
    private void handleCountTimedOutBatchJobsLast7Days() {
        Integer countTimeouts = 0;

        for (AsyncApexJob job : [
            SELECT ExtendedStatus
            FROM AsyncApexJob
            WHERE CreatedDate = LAST_N_DAYS:7
                AND JobType = 'BatchApex'
                AND Status IN ('Aborted', 'Completed', 'Failed')
                AND ApexClass.NamespacePrefix IN ('npsp', 'npe01', 'npo02', 'npe03', 'npe4', 'npe5')
                AND NumberOfErrors > 0
        ]) {

            if (batchHasTimeoutError(job)) {
                countTimeouts++;
            }

        }

        featureManager.setPackageIntegerValue(TelemetryParameterName.Org_CountTimedOutBatchJobsLast7Days.name(), countTimeouts);
    }

    /**
     * @description Determins whether batch has a time out error using the ExtendedStatus field
     */
    private Boolean batchHasTimeoutError(AsyncApexJob job) {
        String requestTooLongMessge = 'request_running_too_long';
        String cpuTimeOutMessage = 'cpu time limit';

        String status = job.ExtendedStatus.toLowerCase();

        return status.contains(requestTooLongMessge) || status.contains(cpuTimeOutMessage);
    }

    /**
     * @description Are there are any TDTM Trigger Handler records marked as Inactive or that the custom has added.
     */
    private void handleHasUserManagedTriggers() {
        Boolean hasUserManagedTrigger = false;
        for (Trigger_Handler__c th : TDTM_Config_API.getCachedRecords()) {
            if (th.User_Managed__c == true || th.Active__c == false) {
                hasUserManagedTrigger = true;
                break;
            }
        }
        featureManager.setPackageBooleanValue(TelemetryParameterName.HasUserManagedTDTM.name(), hasUserManagedTrigger);
    }

    /**
     * @description Total number of records in the Error__c custom object
     */
    private void handleErrorLogCount() {
        try {
            Integer count = Database.countQuery('SELECT Count() FROM Error__c');
            featureManager.setPackageIntegerValue(TelemetryParameterName.Data_CountErrorLog.name(), count);
        } catch (Exception ex) {
            featureManager.setPackageIntegerValue(TelemetryParameterName.Data_CountErrorLog.name(), -1);
        }
    }

    /**
     * @description Get the max number of attached opportunities (using by 'Total Number of Donations') for
     * all Accounts. Note that this will not return useful information if the organization is not using
     * NPSP rollups (either type)
     */
    private void handleMaxNumRelatedOpps() {
        try {
            Integer cnt = 0;
            List<Account> accts = [SELECT npo02__NumberOfClosedOpps__c
                FROM Account
                WHERE npo02__NumberOfClosedOpps__c > 0
                ORDER BY npo02__NumberOfClosedOpps__c DESC
                LIMIT 1];
            if (!accts.isEmpty()) {
                cnt = accts[0].npo02__NumberOfClosedOpps__c.intValue();
            }
            featureManager.setPackageIntegerValue(TelemetryParameterName.Data_MaxNumRelatedOpps.name(), cnt);
        } catch (Exception ex) {
            featureManager.setPackageIntegerValue(TelemetryParameterName.Data_MaxNumRelatedOpps.name(), -1);
        }
    }
}