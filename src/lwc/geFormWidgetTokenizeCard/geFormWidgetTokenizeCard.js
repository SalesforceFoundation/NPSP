import { api, LightningElement, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
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
import ElevateWidgetDisplay from './helpers/elevateWidgetDisplay';
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

export default class geFormWidgetTokenizeCard extends LightningElement {
    CUSTOM_LABELS = GeLabelService.CUSTOM_LABELS;

    @api paymentTransactionStatusValues = {};
    @api hasPaymentMethodFieldInForm;
    display = {};
    alert = {};
    dataImportId;
    isMounted = false;

    _displayState;
    _showSpinner = true;
    _currentPaymentMethod = undefined;
    _cardLast4;
    _cardExpirationDate;
    _widgetDataFromState;
    _readOnlyData;

    constructor() {
        super();
        this.display = new ElevateWidgetDisplay();
        this.display.init(this);
        this._displayState = this.display.currentState();
        registerListener('resetElevateWidget', this.handleElevateWidgetReset, this);
    }

    async connectedCallback() {
        const domainInfo = await GeFormService.getOrgDomain();
        tokenHandler.setVisualforceOriginURLs(domainInfo);
    }

    renderedCallback() {
        //Listens for a message from the Visualforce iframe.
        let component = this;
        tokenHandler.registerPostMessageListener(component);

        registerListener(DISABLE_TOKENIZE_WIDGET_EVENT_NAME, this.handleCriticalError, this);
    }

    disconnectedCallback() {
        unregisterListener(DISABLE_TOKENIZE_WIDGET_EVENT_NAME);
    }

    @wire(getObjectInfo, { objectApiName: apiNameFor(DATA_IMPORT) })
    dataImportObjectDescribe;

    @wire(getRecord, {
        recordId: '$dataImportId', optionalFields: [
            PAYMENT_LAST_4, PAYMENT_EXPIRATION_MONTH, PAYMENT_EXPIRATION_YEAR]
    })
    wiredDataImportRecord(response) {
        this._readOnlyData = response;
        if (response && response.data) {
            this.setReadOnlyData(response.data);
        }
        if (response && response.error) {
            this.handleError(response.error);
        }
    }

    @api
    get paymentToken() {
        return {
            payload: this.requestToken()
        }
    }

    @api
    get widgetDataFromState() {
        return this._widgetDataFromState;
    }

    set widgetDataFromState(widgetState) {
        if (this.isNewRow(widgetState)) {
            this._widgetDataFromState = undefined;
        }

        this._widgetDataFromState = widgetState;
        this.setCurrentPaymentMethod();
        if (this.shouldHandleWidgetDataChange()) {
            this.dataImportId = this._widgetDataFromState[apiNameFor(DATA_IMPORT_ID)];
            refreshApex(this._readOnlyData);
        }

        this.updateDisplayState();
    }

    get showSpinner() {
        return this._showSpinner === true;
    }

    get isCharge() {
        return this._displayState === 'charge';
    }

    get isDeactivated() {
        return this._displayState === 'deactivated';
    }

    get isReadOnly() {
        return this._displayState === 'readOnly';
    }

    get isDoNotCharge() {
        return this._displayState === 'doNotCharge';
    }

    get isCriticalError() {
        return this._displayState === 'criticalError';
    }

    get shouldDisplayEditPaymentInformation() {
        return this.isReadOnly  
            && (this.isExpiredTransaction || this.isPaymentStatusAuthorized());
    }

    get isEdit() {
        return this._displayState === 'edit';
    }

    get showCancelButton() {
        return this.isEdit 
            && !this.isExpiredTransaction
            && !this.isPaymentStatusAuthorized()
            && this.paymentStatus();
    }

    get isExpiredTransaction() {
        return this.paymentStatus() === this.paymentTransactionStatusValues.EXPIRED;
    }

    get isAuthorizedTransaction() {
        return this.paymentStatus() === this.paymentTransactionStatusValues.AUTHORIZED;
    }

    get criticalErrorMessage() {
        return this._criticalErrorMessage;
    }

    get doNotChargeMessage() {
        return this.CUSTOM_LABELS.geBodyPaymentNotProcessingTransaction;
    }

    get tokenizeCardPageUrl() {
        return tokenHandler.getTokenizeCardPageURL();
    }

    get canViewReadOnlyFields() {
        const fields = this.dataImportObjectDescribe.data.fields;
        return fields?.[apiNameFor(PAYMENT_LAST_4)] !== undefined
            && fields?.[apiNameFor(PAYMENT_EXPIRATION_MONTH)] !== undefined
            && fields?.[apiNameFor(PAYMENT_EXPIRATION_YEAR)] !== undefined;
    }

    get cardLast4() {
        return this._cardLast4;
    }

    get cardExpirationDate() {
        return this._cardExpirationDate;
    }

    get deactivatedMessage() {
        return this.CUSTOM_LABELS.geBodyPaymentNotProcessingTransaction
            + ' ' + this.CUSTOM_LABELS.psSelectValidPaymentMethod;
    }

    get shouldDisplayCardProcessingGuidanceMessage() {
        return !this.isReadOnly && this.isInBatchGiftEntry() && this.hasValidPaymentMethod() && this.isMounted;
    }

    async handleMessage(message) {
        tokenHandler.handleMessage(message);

        if (message.isReadyToMount && !this.isMounted) {
            this.requestMount();
        }
    }

    requestParentNullPaymentFieldsInFormState() {
        this.dispatchApplicationEvent('nullPaymentFieldsInFormState', {});
    }

    isNewRow(widgetState) {
        if (isEmpty(this._widgetDataFromState)) return false;
        return this._widgetDataFromState[apiNameFor(DATA_IMPORT_ID)] !== widgetState[apiNameFor(DATA_IMPORT_ID)];
    }

    updateDisplayState() {
        if (this.isInBatchGiftEntry()) {
            this.updateDisplayStateWhenInBatchGiftEntry();
        } else {
            this.updateDisplayStateWhenInSingleGiftEntry();
        }
    }

    updateDisplayStateWhenInBatchGiftEntry() {
        if (this.isPaymentStatusAuthorized() && !this.isPaymentMethodCreditCard()) {
            this.display.transitionTo('resetToDeactivated');
        }

        if (this.isPaymentStatusAuthorized() && this.isPaymentMethodCreditCard()) {
            this.display.transitionTo('readOnly');
        } else if (this.isPaymentMethodCreditCard()) {
            this.display.transitionTo('charge');
        } else {
            this.display.transitionTo('deactivated');
        }
    }

    updateDisplayStateWhenInSingleGiftEntry() {
        if (!this.hasPaymentMethodFieldInForm) {
            this.display.transitionTo('charge');
            if (this.isMounted) {
                this.requestSetPaymentMethod(PAYMENT_METHOD_CREDIT_CARD);
            }
        } else if ((this.isPaymentMethodCreditCard() || this.isPaymentMethodAch())) {
            this.display.transitionTo('charge');
            if (this.isMounted) {
                this.requestSetPaymentMethod(this._currentPaymentMethod);
            }
        } else {
            this.display.transitionTo('deactivated');
        }
    }

    handleUserDoNotCharge() {
        this.dispatchApplicationEvent('doNotChargeState', {
            isElevateWidgetDisabled: true
        });

        this.display.transitionTo('userOriginatedDoNotCharge');
    }

    handleUserEnterPaymentInformation() {
        this.dispatchApplicationEvent('doNotChargeState', {
            isElevateWidgetDisabled: false
        });

        if (this.isInBatchGiftEntry() && !this.isPaymentMethodCreditCard()) {
            this.display.transitionTo('userOriginatedDeactivated');
        } else {
            this.display.transitionTo('userOriginatedCharge');
        }
    }

    handleUserEditExpired() {
        this.dispatchApplicationEvent('doNotChargeState', {
            isElevateWidgetDisabled: false
        });

        this.display.transitionTo('editExpiredTransaction');
    }

    handleUserCancelEdit() {
        this.display.transitionTo('readOnly');
    }

    isPaymentStatusAuthorized() {
        return this._widgetDataFromState[apiNameFor(DATA_IMPORT_PAYMENT_STATUS_FIELD)]
            === this.paymentTransactionStatusValues.AUTHORIZED;
    }

    isPaymentMethodCreditCard() {
        return this.paymentMethod() === PAYMENT_METHOD_CREDIT_CARD;
    }

    isPaymentMethodAch() {
        return this.paymentMethod() === PAYMENT_METHODS.ACH;
    }

    paymentMethod() {
        return this._widgetDataFromState[apiNameFor(DATA_IMPORT_PAYMENT_METHOD)];
    }

    refreshDisplayState() {
        this._displayState = this.display.currentState();
    }

    handleElevateWidgetReset() {
        this.clearError();
        this.clearPaymentInformation();
        this.dismount();

        if (this.isInBatchGiftEntry) {
            if (this.isDoNotCharge) {
                this.resetForBatchFromDoNotCharge();
            } else {
                this.resetForBatch();
            }
        } else {
            this.updateDisplayState();
        }
    }

    resetForBatch() {
        if (this.isPaymentMethodCreditCard()) {
            this.display.transitionTo('resetToCharge');
        } else {
            this.display.transitionTo('resetToDeactivated');
        }
    }

    resetForBatchFromDoNotCharge() {
        if (this.isPaymentMethodCreditCard()) {
            this.display.transitionTo('userOriginatedCharge');
        }
    }

    clearPaymentInformation() {
        this._cardLast4 = undefined;
        this._cardExpirationDate = undefined;
    }

    loadingOn() {
        this._showSpinner = true;
    }

    loadingOff() {
        this._showSpinner = false;
    }

    dismount() {
        this.clearError();
        this.isMounted = false;
    }

    isInBatchGiftEntry() {
        return this.widgetDataFromState &&
            this.widgetDataFromState[apiNameFor(DATA_IMPORT_PARENT_BATCH_LOOKUP)] !== undefined;
    }

    iframe() {
        return this.template.querySelector(`[data-id='${this.CUSTOM_LABELS.commonPaymentServices}']`);
    }

    isPaymentCaptured() {
        return this.paymentStatus() === this.paymentTransactionStatusValues.CAPTURED;
    }

    setReadOnlyData(data) {
        this._cardLast4 = getFieldValue(data, PAYMENT_LAST_4);
        const hasExpiryDateValue =
            getFieldValue(data, PAYMENT_EXPIRATION_MONTH)
            && getFieldValue(data, PAYMENT_EXPIRATION_YEAR);
        if (hasExpiryDateValue) {
            this._cardExpirationDate =
                getFieldValue(data, PAYMENT_EXPIRATION_MONTH)
                + '/' +
                getFieldValue(data, PAYMENT_EXPIRATION_YEAR);
        }
        if (this._cardLast4 && this._cardExpirationDate) {
            this.display.transitionTo('readOnly');
        }
    }

    setCurrentPaymentMethod() {
        this._currentPaymentMethod = this.hasPaymentMethodFieldInForm
            ? this.widgetDataFromState[apiNameFor(DATA_IMPORT_PAYMENT_METHOD)]
            : PAYMENT_METHOD_CREDIT_CARD;
    }

    shouldHandleWidgetDataChange() {
        return (this.isInBatchGiftEntry() && isNotEmpty(this.paymentStatus())
            || isEmpty(this.paymentStatus()));
    }

    readOnlyStatuses() {
        return [
            this.paymentTransactionStatusValues.CAPTURED,
            this.paymentTransactionStatusValues.SUBMITTED,
            this.paymentTransactionStatusValues.AUTHORIZED,
            this.paymentTransactionStatusValues.DECLINED
        ]
    }

    paymentStatus() {
        return this.widgetDataFromState && this.widgetDataFromState[apiNameFor(DATA_IMPORT_PAYMENT_STATUS_FIELD)];
    }

    hasReadOnlyStatus() {
        if (!this.isInBatchGiftEntry()) {
            return false;
        }
        return this.readOnlyStatuses().includes(this.paymentStatus());
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
        this._showSpinner = true;
        tokenHandler.setPaymentMethod(
            this.iframe(), this._currentPaymentMethod, this.handleError,
            this.resolveSetPaymentMethod,
        ).catch(err => {
            this.handleError(err);
        });
    }

    resolveSetPaymentMethod = () => {
        this._showSpinner = false;
    }

    /***
    * @description Handles receipt of an event to disable this widget. Currently
    * used when we've submitted a payment, but BDI processing failed.
    */
    handleCriticalError(event) {
        this._criticalErrorMessage = event.detail.message;
        this.display.transitionTo('criticalError');
    }

    requestMount() {
        tokenHandler.mount(this.iframe(), this._currentPaymentMethod, this.handleError, this.resolveMount);
    }

    resolveMount = () => {
        this._showSpinner = false;
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

    populateAchParametersForIndividual(achTokenizeParameters) {
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
        this.display.transitionTo('loading');
        this.display.transitionTo('charge');
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
