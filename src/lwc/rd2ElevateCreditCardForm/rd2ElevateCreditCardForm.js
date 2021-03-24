import { api, track, LightningElement } from 'lwc';
import { constructErrorMessage } from 'c/utilCommon';

import tokenHandler from 'c/psElevateTokenHandler';
import getOrgDomainInfo from '@salesforce/apex/UTIL_AuraEnabledCommon.getOrgDomainInfo';

import elevateWidgetLabel from '@salesforce/label/c.commonPaymentServices';
import spinnerAltText from '@salesforce/label/c.geAssistiveSpinner';
import elevateDisableButtonLabel from '@salesforce/label/c.RD2_ElevateDisableButtonLabel';
import elevateDisabledMessage from '@salesforce/label/c.RD2_ElevateDisabledMessage';
import nextPaymentDonationDateMessage from '@salesforce/label/c.RD2_NextPaymentDonationDateInfo';
import cardholderNameLabel from '@salesforce/label/c.commonCardholderName';
import elevateEnableButtonLabel from '@salesforce/label/c.RD2_ElevateEnableButtonLabel';

/***
* @description Event name fired when the Elevate credit card widget is displayed or hidden
* on the RD2 entry form
*/
const WIDGET_EVENT_NAME = 'rd2ElevateCreditCardForm';

const TOKENIZE_CREDIT_CARD_EVENT_ACTION = 'createToken';

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
        cardholderNameLabel,
        nextPaymentDonationDateMessage
    };

    @track isLoading = true;
    @track isDisabled = false;
    @track alert = {};

    _paymentMethod = undefined;
    _nextDonationDate = undefined;
    _isEditPayment = false;

    @api
    get paymentMethod() {
        return this._paymentMethod;
    }

    set paymentMethod(value) {
        this._paymentMethod = value;
    }

    @api
    get isEditPayment() {
        return this._isEditPayment;
    }

    set isEditPayment(value) {
        this._isEditPayment = value;
    }

    get nextPaymentDonationDateMessage() {
        return (this.nextDonationDate == null)
        ? ''
        : this.labels.nextPaymentDonationDateMessage.replace('{{DATE}}', ' ');
    }

    @api 
    get nextDonationDate() {
        const localDate = new Date(this._nextDonationDate);
        return new Date(localDate.getUTCFullYear(), localDate.getUTCMonth(), localDate.getUTCDate());
    }

    set nextDonationDate(value) {
        this._nextDonationDate = value;
    }

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
    }

    /***
    * @description Listens for a message from the Visualforce iframe.
    */
    renderedCallback() {
        let component = this;
        tokenHandler.registerPostMessageListener(component);
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

        if (message.isReadyToMount && !this.isMounted) {
            this.requestMount();
        }
    }

    /***
    * @description Method sends a message to the Visualforce iframe wrapper for the Elevate sdk to mount
    * the tokenization iframe.
    */
    requestMount() {
        const iframe = this.template.querySelector(`[data-id='${this.labels.elevateWidgetLabel}']`);
        tokenHandler.mount(iframe, this.paymentMethod, this.handleError, this.resolveMount);
    }

    /***
    * @description Handles a successful response from the Elevate sdk mount request.
    */
    resolveMount = () => {
        this.isLoading = false;
        this.isMounted = true;
    }

    /***
    * @description Method sends a message to the visualforce page iframe requesting a token.
    */
    requestToken() {
        this.clearError();

        const iframe = this.template.querySelector(`[data-id='${this.labels.elevateWidgetLabel}']`);
        const params = { nameOnCard : this.getCardholderName() };
        return tokenHandler.requestToken({
            iframe: iframe,
            tokenizeParameters: params,
            eventAction: TOKENIZE_CREDIT_CARD_EVENT_ACTION,
            handleError: this.handleError,
        });
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
        this.isMounted = false;
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