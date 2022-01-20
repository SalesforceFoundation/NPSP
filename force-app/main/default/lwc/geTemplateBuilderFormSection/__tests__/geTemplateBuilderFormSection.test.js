import { createElement } from 'lwc';
import GeTemplateBuilderFormSection from 'c/geTemplateBuilderFormSection';
import dummyFormSectionData from './data/formSection.json';
import { CLICKED_DOWN, CLICKED_UP } from 'c/geConstants';
import * as a11yHelpers from '../geTemplateBuilderFormSectionA11yHelpers';
import { deepClone } from '../../utilCommon/utilCommon';

jest.useFakeTimers();
jest.mock('c/geTemplateBuilderService', () => {
    return {
        fieldMappingByDevName: {}
    };
});
const scrollIntoViewMock = jest.fn();
window.HTMLElement.prototype.scrollIntoView = scrollIntoViewMock;

describe('c-ge-template-builder-form-section', () => {

    afterEach(clearDOM);

    describe('render behavior', () => {
        it('renders 9 form fields', async () => {
            const element = createFormSection();
            element.formSection = dummyFormSectionData;
            document.body.appendChild(element);

            expect(element.shadowRoot.querySelectorAll('c-ge-template-builder-form-field').length).toBe(9);
        });
    });

    describe('focus placement', () => {
        it('places focus on the up icon button of the bottom-most form field', async () => {
            const element = createFormSection();
            element.formSection = dummyFormSectionData;
            document.body.appendChild(element);

            const updateFocusForSpy = jest.spyOn(a11yHelpers, 'updateFocusFor');

            const secondToLastFormField = element.shadowRoot.querySelectorAll('c-ge-template-builder-form-field')[7];
            secondToLastFormField.focusOnUpButton = jest.fn();

            // Simulate parent component updating form field array position
            [dummyFormSectionData.elements[7], dummyFormSectionData.elements[8]]
                = [dummyFormSectionData.elements[8], dummyFormSectionData.elements[7]];
            element.formSection = dummyFormSectionData;

            const downIconButton = secondToLastFormField.shadowRoot.querySelector('lightning-button-icon[data-id="down"]');
            downIconButton.click();

            await Promise.resolve();
            jest.runOnlyPendingTimers();

            const expectedLength = 9;
            const expectedIndex = 8;
            expect(updateFocusForSpy).toHaveBeenCalledWith(
                expect.anything(),
                CLICKED_DOWN,
                expectedLength,
                expectedIndex
            );
            expect(secondToLastFormField.focusOnUpButton).toHaveBeenCalled();
        });

        it('places focus on the down icon button of the top-most form field', async () => {
            let element = createFormSection();
            element.formSection = dummyFormSectionData;
            document.body.appendChild(element);

            const updateFocusForSpy = jest.spyOn(a11yHelpers, 'updateFocusFor');

            const secondFormField = element.shadowRoot.querySelectorAll('c-ge-template-builder-form-field')[1];
            secondFormField.focusOnDownButton = jest.fn();

            // Simulate parent component updating form field array position
            [dummyFormSectionData.elements[0], dummyFormSectionData.elements[1]]
                = [dummyFormSectionData.elements[1], dummyFormSectionData.elements[0]];
            element.formSection = dummyFormSectionData;

            const upIconButton = secondFormField.shadowRoot.querySelector('lightning-button-icon[data-id="up"]');
            upIconButton.click();

            await Promise.resolve();
            jest.runOnlyPendingTimers();

            const expectedLength = 9;
            const expectedIndex = 0;
            expect(updateFocusForSpy).toHaveBeenCalledWith(
                expect.anything(),
                CLICKED_UP,
                expectedLength,
                expectedIndex
            );
            expect(secondFormField.focusOnDownButton).toHaveBeenCalled();
        });
    });
});

function createFormSection() {
    const element = createElement('c-ge-template-builder-form-section', {
        is: GeTemplateBuilderFormSection
    });
    return element;
}