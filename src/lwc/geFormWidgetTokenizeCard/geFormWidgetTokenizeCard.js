import { api, LightningElement, wire } from 'lwc';
import GeLabelService from 'c/geLabelService';
import tokenHandler from 'c/psElevateTokenHandler';
import { apiNameFor, format, isEmpty, isNotEmpty } from 'c/utilCommon';
import { fireEvent, registerListener, unregisterListener } from 'c/pubsubNoPageRef';
import { getFieldValue, getRecord } from "lightning/uiRecordApi";
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import {
    ACCOUNT_HOLDER_BANK_TYPES,
    ACCOUNT_HOLDER_TYPES,
    DISABLE_TOKENIZE_WIDGET_EVENT_NAME,
    LABEL_NEW_LINE,
    PAYMENT_METHOD_CREDIT_CARD,
    PAYMENT_METHODS,
    TOKENIZE_ACH_EVENT_ACTION,
    TOKENIZE_CREDIT_CARD_EVENT_ACTION
} from 'c/geConstants';

import GeFormService from 'c/geFormService';

import DATA_IMPORT_PAYMENT_AUTHORIZATION_TOKEN_FIELD
    from '@salesforce/schema/DataImport__c.Payment_Authorization_Token__c';
import DATA_IMPORT_PAYMENT_STATUS_FIELD from '@salesforce/schema/DataImport__c.Payment_Status__c';
import DATA_IMPORT_PAYMENT_METHOD from '@salesforce/schema/DataImport__c.Payment_Method__c';
import DATA_IMPORT_CONTACT_FIRSTNAME from '@salesforce/schema/DataImport__c.Contact1_Firstname__c';
import DATA_IMPORT_CONTACT_LASTNAME from '@salesforce/schema/DataImport__c.Contact1_Lastname__c';
import DATA_IMPORT_DONATION_DONOR from '@salesforce/schema/DataImport__c.Donation_Donor__c';
import DATA_IMPORT_ACCOUNT_NAME from '@salesforce/schema/DataImport__c.Account1_Name__c';
import DATA_IMPORT_PARENT_BATCH_LOOKUP from '@salesforce/schema/DataImport__c.NPSP_Data_Import_Batch__c';
import PAYMENT_EXPIRATION_YEAR from '@salesforce/schema/DataImport__c.Payment_Card_Expiration_Year__c';
import PAYMENT_EXPIRATION_MONTH from '@salesforce/schema/DataImport__c.Payment_Card_Expiration_Month__c';
import PAYMENT_LAST_4 from '@salesforce/schema/DataImport__c.Payment_Card_Last_4__c';
import DATA_IMPORT_ID from '@salesforce/schema/DataImport__c.Id';
import DATA_IMPORT from '@salesforce/schema/DataImport__c';

const CONTACT_DONOR_TYPE = 'Contact1';

const MODES = Object.freeze({
    CHARGE: 'Charge',
    READ_ONLY: 'ReadOnly',
    CRITICAL_ERROR: 'CriticalError',
    DO_NOT_CHARGE: 'DoNotCharge',
    DEACTIVATE: 'Deactivate'
});

export default class geFormWidgetTokenizeCard extends LightningElement {
    @api paymentTransactionStatusValues = {};
    @api hasPaymentMethodFieldInForm;
    _isLoading = true;
    alert = {};
    _disabledMessage;
    _isDisabled = false;
    _hasUserDisabledWidget = false;
    _hasEventDisabledWidget = false;
    _isEditMode = false;

    CUSTOM_LABELS = GeLabelService.CUSTOM_LABELS;

    dataImportId;
    _currentPaymentMethod = undefined;
    _isReadOnlyMode = false;
    _showCancelButton = false;
    _cardLast4;
    _cardExpirationDate;
    _widgetDataFromState;

    setMode (mode) {
        switch (mode) {
            case MODES.CHARGE:
                this.enableChargeMode();
                break;
            case MODES.READ_ONLY:
                this.enableReadOnlyMode();
                break;
            case MODES.CRITICAL_ERROR:
                this.enableCriticalErrorMode();
                break;
            case MODES.DO_NOT_CHARGE:
                this.enableDoNotChargeMode();
                break;
            case MODES.DEACTIVATE:
                this.disableWidget();
                break;
            default:
                this.enableChargeMode();
        }
    }

    enableChargeMode() {
        if (this.canEnterChargeMode()) {
            this.handleUserEnabledWidget();
            this._hasEventDisabledWidget = false;
            return;
        }
        if (this.isMounted) {
            this.requestSetPaymentMethod(this._currentPaymentMethod);
        }
    }

    canEnterChargeMode() {
        return !(this.isMounted
            || this._isReadOnlyMode || this._isEditMode
            || this._hasUserDisabledWidget
        );
    }

    enableReadOnlyMode() {
        if (!this.canEnterReadOnlyMode()) return;
        if (this.hasReadOnlyStatus()) {
            this.dataImportId = this.widgetDataFromState[apiNameFor(DATA_IMPORT_ID)];
            this.toggleWidget(true);
            this._isReadOnlyMode = true;
            this._hasUserDisabledWidget = false;
        }
    }

