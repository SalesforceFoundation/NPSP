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
    private static PaymentSelector paymentSelector {
        get {
            if (paymentSelector == null) {
                paymentSelector = new PaymentSelector();
            }
            return paymentSelector;
        }
        set;
    }

    @AuraEnabled
    public static RefundView getPermissionData() {
        RefundView refundView = new RefundView();
        refundView.hasRequiredPermissions = hasRequiredPermission();

        return refundView;
    }

    @AuraEnabled 
    public static RefundView processRefund(Id paymentId) {
        RefundView refundView = getPermissionData();

        if (!refundView.hasRequiredPermissions) {
            return refundView;
        }
        String transactionId = paymentSelector.getPaymentWithElevateId(paymentId)?.Elevate_Payment_ID__c;
        PMT_RefundService refundService = new PMT_RefundService();

        if (PMT_RefundService.isElevateEnabled() && String.isNotBlank(transactionId)) {
            UTIL_Http.Response response = refundService.processRefund(transactionId);
            processResponse(refundView, response);
            refundView.redirectToPaymentId = paymentId;
        }

        return refundView;
    }

    private static Boolean hasRequiredPermission() {
        return UTIL_Permissions.canCreate('npe01__oppPayment__c', false) &&
            UTIL_Permissions.canUpdate('npe01__oppPayment__c', false) &&
            UTIL_Permissions.canRead('npe01__oppPayment__c', false) &&
            UTIL_Permissions.canRead('Opportunity', false) &&
            UTIL_Permissions.canUpdate('Opportunity', false);
    }

    private static ReFundView processResponse(RefundView refundView, UTIL_Http.Response response) {
        refundView.isSuccess = response.statusCode == UTIL_Http.STATUS_CODE_CREATED
            || response.statusCode == UTIL_Http.STATUS_CODE_OK;
        if (!refundView.isSuccess) {
            refundView.errorMessage = response.getErrorMessages();

        }

        return refundView;
    }

    public class RefundView {
        @AuraEnabled public Boolean hasRequiredPermissions;
        @AuraEnabled public Boolean isSuccess;
        @AuraEnabled public Id redirectToPaymentId;
        @AuraEnabled public String errorMessage;
    }
}
