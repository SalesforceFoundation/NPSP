import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import saveAndDryRunDataImport from '@salesforce/apex/GE_GiftEntryController.saveAndDryRunDataImport';
import createTransaction from '@salesforce/apex/GE_GiftEntryController.createTransaction';
import upsertDataImport from '@salesforce/apex/GE_GiftEntryController.upsertDataImport';
import processDataImport from '@salesforce/apex/GE_GiftEntryController.processDataImport';

//import GeFormService from 'c/geFormService';
import { showToast } from 'c/utilTemplateBuilder';
import { deepClone } from 'c/utilCommon';
import { registerListener, unregisterListener } from 'c/pubsubNoPageRef';
import GeLabelService from 'c/geLabelService';

import DATA_IMPORT_BATCH_OBJECT from '@salesforce/schema/DataImportBatch__c';
import DI_PAYMENT_AUTHORIZE_TOKEN_FIELD from '@salesforce/schema/DataImport__c.Payment_Authorization_Token__c';
import DI_PAYMENT_STATUS_FIELD from '@salesforce/schema/DataImport__c.Payment_Status__c';
import DI_PAYMENT_DECLINED_REASON_FIELD from '@salesforce/schema/DataImport__c.Payment_Declined_Reason__c';
import DI_PAYMENT_METHOD_FIELD from '@salesforce/schema/DataImport__c.Payment_Method__c';

const PAYMENT_STATUS__C = DI_PAYMENT_STATUS_FIELD.fieldApiName;
const PAYMENT_DECLINED_REASON__C = DI_PAYMENT_DECLINED_REASON_FIELD.fieldApiName;
const PAYMENT_AUTHORIZE_TOKEN__C = DI_PAYMENT_AUTHORIZE_TOKEN_FIELD.fieldApiName;
const PAYMENT_METHOD__C = DI_PAYMENT_METHOD_FIELD.fieldApiName;
const CAPTURED = 'CAPTURED';
const TOKENIZE_TIMEOUT = 10000; // 10 seconds, long enough for cold starts?
const PAYMENT_TRANSACTION_STATUS_ENUM = Object.freeze({
    PENDING: 'PENDING',
    AUTHORIZED: 'AUTHORIZED',
    CANCELED: 'CANCELED',
    CAPTURED: 'CAPTURED',
    DECLINED: 'DECLINED',
    NONRETRYABLEERROR: 'NONRETRYABLEERROR',
    RETRYABLEERROR: 'RETRYABLEERROR',
    REFUNDISSUED: 'REFUNDISSUED'
});

export default class GeGiftEntryFormApp extends NavigationMixin(LightningElement) {
    @api recordId;
    @api sObjectName;

    @track isPermissionError;
    @track loadingText = 'Saving data import...';

    previouslySavedDataImport = {};
    tokenPromise;

    CUSTOM_LABELS = GeLabelService.CUSTOM_LABELS;

    connectedCallback() {
        registerListener('tokenRequested', this.handleTokenRequested, this);
    }

    disconnectedCallback() {
        unregisterListener('tokenRequested', this.handleTokenRequested, this);
    }

    get isBatchMode() {
        return this.sObjectName &&
            this.sObjectName === DATA_IMPORT_BATCH_OBJECT.objectApiName;
    }

