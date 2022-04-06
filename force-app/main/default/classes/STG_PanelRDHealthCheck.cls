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

    /*********************************************************************************************************
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

    /** @description Recurring Donation SObject API Name */
    private static final String RD_SOBJECT_NAME = 'npe03__Recurring_Donation__c';

    /** @description Health Check Panel Controller Instance */
    private STG_PanelHealthCheck_CTRL ctrl;

    /** @description Health Check Result reporting container */
    private HealthCheckResult result;

    /**
     * @description Constructor
     * @param ctrl Health Check Panel Controller Class
     */
    public STG_PanelRDHealthCheck(STG_PanelHealthCheck_CTRL ctrl) {
        this.ctrl = ctrl;
        this.result = new HealthCheckResult(this.ctrl);
    }

    /***
    * @description Health Check Validation for Legacy Recurring Donations:
    * - Installment Period Picklist Values with Custom Installment Type(s)
    * - Open Opportunity Stage
    * - Cosed Opportunity Stage
    * - Create Installment Opportunity
    */
    public void verifyLegacyRDConfig() {
        npe03__Recurring_Donations_Settings__c settings = UTIL_CustomSettingsFacade.getRecurringDonationsSettings();
        SupportedLegacyRDValues supported = new SupportedLegacyRDValues();

        result.withRecurringDonationScope();

        // The picklist should have the supported and custom picklist values
        validateSupportedPicklistValues(supported.installmentPeriods, 'npe03__Installment_Period__c',
            System.Label.healthDetailsInvalidRDCustomPeriodPIcklist, System.Label.healthSolutionInvalidRDCustomPeriodPicklist);
        // The picklist should absolutely have all of the custom installment period
        validateRequiredPicklistValues(supported.customInstallmentPeriods, 'npe03__Installment_Period__c',
            System.Label.healthDetailsMissingRequiredPicklistValue, System.Label.healthSolutionInvalidRDCustomPeriod);

        validateSupportedPicklistValues(supported.status, 'npe03__Open_Ended_Status__c',
            System.Label.healthDetailsInvalidPicklistValue, System.Label.healthSolutionUnsupportedPicklistValue);
        validateRequiredPicklistValues(supported.status, 'npe03__Open_Ended_Status__c',
            System.Label.healthDetailsMissingRequiredPicklistValue, System.Label.healthSolutionMissingPicklistValue);

        validateSupportedPicklistValues(supported.scheduleTypes, 'npe03__Schedule_Type__c',
            System.Label.healthDetailsInvalidPicklistValue, System.Label.healthSolutionUnsupportedPicklistValue);
        validateRequiredPicklistValues(supported.scheduleTypes, 'npe03__Schedule_Type__c',
            System.Label.healthDetailsMissingRequiredPicklistValue, System.Label.healthSolutionMissingPicklistValue);

        if (!result.hasErrors()) {
            result.addSuccess(System.Label.healthDetailsValidRDCustomPeriod);
        }

        String openOppStage = (Test.isRunningTest()
            ? UTIL_UnitTestData_TEST.getOpenStage()
            : System.Label.npe03.RecurringDonationStageName);
        validateOpenOpportunityStage(openOppStage);
        validateClosedLostOpportunityStage(System.Label.npe03.RecurringDonationClosedLostOpportunityStage);

        // Validate that an Installment Opportunity can be created
        validateNewInstallmentOpportunity(openOppStage, settings.npe03__Record_Type__c);
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
        RD2_Settings settings = RD2_Settings.getInstance();
        SupportedEnhancedRDValues supported = new SupportedEnhancedRDValues();

        result.withRecurringDonationScope();

        validateSupportedPicklistValues(supported.installmentPeriods, 'npe03__Installment_Period__c',
        System.Label.healthDetailsInvalidPicklistValue, System.Label.healthSolutionUnsupportedPicklistValue);

        validateRequiredPicklistValues(supported.status, String.valueOf(npe03__Recurring_Donation__c.Status__c),
            System.Label.healthDetailsMissingRequiredPicklistValue, System.Label.healthSolutionMissingPicklistValue);
        
        validateStatusMapping();

        validateRequiredPicklistValues(supported.recurringTypes, String.valueOf(npe03__Recurring_Donation__c.RecurringType__c),
            System.Label.healthDetailsMissingRequiredPicklistValue, System.Label.healthSolutionMissingPicklistValue);

        validateSupportedPicklistValues(supported.dayOfMonthValues, String.valueOf(npe03__Recurring_Donation__c.Day_Of_Month__c),
            System.Label.healthDetailsInvalidPicklistValue, System.Label.healthSolutionUnsupportedPicklistValue);

        if (!result.hasErrors()) {
            result.addSuccess(System.Label.healthDetailsValidRDCustomPeriod);
        }

        validateOpenOpportunityStage(settings.installmentStage);
        validateClosedLostOpportunityStage(System.Label.npe03.RecurringDonationClosedLostOpportunityStage);

        // Validate that an Installment Opportunity can be created
        validateNewInstallmentOpportunity(settings.installmentStage, settings.installmentRecordTypeId);
    }

    /**
     * @description Validate that the Picklist only has this list of supported picklist values. The picklist
     * may not have some of our supported values (such as if they have been inactivated), but it cannot have
     * entries that are not supported
     * @param supportedValues List of picklist Api Names that "should" be there
     * @param picklistValues List of picklist Api Names that "are" there
     */
    @TestVisible
    private void validateSupportedPicklistValues(Set<String> supportedValues, String fieldName, String errorLabel, String solutionLabel) {
        String fieldLabel = UTIL_Describe.getFieldLabel(RD_SOBJECT_NAME, fieldName);
        List<SelectOption> picklistValues = UTIL_Describe.getSelectOptions(RD_SOBJECT_NAME, fieldName);

        Set<String> supportedValuesLowerCase = new Set<String>();
        for (String val : supportedValues) {
            supportedValuesLowerCase.add(val.toLowerCase());
        }

        for (SelectOption option : picklistValues) {
            if (!supportedValuesLowerCase.contains(option.getValue().toLowerCase())) {
                result.addError(option.getValue(), fieldLabel, errorLabel, solutionLabel);
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
        String fieldLabel = UTIL_Describe.getFieldLabel(RD_SOBJECT_NAME, fieldName);
        List<SelectOption> picklistValues = UTIL_Describe.getSelectOptions(RD_SOBJECT_NAME, fieldName);

        for (String value : requiredValues) {
            Boolean hasValue = false;
            for (SelectOption option : picklistValues) {
                if (option.getValue().toLowerCase() == value.toLowerCase()) {
                    hasValue = true;
                    break;
                }
            }
            if (!hasValue) {
                result.addError(value, fieldLabel, errorLabel, solutionLabel);
            }
        }
    }

    /**
    * @description Validate that all RD Status are mapped to valid States
    * @return void
    */
    @TestVisible
    private void validateStatusMapping() {
        List<SelectOption> picklistValues = 
            UTIL_Describe.getSelectOptions(RD_SOBJECT_NAME, String.valueOf(npe03__Recurring_Donation__c.Status__c));

        for (SelectOption option : picklistValues) {
            if (!option.getDisabled() && String.isBlank(RD2_StatusMapper.getInstance().getState(option.getValue()))) {
                result.addError(
                    String.format(
                        System.Label.RD2_StatusMustBeMapped,
                        new String[] { option.getLabel()}
                    ),
                    System.Label.RD2_StatusMustBeMappedSolution
                );
            }
        }
    }
    /**
     * @description Validates specified stage name exists as an open stage and it is active
     * @param oppStageName Opportunity Stage Name
     * @return void
     */
    private void validateOpenOpportunityStage(String oppStageName) {
        validateOpportunityStage(oppStageName, false, false);
    }

    /**
     * @description Validates specified stage name exists as a Closed Lost stage and it is active
     * @param oppStageName Opportunity Stage Name
     * @return void
     */
    private void validateClosedLostOpportunityStage(String oppStageName) {
        validateOpportunityStage(oppStageName, false, true);
    }

    /**
     * @description Validate that the specified Record Type Api Name exists as Active and defined as
     * Closed and/or Won as appropriate
     * @param oppStageName Record Type Api Name (DeveloperName NOT label)
     * @param isWon
     * @param isClosed
     * @return void
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
            result
                .withRecurringDonationScope()
                .addError(
                String.format(
                    System.Label.healthDetailsInvalidOppStage,
                    new String[] { oppStageName}
                ),
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
        result.withOpportunityScope();

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

        Database.SaveResult[] sr = Database.insert(
            new List<Opportunity>{ testOpp }, false
        );

        Database.rollback(sp);

        validateSaveErrors(sr);
    }

    /**
     * @description Create a Test Account and validate that is saves correctly
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
            result.addError(
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
            result.addSuccess(System.Label.healthLabelRDOppsValid);
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

        result.addError(
            System.Label.healthDetailsSaveOppsFailed + ' ' + errorMsg,
            System.Label.healthSolutionSaveOppsFailed
        );
    }

    /**
     * @description Contains field values supported for the legacy Recurring Donations
     */
    public class SupportedLegacyRDValues {
        public Set<String> installmentPeriods = new Set<String>{
            RD_Constants.INSTALLMENT_PERIOD_WEEKLY,
            RD_Constants.INSTALLMENT_PERIOD_MONTHLY,
            RD_Constants.INSTALLMENT_PERIOD_QUARTERLY,
            RD_Constants.INSTALLMENT_PERIOD_YEARLY,
            RD_Constants.INSTALLMENT_PERIOD_FIRST_AND_FIFTEENTH
        };
        public Set<String> customInstallmentPeriods = new Set<String>();

        public Set<String> status = new Set<String>{
            RD_Constants.OPEN_ENDED_STATUS_OPEN,
            RD_Constants.OPEN_ENDED_STATUS_CLOSED,
            RD_Constants.OPEN_ENDED_STATUS_NONE
        };

        public Set<String> scheduleTypes = new Set<String>{
            RD_Constants.SCHEDULE_TYPE_MULTIPLY_BY,
            RD_Constants.SCHEDULE_TYPE_DIVIDE_BY
        };

        /**
         * @description Create definitions for Legacy RD Health Check
         */
        public SupportedLegacyRDValues() {
            populateCustomInstallmentPeriods();
        }

        /**
         * @description Add any user defined custom installment periods to the periods set
         */
        private void populateCustomInstallmentPeriods() {
            for (npe03__Custom_Installment_Settings__c ci : STG_Panel.stgService.listRDCustomInstallment) {
                installmentPeriods.add(ci.Name);
                customInstallmentPeriods.add(ci.Name);
            }
        }
    }

    /**
     * @description Contains field values supported for the enhanced Recurring Donations
     */
    public class SupportedEnhancedRDValues {
        public Set<String> installmentPeriods = new Set<String>{
            RD2_Constants.INSTALLMENT_PERIOD_DAILY,
            RD2_Constants.INSTALLMENT_PERIOD_WEEKLY,
            RD2_Constants.INSTALLMENT_PERIOD_MONTHLY,
            RD2_Constants.INSTALLMENT_PERIOD_YEARLY,
            RD2_Constants.INSTALLMENT_PERIOD_FIRST_AND_FIFTEENTH
        };

        public Set<String> status = new Set<String>{
            RD2_Constants.STATUS_ACTIVE,
            RD2_Constants.STATUS_CLOSED,
            RD2_Constants.STATUS_LAPSED
        };

        public Set<String> recurringTypes = new Set<String>{
            RD2_Constants.RECURRING_TYPE_OPEN,
            RD2_Constants.RECURRING_TYPE_FIXED
        };

        public Set<String> dayOfMonthValues {
            get {
                if (dayOfMonthValues == null) {
                    dayOfMonthValues = getSupportedDayOfMonth();
                }
                return dayOfMonthValues;
            }
            private set;
        }

        /**
         * @description Build a list of supported day of month picklist values.
         */
        private Set<String> getSupportedDayOfMonth() {
            Set<String> values = new Set<String>();
            for (Integer i = 0; i < 31; i++) {
                values.add(String.valueOf(i));
            }

            values.add(RD2_Constants.DAY_OF_MONTH_LAST_DAY);
            return values;
        }
    }

    /**
     * @description Builds and collects health check results
     */
    public class HealthCheckResult {

        private final String statusError = STG_PanelHealthCheck_CTRL.statusError;
        private final String statusSuccess = STG_PanelHealthCheck_CTRL.statusSuccess;

        private STG_PanelHealthCheck_CTRL ctrl;
        private String scope;

        /**
         * @description Constructor
         */
        public HealthCheckResult(STG_PanelHealthCheck_CTRL ctrl) {
            this.ctrl = ctrl;
        }

        /**
         * @description Defines the current scope label for the test as recurring donation related
         */
        public HealthCheckResult withRecurringDonationScope() {
            scope = System.Label.stgNavRecurringDonations;
            return this;
        }

        /**
         * @description Define the current scope label for the test as opportunity related
         */
        public HealthCheckResult withOpportunityScope() {
            scope = System.Label.stgNavDonations;
            return this;
        }

        /**
         * @description Add a Success message to the displayed results
         */
        public void addSuccess(String solution) {
            ctrl.createDR(
                scope, statusSuccess, null, solution
            );
        }

        /**
         * @description Add an Error messge to the displayed results with a solution
         */
        public void addError(String value, String fieldLabel, String errorLabel, String solutionLabel) {
            ctrl.createDR(
                scope,
                statusError,
                String.format(
                    errorLabel,
                    new String[] { value.escapeHtml4(), fieldLabel.escapeHtml4() }
                ),
                String.format(
                    solutionLabel,
                    new String[] { value.escapeHtml4(), fieldLabel.escapeHtml4() }
                )
            );
        }

        /**
         * @description Add an error message to the list of displayed results
         */
        public void addError(String detail, String solution) {
            ctrl.createDR(
                scope, statusError, detail, solution
            );
        }

        /**
         * @description Are there any errors in the list of displayed results?
         */
        public Boolean hasErrors() {
            for (STG_PanelHealthCheck_CTRL.DetectResult dr : ctrl.listDR) {
                if (dr.strStatus == statusError) {
                    return true;
                }
            }
            return false;
        }
    }

}