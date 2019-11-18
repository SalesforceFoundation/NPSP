import {LightningElement, api, track} from 'lwc';
import ALLOCATION_OBJECT from '@salesforce/schema/Allocation__c';

export default class GeFormWidgetAllocation extends LightningElement {
    @track value;
    @api element;
    @track recordList = [];

    singleRecord;

    /***
    * @description Initializes the component
    */
    connectedCallback() {
        this.singleRecord = { apiName: ALLOCATION_OBJECT.objectApiName };
        this.addRow();
    }

    /**
     * Expected to return true if widget fields are valid, false otherwise
     * @return Boolean
     */
    @api
    isValid() {
        // TODO: Move this method to the service class?
        let fieldIsValid = true;
        if(this.element.required) {
            return this.value !== null 
                && typeof this.value !== 'undefined' 
                && this.value !== ''
                && fieldIsValid;
        }
        return fieldIsValid;
    }

    /**
     * Expected to return an array of objects for each row of the widget
     * @return [record1, record2, ...]
     */
    @api
    returnValues() {
        // TODO: Need to get this working with multiple rows of 
        const fields = this.template.querySelectorAll('c-ge-form-field');
        let widgetFieldAndValues = {};
        if(fields !== null && typeof fields !== 'undefined') {
            fields.forEach(field => {
                widgetFieldAndValues = { ...widgetFieldAndValues, ...(field.fieldAndValue) };
            });
        }
        return widgetFieldAndValues;
    }

    /**
     * Add a new record to the list
     */
    addRow(){
        let newRecord = this.singleRecord;
        this.recordList.push(newRecord);
    }

}