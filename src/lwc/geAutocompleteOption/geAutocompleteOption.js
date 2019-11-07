import {LightningElement, api} from 'lwc';

export default class GeAutocompleteOption extends LightningElement {
    @api value;
    @api displayValue;
    @api iconName;

    handleClick() {
        const detail = {
            value: this.value,
            displayValue: this.displayValue
        };
        this.dispatchEvent(new CustomEvent('select', {detail}));
    }

    get hasIcon() {
        return typeof this.iconName !== 'undefined' && this.iconName !== null;
    }
}