import { LightningElement, api, track } from 'lwc';
import { fireEvent } from 'c/pubsubNoPageRef';

import GeLabelService from 'c/geLabelService';

const MAX_STEPS = 2;
const SAVE = 'save';
const CANCEL = 'cancel';

export default class geBatchWizard extends LightningElement {

    // Expose custom labels to template
    CUSTOM_LABELS = GeLabelService.CUSTOM_LABELS;

    @api dedicatedListenerEventName;

    @track step = 0;
    @track isLoading = true;

    headers = {
        0: this.CUSTOM_LABELS.geHeaderBatchSelectTemplate,
        1: this.CUSTOM_LABELS.geHeaderBatchEnterInfo,
        2: this.CUSTOM_LABELS.geHeaderBatchSetDefaultValues
    }

    steps = {
        first: 0,
        second: 1,
        third: 2
    }

    get showBackButton() {
        return this.step > 0 ? true : false;
    }

    get showSaveButton() {
        return this.step === 2 ? true : false;
    }

    get header() {
        return this.headers[this.step];
    }

    connectedCallback() {
        this.isLoading = false;
    }

    handleNext() {
        if (this.step < MAX_STEPS) {
            this.step += 1;
        }
    }

    handleBack() {
        if (this.showBackButton || this.step > 0) {
            this.step -= 1;
        }
    }

    /*******************************************************************************
    * @description Fires an event to utilDedicatedListener with the save action if
    * a dedicated listener event name is provided otherwise dispatches a CustomEvent.
    */
    handleSave() {
        const payload = { values: this.values, name: this.name };
        const detail = { action: SAVE, payload: payload };
        if (this.dedicatedListenerEventName) {
            fireEvent(this.pageRef, this.dedicatedListenerEventName, detail);
        } else {
            this.dispatchEvent(new CustomEvent(SVGFEFuncAElement, { detail: payload }));
        }
    }

    /*******************************************************************************
    * @description Fires an event to utilDedicatedListener with the cancel action if
    * a dedicated listener event name is provided otherwise dispatches a CustomEvent.
    */
    handleCancel() {
        console.log('************--- handleCancel');
        if (this.dedicatedListenerEventName) {
            fireEvent(this.pageRef, this.dedicatedListenerEventName, { action: CANCEL });
        } else {
            this.dispatchEvent(new CustomEvent(CANCEL, { detail: {} }));
        }
    }
}