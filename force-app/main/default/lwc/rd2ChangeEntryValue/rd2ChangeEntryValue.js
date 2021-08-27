import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import stgLabelFieldValueNone from '@salesforce/label/c.stgLabelFieldValueNone';

export default class Rd2ChangeEntryValue extends NavigationMixin(LightningElement) {
    @api value;
    @api recordIdValue;
    @api displayType;
    @api currencyCode;

    labelNone = stgLabelFieldValueNone;

    navigateToRecord() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordIdValue,
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

    get isEmptyLookup() {
        return this.displayType === 'LOOKUP' && (this.value === null || this.value === undefined);
    }

    get isPopulatedLookup() {
        return this.displayType === 'LOOKUP' && this.value !== null && this.value !== undefined;
    }

    get isMultiCurrency() {
        return this.currencyCode != null;
    }
}