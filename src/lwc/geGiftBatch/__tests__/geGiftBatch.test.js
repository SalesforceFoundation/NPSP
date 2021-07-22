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
        expect(giftBatch.state().total).toBe(495.76);
        expect(giftBatch.state().totalCount).toBe(5);
        expect(giftBatch.state().gifts.length).toBe(5);
    });
});