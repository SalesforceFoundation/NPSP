import { createElement } from 'lwc';
import { mockReset } from '../../../../../../tests/__mocks__/lightning/inputField';
import rd2EntryFormCustomFieldsSection from "c/rd2EntryFormCustomFieldsSection";

const mockFields = [
    {
        apiName: 'Custom1__c',
        required: false
    },
    {
        apiName: 'SomeField__c',
        required: false
    }
];

const mockHandleChange = jest.fn();

describe('creating a new record', () => {
    let element;

    beforeEach(async () => {
        element = createElement('c-rd2-entry-form-custom-fields-section', {is: rd2EntryFormCustomFieldsSection});
        element.fields = mockFields;
        element.addEventListener('change', mockHandleChange);
        document.body.appendChild(element);

        await flushPromises();
    });

    afterEach(() => {
        clearDOM();
        jest.clearAllMocks();
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
        expect(returnValues["Custom1__c"]).toBe(1);
        expect(returnValues["SomeField__c"]).toBe(2);
    });

    it('resets field values', () => {
        mockReset.mockImplementation(function () {
            this.value = undefined;
        });

        const inputField = element.shadowRoot.querySelector('lightning-input-field');
        inputField.value = "1";

        const returnValues = element.returnValues();
        expect(returnValues["Custom1__c"]).toBe("1");
        expect(returnValues["SomeField__c"]).toBeFalsy();

        element.resetValues();

        const resetReturnValues = element.returnValues();
        expect(resetReturnValues["Custom1__c"]).toBe(undefined);
        expect(resetReturnValues["SomeField__c"]).toBe(undefined);
    });

    it('fires change events when field values are changed', () => {
        const custom1Field = element.shadowRoot.querySelector('lightning-input-field');
        custom1Field.value = 2;
        custom1Field.dispatchEvent(new CustomEvent('change'));
        expect(mockHandleChange.mock.calls[0][0].detail).toMatchObject({fieldName: "Custom1__c", value: 2});
    });
});

describe("updating an existing record", () => {
    let element;

    beforeEach(async () => {
        element = createElement("c-rd2-entry-form-custom-fields-section", { is: rd2EntryFormCustomFieldsSection });
        const mockFieldsWithData = mockFields.map((f, i) => {
            return { ...f, value: `TestValue${i}` };
        });
        element.fields = mockFieldsWithData;
        document.body.appendChild(element);

        await flushPromises();
    });

    it("populates fields with initial values", () => {
        const inputFields = element.shadowRoot.querySelectorAll('lightning-input-field');
        expect(inputFields).toHaveLength(2);
        inputFields.forEach(f => {
            expect(f.value).toBeTruthy();
            expect(f.value).toMatch(/TestValue/);
        });
    });
});
