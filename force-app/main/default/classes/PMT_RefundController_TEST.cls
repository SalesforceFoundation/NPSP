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
* @group Payment
* @description Test class for PMT_RefundController
*/
@IsTest
public with sharing class PMT_RefundController_TEST {
    @isTest
    private static void userWithNoPermissionShouldNotBeAbleToPerformAnyRefundAction() {
        User readOnlyUser = UTIL_UnitTestData_TEST.createUser(UTIL_UnitTestData_TEST.PROFILE_READONLY_USER);

        System.runAs(readOnlyUser) {
            PMT_RefundController.RefundView initialRefundView = PMT_RefundController.getInitialView(null);
            PMT_RefundController.RefundView afterRefundView = PMT_RefundController.processRefund(null);

            System.assertEquals(false, initialRefundView.hasRequiredPermissions, 'Read-only user should not have access to refund');
            System.assertEquals(false, afterRefundView.hasRequiredPermissions, 'Read-only user should not be able to refund');
        }
    }

    @isTest
    private static void verifyRefundCalloutIsMadeWhenPaymentIsAnElevateRecord() {
        PS_IntegrationServiceConfig_TEST.enableElevateIntegrationService();
        PaymentSelector_TEST.Stub selectorStub = new PaymentSelector_TEST.Stub();
        npe01__OppPayment__c payment = getElevatePaymentRecord();
        selectorStub.paymentRecords = new List<npe01__OppPayment__c>{ payment };

        PMT_RefundController.paymentSelector = (PaymentSelector) Test.createStub(
            PaymentSelector.class,
            selectorStub
        );

        UTIL_Http_TEST.CalloutMock calloutMock = UTIL_Http_TEST.mockSuccessCalloutResponse(null);

        Test.startTest();
        PMT_RefundController.RefundView refundView = PMT_RefundController.processRefund(payment.Id);
        Test.stopTest();

        System.assertEquals(1, calloutMock.getCalloutCounter(),
            '1 callout should be made when the refund callout is made');
        System.assertEquals(true, refundView.isSuccess,
            'The Refund View should mark as success when the callout is successfully made');
        System.assertEquals(payment.Id, refundView.redirectToPaymentId,
            'The redirect Id should set to the original payment Id when the payment is an Elevate record');
    }

    @isTest
    private static void verifyTheErrorMessageWillBePopulatedCorrectlyWhenElevateCalloutFail() {
        PS_IntegrationServiceConfig_TEST.enableElevateIntegrationService();
        UTIL_Http_TEST.CalloutMock calloutMock = UTIL_Http_TEST.mockNotFoundCalloutResponse();

        PaymentSelector_TEST.Stub selectorStub = new PaymentSelector_TEST.Stub();
        npe01__OppPayment__c payment = getElevatePaymentRecord();
        selectorStub.paymentRecords = new List<npe01__OppPayment__c>{ payment };

        PMT_RefundController.paymentSelector = (PaymentSelector) Test.createStub(
            PaymentSelector.class,
            selectorStub
        );

        Test.startTest();
        PMT_RefundController.RefundView refundView = PMT_RefundController.processRefund(payment.Id);
        Test.stopTest();

        System.assertEquals(1, calloutMock.getCalloutCounter(),
            '1 callout should be made when the refund callout is made');
        System.assertEquals(false, refundView.isSuccess,
            'The Refund View should mark as not success when the callout failed');
        System.assertEquals(System.Label.pmtPaymentNotFund, refundView.errorMessage,
            'The error message should be added to the view when the callout failed');
    }

    @isTest
    private static void verifyRefundRecordIdShouldBeReturnedOnSuccessfulRefund() {
        PS_IntegrationServiceConfig_TEST.enableElevateIntegrationService();
        npe01__OppPayment__c refundRecord = getPaymentRecord();

        PMT_RefundService_TEST.Stub refundServiceStub = new PMT_RefundService_TEST.Stub();
        refundServiceStub.refundRecords = new List<npe01__OppPayment__c>{ refundRecord };

        PMT_RefundController.refundService = (PMT_RefundService) Test.createStub(
            PMT_RefundService.class,
            refundServiceStub
        );

        PaymentSelector_TEST.Stub selectorStub = new PaymentSelector_TEST.Stub();
        selectorStub.paymentRecords = new List<npe01__OppPayment__c>{ refundRecord };

        PMT_RefundController.paymentSelector = (PaymentSelector) Test.createStub(
            PaymentSelector.class,
            selectorStub
        );

        Test.startTest();
        PMT_RefundController.RefundView refundView = PMT_RefundController.processRefund(UTIL_UnitTestData_TEST.mockId(npe01__OppPayment__c.SObjectType));
        Test.stopTest();

        System.assertEquals(refundRecord.Id, refundView.redirectToPaymentId,
            'The refund record should exist when the refund is successful');
    }

    @isTest
    private static void verifyDoubleRefundErrorShouldBeReturnWhenRefundProcessFail() {
        PS_IntegrationServiceConfig_TEST.enableElevateIntegrationService();

        ERR_Handler.Errors errorResult = new ERR_Handler.Errors();
        errorResult.errorsExist = true;
        errorResult.errorRecords.add(
            ERR_Handler.createError(System.Label.pmtPaymentNotRefundable, 'random')
        );

        PMT_RefundService_TEST.Stub refundServiceStub = new PMT_RefundService_TEST.Stub();
        refundServiceStub.errors = errorResult;

        PMT_RefundController.refundService = (PMT_RefundService) Test.createStub(
            PMT_RefundService.class,
            refundServiceStub
        );

        PaymentSelector_TEST.Stub selectorStub = new PaymentSelector_TEST.Stub();
        selectorStub.paymentRecords = new List<npe01__OppPayment__c>{ getPaymentRecord() };

        PMT_RefundController.paymentSelector = (PaymentSelector) Test.createStub(
            PaymentSelector.class,
            selectorStub
        );

        Test.startTest();
        PMT_RefundController.RefundView refundView = PMT_RefundController.processRefund(UTIL_UnitTestData_TEST.mockId(npe01__OppPayment__c.SObjectType));
        Test.stopTest();

        System.assertEquals(false, refundView.isSuccess,
            'The process should fail and the view should set to not successful');
        System.assertEquals(null, refundView.redirectToPaymentId,
            'No redirection Id should be set');
        System.assertEquals(System.Label.pmtPaymentNotRefundable, refundView.errorMessage,
            'The error message from the error record should be set onto the Refund View');
    }

    private static npe01__OppPayment__c getElevatePaymentRecord() {
        return new npe01__OppPayment__c(
            Id = UTIL_UnitTestData_TEST.mockId(npe01__OppPayment__c.SObjectType),
            npe01__Paid__c = true,
            npe01__Payment_Amount__c = 250,
            npe01__Opportunity__c = UTIL_UnitTestData_TEST.mockId(Opportunity.SObjectType),
            Elevate_Payment_ID__c = 'random-id'
        );
    }

    private static npe01__OppPayment__c getPaymentRecord() {
        return new npe01__OppPayment__c(
            Id = UTIL_UnitTestData_TEST.mockId(npe01__OppPayment__c.SObjectType),
            npe01__Paid__c = true,
            npe01__Payment_Amount__c = 250,
            npe01__Opportunity__c = UTIL_UnitTestData_TEST.mockId(Opportunity.SObjectType)
        );
    }
}
