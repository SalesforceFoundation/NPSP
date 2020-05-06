import { LightningElement, api } from 'lwc';

export default class customPicklistType extends LightningElement {
    @api label;
    @api value;
    @api options;
    @api placeholder;
    @api context;

    handleChange(event) {
        this.value = event.detail.value;
    }
}