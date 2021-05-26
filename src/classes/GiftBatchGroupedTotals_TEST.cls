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
* @group Gift Entry
* @group-content ../../ApexDocContent/GiftEntry.htm
* @description Unit tests for GiftBatchGroupedTotals.cls
*/
@isTest
private with sharing class GiftBatchGroupedTotals_TEST {

    @isTest
    private static void shouldReturnMapContainingCorrectRecordCounts() {
        Id DUMMY_BATCH_ID_0 = Id.valueOf('001xa000003DIlo');
        String elevatePaymentAuthorizedStatus = ElevateTransactionStatus.AUTHORIZED.name();
        String elevatePaymentDeclinedStatus = ElevateTransactionStatus.DECLINED.name();
        String elevatePaymentExpiredStatus = ElevateTransactionStatus.EXPIRED.name();

        String dataImportBatchFieldAPIName = String.valueOf(DataImport__c.fields.NPSP_Data_Import_Batch__c);
        String dataImportPaymentStatusFieldAPIName = String.valueOf(DataImport__c.fields.Payment_Status__c);
        String dataImportStatusFieldName = String.valueOf(DataImport__c.fields.Status__c);

        List<AggregateResultProxy> proxiesForBatch0 = new List<AggregateResultProxy> {
            new AggregateResultProxy()
                .withAliasAndValue(dataImportBatchFieldAPIName, DUMMY_BATCH_ID_0)
                .withAliasAndValue(dataImportStatusFieldName, BDI_DataImport_API.bdiImported)
                .withAliasAndValue('recordCount', 1),
            new AggregateResultProxy()
                .withAliasAndValue(dataImportBatchFieldAPIName, DUMMY_BATCH_ID_0)
                .withAliasAndValue(dataImportStatusFieldName, BDI_DataImport_API.bdiFailed)
                .withAliasAndValue('recordCount', 2),
            new AggregateResultProxy()
                .withAliasAndValue(dataImportBatchFieldAPIName, DUMMY_BATCH_ID_0)
                .withAliasAndValue(dataImportPaymentStatusFieldAPIName, elevatePaymentAuthorizedStatus)
                .withAliasAndValue('recordCount', 3),
            new AggregateResultProxy()
                .withAliasAndValue(dataImportBatchFieldAPIName, DUMMY_BATCH_ID_0)
                .withAliasAndValue(dataImportPaymentStatusFieldAPIName, elevatePaymentExpiredStatus)
                .withAliasAndValue('recordCount', 4)                
        };

        Id DUMMY_BATCH_ID_1 = Id.valueOf('002zb000004EJmp');
        List<AggregateResultProxy> proxiesForBatch1 = new List<AggregateResultProxy> {
            new AggregateResultProxy()
                .withAliasAndValue(dataImportBatchFieldAPIName, DUMMY_BATCH_ID_1)
                .withAliasAndValue(dataImportPaymentStatusFieldAPIName, elevatePaymentDeclinedStatus)
                .withAliasAndValue('recordCount', 5),
            new AggregateResultProxy()
                .withAliasAndValue(dataImportBatchFieldAPIName, DUMMY_BATCH_ID_1)
                .withAliasAndValue(dataImportStatusFieldName, BDI_DataImport_API.bdiFailed)
                .withAliasAndValue(dataImportPaymentStatusFieldAPIName, elevatePaymentDeclinedStatus)
                .withAliasAndValue('recordCount', 6)
        };

        List<AggregateResultProxy> allProxies = new List<AggregateResultProxy>();
        allProxies.addAll(proxiesForBatch0);
        allProxies.addAll(proxiesForBatch1);
        GiftBatchGroupedTotals batchTotals = new GiftBatchGroupedTotals(allProxies);

        Map<String, Integer> totalsForBatch0 = batchTotals.totalsFor(DUMMY_BATCH_ID_0);
        System.assertEquals(1, totalsForBatch0.get(GiftBatchAggregateGroupName.PROCESSED.name()));
        System.assertEquals(2 + 4, totalsForBatch0.get(GiftBatchAggregateGroupName.FAILED.name()));
        System.assertEquals(4, totalsForBatch0.get(GiftBatchAggregateGroupName.FAILED_PAYMENT.name()));
        System.assertEquals(4, totalsForBatch0.get(GiftBatchAggregateGroupName.EXPIRED_PAYMENT.name()));
        System.assertEquals(3, totalsForBatch0.get(GiftBatchAggregateGroupName.AUTHORIZED_PAYMENT.name()));
        System.assertEquals(1 + 2 + 3 + 4, totalsForBatch0.get(GiftBatchAggregateGroupName.TOTAL.name()));

        Map<String, Integer> totalsForBatch1 = batchTotals.totalsFor(DUMMY_BATCH_ID_1);
        System.assertEquals(0, totalsForBatch1.get(GiftBatchAggregateGroupName.PROCESSED.name()));
        System.assertEquals(11, totalsForBatch1.get(GiftBatchAggregateGroupName.FAILED.name()));
        System.assertEquals(11, totalsForBatch1.get(GiftBatchAggregateGroupName.FAILED_PAYMENT.name()));
        System.assertEquals(5 + 6, totalsForBatch1.get(GiftBatchAggregateGroupName.TOTAL.name()));
    }
}
