import { createElement } from 'lwc';
import GeBatchGiftEntryHeader from 'c/geBatchGiftEntryHeader';
import { getRecord } from 'lightning/uiRecordApi';
import { registerLdsTestWireAdapter } from '@salesforce/sfdx-lwc-jest';

import getGiftBatchTotalsBy from '@salesforce/apex/GE_GiftEntryController.getGiftBatchTotalsBy';

const mockGetRecord = require('./data/getRecord.json');
const getRecordAdapter = registerLdsTestWireAdapter(getRecord);

const APEX_GIFT_BATCH_TOTALS_BY_SUCCESS = {
    'PROCESSED': 10,
    'FAILED': 5,
    'TOTAL': 20
};

const APEX_GIFT_BATCH_TOTALS_WITHOUT_ROWS = {
    'PROCESSED': 0,
    'FAILED': 0,
    'TOTAL': 0
};

jest.mock(
    "@salesforce/apex/GE_GiftEntryController.getGiftBatchTotalsBy",
    () => {
        return {
            default: jest.fn()
        };
    },
    { virtual: true }
);

describe('c-ge-batch-gift-entry-header', () => {
    afterEach(() => {
        clearDOM();
        jest.clearAllMocks();
    });

    function flushPromises() {
        return new Promise((resolve) => setImmediate(resolve));
    }

    const setup = () => {
        const element = createElement('c-ge-batch-gift-entry-header', {
            is: GeBatchGiftEntryHeader
        });
        document.body.appendChild(element);
        getRecordAdapter.emit(mockGetRecord);
        return element;
    }

    describe('getRecord @wire data', () => {
        it('renders user record details', async () => {
            getGiftBatchTotalsBy.mockResolvedValue(APEX_GIFT_BATCH_TOTALS_BY_SUCCESS);
            const element = setup();

            await flushPromises();
            const headerElement = element.shadowRoot.querySelectorAll('c-util-page-header');
            const headerElements = headerElement[0].shadowRoot.querySelectorAll('h1');
            const text = headerElements[0].querySelectorAll('.uiOutputText');
            expect(text[0].innerHTML).toBe(mockGetRecord.fields.Name.value);
        });
    });

    describe('gift entry batch header elements', () => {
        it('should render three action buttons', async () => {
            getGiftBatchTotalsBy.mockResolvedValue(APEX_GIFT_BATCH_TOTALS_BY_SUCCESS);
            const element = setup();

            await flushPromises();
            const buttons = element.shadowRoot.querySelectorAll('lightning-button');
            expect(buttons.length).toBe(3);
        });

        it('renders detail row', async () => {
            getGiftBatchTotalsBy.mockResolvedValue(APEX_GIFT_BATCH_TOTALS_BY_SUCCESS);
            const element = setup();

            await flushPromises();
            const headerDetailRows = element.shadowRoot.querySelectorAll('c-util-page-header-detail-row');
            expect(headerDetailRows.length).toBe(1);
        });

        it('does not render detail row', async () => {
            getGiftBatchTotalsBy.mockResolvedValue(APEX_GIFT_BATCH_TOTALS_WITHOUT_ROWS);
            const element = setup();

            await flushPromises();
            const headerDetailRows = element.shadowRoot.querySelectorAll('c-util-page-header-detail-row');
            expect(headerDetailRows.length).toBe(0);
        });

        it('renders detail blocks for records processed and records failed with correct record counts on load', async () => {
            getGiftBatchTotalsBy.mockResolvedValue(APEX_GIFT_BATCH_TOTALS_BY_SUCCESS);
            let element = setup();

            await flushPromises();

            const detailBlocks = element.shadowRoot.querySelectorAll('c-util-page-header-detail-block');
            expect(detailBlocks.length).toBe(2);

            const processedGifts = detailBlocks[0].querySelectorAll('p')[1].innerHTML;
            expect(processedGifts).toBe('10 / 20');

            const failedGifts = detailBlocks[1].querySelectorAll('p')[1].innerHTML;
            expect(failedGifts).toBe('5');
        });
    });
});