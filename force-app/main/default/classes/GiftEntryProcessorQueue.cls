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
* @description Processor Queue for all gifts entered and processed through the Gift Entry App.
*/

public with sharing class GiftEntryProcessorQueue implements Queueable, Database.AllowsCallouts {

    private final String ABORTED = 'ABORTED';
    private GiftBatchForQueueable queueableGiftBatch;
    private AsyncApexJobId queueableId;
    private GiftBatchId giftBatchId;

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

    public GiftEntryProcessorQueue(GiftBatchForQueueable giftBatchForProcessing) {
        this.queueableGiftBatch = giftBatchForProcessing;
        this.giftBatchId = giftBatchForProcessing.id();
    }

    public void execute(QueueableContext queueableContext) {
        attachFinalizer();
        queueableId(queueableContext);
        updateGiftBatchWithQueueableId();

        if (queueableGiftBatch.hasChunksToProcess()) {
            queueableGiftBatch.prepareChunk();
            queueableGiftBatch.captureElevateBatches();
            queueableGiftBatch.updateGiftsInChunk();
            queueableGiftBatch.preprocessRecurringGifts();
            queueableGiftBatch.processChunk(giftBatchId.value());
        } else {
            BDI_DataImport_BATCH batch = new BDI_DataImport_BATCH(giftBatchId.value(), false);
            String jobId = Database.executeBatch(batch, Integer.valueOf(batch.diSettings.Batch_Size__c));
        }

        if (queueableGiftBatch.hasChunksToProcess()) {
            chainNextQueueable();
        } else {
            giftBatchService.clearLatestJobIdFrom(queueableGiftBatch.id());
        }
    }

    private void attachFinalizer() {
        if (!Test.isRunningTest()) {
            GiftEntryProcessorQueueFinalizer finalizer =
                new GiftEntryProcessorQueueFinalizer(queueableGiftBatch.id());
            System.attachFinalizer(finalizer);
        }
    }

    private void queueableId(QueueableContext queueableContext) {
        if (Test.isRunningTest()) {
            queueableId = new AsyncApexJobId(UTIL_UnitTestData_TEST.mockId(AsyncApexJob.SObjectType));
        } else {
            queueableId = new AsyncApexJobId(queueableContext.getJobId());
        }
    }

    private void updateGiftBatchWithQueueableId() {
        giftBatchService.updateGiftBatchWith(queueableGiftBatch.id(), queueableId);
    }

    private void chainNextQueueable() {
        if (hasJobBeenAborted()) {
            giftBatchService.failGiftsInProcessing(queueableGiftBatch.id());
            giftBatchService.clearLatestJobIdFrom(queueableGiftBatch.id());
        } else {
            giftBatchService.chainNextQueueable(queueableGiftBatch);
        }
    }

    private Boolean hasJobBeenAborted() {
        String status = giftBatchService.getStatusFor(queueableId);
        return status == ABORTED;
    }
}
