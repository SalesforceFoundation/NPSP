import { LightningElement, api, track, wire } from 'lwc';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import GeLabelService from 'c/geLabelService';
import { isEmpty } from 'c/utilCommon';
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
    @api value;
    @api className;
    @api qaLocatorBase;

    // ================================================================================
    // REACTIVE PROPERTIES
    // ================================================================================
    @track _objectDescribeInfo;

    // ================================================================================
    // PRIVATE PROPERTIES
    // ================================================================================
    _recordTypeId;
    _picklistValues;
    CUSTOM_LABELS = GeLabelService.CUSTOM_LABELS;

    // ================================================================================
    // ACCESSOR METHODS
    // ================================================================================
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
    set objectDescribeInfo(val) {
        this._objectDescribeInfo = val;
        if (val) {
            if (!this.recordTypeId) {
                this.recordTypeId = this.defaultRecordTypeId;
            }
        }
    }

    get objectDescribeInfo() {
        return this._objectDescribeInfo;
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
    // LIFECYCLE METHODS
    // ================================================================================
    connectedCallback() {
        if (isEmpty(this.value)) {
            // Default picklist values to --None-- if no value is loaded
            this.value = this.CUSTOM_LABELS.commonLabelNone;
        }
    }

    // ================================================================================
    // WIRE METHODS
    // ================================================================================
    @wire(getPicklistValues, {
        fieldApiName: '$fullFieldApiName',
        recordTypeId: '$_recordTypeId'
    })
    wiredPicklistValues({ error, data }) {
        if (data) {
            let valueNone = {
                label: this.CUSTOM_LABELS.commonLabelNone,
                value: this.CUSTOM_LABELS.commonLabelNone
            }
            this.picklistValues = [valueNone, ...data.values];
        }
        if (error) {
            console.error(error);
        }
    }

    // ================================================================================
    // PRIVATE METHODS
    // ================================================================================
    handleValueChange(event) {
        this.value = event.detail.value;
        this.dispatchEvent(new CustomEvent('onchange', event)); // bubble up to ge-form-field
    }

    getPicklistOptionsForRecordTypeIds() {
        if (!this.accessibleRecordTypes || this.accessibleRecordTypes.length <= 0) {
            return [CONSTANTS.PICKLIST_OPTION_NONE];
        }
        // TODO: Potentially exclude 'Master' default record type
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

    // ================================================================================
    // AUTOMATION ACCESSOR METHODS
    // ================================================================================
    get qaLocatorPicklist() {
        return `combobox ${this.qaLocatorBase}`;
    }
}