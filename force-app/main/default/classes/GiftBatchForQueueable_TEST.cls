/*
    Copyright (c) 2022 Salesforce.org
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
* @date 2022
* @description GiftBatchForQueueable test class
*/
@IsTest
private class GiftBatchForQueueable_TEST {

    @isTest
    static void shouldAttemptToCaptureElevatePaymentsWhenServiceUnavailable() {
        // Arrange
        Id dummyDataImportBatchId = UTIL_UnitTestData_TEST.mockId(DataImportBatch__c.SObjectType);
        GiftBatchForQueueable dummyGiftBatchForQueueable = buildGiftBatch(dummyDataImportBatchId);
        List<DataImport__c> authorizedGift = new List<DataImport__c> {
            new DataImport__c(
                Id = UTIL_UnitTestData_TEST.mockId(DataImport__c.SObjectType),
                Payment_Status__c = ElevateTransactionStatus.AUTHORIZED.name(),
                Status__c = BDI_DataImport_API.bdiDryRunValidated
            )
        };

        GiftsMock giftsMock = new GiftsMock().with(authorizedGift);
        dummyGiftBatchForQueueable.gifts = stubFor(giftsMock);

        ElevateBatchServiceMock elevateBatchServiceMock = new ElevateBatchServiceMock();
        dummyGiftBatchForQueueable.elevateBatchService = stubFor(elevateBatchServiceMock);

        PS_IntegrationServiceConfigMock integrationServiceConfigMock = new PS_IntegrationServiceConfigMock(true);
        dummyGiftBatchForQueueable.paymentIntegrationServiceConfig = stubFor(integrationServiceConfigMock);

        // Act
        dummyGiftBatchForQueueable.captureElevateBatches();

        // Assert
        System.assertEquals(true, elevateBatchServiceMock.enqueuePaymentCaptureJobForCalled);
        System.assertEquals(true, giftsMock.authorizedToPaymentProcessingStatusWasCalled);
    }

    @isTest
    static void shouldNotAttemptToCaptureElevatePaymentsWhenServiceAvailable() {
        // Arrange
        Id dummyDataImportBatchId = UTIL_UnitTestData_TEST.mockId(DataImportBatch__c.SObjectType);
        GiftBatchForQueueable dummyGiftBatchForQueueable = buildGiftBatch(dummyDataImportBatchId);
        List<DataImport__c> authorizedGift = new List<DataImport__c> {
            new DataImport__c(
                Id = UTIL_UnitTestData_TEST.mockId(DataImport__c.SObjectType),
                Payment_Status__c = ElevateTransactionStatus.AUTHORIZED.name(),
                Status__c = BDI_DataImport_API.bdiDryRunValidated
            )
        };

        GiftsMock giftsMock = new GiftsMock().with(authorizedGift);
        dummyGiftBatchForQueueable.gifts = stubFor(giftsMock);

        ElevateBatchServiceMock elevateBatchServiceMock = new ElevateBatchServiceMock();
        dummyGiftBatchForQueueable.elevateBatchService = stubFor(elevateBatchServiceMock);

        PS_IntegrationServiceConfigMock integrationServiceConfigMock = new PS_IntegrationServiceConfigMock(false);
        dummyGiftBatchForQueueable.paymentIntegrationServiceConfig = stubFor(integrationServiceConfigMock);

        // Act
        dummyGiftBatchForQueueable.captureElevateBatches();

        // Assert
        System.assertEquals(false, elevateBatchServiceMock.enqueuePaymentCaptureJobForCalled);
        System.assertEquals(false, giftsMock.authorizedToPaymentProcessingStatusWasCalled);
    }

