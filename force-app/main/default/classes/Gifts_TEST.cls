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
@IsTest
private class Gifts_TEST {

    @isTest
    static void shouldOnlyCallSelectorMethodsOnceEachWhenRetrievingDonationsForGifts() {
        // Arrange
        Id dummyDataImportId0 = UTIL_UnitTestData_TEST.mockId(DataImport__c.SObjectType);
        Id dummyOpportunityId0 = UTIL_UnitTestData_TEST.mockId(Opportunity.SObjectType);
        Id dummyDataImportId1 = UTIL_UnitTestData_TEST.mockId(DataImport__c.SObjectType);
        Id dummyOpportunityId1 = UTIL_UnitTestData_TEST.mockId(Opportunity.SObjectType);
        Id dummyDataImportId2 = UTIL_UnitTestData_TEST.mockId(DataImport__c.SObjectType);
        Id dummyDataImportBatchId = UTIL_UnitTestData_TEST.mockId(DataImportBatch__c.SObjectType);
        GiftBatchId dummyGiftBatchId = new GiftBatchId(dummyDataImportBatchId);
        List<DataImport__c> dataImportList = new List<DataImport__c> {
            new DataImport__c(
                Id = dummyDataImportId0,
                DonationImported__c = dummyOpportunityId0
            ),
            new DataImport__c(
                Id = dummyDataImportId1,
                DonationImported__c = dummyOpportunityId1
            ),
            new DataImport__c(
                Id = dummyDataImportId2
            )
        };
        List<Opportunity> opportunityList = new List<Opportunity> {
            new Opportunity(
                Id = dummyOpportunityId0
            ),
            new Opportunity(
                Id = dummyOpportunityId1
            )
        };
        GiftSelectorMock giftSelectorMock = new GiftSelectorMock(dataImportList);
        DonationSelectorMock donationSelectorMock = new DonationSelectorMock(opportunityList);

        // Act
        Gifts gifts = new gifts(dummyGiftBatchId, stubFor(giftSelectorMock), stubFor(donationSelectorMock));

        // Assert
        System.assertEquals(1, giftSelectorMock.selectorMethodCallCount,
            'Should only run 1 query when retrieving gifts');
        System.assertEquals(1, donationSelectorMock.selectorMethodCallCount,
            'Should only run 1 query when retrieving donations');
        System.assertEquals(3, gifts.all().size(),
            'Should have 3 gifts');
        System.assertEquals(2, gifts.donations.all().size(),
            'Should have 2 donations');
    }

    @isTest
    static void shouldPopulateDonationForGiftsWithDonation() {
        // Arrange
        Id dummyGiftId0 = UTIL_UnitTestData_TEST.mockId(DataImport__c.SObjectType);
        Id dummyGiftId1 = UTIL_UnitTestData_TEST.mockId(DataImport__c.SObjectType);
        Id dummyGiftId2 = UTIL_UnitTestData_TEST.mockId(DataImport__c.SObjectType);
        Id dummyOppId0 = UTIL_UnitTestData_TEST.mockId(Opportunity.SObjectType);
        Id dummyOppId1 = UTIL_UnitTestData_TEST.mockId(Opportunity.SObjectType);
        Opportunity dummyOpp0 = new Opportunity(Id = dummyOppId0);
        Opportunity dummyOpp1 = new Opportunity(Id = dummyOppId1);
        List<DataImport__c> dummyGifts = buildGifts(3, null, null);
        dummyGifts[0].DonationImported__c = dummyOppId0;
        dummyGifts[1].DonationImported__c = dummyOppId1;
        GiftSelectorMock giftSelectorMock =
            new GiftSelectorMock(dummyGifts);
        DonationSelectorMock donationSelectorMock =
            new DonationSelectorMock(new List<Opportunity> { dummyOpp0, dummyOpp1 });
        Id dummyGiftBatchId = UTIL_UnitTestData_TEST.mockId(DataImportBatch__c.SObjectType);
        GiftBatchId mockedGiftBatchId = new GiftBatchId(dummyGiftBatchId);
        Gifts gifts = new Gifts(mockedGiftBatchId, stubFor(giftSelectorMock), stubFor(donationSelectorMock));

        // Act
        Gift firstGift = gifts.all()[0];
        Gift secondGift = gifts.all()[1];
        Gift thirdGift = gifts.all()[2];

        // Assert
        System.assertEquals(dummyOppId0, firstGift.donation().opportunity().Id,
            'Should return a donation for the first gift');
        System.assertEquals(dummyOppId1, secondGift.donation().opportunity().Id,
            'Should return a donation for the first gift');
        System.assertEquals(null, thirdGift.donation(),
            'Should not return a donation for the third gift');
    }

