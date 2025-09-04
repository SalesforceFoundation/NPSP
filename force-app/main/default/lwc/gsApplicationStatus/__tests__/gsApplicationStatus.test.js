import { createElement } from 'lwc';

import GsApplicationStatus from 'c/gsApplicationStatus'
import getApplicationStatus from '@salesforce/apex/GS_ApplicationStatusController.getApplicationStatus'


/**
 * @description Unit testing for gsApplicationStatus components.
 * It checks that elements that has to be rendered are present according to the information about application status
 */
jest.mock('@salesforce/apex/GS_ApplicationStatusController.getApplicationStatus', () => {
    return {
        default: jest.fn()
    };
}, {virtual: true}
);

// for checking the trial expiration date, 15 days from now are considered.

let dayIn15Days = new Date();
dayIn15Days = dayIn15Days.setDate(dayIn15Days.getDate() + 15);

// Mock data for a trial org that expires in 15 days and has not applied yet
const NOT_APPLIED_EXPIRATION_DATE_15_DAYS = {
    isSandbox: false,
    trialExpirationDate : dayIn15Days,
    applicationDate: null
}
// Mock data for a trial org that expires in 15 days and has applied.
const APPLIED_EXPIRATION_DATE_15_DAYS = {
    isSandbox: false,
    trialExpirationDate : dayIn15Days,
    applicationDate: new Date()
}

describe('c-application-status', () => {
    afterEach(() => {
        clearDOM();
    });

    /**
     * @description testing that component does not render when isActiveInstance is true
     * Asserts:
     *     * No content is rendered in the shadow DOM
     *     * Container div is not present
     */
    it('does not render when isActiveInstance is true', async () => {
        getApplicationStatus.mockResolvedValue(NOT_APPLIED_EXPIRATION_DATE_15_DAYS);
        const element = createElement('c-gs-application-status', {is: GsApplicationStatus});
        document.body.appendChild(element);
        
        await flushPromises();
        // Since isActiveInstance defaults to true, the component should not render
        const container = element.shadowRoot.querySelector('.container');
        expect(container).toBeNull();
        
        // Verify no buttons are rendered
        const button = element.shadowRoot.querySelector('.slds-button');
        expect(button).toBeNull();
        
        // Verify no images are rendered
        const img = element.shadowRoot.querySelector('img');
        expect(img).toBeNull();
        
        // Verify no days left text is rendered
        const daysLeft = element.shadowRoot.querySelector('.daysLeft');
        expect(daysLeft).toBeNull();
    });
});