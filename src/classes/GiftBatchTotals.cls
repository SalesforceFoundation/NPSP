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
* @description Value object for Gift Batch Totals
*/
public inherited sharing class GiftBatchTotals {
    private Integer totalGifts = 0;
    private Integer processedGifts = 0;
    private Integer failedPayments = 0;
    private Integer failedGifts = 0;
    private Integer expiredPayments = 0;
    private Integer authorizedPayments = 0;
    private Integer processingGifts = 0;

    public GiftBatchTotals() {}

    public GiftBatchTotals(List<AggregateResultProxy> results) {
        for (AggregateResultProxy result : results) {
            GiftBatchStatusGroup statusGroup = new GiftBatchStatusGroup(result);
            addToTotalGiftsCountFor(statusGroup);
            countProcessedGiftsFor(statusGroup);
            addToFailedGiftsCountFor(statusGroup);
            addToExpiredPaymentGiftsCountFor(statusGroup);
            addToAuthorizedPaymentGiftsCountFor(statusGroup);
            addToProcessingGiftsCountFor(statusGroup);
        }
    }

    public Map<String, Integer> toMap() {
        return new Map<String, Integer> {
            GiftBatchAggregateGroupName.TOTAL.name() => this.totalGifts,
            GiftBatchAggregateGroupName.PROCESSED.name() => this.processedGifts,
            GiftBatchAggregateGroupName.FAILED.name()=> this.failedGifts,
            GiftBatchAggregateGroupName.FAILED_PAYMENT.name() => this.failedPayments,
            GiftBatchAggregateGroupName.EXPIRED_PAYMENT.name() => this.expiredPayments,
            GiftBatchAggregateGroupName.AUTHORIZED_PAYMENT.name() => this.authorizedPayments,
            GiftBatchAggregateGroupName.PROCESSING.name() => this.processingGifts
        };
    }

    private void addToFailedGiftsCountFor(GiftBatchStatusGroup statusGroup) {
        if (statusGroup.isPaymentFailed()) {
            failedPayments += statusGroup.recordCount();
            failedGifts += statusGroup.recordCount();
        } else if (statusGroup.isProcessingFailed()) {
            failedGifts += statusGroup.recordCount();
        }
    }

    private void addToTotalGiftsCountFor(GiftBatchStatusGroup statusGroup) {
        totalGifts += statusGroup.recordCount();
    }

    private void countProcessedGiftsFor(GiftBatchStatusGroup statusGroup) {
        if (statusGroup.isImported()) {
            processedGifts += statusGroup.recordCount();
        }
    }

    private void addToExpiredPaymentGiftsCountFor(GiftBatchStatusGroup statusGroup) {
        if (statusGroup.isPaymentAuthorizationExpired()) {
            expiredPayments += statusGroup.recordCount();
        }
    }

    private void addToAuthorizedPaymentGiftsCountFor(GiftBatchStatusGroup statusGroup) {
        if (statusGroup.isPaymentAuthorized()) {
            authorizedPayments += statusGroup.recordCount();
        }
    }

    private void addToProcessingGiftsCountFor(GiftBatchStatusGroup statusGroup) {
        if (statusGroup.isProcessing()) {
             processingGifts += statusGroup.recordCount();
        }
    }
}