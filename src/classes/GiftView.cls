public with sharing class GiftView {

    @AuraEnabled public Map<String, Object> fields;
    @AuraEnabled public SoftCreditsView softCredits;

    public GiftView(GiftDTO giftDTO) {
        this.fields = giftDTO.fields;
        this.softCredits = new SoftCreditsView(giftDTO.softCreditsDTO);
    }
}
