import { LightningElement, api, track } from 'lwc';
import { mutable } from 'c/utilTemplateBuilder';

export default class GeTemplateBuilderFormSection extends LightningElement {
    @api activeFormSectionId;
    @track isEditMode;

    @track formSection;
    /* Public setter for the tracked property selectedBatchFields */
    // TODO: Needs to be revisited, WIP tied to retrieving and rendering an existing template
    @api
    set formSection(formSection) {
        this.formSection = formSection;
    }

    get isActiveFormSectionIcon() {
        return this.activeFormSectionId == this.formSection.id ? 'utility:record' : 'utility:routing_offline';
    }

    /*******************************************************************************
    * @description Public method that collects the current values of all the relevant
    * input fields for this FormSection and return an instance of FormSection.
    *
    * @return {object} formSection: Instance of the FormSection class
    */
    @api
    getFormSectionValues() {
        this.formSection.elements = this.getSectionFormFields();
        return mutable(this.formSection);
    }

    /*******************************************************************************
    * @description Public method that collects the current values of all the relevant
    * input fields for this FormSection and return an instance of FormSection.
    *
    * @return {object} formSection: Instance of the FormSection class
    */
    getSectionFormFields() {
        let sectionFormFieldComponents = this.template.querySelectorAll('c-ge-template-builder-form-field');
        let sectionFormFields = [];
        for (let i = 0; i < sectionFormFieldComponents.length; i++) {
            let formField = sectionFormFieldComponents[i].getFormFieldValues();
            sectionFormFields.push(formField);
        }

        return sectionFormFields;
    }

    /*******************************************************************************
    * @description Updates the formSection label in memory
    */
    handleSaveFormSection() {
        const formSectionLabelInputElement =
            this.template.querySelector('lightning-input[data-name="formSectionLabelInputElement"]');
        this.formSection.label = formSectionLabelInputElement.value;
        this.handleExitEditMode();
    }

    /*******************************************************************************
    * @description Sends out a 'deleteformsection' custom event to parent component
    * geTemplateBuilderFormLayout
    */
    handleDeleteSection() {
        this.dispatchEvent(new CustomEvent(
            'deleteformsection',
            { detail: this.formSection }));
    }

    /*******************************************************************************
    * @description Sets formSection into edit mode
    */
    handleEditFormSection() {
        this.isEditMode = true;
    }

    /*******************************************************************************
    * @description Sets formSection into not edit mode
    */
    handleExitEditMode() {
        this.isEditMode = false;
    }

    /*******************************************************************************
    * @description Handles setting the active section and updating the slds icon
    * across all sections.
    *
    * @param {object} event: Onclick event object from lightning-button
    */
    handleSelectActiveSection() {
        this.dispatchEvent(new CustomEvent(
            'changeactivesection',
            { detail: this.formSection.id }));
    }

    /*******************************************************************************
    * @description Sends an event up to parent component geTemplateBuilderGiftFields
    * for shifting the FormSection element up in the list and UI
    *
    * @param {object} event: Onclick event object from lightning-button
    */
    handleFormSectionUp() {
        this.dispatchEvent(new CustomEvent(
            'formsectionup',
            { detail: this.formSection.id }));
    }

    /*******************************************************************************
    * @description Sends an event up to parent component geTemplateBuilderGiftFields
    * for shifting the FormSection element down in the list and UI
    *
    * @param {object} event: Onclick event object from lightning-button
    */
    handleFormSectionDown() {
        this.dispatchEvent(new CustomEvent(
            'formsectiondown',
            { detail: this.formSection.id }));
    }

    /*******************************************************************************
    * @description Sends an event up to parent component geTemplateBuilderGiftFields
    * for shifting the FormField element up in the list and UI
    *
    * @param {object} event: Onclick event object from lightning-button
    */
    handleFormFieldUp(event) {
        const formFieldId = event.detail;
        this.dispatchEvent(new CustomEvent(
            'formfieldup',
            { detail: formFieldId }));
    }

    /*******************************************************************************
    * @description Sends an event up to parent component geTemplateBuilderGiftFields
    * for shifting the FormField element down in the list and UI
    *
    * @param {object} event: Onclick event object from lightning-button
    */
    handleFormFieldDown(event) {
        const formFieldId = event.detail;
        this.dispatchEvent(new CustomEvent(
            'formfielddown',
            { detail: formFieldId }));
    }
}