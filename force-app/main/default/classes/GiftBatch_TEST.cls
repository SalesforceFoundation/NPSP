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
private class GiftBatch_TEST {

    @isTest
    static void shouldUpdateGiftRecordsFromAuthorizedToPaymentProcessingStatus() {
        final Integer numberOfGifts = 10;
        Gifts authorizedGifts = new Gifts(buildGifts(numberOfGifts, ElevateTransactionStatus.AUTHORIZED.name()));
        GiftBatch giftBatch = new GiftBatch();
        giftBatch.gifts = authorizedGifts;
        ElevateBatchServiceMock elevateBatchServiceMock = new ElevateBatchServiceMock();

        System.assert(authorizedGifts.giftsToUpdate.size() == 0);

        giftBatch.elevateBatchService = stubFor(elevateBatchServiceMock);
        giftBatch.giftBatchId = DUMMY_GIFT_BATCH_ID;
        giftBatch.captureAuthorizedGifts();

        System.assert(elevateBatchServiceMock.enqueuePaymentCaptureJobForCalled);
        System.assert(authorizedGifts.giftsToUpdate.size() == numberOfGifts);
        for (DataImport__c gift : authorizedGifts.giftsToUpdate.values()) {
            System.assertEquals(ElevateTransactionStatus.PAYMENTPROCESSING.name(), gift.Payment_Status__c);
        }
    }

    @isTest
    static void shouldUpdateGiftRecordsWithFailReason() {
        final Integer numberOfGifts = 5;
        Gifts authorizedGifts = new Gifts(buildGifts(numberOfGifts, ElevateTransactionStatus.AUTHORIZED.name()));
        GiftBatch giftBatch = new GiftBatch();
        giftBatch.gifts = authorizedGifts;
        ElevateBatchServiceMock elevateBatchServiceMock = new ElevateBatchServiceMock();

        System.assert(authorizedGifts.giftsToUpdate.size() == 0);

        giftBatch.elevateBatchService = stubFor(elevateBatchServiceMock);
        giftBatch.failGiftsWithReason(buildFailReasonByElevateBatchId(numberOfGifts));

        System.assert(authorizedGifts.giftsToUpdate.size() == numberOfGifts);
        for (DataImport__c gift : authorizedGifts.giftsToUpdate.values()) {
            System.assertEquals(ElevateTransactionStatus.RETRYABLEERROR.name(), gift.Payment_Status__c);
            System.assertEquals('DUMMY FAIL REASON', gift.FailureInformation__c);
        }
    }

    @isTest
    static void shouldReturnTotalCountOf10AndTotalAmountOf35050() {
        AggregateResultProxy mockTotalsResult = new AggregateResultProxy()
            .withAliasAndValue('recordCount', 10);
        AggregateResultProxy mockedTotalAmountResult = new AggregateResultProxy()
            .withAliasAndValue('totalAmount', 350.50);

        GiftBatchTotals totals = new GiftBatchTotals(mockTotalsResult, mockedTotalAmountResult);

        GiftBatch giftBatch = new GiftBatch();
        giftBatch.totals = totals;

        System.assertEquals(10, giftBatch.totals().get('TOTAL'));
        System.assertEquals(350.50, giftBatch.totalDonations().amount());
    }

    @isTest
    static void shouldReturnTrueWhenElevateWidgetOnTemplate() {
        GiftBatch giftBatch = new GiftBatch();
        giftBatch.giftTemplate = createDummyGiftTemplate(true);

        System.assertEquals(true, giftBatch.hasElevateWidget());
    }

    @isTest
    static void shouldReturnFalseWhenElevateWidgetNotOnTemplate() {
        GiftBatch giftBatch = new GiftBatch();
        giftBatch.giftTemplate = createDummyGiftTemplate(false);

        System.assertEquals(false, giftBatch.hasElevateWidget());
    }

    @isTest
    static void shouldReturn3Gifts() {
        Gifts gifts = new Gifts(buildGifts(3, null));
        GiftBatch giftBatch = new GiftBatch();
        giftBatch.gifts = gifts;

        System.assertEquals(3, giftBatch.gifts().size());
    }

