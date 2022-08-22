import { createElement } from 'lwc';
import GeBatchGiftEntryHeader from 'c/geBatchGiftEntryHeader';

describe('c-ge-batch-gift-entry-header', () => {
    afterEach(() => {
        clearDOM();
        jest.clearAllMocks();
    });

    const setupComponentWithDummy = (giftBatchState) => {
        const element = createElement('c-ge-batch-gift-entry-header', {
            is: GeBatchGiftEntryHeader
        });
        element.giftBatchState = giftBatchState;
        document.body.appendChild(element);
        return element;
    }

    describe('gift entry batch header elements', () => {
        it('should render three action buttons', async () => {
            const element = setupComponentWithDummy({});

            await flushPromises();
            const buttons = element.shadowRoot.querySelectorAll('lightning-button');
            expect(buttons.length).toBe(3);
        });

        it('should disable action buttons', async () => {
            const element = setupComponentWithDummy({});
            element.isGiftBatchProcessing = true;

            await flushPromises();
            const buttons = element.shadowRoot.querySelectorAll('lightning-button');
            expect(buttons.length).toBe(3);
            expect(buttons[0].disabled).toBe(true);
            expect(buttons[1].disabled).toBe(true);
            expect(buttons[2].disabled).toBe(true);
        });

        it('should render process batch and payments button', async () => {
            const batchHeader = setupComponentWithDummy({
                authorizedPaymentsCount: 1
            });

            await flushPromises();

            const buttons = batchHeader.shadowRoot.querySelectorAll('lightning-button');
            const processBatchButton = buttons[1];
            expect(processBatchButton.label).toBe('c.bgeProcessBatchAndPayments');
        });

        it('renders detail row', async () => {
            const element = setupComponentWithDummy({
                hasValuesGreaterThanZero: true,
                hasPaymentsWithExpiredAuthorizations: false,
                totalGiftsCount: 20,
                processedGiftsCount: 10,
                failedPaymentsCount: 0,
                failedGiftsCount: 5,
                expiredPaymentsCount: 0
            });

            await flushPromises();
            const headerDetailRows = element.shadowRoot.querySelectorAll('c-util-page-header-detail-row');
            expect(headerDetailRows.length).toBe(1);
        });

        it('does not render detail row', async () => {
            const element = setupComponentWithDummy({
                hasValuesGreaterThanZero: false,
                hasPaymentsWithExpiredAuthorizations: false,
                totalGiftsCount: 0,
                processedGiftsCount: 0,
                failedPaymentsCount: 0,
                failedGiftsCount: 0,
                expiredPaymentsCount: 0
            });

            await flushPromises();
            const headerDetailRows = element.shadowRoot.querySelectorAll('c-util-page-header-detail-row');
            expect(headerDetailRows.length).toBe(0);
        });

        it('renders detail blocks for records processed and records failed with correct record counts on load', async () => {
            const element = setupComponentWithDummy({
                hasValuesGreaterThanZero: true,
                hasPaymentsWithExpiredAuthorizations: false,
                totalGiftsCount: 20,
                processedGiftsCount: 10,
                failedPaymentsCount: 0,
                failedGiftsCount: 5,
                expiredPaymentsCount: 0
            });

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
            const batchHeader = setupComponentWithDummy({});
            const handler = jest.fn();
            batchHeader.addEventListener('batchdryrun', handler);

            const buttons = batchHeader.shadowRoot.querySelectorAll('lightning-button');
            const dryRunButton = buttons[0];
            expect(dryRunButton.getAttribute('data-action')).toBe('DRY_RUN_BATCH');
            dryRunButton.click();

            await flushPromises();

            expect(handler).toHaveBeenCalled();
            expect(handler.mock.calls[0][0].type).toBe('batchdryrun');
        });

        it('should dispatch expected custom event and disable header buttons when process batch button is clicked', async () => {
            const batchHeader = setupComponentWithDummy({});
            const handler = jest.fn();
            batchHeader.addEventListener('processbatch', handler);

            const buttons = batchHeader.shadowRoot.querySelectorAll('lightning-button');
            const processBatchButton = buttons[1];
            expect(processBatchButton.getAttribute('data-action')).toBe('PROCESS_BATCH');
            processBatchButton.click();

            await flushPromises();

            expect(handler).toHaveBeenCalled();
            expect(handler.mock.calls[0][0].type).toBe('processbatch');

            expect(buttons[0].disabled).toBe(true);
            expect(buttons[1].disabled).toBe(true);
            expect(buttons[2].disabled).toBe(true);
        });

        it('should dispatch expected custom event when edit button is clicked', async () => {
            const batchHeader = setupComponentWithDummy({ id: 'DUMMY_ID' });
            batchHeader.batchId = 'DUMMY_ID';
            const handler = jest.fn();
            batchHeader.addEventListener('edit', handler);

            const buttons = batchHeader.shadowRoot.querySelectorAll('lightning-button');
            const editBatchButton = buttons[2];
            expect(editBatchButton.getAttribute('data-action')).toBe('EDIT_BATCH');
            editBatchButton.click();

            await flushPromises();

            expect(handler).toHaveBeenCalled();
            expect(handler.mock.calls[0][0].type).toBe('edit');
            expect(handler.mock.calls[0][0].detail).toBe('DUMMY_ID');
        });
    });
});
