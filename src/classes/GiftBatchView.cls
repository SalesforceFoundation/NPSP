public inherited sharing class GiftBatchView {

    @AuraEnabled public Money total;

    public GiftBatchView(GiftBatchDTO giftBatchDTO) {
        total = giftBatchDTO.total();
    }
}