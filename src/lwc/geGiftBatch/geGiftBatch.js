import getGiftBatchView from '@salesforce/apex/GE_GiftEntryController.getGiftBatchView';
import Gift from 'c/geGift';

class GiftBatch {
    _id;
    _total;
    _totalCount;
    _gifts = [];
    _batchTotals;

    constructor() {}

    async init(dataImportBatchId) {
        this._id = dataImportBatchId;
        const viewModel = await getGiftBatchView({ dataImportBatchId: this._id });
        if (viewModel) {
            this._total = viewModel.total;
            this._totalCount = viewModel.totalCount;
            viewModel.gifts.forEach(giftView => {
                console.log('Gift View: ', giftView);
                this._gifts.push(new Gift(giftView));
            });
        }
    }

    makeSomeDataChange() {
        console.log('making some data change....');
        this._totalCount += 1;
        console.log(this._totalCount);
    }

    totalBatchAmount() {
        return this._total || 0.00;
    }

    totalGiftsCount() {
        return this._totalCount || 0;
    }

    gifts() {
        return this._gifts;
    }

    giftBy(giftId) {
        return this._gifts.find(gift => gift.fields.Id === giftId);
    }

    view() {
        return {
            totalGiftsCount: this.totalGiftsCount(),
            total: this.totalBatchAmount(),
            gifts: this.gifts()
        }
    }

    // methods that make an imperative apex call below

    // processGifts() {}

    // refreshTotals() {}

    // retrieveMoreGifts(offset) {}


    // query methods for private properties below

    // isProcessingGifts() {}

    // giftBy(giftId) {}

    // processedGiftsCount() {}

    // failedGiftsCount() {}

    // failedPaymentsCount() {}

    // expiredPaymentsCount() {}             

    // authorizedPaymentsCount() {}

    // hasPaymentsWithExpiredAuthorizations() {}

}

export default GiftBatch;