public with sharing class GiftView {

    @AuraEnabled public DataImport__c dataImport;

    public GiftView(GiftDTO giftDTO) {
        this.dataImport = giftDTO.dataImport;
    }
}
