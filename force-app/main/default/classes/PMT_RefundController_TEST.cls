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
    @IsTest
    private static void userWithNoPermissionShouldNotBeAbleToPerformAnyRefundAction() {
        User readOnlyUser = UTIL_UnitTestData_TEST.createUser(UTIL_UnitTestData_TEST.PROFILE_READONLY_USER);

        System.runAs(readOnlyUser) {
            PMT_RefundController.RefundView initialRefundView = PMT_RefundController.getInitialView(null);
            PMT_RefundController.RefundView afterRefundView = PMT_RefundController.processRefund(null, null);

            System.assertEquals(false, initialRefundView.hasRequiredPermissions, 'Read-only user should not have access to refund');
            System.assertEquals(false, afterRefundView.hasRequiredPermissions, 'Read-only user should not be able to refund');
        }
    }

    @IsTest
    private static void verifyCalloutIsMadeToRetrieveElevateRefundInformation() {
        Decimal refundAmount = 984.21;
        PS_IntegrationServiceConfig_TEST.enableElevateIntegrationService();

        npe01__OppPayment__c payment = getElevatePaymentRecord();
        PMT_RefundService refundService = new PMT_RefundService()
        .withOriginalPayments(new List<npe01__OppPayment__c>{payment});

        refundService.originalPaymentWithRefunds.put(
            payment.Id, new PMT_RefundService.RefundInfo(payment)
        );
        PMT_RefundController.RefundService = refundService;
        Map<String, Object> successResponseBody = new Map<String, Object> {
            'remainingBalance' => refundAmount * PS_CommitmentRequest.DEFAULT_CURRENCY_MULTIPLIER
        };
        UTIL_Http_TEST.CalloutMock calloutMock = UTIL_Http_TEST.mockSuccessCalloutResponse(JSON.serialize(successResponseBody));

        Test.startTest();
        PMT_RefundController.RefundView refundView = PMT_RefundController.getInitialView(payment.Id);
        Test.stopTest();

        System.assertEquals(1, calloutMock.getCalloutCounter(),
            '1 callout should be made when the refund callout is made');
        System.assertEquals(
            refundAmount,
            refundView.remainingBalance,
            'Remaining Balance should be stored into refund view and is converted to displayed format');
    }

    @IsTest
    private static void verifyRefundCalloutIsMadeWhenPaymentIsAnElevateRecord() {
        PS_IntegrationServiceConfig_TEST.enableElevateIntegrationService();

        npe01__OppPayment__c payment = getElevatePaymentRecord();
        PMT_RefundService refundService = new PMT_RefundService()
        .withOriginalPayments(new List<npe01__OppPayment__c>{payment});

        refundService.originalPaymentWithRefunds.put(
            payment.Id, new PMT_RefundService.RefundInfo(payment)
        );
        PMT_RefundController.RefundService = refundService;

        UTIL_Http_TEST.CalloutMock calloutMock = UTIL_Http_TEST.mockSuccessCalloutResponse(null);

        Test.startTest();
        PMT_RefundController.RefundView refundView = PMT_RefundController.processRefund(payment.Id, payment.npe01__Payment_Amount__c);
        Test.stopTest();

        System.assertEquals(1, calloutMock.getCalloutCounter(),
            '1 callout should be made when the refund callout is made');
        System.assertEquals(true, refundView.isSuccess,
            'The Refund View should mark as success when the callout is successfully made');
        System.assertEquals(payment.Id, refundView.redirectToPaymentId,
            'The redirect Id should set to the original payment Id when the payment is an Elevate record');
    }

    @IsTest
    private static void verifyTheErrorMessageWillBePopulatedCorrectlyWhenElevateCalloutFail() {
        PS_IntegrationServiceConfig_TEST.enableElevateIntegrationService();
        UTIL_Http_TEST.CalloutMock calloutMock = UTIL_Http_TEST.mockNotFoundCalloutResponse();

        npe01__OppPayment__c payment = getElevatePaymentRecord();
        PMT_RefundService refundService = new PMT_RefundService()
        .withOriginalPayments(new List<npe01__OppPayment__c>{payment});

        refundService.originalPaymentWithRefunds.put(
            payment.Id, new PMT_RefundService.RefundInfo(payment)
        );
        PMT_RefundController.RefundService = refundService;

        Test.startTest();
        PMT_RefundController.RefundView refundView = PMT_RefundController.processRefund(payment.Id, payment.npe01__Payment_Amount__c);
        Test.stopTest();

        System.assertEquals(1, calloutMock.getCalloutCounter(),
            '1 callout should be made when the refund callout is made');
        System.assertEquals(false, refundView.isSuccess,
            'The Refund View should mark as not success when the callout failed');
        System.assertEquals(System.Label.pmtPaymentNotFound, refundView.errorMessage,
            'The error message should be added to the view when the callout failed');
    }

    @IsTest
    private static void verifyRefundRecordIdShouldBeReturnedOnSuccessfulRefund() {
        npe01__OppPayment__c payment = getPaymentRecord();
        npe01__OppPayment__c refund = getFullRefundRecord(payment.Id);

        PMT_RefundService_TEST.Stub refundServiceStub = new PMT_RefundService_TEST.Stub();
        refundServiceStub.refundRecords = new List<npe01__OppPayment__c>{ refund };
        refundServiceStub.refundInfo = new PMT_RefundService.RefundInfo( payment );
        PMT_RefundController.refundService = (PMT_RefundService) Test.createStub(
            PMT_RefundService.class,
            refundServiceStub
        );

        Test.startTest();
        PMT_RefundController.RefundView refundView = PMT_RefundController.processRefund(payment.Id, payment.npe01__Payment_Amount__c);
        Test.stopTest();

        System.assertEquals(refund.Id, refundView.redirectToPaymentId,
            'The refund record should exist when the refund is successful');
    }

    @IsTest
    private static void verifyDoubleRefundErrorShouldBeReturnWhenRefundProcessFail() {
        npe01__OppPayment__c payment = getPaymentRecord();
        
        payment = addRefundRelatedList(payment, new List<npe01__OppPayment__c>{getFullRefundRecord(payment.Id)});
        npe01__OppPayment__c doubleRefund = getFullRefundRecord(payment.Id);
        doubleRefund.Id = null;
        PMT_RefundService_TEST.Stub refundServiceStub = new PMT_RefundService_TEST.Stub();
        refundServiceStub.refundRecords = new List<npe01__OppPayment__c>{ doubleRefund };
        refundServiceStub.refundInfo = new PMT_RefundService.RefundInfo( payment );
        PMT_RefundController.refundService = (PMT_RefundService) Test.createStub(
            PMT_RefundService.class,
            refundServiceStub
        );

        Test.startTest();
        PMT_RefundController.RefundView refundView = PMT_RefundController.processRefund(payment.Id, payment.npe01__Payment_Amount__c);
        Test.stopTest();

        System.assertEquals(false, refundView.isSuccess,
            'The process should fail and the view should set to not successful');
        System.assertEquals(null, refundView.redirectToPaymentId,
            'No redirection Id should be set');
        System.assertEquals(System.Label.pmtPaymentNotRefundable, refundView.errorMessage,
            'The error message from the error record should be set onto the Refund View');
    }

    private static npe01__OppPayment__c getElevatePaymentRecord() {
        npe01__OppPayment__c payment = getPaymentRecord();
        payment.Elevate_Payment_ID__c = 'random-Id';
        return payment;
    }

    private static npe01__OppPayment__c getPaymentRecord() {

        Opportunity opportunity = new Opportunity(
            Id = UTIL_UnitTestData_TEST.mockId(Opportunity.SObjectType),
            Amount = 1000
        );

        return new npe01__OppPayment__c(
            Id = UTIL_UnitTestData_TEST.mockId(npe01__OppPayment__c.SObjectType),
            npe01__Paid__c = true,
            npe01__Payment_Amount__c = 250,
            npe01__Opportunity__c = opportunity.Id
        );
    }

    private static npe01__OppPayment__c getFullRefundRecord(Id originalPaymentId) {
        return new npe01__OppPayment__c(
            Id = UTIL_UnitTestData_TEST.mockId(npe01__OppPayment__c.SObjectType),
            npe01__Payment_Amount__c = -250,
            DebitType__c = PMT_RefundService.FULL_REFUND,
            npe01__Opportunity__c = UTIL_UnitTestData_TEST.mockId(Opportunity.SObjectType),
            OriginalPayment__c = originalPaymentId
        );
    }

    private static npe01__OppPayment__c addRefundRelatedList(npe01__OppPayment__c payment, List<SObject> records) {
        String paymentRecord = JSON.serialize(payment);
        paymentRecord = paymentRecord.left(paymentRecord.length()-1);

        String objJson = JSON.serialize(records);
        paymentRecord += ',"' + UTIL_Namespace.StrTokenNSPrefix('Refunds__r') + '":{"totalSize":' + records.size() + ',"done":true,"records":' + objJson + '}';

        paymentRecord += '}';

        return (npe01__OppPayment__c)JSON.deserialize(paymentRecord, npe01__OppPayment__c.class);
    }
}
