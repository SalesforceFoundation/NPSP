import { createElement } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';

import GeReviewDonations from 'c/geReviewDonations';
import { registerListener, unregisterListener } from 'c/pubsubNoPageRef';

import getOpenDonationsView from '@salesforce/apex/GE_GiftEntryController.getOpenDonationsView';

// Mock Apex wire adapter
jest.mock(
    '@salesforce/apex/GE_GiftEntryController.getOpenDonationsView',
    () => {
        const {
            createApexTestWireAdapter
        } = require('@salesforce/sfdx-lwc-jest');
        return {
            default: createApexTestWireAdapter(jest.fn())
        };
    },
    { virtual: true }
);

//mock the pubSub methods
jest.mock('c/pubsubNoPageRef', () => {
    return {
        registerListener: jest.fn(),
        unregisterListener: jest.fn()
    }
});

const DUMMY_OPEN_DONATIONS = {donations: [
    { opportunity: {}, unpaidPayments: [], softCredits: { all: [] } },
    { opportunity: {}, unpaidPayments: [], softCredits: { all: [] } }
]};

const DUMMY_SELECTED_DONATION = {
    Name: 'DUMMY SELECTED DONATION NAME',
    attributes: {
        type: 'npe01__OppPayment__c'
    }
};

describe('c-ge-review-donations', () => {

    afterEach(() => {
        clearDOM();
        jest.clearAllMocks();
    });

    const createReviewDonationsElement = () => {
        return createElement('c-ge-review-donations',
            { is: GeReviewDonations }
        );
    }

    describe('rendering behavior', () => {

        it('should not render review donations button', async () => {
            const reviewDonationsElement = createReviewDonationsElement();

            document.body.appendChild(reviewDonationsElement);

            await flushPromises();

            const buttonElement = shadowQuerySelector(reviewDonationsElement, 'button');
            expect(buttonElement).toBeNull();
        });

        it('should render review donations button', async () => {
            const reviewDonationsElement = createReviewDonationsElement();
            reviewDonationsElement.donorId = 'DUMMY_DONOR_ID';

            document.body.appendChild(reviewDonationsElement);

            // Emit data from @wire
            getRecord.emit({});
            getOpenDonationsView.emit(DUMMY_OPEN_DONATIONS);

            await flushPromises();

            const buttonElement = shadowQuerySelector(reviewDonationsElement, 'button');
            expect(buttonElement).toBeTruthy();
            expect(buttonElement.innerHTML).toBe('c.geButtonMatchingReviewDonations');
        });

        it('should render change selection button when a donation is selected', async () => {
            const reviewDonationsElement = createReviewDonationsElement();
            reviewDonationsElement.donorId = 'DUMMY_DONOR_ID';

            document.body.appendChild(reviewDonationsElement);

            // Emit data from @wire
            getRecord.emit({});
            getOpenDonationsView.emit(DUMMY_OPEN_DONATIONS);

            reviewDonationsElement.selectedDonation = {};

            await flushPromises();

            const buttonElement = shadowQuerySelector(reviewDonationsElement, 'button');
            expect(buttonElement).toBeTruthy();
            expect(buttonElement.innerHTML).toBe('c.geButtonMatchingUpdateDonationSelection');
        });

        it('should render hyperlink to selected donation', async () => {
            const reviewDonationsElement = createReviewDonationsElement();
            reviewDonationsElement.donorId = 'DUMMY_DONOR_ID';

            document.body.appendChild(reviewDonationsElement);

            // Emit data from @wire
            getRecord.emit({});
            getOpenDonationsView.emit(DUMMY_OPEN_DONATIONS);

            reviewDonationsElement.selectedDonation = DUMMY_SELECTED_DONATION;

            await flushPromises();

            const buttonElement = shadowQuerySelector(reviewDonationsElement, 'button');
            expect(buttonElement).toBeTruthy();
            expect(buttonElement.innerHTML).toBe('DUMMY SELECTED DONATION NAME');
        });

        it('should clear selected donation when reset pubsub event is fired', async () => {
            const reviewDonationsElement = createReviewDonationsElement();
            reviewDonationsElement.donorId = 'DUMMY_DONOR_ID';

            document.body.appendChild(reviewDonationsElement);

            // Emit data from @wire
            getRecord.emit({});
            getOpenDonationsView.emit(DUMMY_OPEN_DONATIONS);

            reviewDonationsElement.selectedDonation = DUMMY_SELECTED_DONATION;

            await flushPromises();

            const buttonElement = shadowQuerySelector(reviewDonationsElement, 'button');
            expect(buttonElement).toBeTruthy();
            expect(buttonElement.innerHTML).toBe('DUMMY SELECTED DONATION NAME');

            await flushPromises();

            let mockResetReviewDonationsComponent = registerListener.mock.calls[0][1];
            mockResetReviewDonationsComponent.call(reviewDonationsElement);

            await flushPromises();

            expect(buttonElement.innerHTML).not.toBe('DUMMY SELECTED DONATION NAME');
        });
    });
});

const getShadowRoot = (element) => {
    if (!element || !element.shadowRoot) {
        const tagName =
            element && element.tagName && element.tagName.toLowerCase();
        throw new Error(
            `Attempting to retrieve the shadow root of '${tagName || element}'
            but no shadowRoot property found`
        );
    }
    return element.shadowRoot;
}

const shadowQuerySelector = (element, selector) => {
    return getShadowRoot(element).querySelector(selector);
}