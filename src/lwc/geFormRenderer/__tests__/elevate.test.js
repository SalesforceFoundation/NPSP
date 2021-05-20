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

});


const getDummyGift = () => {
    return new ElevateTokenizeableGift(
        'DummyFirstName',
        'DummyLastName',
        5.00,
        'USD'
    );
}