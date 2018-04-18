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
*/
public without sharing class UTIL_OrgTelemetry_SVC {

    /**
    * @description Submit specific feature enablement statistics back to the License Management Org to assist
    * with understanding how our customers are using our functionality. There's no way to unit test this though.
    * Each feature below must be matched to a SubscriberToLmo feature of the same name.
    * This should called in two places: 1) When the Settings page is loaded; 2) When a tracked area is saved.
    * FeatureManagement operations are subject to MIXED_DML errors and must be conducted asynchronously
    */
    @future
    public static void submitFeatureTelemetryToLMO_ASync() {
        STG_SettingsService stgSvc = new STG_SettingsService();
        Addr_Verification_Settings__c addrVerifSettings = UTIL_CustomSettingsFacade.getAddressVerificationSettings();

        System.FeatureManagement.setPackageBooleanValue('IsEnabled_CustomizableRollups', (stgSvc.stgCRLP.Customizable_Rollups_Enabled__c == true));

        // TODO -- Determine what else we want to track in the future. Below are some sample possibilities
        /*
        // NPSP Settings Detail
        System.FeatureManagement.setPackageBooleanValue('IsEnabled_ScheduledJobs', (stgSvc.stgErr.Don_t_Auto_Schedule_Default_NPSP_Jobs__c != true));
        System.FeatureManagement.setPackageBooleanValue('IsEnabled_HouseholdAcctModel', stgSvc.stgCon.npe01__Account_Processor__c == CAO_Constants.HH_ACCOUNT_PROCESSOR);
        System.FeatureManagement.setPackageBooleanValue('IsEnabled_AutomaticPayments', (stgSvc.stgCon.npe01__Payments_Enabled__c == true));
        System.FeatureManagement.setPackageBooleanValue('IsEnabled_DefaultGAU', stgSvc.stgAllo.Default__c != null);
        System.FeatureManagement.setPackageBooleanValue('IsEnabled_AddressVerification', (addrVerifSettings.Enable_Automatic_Verification__c == true));
        System.FeatureManagement.setPackageBooleanValue('hasUserManagedTDTM', getHasUserManagedTriggers());

        // Org Shape Information
        System.FeatureManagement.setPackageBooleanValue('IsEnabled_MultiCurrency', UTIL_Currency.getInstance().isMultiCurrencyOrganization());
        System.FeatureManagement.setPackageBooleanValue('IsEnabled_AdvancedMultiCurrency', UTIL_Currency.getInstance().isAdvancedCurrencyManagementEnabled());
        System.FeatureManagement.setPackageBooleanValue('HasNonEnglishUsers', getHasNonEnglishUsers());
        System.FeatureManagement.setPackageDateValue('OldestOppCloseDate', getOldestCloseDate());
        System.FeatureManagement.setPackageIntegerValue('MaxNumRelatedDonations', getMaxNumRelatedOpps());
        */
    }

    /**
     * @description Returns true if there are any active User records with a local language that does not start with "EN"
     */
    /*private static Boolean getHasNonEnglishUsers() {
        Integer userCnt = [SELECT Count() FROM User WHERE IsActive = True AND (NOT LanguageLocaleKey LIKE 'en_%')];
        return userCnt > 0;
    }*/

    /**
     * @description Returns true if there are any active TDTM Handler records with User_Managed__c=true
     */
    /*private static Boolean getHasUserManagedTriggers() {
        Boolean hasUserManagedTrigger = false;
        for (Trigger_Handler__c th : TDTM_Config_API.getCachedRecords()) {
            if (th.User_Managed__c == true || th.Active__c == false) {
                hasUserManagedTrigger = true;
                break;
            }
        }
        return hasUserManagedTrigger;
    }*/

    /**
     * @description Returns the oldest CloseDate from the Opportunity object
     */
    /*private static Date getOldestCloseDate() {
        try {
            AggregateResult ag = [SELECT Min(CloseDate) oldestDate FROM Opportunity];
            if (ag != null && ag.get('oldestDate') != null) {
                Date dt = (Date) ag.get('oldestDate');
                return dt;
            }
        } catch (Exception ex) {}
        return null;
    }*/

    /**
     * @description Returns the max number of attached opportunities (going by 'Total Number of Donations') for
     * all Accounts.
     */
    /*private static Integer getMaxNumRelatedOpps() {
        try {
            AggregateResult ag = [SELECT Max(npo02__NumberOfClosedOpps__c) maxCount FROM Account];
            if (ag != null && ag.get('maxCount') != null) {
                Integer cnt = (Integer) ag.get('maxCount');
                return cnt;
            }
        } catch (Exception ex) {}
        return null;
    }*/
}