    @isTest
    static void shouldReturnExpectedGiftBatchRecordProperties() {
        String dummyDataImportBatchJSON = '{"attributes":{"type":"DataImportBatch__c"},"LastModifiedDate":"2021-10-04T17:54:26.000Z"}';
        DataImportBatch__c dummyDataImportBatch = (DataImportBatch__c) JSON.deserialize(dummyDataImportBatchJSON, DataImportBatch__c.class);
        dummyDataImportBatch.Name = 'DUMMY_GIFT_BATCH_NAME';
        dummyDataImportBatch.RequireTotalMatch__c = false;
        dummyDataImportBatch.Expected_Count_of_Gifts__c = 5;
        dummyDataImportBatch.Expected_Total_Batch_Amount__c = 100.25;
        dummyDataImportBatch.Batch_Table_Columns__c = '[dummy_batch_table_columns]';

        GiftBatch giftBatch = new GiftBatch();
        giftBatch.batch = dummyDataImportBatch;

        System.assertEquals('DUMMY_GIFT_BATCH_NAME', giftBatch.name());
        System.assertEquals(false, giftBatch.requireTotalMatch());
        System.assertEquals(5, giftBatch.expectedCountOfGifts());
        System.assertEquals(100.25, giftBatch.expectedTotalBatchAmount());
        System.assertEquals('[dummy_batch_table_columns]', giftBatch.batchTableColumns());

        DateTime expectedLastModifiedDate = dummyDataImportBatch.LastModifiedDate;
        System.assertEquals(expectedLastModifiedDate, giftBatch.lastModifiedDate());

        if (!UserInfo.isMultiCurrencyOrganization()) {
            System.assertEquals(UserInfo.getDefaultCurrency(), giftBatch.currencyIsoCode());
        }
    }

    @isTest
    static void shouldAddProvidedGiftToGiftBatchGifts() {
        String additionalObjectStringWithSoftCredits =
            new UTIL_AdditionalObjectData_TEST()
            .withOpportunityContactRoles(3)
            .build();
        DataImport__c dummyDataImport = new DataImport__c(
            Donation_Amount__c = 33.33,
            Additional_Object_JSON__c = additionalObjectStringWithSoftCredits
        );
        Gift dummyGift = new Gift(dummyDataImport);
        GiftBatch dummyGiftBatch = new GiftBatch();

        System.assertEquals(0, dummyGiftBatch.gifts().size());

        dummyGiftBatch.add(dummyGift);

        System.assertEquals(1, dummyGiftBatch.gifts().size());
        System.assertEquals(3, dummyGiftBatch.gifts().findBy(new GiftId(dummyGift.id())).softCredits().size());
    }

    @IsTest
    static void shouldUpdateProcessingGiftsInAbortedBatchesToFailed() {
        GiftBatch giftBatch = new GiftBatch();
        giftBatch.giftBatchId = DUMMY_GIFT_BATCH_ID;
        giftBatch.gifts = new Gifts();
        giftBatch.gifts.dataImportsById = buildDataImportsByIds(DUMMY_GIFT_BATCH_ID.value());
        giftBatch.gifts.giftsToUpdate = new Map<Id, DataImport__c>();
        giftBatch.asyncApexJob =  new TestAsyncApexJob()
            .withStatus(UTIL_BatchJobService.ApexJobStatus.ABORTED.name())
            .build();

        System.assert(giftBatch.canBeEnqueued());
        System.assert(giftBatch.hasStandardGiftsToResolve());

        giftBatch.resolveStandardGiftsRemainingInProcessing();

        System.assertEquals(1, giftBatch.gifts.giftsToUpdate.size());

        for(DataImport__c gift : giftBatch.gifts.giftsToUpdate.values()) {
            System.assert(gift.Status__c == BDI_DataImport_API.bdiFailed);
            System.assertNotEquals(null, gift.FailureInformation__c);
        }
    }

    @IsTest
    static void shouldUpdateProcessingGiftsInFailedBatchesToFailed() {
        GiftBatch giftBatch = new GiftBatch();
        giftBatch.giftBatchId = DUMMY_GIFT_BATCH_ID;
        giftBatch.gifts = new Gifts();
        giftBatch.gifts.dataImportsById = buildDataImportsByIds(DUMMY_GIFT_BATCH_ID.value());
        giftBatch.gifts.giftsToUpdate = new Map<Id, DataImport__c>();
        giftBatch.asyncApexJob =  new TestAsyncApexJob()
            .withStatus(UTIL_BatchJobService.ApexJobStatus.FAILED.name())
            .build();

        System.assert(giftBatch.canBeEnqueued());
        System.assert(giftBatch.hasStandardGiftsToResolve());

        giftBatch.resolveStandardGiftsRemainingInProcessing();

        System.assertEquals(1, giftBatch.gifts.giftsToUpdate.size());

        for(DataImport__c gift : giftBatch.gifts.giftsToUpdate.values()) {
            System.assert(gift.Status__c == BDI_DataImport_API.bdiFailed);
            System.assertNotEquals(null, gift.FailureInformation__c);
        }
    }

