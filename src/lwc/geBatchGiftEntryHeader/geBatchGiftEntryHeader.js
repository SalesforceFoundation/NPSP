import {LightningElement, api, wire} from 'lwc';
import {getRecord, getFieldValue} from 'lightning/uiRecordApi';

import NAME_FIELD from '@salesforce/schema/DataImportBatch__c.Name';
import BATCH_DRY_RUN_LABEL from '@salesforce/label/c.bgeBatchDryRun';
import PROCESS_BATCH_LABEL from '@salesforce/label/c.bgeProcessBatch';
import EDIT_BATCH_INFO_LABEL from '@salesforce/label/c.geEditBatchInfo';
import TAB_HEADER_LABEL from '@salesforce/label/c.bgeTabHeader';

export default class GeBatchGiftEntryHeader extends LightningElement {

    batchDryRunLabel = BATCH_DRY_RUN_LABEL;
    processBatchLabel = PROCESS_BATCH_LABEL;
    editButtonLabel = EDIT_BATCH_INFO_LABEL;
    tabHeaderLabel = TAB_HEADER_LABEL;

    @api batchId;
    @api isPermissionError;

    @wire(getRecord, {
        recordId: '$batchId',
        fields: NAME_FIELD
    })
    batch;

    get batchName() {
        return getFieldValue(this.batch.data, NAME_FIELD);
    }

    handleClick(event) {
        switch (event.target.label) {
            case BATCH_DRY_RUN_LABEL:
                this.dispatchEvent(new CustomEvent('batchdryrun'));
                break;
            case PROCESS_BATCH_LABEL:
                this.dispatchEvent(new CustomEvent('processbatch'));
                break;
            case EDIT_BATCH_INFO_LABEL:
                this.editBatch();
                break;
        }
    }

    editBatch() {
        this.dispatchEvent(new CustomEvent(
            'edit', {detail: this.batchId}
        ));
    }

    /*******************************************************************************
     * Start getters for data-qa-locator attributes
     */

    get qaLocatorBatchDryRun() {
        return `button ${this.batchDryRunLabel}`;
    }
    get qaLocatorProcessBatch() {
        return `button ${this.processBatchLabel}`;
    }
    get qaLocatorEditBatchInfo() {
        return `button ${this.editButtonLabel}`;
    }

    /*******************************************************************************
     * End getters for data-qa-locator attributes
     */
}