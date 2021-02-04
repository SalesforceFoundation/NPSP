import {LightningElement, api} from 'lwc';

export default class UtilProgressBar extends LightningElement {
    @api title;

    @api actualValue;
    @api expectedValue;

    @api formatStyle;
    @api currencyCode;

    get progress() {
        return Math.round(this.actualValue / this.expectedValue * 100);
    }

    get isCurrency() {
        return this.formatStyle === 'currency';
    }

}