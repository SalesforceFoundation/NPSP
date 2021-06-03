import { createElement } from 'lwc';
import GeGiftEntryFormApp from 'c/geGiftEntryFormApp';
import { getRecord } from "@salesforce/sfdx-lwc-jest/src/lightning-stubs/uiRecordApi/uiRecordApi";
import getGiftBatchTotalsBy from '@salesforce/apex/GE_GiftEntryController.getGiftBatchTotalsBy';
import DATA_IMPORT_BATCH_OBJECT from '@salesforce/schema/DataImportBatch__c';
const mockGetRecord = require('./data/getRecord.json');
const PROCESSING_BATCH_MESSAGE = 'c.geProcessingBatch';
const batchTotalsProcessingGifts = require('./data/batchTotalsProcessingGifts.json');

const createGeGiftEntryFormApp = () => {
    return createElement('c-ge-gift-entry-form-app',
        {is: GeGiftEntryFormApp}
    );
}

jest.mock(
    '@salesforce/apex/GE_GiftEntryController.getGiftBatchTotalsBy',
    () => {
        return {
            default: jest.fn(),
        };
    },
    { virtual: true }
);

describe('c-ge-gift-entry-form-app', () => {

    afterEach(  () => {
       clearDOM();
       jest.clearAllMocks();
    });

    it('should render processing batch spinner if batch is still processing', async  () => {
        getGiftBatchTotalsBy.mockResolvedValue(batchTotalsProcessingGifts);
        const formApp = createGeGiftEntryFormApp();
        formApp.sObjectName = DATA_IMPORT_BATCH_OBJECT.objectApiName;

        document.body.appendChild(formApp);
        getRecord.emit(mockGetRecord);

        expect(spinner(formApp)).toBeTruthy();

        await flushPromises();

        expect(spinner(formApp)).toBeTruthy();
        expect(batchProcessingText(formApp).innerHTML).toBe(PROCESSING_BATCH_MESSAGE);
    });
});

const spinner = (element) => {
    return shadowQuerySelector(element, 'lightning-spinner');
}

const batchProcessingText = (element) => {
    return shadowQuerySelector(element, '.loading-text');
}

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