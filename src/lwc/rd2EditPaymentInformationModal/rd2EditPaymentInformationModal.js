import { LightningElement, api, track } from 'lwc';
import { isNull, showToast, constructErrorMessage, format, isUndefined } from 'c/utilCommon';
import { HTTP_CODES } from 'c/geConstants';
import { updateRecord } from 'lightning/uiRecordApi';
import paymentInformationTitle from '@salesforce/label/c.RD2_PaymentInformation';
import closeButtonLabel from '@salesforce/label/c.commonClose';
import cancelButtonLabel from '@salesforce/label/c.stgBtnCancel';
import saveButtonLabel from '@salesforce/label/c.stgBtnSave';
import spinnerAltText from '@salesforce/label/c.geAssistiveSpinner';
import loadingMessage from '@salesforce/label/c.labelMessageLoading';
import waitMessage from '@salesforce/label/c.commonWaitMessage';
import unknownError from '@salesforce/label/c.commonUnknownError';
import updateSuccessMessage from '@salesforce/label/c.RD2_EntryFormUpdateSuccessMessage';
import validatingCardMessage from '@salesforce/label/c.RD2_EntryFormSaveCreditCardValidationMessage';
import savingCommitmentMessage from '@salesforce/label/c.RD2_EntryFormSaveCommitmentMessage';
import savingRDMessage from '@salesforce/label/c.RD2_EntryFormSaveRecurringDonationMessage';
import FIELD_ID from '@salesforce/schema/npe03__Recurring_Donation__c.Id';
import FIELD_NAME from '@salesforce/schema/npe03__Recurring_Donation__c.Name';
import FIELD_LAST_DONATION_DATE from '@salesforce/schema/npe03__Recurring_Donation__c.npe03__Next_Payment_Date__c';
import FIELD_PAYMENT_METHOD from '@salesforce/schema/npe03__Recurring_Donation__c.PaymentMethod__c';
import FIELD_COMMITMENT_ID from '@salesforce/schema/npe03__Recurring_Donation__c.CommitmentId__c';
import FIELD_CARD_LAST4 from '@salesforce/schema/npe03__Recurring_Donation__c.CardLast4__c';
import FIELD_CARD_EXPIRY_MONTH from '@salesforce/schema/npe03__Recurring_Donation__c.CardExpirationMonth__c';
import FIELD_CARD_EXPIRY_YEAR from '@salesforce/schema/npe03__Recurring_Donation__c.CardExpirationYear__c';

import handleUpdatePaymentCommitment from '@salesforce/apex/RD2_EntryFormController.handleUpdatePaymentCommitment';
import logError from '@salesforce/apex/RD2_EntryFormController.logError';

export default class Rd2EditCreditCardModal extends LightningElement {
    @api rdRecord;

    labels = Object.freeze({
        paymentInformationTitle,
        cancelButtonLabel,
        closeButtonLabel,
        saveButtonLabel,
        spinnerAltText,
        loadingMessage,
        waitMessage,
        unknownError,
        validatingCardMessage,
        savingCommitmentMessage,
        savingRDMessage,
        updateSuccessMessage
    });

    @track isSaving = false;
    @track loadingText = this.labels.loadingMessage;
    @track error = {};
    @track isSaveButtonDisabled = false;

    /**
    * @description Dynamically render the payment edit form via CSS to show/hide based on the status of
    * the callout and saving process
    */
    get paymentEditForm() {
        return (this.isSaving)
            ? 'slds-hide'
            : '';
    }

    get paymentMethod() {
        return this.getValue(FIELD_PAYMENT_METHOD.fieldApiName);
    }

    get nextDonationDate() {
        return this.getValue(FIELD_LAST_DONATION_DATE.fieldApiName);
    }

    get commitmentId() {
        return this.getValue(FIELD_COMMITMENT_ID.fieldApiName);
    }

    get rdName() {
        return this.getValue(FIELD_NAME.fieldApiName);
    }

    /**
    * @description Returns the Recurring Donation field value if the field is set and populated
    */
    getValue(fieldName) {
        return this.hasValue(fieldName)
            ? this.rdRecord.fields[fieldName].value
            : null;
    }

    /**
    * @description Determines if the Recurring Donation record is retrieved and
    * its fields defined and populated
    */
    hasValue(fieldName) {
        return this.rdRecord
            && this.rdRecord.fields
            && !isUndefined(this.rdRecord.fields[fieldName])
            && !isNull(this.rdRecord.fields[fieldName].value);
    }

