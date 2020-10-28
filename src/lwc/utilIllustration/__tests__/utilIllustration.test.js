import { createElement } from 'lwc';
import UtilIllustration from 'c/utilIllustration';

describe('c-util-illustration', () => {

    afterEach(clearDOM);

    it('should load with lake mountain', () => {
        const element = createElement('c-util-illustration', { is: UtilIllustration });

        element.title = 'Test title';
        element.message = 'Test message';
        element.size = 'small';
        element.variant = 'lake-mountain';
        document.body.appendChild(element);

        return Promise.resolve().then(() => {
            const messageDiv = element.shadowRoot.querySelector('div.slds-text-longform');
            expect(messageDiv).toBeDefined();

            const messageHeader = element.shadowRoot.querySelector('h3');
            expect(messageHeader.textContent).toBe('Test title');

            const messageBody = element.shadowRoot.querySelector('p');
            expect(messageBody.textContent).toBe('Test message');
        });
    });

    it('should load with wrapped text', () => {
        const element = createElement('c-util-illustration', { is: UtilIllustration });

        element.title = 'Test title';
        element.message = 'Test message';
        element.size = 'small';
        element.variant = 'lake-mountain';
        element.shouldWrapText = true;
        document.body.appendChild(element);

        return Promise.resolve().then(() => {
            const messageDiv = element.shadowRoot.querySelector('div.slds-text-longform');
            expect(messageDiv).toBeDefined();

            const messageHeader = element.shadowRoot.querySelector('h3');
            expect(messageHeader.textContent).toBe('Test title');

            const messageBody = element.shadowRoot.querySelector('p');
            expect(messageBody).toBeNull();

            const layout = element.shadowRoot.querySelector('lightning-layout');
            expect(layout).toBeDefined();

            const layoutItem = element.shadowRoot.querySelector('lightning-layout-item');
            expect(layoutItem).toBeDefined();
        });
    });

});
