import GiftBatch from 'c/geGiftBatch';
import getGiftBatchView from '@salesforce/apex/GE_GiftEntryController.getGiftBatchView';

const giftBatchViewJSON = require('./data/giftBatchView.json');

describe('ge-gift-batch', () => {

    afterEach(() => {
        clearDOM();
        jest.clearAllMocks();
    });

    it('should initialize with expected properties', async () => {
        getGiftBatchView.mockResolvedValue(giftBatchViewJSON);
        const giftBatch = new GiftBatch();
        await giftBatch.init(giftBatchViewJSON.giftBatchId);

        await flushPromises();

        expect(giftBatch.state().id).toBe('DUMMY_GIFT_BATCH_ID');
        expect(giftBatch.state().name).toBe('DUMMY GIFT BATCH NAME');
        expect(giftBatch.state().totalDonationsAmount).toEqual(246.76);
        expect(giftBatch.state().gifts.length).toEqual(3);
        expect(giftBatch.state().processedGiftsCount).toEqual(0);
        expect(giftBatch.state().failedGiftsCount).toEqual(0);
        expect(giftBatch.state().failedPaymentsCount).toEqual(0);
        expect(giftBatch.state().expiredPaymentsCount).toEqual(0);
        expect(giftBatch.state().authorizedPaymentsCount).toEqual(0);
        expect(giftBatch.state().totalGiftsCount).toEqual(3);
        expect(giftBatch.state().hasValuesGreaterThanZero).toEqual(false);
        expect(giftBatch.state().hasPaymentsWithExpiredAuthorizations).toEqual(false);
        expect(giftBatch.state().isProcessingGifts).toEqual(false);
    });
});