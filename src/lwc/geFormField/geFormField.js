import {LightningElement, api, track} from 'lwc';
import GeFormService from 'c/geFormService';

const LIGHTNING_INPUT_TYPES = ['BOOLEAN', 'CURRENCY', 'DATE', 'DATETIME', 'EMAIL', 'NUMBER', 'PERCENT', 'STRING', 'PHONE', 'TEXT', 'TIME', 'URL'];
const RICH_TEXT_TYPE = 'RICHTEXT';
const LOOKUP_TYPE = 'REFERENCE';
const PICKLIST_TYPE = 'PICKLIST';
const TEXT_AREA_TYPE = 'TEXTAREA';
const BOOLEAN_TYPE = 'BOOLEAN';
const CHECKBOX_TYPE = 'CHECKBOX';
const DELAY = 300;

export default class GeFormField extends LightningElement {
    @track value;
    @track picklistValues = [];
    @api element;

    changeTimeout;

    handleValueChange(event) {
        this.value = event.target.value;
        window.clearTimeout(this.changeTimeout);
        this.changeTimeout = setTimeout(() => {
            // parent component (formSection) should bind to onchange event
            const evt = new CustomEvent('change', {field: this.element, value: this.value});
            this.dispatchEvent(evt);
        }, DELAY);
    }

    @api
    get fieldAndValue() {
        let fieldAndValue = {};

        // KIET TBD: This is where we are keeping the field mapping
        // CMT record name at, element.value. 
        // However, it may change to the array dataImportFieldMappingDevNames
        // If so, we need to update this to reflect that.
        // In the Execute Anonymous code, both fields are populated. 
        fieldAndValue[this.element.value] = this.value;
        
        return fieldAndValue;
    }

    get inputType() {
        // the field type is boolean, not checkbox
        if (this.fieldType === BOOLEAN_TYPE) {
            return CHECKBOX_TYPE;
        }
        return GeFormService.getInputTypeFromDataType(this.fieldType);
    }

    get formatter() {
        return GeFormService.getNumberFormatterByDescribeType(this.fieldType);
    }

    get fieldInfo() {
        return GeFormService.getFieldMappingWrapper(this.element.value);
    }

    get objectInfo() {
        return GeFormService.getObjectMappingWrapper(this.objectDevName);
    }

    get fieldType() {
        return this.fieldInfo.Target_Field_Data_Type;
    }

    get isLightningInput() {
        return LIGHTNING_INPUT_TYPES.indexOf(this.fieldType) !== -1;
    }

    get isRichText() {
        return this.fieldType === RICH_TEXT_TYPE;
    }

    get isLookup() {
        return this.fieldType === LOOKUP_TYPE;
    }

    get isPicklist() {
        return this.fieldType === PICKLIST_TYPE;
    }

    get isTextArea() {
        return this.fieldType === TEXT_AREA_TYPE;
    }

    get objectDevName() {
        return this.fieldInfo.Target_Object_Mapping_Dev_Name;
    }

    get objectApiName() {
        return this.objectInfo.Object_API_Name;
    }

    get fieldApiName() {
        return this.fieldInfo.Target_Field_API_Name;
    }
}