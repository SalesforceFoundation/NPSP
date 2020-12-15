import { LightningElement, api, track, wire } from 'lwc';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import GeLabelService from 'c/geLabelService';
import {isEmpty, isNotEmpty} from 'c/utilCommon';

export default class GeFormFieldPicklist extends LightningElement {
    @api objectName;
    @api fieldName;
    @api label;
    @api variant;
    @api required;
    @api value;
    @api className;
    @api qaLocatorBase;
    @api picklistOptionsOverride;

    @track _objectDescribeInfo;
    @track _picklistValues;
    @track defaultRecordTypeId;

    _recordTypeId;
    CUSTOM_LABELS = GeLabelService.CUSTOM_LABELS;

    @wire(getPicklistValues, {
        fieldApiName: '$fullFieldApiName',
        recordTypeId: '$_recordTypeId' })
    wiredPicklistValues({error, data}) {
        if (data) {
            const valueNone = {
                label: this.CUSTOM_LABELS.commonLabelNone,
                value: this.CUSTOM_LABELS.commonLabelNone
            };
            this.picklistValues = [valueNone, ...data.values];
        }
        if (error) {
            console.error(error);
        }
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
        if (this.shouldRetrievePicklistValues()) {
            return `${this.objectName}.${this.fieldName}`;
        }
    }

    shouldRetrievePicklistValues() {
        return isEmpty(this.picklistOptionsOverride) && isNotEmpty(this.objectName) && isNotEmpty(this.fieldName);
    }

    handleValueChange(event) {
        this.value = event.detail.value;
        this.dispatchEvent(new CustomEvent('onchange', event)); // bubble up to ge-form-field
    }

    @api
    reportValidity(){
        const picklistField = this.template.querySelector('lightning-combobox');
        return picklistField.reportValidity();
    }

    @api
    checkValidity(){
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

    @api
    get recordTypeId() {
        return this._recordTypeId;
    }

    set recordTypeId(id) {
        this._recordTypeId = id || this.defaultRecordTypeId;
    }

    get picklistValues() {
        return isNotEmpty(this.picklistOptionsOverride) ? this.picklistOptionsOverride : this._picklistValues;
    }

    set picklistValues(value) {
        this._picklistValues = value;
    }

    connectedCallback() {
        if (!this.recordTypeId) {
            this.recordTypeId = this.defaultRecordTypeId;
        }
        if (isEmpty(this.value)) {
            // Default picklist values to --None-- if no value is loaded
            this.value = this.CUSTOM_LABELS.commonLabelNone;
        }
    }

    get qaLocatorPicklist() {
        return `combobox ${this.qaLocatorBase}`;
    }
}