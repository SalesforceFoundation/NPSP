import {LightningElement, api} from 'lwc';

export default class GeAutocomplete extends LightningElement {
    @api displayValue;
    @api options;
    @api iconName;
    @api label;

    handleChange(event) {
        this.dispatchEvent(new CustomEvent('change', event));
    }

    handleSelect(event) {
        this.dispatchEvent(new CustomEvent('select', event));
        this.options = [];
    }

    get hasOptions() {
        return typeof this.options !== 'undefined' && Array.isArray(this.options) && this.options.length > 0;
    }
}