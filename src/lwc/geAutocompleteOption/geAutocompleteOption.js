import {LightningElement, api} from 'lwc';

export default class GeAutocompleteOption extends LightningElement {
    @api value;
    @api displayValue;
    @api iconName;

    /**
     * Handle this option being selected.
     * @param event
     */
    handleClick(event) {
        const detail = {
            value: this.value,
            displayValue: this.displayValue
        };
        this.dispatchEvent(new CustomEvent('select', {detail}));
    }

    /**
     * When TRUE, iconName is defined and we should display an icon
     * @returns {boolean}
     */
    get hasIcon() {
        return typeof this.iconName !== 'undefined' && this.iconName !== null;
    }
}