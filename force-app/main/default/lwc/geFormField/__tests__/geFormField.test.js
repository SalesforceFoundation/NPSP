import { createElement } from 'lwc';
import GeFormField from 'c/geFormField';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';

// Import mock data
const mockGetPicklistValues = require('./data/wiredPicklistValues.json');
const mockSObjectDescribeInfo = require('./data/sObjectDescribeInfo.json');
const fieldMapping = require('./data/fieldMapping.json');
const recordTypeIdFieldMapping = require('./data/recordTypeIdFieldMapping.json');
const elementJSON = require('./data/picklistElement.json');
const recordTypeIdElementJSON = require('./data/recordTypeIdElement.json');


jest.useFakeTimers();
jest.mock('c/geFormService', () => {
    return {
        getFieldMappingWrapper: jest.fn(() => {
            return require('./data/fieldMapping.json');
        }),
        getInputTypeFromDataType: jest.fn(() => {
            return true;
        }),
        getNumberFormatterByDescribeType: jest.fn(() => {
            return null;
        }),
        getObjectMapping: jest.fn(() => {
            return require('./data/objectMapping.json');
        }),
        importedRecordFieldNames: jest.fn(() => {
            return null;
        }),
        fieldMappingsForImportedRecordFieldName: jest.fn(() => {
            return null;
        }),
        getFieldMappingWrapperFromTarget: jest.fn((targetFieldName) => {
            if (targetFieldName === 'RecordTypeId') {
                return require('./data/recordTypeIdFieldMapping.json');
            }
        }),

    };
});

// Setup for standard picklists
const createStandardPicklistElement = () => {
    const element = createElement('c-ge-form-field', { is: GeFormField });
    element.element = elementJSON;
    element.formState = {
        [fieldMapping.Source_Field_API_Name]: null
    };

    return element;
}

// Setup for record type id picklists
const createRecordTypeIdPicklistElement = () => {
    const element = createElement('c-ge-form-field', { is: GeFormField });
    element.element = recordTypeIdElementJSON;
    element.targetFieldName = 'RecordTypeId';
    element.formState = {
        [recordTypeIdFieldMapping.Source_Field_API_Name]: null
    };

    return element;
}

