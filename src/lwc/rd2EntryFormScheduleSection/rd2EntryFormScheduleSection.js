import { LightningElement, api, track, wire } from 'lwc';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import { handleError } from 'c/rd2EntryForm'
import { isNull } from 'c/utilCommon';

import getSetting from '@salesforce/apex/RD2_entryFormController.getSetting';

import RECURRING_DONATION_OBJECT from '@salesforce/schema/npe03__Recurring_Donation__c';
import FIELD_RECURRING_TYPE from '@salesforce/schema/npe03__Recurring_Donation__c.RecurringType__c';
import FIELD_PLANNED_INSTALLMENTS from '@salesforce/schema/npe03__Recurring_Donation__c.npe03__Installments__c';
import FIELD_INSTALLMENT_PERIOD from '@salesforce/schema/npe03__Recurring_Donation__c.npe03__Installment_Period__c';
import FIELD_INSTALLMENT_FREQUENCY from '@salesforce/schema/npe03__Recurring_Donation__c.InstallmentFrequency__c';
import FIELD_DAY_OF_MONTH from '@salesforce/schema/npe03__Recurring_Donation__c.Day_of_Month__c';
import FIELD_START_DATE from '@salesforce/schema/npe03__Recurring_Donation__c.StartDate__c';

export default class rd2EntryFormScheduleSection extends LightningElement {

    @api recordId;
    @track isLoading = true;
    isNew = false;

    @track fields = {};
    rdObjectInfo;
    dayOfMonthPicklistValues;
    dayOfMonthLastDay;

    /***
    * @description Get settings required to enable or disable fields and populate their values
    */
    connectedCallback() {
        if (isNull(this.recordId)) {
            this.isNew = true;
        }

        getSetting({ parentId: null })
            .then(response => {
                this.dayOfMonthLastDay = response.dayOfMonthLastDay;
            })
            .catch((error) => {
                handleError(error);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    /**
    * @description Retrieve Recurring Donation SObject info
    */
    @wire(getObjectInfo, { objectApiName: RECURRING_DONATION_OBJECT.objectApiName })
    wiredRecurringDonationObjectInfo(response) {
        if (response.data) {
            this.rdObjectInfo = response.data;
            this.setFields(this.rdObjectInfo.fields);
            this.buildFieldDescribes(
                this.rdObjectInfo.fields,
                this.rdObjectInfo.apiName
            );
            this.isLoading = false;

        } else if (response.error) {
            this.isLoading = false;
            handleError(response.error);
        }
    }

    /**
    * @description Method converts field describe info into objects that the
    * getRecord method can accept into its 'fields' parameter.
    */
    buildFieldDescribes(fields, objectApiName) {
        return Object.keys(fields).map((fieldApiName) => {
            return {
                fieldApiName: fieldApiName,
                objectApiName: objectApiName
            }
        });
    }

    /**
    * @description Construct field describe info from the Recurring Donation SObject info
    */
    setFields(fieldInfos) {
        this.fields.recurringType = this.extractFieldInfo(fieldInfos[FIELD_RECURRING_TYPE.fieldApiName]);
        this.fields.period = this.extractFieldInfo(fieldInfos[FIELD_INSTALLMENT_PERIOD.fieldApiName]);
        this.fields.installmentFrequency = this.extractFieldInfo(fieldInfos[FIELD_INSTALLMENT_FREQUENCY.fieldApiName]);
        this.fields.dayOfMonth = this.extractFieldInfo(fieldInfos[FIELD_DAY_OF_MONTH.fieldApiName]);
        this.fields.startDate = this.extractFieldInfo(fieldInfos[FIELD_START_DATE.fieldApiName]);
        this.fields.plannedInstallments = this.extractFieldInfo(fieldInfos[FIELD_PLANNED_INSTALLMENTS.fieldApiName]);
    }

    /**
    * @description Converts field describe info into a object that is easily accessible from the front end
    */
    extractFieldInfo(field) {
        return {
            apiName: field.apiName,
            label: field.label,
            inlineHelpText: field.inlineHelpText,
            dataType: field.dataType
        };
    }

    /***
    * @description Set Installment Frequency to 1 for a new Recurring Donation record
    */
    get defaultInstallmentFrequency() {
        return (this.isNew) ? '1' : undefined;
    }

    /***
    * @description Set today's day as default Day of Month value for a new Recurring Donation record
    */
    get defaultDayOfMonth() {
        return (this.isNew && this.dayOfMonthPicklistValues)
            ? this.getCurrentDayOfMonth()
            : undefined;
    }

    /***
    * @description Retrieve Recurring Donation Day of Month picklist values
    */
    @wire(getPicklistValues, { fieldApiName: FIELD_DAY_OF_MONTH, recordTypeId: '$rdObjectInfo.defaultRecordTypeId' })
    wiredPicklistValues({ error, data }) {
        if (data) {
            this.dayOfMonthPicklistValues = data.values;
        }
        if (error) {
            handleError(error);
        }
    }

    /***
    * @description Sets Day of Month to current day for a new Recurring Donation record.
    * When no match is found, ie today is day 31 in a month, return 'Last_Day' API value.
    * @return String Current day
    */
    getCurrentDayOfMonth() {
        let currentDay = new Date().getDate().toString();

        let matchingPicklistValue = this.dayOfMonthPicklistValues.find(value => {
            return value.value == currentDay;
        });

        return (matchingPicklistValue)
            ? matchingPicklistValue.value
            : this.dayOfMonthLastDay;
    }

    /**
     * Resets the Schedule fields as they were upon the initial load
     */
    @api
    reset() {
        this.template.querySelectorAll('lightning-input-field')
            .forEach(field => {
                field.reset();
            });
    }

    /**
     * Populates the Schedule form fields based on provided data
     */
    @api
    load(data) {
        //TODO, what is the format of "data"?
    }

    /**
     * Checks if values specified on fields are valid
     * @return Boolean
     */
    @api
    isValid() {
        const scheduleFields = this.template.querySelectorAll('lightning-input-field');

        for (const field of scheduleFields) {
            if (!field.isValid()) {
                return false;
            }
        }
        return true;
    }

    /**
     * @description Returns fields displayed on the Recurring Donation Schedule section
     * @return Object containing field API names and their values
     */
    @api
    returnValues() {
        let data = {};

        this.template.querySelectorAll('lightning-input-field')
            .forEach(field => {
                data[field.fieldName] = field.value;
            });

        return data;
    }

}