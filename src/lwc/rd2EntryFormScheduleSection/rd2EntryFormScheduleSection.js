import { LightningElement, api, track, wire } from 'lwc';
import { fireEvent } from 'c/pubsubNoPageRef';

import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getRecord } from 'lightning/uiRecordApi';

import RECURRING_DONATION_OBJECT from '@salesforce/schema/npe03__Recurring_Donation__c';

import FIELD_RECURRING_TYPE from '@salesforce/schema/npe03__Recurring_Donation__c.RecurringType__c';
import FIELD_PLANNED_INSTALLMENTS from '@salesforce/schema/npe03__Recurring_Donation__c.npe03__Installments__c';
import FIELD_AMOUNT from '@salesforce/schema/npe03__Recurring_Donation__c.npe03__Amount__c';
import FIELD_PAYMENT_METHOD from '@salesforce/schema/npe03__Recurring_Donation__c.PaymentMethod__c';
import FIELD_INSTALLMENT_PERIOD from '@salesforce/schema/npe03__Recurring_Donation__c.npe03__Installment_Period__c';
import FIELD_INSTALLMENT_FREQUENCY from '@salesforce/schema/npe03__Recurring_Donation__c.InstallmentFrequency__c';
import FIELD_DAY_OF_MONTH from '@salesforce/schema/npe03__Recurring_Donation__c.Day_of_Month__c';
import FIELD_START_DATE from '@salesforce/schema/npe03__Recurring_Donation__c.StartDate__c';

import currencyFieldLabel from '@salesforce/label/c.lblCurrency';
import donationSectionHeader from '@salesforce/label/c.RD2_EntryFormDonationSectionHeader';

export default class rd2EntryFormScheduleSection extends LightningElement {

    labels = Object.freeze({
        donationSectionHeader,
        currencyFieldLabel
    });

    @api recordId;
    @api isMultiCurrencyEnabled;
    @track isLoaded = false;
    @track fields = {};

    /**
    * @description Retrieve Recurring Donation SObject info
    */
    @wire(getObjectInfo, { objectApiName: RECURRING_DONATION_OBJECT.objectApiName })
    wiredRecurringDonationObjectInfo(response) {
        if (response.data) {
            let rdObjectInfo = response.data;
            this.setFields(rdObjectInfo.fields);
            this.buildFieldDescribes(
                rdObjectInfo.fields,
                rdObjectInfo.apiName
            );

        } else if (response.error) {
            console.error(JSON.stringify(response.error));
        }

        this.isLoaded = true;
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
        this.fields.amount = this.extractFieldInfo(fieldInfos[FIELD_AMOUNT.fieldApiName]);
        this.fields.paymentMethod = this.extractFieldInfo(fieldInfos[FIELD_PAYMENT_METHOD.fieldApiName]);
        this.fields.period = this.extractFieldInfo(fieldInfos[FIELD_INSTALLMENT_PERIOD.fieldApiName]);
        this.fields.installmentFrequency = this.extractFieldInfo(fieldInfos[FIELD_INSTALLMENT_FREQUENCY.fieldApiName]);
        this.fields.dayOfMonth = this.extractFieldInfo(fieldInfos[FIELD_DAY_OF_MONTH.fieldApiName]);
        this.fields.startDate = this.extractFieldInfo(fieldInfos[FIELD_START_DATE.fieldApiName]);
        this.fields.currency = { label: currencyFieldLabel, apiName: 'CurrencyIsoCode' };
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