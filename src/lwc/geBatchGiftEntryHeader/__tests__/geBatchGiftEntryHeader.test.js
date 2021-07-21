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

        it('should render process batch and payments button', async () => {
            const batchHeader = setup();
            batchHeader.batchTotals = {
                authorizedPaymentsCount: true
            };

            await flushPromises();

            const buttons = batchHeader.shadowRoot.querySelectorAll('lightning-button');
            const processBatchButton = buttons[1];
            expect(processBatchButton.label).toBe('c.bgeProcessBatchAndPayments');
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

    describe('event handling and dispatching', () => {
        it('should dispatch expected custom event when dry run button is clicked', async () => {
            const batchHeader = setup();
            const dispatchEventSpy = jest.spyOn(batchHeader, 'dispatchEvent');

            const buttons = batchHeader.shadowRoot.querySelectorAll('lightning-button');
            const dryRunButton = buttons[0];
            expect(dryRunButton.getAttribute('data-action')).toBe('DRY_RUN_BATCH');
            dryRunButton.click();

            await flushPromises();

            const dryRunCustomEvent = new CustomEvent('batchdryrun');
            expect(dispatchEventSpy).toHaveBeenCalledWith(dryRunCustomEvent);
            expect(dispatchEventSpy.mock.calls[0][0].type).toBe('batchdryrun');
        });

        it('should dispatch expected custom event when process batch button is clicked', async () => {
            const batchHeader = setup();
            const dispatchEventSpy = jest.spyOn(batchHeader, 'dispatchEvent');

            const buttons = batchHeader.shadowRoot.querySelectorAll('lightning-button');
            const processBatchButton = buttons[1];
            expect(processBatchButton.getAttribute('data-action')).toBe('PROCESS_BATCH');
            processBatchButton.click();

            await flushPromises();

            const processBatchCustomEvent = new CustomEvent('processbatch');
            expect(dispatchEventSpy).toHaveBeenCalledWith(processBatchCustomEvent);
            expect(dispatchEventSpy.mock.calls[0][0].type).toBe('processbatch');
        });

        it('should dispatch expected custom event when edit button is clicked', async () => {
            const batchHeader = setup();
            batchHeader.batchId = 'DUMMY_ID';
            const dispatchEventSpy = jest.spyOn(batchHeader, 'dispatchEvent');

            const buttons = batchHeader.shadowRoot.querySelectorAll('lightning-button');
            const editBatchButton = buttons[2];
            expect(editBatchButton.getAttribute('data-action')).toBe('EDIT_BATCH');
            editBatchButton.click();

            await flushPromises();

            const editBatchCustomEvent = new CustomEvent('edit');
            expect(dispatchEventSpy).toHaveBeenCalledWith(editBatchCustomEvent);
            expect(dispatchEventSpy.mock.calls[0][0].type).toBe('edit');
            expect(dispatchEventSpy.mock.calls[0][0].detail).toBe('DUMMY_ID');
        });
    });
});
