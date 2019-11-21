import {LightningElement, api, track} from 'lwc';
import ALLOCATION_OBJECT from '@salesforce/schema/Allocation__c';

export default class GeFormWidgetAllocation extends LightningElement {
    @track value;
    @api element;
    @track recordList = [];

    /***
    * @description Initializes the component
    */
    connectedCallback() {
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
     * Expected to return a map of Object API Name to array of records to be created from this widget
     * @return {'Allocation__c' : [record1, record2, ...] }
     */
    @api
    returnValues() {
        const rows = this.template.querySelectorAll('c-ge-form-widget-row');
        let widgetData = {};
        let widgetRowValues = [];

        if(rows !== null && typeof rows !== 'undefined') {
            rows.forEach(row => {
                let rowRecord = row.getRecord();
                widgetRowValues.push(rowRecord);
            });
        }

        widgetData[ALLOCATION_OBJECT.objectApiName] = widgetRowValues;
        return widgetData;
    }

    /**
     * Add a new record to the list
     */
    addRow(){
        let newRecord = { apiName: ALLOCATION_OBJECT.objectApiName };
        this.recordList.push(newRecord);
    }

}