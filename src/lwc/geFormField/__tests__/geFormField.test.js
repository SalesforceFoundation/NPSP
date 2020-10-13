import {createElement} from 'lwc';
import GeFormField from 'c/geFormField';

const fieldMapping = require('./data/fieldMapping.json');

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
        getObjectMappingWrapper: jest.fn(() => {
            return require('./data/objectMapping.json');
        }),
        importedRecordFieldNames: jest.fn(() => {
            return null;
        }),
        fieldMappingsForImportedRecordFieldName: jest.fn(() => {
            return null;
        })
    };
});

describe('c-ge-form-field', () => {

    afterEach(() => {
        clearDOM();
        jest.clearAllMocks();
    });

    it('fires formfieldchange event when change event ' +
        'from geFormFieldPicklist is handled', () => {

        const elementJSON = require('./data/picklistElement.json');

        const element = createElement('c-ge-form-field', {is: GeFormField});
        element.element = elementJSON;
        element.formState = {
            [fieldMapping.Source_Field_API_Name]: {value: 'testInitialPicklistValue'}
        };

        const picklistChangeHandler = jest.fn();
        element.addEventListener('formfieldchange', picklistChangeHandler);

        document.body.appendChild(element);

        expect(element.isPicklist).toBeTruthy();

        const pl = element.shadowRoot.querySelector('c-ge-form-field-picklist');

        const newPicklistValue = 'newPicklistValue';
        return Promise.resolve().then(() => {
            pl.dispatchEvent(new CustomEvent('change', {value: newPicklistValue}));
        });

        expect(picklistChangeHandler).toBeCalled();

        const formFieldChangeDetailObject = {
            [fieldMapping.Source_Field_API_Name]: {value: newPicklistValue}
        }
        expect(picklistChangeHandler).toBeCalledWith(formFieldChangeDetailObject);
    });

});
