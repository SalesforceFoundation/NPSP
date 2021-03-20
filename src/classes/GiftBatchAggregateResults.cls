public inherited sharing class GiftBatchAggregateResults {
    private Integer totalGifts = 0;
    private Integer processedGifts = 0;
    private Integer failedPayments = 0;
    private Integer failedGifts = 0;

    public GiftBatchAggregateResults(List<AggregateResultProxy> results) {
        for (AggregateResultProxy result : results) {
            GiftBatchStatusGroup statusGroup = new GiftBatchStatusGroup(result);
            addToTotalGiftsCountFor(statusGroup);
            countProcessedGiftsFor(statusGroup);
            addToFailedGiftsCountFor(statusGroup);
            addToFailedPaymentGiftsCountFor(statusGroup);
        }
    }

    private void addToTotalGiftsCountFor(GiftBatchStatusGroup statusGroup) {
        totalGifts += statusGroup.count();
    }

    private void countProcessedGiftsFor(GiftBatchStatusGroup statusGroup) {
        if (statusGroup.isImported()) {
            processedGifts = statusGroup.count();
        }
    }

    private void addToFailedGiftsCountFor(GiftBatchStatusGroup statusGroup) {
        if (statusGroup.isProcessingFailed()) {
            failedGifts += statusGroup.count();
        }
    }

    private void addToFailedPaymentGiftsCountFor(GiftBatchStatusGroup statusGroup) {
        if (statusGroup.isPaymentFailed()) {
            failedPayments += statusGroup.count();
        }
    }

    public Map<String, Integer> toMap() {
        return new Map<String, Integer> {
            'totalGifts' => this.totalGifts,
            'processedGifts' => this.processedGifts,
            'failedPayments' => this.failedPayments,
            'failedGifts'=> this.failedGifts
        };
    }
}