    @IsTest
    static void shouldReturn14ChunksOfGiftsWhen700GiftsAreProcessable() {
        // Arrange
        Id dummyDataImportBatchId = UTIL_UnitTestData_TEST.mockId(DataImportBatch__c.SObjectType);
        GiftBatchForQueueable dummyGiftBatchForQueueable = buildGiftBatch(dummyDataImportBatchId);

        // These gifts cannot move to processing status
        List<DataImport__c> importedGifts =
            buildGifts(5, BDI_DataImport_API.bdiImported, dummyDataImportBatchId, true);
        List<DataImport__c> processingGifts =
            buildGifts(4, BDI_DataImport_API.bdiProcessing, dummyDataImportBatchId, true);

        // These gifts can move to processing status
        List<DataImport__c> failedGifts =
            buildGifts(200, BDI_DataImport_API.bdiFailed, dummyDataImportBatchId, true);
        List<DataImport__c> dryRunValidatedGifts =
            buildGifts(500, BDI_DataImport_API.bdiDryRunValidated, dummyDataImportBatchId, true);

        GiftsSelectorForProcessingMock selectorMock =
            new GiftsSelectorForProcessingMock()
                .withImportedGifts(importedGifts)
                .withProcessingGifts(processingGifts)
                .withFailedGifts(failedGifts)
                .withDryRunValidatedGifts(dryRunValidatedGifts);
        dummyGiftBatchForQueueable.giftsSelector = stubFor(selectorMock);

        // Act
        dummyGiftBatchForQueueable.chunkGiftsThatCanBeProcessed();

        // Assert
        System.assertEquals(14, dummyGiftBatchForQueueable.chunkedIds.size(),
            'Should return 14 chunks of gifts');
    }

    @IsTest
    static void shouldSetGiftStatusToProcessingForNextChunk() {
        // Arrange
        Id dummyDataImportBatchId = UTIL_UnitTestData_TEST.mockId(DataImportBatch__c.SObjectType);
        GiftBatchForQueueable dummyGiftBatchForQueueable = buildGiftBatch(dummyDataImportBatchId);
        List<DataImport__c> failedGifts =
            buildGifts(1, BDI_DataImport_API.bdiFailed, dummyDataImportBatchId, true);
        List<DataImport__c> dryRunValidatedGifts =
            buildGifts(1, BDI_DataImport_API.bdiDryRunValidated, dummyDataImportBatchId, true);

        GiftsSelectorForProcessingMock selectorMock =
            new GiftsSelectorForProcessingMock()
                .withFailedGifts(failedGifts)
                .withDryRunValidatedGifts(dryRunValidatedGifts);
        dummyGiftBatchForQueueable.giftsSelector = stubFor(selectorMock);
        dummyGiftBatchForQueueable.chunkGiftsThatCanBeProcessed();

        // Act
        dummyGiftBatchForQueueable.prepareChunk();

        // Assert
        List<DataImport__c> gifts = dummyGiftBatchForQueueable.gifts.giftsToUpdate.values();
        System.assertEquals(2, gifts.size());
        System.assertEquals(BDI_DataImport_API.bdiProcessing, gifts[0].Status__c);
        System.assertEquals(BDI_DataImport_API.bdiProcessing, gifts[1].Status__c);
    }

    @IsTest
    static void shouldReturnGiftBatchId() {
        // Arrange
        Id dummyDataImportBatchId = UTIL_UnitTestData_TEST.mockId(DataImportBatch__c.SObjectType);
        GiftBatchForQueueable dummyGiftBatchForProcessing = buildGiftBatch(dummyDataImportBatchId);

        // Act
        GiftBatchId returnedDummyId = dummyGiftBatchForProcessing.id();

        // Assert
        System.assertEquals(dummyDataImportBatchId, returnedDummyId.value(),
            'Should return the gift batch id');
    }

