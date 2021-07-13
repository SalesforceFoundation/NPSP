import { createElement } from 'lwc';
import GeFormWidgetSoftCreditRow from 'c/geFormWidgetSoftCreditRow';

describe('c-form-widget-soft-credit-row', () => {
    afterEach(() => {
        clearDOM();
    });

    function flushPromises() {
        return new Promise((resolve) => setImmediate(resolve));
    }

    const setup = () => {
        const element = createElement('c-form-widget-soft-credit-row', {
            is: GeFormWidgetSoftCreditRow
        });
        element.disabled = false;
        document.body.appendChild(element);
        return element;
    }

    describe('component render', () => {
        it('renders the modal title', async () => {
            const element = setup();

            await flushPromises();

            const headerElement = element.shadowRoot.querySelector('h1');
            const text = headerElement.innerHTML;
            expect(text).toBe('This is a title');
        });      
    });
});