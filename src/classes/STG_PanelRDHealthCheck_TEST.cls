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
* @group Settings
* @description Recurring Donations Health Check Unit Tests
*/
@IsTest(IsParallel=true)
private class STG_PanelRDHealthCheck_TEST {

    private static final String BAD_PICKLIST_VALUE = 'Non Existent Value';
    private static final String PLEDGED_STAGE = UTIL_UnitTestData_TEST.getOpenStage();

    /**
     * @description Validates that Legacy Recurring Donations is configured properly in the org
     */
    @IsTest
    private static void shouldValidateLegacyRecurringDonationsConfig() {
        npe03__Recurring_Donations_Settings__c rds = UTIL_CustomSettingsFacade.getRecurringDonationsSettingsForTest(
            new npe03__Recurring_Donations_Settings__c(
                IsRecurringDonations2Enabled__c = false,
                npe03__Opportunity_Forecast_Months__c = 1,
                npe03__Maximum_Donations__c = 20,
                npe03__Open_Opportunity_Behavior__c = RD2_Constants.CloseActions.Mark_Opportunities_Closed_Lost.name(),
                npe03__Record_Type__c = UTIL_RecordTypes_TEST.getDefaultRecordTypeId(Opportunity.SObjectType)
            )
        );

        STG_PanelHealthCheck_CTRL ctrl = new STG_PanelHealthCheck_CTRL();

        TDTM_Config_API.disableAllTriggers();

        STG_PanelRDHealthCheck.verifyRecurringDonationConfiguration(ctrl);
        for (STG_PanelHealthCheck_CTRL.DetectResult dr : ctrl.listDR) {
            System.assertEquals(STG_PanelHealthCheck_CTRL.statusSuccess, dr.strStatus,
                'The result status should have been "' + STG_PanelHealthCheck_CTRL.statusSuccess + '".\n' + dr
            );
        }
    }

    /**
     * @description Validate that the legacy health check fails with an error when a custom installment period
     * is created, but does not have a matching picklist value in the installment period picklist
     */
    @IsTest
    private static void shouldValidateLegacyWithCustomInstallmentPeriods() {
        npe03__Custom_Installment_Settings__c customInstallment = new npe03__Custom_Installment_Settings__c(
            npe03__Increment__c = 'Weeks',
            npe03__Value__c = 2,
            Name = BAD_PICKLIST_VALUE
        );
        insert customInstallment;

        npe03__Recurring_Donations_Settings__c rds = UTIL_CustomSettingsFacade.getRecurringDonationsSettingsForTest(
            new npe03__Recurring_Donations_Settings__c(
                IsRecurringDonations2Enabled__c = false,
                npe03__Opportunity_Forecast_Months__c = 1,
                npe03__Maximum_Donations__c = 20,
                npe03__Open_Opportunity_Behavior__c = RD2_Constants.CloseActions.Mark_Opportunities_Closed_Lost.name(),
                npe03__Record_Type__c = UTIL_RecordTypes_TEST.getDefaultRecordTypeId(Opportunity.SObjectType)
            )
        );

        STG_PanelHealthCheck_CTRL ctrl = new STG_PanelHealthCheck_CTRL();

        TDTM_Config_API.disableAllTriggers();

        Test.startTest();

        STG_PanelRDHealthCheck.verifyRecurringDonationConfiguration(ctrl);

        String results = getValidationResults(ctrl);
        System.assert(results.contains(BAD_PICKLIST_VALUE),
            'The error should reference the "' + BAD_PICKLIST_VALUE + '" picklist value.\n' + results
        );

        Test.stopTest();
    }

