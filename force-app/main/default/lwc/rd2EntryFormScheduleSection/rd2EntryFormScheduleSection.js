import { LightningElement, api, track, wire } from "lwc";
import { getObjectInfo, getPicklistValues } from "lightning/uiObjectInfoApi";
import { isNull } from "c/utilCommon";
import { PERIOD, RECURRING_PERIOD_ADVANCED, RECURRING_TYPE_OPEN, RECURRING_TYPE_FIXED } from "c/rd2Service";

import picklistLabelAdvanced from "@salesforce/label/c.RD2_EntryFormPeriodAdvanced";
import customPeriodHelpText from "@salesforce/label/c.RD2_EntryFormPeriodHelpText";
import fieldLabelPeriod from "@salesforce/label/c.RD2_EntryFormPeriodLabel";
import periodPluralDays from "@salesforce/label/c.RD2_EntryFormPeriodPluralDaily";
import periodPluralMonths from "@salesforce/label/c.RD2_EntryFormPeriodPluralMonthly";
import periodPluralWeeks from "@salesforce/label/c.RD2_EntryFormPeriodPluralWeekly";
import periodPluralYears from "@salesforce/label/c.RD2_EntryFormPeriodPluralYearly";
import fieldLabelEvery from "@salesforce/label/c.RD2_EntryFormScheduleEveryLabel";

import RECURRING_DONATION_OBJECT from "@salesforce/schema/npe03__Recurring_Donation__c";
import FIELD_RECURRING_TYPE from "@salesforce/schema/npe03__Recurring_Donation__c.RecurringType__c";
import FIELD_PLANNED_INSTALLMENTS from "@salesforce/schema/npe03__Recurring_Donation__c.npe03__Installments__c";
import FIELD_INSTALLMENT_PERIOD from "@salesforce/schema/npe03__Recurring_Donation__c.npe03__Installment_Period__c";
import FIELD_INSTALLMENT_FREQUENCY from "@salesforce/schema/npe03__Recurring_Donation__c.InstallmentFrequency__c";
import FIELD_DAY_OF_MONTH from "@salesforce/schema/npe03__Recurring_Donation__c.Day_of_Month__c";
import FIELD_START_DATE from "@salesforce/schema/npe03__Recurring_Donation__c.StartDate__c";

// Constants from RD2_Constants class
const LAST_DAY_OF_MONTH = "Last_Day";
const MONTHLY = "Monthly";

export default class rd2EntryFormScheduleSection extends LightningElement {
    @api rd2State;
    @api isPaymentModal = false;
    @api isAmountFrequencyModal = false;
    @api isExperienceSite = false;
    cssHideExperienceSite;
    cssHideOnlyPaymentModal;
    cssHideOnlyAmountFrequencyModal;
    cssLastDay;
    firstRendered = true;
    @track isMonthlyDonation = false;
    @api isElevateDonation = false;
    @api isInitiallyMonthlyDonation = false;

    @track fields = {};

    customLabels = Object.freeze({
        picklistLabelAdvanced,
        fieldLabelEvery,
        fieldLabelPeriod,
        customPeriodHelpText,
        periodPluralDays,
        periodPluralMonths,
        periodPluralWeeks,
        periodPluralYears,
    });

    isRecordReady = false;
    hasError = false;

    isLoading = true;

    customPeriod = PERIOD.MONTHLY; // defaults to monthly, can also be RECURRING_PERIOD_ADVANCED

    rdObjectInfo;

    get isNew() {
        return isNull(this.rd2State.recordId);
    }

    get hidePeriodPicklistField() {
        return this.shouldHideField(this.rd2State.InstallmentPeriodPermissions);
    }

    get disablePeriodPicklistField() {
        return this.shouldDisableField(this.rd2State.InstallmentPeriodPermissions);
    }

    get hideInstallmentFrequencyField() {
        return this.shouldHideField(this.rd2State.InstallmentFrequencyPermissions);
    }

    get disableInstallmentFrequencyField() {
        return this.shouldDisableField(this.rd2State.InstallmentFrequencyPermissions);
    }

