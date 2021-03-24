import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import { registerListener, unregisterListener } from 'c/pubsubNoPageRef';
import getGiftBatchTotalsBy from '@salesforce/apex/GE_GiftEntryController.getGiftBatchTotalsBy';
import isElevateCustomer from '@salesforce/apex/GE_GiftEntryController.isElevateCustomer';

import NAME_FIELD from '@salesforce/schema/DataImportBatch__c.Name';
import { CUSTOM_LABELS } from './helpers/customLabels';

export default class GeBatchGiftEntryHeader extends LightningElement {

    LABELS = CUSTOM_LABELS;
    ACTIONS = Object.freeze({
        DRY_RUN_BATCH: 'DRY_RUN_BATCH',
        PROCESS_BATCH: 'PROCESS_BATCH',
        EDIT_BATCH: 'EDIT_BATCH'
    });

    @api batchId;
    @api isPermissionError;

    connectedCallback() {
        registerListener('geBatchGiftEntryTableChangeEvent', this.handleTableChange, this);
    }

    disconnectedCallback() {
        unregisterListener('geBatchGiftEntryTableChangeEvent', this.handleTableChange, this);
    }

    handleTableChange() {
        refreshApex(this.batchTotals);
    }

    @wire(getRecord, {
        recordId: '$batchId',
        fields: NAME_FIELD
    })
    batch;

    get batchName() {
        return getFieldValue(this.batch.data, NAME_FIELD);
    }

    @wire(getGiftBatchTotalsBy, { batchId: '$batchId' })
    batchTotals;

    get shouldDisplayDetail() {
        if (Number(this.batchTotals.data?.TOTAL) > 0 || Number(this.batchTotals.data?.FAILED) > 0) {
            return true;
        }
        return false;
    }

    @wire(isElevateCustomer)
    isElevateCustomer

    get shouldShowPaymentProcessingErrors() {
        return this.isElevateCustomer.data;
    }

    get processedGiftsCount() {
        return this.batchTotals.data?.PROCESSED;
    }

    get failedGiftsCount() {
        return this.batchTotals.data?.FAILED;
    }

    get failedPaymentsCount() {
        return this.batchTotals.data?.FAILED_PAYMENT;
    }

    get totalGiftsCount() {
        return this.batchTotals.data?.TOTAL;
    }

    handleClick(event) {
        const action =  event.target.getAttribute('data-action');
        switch (action) {
            case this.ACTIONS.DRY_RUN_BATCH:
                this.dispatchEvent(new CustomEvent('batchdryrun'));
                break;
            case this.ACTIONS.PROCESS_BATCH:
                this.dispatchEvent(new CustomEvent('processbatch'));
                break;
            case this.ACTIONS.EDIT_BATCH:
                this.editBatch();
                break;
        }
    }

    editBatch() {
        this.dispatchEvent(new CustomEvent(
            'edit', { detail: this.batchId }
        ));
    }

    get qaLocatorBatchDryRun() {
        return `button ${this.LABELS.bgeBatchDryRun}`;
    }
    get qaLocatorProcessBatch() {
        return `button ${this.LABELS.bgeProcessBatch}`;
    }
    get qaLocatorEditBatchInfo() {
        return `button ${this.LABELS.geEditBatchInfo}`;
    }
}
