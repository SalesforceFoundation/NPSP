import { LightningElement, api, wire } from 'lwc';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import GeLabelService from 'c/geLabelService';
import * as CONSTANTS from './constants';
import OPPORTUNITY from '@salesforce/schema/Opportunity';

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
        if (!this._value && this.isValueInOptions(this.CUSTOM_LABELS.commonLabelNone, this.picklistValues)) {
            return this._value = this.CUSTOM_LABELS.commonLabelNone;
        }
        return '';
    }

    set value(val) {
        if (this.isOpportunity && this.isRecordTypeIdLookup) {
            const picklistOption = this.findPicklistOptionWithLabel(val);
            this._value = picklistOption && picklistOption.value ? picklistOption.value : val;
        } else {
            this._value = val;
        }
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

    get isOpportunity() {
        return this.objectName === OPPORTUNITY.objectApiName;
    }

    get isRecordTypeIdLookup() {
        return this.fieldName === CONSTANTS.RECORD_TYPE_ID;
    }

    /**
     * Accessor method returns the full object and field api name.
     *
     * Returns null if the current field is a RecordTypeId so that we
     * don't invoke the wired `wiredPicklistValues` function. Instead
     * we retrieve record types objects from `_objectDescribeInfo`
     * and build the picklist options array from there.
     */
    get fullFieldApiName() {
        if (this.isRecordTypeIdLookup) return null;
        return `${this.objectName}.${this.fieldName}`;
    }

    handleValueChange(event) {
        this.value = event.detail.value;
        this.dispatchEvent(new CustomEvent('onchange', event)); // bubble up to ge-form-field
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

    findPicklistOptionWithLabel(label) {
        return this.picklistValues.find(option => option.label === label);
    }

    createPicklistOption = (label, value, attributes = null, validFor = []) => ({
        attributes: attributes,
        label: label,
        validFor: validFor,
        value: value
    });

    isValueInOptions(value, options) {
        if (!options || options.length === 0) return false;
        return options.some(option => {
            return option.value === value;
        });
    }

    // ================================================================================
    // AUTOMATION ACCESSOR METHODS
    // ================================================================================
    get qaLocatorPicklist() {
        return `combobox ${this.qaLocatorBase}`;
    }
}