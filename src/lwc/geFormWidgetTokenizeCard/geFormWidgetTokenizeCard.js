import { api, LightningElement, track } from 'lwc';
import GeLabelService from 'c/geLabelService';
import getPaymentTransactionStatusValues
    from '@salesforce/apex/GE_PaymentServices.getPaymentTransactionStatusValues';
import { format } from 'c/utilCommon';
import {
    fireEvent,
    registerListener,
    unregisterListener,
} from 'c/pubsubNoPageRef';

import tokenHandler from 'c/psElevateTokenHandler';
import getOrgDomainInfo from '@salesforce/apex/UTIL_AuraEnabledCommon.getOrgDomainInfo';

import DATA_IMPORT_PAYMENT_AUTHORIZATION_TOKEN_FIELD
    from '@salesforce/schema/DataImport__c.Payment_Authorization_Token__c';
import DATA_IMPORT_PAYMENT_STATUS_FIELD
    from '@salesforce/schema/DataImport__c.Payment_Status__c';
import {
    DISABLE_TOKENIZE_WIDGET_EVENT_NAME,
    LABEL_NEW_LINE,
} from 'c/geConstants';

export default class geFormWidgetTokenizeCard extends LightningElement {
    @track domain;
    @track isLoading = true;
    @track alert = {};
    @track disabledMessage;
    @track isDisabled = false;
    @track hasUserDisabledWidget = false;
    @track hasEventDisabledWidget = false;

    CUSTOM_LABELS = GeLabelService.CUSTOM_LABELS;
    PAYMENT_TRANSACTION_STATUS_ENUM;


    /***
    * @description Initializes the component and determines the Visualforce origin URLs
    */
    async connectedCallback() {
        this.PAYMENT_TRANSACTION_STATUS_ENUM = Object.freeze(
            JSON.parse(await getPaymentTransactionStatusValues())
        );

        const domainInfo = await getOrgDomainInfo()
            .catch(error => {
                this.handleError(error);
            });

        tokenHandler.setVisualforceOriginURLs(domainInfo);
    }

    /***
    * @description Registers event listeners
    */
    renderedCallback() {
        //Listens for a message from the Visualforce iframe.
        let component = this;
        tokenHandler.registerPostMessageListener(component);

        registerListener(DISABLE_TOKENIZE_WIDGET_EVENT_NAME, this.handleEventDisabledWidget, this);
    }

    /***
    * @description Unregisters the event listener
    */
    disconnectedCallback() {
        unregisterListener(DISABLE_TOKENIZE_WIDGET_EVENT_NAME);
    }

    /***
    * @description Returns the Elevate credit card tokenization Visualforce page URL
    */
    get tokenizeCardPageUrl() {
        return tokenHandler.getTokenizeCardPageURL();
    }

    /***
    * @description Returns true if the Elevate credit card widget is enabled
    * and the user did not click an action to hide it
    */
    get displayDoNotChargeCardButton() {
        return !(this.hasEventDisabledWidget || this.hasUserDisabledWidget);
    }

    /***
    * @description Handles a user's onclick event for disabling the widget.
    */
    handleUserDisabledWidget() {
        this.toggleWidget(true);
        this.hasUserDisabledWidget = true;
        this.dispatchApplicationEvent('doNotChargeState', {
            isWidgetDisabled: this.hasUserDisabledWidget
        });
    }

    /***
    * @description Handles a user's onclick event for re-enabling the widget.
    */
    handleUserEnabledWidget() {
        this.isLoading = true;
        this.toggleWidget(false);
        this.hasUserDisabledWidget = false;
        this.dispatchApplicationEvent('doNotChargeState', {
            isWidgetDisabled: this.hasUserDisabledWidget
        });
    }

    /***
    * @description Handles receipt of an event to disable this widget. Currently
    * used when we've charged a card, but BDI processing failed.
    */
    handleEventDisabledWidget(event) {
        this.toggleWidget(true, event.detail.message);
        this.hasEventDisabledWidget = true;
    }

    /***
    * @description Function enables or disables the widget based on provided args.
    *
    * @param {boolean} isDisabled: Determines whether or not the widget is disabled.
    * @param {string} message: Text to be disabled in the widgets body when disabled.
    */
    toggleWidget(isDisabled, message) {
        this.isDisabled = isDisabled;
        this.disabledMessage = message || null;
    }

    /***
    * @description Method handles messages received from iframed visualforce page.
    *
    * @param {object} message: Message received from iframe
    */
    async handleMessage(message) {
        tokenHandler.handleMessage(message);

        if (message.isLoaded) {
            this.isLoading = false;
        }
    }

    /***
     * @description Method sends a message to the visualforce page iframe requesting
     * a token. Response for this request is found and handled in
     * registerPostMessageListener.
     */
    requestToken() {
        this.clearError();

        const iframe = this.template.querySelector(
            `[data-id='${this.CUSTOM_LABELS.commonPaymentServices}']`);

        //The cardholder name is always empty for the purchase Payments Services card tokenization iframe
        //even though when it is accessible by the Gift Entry form for the Donor Type = Contact.
        const nameOnCard = null;
            return tokenHandler.requestToken(iframe, nameOnCard,
                this.handleError, this.resolveToken)

    }

    @api
    get paymentToken() {
        return {
            payload: this.requestToken()
        }
    }

    /**
     * Sets field values when a token is generated
     */
    resolveToken = (token) => {
        return {
            [DATA_IMPORT_PAYMENT_AUTHORIZATION_TOKEN_FIELD.fieldApiName]: token,
            [DATA_IMPORT_PAYMENT_STATUS_FIELD.fieldApiName]: this.PAYMENT_TRANSACTION_STATUS_ENUM.PENDING
        }
    }

    /**
     * Clears the error display
     */
    clearError() {
        this.alert = {};
    }

    /**
     * Displays the error
     */
    handleError = (message) => {
        this.alert = {
            theme: 'error',
            show: true,
            message: this.CUSTOM_LABELS.gePaymentProcessingErrorBanner,
            variant: 'inverse',
            icon: 'utility:error'
        };

        let errorValue;
        let isObject = false;

        if (typeof message.error === 'object') {
            errorValue = JSON.stringify(Object.values(message.error));
            isObject = true;

        } else if (typeof message.error === 'string') {
            errorValue = message.error;
        }

        let labelReplacements = [this.CUSTOM_LABELS.commonPaymentServices, errorValue];

        // This event can be used to extend handling payment errors at the form level by adding additional detail
        // objects.
        // We use the hex value for line feed (new line) 0x0A
        let formattedErrorResponse = format(this.CUSTOM_LABELS.gePaymentProcessError, labelReplacements);
        let splitErrorResponse = formattedErrorResponse.split(LABEL_NEW_LINE);
        return {
            error: {
                message: splitErrorResponse,
                isObject: isObject
            }
        };
    }

    dispatchApplicationEvent(eventName, payload) {
        fireEvent(null, eventName, payload);
    }
}
