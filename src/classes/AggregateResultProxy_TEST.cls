/*
    Copyright (c) 2021 Salesforce.org
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Salesforce.org nor the names of
      its contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
    COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
    LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
    ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
    POSSIBILITY OF SUCH DAMAGE.
*/
/**
* @author Salesforce.org
* @date 2021
* @description Unit tests for AggregateResultProxy.cls
*/
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

