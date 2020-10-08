import { createElement } from 'lwc';
import GeFormFieldPicklist from 'c/geFormFieldPicklist';
import { registerLdsTestWireAdapter } from '@salesforce/sfdx-lwc-jest';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';

// Import mock data
const mockGetPicklistValues = require('./data/wiredPicklistValues.json');
const mockSObjectDescribeInfo = require('./data/sObjectDescribeInfo.json');

// Register a test wire adapter to control @wire(getPicklistValues)
const getPicklistValuesWireAdapter = registerLdsTestWireAdapter(getPicklistValues);

describe('c-ge-form-field-picklist', () => {

    afterEach(clearDOM);

    it('should return 3 picklist options', () => {
        const element = createElement('c-ge-form-field-picklist', { is: GeFormFieldPicklist });
        getPicklistValuesWireAdapter.emit(mockGetPicklistValues);
        document.body.appendChild(element);

        return Promise.resolve().then(() => {
            expect(getSubComponentCombobox(element).options.length).toEqual(3);
            expect(getSubComponentCombobox(element).options).toContainOptions([
                'c.stgLabelNone',
                'Picklist_Option_1',
                'Picklist_Option_2'
            ]);
        });
    });

    it('should return 2 picklist options for record type id fields', () => {
        const element = createElement('c-ge-form-field-picklist', { is: GeFormFieldPicklist });
        element.objectName = 'ObjectName__c';
        element.fieldName = 'RecordTypeId';
        element.objectDescribeInfo = mockSObjectDescribeInfo;
        document.body.appendChild(element);

        return Promise.resolve().then(() => {
            expect(getSubComponentCombobox(element).options.length).toEqual(2);
            expect(getSubComponentCombobox(element).options).toContainOptions([
                '000000000000000001',
                '000000000000000002'
            ]);
        });
    });

    it('has correct default value', () => {
        const element = createElement('c-ge-form-field-picklist', { is: GeFormFieldPicklist });
        getPicklistValuesWireAdapter.emit(mockGetPicklistValues);
        document.body.appendChild(element);

        expect(element.value).toBe('c.stgLabelNone');
    });

    it('has correct value when selecting a new option', () => {
        const element = createElement('c-ge-form-field-picklist', { is: GeFormFieldPicklist });
        getPicklistValuesWireAdapter.emit(mockGetPicklistValues);
        document.body.appendChild(element);
        const picklist = element.shadowRoot.querySelector('lightning-combobox');

        return Promise.resolve()
            .then(() => {
                selectOption(picklist, 'Picklist_Option_1');
                expect(element.value).toBe('Picklist_Option_1');
            })
            .then(() => {
                selectOption(picklist, 'Picklist_Option_2');
                expect(element.value).toBe('Picklist_Option_2');
            })
            .then(() => {
                selectOption(picklist, 'c.stgLabelNone');
                expect(element.value).toBe('c.stgLabelNone');
            });
    });

});

expect.extend({
    toContainOptions(actual, expected) {
        const valueExists = valueToCheck =>
            [...actual].some(actualValue => {
                return actualValue.value === valueToCheck;
            });
        const lengthCheck = actual.length === expected.length;
        const pass =
            lengthCheck &&
            [...expected].every(expectedValue => {
                return valueExists(expectedValue);
            });

        return {
            message: () =>
                `expected the picklist to contain options: ${JSON.stringify(expected)}
                actual options: ${JSON.stringify(actual)}`,
            pass,
        };
    }
});

const getShadowRoot = (element) => {
    if (!element || !element.shadowRoot) {
        const tagName =
            element && element.tagName && element.tagName.toLowerCase();
        throw new Error(
            `Attempting to retrieve the shadow root of '${tagName ||
            element}' but no shadowRoot property found`
        );
    }
    return element.shadowRoot;
}

const shadowQuerySelector = (element, selector) => {
    return getShadowRoot(element).querySelector(selector);
}

const getSubComponentCombobox = picklistElement => {
    return shadowQuerySelector(
        picklistElement,
        'lightning-combobox'
    );
};

const selectOption = (picklist, value) => {
    picklist.dispatchEvent(new CustomEvent('change', { detail: { value: value } }));
}
