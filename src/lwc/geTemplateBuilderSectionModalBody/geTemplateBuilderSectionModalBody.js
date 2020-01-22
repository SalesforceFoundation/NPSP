import { LightningElement, api } from 'lwc';
import { mutable } from 'c/utilCommon';
import { fireEvent } from 'c/pubsubNoPageRef';
import GeLabelService from 'c/geLabelService';

export default class GeTemplateBuilderSectionModalBody extends LightningElement {

    // Expose custom labels to template
    CUSTOM_LABELS = GeLabelService.CUSTOM_LABELS;

    @api modalData;

    get sectionBeingEdited() {
        return this.modalData ? this.modalData.section : {};
    }

    get hasRequiredFields() {
        const section = this.modalData.section;
        return section && section.elements && section.elements.length > 0 ?
            section.elements.some(element => element.required === true)
            : false;
    }

    /*******************************************************************************
    * @description Fires an event to utilDedicatedListener to notify parent aura
    * component GE_ModalProxy that the given section needs to be removed.
    */
    handleDelete() {
        const detail = { action: 'delete', section: this.modalData.section };
        fireEvent(this.pageRef, 'geTemplateBuilderSectionModalBodyEvent', detail);
    }

    /*******************************************************************************
    * @description Fires an event to utilDedicatedListener to notify parent aura
    * component GE_ModalProxy that the modal needs to be updated.
    */
    handleSave() {
        let section = mutable(this.modalData.section);
        section.label = this.template.querySelector('lightning-input[data-name="customLabel"]').value;

        const detail = { action: 'save', section: section };
        fireEvent(this.pageRef, 'geTemplateBuilderSectionModalBodyEvent', detail);
    }

    /*******************************************************************************
    * @description Fires an event to utilDedicatedListener to notify parent aura
    * component GE_ModalProxy that the modal needs to be closed.
    */
    handleCancel() {
        const detail = { action: 'cancel' };
        fireEvent(this.pageRef, 'geTemplateBuilderSectionModalBodyEvent', detail);
    }
}