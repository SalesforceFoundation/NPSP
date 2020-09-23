import { LightningElement, api, track, wire } from 'lwc';
import CURRENCY from '@salesforce/i18n/currency';
import { fireEvent } from 'c/pubsubNoPageRef';
import { showToast, constructErrorMessage, isNull } from 'c/utilCommon';

import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

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
import customFieldsSectionHeader from '@salesforce/label/c.RD2_EntryFormCustomFieldsSectionHeader';
import insertSuccessMessage from '@salesforce/label/c.RD2_EntryFormInsertSuccessMessage';
import updateSuccessMessage from '@salesforce/label/c.RD2_EntryFormUpdateSuccessMessage';
import flsErrorDetail from '@salesforce/label/c.RD2_EntryFormMissingPermissions';
import flsErrorHeader from '@salesforce/label/c.geErrorFLSHeader';

import getSetting from '@salesforce/apex/RD2_EntryFormController.getRecurringSettings';
import checkRequiredFieldPermissions from '@salesforce/apex/RD2_EntryFormController.checkRequiredFieldPermissions';

import MAILING_COUNTRY_FIELD from '@salesforce/schema/Contact.MailingCountry';

const RECURRING_TYPE_OPEN = 'Open';
const PAYMENT_METHOD_CREDIT_CARD = 'Credit Card';
const ELEVATE_SUPPORTED_COUNTRIES = ['US', 'USA', 'United States', 'United States of America'];
const ELEVATE_SUPPORTED_CURRENCIES = ['USD'];

export default class rd2EntryForm extends LightningElement {

    listenerEvent = 'rd2EntryFormEvent';

    customLabels = Object.freeze({
        cancelButtonLabel,
        saveButtonLabel,
        donorSectionHeader,
        otherSectionHeader,
        scheduleSectionHeader,
        statusSectionHeader,
        customFieldsSectionHeader,
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
    @track customFields = {};
    fieldInfos;

    @track header = newHeaderLabel;

    @track isAutoNamingEnabled;
    @track isLoading = true;
    @track hasCustomFields = false;

    isRecordReady = false;
    isSettingReady = false;

    @track isElevateWidgetDisplayed = false;
    isElevateCustomer = false;
    contactId;
    contact = {
        MailingCountry: null
    };


    @track error = {};

    /***
    * @description Dynamically render the new/edit form via CSS to show/hide based on the status of
    * callouts to retrieve RD settings and other required data.
    */
    get cssEditForm() {
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
                this.isSettingReady = true;
                this.rdSettings = response;
                this.customFields = response.customFieldSets;
                this.hasCustomFields = Object.keys(this.customFields).length !== 0;
                this.isElevateCustomer = response.isElevateCustomer;
            })
            .catch((error) => {
                this.handleError(error);
            })
            .finally(() => {
                this.isLoading = false;
            });

        /*
        * Validate that the User has permissions to all required fields. If not, render a message at the top of the page
        */
        checkRequiredFieldPermissions()
            .then(response => {
                if (response === false) {
                    this.error = {
                        header: this.customLabels.flsErrorHeader,
                        detail: this.customLabels.flsErrorDetail
                    };
                }
            })
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
        this.fields.campaign = this.extractFieldInfo(fieldInfos, FIELD_CAMPAIGN.fieldApiName);
        this.fields.name = this.extractFieldInfo(fieldInfos, FIELD_NAME.fieldApiName);
        this.fields.amount = this.extractFieldInfo(fieldInfos, FIELD_AMOUNT.fieldApiName);
        this.fields.paymentMethod = this.extractFieldInfo(fieldInfos, FIELD_PAYMENT_METHOD.fieldApiName);
        this.fields.status = this.extractFieldInfo(fieldInfos, FIELD_STATUS.fieldApiName);
        this.fields.statusReason = this.extractFieldInfo(fieldInfos, FIELD_STATUS_REASON.fieldApiName);
        this.fields.currency = { label: currencyFieldLabel, apiName: 'CurrencyIsoCode' };
    }

