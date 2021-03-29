import apexAddToCaptureGroup from '@salesforce/apex/GE_GiftEntryController.addToCaptureGroup';
import apexCreateCaptureGroup from '@salesforce/apex/GE_GiftEntryController.createCaptureGroup';
import AuthorizedGift from './authorizedGift';

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
            let response = await apexAddToCaptureGroup(tokenizedGift, this.elevateBatchId);
            console.log(`Add response = ${response}`);
            return Object.assign(new AuthorizedGift, JSON.parse(response).body); 
        } catch (ex) {
            if (!this._hasAddRun) {
                this._hasAddRun = true;
                this.elevateBatchId = await this.create();
                this.add(tokenizedGift);
            } else {
                throw Error; // Propagate error to calling function for error handling
            }
        }
    }

    async create() {
        let response = JSON.parse(await apexCreateCaptureGroup());
        return response.id;
    }

}

export default ElevateCaptureGroup;