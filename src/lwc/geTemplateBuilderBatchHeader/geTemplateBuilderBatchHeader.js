import { LightningElement, track, api } from 'lwc';
import getBatchFields from '@salesforce/apex/GE_TemplateBuilderCtrl.getBatchFields';
import { FormField, findByProperty, shiftSelectedField, mutable } from 'c/utilTemplateBuilder';

export default class geTemplateBuilderBatchHeader extends LightningElement {
    @track isLoading = true;
    @track batchFields;
    @track selectedBatchFields;

    @api
    set selectedBatchFields(selectedBatchFields) {
        this.selectedBatchFields = selectedBatchFields;
    }

    connectedCallback() {
        this.init();
    }

    init = async () => {
        this.batchFields = await getBatchFields();
        console.log('Batch Fields: ', this.batchFields);
        this.toggleCheckboxForSelectedBatchFields();
        this.isLoading = false;
    }

    @api
    getTabData() {
        let selectedBatchFieldValues = this.template.querySelectorAll('c-ge-template-builder-form-field');

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

    /*******************************************************************************
    * @description Handles adding FormField objects to the selectedBatchFields
    * array. selectedBatchFields is used in the UI to render geTemplateBuilderFormField
    * components.
    *
    * @param {object} event: Onchange event object from lightning-input checkbox
    */
    handleSelectBatchField(event) {
        console.log('handleSelectBatchField');
        if (!this.selectedBatchFields) { this.selectedBatchFields = [] }
        console.log('Selected Batch Fields: ', mutable(this.selectedBatchFields));
        console.log('Field Name: ', event.target.value);
        let fieldName = event.target.value;
        // selectedField.value doesn't exist when retrieving from Form_Template__c
        // Align front end data and back end data structure
        let alreadySelected = this.selectedBatchFields.find(selectedField => selectedField.value === fieldName);
        console.log('alreadySelected? ', alreadySelected);
        if (alreadySelected) {
            for( let i = 0; i < this.selectedBatchFields.length; i++) {
                if ( this.selectedBatchFields[i].value === fieldName) {
                    this.selectedBatchFields.splice(i, 1);
                }
             }
        } else {
            /* Maye create a class for the batch header fields as well? */
            let field = new FormField(
                event.target.getAttribute('data-label'),
                false,
                event.target.value,
                false,
                undefined,
                undefined
            );
            console.log(field);

            this.selectedBatchFields.push(field);
        }
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
}