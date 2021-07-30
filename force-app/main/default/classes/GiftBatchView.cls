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
* @description View model class used in Gift Entry for a GiftBatch.
*/
public inherited sharing class GiftBatchView {

    @AuraEnabled public Id giftBatchId;
    @AuraEnabled public String name;
    @AuraEnabled public Decimal totalDonationsAmount;
    @AuraEnabled public Boolean requireTotalMatch;
    @AuraEnabled public Decimal expectedCountOfGifts;
    @AuraEnabled public Decimal expectedTotalBatchAmount;
    @AuraEnabled public String batchTableColumns;
    @AuraEnabled public String currencyIsoCode;
    @AuraEnabled public DateTime lastModifiedDate;
    @AuraEnabled public Map<String, Integer> totals;
    @AuraEnabled public List<GiftView> gifts;

    public GiftBatchView() {}

    public GiftBatchView(GiftBatchDTO giftBatchDTO) {
        this.giftBatchId = giftBatchDTO.giftBatchId;
        this.name = giftBatchDTO.name;
        this.totalDonationsAmount = giftBatchDTO.totalDonationsAmount;
        this.requireTotalMatch = giftBatchDTO.requireTotalMatch;
        this.expectedCountOfGifts = giftBatchDTO.expectedCountOfGifts;
        this.expectedTotalBatchAmount = giftBatchDTO.expectedTotalBatchAmount;
        this.batchTableColumns = giftBatchDTO.batchTableColumns;
        this.currencyIsoCode = giftBatchDTO.currencyIsoCode;
        this.lastModifiedDate = giftBatchDTO.lastModifiedDate;
        this.totals = giftBatchDTO.totals;

        gifts = new List<GiftView>();
        for (GiftDTO giftDTO : giftBatchDTO.giftDTOs) {
            gifts.add(new GiftView(giftDTO));
        }
    }
}
