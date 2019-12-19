import {LightningElement, api, track, wire} from 'lwc';
import GeFormService from 'c/geFormService';
import GeLabelService from 'c/geLabelService';
import {getObjectInfo} from "lightning/uiObjectInfoApi";

const RICH_TEXT_TYPE = 'RICHTEXT';
const LOOKUP_TYPE = 'REFERENCE';
const PICKLIST_TYPE = 'PICKLIST';
const TEXT_AREA_TYPE = 'TEXTAREA';
const BOOLEAN_TYPE = 'BOOLEAN';
const DELAY = 300;

export default class GeFormField extends LightningElement {
    @track value;
    @track picklistValues = [];
    @track objectDescribeInfo;
    @track richTextValid = true;
    @track richTextFormats = [
        'font', 'size', 'bold', 'italic', 'underline', 'strike', 'list', 'indent', 'align', 'link', 'clean', 'table', 'header'
    ];
    @api element;
    CUSTOM_LABELS = GeLabelService.CUSTOM_LABELS;
    changeTimeout;


    /**
     * Retrieve field metadata. Used to configure how fields are displayed on the form.
     */
    @wire(getObjectInfo, { objectApiName: '$objectApiName' })
    wiredObjectInfo(response) {
        if(response.data) {
            this.objectDescribeInfo = response.data;
        }
    }

    connectedCallback() {
        const { defaultValue } = this.element;
        if(defaultValue) {
            this.value = defaultValue;
        }
    }

    handleValueChange(event) {
        window.clearTimeout(this.changeTimeout);
        this.changeTimeout = setTimeout(() => this.handleValueChangeSync(event), DELAY);
    }

    handleValueChangeSync(event) {
        this.value = this.getValueFromChangeEvent(event);
        const evt = new CustomEvent('change', {field: this.element, value: this.value});
        this.dispatchEvent(evt);
        if(this.isRichText) {
            this.checkRichTextValidity();
        }
    }

    getValueFromChangeEvent(event) {
        if(this.isLookup) {
            return event.detail.value;
        } else if(this.fieldType === BOOLEAN_TYPE) {
            return event.target.checked.toString();
        }

        return event.target.value;
    }

    /**
     * TRUE when a field is required and filled in correctly, or not required at all.
     * @returns {boolean}
     */
    @api
    isValid() {
        // We need to check for invalid values, regardless if the field is required
        let fieldIsValid = this.checkFieldValidity();

        if(this.element.required) {
            return this.value !== null
                && typeof this.value !== 'undefined'
                && this.value !== ''
                && fieldIsValid;
        }

        return fieldIsValid;
    }

    /**
     * TRUE when a field is filled in, and is the correct format.
     * @returns {boolean}
     */
    checkFieldValidity() {
        // TODO: Handle other input types, if needed
        const inputField = this.template.querySelector('[data-id="inputComponent"]');
        if(inputField !== null && typeof inputField !== 'undefined'
            && typeof inputField.reportValidity === 'function'
            && typeof inputField.checkValidity === 'function') {
                inputField.reportValidity();
                return inputField.checkValidity();
        } else if(this.isRichText) {
            this.checkRichTextValidity();
            if(!this.richTextValid) {
                // workaround, field will not display as invalid if it is untouched
                inputField.focus();
                inputField.blur();
            }
            return this.richTextValid;
        }
        return true;
    }

    checkRichTextValidity() {
        if(this.element.required) {
            const isValid = typeof this.value !== 'undefined' && this.value !== null && this.value.length > 0;
            this.richTextValid = isValid;
            return isValid;
        }
        return true;
    }

    @api
    get fieldAndValue() {
        let fieldAndValue = {};

        // KIET TBD: This is where we are keeping the field mapping
        // CMT record name at, element.value. 
        // However, it may change to the array dataImportFieldMappingDevNames
        // If so, we need to update this to reflect that.
        // In the Execute Anonymous code, both fields are populated.
        // PRINCE: Temporary change below. Please review and update
        // as needed.
        // Changed 'this.element.value' references to getter 'formElementName'.
        fieldAndValue[this.formElementName] = this.value;
        
        return fieldAndValue;
    }

    get formElementName() {
        return this.element.componentName ? this.element.componentName : this.element.dataImportFieldMappingDevNames[0];
    }

    get inputType() {
        return GeFormService.getInputTypeFromDataType(this.fieldType);
    }

    get formatter() {
        return GeFormService.getNumberFormatterByDescribeType(this.fieldType);
    }

    get fieldInfo() {
        return GeFormService.getFieldMappingWrapper(this.formElementName);
    }

    get fieldDescribeInfo() {
        if(this.objectDescribeInfo) {
            return this.objectDescribeInfo.fields[this.fieldApiName];
        }
    }

    get objectInfo() {
        return GeFormService.getObjectMappingWrapper(this.objectDevName);
    }

    get fieldType() {
        return this.fieldInfo.Target_Field_Data_Type;
    }

    get isLightningInput() {
        return typeof GeFormService.getInputTypeFromDataType(this.fieldType) !== 'undefined';
    }

    get isRichText() {
        if(typeof this.fieldDescribeInfo !== 'undefined' && this.fieldType === TEXT_AREA_TYPE) {
            return this.fieldDescribeInfo.htmlFormatted;
        }
    }

    get isLookup() {
        return this.fieldType === LOOKUP_TYPE;
    }

    get isPicklist() {
        return this.fieldType === PICKLIST_TYPE;
    }

    get isTextArea() {
        if(typeof this.fieldDescribeInfo !== 'undefined' && this.fieldType === TEXT_AREA_TYPE) {
            return !this.fieldDescribeInfo.htmlFormatted;
        }
    }

    get objectDevName() {
        return this.fieldInfo.Target_Object_Mapping_Dev_Name;
    }

    get objectApiName() {
        if(typeof this.objectInfo !== 'undefined') {
            return this.objectInfo.Object_API_Name;
        }
    }

    get fieldApiName() {
        return this.fieldInfo.Target_Field_API_Name;
    }

    @api
    get fieldLabel() {
        return this.element.label;
    }
}