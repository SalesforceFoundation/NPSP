import { LightningElement, api } from 'lwc';
import { checkNestedProperty } from 'c/utilCommon';

const PAYMENT_SCHEDULER_WIDGET = 'geFormWidgetPaymentScheduler';
const ALLOCATION_WIDGET = 'geFormWidgetAllocation';
const TOKENIZE_CARD_WIDGET = 'geFormWidgetTokenizeCard';
const WIDGET_LIST = [PAYMENT_SCHEDULER_WIDGET, ALLOCATION_WIDGET, TOKENIZE_CARD_WIDGET];

export default class GeFormWidget extends LightningElement {
    @api element;
    @api widgetData;

    @api
    reset() {
        this.widgetComponent.reset();
    }

    @api
    load(data) {
        this.widgetComponent.load(data);
    }

    @api
    get widgetAndValues() {
        let widgetAndValues = {};
        const thisWidget = this.widgetComponent;
        // Need to make sure all widget components support returnValue()
        if(this.isValid && typeof thisWidget.returnValues === 'function'){
            widgetAndValues = thisWidget.returnValues();
        }
        return widgetAndValues;
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
        return checkNestedProperty(this.widgetData, 'donationAmount') ? this.widgetData.donationAmount : 0;
    }

    /**
     * @description This method should return a list of DataImport__c field api names
     *              that the widget uses so that parent components (geFormSection) know
     *              which fields to include when calling this component's load() function.
     * @returns An Array of field names used by this component.
     */
    @api
    get allFieldsByAPIName() {
        if (this.widgetComponent.allFieldsByAPIName) {
            return this.widgetComponent.allFieldsByAPIName;
        } else {
            return null;
        }
    }

    @api
    setCardHolderName(value) {
        let creditCardWidget = this.template.querySelector('c-ge-form-widget-tokenize-card');
        creditCardWidget.setNameOnCard(value);
    }

}