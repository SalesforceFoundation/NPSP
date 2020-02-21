import { LightningElement, api, track, wire } from 'lwc';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';

export default class GeFormFieldPicklist extends LightningElement {
    @api objectName;
    @api fieldName;
    @api label;
    @api variant;
    @api required;
    @api value;
    @api className;

    @track _objectDescribeInfo;
    @track picklistValues;
    @track defaultRecordTypeId;

    @wire(getPicklistValues, {
        fieldApiName: '$fullFieldApiName',
        recordTypeId: '$defaultRecordTypeId' })
    wiredPicklistValues({error, data}) {
        if(data) {
            this.picklistValues = data.values;
        }
        if(error) {
            console.error(error);
        }
    }

    @api
    set objectDescribeInfo(val) {
        this._objectDescribeInfo = val;
        if(val) {
            this.defaultRecordTypeId = val.defaultRecordTypeId;
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

}