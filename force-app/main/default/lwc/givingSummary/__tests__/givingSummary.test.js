import { createElement } from 'lwc';
import GivingSummary from '../givingSummary';
import { getRecord } from 'lightning/uiRecordApi';

const mockGetRecord = require('./data/getRecord.json');

describe('c-giving-summary', () => {
    afterEach(() => {
        clearDOM();
    });

    it('displays three fields on the component', () => {
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
