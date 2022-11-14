import { LightningElement, api, track, wire } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { NavigationMixin } from 'lightning/navigation';
import { registerListener, unregisterListener } from 'c/pubsubNoPageRef';
import { validateJSONString, getNamespace, showToast, format } from 'c/utilCommon';
import { handleError } from "c/utilTemplateBuilder";
import GeLabelService from 'c/geLabelService';
import geBatchGiftsExpectedTotalsMessage
    from '@salesforce/label/c.geBatchGiftsExpectedTotalsMessage';
import geBatchGiftsExpectedCountOrTotalMessage
    from '@salesforce/label/c.geBatchGiftsExpectedCountOrTotalMessage';
import processBatch from '@salesforce/apex/GE_GiftEntryController.processGiftsFor';
import logError from '@salesforce/apex/GE_GiftEntryController.logError';
import checkForElevateCustomer from '@salesforce/apex/GE_GiftEntryController.isElevateCustomer';

import DATA_IMPORT_BATCH_OBJECT from '@salesforce/schema/DataImportBatch__c';
import BATCH_TABLE_COLUMNS_FIELD from '@salesforce/schema/DataImportBatch__c.Batch_Table_Columns__c';
import PAYMENT_OPPORTUNITY_ID from '@salesforce/schema/npe01__OppPayment__c.npe01__Opportunity__c';

import bgeGridGiftDeleted from '@salesforce/label/c.bgeGridGiftDeleted';
import commonPaymentServices from '@salesforce/label/c.commonPaymentServices';
import gePaymentServicesUnavailableHeader from '@salesforce/label/c.gePaymentServicesUnavailableHeader';
import gePaymentServicesUnavailableBody from '@salesforce/label/c.gePaymentServicesUnavailableBody';
import rdFlsErrorDetail from "@salesforce/label/c.RD2_EntryFormMissingPermissions";
import rdFlsErrorHeader from "@salesforce/label/c.geErrorFLSHeader";

import Settings from 'c/geSettings';

const GIFT_ENTRY_TAB_NAME = 'GE_Gift_Entry';

import GiftBatch from 'c/geGiftBatch';
import Gift from 'c/geGift';
import ElevateBatch from 'c/geElevateBatch';
import { fireEvent } from 'c/pubsubNoPageRef';

export default class GeGiftEntryFormApp extends NavigationMixin(LightningElement) {

    // Expose custom labels to template
    CUSTOM_LABELS = {
        ...GeLabelService.CUSTOM_LABELS,
        rdFlsErrorHeader,
        rdFlsErrorDetail,
    };

    @api recordId;
    @api sObjectName;

    @track isPermissionError;
    @track loadingText = this.CUSTOM_LABELS.geTextSaving;

    _hasDisplayedExpiredAuthorizationWarning = false;
    _hasDisplayedElevateDisconnectedModal = false;

    dataImportRecord = {};
    errorCallback;
    _isBatchProcessing = false;
    shouldLoadSpinner = false;
    isElevateCustomer = false;
    openedGiftDonationId;

    namespace;
    isLoading = true;
    isFormRendering = false;
    isFormCollapsed = false;
    isFormSaveDisabled = false;

    giftBatch = new GiftBatch();
    elevateBatch = new ElevateBatch();
    @track giftBatchState = {};
    gift = new Gift();
    @track giftInView = {};

    handleCollapseForm(event) {
        this.isFormCollapsed = event.detail;
    }

    async handleLoadMoreGifts(event) {
        try {
            const giftsOffset = event.detail.giftsOffset;
            this.giftBatchState = await this.giftBatch.getMoreGifts(giftsOffset);
        } catch(error) {
            handleError(error);
        }
    }

    get shouldDisableMakeRecurringButton() {
        return this.gift.isImported();
    }

