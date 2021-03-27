import { LightningElement, api } from 'lwc';

export default class GeFormWidgetTokenizeCard extends LightningElement {
    @api sourceFieldsUsedInTemplate = [];
    @api widgetDataFromState;
    @api paymentToken;
}