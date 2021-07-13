public inherited sharing class GiftId {

    private Id dataImportId;

    public GiftId(Id dataImportId) {
        if (!isDataImportId(dataImportId)) {
            throw new GiftIdException('Invalid DataImport__c Id');
        }
        this.dataImportId = dataImportId;
    }

    private Boolean isDataImportId(Id dataImportId) {
        SObjectType providedIdSObjectType = dataImportId.getSObjectType();
        if (providedIdSObjectType == DataImport__c.getSObjectType()) {
            return true;
        }
        return false;
    }

    public Id value() {
        return this.dataImportId;
    }

    public class GiftIdException extends Exception {}
}
