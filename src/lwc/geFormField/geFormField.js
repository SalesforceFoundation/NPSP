import {LightningElement, api, track} from 'lwc';
import GeFormService from 'c/geFormService';

const LIGHTNING_INPUT_TYPES = ['CHECKBOX', 'CURRENCY', 'DATE', 'DATETIME', 'EMAIL', 'NUMBER', 'STRING', 'PHONE', 'TEXT', 'TIME', 'URL', 'PERCENT'];
const RICH_TEXT_TYPE = 'RICHTEXT';
const LOOKUP_TYPE = 'REFERENCE';
const PICKLIST_TYPE = 'PICKLIST';
const DELAY = 300;

export default class GeFormField extends LightningElement {
    @track value;
    @api element;
    changeTimeout;

    handleValueChange(event) {
        this.value = event.target.value;
        window.clearTimeout(this.changeTimeout);
        this.changeTimeout = setTimeout(() => {
            // parent component (formSection) should bind to onchange event
            const evt = new CustomEvent('change', {field: this.element, value: this.value});
            console.log(evt); 
            this.dispatchEvent(evt);
        }, DELAY);
    }

    get inputType() {
        return GeFormService.getInputTypeFromDataType(this.element.dataType);
    }

    get fieldInfo() {
        return GeFormService.getFieldInfo(this.element.value);
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
}