describe('c-ge-form-field', () => {

    afterEach(() => {
        clearDOM();
        jest.clearAllMocks();
    });

    it('fires formfieldchange event when change event from geFormFieldPicklist is handled', async () => {
        const element = createStandardPicklistElement();

        const picklistChangeHandler = jest.fn();
        element.addEventListener('formfieldchange', picklistChangeHandler);

        document.body.appendChild(element);

        expect(element.isPicklist).toBeTruthy();

        const picklist = element.shadowRoot.querySelector('lightning-combobox');
        dispatchChangeEvent(picklist, 'newPicklistValue');

        return Promise.resolve().then(() => {
            jest.runOnlyPendingTimers();
            expect(picklistChangeHandler).toBeCalled();
            expect(picklistChangeHandler.mock.calls[0][0].detail.value)
                .toStrictEqual('newPicklistValue');
        });
    });

    it('should return 3 picklist options', async () => {
        const element = createStandardPicklistElement();

        getObjectInfo.emit(mockSObjectDescribeInfo);
        getPicklistValues.emit(mockGetPicklistValues);

        document.body.appendChild(element);

        return Promise.resolve().then(() => {
            expect(element.isPicklist).toBeTruthy();
            expect(getSubComponentCombobox(element).options.length).toEqual(3);
            expect(getSubComponentCombobox(element).options).toContainOptions([
                'c.stgLabelNone',
                'Picklist_Option_1',
                'Picklist_Option_2'
            ]);
        });
    });

    it('should return 2 picklist options for record type id fields', async () => {
        const element = createRecordTypeIdPicklistElement();

        getObjectInfo.emit(mockSObjectDescribeInfo);

        document.body.appendChild(element);

        return Promise.resolve().then(() => {
            expect(element.isPicklist).toBeTruthy();
            expect(getSubComponentCombobox(element).options.length).toEqual(2);
            expect(getSubComponentCombobox(element).options).toContainOptions([
                '000000000000000001',
                '000000000000000002'
            ]);
        });
    });

    it('has correct default value for standard picklists', async () => {
        const element = createStandardPicklistElement();

        getObjectInfo.emit(mockSObjectDescribeInfo);
        getPicklistValues.emit(mockGetPicklistValues);

        document.body.appendChild(element);

        const picklist = getSubComponentCombobox(element);

        return Promise.resolve().then(() => {
            expect(picklist.value).toBe('c.stgLabelNone');
        });
    });

    it('has correct default value for record type id picklists', async () => {
        const element = createRecordTypeIdPicklistElement();

        getObjectInfo.emit(mockSObjectDescribeInfo);

        document.body.appendChild(element);

        const picklist = getSubComponentCombobox(element);

        return Promise.resolve().then(() => {
            expect(picklist.value).toBe('');
        });
    });

    it('has correct value when changed in form state', async () => {
        const element = createStandardPicklistElement();

        getObjectInfo.emit(mockSObjectDescribeInfo);
        getPicklistValues.emit(mockGetPicklistValues);

        document.body.appendChild(element);

        const picklist = getSubComponentCombobox(element);

        const picklistChangeHandler = jest.fn();
        element.addEventListener('formfieldchange', picklistChangeHandler);

        return Promise.resolve()
            .then(() => {
                expect(picklist.value).toBe('c.stgLabelNone');

                dispatchChangeEvent(picklist, 'Picklist_Option_1');

                jest.runOnlyPendingTimers();

                expect(picklistChangeHandler).toBeCalled();
                expect(picklistChangeHandler.mock.calls[0][0].detail.value)
                    .toStrictEqual('Picklist_Option_1');

                mockFormState(element, 'Picklist_Option_1');
            })
            .then(() => {
                expect(picklist.value).toBe('Picklist_Option_1');

                dispatchChangeEvent(picklist, 'Picklist_Option_2');

                jest.runOnlyPendingTimers();

                expect(picklistChangeHandler).toBeCalled();
                expect(picklistChangeHandler.mock.calls[1][0].detail.value)
                    .toStrictEqual('Picklist_Option_2');

                mockFormState(element, 'Picklist_Option_2');
            })
            .then(() => {
                expect(picklist.value).toBe('Picklist_Option_2');
            });
    });

});

/**
 * Returns the shadowRoot property of a given Lightning web component.
 * Originally sourced from lightning-global repo.
 *
 * @param {LWCElement} element The Lightning web component element to retrieve
 * the shadowRoot property off of
 * @returns {ShadowRoot} The shadow root of the given element
 */
export const getShadowRoot = (element) => {
    if (!element || !element.shadowRoot) {
        const tagName =
            element && element.tagName && element.tagName.toLowerCase();
        throw new Error(
            `Attempting to retrieve the shadow root of '${tagName || element}'
            but no shadowRoot property found`
        );
    }
    return element.shadowRoot;
}

/**
 * Non-recursively queries the template of the provided element using the
 * provided selector.
 *
 * @param {LWCElement} element The Lightning web component element for which we 
 * want to query the template.
 * @param {String} selector The selector used to match the descendant element.
 * @returns {Element}
 */
export const shadowQuerySelector = (element, selector) => {
    return getShadowRoot(element).querySelector(selector);
}

const getSubComponentCombobox = geFormFieldElement => {
    return shadowQuerySelector(
        geFormFieldElement,
        'lightning-combobox'
    );
};

const mockFormState = (element, value) => {
    element.formState = {
        [element.sourceFieldAPIName]: value
    };
}

const dispatchChangeEvent = (element, value) => {
    const customEventDetail = { detail: { value: value } };
    element.dispatchEvent(new CustomEvent('change', customEventDetail));
}
