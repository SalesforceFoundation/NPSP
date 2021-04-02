import { createElement } from 'lwc';
import GeFormSection from 'c/geFormSection';

import section from './data/section.json';
import sectionWithElevateWidget from './data/sectionWithElevateWidget.json';

jest.mock('c/geFormService', () => {
    return {
        getFieldMappingWrapper: jest.fn(),
        getInputTypeFromDataType: jest.fn(),
        getNumberFormatterByDescribeType: jest.fn(),
        getObjectMapping: jest.fn(),
        importedRecordFieldNames: jest.fn(),
        fieldMappingsForImportedRecordFieldName: jest.fn(),
        getFieldMappingWrapperFromTarget: jest.fn(),
        getPaymentTransactionStatusEnums: jest.fn(),
        getOrgDomain: jest.fn(),
    };
});

describe('c-ge-form-section', () => {
    afterEach(() => {
        clearDOM();
        jest.clearAllMocks();
    });

    describe('rendered elements', () => {
        it('should render expandable section with provided label', async () => {
            const element = create(section);

            await flushPromises();
            const expandableSectionElements = shadowSelectorAll(element, 'c-util-expandable-section');
            expect(expandableSectionElements.length).toBe(1);

            const sectionLabel = shadowSelector(expandableSectionElements[0], 'span');
            expect(sectionLabel.innerHTML).toBe('Donor Information');
        });

        it('should render 3 form fields', async () => {
            const element = create(section);

            await flushPromises();
            const formFieldElements = shadowSelectorAll(element, 'c-ge-form-field');
            expect(formFieldElements.length).toBe(3);
        });

        it('should render 3 form fields and the elevate widget', async () => {
            const element = create(sectionWithElevateWidget);

            await flushPromises();
            const formFieldElements = shadowSelectorAll(element, 'c-ge-form-field');
            expect(formFieldElements.length).toBe(3);

            const formWidgetElement = shadowSelectorAll(element, 'c-ge-form-widget')[0];
            const elevateWidgets = shadowSelectorAll(formWidgetElement, 'c-ge-form-widget-tokenize-card');
            expect(elevateWidgets.length).toBe(1);
        });
    });
});

const shadowSelectorAll = (element, selector) => {
    return element.shadowRoot.querySelectorAll(selector);
}

const shadowSelector = (element, selector) => {
    return element.shadowRoot.querySelector(selector);
}

const create = (section) => {
    const element = createElement('c-ge-form-section', {
        is: GeFormSection
    });
    element.section = section;
    document.body.appendChild(element);
    return element;
}