public with sharing class BGE_NewGiftBatch_CTRL {

    public Id batchId {get; set;}

    public BGE_NewGiftBatch_CTRL(ApexPages.StandardSetController controller) {

    }

    public void createBatch() {
        //create base record
        DataImportBatch__c batch = new DataImportBatch__c();
        //todo: suggested name is the date?
        batch.name = 'New Batch';
        //set record type ?
        insert batch;
        batchId = batch.Id;
    }

}