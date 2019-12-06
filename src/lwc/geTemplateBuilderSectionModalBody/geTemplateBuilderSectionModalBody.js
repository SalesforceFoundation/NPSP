import { LightningElement, api } from 'lwc';
import { mutable } from 'c/utilTemplateBuilder';
import { fireEvent } from 'c/pubsubNoPageRef';

// Import custom labels
import geHeaderFormFieldsModalRenameSection from '@salesforce/label/c.geHeaderFormFieldsModalRenameSection';
import geHeaderFormFieldsModalDeleteSection from '@salesforce/label/c.geHeaderFormFieldsModalDeleteSection';
import geWarningFormFieldsModalDeleteSection from '@salesforce/label/c.geWarningFormFieldsModalDeleteSection';
import geBodyFormFieldsModalDeleteSection from '@salesforce/label/c.geBodyFormFieldsModalDeleteSection';
import geButtonFormFieldsModalDeleteSectionAndFields from '@salesforce/label/c.geButtonFormFieldsModalDeleteSectionAndFields';
import labelGeCancel from '@salesforce/label/c.labelGeCancel';
import labelGeSave from '@salesforce/label/c.labelGeSave';
import geLabelSectionName from '@salesforce/label/c.geLabelSectionName';

export default class GeTemplateBuilderSectionModalBody extends LightningElement {

    // Expose custom labels to template
    CUSTOM_LABELS = {
        geHeaderFormFieldsModalRenameSection,
        geHeaderFormFieldsModalDeleteSection,
        geWarningFormFieldsModalDeleteSection,
        geBodyFormFieldsModalDeleteSection,
        geButtonFormFieldsModalDeleteSectionAndFields,
        geLabelSectionName,
        labelGeCancel,
        labelGeSave
    }

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