import { LightningElement, api, track } from 'lwc';
import { mutable } from 'c/utilTemplateBuilder';

export default class GeTemplateBuilderFormSection extends LightningElement {
    @api activeFormSectionId;
    @track isEditMode;

    @track formSection;

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
        this.formSection.elements = mutable(this.getSectionFormFields());
        console.log('Form Section: ', this.formSection);
        return this.formSection;
    }

    getSectionFormFields() {
        let sectionFormFieldComponents = this.template.querySelectorAll('c-ge-template-builder-form-field');
        let sectionFormFields = [];
        for (let i = 0; i < sectionFormFieldComponents.length; i++) {
            let formField = sectionFormFieldComponents[i].getFormFieldValues();
            sectionFormFields.push(formField);
        }

        return sectionFormFields;
    }


    handleSaveFormSection() {
        const formSectionLabelInputElement =
            this.template.querySelector('lightning-input[data-name="formSectionLabelInputElement"]');
        this.formSection.label = formSectionLabelInputElement.value;
        this.handleExitEditMode();
    }

    handleEditFormSection() {
        this.isEditMode = true;
    }

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
        console.log('***handleSelectActiveSection | FormSection');
        console.log('***************************');
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