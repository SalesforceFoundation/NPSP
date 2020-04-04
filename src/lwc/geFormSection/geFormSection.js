import {LightningElement, api, track} from 'lwc';
import {getSubsetObject} from "c/utilCommon";

export default class GeFormSection extends LightningElement {
    @api section;
    @api widgetData;
    @track collapsed = false;

    /**
     * Get the alternative text that represents the section expand/collapse button
     * @returns {string} containing the section expand alternative text
     */
    get altTextLabel() {
        return 'Toggle ' + this.section.label;
    }

    @api
    get values() {
        const fields = this.template.querySelectorAll('c-ge-form-field');
        let dataImportFieldAndValues = {};
        if(fields !== null && typeof fields !== 'undefined') {
            fields.forEach(field => {
                dataImportFieldAndValues = { ...dataImportFieldAndValues, ...(field.fieldAndValue) };
            });
        }
        return dataImportFieldAndValues;
    }

    /**
     * Gets value and UI-label for the requestedFields in the section (if any)
     * @param requestedFields - Array of API Field Names to get information
     * @returns {Array} - field value and ui-label using api-field-name as key
     */
    @api
    getFieldValueAndLabel( requestedFields ) {

        const fields = this.template.querySelectorAll('c-ge-form-field');
        let dataImportFieldAndLabels = {};

        if (fields !== null && typeof fields !== 'undefined') {
            fields.forEach( field => {
                if ( requestedFields.indexOf(field.sourceFieldAPIName) !== -1 ){
                    field.clearCustomValidity();
                    dataImportFieldAndLabels = { ...dataImportFieldAndLabels, ...(field.fieldValueAndLabel) };
                }
            });
        }

        return dataImportFieldAndLabels;

    }

    /**
     * Sets custom validity on fields inside fieldsArray
     * @param {fieldsArray},Array with sourceFieldAPIName field property
     * @param {errorMessage}, String custom error message for fields
     */
    @api
    setCustomValidityOnFields( fieldsArray, errorMessage ) {

        const fields = this.template.querySelectorAll('c-ge-form-field');
        if (fields !== null && typeof fields !== 'undefined') {
            fields.forEach(f => {
                if ( fieldsArray.indexOf(f.sourceFieldAPIName)!== -1 ) {
                    f.setCustomValidity(errorMessage);
                }
            });
        }

    }

    @api
    get widgetValues() {
        const widgets = this.template.querySelectorAll('c-ge-form-widget');
        let widgetValues = {};
        if(widgets !== null && typeof widgets !== 'undefined') {
            widgets.forEach(widget => {
                widgetValues = { ...widgetValues, ...(widget.widgetAndValues) };
            });
        }
        return widgetValues;
    }

    /**
     * Get a list of fields that are required, but are null/undefined or otherwise blank in the dynamic form
     * @returns {Array} of invalid fields. If all fields are ok, the array is empty.
     */
    @api
    getInvalidFields() {
        const fields = this.template.querySelectorAll('c-ge-form-field');
        let invalidFields = [];

        fields.forEach(f => {
            if(!f.isValid()) {
                invalidFields.push(f.fieldLabel);
            }
        });

        return invalidFields;
    }

    @api
    getAllFieldsByAPIName() {
        const fields = this.template.querySelectorAll('c-ge-form-field');
        let fieldMappedByAPIName = {};

        fields.forEach(f => {
            fieldMappedByAPIName[f.sourceFieldAPIName] = f;
        });

        return fieldMappedByAPIName;
    }

    @api
    load(data) {
        const fields = this.template.querySelectorAll('c-ge-form-field');
        fields.forEach(fieldCmp => {
            if (Object.keys(data).includes(fieldCmp.sourceFieldAPIName)) {
                fieldCmp.load(
                    getSubsetObject(
                        data,
                        [fieldCmp.sourceFieldAPIName]));
            }

            if (data.recordTypeId || data.recordTypeId === null) {
                fieldCmp.recordTypeId = data.recordTypeId;
            }
        });

        const widgetList = this.template.querySelectorAll('c-ge-form-widget');
        widgetList.forEach(widget => {
            widget.load(data);
        });
    }

    @api
    reset(fieldMappingDevNames = null) {
        const fields = this.template.querySelectorAll('c-ge-form-field');
        const widgetList = this.template.querySelectorAll('c-ge-form-widget');

        fields.forEach(field => {
            if (fieldMappingDevNames) {
                // reset the fields elements related to
                // these field mappings
                if (fieldMappingDevNames.includes(
                    field.element.dataImportFieldMappingDevNames[0]
                )) {
                    field.reset();
                }
            } else {
                // reset all field elements in this section
                field.reset();
            }
        });

        widgetList.forEach(widget => {
            widget.reset();
        });
    }

    handleLookupRecordSelect(event) {
        const selectEvent = new CustomEvent(
            'lookuprecordselect',
            {
                detail: event.detail,
                objectMappingDevName: event.objectMappingDevName
            });
        this.dispatchEvent(selectEvent);
    }

    handleChangeDonationDonor(event) {
        const changeDonationDonorEvent = new CustomEvent(
            'changedonationdonor',
            { detail: event.detail });
        this.dispatchEvent(changeDonationDonorEvent);
    }

    /**
     * @description Inspects all fields and widgets in the section and
     *              returns a list of DataImport__c field api names used as
     *              source fields.  Helps to only send relevant data down from
     *              geFormRenderer to each section during load() flow.
     */
    @api
    get sourceFields() {
        let fields = Object.keys(this.getAllFieldsByAPIName());

        this.template.querySelectorAll('c-ge-form-widget')
            .forEach(widgetCmp => {
                fields.push(...widgetCmp.allFieldsByAPIName);
            });

        return fields;
    }

    @api
    setRecordTypeOnFields(objectMappingDevName, recordTypeId) {
        this.template.querySelectorAll('c-ge-form-field')
            .forEach(field => {
                // Currently only picklists need their selected record's RecordType Id,
                // since they use it to update their available options
                if (field.isPicklist) {
                    if (field.objectMappingDevName === objectMappingDevName) {
                        field.recordTypeId = recordTypeId;
                    }
                }
            });
    }

}