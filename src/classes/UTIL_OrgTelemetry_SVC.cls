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
* Uses "without sharing" so that it has full rights to query all records in all objects. This is needed to ensure a
* consistent return of telemetry data even if the process is called by different users with different permissions.
* Specific PII info is never queried or returned by this class.
*/
public without sharing class UTIL_OrgTelemetry_SVC {

    /**
     * @description A complete list of the Telemetry Types (at a high level) that are handled by this service class.
     */
    public Enum TelemetryTypeEnum {
        NPSP_Settings,
        Org_Environment,
        Data_OldestOppCloseDate,
        Data_MaxNumRelatedOpps,
        Data_MaxAffilationsToAccount,
        Data_MaxRelationshipsToContact,
        Data_CountOfErrorLog,
        InUse_EngagementPlans,
        InUse_AutomatedSoftCredits,
        InUse_AccountSoftCredits
    }

    /**
     * @description Execute the batch job that will process each telemetry featureParameter type one at a time
     * as individual batch iterations. This process has to be asynchronous to handle governor limits against
     * huge queries as well as to avoid MixedDML errors in case a calling process were to modify a record.
     */
    public static void dispatchTelemetryBatchJob() {
        database.executeBatch(new UTIL_OrgTelemetry_BATCH(), 1);
    }

    /**
     * @description Called by an individual synchronous page (i.e., NPSP Settings) to process an individual telemetry type.
     * @param telemetryType
     */
    @future
    public static void processNPSPSettingTelemetry_ASync() {
        processTelemetryType(TelemetryTypeEnum.NPSP_Settings);
    }

    /**
     * @description Submit specific feature enablement statistics back to the License Management Org to assist
     * with understanding how our customers are using our functionality. There's no way to unit test this though.
     * Each feature below must be matched to a SubscriberToLmo feature of the same name.
     * This should called in two places: 1) When the Settings page is loaded; 2) When a tracked area is saved.
     * FeatureManagement operations are subject to MIXED_DML errors and must be conducted asynchronously
     */
    /**
     * @description Called by the batch job to process an individual telemetry type
     * @param telemetryType
     */
    public static void processTelemetryType(TelemetryTypeEnum telemetryType) {


        switch on (telemetryType) {

            // Simple Boolean FeatureParameters based strictly on NPSP Settings that can be processed in a single
            // operation.
            when NPSP_Settings {
                STG_SettingsService stgSvc = new STG_SettingsService();
                Addr_Verification_Settings__c addrVerifSettings = UTIL_CustomSettingsFacade.getAddressVerificationSettings();

                System.FeatureManagement.setPackageBooleanValue('IsEnabled_CustomizableRollups',
                        (stgSvc.stgCRLP.Customizable_Rollups_Enabled__c == true));
                System.FeatureManagement.setPackageBooleanValue('IsEnabled_ScheduledJobs',
                        (stgSvc.stgErr.Don_t_Auto_Schedule_Default_NPSP_Jobs__c != true));
                System.FeatureManagement.setPackageBooleanValue('IsEnabled_HouseholdAcctModel',
                        stgSvc.stgCon.npe01__Account_Processor__c == CAO_Constants.HH_ACCOUNT_PROCESSOR);
                System.FeatureManagement.setPackageBooleanValue('IsEnabled_AutomaticPayments',
                        (stgSvc.stgCon.npe01__Payments_Enabled__c == true));
                System.FeatureManagement.setPackageBooleanValue('IsEnabled_DefaultGAU',
                        stgSvc.stgAllo.Default__c != null);
                System.FeatureManagement.setPackageBooleanValue('IsEnabled_AddressVerification',
                        (addrVerifSettings.Enable_Automatic_Verification__c == true));
                System.FeatureManagement.setPackageBooleanValue('HasUserManagedTDTM', getHasUserManagedTriggers());

            }

            // Simple Boolean FeatureParameters based on the current organization configuration that can be processed
            // in a single operation.
            when Org_Environment {
                System.FeatureManagement.setPackageBooleanValue('Org_IsEnabled_AdvancedMultiCurrency', getIsAdvancedMulticurrencyEnabled());
                System.FeatureManagement.setPackageBooleanValue('Org_HasNonEnglishUsers', getHasNonEnglishUsers());
                System.FeatureManagement.setPackageBooleanValue('Org_IsAdminUserInLightning', USER_UserService.isUserRunningLightning());
            }

            when InUse_AccountSoftCredits {
                Integer ascCount = [SELECT Count() FROM Account_Soft_Credit__c WHERE CreatedDate = LAST_N_DAYS:60 LIMIT 1];
                System.FeatureManagement.setPackageBooleanValue('InUse_AccountSoftCredits', (ascCount == 1));
            }

            when InUse_AutomatedSoftCredits {
                Integer relCount = [SELECT Count() FROM npe4__Relationship__c WHERE Related_Opportunity_Contact_Role__c != null
                        AND LastModifiedDate = LAST_N_DAYS:60 LIMIT 1];
                Integer alfCount = [SELECT Count() FROM npe5__Affiliation__c WHERE Related_Opportunity_Contact_Role__c != null
                        AND LastModifiedDate = LAST_N_DAYS:60 LIMIT 1];
                System.FeatureManagement.setPackageBooleanValue('InUse_AutomatedSoftCredits', (relCount == 1 || alfCount == 1));
            }

            when InUse_EngagementPlans {
                // Query???
                System.FeatureManagement.setPackageBooleanValue('InUse_EnagagementPlans', false);
            }

            when Data_CountOfErrorLog {
                System.FeatureManagement.setPackageIntegerValue('Data_CountOfErrorLog', getErrorLogCount());
            }

            when Data_OldestOppCloseDate {
                Date oldestDate = getOldestCloseDate();
                if (oldestDate != null) {
                    System.FeatureManagement.setPackageDateValue('Data_OldestOppCloseDate', oldestDate);
                }
            }
            when Data_MaxNumRelatedOpps {
                Integer relatedOpps = getMaxNumRelatedOpps();
                if (relatedOpps != null) {
                    System.FeatureManagement.setPackageIntegerValue('Data_MaxNumRelatedOpps', relatedOpps);
                }
            }
            when Data_MaxAffilationsToAccount {
                Integer maxAffiliations = getMaxAffiliationToAccount();
                if (maxAffiliations != null) {
                    System.FeatureManagement.setPackageIntegerValue('Data_MaxAffilationsToAccount', maxAffiliations);
                }
            }
            when Data_MaxRelationshipsToContact {
                Integer maxRelationships = getMaxRelationships();
                if (maxRelationships != null) {
                    System.FeatureManagement.setPackageIntegerValue('Data_MaxRelationshipsToContact', maxRelationships);
                }
            }
        }
    }

    private static Boolean getIsAdvancedMulticurrencyEnabled() {
        if (UserInfo.isMultiCurrencyOrganization() == true) {
            try {
                Integer DCRCount = Database.query('SELECT Id FROM DatedConversionRate WHERE StartDate = LAST_N_DAYS:180 LIMIT 1').size();
                if (DCRCount == 1) {
                    return true;
                }
            } catch (Exception e) { }
        }
        return false;
    }

    /**
     * @description Returns true if there are any active User records with a local language that does not start with "EN"
     */
    private static Boolean getHasNonEnglishUsers() {
        return getNonEnglishLanguageCount() > 0;
    }

    /**
     * @description Returns the number of non-english languages associated with active standard users.
     */
    public static Integer getNonEnglishLanguageCount() {
        Set<String> languages = new Set<String>();
        for (User u : [SELECT LanguageLocaleKey FROM User
                WHERE IsActive = TRUE AND UserType = 'Standard' AND LanguageLocaleKey != 'en_US'
                ORDER BY LanguageLocaleKey]) {
            if (u.LanguageLocaleKey != null && !u.LanguageLocaleKey.startsWithIgnoreCase('en_')) {
                languages.add(u.LanguageLocaleKey);
            }
        }
        return languages.size();
    }

    /**
     * @description Returns true if there are any TDTM Handler records with User_Managed__c=true or Active=false
     */
    private static Boolean getHasUserManagedTriggers() {
        Boolean hasUserManagedTrigger = false;
        if (!Test.isRunningTest()) {
            // getCachedRecords will attempt to create default records which creates a MixedDML error in a unit test
            for (Trigger_Handler__c th : TDTM_Config_API.getCachedRecords()) {
                if (th.User_Managed__c == true || th.Active__c == false) {
                    hasUserManagedTrigger = true;
                    break;
                }
            }
        }
        return hasUserManagedTrigger;
    }

    /**
     * @description Returns the total number of records in the Error__c custom object
     */
    private static Integer getErrorLogCount() {
        Integer cnt = [SELECT Count() FROM Error__c];
        return cnt;
    }

    /**
     * @description Returns the oldest CloseDate from the Opportunity object
     */
    private static Date getOldestCloseDate() {
        try {
            Opportunity opp = [SELECT CloseDate FROM Opportunity ORDER BY CloseDate ASC LIMIT 1];
            if (opp != null) {
                return opp.CloseDate;
            }
        } catch (Exception ex) {}
        return null;
    }

    /**
     * @description Returns the max number of attached opportunities (going by 'Total Number of Donations') for
     * all Accounts.
     */
    private static Integer getMaxNumRelatedOpps() {
        try {
            Account acct = [SELECT npo02__NumberOfClosedOpps__c FROM Account
                                ORDER BY npo02__NumberOfClosedOpps__c DESC LIMIT 1];
            if (acct != null && acct.npo02__NumberOfClosedOpps__c != null) {
                return acct.npo02__NumberOfClosedOpps__c.intValue();
            }
        } catch (Exception ex) {}
        return null;
    }

    /**
     * @description Returns the max number of affiliations attached to any one specific Account
     */
    private static Integer getMaxAffiliationToAccount() {
        try {
            List<AggregateResult> ag = [SELECT Count(Id) MaxPerOrg FROM npe5__Affiliation__c
                GROUP BY npe5__Organization__c
                ORDER BY Count(Id) LIMIT 1];
            if (ag != null && ag.size() == 1) {
                return (Integer) ag[0].get('MaxPerOrg');
            }
        } catch (Exception ex) {}
        return null;
    }

    /**
     * @description Returns the max number of relationships attached to any one specific Contact
     */
    private static Integer getMaxRelationships() {
        try {
            List<AggregateResult> ag = [SELECT Count(Id) MaxRel FROM npe4__Relationship__c
                GROUP BY npe4__Contact__c
                ORDER BY Count(Id) LIMIT 1];
            if (ag != null && ag.size() == 1) {
                return (Integer) ag[0].get('MaxRel');
            }
        } catch (Exception ex) {}
        return null;
    }
}