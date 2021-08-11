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
    static void shouldReturn3ProcessableGiftsOutOf5TotalWhenElevateDeregistered() {
        List<DataImport__c> dummyGifts = buildGifts(3, null, null);
        List<DataImport__c> dummyAuthorizedGiftsGroup1 = buildGifts(
            2, ElevateTransactionStatus.AUTHORIZED.name(), 'DUMMY_ELEVATE_ID_1');
        dummyGifts.addAll(dummyAuthorizedGiftsGroup1);

        Gifts gifts = new Gifts(dummyGifts);
        PS_IntegrationServiceConfigMock integrationServiceConfigMock =
            new PS_IntegrationServiceConfigMock(false);
        gifts.paymentIntegrationServiceConfig = stubFor(integrationServiceConfigMock);

        gifts.prepareGiftsForProcessing();
        System.assertEquals(5, gifts.giftsToUpdate.size());

        Integer numberOfFailedGifts = 0;
        Integer numberOfProcessingGifts = 0;
        String expectedFailureInformation = String.format(
            Label.gePaymentServicesUnavailableFailureMessage,
            new List<String> { Label.commonPaymentServices });

        for (DataImport__c dataImport : gifts.giftsToUpdate) {
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

        gifts.prepareGiftsForProcessing();
        System.assertEquals(5, gifts.giftsToUpdate.size());

        Integer numberOfFailedGifts = 0;
        Integer numberOfProcessingGifts = 0;
        for (DataImport__c dataImport : gifts.giftsToUpdate) {
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
        List<DataImport__c> dummyGifts = buildGifts(20, null, null);
        List<DataImport__c> dummyAuthorizedGiftsGroup1 = buildGifts(
            10, ElevateTransactionStatus.AUTHORIZED.name(), 'DUMMY_ELEVATE_ID_1');
        List<DataImport__c> dummyAuthorizedGiftsGroup2 = buildGifts(
            5, ElevateTransactionStatus.AUTHORIZED.name(), 'DUMMY_ELEVATE_ID_2');
        dummyGifts.addAll(dummyAuthorizedGiftsGroup1);
        dummyGifts.addAll(dummyAuthorizedGiftsGroup2);

        Gifts gifts = new Gifts(dummyGifts);
        System.assertEquals(dummyGifts.size(), gifts.dataImports?.size());
        System.assertEquals(2, gifts.elevateBatchIds()?.size());
    }

    @isTest
    static void shouldReturnCorrectNumberOfAuthorizedToPaymentProcessingGifts() {
        List<DataImport__c> dummyAuthorizedGifts = buildGifts(
            10, ElevateTransactionStatus.AUTHORIZED.name(), 'DUMMY_ELEVATE_ID_1');

        Gifts gifts = new Gifts(dummyAuthorizedGifts);
        gifts.authorizedToPaymentProcessingStatus();

        System.assertEquals(10, gifts.giftsToUpdate.size());
        for (DataImport__c gift : gifts.giftsToUpdate) {
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
        for (DataImport__c gift : gifts.giftsToUpdate) {
            System.assertEquals(ElevateTransactionStatus.RETRYABLEERROR.name(), gift.Payment_Status__c);
            System.assertEquals('DUMMY FAIL REASON', gift.FailureInformation__c);
        }
    }

    private static List<DataImport__c> buildGifts(
        Integer numberOfGifts,
        String paymentStatus,
        String elevateBatchId) {

        List<DataImport__c> dummyAuthorizedGifts = new List<DataImport__c>();
        for (Integer i = 0; i < numberOfGifts; i++) {
            DataImport__c dummyGift = new DataImport__c(
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

    private static PS_IntegrationServiceConfig stubFor(PS_IntegrationServiceConfigMock integrationServiceConfigMock) {
        return (PS_IntegrationServiceConfig) Test.createStub(
            PS_IntegrationServiceConfig.class,
            integrationServiceConfigMock
        );
    }
}