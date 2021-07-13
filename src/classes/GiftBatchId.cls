public inherited sharing class GiftBatchId {

    private Id dataImportBatchId;

    public GiftBatchId(Id dataImportBatchId) {
        if (!isDataImportBatchId(dataImportBatchId)) {
            throw new GiftBatchIdException('Invalid DataImportBatch__c Id');
        }
        this.dataImportBatchId = dataImportBatchId;
    }

    private Boolean isDataImportBatchId(Id dataImportBatchId) {
        SObjectType providedIdSObjectType = dataImportBatchId.getSObjectType();
        if (providedIdSObjectType == DataImportBatch__c.getSObjectType()) {
            return true;
        }
        return false;
    }

    public Id value() {
        return this.dataImportBatchId;
    }

    public class GiftBatchIdException extends Exception {}
}
