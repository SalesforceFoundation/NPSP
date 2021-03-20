public inherited sharing class GiftBatchStatusGroup {
    final private String status;
    final private String paymentStatus;
    private Integer count;

    public GiftBatchStatusGroup(AggregateResultProxy result) {
        Map<String,Object> resultProxy = result.getValuesByAlias();
        paymentStatus = (String) resultProxy.get(Schema.SObjectType.DataImport__c.fields.Payment_Status__c.getName());
        status = (String) resultProxy.get(Schema.SObjectType.DataImport__c.fields.Status__c.getName());
        count = (Integer) resultProxy.get('recordCount');
    }

    public Integer count() {
        return this.count;
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
