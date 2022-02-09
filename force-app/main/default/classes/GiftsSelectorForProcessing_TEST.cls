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
    static void shouldReturn3GiftsThatCanBeMovedToProcessingStatus() {
        // Arrange
        DataImportBatch__c giftBatch = new DataImportBatch__c();
        insert giftBatch;

        List<DataImport__c> giftsToInsert = new List<DataImport__c>();
        giftsToInsert.addAll(buildGifts(5, BDI_DataImport_API.bdiImported, giftBatch.Id));
        giftsToInsert.addAll(buildGifts(4, BDI_DataImport_API.bdiProcessing, giftBatch.Id));
        giftsToInsert.addAll(buildGifts(3, BDI_DataImport_API.bdiDryRunValidated, giftBatch.Id));
        insert giftsToInsert;

        // Act
        GiftsSelectorForProcessing giftsSelector = new GiftsSelectorForProcessing();
        GiftBatchId giftBatchId = new GiftBatchId(giftBatch.Id);
        List<DataImport__c> readyToMoveToProcessing = giftsSelector.getGiftsReadyToMoveToProcessing(giftBatchId);
        Integer readyToMoveToProcessingCount = giftsSelector.getGiftsReadyToMoveToProcessingCount(giftBatchId);

        // Assert
        System.assertEquals(3, readyToMoveToProcessing.size(),
            'Should return a count of 3 for dry-ran validated gifts that can move into processing status');
        System.assertEquals(3, readyToMoveToProcessingCount,
            'Should return a count of 3 for dry-ran validated gifts that can move into processing status');
    }

    @IsTest
    static void shouldReturn9ProcessableGifts() {
        // Arrange
        DataImportBatch__c giftBatch = new DataImportBatch__c();
        insert giftBatch;

        List<DataImport__c> giftsToInsert = new List<DataImport__c>();
        giftsToInsert.addAll(buildGifts(5, BDI_DataImport_API.bdiImported, giftBatch.Id));
        giftsToInsert.addAll(buildGifts(4, BDI_DataImport_API.bdiProcessing, giftBatch.Id));
        giftsToInsert.addAll(buildGifts(3, BDI_DataImport_API.bdiDryRunValidated, giftBatch.Id));
        giftsToInsert.addAll(buildGifts(2, BDI_DataImport_API.bdiFailed, giftBatch.Id));
        insert giftsToInsert;

        // Act
        GiftsSelectorForProcessing giftsSelector = new GiftsSelectorForProcessing();
        GiftBatchId giftBatchId = new GiftBatchId(giftBatch.Id);
        List<DataImport__c> processableGifts = giftsSelector.getProcessableGiftsFor(giftBatchId);
        Integer processableGiftsCount = giftsSelector.getProcessableGiftsCount(giftBatchId);

        // Assert
        System.assertEquals(9, processableGifts.size(),
            'Should return a count of 9 for gifts that can be processed');
        System.assertEquals(9, processableGiftsCount,
            'Should return a count of 9 for gifts that can be processed');
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
