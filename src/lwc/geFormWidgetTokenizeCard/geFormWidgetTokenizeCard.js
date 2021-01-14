import { api, LightningElement, track } from 'lwc';
import GeLabelService from 'c/geLabelService';
import getPaymentTransactionStatusValues
    from '@salesforce/apex/GE_PaymentServices.getPaymentTransactionStatusValues';
import { apiNameFor, format, isEmptyObject } from 'c/utilCommon';
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
import DATA_IMPORT_PAYMENT_METHOD
    from '@salesforce/schema/DataImport__c.Payment_Method__c';
import DATA_IMPORT_CONTACT_FIRSTNAME from '@salesforce/schema/DataImport__c.Contact1_Firstname__c';
import DATA_IMPORT_CONTACT_LASTNAME from '@salesforce/schema/DataImport__c.Contact1_Lastname__c';
import DATA_IMPORT_DONATION_DONOR from '@salesforce/schema/DataImport__c.Donation_Donor__c';
import DATA_IMPORT_ACCOUNT_NAME from '@salesforce/schema/DataImport__c.Account1_Name__c';
import {
    DISABLE_TOKENIZE_WIDGET_EVENT_NAME,
    PAYMENT_METHODS, PAYMENT_METHOD_CREDIT_CARD,
    LABEL_NEW_LINE, ACCOUNT_HOLDER_TYPES, ACCOUNT_HOLDER_BANK_TYPES
} from 'c/geConstants';

const TOKENIZE_CREDIT_CARD_EVENT_ACTION = 'createToken';
const TOKENIZE_ACH_EVENT_ACTION = 'createAchToken';
const CONTACT_DONOR_TYPE = 'Contact1';

export default class geFormWidgetTokenizeCard extends LightningElement {
    @api sourceFieldsUsedInTemplate = [];
    @track domain;
    @track isLoading = true;
    @track alert = {};
    @track disabledMessage;
    @track isDisabled = false;
    @track hasUserDisabledWidget = false;
    @track hasEventDisabledWidget = false;

    CUSTOM_LABELS = GeLabelService.CUSTOM_LABELS;
    PAYMENT_TRANSACTION_STATUS_ENUM;

    _currentPaymentMethod = undefined;
    _hasPaymentMethodInTemplate = false;


    iframe() {
        return this.template.querySelector(
            `[data-id='${this.CUSTOM_LABELS.commonPaymentServices}']`);
    }

    @api
    get widgetDataFromState() {
        return this._widgetDataFromState;
    }

    set widgetDataFromState(widgetState) {
        this._widgetDataFromState = widgetState;

        if (isEmptyObject(this.PAYMENT_TRANSACTION_STATUS_ENUM) ||
            this.shouldHandleWidgetDataChange()) {

            this.handleWidgetDataChange();
        }
    }

    handleWidgetDataChange() {
        this._hasPaymentMethodInTemplate =
            this.sourceFieldsUsedInTemplate.includes(apiNameFor(DATA_IMPORT_PAYMENT_METHOD));

        if (this._hasPaymentMethodInTemplate) {
            this._currentPaymentMethod = this.widgetDataFromState[apiNameFor(DATA_IMPORT_PAYMENT_METHOD)];

            if (this.hasValidPaymentMethod(this._currentPaymentMethod)) {
                if (this.isMounted) {
                    this.requestSetPaymentMethod(this._currentPaymentMethod);
                } else {
                    if (!this.hasUserDisabledWidget) {
                        this.handleUserEnabledWidget();
                        this.hasEventDisabledWidget = false;
                    }
                }
            } else {
                this.toggleWidget(true, this.disabledWidgetMessage);
                this.hasEventDisabledWidget = true;
            }
        } else {
            this._currentPaymentMethod = PAYMENT_METHOD_CREDIT_CARD;
        }
    }

    shouldHandleWidgetDataChange() {
        return !this.isPaymentCharged();
    }

    isPaymentCharged() {
        return (this.widgetDataFromState[apiNameFor(DATA_IMPORT_PAYMENT_STATUS_FIELD)] ===
            this.PAYMENT_TRANSACTION_STATUS_ENUM.CAPTURED ||

            this.widgetDataFromState[apiNameFor(DATA_IMPORT_PAYMENT_STATUS_FIELD)] ===
            this.PAYMENT_TRANSACTION_STATUS_ENUM.SUBMITTED);
    }

    hasValidPaymentMethod(paymentMethod) {
        return paymentMethod === PAYMENT_METHODS.ACH
            || paymentMethod === PAYMENT_METHOD_CREDIT_CARD;
    }

    tokenizeEventAction() {
        return this._currentPaymentMethod === PAYMENT_METHODS.ACH
            ? TOKENIZE_ACH_EVENT_ACTION
            : TOKENIZE_CREDIT_CARD_EVENT_ACTION;
    }

    requestSetPaymentMethod(paymentMethod) {
        this.isLoading = true;
        tokenHandler.setPaymentMethod(
            this.iframe(), paymentMethod, this.handleError,
            this.resolveSetPaymentMethod,
        ).catch(err => {
            this.handleError(err);
        });
    }

    resolveSetPaymentMethod = () => {
        this.isLoading = false;
    }

