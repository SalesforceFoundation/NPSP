/*
    Copyright (c) 2020 Salesforce.org
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
* @group Recurring Donations
* @description Recurring Donation settings wrapper
*
*/
public with sharing class RD2_Settings {
    private static RD2_Settings rdSettings;

    public static RD2_Settings getInstance() {
        if (rdSettings == null) {
            rdSettings = new RD2_Settings();
        }
        return rdSettings;
    }

    /***
    * @description Recurring Donation custom settings
    */
    private npe03__Recurring_Donations_Settings__c settings {
        get {
            if (settings == null) {
                settings = UTIL_CustomSettingsFacade.getRecurringDonationsSettings();
            } 
            return settings;
        }
        set;
    }

    public void reloadSetting() {
        settings = null;
    }

    /***
    * @description The installment Opportunity Stage
    */
    public String installmentStage {
        get {
            if (installmentStage == null) {
                installmentStage = String.isNotBlank(settings.InstallmentOppStageName__c)
                    ? settings.InstallmentOppStageName__c
                    : System.Label.npe03.RecurringDonationStageName;
            }
            return installmentStage;
        } 
        private set;
    }

    /***
    * @description The installment Opportunity Record Type Id
    */
    public Id installmentRecordTypeId {
        get {            
            return (Id) settings.npe03__Record_Type__c;
        } 
        private set;
    }

    /***
    * @description Indicates if Campaign should be propagated from RD to the installment Opportunity
    */
    public Boolean shouldSetInstallmentCampaign {
        get {            
            return settings.npe03__Add_Campaign_to_All_Opportunites__c;
        } 
        private set;
    }

    /***
    * @description Indicates if Recurring Donation Change Log is Enabled
    */
    public Boolean isChangeLogEnabled() {
        return settings.EnableChangeLog__c == true;
    }

    /***
    * @description Indicates if open installment Opportunities should be deleted when RD is closed
    */
    public Boolean isCloseActionDeletion() {
        return settings.npe03__Open_Opportunity_Behavior__c == RD2_Constants.CloseActions.Delete_Open_Opportunities.name();
    }

    /***
    * @description Indicates if open installment Opportunities should be set to Closed Lost when RD is closed
    */
    public Boolean isCloseActionClosedLost() {
        return settings.npe03__Open_Opportunity_Behavior__c == RD2_Constants.CloseActions.Mark_Opportunities_Closed_Lost.name();
    }

    /***
    * @description Indicates if open installment Opportunities should be unchanged when RD is closed
    */
    public Boolean isCloseActionNoAction() {
        return settings.npe03__Open_Opportunity_Behavior__c == RD2_Constants.CloseActions.No_Action.name();
    }

    /***
    * @description Retrieve RD2_Entry_Form_Custom_Fields Fieldset and eliminate any packaged and already displayed fields
    * @return List<Schema.FieldSetMember>
    */
    public List<Schema.FieldSetMember> getCustomFieldSetMembers() {
        Set<String> excludedCustomFields = getExcludedCustomFields();

        List<Schema.FieldSetMember> fields = new List<Schema.FieldSetMember>();
        List<Schema.FieldSetMember> fieldSetFields = Schema.SObjectType.npe03__Recurring_Donation__c.fieldSets.RD2_Entry_Form_Custom_Fields.getFields();

        for (Schema.FieldSetMember field : fieldSetFields) {
            if (excludedCustomFields.contains(field.getFieldPath())
                    || field.getFieldPath().startsWith('npsp__')
                    || field.getFieldPath().startsWith('npe03__')
                    || !UTIL_Describe.getFieldDescribe('npe03__Recurring_Donation__c', field.getFieldPath()).isAccessible()
                    ) {
                continue;
            }

            fields.add(field);
        }

        return fields;
    }


    /***
    * @description Installment Opp Auto Creation Option,
    * If random string is input, the setting will be default to Always Create Next installment
    */
    public String installmentCreateOption {
        get {
            if (installmentCreateOption == null) {
                installmentCreateOption = String.isNotBlank(settings.InstallmentOppAutoCreateOption__c)
                    ? settings.InstallmentOppAutoCreateOption__c
                    : RD2_Constants.InstallmentCreateOptions.Always_Create_Next_Installment.name();
            }

            return installmentCreateOption;
        }
        private set;
    }

    /***
    * @description Sets execution mode for insertion of first Opportunity on a Recurring Donation
    */
    @TestVisible
    public String firstInstallmentCreateMode {
        get {
            if (firstInstallmentCreateMode == null) {
                firstInstallmentCreateMode = String.isNotBlank(settings.InstallmentOppFirstCreateMode__c)
                    ? settings.InstallmentOppFirstCreateMode__c
                    : RD2_Constants.FirstInstallmentOppCreateOptions.Synchronous.name();
            }

            return firstInstallmentCreateMode;
        }
        private set;
    }

    /***
    * @description Indicates if the first installment can be created on a Recurring Donation
    */
    public Boolean isFirstInstallmentEnabled {
        get {
            if (isFirstInstallmentEnabled == null) {
                isFirstInstallmentEnabled =
                    installmentCreateOption != RD2_Constants.InstallmentCreateOptions.Disable_First_Installment.name()
                    && installmentCreateOption != RD2_Constants.InstallmentCreateOptions.Disable_All_Installments.name();
            }
            return isFirstInstallmentEnabled;
        } 
        private set;
    }

    /***
    * @description Indicates if the next installment can be created on a Recurring Donation
    */
    public Boolean isNextInstallmentEnabled {
        get {
            if (isNextInstallmentEnabled == null) {
                isNextInstallmentEnabled =
                    installmentCreateOption != RD2_Constants.InstallmentCreateOptions.Disable_All_Installments.name();
            }
            
            return isNextInstallmentEnabled;
        } 
        private set;
    }

    /***
    * @description Indicates if any installment creation on a Recurring Donation is disabled
    */
    public Boolean isDisableAllInstallments {
        get {
            if (isDisableAllInstallments == null) {
                isDisableAllInstallments =
                    installmentCreateOption == RD2_Constants.InstallmentCreateOptions.Disable_All_Installments.name();
            }
            return isDisableAllInstallments;
        } 
        private set;
    }

    /***
    * @description Specifies number of days before and after the installment Close Date
    * so it can be matched with an existing Opportunity
    */
    public Integer nextDonationDateMatchDays {
        get {
            if (nextDonationDateMatchDays == null) {
                Decimal value = settings.NextDonationDateMatchRangeDays__c;

                nextDonationDateMatchDays = value == null || value < 0
                    ? RD2_Constants.DEFAULT_NEXT_DONATION_DATE_MATCH_RANGE_DAYS
                    : Integer.valueOf(value);
            }
            return nextDonationDateMatchDays;
        }
        private set;
    }

    /***
    * @description Retrieves configuration determining if the fiscal year should be used
    * for the current/next year value calculations
    */
    public Boolean useFiscalYear {
        get {
            if (useFiscalYear == null) {
                useFiscalYear = settings.UseFiscalYearForRecurringDonationValue__c == true;
            }
            return useFiscalYear;
        } 
        private set;
    }

    /***
    * @description Saves latest Recurring Donation batch results
    */
    public void saveLatestBatchResults(Id jobId, Integer recordsProcessed, Integer recordsFailed) {
        AsyncApexJob job = new UTIL_BatchJobService().getAsyncApexJob(jobId);

        settings.npe03__Last_Batch_Run__c = job == null ? Datetime.now() : job.CompletedDate;
        settings.npe03__Number_of_Successes__c = recordsProcessed - recordsFailed;
        settings.npe03__Number_of_Failures__c = recordsFailed;

        if (!Test.isRunningTest()) {
            upsert settings;
        }
    }

    public Boolean isStatusAutomationForClosedEnabled() {
        return settings.StatusAutomationDaysForClosed__c != null;
    }

    public Boolean isStatusAutomationForLapsedEnabled() {
        return settings.StatusAutomationDaysForLapsed__c != null;
    }

    public String statusAutomationClosedValue {
        get {
            if (statusAutomationClosedValue == null) {
                statusAutomationClosedValue = settings.StatusAutomationClosedValue__c;
            }
            return statusAutomationClosedValue;
        }
        private set;
    }

    public String statusAutomationLapsedValue {
        get {
            if (statusAutomationLapsedValue == null) {
                statusAutomationLapsedValue = settings.StatusAutomationLapsedValue__c;
            }
            return statusAutomationLapsedValue;
        }
        private set;
    }

    public Integer statusAutomationNumberOfDaysForClosed {
        get {
            if (statusAutomationNumberOfDaysForClosed == null) {
                statusAutomationNumberOfDaysForClosed = (settings.StatusAutomationDaysForClosed__c == null)
                    ? null
                    : Integer.valueOf(settings.StatusAutomationDaysForClosed__c);
            }
            return statusAutomationNumberOfDaysForClosed;
        }
        private set;
    }

    public Integer statusAutomationNumberOfDaysForLapsed {
        get {
            if (statusAutomationNumberOfDaysForLapsed == null) {
                statusAutomationNumberOfDaysForLapsed = (settings.StatusAutomationDaysForLapsed__c == null)
                    ? null
                    : Integer.valueOf(settings.StatusAutomationDaysForLapsed__c);
            }
            return statusAutomationNumberOfDaysForLapsed;
        }
        private set;
    }

    /**
    * @description Set of fields that will be excluded from the RD2_EntryForm Custom Field Section
    */
    @TestVisible
    private static Set<String> getExcludedCustomFields() {
        return new Set<String> {
                'CreatedById',
                'CreatedDate',
                'CurrencyIsoCode',
                'Id',
                'IsDeleted',
                'LastModifiedById',
                'LastModifiedDate',
                'LastReferencedDate',
                'LastViewedDate',
                'Name',
                'OwnerId',
                'SystemModStamp'
        };
    }
}
