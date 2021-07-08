public with sharing class GiftView {

    @AuraEnabled public DataImport__c dataImport;
    @AuraEnabled public List<OpportunityContactRole> softCredits;

    public GiftView(GiftDTO giftDTO) {
        this.dataImport = giftDTO.dataImport;
        this.softCredits = giftDTO.softCredits;
    }
}
