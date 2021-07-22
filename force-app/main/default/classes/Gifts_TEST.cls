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
private class Gifts_TEST {
    @isTest static void shouldReturnCorrectNumberOfGiftCounts() {
        List<DataImport__c> dummyGifts = buildGifts(20, null, null);
        List<DataImport__c> dummyAuthorizedGiftsGroup1 = buildGifts(
            10, ElevateTransactionStatus.AUTHORIZED.name(), 'DUMMY_ELEVATE_ID_1');
        List<DataImport__c> dummyAuthorizedGiftsGroup2 = buildGifts(
            5, ElevateTransactionStatus.AUTHORIZED.name(), 'DUMMY_ELEVATE_ID_2');
        dummyGifts.addAll(dummyAuthorizedGiftsGroup1);
        dummyGifts.addAll(dummyAuthorizedGiftsGroup2);

        Gifts gifts = new Gifts(dummyGifts);
        System.assertEquals(dummyGifts.size(), gifts.dataImports?.size());
        System.assertEquals(2, gifts.elevateBatchIds()?.size());
    }

    @isTest static void shouldReturnCorrectNumberOfAuthorizedToPaymentProcessingGifts() {
        List<DataImport__c> dummyAuthorizedGifts = buildGifts(
            10, ElevateTransactionStatus.AUTHORIZED.name(), 'DUMMY_ELEVATE_ID_1');

        Gifts gifts = new Gifts(dummyAuthorizedGifts);
        gifts.authorizedToPaymentProcessingStatus();

        System.assertEquals(10, gifts.giftsToUpdate.size());
        for (DataImport__c gift : gifts.giftsToUpdate) {
            System.assertEquals(ElevateTransactionStatus.PAYMENTPROCESSING.name(), gift.Payment_Status__c);
        }
    }

    @isTest static void shouldReturnCorrectNumberOfGiftsWithFailReason() {
        final Integer numberOfFailedGifts = 15;
        final String elevateBatchId = 'DUMMY_ELEVATE_ID_1';

        List<DataImport__c> dummyAuthorizedGifts = buildGifts(
            numberOfFailedGifts, ElevateTransactionStatus.AUTHORIZED.name(), elevateBatchId);

        Gifts gifts = new Gifts(dummyAuthorizedGifts);
        gifts.failGiftsByElevateBatchIdWithReason(buildFailReasonByElevateBatchId(numberOfFailedGifts, elevateBatchId));

        System.assertEquals(numberOfFailedGifts, gifts.giftsToUpdate.size());
        for (DataImport__c gift : gifts.giftsToUpdate) {
            System.assertEquals(ElevateTransactionStatus.RETRYABLEERROR.name(), gift.Payment_Status__c);
            System.assertEquals('DUMMY FAIL REASON', gift.FailureInformation__c);
        }
    }

    private static List<DataImport__c> buildGifts(
        Integer numberOfGifts,
        String paymentStatus,
        String elevateBatchId) {

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
                Payment_Elevate_Batch_ID__c = elevateBatchId
            );
            dummyAuthorizedGifts.add(dummyGift);
        }
        return dummyAuthorizedGifts;
    }

    private static Map<String, String> buildFailReasonByElevateBatchId(Integer numberOfGifts, String elevateBatchId) {
        Map<String, String> failReasonByElevateBatchId = new Map<String, String>();
        for (Integer i = 0; i < numberOfGifts; i++) {
            failReasonByElevateBatchId.put(elevateBatchId, 'DUMMY FAIL REASON');
        }
        return failReasonByElevateBatchId;
    }
}