import { createElement } from 'lwc';
import GeBatchGiftEntryHeader from 'c/geBatchGiftEntryHeader';
import { getRecord } from 'lightning/uiRecordApi';
import { registerLdsTestWireAdapter, registerApexTestWireAdapter } from '@salesforce/sfdx-lwc-jest';

import getGiftBatchTotalsBy from '@salesforce/apex/GE_GiftEntryController.getGiftBatchTotalsBy';

const mockGetRecord = require('./data/getRecord.json');
const getRecordAdapter = registerLdsTestWireAdapter(getRecord);
const getGiftBatchTotalsByAdapter = registerApexTestWireAdapter(getGiftBatchTotalsBy);

const APEX_BATCH_TOTALS_BY_SUCCESS = {
    'processedGifts': 10,
    'failedGifts': 5,
    'failedPayments': 1,
    'totalGifts': 20
};

describe('c-ge-batch-gift-entry-header', () => {
    afterEach(() => {
        clearDOM();
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
            const element = setup();

            await flushPromises();
            const headerElement = element.shadowRoot.querySelectorAll('c-util-page-header');
            const headerElements = headerElement[0].shadowRoot.querySelectorAll('h1');
            const text = headerElements[0].querySelectorAll('.uiOutputText');
            expect(text[0].innerHTML).toBe(mockGetRecord.fields.Name.value);
        });
    });

    describe('header body details', () => {
        it('renders detail row', async () => {
            const element = setup();

            getGiftBatchTotalsByAdapter.emit(APEX_BATCH_TOTALS_BY_SUCCESS);

            await flushPromises();
            const headerDetailRows = element.shadowRoot.querySelectorAll('c-util-page-header-detail-row');
            expect(headerDetailRows.length).toBe(1);
        });

        it('does not render detail row', async () => {
            const element = setup();

            await flushPromises();
            const headerDetailRows = element.shadowRoot.querySelectorAll('c-util-page-header-detail-row');
            expect(headerDetailRows.length).toBe(0);
        });

        it('renders detail blocks with correct record counts', async () => {
            const element = setup();

            getGiftBatchTotalsByAdapter.emit(APEX_BATCH_TOTALS_BY_SUCCESS);

            await flushPromises();
            const detailBlocks = element.shadowRoot.querySelectorAll('c-util-page-header-detail-block');
            expect(detailBlocks.length).toBe(3);

            const processedGiftsBlock = detailBlocks[0].querySelectorAll('p');
            const processedGifts = processedGiftsBlock[1].innerHTML;
            expect(processedGifts).toBe('10 / 20');

            const failedGiftsBlock = detailBlocks[1].querySelectorAll('p');
            const failedGifts = failedGiftsBlock[1].innerHTML;
            expect(failedGifts).toBe('5');

            const failedPaymentsBlock = detailBlocks[2].querySelectorAll('p');
            const failedPayments = failedPaymentsBlock[1].innerHTML;
            expect(failedPayments).toBe('1');
        });
    });
});