    @IsTest
    static void shouldHaveChunksToProcessWhenGiftBatchHasGiftsThatCanBeProcessed() {
        // Arrange
        Id dummyDataImportBatchId = UTIL_UnitTestData_TEST.mockId(DataImportBatch__c.SObjectType);
        GiftBatchForQueueable dummyGiftBatchForProcessing = buildGiftBatch(dummyDataImportBatchId);
        // These gifts cannot move to processing status
        List<DataImport__c> importedGifts =
            buildGifts(2, BDI_DataImport_API.bdiImported, dummyDataImportBatchId, true);
        List<DataImport__c> processingGifts =
            buildGifts(3, BDI_DataImport_API.bdiProcessing, dummyDataImportBatchId, true);

        // These gifts can move to processing status
        List<DataImport__c> failedGifts =
            buildGifts(100, BDI_DataImport_API.bdiFailed, dummyDataImportBatchId, true);
        List<DataImport__c> dryRunValidatedGifts =
            buildGifts(50, BDI_DataImport_API.bdiDryRunValidated, dummyDataImportBatchId, true);

        GiftsSelectorForProcessingMock selectorMock =
            new GiftsSelectorForProcessingMock()
                .withImportedGifts(importedGifts)
                .withProcessingGifts(processingGifts)
                .withFailedGifts(failedGifts)
                .withDryRunValidatedGifts(dryRunValidatedGifts);
        dummyGiftBatchForProcessing.giftsSelector = stubFor(selectorMock);

        // Act
        dummyGiftBatchForProcessing.chunkGiftsThatCanBeProcessed();

        // Assert
        System.assertEquals(3, dummyGiftBatchForProcessing.chunkedIds.size(),
            'Should return 3 chunks that are ready to be updated to processing status');
        System.assertEquals(true, dummyGiftBatchForProcessing.hasChunksToProcess(),
            'Should return true when there are chunks to process');
        for (List<Id> chunk : dummyGiftBatchForProcessing.chunkedIds) {
            System.assertEquals(50, chunk.size(),
                'Should return 50 gifts in each chunk');
        }
    }

    @IsTest
    static void shouldNotHaveAnyChunksWhenGiftBatchHasNoProcessableGifts() {
        // Arrange
        Id dummyDataImportBatchId = UTIL_UnitTestData_TEST.mockId(DataImportBatch__c.SObjectType);
        GiftBatchForQueueable dummyGiftBatchForProcessing = buildGiftBatch(dummyDataImportBatchId);
        // These gifts cannot move to processing status
        List<DataImport__c> importedGifts =
            buildGifts(2, BDI_DataImport_API.bdiImported, dummyDataImportBatchId, true);

        GiftsSelectorForProcessingMock selectorMock =
            new GiftsSelectorForProcessingMock()
                .withImportedGifts(importedGifts);
        dummyGiftBatchForProcessing.giftsSelector = stubFor(selectorMock);

        // Act
        dummyGiftBatchForProcessing.chunkGiftsThatCanBeProcessed();

        // Assert
        System.assertEquals(0, dummyGiftBatchForProcessing.chunkedIds.size(),
            'Should not have any chunks to process');
    }

    @IsTest
    static void shouldCallMethodOnMemberToUpdateGifts() {
        // Arrange
        Id dummyDataImportBatchId = UTIL_UnitTestData_TEST.mockId(DataImportBatch__c.SObjectType);
        GiftBatchForQueueable dummyGiftBatchForProcessing = buildGiftBatch(dummyDataImportBatchId);
        List<DataImport__c> dryRunValidatedGifts =
            buildGifts(2, BDI_DataImport_API.bdiDryRunValidated, dummyDataImportBatchId, true);
        GiftsMock giftsMock = new GiftsMock().with(dryRunValidatedGifts);
        dummyGiftBatchForProcessing.gifts = stubFor(giftsMock);

        // Act
        dummyGiftBatchForProcessing.updateGiftsInChunk();

        // Assert
        System.assertEquals(true, giftsMock.updateRecordsWasCalled(),
            'Should have called updateRecords method on Gifts member');
    }

    public class GiftsSelectorForProcessingMock implements StubProvider {

        public List<DataImport__c> importedGifts = new List<DataImport__c>();
        public List<DataImport__c> processingGifts = new List<DataImport__c>();
        public List<DataImport__c> failedGifts = new List<DataImport__c>();
        public List<DataImport__c> dryRunValidatedGifts = new List<DataImport__c>();

        public GiftsSelectorForProcessingMock() {}

        public GiftsSelectorForProcessingMock withImportedGifts(List<DataImport__c> gifts) {
            importedGifts = gifts;
            return this;
        }

        public GiftsSelectorForProcessingMock withProcessingGifts(List<DataImport__c> gifts) {
            processingGifts = gifts;
            return this;
        }

        public GiftsSelectorForProcessingMock withFailedGifts(List<DataImport__c> gifts) {
            failedGifts = gifts;
            return this;
        }

        public GiftsSelectorForProcessingMock withDryRunValidatedGifts(List<DataImport__c> gifts) {
            dryRunValidatedGifts = gifts;
            return this;
        }

