import stageGift from '@salesforce/apex/GE_GiftEntryController.stageGift';
import apexCreateElevateBatch from '@salesforce/apex/GE_GiftEntryController.createElevateBatch';

class ElevateBatch {

    constructor(elevateBatchId) {
        this.elevateBatchId = elevateBatchId;
        this._hasAddRun = false;
    }

    async add(tokenizedGift) {
        if (!this.elevateBatchId) {
            this.elevateBatchId = await this.create();
        }

        try {
            const authorizedGift = await stageGift(
                {tokenizedGift: tokenizedGift, elevateBatchId: this.elevateBatchId}
            );
            return authorizedGift;
        } catch (ex) {
            if (!this._hasAddRun) {
                this._hasAddRun = true;
                this.elevateBatchId = await this.create();
                return this.add(tokenizedGift);
            } else {
                throw(ex); // Propagate error to calling function for error handling
            }
        }
    }

    async create() {
        const elevateBatch = await apexCreateElevateBatch();
        return elevateBatch.elevateBatchId;
    }

}

export default ElevateBatch;