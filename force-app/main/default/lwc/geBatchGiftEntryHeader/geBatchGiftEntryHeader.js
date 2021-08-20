import { LightningElement, api } from 'lwc';
import CUSTOM_LABELS from './helpers/customLabels';

export default class GeBatchGiftEntryHeader extends LightningElement {

    LABELS = CUSTOM_LABELS;
    ACTIONS = Object.freeze({
        DRY_RUN_BATCH: 'DRY_RUN_BATCH',
        PROCESS_BATCH: 'PROCESS_BATCH',
        EDIT_BATCH: 'EDIT_BATCH'
    });

    @api giftBatchState;

    get batchName() {
        return this.giftBatchState.name;
    }

    get shouldDisplayHeaderDetails() {
        return this.giftBatchState.hasValuesGreaterThanZero;
    }

    get hasFailedPayments() {
        return this.giftBatchState.failedPaymentsCount > 0;
    }

    get isGiftBatchProcessing() {
        return this.giftBatchState.isProcessingGifts;
    }

    get processBatchButtonName() {
        let buttonName = this.LABELS.bgeProcessBatch;
        if (this.giftBatchState.authorizedPaymentsCount) {
            buttonName = this.LABELS.bgeProcessBatchAndPayments;
        }
        return buttonName;
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
            'edit', { detail: this.giftBatchState.id }
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
