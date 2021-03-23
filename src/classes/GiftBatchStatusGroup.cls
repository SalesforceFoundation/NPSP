public inherited sharing class GiftBatchStatusGroup {
    final private String status;
    final private String paymentStatus;
    private Integer recordCount;

    public GiftBatchStatusGroup(AggregateResultProxy result) {
        Map<String,Object> resultProxy = result.getValuesByAlias();
        paymentStatus = (String) resultProxy.get(String.valueOf(DataImport__c.fields.Payment_Status__c));
        status = (String) resultProxy.get(String.valueOf(DataImport__c.fields.Status__c));
        recordCount = (Integer) resultProxy.get('recordCount');
    }

    public Integer recordCount() {
        return this.recordCount;
    }

    public Boolean isImported() {
        return status == 'Imported';
    }

    public Boolean isProcessingFailed() {
        return status == 'Failed';
    }

    public Boolean isPaymentFailed() {
        return paymentStatus == 'DECLINED';
    }
}
