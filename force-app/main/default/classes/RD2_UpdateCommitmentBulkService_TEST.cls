/*
    Copyright (c) 2022, Salesforce.org
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
* @date 2022
* @group Recurring Donations
* @description Test class for RD2_UpdateCommitmentBulkService
*/
@IsTest
public class RD2_UpdateCommitmentBulkService_TEST {
    private static final TEST_SObjectGateway.ErrorGateway errorGateway = new TEST_SObjectGateway.ErrorGateway();

    @isTest
    private static void verifyElevateBulkApiIsExecuteSuccessfullyWhenThereIsAtLeast1Record() {
        PS_IntegrationServiceConfig_TEST.enableElevateIntegrationService();
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        UTIL_Http_TEST.CalloutMock calloutMock = UTIL_Http_TEST.mockSuccessCalloutResponse(mockSuccessResponseBody(1));

        List<npe03__Recurring_Donation__c> rds = constrcutRecurringDonations(1);

        Test.startTest();
        new RD2_UpdateCommitmentBulkService()
            .withCommitments(rds)
            .processCommitments();
        Test.stopTest();

        System.assertEquals(1, calloutMock.getCalloutCounter(),
            '1 callout should be made when there is less than 50 records in the transaction.');
        System.assertEquals(0, errorGateway.getRecords().size(),
            'No error record should be created when the callout is successful');
    }

    @isTest
    private static void verifyOnly2CalloutWillbeMadeWhenTotalProcessRecordIsBetween50and100() {
        Integer recordCount = 100;
        PS_IntegrationServiceConfig_TEST.enableElevateIntegrationService();
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        UTIL_Http_TEST.CalloutMock calloutMock = UTIL_Http_TEST.mockSuccessCalloutResponse(mockSuccessResponseBody(recordCount));

        List<npe03__Recurring_Donation__c> rds = constrcutRecurringDonations(recordCount);

        Test.startTest();
        new RD2_UpdateCommitmentBulkService()
            .withCommitments(rds)
            .processCommitments();
        Test.stopTest();

        System.assertEquals(2, calloutMock.getCalloutCounter(),
            '1 callout should be made when there is less than 50 records in the transaction.');
        System.assertEquals(0, errorGateway.getRecords().size(),
            'No error record should be created when the callout is successful');
    }

    @isTest
    private static void verifyMaximumOnly5CalloutCanBeMadeDuringOneProcess() {
        Integer recordCount = 251;
        PS_IntegrationServiceConfig_TEST.enableElevateIntegrationService();
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        UTIL_Http_TEST.CalloutMock calloutMock = UTIL_Http_TEST.mockSuccessCalloutResponse(mockSuccessResponseBody(recordCount));

        List<npe03__Recurring_Donation__c> rds = constrcutRecurringDonations(recordCount);

        Test.startTest();
        new RD2_UpdateCommitmentBulkService()
            .withCommitments(rds)
            .processCommitments();
        Test.stopTest();

        System.assertEquals(5, calloutMock.getCalloutCounter(),
            '1 callout should be made when there is less than 50 records in the transaction.');
        System.assertEquals(0, errorGateway.getRecords().size(),
            'No error record should be created when the callout is successful');
    }

    @isTest
    private static void verifyAnErrorWithElevateBulkApiErrorWillBeLoggedWhenCalloutFail() {
        Integer recordCount = 1;
        PS_IntegrationServiceConfig_TEST.enableElevateIntegrationService();
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        UTIL_Http_TEST.mockBadRequestCalloutResponse();

        List<npe03__Recurring_Donation__c> rds = constrcutRecurringDonations(recordCount);

        Test.startTest();
        new RD2_UpdateCommitmentBulkService()
            .withCommitments(rds)
            .processCommitments();
        Test.stopTest();

        List<Error__c> errors = errorGateway.getRecords();
        System.assertEquals(1, errorGateway.getRecords().size(),
            '1 error record should be created when the callout is successful');
            System.assertEquals(ERR_Handler_API.Context.Elevate.name(),errors[0].Context_Type__c,
            'The error record context type should match with Elevate context.');
            System.assertEquals(RD2_ElevateIntegrationService.LOG_TYPE_COMMITMENT_UPDATE_BULK,errors[0].Error_Type__c,
            'The error type type should specific the update bulk context.');
    }

    @isTest
    private static void verifyMaximum5ErrorRecordsWithElevateBulkApiErrorWillBeLoggedWhenCalloutFail() {
        Integer recordCount = 251;
        PS_IntegrationServiceConfig_TEST.enableElevateIntegrationService();
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        UTIL_Http_TEST.mockBadRequestCalloutResponse();

        List<npe03__Recurring_Donation__c> rds = constrcutRecurringDonations(recordCount);

        Test.startTest();
        new RD2_UpdateCommitmentBulkService()
            .withCommitments(rds)
            .processCommitments();
        Test.stopTest();

        List<Error__c> errors = errorGateway.getRecords();
        System.assertEquals(5, errorGateway.getRecords().size(),
            '1 error record should be created when the callout is successful');
        for (Error__c error : errors) {
            System.assertEquals(ERR_Handler_API.Context.Elevate.name(),error.Context_Type__c,
            'The error record context type should match with Elevate context.');
            System.assertEquals(RD2_ElevateIntegrationService.LOG_TYPE_COMMITMENT_UPDATE_BULK,error.Error_Type__c,
            'The error type type should specific the update bulk context.');
        }
    }

    public static String mockSuccessResponseBody(Integer recordCount) {
        return '{"id":"' + 'radom-batch-id'
            + '","createdAt": "2021-12-15T20:45:25.000+0000"'
            + '","status":"CREATED","statusReason":"COMMITMENT_CREATED"'
            + '","operationsSubmitted":' + recordCount
            + '}';
    }

    private static List<npe03__Recurring_Donation__c> constrcutRecurringDonations(Integer recordCount) {
        List<npe03__Recurring_Donation__c> rds = new List<npe03__Recurring_Donation__c>();

        for (Integer i = 0; i < recordCount; i++) {
            rds.add(        
                TEST_RecurringDonationBuilder.constructEnhancedBuilder()
                    .withClosedReason('random')
                    .withStatusClosed()
                    .build()
            );
        }

        return rds;
    }
}
