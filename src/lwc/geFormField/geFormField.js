import {LightningElement, api, track} from 'lwc';
import GeFormService from 'c/geFormService';

const LIGHTNING_INPUT_TYPES = ['CHECKBOX', 'CURRENCY', 'DATE', 'DATETIME', 'EMAIL', 'NUMBER', 'PERCENT', 'STRING', 'PHONE', 'TEXT', 'TIME', 'URL'];
const RICH_TEXT_TYPE = 'RICHTEXT';
const LOOKUP_TYPE = 'REFERENCE';
const PICKLIST_TYPE = 'PICKLIST';
const TEXT_AREA_TYPE = 'TEXTAREA';
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

    get inputType() {
        return GeFormService.getInputTypeFromDataType(this.fieldType);
    }

    get formatter() {
        return GeFormService.getNumberFormatterByDescribeType(this.fieldType);
    }

    get fieldInfo() {
        return GeFormService.getFieldInfo(this.element.value);
    }

    get objectInfo() {
        return GeFormService.getObjectInfo(this.objectDevName);
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