import { createElement } from 'lwc';
import GivenSummary from '../givenSummary';

function flushPromises() {
    // eslint-disable-next-line no-undef
    return new Promise((resolve) => setImmediate(resolve));
}

describe('c-given-summary', () => {
    afterEach(() => {
        // clean mock functions
        jest.clearAllMocks();

        // The jsdom instance is shared across test cases in a single file so reset the DOM
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('displays three fields on the component', () => {
        const element = createElement('c-given-summary', { is: GivenSummary });
        document.body.appendChild(element);
        return flushPromises().then(() => {
            expect(
                element.shadowRoot.querySelector('lightning-card')
            ).toBeTruthy();
            expect(element.shadowRoot.querySelector('.lifetime')).toBeTruthy();
            expect(
                element.shadowRoot.querySelector('.lifetime').innerHTML
            ).toBe('$7,000');
            expect(
                element.shadowRoot.querySelector('.thisYear').innerHTML
            ).toBe('$6,000');
            expect(
                element.shadowRoot.querySelector('.previousYear').innerHTML
            ).toBe('$1,000');
        });
    });
});
