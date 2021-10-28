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
@IsTest
private class GiftBatches_TEST {

    @IsTest
    static void shouldReturnExpectedGroupedTotals() {
        GiftBatchSelector mockedGiftBatchSelector = stubFor(new GiftBatchSelectorMock());
        Id dummyGiftBatchIdForEmptyTotals = UTIL_UnitTestData_TEST.mockId(DataImportBatch__c.SObjectType);
        GiftBatches giftBatches = new GiftBatches(
            new Set<Id> { DUMMY_BATCH_ID_0, dummyGiftBatchIdForEmptyTotals },
            mockedGiftBatchSelector);

        GiftBatchGroupedTotals groupedTotals = giftBatches.getGroupedTotals();
        Map<String, Integer> totalsForGiftBatch = groupedTotals.totalsFor(DUMMY_BATCH_ID_0);

        System.assertEquals(1, totalsForGiftBatch.get(GiftBatchAggregateGroupName.PROCESSED.name()));
        System.assertEquals(2 + 4, totalsForGiftBatch.get(GiftBatchAggregateGroupName.FAILED.name()));
        System.assertEquals(4, totalsForGiftBatch.get(GiftBatchAggregateGroupName.FAILED_PAYMENT.name()));
        System.assertEquals(4, totalsForGiftBatch.get(GiftBatchAggregateGroupName.EXPIRED_PAYMENT.name()));
        System.assertEquals(3, totalsForGiftBatch.get(GiftBatchAggregateGroupName.AUTHORIZED_PAYMENT.name()));
        System.assertEquals(1 + 2 + 3 + 4, totalsForGiftBatch.get(GiftBatchAggregateGroupName.TOTAL.name()));
    }
    
    private class GiftBatchSelectorMock implements StubProvider {
        public Object handleMethodCall(Object stubbedObject,
            String stubbedMethodName,
            Type returnType,
            List<Type> listOfParamTypes,
            List<String> listOfParamNames,
            List<Object> listOfArgs) {

            switch on (stubbedMethodName) {
                when 'selectGiftBatchesById' {
                    return new List<DataImportBatch__c> { new DataImportBatch__c() };
                }
                when 'selectBatchGiftsGroupedByStatusBy' {
                    return proxiesForBatch0;
                }
            }

            return null;
        }
    }

    private static GiftBatchSelector stubFor(GiftBatchSelectorMock giftBatchSelectorMock) {
        return (GiftBatchSelector) Test.createStub(GiftBatchSelector.class, giftBatchSelectorMock);
    }

    private static Id DUMMY_BATCH_ID_0 = UTIL_UnitTestData_TEST.mockId(DataImportBatch__c.SObjectType);
    private static String elevatePaymentAuthorizedStatus = ElevateTransactionStatus.AUTHORIZED.name();
    private static String elevatePaymentDeclinedStatus = ElevateTransactionStatus.DECLINED.name();
    private static String elevatePaymentExpiredStatus = ElevateTransactionStatus.EXPIRED.name();

    private static String dataImportBatchFieldAPIName = String.valueOf(DataImport__c.fields.NPSP_Data_Import_Batch__c);
    private static String dataImportPaymentStatusFieldAPIName = String.valueOf(DataImport__c.fields.Payment_Status__c);
    private static String dataImportStatusFieldName = String.valueOf(DataImport__c.fields.Status__c);

    private static List<AggregateResultProxy> proxiesForBatch0 = new List<AggregateResultProxy> {
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
}
