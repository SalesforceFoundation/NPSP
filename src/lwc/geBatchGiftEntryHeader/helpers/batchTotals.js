class BatchTotals {
    PROCESSED;
    FAILED;
    FAILED_PAYMENT;
    TOTAL;

    constructor(totals) {
        Object.assign(this, totals);
        Object.freeze(this);
    }

    get processedGiftsCount() {
        return this.PROCESSED;
    }

    get failedGiftsCount() {
        return this.FAILED;
    }

    get failedPaymentsCount() {
        return this.FAILED_PAYMENT;
    }

    get totalGiftsCount() {
        return this.TOTAL;
    }

    get hasValuesGreaterThanZero() {
        return Number(this.PROCESSED) > 0 || Number(this.FAILED) > 0;
    }
}

export default BatchTotals;