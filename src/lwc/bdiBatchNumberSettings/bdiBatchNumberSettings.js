import {LightningElement, wire} from 'lwc';
import isSysAdmin from '@salesforce/apex/BDI_BatchNumberSettingsController.isSysAdmin';
import save from '@salesforce/apex/BDI_BatchNumberSettingsController.save';
import activate from '@salesforce/apex/BDI_BatchNumberSettingsController.activate';
import deactivate from '@salesforce/apex/BDI_BatchNumberSettingsController.deactivate';
import getAutoNumbers from '@salesforce/apex/BDI_BatchNumberSettingsController.getAutoNumbers';
import getFieldDescribes from '@salesforce/apex/BDI_BatchNumberSettingsController.getFieldDescribes';

import DataImportBatch from '@salesforce/schema/DataImportBatch__c';
import Batch_Number from '@salesforce/schema/DataImportBatch__c.Batch_Number__c';

import Description from '@salesforce/schema/AutoNumber__c.Description__c';
import Display_Format from '@salesforce/schema/AutoNumber__c.Display_Format__c';
import Field_API_Name from '@salesforce/schema/AutoNumber__c.Field_API_Name__c';
import IsActive from '@salesforce/schema/AutoNumber__c.IsActive__c';
import Max_Used_Number from '@salesforce/schema/AutoNumber__c.Max_Used_Number__c';
import Object_API_Name from '@salesforce/schema/AutoNumber__c.Object_API_Name__c';
import Starting_Number from '@salesforce/schema/AutoNumber__c.Starting_Number__c';

import autoNumberErrorInvalidDisplayFormat
    from '@salesforce/label/c.autoNumberErrorInvalidDisplayFormat';
import batchNumberSettingsActivate from '@salesforce/label/c.batchNumberSettingsActivate';
import batchNumberSettingsConfigureHeader
    from '@salesforce/label/c.batchNumberSettingsConfigureHeader';
import batchNumberSettingsDescActivation
    from '@salesforce/label/c.batchNumberSettingsDescActivation';
import batchNumberSettingsDescDisplayFormat
    from '@salesforce/label/c.batchNumberSettingsDescDisplayFormat';
import batchNumberSettingsDescription
    from '@salesforce/label/c.batchNumberSettingsDescription';
import batchNumberSettingsDescriptionCreate
    from '@salesforce/label/c.batchNumberSettingsDescriptionCreate';
import batchNumberSettingsError from '@salesforce/label/c.batchNumberSettingsError';
import batchNumberSettingsHeader from '@salesforce/label/c.batchNumberSettingsHeader';
import batchNumberSettingsHeaderDisplayFormat
    from '@salesforce/label/c.batchNumberSettingsHeaderDisplayFormat';
import batchNumberSettingsHeaderFormats
    from '@salesforce/label/c.batchNumberSettingsHeaderFormats';
import commonActivate from '@salesforce/label/c.commonActivate';
import commonDeactivate from '@salesforce/label/c.commonDeactivate';
import commonSave from '@salesforce/label/c.commonSave';

const COLUMNS = [
    {fieldName: Display_Format.fieldApiName},
    {fieldName: IsActive.fieldApiName, type: 'boolean'},
    {fieldName: Description.fieldApiName, type: 'text'},
    {fieldName: Max_Used_Number.fieldApiName, type: 'text'},
];

export default class bdiBatchNumberSettings extends LightningElement {
    displayFormat;
    startingNumber;
    description;

    // The target field, DataImportBatch__c.Batch_Number__c, is a 30 char
    // text field.  These max length constraints allow a starting number
    // of up to 999,999,999 by enforcing a max Starting Number length of
    // 9 characters, and a max Display Format length of
    // 23 characters.
    // The Display Format requires opening and closing braces containing
    // at least one zero (0). So after removing those the remaining
    // Display Format length will be 20 char or less, and the total
    // length of the formatted number when using the max Starting Number of
    // 999,999,9999 would be 29 characters, with one character reserved
    // for the increment to 1,000,000,000.
    maxLengthDisplayFormat = 23;
    maxLengthStartingNumber = 9;

    columns;
    autoNumberRecords;

    error;
    get error() {
        return this.error.body.message;
    }

    labels = {
        buttonSave: commonSave,
        buttonSaveActivate: batchNumberSettingsActivate,
        description: batchNumberSettingsDescription,
        descriptionActivation: batchNumberSettingsDescActivation,
        descriptionConfigure: batchNumberSettingsDescriptionCreate,
        descriptionDisplayFormat: batchNumberSettingsDescDisplayFormat,
        error: batchNumberSettingsError,
        errorInvalidDisplayFormat: autoNumberErrorInvalidDisplayFormat,
        header: batchNumberSettingsHeader,
        headerConfigure: batchNumberSettingsConfigureHeader,
        headerDisplayFormat: batchNumberSettingsHeaderDisplayFormat,
        headerFormats: batchNumberSettingsHeaderFormats
    }

    fieldDescribes;
    @wire(getFieldDescribes)
    wiredFieldDescribes({error, data}) {
        if (data) {
            this.fieldDescribes = JSON.parse(data);
            this.columns =
                this.getColumnsWithFieldLabels(COLUMNS, this.fieldDescribes)
                    .concat(this.actionsColumn);
        } else if (error) {
            this.error = error;
        }
    }

    get actionsColumn() {
        return [{type: 'action', typeAttributes: {rowActions: this.getRowActions}}];
    }

    getRowActions(row, doneCallback) {
        const actions = [];
        if (row[IsActive.fieldApiName]) {
            actions.push({
                'label': commonDeactivate,
                'name': 'deactivate'
            });
        } else {
            actions.push({
                'label': commonActivate,
                'name': 'activate'
            });
        }
        doneCallback(actions);
    }

