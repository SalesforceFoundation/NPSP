import apexAddToElevateBatch from '@salesforce/apex/NPSP_Batch.addToElevateBatch';
import NPSP_DATA_IMPORT_BATCH_FIELD from '@salesforce/schema/DataImport__c.NPSP_Data_Import_Batch__c';
import DATA_IMPORT_OBJECT from '@salesforce/schema/DataImport__c';

class GiftBatch {

    constructor(batchId) {
        this.batchId = batchId;
    }

    async add(dataImport) {
        if (!this.elevateBatchId) {
            this.elevateBatchId = await this.create();
        }

        try {
            const authorizedGift = await apexAddToElevateBatch(
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

}

export default GiftBatch;