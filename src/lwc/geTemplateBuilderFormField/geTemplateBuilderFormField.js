/* eslint-disable no-console */
import { LightningElement, api } from 'lwc';
import { mutable } from 'c/utilTemplateBuilder';

export default class geTemplateBuilderFormField extends LightningElement {
    @api field;

    /*******************************************************************************
    * @description Sends an event up to geTemplateBuilder to shift the FormField
    * up in the array and UI.
    */
    handleFormFieldUp() {
        console.log('geTemplateBuilderFormField | handleFormFieldUp');
        const field = this.getFormFieldValues();
        this.dispatchEvent(new CustomEvent('formfieldup', { detail: field }));
    }

    /*******************************************************************************
    * @description Sends an event up to geTemplateBuilder to shift the FormField
    * down in the array and UI.
    */
    handleFormFieldDown() {
        const field = this.getFormFieldValues();
        this.dispatchEvent(new CustomEvent('formfielddown', { detail: field }));
    }

    /*******************************************************************************
    * @description Enables the 'Default Value' input field.
    * 
    * @param {object} event: Onchange event from lightning-input checkbox
    */
    handleAllowDefaultValue(event) {
        let defaultValueInputField = this.template.querySelector('lightning-input[data-name="defaultValue"]');
        defaultValueInputField.disabled = !event.target.checked;
    }

    /*******************************************************************************
    * @description Public method that collects the current values of all the relevant
    * input fields for this FormField and return an instance of FormField. 
    * 
    * @return {object} field: Instance of the FormField class
    */
    @api
    getFormFieldValues() {
        let required = this.template.querySelector('lightning-input[data-name="required"]').checked;
        let allowDefaultValue = this.template.querySelector('lightning-input[data-name="allowDefaultValue"]').checked;
        let defaultValue = allowDefaultValue ? this.template.querySelector('lightning-input[data-name="defaultValue"]').value : undefined;

        let field = mutable(this.field);
        field.required = required;
        field.allowDefaultValue = allowDefaultValue;
        field.defaultValue = defaultValue;

        return field;
    }
}