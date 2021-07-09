public with sharing class GiftView {

    @AuraEnabled public Map<String, Object> fields;
    @AuraEnabled public List<OpportunityContactRole> softCredits;

    public GiftView(GiftDTO giftDTO) {
        this.fields = giftDTO.fields;
        this.softCredits = giftDTO.softCredits;
    }
}
