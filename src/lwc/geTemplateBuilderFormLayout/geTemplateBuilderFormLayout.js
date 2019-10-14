import { LightningElement, api, track } from 'lwc';
import { FormLayout, mutable } from 'c/utilTemplateBuilder';

export default class GeTemplateBuilderFormLayout extends LightningElement {
    @api fieldMappingSet;
    @track activeFormSectionId;

    @track formSections = [];
    /* Public setter for the tracked property selectedFieldMappingSet */
    // TODO: Needs to be revisited, WIP tied to retrieving and rendering an existing template
    @api
    set formSections(formSections) {
        this.formSections = formSections;
    }

    /*******************************************************************************
    * @description Public method that returns an instance of FormLayout.
    *
    * @return {object} formLayout: Instance of FormLayout containing FormSections
    * and FormFields
    */
    @api
    getFormLayout() {
        let formSectionComponents = this.template.querySelectorAll('c-ge-template-builder-form-section');
        let formSections = [];
        for (let i = 0; i < formSectionComponents.length; i++) {
            let formSection = formSectionComponents[i].getFormSectionValues();
            formSections.push(formSection);
        }

        /* Where's this version number going to come from? */
        const version = '1.0';
        let formLayout = new FormLayout(this.fieldMappingSet, version, formSections);
        return formLayout;
    }

    /*******************************************************************************
    * @description Handles setting the active section and updating the slds icon
    * across all sections.
    *
    * @param {object} event: Onclick event object from lightning-button
    */
    handleSelectActiveSection(event) {
        const sectionId = event.detail;
        this.activeFormSectionId = sectionId;

        this.dispatchEvent(new CustomEvent(
            'changeactivesection',
            { detail: sectionId }));
    }

    /*******************************************************************************
    * @description Removes a section and dispatches a 'deleteformsection' custom event
    * to parent component geTemplateBuilderGiftFields.
    *
    * @param {object} event: Onclick event object from lightning-button
    */
    handleDeleteFormSection(event) {
        const formSection = event.detail;

        let formSections = mutable(this.formSections);
        for (let i = 0; i < formSections.length; i++) {
            if (formSections[i].id === formSection.id) {
                formSections.splice(i, 1);
            }
        }

        this.formSections = formSections;

        this.dispatchEvent(new CustomEvent(
            'deleteformsection',
            { detail: { formSections: formSections, formSection: formSection } }));
    }

    /*******************************************************************************
    * @description Sends an event up to parent component geTemplateBuilderGiftFields
    * for shifting the FormSection element up in the list and UI
    *
    * @param {object} event: Onclick event object from lightning-button
    */
    handleFormSectionUp(event) {
        const sectionId = event.detail;
        this.dispatchEvent(new CustomEvent(
            'formsectionup',
            { detail: sectionId }));
    }

    /*******************************************************************************
    * @description Sends an event up to parent component geTemplateBuilderGiftFields
    * for shifting the FormSection element down in the list and UI
    *
    * @param {object} event: Onclick event object from lightning-button
    */
    handleFormSectionDown(event) {
        const sectionId = event.detail;
        this.dispatchEvent(new CustomEvent(
            'formsectiondown',
            { detail: sectionId }));
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