import { LightningElement, api } from 'lwc';
import {hasNestedProperty, isUndefined} from 'c/utilCommon';

const PAYMENT_SCHEDULER_WIDGET = 'geFormWidgetPaymentScheduler';
const ALLOCATION_WIDGET = 'geFormWidgetAllocation';
const TOKENIZE_CARD_WIDGET = 'geFormWidgetTokenizeCard';
const WIDGET_LIST = [PAYMENT_SCHEDULER_WIDGET, ALLOCATION_WIDGET, TOKENIZE_CARD_WIDGET];

export default class GeFormWidget extends LightningElement {
    @api element;
    @api widgetData;
    @api formState;

    @api
    reset() {
        this.widgetComponent.reset();
    }

    get isValid() {
        const thisWidget = this.widgetComponent;
        let isValid = false;
        if(thisWidget !== null && typeof thisWidget !== 'undefined'
            && typeof thisWidget.isValid === 'function') {
                isValid = thisWidget.isValid();
        } else if(isUndefined(thisWidget.isValid)) {
            // if no validation function defined, assume widget is valid
            return true;
        }
        return isValid;
    }

    get widgetComponent() {
        return this.template.querySelector('[data-id="widgetComponent"]');
    }

    get isPaymentScheduler() {
        return this.element.componentName === PAYMENT_SCHEDULER_WIDGET;
    }

    @api
    get isElevateTokenizeCard() {
        return this.element.componentName === TOKENIZE_CARD_WIDGET;
    }    

    get isAllocation() {
        return this.element.componentName === ALLOCATION_WIDGET;
    }

    get widgetNotFound(){
        return WIDGET_LIST.indexOf(this.element.componentName) < 0
    }

    get totalAmount() {
        return hasNestedProperty(this.widgetData, 'donationAmount') ? this.widgetData.donationAmount : 0;
    }

    handleFormWidgetChange(event) {
        this.dispatchEvent(new CustomEvent('formwidgetchange', {detail: event.detail}))
    }

    @api
    get paymentToken() {
        const thisWidget = this.widgetComponent;
        if (this.isValid) {
            return thisWidget.paymentToken;
        }
    }

}