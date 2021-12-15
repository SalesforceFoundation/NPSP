import { createElement } from 'lwc';
import GivingSummary from '../givingSummary';
import { getRecord } from 'lightning/uiRecordApi';
//import getDonationsSummary from '@salesforce/apex/GivingSummaryController.getDonationsSummaryForContact'

/*const THE_RETURNED_CONTACT = {
    npo02__TotalOppAmount__c : "7000",
    npo02__OppAmountThisYear__c : "6000",
    npo02__OppAmountLastYear__c : "1000"
}*/

/*jest.mock('@salesforce/apex/GivingSummaryController.getDonationsSummaryForContact', () => {
    return {
        default: jest.fn()
    };
}, {virtual: true}
);*/

const mockGetRecord = require('./data/getRecord.json');

describe('c-giving-summary', () => {
    afterEach(() => {
        clearDOM();
    });

    it('displays three fields on the component', () => {
        //getDonationsSummary.mockResolvedValue(THE_RETURNED_CONTACT);

        const element = createElement('c-giving-summary', { is: GivingSummary });
        element.contactId = mockGetRecord.id;
        getRecord.emit(mockGetRecord);
        document.body.appendChild(element);
        return flushPromises().then(() => {
            expect(
                element.shadowRoot.querySelector('lightning-card')
            ).toBeDefined();
            expect(element.shadowRoot.querySelector('.lifetime')).toBeDefined();
            const value = element.shadowRoot.querySelector('lightning-formatted-number').value;
            expect(value).toBe('7000');

        });
    });
});
