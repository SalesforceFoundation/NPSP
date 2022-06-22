import { createElement } from 'lwc';
import GeFormWidgetSoftCredit from 'c/geFormWidgetSoftCredit';

const DUMMY_SOFT_CREDITS = JSON.stringify([
    { Role: 'Influencer', ContactId: '1', key: '1' },
    { Role: 'Honoree', ContactId: '2', key: '2' },
    { Role: 'Solicitor', ContactId: '3', key: '3' }
]);
const DUMMY_PROCESSED_SOFT_CREDITS = JSON.stringify([
    { Role: 'Donor', ContactId: '4', Id: '1' },
    { Role: 'Household Member', ContactId: '5', Id: '2' },
]);

describe('c-form-widget-soft-credit', () => {

    afterEach(() => {
        clearDOM();
    });

    const createSoftCreditWidget = () => {
        const element = createElement('c-form-widget-soft-credit', {
            is: GeFormWidgetSoftCredit
        });
        return element;
    }

    describe('render behavior', () => {
        it('renders the title', async () => {
            const element = createSoftCreditWidget();
            element.giftInView = {
                fields: {},
                softCredits: `[]`,
                processedSoftCredits: `[]`
            };
            document.body.appendChild(element);

            await flushPromises();

            const headerElement = element.shadowRoot.querySelector('h2');
            const text = headerElement.innerHTML;
            expect(text).toBe('c.commonSoftCredits');
        });

        it('renders 3 soft credit rows', async () => {
            const element = createSoftCreditWidget();
            element.giftInView = {
                fields: {},
                softCredits: DUMMY_SOFT_CREDITS,
                processedSoftCredits: `[]`
            };
            document.body.appendChild(element);

            await flushPromises();

            const rowElements = shadowSelectorAll(element, 'c-ge-form-widget-soft-credit-row');
            expect(rowElements.length).toBe(3);
        });

        it('renders 2 processed soft credit rows', async () => {
            const element = createSoftCreditWidget();
            element.giftInView = {
                fields: {},
                softCredits: `[]`,
                processedSoftCredits: DUMMY_PROCESSED_SOFT_CREDITS
            };
            document.body.appendChild(element);

            await flushPromises();

            const rowElements = shadowSelectorAll(element, 'c-ge-form-widget-soft-credit-row');
            expect(rowElements.length).toBe(2);
        });

        it('renders the add button', async () => {
            let element = createSoftCreditWidget();
            element.giftInView = {
                fields: {},
                softCredits: `[]`,
                processedSoftCredits: DUMMY_PROCESSED_SOFT_CREDITS
            };
            document.body.appendChild(element);

            await flushPromises();

            const buttonElement = shadowSelectorAll(element, 'lightning-button');
            expect(buttonElement.length).toBe(1);
        });

        it('does not render the add button', async () => {
            let element = createSoftCreditWidget();
            element.giftInView = {
                fields: {},
                softCredits: createDummySoftCredits(250),
                processedSoftCredits: DUMMY_PROCESSED_SOFT_CREDITS
            };
            document.body.appendChild(element);

            await flushPromises();

            const buttonElement = shadowSelectorAll(element, 'lightning-button');
            expect(buttonElement.length).toBe(0);
        });

        it('renders a warning message when the gift in view has a schedule', async () => {
            let element = createSoftCreditWidget();
            element.giftInView = {
                fields: {},
                softCredits: createDummySoftCredits(250),
                processedSoftCredits: DUMMY_PROCESSED_SOFT_CREDITS,
                schedule: {
                    recurringType: 'Open'
                }
            };
            document.body.appendChild(element);

            await flushPromises();

            const warning = element.shadowRoot.querySelector('c-util-inline-text');
            expect(warning).toBeTruthy();
        });

        it('does not render a warning message when the gift is standard', async () => {
            let element = createSoftCreditWidget();
            element.giftInView = {
                fields: {},
                softCredits: createDummySoftCredits(250),
                processedSoftCredits: DUMMY_PROCESSED_SOFT_CREDITS
            };
            document.body.appendChild(element);

            await flushPromises();

            const warning = element.shadowRoot.querySelector('c-util-inline-text');
            expect(warning).toBeFalsy();
        });
    });

    const shadowSelectorAll = (element, selector) => {
        return element.shadowRoot.querySelectorAll(selector);
    }

    const createDummySoftCredits = (softCreditsCount) => {
        let dummySoftCredits = [];
        for (let i = 0; i < softCreditsCount; i++) {
            dummySoftCredits.push({key: i});
        }
        return JSON.stringify(dummySoftCredits);
    }
});