import { LightningElement, track, api } from 'lwc';
import { mutable } from 'c/utilTemplateBuilder';

export default class UtilModal extends LightningElement {
    @track modalData;

    @api
    set modalData(modalData) {
        this.modalData = modalData;
    }

    get sectionBeingEdited() {
        return this.modalData ? this.modalData.section : {};
    }

    handleDelete() {
        console.log('Delete');
        this.dispatchEvent(new CustomEvent('handlesave', {
            detail: { action: 'delete', section: this.modalData.section }
        }));
    }

    handleCancel() {
        console.log('Cancel');
        this.dispatchEvent(new CustomEvent('handlecancel'));
        console.log('event has been dispatched');
    }

    handleSave() {
        console.log('Save');
        let modalData = mutable(this.modalData);
        console.log('modalData: ', modalData);
        const customLabel = this.template.querySelector('lightning-input[data-name="customLabel"]').value;
        modalData.section.label = customLabel;

        this.modalData = modalData;

        this.dispatchEvent(new CustomEvent('handlesave', {
            detail: { action: 'save', section: this.modalData.section }
        }));

        console.log('event has been dispatched');
    }
}