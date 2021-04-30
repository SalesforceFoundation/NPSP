import {api, LightningElement} from 'lwc';
import { isBlank } from 'c/util';

export default class FormattedTextWithDate extends LightningElement {
    @api value;
    @api date;

    get splitText() {
        return this.value.split('{{DATE}}');
    }

    get firstHalf() {
        return this.splitText[0];
    }

    get secondHalf() {
        return this.splitText[1];
    }

    get hasSecondHalf() {
        return !isBlank(this.secondHalf);
    }

    get hasFirstHalf() {
        return !isBlank(this.firstHalf);
    }
}