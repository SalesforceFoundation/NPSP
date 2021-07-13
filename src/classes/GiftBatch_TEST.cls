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
        for (DataImport__c gift : authorizedGifts.giftsToUpdate) {
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
        for (DataImport__c gift : authorizedGifts.giftsToUpdate) {
            System.assertEquals(ElevateTransactionStatus.RETRYABLEERROR.name(), gift.Payment_Status__c);
            System.assertEquals('DUMMY FAIL REASON', gift.FailureInformation__c);
        }
    }

    @isTest
    static void shouldReturnTotalRowAmount() {
        GiftBatch giftBatch = new GiftBatch();
        giftBatch.typedModel = (BGE_DataImportBatchEntry_CTRL.DataImportModel)
            JSON.deserialize(DUMMY_DATA_IMPORT_MODEL,
                BGE_DataImportBatchEntry_CTRL.DataImportModel.class);

        System.assertEquals(300, giftBatch.total().amount());
    }

    @isTest
    static void shouldReturnTotalRowCount() {
        GiftBatch giftBatch = new GiftBatch();
        giftBatch.typedModel = (BGE_DataImportBatchEntry_CTRL.DataImportModel)
            JSON.deserialize(DUMMY_DATA_IMPORT_MODEL,
                BGE_DataImportBatchEntry_CTRL.DataImportModel.class);

        System.assertEquals(2, giftBatch.totalCount());
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

    static String DUMMY_DATA_IMPORT_MODEL = '{"totalRowAmount":300.0,"totalCountOfRows":2}';

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
        return (ElevateBatchService) Test.createStub(
            ElevateBatchService.class,
            elevateBatchServiceMock
        );
    }

    private static List<DataImport__c> buildGifts(Integer numberOfGifts, String paymentStatus) {
        List<DataImport__c> dummyAuthorizedGifts = new List<DataImport__c>();
        for (Integer i = 0; i < numberOfGifts; i++) {
            DataImport__c dummyGift = new DataImport__c(
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