    @isTest
    static void shouldReturn3ProcessableGiftsOutOf5TotalWhenElevateDeregistered() {
        List<DataImport__c> dummyGifts = buildGifts(3, null, null);
        List<DataImport__c> dummyAuthorizedGiftsGroup1 = buildGifts(
            2, ElevateTransactionStatus.AUTHORIZED.name(), 'DUMMY_ELEVATE_ID_1');
        dummyGifts.addAll(dummyAuthorizedGiftsGroup1);

        Gifts gifts = new Gifts(dummyGifts);
        PS_IntegrationServiceConfigMock integrationServiceConfigMock =
            new PS_IntegrationServiceConfigMock(false);
        gifts.paymentIntegrationServiceConfig = stubFor(integrationServiceConfigMock);

        gifts.prepareForProcessing();

        Integer numberOfFailedGifts = 0;
        Integer numberOfProcessingGifts = 0;
        String expectedFailureInformation = String.format(
            Label.gePaymentServicesUnavailableFailureMessage,
            new List<String> { Label.commonPaymentServices });

        for (DataImport__c dataImport : gifts.giftsToUpdate.values()) {
            if (dataImport.Status__c == BDI_DataImport_API.bdiFailed) {
                numberOfFailedGifts ++;
                System.assertEquals(expectedFailureInformation, dataImport.FailureInformation__c);
            }

            if (dataImport.Status__c == BDI_DataImport_API.bdiProcessing) {
                numberOfProcessingGifts ++;
            }
        }

        System.assertEquals(2, numberOfFailedGifts);
        System.assertEquals(3, numberOfProcessingGifts);
    }

    @isTest
    static void shouldReturn5ProcessableGiftsOutOf5TotalWhenElevateRegistered() {
        List<DataImport__c> dummyGifts = buildGifts(3, null, null);
        List<DataImport__c> dummyAuthorizedGiftsGroup1 = buildGifts(
            2, ElevateTransactionStatus.AUTHORIZED.name(), 'DUMMY_ELEVATE_ID_1');
        dummyGifts.addAll(dummyAuthorizedGiftsGroup1);

        Gifts gifts = new Gifts(dummyGifts);
        PS_IntegrationServiceConfigMock integrationServiceConfigMock =
            new PS_IntegrationServiceConfigMock(true);
        gifts.paymentIntegrationServiceConfig = stubFor(integrationServiceConfigMock);

        gifts.prepareForProcessing();
        System.assertEquals(5, gifts.giftsToUpdate.size());

        Integer numberOfFailedGifts = 0;
        Integer numberOfProcessingGifts = 0;
        for (DataImport__c dataImport : gifts.giftsToUpdate.values()) {
            if (dataImport.Status__c == BDI_DataImport_API.bdiFailed) {
                numberOfFailedGifts ++;
            }

            if (dataImport.Status__c == BDI_DataImport_API.bdiProcessing) {
                numberOfProcessingGifts ++;
            }
        }

        System.assertEquals(0, numberOfFailedGifts);
        System.assertEquals(5, numberOfProcessingGifts);
    }

    @isTest
    static void shouldReturnCorrectNumberOfGiftCounts() {
        GE_PaymentServicesMock mockInstance = new GE_PaymentServicesMock();
        mockInstance.withIsElevateCustomer(true);
        GE_PaymentServices paymentServicesMock = (GE_PaymentServices) Test.createStub(
            GE_PaymentServices.class,
            mockInstance
        );
        GE_PaymentServices.setInstance(paymentServicesMock);
        List<DataImport__c> dummyGifts = buildGifts(20, null, null);
        List<DataImport__c> dummyAuthorizedGiftsGroup1 = buildGifts(
            10, ElevateTransactionStatus.AUTHORIZED.name(), 'DUMMY_ELEVATE_ID_1');
        List<DataImport__c> dummyAuthorizedGiftsGroup2 = buildGifts(
            5, ElevateTransactionStatus.AUTHORIZED.name(), 'DUMMY_ELEVATE_ID_2');
        dummyGifts.addAll(dummyAuthorizedGiftsGroup1);
        dummyGifts.addAll(dummyAuthorizedGiftsGroup2);

        Gifts gifts = new Gifts(dummyGifts);

        System.assertEquals(dummyGifts.size(), gifts.all().size());
        System.assertEquals(2, gifts.elevateBatchIds()?.size());
    }

