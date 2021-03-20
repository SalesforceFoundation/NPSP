public inherited sharing class GiftBatchAggregateResults {
    private Integer totalGifts = 0;
    private Integer processedGifts = 0;
    private Integer failedPayments = 0;
    private Integer failedGifts = 0;

    public GiftBatchAggregateResults(List<AggregateResult> results) {
        for (AggregateResult result : results) {
            totalGifts += (Integer) result.get('recordCount');

            String status = (String) result.get(Schema.SObjectType.DataImport__c.fields.Status__c.getName());
            if (status == 'Imported') {
                processedGifts = (Integer) result.get('recordCount');
                continue;
            }

            String paymentStatus = (String) result.get(Schema.SObjectType.DataImport__c.fields.Payment_Status__c.getName());
            if (paymentStatus == 'DECLINED') {
                failedPayments += (Integer) result.get('recordCount');
            }
            if (status == 'Failed') {
                failedGifts += (Integer) result.get('recordCount');
            }
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
