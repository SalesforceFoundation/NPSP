import { LightningElement, api, track, wire } from 'lwc';
import CURRENCY from '@salesforce/i18n/currency';
import { registerListener } from 'c/pubsubNoPageRef';
import { Rd2Service } from 'c/rd2Service';
import { isNull, showToast, constructErrorMessage, format, extractFieldInfo, buildFieldDescribes, isEmpty } from 'c/utilCommon';
import { HTTP_CODES, PAYMENT_METHOD_ACH, PAYMENT_METHOD_CREDIT_CARD } from 'c/geConstants';

import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

import RECURRING_DONATION_OBJECT from '@salesforce/schema/npe03__Recurring_Donation__c';

import FIELD_NAME from '@salesforce/schema/npe03__Recurring_Donation__c.Name';
import FIELD_CAMPAIGN from '@salesforce/schema/npe03__Recurring_Donation__c.npe03__Recurring_Donation_Campaign__c';
import FIELD_AMOUNT from '@salesforce/schema/npe03__Recurring_Donation__c.npe03__Amount__c';
import FIELD_PAYMENT_METHOD from '@salesforce/schema/npe03__Recurring_Donation__c.PaymentMethod__c';
import FIELD_RECURRING_TYPE from '@salesforce/schema/npe03__Recurring_Donation__c.RecurringType__c';
import FIELD_STATUS from '@salesforce/schema/npe03__Recurring_Donation__c.Status__c';
import FIELD_STATUS_REASON from '@salesforce/schema/npe03__Recurring_Donation__c.ClosedReason__c';
import FIELD_COMMITMENT_ID from '@salesforce/schema/npe03__Recurring_Donation__c.CommitmentId__c';
import FIELD_ACH_LAST4 from '@salesforce/schema/npe03__Recurring_Donation__c.ACH_Last_4__c';
import FIELD_CARD_LAST4 from '@salesforce/schema/npe03__Recurring_Donation__c.CardLast4__c';
import FIELD_CARD_EXPIRY_MONTH from '@salesforce/schema/npe03__Recurring_Donation__c.CardExpirationMonth__c';
import FIELD_CARD_EXPIRY_YEAR from '@salesforce/schema/npe03__Recurring_Donation__c.CardExpirationYear__c';
import FIELD_INSTALLMENT_FREQUENCY from '@salesforce/schema/npe03__Recurring_Donation__c.InstallmentFrequency__c';
import FIELD_INSTALLMENT_PERIOD from '@salesforce/schema/npe03__Recurring_Donation__c.npe03__Installment_Period__c';
import FIELD_NEXT_DONATION_DATE from '@salesforce/schema/npe03__Recurring_Donation__c.npe03__Next_Payment_Date__c';
import FIELD_CONTACT_ID from '@salesforce/schema/npe03__Recurring_Donation__c.npe03__Contact__c';
import FIELD_ORGANIZATION_ID from '@salesforce/schema/npe03__Recurring_Donation__c.npe03__Organization__c';

import currencyFieldLabel from '@salesforce/label/c.lblCurrency';
import cancelButtonLabel from '@salesforce/label/c.stgBtnCancel';
import closeButtonLabel from '@salesforce/label/c.commonClose';
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
import savingCommitmentMessage from '@salesforce/label/c.RD2_EntryFormSaveCommitmentMessage';
import commitmentFailedMessage from '@salesforce/label/c.RD2_EntryFormSaveCommitmentFailedMessage';
import contactAdminMessage from '@salesforce/label/c.commonContactSystemAdminMessage';
import unknownError from '@salesforce/label/c.commonUnknownError';

import getRecurringSettings from '@salesforce/apex/RD2_EntryFormController.getRecurringSettings';
import hasRequiredFieldPermissions from '@salesforce/apex/RD2_EntryFormController.hasRequiredFieldPermissions';
import handleCommitment from '@salesforce/apex/RD2_EntryFormController.handleCommitment';
import logError from '@salesforce/apex/RD2_EntryFormController.logError';

