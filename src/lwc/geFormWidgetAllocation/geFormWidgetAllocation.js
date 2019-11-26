import {LightningElement, api, track} from 'lwc';
import ALLOCATION_OBJECT from '@salesforce/schema/Allocation__c';

export default class GeFormWidgetAllocation extends LightningElement {
    @track value;
    @api element;
    @track recordList = [];
    @track fieldList = [];

    // TODO: Logic to determine "rules" for the Widget should go here
    // Ex. Setting the Amount when a percent is entered

    /***
    * @description Initializes the component
    */
    connectedCallback() {
        // Represents the fields in a row of the widget
        this.fieldList = [
            {'mappedField':'Allocation__c.General_Accounting_Unit__c', 'size':4, 'required': true},
            {'mappedField':'Allocation__c.Amount__c', 'size':3},
            {'mappedField':'Allocation__c.Percent__c', 'size':3}
        ];
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
                let rowRecord = row.getValues();
                widgetRowValues.push(rowRecord);
            });
        }

        widgetData[ALLOCATION_OBJECT.objectApiName] = widgetRowValues;
        // console.log(widgetData); 
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