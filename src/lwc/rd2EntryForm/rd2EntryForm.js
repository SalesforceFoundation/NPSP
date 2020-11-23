import { LightningElement, api, track, wire } from 'lwc';
import CURRENCY from '@salesforce/i18n/currency';
import { registerListener } from 'c/pubsubNoPageRef';
import { isNull, showToast, constructErrorMessage, format } from 'c/utilCommon';
import { HTTP_CODES } from 'c/geConstants';

import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

import RECURRING_DONATION_OBJECT from '@salesforce/schema/npe03__Recurring_Donation__c';

import FIELD_NAME from '@salesforce/schema/npe03__Recurring_Donation__c.Name';
import FIELD_CAMPAIGN from '@salesforce/schema/npe03__Recurring_Donation__c.npe03__Recurring_Donation_Campaign__c';
import FIELD_AMOUNT from '@salesforce/schema/npe03__Recurring_Donation__c.npe03__Amount__c';
import FIELD_PAYMENT_METHOD from '@salesforce/schema/npe03__Recurring_Donation__c.PaymentMethod__c';
import FIELD_STATUS from '@salesforce/schema/npe03__Recurring_Donation__c.Status__c';
import FIELD_STATUS_REASON from '@salesforce/schema/npe03__Recurring_Donation__c.ClosedReason__c';
import FIELD_COMMITMENT_ID from '@salesforce/schema/npe03__Recurring_Donation__c.CommitmentId__c';

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
import elevateWidgetLabel from '@salesforce/label/c.commonPaymentServices';
import spinnerAltText from '@salesforce/label/c.geAssistiveSpinner';
import loadingMessage from '@salesforce/label/c.labelMessageLoading';
import waitMessage from '@salesforce/label/c.commonWaitMessage';
import savingRDMessage from '@salesforce/label/c.RD2_EntryFormSaveRecurringDonationMessage';
import validatingCardMessage from '@salesforce/label/c.RD2_EntryFormSaveCreditCardValidationMessage';
import creatingCommitmentMessage from '@salesforce/label/c.RD2_EntryFormSaveCommitmentMessage';
import commitmentFailedMessage from '@salesforce/label/c.RD2_EntryFormSaveCommitmentFailedMessage';
import contactAdminMessage from '@salesforce/label/c.commonContactSystemAdminMessage';
import unknownError from '@salesforce/label/c.commonUnknownError';

import getSetting from '@salesforce/apex/RD2_EntryFormController.getRecurringSettings';
import hasRequiredFieldPermissions from '@salesforce/apex/RD2_EntryFormController.hasRequiredFieldPermissions';
import getTempCommitmentId from '@salesforce/apex/RD2_EntryFormController.getTempCommitmentId';
import getCommitmentRequestBody from '@salesforce/apex/RD2_EntryFormController.getCommitmentRequestBody';
import createCommitment from '@salesforce/apex/RD2_EntryFormController.createCommitment';

import MAILING_COUNTRY_FIELD from '@salesforce/schema/Contact.MailingCountry';

const RECURRING_TYPE_OPEN = 'Open';
const PAYMENT_METHOD_CREDIT_CARD = 'Credit Card';
const ELEVATE_SUPPORTED_COUNTRIES = ['US', 'USA', 'United States', 'United States of America'];
const ELEVATE_SUPPORTED_CURRENCIES = ['USD'];