    handleLoadData(event) {
        try {
            this.isFormRendering = true;
            const giftId = event.detail.Id;
            const foundGift = this.giftBatch.findGiftBy(giftId);
            this.gift = new Gift(foundGift.state());
            this.giftInView = this.gift.state();
            this.openedGiftDonationId = this.gift.donationId();

            if (this.isFormCollapsed) {
                this.isFormCollapsed = false;
            }
            fireEvent(this, 'resetElevateWidget', {});
            
            this.isFormRendering = false;
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
        registerListener('clearprocessedsoftcreditsinview', this.handleClearProcessedSoftCreditsInView, this);

        if (this.recordId) {
            this.giftBatchState = await this.giftBatch.init(this.recordId);
            await this.updateAppDisplay();
        }
        registerListener('geBatchGiftEntryTableChangeEvent', this.retrieveBatchTotals, this);
        await Settings.init();
    }

    get batchCurrencyIsoCode() {
        return this.giftBatchState.currencyIsoCode;
    }

    disconnectedCallback() {
        unregisterListener('geBatchGiftEntryTableChangeEvent', this.retrieveBatchTotals, this);
    }

    handleClearProcessedSoftCreditsInView() {
        if (this.gift.hasProcessedSoftCredits()) {
            this.gift.clearProcessedSoftCredits();
            this.giftInView = this.gift.state();
        }
    }

    handleReviewDonationsChange(event) {
        const reviewRecord = event.detail.record;
        let reviewRecordOpportunityId = null;
        if (reviewRecord.fields) {
            reviewRecordOpportunityId =
                reviewRecord.fields[PAYMENT_OPPORTUNITY_ID.fieldApiName]
                || reviewRecord.fields.Id;
        }

        const reviewRecordHasSoftCredits =
            reviewRecord && reviewRecord.softCredits;

        this.gift.clearProcessedSoftCredits();
        if (reviewRecordHasSoftCredits) {
            this.gift.addProcessedSoftCredits(reviewRecord.softCredits);
        }
        this.giftInView = this.gift.state();
    }

    handleSoftCreditWidgetChange(event) {
        switch(event.action) {
            case 'addSoftCredit':
                this.gift.addNewSoftCredit();
                break;
            case 'removeSoftCredit':
                this.gift.removeSoftCredit(event.detail.key);
                break;
            case 'updateSoftCredit':
                this.gift.updateSoftCredit(event.detail.softCredit);
                break;
        }

        this.giftInView = this.gift.state();
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
        if (this.shouldDisplayElevateDeregistrationWarning()) {
            this.displayElevateDeregistrationWarning();
        }
        this._isBatchProcessing = this.giftBatchState.isProcessingGifts;
        this.shouldLoadSpinner = this._isBatchProcessing
        this.isLoading = false;
        if (!this._isBatchProcessing) return;
        await this.startPolling();
    }

    handleLogError(event) {
        this.processLogError(event.detail.error, event.detail.context);
    }

    processLogError(error, context) {
        logError({error: error, context: context});
    }

    shouldDisplayElevateDeregistrationWarning() {
        return !this.isElevateCustomer
            && !this._hasDisplayedElevateDisconnectedModal
            && this.giftBatchState.authorizedPaymentsCount > 0;
    }

    displayElevateDeregistrationWarning() {
        this.displayModalPrompt ({
            variant: 'warning',
            title: format(gePaymentServicesUnavailableHeader, [commonPaymentServices]),
            message: format(gePaymentServicesUnavailableBody, [commonPaymentServices]),
            buttons:
                [{
                    label: this.CUSTOM_LABELS.commonOkay,
                    variant: 'neutral',
                    action: () => { this.dispatchEvent(new CustomEvent('closemodal')); }
                }]
        });
        this._hasDisplayedElevateDisconnectedModal = true;
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

                const mostRecentGift = this.giftBatch.mostRecentGift();
                if (mostRecentGift.failureInformation()) {
                    event.detail.error(mostRecentGift.failureInformation());
                    return;
                } else {
                    event.detail.success();
                    this.handleClearGiftInView();
                }
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
                this.shouldLoadSpinner = true
                await this.refreshBatchTotals();
            } catch (error) {
                this.shouldLoadSpinner = false
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
        return this._isBatchProcessing || this.giftBatchState.isProcessingGifts;
    }

    async processBatch() {
        this.handleClearGiftInView();
        this._isBatchProcessing = true;

        new Promise((resolve,reject) => {
            setTimeout(async ()=> {
                await processBatch({
                    batchId: this.batchId
                }).catch(error => {
                    handleError(error);
                }).finally(() => {
                    this.startPolling();
                });
                resolve();
            }, 0);
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
        await this.refreshBatchTable();
        this.isFormCollapsed = true;
        this._isBatchProcessing = this.giftBatchState.isProcessingGifts;
        this.shouldLoadSpinner = this._isBatchProcessing
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

    async refreshBatchTotals() {
        try {
            const wasProcessing = this._isBatchProcessing;

            this._hasDisplayedExpiredAuthorizationWarning = false;
            this.giftBatchState = await this.giftBatch.refreshTotals();

            const finishedProcessingDuringThisRefresh =
                wasProcessing && !this.giftBatchState.isProcessingGifts;
            if (finishedProcessingDuringThisRefresh) {
                await this.handleProcessedBatch();
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
        try {
            this.isFormSaveDisabled = true;
            const gift = new Gift({fields: event.detail});
            const isRemovedFromElevate = await this.removeFromElevateBatch(gift);

            await this.performDelete(gift.asDataImport(), isRemovedFromElevate);

            if (this.giftInView?.fields.Id === gift?.id()) {
                this.handleClearGiftInView();
            }

            showToast(
                this.CUSTOM_LABELS.PageMessagesConfirm,
                bgeGridGiftDeleted,
                'success',
                'dismissible',
                null
            );
            this.isFormSaveDisabled = false;
        } catch(error) {
            this.isFormSaveDisabled = false;
            handleError(error);
        }
    }

    async removeFromElevateBatch(gift) {
        let isRemovedFromElevate = false;
        if (this.shouldRemoveFromElevateBatch(gift)) {
            try {
                await this.deleteFromElevateBatch(gift);
                isRemovedFromElevate = true;
            } catch (exception) {
                let errorMsg = GeLabelService.format(
                    this.CUSTOM_LABELS.geErrorElevateDelete, 
                    [this.CUSTOM_LABELS.commonPaymentServices]
                );
                throw new Error(errorMsg);
            }
        }

        return isRemovedFromElevate;
    }

    async performDelete(giftAsDataImport, isRemovedFromElevate) {
        try {
            this.giftBatchState = await this.giftBatch.remove(giftAsDataImport);
        } catch (exception) {
            if (isRemovedFromElevate) {
                this.logFailureAfterElevateDelete(exception, giftAsDataImport);
                let errorMsg = GeLabelService.format(
                    this.CUSTOM_LABELS.geErrorRecordFailAfterElevateDelete, 
                    [this.CUSTOM_LABELS.commonPaymentServices]
                );
                throw new Error(errorMsg);
            }
            throw exception;
        }
    }

    logFailureAfterElevateDelete(exception, giftAsDataImport) {
        this.processLogError(
            exception.toString(),
            GeLabelService.format(
                this.CUSTOM_LABELS.geElevateDeleteErrorLog,
                [this.CUSTOM_LABELS.commonPaymentServices,
                giftAsDataImport.Id,
                this.batchId]
            )
        );
    }

    shouldRemoveFromElevateBatch(gift) {
        return gift &&
            this.isElevateCustomer &&
            gift.hasElevateRemovableStatus();
    }

    async deleteFromElevateBatch(gift) {
        try {
            return await this.elevateBatch.remove(gift);
        } catch (exception) {
            throw exception;
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

    handleAddSchedule(event) {
        const schedule = event.detail;
        this.gift.addSchedule(schedule);
        this.giftInView = this.gift.state();
        fireEvent(this, 'geModalCloseEvent', {});
    }

    handleRemoveSchedule() {
        this.gift.removeSchedule();
        this.giftInView = this.gift.state();
    }


}
