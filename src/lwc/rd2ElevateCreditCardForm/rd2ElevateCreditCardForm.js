import { api, track, wire, LightningElement } from 'lwc';
import { constructErrorMessage, extractFieldInfo } from 'c/utilCommon';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

import tokenHandler from 'c/psElevateTokenHandler';
import getOrgDomainInfo from '@salesforce/apex/UTIL_AuraEnabledCommon.getOrgDomainInfo';

import RECURRING_DONATION_OBJECT from '@salesforce/schema/npe03__Recurring_Donation__c';
import FIELD_CARD_LAST4 from '@salesforce/schema/npe03__Recurring_Donation__c.CardLast4__c';
import FIELD_CARD_EXPIRY_MONTH from '@salesforce/schema/npe03__Recurring_Donation__c.CardExpirationMonth__c';
import FIELD_CARD_EXPIRY_YEAR from '@salesforce/schema/npe03__Recurring_Donation__c.CardExpirationYear__c';

import elevateWidgetLabel from '@salesforce/label/c.commonPaymentServices';
import spinnerAltText from '@salesforce/label/c.geAssistiveSpinner';
import elevateDisableButtonLabel from '@salesforce/label/c.RD2_ElevateDisableButtonLabel';
import elevateDisabledMessage from '@salesforce/label/c.RD2_ElevateDisabledMessage';
import elevateEnableButtonLabel from '@salesforce/label/c.RD2_ElevateEnableButtonLabel';
import updatePaymentButtonLabel from '@salesforce/label/c.RD2_ElevateUpdatePaymentButtonLabel';
import cardholderNameLabel from '@salesforce/label/c.commonCardholderName';
import cardExpirationDate from '@salesforce/label/c.commonMMYY';
import cancelLabel from '@salesforce/label/c.commonCancel';



/***
* @description Event name fired when the Elevate credit card widget is displayed or hidden
* on the RD2 entry form
*/
const WIDGET_EVENT_NAME = 'rd2ElevateCreditCardForm';

const FIELDS = [
    FIELD_CARD_LAST4,
    FIELD_CARD_EXPIRY_MONTH,
    FIELD_CARD_EXPIRY_YEAR
];

/***
* @description Payment services Elevate credit card widget on the Recurring Donation entry form
*/
export default class rd2ElevateCreditCardForm extends LightningElement {

    labels = {
        elevateWidgetLabel,
        spinnerAltText,
        elevateDisableButtonLabel,
        elevateDisabledMessage,
        elevateEnableButtonLabel,
        updatePaymentButtonLabel,
        cardholderNameLabel,
        cardExpirationDate,
        cancelLabel
    };

    @api recordId;
    @api isEdit;
    @track isLoading = true;
    @track isDisabled = false;
    @track alert = {};
    @track fields = {};
    @track record;

    /***
    * @description Get the organization domain information such as domain and the pod name
    * in order to determine the Visualforce origin URL so that origin source can be verified.
    */
    async connectedCallback() {
        const domainInfo = await getOrgDomainInfo()
            .catch(error => {
                this.handleError(error);
            });

        tokenHandler.setVisualforceOriginURLs(domainInfo);

        this.isDisabled = this.isEdit;
    }

    /***
    * @description Listens for a message from the Visualforce iframe.
    */
    renderedCallback() {
        let component = this;
        tokenHandler.registerPostMessageListener(component);
    }

    /***
    * @description Retrieves Recurring Donation Object and fields labels/help text
    */
    @wire(getObjectInfo, { objectApiName: RECURRING_DONATION_OBJECT.objectApiName })
    wiredRecurringDonationObjectInfo(response) {
        if (response.data) {
            this.setFields(response.data.fields);
        }

        if (response.error) {
            this.handleError(response.error);
        }
    }

    /***
     * @description Tracks specified fields so when the Recurring Donation record is updated,
     * this method is called to force refresh of the data and the component.
     */
    @wire(getRecord, {
        recordId: '$recordId',
        fields: FIELDS
    })
    wiredRecurringDonation(response) {
        if (response.data) {
            this.record = response.data;
        }

        if (response.error) {
            this.handleError(response.error);
        }
    }

