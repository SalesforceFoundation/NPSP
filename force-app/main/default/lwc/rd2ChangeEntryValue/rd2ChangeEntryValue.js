import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class Rd2ChangeEntryValue extends NavigationMixin(LightningElement) {
    @api value;
    @api idValue;
    @api displayType;

    navigateToRecord() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.idValue,
                actionName: 'view'
            }
        });
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