    @IsTest
    static void shouldUpdateProcessingGiftsInCompletedBatchesToFailed() {
        GiftBatch giftBatch = new GiftBatch();
        giftBatch.gifts = new Gifts();
        giftBatch.giftBatchId = DUMMY_GIFT_BATCH_ID;
        giftBatch.gifts.dataImportsById = buildDataImportsByIds(DUMMY_GIFT_BATCH_ID.value());
        giftBatch.gifts.giftsToUpdate = new Map<Id, DataImport__c>();
        giftBatch.asyncApexJob =  new TestAsyncApexJob()
            .withStatus(UTIL_BatchJobService.ApexJobStatus.COMPLETED.name())
            .build();

        System.assert(giftBatch.canBeEnqueued());
        System.assert(giftBatch.hasStandardGiftsToResolve());

        giftBatch.resolveStandardGiftsRemainingInProcessing();

        System.assertEquals(1, giftBatch.gifts.giftsToUpdate.size());

        for(DataImport__c gift : giftBatch.gifts.giftsToUpdate.values()) {
            System.assert(gift.Status__c == BDI_DataImport_API.bdiFailed);
            System.assertNotEquals(null, gift.FailureInformation__c);
        }
    }

    @IsTest
    static void shouldNotUpdateProcessingGiftsInUnfinishedBatchesToFailed() {
        GiftBatch giftBatch = new GiftBatch();
        giftBatch.gifts = new Gifts();
        giftBatch.giftBatchId = DUMMY_GIFT_BATCH_ID;
        giftBatch.gifts.dataImportsById = buildDataImportsByIds(DUMMY_GIFT_BATCH_ID.value());
        giftBatch.gifts.giftsToUpdate = new Map<Id, DataImport__c>();
        giftBatch.asyncApexJob =  new TestAsyncApexJob()
            .withStatus(UTIL_BatchJobService.ApexJobStatus.PROCESSING.name())
            .build();

        System.assert(!giftBatch.canBeEnqueued());
        System.assert(!giftBatch.hasStandardGiftsToResolve());
    }


    private static Map<Id, DataImport__c> buildDataImportsByIds(Id batchId) {
        Map<Id, DataImport__c> dataImportMap = new Map<Id, DataImport__c>();
        dataImportMap.put(getDummyDataImportId(),
            new DataImport__c(Id = getDummyDataImportId(),
                Status__c = BDI_DataImport_API.bdiProcessing, NPSP_Data_Import_Batch__c = batchId));
        return dataImportMap;
    }

    private static Id getDummyDataImportId() {
        return UTIL_UnitTestData_TEST.mockId(DataImport__c.getSObjectType());
    }

    /***
 * @description Builds an AsyncApexJob and sets attributes that are not writable otherwise
 */
    public class TestAsyncApexJob {
        private Map<String, Object> valuesByFieldName;

        public TestAsyncApexJob() {
            valuesByFieldName = new Map<String, Object>();
            //defaults
            valuesByFieldName.put('Status', UTIL_BatchJobService.ApexJobStatus.COMPLETED.name());
        }

        public TestAsyncApexJob withStatus(String status) {
            valuesByFieldName.put('Status', status);
            return this;
        }

        public AsyncApexJob build() {
            String jsonString = JSON.serialize(valuesByFieldName);

            return (AsyncApexJob) JSON.deserialize(jsonString, AsyncApexJob.class);
        }
    }

