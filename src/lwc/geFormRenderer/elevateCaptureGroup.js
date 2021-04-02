import apexAddToCaptureGroup from '@salesforce/apex/GE_GiftEntryController.addToCaptureGroup';
import apexCreateCaptureGroup from '@salesforce/apex/GE_GiftEntryController.createCaptureGroup';

class ElevateCaptureGroup {

    constructor(elevateBatchId) {
        this.elevateBatchId = elevateBatchId;
        this._hasAddRun = false;
    }

    async add(tokenizedGift) {
        if (!this.elevateBatchId) {
            this.elevateBatchId = await this.create();   
        }

        try {
            let authorizedGift = await apexAddToCaptureGroup(
                {tokenizedGift: tokenizedGift, groupId: this.elevateBatchId}
            );
            return authorizedGift;
        } catch (ex) {
            if (!this._hasAddRun) {
                this._hasAddRun = true;
                this.elevateBatchId = await this.create();
                this.add(tokenizedGift);
            } else {
                throw(ex); // Propagate error to calling function for error handling
            }
        }
    }

    async create() {
        let captureGroup = await apexCreateCaptureGroup();
        return captureGroup.groupId;
    }

}

export default ElevateCaptureGroup;