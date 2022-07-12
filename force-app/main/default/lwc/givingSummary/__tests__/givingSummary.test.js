import { createElement } from 'lwc';
import GivingSummary from '../givingSummary';
import { getRecord } from 'lightning/uiRecordApi';
import { extended, full } from "@sa11y/preset-rules";
import { setup } from "@sa11y/jest";

setup();

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
            const value = element.shadowRoot.querySelector('p').innerHTML;
            expect(value).toBe('USD 7000');
        });
    });

    it("checks element is accessible", async () => {
        const element = createElement("c-giving-summary", {
            is: GivingSummary,
        });
        document.body.appendChild(element);
        await expect(element).toBeAccessible(extended);
    });

    it("checks document is fully accessible", async () => {
        const element = createElement("c-giving-summary", {
            is: GivingSummary,
        });
        document.body.appendChild(element);
        await expect(element).toBeAccessible(full);
    });

});