    /***
    * @description Method converts field describe info into a object that is easily accessible from the front end.
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
                dataType: field.dataType
            };
        } catch (error) { }
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

            this.evaluateElevateWidget(getFieldValue(this.record, FIELD_PAYMENT_METHOD));

        } else if (response.error) {
            this.handleError(response.error);
        }
    }

    /**
     * @description Handles contact change only when the org is connected to Elevate
     * and a new Recurring Donation is being created.
     * Otherwise, contact data should not be retrieved from database.
     */
    handleContactChange(event) {
        if (this.isElevateCustomer && !this.isEdit) {
            this.contactId = event.detail && event.detail.value ? event.detail.value : event.detail;
            this.contact.MailingCountry = null;
        }
    }

    /**
     * @description Retrieves the contact data whenever a contact is changed
     * The data is not refreshed when the contact Id is null.
     */
    @wire(getRecord, { recordId: '$contactId', fields: MAILING_COUNTRY_FIELD })
    wiredGetRecord({ error, data }) {
        if (data) {
            this.contact.MailingCountry = data.fields.MailingCountry.value;

            this.handleElevateWidgetDisplay();
            
        } else if (error) {
            this.handleError(error);
        }
    }

    /***
    * @description Checks if form re-rendering is required due to payment method change
    * @param event Contains new payment method value
    */
    handlePaymentChange(event) {
        this.clearError();
        this.evaluateElevateWidget(event.detail.value);
    }

    /***
    * @description Recurring Type change might hide or display the credit card widget
    * @param event
    */
    handleRecurringTypeChange(event) {
        this.handleElevateWidgetDisplay();
    }

    /***
     * @description Currency change might hide or display the credit card widget
     * @param event
     */
    handleCurrencyChange(event) {
        this.handleElevateWidgetDisplay();
    }

    /***
    * @description Checks if the credit card widget should be displayed.
    */
    handleElevateWidgetDisplay() {
        if (this.isElevateCustomer) {
            this.evaluateElevateWidget(this.getPaymentMethod());
        }
    }

    /***
    * @description Checks if the credit card widget should be displayed.
    * The Elevate widget is applicable to new RDs only.
    * @param paymentMethod Payment method
    */
    evaluateElevateWidget(paymentMethod) {
        this.isElevateWidgetDisplayed = this.isElevateCustomer === true
            && !this.isEdit
            && paymentMethod === PAYMENT_METHOD_CREDIT_CARD
            && this.scheduleComponent.getRecurringType() === RECURRING_TYPE_OPEN
            && this.isCurrencySupported()
            && this.isCountrySupported();
    }

    /***
     * @description Returns true if the currency code on the Recurring Donatation 
     * is supported by the Elevate credit card widget
     */
    isCurrencySupported() {
        let currencyCode;

        if (this.isMultiCurrencyEnabled) {
            currencyCode = this.template.querySelector('lightning-input-field[data-id="currencyField"]').value;

        } else {
            currencyCode = CURRENCY;
        }

        return ELEVATE_SUPPORTED_CURRENCIES.includes(currencyCode);
    }

    /***
     * @description Returns true if the Contact.MailingCountry
     * is supported by the Elevate credit card widget
     */
    isCountrySupported() {
        const country = (this.contactId && this.contact && this.contact.MailingCountry)
            ? this.contact.MailingCountry
            : null;

        return isNull(country)
            || ELEVATE_SUPPORTED_COUNTRIES.includes(country);
    }

    /***
    * @description Overrides the standard submit.
    * Collects and validates fields displayed on the form and any integrated LWC
    * and submits them for the record insert or update.
    */
    handleSubmit(event) {
        this.clearError();
        this.isLoading = true;
        this.saveButton.disabled = true;

        const allFields = this.getAllSectionsInputValues();

        if (this.isSectionInputsValid()) {
            this.processSubmit(allFields);

        } else {
            this.isLoading = false;
            this.saveButton.disabled = false;
        }
    }

    /***
    * @description Overrides the standard submit.
    * Collects and validates fields displayed on the form and any integrated LWC
    * and submits them for the record insert or update.
    */
    processSubmit = async (allFields) => {
        if (this.isElevateWidgetDisplayed) {
            try {
                const elevateWidget = this.template.querySelector('[data-id="elevateWidget"]');
                const token = await elevateWidget.returnValues().payload;
            } catch (error) {
                this.handleTokenizeCardError(error);
                return;
            }
        }

        try {
            this.template.querySelector('[data-id="outerRecordEditForm"]').submit(allFields);
        } catch (error) {
            this.handleSaveError(error);
        }
    }

