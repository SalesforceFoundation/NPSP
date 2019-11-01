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

    @api
    get fieldAndValue() {
        let fieldAndValue = {};
        fieldAndValue[this.element.value] = this.value;
        return fieldAndValue;
    }

    get isPaymentScheduler() {
        return this.element.componentName === PAYMENT_WIDGET;
    }

}