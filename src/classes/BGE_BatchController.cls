public with sharing class BGE_BatchController {

    private static final Integer SQL_MINOR_LIMIT = 1;
    private static final Integer SQL_FILTERED_BATCHETS_LIMIT = 10;

	public static DataImportBatch__c batchRecord = new DataImportBatch__c();

	public BGE_BatchController() {

	}


    public static void saveBatch (DataImportBatch__c newBatch) {

        batchRecord = newBatch;

        // Insert batch
        if (batchRecord != null) {

            insert batchRecord;
        }   
    }
    

    public static List<DataImportBatch__c> findByName(String searchKey) {

        String trimText = searchKey.trim();
        String name = '%' + trimText + '%';
        List<DataImportBatch__c> result = null;

        // Find all the statuses in the BGE_Status_list__c custom setting.
        Map<String, BGE_Status_list__c> statusesMap = BGE_Status_list__c.getAll();

        // Create a Set of statuses to filter the query.
        Set<String> statusesSet  = statusesMap.keySet();

        // If the user had input text.
        if (!String.isEmpty(trimText)) {

            // Query for a List of Batches filtered by status and the text the user had input.
            result = [SELECT Id, Name, CreatedDate, Batch_Description__c, Batch_Template__c
                        FROM DataImportBatch__c
                        WHERE Name
                        LIKE :name and Status__c
                        IN: statusesSet
                        LIMIT :SQL_FILTERED_BATCHETS_LIMIT];
        }

        return result;
    }

    public void updateBatch (Id batchId, Id templateId, String status) {

        DataImportBatch__c[] batches = [SELECT Id, 
                                                Batch_Template__c,
                                                Status__c
                                            FROM DataImportBatch__c WHERE Id = :batchId 
                                            LIMIT :SQL_MINOR_LIMIT];

        DataImportBatch__c batch = batches[0];

        Batch_Template__c[] templates = [SELECT Id
                                            FROM Batch_Template__c WHERE Id = :templateId
                                            LIMIT :SQL_MINOR_LIMIT];
        Batch_Template__c template = templates[0];

        batch.Batch_Template__c = template.Id;
        batch.Status__c = status;

        update batch;

    }
}