import { LightningElement, track } from 'lwc';
import getBatchFields from '@salesforce/apex/GE_TemplateBuilderCtrl.getBatchFields';
import { findByProperty, shiftSelectedField, makeListLightningIterable } from 'c/utilTemplateBuilder';

export default class geTemplateBuilderBatchHeader extends LightningElement {
    @track batchFields;
    @track _selectedBatchFields;
    @track isLoading = true;

    connectedCallback() {
        this.init();
    }

    init = async () => {
        this.batchFields = makeListLightningIterable(await getBatchFields());
        this.isLoading = false;
    }

    /*******************************************************************************
    * @description Sends an event up to geTemplateBuilder for tab navigation
    *
    * @param {object} event: Onclick event object from lightning-button
    */
    handleGoToTab(event) {
        let selectedBatchFieldValues = this.template.querySelectorAll('c-ge-template-builder-form-field');

        let batchHeader = {
            sourceTab: 'geTemplateBuilderBatchHeader',
            batchFields: []
        };

        for (let i = 0; i < selectedBatchFieldValues.length; i++) {
            let batchField = selectedBatchFieldValues[i].getFormFieldValues();
            batchHeader.batchFields.push(batchField);
        }

        let detail = {
            tabData: batchHeader,
            tabValue: event.target.getAttribute('data-tab-value')
        }

        this.dispatchEvent(new CustomEvent('gototab', { detail: detail }));
    }

    /*******************************************************************************
    * @description Handles adding FormField objects to the _selectedBatchFields
    * array. _selectedBatchFields is used in the UI to render geTemplateBuilderFormField
    * components.
    *
    * @param {object} event: Onchange event object from lightning-input checkbox
    */
    handleSelectBatchField(event) {
        if (!this._selectedBatchFields) { this._selectedBatchFields = [] }

        let fieldName = event.target.value;
        let alreadySelected = this._selectedBatchFields.find(selectedField => selectedField.value === fieldName);

        if (alreadySelected) {
            for( let i = 0; i < this._selectedBatchFields.length; i++){ 
                if ( this._selectedBatchFields[i].value === fieldName) {
                    this._selectedBatchFields.splice(i, 1); 
                }
             }
        } else {
            /* Maye create a class for the batch header fields as well? */
            let field = {
                id: event.target.getAttribute('data-id'),
                label: event.target.getAttribute('data-label'),
                value: fieldName,
                required: false,
                allowDefaultValue: false,
                defaultValue: undefined
            };

            this._selectedBatchFields.push(field);
        }
    }

    /*******************************************************************************
    * @description Handles shifting the FormField element up in the list and UI
    *
    * @param {object} event: Onclick event object from lightning-button
    */
    handleFormFieldUp(event) {
        let oldIndex = findByProperty(this._selectedBatchFields, 'value', event.detail.value);
        if (oldIndex > 0) {
            shiftSelectedField(this._selectedBatchFields, oldIndex, oldIndex - 1);
        }
    }

    /*******************************************************************************
    * @description Handles shifting the FormField element down in the list and UI
    *
    * @param {object} event: Onclick event object from lightning-button
    */
    handleFormFieldDown(event) {
        let oldIndex = findByProperty(this._selectedBatchFields, 'value', event.detail.value);
        if (oldIndex < this._selectedBatchFields.length - 1) {
            shiftSelectedField(this._selectedBatchFields, oldIndex, oldIndex + 1);
        }
    }
}