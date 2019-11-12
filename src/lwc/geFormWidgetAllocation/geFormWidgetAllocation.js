import {LightningElement, api, track} from 'lwc';
import GeFormWidget from 'c/geFormWidget';
import GeFormField from 'c/geFormField';

const DELAY = 300;

export default class GeFormWidgetAllocation extends LightningElement {
    @track value;
    @api element;

    changeTimeout;

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

}