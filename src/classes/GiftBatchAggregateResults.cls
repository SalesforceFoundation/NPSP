public inherited sharing class GiftBatchAggregateResults {
    private Integer totalGifts = 0;
    private Integer processedGifts = 0;
    private Integer failedPayments = 0;
    private Integer failedGifts = 0;

    public GiftBatchAggregateResults(List<AggregateResultProxy> results) {
        for (AggregateResultProxy result : results) {
            GiftBatchStatusGroup statusGroup = new GiftBatchStatusGroup(result);

            if (statusGroup.isImported()) {
                processedGifts = statusGroup.count();
            }

            if (statusGroup.isProcessingFailed()) {
                failedGifts += statusGroup.count();
            }

            if (statusGroup.isPaymentFailed()) {
                failedPayments += statusGroup.count();
            }

            // totalGifts += (Integer) result.get('recordCount');
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
