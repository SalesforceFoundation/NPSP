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
import statusSectionHeader from '@salesforce/label/c.RD2_EntryFormStatusSectionHeader';
import insertSuccessMessage from '@salesforce/label/c.RD2_EntryFormInsertSuccessMessage';
import updateSuccessMessage from '@salesforce/label/c.RD2_EntryFormUpdateSuccessMessage';
import flsErrorDetail from '@salesforce/label/c.RD2_EntryFormMissingPermissions';
import flsErrorHeader from '@salesforce/label/c.geErrorFLSHeader';

import getSetting from '@salesforce/apex/RD2_entryFormController.getRecurringSettings';

export default class rd2EntryForm extends LightningElement {

    listenerEvent = 'rd2EntryFormEvent';

    customLabels = Object.freeze({
        cancelButtonLabel,
        saveButtonLabel,
        donorSectionHeader,
        otherSectionHeader,
        scheduleSectionHeader,
        statusSectionHeader,
        currencyFieldLabel,
        flsErrorHeader,
        flsErrorDetail
    });

    @api parentId;
    @api recordId;

    @track isEdit = false;
    @track record;
    @track isMultiCurrencyEnabled = false;
    @track fields = {};
    @track rdSettings = {};
    fieldInfos;

    @track header = newHeaderLabel;

    @track isAutoNamingEnabled;
    @track isLoading = true;

    isRecordReady = false;
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
        return (!this.isLoading && this.isSettingReady && this.isRecordReady && !this.hasError)
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
                this.isSettingReady = true;
                this.rdSettings = response;
            })
            .catch((error) => {
                this.handleError(error, true);
            })
            .finally(() => {
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

            this.isRecordReady = true;
        }

        if (response.error) {
            this.handleError(response.error, true);
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
        try {
            this.fields.name = this.extractFieldInfo(fieldInfos[FIELD_NAME.fieldApiName]);
            this.fields.campaign = this.extractFieldInfo(fieldInfos[FIELD_CAMPAIGN.fieldApiName]);
            this.fields.amount = this.extractFieldInfo(fieldInfos[FIELD_AMOUNT.fieldApiName]);
            this.fields.paymentMethod = this.extractFieldInfo(fieldInfos[FIELD_PAYMENT_METHOD.fieldApiName]);
            this.fields.status = this.extractFieldInfo(fieldInfos[FIELD_STATUS.fieldApiName]);
            this.fields.statusreason = this.extractFieldInfo(fieldInfos[FIELD_STATUS_REASON.fieldApiName]);
            this.fields.currency = { label: currencyFieldLabel, apiName: 'CurrencyIsoCode' };
        } catch (error) {
            const permissionsError = {
                header: this.customLabels.flsErrorHeader,
                detail: this.customLabels.flsErrorDetail
            }
            this.handleError(permissionsError, true);
        }

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
            this.isEdit = true;

        } else if (response.error) {
            this.handleError(response.error, true);
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

        const scheduleSection = this.scheduleComponent;
        const scheduleFields = (scheduleSection === null || scheduleSection === undefined)
            ? {}
            : scheduleSection.returnValues();

        const donorSection = this.donorComponent;
        const donorFields = (donorSection === null || donorSection === undefined)
            ? {}
            : donorSection.returnValues();

        const allFields = {
            ...fields, ...scheduleFields, ...donorFields
        };

        let isValid = donorSection.isValid() && scheduleSection.isValid();

        if (isValid) {
            this.template.querySelector('[data-id="outerRecordEditForm"]').submit(allFields);
        } else {
            this.isLoading = false;
            this.hasError = false;
            this.template.querySelector("[data-id='submitButton']").disabled = false;
        }
    }

    /***
    * @description Handle component display when an error occurs
    * @param error: Error Event
    * @param disableSaveButton: true to disable the Save button on the page; defaults to false
    */
    handleError(error, disableSaveButton) {
        this.errorMessage = (!error || (!error.detail && !error.header)) ? constructErrorMessage(error) : error;
        this.hasError = true;

        const disableBtn = !!(disableSaveButton && disableSaveButton === true);
        this.isLoading = disableBtn;

        this.template.querySelector("[data-id='submitButton']").disabled = disableBtn;
        this.template.querySelector(".slds-modal__header").scrollIntoView();
    }

    /***
     * @description Handle component display when a save error occurs
     */
    handleSaveError(error) {
        this.handleError(error, false);
    }

    /**
     * @description Handle a child-to-parent component error event
     * @param event (error construct)
     */
    handleChildComponentError(event) {
        let error = event.detail && event.detail.value ? event.detail.value : event.detail;
        this.handleError(error, true);
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

    /**
    * @description Returns true when all required data for the form is ready
    * @returns {boolean|boolean}
    */
    get isFormReady() {
        return (!this.isLoading && this.fields && this.isSettingReady);
    }

    /**
     * @description Returns the Schedule Child Component instance
     * @returns rd2EntryFormScheduleSection component dom
     */
    get scheduleComponent() {
        return this.template.querySelectorAll('[data-id="scheduleComponent"]')[0];
    }

    /**
     * @description Returns the Donor Child Component instance
     * @returns rd2EntryFormDonorSection component dom
     */
    get donorComponent() {
        return this.template.querySelectorAll('[data-id="donorComponent"]')[0];
    }

}