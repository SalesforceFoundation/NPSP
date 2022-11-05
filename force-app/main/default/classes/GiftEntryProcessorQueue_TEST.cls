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
* @description GiftEntryProcessorQueue test class
*/

@IsTest
private class GiftEntryProcessorQueue_TEST {

    @isTest
    static void shouldCreateRecurringDonationWhenGiftBatchHasRecurringGift() {
        // Arrange
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        Data_Import_Settings__c dataImportSettings = UTIL_CustomSettingsFacade.getDataImportSettings();
        dataImportSettings.Field_Mapping_Method__c = BDI_DataImportService.FM_DATA_IMPORT_FIELD_MAPPING;
        dataImportSettings.Default_Data_Import_Field_Mapping_Set__c =
            BDI_MappingServiceAdvanced.DEFAULT_DATA_IMPORT_FIELD_MAPPING_SET_NAME;
        UTIL_CustomSettingsFacade.setDataImportSettings(dataImportSettings);

        DataImportBatch__c giftBatch = new DataImportBatch__c();
        insert giftBatch;

        List<DataImport__c> giftsToInsert = new List<DataImport__c>();
        giftsToInsert.add(new DataImport__c(
            Recurring_Donation_Installment_Period__c = 'Monthly',
            Recurring_Donation_Effective_Date__c = Date.today(),
            Recurring_Donation_Recurring_Type__c = 'Open',
            Recurring_Donation_Day_of_Month__c = '5',
            Recurring_Donation_Amount__c = 25.00,
            Recurring_Donation_Date_Established__c = Date.today(),
            Donation_Date__c = Date.today(),
            NPSP_Data_Import_Batch__c = giftBatch.Id,
            Contact1_Lastname__c = 'Dummy Last Name',
            Donation_Donor__c = 'Contact1'
        ));
        insert giftsToInsert;

        GiftBatchForQueueable giftBatchForProcessing = new GiftBatchForQueueable(new GiftBatchId(giftBatch.Id), new GiftBatchSelector());
        giftBatchForProcessing.chunkGiftsThatCanBeProcessed();
        GiftEntryProcessorQueue processorQueue = new GiftEntryProcessorQueue(giftBatchForProcessing);

        // Act
        Test.startTest();
        processorQueue.execute(null);
        Test.stopTest();

        // Assert
        npe03__Recurring_Donation__c[] resultingRDs =
            [SELECT Id,
                npe03__Amount__c,
                npe03__Installment_Period__c,
                RecurringType__c,
                StartDate__c,
                npe03__Date_Established__c,
                Day_of_Month__c
            FROM npe03__Recurring_Donation__c];

        System.assertEquals(1, resultingRDs.size(),
            'Should result in one recurring donation record');
        System.assertEquals(25.00, resultingRDs[0].npe03__Amount__c,
            'Should have the correct amount');
        System.assertEquals(Date.today(), resultingRDs[0].npe03__Date_Established__c,
            'Should have the correct date established');
        System.assertEquals('Monthly', resultingRDs[0].npe03__Installment_Period__c,
            'Should have the correct installment period');
        System.assertEquals('Open', resultingRDs[0].RecurringType__c,
            'Should have the correct recurring type');
        System.assertEquals('5', resultingRDs[0].Day_of_Month__c,
            'Should have the correct day of month');

        Opportunity[] resultingOpportunities =
            [SELECT Id,
                Amount,
                npe03__Recurring_Donation__c
            FROM Opportunity];
        System.assertEquals(1, resultingOpportunities.size(),
            'Should result in one opportunity record');
        System.assertEquals(resultingRDs[0].Id, resultingOpportunities[0].npe03__Recurring_Donation__c,
            'Resulting opportunity should look up to the recurring donation');
        System.assertEquals(25.00, resultingOpportunities[0].Amount,
            'Should have the correct amount');
    }

    @IsTest
    static void shouldCreate20OpportunitiesAndFail10GiftsIn1Chunk() {
        // Arrange
        DataImportBatch__c giftBatch = new DataImportBatch__c();
        insert giftBatch;

        List<DataImport__c> giftsToInsert = new List<DataImport__c>();
        giftsToInsert.addAll(buildGifts(2, BDI_DataImport_API.bdiImported, giftBatch.Id, false));
        giftsToInsert.addAll(buildGifts(20, BDI_DataImport_API.bdiDryRunValidated, giftBatch.Id, false));
        giftsToInsert.addAll(buildAuthorizedGifts(10, BDI_DataImport_API.bdiDryRunValidated, giftBatch.Id, false));
        insert giftsToInsert;

        GiftBatchForQueueable giftBatchForProcessing = new GiftBatchForQueueable(new GiftBatchId(giftBatch.Id), new GiftBatchSelector());
        giftBatchForProcessing.chunkGiftsThatCanBeProcessed();
        GiftEntryProcessorQueue processorQueue = new GiftEntryProcessorQueue(giftBatchForProcessing);
        GiftBatchServiceMock mockService = new GiftBatchServiceMock();
        processorQueue.giftBatchService = stubFor(mockService);

        // Act
        Test.startTest();
        processorQueue.execute(null);
        Test.stopTest();

        // Assert
        System.assertEquals(false, mockService.chainNextQueueableWasCalled);
        System.assertEquals(true, mockService.clearLatestJobIdFromWasCalled);
        System.assertEquals(20, [SELECT count() FROM Opportunity]);
        System.assertEquals(10, [SELECT count() FROM DataImport__c WHERE Status__c = :BDI_DataImport_API.bdiFailed]);
    }

