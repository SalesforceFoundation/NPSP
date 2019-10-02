import { LightningElement, track, api } from 'lwc';
import getBatchFields from '@salesforce/apex/GE_TemplateBuilderCtrl.getBatchFields';
import { findByProperty, shiftSelectedField, makeListLightningIterable } from 'c/utilTemplateBuilder';

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
        this.batchFields = makeListLightningIterable(await getBatchFields());
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

    /*******************************************************************************
    * @description Handles adding FormField objects to the selectedBatchFields
    * array. selectedBatchFields is used in the UI to render geTemplateBuilderFormField
    * components.
    *
    * @param {object} event: Onchange event object from lightning-input checkbox
    */
    handleSelectBatchField(event) {
        if (!this.selectedBatchFields) { this.selectedBatchFields = [] }

        let fieldName = event.target.value;
        let alreadySelected = this.selectedBatchFields.find(selectedField => selectedField.value === fieldName);

        if (alreadySelected) {
            for( let i = 0; i < this.selectedBatchFields.length; i++) {
                if ( this.selectedBatchFields[i].value === fieldName) {
                    this.selectedBatchFields.splice(i, 1);
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