    @isTest
    static void shouldReturnCorrectNumberOfAuthorizedToPaymentProcessingGifts() {
        List<DataImport__c> dummyAuthorizedGifts = buildGifts(
            10, ElevateTransactionStatus.AUTHORIZED.name(), 'DUMMY_ELEVATE_ID_1');

        Gifts gifts = new Gifts(dummyAuthorizedGifts);
        gifts.authorizedToPaymentProcessingStatus();

        System.assertEquals(10, gifts.giftsToUpdate.size());
        for (DataImport__c gift : gifts.giftsToUpdate.values()) {
            System.assertEquals(ElevateTransactionStatus.PAYMENTPROCESSING.name(), gift.Payment_Status__c);
        }
    }

    @isTest
    static void shouldReturnCorrectNumberOfGiftsWithFailReason() {
        final Integer numberOfFailedGifts = 15;
        final String elevateBatchId = 'DUMMY_ELEVATE_ID_1';

        List<DataImport__c> dummyAuthorizedGifts = buildGifts(
            numberOfFailedGifts, ElevateTransactionStatus.AUTHORIZED.name(), elevateBatchId);

        Gifts gifts = new Gifts(dummyAuthorizedGifts);
        gifts.failGiftsByElevateBatchIdWithReason(buildFailReasonByElevateBatchId(numberOfFailedGifts, elevateBatchId));

        System.assertEquals(numberOfFailedGifts, gifts.giftsToUpdate.size());
        for (DataImport__c gift : gifts.giftsToUpdate.values()) {
            System.assertEquals(ElevateTransactionStatus.RETRYABLEERROR.name(), gift.Payment_Status__c);
            System.assertEquals('DUMMY FAIL REASON', gift.FailureInformation__c);
        }
    }

    @isTest
    static void shouldReturn2Gifts() {
        GiftSelectorMock giftSelectorMock = new GiftSelectorMock(false);
        GiftBatchId mockedGiftBatchId = new GiftBatchId(DUMMY_BATCH_ID);

        Gifts gifts = new Gifts(mockedGiftBatchId, stubFor(giftSelectorMock));

        System.assertEquals(2, gifts.size());
        System.assertEquals(2, gifts.all().size());
    }

    @isTest
    static void shouldReturnGiftsWithExpectedFields() {
        GiftSelectorMock giftSelectorMock = new GiftSelectorMock(true);
        GiftBatchId mockedGiftBatchId = new GiftBatchId(DUMMY_BATCH_ID);

        Gifts gifts = new Gifts(mockedGiftBatchId, stubFor(giftSelectorMock));
        Gift dummyGift0 = gifts.findBy(new GiftId(DUMMY_GIFT_ID_0));
        Gift dummyGift1 = gifts.findBy(new GiftId(DUMMY_GIFT_ID_1));

        System.assertEquals('Dummy First Name 0', dummyGift0.fields().get(CONTACT1_FIRST_NAME));
        System.assertEquals('Dummy First Name 1', dummyGift1.fields().get(CONTACT1_FIRST_NAME));
    }

    @isTest
    static void shouldNotReturnGiftsWithUnexpectedFields() {
        GiftSelectorMock giftSelectorMock = new GiftSelectorMock(false);
        GiftBatchId mockedGiftBatchId = new GiftBatchId(DUMMY_BATCH_ID);

        Gifts gifts = new Gifts(mockedGiftBatchId, stubFor(giftSelectorMock));
        Gift dummyGift0 = gifts.findBy(new GiftId(DUMMY_GIFT_ID_0));
        Gift dummyGift1 = gifts.findBy(new GiftId(DUMMY_GIFT_ID_1));

        System.assertEquals(null, dummyGift0.fields().get(CONTACT1_FIRST_NAME));
        System.assertEquals(null, dummyGift1.fields().get(CONTACT1_FIRST_NAME));
    }

    @isTest
    static void shouldFailCorrectGiftWithProvidedReason() {
        GiftSelectorMock giftSelectorMock = new GiftSelectorMock(true);
        GiftBatchId dummyGiftBatchId = new GiftBatchId(DUMMY_BATCH_ID);
        Gifts gifts = new Gifts(dummyGiftBatchId, stubFor(giftSelectorMock));

        Map<String, String> failReasonMap = new Map<String, String> {
            DUMMY_ELEVATE_BATCH_ID => 'Something went wrong!'
        };
        gifts.failGiftsByElevateBatchIdWithReason(failReasonMap);

        Gift dummyGift0 = gifts.findBy(new GiftId(DUMMY_GIFT_ID_0));
        String failureInformationField = String.valueOf(DataImport__c.FailureInformation__c);
        System.assertEquals('Something went wrong!', dummyGift0.fields().get(failureInformationField));
    }

