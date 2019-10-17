import { LightningElement, api, track } from 'lwc';
import { mutable, inputTypeByDescribeType, lightningInputTypeByDataType, showToast } from 'c/utilTemplateBuilder';

export default class geTemplateBuilderFormField extends LightningElement {
    @track field;

    @api
    set field(field) {
        this.field = field;
    }

    get isDefaultValueAllowed() {
        return this.field.allowDefaultValue ? false : true;
    }

    get isRequired() {
        return (this.field.required === 'Yes' || this.field.required === true) ? true : false;
    }

    get isLightningTextarea() {
        return this.lightningInputType === 'textarea' ? true : false;
    }

    get isLightningCombobox() {
        return this.lightningInputType === 'combobox' ? true : false;
    }

    get isLightningSearch() {
        return this.lightningInputType === 'search' ? true : false;
    }

    /* Needs to be reworked */
    get isLightningRichText() {
        return this.lightningInputType === 'richtext' ? true : false;
    }

    get isLightningInput() {
        if (this.lightningInputType !== 'textarea' &&
            this.lightningInputType !== 'combobox' &&
            this.lightningInputType !== 'richtext' &&
            this.lightningInputType !== 'search') {
            return true;
        }
        return false;
    }

    get lightningInputType() {
        return this.field.dataType ? inputTypeByDescribeType[this.field.dataType.toLowerCase()] : 'text';
    }

    // TODO: Needs to be completed for lookup fields
    handleSearch(event) {
        console.log('handle search');
        const isEnterKey = event.keyCode === 13;
        if (isEnterKey) {
            showToast(this, 'Search Test', event.target.value, 'warning');
        }
    }

    /* TODO: Delete later. For debugging only */
    connectedCallback() {
        //console.log('FIELD: ', mutable(this.field));
        //console.log('TYPE: ', this.lightningInputType);
    }

    /*******************************************************************************
    * @description Dispatches an event up to parent component to shift the FormField
    * up in the data structure.
    */
    handleFormFieldUp() {
        const field = this.getFormFieldValues();
        this.dispatchEvent(new CustomEvent(
            'formfieldup',
            { detail: field }));
    }

    /*******************************************************************************
    * @description Dispatches an event up to parent component to shift the FormField
    * down in the data structure.
    */
    handleFormFieldDown() {
        const field = this.getFormFieldValues();
        this.dispatchEvent(new CustomEvent(
            'formfielddown',
            { detail: field }));
    }

    /*******************************************************************************
    * @description Enables the 'Default Value' input field.
    * 
    * @param {object} event: Onchange event from lightning-input checkbox
    */
    handleToggleDefaultValue(event) {
        let field = mutable(this.field);
        field.allowDefaultValue = !field.allowDefaultValue;
        if (!field.allowDefaultValue) {
            field.defaultValue = '';
        }
        this.field = field;
    }

    /*******************************************************************************
    * @description Public method that collects the current values of all the relevant
    * input fields for this FormField and return an instance of FormField. 
    * 
    * @return {object} field: Instance of the FormField class
    */
    @api
    getFormFieldValues() {
        const elementType = lightningInputTypeByDataType[this.lightningInputType] ? lightningInputTypeByDataType[this.lightningInputType] : 'lightning-input';
        const required = this.template.querySelector('lightning-input[data-name="required"]').checked;
        const allowDefaultValue = this.template.querySelector('lightning-input[data-name="allowDefaultValue"]').checked;
        const customLabel = this.template.querySelector('lightning-input[data-name="customLabel"]').value;
        let defaultValue = allowDefaultValue ? this.template.querySelector(`${elementType}[data-name="defaultValue"]`).value : undefined;

        // TODO: Clean up way of getting default value if checkbox
        if (allowDefaultValue && this.field.dataType && this.field.dataType.toLowerCase() === 'boolean') {
            defaultValue = this.template.querySelector(`${elementType}[data-name="defaultValue"]`).checked;
        }

        let field = mutable(this.field);
        field.required = required;
        field.allowDefaultValue = allowDefaultValue;
        field.defaultValue = defaultValue;
        field.elementType = elementType;
        field.displayRule = undefined;
        field.validationRule = undefined;
        field.customLabel = customLabel;
        field.dataImportFieldMappingDevNames = [field.value];

        return field;
    }
}