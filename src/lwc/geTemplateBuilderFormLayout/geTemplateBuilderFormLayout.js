import { LightningElement, api } from 'lwc';

export default class GeTemplateBuilderFormLayout extends LightningElement {
    @api formSections = [];

    /*******************************************************************************
    * @description Handles setting the active section and updating the slds icon
    * across all sections.
    *
    * @param {object} event: Onclick event object from lightning-button
    */
    handleSelectActiveSection(event) {
        console.log('***handleSelectActiveSection');
        console.log('***************************');
        const sectionId = event.target.getAttribute('data-section-id');
        let buttons = this.template.querySelectorAll('lightning-button-icon[data-name="activeSectionButton"]');
        for (let i = 0; i < buttons.length; i++) {
            buttons[i].iconName = buttons[i].dataset.sectionId == sectionId ? 'utility:record' : 'utility:routing_offline';
        }

        this.dispatchEvent(new CustomEvent(
            'changeactivesection',
            { detail: sectionId }));
    }

    /*******************************************************************************
    * @description Sends an event up to parent component geTemplateBuilderGiftFields
    * for shifting the FormSection element up in the list and UI
    *
    * @param {object} event: Onclick event object from lightning-button
    */
    handleFormSectionUp(event) {
        this.dispatchEvent(new CustomEvent(
            'formsectionup',
            { detail: event.target.getAttribute('data-section-id') }));
    }

    /*******************************************************************************
    * @description Sends an event up to parent component geTemplateBuilderGiftFields
    * for shifting the FormSection element down in the list and UI
    *
    * @param {object} event: Onclick event object from lightning-button
    */
    handleFormSectionDown(event) {
        this.dispatchEvent(new CustomEvent(
            'formsectiondown',
            { detail: event.target.getAttribute('data-section-id') }));
    }

    /*******************************************************************************
    * @description Sends an event up to parent component geTemplateBuilderGiftFields
    * for shifting the FormField element up in the list and UI
    *
    * @param {object} event: Onclick event object from lightning-button
    */
    handleFormFieldUp(event) {
        this.dispatchEvent(new CustomEvent(
            'formfieldup',
            { detail: event.detail }));
    }

    /*******************************************************************************
    * @description Sends an event up to parent component geTemplateBuilderGiftFields
    * for shifting the FormField element down in the list and UI
    *
    * @param {object} event: Onclick event object from lightning-button
    */
    handleFormFieldDown(event) {
        this.dispatchEvent(new CustomEvent(
            'formfielddown',
            { detail: event.detail }));
    }
}