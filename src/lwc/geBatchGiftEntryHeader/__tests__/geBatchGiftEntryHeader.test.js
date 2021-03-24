import { createElement } from 'lwc';
import GeBatchGiftEntryHeader from 'c/geBatchGiftEntryHeader';
import { getRecord } from 'lightning/uiRecordApi';
import { registerLdsTestWireAdapter, registerApexTestWireAdapter } from '@salesforce/sfdx-lwc-jest';

import getGiftBatchTotalsBy from '@salesforce/apex/GE_GiftEntryController.getGiftBatchTotalsBy';

const mockGetRecord = require('./data/getRecord.json');
const getRecordAdapter = registerLdsTestWireAdapter(getRecord);
const getGiftBatchTotalsByAdapter = registerApexTestWireAdapter(getGiftBatchTotalsBy);

const APEX_GIFT_BATCH_TOTALS_BY_SUCCESS = {
    'PROCESSED': 10,
    'FAILED': 5,
    'FAILED_PAYMENT': 1,
    'TOTAL': 20
};

const APEX_GIFT_BATCH_TOTALS_BY_SUCCESS_2 = {
    'PROCESSED': 5,
    'FAILED': 2,
    'FAILED_PAYMENT': 3,
    'TOTAL': 10
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

    describe('gift entry batch header elements', () => {
        it('should render three action buttons', async () => {
            const element = setup();

            await flushPromises();
            const buttons = element.shadowRoot.querySelectorAll('lightning-button');
            expect(buttons.length).toBe(3);
        });

        it('renders detail row', async () => {
            const element = setup();

            getGiftBatchTotalsByAdapter.emit(APEX_GIFT_BATCH_TOTALS_BY_SUCCESS);

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

        it('renders detail blocks with correct record counts on load', async () => {
            const element = setup();

            getGiftBatchTotalsByAdapter.emit(APEX_GIFT_BATCH_TOTALS_BY_SUCCESS);

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

            getGiftBatchTotalsByAdapter.emit(APEX_GIFT_BATCH_TOTALS_BY_SUCCESS_2);

            await flushPromises();
            const detailBlocks2 = element.shadowRoot.querySelectorAll('c-util-page-header-detail-block');
            expect(detailBlocks.length).toBe(3);

            const processedGiftsBlock2 = detailBlocks2[0].querySelectorAll('p');
            const processedGifts2 = processedGiftsBlock2[1].innerHTML;
            expect(processedGifts2).toBe('5 / 10');
        });
    });
});