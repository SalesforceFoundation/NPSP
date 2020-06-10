/*******************************************************************************
* @description Server / Platform  Imports
*/
import { LightningElement, api, track, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import { fireEvent } from 'c/pubsubNoPageRef';
import { HttpRequestError, CardChargedBDIError } from 'c/utilCustomErrors';
import { isNotEmpty, validateJSONString, format, getNamespace } from 'c/utilCommon';
import { getCurrencyLowestCommonDenominator } from 'c/utilNumberFormatter';
import { handleError } from "c/utilTemplateBuilder";
import GeLabelService from 'c/geLabelService';
import geBatchGiftsHeader from '@salesforce/label/c.geBatchGiftsHeader';
import geBatchGiftsExpectedTotalsMessage
    from '@salesforce/label/c.geBatchGiftsExpectedTotalsMessage';
import geBatchGiftsExpectedCountOrTotalMessage
    from '@salesforce/label/c.geBatchGiftsExpectedCountOrTotalMessage';
import saveAndDryRunDataImport from '@salesforce/apex/GE_GiftEntryController.saveAndDryRunDataImport';
import sendPurchaseRequest from '@salesforce/apex/GE_GiftEntryController.sendPurchaseRequest';
import upsertDataImport from '@salesforce/apex/GE_GiftEntryController.upsertDataImport';
import submitDataImportToBDI from '@salesforce/apex/GE_GiftEntryController.submitDataImportToBDI';
import getPaymentTransactionStatusValues from '@salesforce/apex/GE_PaymentServices.getPaymentTransactionStatusValues';

/*******************************************************************************
* @description Schema imports
*/
import DATA_IMPORT_BATCH_OBJECT from '@salesforce/schema/DataImportBatch__c';
import BATCH_NAME
    from '@salesforce/schema/DataImportBatch__c.Name';
import EXPECTED_COUNT_OF_GIFTS
    from '@salesforce/schema/DataImportBatch__c.Expected_Count_of_Gifts__c';
import EXPECTED_TOTAL_BATCH_AMOUNT
    from '@salesforce/schema/DataImportBatch__c.Expected_Total_Batch_Amount__c';
import BATCH_TABLE_COLUMNS_FIELD from '@salesforce/schema/DataImportBatch__c.Batch_Table_Columns__c';
import REQUIRE_TOTAL_MATCH from '@salesforce/schema/DataImportBatch__c.RequireTotalMatch__c';
import DI_PAYMENT_AUTHORIZE_TOKEN_FIELD from '@salesforce/schema/DataImport__c.Payment_Authorization_Token__c';
import DI_PAYMENT_ELEVATE_ID from '@salesforce/schema/DataImport__c.Payment_Elevate_ID__c';
import DI_PAYMENT_CARD_NETWORK from '@salesforce/schema/DataImport__c.Payment_Card_Network__c';
import DI_PAYMENT_EXPIRATION_YEAR from '@salesforce/schema/DataImport__c.Payment_Card_Expiration_Year__c';
import DI_PAYMENT_EXPIRATION_MONTH from '@salesforce/schema/DataImport__c.Payment_Card_Expiration_Month__c';
import DI_PAYMENT_GATEWAY_ID from '@salesforce/schema/DataImport__c.Payment_Gateway_ID__c';
import DI_PAYMENT_GATEWAY_TRANSACTION_ID from '@salesforce/schema/DataImport__c.Payment_Gateway_Payment_ID__c';
import DI_PAYMENT_AUTHORIZED_AT from '@salesforce/schema/DataImport__c.Payment_Authorized_UTC_Timestamp__c';
import DI_PAYMENT_LAST_4 from '@salesforce/schema/DataImport__c.Payment_Card_Last_4__c';
import DI_PAYMENT_STATUS_FIELD from '@salesforce/schema/DataImport__c.Payment_Status__c';
import DI_PAYMENT_DECLINED_REASON_FIELD from '@salesforce/schema/DataImport__c.Payment_Declined_Reason__c';
import DI_PAYMENT_METHOD_FIELD from '@salesforce/schema/DataImport__c.Payment_Method__c';
import DI_DONATION_AMOUNT_FIELD from '@salesforce/schema/DataImport__c.Donation_Amount__c';
import DI_DONATION_CAMPAIGN_NAME_FIELD from '@salesforce/schema/DataImport__c.Donation_Campaign_Name__c';

/*******************************************************************************
* @description Constants
*/
import { LABEL_NEW_LINE, HTTP_CODES } from 'c/geConstants';
const PAYMENT_STATUS__C = DI_PAYMENT_STATUS_FIELD.fieldApiName;
const PAYMENT_DECLINED_REASON__C = DI_PAYMENT_DECLINED_REASON_FIELD.fieldApiName;
const PAYMENT_AUTHORIZE_TOKEN__C = DI_PAYMENT_AUTHORIZE_TOKEN_FIELD.fieldApiName;
const PAYMENT_METHOD__C = DI_PAYMENT_METHOD_FIELD.fieldApiName;
const PAYMENT_ELEVATE_ID = DI_PAYMENT_ELEVATE_ID.fieldApiName;
const PAYMENT_CARD_NETWORK = DI_PAYMENT_CARD_NETWORK.fieldApiName;
const PAYMENT_LAST_4 = DI_PAYMENT_LAST_4.fieldApiName;
const PAYMENT_EXPIRATION_MONTH = DI_PAYMENT_EXPIRATION_MONTH.fieldApiName;
const PAYMENT_EXPIRATION_YEAR = DI_PAYMENT_EXPIRATION_YEAR.fieldApiName;
const PAYMENT_GATEWAY_ID = DI_PAYMENT_GATEWAY_ID.fieldApiName;
const PAYMENT_TRANSACTION_ID = DI_PAYMENT_GATEWAY_TRANSACTION_ID.fieldApiName;
const PAYMENT_AUTHORIZED_AT = DI_PAYMENT_AUTHORIZED_AT.fieldApiName;
const DONATION_AMOUNT__C = DI_DONATION_AMOUNT_FIELD.fieldApiName;
const DONATION_CAMPAIGN_NAME__C = DI_DONATION_CAMPAIGN_NAME_FIELD.fieldApiName;
const BDI_DATA_IMPORT_PAGE = 'BDI_DataImport';

export default class GeGiftEntryFormApp extends NavigationMixin(LightningElement) {

    // Expose custom labels to template
    CUSTOM_LABELS = GeLabelService.CUSTOM_LABELS;

    @api recordId;
    @api sObjectName;

    @track isPermissionError;
    @track loadingText = this.CUSTOM_LABELS.geTextSaving;

    dataImportRecord = {};
    errorCallback;
    isFailedPurchase = false;
    _isCreditCardWidgetInDoNotChargeState = false;

    PAYMENT_TRANSACTION_STATUS_ENUM;

    namespace;
    count;
    total;

    get isBatchMode() {
        return this.sObjectName &&
            this.sObjectName === DATA_IMPORT_BATCH_OBJECT.objectApiName;
    }

    constructor() {
        super();
        this.namespace = getNamespace(DATA_IMPORT_BATCH_OBJECT.objectApiName);
    }

    connectedCallback() {
        getPaymentTransactionStatusValues()
            .then(response => {
                this.PAYMENT_TRANSACTION_STATUS_ENUM = Object.freeze(JSON.parse(response));
            });
    }

    /*******************************************************************************
    * @description Receives a 'submit' event from geFormRenderer and proceeds down
    * the Batch or Single save paths depending on the current app mode.
    *
    * @param {object} event: Custom Event containing the Data Import record and
    * potentially other objects (booleans, callbacks, etc).
    */
    handleSubmit(event) {
        // Callback received from geFormRenderer. Provides functions that
        // toggle the form save button, toggle the lightning spinner, and displays aura exceptions.
        this.errorCallback = event.detail.errorCallback;

        try {
            if (this.isBatchMode) {
                this.batchGiftSubmit(event);
            } else {
                this.singleGiftSubmit(event);
            }
        } catch (error) {
            this.errorCallback(error);
        }
    }

    /*******************************************************************************
    * @description Handles a batch gift entry submit. Saves a Data Import record,
    * runs dry run, and renders the Data Import in the Batch Gift Table.
    *
    * @param {object} event: Custom Event containing the Data Import record and a
    * callback for handling and displaying errors in the form.
    */
    batchGiftSubmit(event) {
        const table = this.template.querySelector('c-ge-batch-gift-entry-table');
        this.dataImportRecord = event.detail.dataImportRecord;
        saveAndDryRunDataImport({batchId: this.recordId, dataImport: this.dataImportRecord})
            .then((result) => {
                let dataImportModel = JSON.parse(result);
                Object.assign(dataImportModel.dataImportRows[0],
                    dataImportModel.dataImportRows[0].record);
                table.upsertData(dataImportModel.dataImportRows[0], 'Id');
                this.count = dataImportModel.totalCountOfRows;
                this.total = dataImportModel.totalRowAmount;
                event.detail.success(); //Re-enable the Save button
            })
            .catch(error => {
                event.detail.error(error);
            });
    }

    /*******************************************************************************
    * @description Handles a single gift entry submit. Saves a Data Import record,
    * makes an elevate payment if needed, and processes the Data Import through
    * BDI.
    *
    * @param {object} event: Custom Event containing the Data Import record and a
    * callback for handling and displaying errors in the form.
    */
    singleGiftSubmit = async (event) => {
        let { inMemoryDataImport } = event.detail;
        this.hasUserSelectedDonation = event.detail.hasUserSelectedDonation;
        this._isCreditCardWidgetInDoNotChargeState = event.detail.isWidgetInDoNotChargeState;
        try {
            await this.saveDataImport(inMemoryDataImport);

            const hasPaymentToProcess = this.dataImportRecord[PAYMENT_AUTHORIZE_TOKEN__C];
            if (isNotEmpty(hasPaymentToProcess)) {
                await this.processPayment();
            }

            if (!this.isFailedPurchase || this._isCreditCardWidgetInDoNotChargeState) {
                await this.processDataImport();
            }
        } catch (error) {
            this.errorCallback(error);
        }
    }

    /*******************************************************************************
    * @description Upserts the provided data import record. Attempts to retrieve
    * an Elevate token for a purchase call if needed.
    *
    * @param {object} inMemoryDataImport: DataImport__c object built from the form
    * fields.
    *
    * @return {object} dataImportRecord: A DataImport__c record
    */
    saveDataImport = async (inMemoryDataImport) => {
        if (this.dataImportRecord.Id) {
            this.loadingText = this.CUSTOM_LABELS.geTextUpdating;
            inMemoryDataImport = this.prepareInMemoryDataImportForUpdate(inMemoryDataImport);
        } else {
            this.loadingText = this.CUSTOM_LABELS.geTextSaving;
        }

        this.dataImportRecord = await upsertDataImport({ dataImport: inMemoryDataImport });
    };

    /*******************************************************************************
    * @description Re-apply Data Import id and relevant payment/elevate fields.
    * The inMemoryDataImport is built new from the form on every save click. We
    * need to catch it up with the correct id to make sure we update instead of
    * inserting a new record on re-save attempts.
    *
    * @param {object} inMemoryDataImport: DataImport__c object built from the form
    * fields.
    *
    * @return {object} inMemoryDataImport: DataImport__c object built from the form
    * fields.
    */
    prepareInMemoryDataImportForUpdate(inMemoryDataImport) {
        inMemoryDataImport.Id = this.dataImportRecord.Id;
        inMemoryDataImport[PAYMENT_METHOD__C] = this.dataImportRecord[PAYMENT_METHOD__C];
        inMemoryDataImport[PAYMENT_STATUS__C] =
            this._isCreditCardWidgetInDoNotChargeState ? '' : this.dataImportRecord[PAYMENT_STATUS__C];
        inMemoryDataImport[PAYMENT_DECLINED_REASON__C] =
            this._isCreditCardWidgetInDoNotChargeState ? '' : this.dataImportRecord[PAYMENT_DECLINED_REASON__C];
        inMemoryDataImport[PAYMENT_AUTHORIZE_TOKEN__C] =
            this._isCreditCardWidgetInDoNotChargeState ? '' : this.dataImportRecord[PAYMENT_AUTHORIZE_TOKEN__C];
        return inMemoryDataImport;
    }

    /*******************************************************************************
    * @description Method attempts to make a purchase call to Payment
    * Services. Immediately attempts to the charge the card provided in the Payment
    * Services iframe (GE_TokenizeCard).
    */
    processPayment = async () => {
        this.loadingText = this.CUSTOM_LABELS.geTextChargingCard;

        const isReadyToCharge = await this.checkPaymentTransactionStatus(this.dataImportRecord[PAYMENT_STATUS__C]);
        if (isReadyToCharge) {

            const purchaseResponse = await this.makePurchaseCall();
            if (purchaseResponse) {

                let errors = this.processPurchaseResponse(purchaseResponse);

                this.dataImportRecord = await upsertDataImport({ dataImport: this.dataImportRecord });

                if (isNotEmpty(errors)) {
                    this.isFailedPurchase = true;
                    this.handleFailedPurchaseCall(purchaseResponse);
                } else {
                    this.isFailedPurchase = false;
                }
            }
        }
    }

    /*******************************************************************************
     * @description Updates the dataImportRecord fields with response values from
     * payment services.
     *
     * @param {object} response The response object from payment services returned when
     * purchase call is made.
     *
     * @return {string} A concatenated string of errors returned from the purchase call to
     * payment services
     */
    processPurchaseResponse(response) {
        let errors = '';
        let responseBody = response.body;

        this.dataImportRecord[PAYMENT_STATUS__C] = this.getPaymentStatus(response);
        this.dataImportRecord[PAYMENT_ELEVATE_ID] = responseBody.id;

        if (response.statusCode === HTTP_CODES.Created) {

            if (isNotEmpty(responseBody.cardData)) {
                this.dataImportRecord[PAYMENT_CARD_NETWORK] = responseBody.cardData.brand;
                this.dataImportRecord[PAYMENT_LAST_4] = responseBody.cardData.last4;
                this.dataImportRecord[PAYMENT_EXPIRATION_MONTH] = responseBody.cardData.expirationMonth;
                this.dataImportRecord[PAYMENT_EXPIRATION_YEAR] = responseBody.cardData.expirationYear;
            }
            this.dataImportRecord[PAYMENT_DECLINED_REASON__C] = '';
            this.dataImportRecord[PAYMENT_GATEWAY_ID] = responseBody.gatewayId;
            this.dataImportRecord[PAYMENT_TRANSACTION_ID] = responseBody.gatewayTransactionId;
            this.dataImportRecord[PAYMENT_AUTHORIZED_AT] = responseBody.authorizedAt;

        } else {
            this.dataImportRecord[PAYMENT_DECLINED_REASON__C] =
                this.getPaymentDeclinedReason(response);

            errors = this.getFailedPurchaseMessage(response);
        }

        return errors;
    }

    /*******************************************************************************
    * @description Method attempts to handle a failed purchase call response.
    *
    * @param {object} purchaseResponse: Response from
    * GE_GiftEntryController.sendPurchaseRequest()
    */
    handleFailedPurchaseCall(purchaseResponse) {
        const hasPurchaseCallValidationErrors = purchaseResponse.statusCode === HTTP_CODES.Bad_Request;
        if (hasPurchaseCallValidationErrors) {
            this.catchPurchaseCallValidationErrors(purchaseResponse);
        } else {
            this.throwHttpRequestError(purchaseResponse);
        }
    }

    /*******************************************************************************
    * @description Dispatch an event to the form renderer whenever we have a field
    * validation error from the purchase call. Various http 400 errors. Thus far
    * the body of the response from these calls have had an errors array property.
    *
    * @param {object} purchaseResponse: Response from
    * GE_GiftEntryController.sendPurchaseRequest()
    */
    catchPurchaseCallValidationErrors(purchaseResponse) {
        let errors = this.getFailedPurchaseMessage(purchaseResponse);
        let labelReplacements = [this.CUSTOM_LABELS.commonPaymentServices, errors];
        let formattedErrorResponse = format(this.CUSTOM_LABELS.gePaymentProcessError, labelReplacements);

        // We use the hex value for line feed (new line) 0x0A
        let splitErrorResponse = formattedErrorResponse.split(LABEL_NEW_LINE);

        const form = this.template.querySelector('c-ge-form-renderer');
        form.showSpinner = false;
        fireEvent(null, 'paymentError', {
            error: {
                message: splitErrorResponse,
                isObject: true
            }
        });
    }

    /*******************************************************************************
    * @description Throw an HttpRequestError for non-400 and non-200 responses from
    * a purchase call.
    *
    * @param {object} purchaseResponse: Response from
    * GE_GiftEntryController.sendPurchaseRequest()
    */
    throwHttpRequestError(purchaseResponse) {
        const errorMessage =
            this.CUSTOM_LABELS.commonPaymentServices + ': ' +
            this.getFailedPurchaseMessage(purchaseResponse)

        throw new HttpRequestError(
            errorMessage,
            purchaseResponse.status,
            purchaseResponse.statusCode);
    }

    /*******************************************************************************
    * @description Method checks the current payment transaction's status and
    * returns true if the card is in a 'chargeable' status.
    *
    * @param {string} paymentStatus: Payment transaction status
    *
    * @return {boolean}: True if card is in a 'chargeable' status
    */
    checkPaymentTransactionStatus = async (paymentStatus) => {

        switch (paymentStatus) {
            case this.PAYMENT_TRANSACTION_STATUS_ENUM.PENDING: return true;
            case this.PAYMENT_TRANSACTION_STATUS_ENUM.AUTHORIZED: return false;
            case this.PAYMENT_TRANSACTION_STATUS_ENUM.CANCELED: return false;
            case this.PAYMENT_TRANSACTION_STATUS_ENUM.CAPTURED: return false;
            case this.PAYMENT_TRANSACTION_STATUS_ENUM.DECLINED: return true;
            case this.PAYMENT_TRANSACTION_STATUS_ENUM.NONRETRYABLEERROR: return false;
            case this.PAYMENT_TRANSACTION_STATUS_ENUM.RETRYABLEERROR: return true;
            case this.PAYMENT_TRANSACTION_STATUS_ENUM.REFUNDISSUED: return false;
            default: return true;
        }
    }

    /*******************************************************************************
    * @description Posts an http request through the `sendPurchaseRequest` apex
    * method and parses the response.
    *
    * @return {object} response: An http response object
    */
    makePurchaseCall = async () => {
        let purchaseResponseString = await sendPurchaseRequest({
            requestBodyParameters: this.buildPurchaseRequestBodyParameters(),
            dataImportRecordId: this.dataImportRecord.Id
        });
        let response = JSON.parse(purchaseResponseString);
        if (response.body && validateJSONString(response.body)) {
            response.body = JSON.parse(response.body);
        }

        return response;
    }

    /*******************************************************************************
    * @description Builds parts of the purchase request body that requires data
    * from the Data Import record upfront. We pass this into the `sendPurchaseRequest`
    * method and is eventually merged in with the rest of the purchase request body.
    *
    * @return {object}: Object that we can deserialize and apply to the purchase
    * request body in apex.
    */
    buildPurchaseRequestBodyParameters() {
        const { firstName, lastName } = this.getCardholderNames();
        const metadata = {
            campaignCode: this.dataImportRecord[DONATION_CAMPAIGN_NAME__C]
        };

        return JSON.stringify({
            amount: getCurrencyLowestCommonDenominator(this.dataImportRecord[DONATION_AMOUNT__C]),
            email: 'test@test.test',
            firstName: firstName,
            lastName: lastName,
            metadata: metadata,
            paymentMethodToken: this.dataImportRecord[PAYMENT_AUTHORIZE_TOKEN__C],
        });
    }

    /*******************************************************************************
    * @description Queries for the geFormRenderer component and retrieves the
    * fabricated cardholder names object.
    *
    * @return {object}: Object containing firstName, lastName, and accountName
    * from the form.
    */
    getCardholderNames() {
        const renderer = this.template.querySelector('c-ge-form-renderer');
        return renderer.getCardholderNames();
    }

    /*******************************************************************************
    * @description Get the value for DataImport__c.Payment_Status__c from the
    * purchase call response.
    *
    * @param {object} response: Http response object
    *
    * @return {string}: Status of the payment charge request
    */
    getPaymentStatus(response) {
        return response.body.status || response.status || this.CUSTOM_LABELS.commonUnknownError;
    }

    /*******************************************************************************
    * @description Get the value for DataImport__c.Payment_Declined_Reason__c from
    * the purchase call response.
    *
    * @param {object} response: Http response object
    *
    * @return {string}: Reason the payment was declined
    */
    getPaymentDeclinedReason(response) {
        const isSuccessfulPurchase = response.statusCode === HTTP_CODES.Created;
        return isSuccessfulPurchase ? null : this.getFailedPurchaseMessage(response);
    }

    /*******************************************************************************
    * @description Get the message or errors from a failed purchase call.
    *
    * @param {object} response: Http response object
    *
    * @return {string}: Message from a failed purchase call response
    */
    getFailedPurchaseMessage(response) {
        // For some reason the key in the body object for 'Message'
        // in the response we receive from Elevate is capitalized.
        // Also checking for lowercase M in message in case they fix it.
        return response.body.Message ||
            response.body.message ||
            response.errorMessage ||
            JSON.stringify(response.body.errors.map(error => error.message)) ||
            this.CUSTOM_LABELS.commonUnknownError;
    }

    /*******************************************************************************
    * @description Sends the Data Import into BDI for processing and navigates to
    * the opportunity record detail page on success.
    */
    processDataImport = async () => {
        this.loadingText = this.CUSTOM_LABELS.geTextProcessing;

        submitDataImportToBDI({ dataImport: this.dataImportRecord, updateGift: this.hasUserSelectedDonation })
            .then(opportunityId => {
                this.loadingText = this.CUSTOM_LABELS.geTextNavigateToOpportunity;
                this.navigateToRecordPage(opportunityId);
            })
            .catch(error => {
                this.catchBDIProcessingError(error);
            });
    }

    /*******************************************************************************
    * @description Catches a BDI processing error and transforms the error into
    * something we can ingest in the form renderer.
    */
    catchBDIProcessingError(error) {
        const hasPaymentBeenCaptured = this.checkForCapturedPayment();
        if (hasPaymentBeenCaptured) {
            error = new CardChargedBDIError(error);
        }
        this.errorCallback(error);
    }

    /*******************************************************************************
    * @description Method checks to see if the current data import record has a
    * successful payment transaction.
    *
    * TODO: Update to check for the elevate transaction id in the future.
    */
    checkForCapturedPayment() {
        return this.dataImportRecord[PAYMENT_STATUS__C] === this.PAYMENT_TRANSACTION_STATUS_ENUM.CAPTURED &&
            isNotEmpty(this.dataImportRecord[PAYMENT_AUTHORIZE_TOKEN__C]);
    }

    handleSectionsRetrieved(event) {
        const formSections = event.target.sections;
        const table = this.template.querySelector('c-ge-batch-gift-entry-table');
        table.handleSectionsRetrieved(formSections);
    }

    handleBatchDryRun() {
        //toggle the spinner on the form
        const form = this.template.querySelector('c-ge-form-renderer');
        const toggleSpinner = function () {
            form.showSpinner = !form.showSpinner
        };
        form.showSpinner = true;

        const table = this.template.querySelector('c-ge-batch-gift-entry-table');
        table.runBatchDryRun(toggleSpinner);
    }

    handleLoadData(event) {
        const form = this.template.querySelector('c-ge-form-renderer');
        form.reset();
        form.load(event.detail);
    }

    handlePermissionErrors() {
        this.isPermissionError = true;
    }
    handleEditBatch() {
        this.dispatchEvent(new CustomEvent('editbatch'));
    }

    handleToggleModal(event) {
        this.dispatchEvent(new CustomEvent('togglemodal', { detail: event.detail }));
    }

    navigateToRecordPage(recordId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                actionName: 'view'
            }
        });
    }

    get expectedCountOfGifts() {
        return getFieldValue(this.batch.data, EXPECTED_COUNT_OF_GIFTS);
    }

    get expectedTotalBatchAmount() {
        return getFieldValue(this.batch.data, EXPECTED_TOTAL_BATCH_AMOUNT);
    }

    get batchName() {
        return getFieldValue(this.batch.data, BATCH_NAME);
    }

    get userDefinedBatchTableColumnNames() {
        const batchTableColumns = validateJSONString(
            getFieldValue(this.batch.data, BATCH_TABLE_COLUMNS_FIELD)
        );
        if (batchTableColumns) return batchTableColumns;
        return [];
    }

    get giftsTableTitle() {
        return format(geBatchGiftsHeader, [this.batchName]);
    }

    @wire(getRecord, {
        recordId: '$recordId',
        fields: [BATCH_NAME, EXPECTED_COUNT_OF_GIFTS,
            EXPECTED_TOTAL_BATCH_AMOUNT,
            REQUIRE_TOTAL_MATCH,
            BATCH_TABLE_COLUMNS_FIELD]
    })
    batch;

    handleProcessBatch() {
        if (this.isProcessable) {
            this.navigateToDataImportProcessingPage();
        } else {
            if (this.expectedCountOfGifts && this.expectedTotalBatchAmount) {
                handleError(geBatchGiftsExpectedTotalsMessage);
            } else {
                handleError(geBatchGiftsExpectedCountOrTotalMessage);
            }
        }
    }

    navigateToDataImportProcessingPage() {
        let url = '/apex/' + this.bdiDataImportPageName +
            '?batchId=' + this.recordId + '&retURL=' + this.recordId;

        this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: url
                }
            },
            true
        );
    }

    get bdiDataImportPageName() {
        return this.namespace ?
            `${this.namespace}__${BDI_DATA_IMPORT_PAGE}` :
            BDI_DATA_IMPORT_PAGE;
    };

    get requireTotalMatch() {
        return getFieldValue(this.batch.data, REQUIRE_TOTAL_MATCH);
    }

    get totalsMatch() {
        if (this.expectedCountOfGifts && this.expectedTotalBatchAmount) {
            return this.countMatches && this.amountMatches;
        } else if (this.expectedCountOfGifts) {
            return this.countMatches;
        } else if (this.expectedTotalBatchAmount) {
            return this.amountMatches;
        }
    }

    get countMatches() {
        return this.count === this.expectedCountOfGifts;
    }

    get amountMatches() {
        return this.total === this.expectedTotalBatchAmount;
    }

    get isProcessable() {
        if (this.totalsMatch) {
            return true;
        } else if (this.requireTotalMatch) {
            return false;
        } else {
            return true;
        }
    }

    handleDelete(event) {
        this.count--;
        this.total = this.total - event.detail.amount;
    }

    handleCountChanged(event) {
        this.count = event.detail.value;
    }

    handleTotalChanged(event) {
        this.total = event.detail.value;
    }

}
