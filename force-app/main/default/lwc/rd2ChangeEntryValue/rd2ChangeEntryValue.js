import { LightningElement, api } from 'lwc';

export default class Rd2ChangeEntryValue extends LightningElement {
    @api value;
    @api idValue;
    @api displayType;

    navigateToRecord() {

    }

    get isMoney() {
        return this.displayType === 'MONEY';
    }

    get isText() {
        return this.displayType === 'TEXT';
    }

    get isNumber() {
        return this.displayType === 'NUMERIC';
    }

    get isLookup() {
        return this.displayType === 'LOOKUP';
    }
}