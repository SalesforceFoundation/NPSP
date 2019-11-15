import {LightningElement, api, track} from 'lwc';
import ALLOCATION_OBJECT from '@salesforce/schema/Allocation__c';

const DELAY = 300;

export default class GeFormWidgetAllocation extends LightningElement {
    @track value;
    @api element;

    singleRecord;
    changeTimeout;

    /***
    * @description Initializes the component
    */
    connectedCallback() {
        this.singleRecord = { apiName: ALLOCATION_OBJECT.objectApiName };
    }

    // TODO: Move this to a service component
    handleValueChange(event) {
        this.value = event.target.value;
        window.clearTimeout(this.changeTimeout);
        this.changeTimeout = setTimeout(() => {
            // parent component (formSection) should bind to onchange event
            const evt = new CustomEvent('change', {field: this.element, value: this.value});
            this.dispatchEvent(evt);
        }, DELAY);
    }

    /**
     * Expected to return true if widget fields are valid, false otherwise
     * @return Boolean
     */
    @api
    isValid() {
        // TODO: Check that input value is valid for this field type
        // Also move this method to the service class?
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
     * Expected to return an array of sobject records
     * @return [record1, record2, ...]
     */
    @api
    returnValue() {
        const testField = 'Name';
        let returnVal = this.singleRecord;
        returnVal[testField] = 'Test Name';
        return [returnVal];
    }

}