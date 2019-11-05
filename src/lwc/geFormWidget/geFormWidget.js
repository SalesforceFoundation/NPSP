import {LightningElement, api, track} from 'lwc';
import GeFormService from 'c/geFormService';

const PAYMENT_WIDGET = 'geFormPaymentWidget';

const DELAY = 300;

export default class GeFormField extends LightningElement {
    // TODO: Could value be an array that matches the field mappings list passed to the widget?
    @track value;
    @api element;

    changeTimeout;

    handleValueChange(event) {
        this.value = event.target.value;
        window.clearTimeout(this.changeTimeout);
        this.changeTimeout = setTimeout(() => {
            // parent component (formSection) should bind to onchange event
            const evt = new CustomEvent('change', {field: this.element, value: this.value});
            this.dispatchEvent(evt);
        }, DELAY);
    }

    get isPaymentScheduler() {
        return this.element.componentName === PAYMENT_WIDGET;
    }

    @api
    get fieldAndValue() {
        // TODO: Will need to update this when we decide how to store Widget data
        let fieldAndValue = {};
        fieldAndValue[this.element.value] = this.value;
        return fieldAndValue;
    }

    isValid() {
        const thisWidget = this.template.querySelector('[data-id="widgetComponent"]');
        let isValid = true;
        if(thisWidget !== null && typeof thisWidget !== 'undefined'
            && typeof thisWidget.isValid == 'function') {
                isValid = thisWidget.isValid();
        }
        return isValid;
    }

    checkValid() {
        // console.log(this.isValid()); 
    }

}