    /***
    * @description Collects fields displayed on the form and any integrated LWC
    */
    getAllSectionsInputValues() {
        const donorFields = (isNull(this.donorComponent))
            ? {}
            : this.donorComponent.returnValues();

        const scheduleFields = (isNull(this.scheduleComponent))
            ? {}
            : this.scheduleComponent.returnValues();

        const extrafields = (isNull(this.customFieldsComponent))
            ? {}
            : this.customFieldsComponent.returnValues();

        return { ...scheduleFields, ...donorFields, ...extrafields, ...this.returnValues() };
    }

    /***
    * @description Validate all fields on the integrated LWC sections 
    */
    isSectionInputsValid() {
        const isDonorSectionValid = (isNull(this.donorComponent))
            ? true
            : this.donorComponent.isValid();

        const isScheduleSectionValid = (isNull(this.scheduleComponent))
            ? true
            : this.scheduleComponent.isValid();

        const isCustomFieldSectionValid = (isNull(this.customFieldsComponent))
            ? true
            : this.customFieldsComponent.isValid();

        const isEntryFormValid = this.isValid();

        return isDonorSectionValid && isScheduleSectionValid && isCustomFieldSectionValid && isEntryFormValid;
    }

    /**
    * @description Clears the error notification
    */
    clearError() {
        this.error = {};
    }

    /***
     * @description Handle component display when an error on the save action occurs.
     * Keep Save button enabled so user can correct a value and save again.
     */
    handleSaveError(error) {
        this.handleError(error, false);
    }

    /***
     * @description Handle error and disable the Save button
     */
    handleError(error) {
        this.handleError(error, true);
    }

    /***
    * @description Handle component display when an error occurs
    * @param error: Error Event
    * @param disableSaveButton: Indicates if the Save button should be disabled
    */
    handleError(error, disableSaveButton) {
        this.error = constructErrorMessage(error);

        this.handlePageOnError(disableSaveButton);
    }

    /***
    * @description Handle component display when an error occurs
    * @param disableSaveButton: Indicates if the Save button should be disabled
    */
    handlePageOnError(disableSaveButton) {
        const disableBtn = !!(disableSaveButton && disableSaveButton === true);
        this.isLoading = disableBtn;

        this.saveButton.disabled = disableBtn;
        this.template.querySelector(".slds-modal__header").scrollIntoView();
    }

    /**
     * @description Handle a child-to-parent component error event
     * @param event (error construct)
     */
    handleChildComponentError(event) {
        let error = event.detail && event.detail.value ? event.detail.value : event.detail;
        this.handleError(error);
    }

    /**
    * Handle component display when an error on the tokenize credit card event
    */
    handleTokenizeCardError(event) {
        //Do not display an error from the tokenize card since
        //it will be displayed in the credit card widget,
        //but stop loading and enable the Save button

        const disableSaveButton = false;
        this.handlePageOnError(disableSaveButton);
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

    /**
     * @description Returns the Custom Field Child Component instance
     * @returns rd2EntryFormCustomFieldsSection component dom
     */
    get customFieldsComponent() {
        return this.template.querySelectorAll('[data-id="customFieldsComponent"]')[0];
    }

    /**
     * @description Returns the save button element
     */
    get saveButton() {
        return this.template.querySelector("[data-id='submitButton']");
    }

    /***
     * @description Returns value of the Payment Method field
     */
    getPaymentMethod() {
        const paymentMethod = this.template.querySelector(`lightning-input-field[data-id='${FIELD_PAYMENT_METHOD.fieldApiName}']`);

        return paymentMethod ? paymentMethod.value : null;
    }

    /**
     * @description Checks if values specified on fields are valid
     * @return Boolean
     */
    isValid() {
        let isValid = true;
        this.template.querySelectorAll('lightning-input-field')
            .forEach(field => {
                if (!field.reportValidity()) {
                    isValid = false;
                }
            });
        return isValid;
    }

    /**
     * @description Returns fields displayed on the parent form
     * @return Object containing field API names and their values
     */
    returnValues() {
        let data = {};

        this.template.querySelectorAll('lightning-input-field')
            .forEach(field => {
                data[field.fieldName] = field.value;
            });

        return data;
    }

}