import { LightningElement, api, wire } from 'lwc';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import GeLabelService from 'c/geLabelService';
import * as CONSTANTS from './constants';

export default class GeFormFieldPicklist extends LightningElement {
    // ================================================================================
    // PUBLIC PROPERTIES
    // ================================================================================
    @api objectName;
    @api fieldName;
    @api label;
    @api variant;
    @api required;
    @api className;
    @api qaLocatorBase;

    // ================================================================================
    // PRIVATE PROPERTIES
    // ================================================================================
    _recordTypeId;
    _picklistValues;
    _objectDescribeInfo;
    _value;
    CUSTOM_LABELS = GeLabelService.CUSTOM_LABELS;

    // ================================================================================
    // ACCESSOR METHODS
    // ================================================================================
    @api
    get value() {
        if (this.isValueInOptions(this._value, this.picklistValues)) {
            return this._value;
        }
        if (this.isValueInOptions(this.CUSTOM_LABELS.commonLabelNone, this.picklistValues )) {
            return this._value = this.CUSTOM_LABELS.commonLabelNone;
        }
        return '';
    }

    set value(val) {
        this._value = val;
    }

    @api
    get recordTypeId() {
        return this._recordTypeId;
    }

    set recordTypeId(id) {
        this._recordTypeId = id || this.defaultRecordTypeId;
    }

    get defaultRecordTypeId() {
        if (this.objectDescribeInfo) {
            return this.objectDescribeInfo.defaultRecordTypeId;
        }
        return null;
    }

    get picklistValues() {
        if (this.fieldName === CONSTANTS.RECORD_TYPE_ID) {
            return this.getPicklistOptionsForRecordTypeIds();
        }
        return this._picklistValues;
    }

    set picklistValues(values) {
        this._picklistValues = values;
    }

    @api
    get objectDescribeInfo() {
        return this._objectDescribeInfo;
    }

    set objectDescribeInfo(val) {
        this._objectDescribeInfo = val;
        if (val) {
            if (!this.recordTypeId) {
                this.recordTypeId = this.defaultRecordTypeId;
            }
        }
    }

    get fullFieldApiName() {
        if (this.fieldName === CONSTANTS.RECORD_TYPE_ID) return null;
        return `${this.objectName}.${this.fieldName}`;
    }

    get accessibleRecordTypes() {
        if (!this.objectDescribeInfo) return [];
        const allRecordTypes = Object.values(this.objectDescribeInfo.recordTypeInfos);
        return allRecordTypes.filter(recordType => recordType.available && !recordType.master);
    }

    // ================================================================================
    // PUBLIC METHODS
    // ================================================================================
    @api
    reportValidity() {
        const picklistField = this.template.querySelector('lightning-combobox');
        return picklistField.reportValidity();
    }

    @api
    checkValidity() {
        const picklistField = this.template.querySelector('lightning-combobox');
        return picklistField.checkValidity();
    }

    @api
    setCustomValidity(errorMessage) {
        const picklistField = this.template.querySelector('lightning-combobox');
        return picklistField.setCustomValidity(errorMessage);
    }

    @api
    resetCustomValidity() {
        this.setCustomValidity('');
    }

    @api
    reset() {
        this.recordTypeId = this.defaultRecordTypeId;
    }

    // ================================================================================
    // WIRE METHODS
    // ================================================================================
    @wire(getPicklistValues, {
        fieldApiName: '$fullFieldApiName',
        recordTypeId: '$recordTypeId'
    })
    wiredPicklistValues({ error, data }) {
        if (data) {
            this.picklistValues = [CONSTANTS.PICKLIST_OPTION_NONE, ...data.values];
        }
        if (error) {
            console.error(error);
        }
    }

    // ================================================================================
    // PRIVATE METHODS
    // ================================================================================
    handleValueChange(event) {
        event.stopPropagation();
        this.value = event.detail.value;
        this.dispatchEvent(new CustomEvent('change', event));
    }

    getPicklistOptionsForRecordTypeIds() {
        if (!this.accessibleRecordTypes || this.accessibleRecordTypes.length <= 0) {
            return [CONSTANTS.PICKLIST_OPTION_NONE];
        }

        const recordTypeIdPicklistOptions = this.accessibleRecordTypes.map(recordType => {
            return this.createPicklistOption(recordType.name, recordType.recordTypeId);
        });

        return recordTypeIdPicklistOptions;
    }

    createPicklistOption = (label, value, attributes = null, validFor = []) => ({
        attributes: attributes,
        label: label,
        validFor: validFor,
        value: value
    });

    isValueInOptions(value, options) {
        if (!options || options.length === 0) {
            return false;
        }

        const valueIsInOptions = valueToCheck =>
            options.some(option => {
                return option.value === valueToCheck;
            });

        let valueExists = false;
        if (Array.isArray(value)) {
            valueExists = value.every(valueToCheck => {
                return valueIsInOptions(valueToCheck);
            });
        } else {
            valueExists = valueIsInOptions(value);
        }
        return valueExists;
    }

    // ================================================================================
    // AUTOMATION ACCESSOR METHODS
    // ================================================================================
    get qaLocatorPicklist() {
        return `combobox ${this.qaLocatorBase}`;
    }
}