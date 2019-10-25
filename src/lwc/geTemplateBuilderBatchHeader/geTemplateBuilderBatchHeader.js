import { LightningElement, track, api } from 'lwc';
import getBatchFields from '@salesforce/apex/GE_TemplateBuilderCtrl.getBatchFields';
import { BatchHeaderField, findIndexByProperty, mutable, sort, dispatch, handleError } from 'c/utilTemplateBuilder';

const REQUIRED_FIELDS = [
    'Name'
];
Object.freeze(REQUIRED_FIELDS);

export default class geTemplateBuilderBatchHeader extends LightningElement {
    @track isLoading = true;
    @track batchFields;
    @api selectedBatchFields;

    connectedCallback() {
        this.isLoading = true;
        this.init();
    }

    @api
    init = async () => {
        try {
            this.batchFields = await getBatchFields();
            this.batchFields = sort(this.batchFields, 'label', 'asc');
            this.handleRequiredFields();
            this.toggleCheckboxForSelectedBatchFields();
            this.isLoading = false;
        } catch (error) {
            handleError(this, error);
            this.isLoading = false;
        }
    }

    /*******************************************************************************
    * @description Public method that collects form field values from all instances
    * of child component geTemplateBuilderFormField.
    *
    * @return {list} batchHeaderFields: List of utilTemplateBuiilder.BatchHeaderField
    * instances.
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
    * @description Receives event from child component and dispatches event to
    * parent to update a batch header field's details.
    *
    * @param {object} event: Event received from child component.
    * component chain: geTemplateBuilderFormField -> here
    */
    handleUpdateBatchHeaderField(event) {
        dispatch(this, 'updatebatchheaderfield', event.detail);
    }

    /*******************************************************************************
    * @description Receives event from child component and dispatches event to
    * parent to move a batch header field up.
    *
    * @param {object} event: Event received from child component.
    * component chain: geTemplateBuilderFormField -> here
    */
    handleFormFieldUp(event) {
        dispatch(this, 'batchheaderfieldup', event.detail);
    }

    /*******************************************************************************
    * @description Receives event from child component and dispatches event to
    * parent to move a batch header field down.
    *
    * @param {object} event: Event received from child component.
    * component chain: geTemplateBuilderFormField -> here
    */
    handleFormFieldDown(event) {
        dispatch(this, 'batchheaderfielddown', event.detail);
    }

    /*******************************************************************************
    * @description Onchange event handler for the batch header field checkboxes.
    * Adds/removes batch header fields.
    *
    * @param {object} event: Onchange event object from lightning-input checkbox
    */
    handleSelectBatchField(event) {
        const fieldName = event.target.value;
        const index = findIndexByProperty(this.selectedBatchFields, 'value', fieldName);
        const addSelectedField = index === -1 ? true : false;

        if (addSelectedField) {
            this.addField(fieldName)
        } else {
            this.removeField(index, fieldName);
        }
    }

    /*******************************************************************************
    * @description Creates an instance of BatchHeaderField. Dispatches an event to
    * notify parent component geTemplateBuilder that a new batch header field
    * needs to be added.
    *
    * @param {string} fieldName: DataImport__c field api name
    */
    addField(fieldName) {
        let batchField = this.batchFields.find(bf => {
            return bf.value === fieldName;
        });

        let field = new BatchHeaderField(
            batchField.label,
            batchField.value,
            batchField.isRequired,
            batchField.isRequiredFieldDisabled,
            false,
            null,
            batchField.dataType,
            batchField.picklistOptions
        );

        dispatch(this, 'addbatchheaderfield', field);

        const batchFieldIndex = findIndexByProperty(
            this.batchFields,
            'value',
            fieldName);
        this.batchFields[batchFieldIndex].checked = true;
    }

    /*******************************************************************************
    * @description Finds the index of the BatchHeaderField to be removed. Dispatches
    * an event to notify parent component geTemplateBuilder that a batch header field
    * needs to be removed.
    *
    * @param {integer} index: Index of field in the selectedBatchHeaderFields
    * @param {string} fieldName: DataImport__c field api name
    */
    removeField(index, fieldName) {
        const batchFieldIndex = findIndexByProperty(
            this.batchFields,
            'value',
            fieldName);
        this.batchFields[batchFieldIndex].checked = false;

        dispatch(this, 'removebatchheaderfield', index);
    }

    /*******************************************************************************
    * @description Receives event from child component and calls removeField method
    * to dispatch an event notifying parent component geTemplateBuilder that a
    * batch header field needs to be removed.
    *
    * @param {object} event: Event received from child component.
    * component chain: geTemplateBuilderFormField -> here
    */
    handleDeleteBatchHeaderField(event) {
        const fieldName = event.detail;
        const index = findIndexByProperty(this.selectedBatchFields, 'value', fieldName);
        this.removeField(index, fieldName);
    }

    /*******************************************************************************
    * @description Adds required fields to selectedBatchFields property and toggles
    * their respective checkboxes.
    */
    handleRequiredFields() {
        for (let i = 0; i < this.batchFields.length; i++) {
            if (REQUIRED_FIELDS.includes(this.batchFields[i].value)) {
                this.batchFields[i].isRequired = true;
                this.batchFields[i].isRequiredFieldDisabled = true;
            }
        }

        const requiredFields = this.batchFields.filter(batchField => { return batchField.isRequired });

        const selectedFieldsExists = this.selectedBatchFields && this.selectedBatchFields.length > 0;

        requiredFields.forEach((field) => {
            if (selectedFieldsExists) {
                const alreadySelected = this.batchFields.find(bf => { return bf.value === field.value; });
                if (alreadySelected) { return; }
            }

            this.addField(field.value);
        });
    }

    // TODO: Need to finish or scrap the incomplete function below
    /*******************************************************************************
    * @description WIP. Function toggles the checkboxes for any existing/selected batch
    * header fields. Used when retrieving an existing form template.
    */
    toggleCheckboxForSelectedBatchFields() {
        if (this.selectedBatchFields && this.selectedBatchFields.length > 0) {
            let _batchFields = mutable(this.batchFields);

            for (let i = 0; i < this.selectedBatchFields.length; i++) {
                const selectedBatchField = this.selectedBatchFields[i];
                const batchFieldIndex = findIndexByProperty(
                    _batchFields,
                    'value',
                    selectedBatchField.value);

                _batchFields[batchFieldIndex].checked = true;
            }

            this.batchFields = _batchFields;
        }
    }
}