    /**
     * @description Validates that Enhanced Recurring Donations is configured properly in the org.
     * Because RD1 is the default for NPSP, there are some settings that will fail the health check
     * such as for the Quarterly installment period. Situations like this are validated for in the
     * method.
     */
    @IsTest
    private static void shouldValidateEnhancedRecurringDonationsConfig() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donations_Settings__c rds = UTIL_CustomSettingsFacade.getRecurringDonationsSettingsForTest(
            new npe03__Recurring_Donations_Settings__c(
                IsRecurringDonations2Enabled__c = true,
                npe03__Opportunity_Forecast_Months__c = 1,
                npe03__Open_Opportunity_Behavior__c = RD2_Constants.CloseActions.Mark_Opportunities_Closed_Lost.name(),
                npe03__Record_Type__c = UTIL_RecordTypes_TEST.getDefaultRecordTypeId(Opportunity.SObjectType),
                InstallmentOppStageName__c = PLEDGED_STAGE
            )
        );

        STG_PanelHealthCheck_CTRL ctrl = new STG_PanelHealthCheck_CTRL();

        TDTM_Config_API.disableAllTriggers();

        STG_PanelRDHealthCheck.verifyRecurringDonationConfiguration(ctrl);

        String results = getValidationResults(ctrl);

        String errResults = '';
        Integer errCount = 0;
        for (STG_PanelHealthCheck_CTRL.DetectResult dr : ctrl.listDR) {
            if (dr.strStatus == STG_PanelHealthCheck_CTRL.statusError) {
                errResults += dr.strDetails + '\n';
                errCount++;
            }
        }

        // Since RD1 is enabled by default, there are 4 configuration errors:
        // - Quarterly in the Installment Period field
        // - 29,30,31 in the DayOfMonth field
        System.assertEquals(4, errCount,
            'There should exactly four entries in this validation.\n' + results
        );

