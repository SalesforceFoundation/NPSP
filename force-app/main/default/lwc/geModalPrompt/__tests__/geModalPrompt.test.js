import { createElement } from 'lwc';
import GeModalPrompt from 'c/geModalPrompt';

describe('c-ge-modal-prompt', () => {
    afterEach(() => {
        clearDOM();
    });

    function flushPromises() {
        return new Promise((resolve) => setImmediate(resolve));
    }

    const setup = (variant='warning') => {
        const element = createElement('c-ge-modal-prompt', {
            is: GeModalPrompt
        });
        element.variant = variant;
        element.title = 'This is a title';
        element.message = 'This is a message';
        element.buttonText = 'This is a button';
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

        it('renders the modal message', async () => {
            const element = setup();

            await flushPromises();

            const bodyElement = element.shadowRoot.querySelector('h2');
            const text = bodyElement.innerHTML;
            expect(text).toBe('This is a message');
        });

        it('renders the computed warning variant class', async () => {
            const element = setup('warning');

            await flushPromises();

            const headerElements = element.shadowRoot.querySelectorAll('.slds-theme_warning');

            expect(headerElements.length).toBe(1);
        });

        it('renders the computed default variant class with unsupported variant option', async () => {
            const element = setup('nonsense');

            await flushPromises();

            const headerElements = element.shadowRoot.querySelectorAll('.slds-theme_default');

            expect(headerElements.length).toBe(1);
        });            
    });
});