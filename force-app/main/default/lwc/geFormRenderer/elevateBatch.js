import apexAddToElevateBatch from '@salesforce/apex/GE_GiftEntryController.addToElevateBatch';
import apexCreateElevateBatch from '@salesforce/apex/GE_GiftEntryController.createElevateBatch';
import apexRemoveFromElevateBatch from '@salesforce/apex/GE_GiftEntryController.removeFromElevateBatch';


class ElevateBatch {
    constructor() {
        this.elevateBatchId = null;
        this._hasAddRun = false;
    }
    
    async add(tokenizedGift) {
        try {
            if (!this.elevateBatchId) {
                this.elevateBatchId = await this.create();
            }
            
            const authorizedGift = await apexAddToElevateBatch(
                {tokenizedGift: tokenizedGift, elevateBatchId: this.elevateBatchId}
            );

            return authorizedGift;
        } catch (exception) {
            if (!this._hasAddRun) {
                this._hasAddRun = true;
                this.elevateBatchId = await this.create();
                return this.add(tokenizedGift);
            } else {
                throw(exception);
            }
        }
    }

    async create() {
        const elevateBatch = await apexCreateElevateBatch();
        return elevateBatch.elevateBatchId;
    }

    async remove(authorizedGift) {
        console.log('in remove');
        await apexRemoveFromElevateBatch({
            authorizedGift: authorizedGift
        });
    }
}

export default ElevateBatch;