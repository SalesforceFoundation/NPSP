public inherited sharing class GiftBatchDTO {

    public Id giftBatchId;
    public Integer totalCount;
    public Decimal total;
    public List<GiftDTO> giftDTOs;

    public GiftBatchDTO(GiftBatch giftBatch) {
        this.giftBatchId = giftBatch.id();
        this.totalCount = giftBatch.totalCount();
        this.total = giftBatch.total().amount();

        giftDTOs = new List<GiftDTO>();
        for (Gift gift : giftBatch.gifts().all()) {
            giftDTOs.add(new GiftDTO(gift));
        }
    }
}
