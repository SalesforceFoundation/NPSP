import { LightningElement, track, api, wire } from 'lwc';
import { findIndexByProperty, mutable, sort, dispatch, handleError } from 'c/utilTemplateBuilder';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import DATA_IMPORT_BATCH_OBJECT from '@salesforce/schema/DataImportBatch__c';

const ADDITIONAL_REQUIRED_FIELDS = [
    'Name'
];
Object.freeze(ADDITIONAL_REQUIRED_FIELDS);

const BLACKLISTED_FIELDS = [
    'Batch_Process_Size__c',
    'Run_Opportunity_Rollups_while_Processing__c',
    'Donation_Matching_Behavior__c',
    'Donation_Matching_Implementing_Class__c',
    'Donation_Matching_Rule__c',
    'Donation_Date_Range__c',
    'Post_Process_Implementing_Class__c',
    'OwnerId',
];
Object.freeze(BLACKLISTED_FIELDS);

const SORTED_BY = 'required';
const SORT_ORDER = 'desc';
const PICKLIST = 'Picklist';
const API_NAME = 'apiName';
const NAMESPACE = 'npsp__';

export default class geTemplateBuilderBatchHeader extends LightningElement {
    @track isLoading = true;
    @track batchFields = [];
    @api selectedBatchFields;
    dataImportBatchInfo;
    wireAdapterArg;

    @wire(getObjectInfo, { objectApiName: DATA_IMPORT_BATCH_OBJECT })
    wiredBatchDataImportObject({ error, data }) {
        if (data) {
            this.dataImportBatchInfo = data;
            this.init();
        } else if (error) {
            console.log(error);
        }
    }

    connectedCallback() {
        if (this.dataImportBatchInfo) {
            this.handleRequiredFields();
            this.toggleCheckboxForSelectedBatchFields();
        }
    }

    @api
    init = async () => {
        try {
            let batchFields = mutable(this.dataImportBatchInfo.fields);

            Object.getOwnPropertyNames(batchFields).forEach((key) => {
                let field = batchFields[key];

                if (BLACKLISTED_FIELDS.includes(field.apiName.replace(NAMESPACE, ''))) {
                    return;
                }

                if (field.dataType === PICKLIST) {
                    field.isPicklist = true;
                } else {
                    field.isPicklist = false;
                }

                field.fieldInfo = {
                    fieldApiName: field.apiName || field.value,
                    objectApiName: this.dataImportBatchInfo.apiName,
                    defaultRecordTypeId: this.dataImportBatchInfo.defaultRecordTypeId
                }

                if (ADDITIONAL_REQUIRED_FIELDS.includes(field.apiName)) {
                    field.required = true;
                }

                if (field.createable && field.updateable) {
                    if (field.required) {
                        field.checked = true;
                        field.isRequiredFieldDisabled = true;
                    } else {
                        field.checked = false;
                        field.isRequiredFieldDisabled = false;
                    }

                    this.batchFields.push(field);
                }
            });

            this.batchFields = sort(this.batchFields, SORTED_BY, SORT_ORDER);
            this.handleRequiredFields();
            this.toggleCheckboxForSelectedBatchFields();
            this.isLoading = false;
        } catch (error) {
            console.log(error);
            handleError(this, error);
            this.isLoading = false;
        }
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
    handleToggleBatchField(event) {
        const fieldName = event.target.value;
        const index = findIndexByProperty(this.selectedBatchFields, API_NAME, fieldName);
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
            return bf.apiName === fieldName;
        });

        let field = {
            label: batchField.label,
            apiName: batchField.apiName,
            required: batchField.required,
            isRequiredFieldDisabled: batchField.isRequiredFieldDisabled,
            allowDefaultValue: true,
            defaultValue: null,
            dataType: batchField.dataType,
            fieldInfo: batchField.fieldInfo
        }

        dispatch(this, 'addbatchheaderfield', field);

        const batchFieldIndex = findIndexByProperty(
            this.batchFields,
            API_NAME,
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
            API_NAME,
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
        const fieldName = event.detail.fieldName;
        const index = findIndexByProperty(this.selectedBatchFields, API_NAME, fieldName);
        this.removeField(index, fieldName);
    }

    /*******************************************************************************
    * @description Adds required fields to selectedBatchFields property and toggles
    * their respective checkboxes.
    */
    handleRequiredFields() {
        for (let i = 0; i < this.batchFields.length; i++) {
            if (ADDITIONAL_REQUIRED_FIELDS.includes(this.batchFields[i].apiName)) {
                this.batchFields[i].required = true;
                this.batchFields[i].isRequiredFieldDisabled = true;
            }
        }

        const requiredFields = this.batchFields.filter(batchField => { return batchField.required });

        const selectedFieldsExists = this.selectedBatchFields && this.selectedBatchFields.length > 0;

        requiredFields.forEach((field) => {
            if (selectedFieldsExists) {
                const alreadySelected = this.batchFields.find(bf => { return bf.apiName === field.apiName; });
                if (alreadySelected) { return; }
            }

            this.addField(field.apiName);
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
                    API_NAME,
                    selectedBatchField.apiName);

                _batchFields[batchFieldIndex].checked = true;
            }

            this.batchFields = _batchFields;
        }
    }
}