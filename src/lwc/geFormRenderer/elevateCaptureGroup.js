import apexAddToCaptureGroup from '@salesforce/apex/GE_GiftEntryController.addToCaptureGroup';
import apexCreateCaptureGroup from '@salesforce/apex/GE_GiftEntryController.createCaptureGroup';
import AuthorizedGift from './authorizedGift';

class ElevateCaptureGroup {

    constructor(elevateBatchId) {
        this.elevateBatchId = elevateBatchId;
        this._runCount = 0;
    }

    async add(tokenizedGift) {
        if (!this.elevateBatchId) {
            this.elevateBatchId = await this.create();   
        }

        try {
            this._runCount = 1;

            let response = await apexAddToCaptureGroup(tokenizedGift, null);
            return Object.assign(new AuthorizedGift, JSON.parse(response).body); 
        } catch (ex) {
            if (!this._runCount) {
                this.elevateBatchId = await this.create();
                this.add(tokenizedGift);
            }
        }

    }

    async create() {
        let response = JSON.parse(await apexCreateCaptureGroup());
        return response.id;
    }

}

export default ElevateCaptureGroup;