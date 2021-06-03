import apexAddToElevateBatch from '@salesforce/apex/GE_GiftEntryController.addToElevateBatch';
import apexCreateElevateBatch from '@salesforce/apex/GE_GiftEntryController.createElevateBatch';

jest.mock('@salesforce/apex/GE_GiftEntryController.addToElevateBatch',
    () => ({ default : jest.fn() }),
    { virtual: true }
);
jest.mock('@salesforce/apex/GE_GiftEntryController.createElevateBatch',
    () => ({ default : jest.fn() }),
    { virtual: true }
);

import ElevateBatch from "../elevateBatch";
import ElevateTokenizeableGift from "../elevateTokenizeableGift";

describe('elevate-elevate-batch', () => {

    afterEach(() => {
        jest.clearAllMocks();
    });

    it('create elevate batch returns id of a new elevate batch', async () => {
        apexCreateElevateBatch.mockResolvedValue({
            "elevateBatchId" : "fake-elevate-batch-id"
        });

        const elevateBatch = new ElevateBatch();
        const elevateBatchId = await elevateBatch.create();

        expect(elevateBatchId).toBe('fake-elevate-batch-id');
    });

    it('new elevate batch without id when adding gift then elevate batch has id', async () => {
        apexCreateElevateBatch.mockResolvedValue({
            "elevateBatchId" : "fake-elevate-batch-id"
        });

        const tokenizableGift = getDummyGift();

        const elevateBatch = new ElevateBatch();
        await elevateBatch.add(tokenizableGift);

        expect(apexAddToElevateBatch).toHaveBeenLastCalledWith({
            "elevateBatchId": "fake-elevate-batch-id",
            tokenizedGift: tokenizableGift
        });

    });

});


const getDummyGift = () => {
    return new ElevateTokenizeableGift(
        'DummyFirstName',
        'DummyLastName',
        5.00,
        'USD'
    );
}