    @isTest
    static void shouldUpdateGiftsToProcessingStatus() {
        DataImport__c testDataImport = new DataImport__c(
            Status__c = BDI_DataImport_API.bdiDryRunValidated
        );
        insert testDataImport;

        Gifts gifts = new Gifts();
        gifts = new Gifts(new List<DataImport__c> { testDataImport });

        test.startTest();
        gifts.giftsToProcessingStatus();
        test.stopTest();

        Gift testGift = gifts.findBy(new GiftId(testDataImport.Id));
        String statusField = String.valueOf(DataImport__c.Status__c);
        System.assertEquals(testGift.fields().get(statusField), BDI_DataImport_API.bdiProcessing);
    }

    @IsTest
    static void shouldSetOnlyStandardGiftsToProcessing() {
        List<DataImport__c> dataImports = new List<DataImport__c>();
        DataImport__c testDataImport = new DataImport__c(
            Status__c = BDI_DataImport_API.bdiProcessing,
            Payment_Status__c = ElevateTransactionStatus.PAYMENTPROCESSING.name()
        );
        DataImport__c testDataImport1 = new DataImport__c(
            Status__c = BDI_DataImport_API.bdiProcessing
        );

        dataImports.add(testDataImport);
        dataImports.add(testDataImport1);
        insert dataImports;

        Gifts gifts = new Gifts(dataImports);

        Test.startTest();
        List<Gift> processingGifts = gifts.standardGiftsInProcessing();
        Test.stopTest();

        System.assertEquals(1 ,processingGifts.size());
    }


    private static List<DataImport__c> buildGifts(
        Integer numberOfGifts,
        String paymentStatus,
        String elevateBatchId) {

        List<DataImport__c> dummyAuthorizedGifts = new List<DataImport__c>();
        for (Integer i = 0; i < numberOfGifts; i++) {
            DataImport__c dummyGift = new DataImport__c(
                Id = UTIL_UnitTestData_TEST.mockId(DataImport__c.getSObjectType()),
                Status__c = BDI_DataImport_API.bdiDryRunValidated,
                NPSP_Data_Import_Batch__c = UTIL_UnitTestData_TEST.mockId(DataImportBatch__c.getSObjectType()),
                Account1_Name__c = 'DUMMY ACCOUNT ' +  i,
                Donation_Amount__c = 1,
                Donation_Date__c = Date.today(),
                Donation_Donor__c = 'Account1',
                Payment_Status__c = paymentStatus,
                Payment_Elevate_Batch_ID__c = elevateBatchId
            );
            dummyAuthorizedGifts.add(dummyGift);
        }
        return dummyAuthorizedGifts;
    }

    private static Map<String, String> buildFailReasonByElevateBatchId(Integer numberOfGifts, String elevateBatchId) {
        Map<String, String> failReasonByElevateBatchId = new Map<String, String>();
        for (Integer i = 0; i < numberOfGifts; i++) {
            failReasonByElevateBatchId.put(elevateBatchId, 'DUMMY FAIL REASON');
        }
        return failReasonByElevateBatchId;
    }

    public class DonationSelectorMock implements StubProvider {

        public Integer selectorMethodCallCount = 0;
        private List<Opportunity> recordsToReturn;

        public DonationSelectorMock(List<Opportunity> recordsToReturn) {
            this.recordsToReturn = recordsToReturn;
        }

        public Object handleMethodCall(Object stubbedObject,
            String stubbedMethodName,
            Type returnType,
            List<Type> listOfParamTypes,
            List<String> listOfParamNames,
            List<Object> listOfArgs) {

            switch on (stubbedMethodName) {
                when 'getDonation' {
                    this.selectorMethodCallCount++;

                    return new List<Opportunity> { new Opportunity(
                        Amount = 100.00,
                        StageName = UTIL_UnitTestData_TEST.getOpenStage(),
                        Name = 'Dummy Opportunity From Mocked Selector',
                        CloseDate = Date.today()
                    )};
                }
                when 'getDonations' {
                    this.selectorMethodCallCount++;
                    return recordsToReturn;
                }
            }

            return null;
        }
    }