    canEnterReadOnlyMode() {
        return !(this._isEditMode || this._hasUserDisabledWidget);
    }

    enableCriticalErrorMode() {
        this.toggleWidget(true, this._disabledMessage);
        this._hasEventDisabledWidget = true;
    }

    enableDoNotChargeMode() {
        this.toggleWidget(true);
        this._hasUserDisabledWidget = true;
        this.isMounted = false;
        this.dispatchApplicationEvent('doNotChargeState', {
            isElevateWidgetDisabled: this._hasUserDisabledWidget
        });
    }

    disableWidget() {
        this._isReadOnlyMode = false;
        this._showCancelButton = false;
        this.toggleWidget(true, this.disabledWidgetMessage);
        this._hasEventDisabledWidget = true;
    }

    disableReadOnlyMode() {
        if (!this.hasValidPaymentMethod()) {
            this.setMode(MODES.DEACTIVATE);
            return;
        }
        this._isEditMode = true;
        this._isReadOnlyMode = false;
        this._showCancelButton = true;
        this.handleUserEnabledWidget();
    }

    cancelEditPaymentInformation() {
        this._showCancelButton = false;
        this._isEditMode = false;
        this.enableReadOnlyMode();
    }

    isInBatchGiftEntry() {
        return this.widgetDataFromState &&
               this.widgetDataFromState[apiNameFor(DATA_IMPORT_PARENT_BATCH_LOOKUP)] !== undefined;
    }

    iframe() {
        return this.template.querySelector(
            `[data-id='${this.CUSTOM_LABELS.commonPaymentServices}']`);
    }

    get isReadOnlyMode() {
        return this._isReadOnlyMode;
    }

    @api
    get widgetDataFromState() {
        return this._widgetDataFromState;
    }

    get shouldDisplayCancelButton() {
        return this._showCancelButton;
    }

    get shouldDisplayEditPaymentInformation() {
        return this.isReadOnlyMode && !this.isPaymentCaptured();
    }

    get shouldDisplayCardProcessingGuidanceMessage() {
        return !this.isReadOnlyMode && this.isInBatchGiftEntry() && this.hasValidPaymentMethod() && this.isMounted;
    }

    isPaymentCaptured() {
        return this.currentPaymentStatus() === this.paymentTransactionStatusValues.CAPTURED;
    }

    @wire(getObjectInfo, {objectApiName: apiNameFor(DATA_IMPORT)})
    dataImportObjectDescribe;

    @wire(getRecord, {recordId: '$dataImportId', optionalFields: [
            PAYMENT_LAST_4, PAYMENT_EXPIRATION_MONTH, PAYMENT_EXPIRATION_YEAR]})
    wiredDataImportRecord({data, error}) {
        if (data) {
            this.setReadOnlyData(data)
        } else if (error) {
            this.handleError(error);
        }
    }

    get canViewReadOnlyFields() {
        const fields = this.dataImportObjectDescribe.data.fields;
        return fields?.[apiNameFor(PAYMENT_LAST_4)] !== undefined
            && fields?.[apiNameFor(PAYMENT_EXPIRATION_MONTH)] !== undefined
            && fields?.[apiNameFor(PAYMENT_EXPIRATION_YEAR)] !== undefined;
    }
    
    get hasUserDisabledWidget() {
        return this._hasUserDisabledWidget;
    }

    setReadOnlyData(data) {
        this._cardLast4  = getFieldValue(data, PAYMENT_LAST_4);
        this._cardExpirationDate =  getFieldValue(data, PAYMENT_EXPIRATION_MONTH) + '/' +
            getFieldValue(data, PAYMENT_EXPIRATION_YEAR);
    }

    get cardLast4() {
        return this._cardLast4;
    }

    get cardExpirationDate() {
        return this._cardExpirationDate;
    }

    get isLoading() {
        return this._isLoading;
    }

    get disabledMessage() {
        return this._disabledMessage;
    }

    get isDisabled() {
        return this._isDisabled;
    }

    set widgetDataFromState(widgetState) {
        if (this.isNewRow(widgetState)) {
           this.resetWidget();
        }
        this._widgetDataFromState = widgetState;
        this.setCurrentPaymentMethod();
        if (this.shouldHandleWidgetDataChange()) {
            this.handleWidgetDataChange();
        }
    }

    isNewRow(widgetState) {
        if (isEmpty(this._widgetDataFromState)) return false;
        return this._widgetDataFromState[apiNameFor(DATA_IMPORT_ID)] !== widgetState[apiNameFor(DATA_IMPORT_ID)];
    }

    resetWidget() {
        this._isReadOnlyMode = false;
        this._showCancelButton= false;
        this._widgetDataFromState = undefined;
    }

