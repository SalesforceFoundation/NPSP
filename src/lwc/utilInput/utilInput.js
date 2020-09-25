/* eslint-disable consistent-return */
import { LightningElement, api, track, wire } from 'lwc';
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import { inputTypeByDescribeType } from 'c/utilTemplateBuilder';
import { isNotEmpty, isEmpty } from 'c/utilCommon';
import geBodyBatchFieldBundleInfo from '@salesforce/label/c.geBodyBatchFieldBundleInfo';

const WIDGET = 'widget';
const TEXTAREA = 'textarea';
const COMBOBOX = 'combobox';
const SEARCH = 'search';
const CHECKBOX = 'checkbox';
const DATE = 'date';
const DATETIME = 'datetime-local';
const YES = 'Yes';
const TEXT = 'text';
const TRUE = 'true';
const RICH_TEXT_FORMATS = [
    'font', 'size', 'bold', 'italic', 'underline', 'strike', 'list', 'indent', 'align', 'link', 'clean', 'table', 'header'
];
const CURRENCY = 'currency';
const PERCENT = 'percent';
const DECIMAL = 'decimal';

export default class utilInput extends LightningElement {

    // expose custom labels to template
    CUSTOM_LABELS = { geBodyBatchFieldBundleInfo };
    richTextFormats = RICH_TEXT_FORMATS;

    @api fieldApiName;
    @api label;
    @api defaultValue;
    @api required;
    @api type;
    @api formFieldType;
    @api objectInfo;
    @api objectApiName;
    @api tabIndex;
    @api variant = 'label-stacked';
    @api value;
    @api widgetName;

    @track isRichTextValid = true;

    @api
    reportValue() {
        return {
            objectApiName: this.uiObjectApiName,
            fieldApiName: this.fieldApiName,
            value: this.fieldValue
        };
    }

    get fieldValue() {
        if (this.isLightningCheckbox) {
            return isNotEmpty(this.value) ? this.value : this.checkboxDefaultValue;
        }
        if (this.value !== undefined) {
            return this.value;
        }
        if (this.defaultValue !== undefined) {
            return this.defaultValue;
        }
        // Workaround to empty a rich text input if an explicit value or default value isn't provided
        if (this.isLightningRichText) {
            return '';
        }
        return undefined;
    }

    get checkboxDefaultValue() {
        return (this.defaultValue === TRUE || this.defaultValue === true) ? true : false;
    }

    get isWidget() {
        return this.formFieldType === WIDGET ? true : false;
    }

    get isLightningTextarea() {
        return this.lightningInputType === TEXTAREA && !this.isLightningRichText ? true : false;
    }

    get isLightningCombobox() {
        return this.lightningInputType === COMBOBOX ? true : false;
    }

    get isLightningSearch() {
        return this.lightningInputType === SEARCH ? true : false;
    }

    get isLightningRichText() {
        if ((this.fieldDescribe && this.fieldDescribe.htmlFormatted) &&
            this.lightningInputType === TEXTAREA) {
            return this.fieldDescribe.htmlFormatted;
        }
        return false;
    }

    get isLightningCheckbox() {
        return this.lightningInputType === CHECKBOX ? true : false;
    }

    get isLightningDateOrDatetime() {
        return (this.lightningInputType === DATE || this.lightningInputType === DATETIME) ? true : false;
    }

    get isBaseLightningInput() {
        if (this.lightningInputType !== TEXTAREA &&
            this.lightningInputType !== COMBOBOX &&
            this.lightningInputType !== SEARCH &&
            this.lightningInputType !== CHECKBOX &&
            this.lightningInputType !== DATE &&
            this.lightningInputType !== DATETIME) {
            return true;
        }
        return false;
    }

    get dataType() {
        return this.type ? this.type.toLowerCase() : undefined;
    }

    get formatter() {
        if (this.dataType === CURRENCY || this.dataType === PERCENT || this.dataType === DECIMAL) {
            return this.dataType;
        }
        return undefined;
    }

    get granularity() {
        if (this.formatter) {
            switch (this.dataType) {
                case CURRENCY: return '0.01';
                case PERCENT: return '0.01';
                case DECIMAL: return '0.001';
                default: return 'any';
            }
        }
        return undefined;
    }

    get lightningInputType() {
        return this.type ? inputTypeByDescribeType[this.type.toLowerCase()] : TEXT;
    }

    get isRequired() {
        const _required = this.required === YES || this.required === true;
        return (_required && !this.isLightningCheckbox) ? true : false;
    }

    get fieldDescribe() {
        if (this.objectInfo && this.objectInfo.fields) {
            return this.objectInfo.fields[this.fieldApiName];
        }
    }

