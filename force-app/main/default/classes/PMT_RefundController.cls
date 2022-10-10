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
* @description Apex Controller for paymnet refund
*/
public with sharing class PMT_RefundController {
    @TestVisible
    private static PMT_RefundService refundService {
        get {
            if (refundService == null) {
                refundService = new PMT_RefundService();
            }
            return refundService;
        }
        set;
    }

    @AuraEnabled
    public static RefundView getInitialView(Id paymentId) {
        RefundView refundView = new RefundView();
        setPermissionData(refundView);

        if (!refundView.hasRequiredPermissions) {
            return refundView;
        }

        refundService.withOriginalPaymentIds(new Set<Id>{paymentId});
        PMT_RefundService.RefundInfo refundInfo = refundService.getRefundInfoFor(paymentId);

        if (isElevatePayment(refundInfo.originalPayment.Elevate_Payment_ID__c)) {
            UTIL_Http.Response response = refundService.getElevatePaymentRefundInfo(refundInfo.originalPayment.Elevate_Payment_ID__c);
            processPaymentInfoResponse(refundView, response);
        } else {
            refundView.remainingBalance = refundInfo.remainingBalance;
        }

        if (UserInfo.isMultiCurrencyOrganization()) {
            refundView.currencyCode = (String) refundInfo.originalPayment.get(UTIL_Currency.CURRENCY_ISO_CODE_FIELD);

        } else {
            refundView.currencyCode = null;
        }
        return refundView;
    }

    @AuraEnabled 
    public static RefundView processRefund(Id paymentId, Decimal refundAmount) {
        RefundView refundView = new RefundView();
        setPermissionData(refundView);

        if (!refundView.hasRequiredPermissions) {
            return refundView;
        }

        refundService.withOriginalPaymentIds(new Set<Id>{paymentId});
        PMT_RefundService.RefundInfo refundInfo = refundService.getRefundInfoFor(paymentId);

        if (!isPaymentRefundable(refundInfo.originalPayment)) {
            handleError(refundView, System.Label.pmtPaymentNotRefundable);
            return refundView;
        }

        if (refundView.isSuccess != null && !refundView.isSuccess) {
            return refundView;
        }

        if (isElevatePayment(refundInfo?.originalPayment?.Elevate_Payment_ID__c)) {
            processElevateRefund(refundInfo.originalPayment, refundView, refundAmount);
        } else {
            processNonElevateRefund(refundInfo.originalPayment, refundView, refundAmount);
        }

        return refundView;
    }

    private static Boolean isPaymentRefundable(npe01__OppPayment__c originalPayment) {
        return String.isBlank(originalPayment.DebitType__c) && originalPayment.npe01__Payment_Amount__c > 0;
    }


    private static void setPermissionData(RefundView refundView) {
        refundView.hasRequiredPermissions = hasRequiredPermission();
    }

    private static Boolean isElevatePayment(String transactionId) {
        return PMT_RefundService.isElevateEnabled() && String.isNotBlank(transactionId);
    }

    private static void processElevateRefund(npe01__OppPayment__c originalPayment, RefundView refundView, Decimal refundAmount) {
        UTIL_Http.Response response = refundService
            .processElevateRefund(originalPayment.Elevate_Payment_ID__c, refundAmount);
        processResponse(refundView, response);
        refundView.redirectToPaymentId = originalPayment.Id;
    }

    private static void processNonElevateRefund(npe01__OppPayment__c originalPayment, RefundView refundView, Decimal refundAmount) {
        refundService.withOriginalPayments(new List<npe01__OppPayment__c>{originalPayment});
        npe01__OppPayment__c refundRecord = refundService.buildRefundRecord(originalPayment, refundAmount);
        List<ErrorRecord> errorRecords = new PMT_ValidationService()
            .validateRefund(refundRecord, refundService.getRefundInfoFor(refundRecord.OriginalPayment__c))
            .getErrors();
        if (errorRecords != null && !errorRecords.isEmpty()) {
            handleError(refundView, errorRecords[0].getFirstError());
            return;
        }

        refundService.insertRefunds();

        List<ErrorRecord> errors = refundService.getErrors();
        if (errors == null || errors.isEmpty()) {
            refundView.redirectToPaymentId = refundService.getRefundRecords()[0].Id;
            refundView.isSuccess = true;
        } else {
            handleError(refundView, errors[0].getFirstError());
        }
    }

    private static void handleError(RefundView refundView, String errorMessage) {
        refundView.isSuccess = false;
        refundView.errorMessage = errorMessage;
    }

    private static Boolean hasRequiredPermission() {
        return UTIL_Permissions.canCreate('npe01__oppPayment__c', false) &&
            UTIL_Permissions.canUpdate('npe01__oppPayment__c', false) &&
            UTIL_Permissions.canUpdate('Opportunity', false) &&
            UTIL_Permissions.canCreate('npe01__oppPayment__c', 'npe01__Payment_Amount__c', false) && 
            UTIL_Permissions.canCreate('npe01__oppPayment__c', String.valueOf(npe01__oppPayment__c.DebitType__c), false) && 
            UTIL_Permissions.canCreate('npe01__oppPayment__c', String.valueOf(npe01__oppPayment__c.OriginalPayment__c), false) &&
            UTIL_Permissions.canCreate('npe01__oppPayment__c', 'npe01__Paid__c', false) &&
            UTIL_Permissions.canCreate('npe01__oppPayment__c', 'npe01__Payment_Date__c', false);
    }

    private static void processResponse(RefundView refundView, UTIL_Http.Response response) {
        refundView.isSuccess = response.statusCode == UTIL_Http.STATUS_CODE_CREATED
            || response.statusCode == UTIL_Http.STATUS_CODE_OK;
        if (!refundView.isSuccess) {
            refundView.errorMessage = response.getErrorMessages();

        }
    }

    private static void processPaymentInfoResponse(RefundView refundView, UTIL_Http.Response response) {
        processResponse(refundView, response);
        if (!refundView.isSuccess) {
            return;
        }

        Map<String, Object> paymentInfo = (Map<String, Object>) JSON.deserializeUntyped(response.body);
        Decimal remainingBalance = (Decimal) paymentInfo.get('remainingBalance');
        refundView.remainingBalance = remainingBalance / PS_CommitmentRequest.DEFAULT_CURRENCY_MULTIPLIER;
    }

    public inherited sharing class RefundView {
        @AuraEnabled public Boolean hasRequiredPermissions;
        @AuraEnabled public Boolean isSuccess;
        @AuraEnabled public Id redirectToPaymentId;
        @AuraEnabled public String errorMessage;
        @AuraEnabled public Decimal remainingBalance;
        @AuraEnabled public String currencyCode;
        @AuraEnabled public Date paymentDate;
    }
}