        public Object handleMethodCall(Object stubbedObject,
            String stubbedMethodName,
            Type returnType,
            List<Type> listOfParamTypes,
            List<String> listOfParamNames,
            List<Object> listOfArgs) {

            switch on (stubbedMethodName) {
                when 'getGiftsReadyToMoveToProcessing' {
                    List<DataImport__c> giftsToReturn = new List<DataImport__c>();
                    giftsToReturn.addAll(dryRunValidatedGifts);
                    giftsToReturn.addAll(failedGifts);
                    return giftsToReturn;
                }
            }
            return null;
        }
    }

    private static GiftsSelectorForProcessing stubFor(GiftsSelectorForProcessingMock giftsSelectorMock) {
        return (GiftsSelectorForProcessing) Test.createStub(
            GiftsSelectorForProcessing.class,
            giftsSelectorMock
        );
    }

    private class GiftBatchSelectorMock implements StubProvider {
        public Object handleMethodCall(Object stubbedObject,
                String stubbedMethodName,
                Type returnType,
                List<Type> listOfParamTypes,
                List<String> listOfParamNames,
                List<Object> listOfArgs) {

            switch on (stubbedMethodName) {
                when 'selectGiftBatchBy' {
                    return new DataImportBatch__c();
                }
            }
            return null;
        }
    }

    private static GiftBatchSelector stubFor(GiftBatchSelectorMock giftBatchSelectorMock) {
        return (GiftBatchSelector) Test.createStub(GiftBatchSelector.class, giftBatchSelectorMock);
    }


    public class GiftsMock implements StubProvider {

        public List<DataImport__c> gifts = new List<DataImport__c>();
        private Boolean prepareForProcessingWasCalled = false;
        private Boolean updateRecordsWasCalled = false;
        private Boolean authorizedToPaymentProcessingStatusWasCalled = false;

        public GiftsMock() {}

        public GiftsMock with(List<DataImport__c> gifts) {
            this.gifts = gifts;
            return this;
        }

        public Boolean updateRecordsWasCalled() {
            return updateRecordsWasCalled;
        }

        public Boolean prepareForProcessingWasCalled() {
            return prepareForProcessingWasCalled;
        }

        public Object handleMethodCall(Object stubbedObject,
            String stubbedMethodName,
            Type returnType,
            List<Type> listOfParamTypes,
            List<String> listOfParamNames,
            List<Object> listOfArgs) {

            switch on (stubbedMethodName) {
                when 'prepareForProcessing' {
                    prepareForProcessingWasCalled = true;
                }

                when 'updateRecords' {
                    updateRecordsWasCalled = true;
                }

                when 'authorizedToPaymentProcessingStatus' {
                    authorizedToPaymentProcessingStatusWasCalled = true;
                }
            }

            return null;
        }
    }

    private static Gifts stubFor(GiftsMock giftsMock) {
        return (Gifts) Test.createStub(Gifts.class, giftsMock);
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

    private static GiftBatchForQueueable buildGiftBatch(Id dummyId) {
        GiftBatchSelector mockedGiftBatchSelector = stubFor(new GiftBatchSelectorMock());
        GiftBatchId dummyGiftBatchId =
            new GiftBatchId(dummyId);
        GiftBatchForQueueable dummyGiftBatchForProcessing =
            new GiftBatchForQueueable(dummyGiftBatchId, mockedGiftBatchSelector);
        return dummyGiftBatchForProcessing;
    }

    private static List<DataImport__c> buildGifts(Integer count, String status, Id giftBatchId, Boolean addDummyId) {
        List<DataImport__c> gifts = new List<DataImport__c>();
        for (Integer i = 0; i < count; i++) {
            gifts.add(new DataImport__c(
                Id = addDummyId ? UTIL_UnitTestData_TEST.mockId(DataImport__c.SObjectType) : null,
                Donation_Amount__c = 33.33,
                Donation_Date__c = Date.today(),
                Status__c = status,
                NPSP_Data_Import_Batch__c = giftBatchId
            ));
        }
        return gifts;
    }

    private static Id createMockId(SObjectType type) {
        return UTIL_UnitTestData_TEST.mockId(type);
    }

}
