import { api, track, LightningElement } from 'lwc';
import { fireEvent } from 'c/pubsubNoPageRef';
import { getNamespace, isFunction } from 'c/utilCommon';
import {
    TOKENIZE_TIMEOUT_MS,
    getTokenizeCardPageURL, getVisualforceOriginURLs
} from 'c/psElevateCommon';

import PAYMENT_AUTHORIZATION_TOKEN_FIELD from '@salesforce/schema/DataImport__c.Payment_Authorization_Token__c';

import getOrgDomainInfo from '@salesforce/apex/PS_ElevateController.getOrgDomainInfo';

import commonPaymentServices from '@salesforce/label/c.commonPaymentServices';
import assistiveSpinner from '@salesforce/label/c.geAssistiveSpinner';
import tokenRequestTimedOut from '@salesforce/label/c.gePaymentRequestTimedOut';

import rd2ElevateDisableLabel from '@salesforce/label/c.RD2_ElevateDisableLabel';
import rd2ElevateDisabledMessage from '@salesforce/label/c.RD2_ElevateDisabledMessage';
import rd2ElevateEnableLabel from '@salesforce/label/c.RD2_ElevateEnableLabel';

const WIDGET_DISABLED_EVENT_NAME = 'rd2TokenizeCardWidgetDisabled';

export default class psElevateCreditCardForm extends LightningElement {

    labels = {
        commonPaymentServices,
        assistiveSpinner,
        tokenRequestTimedOut,
        rd2ElevateDisableLabel,
        rd2ElevateDisabledMessage,
        rd2ElevateEnableLabel
    };


    @api cardHolderName;

    @track domain;
    @track visualforceOrigin;
    @track isLoading = true;
    @track alert = {};
    @track isDisabled = false;
    _visualforceOriginUrls;

    /***
    * @description
    */
    async connectedCallback() {
        this.domainInfo = await getOrgDomainInfo();

        this._visualforceOriginUrls = getVisualforceOriginURLs(this.domainInfo, this.getCurrentNamespace());
    }

    /***
    * @description
    */
    renderedCallback() {
        this.registerPostMessageListener();
    }

    /***
    * @description
    */
    disconnectedCallback() {
    }

    /***
    * @description
    */
    getCurrentNamespace() {
        return getNamespace(PAYMENT_AUTHORIZATION_TOKEN_FIELD.fieldApiName);
    }

    /***
    * @description 
    */
    get tokenizeCardPageUrl() {
        return getTokenizeCardPageURL(this.getCurrentNamespace());
    }

    /***
    * @description Handles a user's onclick event for disabling the widget.
    */
    handleUserDisabledWidget() {
        this.hideWidget();
        this.dispatchApplicationEvent(WIDGET_DISABLED_EVENT_NAME, {
            isWidgetDisabled: true
        });
    }

    /***
    * @description Handles a user's onclick event for re-enabling the widget.
    */
    handleUserEnabledWidget() {
        this.isLoading = true;
        this.displayWidget();
        this.dispatchApplicationEvent(WIDGET_DISABLED_EVENT_NAME, {
            isWidgetDisabled: false
        });
    }

    /***
    * @description Function enables or disables the widget based on provided args.
    */
    displayWidget() {
        this.isDisabled = false;
        this.clearError();
    }

    /***
    * @description Function enables or disables the widget based on provided args.
    */
    hideWidget() {
        this.isDisabled = true;
        this.clearError();
    }

    /***
    * @description
    */
    dispatchApplicationEvent(eventName, payload) {
        fireEvent(null, eventName, payload);
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
                    this.clearError();

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
     * 
     */
    clearError() {
        this.alert = {};
    }

    /**
     * Requests a payment token when the form is saved
     * @return {paymentToken: Promise<*>} Promise that will resolve to the token
     */
    @api
    returnValues() {
        return {
            payload: this.requestToken()
        };
    }

    @api
    setNameOnCard(cardHolderName) {
        this.cardHolderName = cardHolderName;
    }

}
