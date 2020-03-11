import {LightningElement, api, track} from 'lwc';
import {isUndefined, isNotEmpty} from "c/utilCommon";


export default class GeFormSection extends LightningElement {
    @api section;
    @api widgetData;
    @track collapsed = false;
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
    load(data){
        const fields = this.template.querySelectorAll('c-ge-form-field');
        const widgetList = this.template.querySelectorAll('c-ge-form-widget');

        fields.forEach(field => {
            field.load(data);
        });

        widgetList.forEach(widget => {
            widget.load(data);
        });
    }

    @api
    reset() {
        const fields = this.template.querySelectorAll('c-ge-form-field');
        const widgetList = this.template.querySelectorAll('c-ge-form-widget');

        fields.forEach(field => {
            field.reset();
        });

        widgetList.forEach(widget => {
            widget.reset();
        });
    }

    handleChangeLookup(event) {
        const changeLookupEvent = new CustomEvent(
            'changelookup',
            { detail: event.detail });
        this.dispatchEvent(changeLookupEvent);
    }

    handleChangePicklist(event) {
        const changePicklistEvent = new CustomEvent(
            'changepicklist',
            { detail: event.detail });
        this.dispatchEvent(changePicklistEvent);
    }


    registerCreditCardWidget() {
        if(!isUndefined(this.section)){
            this.section.elements.forEach(element => {
                if(element.componentName === 'geFormWidgetTokenizeCard'){
                    this.hasCreditCardWidget = true;
                }
            })
        }
    }

    handleChangeNameOnCardField(){
        const changeNameOnCardFieldEvent = new CustomEvent(
            'changenameoncardfield'
        );
        this.dispatchEvent(changeNameOnCardFieldEvent);
    }

    @api
    setCardHolderName(value) {
        const widgetList = this.template.querySelectorAll('c-ge-form-widget');
        widgetList.forEach(widget =>{
            if(widget.isElevateTokenizeCard){
                widget.setCardHolderName(value)
            }
        });
    }

    @api
    get isCreditCardWidgetAvailable() {
        return this.hasCreditCardWidget;
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



}