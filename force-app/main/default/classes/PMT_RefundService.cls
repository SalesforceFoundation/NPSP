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
* @description Payment Refund Service
*/
public inherited sharing class PMT_RefundService {
    public static final String FULL_REFUND = 'Refund';

    private Boolean isMultiCurrencyEnabled {
        get {
            if (isMultiCurrencyEnabled == null) {
                isMultiCurrencyEnabled = UserInfo.isMultiCurrencyOrganization();
            }
            return isMultiCurrencyEnabled;
        }
        set;
    }

    private UTIL_Http.RequestService requestService {
        get {
            if (requestService == null) {
                requestService = new UTIL_Http.RequestService();
            }
            return requestService;
        }
        set;
    }

    @TestVisible
    private PaymentSelector paymentSelector {
        get {
            if (paymentSelector == null) {
                paymentSelector = new PaymentSelector();
            }
            return paymentSelector;
        }
        set;
    }

    @TestVisible
    private List<npe01__OppPayment__c> originalPayments {
        get {
            if (originalPayments == null && originalPaymentIds != null) {
                originalPayments = paymentSelector.getPaymentRecordsForRefund(originalPaymentIds);
            }
            return originalPayments;
        }
        set;
    }

    private Set<Id> originalPaymentIds {
        get {
            if (originalPaymentIds == null) {
                if (originalPayments != null) {
                    originalPaymentIds = UTIL_SObject.extractIds(originalPayments);
                } else if (refundRecords != null) {
                    UTIL_SObject.extractId(refundRecords, npe01__OppPayment__c.originalPayment__c);
                }
            }
            return originalPaymentIds;
        }
        set;
    }

    private List<npe01__OppPayment__c> refundRecords;
    @TestVisible
    private Map<Id, Opportunity> opportunityMap;
    private ERR_Handler.Errors errorResult = new ERR_Handler.Errors();

    @TestVisible
    private static PS_IntegrationServiceConfig config {
        get {
            if (config == null) {
                config = new PS_IntegrationServiceConfig();
            }
            return config;
        }
        set;
    }

    public static Boolean isElevateEnabled() {
        return config.isIntegrationEnabled();
    }

    public PMT_RefundService withOriginalPayments(List<npe01__OppPayment__c> originalPayments) {
        this.originalPayments = originalPayments;
        return this;
    }

    public PMT_RefundService withRefundRecords(List<npe01__OppPayment__c> refundRecords) {
        this.refundRecords = refundRecords;
        return this;
    }

    public List<npe01__OppPayment__c> getRefundRecords() {
        return this.refundRecords;
    }

    public ERR_Handler.Errors getErrors() {
        return errorResult;
    }

    public UTIL_Http.Response processElevateRefund(String transactionId) {
        HttpRequest request = buildRefundRequest(transactionId);

        UTIL_Http.Response response;
        try {
            response = requestService.sendRequest(request);
        } catch (Exception ex) {
            response = requestService.buildErrorResponse(ex);
        }

        processPaymentStatusCode(response);
        return response;
    }

    public void processNonElevateRefunds() {
        Boolean shouldBuildRefundRecord = this.refundRecords == null;
 
        for (npe01__OppPayment__c originalPayment : this.originalPayments) {
            if (shouldBuildRefundRecord) {
                buildRefundRecord(originalPayment);
            }
            updateParentOpportunity(originalPayment);
        }
    }

    public void processDML() {
        Savepoint sp = Database.setSavepoint();
        try {
            if (!this.refundRecords.isEmpty()) {
                insert this.refundRecords;
            }
            
            if (!this.opportunityMap.isEmpty()) {
                update this.opportunityMap.values();
            }
        } catch (DmlException ex) {
            Database.rollback(sp);
            processError(ex);
        }
    }

    public Map<Id, RefundInfo> calculatePaymentWithRefundableAmount(List<npe01__OppPayment__c> originalPayments) {
        Map<Id, RefundInfo> paymentIdToRefundabInfo = new Map<Id, RefundInfo>();

        for (npe01__OppPayment__c originalPayment : originalPayments) {
            RefundInfo refundInfo = new refundInfo(originalPayment);

            paymentIdToRefundabInfo.put(originalPayment.Id, refundInfo);
        }

        return paymentIdToRefundabInfo;
    }

    private void processError(DMLException ex) {
        if (ex == null) {
            return;
        }
        ERR_Handler.Errors dmlErrors = ERR_Handler.getErrorsOnly(ex, ERR_Handler_API.Context.PMT);

        errorResult.errorRecords.addAll(
            dmlErrors.errorRecords
        );
    }

    private void buildRefundRecord(npe01__OppPayment__c originalPayment) {
        npe01__OppPayment__c refund = new npe01__OppPayment__c(
            npe01__Payment_Amount__c = -1 * originalPayment.npe01__Payment_Amount__c,
            npe01__Opportunity__c = originalPayment.npe01__Opportunity__c,
            OriginalPayment__c = originalPayment.Id,
            DebitType__c = PMT_RefundService.FULL_REFUND
        );
        
        if (isMultiCurrencyEnabled) {
            refund.put(UTIL_Currency.CURRENCY_ISO_CODE_FIELD, originalPayment.get(UTIL_Currency.CURRENCY_ISO_CODE_FIELD));
        }

        if (this.refundRecords == null) {
            this.refundRecords = new List<npe01__OppPayment__c>();
        }
        this.refundRecords.add(refund);
    }

    private void updateParentOpportunity(npe01__OppPayment__c originalPayment) {
        if (this.opportunityMap == null) {
            this.opportunityMap = new Map<Id,Opportunity>();
        }
        Opportunity opportunity = this.opportunityMap.get(originalPayment.npe01__Opportunity__c);
        if (opportunity == null) {
            opportunity = new Opportunity(
                Id = originalPayment.npe01__Opportunity__c,
                Amount = originalPayment.npe01__Opportunity__r.Amount
            );
        }
        opportunity.Amount = opportunity.Amount - originalPayment.npe01__Payment_Amount__c;

        this.opportunityMap.put(opportunity.Id, opportunity);
    }

    private HttpRequest buildRefundRequest(String transactionId) {
        RequestBody reqBody = new RequestBody(transactionId);

        return new PS_Request.Builder()
            .withMethod(UTIL_Http.Method.POST)
            .withEndpoint(PS_Request.ElevateEndpoint.REFUND)
            .withRecommendedTimeout()
            .withBody(JSON.serialize(reqBody))
            .build();
    }

    private void processPaymentStatusCode(UTIL_Http.Response response) {
        String paymentErrorMessage;
        if (response.statusCode == UTIL_Http.STATUS_CODE_NOT_FOUND) {
            paymentErrorMessage = System.Label.pmtPaymentNotFund;

        } else if (response.statusCode == UTIL_Http.STATUS_CODE_CONFLICT) {
            paymentErrorMessage = System.Label.pmtPaymentNotRefundable;

        }  else if (response.statusCode == UTIL_Http.STATUS_CODE_UNPROCESSABLE_ENTITY) {
            paymentErrorMessage =  System.Label.pmtOriginalPaymentNotCompleted;
        }
        
        if (String.isNotBlank(paymentErrorMessage)) {
            response.body = new UTIL_Http.ErrorResponseBody()
                .withError(paymentErrorMessage)
                .getAsJson();
        }
    }

    public class RequestBody {
        @TestVisible
        String transactionId;

        public RequestBody(String transactionId) {
            this.transactionId = transactionId;
        }
    }

    public class RefundInfo {
        public npe01__OppPayment__c originalPayment;
        public Decimal refundableAmount;

        public RefundInfo(npe01__OppPayment__c originalPayment) {
            this.originalPayment = originalPayment;
            this.refundableAmount = this.originalPayment.npe01__Payment_Amount__c;

            if (this.originalPayment.Refunds__r != null) {
                for (npe01__OppPayment__c refund : originalPayment.Refunds__r) {
                    refundableAmount += refund.npe01__Payment_Amount__c;
                }
            }
        }

        public void updateRefundAmount(npe01__OppPayment__c currentRefund) {
            if (currentRefund.Id == null || this.originalPayment.Refunds__r == null) {
                this.refundableAmount += currentRefund.npe01__Payment_Amount__c;
            } else {
                for (npe01__OppPayment__c previousRefund : originalPayment.Refunds__r) {
                    if (previousRefund.Id == currentRefund.Id) {
                        this.refundableAmount -= previousRefund.npe01__Payment_Amount__c;
                        this.refundableAmount += currentRefund.npe01__Payment_Amount__c;
                        return;
                    }
                }
            }
        }
    }
}
