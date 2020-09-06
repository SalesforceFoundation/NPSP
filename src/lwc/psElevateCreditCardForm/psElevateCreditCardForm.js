import { api, track, LightningElement } from 'lwc';
import { format, getNamespace, isFunction } from 'c/utilCommon';
import { isBlank } from 'c/util';
import { getTokenizeCardPageURL, getVisualforceOriginURLs } from 'c/psElevateCommon';
import { fireEvent, registerListener, unregisterListener } from 'c/pubsubNoPageRef';

import PAYMENT_AUTHORIZATION_TOKEN_FIELD from '@salesforce/schema/DataImport__c.Payment_Authorization_Token__c';

import getOrgDomainInfo from '@salesforce/apex/PS_ElevateController.getOrgDomainInfo';

import commonPaymentServices from '@salesforce/label/c.commonPaymentServices';
import assistiveSpinner from '@salesforce/label/c.geAssistiveSpinner';
import tokenRequestTimedOut from '@salesforce/label/c.gePaymentRequestTimedOut';

import geButtonPaymentDoNotCharge from '@salesforce/label/c.geButtonPaymentDoNotCharge';
import geBodyPaymentNotProcessingTransaction from '@salesforce/label/c.geBodyPaymentNotProcessingTransaction';
import geButtonPaymentAlternate from '@salesforce/label/c.geButtonPaymentAlternate';
import gePaymentProcessingErrorBanner from '@salesforce/label/c.gePaymentProcessingErrorBanner';
import gePaymentProcessError from '@salesforce/label/c.gePaymentProcessError';

import rd2ElevateDisableLabel from '@salesforce/label/c.RD2_ElevateDisableLabel';
import rd2ElevateDisabledMessage from '@salesforce/label/c.RD2_ElevateDisabledMessage';
import rd2ElevateEnableLabel from '@salesforce/label/c.RD2_ElevateEnableLabel';

import {
    DISABLE_TOKENIZE_WIDGET_EVENT_NAME,
    LABEL_NEW_LINE,
    WIDGET_TYPE_DI_FIELD_VALUE,
} from 'c/geConstants';

const TOKENIZE_TIMEOUT_MS = 10000; 
const WIDGET_DISABLED_EVENT_NAME = 'doNotChargeState';

export default class psElevateCreditCardForm extends LightningElement {

    labels = {
        commonPaymentServices,
        assistiveSpinner,
        tokenRequestTimedOut,
        gePaymentProcessingErrorBanner,
        gePaymentProcessError,
        geButtonPaymentDoNotCharge,
        geBodyPaymentNotProcessingTransaction,
        geButtonPaymentAlternate,
        rd2ElevateDisableLabel,
        rd2ElevateDisabledMessage,
        rd2ElevateEnableLabel
    };


    @api cardHolderName;
    @api scope;

    @track domain;
    @track visualforceOrigin;
    @track isLoading = true;
    @track alert = {};
    @track disabledMessage;
    @track isDisabled = false;
    @track hasUserDisabledWidget = false;
    @track hasEventDisabledWidget = false;
    _visualforceOriginUrls;

    isGEWidget() {
        return isBlank(this.scope) || this.scope !== 'rd2'
            ? true //default is GE
            : false;
    }

    get disableCardEntryLabel() {
        return this.isGEWidget()
            ? this.labels.geButtonPaymentDoNotCharge
            : this.labels.rd2ElevateDisableLabel
    }

    get disabledCardEntryMessage() {
        return this.isGEWidget()
            ? this.labels.geBodyPaymentNotProcessingTransaction
            : this.labels.rd2ElevateDisabledMessage
    }

    get enableCardEntryLabel() {
        return this.isGEWidget()
            ? this.labels.geButtonPaymentAlternate
            : this.labels.rd2ElevateEnableLabel
    }

    get displayHideCardButton() {
        return !(this.hasEventDisabledWidget || this.hasUserDisabledWidget);
    }

    get tokenizeCardPageUrl() {
        return getTokenizeCardPageURL(this.getCurrentNamespace());
    }

    async connectedCallback() {
        this.domainInfo = await getOrgDomainInfo();

        this._visualforceOriginUrls = getVisualforceOriginURLs(this.domainInfo, this.getCurrentNamespace());
    }

    renderedCallback() {
        this.registerPostMessageListener();
        registerListener(DISABLE_TOKENIZE_WIDGET_EVENT_NAME, this.handleEventDisabledWidget, this);
    }

    disconnectedCallback() {
        unregisterListener(DISABLE_TOKENIZE_WIDGET_EVENT_NAME);
    }

    /***
    * @description Handles a user's onclick event for disabling the widget.
    */
    handleUserDisabledWidget() {
        this.hideWidget();
        this.hasUserDisabledWidget = true;
        this.dispatchApplicationEvent(WIDGET_DISABLED_EVENT_NAME, {
            isWidgetDisabled: this.hasUserDisabledWidget
        });
    }

