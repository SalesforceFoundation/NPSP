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
* @description GiftBatch DTO class.
*/
public inherited sharing class GiftBatchDTO {

    public Id giftBatchId;
    public String name;
    public Decimal totalDonationsAmount;
    public Boolean requireTotalMatch;
    public Decimal expectedCountOfGifts;
    public Decimal expectedTotalBatchAmount;
    public String batchTableColumns;
    public String currencyIsoCode;
    public DateTime lastModifiedDate;
    public Map<String, Integer> totals;
    public List<GiftDTO> giftDTOs;

    public GiftBatchDTO(GiftBatch giftBatch) {
        populateFields(giftBatch);
        populateDTOs(giftBatch);
    }

    private void populateFields(GiftBatch giftBatch) {
        this.giftBatchId = giftBatch.id();
        this.name = giftBatch.name();
        this.totalDonationsAmount = giftBatch.totalDonations().amount();
        this.requireTotalMatch = giftBatch.requireTotalMatch();
        this.expectedCountOfGifts = giftBatch.expectedCountOfGifts();
        this.expectedTotalBatchAmount = giftBatch.expectedTotalBatchAmount();
        this.batchTableColumns = giftBatch.batchTableColumns();
        this.lastModifiedDate = giftBatch.lastModifiedDate();
        this.currencyIsoCode = giftBatch.currencyIsoCode();
        this.totals = giftBatch.totals();
    }

    private void populateDTOs(GiftBatch giftBatch) {
        giftDTOs = new List<GiftDTO>();
        for (Gift gift : giftBatch.gifts().all()) {
            if (gift.id() != null && gift.hasPopulatedRecurringFields()) {
                gift.remapFieldsForView();
            }
            giftDTOs.add(new GiftDTO(gift));
        }
    }
}
