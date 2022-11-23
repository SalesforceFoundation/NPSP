import getGiftBatchViewWithLimitsAndOffsets from '@salesforce/apex/GE_GiftEntryController.getGiftBatchViewWithLimitsAndOffsets';
import getGiftBatchTotalsBy from '@salesforce/apex/GE_GiftEntryController.getGiftBatchTotalsBy';
import updateGiftBatchWith from '@salesforce/apex/GE_GiftEntryController.updateGiftBatchWith';
import deleteGiftFromGiftBatch from '@salesforce/apex/GE_GiftEntryController.deleteGiftFromGiftBatch';
import addGiftTo from '@salesforce/apex/GE_GiftEntryController.addGiftTo';
import hasActiveRunningJob from '@salesforce/apex/GE_GiftEntryController.hasActiveRunningJob';
import isGiftBatchAccessible from '@salesforce/apex/GE_GiftEntryController.isGiftBatchAccessible';

// Methods below still need to be replaced/updated to go through service x domain. These were only moved.
import runBatchDryRun from '@salesforce/apex/BGE_DataImportBatchEntry_CTRL.runBatchDryRun';

import Gift from 'c/geGift';

const DEFAULT_MEMBER_GIFTS_QUERY_LIMIT = 25;

class GiftBatch {
    _accessible = true;
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
    _isProcessing = false;
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
        this._accessible = await isGiftBatchAccessible({ batchId: this._id });

        if (this._accessible) {
            this._isProcessing = await hasActiveRunningJob({ batchId: this._id });
            const viewModel = await getGiftBatchViewWithLimitsAndOffsets({
                dataImportBatchId: this._id,
                giftsLimit: DEFAULT_MEMBER_GIFTS_QUERY_LIMIT,
                giftsOffset: 0
            });
            this._setPropertiesFrom(viewModel);
        }

        return this.state();
    }

    _setPropertiesFrom(viewModel, appendGifts) {
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
            if (!appendGifts) {
                this._gifts = [];
            }
            viewModel.gifts.forEach(giftView => {
                this._gifts.push(new Gift(giftView));
            });
        }
    }

    async refreshTotals() {
        this._totals = await getGiftBatchTotalsBy({ batchId: this._id });
        this._isProcessing = await hasActiveRunningJob({ batchId: this._id });
        return this.state();
    }

    async getMoreGifts(giftsOffset) {
        const newViewModel = await getGiftBatchViewWithLimitsAndOffsets({
            dataImportBatchId: this._id,
            giftsLimit: DEFAULT_MEMBER_GIFTS_QUERY_LIMIT,
            giftsOffset: giftsOffset
        });
        this._setPropertiesFrom(newViewModel, true);
        return this.state();
    }

    async updateWith(giftBatchChanges) {
        const newViewModel = await updateGiftBatchWith({ giftBatchChangesAsJSON: JSON.stringify(giftBatchChanges) });
        this._setPropertiesFrom(newViewModel);
        return this.state();
    }

    async dryRun() {
        await runBatchDryRun({ batchId: this._id, numberOfRowsToReturn: 0 });
        return await this.latestState();
    }

    async addMember(gift) {
        await addGiftTo({ dataImportBatchId: this._id, inboundGift: gift.forSave() });
        return await this.latestState(this._gifts.length + 1);
    }

    async updateMember(gift) {
        await addGiftTo({ dataImportBatchId: this._id, inboundGift: gift.forSave() });
        return await this.latestState(this._gifts.length + 1);
    }

    async remove(gift) {
        await deleteGiftFromGiftBatch({ batchId: this._id, dataImportId: gift.Id });
        return await this.latestState(this._gifts.length - 1);
    }

    async latestState(length) {
        const newViewModel = await getGiftBatchViewWithLimitsAndOffsets({
            dataImportBatchId: this._id,
            giftsLimit: length || DEFAULT_MEMBER_GIFTS_QUERY_LIMIT,
            giftsOffset: 0
        });
        this._setPropertiesFrom(newViewModel);
        return this.state();
    }

    isAccessible() {
        return this._accessible;
    }

    giftsInViewSize() {
        return this._gifts.length;
    }

    mostRecentGift() {
        return this._gifts?.length > 0 && this._gifts[0];
    }

    findGiftBy(giftId) {
        return this._gifts.find(gift => gift.id() === giftId);
    }

    id() {
        return this._id;
    }

    matchesExpectedCountOfGifts() {
        return this._totals.TOTAL === this._expectedCountOfGifts;
    }

    matchesExpectedTotalBatchAmount() {
        return this._totalDonationsAmount === this._expectedTotalBatchAmount;
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
        return Number(this._totals.PROCESSING) > 0 || this._isProcessing;
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
            isProcessingGifts: this.isProcessingGifts(),
            isAccessible: this.isAccessible()
        }
    }
}

export default GiftBatch;
