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
    public static final String PARTIAL_REFUND = 'Partial Refund';

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
    private AllocationSelector allocationSelector {
        get {
            if (allocationSelector == null) {
                allocationSelector = new AllocationSelector();
            }
            return allocationSelector;
        }
        set;
    }

    @TestVisible
    private List<npe01__OppPayment__c> originalPayments {
        get {
            if (originalPayments == null && originalPaymentIds != null) {
                originalPayments = paymentSelector.getPaymentsWithRefunds(originalPaymentIds);
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

    @TestVisible
    private Map<Id, RefundInfo> originalPaymentWithRefunds {
        get {
            if (originalPaymentWithRefunds == null) {
                originalPaymentWithRefunds = getOriginalPaymentWithRefundInfo(this.originalPayments);
            }
            return originalPaymentWithRefunds;
        }
        set;
    }

    public static Allocations_Settings__c allocationSettings = UTIL_CustomSettingsFacade.getAllocationsSettings();


    private List<npe01__OppPayment__c> refundRecords;
    @TestVisible
    private Map<Id, Opportunity> opportunityMap;
    private List<Allocation__c> allocationsToUpdate;
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

    public PMT_RefundService withOriginalPaymentIds(Set<Id> originalPaymentIds) {
        this.originalPaymentIds = originalPaymentIds;
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

    public RefundInfo getRefundInfoFor(Id originalPaymentId) {
        if (originalPaymentId == null) {
            return null;
        }

        RefundInfo refundInfo = this.originalPaymentWithRefunds.get(originalPaymentId);

        if (refundInfo == null) {
            npe01__OppPayment__c payment = paymentSelector.getPaymentRecordForRefund(originalPaymentId);
            this.originalPayments.add(payment);
            refundInfo = new RefundInfo(payment);
            this.originalPaymentWithRefunds.put(payment.Id, refundInfo);
        }

        return refundInfo;
    }

    public UTIL_Http.Response getElevatePaymentRefundInfo(String transactionId) {
        HttpRequest request = buildTransactionRequest(transactionId);

        UTIL_Http.Response response;
        try {
            response = requestService.sendRequest(request);
        } catch (Exception ex) {
            response = requestService.buildErrorResponse(ex);
        }

        return response;
    }

    public UTIL_Http.Response processElevateRefund(String transactionId, Decimal refundAmount) {
        HttpRequest request = buildRefundRequest(transactionId, refundAmount);

        UTIL_Http.Response response;
        try {
            response = requestService.sendRequest(request);
        } catch (Exception ex) {
            response = requestService.buildErrorResponse(ex);
        }

        processPaymentStatusCode(response);
        return response;
    }

    public void processDML() {
        Savepoint sp = Database.setSavepoint();
        try {
            if (!this.refundRecords.isEmpty()) {
                insert this.refundRecords;
            }
            if (!this.allocationsToUpdate.isEmpty()) {
                update this.allocationsToUpdate;
            }
            if (!this.opportunityMap.isEmpty()) {
                update this.opportunityMap.values();
            }
        } catch (DmlException ex) {
            Database.rollback(sp);
            processError(ex);
        }
    }

    private Map<Id, RefundInfo> getOriginalPaymentWithRefundInfo(List<npe01__OppPayment__c> originalPayments) {
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

    public npe01__OppPayment__c buildRefundRecord(npe01__OppPayment__c originalPayment, Decimal refundAmount) {
        refundAmount = (refundAmount == null) ? originalPayment.npe01__Payment_Amount__c : refundAmount; 
        npe01__OppPayment__c refund = new npe01__OppPayment__c(
            npe01__Payment_Amount__c = -1 * refundAmount,
            npe01__Opportunity__c = originalPayment.npe01__Opportunity__c,
            OriginalPayment__c = originalPayment.Id,
            DebitType__c = (originalPayment.npe01__Payment_Amount__c == refundAmount)
                ? PMT_RefundService.FULL_REFUND
                : PMT_RefundService.PARTIAL_REFUND
        );
        
        if (isMultiCurrencyEnabled) {
            refund.put(UTIL_Currency.CURRENCY_ISO_CODE_FIELD, originalPayment.get(UTIL_Currency.CURRENCY_ISO_CODE_FIELD));
        }

        if (this.refundRecords == null) {
            this.refundRecords = new List<npe01__OppPayment__c>();
        }

        this.refundRecords.add(refund);
        return refund;
    }

    public void updateParentOpportunity(npe01__OppPayment__c originalPayment, Decimal refundAmount) {
        if (this.opportunityMap == null) {
            this.opportunityMap = new Map<Id,Opportunity>();
        }
        Opportunity opportunity = this.opportunityMap.get(originalPayment.npe01__Opportunity__c);
        if (opportunity == null) {
            opportunity = new Opportunity(
                Id = originalPayment.npe01__Opportunity__c,
                Amount = (originalPayment.npe01__Opportunity__r.Amount == null)
                    ? 0
                    : originalPayment.npe01__Opportunity__r.Amount
            );
        }

        opportunity.Amount = opportunity.Amount - refundAmount;

        this.opportunityMap.put(opportunity.Id, opportunity);
    }

    public void processAllocations() {
        Set<Id> partialRefundOppIds = new Set<Id>();
        for (npe01__OppPayment__c refund : this.refundRecords) {
            if (refund.DebitType__c == PARTIAL_REFUND) {
                partialRefundOppIds.add(refund.npe01__Opportunity__c);
            }
        }
        List<Allocation__c> allocations = allocationSelector.getOpportunityAllocations(partialRefundOppIds);
        Map<Id, List<Allocation__c>> allocationsGroupByOpp = new Map<Id, List<Allocation__c>>();

        for (Allocation__c allocation : allocations) {
            if (allocationSettings.Default_Allocations_Enabled__c && allocation.General_Accounting_Unit__c == allocationSettings.default__c) {
                continue;
            }
          
            List<Allocation__c> groupedAllocations = allocationsGroupByOpp.get(allocation.Opportunity__c);
            
            if(groupedAllocations == null) {
                groupedAllocations = new List<Allocation__c>();
                allocationsGroupByOpp.put(allocation.Opportunity__c, groupedAllocations);
            }

            groupedAllocations.add(allocation);
        }

        for (List<Allocation__c> groupedAllocations : allocationsGroupByOpp.values()) {
            convertFixedAmountAllocationsToPercentage(groupedAllocations);
        }
    }

    private void convertFixedAmountAllocationsToPercentage(List<Allocation__c> allocations) {
        if (allocations == null || allocations.isEmpty()) {
            return;
        }
        if (this.allocationsToUpdate == null) {
            this.allocationsToUpdate = new List<Allocation__c>();
        }

        List<Allocation__c> toUpdate = new List<Allocation__c>();

        Decimal oppAmount = allocations[0].Opportunity__r.Amount;
        Double percentage = 0.0;
        for (Allocation__c allocation : allocations) {
            if (allocation.Percent__c == null) {
                Decimal calculatedPercentage = allocation.Amount__c / oppAmount * 100;
                allocation.Percent__c = calculatedPercentage.setScale(2, RoundingMode.HALF_UP);
                toUpdate.add(allocation);
            }

            percentage += allocation.Percent__c;
        }

        if (percentage > 100) {
            toUpdate[0].Percent__c = toUpdate[0].Percent__c - (percentage - 100);
        }

        this.allocationsToUpdate.addAll(toUpdate);
    }

    private HttpRequest buildTransactionRequest(String transactionId) {
        return new PS_Request.Builder()
            .withMethod(UTIL_Http.Method.GET)
            .withEndpoint(PS_Request.ElevateEndpoint.TRANSACTIONS)
            .withCommitmentId(transactionId)
            .withRecommendedTimeout()
            .build();
    }

    private HttpRequest buildRefundRequest(String transactionId, Decimal refundAmount) {
        RequestBody reqBody = new RequestBody(transactionId, refundAmount);

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
            paymentErrorMessage = System.Label.pmtPaymentNotFound;

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

    public inherited sharing class RequestBody {
        @TestVisible
        String transactionId;
        Integer amount;

        public RequestBody(String transactionId, Decimal refundAmount) {
            this.transactionId = transactionId;
            Decimal scaleRefundAmount = refundAmount * PS_CommitmentRequest.DEFAULT_CURRENCY_MULTIPLIER;
            this.amount = scaleRefundAmount.intValue();
        }
    }

    public inherited sharing class RefundInfo {
        public npe01__OppPayment__c originalPayment;
        public Decimal remainingBalance;

        public RefundInfo(npe01__OppPayment__c originalPayment) {
            this.originalPayment = originalPayment;
            this.remainingBalance = this.originalPayment.npe01__Payment_Amount__c;

            if (this.originalPayment.Refunds__r != null) {
                for (npe01__OppPayment__c refund : originalPayment.Refunds__r) {
                    remainingBalance += refund.npe01__Payment_Amount__c;
                }
            }
        }

        public void updateRemainingBalance(npe01__OppPayment__c currentRefund) {
            this.remainingBalance = getNewRemiaingBalanceWith(currentRefund);
        }

        public Decimal getNewRemiaingBalanceWith(npe01__OppPayment__c currentRefund) {
            Decimal tempBalance = this.remainingBalance;
            if (currentRefund.Id == null || this.originalPayment.Refunds__r == null) {
                tempBalance += currentRefund.npe01__Payment_Amount__c;
               
            } else {
                for (npe01__OppPayment__c previousRefund : originalPayment.Refunds__r) {
                    if (previousRefund.Id == currentRefund.Id) {
                        tempBalance -= previousRefund.npe01__Payment_Amount__c;
                        break;
                    }
                }
                tempBalance += currentRefund.npe01__Payment_Amount__c;
            }

            return tempBalance;
        }
    }
}
