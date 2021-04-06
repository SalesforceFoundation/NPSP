import apexAddToCaptureGroup from '@salesforce/apex/GE_GiftEntryController.addToCaptureGroup';
import apexCreateCaptureGroup from '@salesforce/apex/GE_GiftEntryController.createCaptureGroup';

jest.mock('@salesforce/apex/GE_GiftEntryController.addToCaptureGroup',
    () => ({ default : jest.fn() }),
    { virtual: true }
);
jest.mock('@salesforce/apex/GE_GiftEntryController.createCaptureGroup',
    () => ({ default : jest.fn() }),
    { virtual: true }
);

import ElevateCaptureGroup from "../elevateCaptureGroup";
import ElevateTokenizeableGift from "../elevateTokenizeableGift";

describe('elevate-capture-group', () => {

    afterEach(() => {
        jest.clearAllMocks();
    });

    it('create capture group returns id of a new capture group', async () => {
        apexCreateCaptureGroup.mockResolvedValue({
            "groupId" : "fake-capture-group-id"
        });

        const captureGroup = new ElevateCaptureGroup();
        const elevateBatchId = await captureGroup.create();

        expect(elevateBatchId).toBe('fake-capture-group-id');
    });

    it('new capture group without id when adding gift then group has id', async () => {
        apexCreateCaptureGroup.mockResolvedValue({
            "groupId" : "fake-capture-group-id"
        });

        const tokenizableGift = getDummyGift();

        const captureGroup = new ElevateCaptureGroup();
        await captureGroup.add(tokenizableGift);

        expect(apexAddToCaptureGroup).toHaveBeenLastCalledWith({
            "groupId": "fake-capture-group-id",
            tokenizedGift: tokenizableGift
        });

    });

    it('capture group with existing id when adding gift then id is unchanged', async () => {
        apexAddToCaptureGroup.mockResolvedValue({});

        const captureGroup = new ElevateCaptureGroup('fakeCaptureGroupId');

        const tokenizableGift = getDummyGift();

        await captureGroup.add(tokenizableGift);

        expect(apexAddToCaptureGroup).toHaveBeenCalledTimes(1);
        expect(apexCreateCaptureGroup).toHaveBeenCalledTimes(0);

        expect(apexAddToCaptureGroup).toHaveBeenLastCalledWith({
            groupId: 'fakeCaptureGroupId',
            tokenizedGift: tokenizableGift
        });
    });

    it('capture group when add fails then new group id should be used in subsequent call', async () => {
        apexCreateCaptureGroup.mockResolvedValue({
            "groupId" : "good-fake-capture-group-id"
        });
        apexAddToCaptureGroup.mockRejectedValueOnce({});

        const DUMMY_RESPONSE = { groupId: 'DUMMY_GROUP_ID', tokenizedGift: {} };
        apexAddToCaptureGroup.mockResolvedValueOnce(DUMMY_RESPONSE);

        const captureGroup = new ElevateCaptureGroup('badFakeCaptureGroupId');

        const tokenizableGift = getDummyGift();

        const captureGroupResponse = await captureGroup.add(tokenizableGift);

        expect(apexAddToCaptureGroup).toHaveBeenCalledTimes(2); // first add fails due to group being closed
        expect(apexAddToCaptureGroup).toHaveBeenNthCalledWith(1, {"groupId": "badFakeCaptureGroupId", "tokenizedGift": tokenizableGift });
        expect(apexCreateCaptureGroup).toHaveBeenCalledTimes(1); // a new group should have been created

        // second call uses known good group id
        expect(apexAddToCaptureGroup).toHaveBeenLastCalledWith({"groupId": "good-fake-capture-group-id", "tokenizedGift": tokenizableGift });

        expect(captureGroupResponse).toBe(DUMMY_RESPONSE);
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