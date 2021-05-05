import { api, track, LightningElement } from 'lwc';
import { constructErrorMessage } from 'c/utilCommon';

import tokenHandler from 'c/psElevateTokenHandler';
import getOrgDomainInfo from '@salesforce/apex/UTIL_AuraEnabledCommon.getOrgDomainInfo';

import elevateWidgetLabel from '@salesforce/label/c.commonPaymentServices';
import spinnerAltText from '@salesforce/label/c.geAssistiveSpinner';
import elevateDisableButtonLabel from '@salesforce/label/c.RD2_ElevateDisableButtonLabel';
import elevateDisabledMessage from '@salesforce/label/c.RD2_ElevateDisabledMessage';
import nextPaymentDonationDateMessage from '@salesforce/label/c.RD2_NextPaymentDonationDateInfo';
import nextACHPaymentDonationDateMessage from '@salesforce/label/c.RD2_NextACHPaymentDonationDateInfo';
import cardholderNameLabel from '@salesforce/label/c.commonCardholderName';
import elevateEnableButtonLabel from '@salesforce/label/c.RD2_ElevateEnableButtonLabel';
import updatePaymentButtonLabel from '@salesforce/label/c.commonEditPaymentInformation';
import cancelButtonLabel from '@salesforce/label/c.commonCancel';
import commonExpirationDate from '@salesforce/label/c.commonMMYY';
import { isNull } from 'c/util';
import {
    ACCOUNT_HOLDER_BANK_TYPES,
    ACCOUNT_HOLDER_TYPES,
    PAYMENT_METHOD_ACH,
    PAYMENT_METHOD_CREDIT_CARD,
    TOKENIZE_CREDIT_CARD_EVENT_ACTION,
    TOKENIZE_ACH_EVENT_ACTION
} from 'c/geConstants';

/***
* @description Event name fired when the Elevate credit card widget is displayed or hidden
* on the RD2 entry form
*/
const WIDGET_EVENT_NAME = 'rd2ElevateCreditCardForm';

const ELEVATE_PAYMENT_METHODS = [PAYMENT_METHOD_ACH, PAYMENT_METHOD_CREDIT_CARD];
const DEFAULT_ACH_CODE = 'WEB';

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
        updatePaymentButtonLabel,
        cancelButtonLabel,
        nextPaymentDonationDateMessage,
        nextACHPaymentDonationDateMessage,
        commonExpirationDate
    };

    @track isLoading = true;
    @track isDisabled = false;
    @track alert = {};

    _paymentMethod;
    _nextDonationDate;
    _isEditPayment = false;
    
    @api isEditMode;
    @api cardLastFour;
    @api cardLastFourLabel;
    @api cardExpDate;
    @api achLastFourLabel;
    @api achLastFour;

    @api payerOrganizationName;
    @api payerFirstName;
    @api payerLastName;
    @api achAccountType;

    @api
    get paymentMethod() {
        return this._paymentMethod;
    }

    set paymentMethod(value) {
        this.notifyIframePaymentMethodChanged(value);
        this._paymentMethod = value;
    }

    notifyIframePaymentMethodChanged(newValue) {
        const iframe = this.selectIframe();
        if (isNull(iframe)) {
            return;
        }
        if(this.shouldNotifyIframe(newValue)) {
            tokenHandler.setPaymentMethod(
                iframe,
                newValue,
                this.handleError,
                this.resolveMount
            ).catch(err => {
                this.handleError(err);
            });
        }
    }

    @api
    get isEditPayment() {
        return this._isEditPayment;
    }

    set isEditPayment(value) {
        this._isEditPayment = value;
    }

    get isAchPayment() {
        return this.paymentMethod === PAYMENT_METHOD_ACH;
    }

    get isCardPayment() {
        return this.paymentMethod === PAYMENT_METHOD_CREDIT_CARD;
    }

    get isEditAch() {
        return this.isEditMode && this.isAchPayment;
    }

    get isEditCard() {
        return this.isEditMode && this.isCardPayment;
    }

    get nextPaymentDateMessage() {
        if(this.isAchPayment) {
            return this.labels.nextACHPaymentDonationDateMessage;
        } else if(this.isCardPayment) {
            return this.labels.nextPaymentDonationDateMessage;
        }
    }

    isElevatePaymentMethod(paymentMethod) {
        return ELEVATE_PAYMENT_METHODS.includes(paymentMethod);
    }

    shouldNotifyIframe(newPaymentMethod) {
        const oldPaymentMethod = this._paymentMethod;
        const changed = oldPaymentMethod !== newPaymentMethod;
        const newMethodValidForElevate = this.isElevatePaymentMethod(newPaymentMethod);
        return changed && newMethodValidForElevate;
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
        if(this.isEditMode) {
            this.isDisabled = true;
        }

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
        const iframe = this.selectIframe();
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

        const iframe = this.selectIframe();
        if(this.paymentMethod === PAYMENT_METHOD_CREDIT_CARD) {
            return this.requestCardToken(iframe);
        } else if(this.paymentMethod === PAYMENT_METHOD_ACH) {
            return this.requestAchToken(iframe);
        }
    }

    selectIframe() {
        return this.template.querySelector(`[data-id='${this.labels.elevateWidgetLabel}']`);
    }

    requestCardToken(iframe) {
        const params = {nameOnCard: this.getCardholderName()};
        return tokenHandler.requestToken({
            iframe: iframe,
            tokenizeParameters: params,
            eventAction: TOKENIZE_CREDIT_CARD_EVENT_ACTION,
            handleError: this.handleError,
        });
    }

    requestAchToken(iframe) {
        const params = JSON.stringify(this.getAchParams());
        return tokenHandler.requestToken({
            iframe: iframe,
            tokenizeParameters: params,
            eventAction: TOKENIZE_ACH_EVENT_ACTION,
            handleError: this.handleError,
        });
    }

    getAchParams() {
        if(this.achAccountType === ACCOUNT_HOLDER_TYPES.INDIVIDUAL) {
            return {
                accountHolder: {
                    firstName: this.payerFirstName,
                    lastName: this.payerLastName,
                    type: this.achAccountType,
                    bankType: ACCOUNT_HOLDER_BANK_TYPES.CHECKING
                },
                achCode: DEFAULT_ACH_CODE,
                nameOnAccount: `${this.payerFirstName} ${this.payerLastName}`
            };
        } else if(this.achAccountType === ACCOUNT_HOLDER_TYPES.BUSINESS) {
            return {
                accountHolder: {
                    businessName: this.payerLastName,
                    accountName: this.payerOrganizationName,
                    type: this.achAccountType,
                    bankType: ACCOUNT_HOLDER_BANK_TYPES.CHECKING
                },
                achCode: DEFAULT_ACH_CODE,
                nameOnAccount: this.payerOrganizationName
            };
        }
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

    get qaLocatorLastFourDigits() {
        return `text Last Four Digits`;
    }

    get qaLocatorExpirationDate() {
        return `text Expiration Date`;
    }

}