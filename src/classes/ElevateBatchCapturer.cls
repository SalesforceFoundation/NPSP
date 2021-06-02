/*
    Copyright (c) 2020, Salesforce.org
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
* @date 2021
* @group Gift Entry
* @group-content
* @description Makes the callout to the Elevate endpoint for capturing
* payments in Elevate Batches.
*/
public without sharing class ElevateBatchCapturer implements Queueable, Database.AllowsCallouts {

    private Id giftBatchId;
    @TestVisible private queueableElevateBatches queueableElevateBatches;
    @TestVisible private Map<String, String> failReasonByElevateBatchId = new Map<String, String>();
    @TestVisible private GiftBatchService giftBatchService = new GiftBatchService();
    @TestVisible private ElevateBatchService elevateBatchService = new ElevateBatchService();

    public ElevateBatchCapturer(Id batchId, Set<String> elevateBatchIds) {
        this.giftBatchId = batchId;
        queueableElevateBatches = new queueableElevateBatches(elevateBatchIds);
    }

    public ElevateBatchCapturer(Id batchId, queueableElevateBatches queueableElevateBatches) {
        this.giftBatchId = batchId;
        this.queueableElevateBatches = queueableElevateBatches;
    }

    public void execute(QueueableContext context) {
        elevateBatches();
        if (hasGiftsThatFailedCapture()) {
            updatePendingGiftsWithFailure();
        }
        chainNextJob();
    }

    private void elevateBatches() {
        for (String elevateBatchId : queueableElevateBatches.idsToCapture()) {
            ElevateBatchResponse response = elevateBatchService.capture(elevateBatchId);
            handleCaptureResponseFrom(elevateBatchId, response);
        }
    }

    private void handleCaptureResponseFrom(String elevateBatchId, ElevateBatchResponse captureResponse) {
        if (captureResponse.isValidCaptureResponse() == false) {
            failReasonByElevateBatchId.put(elevateBatchId, captureResponse.firstError());
        }
    }

    private Boolean hasGiftsThatFailedCapture() {
        return failReasonByElevateBatchId.keySet().size() > 0;
    }

    private void updatePendingGiftsWithFailure() {
        giftBatchService.giftsFailedCaptureFor(giftBatchId, failReasonByElevateBatchId);
    }

    private void chainNextJob() {
        if (queueableElevateBatches.hasGroupsToCapture()) {
            ElevateBatchCapturer capturer =
                new ElevateBatchCapturer(giftBatchId, queueableElevateBatches);
            if (!Test.isRunningTest()) { System.enqueueJob(capturer); }
        }
    }

    private class queueableElevateBatches {
        private List<String> elevateBatchIds;
        private List<List<String>> partitionedElevateBatchIds;
        private final Integer MAX_COUNT = 50;
        private Integer currentPartitionIndex = 0;

        public queueableElevateBatches(Set<String> elevateBatchIds) {
            this.elevateBatchIds = new List<String>();
            this.elevateBatchIds.addAll(elevateBatchIds);
            partitionedElevateBatchIds = partitionElevateBatchIds(this.elevateBatchIds);
        }

        public List<String> idsToCapture() {
            List<String> currentIdsToCapture = partitionedElevateBatchIds[currentPartitionIndex];
            currentPartitionIndex++;
            return currentIdsToCapture;
        }

        public Integer partitionSize() {
            return partitionedElevateBatchIds.size();
        }

        public Integer currentPartitionIndex() {
            return currentPartitionIndex;
        }

        public Boolean hasGroupsToCapture() {
            return partitionSize() > currentPartitionIndex();
        }

        private List<List<String>> partitionElevateBatchIds(List<String> elevateBatchIds) {
            List<List<String>> partitionedElevateBatchIds = new List<List<String>>();
            List<String> currentList = new List<String>();
            Integer currentCount = 0;

            for (Integer i = 0; i < elevateBatchIds.size(); i++) {
                currentList.add(elevateBatchIds[i]);
                currentCount++;

                Boolean isAtPartitionLimit = currentCount == MAX_COUNT;
                Boolean isLastIdToAdd = (i == elevateBatchIds.size() - 1 && currentList.size() > 0);

                if (isAtPartitionLimit || isLastIdToAdd) {
                    partitionedElevateBatchIds.add(currentList);
                    currentCount = 0;
                    currentList = new List<String>();
                }
            }

            return partitionedElevateBatchIds;
        }
    }
}