    @api
    get uiLabel() {
        if (this.label) {
            return this.label;
        } else if (this.fieldDescribe) {
            return this.fieldDescribe.label;
        }
        return undefined;
    }

    get uiObjectApiName() {
        return this.objectInfo && this.objectInfo.apiName ? this.objectInfo.apiName : this.objectApiName;
    }

    get showRichTextLabel() {
        return this.isLightningRichText && this.variant !== 'label-hidden' ? true : false;
    }

    @wire(getObjectInfo, { objectApiName: '$objectApiName' })
    wiredObjectInfo(response) {
        if (response.data) {
            this.objectInfo = response.data;
            if (!this.type) {
                let field = this.objectInfo.fields[this.fieldApiName];
                if (isNotEmpty(field)) {
                    this.type = field.dataType;
                }
            }
        }
    }

    /*******************************************************************************
    * @description Dispatches an event to notify parent component that the form
    * field's defaultValue property for a combobox has changed.
    *
    * @param {object} event: Event object from lightning-combobox onchange event handler 
    */
    handleChangeCombobox(event) {
        let detail = {
            objectApiName: this.uiObjectApiName,
            fieldApiName: this.fieldApiName,
            value: event.target.value
        };
        this.value = event.detail.value;
        this.dispatchEvent(new CustomEvent('changevalue', { detail: detail }));
    }

    /*******************************************************************************
    * @description Dispatches an event to notify parent component that the form
    * field's defaultValue property has changed.
    *
    * @param {object} event: Event object from various lightning-input type's
    * change event handler.
    */
    handleValueChange(event) {
        if (this.type && this.lightningInputType === CHECKBOX) {
            this.value = event.target.checked;
        } else if (this.type && this.lightningInputType === SEARCH) {
            this.value = event.detail.value;
        } else if (event.target) {
            this.value = event.target.value;
        }

        let isValid = true;
        if (this.isLightningRichText) {
            isValid = this.checkRichTextValidity();
        } else {
            isValid = this.isValid();
        }

        let detail = {
            objectApiName: this.uiObjectApiName,
            fieldApiName: this.fieldApiName,
            value: this.fieldValue,
            isValid: isValid
        }

        this.dispatchEvent(new CustomEvent('changevalue', { detail: detail }));
    }

    /*******************************************************************************
    * @description Public method used to check the current input's validity by
    * calling checkFieldValidity.
    *
    * @return {boolean}: TRUE when a field is required and filled in correctly,
    * or not required at all.
    */
    @api
    isValid() {
        // We need to check for invalid values, regardless if the field is required
        let fieldIsValid = this.checkFieldValidity();
        if (this.fieldDescribe !== null && this.isRequired) {
            return isNotEmpty(this.fieldValue) && fieldIsValid;
        }

        return fieldIsValid;
    }

    /*******************************************************************************
    * @description Method calls lightning-input methods reportValidity and
    * checkValidity on the current input.
    *
    * @return {boolean}: TRUE when a field is filled in, and is the correct format.
    */
    checkFieldValidity() {
        const inputField = this.template.querySelector('[data-id="inputComponent"]');
        if (typeof inputField !== 'undefined'
            && inputField !== null
            && typeof inputField.reportValidity === 'function'
            && typeof inputField.checkValidity === 'function') {
            inputField.reportValidity();
            return inputField.checkValidity();
        } else if (this.isLightningRichText) {
            this.checkRichTextValidity();
            if (!this.isRichTextValid) {
                // workaround, field will not display as invalid if it is untouched
                inputField.focus();
                inputField.blur();
            }
            return this.isRichTextValid;
        }
        return true;
    }

    checkRichTextValidity() {
        if (this.isRequired) {
            const isValid = isNotEmpty(this.fieldValue) && this.fieldValue.length > 0;
            this.isRichTextValid = isValid;
            return isValid;
        }
        return true;
    }

    stopPropagation(event) {
        event.stopPropagation();
    }

    /*******************************************************************************
     * Start getters for data-qa-locator attributes
     */

    get qaLocatorRichText() {
        return `richtext ${this.uiLabel}`;
    }

    get qaLocatorTextArea() {
        return `textarea ${this.uiLabel}`;
    }

    get qaLocatorCheckbox() {
        return `checkbox ${this.uiLabel}`;
    }

    get qaLocatorDateTime() {
        return `datetime ${this.uiLabel}`;
    }

    get qaLocatorBaseInput() {
        return `input ${this.uiLabel}`;
    }

    /*******************************************************************************
     * End getters for data-qa-locator attributes
     */


}