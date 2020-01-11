import { LightningElement, api, track } from 'lwc';
import { inputTypeByDescribeType } from 'c/utilTemplateBuilder';

const BOOLEAN = 'boolean';
const TEXTAREA = 'textarea';
const COMBOBOX = 'combobox';
const SEARCH = 'search';
const RICHTEXT = 'richtext';
const CHECKBOX = 'checkbox';
const DATE = 'date';
const DATETIME = 'datetime-local';
const YES = 'Yes';
const TEXT = 'text';
const TRUE = 'true';

export default class utilInput extends LightningElement {

    @api fieldApiName;
    @api label;
    @api defaultValue;
    @api required;
    @api type;
    @api objectInfo;

    @track value;

    @api
    reportValue() {
        return {
            objectApiName: this.objectInfo ? this.objectInfo.apiName : undefined,
            fieldApiName: this.fieldApiName,
            value: this.value ? this.value : this.defaultValue
        };
    }

    get defaultValueForCheckbox() {
        return (this.defaultValue === TRUE || this.defaultValue === true) ? true : false;
    }

    get isLightningTextarea() {
        return this.lightningInputType === TEXTAREA ? true : false;
    }

    get isLightningCombobox() {
        return this.lightningInputType === COMBOBOX ? true : false;
    }

    get isLightningSearch() {
        return this.lightningInputType === SEARCH ? true : false;
    }

    get isLightningRichText() {
        return this.lightningInputType === RICHTEXT ? true : false;
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
            this.lightningInputType !== RICHTEXT &&
            this.lightningInputType !== SEARCH &&
            this.lightningInputType !== CHECKBOX &&
            this.lightningInputType !== DATE &&
            this.lightningInputType !== DATETIME) {
            return true;
        }
        return false;
    }

    get formatter() {
        if (this.type === 'Currency' || this.type === 'Percent' || this.type === 'Decimal') {
            return this.type;
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

    get uiLabel() {
        if (this.label) {
            return this.label;
        } else if (this.fieldDescribe) {
            return this.fieldDescribe.label;
        }
        return undefined;
    }

    connectedCallback() {
        console.log('**********************--- connectedCallback');
        console.log(this.fieldApiName);
    }

    /*******************************************************************************
    * @description Dispatches an event to notify parent component that the form
    * field's defaultValue property for a combobox has changed.
    *
    * @param {object} event: Event object from lightning-combobox onchange event handler 
    */
    handleChangeCombobox(event) {
        let detail = {
            fieldName: this.name,
            property: 'defaultValue',
            value: event.target.value
        }

        //dispatch(this, 'updateformelement', detail);
    }

    /*******************************************************************************
    * @description Dispatches an event to notify parent component that the form
    * field's defaultValue property has changed.
    *
    * @param {object} event: Event object from various lightning-input type's
    * onblur event handler 
    */
    handleOnBlur(event) {
        this.value = this.type && this.lightningInputType === CHECKBOX ?
            event.target.checked :
            event.target.value;
    }
}