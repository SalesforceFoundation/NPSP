import { createElement } from 'lwc';
import Rd2ChangeEntryValue from 'c/rd2ChangeEntryValue';

describe('c-rd2-change-entry-value', () => {
    afterEach(() => {
        clearDOM();
    });

    it('renders formatted text', () => {
        const component = createElement('c-rd2-change-entry-value', { is: Rd2ChangeEntryValue });
        component.value = 'Some Text';
        component.displayType = 'TEXT';
        document.body.appendChild(component);

        const outputCmp = component.querySelector('lightning-formatted-text');
        expect(component).toMatchSnapshot();
        // expect(outputCmp.value).toBe('Some Text');

    });
});