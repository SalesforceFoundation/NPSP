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
    static void shouldReturnTrueWhenGiftHasRecurringFieldsPopulated() {
        // Arrange
        DataImport__c dataImport = new DataImport__c(
            Id = UTIL_UnitTestData_TEST.mockId(DataImport__c.SObjectType),
            Donation_Amount__c = 10.00,
            Donation_Date__c = Date.today(),
            Recurring_Donation_Recurring_Type__c = 'Open',
            Recurring_Donation_Installment_Period__c = 'Monthly',
            Recurring_Donation_Effective_Date__c = Date.today(),
            Recurring_Donation_Day_of_Month__c = '5'
        );
        Gift gift = new Gift(dataImport);

        // Act
        Boolean isRecurring = gift.hasPopulatedRecurringFields();

        // Assert
        System.assertEquals(true, isRecurring,
            'Should be true when gift has populated recurring fields');
    }

    @isTest
    static void shouldReturnFalseWhenGiftDoesNotHaveRecurringFieldsPopulated() {
        // Arrange
        DataImport__c dataImport = new DataImport__c(
            Id = UTIL_UnitTestData_TEST.mockId(DataImport__c.SObjectType),
            Donation_Amount__c = 10.00,
            Donation_Date__c = Date.today()
        );
        Gift gift = new Gift(dataImport);

        // Act
        Boolean isRecurring = gift.hasPopulatedRecurringFields();

        // Assert
        System.assertEquals(false, isRecurring,
            'Should be false when gift does not have populated recurring fields');
    }

    @isTest
    static void shouldPopulatedRecurringDonationFieldsAndNullDonationFields() {
        // Arrange
        Date today = Date.today();
        DataImport__c dataImport = new DataImport__c(
            Id = UTIL_UnitTestData_TEST.mockId(DataImport__c.SObjectType),
            Recurring_Donation_Installment_Period__c = 'Monthly',
            Recurring_Donation_Effective_Date__c = today,
            Recurring_Donation_Recurring_Type__c = 'Open',
            Recurring_Donation_Day_of_Month__c = '5',
            Donation_Amount__c = 25.00,
            Donation_Date__c = today
        );
        Gift gift = new Gift(dataImport);

        // Act
        gift.preprocessForRecurringGift(false);

        // Assert
        System.assert(dataImport.Donation_Amount__c == null);
        System.assert(dataImport.Donation_Date__c == null);
        System.assert(dataImport.DonationImported__c == null);
        System.assert(dataImport.Recurring_Donation_Installment_Period__c == 'Monthly');
        System.assert(dataImport.Recurring_Donation_Effective_Date__c == today);
        System.assert(dataImport.Recurring_Donation_Recurring_Type__c == 'Open');
        System.assert(dataImport.Recurring_Donation_Day_of_Month__c == '5');
    }


    @isTest
    static void shouldPopulatedRecurringDonationFieldsAndPayFirstInstallment() {
        // Arrange
        Date today = Date.today();
        DataImport__c dataImport = new DataImport__c(
                Id = UTIL_UnitTestData_TEST.mockId(DataImport__c.SObjectType),
                Recurring_Donation_Installment_Period__c = 'Monthly',
                Recurring_Donation_Effective_Date__c = today,
                Recurring_Donation_Recurring_Type__c = 'Open',
                Recurring_Donation_Day_of_Month__c = '5',
                Donation_Amount__c = 25.00,
                Donation_Date__c = today
        );
        Gift gift = new Gift(dataImport);

        // Act
        gift.preprocessForRecurringGift(true);

        // Assert
        System.assert(dataImport.Donation_Amount__c != null);
        System.assert(dataImport.Donation_Date__c == null);
        System.assert(dataImport.DonationImported__c == null);
        System.assert(dataImport.Recurring_Donation_Installment_Period__c == 'Monthly');
        System.assert(dataImport.Recurring_Donation_Effective_Date__c == today);
        System.assert(dataImport.Recurring_Donation_Recurring_Type__c == 'Open');
        System.assert(dataImport.Recurring_Donation_Day_of_Month__c == '5');
    }


    @isTest
    static void shouldPopulateDonationInGift(){
        // Arrange
        Id dummyDataImportId = UTIL_UnitTestData_TEST.mockId(DataImport__c.SObjectType);
        Id dummyOpportunityId = UTIL_UnitTestData_TEST.mockId(Opportunity.SObjectType);
        DataImport__c dummyDataImport = new DataImport__c(
            Id = dummyDataImportId,
            Donation_Amount__c = 3.00,
            Donation_Date__c = Date.today()
        );
        Opportunity dummyOpportunity = new Opportunity(
            Id = dummyOpportunityId,
            Amount = 100.00,
            StageName = UTIL_UnitTestData_TEST.getOpenStage()
        );
        Donation dummyDonation = new Donation(dummyOpportunity);
        Gift gift = new Gift(dummyDataImport, dummyDonation);

        // Act
        Donation retrievedDonation = gift.donation();

        // Assert
        System.assertEquals(dummyOpportunityId, retrievedDonation.opportunity().Id,
            'Should return the donation associated with the gift.');
    }

    @isTest
    static void validateThatGiftNeedsToBeReauthorized() {
        DataImport__c dataImport = new DataImport__c(
            Payment_Status__c = ElevateTransactionStatus.AUTHORIZED.name(),
            Payment_Elevate_Batch_ID__c = 'test-valid-group-id',
            Donation_Amount__c = 3.00
        );
        Gift authorizedGift = new Gift(dataImport);

        GiftSelector mockedGiftSelector = stubFor(new GiftSelectorMock(3.00));
        authorizedGift.giftSelector = mockedGiftSelector;
        System.assertEquals(false, authorizedGift.requiresReauthorizationBeforeChange());

        mockedGiftSelector = stubFor(new GiftSelectorMock(5.00));
        authorizedGift.giftSelector = mockedGiftSelector;

        Boolean needsReauthorization = authorizedGift.requiresReauthorizationBeforeChange();
        System.assert(needsReauthorization);
    }

    @isTest
    static void shouldNotRequireReauthorization() {
        DataImport__c dataImport = new DataImport__c(Payment_Status__c = null);
        Gift gift = new Gift(dataImport);

        System.assertEquals(false, gift.requiresReauthorizationBeforeChange());
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
        System.assertEquals(dataImport.Id, gift.id());
        System.assertEquals(dataImport, gift.asDataImport());
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
            new OpportunityContactRole(Role='Influencer'),
            new OpportunityContactRole(Role='Solicitor'),
            new OpportunityContactRole(Role='Honoree')
        };

        SoftCredits dummySoftCredits = new SoftCredits(dummyOCRs);

        gift.assignSoftCredits(dummySoftCredits);

        System.assertEquals(3, gift.softCredits().size());
    }

    @isTest
    static void shouldCallMethodsInUnitOfWorkWhenSaved() {
        Id dummyDataImportId = UTIL_UnitTestData_TEST.mockId(DataImport__c.SObjectType);
        DataImport__c dataImport = new DataImport__c(
            Id = dummyDataImportId,
            Donation_Amount__c = 10,
            Donation_Date__c = Date.today()
        );
        Gift gift = new Gift(dataImport);
        UnitOfWorkMock unitOfWorkMock = new UnitOfWorkMock();
        gift.unitOfWork = stubFor(unitOfWorkMock);
        gift.saveRecord();

        System.assertEquals(true, unitOfWorkMock.registerDirtyCalled);
        System.assertEquals(true, unitOfWorkMock.saveCalled);
    }

    @isTest
    static void shouldReturnTrueForAuthorizedGift() {
        DataImport__c dataImport = new DataImport__c(Payment_Status__c = ElevateTransactionStatus.AUTHORIZED.name());
        Gift gift = new Gift(dataImport);

        System.assertEquals(true, gift.hasAuthorizedPayment());
    }

    @isTest
    static void shouldReturnFalseForNonAuthorizedGift() {
        DataImport__c dataImport = new DataImport__c(Payment_Status__c = null);
        Gift gift = new Gift(dataImport);

        System.assertEquals(false, gift.hasAuthorizedPayment());
    }

    @isTest
    static void shouldReturnTrueForDryRunValidatedGift() {
        DataImport__c dataImport = new DataImport__c(Status__c = BDI_DataImport_API.bdiDryRunValidated);
        Gift gift = new Gift(dataImport);

        System.assertEquals(true, gift.isDryRunValidated());
    }

    @isTest
    static void shouldReturnFalseForImportedGift() {
        DataImport__c dataImport = new DataImport__c(Status__c = BDI_DataImport_API.bdiImported);
        Gift gift = new Gift(dataImport);

        System.assertEquals(false, gift.isDryRunValidated());
    }

    @isTest
    static void shouldConvertSoftCreditsToAdditionalObjectJSONWhenSaved() {
        DataImport__c dataImport = new DataImport__c(
            Donation_Amount__c = 10,
            Donation_Date__c = Date.today()
        );
        Gift gift = new Gift(dataImport);

        UnitOfWorkMock unitOfWorkMock = new UnitOfWorkMock();
        gift.unitOfWork = stubFor(unitOfWorkMock);

        Id dummyContactId = UTIL_UnitTestData_TEST.mockId(Contact.SObjectType);
        List<OpportunityContactRole> dummyOCRs = new List<OpportunityContactRole> {
            new OpportunityContactRole(Role = 'Influencer', ContactId = dummyContactId)
        };

        SoftCredits dummySoftCredits = new SoftCredits(dummyOCRs);
        gift.assignSoftCredits(dummySoftCredits);

        System.assertEquals(1, gift.softCredits().size());
        System.assertEquals(null, gift.additionalObjectString());

        gift.saveRecord();

        System.assert(gift.additionalObjectString().contains(dummyContactId));
        System.assert(gift.additionalObjectString().contains('Influencer'));
    }

    @isTest
    static void shouldProcessGiftThroughBDI() {
        DataImport__c dataImport = new DataImport__c(
            Account1_Name__c = 'testAcct',
            Donation_Donor__c = 'Account1',
            Donation_Amount__c = 100,
            Donation_Date__c = Date.today()
        );
        insert dataImport;
        Gift gift = new Gift(dataImport);

        System.assertEquals(null, gift.status());
        gift.dryRunThroughBDI();
        System.assertEquals(BDI_DataImport_API.bdiDryRunValidated, gift.status());

        gift.processThroughBDI();
        System.assertEquals(BDI_DataImport_API.bdiImported, gift.status());
    }

    @isTest
    static void shouldRemoveNetNewSoftCredits() {
        // Arrange
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

        // Act
        gift.preprocessForRecurringGift(false);

        // Assert
        System.assertEquals(0, gift.softCredits().size(),
            'Should not have any soft credits after preprocessing for recurring gift');
    }

    @isTest
    static void shouldInstrumentNewSingleGiftProcessedThroughBDIService() {
        BDI_DataImportService.isFromGiftEntryUI = true;     // simulate the service coming through the UI
        SfdoInstrumentationMock_TEST.MockService mockService = SfdoInstrumentationMock_TEST.injectMockedInstrumentationService();

        DataImport__c dataImport = new DataImport__c(
            Account1_Name__c = 'testAcct',
            Donation_Donor__c = 'Account1',
            Donation_Amount__c = 100,
            Donation_Date__c = Date.today()
        );
        insert dataImport;
        Gift gift = new Gift(dataImport);
        System.assertEquals(null, gift.status());

        gift.dryRunThroughBDI();
        System.assertEquals(null, mockService.value, 'The instrumentation service should have not been called during DryRun mode');

        gift.processThroughBDI();
        System.assertEquals(1, mockService.value, 'The instrumentation service should have indicated one new Gift was inserted');
        System.assertEquals(sfdoInstrumentationEnum.Feature.GiftEntry, mockService.feature,
            'The instrumentation service should have indicated GiftEntry');
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

    private class UnitOfWorkMock implements StubProvider {
        public Boolean registerDirtyCalled = false;
        public Boolean saveCalled = false;

        public Object handleMethodCall(Object stubbedObject,
                String stubbedMethodName,
                Type returnType,
                List<Type> listOfParamTypes,
                List<String> listOfParamNames,
                List<Object> listOfArgs) {

            switch on (stubbedMethodName) {
                when 'registerDirty' {
                    registerDirtyCalled = true;
                }
                when 'save' {
                    saveCalled = true;
                    return new List<Database.SaveResult>();
                }
            }
            return null;
        }
    }

    private static UnitOfWork stubFor(UnitOfWorkMock unitOfWorkMock) {
        return (UnitOfWork) Test.createStub( UnitOfWork.class, unitOfWorkMock );
    }
}
