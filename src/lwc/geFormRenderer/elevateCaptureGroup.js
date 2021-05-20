import apexAddToCaptureGroup from '@salesforce/apex/GE_GiftEntryController.addToCaptureGroup';
import apexCreateCaptureGroup from '@salesforce/apex/GE_GiftEntryController.createCaptureGroup';

class ElevateCaptureGroup {

    constructor(elevateBatchId) {
        this.elevateBatchId = elevateBatchId;
    }

    async add(tokenizedGift) {
        try {
            if (!this.elevateBatchId) {
                this.elevateBatchId = await this.create();
            }

            const authorizedGift = await apexAddToCaptureGroup(
                { tokenizedGift: tokenizedGift, groupId: this.elevateBatchId }
            );

            return authorizedGift;
        } catch (exception) {
            throw (exception);
        }
    }

    async create() {
        const captureGroup = await apexCreateCaptureGroup();
        return captureGroup.groupId;
    }
}

export default ElevateCaptureGroup;