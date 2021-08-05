import { LightningElement, api, track, wire } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { NavigationMixin } from 'lightning/navigation';
import { fireEvent, registerListener, unregisterListener } from 'c/pubsubNoPageRef';
import { validateJSONString, deepClone, getNamespace, showToast, apiNameFor } from 'c/utilCommon';
import { handleError } from "c/utilTemplateBuilder";
import GeLabelService from 'c/geLabelService';
import geBatchGiftsExpectedTotalsMessage
    from '@salesforce/label/c.geBatchGiftsExpectedTotalsMessage';
import geBatchGiftsExpectedCountOrTotalMessage
    from '@salesforce/label/c.geBatchGiftsExpectedCountOrTotalMessage';
import checkForElevateCustomer 
    from '@salesforce/apex/GE_GiftEntryController.isElevateCustomer';
import processBatch from '@salesforce/apex/GE_GiftEntryController.processGiftsFor';

import DATA_IMPORT_BATCH_OBJECT from '@salesforce/schema/DataImportBatch__c';
import BATCH_TABLE_COLUMNS_FIELD from '@salesforce/schema/DataImportBatch__c.Batch_Table_Columns__c';

import bgeGridGiftDeleted from '@salesforce/label/c.bgeGridGiftDeleted';
const GIFT_ENTRY_TAB_NAME = 'GE_Gift_Entry';

import GiftBatch from 'c/geGiftBatch';
import Gift from 'c/geGift';

export default class GeGiftEntryFormApp extends NavigationMixin(LightningElement) {

    // Expose custom labels to template
    CUSTOM_LABELS = GeLabelService.CUSTOM_LABELS;

    @api recordId;
    @api sObjectName;

    @track isPermissionError;
    @track loadingText = this.CUSTOM_LABELS.geTextSaving;

    _hasDisplayedExpiredAuthorizationWarning = false;

    dataImportRecord = {};
    errorCallback;
    _isBatchProcessing = false;
    isElevateCustomer = false;

    namespace;
    isLoading = true;

    giftBatch = new GiftBatch();
    @track giftBatchState = {};
    gift = new Gift();
    @track giftInView = {};

    async handleLoadMoreGifts(event) {
        try {
            const giftsOffset = event.detail.giftsOffset;
            this.giftBatchState = await this.giftBatch.getMoreGifts(giftsOffset);
        } catch(error) {
            handleError(error);
        }
    }

    handleLoadData(event) {
        try {
            const giftId = event.detail.Id;
            this.gift = this.giftBatch.findGiftBy(giftId);
            this.giftInView = this.gift.state();
        } catch(error) {
            handleError(error);
        }
    }

    handleFormStateChange(event) {
        try {
            const giftFieldChanges = event.detail;
            this.gift.updateFieldsWith(giftFieldChanges);
            this.giftInView = this.gift.state();
        } catch(error) {
            handleError(error);
        }
    }

    handleDeleteFieldFromGiftState(event) {
        try {
            const field = event.detail;
            this.gift.removeField(field);
            this.giftInView = this.gift.state();
        } catch(error) {
            handleError(error);
        }
    }

    get isBatchMode() {
        return this.sObjectName &&
            this.sObjectName === DATA_IMPORT_BATCH_OBJECT.objectApiName;
    }

    constructor() {
        super();
        this.namespace = getNamespace(DATA_IMPORT_BATCH_OBJECT.objectApiName);
    }

    async connectedCallback() {
        this.isElevateCustomer = await checkForElevateCustomer();
        registerListener('geBatchGiftEntryTableChangeEvent', this.retrieveBatchTotals, this);
        registerListener('refreshbatchtable', this.refreshBatchTable, this);
        registerListener('softcreditwidgetchange', this.handleSoftCreditWidgetChange, this);

        if (this.recordId) {
            this.giftBatchState = await this.giftBatch.init(this.recordId);
            await this.updateAppDisplay();
        }
    }

    disconnectedCallback() {
        unregisterListener('geBatchGiftEntryTableChangeEvent', this.retrieveBatchTotals, this);
    }

    handleSoftCreditWidgetChange(event) {
        console.log('handleSoftCreditWidgetChange', deepClone(event));
        switch(event.action) {
            case 'addSoftCredit':
                console.log('case addSoftCredit');
                this.gift.addNewSoftCredit();
                this.giftInView = this.gift.state();
                break;
            case 'removeSoftCredit':
                console.log('case removeSoftCredit');
                this.gift.removeSoftCredit(event.detail.key);
                this.giftInView = this.gift.state();
                break;
            case 'updateSoftCredit':
                console.log('case updateSoftCredit');
                this.gift.updateSoftCredit(event.detail.softCredit);
                this.giftInView = this.gift.state();
                break;
        }

        console.log('New Gift In View: ', deepClone(this.giftInView));
    }