    /**
     * @description Retrieve Recurring Donation SObject info
     */
    @wire(getObjectInfo, { objectApiName: RECURRING_DONATION_OBJECT.objectApiName })
    wiredRecurringDonationObjectInfo(response) {
        if (response.data) {
            this.rdObjectInfo = response.data;
            this.setFields(this.rdObjectInfo.fields);
            this.buildFieldDescribes();
            this.isLoading = !this.isEverythingLoaded();
            

            this.cssHideExperienceSite = this.isExperienceSite ? 'slds-hide' : '';
            this.cssHideOnlyPaymentModal = this.isPaymentModal ? 'slds-hide' : '';
            this.cssHideOnlyAmountFrequencyModal = this.isAmountFrequencyModal ? 'slds-hide' : '';

        } else if (response.error) {
            this.hasError = true;
            this.dispatchEvent(new CustomEvent("errorevent", { detail: { value: response.error } }));
        }
    }

    renderedCallback() {
        this.applyCSSOnlyOnEperienceSite();
    }

    /***
     * @description Applies CSS styles to rendered elements only for Experience Sites.
     */
    applyCSSOnlyOnEperienceSite() {
        this.cssHideExperienceSite = this.isExperienceSite ? 'slds-hide' : '';
        this.cssHideOnlyPaymentModal = this.isPaymentModal ? 'slds-hide' : '';
        this.cssHideOnlyAmountFrequencyModal = this.isAmountFrequencyModal ? 'slds-hide' : '';
        
        
        if(this.isExperienceSite && this.firstRendered) {
            if(this.rd2State.dayOfMonth) {
                this.isMonthlyDonation = !this.isElevateDonation ? true : false;
            } else {
                this.isMonthlyDonation = false;
                let dd = String(new Date().getDate()).padStart(2, "0");
                this.rd2State.dayOfMonth = dd === 31 ? LAST_DAY_OF_MONTH : dd;
            }
            this.cssLastDay = !this.isMonthlyDonation || this.isPaymentModal ? 'slds-hide' : 'slds-p-right_small slds-p-left_small slds-size_12-of-12 slds-large-size_4-of-12 fixExperienceDayOfMonth';
        }
        this.firstRendered = false;
    }

    /**
     * @description Set isLoading to false only after all wired actions have fully completed
     * @returns True (All Done) or False (Still Loading)
     */
    isEverythingLoaded() {
        return (
            this.installmentPeriodPicklistValues &&
            this.dayOfMonthPicklistValues &&
            this.isRecordReady &&
            this.rdObjectInfo &&
            !this.hasError
        );
    }

    /**
     * @description Method converts field describe info into objects that the
     * getRecord method can accept into its 'fields' parameter.
     */
    buildFieldDescribes() {
        const { fields, apiName } = this.rdObjectInfo;
        return Object.keys(fields).map((fieldApiName) => {
            return {
                fieldApiName: fieldApiName,
                objectApiName: apiName,
            };
        });
    }

    /**
     * @description Construct field describe info from the Recurring Donation SObject info
     */
    setFields(fieldInfos) {
        this.fields.recurringType = this.extractFieldInfo(fieldInfos, FIELD_RECURRING_TYPE.fieldApiName);
        this.fields.period = this.extractFieldInfo(fieldInfos, FIELD_INSTALLMENT_PERIOD.fieldApiName);
        this.fields.installmentFrequency = this.extractFieldInfo(fieldInfos, FIELD_INSTALLMENT_FREQUENCY.fieldApiName);
        this.fields.dayOfMonth = this.extractFieldInfo(fieldInfos, FIELD_DAY_OF_MONTH.fieldApiName);
        this.fields.startDate = this.extractFieldInfo(fieldInfos, FIELD_START_DATE.fieldApiName);
        this.fields.plannedInstallments = this.extractFieldInfo(fieldInfos, FIELD_PLANNED_INSTALLMENTS.fieldApiName);
        this.isRecordReady = true;
    }

    /**
     * @description Converts field describe info into a object that is easily accessible from the front end
     * Ignore errors to allow the UI to simply not render the layout-item if the field info doesn't exist
     * (i.e, the field isn't accessible).
     */
    extractFieldInfo(fieldInfos, fldApiName) {
        try {
            const field = fieldInfos[fldApiName];
            return {
                apiName: field.apiName,
                label: field.label,
                inlineHelpText: field.inlineHelpText,
                dataType: field.dataType,
            };
        } catch (error) {}
    }

    /**
     * @description Returns a boolean to disable entry into a field based on the FLS
     * @returns True to disable entry into the field
     */
    shouldDisableField(fieldPerms) {
        return this.isNew ? !fieldPerms.Createable : !fieldPerms.Updateable;
    }

    /**
     * @description Returns a boolean to hide a field based on the FLS
     * @returns True to hide the field entirely in the UI
     */
    shouldHideField(fieldPerms) {
        return !fieldPerms.Visible;
    }

