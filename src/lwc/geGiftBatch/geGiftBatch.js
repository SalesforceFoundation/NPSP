import getGiftBatchView from '@salesforce/apex/GE_GiftEntryController.getGiftBatchView';
class GiftBatch {
    _id;
    _name;
    _totals = {};
    _total = 0.00;
    _totalCount = 0;
    _gifts = [];

    async init(dataImportBatchId) {
        this._id = dataImportBatchId;
        const viewModel = await getGiftBatchView({ dataImportBatchId: this._id });
        if (viewModel) {
            this._id = viewModel.giftBatchId;
            this._name = viewModel.name;
            this._total = viewModel.total;
            this._totalCount = viewModel.totalCount;
            this._totals = viewModel.totals;
            // viewModel.gifts.forEach(giftView => {
            //     console.log('Gift View: ', giftView);
            //     this._gifts.push(new Gift(giftView));
            // });
            viewModel.gifts.forEach(gift => {
                this._gifts.push(gift);
            });
        }

        return this.state();
    }

    id() {
        return this._id;
    }

    state() {
        return {
            id: this._id,
            name: this._name,
            total: this._total,
            totalCount: this._totalCount,
            gifts: this._gifts,
            totals: this._totals
        }
    }
}

export default GiftBatch;
