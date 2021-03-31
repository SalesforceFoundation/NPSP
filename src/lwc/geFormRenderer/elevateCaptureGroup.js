import apexAddToCaptureGroup from '@salesforce/apex/GE_GiftEntryController.addToCaptureGroup';
import apexCreateCaptureGroup from '@salesforce/apex/GE_GiftEntryController.createCaptureGroup';
import ElevateAuthorizedGift from './elevateAuthorizedGift';

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
            let response = JSON.parse(await apexAddToCaptureGroup(tokenizedGift, this.elevateBatchId)).body;
            let authorizedGift = new ElevateAuthorizedGift();
            Object.keys(authorizedGift).forEach(
                key => authorizedGift[key] = response[key]
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
        let response = JSON.parse(await apexCreateCaptureGroup());
        return response.id;
    }

}

export default ElevateCaptureGroup;