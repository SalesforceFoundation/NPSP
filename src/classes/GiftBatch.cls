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
* @date 2021
* @description Batch entity class in NPSP.
*/

public inherited sharing class GiftBatch {

    private Id batchId;
    private DataImportBatch__c giftBatch;
    private Gifts allGifts;
    private Gifts authorizedGifts;
    private Gifts pendingGifts;
    private GiftBatchSelector giftBatchSelector {
        get {
            if (giftBatchSelector == null) {
                giftBatchSelector = new GiftBatchSelector();
            }
            return giftBatchSelector;
        }
        set;
    }

    private GiftSelector giftSelector {
        get {
            if (giftSelector == null) {
                giftSelector = new GiftSelector();
            }
            return giftSelector;
        }
        set;
    }

    private ElevateCaptureGroupService captureGroupService {
        get {
            if (captureGroupService == null) {
                captureGroupService = new ElevateCaptureGroupService();
            }
            return captureGroupService;
        }
        set;
    }

    @TestVisible
    private GiftBatch(Gifts authorizedGifts) {
        this.authorizedGifts = authorizedGifts;
    }

    public GiftBatch(Id batchId) {
        this.batchId = batchId;
        List<DataImportBatch__c> giftBatches =
            giftBatchSelector.selectGiftBatchesById(new Set<Id>{ batchId });
        if (giftBatches.size() > 0) {
            this.giftBatch = giftBatches[0];
        }
        this.authorizedGifts = authorizedGifts();
    }

    public void queueableJobId(String queueableJobId) {
        giftBatch.Queueable_Job_Id__c = queueableJobId;
    }

    public String queueableJobId() {
        String queueableJobId = giftBatch.Queueable_Job_Id__c;
        return queueableJobId;
    }

    public void captureAuthorizedGifts() {
        new ElevateCaptureGroupService().enqueuePaymentCaptureJobFor(batchId, capturableGroupIds());
        transitionAuthorizedGiftsToPendingGifts();
    }

    private Set<String> capturableGroupIds() {
        return authorizedGifts()?.capturableGroupIds();
    }

    public void failGiftsWithReason(Map<String, String> failReasonByCaptureGroupId) {
        System.debug('failGiftsWithReason');

        List<DataImport__c> giftsFailedCapture = new List<DataImport__c>();

        for (String captureGroupId : failReasonByCaptureGroupId.keySet()) {
            DataImport__c gift = allGifts().findByCaptureGroupId(captureGroupId);
            gift.Payment_Status__c = ElevateTransactionStatus.RETRYABLEERROR.name();
            gift.FailureInformation__c = failReasonByCaptureGroupId.get(captureGroupId);
            giftsFailedCapture.add(gift);
        }

        update giftsFailedCapture;
    }

    public void transitionAuthorizedGiftsToPendingGifts() {
        authorizedGifts.toPending();
        updateAuthorizedGifts();
    }

    private void updateAuthorizedGifts() {
        update authorizedGifts().dataImports();
    }

    private void updatePendingGifts() {
        update pendingGifts().dataImports();
    }

    private Gifts authorizedGifts() {
        if (authorizedGifts != null) {
            return authorizedGifts;
        }
        return new Gifts(giftSelector.getAuthorizedGiftsFor(this.batchId));
    }

    private Gifts pendingGifts() {
        if (pendingGifts != null) {
            return pendingGifts;
        }
        return new Gifts(giftSelector.getPendingGiftsFor(this.batchId));
    }

    private Gifts allGifts() {
        if (allGifts != null) {
            return allGifts;
        }
        return new Gifts(giftSelector.getGiftsFor(this.batchId));
    }
}