    /**
     * @description Construct field describe info from the Recurring Donation SObject info
     */
    setFields(rdObjectInfo) {
        this.fields.cardLast4 = extractFieldInfo(rdObjectInfo, FIELD_CARD_LAST4.fieldApiName);
    }

    get cardLast4() {
        return getFieldValue(this.record, FIELD_CARD_LAST4);
    }

    get cardExpirationDate() {
        return getFieldValue(this.record, FIELD_CARD_EXPIRY_MONTH) + "/" + getFieldValue(this.record, FIELD_CARD_EXPIRY_YEAR);
    }

    get disableInputLabel() {
        return this.isEdit
            ? this.labels.cancelLabel
            : this.labels.elevateDisableButtonLabel;
    }

    /***
    * @description Elevate credit card tokenization Visualforce page URL
    */
    get tokenizeCardPageUrl() {
        return tokenHandler.getTokenizeCardPageURL();
    }

    /***
    * @description Method handles messages received from Visualforce iframe wrapper.
    * @param message Message received from iframe
    */
    async handleMessage(message) {
        tokenHandler.handleMessage(message);

        if (message.isLoaded) {
            this.isLoading = false;
        }
    }

    /***
    * @description Method sends a message to the visualforce page iframe requesting a token.
    */
    requestToken() {
        this.clearError();

        const iframe = this.template.querySelector(`[data-id='${this.labels.elevateWidgetLabel}']`);

        return tokenHandler.requestToken(iframe, this.getCardholderName(), this.handleError);
    }

    /***
    * @description Handles user onclick event for disabling the widget.
    */
    handleUserDisabledWidget() {
        this.hideWidget();
        tokenHandler.dispatchApplicationEvent(WIDGET_EVENT_NAME, {
            isDisabled: true
        });
    }

    /***
    * @description Handles user onclick event for re-enabling the widget.
    */
    handleUserEnabledWidget() {
        this.isLoading = true;
        this.displayWidget();
        tokenHandler.dispatchApplicationEvent(WIDGET_EVENT_NAME, {
            isDisabled: false
        });
    }

    /***
    * @description Enables or disables the widget based on provided args.
    */
    displayWidget() {
        this.isDisabled = false;
        this.clearError();
    }

    /***
    * @description Enables or disables the widget based on provided args.
    */
    hideWidget() {
        this.isDisabled = true;
        this.clearError();
    }

    /**
     * Clears the error display
     */
    clearError() {
        this.alert = {};
    }

    /**
     * Handles the error from the iframe
     * @param message Error container
     * @return object Error object returned to the RD entry form
     */
    handleError = (message) => {
        let errorValue;
        let isObject = false;

        if (typeof message.error === 'object') {
            errorValue = JSON.stringify(Object.values(message.error));
            isObject = true;

        } else if (typeof message.error === 'string') {
            errorValue = message.error;

        } else {//an unexpected error has been generated
            const error = constructErrorMessage(message);
            errorValue = error
                ? error.detail
                : JSON.stringify(message);
        }

        this.alert = {
            theme: 'error',
            show: true,
            message: errorValue,
            variant: 'inverse',
            icon: 'utility:error'
        };

        return {
            error: {
                message: errorValue,
                isObject: isObject
            }
        };
    }

    /**
     * @description Concatenate the cardholder first and last names if there are any
     * @returns A concatenated Cardholder Name string from the First and Last Name fields
     */
    getCardholderName() {
        const nameField = this.template.querySelector('[data-id="cardholderName"]');
        return nameField.value;
    }

    /**
     * @description Concatenate the cardholder first and last names if there are any
     * @returns A concatenated Cardholder Name string from the First and Last Name fields
     */
    @api
    setCardholderName(donorName) {
        const nameField = this.template.querySelector('[data-id="cardholderName"]');
        nameField.value = donorName;
    }

    /**
     * Requests a payment token when the form is saved
     * @return {paymentToken: Promise<*>} Promise that will resolve to the token
     */
    @api
    returnToken() {
        return {
            payload: this.requestToken()
        };
    }
}
