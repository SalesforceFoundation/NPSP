import { LightningElement, api, track, wire } from 'lwc';
import { fireEvent } from 'c/pubsubNoPageRef';
import { showToast, constructErrorMessage, isNull } from 'c/utilCommon';

import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getRecord } from 'lightning/uiRecordApi';

import RECURRING_DONATION_OBJECT from '@salesforce/schema/npe03__Recurring_Donation__c';

import FIELD_NAME from '@salesforce/schema/npe03__Recurring_Donation__c.Name';
import FIELD_CAMPAIGN from '@salesforce/schema/npe03__Recurring_Donation__c.npe03__Recurring_Donation_Campaign__c';
import FIELD_AMOUNT from '@salesforce/schema/npe03__Recurring_Donation__c.npe03__Amount__c';
import FIELD_PAYMENT_METHOD from '@salesforce/schema/npe03__Recurring_Donation__c.PaymentMethod__c';
import FIELD_STATUS from '@salesforce/schema/npe03__Recurring_Donation__c.Status__c';
import FIELD_STATUS_REASON from '@salesforce/schema/npe03__Recurring_Donation__c.ClosedReason__c';

import currencyFieldLabel from '@salesforce/label/c.lblCurrency';
import cancelButtonLabel from '@salesforce/label/c.stgBtnCancel';
import saveButtonLabel from '@salesforce/label/c.stgBtnSave';
import newHeaderLabel from '@salesforce/label/c.RD2_EntryFormHeader';
import editHeaderLabel from '@salesforce/label/c.commonEdit';
import donorSectionHeader from '@salesforce/label/c.RD2_EntryFormDonorSectionHeader';
import scheduleSectionHeader from '@salesforce/label/c.RD2_EntryFormDonationSectionHeader';
import otherSectionHeader from '@salesforce/label/c.RD2_EntryFormOtherSectionHeader';
import insertSuccessMessage from '@salesforce/label/c.RD2_EntryFormInsertSuccessMessage';
import updateSuccessMessage from '@salesforce/label/c.RD2_EntryFormUpdateSuccessMessage';

import getSetting from '@salesforce/apex/RD2_entryFormController.getSetting';

export default class rd2EntryForm extends LightningElement {

    listenerEvent = 'rd2EntryFormEvent';

    customLabels = Object.freeze({
        cancelButtonLabel,
        saveButtonLabel,
        donorSectionHeader,
        otherSectionHeader,
        scheduleSectionHeader,
        currencyFieldLabel
    });

    @api parentId;
    @api recordId;

    @track isEdit = false;
    @track record;
    @track isMultiCurrencyEnabled = false;
    @track fields = {};
    fieldInfos;

    @track header = newHeaderLabel;

    @track isAutoNamingEnabled;
    @track isLoading = true;
    @track isRecordReady = false;
    isSettingReady = false;

    @track hasError = false;
    @track errorMessage = {};

    /***
    * @description Dynamic render edit form CSS to show/hide the edit form
    */
    get cssEditForm() {
        //Note: all of these flags need to be checked before the sections are displayed.
        //If the isSettingReady is not checked, then the form on an error resets all fields
        //including the Schedule section LWC fields.
        //TODO: check why and how this expression can be simplifed.
        return (!this.isLoading && this.isSettingReady && this.isRecordReady)
            ? ''
            : 'slds-hide';
    }

    /***
    * @description Get settings required to enable or disable fields and populate their values
    */
    connectedCallback() {
        getSetting({ parentId: this.parentId })
            .then(response => {
                this.isAutoNamingEnabled = response.isAutoNamingEnabled;
                this.isMultiCurrencyEnabled = response.isMultiCurrencyEnabled;
            })
            .catch((error) => {
                this.handleError(error);
            })
            .finally(() => {
                this.isSettingReady = true;
                this.isLoading = false;
            });
    }

