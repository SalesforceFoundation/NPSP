import { LightningElement, api, track, wire } from 'lwc';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';

export default class GeFormFieldPicklist extends LightningElement {
    @api objectName;
    @api fieldName;
    @api label;

    @track picklistValues;
    @api value;

    @wire(getObjectInfo, { objectApiName: '$objectName' } ) objectInfo;

    @wire(getPicklistValues, {
        fieldApiName: '$fullFieldApiName',
        recordTypeId: '$objectInfo.data.defaultRecordTypeId' })
    wiredPicklistValues({error, data}) {
        if(data) {
            this.picklistValues = data.values;
        }

        if(error) {
            console.error(error);
        }
    }

    get fullFieldApiName() {
        return `${this.objectName}.${this.fieldName}`;
    }

    handleValueChange(event) {
        this.value = event.detail.value;
        this.dispatchEvent(new CustomEvent('onchange', event)); // bubble up to ge-form-field
    }
}