import MAILING_COUNTRY_FIELD from '@salesforce/schema/Contact.MailingCountry';
import CONTACT_FIRST_NAME from '@salesforce/schema/Contact.FirstName';
import CONTACT_LAST_NAME from '@salesforce/schema/Contact.LastName';
import ACCOUNT_NAME from '@salesforce/schema/Account.Name';
import ACCOUNT_PRIMARY_CONTACT_LAST_NAME from '@salesforce/schema/Account.npe01__One2OneContact__r.LastName';


const STATUS_CLOSED = 'Closed';
const RECURRING_TYPE_OPEN = 'Open';
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
        closeButtonLabel,
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
        savingCommitmentMessage,
        commitmentFailedMessage,
        contactAdminMessage,
        unknownError
    });

    @api parentId;
    @api recordId;

    @track isEdit = false;
    @track isCommitmentEdit = false;
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
    @track isElevateEditWidgetEnabled = false;
    hasUserDisabledElevateWidget = false;
    isElevateCustomer = false;
    commitmentId = null;
    paymentMethodToken;
    _paymentMethod;

    contactId;
    organizationAccountId;
    organizationAccountName;
    accountHolderType;

    contact = {
        MailingCountry: null
    };

    rd2Service = new Rd2Service();

    @track error = {};

    /***
    * @description Get the next donation date for this recurring donation
    */
    @api 
    get nextDonationDate() {
        const localDate = new Date(this._nextDonationDate);
        return new Date(localDate.getUTCFullYear(), localDate.getUTCMonth(), localDate.getUTCDate());
    }

    /***
    * @description Get the Credit Card expiration date, formated as MM/YYYY
    */
    @api 
    get cardExpDate(){
        const cardExpMonth = getFieldValue(this.record, FIELD_CARD_EXPIRY_MONTH);
        const cardExpYear = getFieldValue(this.record, FIELD_CARD_EXPIRY_YEAR);
        return (cardExpMonth && cardExpYear) ? cardExpMonth + '/' + cardExpYear : '';
    }

    /***
    * @description Get the Label for the Card Last 4 field
    */
    get cardLastFourLabel() {
        return (this.fields.cardLastFour) ? this.fields.cardLastFour.label : '';
    }

    /***
     * @description Get the Label for the Card Last 4 field
     */
    get achLastFourLabel() {
        return (this.fields.achLastFour) ? this.fields.achLastFour.label : '';
    }

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
        getRecurringSettings({ parentId: this.parentId })
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
                this.evaluateElevateEditWidget();
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
        if(this.shouldResetPaymentMethodOnStateChange(event)) {
            this.resetPaymentMethod();
        }
        this.hasUserDisabledElevateWidget = event.isDisabled;
    }

    shouldResetPaymentMethodOnStateChange(event) {
        return event.isDisabled
            && this.isEdit
            && this._paymentMethod !== this.existingPaymentMethod
            && this.isCommitmentEdit;
    }

    /***
    * @description Retrieve Recurring Donation Object info
    */
    @wire(getObjectInfo, { objectApiName: RECURRING_DONATION_OBJECT.objectApiName })
    wiredRecurringDonationObjectInfo(response) {
        if (response.data) {
            let rdObjectInfo = response.data;
            this.setFields(rdObjectInfo.fields);
            this.fieldInfos = buildFieldDescribes(
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
    * @description Construct field describe info from the Recurring Donation SObject info
    */
    setFields(fieldInfos) {
        this.fields.campaign = extractFieldInfo(fieldInfos, FIELD_CAMPAIGN.fieldApiName);
        this.fields.name = extractFieldInfo(fieldInfos, FIELD_NAME.fieldApiName);
        this.fields.amount = extractFieldInfo(fieldInfos, FIELD_AMOUNT.fieldApiName);
        this.fields.paymentMethod = extractFieldInfo(fieldInfos, FIELD_PAYMENT_METHOD.fieldApiName);
        this.fields.status = extractFieldInfo(fieldInfos, FIELD_STATUS.fieldApiName);
        this.fields.statusReason = extractFieldInfo(fieldInfos, FIELD_STATUS_REASON.fieldApiName);
        this.fields.cardLastFour = extractFieldInfo(fieldInfos, FIELD_CARD_LAST4.fieldApiName);
        this.fields.currency = { label: currencyFieldLabel, apiName: 'CurrencyIsoCode' };
        this.fields.achLastFour = extractFieldInfo(fieldInfos, FIELD_ACH_LAST4.fieldApiName);
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
            this._paymentMethod = getFieldValue(this.record, FIELD_PAYMENT_METHOD);
            this.existingPaymentMethod = getFieldValue(this.record, FIELD_PAYMENT_METHOD);
            this.contactId = getFieldValue(this.record, FIELD_CONTACT_ID);
            this.organizationAccountId = getFieldValue(this.record, FIELD_ORGANIZATION_ID);
            this.commitmentId = getFieldValue(this.record, FIELD_COMMITMENT_ID);
            this.isCommitmentEdit = !isNull(this.commitmentId);
            this._nextDonationDate = getFieldValue(this.record, FIELD_NEXT_DONATION_DATE);
            this.cardLastFour = getFieldValue(this.record, FIELD_CARD_LAST4);
            this.achLastFour = getFieldValue(this.record, FIELD_ACH_LAST4);

            this.evaluateElevateEditWidget();
            this.evaluateElevateWidget();

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

    handleAccountChange(event) {
        this.organizationAccountId = event.detail;
    }

    handleDonorTypeChange(event) {
        this.accountHolderType = this.rd2Service.accountHolderTypeFor(event.detail);
    }

    /**
     * @description Retrieves the contact data whenever a contact is changed.
     * Data is not refreshed when the contact Id is null.
     */
    @wire(getRecord, {
        recordId: '$contactId', fields: [
            MAILING_COUNTRY_FIELD,
            CONTACT_LAST_NAME,
            CONTACT_FIRST_NAME
        ]
    })
    wiredGetRecord({error, data}) {
        if (data) {
            this.contact.MailingCountry = getFieldValue(data, MAILING_COUNTRY_FIELD);
            this.contactLastName = getFieldValue(data, CONTACT_LAST_NAME);
            this.contactFirstName = getFieldValue(data, CONTACT_FIRST_NAME);

            this.handleElevateWidgetDisplay();

        } else if (error) {
            this.handleError(error);
        }
    }

    @wire(getRecord, {
        recordId: '$organizationAccountId', fields: [ACCOUNT_NAME, ACCOUNT_PRIMARY_CONTACT_LAST_NAME]
    })
    wiredGetDonorAccount({error, data}) {
        if(data) {
            this.organizationAccountName = getFieldValue(data, ACCOUNT_NAME);
            this.contactLastName = getFieldValue(data, ACCOUNT_PRIMARY_CONTACT_LAST_NAME);
        } else if(error) {
            this.handleError(error);
        }
    }

    /***
    * @description Checks if form re-rendering is required due to payment method change
    * @param event Contains new payment method value
    */
    handlePaymentChange(event) {
        //reset the widget and the form related to the payment method
        this.hasUserDisabledElevateWidget = this.isCommitmentEdit;
        this._paymentMethod = event.detail.value;
        this.isElevateEditWidgetEnabled = false;
        this.evaluateElevateWidget();
    }

    /***
    * @description Handle schedule form fields:
    * - Recurring Type change might hide or display the credit card widget.
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
            this.evaluateElevateWidget();
        }
    }

    /***
    * @description Checks if the Elevate Widget should be displayed on Edit
    */
    evaluateElevateEditWidget() {
        const statusField = getFieldValue(this.record, FIELD_STATUS);

        if (this.isElevateCustomer && this.isEdit && statusField !== STATUS_CLOSED) {
            // On load, we can't rely on the schedule component, but we should when detecting changes
            let recurringType = getFieldValue(this.record, FIELD_RECURRING_TYPE);
            if(this.scheduleComponent && this.scheduleComponent.getRecurringType()) {
                recurringType = this.scheduleComponent.getRecurringType();
            }

            // Since the widget requires interaction to Edit, this should start as true
            this.hasUserDisabledElevateWidget = this.isCommitmentEdit;

            this.isElevateEditWidgetEnabled = this.isElevatePaymentMethod()
                && recurringType === RECURRING_TYPE_OPEN
                && this.isCurrencySupported()
                && this.isCountrySupported();

            this.isElevateWidgetEnabled = this.isElevateEditWidgetEnabled;
        }
    }

    /***
    * @description Checks if the Elevate widget should be displayed.
    * The Elevate widget is applicable to new RDs only for now.
    * @param paymentMethod Payment method
    */
    evaluateElevateWidget() {
        const isOpenSchedule = (this.scheduleComponent && this.scheduleComponent.getRecurringType() === RECURRING_TYPE_OPEN);
        const isValidPaymentMethod = this.isElevatePaymentMethod();
        const currencySupported = this.isCurrencySupported();
        const countrySupported = this.isCountrySupported();
        this.isElevateWidgetEnabled = this.isElevateEditWidgetEnabled
            || (this.isElevateCustomer === true
            && isValidPaymentMethod
            && isOpenSchedule
            && currencySupported
            && countrySupported);

        this.populateCardHolderName();
    }

    isElevatePaymentMethod() {
        return this._paymentMethod === PAYMENT_METHOD_CREDIT_CARD || this._paymentMethod === PAYMENT_METHOD_ACH;
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
    * @description Returns true if Schedule fields has updated
    */
    hasElevateFieldsChange(allFields) {
        const amount = getFieldValue(this.record, FIELD_AMOUNT);
        const frequency = getFieldValue(this.record, FIELD_INSTALLMENT_FREQUENCY);
        const period = getFieldValue(this.record, FIELD_INSTALLMENT_PERIOD);
        const campaignId = getFieldValue(this.record, FIELD_CAMPAIGN);


        const hasFrequencyField = allFields.hasOwnProperty(FIELD_INSTALLMENT_FREQUENCY.fieldApiName);
        const amountChanged = amount !== Number(allFields[FIELD_AMOUNT.fieldApiName]);
        const frequencyChanged = hasFrequencyField && (frequency !== Number(allFields[FIELD_INSTALLMENT_FREQUENCY.fieldApiName]));
        const installmentPeriodChanged = period !== allFields[FIELD_INSTALLMENT_PERIOD.fieldApiName];
        const campaignChanged = campaignId !== allFields[FIELD_CAMPAIGN.fieldApiName];

        return amountChanged
            || frequencyChanged
            || installmentPeriodChanged
            || campaignChanged;
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

        if (this.isFormValid()) {
            const allFields = this.getAllFields();
            if (this.shouldSendToElevate(allFields)) {
                this.processCommitmentSubmit(allFields);

            } else {
                this.processSubmit(allFields);
            }

        } else {
            this.isLoading = false;
            this.isSaveButtonDisabled = false;
        }
    }


    /***
    * @description Overrides the standard submit when an
    * Elevate recurring commitment record is to be created or updated.
    */
    async processCommitmentSubmit(allFields) {
        try {
            if (this.isElevateWidgetDisplayed()) {
                this.loadingText = this.rd2Service.getPaymentProcessingMessage(this.paymentMethod);

                const elevateWidget = this.template.querySelector('[data-id="elevateWidget"]');

                this.paymentMethodToken = await elevateWidget.returnToken().payload;
            }

        } catch (error) {
            this.setSaveButtonDisabled(false);
            return;
        }

        this.loadingText = this.customLabels.savingCommitmentMessage;

        try {
            const rd = this.rd2Service.constructRecurringDonation(this.recordId, this.commitmentId)
                .withInputFieldValues(allFields);

            handleCommitment({
                jsonRecord: rd.asJSON(),
                paymentMethodToken: this.paymentMethodToken
            })
                .then(jsonResponse => {
                    const response = isNull(jsonResponse) ? null : JSON.parse(jsonResponse);
                    const isSuccess = isNull(response)
                        || response.statusCode === HTTP_CODES.Created
                        || response.statusCode === HTTP_CODES.OK;
                    const responseBody = JSON.parse(response.body);

                    if (isSuccess) {
                        rd.withCommitmentResponseBody(responseBody);
                        this.processSubmit(rd.record);
                    } else {
                        const message = this.rd2Service.getCommitmentError(response);
                        this.handleSaveError(message);
                    }
                })
                .catch((error) => {
                    this.handleSaveError(error);
                });

        } catch (error) {
            this.handleSaveError(error);
        }
    }

    /***
    * @description Determines if new or existing Recurring Donation is an Elevate recurring commitment
    */
    shouldSendToElevate(allFields) {
        if (!this.isElevateCustomer) {
            return false;
        }

        return this.isElevateWidgetDisplayed()
            || (this.hasElevateFieldsChange(allFields) && !isEmpty(this.getCommitmentId()));
    }

    /***
    * @description Returns commitment Id that can be retrieved from database, or
    * set by the user in the custom fields section
    */
    getCommitmentId() {
        return !isEmpty(this.commitmentId)
            ? this.commitmentId
            : null;
    }

    /***
    * @description Overrides the standard submit.
    * Collects and validates fields displayed on the form and any integrated LWC
    * and submits them for the record insert or update.
    */
    processSubmit(rdRecord) {
        try {
            this.loadingText = this.customLabels.savingRDMessage;
            this.template.querySelector('[data-id="outerRecordEditForm"]').submit(rdRecord);

        } catch (error) {
            this.handleSaveError(error);
        }
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
        try {
            this.error = constructErrorMessage(error);
            // Transform the error to a user-friendly error and log it when
            // the RD insert failed but the Elevate commitment has been created
            if (isNull(this.recordId) && !isEmpty(this.getCommitmentId())) {

                this.error.detail = format(
                    this.customLabels.commitmentFailedMessage,
                    [this.getCommitmentId(), this.error.detail]
                );

                logError({ recordId: this.recordId, errorMessage: this.error.detail })
                    .catch((error) => { });
            }
        } catch (error) { }

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
        if (this.error && this.error.detail && this.isLoading === false) {
            this.template.querySelector(".error-container").scrollIntoView(true);
        }
    }

    /**
     * @description Handle a child-to-parent component error event
     * @param event (error construct)
     */
    handleChildComponentError(event) {
        const error = event.detail && event.detail.value ? event.detail.value : event.detail;
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

        const message = this.isEdit
            ? updateSuccessMessage.replace("{0}", this.recordName)
            : insertSuccessMessage.replace("{0}", this.recordName);

        showToast(message, '', 'success');

        this.closeModal(recordId);
    }

    /**
     * @description Dispatches an event to close the Recurring Donation entry form modal
     */
    closeModal(recordId) {
        this.resetAllValues();

        const closeModalEvent = new CustomEvent('closemodal', {
            detail: { recordId: recordId },
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
        this.clearError();

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

    resetPaymentMethod() {
        const field = this.template.querySelector('lightning-input-field[data-id="paymentMethod"]');
        field.reset();
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
    get paymentMethod() {
        return this._paymentMethod;
    }

    /***
    * @description Collects fields displayed on the form and any integrated LWC
    */
    getAllFields() {
        const donorFields = (isNull(this.donorComponent))
            ? {}
            : this.donorComponent.returnValues();

        const scheduleFields = (isNull(this.scheduleComponent))
            ? {}
            : this.scheduleComponent.returnValues();

        const customFields = (isNull(this.customFieldsComponent))
            ? {}
            : this.customFieldsComponent.returnValues();

        const paymentMethod = {
            [FIELD_PAYMENT_METHOD.fieldApiName]: this.paymentMethod
        }

        return { ...scheduleFields, ...donorFields, ...customFields, ...paymentMethod, ...this.returnValues() };
    }

    /***
    * @description Validate all fields on the integrated LWC sections
    */
    isFormValid() {
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
     * @description Close the modal when Escsape key is pressed
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