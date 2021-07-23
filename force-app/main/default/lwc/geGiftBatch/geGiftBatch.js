import getGiftBatchView from '@salesforce/apex/GE_GiftEntryController.getGiftBatchView';
import getGiftBatchTotalsBy from '@salesforce/apex/GE_GiftEntryController.getGiftBatchTotalsBy';
import updateGiftBatchWith from '@salesforce/apex/GE_GiftEntryController.updateGiftBatchWith';

import Gift from 'c/geGift';

class GiftBatch {
    _id;
    _name = '';
    _totalDonationsAmount = 0;
    _requireTotalMatch = false;
    _expectedCountOfGifts = 0.0;
    _expectedTotalBatchAmount = 0.00;
    _batchTableColumns = '';
    _currencyIsoCode = '';
    _lastModifiedDate;
    _gifts = [];
    _totals = {
        processedGiftsCount: 0,
        failedGiftsCount: 0,
        failedPaymentsCount: 0,
        expiredPaymentsCount: 0,
        authorizedPaymentsCount: 0,
        totalGiftsCount: 0,
        hasValuesGreaterThanZero: false,
        hasPaymentsWithExpiredAuthorizations: false,
        isProcessingGifts: false
    };

    async init(dataImportBatchId) {
        this._id = dataImportBatchId;
        const viewModel = await getGiftBatchView({ dataImportBatchId: this._id });
        this._setPropertiesFrom(viewModel);
        return this.state();
    }

    _setPropertiesFrom(viewModel) {
        if (viewModel) {
            this._id = viewModel.giftBatchId;
            this._name = viewModel.name;
            this._totalDonationsAmount = viewModel.totalDonationsAmount;
            this._requireTotalMatch = viewModel.requireTotalMatch;
            this._expectedCountOfGifts = viewModel.expectedCountOfGifts
            this._expectedTotalBatchAmount = viewModel.expectedTotalBatchAmount
            this._batchTableColumns = viewModel.batchTableColumns
            this._currencyIsoCode = viewModel.currencyIsoCode
            this._lastModifiedDate = viewModel.lastModifiedDate;
            this._totals = viewModel.totals;
            viewModel.gifts.forEach(giftView => {
                this._gifts.push(new Gift(giftView));
            });
        }
    }

    async refreshTotals() {
        this._totals = await getGiftBatchTotalsBy({ batchId: this._id });
        return this.state();
    }

    async updateWith(giftBatchChanges) {
        const newViewModel = await updateGiftBatchWith({ giftBatchChangesAsJSON: JSON.stringify(giftBatchChanges) });
        this._setPropertiesFrom(newViewModel);
        return this.state();
    }

    id() {
        return this._id;
    }

    processedGiftsCount() {
        return this._totals.PROCESSED;
    }

    failedGiftsCount() {
        return this._totals.FAILED;
    }

    failedPaymentsCount() {
        return this._totals.FAILED_PAYMENT;
    }

    expiredPaymentsCount() {
        return this._totals.EXPIRED_PAYMENT;
    }

    authorizedPaymentsCount() {
        return this._totals.AUTHORIZED_PAYMENT;
    }

    totalGiftsCount() {
        return this._totals.TOTAL;
    }

    hasValuesGreaterThanZero() {
        return Number(this._totals.PROCESSED) > 0 || Number(this._totals.FAILED) > 0;
    }

    hasPaymentsWithExpiredAuthorizations() {
        return Number(this._totals.EXPIRED_PAYMENT) > 0;
    }

    isProcessingGifts() {
        return Number(this._totals.PROCESSING) > 0;
    }

    state() {
        return {
            id: this._id,
            name: this._name,
            totalDonationsAmount: this._totalDonationsAmount,
            gifts: this._gifts,
            requireTotalMatch: this._requireTotalMatch,
            expectedCountOfGifts: this._expectedCountOfGifts,
            expectedTotalBatchAmount: this._expectedTotalBatchAmount,
            batchTableColumns: this._batchTableColumns,
            currencyIsoCode: this._currencyIsoCode,
            lastModifiedDate: this._lastModifiedDate,
            processedGiftsCount: this.processedGiftsCount(),
            failedGiftsCount: this.failedGiftsCount(),
            failedPaymentsCount: this.failedPaymentsCount(),
            expiredPaymentsCount: this.expiredPaymentsCount(),
            authorizedPaymentsCount: this.authorizedPaymentsCount(),
            totalGiftsCount: this.totalGiftsCount(),
            hasValuesGreaterThanZero: this.hasValuesGreaterThanZero(),
            hasPaymentsWithExpiredAuthorizations: this.hasPaymentsWithExpiredAuthorizations(),
            isProcessingGifts: this.isProcessingGifts()
        }
    }
}

export default GiftBatch;
