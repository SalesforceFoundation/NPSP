import { createElement } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';

import GeReviewDonations from 'c/geReviewDonations';

import getOpenDonations from '@salesforce/apex/GE_GiftEntryController.getOpenDonations';

// Mock Apex wire adapter
jest.mock(
    '@salesforce/apex/GE_GiftEntryController.getOpenDonations',
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

const DUMMY_OPEN_DONATIONS = [
    { opportunity: {}, unpaidPayments: [] },
    { opportunity: {}, unpaidPayments: [] }
]

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
            getOpenDonations.emit(JSON.stringify(DUMMY_OPEN_DONATIONS));

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
            getOpenDonations.emit(JSON.stringify(DUMMY_OPEN_DONATIONS));

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
            getOpenDonations.emit(JSON.stringify(DUMMY_OPEN_DONATIONS));

            reviewDonationsElement.selectedDonation = {
                Name: 'DUMMY SELECTED DONATION NAME',
                attributes: {
                    type: 'npe01__OppPayment__c'
                }
            };;

            await flushPromises();

            const buttonElement = shadowQuerySelector(reviewDonationsElement, 'button');
            expect(buttonElement).toBeTruthy();
            expect(buttonElement.innerHTML).toBe('DUMMY SELECTED DONATION NAME');
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