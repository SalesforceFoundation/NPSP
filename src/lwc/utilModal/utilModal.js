import { LightningElement, track, api } from 'lwc';
import { mutable, dispatch } from 'c/utilTemplateBuilder';

export default class UtilModal extends LightningElement {
    @track modalData;

    @api
    set modalData(modalData) {
        this.modalData = modalData;
    }

    get sectionBeingEdited() {
        return this.modalData ? this.modalData.section : {};
    }

    /*******************************************************************************
    * @description Dispatches an event to notify parent aura component GE_ModalProxy
    * that the given section needs to be removed.
    */
    handleDelete() {
        const detail = { action: 'delete', section: this.modalData.section };
        dispatch(this, 'utilModalEvent', detail, true);
    }

    /*******************************************************************************
    * @description Dispatches an event to notify parent aura component GE_ModalProxy
    * that the modal needs to be updated.
    */
    handleSave() {
        let section = mutable(this.modalData.section);
        section.label = this.template.querySelector('lightning-input[data-name="customLabel"]').value;;

        const detail = { action: 'save', section: section };
        dispatch(this, 'utilModalEvent', detail, true);
    }

    /*******************************************************************************
    * @description Dispatches an event to notify parent aura component GE_ModalProxy
    * that the modal needs to be closed.
    */
    handleCancel() {
        const detail = { action: 'cancel' };
        dispatch(this, 'utilModalEvent', detail , true);
    }
}