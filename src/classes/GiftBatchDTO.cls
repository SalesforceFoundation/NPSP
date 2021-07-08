public inherited sharing class GiftBatchDTO {

    public Id giftBatchId;

    public GiftBatchDTO(GiftBatch giftBatch) {
       this.giftBatchId = giftBatch.id();
    }
}
