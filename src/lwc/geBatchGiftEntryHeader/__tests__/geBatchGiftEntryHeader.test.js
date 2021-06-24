import { createElement } from 'lwc';
import GeBatchGiftEntryHeader from 'c/geBatchGiftEntryHeader';
import { getRecord } from "@salesforce/sfdx-lwc-jest/src/lightning-stubs/uiRecordApi/uiRecordApi";

const mockGetRecord = require('./data/getRecord.json');

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
        getRecord.emit(mockGetRecord);
        return element;
    }

    describe('getRecord @wire data', () => {
        it('renders the data import batch record name as the title', async () => {
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

            element.batchTotals = {
                hasValuesGreaterThanZero: true,
                hasPaymentsWithExpiredAuthorizations: false,
                totalGiftsCount: 20,
                processedGiftsCount: 10,
                failedPaymentsCount: 0,
                failedGiftsCount: 5,
                expiredPaymentsCount: 0
            }

            getRecord.emit(false);

            await flushPromises();
            const headerDetailRows = element.shadowRoot.querySelectorAll('c-util-page-header-detail-row');
            expect(headerDetailRows.length).toBe(1);
        });

        it('does not render detail row', async () => {
            const element = setup();

            element.batchTotals = {
                hasValuesGreaterThanZero: false,
                hasPaymentsWithExpiredAuthorizations: false,
                totalGiftsCount: 0,
                processedGiftsCount: 0,
                failedPaymentsCount: 0,
                failedGiftsCount: 0,
                expiredPaymentsCount: 0
            }

            await flushPromises();
            const headerDetailRows = element.shadowRoot.querySelectorAll('c-util-page-header-detail-row');
            expect(headerDetailRows.length).toBe(0);
        });

        it('renders detail blocks for records processed and records failed with correct record counts on load', async () => {
            const element = setup();

            element.batchTotals = {
                hasValuesGreaterThanZero: true,
                hasPaymentsWithExpiredAuthorizations: false,
                totalGiftsCount: 20,
                processedGiftsCount: 10,
                failedPaymentsCount: 0,
                failedGiftsCount: 5,
                expiredPaymentsCount: 0
            }
            getRecord.emit(true);

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
