import apexAddToElevateBatch from '@salesforce/apex/GE_GiftEntryController.addToElevateBatch';
import apexCreateElevateBatch from '@salesforce/apex/GE_GiftEntryController.createElevateBatch';

class ElevateBatch {
    async add(tokenizedGift) {
        try {
            this.elevateBatchId = await this.create();
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
}

export default ElevateBatch;