    /***
     * @description Retrieve Recurring Donation Day of Month picklist values
     */
    @wire(getPicklistValues, { fieldApiName: FIELD_DAY_OF_MONTH, recordTypeId: "$rdObjectInfo.defaultRecordTypeId" })
    wiredDayOfMonthPicklistValues({ error, data }) {
        if (data) {
            this.dayOfMonthPicklistValues = data.values;
        } else if (error) {
            // Day of Month field likely not visible
            this.dayOfMonthPicklistValues = {};
        }
        this.isLoading = !this.isEverythingLoaded();
    }

    /***
     * @description Retrieve Recurring Donation Installment Period picklist values
     */
    @wire(getPicklistValues, {
        fieldApiName: FIELD_INSTALLMENT_PERIOD,
        recordTypeId: "$rdObjectInfo.defaultRecordTypeId",
    })
    wiredInstallmentPeriodPicklistValues({ error, data }) {
        if (data) {
            this.installmentPeriodPicklistValues = data.values;
        } else if (error) {
            // Installment Period field likely not visible
            this.installmentPeriodPicklistValues = {};
        }
        this.isLoading = !this.isEverythingLoaded();
    }

    /***
     * @description Sets Day of Month to current day for a new Recurring Donation record.
     * When no match is found, ie today is day 31 in a month, return 'Last_Day' API value.
     * @return String Current day
     */
    getCurrentDayOfMonth() {
        const currentDay = new Date().getDate().toString();

        const matchingPicklistValue = this.dayOfMonthPicklistValues.find(({ value }) => {
            return value === currentDay;
        });

        return matchingPicklistValue ? matchingPicklistValue.value : LAST_DAY_OF_MONTH;
    }

    handleDayOfMonthChange(event) {
        const dayOfMonth = event.target.value;
        this.dispatchEvent(new CustomEvent("dayofmonthchange", { detail: dayOfMonth }));
    }

    handleStartDateChange(event) {
        const startDate = event.target.value;
        this.dispatchEvent(new CustomEvent("startdatechange", { detail: startDate }));
    }

    /**
     * @description Automatically Show/Hide the NumberOfPlannedInstallments field based on the Recurring Type value
     * @param event
     */
    handleRecurringTypeChange(event) {
        const recurringType = event.target.value;
        // Notify the main entry form about the Recurring Type value change
        this.dispatchEvent(new CustomEvent("typechange", { detail: recurringType }));
    }

    /**
     * @description When the custom Recurring Period picklist is updated change what other fields are visible on the
     * page: Monthly - just day of month; Advanced: Show the full period picklist and other fields.
     * @param event
     */
    handleRecurringPeriodChange(event) {
        const recurringPeriod = event.target.value;
        this.dispatchEvent(new CustomEvent("periodtypechange", { detail: recurringPeriod }));
    }

    /**
     * @description When the Recurring Period picklist is Advanced, this picklist is visible and allows the User to select
     * any of the supported (and active) installment periods. If Monthly is selected, enable the DayOfMonth field visibility.
     * @param event
     */
    handleAdvancedPeriodChange(event) {
        this.toggleLastDayFieldOnExperienceSite(event);
        const period = event.target.value;
        this.dispatchEvent(new CustomEvent("periodchange", { detail: period }));
    }

    /**
     * @description On Experience Sites, based on the Recurrent Donation data it will show/hide Last Date field.
     * @param event
     */
    toggleLastDayFieldOnExperienceSite(event) {
        if(this.isExperienceSite) {
            if((event.target.value === MONTHLY && this.isElevateDonation && this.isInitiallyMonthlyDonation)||!(event.target.value === MONTHLY)) {
                this.isMonthlyDonation = false;
            } else {
                this.isMonthlyDonation = true;
            }
            this.cssLastDay = !this.isMonthlyDonation || this.isPaymentModal ? 'slds-hide' : 'slds-p-right_small slds-p-left_small slds-size_12-of-12 slds-large-size_4-of-12 fixExperienceDayOfMonth';
        }
    }

    /**
     * @description When the frequency changes, we need to check if the Annual Value changed
     * @param event
     */
    handleRecurringFrequencyChange(event) {
        this.dispatchEvent(new CustomEvent("frequencychange", { detail: event.target.value }));
    }

    /**
     * @description When the installments change, we need to check if the Annual Value changed
     * @param event
     */
    handlePlannedInstallmentsChange(event) {
        this.dispatchEvent(new CustomEvent("installmentschange", { detail: event.target.value }));
    }

