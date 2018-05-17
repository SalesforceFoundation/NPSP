public with sharing class BGE_HandsOnGridSelector {

    public static final Integer SQL_MINOR_LIMIT = 1;
    public static final Integer SQL_MAJOR_LIMIT = 10000;

    public Map<Id, Batch_Template_Field__c> getTemplateFieldsByTemplateId(Id recordId) {

        Map<Id, Batch_Template_Field__c> result = new Map<Id, Batch_Template_Field__c>([SELECT
                                                                                            Name,
                                                                                            Order__c,
                                                                                            Read_Only__c,
                                                                                            Required__c
                                                                                        FROM Batch_Template_Field__c
                                                                                        WHERE Batch_Template__c =: recordId
                                                                                        ORDER BY Order__c ASC
                                                                                        LIMIT :SQL_MAJOR_LIMIT]);

        return result;
    }

    public SObject[] getDataImportsByBatchId(Id recordId, String[] fieldNames) {

        return getDataImportsByBatchIdWithOffset(recordId, fieldNames, 0);
    }

    public SObject[] getDataImportsByBatchIdWithOffset(Id recordId, String[] fieldNames, Integer offset) {

        String query = 'SELECT ';
        query += String.join(fieldNames, ',');
        query += ' FROM DataImport__c WHERE NPSP_Data_Import_Batch__c = :recordId ORDER BY createdDate ASC LIMIT 50 OFFSET :offset';

        return Database.query(query);
    }

    public DataImportBatch__c getBatchById(Id recordId) {

        DataImportBatch__c[] result = new DataImportBatch__c[] {};

        result = [SELECT Batch_Template__c FROM DataImportBatch__c WHERE Id = :recordId LIMIT :SQL_MINOR_LIMIT];

        return !result.isEmpty() ? result[0] : null;
    }

    public Integer getDataImportBatchCountByBatchId(Id recordId) {

        Integer result = 0;

        try {
            result = [SELECT count() FROM DataImport__c WHERE NPSP_Data_Import_Batch__c = :recordId];
        }
        catch (DmlException ex) {
            result = 0;
        }

        return result;
    }

    public Decimal getDataImportDonationAmountByBatchId(String recordId) {

        Decimal result = 0;

        AggregateResult[] query = [SELECT SUM(Donation_Amount__c)
                                    FROM DataImport__c
                                    WHERE NPSP_Data_Import_Batch__c = :recordId
                                    AND Donation_Amount__c != null];

        if (!query.isEmpty()) {
            result = (Decimal) query[0].get('expr0') != null ? (Decimal) query[0].get('expr0') : 0;
        }

        return result;
    }





}
