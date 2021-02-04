import { createElement } from 'lwc';
import UtilIllustration from 'c/utilIllustration';

const ILLUSTRATION_TITLE = 'Test title';
const ILLUSTRATION_MESSAGE = 'Test message';
const ILLUSTATION_SIZE_SMALL = 'small';

describe('c-util-illustration', () => {

    afterEach(clearDOM);

    it('should load with lake mountain', () => {
        const element = createElement('c-util-illustration', { is: UtilIllustration });

        element.title = ILLUSTRATION_TITLE;
        element.message = ILLUSTRATION_MESSAGE;
        element.size = ILLUSTATION_SIZE_SMALL;
        element.variant = 'lake-mountain';

        document.body.appendChild(element);

        return Promise.resolve().then(() => {
            const messageDiv = element.shadowRoot.querySelector('div.slds-text-longform');
            expect(messageDiv).toBeDefined();

            const messageHeader = element.shadowRoot.querySelector('h3');
            expect(messageHeader.textContent).toBe(ILLUSTRATION_TITLE);

            const messageBody = element.shadowRoot.querySelector('p');
            expect(messageBody.textContent).toBe(ILLUSTRATION_MESSAGE);
        });
    });

    it('should load with wrapped text', () => {
        const element = createElement('c-util-illustration', { is: UtilIllustration });

        element.title = ILLUSTRATION_TITLE;
        element.message = ILLUSTRATION_MESSAGE;
        element.size = ILLUSTATION_SIZE_SMALL;
        element.variant = 'lake-mountain';
        element.shouldWrapText = true;

        document.body.appendChild(element);

        return Promise.resolve().then(() => {
            const messageDiv = element.shadowRoot.querySelector('div.slds-text-longform');
            expect(messageDiv).toBeDefined();

            const messageHeader = element.shadowRoot.querySelector('h3');
            expect(messageHeader.textContent).toBe(ILLUSTRATION_TITLE);

            const messageBody = element.shadowRoot.querySelector('p');
            expect(messageBody).toBeNull();

            const layout = element.shadowRoot.querySelector('lightning-layout');
            expect(layout).toBeDefined();

            const layoutItem = element.shadowRoot.querySelector('lightning-layout-item');
            expect(layoutItem).toBeDefined();
        });
    });

    it('should set heading 2 when param is passed in', () => {
        const element = createElement('c-util-illustration', {
            is: UtilIllustration
        });

        const headingText = 'Test header 2 when required for accessibility';

        element.heading = headingText;
        element.message = ILLUSTRATION_MESSAGE;
        element.size = ILLUSTATION_SIZE_SMALL;
        element.variant = 'no-access';

        document.body.appendChild(element);

        return Promise.resolve().then(() => {
            const messageDiv = element.shadowRoot.querySelector('div.slds-text-longform');
            expect(messageDiv).toBeDefined();

            const heading = element.shadowRoot.querySelector('h2');
            expect(heading).not.toBeNull();
            expect(heading.textContent).toBe(headingText);

            const heading3 = element.shadowRoot.querySelector('h3');
            expect(heading3).toBeNull();

            const messageBody = element.shadowRoot.querySelector('p');
            expect(messageBody.textContent).toBe(ILLUSTRATION_MESSAGE);
        });
    });

});
