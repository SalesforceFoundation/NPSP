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

import ElevateBatch from "../elevateElevateBatch";
import ElevateTokenizeableGift from "../elevateTokenizeableGift";

describe('elevate-capture-group', () => {

    afterEach(() => {
        jest.clearAllMocks();
    });

    it('create capture group returns id of a new capture group', async () => {
        apexCreateElevateBatch.mockResolvedValue({
            "groupId" : "fake-capture-group-id"
        });

        const elevateBatch = new ElevateBatch();
        const elevateBatchId = await elevateBatch.create();

        expect(elevateBatchId).toBe('fake-capture-group-id');
    });

    it('new capture group without id when adding gift then group has id', async () => {
        apexCreateElevateBatch.mockResolvedValue({
            "groupId" : "fake-capture-group-id"
        });

        const tokenizableGift = getDummyGift();

        const elevateBatch = new ElevateBatch();
        await elevateBatch.add(tokenizableGift);

        expect(apexAddToElevateBatch).toHaveBeenLastCalledWith({
            "groupId": "fake-capture-group-id",
            tokenizedGift: tokenizableGift
        });

    });

    it('capture group with existing id when adding gift then id is unchanged', async () => {
        apexAddToElevateBatch.mockResolvedValue({});

        const elevateBatch = new ElevateBatch('fakeElevateBatchId');

        const tokenizableGift = getDummyGift();

        await elevateBatch.add(tokenizableGift);

        expect(apexAddToElevateBatch).toHaveBeenCalledTimes(1);
        expect(apexCreateElevateBatch).toHaveBeenCalledTimes(0);

        expect(apexAddToElevateBatch).toHaveBeenLastCalledWith({
            groupId: 'fakeElevateBatchId',
            tokenizedGift: tokenizableGift
        });
    });

    it('capture group when add fails then new group id should be used in subsequent call', async () => {
        apexCreateElevateBatch.mockResolvedValue({
            "groupId" : "good-fake-capture-group-id"
        });
        apexAddToElevateBatch.mockRejectedValueOnce({});

        const DUMMY_RESPONSE = { groupId: 'DUMMY_GROUP_ID', tokenizedGift: {} };
        apexAddToElevateBatch.mockResolvedValueOnce(DUMMY_RESPONSE);

        const elevateBatch = new ElevateBatch('badFakeElevateBatchId');

        const tokenizableGift = getDummyGift();

        const elevateBatchResponse = await elevateBatch.add(tokenizableGift);

        expect(apexAddToElevateBatch).toHaveBeenCalledTimes(2); // first add fails due to group being closed
        expect(apexAddToElevateBatch).toHaveBeenNthCalledWith(1, {"groupId": "badFakeElevateBatchId", "tokenizedGift": tokenizableGift });
        expect(apexCreateElevateBatch).toHaveBeenCalledTimes(1); // a new group should have been created

        // second call uses known good group id
        expect(apexAddToElevateBatch).toHaveBeenLastCalledWith({"groupId": "good-fake-capture-group-id", "tokenizedGift": tokenizableGift });

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