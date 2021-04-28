/**
 * For the original lightning-input mock that comes with
 * @salesforce/sfdx-lwc-jest, see:
 * https://github.com/salesforce/sfdx-lwc-jest/blob/master/src/lightning-stubs/inputField/inputField.js
 */
import { LightningElement, api } from 'lwc';

export const mockGetInputFieldValue = jest.fn().mockImplementation((field) => {
    return field._value;
});

export default class InputField extends LightningElement {
    @api dirty;
    @api disabled;
    @api fieldName;
    @api readOnly;
    @api required;
    @api get value() {
        return mockGetInputFieldValue(this);
    }
    set value(v) {
        this._value = v;
    }
    @api variant;
    @api clean() {}
    @api reportValidity() {}
    @api reset() {}
    @api setErrors() {}
    @api updateDependentField() {}
    @api wirePicklistValues() {}
    @api wireRecordUi() {}

    _value;
}