    @IsTest
    static void shouldCreate50OpportunitiesIn1ChunkAndQueueUpNextChunk() {
        // Arrange
        DataImportBatch__c giftBatch = new DataImportBatch__c();
        insert giftBatch;

        List<DataImport__c> giftsToInsert = new List<DataImport__c>();
        giftsToInsert.addAll(buildGifts(2, BDI_DataImport_API.bdiImported, giftBatch.Id, false));
        giftsToInsert.addAll(buildGifts(75, BDI_DataImport_API.bdiDryRunValidated, giftBatch.Id, false));
        insert giftsToInsert;

        GiftBatchForQueueable giftBatchForProcessing = new GiftBatchForQueueable(new GiftBatchId(giftBatch.Id), new GiftBatchSelector());
        giftBatchForProcessing.chunkGiftsThatCanBeProcessed();
        GiftEntryProcessorQueue processorQueue = new GiftEntryProcessorQueue(giftBatchForProcessing);
        GiftBatchServiceMock mockService = new GiftBatchServiceMock();
        processorQueue.giftBatchService = stubFor(mockService);

        // Act
        Test.startTest();
        processorQueue.execute(null);
        Test.stopTest();

        // Assert
        System.assertEquals(true, mockService.chainNextQueueableWasCalled);
        System.assertEquals(false, mockService.clearLatestJobIdFromWasCalled);
        System.assertEquals(50, [SELECT count() FROM Opportunity]);
    }

    @IsTest
    static void shouldFailGiftsInChunkWhenJobIsAborted() {
        // Arrange
        DataImportBatch__c giftBatch = new DataImportBatch__c();
        insert giftBatch;

        List<DataImport__c> giftsToInsert = new List<DataImport__c>();
        giftsToInsert.addAll(buildGifts(2, BDI_DataImport_API.bdiImported, giftBatch.Id, false));
        giftsToInsert.addAll(buildGifts(75, BDI_DataImport_API.bdiDryRunValidated, giftBatch.Id, false));
        insert giftsToInsert;

        GiftBatchForQueueable giftBatchForProcessing = new GiftBatchForQueueable(new GiftBatchId(giftBatch.Id), new GiftBatchSelector());
        giftBatchForProcessing.chunkGiftsThatCanBeProcessed();
        GiftEntryProcessorQueue processorQueue = new GiftEntryProcessorQueue(giftBatchForProcessing);
        GiftBatchServiceMock mockService = new GiftBatchServiceMock();
        mockService.asyncApexJobStatus = 'ABORTED';
        processorQueue.giftBatchService = stubFor(mockService);

        // Act
        Test.startTest();
        processorQueue.execute(null);
        Test.stopTest();

        // Assert
        System.assertEquals(false, mockService.chainNextQueueableWasCalled);
        System.assertEquals(true, mockService.clearLatestJobIdFromWasCalled);
        System.assertEquals(true, mockService.failGiftsInProcessingWasCalled);
    }

    public class GiftBatchServiceMock implements StubProvider {
        public String asyncApexJobStatus = 'COMPLETED';
        public Boolean clearLatestJobIdFromWasCalled = false;
        public Boolean updateGiftBatchWithWasCalled = false;
        public Boolean chainNextQueueableWasCalled = false;
        public Boolean failGiftsInProcessingWasCalled = false;
        public GiftBatchId giftBatchId = null;

        public Object handleMethodCall(Object stubbedObject,
            String stubbedMethodName,
            Type returnType,
            List<Type> listOfParamTypes,
            List<String> listOfParamNames,
            List<Object> listOfArgs) {

            switch on (stubbedMethodName) {
                when 'updateGiftBatchWith' {
                    updateGiftBatchWithWasCalled = true;
                    giftBatchId = (GiftBatchId) listOfArgs[0];
                }
                when 'clearLatestJobIdFrom' {
                    clearLatestJobIdFromWasCalled = true;
                }
                when 'chainNextQueueable' {
                    chainNextQueueableWasCalled = true;
                }
                when 'getStatusFor' {
                    return asyncApexJobStatus;
                }
                when 'failGiftsInProcessing' {
                    failGiftsInProcessingWasCalled = true;
                }
            }
            return null;
        }
    }

    private static GiftBatchService stubFor(GiftBatchServiceMock giftBatchServiceMock) {
        return (GiftBatchService) Test.createStub(
            GiftBatchService.class,
            giftBatchServiceMock
        );
    }

    private static List<DataImport__c> buildGifts(Integer count, String status, Id giftBatchId, Boolean withDummyId) {
        List<DataImport__c> gifts = new List<DataImport__c>();
        for (Integer i = 0; i < count; i++) {
            gifts.add(new DataImport__c(
                Id = withDummyId ? UTIL_UnitTestData_TEST.mockId(DataImport__c.SObjectType) : null,
                Donation_Amount__c = 33.33,
                Donation_Date__c = Date.today(),
                Status__c = status,
                NPSP_Data_Import_Batch__c = giftBatchId,
                Contact1_LastName__c = 'Dummy Last Name',
                Donation_Donor__c = 'Contact1'
            ));
        }
        return gifts;
    }

    private static List<DataImport__c> buildAuthorizedGifts(Integer count, String status, Id giftBatchId, Boolean withDummyId) {
        List<DataImport__c> gifts = new List<DataImport__c>();
        for (Integer i = 0; i < count; i++) {
            gifts.add(new DataImport__c(
                Id = withDummyId ? UTIL_UnitTestData_TEST.mockId(DataImport__c.SObjectType) : null,
                Donation_Amount__c = 10.10,
                Donation_Date__c = Date.today(),
                Status__c = status,
                Payment_Status__c = 'AUTHORIZED',
                NPSP_Data_Import_Batch__c = giftBatchId,
                Contact1_LastName__c = 'Dummy Last Name',
                Donation_Donor__c = 'Contact1'
            ));
        }
        return gifts;
    }

}