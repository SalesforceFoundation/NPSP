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
* @description GiftsSelectorForProcessing test class
*/
@IsTest
private class GiftsSelectorForProcessing_TEST {

    @IsTest
    static void shouldReturn10GiftsThatCanBeMovedToProcessingStatus() {
        // Arrange
        DataImportBatch__c giftBatch = new DataImportBatch__c();
        insert giftBatch;

        List<DataImport__c> giftsToInsert = new List<DataImport__c>();
        // These gifts can not move into the processing status
        giftsToInsert.addAll(buildGifts(5, BDI_DataImport_API.bdiImported, giftBatch.Id));
        giftsToInsert.addAll(buildGifts(4, BDI_DataImport_API.bdiProcessing, giftBatch.Id));

        // These gifts can move into the processing status
        giftsToInsert.addAll(buildGifts(10, BDI_DataImport_API.bdiDryRunValidated, giftBatch.Id));
        insert giftsToInsert;

        List<Id> giftIds = getIdsFrom(giftsToInsert);

        // Act
        GiftsSelectorForProcessing giftsSelector = new GiftsSelectorForProcessing();
        GiftBatchId giftBatchId = new GiftBatchId(giftBatch.Id);
        List<DataImport__c> readyToMoveToProcessing = giftsSelector.getGiftsReadyToMoveToProcessing(giftBatchId);

        // Assert
        System.assertEquals(10, readyToMoveToProcessing.size(),
            'Should return a count of 10 for dry-ran validated gifts that can move into processing status');
    }

    @IsTest
    static void shouldReturn3GiftsThatCanBeMovedToProcessingStatus() {
        // Arrange
        DataImportBatch__c giftBatch = new DataImportBatch__c();
        insert giftBatch;

        List<DataImport__c> giftsToInsert = new List<DataImport__c>();
        // These gifts can not move into the processing status
        giftsToInsert.addAll(buildGifts(5, BDI_DataImport_API.bdiImported, giftBatch.Id));
        giftsToInsert.addAll(buildGifts(4, BDI_DataImport_API.bdiProcessing, giftBatch.Id));

        // These gifts can move into the processing status
        giftsToInsert.addAll(buildGifts(3, BDI_DataImport_API.bdiDryRunValidated, giftBatch.Id));
        insert giftsToInsert;

        List<Id> giftIds = getIdsFrom(giftsToInsert);

        // Act
        GiftsSelectorForProcessing giftsSelector = new GiftsSelectorForProcessing();
        GiftBatchId giftBatchId = new GiftBatchId(giftBatch.Id);
        List<DataImport__c> readyToMoveToProcessing = giftsSelector.getGiftsReadyToMoveToProcessing(giftIds, 50);

        // Assert
        System.assertEquals(3, readyToMoveToProcessing.size(),
            'Should return a count of 3 for dry-ran validated gifts that can move into processing status');
    }


    private static List<Id> getIdsFrom(List<DataImport__c> gifts) {
        List<Id> ids = new List<Id>();
        for (DataImport__c gift : gifts) {
            ids.add(gift.Id);
        }
        return ids;
    }

    private static List<DataImport__c> buildGifts(Integer count, String status, Id giftBatchId) {
        List<DataImport__c> gifts = new List<DataImport__c>();
        for (Integer i = 0; i < count; i++) {
            gifts.add(new DataImport__c(
                Donation_Amount__c = 33.33,
                Status__c = status,
                NPSP_Data_Import_Batch__c = giftBatchId
            ));
        }
        return gifts;
    }
}
