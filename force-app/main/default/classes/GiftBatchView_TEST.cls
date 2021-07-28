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
* @description GiftBatchView tests.
*/
@isTest
private class GiftBatchView_TEST {

    @isTest
    static void shouldReturn200TotalDonationsAmount() {
        GiftBatchView giftBatchView = createDummyGiftBatchViewWith(new Gifts());
        System.assertEquals(200, giftBatchView.totalDonationsAmount);
    }

    @isTest
    static void shouldReturn2TotalGiftsCount() {
        GiftBatchView giftBatchView = createDummyGiftBatchViewWith(new Gifts());
        System.assertEquals(2, giftBatchView.totals.get('TOTAL'));
    }

    @isTest
    static void shouldHave2GiftViews() {
        Gifts gifts = new Gifts(DUMMY_DATA_IMPORTS_WITH_CONTACT_FIRST_NAME);
        GiftBatchView giftBatchView = createDummyGiftBatchViewWith(gifts);
        System.assertEquals(2, giftBatchView.gifts.size());
    }

    @isTest
    static void shouldHave0GiftViews() {
        GiftBatchView giftBatchView = createDummyGiftBatchViewWith(new Gifts());
        System.assertEquals(0, giftBatchView.gifts.size());
    }

    private static GiftBatchView createDummyGiftBatchViewWith(Gifts gifts) {
        AggregateResultProxy mockTotalsResult = new AggregateResultProxy()
            .withAliasAndValue('recordCount', 2);
        AggregateResultProxy mockedTotalAmountResult = new AggregateResultProxy()
            .withAliasAndValue('totalAmount', 200);
        GiftBatchTotals totals = new GiftBatchTotals(mockTotalsResult, mockedTotalAmountResult);

        GiftBatch giftBatch = new GiftBatch();
        giftBatch.giftBatchId = new GiftBatchId(DUMMY_DATA_IMPORT_BATCH_ID);
        giftBatch.batch = new DataImportBatch__c();
        giftBatch.batch.RequireTotalMatch__c = false;
        giftBatch.batch.Expected_Count_of_Gifts__c = 2.0;
        giftBatch.batch.Expected_Total_Batch_Amount__c = 200.00;
        giftBatch.batch.Batch_Table_Columns__c = 'DUMMY BATCH COLUMNS';
        giftBatch.totals = totals;
        giftBatch.gifts = gifts;

        GiftBatchDTO giftBatchDTO = new GiftBatchDTO(giftBatch);
        return new GiftBatchView(giftBatchDTO);
    }

    private static List<DataImport__c> DUMMY_DATA_IMPORTS_WITH_CONTACT_FIRST_NAME =
        new List<DataImport__c>{
            new DataImport__c(
                    Id = UTIL_UnitTestData_TEST.mockId(DataImport__c.getSObjectType()),
                    Contact1_Firstname__c = 'Dummy First Name',
                    Donation_Amount__c = 100,
                    Donation_Date__c = Date.today()
            ),
            new DataImport__c(
                    Id = UTIL_UnitTestData_TEST.mockId(DataImport__c.getSObjectType()),
                    Contact1_Firstname__c = 'Dummy First Name',
                    Donation_Amount__c = 200,
                    Donation_Date__c = Date.today()
            )
        };

    private static Id DUMMY_DATA_IMPORT_BATCH_ID = UTIL_UnitTestData_TEST.mockId(DataImportBatch__c.getSObjectType());
}
