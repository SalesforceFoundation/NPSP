import { LightningElement, api, track } from 'lwc';
import { FormLayout } from 'c/utilTemplateBuilder';

export default class GeTemplateBuilderFormLayout extends LightningElement {
    @track formSections = [];
    @api fieldMappingSet;

    @api
    set formSections(formSections) {
        this.formSections = formSections;
    }

    @track activeFormSectionId;

    @api
    getFormSections() {
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
        console.log('***handleSelectActiveSection | FormLayout');
        console.log('***************************');
        const sectionId = event.detail;
        this.activeFormSectionId = sectionId;

        this.dispatchEvent(new CustomEvent(
            'changeactivesection',
            { detail: sectionId }));
    }

    handleDeleteFormSection(event) {
        const formSection = event.detail;
        for (let i = 0; i < this.formSections.length; i++) {
            if (this.formSections[i].id === formSection.id) {
                this.formSections.splice(i, 1);
            }
        }

        this.dispatchEvent(new CustomEvent(
            'deleteformsection',
            { detail: formSection }));
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