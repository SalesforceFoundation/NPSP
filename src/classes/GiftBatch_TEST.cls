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
    @isTest static void shouldUpdateGiftRecordsFromAuthorizedToPaymentProcessingStatus() {
        final Integer numberOfGifts = 10;
        Gifts authorizedGifts = new Gifts(buildAuthorizedGifts(numberOfGifts));
        GiftBatch giftBatch = new GiftBatch(authorizedGifts);
        ElevateCaptureGroupServiceMock captureGroupServiceMock = new ElevateCaptureGroupServiceMock();

        System.assert(authorizedGifts.giftsToUpdate.size() == 0);

        giftBatch.captureGroupService = stubFor(captureGroupServiceMock);
        giftBatch.captureAuthorizedGifts();

        System.assert(captureGroupServiceMock.enqueuePaymentCaptureJobForCalled);
        System.assert(authorizedGifts.giftsToUpdate.size() == numberOfGifts);
        for (DataImport__c gift : authorizedGifts.giftsToUpdate) {
            System.assertEquals(ElevateTransactionStatus.PAYMENTPROCESSING.name(), gift.Payment_Status__c);
        }
    }

    @isTest static void shouldUpdateGiftRecordsWithFailReason() {
        final Integer numberOfGifts = 5;
        Gifts authorizedGifts = new Gifts(buildAuthorizedGifts(numberOfGifts));
        GiftBatch giftBatch = new GiftBatch(authorizedGifts);
        ElevateCaptureGroupServiceMock captureGroupServiceMock = new ElevateCaptureGroupServiceMock();

        System.assert(authorizedGifts.giftsToUpdate.size() == 0);

        giftBatch.captureGroupService = stubFor(captureGroupServiceMock);
        giftBatch.failGiftsWithReason(buildFailReasonByCaptureGroupId(numberOfGifts));

        System.assert(authorizedGifts.giftsToUpdate.size() == numberOfGifts);
        for (DataImport__c gift : authorizedGifts.giftsToUpdate) {
            System.assertEquals(ElevateTransactionStatus.RETRYABLEERROR.name(), gift.Payment_Status__c);
            System.assertEquals('DUMMY FAIL REASON', gift.FailureInformation__c);
        }
    }

    public class ElevateCaptureGroupServiceMock implements StubProvider {
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

    private static ElevateCaptureGroupService stubFor(ElevateCaptureGroupServiceMock captureGroupServiceMock) {
        return (ElevateCaptureGroupService) Test.createStub(
            ElevateCaptureGroupService.class,
            captureGroupServiceMock
        );
    }

    private static List<DataImport__c> buildAuthorizedGifts(Integer numberOfGifts) {
        List<DataImport__c> dummyAuthorizedGifts = new List<DataImport__c>();
        for (Integer i = 0; i < numberOfGifts; i++) {
            DataImport__c dummyGift = new DataImport__c(
                Status__c = null,
                NPSP_Data_Import_Batch__c = UTIL_UnitTestData_TEST.mockId(DataImportBatch__c.getSObjectType()),
                Account1_Name__c = 'DUMMY ACCOUNT ' +  i,
                Donation_Amount__c = 1,
                Donation_Date__c = Date.today(),
                Donation_Donor__c = 'Account1',
                Payment_Status__c = ElevateTransactionStatus.AUTHORIZED.name(),
                Payment_Elevate_Batch_ID__c = 'DUMMY_ELEVATE_BATCH_ID_' + i
            );
            dummyAuthorizedGifts.add(dummyGift);
        }
        return dummyAuthorizedGifts;
    }

    private static Map<String, String> buildFailReasonByCaptureGroupId(Integer numberOfGifts) {
        Map<String, String> failReasonByCaptureGroupId = new Map<String, String>();
        for (Integer i = 0; i < numberOfGifts; i++) {
            failReasonByCaptureGroupId.put('DUMMY_ELEVATE_BATCH_ID_' + i, 'DUMMY FAIL REASON');
        }
        return failReasonByCaptureGroupId;
    }
}