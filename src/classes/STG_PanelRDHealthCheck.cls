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
* @description Recurring Donations Health Check
*/
public inherited sharing class STG_PanelRDHealthCheck {

    /**
    * @description Delegate Health Check operations for Recurring Donations
    * @param ctrl The Health Check panel's controller
    */
    public static void verifyRecurringDonationConfiguration(STG_PanelHealthCheck_CTRL ctrl) {
        STG_PanelRDHealthCheck healthCheck = new STG_PanelRDHealthCheck(ctrl);
        if (RD2_EnablementService.getInstance().isRecurringDonations2Enabled()) {
            healthCheck.verifyEnhancedRDConfig();
        } else {
            healthCheck.verifyLegacyRDConfig();
        }
    }

    /** @description Health CHeck Panel Controller Instance */
    private STG_PanelHealthCheck_CTRL ctrl;

    /**
     * @description Constructor
     * @param ctrl Health Check Panel Controller Class
     */
    public STG_PanelRDHealthCheck(STG_PanelHealthCheck_CTRL ctrl) {
        this.ctrl = ctrl;
    }

    /**
    * @description Health Check Validation for Legacy Recurring Donations:
    * - Installment Period Picklist Values with Custom Installment Type(s)
    * - Open Opportunity Stage
    * - Cosed Opportunity Stage
    * - Create Installment Opportunity
    */
    public void verifyLegacyRDConfig() {
        npe03__Recurring_Donations_Settings__c rds = UTIL_CustomSettingsFacade.getRecurringDonationsSettings();

        // =============================================================
        // Verify Standard and Custom Installment Periods
        // =============================================================
        Set<String> installmentPeriods = new Set<String>();
        Set<String> customInstallmentPeriods = new Set<String>();
        installmentPeriods.add(RD_Constants.INSTALLMENT_PERIOD_WEEKLY);
        installmentPeriods.add(RD_Constants.INSTALLMENT_PERIOD_MONTHLY);
        installmentPeriods.add(RD_Constants.INSTALLMENT_PERIOD_QUARTERLY);
        installmentPeriods.add(RD_Constants.INSTALLMENT_PERIOD_YEARLY);
        installmentPeriods.add(RD_Constants.INSTALLMENT_PERIOD_FIRST_AND_FIFTEENTH);

        // Get Custom Installment Periods
        for (npe03__Custom_Installment_Settings__c ci : STG_Panel.stgService.listRDCustomInstallment) {
            installmentPeriods.add(ci.Name);
            customInstallmentPeriods.add(ci.Name);
        }

        // The picklist should have the supported and custom picklist values
        validateSupportedPicklistValues(installmentPeriods, 'npe03__Installment_Period__c',
            System.Label.healthDetailsInvalidRDCustomPeriodPIcklist, System.Label.healthSolutionInvalidRDCustomPeriodPicklist);
        // The picklist should absolutely have all of the custom installment period
        validateRequiredPicklistValues(customInstallmentPeriods, 'npe03__Installment_Period__c',
            System.Label.healthDetailsMissingRequiredPicklistValue, System.Label.healthSolutionInvalidRDCustomPeriod);

        // ===========================================================================================
        // Verify Open Ended Status Values. This field should have all 3 values and nothing else
        // ===========================================================================================
        Set<String> supportedStatus = new Set<String>();
        supportedStatus.add(RD_Constants.OPEN_ENDED_STATUS_OPEN);
        supportedStatus.add(RD_Constants.OPEN_ENDED_STATUS_CLOSED);
        supportedStatus.add(RD_Constants.OPEN_ENDED_STATUS_NONE);
        validateSupportedPicklistValues(supportedStatus, 'npe03__Open_Ended_Status__c',
            System.Label.healthDetailsInvalidPicklistValue, System.Label.healthSolutionUnsupportedPicklistValue);
        validateRequiredPicklistValues(supportedStatus, 'npe03__Open_Ended_Status__c',
            System.Label.healthDetailsMissingRequiredPicklistValue, System.Label.healthSolutionMissingPicklistValue);

        // =============================================================
        // Verify Schedule Type Values
        // =============================================================
        Set<String> supportedScheduleTypes = new Set<String>();
        supportedScheduleTypes.add(RD_Constants.SCHEDULE_TYPE_MULTIPLY_BY);
        supportedScheduleTypes.add(RD_Constants.SCHEDULE_TYPE_DIVIDE_BY);

        validateSupportedPicklistValues(supportedScheduleTypes, 'npe03__Schedule_Type__c',
            System.Label.healthDetailsInvalidPicklistValue, System.Label.healthSolutionUnsupportedPicklistValue);
        validateRequiredPicklistValues(supportedScheduleTypes, 'npe03__Schedule_Type__c',
            System.Label.healthDetailsMissingRequiredPicklistValue, System.Label.healthSolutionMissingPicklistValue);

        if (hasValidationErrors()) {
            ctrl.createDR(System.Label.stgNavRecurringDonations,
                STG_PanelHealthCheck_CTRL.statusSuccess,
                null,
                System.Label.healthDetailsValidRDCustomPeriod
            );
        }

        // ===========================================================================================
        // Validate Recurring Donation Stages
        // ===========================================================================================
        String closedOppStage = System.Label.npe03.RecurringDonationClosedLostOpportunityStage;
        String openOppStage = (Test.isRunningTest()
            ? UTIL_UnitTestData_TEST.getOpenStage()
            : System.Label.npe03.RecurringDonationStageName);
        validateOpportunityStage(openOppStage, false, false);
        validateOpportunityStage(closedOppStage, false, true);

        // ===========================================================================================
        // Validate that an Installment Opportunity can be created
        // ===========================================================================================
        validateNewInstallmentOpportunity(openOppStage, rds.npe03__Record_Type__c);
    }

    /**
    * @description Health Check Validation for Enhanced Recurring Donations:
    * - Installment Period Picklist Values
    * - RD Status Picklist Values
    * - Day of Month Picklist Values
    * - Recurring Type Picklist Values
    * - Open Opportunity Stage
    * - Cosed Opportunity Stage
    * - Create Installment Opportunity
    */
    public void verifyEnhancedRDConfig() {
        RD2_Settings settings = new RD2_Settings();

        // =============================================================
        // Verify Installment Periods
        // =============================================================
        Set<String> supportedInstallmentPeriods = new Set<String>();
        supportedInstallmentPeriods.add(RD2_Constants.INSTALLMENT_PERIOD_DAILY);
        supportedInstallmentPeriods.add(RD2_Constants.INSTALLMENT_PERIOD_WEEKLY);
        supportedInstallmentPeriods.add(RD2_Constants.INSTALLMENT_PERIOD_MONTHLY);
        supportedInstallmentPeriods.add(RD2_Constants.INSTALLMENT_PERIOD_YEARLY);
        supportedInstallmentPeriods.add(RD2_Constants.INSTALLMENT_PERIOD_FIRST_AND_FIFTEENTH);

        validateSupportedPicklistValues(supportedInstallmentPeriods, 'npe03__Installment_Period__c',
            System.Label.healthDetailsInvalidPicklistValue, System.Label.healthSolutionUnsupportedPicklistValue);

        // =============================================================
        // Verify Status Values
        // =============================================================
        Set<String> supportedStatus = new Set<String>();
        supportedStatus.add(RD2_Constants.STATUS_ACTIVE);
        supportedStatus.add(RD2_Constants.STATUS_CLOSED);
        supportedStatus.add(RD2_Constants.STATUS_LAPSED);

        validateSupportedPicklistValues(supportedStatus, String.valueOf(npe03__Recurring_Donation__c.Status__c),
            System.Label.healthDetailsInvalidPicklistValue, System.Label.healthSolutionUnsupportedPicklistValue);

        // =============================================================
        // Verify Recurring Type Values
        // =============================================================
        Set<String> supportedType = new Set<String>();
        supportedType.add(RD2_Constants.RECURRING_TYPE_OPEN);

        validateRequiredPicklistValues(supportedType, String.valueOf(npe03__Recurring_Donation__c.RecurringType__c),
            System.Label.healthDetailsMissingRequiredPicklistValue, System.Label.healthSolutionMissingPicklistValue);

        // =============================================================
        // Verify Day Of Month Values
        // =============================================================
        Set<String> supportedDayOfMonth = new Set<String>();
        for (Integer n=0; n < 29; n++) {
            supportedDayOfMonth.add(String.valueOf(n));
        }
        supportedDayOfMonth.add(RD2_Constants.DAY_OF_MONTH_LAST_DAY);

        validateSupportedPicklistValues(supportedDayOfMonth, String.valueOf(npe03__Recurring_Donation__c.Day_of_Month__c),
            System.Label.healthDetailsInvalidPicklistValue, System.Label.healthSolutionUnsupportedPicklistValue);

        if (hasValidationErrors()) {
            ctrl.createDR(System.Label.stgNavRecurringDonations,
                STG_PanelHealthCheck_CTRL.statusSuccess,
                null,
                System.Label.healthDetailsValidRDCustomPeriod
            );
        }

        // ===========================================================================================
        // Validate Recurring Donation Stages
        // ===========================================================================================
        validateOpportunityStage(settings.installmentStage, false, false);
        validateOpportunityStage(System.Label.npe03.RecurringDonationClosedLostOpportunityStage, false, true);

        // ===========================================================================================
        // Validate that an Installment Opportunity can be created
        // ===========================================================================================
        validateNewInstallmentOpportunity(settings.installmentStage, settings.installmentRecordTypeId);
    }

    // ==================================================================================
    // HELPER METHODS
    // ==================================================================================

    /**
     * @description Validate that the Picklist only has this list of supported picklist values. The picklist
     * may not have some of our supported values (such as if they have been inactivated), but it cannot have
     * entries that are not supported
     * @param supportedValues List of picklist Api Names that "should" be there
     * @param picklistValues List of picklist Api Names that "are" there
     */
    @TestVisible
    private void validateSupportedPicklistValues(Set<String> supportedValues, String fieldName, String errorLabel, String solutionLabel) {
        String fieldLabel = UTIL_Describe.getFieldLabel('npe03__Recurring_Donation__c', fieldName);
        List<SelectOption> picklistValues = UTIL_Describe.getSelectOptions(
            'npe03__Recurring_Donation__c', fieldName);

        Set<String> supportedValuesLowerCase = new Set<String>();
        for (String val : supportedValues) {
            supportedValuesLowerCase.add(val.toLowerCase());
        }

        for (SelectOption option : picklistValues) {
            if (!supportedValuesLowerCase.contains(option.getValue().toLowerCase())) {
                ctrl.createDR(System.Label.stgNavRecurringDonations,
                    STG_PanelHealthCheck_CTRL.statusError,
                    String.format(errorLabel,
                        new String[] { option.getValue().escapeHtml4(), fieldLabel.escapeHtml4() }
                    ),
                    String.format(solutionLabel,
                        new String[] { option.getValue().escapeHtml4(), fieldLabel.escapeHtml4() }
                    )
                );
            }
        }
    }

    /**
     * @description Validate that all of the "required" Picklist Values are in the field.
     * @param requiredValues List of picklist Api Names that "should" be there
     * @param picklistValues List of picklist Api Names that "are" there
     */
    @TestVisible
    private void validateRequiredPicklistValues(Set<String> requiredValues, String fieldName, String errorLabel, String solutionLabel) {

        String fieldLabel = UTIL_Describe.getFieldLabel('npe03__Recurring_Donation__c', fieldName);
        List<SelectOption> picklistValues = UTIL_Describe.getSelectOptions(
            'npe03__Recurring_Donation__c', fieldName);

        for (String value : requiredValues) {
            Boolean hasValue = false;
            for (SelectOption option : picklistValues) {
                if (option.getValue().toLowerCase() == value.toLowerCase()) {
                    hasValue = true;
                    break;
                }
            }
            System.debug('> Looking for ' + value + ': ' + hasValue);
            if (!hasValue) {
                ctrl.createDR(System.Label.stgNavRecurringDonations,
                    STG_PanelHealthCheck_CTRL.statusError,
                    String.format(errorLabel,
                        new String[] { value.escapeHtml4(), fieldLabel.escapeHtml4() }
                    ),
                    String.format(solutionLabel,
                        new String[] { value.escapeHtml4(), fieldLabel.escapeHtml4() }
                    )
                );
            }
        }
    }

    /**
     * @description Validate that the specified Record Type Api Name exists as Active and defined as
     * Closed and/or Won as appropriate
     * @param oppStageName Record Type Api Name (DeveloperName NOT label)
     * @param isWon
     * @param isClosed
     */
    @TestVisible
    private void validateOpportunityStage(String oppStageName, Boolean isWon, Boolean isClosed) {

        Integer cnt = [SELECT COUNT() FROM OpportunityStage
            WHERE ApiName = :oppStageName
            AND IsClosed = :isClosed
            AND IsWon = :isWon
            AND IsActive = TRUE
        ];
        if (cnt == 0) {
            ctrl.createDR(System.Label.stgNavRecurringDonations,
                STG_PanelHealthCheck_CTRL.statusError,
                String.format(System.Label.healthDetailsInvalidOppStage,
                    new String[] {
                        oppStageName
                    }),
                System.Label.healthSolutionInvalidOppStage
            );
        }
    }

    /**
     * @description Validate that a new Installment Opportunity can be created using the defined
     * Open Stage. Render any errors in the UI.
     * @param oppStage Stage Api Name
     */
    @TestVisible
    private void validateNewInstallmentOpportunity(String oppStage, Id oppRecordType) {
        Savepoint sp = Database.setSavepoint();

        // create a test account and test opportunity
        Account acct = validateTestAccount();
        if (acct == null) {
            return;
        }

        Opportunity testOpp = new Opportunity(
            AccountId = acct.Id,
            Amount = 100,
            CloseDate = System.today(),
            Name = 'TestOpp',
            StageName = oppStage,
            RecordTypeId = oppRecordType
        );

        Database.SaveResult[] sr = Database.insert(new List<Opportunity>{
            testOpp
        }, false);

        Database.rollback(sp);

        validateSaveErrors(sr);
    }

    /**
     * @description Create a Test Account and validate that is saves correctl
     * @return Account Instance
     */
    private Account validateTestAccount() {
        // create a test account and test opportunity
        Account acct = new Account(
            Name = 'test account ' + String.valueOf(System.currentTimeMillis())
        );
        try {
            insert acct;
        } catch (Exception ex) {
            ctrl.createDR(System.Label.stgNavDonations,
                STG_PanelHealthCheck_CTRL.statusError,
                System.Label.healthDetailsSaveAcctFailed + ' ' + ex.getMessage(),
                System.Label.healthSolutionSaveOppsFailed
            );
            acct = null;
        }
        return acct;
    }

    /**
     * @description Validate database save errors when creating a test Opportunity Record
     * @param sr Save Results
     */
    private void validateSaveErrors(List<Database.SaveResult> sr) {

        if (sr[0].isSuccess()) {
            ctrl.createDR(System.Label.stgNavDonations,
                STG_PanelHealthCheck_CTRL.statusSuccess,
                null,
                System.Label.healthLabelRDOppsValid
            );
            return;
        }

        String errorMsg = '';
        Database.Error[] errors = sr[0].getErrors();
        for (Database.Error err : errors) {

            if (err.getStatusCode() == StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION) {
                errorMsg += ' ' + System.Label.npe03.RecurringDonationCustomValidationWarning;

            } else if (err.getStatusCode() == StatusCode.REQUIRED_FIELD_MISSING) {
                errorMsg += ' ' + System.Label.npe03.RecurringDonationRequiredFieldsWarning;

            }  else {
                errorMsg += ' ' + err.getMessage();
            }

            List<String> fields = err.getFields();
            errorMsg += String.join(fields, ', ');
        }

        ctrl.createDR(System.Label.stgNavDonations,
            STG_PanelHealthCheck_CTRL.statusError,
            System.Label.healthDetailsSaveOppsFailed + ' ' + errorMsg,
            System.Label.healthSolutionSaveOppsFailed
        );
    }

    /**
     * @description Returns true if there are any "Errors" in the health check results
     * @return True or False
     */
    private Boolean hasValidationErrors() {
        for (STG_PanelHealthCheck_CTRL.DetectResult dr : ctrl.listDR) {
            if (dr.strStatus == STG_PanelHealthCheck_CTRL.statusError) {
                return true;
            }
        }
        return false;
    }

}