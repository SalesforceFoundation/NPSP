public inherited sharing class GiftBatchView {

    @AuraEnabled public Id giftBatchId;
    @AuraEnabled public Integer totalCount;
    @AuraEnabled public Decimal total;
    @AuraEnabled public List<GiftView> gifts;

    public GiftBatchView(GiftBatchDTO giftBatchDTO) {
        this.giftBatchId = giftBatchDTO.giftBatchId;
        this.totalCount = giftBatchDTO.totalCount;
        this.total = giftBatchDTO.total;

        gifts = new List<GiftView>();
        for (GiftDTO giftDTO : giftBatchDTO.giftDTOs) {
            gifts.add(new GiftView(giftDTO));
        }
    }
}
