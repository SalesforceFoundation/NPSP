/**
 * For the original lightning-input mock that comes with
 * @salesforce/sfdx-lwc-jest, see:
 * https://github.com/salesforce/sfdx-lwc-jest/blob/master/src/lightning-stubs/input/input.js
 */
import { LightningElement, api } from 'lwc';

export const mockCheckInputValidity = jest.fn();

export default class Input extends LightningElement {
    @api accept;
    @api autocomplete;
    @api checked;
    @api dateAriaControls;
    @api dateAriaDescribedBy;
    @api dateAriaLabel;
    @api dateAriaLabelledBy;
    @api dateStyle;
    @api disabled;
    @api fieldLevelHelp;
    @api files;
    @api formatFractionDigits;
    @api formatter;
    @api isLoading;
    @api label;
    @api max;
    @api maxLength;
    @api messageToggleActive;
    @api messageToggleInactive;
    @api messageWhenBadInput;
    @api messageWhenPatternMismatch;
    @api messageWhenRangeOverflow;
    @api messageWhenRangeUnderflow;
    @api messageWhenStepMismatch;
    @api messageWhenTooLong;
    @api messageWhenTooShort;
    @api messageWhenTypeMismatch;
    @api messageWhenValueMissing;
    @api min;
    @api minLength;
    @api multiple;
    @api name;
    @api pattern;
    @api placeholder;
    @api readOnly;
    @api required;
    @api step;
    @api timeAriaControls;
    @api timeAriaDescribedBy;
    @api timeAriaLabelledBy;
    @api timeStyle;
    @api timezone;
    @api type;
    @api validity;
    @api value;
    @api variant;
    @api checkValidity = mockCheckInputValidity;
    @api reportValidity() {}
    @api setCustomValidity() {}
    @api showHelpMessageIfInvalid() {}
}