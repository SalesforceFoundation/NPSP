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
public without sharing class ElevateCaptureGroupCapturer implements Queueable, Database.AllowsCallouts {

    private Id batchId;
    private QueueableCaptureGroups queueableCaptureGroups;
    private Map<String, String> failReasonByCaptureGroupId = new Map<String, String>();
    private ElevateCaptureGroupService captureGroupService = new ElevateCaptureGroupService();

    public ElevateCaptureGroupCapturer(Id batchId, Set<String> capturableGroupIds) {
        System.debug('queueable constructor...');
        this.batchId = batchId;
        queueableCaptureGroups = new QueueableCaptureGroups(capturableGroupIds);
    }

    public ElevateCaptureGroupCapturer(Id batchId, QueueableCaptureGroups queueableCaptureGroups) {
        System.debug('queueable child execute...');
        this.batchId = batchId;
        this.queueableCaptureGroups = queueableCaptureGroups;
    }

    public void execute(QueueableContext context) {
        System.debug('queueable execute...');
        captureGroups();
        if (hasGiftsThatFailedCapture()) {
            updatePendingGiftsWithFailure();
        }
        chainNextJob();
    }

    private void captureGroups() {
        for (String captureGroupId : queueableCaptureGroups.idsToCapture()) {
            ElevateCaptureGroupResponse response = captureGroupService.capture(captureGroupId);
            handleCaptureResponseFrom(captureGroupId, response);
        }
    }

    private void handleCaptureResponseFrom(String captureGroupId, ElevateCaptureGroupResponse captureResponse) {
        if (captureResponse.isValidCaptureResponse() == false) {
            failReasonByCaptureGroupId.put(captureGroupId, captureResponse.firstError());
        }
    }

    private Boolean hasGiftsThatFailedCapture() {
        return failReasonByCaptureGroupId.keySet().size() > 0;
    }

    private void updatePendingGiftsWithFailure() {
        GiftBatchService giftBatchService = new GiftBatchService();
        giftBatchService.giftsFailedCaptureFor(batchId, failReasonByCaptureGroupId);
    }

    private void chainNextJob() {
        if (queueableCaptureGroups.hasGroupsToCapture()) {
            ElevateCaptureGroupCapturer capturer =
                new ElevateCaptureGroupCapturer(batchId, queueableCaptureGroups);
            System.enqueueJob(capturer);
        }
    }

    private class QueueableCaptureGroups {
        private List<String> captureGroupIds;
        private List<List<String>> partitionedGroupIds;
        private final Integer MAX_COUNT = 50;
        private Integer currentPartitionIndex = 0;

        public QueueableCaptureGroups(Set<String> captureGroupIds) {
            System.debug('QueueableCaptureGroups constructor with set...');
            this.captureGroupIds = new List<String>();
            this.captureGroupIds.addAll(captureGroupIds);
            partitionedGroupIds = subdivide(this.captureGroupIds);
        }

        public List<String> idsToCapture() {
            List<String> currentIdsToCapture = partitionedGroupIds[currentPartitionIndex];
            currentPartitionIndex++;
            return currentIdsToCapture;
        }

        public Integer partitionSize() {
            return partitionedGroupIds.size();
        }

        public Integer currentPartitionIndex() {
            return currentPartitionIndex;
        }

        public Boolean hasGroupsToCapture() {
            return partitionSize() > currentPartitionIndex();
        }

        private List<List<String>> subdivide(List<String> captureGroupIds) {
            Integer containingListSize = captureGroupIds.size() / MAX_COUNT;
            if (Math.mod(captureGroupIds.size(), MAX_COUNT) > 0) {
                containingListSize++;
            }
            System.debug(containingListSize);
            List<List<String>> subdividedList = new List<List<String>>();
            List<String> currentList = new List<String>();
            Integer currentCount = 0;

            for (Integer i = 0; i < captureGroupIds.size(); i++) {
                System.debug('Loop iteration: ' + i);
                currentList.add(captureGroupIds[i]);

                currentCount++;
                if (currentCount == MAX_COUNT || (i == captureGroupIds.size() - 1 && currentList.size() > 0)) {
                    subdividedList.add(currentList);
                    System.debug(currentList);
                    currentCount = 0;
                    currentList = new List<String>();
                }
            }

            return subdividedList;
        }
    }
}
