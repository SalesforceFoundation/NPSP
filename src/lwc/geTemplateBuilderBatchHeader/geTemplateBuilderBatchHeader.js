import { LightningElement, track, api } from 'lwc';
import {
    findIndexByProperty,
    mutable,
    dispatch,
    handleError,
    findMissingRequiredBatchFields
} from 'c/utilTemplateBuilder';
import DI_BATCH_INFO from '@salesforce/schema/DataImportBatch__c';

const PROP_API_NAME = 'apiName';
const PROP_BATCH_HEADER_TAB_ERROR = 'hasBatchHeaderTabError';
const EVENT_UPDATE_VALIDITY = 'updatevalidity';
const EVENT_BATCH_HEADER_FIELD_UPDATE = 'updatebatchheaderfield';
const EVENT_BATCH_HEADER_FIELD_UP = 'batchheaderfieldup';
const EVENT_BATCH_HEADER_FIELD_DOWN = 'batchheaderfielddown';
const EVENT_BATCH_HEADER_FIELD_ADD = 'addbatchheaderfield';
const EVENT_BATCH_HEADER_FIELD_REMOVE = 'removebatchheaderfield';

export default class geTemplateBuilderBatchHeader extends LightningElement {
    @track isLoading = true;
    @api batchFields;
    @api selectedBatchFields;
    @track hasErrors;
    @api missingRequiredFields;
    isInitialized = false;

    get dataImportBatchName() {
        return DI_BATCH_INFO && DI_BATCH_INFO.objectApiName ? DI_BATCH_INFO.objectApiName : null;
    }

    renderedCallback() {
        if (!this.isInitialized && this.isLoading === false) {
            this.isInitialized = true;
            this.validate();
        }
    }

    connectedCallback() {
        try {
            this.handleRequiredFields();
            this.toggleCheckboxForSelectedBatchFields();
            this.validate();
            this.isLoading = false;
        } catch (error) {
            handleError(this, error);
            this.isLoading = false;
        }
    }

    /*******************************************************************************
    * @description Checks to see if there are any errors for the tab. Currently only
    * checks for missing required fields.
    *
    * @return {boolean} hasErrors: Returns true if tab has any errors.
    */
    @api
    validate() {
        this.hasErrors = this.hasMissingRequiredFields();
        return !this.hasErrors;
    }

    /*******************************************************************************
    * @description Checks for any missing required DataImportBatch__c fields.
    *
    * @return {boolean} hasMissingFields: Returns true if any DataImportBatch__c
    * fields are missing.
    */
    hasMissingRequiredFields() {
        let hasMissingFields = false;
        if (this.missingRequiredFields === null || this.missingRequiredFields.length === 0) {
            this.missingRequiredFields = findMissingRequiredBatchFields(this.batchFields, this.selectedBatchFields);
        }

        if (this.missingRequiredFields && this.missingRequiredFields.length > 0) {
            dispatch(this, EVENT_UPDATE_VALIDITY, {
                property: PROP_BATCH_HEADER_TAB_ERROR,
                hasError: false
            });
            hasMissingFields = true;
        } else {
            hasMissingFields = false;
        }

        return hasMissingFields;
    }

    /*******************************************************************************
    * @description Receives event from child component and dispatches event to
    * parent to update a batch header field's details.
    *
    * @param {object} event: Event received from child component.
    * component chain: geTemplateBuilderFormField -> here
    */
    handleUpdateBatchHeaderField(event) {
        dispatch(this, EVENT_BATCH_HEADER_FIELD_UPDATE, event.detail);
    }

    /*******************************************************************************
    * @description Receives event from child component and dispatches event to
    * parent to move a batch header field up.
    *
    * @param {object} event: Event received from child component.
    * component chain: geTemplateBuilderFormField -> here
    */
    handleFormElementUp(event) {
        dispatch(this, EVENT_BATCH_HEADER_FIELD_UP, event.detail);
    }

    /*******************************************************************************
    * @description Receives event from child component and dispatches event to
    * parent to move a batch header field down.
    *
    * @param {object} event: Event received from child component.
    * component chain: geTemplateBuilderFormField -> here
    */
    handleFormElementDown(event) {
        dispatch(this, EVENT_BATCH_HEADER_FIELD_DOWN, event.detail);
    }

    /*******************************************************************************
    * @description Onchange event handler for the batch header field checkboxes.
    * Adds/removes batch header fields.
    *
    * @param {object} event: Onchange event object from lightning-input checkbox
    */
    handleToggleBatchField(event) {
        const fieldName = event.target.value;
        const index = findIndexByProperty(this.selectedBatchFields, PROP_API_NAME, fieldName);
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
        let batchFields = mutable(this.batchFields);

        dispatch(this, EVENT_BATCH_HEADER_FIELD_ADD, fieldName);

        const batchFieldIndex = findIndexByProperty(
            batchFields,
            PROP_API_NAME,
            fieldName);
        batchFields[batchFieldIndex].checked = true;
        this.batchFields = batchFields;
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
            PROP_API_NAME,
            fieldName);
        this.batchFields[batchFieldIndex].checked = false;

        dispatch(this, EVENT_BATCH_HEADER_FIELD_REMOVE, index);
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
        const fieldName = event.detail.fieldName;
        const index = findIndexByProperty(this.selectedBatchFields, PROP_API_NAME, fieldName);
        this.removeField(index, fieldName);
    }

    /*******************************************************************************
    * @description Adds required fields to selectedBatchFields property
    */
    handleRequiredFields() {
        const requiredFields = this.batchFields.filter(batchField => { return batchField.required });
        const selectedFieldsExists = this.selectedBatchFields && this.selectedBatchFields.length > 0;

        requiredFields.forEach((field) => {
            if (selectedFieldsExists) {
                const alreadySelected = this.selectedBatchFields.find(bf => { return bf.apiName === field.apiName; });
                if (alreadySelected) { return; }
            }

            this.addField(field.apiName);
        });
    }

    /*******************************************************************************
    * @description Method toggles the checkboxes for any existing/selected batch
    * header fields. Used when retrieving an existing form template.
    */
    toggleCheckboxForSelectedBatchFields() {
        if (this.selectedBatchFields && this.selectedBatchFields.length > 0) {
            let _batchFields = mutable(this.batchFields);

            for (let i = 0; i < this.selectedBatchFields.length; i++) {
                const selectedBatchField = this.selectedBatchFields[i];
                const batchFieldIndex = findIndexByProperty(
                    _batchFields,
                    PROP_API_NAME,
                    selectedBatchField.apiName);

                _batchFields[batchFieldIndex].checked = true;
            }

            this.batchFields = _batchFields;
        }
    }
}
