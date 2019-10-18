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

    get isEmptySection() {
        return this.formSection.elements.length === 0 ? true : false;
    }

    /*******************************************************************************
    * @description Public method that collects the current values of all the relevant
    * input fields for this FormSection and return an instance of FormSection.
    *
    * @return {object} formSection: Instance of the FormSection class
    */
    @api
    getFormSectionValues() {
        let formSection = mutable(this.formSection);
        formSection.elements = this.getSectionFormFields();
        return formSection;
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
        let formSection = mutable(this.formSection);
        formSection.elements = this.getSectionFormFields();

        const formSectionLabelInputElement =
            this.template.querySelector('lightning-input[data-name="formSectionLabelInputElement"]');
        formSection.label = formSectionLabelInputElement.value;
        this.formSection = formSection;
        this.handleExitEditMode();
    }

    /*******************************************************************************
    * @description Dispatches an event to parent component geTemplateBuilderFormLayout
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
    * @description Dispatches an event up to parent component geTemplateFormLayout
    * to set the currently active section
    */
    handleSelectActiveSection(event) {
        this.dispatchEvent(new CustomEvent(
            'changeactivesection',
            { detail: this.formSection.id }));
    }

    /*******************************************************************************
    * @description Dispatches an event up to parent component geTemplateFormLayout
    * to shift the FormSection element up in the data structure
    */
    handleFormSectionUp() {
        this.dispatchEvent(new CustomEvent(
            'formsectionup',
            { detail: this.formSection.id }));
    }

    /*******************************************************************************
    * @description Dispatches an event up to parent component geTemplateFormLayout
    * to shift the FormSection element down in the data structure
    */
    handleFormSectionDown() {
        this.dispatchEvent(new CustomEvent(
            'formsectiondown',
            { detail: this.formSection.id }));
    }

    /*******************************************************************************
    * @description Dispatches an event up to parent component geTemplateFormLayout
    * to shift the FormField element up in the data structure
    *
    * @param {object} event: Custom Event received from child component
    * geTemplateBuilderFormField
    */
    handleFormFieldUp(event) {
        this.dispatchEvent(new CustomEvent(
            'formfieldup',
            { detail: event.detail }));
    }

    /*******************************************************************************
    * @description Dispatches an event up to parent component geTemplateFormLayout
    * to shift the FormField element down in the data structure
    *
    * @param {object} event: Custom Event received from child component
    * geTemplateBuilderFormField
    */
    handleFormFieldDown(event) {
        this.dispatchEvent(new CustomEvent(
            'formfielddown',
            { detail: event.detail }));
    }
}