        System.assert(errResults.contains(RD_Constants.INSTALLMENT_PERIOD_QUARTERLY),
            'The error should reference the "' + RD_Constants.INSTALLMENT_PERIOD_QUARTERLY + '" picklist value.\n' + errResults
        );
        System.assert(errResults.contains('29'),
            'The error should reference the "29" picklist value.\n' + errResults
        );
    }

    /**
     * @description Validates that the helper methods to validate both supported and required
     * picklist values works as expected
     */
    @IsTest
    private static void shouldValidatePicklistEntries() {

        STG_PanelHealthCheck_CTRL ctrl = new STG_PanelHealthCheck_CTRL();
        STG_PanelRDHealthCheck healthCheck = new STG_PanelRDHealthCheck(ctrl);

        // Verify known packaged installment periods on this field
        // =============================================================
        Set<String> supportedInstallmentPeriods = new Set<String>();
        supportedInstallmentPeriods.add(RD_Constants.INSTALLMENT_PERIOD_WEEKLY);
        supportedInstallmentPeriods.add(RD_Constants.INSTALLMENT_PERIOD_MONTHLY);
        supportedInstallmentPeriods.add(RD_Constants.INSTALLMENT_PERIOD_QUARTERLY);
        supportedInstallmentPeriods.add(RD_Constants.INSTALLMENT_PERIOD_YEARLY);
        supportedInstallmentPeriods.add(RD_Constants.INSTALLMENT_PERIOD_FIRST_AND_FIFTEENTH);

        healthCheck.validateSupportedPicklistValues(supportedInstallmentPeriods, 'npe03__Installment_Period__c',
            System.Label.healthDetailsInvalidPicklistValue, System.Label.healthSolutionUnsupportedPicklistValue);

        healthCheck.validateRequiredPicklistValues(supportedInstallmentPeriods, 'npe03__Installment_Period__c',
            System.Label.healthDetailsMissingRequiredPicklistValue, System.Label.healthSolutionMissingPicklistValue);

        String results = getValidationResults(ctrl);
        System.assertEquals(0, ctrl.listDR.size(),
            'There should zero errors in this picklist validation\n' + results
        );

        // Add an invalid "required" picklist to this list and validate that the required
        // validation logs the error.
        // =============================================================
        supportedInstallmentPeriods.add(BAD_PICKLIST_VALUE);
        healthCheck.validateRequiredPicklistValues(supportedInstallmentPeriods, 'npe03__Installment_Period__c',
            System.Label.healthDetailsInvalidPicklistValue, System.Label.healthSolutionUnsupportedPicklistValue);

        results = getValidationResults(ctrl);
        System.assertEquals(1, ctrl.listDR.size(),
            'There should exactly one error in this picklist validation.\n' + results
        );
        System.assert(results.contains(BAD_PICKLIST_VALUE),
            'The error should reference the "' + BAD_PICKLIST_VALUE + '" picklist value.\n' + results
        );
    }

    /**
     * @description Validate that the checking of the Opportunity Stage Settings works as expected
     */
    @IsTest
    private static void shouldValidateOppStageSettings() {
        STG_PanelHealthCheck_CTRL ctrl = new STG_PanelHealthCheck_CTRL();
        STG_PanelRDHealthCheck healthCheck = new STG_PanelRDHealthCheck(ctrl);

        healthCheck.validateOpportunityStage(PLEDGED_STAGE, false, false);

        String results = getValidationResults(ctrl);
        System.assertEquals(0, ctrl.listDR.size(),
            'There should zero errors in the record type validation\n' + results
        );

        healthCheck.validateOpportunityStage(PLEDGED_STAGE, true, true);

        results = getValidationResults(ctrl);
        System.assertEquals(1, ctrl.listDR.size(),
            'There should one errors in the record type validation.\n' + results
        );
        System.assert(results.contains(PLEDGED_STAGE),
            'The error should reference the "' + PLEDGED_STAGE + '" Stage Name.\n' + results
        );
    }

    /**
     * @description Validate that the checking of the Opportunity Stage Settings works as expected
     */
    @IsTest
    private static void shouldValidateOpportunityInstallment() {
        STG_PanelHealthCheck_CTRL ctrl = new STG_PanelHealthCheck_CTRL();
        STG_PanelRDHealthCheck healthCheck = new STG_PanelRDHealthCheck(ctrl);

        Id defaultRtId = UTIL_RecordTypes_TEST.getDefaultRecordTypeId(Opportunity.SObjectType);

        // =============================================================
        // Create a valid installment with a valid stage and record type id
        // =============================================================
        healthCheck.validateNewInstallmentOpportunity(PLEDGED_STAGE, defaultRtId);

        String results = getValidationResults(ctrl);
        System.assertEquals(1, ctrl.listDR.size(),
            'There should one result in the installment validation.\n' + results
        );
        System.assertEquals(STG_PanelHealthCheck_CTRL.statusSuccess, ctrl.listDR[0].strStatus,
            'The result status should have been "' + STG_PanelHealthCheck_CTRL.statusSuccess + '".\n' + results
        );
        ctrl.listDR.clear();

        // =============================================================
        // Create a valid installment with an invalid opportunity stage
        // =============================================================
        Id mockRecordTypeId = UTIL_UnitTestData_TEST.mockId(defaultRtId.getSobjectType());
        healthCheck.validateNewInstallmentOpportunity(PLEDGED_STAGE, mockRecordTypeId);

        results = getValidationResults(ctrl);
        System.assertEquals(1, ctrl.listDR.size(),
            'There should one result in the installment validation.\n' + results
        );
        System.assertEquals(STG_PanelHealthCheck_CTRL.statusError, ctrl.listDR[0].strStatus,
            'The result status should have been "' + STG_PanelHealthCheck_CTRL.statusError + '".\n' + results
        );
        System.assert(ctrl.listDR[0].strDetails.contains(mockRecordTypeId),
            'The result status details should contained the bad record type id of "' + mockRecordTypeId + '".\n' + results
        );
    }

    // ==================================================================================
    // HELPER METHODS
    // ==================================================================================

    private static String getValidationResults(STG_PanelHealthCheck_CTRL ctrl) {
        String results = '';
        for (STG_PanelHealthCheck_CTRL.DetectResult dr : ctrl.listDR) {
            results += dr.strStatus + ': ' + (dr.strDetails != null ? dr.strDetails : dr.strSolution) + '\n';
        }
        return results;
    }
}