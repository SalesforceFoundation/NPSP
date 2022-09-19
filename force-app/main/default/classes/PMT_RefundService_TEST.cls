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
* @description Test class for PMT_RefundService
*/
@IsTest
public with sharing class PMT_RefundService_TEST {
    private static final TEST_SObjectGateway.PaymentGateway paymentGateway = new TEST_SObjectGateway.PaymentGateway();
    private static final TEST_SObjectGateway.OpportunityGateway oppGateway = new TEST_SObjectGateway.OpportunityGateway();
    
    @isTest
    private static void verifyRefundEndpointCanBeCalloutSuccessfully() {
        PS_IntegrationServiceConfig_TEST.enableElevateIntegrationService();
        UTIL_Http_TEST.CalloutMock calloutMock = UTIL_Http_TEST.mockSuccessCalloutResponse(null);
        PMT_RefundService refundService = new PMT_RefundService();
        Test.startTest();
        UTIL_Http.Response response = refundService.processElevateRefund('random-id',10);
        Test.stopTest();

        System.assertEquals(1, calloutMock.getCalloutCounter(),
            '1 callout should be made when the refund callout is made');
        System.assertEquals(UTIL_Http.STATUS_CODE_OK, response.statusCode,
            'The status code should return OK when the callout is successful');
    }

    @isTest
    private static void verifyReturnNotFoundErrorWhenStatusCodeIs404() {
        PS_IntegrationServiceConfig_TEST.enableElevateIntegrationService();
        UTIL_Http_TEST.CalloutMock calloutMock = UTIL_Http_TEST.mockNotFoundCalloutResponse();
        PMT_RefundService refundService = new PMT_RefundService();
        Test.startTest();
        UTIL_Http.Response response = refundService.processElevateRefund('random-id', 10);
        Test.stopTest();

        System.assertEquals(1, calloutMock.getCalloutCounter(),
            '1 callout should be made when the refund callout is made');
        System.assertEquals(UTIL_Http.STATUS_CODE_NOT_FOUND, response.statusCode,
            'The status code should return 404 not found when the Elevate record cannot be found');
        System.assertEquals(System.Label.pmtPaymentNotFound, response.getErrorMessages(),
            'The response body should be convert to original payment not found error message');
    }

    @isTest
    private static void verifyReturnNotRefundableErrorWhenStatusCodeIs409() {
        PS_IntegrationServiceConfig_TEST.enableElevateIntegrationService();
        UTIL_Http_TEST.CalloutMock calloutMock = UTIL_Http_TEST.mockDataConflictCalloutResponse();
        PMT_RefundService refundService = new PMT_RefundService();
        Test.startTest();
        UTIL_Http.Response response = refundService.processElevateRefund('random-id', 10);
        Test.stopTest();

        System.assertEquals(1, calloutMock.getCalloutCounter(),
            '1 callout should be made when the refund callout is made');
        System.assertEquals(UTIL_Http.STATUS_CODE_CONFLICT, response.statusCode,
            'The status code should return 409 conflic when the payment is not refundable');
        System.assertEquals(System.Label.pmtPaymentNotRefundable, response.getErrorMessages(),
            'The response body should be convert to not refundable error message');
    }

    @isTest
    private static void verifyReturnPaymentNotCompleteErrorWhenStatusCodeIs422() {
        PS_IntegrationServiceConfig_TEST.enableElevateIntegrationService();
        UTIL_Http_TEST.CalloutMock calloutMock = UTIL_Http_TEST.mockDataUnprocessableResponse();
        PMT_RefundService refundService = new PMT_RefundService();
        Test.startTest();
        UTIL_Http.Response response = refundService.processElevateRefund('random-id', 10);
        Test.stopTest();

        System.assertEquals(1, calloutMock.getCalloutCounter(),
            '1 callout should be made when the refund callout is made');
        System.assertEquals(UTIL_Http.STATUS_CODE_UNPROCESSABLE_ENTITY, response.statusCode,
            'The status code should return 422 unprocessable when the transaction is not completed');
        System.assertEquals(System.Label.pmtOriginalPaymentNotCompleted, response.getErrorMessages(),
            'The response body should be convert to original transaction is not completed error message');
    }

    @isTest
    private static void verifyAPaymentCanBeFullyRefunded() {
        npe01__OppPayment__c originalPayment = getPaymentRecord ();
        PaymentSelector_TEST.Stub selectorStub = new PaymentSelector_TEST.Stub();
        selectorStub.paymentRecords = new List<npe01__OppPayment__c>{ originalPayment };

        PMT_RefundService refundService = new PMT_RefundService(); 
        refundService.paymentSelector = (PaymentSelector) Test.createStub(
            PaymentSelector.class,
            selectorStub
        );
  
        Test.startTest();
        refundService.withOriginalPayments( new List<npe01__OppPayment__c>{originalPayment} );
        refundService.buildRefundRecord(originalPayment, originalPayment.npe01__Payment_Amount__c);
        refundService.updateParentOpportunity(originalPayment, originalPayment.npe01__Payment_Amount__c);
        Test.stopTest();

        npe01__OppPayment__c refundRecord = refundService.getRefundRecords()?.get(0);
        Opportunity parentOpp = refundService.opportunityMap.values()?.get(0);

        System.assertEquals(1,refundService.getRefundRecords().size(),
            'A refund record should be created');
        System.assertEquals(originalPayment.npe01__Payment_Amount__c, -1 * refundRecord.npe01__Payment_Amount__c,
            'The amount on the refund record should match the original payment amont but negative');
        System.assertEquals(originalPayment.Id, refundRecord.originalPayment__c,
            'The refund record should map to the original payment record');
        System.assertEquals(PMT_RefundService.FULL_REFUND, refundRecord.DebitType__c,
            'The original payment refund type should be set to: ' + PMT_RefundService.FULL_REFUND);
        System.assertNotEquals(null, parentOpp, 'The parent opportunity should be proccessed');
        System.assertEquals(0, parentOpp.Amount, 'The opporunity amount should be set to 0 after the refund');
    }

    @isTest
    private static void verifyAPaymentCanBePartiallyRefunded() {
        npe01__OppPayment__c originalPayment = getPaymentRecord ();
        Decimal originalAmount = originalPayment.npe01__Payment_Amount__c;
        Decimal refundAmount = originalPayment.npe01__Payment_Amount__c / 2;
        PaymentSelector_TEST.Stub selectorStub = new PaymentSelector_TEST.Stub();
        selectorStub.paymentRecords = new List<npe01__OppPayment__c>{ originalPayment };

        PMT_RefundService refundService = new PMT_RefundService(); 
        refundService.paymentSelector = (PaymentSelector) Test.createStub(
            PaymentSelector.class,
            selectorStub
        );
  
        Test.startTest();
        refundService.withOriginalPayments( new List<npe01__OppPayment__c>{originalPayment} );
        refundService.buildRefundRecord(originalPayment, refundAmount);
        refundService.updateParentOpportunity(originalPayment, refundAmount);
        Test.stopTest();

        npe01__OppPayment__c refundRecord = refundService.getRefundRecords()?.get(0);
        Opportunity parentOpp = refundService.opportunityMap.values()?.get(0);

        System.assertEquals(1,refundService.getRefundRecords().size(),
            'A refund record should be created');
        System.assertEquals(refundAmount, -1 * refundRecord.npe01__Payment_Amount__c,
            'The amount on the refund record should match the original payment amont but negative');
        System.assertEquals(originalPayment.Id, refundRecord.originalPayment__c,
            'The refund record should map to the original payment record');
        System.assertEquals(PMT_RefundService.PARTIAL_REFUND, refundRecord.DebitType__c,
            'The refund type should be set to: ' + PMT_RefundService.PARTIAL_REFUND);
        System.assertNotEquals(null, parentOpp, 'The parent opportunity should be proccessed');
        System.assertEquals(originalAmount - refundAmount, parentOpp.Amount,
            'Partial Refund Amount should be deducted from the opportunity amount');
    }

    @isTest
    private static void verifyRefundWillBeMadeInTheSameCurrencyAsTheOriginalPayment() {
        if (!userInfo.isMultiCurrencyOrganization()) {
            return;
        }

        npe01__OppPayment__c originalPayment = getPaymentRecord();

        String isoCode = getDefaultISOCode();
        Opportunity opp = (Opportunity)originalPayment.getSObject(npe01__OppPayment__c.npe01__Opportunity__c);
        opp.put(UTIL_Currency.CURRENCY_ISO_CODE_FIELD, isoCode);
        originalPayment.put(UTIL_Currency.CURRENCY_ISO_CODE_FIELD, isoCode);

        PaymentSelector_TEST.Stub selectorStub = new PaymentSelector_TEST.Stub();
        selectorStub.paymentRecords = new List<npe01__OppPayment__c>{ originalPayment };

        PMT_RefundService refundService = new PMT_RefundService(); 
        refundService.paymentSelector = (PaymentSelector) Test.createStub(
            PaymentSelector.class,
            selectorStub
        );
  
        Test.startTest();
        refundService.withOriginalPayments( new List<npe01__OppPayment__c>{originalPayment} );
        refundService.buildRefundRecord(originalPayment, originalPayment.npe01__Payment_Amount__c);
        refundService.updateParentOpportunity(originalPayment, originalPayment.npe01__Payment_Amount__c);
        Test.stopTest();

        npe01__OppPayment__c refundRecord = refundService.getRefundRecords()?.get(0);
        Opportunity parentOpp = refundService.opportunityMap.values()?.get(0);

        System.assertEquals(1,refundService.getRefundRecords().size(),
            'A refund record should be created');
        System.assertEquals(originalPayment.npe01__Payment_Amount__c, -1 * refundRecord.npe01__Payment_Amount__c,
            'The amount on the refund record should match the original payment amont but negative');
        System.assertEquals(originalPayment.Id, refundRecord.originalPayment__c,
            'The refund record should map to the original payment record');
        System.assertEquals(PMT_RefundService.FULL_REFUND, refundRecord.DebitType__c,
            'The original payment refund type should be set to: ' + PMT_RefundService.FULL_REFUND);
        System.assertNotEquals(null, parentOpp, 'The parent opportunity should be proccessed');
        System.assertEquals(0, parentOpp.Amount, 'The opporunity amount should be set to 0 after the refund');
        System.assertEquals(
            (String )originalPayment.get(UTIL_Currency.CURRENCY_ISO_CODE_FIELD),
            (String) refundRecord.get(UTIL_Currency.CURRENCY_ISO_CODE_FIELD),
            'Refund record should be set to the same currency as the original payment');

    }

    private static npe01__OppPayment__c getPaymentRecord() {
        Opportunity opportunity = new Opportunity(
            Id = UTIL_UnitTestData_TEST.mockId(Opportunity.SObjectType),
            Amount = 1000
        );

        npe01__OppPayment__c payment = new npe01__OppPayment__c(
            Id = UTIL_UnitTestData_TEST.mockId(npe01__OppPayment__c.SObjectType),
            npe01__Opportunity__c = opportunity.Id,
            npe01__Paid__c = true,
            npe01__Payment_Amount__c = 1000,
            npe01__Opportunity__r = opportunity
        );

        return payment;
    }

    public static String getDefaultISOCode() {
        for (sObject currencyType : database.query('SELECT IsoCode, ConversionRate, IsCorporate FROM CurrencyType')) {
            if ((boolean) currencyType.get('IsCorporate')) {
                return (String) currencyType.get('IsoCode');
            }
        }
        return 'USD';
    }

    public class Stub implements System.StubProvider {
        public List<npe01__OppPayment__c> refundRecords;
        public ERR_Handler.Errors errors = new ERR_Handler.Errors();
        public PMT_RefundService.RefundInfo refundInfo;
 
        public Object handleMethodCall(
            Object stubbedObject,
            String methodName,
            Type returnType,
            List<Type> paramTypes,
            List<String> paramNames,
            List<Object> args
        ) {
            switch on methodName {
                when 'getRefundRecords' {
                    return refundRecords;
                } when 'getErrors' {
                    return errors;
                } when 'getRefundInfoFor' {
                    return refundInfo;
                } when 'buildRefundRecord' {
                    return refundRecords[0];
                } when else {
                    return null;
                }
            }
        }
    }
}
