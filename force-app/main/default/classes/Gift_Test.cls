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

@isTest
private class Gift_Test {

    @isTest
    static void validateThatGiftNeedsToBeReauthorized() {
        DataImport__c dataImport = new DataImport__c(
            Payment_Status__c = ElevateTransactionStatus.AUTHORIZED.name(),
            Payment_Elevate_Batch_ID__c = 'test-valid-group-id',
            Donation_Amount__c = 3.00
        );
        Gift authorizedGift = new Gift(dataImport);

        GiftSelector mockedGiftSelector = stubFor(new GiftSelectorMock(5.00));
        authorizedGift.giftSelector = mockedGiftSelector;

        Boolean needsReauthorization = authorizedGift.requiresReauthorizationBeforeChange();
        System.assert(needsReauthorization);
    }

    @isTest
    static void shouldReturnDataImportRecord() {
        DataImport__c dataImport = new DataImport__c(
            Donation_Amount__c = 10,
            Donation_Date__c = Date.today()
        );

        Gift gift = new Gift(dataImport);

        String donationAmountField = String.valueOf(DataImport__c.Donation_Amount__c);
        System.assertEquals(10, gift.fields().get(donationAmountField));
    }

    @isTest
    static void shouldHave2SoftCreditsFromAdditionalObjectJSON() {
        String additionalObjectStringWithSoftCredits =
            new UTIL_AdditionalObjectData_TEST()
            .withOpportunityContactRoles(2)
            .build();

        DataImport__c dataImport = new DataImport__c(
            Donation_Amount__c = 10,
            Donation_Date__c = Date.today(),
            Additional_Object_JSON__c = additionalObjectStringWithSoftCredits
        );
        Gift gift = new Gift(dataImport);

        System.assertEquals(2, gift.softCredits().size());
    }

    @isTest
    static void shouldHave0SoftCreditsFromAdditionalObjectJSON() {
        String additionalObjectStringWithGeneralAccountUnits =
            new UTIL_AdditionalObjectData_TEST()
            .withGeneralAccountingUnits(5)
            .build();

        DataImport__c dataImport = new DataImport__c(
            Donation_Amount__c = 10,
            Donation_Date__c = Date.today(),
            Additional_Object_JSON__c = additionalObjectStringWithGeneralAccountUnits
        );
        Gift gift = new Gift(dataImport);

        System.assertEquals(0, gift.softCredits().size());
    }

    @isTest
    static void shouldAdd3SoftCreditsToGift() {
        DataImport__c dataImport = new DataImport__c(
            Donation_Amount__c = 10,
            Donation_Date__c = Date.today()
        );
        Gift gift = new Gift(dataImport);

        List<OpportunityContactRole> dummyOCRs = new List<OpportunityContactRole> {
            new OpportunityContactRole(),
            new OpportunityContactRole(),
            new OpportunityContactRole()
        };

        SoftCredits dummySoftCredits = new SoftCredits(dummyOCRs);

        gift.addSoftCredits(dummySoftCredits);

        System.assertEquals(3, gift.softCredits().size());
    }

    @isTest
    static void shouldReturnAsDataImport() {
        Id dummyDataImportId = UTIL_UnitTestData_TEST.mockId(DataImport__c.SObjectType);
        DataImport__c dataImport = new DataImport__c(
            Id = dummyDataImportId,
            Donation_Amount__c = 10,
            Donation_Date__c = Date.today()
        );
        Gift gift = new Gift(dataImport);

        System.assertEquals(dataImport.Id, gift.id());
        System.assertEquals(dataImport, gift.asDataImport());
    }

    private class GiftSelectorMock implements StubProvider {

        private Decimal newDonationAmount;

        public GiftSelectorMock(Decimal newDonationAmount) {
            this.newDonationAmount = newDonationAmount;
        }

        public Object handleMethodCall(Object stubbedObject,
            String stubbedMethodName,
            Type returnType,
            List<Type> listOfParamTypes,
            List<String> listOfParamNames,
            List<Object> listOfArgs) {

            switch on (stubbedMethodName) {
                when 'getGiftById' {
                    return new DataImport__c(
                        Payment_Status__c = ElevateTransactionStatus.AUTHORIZED.name(),
                        Payment_Elevate_Batch_ID__c = 'test-valid-group-id',
                        Donation_Amount__c = newDonationAmount
                    );
                }
            }

            return null;
        }
    }

    private static GiftSelector stubFor(GiftSelectorMock giftSelectorMock) {
        return (GiftSelector) Test.createStub(
            GiftSelector.class,
            giftSelectorMock
        );
    }
}
