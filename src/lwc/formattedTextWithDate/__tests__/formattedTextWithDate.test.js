import {createElement} from 'lwc';
import FormattedTextWithDate from 'c/formattedTextWithDate';
const PLACEHOLDER_DATE = '2021-05-04';

describe('c-formatted-text-with-date', () => {
    it('renders a string with a date in the middle', () => {
        const element = createElement('c-formatted-text-with-date', { is: FormattedTextWithDate });
        element.value = 'Some text about a day: {{DATE}}. And some follow-up text';
        element.date = PLACEHOLDER_DATE;
        document.body.appendChild(element);

        const textElements = element.shadowRoot.querySelectorAll('lightning-formatted-text');
        expect(textElements).toHaveLength(2);
    });

    it('renders a string with date at the end', () => {
        const element = createElement('c-formatted-text-with-date', { is: FormattedTextWithDate });
        element.value = '{{DATE}} is a day at the start of a string.';
        element.date = PLACEHOLDER_DATE;
        document.body.appendChild(element);

        const textElements = element.shadowRoot.querySelectorAll('lightning-formatted-text');
        expect(textElements).toHaveLength(1);
    });

    it('renders a string with date at the start', () => {
        const element = createElement('c-formatted-text-with-date', { is: FormattedTextWithDate });
        element.value = 'String with date at the end {{DATE}}';
        element.date = PLACEHOLDER_DATE;
        document.body.appendChild(element);

        const textElements = element.shadowRoot.querySelectorAll('lightning-formatted-text');
        expect(textElements).toHaveLength(1);
    });
})