public with sharing class GiftDTO {

    public DataImport__c dataImport;
    public List<OpportunityContactRole> softCredits;

    public GiftDTO(Gift gift) {
        this.dataImport = gift.dataImportRecord();
        this.softCredits = gift.softCredits().all();
    }
}
