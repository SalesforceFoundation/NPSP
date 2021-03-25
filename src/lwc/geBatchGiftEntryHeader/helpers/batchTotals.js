import getGiftBatchTotalsBy from '@salesforce/apex/GE_GiftEntryController.getGiftBatchTotalsBy';

const BatchTotals = async (batchId) => {
    const totals = await getGiftBatchTotalsBy({ batchId: batchId });
    const { PROCESSED, FAILED, TOTAL } = totals;

    return ({
        get processedGiftsCount() {
            return PROCESSED;
        },
        get failedGiftsCount() {
            return FAILED;
        },
        get totalGiftsCount() {
            return TOTAL;
        },
        get hasValuesGreaterThanZero() {
            return Number(PROCESSED) > 0 || Number(FAILED) > 0;
        },
    });
}

export default BatchTotals;