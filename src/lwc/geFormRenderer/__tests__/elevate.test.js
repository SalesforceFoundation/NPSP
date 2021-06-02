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

    it('elevate batch with existing id when adding gift then id is unchanged', async () => {
        apexAddToElevateBatch.mockResolvedValue({});

        const elevateBatch = new ElevateBatch('fakeElevateBatchId');

        const tokenizableGift = getDummyGift();

        await elevateBatch.add(tokenizableGift);

        expect(apexAddToElevateBatch).toHaveBeenCalledTimes(1);
        expect(apexCreateElevateBatch).toHaveBeenCalledTimes(0);

        expect(apexAddToElevateBatch).toHaveBeenLastCalledWith({
            elevateBatchId: 'fakeElevateBatchId',
            tokenizedGift: tokenizableGift
        });
    });

    it('elevate batch when add fails then new elevate batch id should be used in subsequent call', async () => {
        apexCreateElevateBatch.mockResolvedValue({
            "elevateBatchId" : "good-fake-elevate-batch-id"
        });
        apexAddToElevateBatch.mockRejectedValueOnce({});

        const DUMMY_RESPONSE = { elevateBatchId: 'DUMMY_GROUP_ID', tokenizedGift: {} };
        apexAddToElevateBatch.mockResolvedValueOnce(DUMMY_RESPONSE);

        const elevateBatch = new ElevateBatch('badFakeElevateBatchId');

        const tokenizableGift = getDummyGift();

        const elevateBatchResponse = await elevateBatch.add(tokenizableGift);

        expect(apexAddToElevateBatch).toHaveBeenCalledTimes(2); // first add fails due to elevate batch being closed
        expect(apexAddToElevateBatch).toHaveBeenNthCalledWith(1, {"elevateBatchId": "badFakeElevateBatchId", "tokenizedGift": tokenizableGift });
        expect(apexCreateElevateBatch).toHaveBeenCalledTimes(1); // a new elevate batch should have been created

        // second call uses known good elevate batch id
        expect(apexAddToElevateBatch).toHaveBeenLastCalledWith({"elevateBatchId": "good-fake-elevate-batch-id", "tokenizedGift": tokenizableGift });

        expect(elevateBatchResponse).toBe(DUMMY_RESPONSE);
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