/***
* @description Event name fired when the Elevate credit card widget
* is displayed or hidden on the RD2 entry form
*/
const ELEVATE_WIDGET_EVENT_NAME = 'rd2ElevateCreditCardForm';

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
        flsErrorDetail,
        elevateWidgetLabel,
        spinnerAltText,
        loadingMessage,
        waitMessage,
        savingRDMessage,
        validatingCardMessage,
        creatingCommitmentMessage,
        commitmentFailedMessage,
        contactAdminMessage,
        unknownError
    });

    @api parentId;
    @api recordId;

    @track isEdit = false;
    @track record;
    recordName;
    @track isMultiCurrencyEnabled = false;
    @track fields = {};
    @track rdSettings = {};
    @track customFields = {};
    fieldInfos;

    @track header = newHeaderLabel;

    @track isAutoNamingEnabled;
    @track isLoading = true;
    @track loadingText = this.customLabels.loadingMessage;
    @track hasCustomFields = false;
    isRecordReady = false;
    @track isSettingReady = false;
    @track isSaveButtonDisabled = true;

    @track isElevateWidgetEnabled = false;
    hasUserDisabledElevateWidget = false;
    isElevateCustomer = false;
    paymentMethodToken;
    cardholderName;

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
                this.isSaveButtonDisabled = false;
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
        hasRequiredFieldPermissions()
            .then(response => {
                if (response === false) {
                    this.handleError({
                        header: this.customLabels.flsErrorHeader,
                        detail: this.customLabels.flsErrorDetail
                    });
                }
            });

        registerListener(ELEVATE_WIDGET_EVENT_NAME, this.handleElevateWidgetDisplayState, this);
    }

    /**
     * @description Set variable that informs the RD form when the
     *  credit card widget is displayed or hidden by a user
     * @param event
     */
    handleElevateWidgetDisplayState(event) {
        this.hasUserDisabledElevateWidget = event.isDisabled;
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
     * @description Retrieves the contact data whenever a contact is changed.
     * Data is not refreshed when the contact Id is null.
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
        //reset the widget and the form related to the payment method
        this.hasUserDisabledElevateWidget = false;
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
        this.isElevateWidgetEnabled = this.isElevateCustomer === true
            && !this.isEdit
            && paymentMethod === PAYMENT_METHOD_CREDIT_CARD
            && this.scheduleComponent.getRecurringType() === RECURRING_TYPE_OPEN
            && this.isCurrencySupported()
            && this.isCountrySupported();

        this.populateCardHolderName();
    }

    /***
    * @description Returns true if the Elevate widget is enabled and
    * user did not click on the link to hide it
    */
    isElevateWidgetDisplayed() {
        return this.isElevateWidgetEnabled === true
            && this.hasUserDisabledElevateWidget !== true;
    }

    /***
    * @description Prepopulates the card holder name field on the Elevate credit card widget
    */
    populateCardHolderName() {
        if (!this.isElevateWidgetDisplayed()) {
            return;
        }

        // TO-DO: Prepopulate the Cardholder Name with the currently selected Contact or Organization Name
        // when the component first registers, and ideally if the Contact or Org is changed.

        // const creditCardForm = this.creditCardComponent;
        // creditCardForm.setCardholderName('Test Name');

        // const contactId = event.detail.fields.npe03__Contact__c.value;
        // const accountId = event.detail.fields.npe03__Organization__c.value;
        // getCardholderNamesForElevate({ contactId: contactId, accountId: accountId })
        //     .then(response => {
        //         this.cardholderName = response;
        //     });
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
        this.loadingText = this.customLabels.waitMessage;
        this.isSaveButtonDisabled = true;

        const allFields = this.getAllSectionsInputValues();

        if (this.isSectionInputsValid()) {
            this.processSubmit(allFields);

        } else {
            this.isLoading = false;
            this.isSaveButtonDisabled = false;
        }
    }

    /***
    * @description Overrides the standard submit.
    * Collects and validates fields displayed on the form and any integrated LWC
    * and submits them for the record insert or update.
    */
    processSubmit = async (allFields) => {
        if (this.isElevateWidgetDisplayed()) {
            try {
                this.loadingText = this.customLabels.validatingCardMessage;
                const elevateWidget = this.template.querySelector('[data-id="elevateWidget"]');
                this.paymentMethodToken = await elevateWidget.returnToken().payload;

                if (!this.isEdit) {
                    const tempId = await getTempCommitmentId();
                    allFields[FIELD_COMMITMENT_ID.fieldApiName] = tempId;
                }

            } catch (error) {
                this.setSaveButtonDisabled(false);
                return;
            }
        }

        try {
            this.loadingText = this.customLabels.savingRDMessage;
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
        this.error = constructErrorMessage(error);
        this.setSaveButtonDisabled(false);
    }

    /***
     * @description Handle error and disable the Save button
     */
    handleError(error) {
        this.error = (error && error.detail)
            ? error
            : constructErrorMessage(error);

        this.setSaveButtonDisabled(true);
    }

    /***
    * @description Handle component display when an error occurs
    * @param isDisabled: Indicates if the Save button should be disabled
    */
    setSaveButtonDisabled(isDisabled) {
        const disableBtn = !!(isDisabled && isDisabled === true);

        this.isLoading = disableBtn;
        this.isSaveButtonDisabled = disableBtn;
        
        
    }
    /**
    * @description Scroll to error if the error is rendered 
    */
    renderedCallback() {
        if (this.error.detail && this.isLoading === false) {
            this.template.querySelector(".error-container").scrollIntoView(true);
        }
    }

    /**
     * @description Handle a child-to-parent component error event
     * @param event (error construct)
     */
    handleChildComponentError(event) {
        let error = event.detail && event.detail.value ? event.detail.value : event.detail;
        this.handleError(error);
    }

    /***
    * @description Fires an event to utilDedicatedListener with the cancel action
    */
    handleCancel() {
        this.closeModal(this.recordId);
    }

    /***
    * @description Fires an event to utilDedicatedListener with the success action
    */
    handleSuccess(event) {
        this.recordName = event.detail.fields.Name.value;
        const recordId = event.detail.id;

        if (this.isElevateWidgetDisplayed()) {
            this.handleElevateCommitment(recordId);

        } else {
            this.showToastSuccess();
            this.closeModal(recordId);
        }
    }

    /**
     * @description Sends Commitment request to the Elevate API and
     * updates the Recurring Donation Commitment Id on the successfull creation
     * If an error occurs when the Commitment is created,
     * it should be displayed, and the modal closed since
     * the another creation of the same Recurring Donation should be prevented.
     */
    handleElevateCommitment(recordId) {
        this.loadingText = this.customLabels.creatingCommitmentMessage;

        getCommitmentRequestBody({
            recordId: recordId,
            paymentMethodToken: this.paymentMethodToken
        })
            .then(jsonRequestBody => {
                createCommitment({ recordId: recordId, jsonRequestBody: jsonRequestBody })
                    .then(jsonResponse => {
                        this.processCommitmentResponse(jsonResponse);
                    })
                    .catch((error) => {
                        this.displayCommitmentError(error);
                    })
                    .finally(() => {
                        this.closeModal(recordId);
                    });
            })
            .catch(error => {
                this.displayCommitmentError(error);
                this.closeModal(recordId);
            });
    }

    /**
     * @description Verifies if the Commitment was successfully created,
     * and displays the error if the error response has been returned.
     */
    processCommitmentResponse(jsonResponse) {
        let response = JSON.parse(jsonResponse);

        if (response.statusCode === HTTP_CODES.Created) {
            this.showToastSuccess();

        } else {
            this.displayCommitmentErrorResponse(response);
        }
    }

    /**
     * @description Displayes errors extracted from the error response
     * returned from the Elevate API when the Commitment cannot be created
     */
    displayCommitmentErrorResponse(response) {
        if (response.body) {
            // Errors returned in the response body can contain a single quote, for example:
            // "body": "{'errors':[{'message':'\"Unauthorized\"'}]}".
            // However, the JSON parser does not work with a single quote,
            // so need to replace it with the double quote but after
            // replacing \" with an empty string, otherwise the message content
            // will be misformatted.
            if (JSON.stringify(response.body).includes("'errors'")) {
                response.body = response.body.replace(/\"/g, '').replace(/\'/g, '"');
            }

            //parse the error response
            try {
                response.body = JSON.parse(response.body);
            } catch (error) { }
        }

        let errors = this.getErrors(response);
        this.showToastCommitmentError(errors);
    }

    /***
    * @description Get the message or errors from a failed API call.
    * @param {object} response: Http response object
    * @return {string}: Message from a failed API call response
    */
    getErrors(response) {
        if (response.body && response.body.errors) {
            return response.body.errors.map(error => error.message).join('\n ');
        }

        // For some reason the key in the body object for 'Message'
        // in the response we receive from Elevate is capitalized.
        // Also checking for lowercase M in message in case they fix it.
        return response.body.Message
            || response.body.message
            || response.errorMessage
            || JSON.stringify(response.body);
    }

    /**
     * @description Processes unexpected error from the commitment response
     */
    displayCommitmentError(errorException) {
        let error = constructErrorMessage(errorException);

        let message;
        if (error) {
            if (error.body && error.body.message) {
                message = error.body.message;
            } else if (error.message) {
                message = error.message;
            } else if (error.detail) {
                message = error.detail;
            }
        }
        if (isNull(message)) {
            message = JSON.stringify(error);
        }

        this.showToastCommitmentError(message);
    }

    /**
     * @description Displays errors generated during commitment callout
     */
    showToastCommitmentError(errors) {
        const title = this.customLabels.elevateWidgetLabel;

        // The space is required before the param {0},
        // otherwise the errors are duplicated when the message is formatted.
        // Moreover, the '\n {0}' cannot be part of the commitment failed message
        // since the new line is not replaced with a return.
        const message = this.getRecurringDonationSuccessMessage()
            + '\n' + this.customLabels.commitmentFailedMessage
            + '\n {0}'
            + '\n' + this.customLabels.contactAdminMessage;

        let replacements = [errors];
        let formattedMessage = format(message, replacements);

        showToast(title, formattedMessage, 'error', 'sticky');
    }

    /**
     * @description Displays toast message on successful save
     */
    showToastSuccess() {
        showToast(this.getRecurringDonationSuccessMessage(), '', 'success');
    }

    /**
     * @description Message displayed when the Recurring Donation is created or updated successfully
     */
    getRecurringDonationSuccessMessage() {
        return (this.isEdit)
            ? updateSuccessMessage.replace("{0}", this.recordName)
            : insertSuccessMessage.replace("{0}", this.recordName);
    }

    /**
     * @description Dispatches an event to close the Recurring Donation entry form modal
     */
    closeModal(recordId) {
        this.resetAllValues();

        const closeModalEvent = new CustomEvent('closemodal', {
            detail :{recordId: recordId},
        });
        this.dispatchEvent(closeModalEvent);
    }

    /**
    * @description Reset all input values when entry form modal is closed, Reset all values in LWC
    *   because New override button will not refresh in the same lightning session
    */
    resetAllValues() {
        this.recordId = null;
        this.isLoading = false;
        this.isSaveButtonDisabled = false;
        this.isElevateWidgetEnabled = false;
        this.error = {}

        const inputFields = this.template.querySelectorAll('lightning-input-field');
        inputFields.forEach(field => {
            if (field.value) {
                field.clean();
            }
        });

        if (!isNull(this.donorComponent)) {
            this.donorComponent.resetValues();
            this.donorComponent.forceRefresh();
        }
        if (!isNull(this.scheduleComponent)) {
            this.scheduleComponent.resetValues();
            this.scheduleComponent.forceRefresh();
        }
        if (!isNull(this.customFieldsComponent)) {
            this.customFieldsComponent.resetValues();
        }
    }

    /**
     * @description Returns the Schedule Child Component instance
     * @return rd2EntryFormScheduleSection component dom
     */
    get scheduleComponent() {
        return this.template.querySelectorAll('[data-id="scheduleComponent"]')[0];
    }

    /**
     * @description Returns the Donor Child Component instance
     * @return rd2EntryFormDonorSection component dom
     */
    get donorComponent() {
        return this.template.querySelectorAll('[data-id="donorComponent"]')[0];
    }

    /**
     * @description Returns the Custom Field Child Component instance
     * @return rd2EntryFormCustomFieldsSection component dom
     */
    get customFieldsComponent() {
        return this.template.querySelectorAll('[data-id="customFieldsComponent"]')[0];
    }

    /**
     * @description Returns the Credit Card Child Component instance
     * @returns rd2ElevateCreditCardForm component dom
     */
    get creditCardComponent() {
        return this.template.querySelector('[data-id="elevateWidget"]');
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

    /**
     * @description Close the modal when Escape key is pressed
     */
    handleKeyUp(event) {
        if (event.keyCode === 27 || event.code === 'Escape') {
            this.handleCancel();
        }
    }

    /**
     * @description Trap focus onto the modal when the focus reaches the top
     */
    handleClosedButtonTrapFocus(event) {
        if (event.shiftKey && event.code === 'Tab') {
            event.stopPropagation();
            this.template.querySelector('[data-id="submitButton"]').focus();
        }
    }

    /**
     * @description Trap focus onto the modal when the focus reaches the end
     */
    handleSaveButtonTrapFocus(event) {
        if (event.code === 'Tab') {
            event.stopPropagation();
            this.template.querySelector('[data-id="closeButton"]').focus();
        }
    }
}