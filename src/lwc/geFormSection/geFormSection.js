import {LightningElement, api, track} from 'lwc';
import { getSubsetObject, isUndefined, isNotEmpty } from 'c/utilCommon';
import GeFormService from 'c/geFormService';

const COLLAPSED_DISPLAY_MODE = 'collapsed';

export default class GeFormSection extends LightningElement {
    @api section;
    @api widgetData;
    @track hasCreditCardWidget = false;


    renderedCallback() {
        this.registerCreditCardWidget();
        this.handleChangeNameOnCardField();
    }

    /**
     * Get the alternative text that represents the section expand/collapse button
     * @returns {string} containing the section expand alternative text
     */
    get altTextLabel() {
        return 'Toggle ' + this.section.label;
    }


    get isCollapsed() {
        return this.section.defaultDisplayMode === COLLAPSED_DISPLAY_MODE;
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
        let widgetValues = [];

        if (widgets !== null && typeof widgets !== 'undefined') {
            widgets.forEach(widget => {
                widgetValues.push(widget.widgetAndValues);
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
    reset(fieldMappingDevNames = null, setDefaults = true) {
        const fields = this.template.querySelectorAll('c-ge-form-field');
        const widgetList = this.template.querySelectorAll('c-ge-form-widget');

        fields.forEach(field => {
            if (fieldMappingDevNames) {
                // reset the fields elements related to
                // these field mappings
                if (fieldMappingDevNames.includes(
                    field.element.dataImportFieldMappingDevNames[0]
                )) {
                    field.reset(setDefaults);
                }
            } else {
                // reset all field elements in this section
                field.reset(setDefaults);
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
                if (isNotEmpty(widgetCmp.allFieldsByAPIName)) {
                    fields.push(...widgetCmp.allFieldsByAPIName);
                }
            });

        return fields;
    }

    registerCreditCardWidget() {
        if (!isUndefined(this.section)) {
            this.section.elements.forEach(element => {
                if (element.componentName === 'geFormWidgetTokenizeCard') {
                    this.hasCreditCardWidget = true;
                }
            })
        }
    }

    handleChangeNameOnCardField() {
        const changeNameOnCardFieldEvent = new CustomEvent(
            'changenameoncardfield'
        );
        this.dispatchEvent(changeNameOnCardFieldEvent);
    }

    @api
    setCardHolderName(value) {
        const widgetList = this.template.querySelectorAll('c-ge-form-widget');
        widgetList.forEach(widget => {
            if (widget.isElevateTokenizeCard) {
                widget.setCardHolderName(value);
            }
        });
    }

    @api
    get isCreditCardWidgetAvailable() {
        return this.hasCreditCardWidget;
    }

    get renderableElements() {
        if (!isUndefined(this.section)) {
            return this.section.elements.filter(element => new GeFormElement(element).isRenderable);
        } else {
            return [];
        }
    }

    @api
    getAllFieldsByFieldAPIName() {
        const fields = this.template.querySelectorAll('c-ge-form-field');
        let fieldData = {};
        if (isNotEmpty(fields)) {
            fields.forEach(field => {
                fieldData = { ...fieldData, ...(field.fieldValueAndFieldApiName) };
            });
        }
        return fieldData;
    }



    @api
    setRecordTypeOnFields(objectMappingDevName, recordTypeId) {
        this.template.querySelectorAll('c-ge-form-field')
            .forEach(field => {
                // Currently only picklists need their selected record's RecordType Id,
                // since they use it to update their available options
                if (field.isPicklist) {
                    if (field.targetObjectMappingDevName === objectMappingDevName) {
                        field.recordTypeId = recordTypeId;
                    }
                }
            });
    }

}

class GeFormElement {
    element;

    constructor(element) {
        this.element = element;
    }

    get fieldMapping() {
        return GeFormService.getFieldMappingWrapper(this.formElementName);
    }

    get targetObjectMappingDevName() {
        if(isNotEmpty(this.fieldMapping)) {
            return this.fieldMapping.Target_Object_Mapping_Dev_Name;
        }
    }

    get formElementName() {
        return this.element.componentName ? this.element.componentName : this.element.dataImportFieldMappingDevNames[0];
    }

    get objectMapping() {
        return GeFormService.getObjectMappingWrapper(this.targetObjectMappingDevName);
    }

    get hasMappingInformation() {
        return isNotEmpty(this.objectMapping) && isNotEmpty(this.fieldMapping);
    }

    get isWidget() {
        return !!this.element.componentName;
    }

    get isRenderable() {
        if(this.isWidget) {
            // always render widgets
            return true;
        } else if(isNotEmpty(this.fieldMapping)) {
            // the mapping record for this field is valid when it exists and
            // the source and target fields are describable
            return this.hasMappingInformation && this.fieldMapping.isDescribable;
        }
        return false;
    }

}