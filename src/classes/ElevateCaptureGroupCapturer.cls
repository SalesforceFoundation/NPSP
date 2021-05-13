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
public without sharing class ElevateCaptureGroupCapturer implements Finalizer, Queueable {

    private NPSP_Batch giftBatch;
    private QueueableCaptureGroup queueableCaptureGroup;
    private List<ElevateCaptureGroupResponse> captureGroupResponses;

    public ElevateCaptureGroupCapturer(NPSP_Batch giftBatch) {
        System.debug('in qeueable constructor');
        this.giftBatch = giftBatch;
        queueableCaptureGroup = new QueueableCaptureGroup(giftBatch.capturableGroupIds());
    }

    public ElevateCaptureGroupCapturer(QueueableCaptureGroup queueableCaptureGroup, NPSP_Batch giftBatch) {
        this.giftBatch = giftBatch;
        this.queueableCaptureGroup = queueableCaptureGroup;
    }

    public void execute(QueueableContext context) {
        System.debug('in queueable execute method... current paritition index: ' + queueableCaptureGroup.currentPartitionIndex());
        System.attachFinalizer(this);
        giftBatch.queueableJobId(context.getJobId());
        System.debug('Gift Job Id: ' + giftBatch.queueableJobId());

        for (String captureGroupId : queueableCaptureGroup.idsToCapture()) {
            // TODO: make the callout
            System.debug(captureGroupId);
            // TODO: if callout succeeds
            // Apply success values to gift in memory

            // TODO: if callout fails
            // Apply fail and fail reason values to gift in memory

            giftBatch.giftIsNowProcessing(captureGroupId);
        }

        if (queueableCaptureGroup.shouldChainNextJob()) {
            System.debug('enqueuing child job');
            System.enqueueJob(new ElevateCaptureGroupCapturer(queueableCaptureGroup, giftBatch));
        }

        // TODO: Perform dml to persist success / fail info to gifts
        giftBatch.updateMembers();
    }

    public void execute(FinalizerContext context) {
        System.debug('in finalizer execute method...');
    }

    // private HttpRequest captureRequest(String groupId) {
    //     return new PS_Request.Builder()
    //         .withMethod(UTIL_Http.Method.POST)
    //         .withCaptureGroupId(groupId)
    //         .withEndpoint(PS_Request.ElevateEndpoint.CHARGE_CAPTURE_GROUP)
    //         .build();
    // }

    private class QueueableCaptureGroup {
        private List<String> captureGroupIds;
        private List<List<String>> partitionedGroupIds;
        private final Integer MAX_COUNT = 50;
        private Integer currentPartitionIndex = 0;

        public QueueableCaptureGroup(List<String> captureGroupIds) {
            this.captureGroupIds = captureGroupIds;
            partitionedGroupIds = subdivide(captureGroupIds);
        }

        public List<String> idsToCapture() {
            List<String> groupIds = partitionedGroupIds[currentPartitionIndex];
            currentPartitionIndex++;
            return groupIds;
        }

        public Integer partitionSize() {
            return partitionedGroupIds.size();
        }

        public Integer currentPartitionIndex() {
            return currentPartitionIndex;
        }

        public Boolean shouldChainNextJob() {
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
