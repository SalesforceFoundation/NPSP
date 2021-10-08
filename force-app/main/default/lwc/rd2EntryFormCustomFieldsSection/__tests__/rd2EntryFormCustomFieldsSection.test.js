import { createElement } from 'lwc';
import { mockReportValidity, mockReset } from '../../../../../../tests/__mocks__/lightning/inputField';
import rd2EntryFormCustomFieldsSection from "c/rd2EntryFormCustomFieldsSection";

describe('custom fields', () => {
    let element;

    beforeEach(async () => {
        element = createElement('c-rd2-entry-form-custom-fields-section', {is: rd2EntryFormCustomFieldsSection});
        element.recordId = '123456';
        element.fields = [
            {
                apiName: 'npe03__Recurring_Donation__c.Custom1__c',
                required: false
            },
            {
                apiName: 'SomeObject.SomeField__c',
                required: false
            }
        ];
        document.body.appendChild(element);

        await flushPromises();
    });

    afterEach(() => {
        clearDOM();
        jest.clearAllMocks();
    });

    it('validates recordId', () => {
        const recordEditForm = element.shadowRoot.querySelector('lightning-record-edit-form');

        expect(recordEditForm.recordId).toBe('123456');
    });

    it('handles two valid fields', () => {
        const inputFields = element.shadowRoot.querySelectorAll('lightning-input-field');
        inputFields.forEach(f => {
            f.value = '1';
            f.required = true;
        });

        expect(element.isValid()).toBeTruthy();
    });

    it('handles two invalid fields', () => {
        const inputFields = element.shadowRoot.querySelectorAll('lightning-input-field');
        inputFields.forEach(f => {
            f.required = true;
        });

        expect(element.isValid()).toBeFalsy();
    });

    it('handles one valid and one invalid field', () => {
        const inputField = element.shadowRoot.querySelector('lightning-input-field');
        inputField.required = true;

        expect(element.isValid()).toBeFalsy();
    });

    it('returns field values', () => {
        let setValue = 1;
        const inputFields = element.shadowRoot.querySelectorAll('lightning-input-field');
        inputFields.forEach(f => { f.value = setValue++ });

        const returnValues = element.returnValues();
        expect(returnValues["npe03__Recurring_Donation__c.Custom1__c"]).toBe(1);
        expect(returnValues["SomeObject.SomeField__c"]).toBe(2);
    });

    it('resets field values', () => {
        mockReset.mockImplementation(function () {
            this.value = undefined;
        });

        const inputField = element.shadowRoot.querySelector('lightning-input-field');
        inputField.value = "1";

        const returnValues = element.returnValues();
        expect(returnValues["npe03__Recurring_Donation__c.Custom1__c"]).toBe("1");
        expect(returnValues["SomeObject.SomeField__c"]).toBeFalsy();

        element.resetValues();

        const resetReturnValues = element.returnValues();
        expect(resetReturnValues["npe03__Recurring_Donation__c.Custom1__c"]).toBe(undefined);
        expect(resetReturnValues["SomeObject.SomeField__c"]).toBe(undefined);
    });
});