import { createElement } from 'lwc';
import Rd2ChangeEntryValue from 'c/rd2ChangeEntryValue';
import { getNavigateCalledWith } from "lightning/navigation";

describe('c-rd2-change-entry-value', () => {
    afterEach(() => {
        clearDOM();
    });

    it('renders formatted text', () => {
        const component = createElement('c-rd2-change-entry-value', { is: Rd2ChangeEntryValue });
        component.value = 'Some Text';
        component.displayType = 'TEXT';
        document.body.appendChild(component);

        const outputCmp = component.shadowRoot.querySelector('lightning-formatted-text');

        expect(outputCmp.value).toBe('Some Text');

    });

    it('renders currency', () => {
        const component = createElement('c-rd2-change-entry-value', { is: Rd2ChangeEntryValue });
        component.value = 50;
        component.displayType = 'MONEY';
        document.body.appendChild(component);

        const outputCmp = component.shadowRoot.querySelector('lightning-formatted-number');

        expect(outputCmp.value).toBe(50);
        expect(outputCmp.formatStyle).toBe('currency');
    });

    it('renders numbers', () => {
        const component = createElement('c-rd2-change-entry-value', { is: Rd2ChangeEntryValue });
        component.value = 50;
        component.displayType = 'NUMERIC';
        document.body.appendChild(component);

        const outputCmp = component.shadowRoot.querySelector('lightning-formatted-number');

        expect(outputCmp.value).toBe(50);
    });

    it('renders lookup fields', () => {
        const component = createElement('c-rd2-change-entry-value', { is: Rd2ChangeEntryValue });
        component.value = 'Some Record Name';
        component.recordIdValue = 'fake_record_id';
        component.displayType = 'LOOKUP';
        document.body.appendChild(component);

        const outputCmp = component.shadowRoot.querySelector('a');

        expect(outputCmp.textContent).toBe('Some Record Name');
        outputCmp.click();

        const { pageReference } = getNavigateCalledWith();

        expect(pageReference.type).toBe("standard__recordPage");
        expect(pageReference.attributes.recordId).toBe('fake_record_id');
        expect(pageReference.attributes.actionName).toBe("view");

    });

    it('navigates on click', () => {

    });


});