    get _showDayOfMonth() {
        return this.rd2State.recurringPeriod === PERIOD.MONTHLY;
    }

    get _scheduleRowColumnSize() {
        if(this.isAmountFrequencyModal) {
            return 4;
        } else if (this.rd2State.periodType === PERIOD.MONTHLY) {
            return 6;
        } else if (this.rd2State.recurringPeriod === PERIOD.MONTHLY) {
            return 3;
        } else {
            return 4;
        }
    }

    get _isAdvancedMode() {
        return this.rd2State.periodType === RECURRING_PERIOD_ADVANCED;
    }

    get _recurringTypeColumnSize() {
        return this.rd2State.recurringType === RECURRING_TYPE_FIXED ? 4 : 6;
    }

    get _showNumPlannedInstallments() {
        return this.rd2State.recurringType === RECURRING_TYPE_FIXED;
    }

    /**
     * @description Custom Period picklist options - Advanced and Monthly (using the correct labels)
     */
    get customPeriodOptions() {
        let monthlyLabel = PERIOD.MONTHLY;

        // Get the translated labels for Monthly if there is one
        this.installmentPeriodPicklistValues.forEach((pl) => {
            if (pl.value === PERIOD.MONTHLY) {
                monthlyLabel = pl.label;
            }
        });

        return [
            { label: monthlyLabel, value: PERIOD.MONTHLY },
            { label: this.customLabels.picklistLabelAdvanced, value: RECURRING_PERIOD_ADVANCED },
        ];
    }

    /**
     * @description Build the picklist values to use for the Period picklist in the Advanced view. These replace
     * the standard Monthly, Weekly, Yearly labels with Months, Weeks, Years - but only for labels visible in
     * this Picklist on this UI.
     */
    get advancedPeriodOptions() {
        return this.installmentPeriodPicklistValues.map(({ label, value }) => {
            switch (value) {
                case PERIOD.DAILY:
                    return { label: this.customLabels.periodPluralDays, value };
                case PERIOD.WEEKLY:
                    return { label: this.customLabels.periodPluralWeeks, value };
                case PERIOD.MONTHLY:
                    return { label: this.customLabels.periodPluralMonths, value };
                case PERIOD.YEARLY:
                    return { label: this.customLabels.periodPluralYears, value };
                default:
                    return { label, value };
            }
        });
    }

    /**
     * Resets the Schedule fields as they were upon the initial load
     */
    @api
    reset() {
        this.template.querySelectorAll("lightning-input-field").forEach((field) => {
            field.reset();
        });
    }

    /**
     * @description Checks if values specified on fields are valid
     * @return Boolean
     */
    @api
    isValid() {
        let isValid = true;

        this.template.querySelectorAll("lightning-input-field").forEach((field) => {
            if (!field.reportValidity()) {
                isValid = false;
            }
        });

        this.template.querySelectorAll(".advanced-mode-fields").forEach((field) => {
            if (!field.reportValidity()) {
                isValid = false;
            }
        });

        return isValid;
    }

    /**
     * @description Returns fields displayed on the Recurring Donation Schedule section
     * @return Object containing field API names and their values
     */
    @api
    returnValues() {
        let data = {};

        // Standard Input Fields
        this.template.querySelectorAll("lightning-input-field").forEach((field) => {
            data[field.fieldName] = field.value;
        });

        // Overridden inputs using lighting-input or lightning-combobox
        this.template.querySelectorAll(".advanced-mode-fields").forEach((input) => {
            switch (input.name) {
                case "installmentFrequency":
                    data[this.fields.installmentFrequency.apiName] = input.value;
                    break;
                case "CustomPeriodSelect":
                    if (!this._isAdvancedMode) {
                        data[this.fields.period.apiName] = input.value;
                    }
                    break;
                case "advancedPeriodSelect":
                    if (this._isAdvancedMode) {
                        data[this.fields.period.apiName] = input.value;
                    }
                    break;
            }
        });

        if (data[this.fields.recurringType.apiName] === RECURRING_TYPE_OPEN) {
            data[this.fields.plannedInstallments.apiName] = null;
        }

        return data;
    }

    /**
     * @description reset all lighning-input-field value
     */
    @api
    resetValues() {
        this.template.querySelectorAll("lightning-input-field").forEach((field) => {
            if (field.value) {
                field.reset();
            }
        });
        this.isLoading = true;
    }


    /** Deprecated API properties */
    @api recordId;

    @api
    load() {}

    @api
    getRecurringType() {}

    @api
    getInstallmentPeriod() {}

    @api
    forceRefresh() {}
    
}
