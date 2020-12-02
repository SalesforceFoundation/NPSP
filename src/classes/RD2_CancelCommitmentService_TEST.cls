/*
    Copyright (c) 2020, Salesforce.org
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
* @date 2020
* @group Recurring Donations
* @description Unit Tests for the Cancel Commitment Service
*/
@IsTest
public with sharing class RD2_CancelCommitmentService_TEST {
    public static final String COMMITMENT_ID = '11a1c101-bcde-001-111f-g1dh00i0jk111';
    private static final TEST_SObjectGateway.RecurringDonationGateway rdGateway = new TEST_SObjectGateway.RecurringDonationGateway();
    private static final String LOG_TYPE_COMMITMENT_CANCEL = RD2_ElevateIntegrationService.LOG_TYPE_COMMITMENT_CANCEL;

    /****
    * @description Creates data required for unit tests
    */
    @TestSetup
    private static void setUp() {
        Contact contact = UTIL_UnitTestData_TEST.getContact();
        insert contact;
    }

    /**
    * @description Verifies RD Close Reason will not be updated back
    * to the user provided Closed Reason value
    * when Elevate callout results in an error response.
    */
    @isTest
    private static void shouldSetClosedReasonToErrorResponseMessageStatusWhenCancelFails() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        RD2_ElevateIntegrationService_TEST.enableElevateUserPermissions();
        PS_IntegrationService.setConfiguration(PS_IntegrationServiceConfig_TEST.testConfig);
        RD2_CancelCommitmentService.maxCancelRetries = 0;

        npe03__Recurring_Donation__c rd = RD2_ElevateIntegrationService_TEST.getElevateRecurringDonationBaseBuilder().build();
        insert rd;

        Test.startTest();
        UTIL_Http_TEST.mockBadRequestCalloutResponse();

        String closedReason = 'Original Reason';
        rd.ClosedReason__c = closedReason;
        rd.Status__c = RD2_Constants.STATUS_CLOSED;
        update rd;

        Test.stopTest();

        rd = rdGateway.getRecord(rd.Id);

        String expectedMessage = UTIL_Http_TEST.BAD_REQUEST_MESSAGE;
        System.assertEquals(expectedMessage, rd.ClosedReason__c,
            'RD Closed Reason be set to the error response message');

        assertCancelCommitmentError(expectedMessage, rd.Id);
    }

    /**
    * @description Verifies RD Closed Reason will be switched to
    * the user provided Closed Reason value
    * when the Commitment in Elevate cannot be found.
    */
    @isTest
    private static void shouldSetClosedReasonToUserSpecifiedValueWhenCommitmentCannotBeFound() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        RD2_ElevateIntegrationService_TEST.enableElevateUserPermissions();
        PS_IntegrationService.setConfiguration(PS_IntegrationServiceConfig_TEST.testConfig);
        RD2_CancelCommitmentService.maxCancelRetries = 0;

        npe03__Recurring_Donation__c rd = RD2_ElevateIntegrationService_TEST.getElevateRecurringDonationBaseBuilder().build();
        insert rd;

        Test.startTest();
        UTIL_Http_TEST.mockNotFoundCalloutResponse();

        String closedReason = 'Original Reason';
        rd.ClosedReason__c = closedReason;
        rd.Status__c = RD2_Constants.STATUS_CLOSED;
        update rd;

        Test.stopTest();

        rd = rdGateway.getRecord(rd.Id);
        System.assertEquals(UTIL_Http_TEST.MESSAGE_NOT_FOUND, rd.ClosedReason__c,
            'RD Closed Reason should contain the error response message');

        assertCancelCommitmentError(UTIL_Http_TEST.MESSAGE_NOT_FOUND, rd.Id);
    }

    /**
    * @description Verifies RD Closed Reason will be switched to
    * the user provided Closed Reason value
    * when the Commitment in Elevate is already cancelled.
    */
    @isTest
    private static void shouldSetClosedReasonToUserSpecifiedValueWhenCommitmentIsAlreadyCancelled() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        RD2_ElevateIntegrationService_TEST.enableElevateUserPermissions();
        PS_IntegrationService.setConfiguration(PS_IntegrationServiceConfig_TEST.testConfig);
        RD2_CancelCommitmentService.maxCancelRetries = 0;

        npe03__Recurring_Donation__c rd = RD2_ElevateIntegrationService_TEST.getElevateRecurringDonationBaseBuilder().build();
        insert rd;

        Test.startTest();
        UTIL_Http_TEST.mockDataConflictCalloutResponse();

        String closedReason = 'Original Reason';
        rd.ClosedReason__c = closedReason;
        rd.Status__c = RD2_Constants.STATUS_CLOSED;
        update rd;

        Test.stopTest();

        rd = rdGateway.getRecord(rd.Id);
        System.assertEquals(UTIL_Http_TEST.MESSAGE_DATA_CONFLICT, rd.ClosedReason__c,
            'RD Closed Reason should contain the error response message');

        assertCancelCommitmentError(UTIL_Http_TEST.MESSAGE_DATA_CONFLICT, rd.Id);
    }

    /**
    * @description Verifies RD Closed Reason will be switched to
    * the user provided Closed Reason value
    * when the Commitment in Elevate is cancelled.
    */
    @isTest
    private static void shouldSetClosedReasonToUserSpecifiedValueWhenCancelIsSuccess() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        RD2_ElevateIntegrationService_TEST.enableElevateUserPermissions();
        PS_IntegrationService.setConfiguration(PS_IntegrationServiceConfig_TEST.testConfig);
        RD2_CancelCommitmentService.maxCancelRetries = 0;

        npe03__Recurring_Donation__c rd = RD2_ElevateIntegrationService_TEST.getElevateRecurringDonationBaseBuilder().build();
        insert rd;

        Test.startTest();
        UTIL_Http_TEST.mockSuccessCalloutResponse(buildCommitmentCanceledResponseBody());

        String closedReason = 'Original Reason';
        rd.ClosedReason__c = closedReason;
        rd.Status__c = RD2_Constants.STATUS_CLOSED;
        update rd;

        Test.stopTest();

        rd = rdGateway.getRecord(rd.Id);
        System.assertEquals(closedReason, rd.ClosedReason__c,
            'RD Closed Reason should be swapped back to the user provided value');

        RD2_ElevateIntegrationService_TEST.assertNoError();
    }

    /***
    * @description Should recognize Elevate status is verified when confirmation not required
    */
    @isTest
    private static void shouldSetClosedReasonToOriginalErrorWhenElevateCancelNotVerified() {
    }

    /***
    * @description Should recognize Elevate status is verified when Elevate status is inactive
    */
    @isTest
    private static void shouldSetClosedReasonToUserSpecifiedValueWhenElevateCancelVerified() {
    }

    /***
    * @description Should recognize Elevate status is not verified when Elevate status is active
    */
    @isTest
    private static void shouldRetryWhenStatusIsActive() {
    }

    /**
    * @description Verifies that callout will be retried when the response to cancel times out
    */
    @isTest
    private static void shouldRetryWhenCommitmentWhenResponseIsTimeout() {
    }

    /**
    * @description Verifies that callout will be retried when the response to cancel is conflict.
    */
    @isTest
    private static void shouldRetryWhenCommitmentWhenResponseIsConflict() {
    }


    // Helpers
    ///////////////////

    /****
    * @description Builds a cancel commitment response body
    * returned when the commitment is successfully cancelled
    * @return String
    */
    public static String buildCommitmentCanceledResponseBody() {
        return '{"id":"' + COMMITMENT_ID
            + '","status":"INACTIVE","statusReason":"DONOR_CANCELED"'
            + '"}}';
    }

    /****
    * @description Verifies an error is created with
    * the specified error message and referencing expected record Id
    * @param message Expected error message
    * @param recordId Expected Recurring Donation Id
    * @return void
    */
    private static void assertCancelCommitmentError(String message, Id recordId) {
        RD2_ElevateIntegrationService_TEST.assertError(message, recordId, LOG_TYPE_COMMITMENT_CANCEL);
    }

}