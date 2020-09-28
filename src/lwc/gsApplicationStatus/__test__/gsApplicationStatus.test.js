import { createElement} from 'lwc';
import GsApplicationStatus from 'c/gsApplicationStatus'
import getApplicationStatus from '@salesforce/apex/GS_ApplicationStatusController.getApplicationStatus'

jest.mock('@salesforce/apex/GS_ApplicationStatusController.getApplicationStatus', () => {
    return {
        default: jest.fn()
    };
}, {virtual: true}
);

function flushPromises() {
    return new Promise(resolve => setImmediate(resolve));
}

let dayIn15Days = new Date();
dayIn15Days = dayIn15Days.setDate(dayIn15Days.getDate() + 15);

const NOT_APPLIED_EXPIRATION_DATE_15_DAYS = {
    isSandbox: false,
    trialExpirationDate : dayIn15Days,
    applicationDate: null
}

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

    it('shows apply button and shows 15 days left when application is not applied', () => {
        getApplicationStatus.mockResolvedValue(NOT_APPLIED_EXPIRATION_DATE_15_DAYS);
        const element = createElement('c-gs-application-status', {is: GsApplicationStatus});
        document.body.appendChild(element);
        return flushPromises().
        then(() => {
            const button = element.shadowRoot.querySelector('.slds-button');
            expect(button.innerHTML).toBe('c.gsApplyForFreeLicenses');
            const daysLeft = element.shadowRoot.querySelector(".daysLeft");
            expect(daysLeft.innerHTML).toContain('15');
        })
        
    });

    it('shows check status button and shows 15 days left when application is not applied', () => {
        getApplicationStatus.mockResolvedValue(APPLIED_EXPIRATION_DATE_15_DAYS);
        const element = createElement('c-gs-application-status', {is: GsApplicationStatus});
        document.body.appendChild(element);
        return flushPromises().
        then(() => {
            const button = element.shadowRoot.querySelector('.slds-button');
            expect(button.innerHTML).toBe('c.gsCheckStatus');
            const daysLeft = element.shadowRoot.querySelector(".daysLeft");
            expect(daysLeft.innerHTML).toContain('15');
        })
        
    });
});