public inherited sharing class GiftBatchDTO {

    public Id giftBatchId;
    public Integer totalCount;
    public Decimal total;

    public GiftBatchDTO(GiftBatch giftBatch) {
        this.giftBatchId = giftBatch.id();
        this.totalCount = giftBatch.totalCount();
        this.total = giftBatch.total().amount();
    }
}
