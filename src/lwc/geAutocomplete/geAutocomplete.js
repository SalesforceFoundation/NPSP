import { LightningElement, api } from 'lwc';
import GeLabelService from 'c/geLabelService';
import { isNotEmpty } from 'c/utilCommon';

const COMBO_BOX_CLASS = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
const INPUT_CLASS = 'slds-input slds-combobox__input';


export default class GeAutocomplete extends LightningElement {
    @api displayValue;
    @api value;
    @api options;
    @api iconName;
    @api label;
    @api fieldInfo;
    @api valid;
    @api required;

    CUSTOM_LABELS = GeLabelService.CUSTOM_LABELS;

    /**
     * Handle changes in the value being searched for.
     * @param event
     */
    handleChange(event) {
        this.dispatchEvent(new CustomEvent('change', {detail: event.target.value}));
    }

    /**
     * Handle selecting one of the options in the dropdown list, clear the dropdown list.
     * @param event
     */
    handleSelect(event) {
        this.dispatchEvent(new CustomEvent('select', event));
        this.options = [];
    }

    /**
     * Clear the selected value and the search input value.
     * @param event
     */
    handleClear(event) {
        this.displayValue = '';
        this.value = null;
        const payload = {
            detail: {
                value: this.value,
                displayValue: this.displayValue
            }
        };
        this.dispatchEvent(new CustomEvent('select', payload));
    }

    /**
     * When TRUE, options are available in the dropdown list.
     * @returns {boolean}
     */
    get hasOptions() {
        return typeof this.options !== 'undefined' && Array.isArray(this.options) && this.options.length > 0;
    }

    /**
     * @returns {boolean} TRUE when an option is selected for this lookup
     */
    get hasOptionSelected() {
        return !this.hasOptions && isNotEmpty(this.value);
    }

    get invalid() {
        // necessary for aria attributes
        return !this.valid;
    }

    /*******************************************
     Dynamic CSS/Id / Display Attributes below here
     *******************************************/

    get formElementClass() {
        return this.valid ? 'slds-form-element' : 'slds-form-element slds-has-error';
    }

    get comboBoxClass() {
        return this.hasOptions ? COMBO_BOX_CLASS + ' slds-is-open' : COMBO_BOX_CLASS;
    }

    get comboBoxContainerClass() {
        return this.hasOptionSelected ? 'slds-combobox_container slds-has-selection' : 'slds-combobox_container';
    }

    get comboBoxFormElementClass() {
        return this.hasOptionSelected ?
            'slds-combobox__form-element slds-input-has-icon slds-input-has-icon_left-right'
            : 'slds-combobox__form-element slds-input-has-icon slds-input-has-icon_right';
    }

    get inputClass() {
        return this.hasOptionSelected ? INPUT_CLASS + ' slds-combobox__input-value' : INPUT_CLASS;
    }

    get comboBoxId() {
        return `comboBox-${this.id}`;
    }

    get listBoxId() {
        return `listBox-${this.id}`;
    }

    get errorMsgId() {
        return `errMsg-${this.id}`;
    }
}