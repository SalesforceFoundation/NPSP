import { LightningElement, track, api } from 'lwc';
import getBatchFields from '@salesforce/apex/GE_TemplateBuilderCtrl.getBatchFields';
import { FormField, findByProperty, shiftSelectedField, mutable } from 'c/utilTemplateBuilder';

export default class geTemplateBuilderBatchHeader extends LightningElement {
    @track isLoading = true;
    @track batchFields;
    @track selectedBatchFields;

    /* Public setter for the tracked property selectedBatchFields
    Needs to be revisited, WIP tied to retrieving and rendering an existing template */
    @api
    set selectedBatchFields(selectedBatchFields) {
        this.selectedBatchFields = selectedBatchFields;
    }

    connectedCallback() {
        this.init();
    }

    init = async () => {
        this.batchFields = await getBatchFields();
        this.toggleCheckboxForSelectedBatchFields();
        this.isLoading = false;
    }

    /*******************************************************************************
    * @description Public method that returns a list of batch header field instances
    * of the FormField class. Called when saving a form template.
    *
    * @return {list} batchHeaderFields: List of batch header field instances of the
    * FormField class.
    */
    @api
    getTabData() {
        const selectedBatchFieldValues = this.template.querySelectorAll('c-ge-template-builder-form-field');

        let batchHeaderFields = [];

        for (let i = 0; i < selectedBatchFieldValues.length; i++) {
            let batchField = selectedBatchFieldValues[i].getFormFieldValues();
            batchHeaderFields.push(batchField);
        }

        return batchHeaderFields;
    }

    /*******************************************************************************
    * @description Sends an event up to geTemplateBuilder for tab navigation
    *
    * @param {object} event: Onclick event object from lightning-button
    */
    handleGoToTab(event) {
        let detail = {
            tabData: this.getTabData(),
            tabValue: event.target.getAttribute('data-tab-value')
        }

        this.dispatchEvent(new CustomEvent('gototab', { detail: detail }));
    }

    /*******************************************************************************
    * @description Onchange event handler for the batch header field checkboxes.
    * Adds FormField objects to the selectedBatchFields array.
    * selectedBatchFields is used in the UI to render instances of the
    * geTemplateBuilderFormField component.
    *
    * @param {object} event: Onchange event object from lightning-input checkbox
    */
    handleSelectBatchField(event) {
        if (!this.selectedBatchFields) { this.selectedBatchFields = [] }

        const fieldName = event.target.value;
        const index = findByProperty(this.selectedBatchFields, 'value', fieldName);
        const addSelectedField = index === -1 ? true : false;

        if (addSelectedField) {
            this.addField(event.target);
        } else {
            this.removeField(index);
        }
    }

    /*******************************************************************************
    * @description Adds a field to the selected fields
    *
    * @param {object} target: Object containing the label and value of the field
    * to be added
    */
    addField(target) {
        let field = new FormField(
            target.label,
            false,
            target.value,
            false,
            undefined,
            undefined
        );

        this.selectedBatchFields.push(field);
    }

    /*******************************************************************************
    * @description Removes a field from the selected fields by index
    *
    * @param {integer} index: Index of the field to be removed
    */
    removeField(index) {
        this.selectedBatchFields.splice(index, 1);
    }

    /*******************************************************************************
    * @description Handles shifting the FormField element up in the list and UI
    *
    * @param {object} event: Onclick event object from lightning-button
    */
    handleFormFieldUp(event) {
        let oldIndex = findByProperty(this.selectedBatchFields, 'value', event.detail.value);
        if (oldIndex > 0) {
            shiftSelectedField(this.selectedBatchFields, oldIndex, oldIndex - 1);
        }
    }

    /*******************************************************************************
    * @description Handles shifting the FormField element down in the list and UI
    *
    * @param {object} event: Onclick event object from lightning-button
    */
    handleFormFieldDown(event) {
        let oldIndex = findByProperty(this.selectedBatchFields, 'value', event.detail.value);
        if (oldIndex < this.selectedBatchFields.length - 1) {
            shiftSelectedField(this.selectedBatchFields, oldIndex, oldIndex + 1);
        }
    }

    /*******************************************************************************
    * @description WIP. Function toggles the checkboxes for any existing/selected batch
    * header fields. Used when retrieving an existing form template.
    */
    toggleCheckboxForSelectedBatchFields() {
        console.log('toggleCheckboxForSelectedBatchFields');
        let _batchFields = mutable(this.batchFields);
        if (this.selectedBatchFields && this.selectedBatchFields.length > 0) {
            for (let i = 0; i < this.selectedBatchFields.length; i++) {
                const selectedBatchField = this.selectedBatchFields[i];
                const batchFieldIndex = findByProperty(
                    _batchFields,
                    'value',
                    selectedBatchField.dataImportFieldMappingDevNames[0]);

                console.log('Preselected Index: ', batchFieldIndex);
                console.log('Batch Field: ', _batchFields[batchFieldIndex]);
                _batchFields[batchFieldIndex].checked = true;
            }

            console.log('Batch Fields: ', _batchFields);
            this.batchFields = _batchFields;
        }
    }
}