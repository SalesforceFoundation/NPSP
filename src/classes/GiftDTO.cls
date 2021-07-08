public with sharing class GiftDTO {

    public DataImport__c dataImport;

    public GiftDTO(Gift gift) {
        this.dataImport = gift.dataImportRecord();
    }
}
