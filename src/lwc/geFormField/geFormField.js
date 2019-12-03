import {LightningElement, api, track} from 'lwc';
import GeFormService from 'c/geFormService';

const RICH_TEXT_TYPE = 'RICHTEXT';
const LOOKUP_TYPE = 'REFERENCE';
const PICKLIST_TYPE = 'PICKLIST';
const TEXT_AREA_TYPE = 'TEXTAREA';
const BOOLEAN_TYPE = 'BOOLEAN';
const DELAY = 300;

export default class GeFormField extends LightningElement {
    @track value;
    @track picklistValues = [];
    @api element;
    @api targetFieldName;

    changeTimeout;

    connectedCallback(){
        if(this.targetFieldName !== undefined){
            // Construct an element object using the field name and mapping info
            this.element = {
                label: this.fieldInfo.Target_Field_Label,
                required: this.fieldInfo.Is_Required,
                dataImportFieldMappingDevNames: [this.targetFieldName]
            };
        }
    }

    handleValueChange(event) {
        this.value = this.getValueFromChangeEvent(event);
        window.clearTimeout(this.changeTimeout);
        this.changeTimeout = setTimeout(() => {
            // parent component (formSection) should bind to onchange event
            const evt = new CustomEvent('change', {field: this.element, value: this.value});
            this.dispatchEvent(evt);
        }, DELAY);
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

        if(this.element !== null && this.element.required) {
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

        // TODO: Update for widget fields
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
        return this.targetFieldName !== undefined ? 
            GeFormService.getFieldMappingWrapperFromTarget(this.targetFieldName) :
            GeFormService.getFieldMappingWrapper(this.formElementName);
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

    @api
    get fieldLabel() {
        return this.element.label;
    }
}