    getColumnsWithFieldLabels = (columns, fields) => {
        let columnsWithFieldLabelsApplied = JSON.parse(JSON.stringify(columns));
        columnsWithFieldLabelsApplied.forEach(column => {
            if (fields[column.fieldName]) {
                column.label = fields[column.fieldName].label;
            }
        });
        return columnsWithFieldLabelsApplied;
    }

    permissionEnabled;
    async connectedCallback() {
        await isSysAdmin()
            .then(response => {
                this.permissionEnabled = response;
            })
            .catch(error => this.error = error);

        if (this.permissionEnabled) {
            this.fetchAutoNumbers();
        }
    }

    isLoading;
    fetchAutoNumbers() {
        this.isLoading = true;
        getAutoNumbers()
            .then(response => {
                this.isLoading = false;
                this.autoNumberRecords = response;
            })
            .catch(error => this.error = error);
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        switch (actionName) {
            case 'activate':
                activate({autoNumberId: row['Id']})
                    .then(() => this.fetchAutoNumbers())
                    .catch(error => this.error = error);
                break;
            case 'deactivate':
                deactivate({autoNumberId: row['Id']})
                    .then(() => this.fetchAutoNumbers())
                    .catch(error => this.error = error);
                break;
        }
    }

    async handleSave() {
        await this.save();
        this.reset();
        this.fetchAutoNumbers();
    }

    async save() {
        this.isLoading = true;
        try {
            const autoNumber = await save({autoNumber: JSON.stringify({fields: this.fields})});
            return autoNumber;
        } catch (err) {
            this.error = err;
            this.displayErrorOnInputs(this.errorDetails);
        } finally {
            this.isLoading = false;
        }
    }

    async handleSaveAndActivate() {
        const autoNumber = await this.save();
        await this.activate(autoNumber.Id);
        this.reset();
        this.fetchAutoNumbers();
    }

    async activate(autoNumberId) {
        this.isLoading = true;
        try {
            await activate({autoNumberId: autoNumberId});
        } catch (err) {
            this.error = err;
        } finally {
            this.isLoading = false;
        }
    }

    get fields() {
        return {
            [Object_API_Name.fieldApiName]: DataImportBatch.objectApiName,
            [Field_API_Name.fieldApiName]: Batch_Number.fieldApiName,
            [Starting_Number.fieldApiName]: this.startingNumber,
            [Display_Format.fieldApiName]: this.displayFormat,
            [Description.fieldApiName]: this.description
        }
    }

    get errorMessage() {
        return this.error ? this.labels.error + ' ' + this.errorDetails : null;
    }

    get errorDetails() {
        return this.error ? this.error.body.message : '';
    }

    handleStartingNumberChange(event) {
        this.startingNumber = event.target.value;
    }

    handleDescriptionChange(event) {
        this.description = event.target.value;
    }

    handleDisplayFormatBlur(event) {
        if (!this.isValidDisplayFormat(event.target.value)) {
            event.target.setCustomValidity(this.labels.errorInvalidDisplayFormat);
        } else {
            event.target.setCustomValidity('');
        }
        event.target.reportValidity();
    }

    isValidDisplayFormat(value) {
        const re = '.*\\{0+\\}';
        const regex = RegExp(re);
        return regex.test(value) &&
            value.match(/{/g).length === 1 &&
            value.match(/}/g).length === 1;
    }

    handleDisplayFormatChange(event) {
        this.displayFormat = event.target.value;
    }

    get displayNumberPlaceholder() {
        return '{000000} or BTC-{000000}';
    }

    // ================================================================================
    // Quality Assurance Locators
    // ================================================================================

    get qaLocatorDisplayFormat() {
        return `input ${this.labelDisplayFormat}`;
    }

    get qaLocatorStartingNumber() {
        return `input ${this.labelStartingNumber}`;
    }

    get qaLocatorDescription() {
        return `input ${this.labelDescription}`;
    }

    get qaLocatorSaveButton() {
        return `button ${this.labels.buttonSave}`;
    }

    get qaLocatorSaveAndActivateButton() {
        return `button ${this.labels.buttonSaveActivate}`;
    }

    get qaLocatorBatchNumberDatatable() {
        return `datatable`;
    }

    get labelDisplayFormat() {
        return this.fieldDescribes ? this.fieldDescribes[Display_Format.fieldApiName].label : '';
    }

    get inlineHelpTextDisplayFormat() {
        return this.fieldDescribes ? this.fieldDescribes[Display_Format.fieldApiName].inlineHelpText : '';
    }

    get labelStartingNumber() {
        return this.fieldDescribes ? this.fieldDescribes[Starting_Number.fieldApiName].label : '';
    }

    get inlineHelpTextStartingNumber() {
        return this.fieldDescribes ? this.fieldDescribes[Starting_Number.fieldApiName].inlineHelpText : '';
    }

    get labelDescription() {
        return this.fieldDescribes ? this.fieldDescribes[Description.fieldApiName].label : '';
    }

    get inlineHelpTextDescription() {
        return this.fieldDescribes ? this.fieldDescribes[Description.fieldApiName].inlineHelpText : '';
    }

    reset() {
        this.error = null;
        this.displayFormat = null;
        this.startingNumber = null;
        this.description = null;
    }

    displayErrorOnInputs(errorMessage) {
        const inputs = this.template.querySelectorAll('lightning-input');
        inputs.forEach(input => {
            if (errorMessage.includes(input.name) || errorMessage.includes(input.label)) {
                input.setCustomValidity(errorMessage);
                input.reportValidity();
            } else {
                input.setCustomValidity('');
            }
        })
    }

}