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

public inherited sharing class GiftBatch implements IGiftBatch {

    @TestVisible private GiftBatchId giftBatchId;
    @TestVisible private DataImportBatch__c batch;
    @TestVisible private Money total;
    @TestVisible private Integer totalCount;
    @TestVisible private GiftBatchTotals totals;

    @TestVisible
    private Gifts gifts = new Gifts();

    @TestVisible
    private GiftTemplate giftTemplate;

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
    private GiftBatch() {}

    public GiftBatch(GiftBatchId giftBatchId) {
        this.giftBatchId = giftBatchId;
        this.batch = giftBatchSelector.selectGiftBatchBy(giftBatchId);
        this.giftTemplate = new GiftTemplate(batch.Form_Template__r.Template_JSON__c);
        this.gifts = new Gifts(giftBatchId, new GiftSelector(giftTemplate));
        this.totals = new GiftBatchTotals(giftBatchId, giftBatchSelector);
    }

    public Boolean hasElevateWidget() {
        return this.giftTemplate.hasElevateWidget();
    }

    public void captureAuthorizedGifts() {
        elevateBatchService.enqueuePaymentCaptureJobFor(id(), gifts?.elevateBatchIds());
        gifts.authorizedToPaymentProcessingStatus();
    }

    public void failGiftsWithReason(Map<String, String> failReasonByElevateBatchId) {
        gifts.failGiftsByElevateBatchIdWithReason(failReasonByElevateBatchId);
    }

    public void processGifts() {
        gifts.giftsToProcessingStatus();
        captureAuthorizedGifts();
        BDI_DataImport_API.processDataImportBatches(new List<Id>{ id() });
    }

    public void updateRecords() {
        gifts.updateRecords();
    }

    public Id id() {
        return this.giftBatchId.value();
    }

    public String name() {
        return this.batch.name;
    }

    public Gifts gifts() {
        return this.gifts;
    }

    public Map<String, Integer> totals() {
        return this.totals.toMap();
    }

    public Money totalDonations() {
        return new Money(this.totals.totalAmount(), 'US');
    }

    public Boolean requireTotalMatch() {
        return this.batch.RequireTotalMatch__c;
    }

    public Decimal expectedCountOfGifts() {
        return this.batch.Expected_Count_of_Gifts__c;
    }

    public Decimal expectedTotalBatchAmount() {
        return this.batch.Expected_Total_Batch_Amount__c;
    }

    public String batchTableColumns() {
        return this.batch.Batch_Table_Columns__c;
    }

    public String currencyIsoCode() {
        RecordCurrencyCode currencyCode = new RecordCurrencyCode(this.batch);
        return currencyCode.value();
    }
}
