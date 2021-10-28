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
* @description GiftView tests.
*/
@isTest
private class GiftView_TEST {

    @isTest
    static void shouldReturnGiftViewWithDataImport() {
        DataImport__c dataImport = new DataImport__c(
            Donation_Amount__c = 10,
            Donation_Date__c = Date.today()
        );
        Gift gift = new Gift(dataImport);
        GiftDTO giftDTO = new GiftDTO(gift);
        GiftView giftView = new GiftView(giftDTO);

        String donationAmountField = String.valueOf(DataImport__c.Donation_Amount__c);
        System.assertEquals(10, giftView.fields.get(donationAmountField));
    }

    @isTest
    static void shouldReturnGiftViewWith2SoftCredits() {
        String additionalObjectString =
            new UTIL_AdditionalObjectData_TEST()
            .withOpportunityContactRoles(2)
            .build();

        DataImport__c dataImport = new DataImport__c(
            Donation_Amount__c = 10,
            Donation_Date__c = Date.today(),
            Additional_Object_JSON__c = additionalObjectString
        );
        Gift gift = new Gift(dataImport);
        GiftDTO giftDTO = new GiftDTO(gift);
        GiftView giftView = new GiftView(giftDTO);

        System.assertEquals(2, giftView.softCredits.all.size());
    }
}