    handleTokenRequested() {
        this.tokenPromise = new Promise((resolve, reject) => {
            registerListener('tokenResponse', message => {
                if(message.error) {
                    reject(message);
                } else if(message.token) {
                    resolve(message.token);
                }
            }, this);
            setTimeout(() => {
                reject('Request timed out');
                unregisterListener('tokenResponse', resolve, this);
            }, TOKENIZE_TIMEOUT);
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
        const { errorCallback } = event.detail;

        try {
            if (this.isBatchMode) {
                this.batchGiftSubmit(event);
            } else {
                this.singleGiftSubmit(event);
            }
        } catch (error) {
            errorCallback(error);
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
        const dataImportRecord = event.detail.dataImportRecord;
        saveAndDryRunDataImport({batchId: this.recordId, dataImport: dataImportRecord})
            .then((result) => {
                let dataImportModel = JSON.parse(result);
                Object.assign(dataImportModel.dataImportRows[0],
                    dataImportModel.dataImportRows[0].record);
                table.upsertData(dataImportModel.dataImportRows[0], 'Id');
                table.setTotalCount(dataImportModel.totalCountOfRows);
                table.setTotalAmount(dataImportModel.totalAmountOfRows);
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
        let { inMemoryDataImport, hasUserSelectedDonation, errorCallback } = event.detail;

        try {
            let dataImportRecord = await this.saveDataImport(inMemoryDataImport, errorCallback);

            const hasPaymentToProcess = dataImportRecord && dataImportRecord[PAYMENT_AUTHORIZE_TOKEN__C];
            if (hasPaymentToProcess) {
                dataImportRecord = await this.startPaymentProcessing(dataImportRecord, errorCallback);
            }

            if (dataImportRecord) {
                this.startDataImportProcessing(dataImportRecord, hasUserSelectedDonation, errorCallback);
            }
        } catch (error) {
            errorCallback(error);
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
        if (this.previouslySavedDataImport.Id) {
            this.loadingText = 'Re-saving Data Import record...';

            inMemoryDataImport.Id = this.previouslySavedDataImport.Id;
            inMemoryDataImport[PAYMENT_METHOD__C] = this.previouslySavedDataImport[PAYMENT_METHOD__C];
            inMemoryDataImport[PAYMENT_STATUS__C] = this.previouslySavedDataImport[PAYMENT_STATUS__C];
            inMemoryDataImport[PAYMENT_DECLINED_REASON__C] =
                this.previouslySavedDataImport[PAYMENT_DECLINED_REASON__C];
        } else {
            this.loadingText = 'Saving Data Import record...';
        }

        inMemoryDataImport[PAYMENT_AUTHORIZE_TOKEN__C] = await this.tokenPromise;
        const dataImportRecord = await upsertDataImport({ dataImport: inMemoryDataImport });
        this.previouslySavedDataImport = deepClone(dataImportRecord);

        return dataImportRecord;
    }

    /*******************************************************************************
    * @description Method attempts to make a purchase call to Payment
    * Services. Immediately attempts to the charge the card provided in the Payment
    * Services iframe (GE_TokenizeCard).
    *
    * @param {object} dataImportRecord: A DataImport__c record
    * @param {function} errorCallback: An error handler function. Toggles
    *   the form save button, lightning spinner, and catches aura exceptions.
    *
    * @return {object} dataImportRecord: A DataImport__c record
    */
    startPaymentProcessing = async (dataImportRecord, errorCallback) => {
        this.loadingText = 'Charging card...';

        const isReadyToCharge = this.checkPaymentTransactionStatus(dataImportRecord[PAYMENT_STATUS__C]);
        if (isReadyToCharge) {
            const renderer = this.template.querySelector('c-ge-form-renderer');
            const cardholderNames = JSON.stringify(renderer.fabricatedCardholderNames);
            const purchaseCallResponse = await this.makePurchaseCall(dataImportRecord, cardholderNames);

            if (purchaseCallResponse) {
                dataImportRecord = this.setDataImportElevateFields(dataImportRecord, purchaseCallResponse);
                dataImportRecord = await upsertDataImport({ dataImport: dataImportRecord });
                this.previouslySavedDataImport = deepClone(dataImportRecord);
            }

            if (purchaseCallResponse.statusCode !== 201) {
                // For some reason the key in the body object for 'Message'
                // in the response we receive from Elevate is capitalized.
                let errors =
                    purchaseCallResponse.body.Message ||
                    purchaseCallResponse.body.errors.map(error => error.message).join(', ');
                errorCallback(errors);

                return undefined;
            }
        }

        return dataImportRecord;
    }

    /*******************************************************************************
    * @description Method checks the current payment transaction's status and
    * returns true if the card is in a 'chargeable' status.
    *
    * @param {string} paymentStatus: Payment transaction status
    *
    * @return {boolean}: True if card is in a 'chargeable' status
    */
    checkPaymentTransactionStatus = (paymentStatus) => {
        switch (paymentStatus) {
            case PAYMENT_TRANSACTION_STATUS_ENUM.PENDING: return false;
            case PAYMENT_TRANSACTION_STATUS_ENUM.AUTHORIZED: return false;
            case PAYMENT_TRANSACTION_STATUS_ENUM.CANCELED: return false;
            case PAYMENT_TRANSACTION_STATUS_ENUM.CAPTURED: return false;
            case PAYMENT_TRANSACTION_STATUS_ENUM.DECLINED: return true;
            case PAYMENT_TRANSACTION_STATUS_ENUM.NONRETRYABLEERROR: return false;
            case PAYMENT_TRANSACTION_STATUS_ENUM.RETRYABLEERROR: return true;
            case PAYMENT_TRANSACTION_STATUS_ENUM.REFUNDISSUED: return false;
            default: return true;
        }
    }

    /*******************************************************************************
    * @description Posts an http request through the `createTransaction` apex
    * method and parses the response.
    *
    * @param {object} dataImportRecord: A DataImport__c record
    *
    * @return {object} response: An http response object
    */
    makePurchaseCall = async (dataImportRecord, cardholderNames) => {
        let purchaseCallResponseString = await createTransaction({
            dataImportRecord: dataImportRecord,
            cardholderNames: cardholderNames
        });
        let response = JSON.parse(purchaseCallResponseString);
        response.body = JSON.parse(response.body);

        return response;
    }

    /*******************************************************************************
    * @description Method sets values Payment Services related Data Import fields.
    * Payment_Status__c and Payment_Declined_Reason__c.
    *
    * @param {object} dataImportRecord: A DataImport__c record
    * @param {object} purchaseResponse: An http response object
    *
    * @return {object} dataImportRecord: A DataImport__c record
    */
    setDataImportElevateFields = (dataImportRecord, purchaseCallResponse) => {
        const paymentStatus =
            purchaseCallResponse.body.status ||
            purchaseCallResponse.status ||
            CUSTOM_LABELS.commonUnknownError;
        dataImportRecord[PAYMENT_STATUS__C] = paymentStatus;

        const isSuccessfulPurchase = purchaseCallResponse.statusCode === 201;
        if (isSuccessfulPurchase) {
            // TODO: How do we want to handle payment method for successful charges? What about failed charges?
            dataImportRecord[PAYMENT_METHOD__C] = 'Credit Card';
            dataImportRecord[PAYMENT_DECLINED_REASON__C] = null;
        } else {
            dataImportRecord[PAYMENT_DECLINED_REASON__C] = JSON.stringify(purchaseCallResponse.body);
        }

        return dataImportRecord;
    }

    /*******************************************************************************
    * @description Sends the Data Import into BDI for processing and navigates to
    * the opportunity record detail page on success.
    *
    * @param {object} dataImportRecord: A DataImport__c record
    * @param {boolean} hasUserSelectedDonation: True if a selection had been made in
    * the 'Review Donations' modal.
    * Determines BDI matching criteria.
    *   true = "single match or create" and means we are updating
    *   false = "do not match"
    */
    startDataImportProcessing = (dataImportRecord, hasUserSelectedDonation, errorCallback) => {
        this.loadingText = 'Processing data import record...';
        processDataImport({ diRecord: dataImportRecord, updateGift: hasUserSelectedDonation })
            .then(opportunityId => {
                this.loadingText = 'Navigating to opportunity record...';
                this.previouslySavedDataImport = {};
                this.navigateToRecordPage(opportunityId);
            })
            .catch(error => {
                errorCallback(error);
                // TODO: Potentially have to check for other types of status that MAY
                // indicate a charge could still occur (pending, authorized, etc)
                if (dataImportRecord[PAYMENT_STATUS__C] === CAPTURED) {
                    showToast('HEY!', 'Card was charged. Please fix the outstanding errors and try again.', 'error', 'sticky');
                }
            });
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

    handleReviewDonationsModal(event) {
        this.dispatchEvent(new CustomEvent('togglereviewdonationsmodal', { detail: event.detail }));
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
}