    private static GiftTemplate createDummyGiftTemplate(Boolean withElevateWidget) {
        GE_Template.Element field =
            new GE_Template.Element('field', 'True', null, 'CustomLabel', new List<String>{'Account_1_Name'});

        GE_Template.Element[] elements = new GE_Template.Element[] { field };

        if (withElevateWidget == true) {
            GE_Template.Element widget =
                new GE_Template.Element('widget', 'DisplayRule', 'geFormWidgetTokenizeCard', new List<String>{});
            elements.add(widget);
        }

        GE_Template.Section section =
            new GE_Template.Section('SectionLabel', 'Accordion', 'Expanded', 'True', elements);

        GE_Template.Layout layout =
            new GE_Template.Layout('DefaultMappingSet', new GE_Template.Section[]{section});

        GE_Template.Template template =
            new GE_Template.Template('Sample Template', 'This is the description.', '1.0', layout);

        return new GiftTemplate(JSON.serialize(template));
    }

    private class ElevateBatchServiceMock implements StubProvider {
        public Boolean enqueuePaymentCaptureJobForCalled = false;

        public Object handleMethodCall(Object stubbedObject,
            String stubbedMethodName,
            Type returnType,
            List<Type> listOfParamTypes,
            List<String> listOfParamNames,
            List<Object> listOfArgs) {

            switch on (stubbedMethodName) {
                when 'enqueuePaymentCaptureJobFor' {
                    enqueuePaymentCaptureJobForCalled = true;
                }
            }

            return null;
        }
    }

    private static ElevateBatchService stubFor(ElevateBatchServiceMock elevateBatchServiceMock) {
        return (ElevateBatchService) Test.createStub(ElevateBatchService.class, elevateBatchServiceMock);
    }

    public class PS_IntegrationServiceConfigMock implements StubProvider {
        public Boolean isIntegrationEnabled = false;

        public PS_IntegrationServiceConfigMock(Boolean isIntegrationEnabled) {
            this.isIntegrationEnabled = isIntegrationEnabled;
        }

        public Object handleMethodCall(Object stubbedObject,
            String stubbedMethodName,
            Type returnType,
            List<Type> listOfParamTypes,
            List<String> listOfParamNames,
            List<Object> listOfArgs) {

            switch on (stubbedMethodName) {
                when 'isIntegrationEnabled' {
                    return isIntegrationEnabled;
                }
            }

            return null;
        }
    }

    private static PS_IntegrationServiceConfig stubFor(PS_IntegrationServiceConfigMock integrationServiceConfigMock) {
        return (PS_IntegrationServiceConfig) Test.createStub(
            PS_IntegrationServiceConfig.class,
            integrationServiceConfigMock
        );
    }

    public class GiftsMock implements StubProvider {
        public Object handleMethodCall(Object stubbedObject,
            String stubbedMethodName,
            Type returnType,
            List<Type> listOfParamTypes,
            List<String> listOfParamNames,
            List<Object> listOfArgs) {

            return null;
        }
    }

    private static Gifts stubFor(GiftsMock giftsMock) {
        return (Gifts) Test.createStub(Gifts.class, giftsMock);
    }

    private static List<DataImport__c> buildGifts(Integer numberOfGifts, String paymentStatus) {
        List<DataImport__c> dummyAuthorizedGifts = new List<DataImport__c>();
        for (Integer i = 0; i < numberOfGifts; i++) {
            DataImport__c dummyGift = new DataImport__c(
                Id = UTIL_UnitTestData_TEST.mockId(DataImport__c.getSObjectType()),
                Status__c = null,
                NPSP_Data_Import_Batch__c = UTIL_UnitTestData_TEST.mockId(DataImportBatch__c.getSObjectType()),
                Account1_Name__c = 'DUMMY ACCOUNT ' +  i,
                Donation_Amount__c = 1,
                Donation_Date__c = Date.today(),
                Donation_Donor__c = 'Account1',
                Payment_Status__c = paymentStatus,
                Payment_Elevate_Batch_ID__c = 'DUMMY_ELEVATE_BATCH_ID_' + i
            );
            dummyAuthorizedGifts.add(dummyGift);
        }
        return dummyAuthorizedGifts;
    }

    private static Map<String, String> buildFailReasonByElevateBatchId(Integer numberOfGifts) {
        Map<String, String> failReasonByElevateBatchId = new Map<String, String>();
        for (Integer i = 0; i < numberOfGifts; i++) {
            failReasonByElevateBatchId.put('DUMMY_ELEVATE_BATCH_ID_' + i, 'DUMMY FAIL REASON');
        }
        return failReasonByElevateBatchId;
    }

    private static final GiftBatchId DUMMY_GIFT_BATCH_ID =
        new GiftBatchId(UTIL_UnitTestData_TEST.mockId(DataImportBatch__c.getSObjectType()));
}