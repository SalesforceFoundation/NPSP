import {LightningElement, api, track} from 'lwc';
import GeFormService from 'c/geFormService';

const PAYMENT_WIDGET = 'geFormWidgetPayment';
const ALLOCATION_WIDGET = 'geFormWidgetAllocation';
const WIDGET_LIST = [PAYMENT_WIDGET, ALLOCATION_WIDGET];

const DELAY = 300;

export default class GeFormWidget extends LightningElement {
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
        // TODO: Will need to update this when we decide how to store Widget data
        let fieldAndValue = {};
        fieldAndValue[this.element.value] = this.value;
        return fieldAndValue;
    }

    widgetIsValid() {
        const thisWidget = this.template.querySelector('[data-id="widgetComponent"]');
        let isValid = true;
        if(thisWidget !== null && typeof thisWidget !== 'undefined'
            && typeof thisWidget.isValid == 'function') {
                isValid = thisWidget.isValid();
        }
        return isValid;
    }

    get isPaymentScheduler() {
        return this.element.componentName === PAYMENT_WIDGET;
    }

    get isAllocation() {
        return this.element.componentName === ALLOCATION_WIDGET;
    }

    get widgetNotFound(){
        return WIDGET_LIST.indexOf(this.element.componentName) < 0
    }

    checkValid() {
        console.log('Is Widget valid?: ' + this.widgetIsValid()); 
    }

}