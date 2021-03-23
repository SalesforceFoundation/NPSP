@isTest
private with sharing class AggregateResultProxy_TEST {

    @isTest
    private static void shouldReturnExpectedValuesFromAlias() {
        DataImportBatch__c batch = new DataImportBatch__c();
        insert batch;

        List<DataImport__c> dataImports = new List<DataImport__c>();
        for (Integer i = 0; i < 5; i++) {
            dataImports.add(createDataImportTemp('Failed', 'DUMMY_STATUS', batch.Id));
        }
        for (Integer i = 0; i < 3; i++) {
            dataImports.add(createDataImportTemp('Imported', 'DUMMY_STATUS', batch.Id));
        }
        insert dataImports;

        test.startTest();
        List<AggregateResultProxy> queryResultProxies = new List<AggregateResultProxy>();
        for (AggregateResult result : [SELECT COUNT(Id)recordCount, Status__c
                                        FROM DataImport__c
                                        WHERE NPSP_Data_Import_Batch__c = :batch.Id
                                        GROUP BY Status__c]) {
            queryResultProxies.add(new AggregateResultProxy().withAggregateResult(result));
        }
        test.stopTest();

        for (AggregateResultProxy resultProxy : queryResultProxies) {
            Map<String, Object> valueByAlias = resultProxy.getValuesByAlias();

            if (valueByAlias.get('Status__c') == 'Imported') {
                System.assertEquals(3, valueByAlias.get('recordCount'),
                    'Expect 3 in aggregate result alias `recordCount` for Data Import records with Imported status');
            }

            if (valueByAlias.get('Status__c') == 'Failed') {
                System.assertEquals(5, valueByAlias.get('recordCount'),
                    'Expect 3 in aggregate result alias `recordCount` for Data Import records with Failed status');
            }
        }
    }

    @isTest
    private static void shouldReturnExplicitlyExpectedValuesFromGivenAlias() {
        AggregateResultProxy resultProxy = new AggregateResultProxy()
            .withAliasAndValue('recordCount', 25)
            .withAliasAndValue('Payment_Status__c', 'DECLINED');
        System.assertEquals('DECLINED', resultProxy.getValuesByAlias().get('Payment_Status__c'));
        System.assertEquals(25, resultProxy.getValuesByAlias().get('recordCount'));
    }

    private static DataImport__c createDataImportTemp(String status, String paymentStatus, Id batchId) {
        DataImport__c dataImport = new DataImport__c(
            Status__c = status,
            Payment_Status__c = paymentStatus,
            NPSP_Data_Import_Batch__c = batchId
        );
        return dataImport;
    }
}

