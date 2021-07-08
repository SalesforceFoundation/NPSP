public inherited sharing class GiftBatchView {

    @AuraEnabled public Id giftBatchId;
    @AuraEnabled public Integer totalCount;
    @AuraEnabled public Decimal total;

    public GiftBatchView(GiftBatchDTO giftBatchDTO) {
        this.giftBatchId = giftBatchDTO.giftBatchId;
        this.totalCount = giftBatchDTO.totalCount;
        this.total = giftBatchDTO.total;
    }
}
