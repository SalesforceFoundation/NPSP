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
* @date 2022
* @description Gift Batch entity used when processing batches through BDI
*/
public inherited sharing class GiftBatchForQueueable {

    private final Integer CHUNK_LIMIT = 50;

    private GiftBatchId giftBatchId;

    private Boolean shouldPayFirstInstallment;

    private GiftBatch giftBatch;

    @TestVisible
    private Gifts gifts;
    @TestVisible
    private List<List<Id>> chunkedIds = new List<List<Id>>();
    @TestVisible
    private GiftsSelectorForProcessing giftsSelector {
        get {
            if (giftsSelector == null) {
                return new GiftsSelectorForProcessing();
            }
            return giftsSelector;
        }
        set;
    }

    @TestVisible
    private GiftBatchSelector giftBatchSelector {
        get {
            if (giftBatchSelector == null) {
                giftBatchSelector = new GiftBatchSelector();
            }
            return giftBatchSelector;
        }
        set;
    }

    @TestVisible
    private Data_Import_Settings__c dataImportSettings {
        get {
            if (dataImportSettings == null) {
                return BDI_DataImportService.loadSettings(giftBatchId.value());
            }
            return dataImportSettings;
        }
        set;
    }
    @TestVisible
    private ElevateBatchService elevateBatchService {
        get {
            if (elevateBatchService == null) {
                elevateBatchService = new ElevateBatchService();
            }
            return elevateBatchService;
        }
        set;
    }
    @TestVisible
    private PS_IntegrationServiceConfig paymentIntegrationServiceConfig {
        get {
            if (paymentIntegrationServiceConfig == null) {
                paymentIntegrationServiceConfig = new PS_IntegrationServiceConfig();
            }
            return paymentIntegrationServiceConfig;
        }
        set;
    }


    @TestVisible
    private GiftBatchService giftBatchService {
        get {
            if (giftBatchService == null) {
                return new GiftBatchService();
            }
            return giftBatchService;
        }
        set;
    }

    public GiftBatchForQueueable(GiftBatchId giftBatchId, GiftBatchSelector giftBatchSelector) {
        this.giftBatchId = giftBatchId;
        this.giftBatchSelector = giftBatchSelector;
        this.giftBatch = new GiftBatch(giftBatchSelector.selectGiftBatchBy(giftBatchId));
    }

    public GiftBatchId id() {
        return giftBatchId;
    }

    public Boolean hasChunksToProcess() {
        return chunkedIds.size() > 0;
    }

    public void prepareChunk() {
        List<Id> giftIdsToSelect = chunkedIds.get(0);
        gifts = new Gifts(giftsSelector.getGiftsReadyToMoveToProcessing(giftIdsToSelect, CHUNK_LIMIT));
        gifts.moveProcessableToProcessingStatus();
        giftBatchService.disableRD2AsynchronousProcesses();
    }

    public void preprocessRecurringGifts() {
        gifts.preprocessRecurringGifts(this.giftBatch.shouldPayFirstInstallment());
    }

    public void captureElevateBatches() {
        if (paymentIntegrationServiceConfig.isIntegrationEnabled()) {
            elevateBatchService.enqueuePaymentCaptureJobFor(id().value(), gifts?.elevateBatchIds());
            gifts.authorizedToPaymentProcessingStatus();
        }
    }

    public void updateGiftsInChunk() {
        gifts.updateRecords();
    }

    public void processChunk() {
        List<DataImport__c> dataImports = gifts.asDataImports();
        BDI_DataImport_API.processDataImportRecords(dataImportSettings, dataImports, false);
        chunkedIds.remove(0);
    }

    public void chunkGiftsThatCanBeProcessed() {
        List<SObject> results = giftsSelector.getGiftsReadyToMoveToProcessing(giftBatchId);
        if (results.size() > 0) {
            Set<Id> giftIds = (new Map<Id,SObject>(results)).keySet();
            mapIdsByChunk(new List<Id> (giftIds));
        }
    }

    private void mapIdsByChunk(List<Id> giftIds) {
        chunkedIds = new List<List<Id>>();
        List<Id> currentChunk = new List<Id>();
        for (Integer i = 0; i < giftIds.size(); i++) {
            Id giftId = giftIds[i];
            currentChunk.add(giftId);

            Boolean isChunkFull = currentChunk.size() == CHUNK_LIMIT;
            Boolean isLastItem = (i == giftIds.size() - 1);

            if (isChunkFull || isLastItem) {
                chunkedIds.add(currentChunk);
                currentChunk = new List<Id>();
            }
        }
    }
}
