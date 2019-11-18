import {LightningElement, api, track} from 'lwc';

const PAYMENT_WIDGET = 'geFormWidgetPayment';
const ALLOCATION_WIDGET = 'geFormWidgetAllocation';
const WIDGET_LIST = [PAYMENT_WIDGET, ALLOCATION_WIDGET];

export default class GeFormWidget extends LightningElement {
    // TODO: Could value be an array that matches the field mappings list passed to the widget?
    @track value = [];
    @api element;

    @api
    get fieldAndValue() {
        // TODO: Should this contain a list of all records maintained by this widget?
        let fieldAndValue = {};
        const thisWidget = this.widgetComponent;
        // Need to make sure all widget components support returnValue()
        if(this.isValid && typeof thisWidget.returnValues === 'function'){
            this.value = thisWidget.returnValues();
            fieldAndValue[this.element.componentName] = this.value;
        }
        return fieldAndValue;
    }

    get isValid() {
        const thisWidget = this.widgetComponent;
        let isValid = false;
        if(thisWidget !== null && typeof thisWidget !== 'undefined'
            && typeof thisWidget.isValid === 'function') {
                isValid = thisWidget.isValid();
        }
        return isValid;
    }

    get widgetComponent(){
        return this.template.querySelector('[data-id="widgetComponent"]');
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
        console.log('Is Widget valid?: ' + this.isValid); 
    }

}