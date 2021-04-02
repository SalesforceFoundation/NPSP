/**
 * For the original lightning-combobox mock that comes with
 * @salesforce/sfdx-lwc-jest, see:
 * https://github.com/salesforce/sfdx-lwc-jest/blob/master/src/lightning-stubs/combobox/combobox.js
 */
import { LightningElement, api } from 'lwc';

export const mockCheckComboboxValidity = jest.fn();

export default class Combobox extends LightningElement {
    @api disabled;
    @api dropdownAlignment;
    @api fieldLevelHelp;
    @api label;
    @api messageWhenValueMissing;
    @api name;
    @api options;
    @api placeholder;
    @api readOnly;
    @api required;
    @api spinnerActive;
    @api validity;
    @api value;
    @api variant;
    @api checkValidity = mockCheckComboboxValidity
    @api reportValidity() {}
    @api setCustomValidity() {}
    @api showHelpMessageIfInvalid() {}
}