public inherited sharing class GiftBatchGroupedTotals {
    private final String NPSP_DATA_IMPORT_BATCH =
        Schema.SObjectType.DataImport__c.fields.NPSP_Data_Import_Batch__c.getName();
    private Map<Id, GiftBatchTotals> giftBatchTotalsByBatchId = new Map<Id, GiftBatchTotals>();

    public GiftBatchGroupedTotals(List<AggregateResultProxy> results) {
        Map<Id, List<AggregateResultProxy>> groupedTotals = new Map<Id, List<AggregateResultProxy>>();
        groupResultProxiesByBatchId(results, groupedTotals);

        for (Id batchId : groupedTotals.keySet()) {
            giftBatchTotalsByBatchId.put(batchid, new GiftBatchTotals(groupedTotals.get(batchId)));
        }
    }

    public Map<String, Integer> totalsFor(Id batchId) {
        return giftBatchTotalsByBatchId.get(batchId).toMap();
    }

    private void groupResultProxiesByBatchId(
        List<AggregateResultProxy> results,
        Map<Id, List<AggregateResultProxy>> groupedTotals) {

        for (AggregateResultProxy resultProxy : results) {
            Id batchId = (Id) resultProxy.getValuesByAlias().get(NPSP_DATA_IMPORT_BATCH);
            List<AggregateResultProxy> collectedResults = groupedTotals.get(batchId);

            if (collectedResults != null) {
                collectedResults.add(resultProxy);
            } else {
                collectedResults = new List<AggregateResultProxy> {resultProxy};
            }

            groupedTotals.put(batchId, collectedResults);
        }
    }

    private class GiftBatchTotals {
        private Integer totalGifts = 0;
        private Integer processedGifts = 0;
        private Integer failedPayments = 0;
        private Integer failedGifts = 0;

        private GiftBatchTotals(List<AggregateResultProxy> results) {
            for (AggregateResultProxy result : results) {
                GiftBatchStatusGroup statusGroup = new GiftBatchStatusGroup(result);
                addToTotalGiftsCountFor(statusGroup);
                countProcessedGiftsFor(statusGroup);
                addToFailedGiftsCountFor(statusGroup);
                addToFailedPaymentGiftsCountFor(statusGroup);
            }
        }
    
        private Map<String, Integer> toMap() {
            return new Map<String, Integer> {
                GiftBatchAggregateGroupName.TOTAL.name() => this.totalGifts,
                GiftBatchAggregateGroupName.PROCESSED.name() => this.processedGifts,
                GiftBatchAggregateGroupName.FAILED.name()=> this.failedGifts,
                GiftBatchAggregateGroupName.FAILED_PAYMENT.name() => this.failedPayments
            };
        }
    
        private void addToTotalGiftsCountFor(GiftBatchStatusGroup statusGroup) {
            totalGifts += statusGroup.recordCount();
        }
    
        private void countProcessedGiftsFor(GiftBatchStatusGroup statusGroup) {
            if (statusGroup.isImported()) {
                processedGifts = statusGroup.recordCount();
            }
        }
    
        private void addToFailedGiftsCountFor(GiftBatchStatusGroup statusGroup) {
            if (statusGroup.isProcessingFailed()) {
                failedGifts += statusGroup.recordCount();
            }
        }
    
        private void addToFailedPaymentGiftsCountFor(GiftBatchStatusGroup statusGroup) {
            if (statusGroup.isPaymentFailed()) {
                failedPayments += statusGroup.recordCount();
            }
        }
    }
}