    private class GiftSelectorMock implements StubProvider {

        public Integer selectorMethodCallCount = 0;
        private Boolean returnWithAdditionalFields = false;
        private List<DataImport__c> recordsToReturn;

        public GiftSelectorMock(Boolean returnWithAdditionalFields) {
            this.returnWithAdditionalFields = returnWithAdditionalFields;
        }

        public GiftSelectorMock(List<DataImport__c> recordsToReturn) {
            this.recordsToReturn = recordsToReturn;
        }

        public Object handleMethodCall(Object stubbedObject,
            String stubbedMethodName,
            Type returnType,
            List<Type> listOfParamTypes,
            List<String> listOfParamNames,
            List<Object> listOfArgs) {

            switch on (stubbedMethodName) {
                when 'getGiftsFor' {
                    this.selectorMethodCallCount++;
                    if (this.recordsToReturn != null) {
                        return this.recordsToReturn;
                    }
                    if (this.returnWithAdditionalFields) {
                        return dummyDataImportsWithContactFirstName;
                    } else {
                        return dummyDataImports;
                    }
                }
            }

            return null;
        }
    }

    public class PS_IntegrationServiceConfigMock implements StubProvider {
        public Boolean isIntegrationEnabled = false;

        public PS_IntegrationServiceConfigMock(Boolean isIntegrationEnabled) {
            this.isIntegrationEnabled = isIntegrationEnabled;
        }

        public Object handleMethodCall(Object stubbedObject,
            String stubbedMethodName,
            Type returnType,
            List<Type> listOfParamTypes,
            List<String> listOfParamNames,
            List<Object> listOfArgs) {

            switch on (stubbedMethodName) {
                when 'isIntegrationEnabled' {
                    return isIntegrationEnabled;
                }
            }

            return null;
        }
    }

    private static DonationSelector stubFor(DonationSelectorMock donationSelectorMock) {
        return (DonationSelector) Test.createStub(
            DonationSelector.class,
            donationSelectorMock
        );
    }

    private static GiftSelector stubFor(GiftSelectorMock giftSelectorMock) {
        return (GiftSelector) Test.createStub(
            GiftSelector.class,
            giftSelectorMock
        );
    }

    private static PS_IntegrationServiceConfig stubFor(PS_IntegrationServiceConfigMock integrationServiceConfigMock) {
        return (PS_IntegrationServiceConfig) Test.createStub(
            PS_IntegrationServiceConfig.class,
            integrationServiceConfigMock
        );
    }

    private final static Id DUMMY_BATCH_ID = UTIL_UnitTestData_TEST.mockId(DataImportBatch__c.getSObjectType());
    private final static Id DUMMY_GIFT_ID_0 = UTIL_UnitTestData_TEST.mockId(DataImport__c.getSObjectType());
    private final static Id DUMMY_GIFT_ID_1 = UTIL_UnitTestData_TEST.mockId(DataImport__c.getSObjectType());
    private final static String CONTACT1_FIRST_NAME = String.valueOf(DataImport__c.Contact1_Firstname__c);
    private final static String DUMMY_ELEVATE_BATCH_ID = 'DUMMY_ELEVATE_BATCH_ID';

    private static List<DataImport__c> dummyDataImportsWithContactFirstName =
        new List<DataImport__c>{
            new DataImport__c(
                    Id = DUMMY_GIFT_ID_0,
                    Contact1_Firstname__c = 'Dummy First Name 0',
                    Donation_Amount__c = 100,
                    Donation_Date__c = Date.today(),
                    Status__c = BDI_DataImport_API.bdiDryRunValidated,
                    Payment_Elevate_Batch_ID__c = DUMMY_ELEVATE_BATCH_ID
            ),
            new DataImport__c(
                    Id = DUMMY_GIFT_ID_1,
                    Contact1_Firstname__c = 'Dummy First Name 1',
                    Donation_Amount__c = 200,
                    Donation_Date__c = Date.today()
            )
        };

    private static List<DataImport__c> dummyDataImports =
        new List<DataImport__c>{
            new DataImport__c(
                    Id = DUMMY_GIFT_ID_0,
                    Donation_Amount__c = 100,
                    Donation_Date__c = Date.today()
            ),
            new DataImport__c(
                    Id = DUMMY_GIFT_ID_1,
                    Donation_Amount__c = 200,
                    Donation_Date__c = Date.today()
            )
        };
}