    /***
    * @description Handles a user's onclick event for re-enabling the widget.
    */
    handleUserEnabledWidget() {
        this.isLoading = true;
        this.displayWidget();
        this.hasUserDisabledWidget = false;
        this.dispatchApplicationEvent(WIDGET_DISABLED_EVENT_NAME, {
            isWidgetDisabled: this.hasUserDisabledWidget
        });
    }

    /***
    * @description Handles receipt of an event to disable this widget. Currently
    * used when we've charged a card, but BDI processing failed.
    */
    handleEventDisabledWidget(event) {
        this.hideWidget(event.detail.message);
        this.hasEventDisabledWidget = true;
    }

    /***
    * @description Function enables or disables the widget based on provided args.
    * @param {string} message: Text to be disabled in the widgets body when disabled.
    */
    displayWidget(message) {
        this.isDisabled = false;
        this.disabledMessage = message || null;
    }

    /***
    * @description Function enables or disables the widget based on provided args.
    * @param {string} message: Text to be disabled in the widgets body when disabled.
    */
    hideWidget(message) {
        this.isDisabled = true;
        this.disabledMessage = message || null;
    }

    getCurrentNamespace() {
        return getNamespace(
            PAYMENT_AUTHORIZATION_TOKEN_FIELD.fieldApiName);
    }

    /***
    * @description Method listens for a message from the visualforce iframe.
    * Rejects any messages from an unknown origin.
    */
    registerPostMessageListener() {
        let component = this;

        window.onmessage = async function (event) {
            component.visualforceOrigin = component._visualforceOriginUrls.find(
                origin => event.origin === origin.value
            ).value;

            if (component.visualforceOrigin) {
                const message = JSON.parse(event.data);
                component.handleMessage(message);
            }
        }
    }

    /***
    * @description Method handles messages received from iframed visualforce page.
    *
    * @param {object} message: Message received from iframe
    */
    async handleMessage(message) {
        if (message.error || message.token) {
            if (isFunction(this.tokenCallback)) {
                this.tokenCallback(message);
            }

        } else if (message.isLoaded) {
            this.isLoading = false;
        }
    }

    /***
    * @description Method sends a message to the visualforce page iframe requesting
    * a token. Response for this request is found and handled in
    * registerPostMessageListener.
    */
    requestToken() {
        const iframe = this.template.querySelector(`[data-id='${this.labels.commonPaymentServices}']`);

        if (iframe) {
            const tokenPromise = new Promise((resolve, reject) => {

                const timer = setTimeout(() => reject(this.handleTokenizationTimeout()), TOKENIZE_TIMEOUT_MS);

                this.tokenCallback = message => {
                    clearTimeout(timer);
                    this.alert = {};

                    if (message.error) {
                        reject(this.handleTokenizationError(message));

                    } else if (message.token) {
                        resolve({
                            [PAYMENT_AUTHORIZATION_TOKEN_FIELD.fieldApiName]: message.token
                        });
                    }
                };

            });

            iframe.contentWindow.postMessage(
                { action: 'createToken' },
                this.visualforceOrigin
            );

            return tokenPromise;
        }
    }

    handleTokenizationTimeout() {
        return {
            error: this.labels.tokenRequestTimedOut,
            isObject: false
        };
    }

    handleTokenizationError(message) {
        let errorValue;
        let isObject = false;

        if (typeof message.error === 'object') {
            errorValue = JSON.stringify(Object.values(message.error));
            isObject = true;

        } else if (typeof message.error === 'string') {
            errorValue = message.error;
        }

        const isGEWidget = this.isGEWidget();

        /** This event can be used to extend handling payment errors at the form level by adding additional detail
         * objects.
         * We use the hex value for line feed (new line) 0x0A
         */
        let labelReplacements = [this.labels.commonPaymentServices, errorValue];
        let formattedErrorResponse = format(this.labels.gePaymentProcessError, labelReplacements);
        let splitErrorResponse = formattedErrorResponse.split(LABEL_NEW_LINE);

        let alertMessage = isGEWidget
            ? this.labels.gePaymentProcessingErrorBanner
            : errorValue;

        this.alert = {
            theme: 'error',
            show: true,
            message: alertMessage,
            variant: 'inverse',
            icon: 'utility:error'
        };

        return {
            error: {
                message: (isGEWidget || isObject) ? splitErrorResponse : errorValue,
                isObject: isObject
            }
        };              
    }

    /**
     * Requests a payment token when the form is saved
     * @return {paymentToken: Promise<*>} Promise that will resolve to the token
     */
    @api
    returnValues() {
        return {
            type: WIDGET_TYPE_DI_FIELD_VALUE,
            payload: this.requestToken()
        };
    }

    @api
    load() { }

    @api
    reset() { }

    @api
    get allFieldsByAPIName() {
        return [PAYMENT_AUTHORIZATION_TOKEN_FIELD.fieldApiName];
    }

    @api
    setNameOnCard(cardHolderName) {
        this.cardHolderName = cardHolderName;
    }

    dispatchApplicationEvent(eventName, payload) {
        fireEvent(null, eventName, payload);
    }
}