    /***
    * @description Retrieve Recurring Donation Object info
    */
    @wire(getObjectInfo, { objectApiName: RECURRING_DONATION_OBJECT.objectApiName })
    wiredRecurringDonationObjectInfo(response) {
        if (response.data) {
            let rdObjectInfo = response.data;
            this.setFields(rdObjectInfo.fields);
            this.fieldInfos = this.buildFieldDescribes(
                rdObjectInfo.fields,
                rdObjectInfo.apiName
            );

            if (isNull(this.recordId)) {
                this.isRecordReady = true;
            } else {
                this.isEdit = true;
            }
        }

        if (response.error) {
            this.isRecordReady = true;
            this.handleError(response.error);
        }
    }

    /***
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

    /***
    * @description Construct field describe info from the Recurring Donation SObject info
    */
    setFields(fieldInfos) {
        this.fields.name = this.extractFieldInfo(fieldInfos[FIELD_NAME.fieldApiName]);
        this.fields.campaign = this.extractFieldInfo(fieldInfos[FIELD_CAMPAIGN.fieldApiName]);
        this.fields.amount = this.extractFieldInfo(fieldInfos[FIELD_AMOUNT.fieldApiName]);
        this.fields.paymentMethod = this.extractFieldInfo(fieldInfos[FIELD_PAYMENT_METHOD.fieldApiName]);
        this.fields.status = this.extractFieldInfo(fieldInfos[FIELD_STATUS.fieldApiName]);
        this.fields.statusreason = this.extractFieldInfo(fieldInfos[FIELD_STATUS_REASON.fieldApiName]);
        this.fields.currency = { label: currencyFieldLabel, apiName: 'CurrencyIsoCode' };
    }

    /***
    * @description Method converts field describe info into a object that is easily accessible from the front end
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
    * @description Retrieve Recurring Donation record value
    */
    @wire(getRecord, { recordId: '$recordId', fields: '$fieldInfos' })
    wiredRecurringDonationRecord(response) {
        if (response.data) {
            this.record = response.data;
            this.header = editHeaderLabel + ' ' + this.record.fields.Name.value;
            this.isRecordReady = true;
        }

        if (response.error) {
            this.isRecordReady = true;
            this.handleError(response.error);
        }
    }


    /***
    * @description Overrides the standard submit.
    * Collects fields displayed on the form and any integrated LWC (for example Schedule section)
    * and submits them for the record insert or update.
    */
    handleSubmit(event) {
        this.isLoading = true;
        this.hasError = false;
        this.template.querySelector("[data-id='submitButton']").disabled = true;

        event.preventDefault();
        const fields = event.detail.fields;

        const scheduleSection = this.template.querySelector('c-rd2-entry-form-schedule-section');
        const scheduleFields = (scheduleSection === null || scheduleSection === undefined)
            ? {}
            : scheduleSection.returnValues();

        const donorSection = this.template.querySelector('c-rd2-entry-form-donor-section');
        const donorFields = (donorSection === null || donorSection === undefined)
            ? {}
            : donorSection.returnValues();

        const allFields = {
            ...fields, ...scheduleFields, ...donorFields
        };

        this.template.querySelector('[data-id="outerRecordEditForm"]').submit(allFields);
    }

    /***
    * @description Handle component display when an error occurs
    */
    handleError(error) {
        this.errorMessage = constructErrorMessage(error);
        this.hasError = true;
        this.isLoading = false;

        this.template.querySelector("[data-id='submitButton']").disabled = false;
        this.template.querySelector(".slds-modal__header").scrollIntoView();
    }

    /***
    * @description Fires an event to utilDedicatedListener with the cancel action
    */
    handleCancel() {
        fireEvent(this.pageRef, this.listenerEvent, { action: 'cancel', recordId: this.recordId });
    }

    /***
    * @description Fires an event to utilDedicatedListener with the success action
    */
    handleSuccess(event) {
        const recordName = event.detail.fields.Name.value;
        const message = (this.recordId)
            ? updateSuccessMessage.replace("{0}", recordName)
            : insertSuccessMessage.replace("{0}", recordName);

        showToast(message, '', 'success', []);

        fireEvent(this.pageRef, this.listenerEvent, { action: 'success', recordId: event.detail.id });
    }

}

/**
 * TODO This does not work yet. The calling code says "Type Error: handleError is not a function"
 * @param {object} error:
 */
const handleError = (error) => {
    alert('handleError');
    rd2EntryForm.handleError(error);
}

export {
    handleError
};