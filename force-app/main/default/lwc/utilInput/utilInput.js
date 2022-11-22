/* eslint-disable consistent-return */
import { LightningElement, api, track, wire } from 'lwc';
import { getObjectInfo, getPicklistValues } from "lightning/uiObjectInfoApi";
import { inputTypeByDescribeType } from 'c/utilTemplateBuilder';
import { isEmpty, isNotEmpty, isString, UtilDescribe, nonePicklistOption } from 'c/utilCommon';
import geBodyBatchFieldBundleInfo from '@salesforce/label/c.geBodyBatchFieldBundleInfo';
import commonLabelNone from '@salesforce/label/c.stgLabelNone';
import RECORD_TYPE_FIELD from '@salesforce/schema/Opportunity.RecordTypeId';

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
const LABEL_HIDDEN = 'label-hidden';
const LABEL_STACKED = 'label-stacked';
const LABEL_INLINE = 'label-inline';

export default class utilInput extends LightningElement {

    // expose custom labels to template
    CUSTOM_LABELS = { geBodyBatchFieldBundleInfo, commonLabelNone };
    PICKLIST_OPTION_NONE = nonePicklistOption();
    richTextFormats = RICH_TEXT_FORMATS;
    utilDescribe = new UtilDescribe();
    @api fieldApiName;
    @api label;
    @api defaultValue;
    @api required;
    @api type;
    @api formFieldType;
    @api objectApiName;
    @api tabIndex;
    @api variant = LABEL_STACKED;
    @api value;
    @api widgetName;
    @api picklistOptionsOverride;
    @api disabled;

    @track isRichTextValid = true;
    @track defaultRecordTypeId;
    @track fieldDescribe;
    @track _picklistValues;

    @api
    reportValue() {
        return {
            objectApiName: this.objectApiName,
            fieldApiName: this.fieldApiName,
            value: this.fieldValue
        };
    }

    get fieldValue() {
        if (this.isLightningCheckbox) {
            return isNotEmpty(this.value) ? this.value : this.checkboxDefaultValue;
        }
        if (this.isPicklist && this.value === null) {
            return this.CUSTOM_LABELS.commonLabelNone;
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
        return (this.defaultValue === TRUE || this.defaultValue === true);
    }

    get isWidget() {
        return this.formFieldType === WIDGET;
    }

    get isLightningTextarea() {
        return this.lightningInputType === TEXTAREA && !this.isLightningRichText;
    }

    get isLightningCombobox() {
        return this.lightningInputType === COMBOBOX || this.isRecordTypePicklist;
    }

    get isLightningSearch() {
        return this.lightningInputType === SEARCH && !this.isRecordTypePicklist;
    }

    get isLightningRichText() {
        if ((this.fieldDescribe && this.fieldDescribe.htmlFormatted) &&
            this.lightningInputType === TEXTAREA) {
            return this.fieldDescribe.htmlFormatted;
        }
        return false;
    }

    get isLightningCheckbox() {
        return this.lightningInputType === CHECKBOX && isEmpty(this.picklistOptionsOverride);
    }

    get isLightningDateOrDatetime() {
        return (this.lightningInputType === DATE || this.lightningInputType === DATETIME);
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
        if (isNotEmpty(this.picklistOptionsOverride)) {
            return COMBOBOX;
        }

        return this.type ? inputTypeByDescribeType[this.type.toLowerCase()] : TEXT;
    }

    get picklistValues() {
        if (this.picklistOptionsOverride) {
            return this.picklistOptionsOverride;
        }

        if (this.fieldApiName === RECORD_TYPE_FIELD.fieldApiName) {
            return this.utilDescribe.getPicklistOptionsForRecordTypeIds();
        }

        return this._picklistValues;
    }

    set picklistValues(values) {
        this._picklistValues = values;
    }

    get isRecordTypePicklist() {
        return this.fieldApiName === RECORD_TYPE_FIELD.fieldApiName;
    }

    get isRequired() {
        return this.required === YES || this.required === true;
    }
    get isDisabled() {
        return this.disabled;
    }

    get lookupFormElementClass() {
        if(this.variant === LABEL_INLINE) {
            return 'slds-form-element slds-form-element_horizontal';
        } else if (this.variant === LABEL_STACKED) {
            return 'slds-form-element slds-form-element_stacked';
        } else if (this.variant === LABEL_HIDDEN) {
            return 'slds-form-element slds-form-element_hidden';
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

    get showRichTextLabel() {
        return this.isLightningRichText && this.variant !== LABEL_HIDDEN;
    }

    @wire(getObjectInfo, { objectApiName: '$objectApiName' })
    wiredObjectInfo(response) {
        if (response.data) {
            this.objectInfo = response.data;
            this.utilDescribe.setDescribe(response.data);
            this.defaultRecordTypeId = this.utilDescribe.defaultRecordTypeId();
            this.fieldDescribe = this.utilDescribe.getFieldDescribe(this.fieldApiName);

            if (!this.type) {
                if (isNotEmpty(this.fieldDescribe)) {
                    this.type = this.fieldDescribe.dataType;
                }
            }
        }
    }

    @wire(getPicklistValues, {
        fieldApiName: '$fullFieldApiNameForStandardPicklists',
        recordTypeId: '$defaultRecordTypeId'
    })
    wiredPicklistValues({error, data}) {
        if (data) {
            this.picklistValues = [this.PICKLIST_OPTION_NONE, ...data.values];
        }
        if (error) {
            console.error(error);
        }
    }

    get fullFieldApiNameForStandardPicklists() {
        if (this.isStandardPicklist()) {
            return `${this.objectApiName}.${this.fieldApiName}`;
        }
    }

    isStandardPicklist() {
        return this.isLightningCombobox && !this.isRecordTypePicklist && !this.hasPicklistOverride;
    }

    /*******************************************************************************
    * @description Dispatches an event to notify parent component that the form
    * field's defaultValue property for a combobox has changed.
    *
    * @param {object} event: Event object from lightning-combobox onchange event handler 
    */
    handleChangeCombobox(event) {
        const { value } = event.detail;
        const isSelectedValueNone = value === this.CUSTOM_LABELS.commonLabelNone;

        const detail = {
            objectApiName: this.objectApiName,
            fieldApiName: this.fieldApiName,
            value: isSelectedValueNone ? null : value
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
            this.value = this.valueFromLookupChange(event);
        } else if (event.target) {
            this.value = event.target.value;
        }

        let isValid;
        if (this.isLightningRichText) {
            isValid = this.checkRichTextValidity();
        } else {
            isValid = this.isValid();
        }

        let detail = {
            objectApiName: this.objectApiName,
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

    valueFromLookupChange(event) {
        const val = event.detail.value;
        if (isString(val)) {
            return val;
        } else if (Array.isArray(val)) {
            return val[0] ? val[0] : null;
        }
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

    get qaLocatorPicklist() {
        return `combobox ${this.uiLabel}`;
    }

    get qaLocatorLookup() {
        return `autocomplete ${this.uiLabel}`;
    }

    /*******************************************************************************
     * End getters for data-qa-locator attributes
     */


}