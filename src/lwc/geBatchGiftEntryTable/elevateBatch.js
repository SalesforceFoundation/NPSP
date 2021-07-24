import apexAddToElevateBatch from '@salesforce/apex/GE_GiftEntryController.addToElevateBatch';
import apexCreateElevateBatch from '@salesforce/apex/GE_GiftEntryController.createElevateBatch';
import apexRemoveFromElevateBatch from '@salesforce/apex/GE_GiftEntryController.removeFromElevateBatch';

class ElevateBatch {
    
    constructor(elevateBatchId) {
        this.elevateBatchId = elevateBatchId;
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
            throw (exception);
        }
    }

    async create() {
        const elevateBatch = await apexCreateElevateBatch();
        return elevateBatch.elevateBatchId;
    }

    async remove(paymentId) {
        const removedGift = await apexRemoveFromElevateBatch(
            { authorizedGift: 
                {elevateBatchId: this.elevateBatchId, paymentId: paymentId}
            }
        );
    }
}

export default ElevateBatch;