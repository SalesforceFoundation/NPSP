import { createElement } from 'lwc';
import { registerSa11yMatcher } from '@sa11y/jest'

import GsApplicationStatus from 'c/gsApplicationStatus'
import getApplicationStatus from '@salesforce/apex/GS_ApplicationStatusController.getApplicationStatus'

registerSa11yMatcher();

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

function flushPromises() {
    return new Promise(resolve => setImmediate(resolve));
}


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
        while(document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    /**
     * @description testing 15 days left and no application
     * Asserts:
     *     * button is apply for free licenses
     *     * 15 days trial org remaining
     *     * Img is the one that correponds with the this state
     */
    it('shows apply button and shows 15 days left when application is not applied', () => {
        getApplicationStatus.mockResolvedValue(NOT_APPLIED_EXPIRATION_DATE_15_DAYS);
        const element = createElement('c-gs-application-status', {is: GsApplicationStatus});
        document.body.appendChild(element);
        return flushPromises().
        then(() => {
            const button = element.shadowRoot.querySelector('.slds-button');
            expect(button.innerHTML).toBe('c.gsApplyForFreeLicenses');
            expect(button).toBeAccessible();
            const daysLeft = element.shadowRoot.querySelector(".daysLeft");
            expect(daysLeft.innerHTML).toContain('15');
            const img = element.shadowRoot.querySelector('img').getAttribute('src');
            expect(img).toBe('CumulusStaticResources/gsResources/Accept_Tasks_Apply_Card.png');

        })
        
    });

    /**
     * @description testing 15 days left and application
     * Asserts:
     *     * button is apply for free licenses
     *     * 15 days trial org remaining
     *     * Img is the one that correponds with the this state
     */
    it('shows check status button and shows 15 days left when application is not applied', () => {
        getApplicationStatus.mockResolvedValue(APPLIED_EXPIRATION_DATE_15_DAYS);
        const element = createElement('c-gs-application-status', {is: GsApplicationStatus});
        document.body.appendChild(element);
        return flushPromises().
        then(() => {
            const button = element.shadowRoot.querySelector('.slds-button');
            expect(button.innerHTML).toBe('c.gsCheckStatus');
            expect(button).toBeAccessible();
            const daysLeft = element.shadowRoot.querySelector(".daysLeft");
            expect(daysLeft.innerHTML).toContain('15');
            const img = element.shadowRoot.querySelector('img').getAttribute('src');
            expect(img).toBe('CumulusStaticResources/gsResources/gift_illustration_2.svg');
        })
        
    });
});