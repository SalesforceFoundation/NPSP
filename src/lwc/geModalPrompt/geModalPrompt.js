import { LightningElement } from 'lwc';
import { fireEvent } from 'c/pubsubNoPageRef';
import GeLabelService from 'c/geLabelService';

export default class geModalPrompt extends LightningElement {

    // expose custom labels to template
    CUSTOM_LABELS = GeLabelService.CUSTOM_LABELS;

    handleCloseModal() {
        fireEvent(this.pageRef, 'geModalCloseEvent', {});
    }
}