    async refreshBatchTable() {
        this.giftBatchState = await this.giftBatch.latestState(this.giftBatch.giftsInViewSize());
    }

    async retrieveBatchTotals() {
        try {
            this.giftBatchState = await this.giftBatch.refreshTotals();
            await this.updateAppDisplay();
        } catch(error) {
            handleError(error);
        }
    }

    async updateAppDisplay() {
        if (this.shouldDisplayExpiredAuthorizationWarning()) {
            this.displayExpiredAuthorizationWarningModalForPageLoad();
        }
        this._isBatchProcessing = this.giftBatchState.isProcessingGifts;
        this.isLoading = false;
        if (!this._isBatchProcessing) return;
        await this.startPolling();
    }

    /*******************************************************************************
    * @description Receives a 'submit' event from geFormRenderer and proceeds down
    * the Batch or Single save paths depending on the current app mode.
    *
    * @param {object} event: Custom Event containing the Data Import record and
    * potentially other objects (booleans, callbacks, etc).
    */
    async handleSubmit(event) {
        // Callback received from geFormRenderer. Provides functions that
        // toggle the form save button, toggle the lightning spinner, and displays aura exceptions.
        this.errorCallback = event.detail.error;

        try {
            if (this.isBatchMode) {

                const giftForSubmit = this.gift.asDataImport();

                if (giftForSubmit.Id) {
                    this.giftBatchState = await this.giftBatch.updateMember(this.gift);
                } else {
                    this.giftBatchState = await this.giftBatch.addMember(this.gift);
                }

                event.detail.success();

                showToast(
                    this.CUSTOM_LABELS.PageMessagesConfirm,
                    'Gift successfully saved',
                    'success',
                    'dismissible',
                    null
                );

                this.handleClearGiftInView();
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
        table.handleSubmit(event);
    }

    handleSectionsRetrieved(event) {
        const formSections = event.target.sections;
        const table = this.template.querySelector('c-ge-batch-gift-entry-table');
        table.sections = formSections;
    }

    async handleBatchDryRun() {
        try {
            await this.refreshBatchTotals();
        } catch (error) {
            handleError(error);
        } finally {
            if (this.shouldDisplayExpiredAuthorizationWarning()) {
                this.displayExpiredAuthorizationWarningModalForProcessAndDryRun(
                    async () => {
                        this.giftBatchState = await this.giftBatch.dryRun();
                        this.dispatchEvent(new CustomEvent('closemodal')); 
                    } 
                );
            } else {
                this.giftBatchState = await this.giftBatch.dryRun();
            }
        }
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

    handleNavigateEvent(event) {
        if (event.detail.to === 'recordPage') {
            this.navigateToRecordPage(event.detail.recordId);
        }

        if (event.detail.to === 'landingPage') {
            this.navigateToLandingPage();
        }
    }

    navigateToRecordPage(recordId) {
        const pageReference = {
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                actionName: 'view'
            }
        };
        this[NavigationMixin.Navigate](pageReference);
    }

    navigateToLandingPage() {
        const giftEntryTabName = this.namespace ?
            `${this.namespace}__${GIFT_ENTRY_TAB_NAME}` :
            GIFT_ENTRY_TAB_NAME;
        const url = `/lightning/n/${giftEntryTabName}`;

        const pageReference = {
            type: 'standard__webPage',
            attributes: { url: url }
        };
        this[NavigationMixin.Navigate](pageReference, true);
    }

    get batchName() {
        return this.giftBatchState.name;
    }

    // TODO: maybe is internal to batch table component OR internal to possible new GiftEntryBatchTable class
    get userDefinedBatchTableColumnNames() {
        const batchTableColumns =
            validateJSONString(this.giftBatchState.batchTableColumns);
        if (batchTableColumns) {
            return batchTableColumns;
        }
        return [];
    }

    shouldDisplayExpiredAuthorizationWarning() {
        return this.isElevateCustomer
            && this.giftBatchState.hasPaymentsWithExpiredAuthorizations
            && !this._hasDisplayedExpiredAuthorizationWarning;
    }

    async handleProcessBatch() {
        if (this.isProcessable()) {
            try {
                await this.refreshBatchTotals();
            } catch (error) {
                handleError(error);
            } finally {
                await this.startBatchProcessing();
            }
            return;
        }
        this.handleBatchProcessingErrors();
    }

    async startBatchProcessing() {
        if (this.shouldDisplayExpiredAuthorizationWarning()) {
            this.displayExpiredAuthorizationWarningModalForProcessAndDryRun(
                this.processBatchAndCloseAuthorizationWarningModal()
            );
            return;
        }
        await this.processBatch();
    }

    processBatchAndCloseAuthorizationWarningModal() {
        return async () => {
            await this.processBatch();
            this.dispatchEvent(new CustomEvent('closemodal'));
        };
    }

    handleBatchProcessingErrors() {
        if (this.giftBatchState.expectedCountOfGifts && this.giftBatchState.expectedTotalBatchAmount) {
            handleError(geBatchGiftsExpectedTotalsMessage);
        } else {
            handleError(geBatchGiftsExpectedCountOrTotalMessage);
        }
    }

    get isBatchProcessing() {
        return this._isBatchProcessing;
    }

    async processBatch() {
        await processBatch({
            batchId: this.batchId
        }).then(() => {
            this._isBatchProcessing = true;
        }).catch(error => {
            handleError(error);
        }).finally(() => {
            this.startPolling();
        });
    }

    async startPolling() {
        const poll = setInterval(() => {
            Promise.resolve(true).then(() => {
                this.refreshBatchTotals();
            }).then(() => {
                if (!this._isBatchProcessing) {
                    clearInterval(poll);
                }
                if (!this.isBatchGiftEntryInFocus()) {
                    clearInterval(poll);
                }
            })
        }, 5000);
    }

    isBatchGiftEntryInFocus() {
        return location.href.includes(this.batchId);
    }

    async handleProcessedBatch() {
        this.giftBatchState = await this.giftBatch.init(this.recordId);
        this.collapseForm();
        showToast(
            this.CUSTOM_LABELS.PageMessagesConfirm,
            GeLabelService.format(
                this.CUSTOM_LABELS.geBatchProcessingSuccess,
                [this.batchName]),
            'success',
            'dismissible',
            null
        );
    }

    collapseForm() {
        // TODO: formRenderer should be able to
        // figure out when it's collapse based on
        // props that are received from formApp.
        // Look into removing this function entirely
        const form = this.template.querySelector('c-ge-form-renderer');
        form.collapse();
    }

    async refreshBatchTotals() {
        try {
            const wasProcessing = this._isBatchProcessing;

            this._hasDisplayedExpiredAuthorizationWarning = false;
            this.giftBatchState = await this.giftBatch.refreshTotals();
            this._isBatchProcessing = this.giftBatchState.isProcessingGifts;

            const finishedProcessingDuringThisRefresh =
                wasProcessing && this._isBatchProcessing === false;
            if (finishedProcessingDuringThisRefresh) {
                this.handleProcessedBatch();
            }
        } catch(error) {
            handleError(error);
        }
    }

    requireTotalMatch() {
        return this.giftBatchState.requireTotalMatch;
    }

    totalsMatch() {
        if (this.giftBatchState.expectedCountOfGifts && this.giftBatchState.expectedTotalBatchAmount) {
            return this.giftBatch.matchesExpectedCountOfGifts() && this.giftBatch.matchesExpectedTotalBatchAmount();

        } else if (this.giftBatchState.expectedCountOfGifts) {
            return this.giftBatch.matchesExpectedCountOfGifts();

        } else if (this.giftBatchState.expectedTotalBatchAmount) {
            return this.giftBatch.matchesExpectedTotalBatchAmount();
        }
    }

    isProcessable() {
        if (this.totalsMatch()) {
            return true;
        }
        return !this.requireTotalMatch();
    }

    handleClearGiftInView() {
        this.gift = new Gift();
        this.giftInView = this.gift.state();
    }

    async handleDelete(event) {
        // TODO: maybe throw spinner while record is being deleted?
        try {
            const gift = event.detail;
            this.giftBatchState = await this.giftBatch.remove(gift);

            if (this.giftInView?.fields.Id === gift?.Id) {
                this.handleClearGiftInView();
            }

            showToast(
                this.CUSTOM_LABELS.PageMessagesConfirm,
                bgeGridGiftDeleted,
                'success',
                'dismissible',
                null
            );
        } catch(error) {
            handleError(error);
        }
    }

    get batchId() {
        return this.giftBatchState.id;
    }

    async handleReceiveEvent(event) {
        if (event.action === 'save') {
            await this.saveGiftBatchTableColumnChange(event.payload.values);
        }
        this.closeModalCallback();
    }

    async saveGiftBatchTableColumnChange(batchTableColumns) {
        try {
            const giftBatchChanges = {
                giftBatchId: this.giftBatchState.id,
                batchTableColumns: JSON.stringify(batchTableColumns)
            };

            this.giftBatchState =
                await this.giftBatch.updateWith(giftBatchChanges);
        } catch(error) {
            handleError(error);
        }
    }

    @wire(getObjectInfo, { objectApiName: DATA_IMPORT_BATCH_OBJECT})
    dataImportBatchObjectInfo;

    get userCanEditBatchTableColumns() {
        try {
            return this.dataImportBatchObjectInfo.data.fields[
                BATCH_TABLE_COLUMNS_FIELD.fieldApiName
                ].updateable;
        } catch (e) {
            return false;
        }
    }

    handleSelectColumns(event) {
        const modalContent =
            this.userCanEditBatchTableColumns ?
                this.buildModalConfigSelectColumns(
                    event.detail.options,
                    event.detail.values) :
                this.modalConfigNoAccess;

        registerListener('privateselectcolumns', this.handleReceiveEvent, this);

        this.dispatchEvent(new CustomEvent('togglemodal', {
            detail: modalContent
        }));
    }

    displayModalPrompt(componentProperties) {
        const detail = {
            modalProperties: {
                componentName: 'geModalPrompt',
                showCloseButton: true
            },
            componentProperties
        };
        this.dispatchEvent(new CustomEvent('togglemodal', { detail }));      
    }

    displayExpiredAuthorizationWarningModalForPageLoad() {
        this.displayModalPrompt ({
                'variant': 'warning',
                'title': this.CUSTOM_LABELS.gePaymentAuthExpiredHeader,
                'message': this.CUSTOM_LABELS.gePaymentAuthExpiredWarningText,
                'buttons': 
                    [{
                        label: this.CUSTOM_LABELS.commonOkay,
                        variant: 'neutral',
                        action: () => { this.dispatchEvent(new CustomEvent('closemodal')); }
                    }]
            });
        this._hasDisplayedExpiredAuthorizationWarning = true;
    }

    displayExpiredAuthorizationWarningModalForProcessAndDryRun(actionOnProceed) {
        this.displayModalPrompt ({
                'variant': 'warning',
                'title': this.CUSTOM_LABELS.gePaymentAuthExpiredHeader,
                'message': this.CUSTOM_LABELS.gePaymentAuthExpiredWarningText,
                'buttons': 
                    [{
                        label: this.CUSTOM_LABELS.geProcessAnyway,
                        variant: 'neutral',
                        action: actionOnProceed
                    },
                    {
                        label: this.CUSTOM_LABELS.commonCancel,
                        variant: 'brand',
                        action: () => { this.dispatchEvent(new CustomEvent('closemodal')); }
                    }]
            });
        this._hasDisplayedExpiredAuthorizationWarning = true;
    }    

    buildModalConfigSelectColumns(available, selected) {
        const modalConfig = {
            componentProperties: {
                name: 'selectcolumnsmodal',
                cssClass: 'slds-m-bottom_medium slds-p-horizontal_small',
                sourceLabel: this.CUSTOM_LABELS.geLabelCustomTableSourceFields,
                selectedLabel: this.CUSTOM_LABELS.geLabelCustomTableSelectedFields,
                dedicatedListenerEventName: 'privateselectcolumns',
                options: available,
                values: selected,
                showModalFooter: true,
                min: 1
            },
            modalProperties: {
                cssClass: 'slds-modal_large',
                header: this.CUSTOM_LABELS.geTabBatchTableColumns,
                componentName: 'utilDualListbox',
                showCloseButton: true
            }
        };
        return modalConfig;
    }

    get modalConfigNoAccess() {
        const errorFieldName =
            `${BATCH_TABLE_COLUMNS_FIELD.objectApiName}: (${BATCH_TABLE_COLUMNS_FIELD.fieldApiName})`;
        const errorFLSBody = GeLabelService.format(
            this.CUSTOM_LABELS.geErrorFLSBody, [errorFieldName]
        );
        const message = `${this.CUSTOM_LABELS.geErrorFLSBatchTableColumns}  ${errorFLSBody}`;
        return {
            componentProperties: {
                name: 'noaccessmodal',
                illustrationClass: 'slds-p-around_large',
                dedicatedListenerEventName: 'privateselectcolumns',
                showModalFooter: false,
                message: message,
                title: this.CUSTOM_LABELS.geErrorFLSHeader,
                variant: 'no-access'
            },
            modalProperties: {
                cssClass: 'slds-modal_large',
                header: this.CUSTOM_LABELS.geTabBatchTableColumns,
                componentName: 'utilIllustration',
                showCloseButton: true
            }
        };
    }

    closeModalCallback = function() {
        const closeModal = () => this.dispatchEvent(new CustomEvent('closemodal'));
        const unregisterModalListener = () =>
            unregisterListener('privateselectcolumns', this.handleReceiveEvent, this);

        closeModal();
        unregisterModalListener();
    }

}