    handleWidgetDataChange() {
        if (this.hasValidPaymentMethod()) {
            this.setMode(MODES.READ_ONLY);
            this.setMode(MODES.CHARGE);
            return;
        }
        this.setMode(MODES.DEACTIVATE);
    }

    setCurrentPaymentMethod() {
        this._currentPaymentMethod = this.hasPaymentMethodFieldInForm
            ? this.widgetDataFromState[apiNameFor(DATA_IMPORT_PAYMENT_METHOD)]
            : PAYMENT_METHOD_CREDIT_CARD;
    }

    shouldHandleWidgetDataChange() {
        return (this.isInBatchGiftEntry() && isNotEmpty(this.currentPaymentStatus())
            || isEmpty(this.currentPaymentStatus()));
    }

    readOnlyStatuses () {
        return [
            this.paymentTransactionStatusValues.CAPTURED,
            this.paymentTransactionStatusValues.SUBMITTED,
            this.paymentTransactionStatusValues.AUTHORIZED,
            this.paymentTransactionStatusValues.DECLINED
        ]
    }

    currentPaymentStatus () {
        return this.widgetDataFromState[apiNameFor(DATA_IMPORT_PAYMENT_STATUS_FIELD)];
    }

    hasReadOnlyStatus() {
        if (!this.isInBatchGiftEntry()) {
            return false;
        }
        return this.readOnlyStatuses().includes(this.currentPaymentStatus());
    }

    hasValidPaymentMethod() {
        if (this.isInBatchGiftEntry() && this._currentPaymentMethod === PAYMENT_METHODS.ACH) {
            return false;
        }
        return this._currentPaymentMethod === PAYMENT_METHODS.ACH
            || this._currentPaymentMethod === PAYMENT_METHOD_CREDIT_CARD;
    }

    tokenizeEventAction() {
        return this._currentPaymentMethod === PAYMENT_METHODS.ACH
            ? TOKENIZE_ACH_EVENT_ACTION
            : TOKENIZE_CREDIT_CARD_EVENT_ACTION;
    }

    requestSetPaymentMethod() {
        this._isLoading = true;
        tokenHandler.setPaymentMethod(
            this.iframe(), this._currentPaymentMethod, this.handleError,
            this.resolveSetPaymentMethod,
        ).catch(err => {
            this.handleError(err);
        });
    }

    resolveSetPaymentMethod = () => {
        this._isLoading = false;
    }

    get shouldDisplayEnableButton() {
        if (!this.hasPaymentMethodFieldInForm) return true;
        return !!(this.hasPaymentMethodFieldInForm && this.hasValidPaymentMethod());

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
        const domainInfo = await GeFormService.getOrgDomain();
        tokenHandler.setVisualforceOriginURLs(domainInfo);
    }

    /***
    * @description Registers event listeners
    */
    renderedCallback() {
        //Listens for a message from the Visualforce iframe.
        let component = this;
        tokenHandler.registerPostMessageListener(component);

        registerListener(DISABLE_TOKENIZE_WIDGET_EVENT_NAME, this.handleCriticalError, this);
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
        return !(this._hasEventDisabledWidget || this._hasUserDisabledWidget) && !this._showCancelButton;
    }

    /***
    * @description Handles a user's onclick event for disabling the widget.
    */
    handleUserDisabledWidget() {
        this.setMode(MODES.DO_NOT_CHARGE)
    }

    /***
    * @description Handles a user's onclick event for re-enabling the widget.
    */
    handleUserEnabledWidget() {
        this._isLoading = true;
        this.toggleWidget(false);
        this._hasUserDisabledWidget = false;
        this.dispatchApplicationEvent('doNotChargeState', {
            isElevateWidgetDisabled: this._hasUserDisabledWidget
        });
    }

    /***
    * @description Handles receipt of an event to disable this widget. Currently
    * used when we've submitted a payment, but BDI processing failed.
    */
    handleCriticalError(event) {
        this._disabledMessage = event.detail.message;
        this.setMode(MODES.CRITICAL_ERROR);
    }

    /***
    * @description Function enables or disables the widget based on provided args.
    *
    * @param {boolean} isDisabled: Determines whether or not the widget is disabled.
    * @param {string} message: Text to be disabled in the widgets body when disabled.
    */
    toggleWidget(isDisabled, message) {
        this._isDisabled = isDisabled;
        this.isMounted = false;
        this._disabledMessage = message || null;
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
        this._isLoading = false;
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
            [DATA_IMPORT_PAYMENT_STATUS_FIELD.fieldApiName]: this.paymentTransactionStatusValues.PENDING
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

    get qaLocatorLastFourDigits() {
        return `text Last Four Digits`;
    }

    get qaLocatorExpirationDate() {
        return `text Expiration Date`;
    }
    get qaLocatorDoNotChargeButton() {
        return `button Do Not Use Elevate`;
    }

    get qaLocatorEditPaymentInformation() {
        return `button Edit Payment Information`;
    }
    get qaLocatorCancelEditPaymentInformation() {
        return `button Cancel Edit Payment Information`;
    }
}
