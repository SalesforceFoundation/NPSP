/*
    Copyright (c) 2022 Salesforce.org
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
* @group Payment and Refund
* @description Payment Validation Service Test
*
*/
@IsTest
public with sharing class PMT_ValidationService_TEST {
    @IsTest
    private static void verifyNoErrorWillBeAddedOnCorrectFullRefund() {
        npe01__OppPayment__c originalPayment = new npe01__OppPayment__c(
            Id = UTIL_UnitTestData_TEST.mockId(npe01__OppPayment__c.SObjectType),
            npe01__Payment_Amount__c = 10,
            npe01__Paid__c = true
        );

        npe01__OppPayment__c refund = new npe01__OppPayment__c(
            npe01__Payment_Amount__c = -10,
            DebitType__c = PMT_RefundService.FULL_REFUND,
            OriginalPayment__c = originalPayment.Id
        );

        PMT_ValidationService validationService = new PMT_ValidationService(
            new List<npe01__OppPayment__c>{refund},
            null,
            TDTM_Runnable.Action.BeforeInsert
        );

        validationService.isEnforceAccountingDataConsistency = false;
        PMT_RefundService refundService = new PMT_RefundService()
            .withOriginalPayments(new List<npe01__OppPayment__c>{originalPayment});
    
        refundService.originalPaymentWithRefunds.put(
            originalPayment.Id, new PMT_RefundService.RefundInfo(originalPayment)
        );
        validationService.RefundService = refundService;

        Test.startTest();
        List<ErrorRecord> errorRecords = validationService.validate().getErrors();
        Test.stopTest();

        System.assertEquals(0, errorRecords.size(),
            'Expected no error to be returned.');
    }

    @IsTest
    private static void verifyNoErrorWillBeAddedOnCorrectPartialRefund() {
        npe01__OppPayment__c originalPayment = new npe01__OppPayment__c(
            Id = UTIL_UnitTestData_TEST.mockId(npe01__OppPayment__c.SObjectType),
            npe01__Payment_Amount__c = 100,
            npe01__Paid__c = true
        );

        List<npe01__OppPayment__c> refunds = new List<npe01__OppPayment__c> {
            new npe01__OppPayment__c(
                Id = UTIL_UnitTestData_TEST.mockId(npe01__OppPayment__c.SObjectType),
                npe01__Payment_Amount__c = -40,
                DebitType__c = PMT_RefundService.PARTIAL_REFUND,
                OriginalPayment__c = originalPayment.Id
            )
        };

        originalPayment = addRefundRelatedList(originalPayment, refunds);

        npe01__OppPayment__c newRefund = new npe01__OppPayment__c(
            npe01__Payment_Amount__c = -50,
            DebitType__c = PMT_RefundService.PARTIAL_REFUND,
            OriginalPayment__c = originalPayment.Id
        );
        PMT_ValidationService validationService = new PMT_ValidationService(
            new List<npe01__OppPayment__c>{newRefund},
            null,
            TDTM_Runnable.Action.BeforeInsert
        );

        validationService.isEnforceAccountingDataConsistency = false;
        PMT_RefundService refundService = new PMT_RefundService()
            .withOriginalPayments(new List<npe01__OppPayment__c>{originalPayment});
    
        refundService.originalPaymentWithRefunds.put(
            originalPayment.Id, new PMT_RefundService.RefundInfo(originalPayment)
        );
        validationService.RefundService = refundService;

        Test.startTest();
        List<ErrorRecord> errorRecords = validationService.validate().getErrors();
        Test.stopTest();

        System.assertEquals(0, errorRecords.size(),
            'Expected no error to be returned.');
    }

    @IsTest
    private static void verifyRefundsNeedToHaveAnOriginalPayment() {
        npe01__OppPayment__c refund = new npe01__OppPayment__c(
            npe01__Payment_Amount__c = -10,
            DebitType__c = PMT_RefundService.FULL_REFUND,
            OriginalPayment__c = null
            );

        PMT_ValidationService validationService = new PMT_ValidationService(
            new List<npe01__OppPayment__c>{refund},
            null,
            TDTM_Runnable.Action.BeforeInsert
        );
        validationService.isEnforceAccountingDataConsistency = false;    
    
        Test.startTest();
        List<ErrorRecord> errorRecords = validationService.validate().getErrors();
        Test.stopTest();

        System.assertEquals(1, errorRecords.size(),
            'There should be one error create when the refund does not have an original payment');
        System.assertEquals(System.Label.pmtOriginalPaymentNotFound, errorRecords[0].getFirstError(),
            'Original Payment not found error should be returned');
    }

    @IsTest
    private static void verifyRefundOriginalPaymentHasToBePaid() {
        npe01__OppPayment__c originalPayment = new npe01__OppPayment__c(
            Id = UTIL_UnitTestData_TEST.mockId(npe01__OppPayment__c.SObjectType),
            npe01__Payment_Amount__c = 10,
            npe01__Paid__c = false
        );

        npe01__OppPayment__c refund = new npe01__OppPayment__c(
            npe01__Payment_Amount__c = -10,
            DebitType__c = PMT_RefundService.FULL_REFUND,
            OriginalPayment__c = originalPayment.Id
        );

        PMT_ValidationService validationService = new PMT_ValidationService(
            new List<npe01__OppPayment__c>{refund},
            null,
            TDTM_Runnable.Action.BeforeInsert
        );
        validationService.isEnforceAccountingDataConsistency = false;

        PMT_RefundService refundService = new PMT_RefundService()
            .withOriginalPayments(new List<npe01__OppPayment__c>{originalPayment});
    
        refundService.originalPaymentWithRefunds.put(
            originalPayment.Id, new PMT_RefundService.RefundInfo(originalPayment)
        );
        validationService.RefundService = refundService;

        Test.startTest();
        List<ErrorRecord> errorRecords = validationService.validate().getErrors();
        Test.stopTest();

        System.assertEquals(1, errorRecords.size(),
            'Expecting an error collection to be returned');
        System.assertEquals(System.Label.pmtOriginalPaymentNotPaid, errorRecords[0].getFirstError(),
            'Original Payment should be paid error should be returned');
    }

    @IsTest
    private static void verifyRefundPaymentCannotBeRefunded() {
        npe01__OppPayment__c originalPayment = new npe01__OppPayment__c(
            Id = UTIL_UnitTestData_TEST.mockId(npe01__OppPayment__c.SObjectType),
            npe01__Payment_Amount__c = 10,
            DebitType__c = PMT_RefundService.FULL_REFUND,
            npe01__Paid__c = true
        );

        npe01__OppPayment__c refund = new npe01__OppPayment__c(
            npe01__Payment_Amount__c = -10,
            DebitType__c = PMT_RefundService.FULL_REFUND,
            OriginalPayment__c = originalPayment.Id
        );

        PMT_ValidationService validationService = new PMT_ValidationService(
            new List<npe01__OppPayment__c>{refund},
            null,
            TDTM_Runnable.Action.BeforeInsert
        );
        validationService.isEnforceAccountingDataConsistency = false;

        PMT_RefundService refundService = new PMT_RefundService()
            .withOriginalPayments(new List<npe01__OppPayment__c>{originalPayment});
    
        refundService.originalPaymentWithRefunds.put(
            originalPayment.Id, new PMT_RefundService.RefundInfo(originalPayment)
        );
        validationService.RefundService = refundService;

        Test.startTest();
        List<ErrorRecord> errorRecords = validationService.validate().getErrors();
        Test.stopTest();

        System.assertEquals(1, errorRecords.size(),
            'Expecting an error collection to be returned');
        System.assertEquals(System.Label.pmtPaymentNotRefundable, errorRecords[0].getFirstError(),
            'Original Payment cannot be a refund payment');
    }

    @IsTest
    private static void verifyCanNotRefundMoreThanRemainingBalance() {
        npe01__OppPayment__c originalPayment = new npe01__OppPayment__c(
            Id = UTIL_UnitTestData_TEST.mockId(npe01__OppPayment__c.SObjectType),
            npe01__Payment_Amount__c = 10,
            npe01__Paid__c = true
        );

        npe01__OppPayment__c refund = new npe01__OppPayment__c(
            npe01__Payment_Amount__c = -11,
            DebitType__c = PMT_RefundService.FULL_REFUND,
            OriginalPayment__c = originalPayment.Id
        );

        PMT_ValidationService validationService = new PMT_ValidationService(
            new List<npe01__OppPayment__c>{refund},
            null,
            TDTM_Runnable.Action.BeforeInsert
        );

        validationService.isEnforceAccountingDataConsistency = false;
        PMT_RefundService refundService = new PMT_RefundService()
            .withOriginalPayments(new List<npe01__OppPayment__c>{originalPayment});
    
        refundService.originalPaymentWithRefunds.put(
            originalPayment.Id, new PMT_RefundService.RefundInfo(originalPayment)
        );
        validationService.RefundService = refundService;

        Test.startTest();
        List<ErrorRecord> errorRecords = validationService.validate().getErrors();
        Test.stopTest();

        System.assertEquals(1, errorRecords.size(),
            'Expecting an error collection to be returned');
        System.assertEquals(System.Label.pmtRefundAmountInvalid, errorRecords[0].getFirstError(),
            'Refund cannot be greater than the original payment amount');
    }

    @IsTest
    private static void verifyRefundCannotBeMadeOnFullyRefundPayment() {
        npe01__OppPayment__c originalPayment = new npe01__OppPayment__c(
            Id = UTIL_UnitTestData_TEST.mockId(npe01__OppPayment__c.SObjectType),
            npe01__Payment_Amount__c = 10,
            npe01__Paid__c = true
        );

        npe01__OppPayment__c refund = new npe01__OppPayment__c(
            npe01__Payment_Amount__c = -10,
            DebitType__c = PMT_RefundService.FULL_REFUND,
            OriginalPayment__c = originalPayment.Id
        );
       
        originalPayment = addRefundRelatedList(originalPayment, new List<SObject>{refund});

        PMT_ValidationService validationService = new PMT_ValidationService(
            new List<npe01__OppPayment__c>{refund},
            null,
            TDTM_Runnable.Action.BeforeInsert
        );

        validationService.isEnforceAccountingDataConsistency = false;
        PMT_RefundService refundService = new PMT_RefundService()
            .withOriginalPayments(new List<npe01__OppPayment__c>{originalPayment});
    
        refundService.originalPaymentWithRefunds.put(
            originalPayment.Id, new PMT_RefundService.RefundInfo(originalPayment)
        );
        validationService.RefundService = refundService;

        Test.startTest();
        List<ErrorRecord> errorRecords = validationService.validate().getErrors();
        Test.stopTest();

        System.assertEquals(1, errorRecords.size(),
            'Expecting an error collection to be returned');
        System.assertEquals(System.Label.pmtPaymentNotRefundable, errorRecords[0].getFirstError(),
            'Refund cannot be processed when the payment is fully refunded');
    }

    @IsTest
    private static void verifyPartialRefundCannotExceedRemainingBalance() {
        npe01__OppPayment__c originalPayment = new npe01__OppPayment__c(
            Id = UTIL_UnitTestData_TEST.mockId(npe01__OppPayment__c.SObjectType),
            npe01__Payment_Amount__c = 100,
            npe01__Paid__c = true
        );

        List<npe01__OppPayment__c> refunds = new List<npe01__OppPayment__c> {
            new npe01__OppPayment__c(
                Id = UTIL_UnitTestData_TEST.mockId(npe01__OppPayment__c.SObjectType),
                npe01__Payment_Amount__c = -40,
                DebitType__c = PMT_RefundService.PARTIAL_REFUND,
                OriginalPayment__c = originalPayment.Id
            ),
            new npe01__OppPayment__c(
                Id = UTIL_UnitTestData_TEST.mockId(npe01__OppPayment__c.SObjectType),
                npe01__Payment_Amount__c = -40,
                DebitType__c = PMT_RefundService.PARTIAL_REFUND,
                OriginalPayment__c = originalPayment.Id
            )
        };

        originalPayment = addRefundRelatedList(originalPayment, refunds);

        npe01__OppPayment__c newRefund = new npe01__OppPayment__c(
            npe01__Payment_Amount__c = -21,
            DebitType__c = PMT_RefundService.PARTIAL_REFUND,
            OriginalPayment__c = originalPayment.Id
        );
        PMT_ValidationService validationService = new PMT_ValidationService(
            new List<npe01__OppPayment__c>{newRefund},
            null,
            TDTM_Runnable.Action.BeforeInsert
        );

        validationService.isEnforceAccountingDataConsistency = false;
        PMT_RefundService refundService = new PMT_RefundService()
            .withOriginalPayments(new List<npe01__OppPayment__c>{originalPayment});
    
        refundService.originalPaymentWithRefunds.put(
            originalPayment.Id, new PMT_RefundService.RefundInfo(originalPayment)
        );
        validationService.RefundService = refundService;

        Test.startTest();
        List<ErrorRecord> errorRecords = validationService.validate().getErrors();
        Test.stopTest();

        System.assertEquals(1, errorRecords.size(),
            'Expecting an error collection to be returned');
        System.assertEquals(System.Label.pmtRefundAmountInvalid, errorRecords[0].getFirstError(),
            'Refund cannot be processed when the payment is fully refunded');
    }

    @IsTest
    private static void verifyElevatePaymenCanBeModifiedWithIntegrationUserPermission() {
        npe01__OppPayment__c payment = new npe01__OppPayment__c(
            Id = UTIL_UnitTestData_TEST.mockId(npe01__OppPayment__c.SObjectType),
            npe01__Payment_Amount__c = 10,
            npe01__Paid__c = true,
            Elevate_Payment_ID__c = 'Random'
        );

        npe01__OppPayment__c oldPayment = payment.clone(true);
        oldPayment.npe01__Payment_Amount__c = payment.npe01__Payment_Amount__c + 10;

        PMT_ValidationService validationService = new PMT_ValidationService(
            new List<npe01__OppPayment__c>{payment},
            new List<npe01__OppPayment__c>{oldPayment},
            TDTM_Runnable.Action.BeforeUpdate
        );
        validationService.isEnforceAccountingDataConsistency = false;

        PS_IntegrationServiceConfig_TEST.Stub configStub = new PS_IntegrationServiceConfig_TEST.Stub()
            .withIsIntegrationEnabled(true)
            .withHasIntegrationPermissions(true);
        PMT_ValidationService.config = (PS_IntegrationServiceConfig) Test.createStub(
            PS_IntegrationServiceConfig.class,
            configStub
        );

        Test.startTest();
        List<ErrorRecord> errorRecords = validationService.validate().getErrors();
        Test.stopTest();

        System.assertEquals(0, errorRecords.size(),
            'No error record colleciton should be returned');
    }

    @IsTest
    private static void verifyElevatePaymentCannotBeModifiedWithoutEditPermission() {
        npe01__OppPayment__c payment = new npe01__OppPayment__c(
            Id = UTIL_UnitTestData_TEST.mockId(npe01__OppPayment__c.SObjectType),
            npe01__Payment_Amount__c = 10,
            npe01__Paid__c = true,
            Elevate_Payment_ID__c = 'Random'
        );

        npe01__OppPayment__c oldPayment = payment.clone(true);
        oldPayment.npe01__Payment_Amount__c = payment.npe01__Payment_Amount__c + 10;

        PMT_ValidationService validationService = new PMT_ValidationService(
            new List<npe01__OppPayment__c>{payment},
            new List<npe01__OppPayment__c>{oldPayment},
            TDTM_Runnable.Action.BeforeUpdate
        );
        validationService.isEnforceAccountingDataConsistency = false;

        PS_IntegrationServiceConfig_TEST.Stub configStub = new PS_IntegrationServiceConfig_TEST.Stub()
            .withIsIntegrationEnabled(true)
            .withHasIntegrationPermissions(false);
        PMT_ValidationService.config = (PS_IntegrationServiceConfig) Test.createStub(
            PS_IntegrationServiceConfig.class,
            configStub
        );

        Test.startTest();
        List<ErrorRecord> errorRecords = validationService.validate().getErrors();
        Test.stopTest();

        System.assertEquals(1, errorRecords.size(),
            'Expecting an error collection to be returned');
        System.assertEquals(System.Label.pmtElevatePermissionRequired, errorRecords[0].getFirstError(),
            'Cannot update Elevate payment without integrationPermission');
    }

    @IsTest
    private static void verifyAddingPaymentToElevateWillNotRunValidation() {
        npe01__OppPayment__c originalPayment = new npe01__OppPayment__c(
            Id = UTIL_UnitTestData_TEST.mockId(npe01__OppPayment__c.SObjectType),
            npe01__Payment_Amount__c = 10,
            npe01__Paid__c = true
        );

        npe01__OppPayment__c updatedPayment = originalPayment.clone(true);
        updatedPayment.Elevate_Payment_ID__c = 'Random';

        PMT_ValidationService validationService = new PMT_ValidationService(
            new List<npe01__OppPayment__c>{updatedPayment},
            new List<npe01__OppPayment__c>{originalPayment},
            TDTM_Runnable.Action.BeforeUpdate
        );

        validationService.isEnforceAccountingDataConsistency = false;
        PS_IntegrationServiceConfig_TEST.Stub configStub = new PS_IntegrationServiceConfig_TEST.Stub()
        .withIsIntegrationEnabled(true)
        .withHasIntegrationPermissions(false);

        PMT_ValidationService.config = (PS_IntegrationServiceConfig) Test.createStub(
            PS_IntegrationServiceConfig.class,
            configStub
        );

        Test.startTest();
        List<ErrorRecord> errorRecords = validationService.validate().getErrors();
        Test.stopTest();

        System.assertEquals(0, errorRecords.size(),
            'Expecting Elevate validation should not run against newly added Elevate payment.');
    }

    @IsTest
    private static void verifyElevateRefundWillNotBeValidate() {
        npe01__OppPayment__c originalPayment = new npe01__OppPayment__c(
            Id = UTIL_UnitTestData_TEST.mockId(npe01__OppPayment__c.SObjectType),
            npe01__Payment_Amount__c = 10,
            npe01__Paid__c = true,
            Elevate_Payment_ID__c = 'random'
        );

        npe01__OppPayment__c refund = new npe01__OppPayment__c(
            npe01__Payment_Amount__c = -11,
            DebitType__c = PMT_RefundService.FULL_REFUND,
            OriginalPayment__c = originalPayment.Id,
            Elevate_Payment_ID__c = 'random'
        );

        PMT_ValidationService validationService = new PMT_ValidationService(
            new List<npe01__OppPayment__c>{refund},
            null,
            TDTM_Runnable.Action.BeforeInsert
        );

        validationService.isEnforceAccountingDataConsistency = false;
        PS_IntegrationServiceConfig_TEST.Stub configStub = new PS_IntegrationServiceConfig_TEST.Stub()
        .withIsIntegrationEnabled(true)
        .withHasIntegrationPermissions(false);

        PMT_ValidationService.config = (PS_IntegrationServiceConfig) Test.createStub(
            PS_IntegrationServiceConfig.class,
            configStub
        );

        PMT_RefundService refundService = new PMT_RefundService()
            .withOriginalPayments(new List<npe01__OppPayment__c>{originalPayment});
    
        refundService.originalPaymentWithRefunds.put(
            originalPayment.Id, new PMT_RefundService.RefundInfo(originalPayment)
        );
        validationService.RefundService = refundService;

        Test.startTest();
        List<ErrorRecord> errorRecords = validationService.validate().getErrors();
        Test.stopTest();

        System.assertEquals(0, errorRecords.size(),
            'Expecting refund validation should not run against Elevate refund record.');
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