    get shouldDisplayEnableButton() {
        if (!this._hasPaymentMethodInTemplate) return true;
        if (this._hasPaymentMethodInTemplate && this.hasValidPaymentMethod(this._currentPaymentMethod)) {
            return true;
        }
        return false;
    }

    get disabledWidgetMessage() {
        if (this.shouldDisplayEnableButton) {
            return this.CUSTOM_LABELS.geBodyPaymentNotProcessingTransaction;
        }
        return this.CUSTOM_LABELS.geBodyPaymentNotProcessingTransaction
            + ' ' + this.CUSTOM_LABELS.psSelectValidPaymentMethod;
    }

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
    get displayDisableWidgetButton() {
        return !(this.hasEventDisabledWidget || this.hasUserDisabledWidget);
    }

    /***
    * @description Handles a user's onclick event for disabling the widget.
    */
    handleUserDisabledWidget() {
        this.toggleWidget(true);
        this.hasUserDisabledWidget = true;
        this.isMounted = false;
        this.dispatchApplicationEvent('doNotChargeState', {
            isElevateWidgetDisabled: this.hasUserDisabledWidget
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
            isElevateWidgetDisabled: this.hasUserDisabledWidget
        });
    }

    /***
    * @description Handles receipt of an event to disable this widget. Currently
    * used when we've submitted a payment, but BDI processing failed.
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
        this.isMounted = false;
        this.disabledMessage = message || null;
    }

    /***
    * @description Method handles messages received from iframed visualforce page.
    *
    * @param {object} message: Message received from iframe
    */
    async handleMessage(message) {
        tokenHandler.handleMessage(message);

        if (message.isReadyToMount && !this.isMounted) {
            this.requestMount();
        }
    }

    requestMount() {
        tokenHandler.mount(this.iframe(), this._currentPaymentMethod, this.handleError, this.resolveMount);
    }

    resolveMount = () => {
        this.isLoading = false;
        this.isMounted = true;
    }

    /***
     * @description Method sends a message to the visualforce page iframe requesting
     * a token. Response for this request is found and handled in
     * registerPostMessageListener.
     */
    requestToken() {
        this.clearError();
        return tokenHandler.requestToken({
            iframe: this.iframe(),
            tokenizeParameters: this.buildTokenizeParameters(),
            eventAction: this.tokenizeEventAction(),
            handleError: this.handleError,
            resolveToken: this.resolveToken,
        });
    }

    buildTokenizeParameters() {
        if (this._currentPaymentMethod === PAYMENT_METHOD_CREDIT_CARD) {
            //The cardholder name is always empty for the purchase Payments Services card tokenization iframe
            //even though when it is accessible by the Gift Entry form for the Donor Type = Contact.
            return { nameOnCard: null };
        } else {
            return this.ACHTokenizeParameters();
        }
    }

    ACHTokenizeParameters() {
        let achTokenizeParameters = {
            nameOnAccount: '',
            accountHolder: {},
        };
        achTokenizeParameters.accountHolder.type = this.accountHolderType();
        achTokenizeParameters.accountHolder.bankType = ACCOUNT_HOLDER_BANK_TYPES.CHECKING;
        achTokenizeParameters = this.accountHolderType() ===
        ACCOUNT_HOLDER_TYPES.BUSINESS
            ? this.populateAchParametersForBusiness(achTokenizeParameters)
            : this.populateAchParametersForIndividual(achTokenizeParameters);
        return JSON.stringify(achTokenizeParameters);
    }

    populateAchParametersForBusiness(achTokenizeParameters) {
        achTokenizeParameters.accountHolder.businessName =
            this.widgetDataFromState[apiNameFor(DATA_IMPORT_CONTACT_LASTNAME)];
        achTokenizeParameters.accountHolder.accountName =
            this.widgetDataFromState[apiNameFor(DATA_IMPORT_ACCOUNT_NAME)];
        achTokenizeParameters.nameOnAccount =
            this.widgetDataFromState[apiNameFor(DATA_IMPORT_ACCOUNT_NAME)];
        return achTokenizeParameters;
    }

    populateAchParametersForIndividual (achTokenizeParameters) {
        achTokenizeParameters.accountHolder.firstName =
            this.widgetDataFromState[apiNameFor(DATA_IMPORT_CONTACT_FIRSTNAME)];
        achTokenizeParameters.accountHolder.lastName =
            this.widgetDataFromState[apiNameFor(DATA_IMPORT_CONTACT_LASTNAME)];
        achTokenizeParameters.nameOnAccount =
            `${this.widgetDataFromState[apiNameFor(DATA_IMPORT_CONTACT_FIRSTNAME)]} ${this.widgetDataFromState[apiNameFor(DATA_IMPORT_CONTACT_LASTNAME)]}`;
        return achTokenizeParameters
    }

    accountHolderType() {
        return this.widgetDataFromState[
            apiNameFor(DATA_IMPORT_DONATION_DONOR)] === CONTACT_DONOR_TYPE
            ? ACCOUNT_HOLDER_TYPES.INDIVIDUAL
            : ACCOUNT_HOLDER_TYPES.BUSINESS;
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
