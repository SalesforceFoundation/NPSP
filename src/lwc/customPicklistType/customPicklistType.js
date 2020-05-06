import { LightningElement, api } from 'lwc';

export default class customPicklistType extends LightningElement {
    @api label;
    @api value;
    @api options;
    @api placeholder;
    @api keyField;
    @api disabled;

    /***
    * @description Propagates the picklist value change to the custom datatable event handler
    */
    handleChange(event) {
        this.value = event.detail.value;

        this.dispatchEvent(new CustomEvent('picklistchange', {
            composed: true,
            bubbles: true,
            cancelable: true,
            detail: {
                data: { value: this.value, keyField: this.keyField }
            }
        }));
    }

}