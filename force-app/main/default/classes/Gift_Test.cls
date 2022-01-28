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
    static void shouldHaveSchedule() {
        // Arrange
        npe03__Recurring_Donation__c rd = new npe03__Recurring_Donation__c(
            RecurringType__c = 'Open',
            npe03__Date_Established__c = Date.today(),
            Day_of_Month__c = '1',
            StartDate__c = Date.today(),
            npe03__Installment_Period__c = 'Monthly'
        );
        Id dummyDataImportId = UTIL_UnitTestData_TEST.mockId(DataImport__c.SObjectType);
        DataImport__c dataImport = new DataImport__c(
            Id = dummyDataImportId,
            Donation_Amount__c = 10,
            Donation_Date__c = Date.today()
        );
        Gift dummyGift = new Gift(dataImport);
        UnitOfWorkMock unitOfWorkMock = new UnitOfWorkMock();
        dummyGift.unitOfWork = stubFor(unitOfWorkMock);

        // Act
        dummyGift.addSchedule(rd);
        dummyGift.saveRecord();
        DataImport__c recordToInsert = (DataImport__c) unitOfWorkMock.objectsToInsert[0];

        // Assert
        System.assertEquals(true, dummyGift.hasSchedule(),
            'Gift should have a schedule');
        System.assertEquals('Open', recordToInsert.Recurring_Donation_Recurring_Type__c,
            'Unit of work should have recurring donation type set to Open');
        System.assertEquals('1', recordToInsert.Recurring_Donation_Day_of_Month__c,
            'Unit of work should have recurring donation day of month set to 1');
        System.assertEquals('Monthly', recordToInsert.Recurring_Donation_Installment_Period__c,
            'Unit of work should have recurring donation installment period set to Monthly');
        System.assertEquals(10, recordToInsert.Recurring_Donation_Amount__c,
            'Unit of work should have recurring donation amount set to 10');
        System.assertEquals(Date.today(), recordToInsert.Recurring_Donation_Date_Established__c,
            'Unit of work should have recurring donation date established set to today');
        System.assertEquals(Date.today(), recordToInsert.Recurring_Donation_Effective_Date__c,
            'Unit of work should have recurring donation effective date set to today');
    }

    @isTest
    static void shouldNotHaveSchedule() {
        // Arrange
        Id dummyDataImportId = UTIL_UnitTestData_TEST.mockId(DataImport__c.SObjectType);
        DataImport__c dataImport = new DataImport__c(
            Id = dummyDataImportId,
            Donation_Amount__c = 10,
            Donation_Date__c = Date.today()
        );
        Gift dummyGift = new Gift(dataImport);
        UnitOfWorkMock unitOfWorkMock = new UnitOfWorkMock();
        dummyGift.unitOfWork = stubFor(unitOfWorkMock);

        // Act
        dummyGift.saveRecord();
        DataImport__c recordToInsert = (DataImport__c) unitOfWorkMock.objectsToInsert[0];

        // Assert
        System.assertEquals(false, dummyGift.hasSchedule(),
            'Gift should not have a schedule');
        System.assert(recordToInsert.Recurring_Donation_Recurring_Type__c == null,
            'Unit of work should not have recurring donation type set');
        System.assert(recordToInsert.Recurring_Donation_Day_of_Month__c == null,
            'Unit of work should not have recurring donation day of month set');
        System.assert(recordToInsert.Recurring_Donation_Installment_Period__c == null,
            'Unit of work should not have recurring donation installment period set');
        System.assert(recordToInsert.Recurring_Donation_Amount__c == null,
            'Unit of work should not have recurring donation amount set');
        System.assert(recordToInsert.Recurring_Donation_Date_Established__c == null,
            'Unit of work should not have recurring donation date established set');
        System.assert(recordToInsert.Recurring_Donation_Effective_Date__c == null,
            'Unit of work should not have recurring donation effective date set');
    }

    @isTest
    static void shouldNotHaveScheduleWhenProvidedScheduleIsIncomplete() {
        // Arrange
        npe03__Recurring_Donation__c rd = new npe03__Recurring_Donation__c(
            npe03__Date_Established__c = Date.today(),
            Day_of_Month__c = '1',
            StartDate__c = Date.today(),
            npe03__Installment_Period__c = 'Monthly'
        );
        Id dummyDataImportId = UTIL_UnitTestData_TEST.mockId(DataImport__c.SObjectType);
        DataImport__c dataImport = new DataImport__c(
            Id = dummyDataImportId,
            Donation_Amount__c = 10,
            Donation_Date__c = Date.today()
        );
        Gift dummyGift = new Gift(dataImport);
        UnitOfWorkMock unitOfWorkMock = new UnitOfWorkMock();
        dummyGift.unitOfWork = stubFor(unitOfWorkMock);

        // Act
        dummyGift.addSchedule(rd);
        dummyGift.saveRecord();
        DataImport__c recordToInsert = (DataImport__c) unitOfWorkMock.objectsToInsert[0];

        // Assert
        System.assertEquals(false, dummyGift.hasSchedule(),
            'Gift should not have a schedule');
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
        public List<SObject> objectsToInsert;
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
                    objectsToInsert = (List<SObject>) listOfArgs[0];
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