    /**
    * @description Close the modal 
    */
    handleClose() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    /**
    * @description Process new payment information
    */
    async handleProcessCommitment() {
        this.clearError();
        this.isSaving = true;
        this.isSaveButtonDisabled = true;

        this.loadingText = this.labels.validatingCardMessage;

        try {
            const elevateWidget = this.template.querySelector('[data-id="elevateWidget"]');

            this.paymentMethodToken = await elevateWidget.returnToken().payload;

        } catch (error) {
            this.setSaveButtonDisabled(false);
            return;
        }

        this.loadingText = this.labels.savingCommitmentMessage;

        try {
            handleUpdatePaymentCommitment({
                jsonRecord: JSON.stringify(this.constructRecurringDonation()),
                paymentMethodToken: this.paymentMethodToken
            })
                .then(jsonResponse => {
                    let response = isNull(jsonResponse) ? null : JSON.parse(jsonResponse);
                    let isSuccess = isNull(response)
                        || response.statusCode === HTTP_CODES.Created
                        || response.statusCode === HTTP_CODES.OK;

                    if (isSuccess) {
                        this.loadingText = this.labels.savingRDMessage;
                        this.updateRecurringDonation(this.constructRecurringDonation(response));

                    } else {
                        let message = this.getCommitmentError(response);
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

    /**
    * @description Use updateRecord to update Recurring Donation
    * @param fields all recurringDonation field values 
    */
    updateRecurringDonation(fields) {
        const recordInput = {fields};
        updateRecord(recordInput)
            .then(() => {
                this.handleSuccess();
            })
            .catch(error => {
                this.handleSaveError(error);
                this.handleLogError();
            });
    }

    /**
    * @description Launch a succeed toast message and closed the modal
    */
    handleSuccess() {
        const message = this.labels.updateSuccessMessage.replace("{0}", this.rdName);
        showToast(message, '', 'success');
        this.handleClose();
    }

    /**
    * @description Convert LWC RD record into recognizable form and consume the api response if exist
    */
    constructRecurringDonation(response) {
        let rd = {};
        rd[FIELD_ID.fieldApiName] = this.rdRecord.id;
        rd[FIELD_COMMITMENT_ID.fieldApiName] = this.commitmentId;
        if (!isNull(response) && !isUndefined(response)
            && !isNull(response.body) && !isUndefined(response.body)
        ) {
            const responseBody = JSON.parse(response.body);
            const cardData = responseBody.cardData;

            if (!isNull(cardData) && !isUndefined(cardData)) {
                rd[FIELD_CARD_LAST4.fieldApiName] = cardData.last4;
                rd[FIELD_CARD_EXPIRY_MONTH.fieldApiName] = cardData.expirationMonth;
                rd[FIELD_CARD_EXPIRY_YEAR.fieldApiName] = cardData.expirationYear;
            } 
        }

        return rd;
    }

    /**
    * @description Displays errors extracted from the error response
    * returned from the Elevate API when the Commitment cannot be created
    */
    getCommitmentError(response) {
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

        return format('{0}', [errors]);
    }

    /***
    * @description Handle component display when an error on the save action occurs.
    * Keep Save button enabled so user can correct a value and save again.
    */
    handleSaveError(error) {
        try {
            this.error = constructErrorMessage(error); 
        } catch (error) { }

        this.setSaveButtonDisabled(false);
    }

    /***
    * @description log the error 
    */
    handleLogError() {
        logError({ recordId: this.rdRecord.id, errorMessage: this.error.detail })
            .catch((error) => { });
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
    * @description Clears the error notification
    */
    clearError() {
        this.error = {};
    }

    /***
    * @description Handle component display when an error occurs
    * @param isDisabled: Indicates if the Save button should be disabled
    */
    setSaveButtonDisabled(isDisabled) {
        const disableBtn = !!(isDisabled && isDisabled === true);

        this.isSaving = disableBtn;
        this.isSaveButtonDisabled = disableBtn;
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

    /**
     * @description Close the modal when Escape key is pressed
     */
    handleKeyUp(event) {
        if (event.keyCode === 27 || event.code === 'Escape') {
            this.handleCancel();
        }
    }
}
