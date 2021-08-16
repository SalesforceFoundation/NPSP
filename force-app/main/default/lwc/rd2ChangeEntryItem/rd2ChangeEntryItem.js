import { LightningElement, api } from 'lwc';

export default class Rd2ChangeEntryItem extends LightningElement {
    @api oldValue;
    @api newValue;
    @api oldId;
    @api newId;
    @api label;
    @api displayType;

    get hasNewValue() {
        return this.newValue !== null && this.newValue !== undefined;
    }
}