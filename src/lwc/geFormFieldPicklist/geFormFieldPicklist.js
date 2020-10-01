import { LightningElement, api, track, wire } from 'lwc';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import GeLabelService from 'c/geLabelService';
import { isEmpty } from 'c/utilCommon';

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
    @track defaultRecordTypeId;

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

    get picklistValues() {
        return this._picklistValues;
    }

    set picklistValues(values) {
        this._picklistValues = values;
    }

    @api
    set objectDescribeInfo(val) {
        this._objectDescribeInfo = val;
        if (val) {
            this.defaultRecordTypeId = val.defaultRecordTypeId;
            if (!this.recordTypeId) {
                this.recordTypeId = this.defaultRecordTypeId;
            }
        } else {
            this.defaultRecordTypeId = null;
        }
    }

    get objectDescribeInfo() {
        return this._objectDescribeInfo;
    }

    get fullFieldApiName() {
        return `${this.objectName}.${this.fieldName}`;
    }

    @api
    get recordTypeId() {
        return this._recordTypeId;
    }

    set recordTypeId(id) {
        this._recordTypeId = id || this.defaultRecordTypeId;
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
        if (!this.recordTypeId) {
            this.recordTypeId = this.defaultRecordTypeId;
        }
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

    // ================================================================================
    // AUTOMATION ACCESSOR METHODS
    // ================================================================================
    get qaLocatorPicklist() {
        return `combobox ${this.qaLocatorBase}`;
    }
}