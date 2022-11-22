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
    private OpportunitySelector opportunitySelector {
        get {
            if (opportunitySelector == null) {
                opportunitySelector = new OpportunitySelector();
            }
            return opportunitySelector;
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


    private List<npe01__OppPayment__c> refundRecords = new List<npe01__OppPayment__c>();
    private List<npe01__OppPayment__c> oldRefundRecords = new List<npe01__OppPayment__c>();
    @TestVisible
    private Map<Id, Opportunity> opportunityMap;
    @TestVisible
    private List<Allocation__c> allocationsToUpdate = new List<Allocation__c>();
    private Map<Id, ErrorRecord> paymentIdToErrorRecord = new Map<Id, ErrorRecord>();

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

        public PMT_RefundService withOldRefundRecords(List<npe01__OppPayment__c> oldRefundRecords) {
        this.oldRefundRecords = oldRefundRecords;
        return this;
    }

    public List<npe01__OppPayment__c> getRefundRecords() {
        return this.refundRecords;
    }

    public List<ErrorRecord> getErrors() {
        return this.paymentIdToErrorRecord.values();
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

    public npe01__OppPayment__c buildRefundRecord(npe01__OppPayment__c originalPayment, Decimal refundAmount) {
        npe01__OppPayment__c refund = new npe01__OppPayment__c(
            npe01__Payment_Amount__c = -1 * refundAmount,
            npe01__Opportunity__c = originalPayment.npe01__Opportunity__c,
            OriginalPayment__c = originalPayment.Id,
            npe01__Paid__c = true,
            npe01__Payment_Date__c = Date.today(),
            DebitType__c = (originalPayment.npe01__Payment_Amount__c == refundAmount)
                ? PMT_RefundService.FULL_REFUND
                : PMT_RefundService.PARTIAL_REFUND
        );
        
        if (isMultiCurrencyEnabled) {
            refund.put(UTIL_Currency.CURRENCY_ISO_CODE_FIELD, originalPayment.get(UTIL_Currency.CURRENCY_ISO_CODE_FIELD));
        }

        this.refundRecords.add(refund);
        return refund;
    }

    public PMT_RefundService adjustAllocationsAndOpportunities() {
        processAllocations();
        processOpportunities();
        return this;
    }

    public void insertRefunds() {
        List<Database.SaveResult> saveResults = Database.insert(this.refundRecords, false);
        for (Integer i = 0; i < this.refundRecords.size(); i++) {
            if (!saveResults[i].isSuccess()) {
                processError(
                    new List<npe01__OppPayment__c>{this.refundRecords[i]},
                    saveResults[i].getErrors()[0].getMessage()
                );
            }
        }
    }

    public void updateAllocationsAndOpportunities() {
        List<Database.SaveResult> allocationResults;
        List<Database.SaveResult> opportunityResults;

        if (!this.allocationsToUpdate.isEmpty()) {
            ALLO_AllocationsUtil.disableAllocationTriggers();
            allocationResults = Database.update(this.allocationsToUpdate, false);
            ALLO_AllocationsUtil.enableAllocationTriggers();
        }
        if (!this.opportunityMap.isEmpty()) {
            opportunityResults = Database.update(this.opportunityMap.values(), false);
        }

        Map<Id, List<npe01__OppPayment__c>> refundsGroupByOpps = groupRefundsByOpp();

        for (Integer i = 0; i < this.allocationsToUpdate.size(); i++) {
            if (!allocationResults[i].isSuccess()) {
                processError(
                    refundsGroupByOpps.get(this.allocationsToUpdate[i].Opportunity__c),
                    allocationResults[i].getErrors()[0].getMessage()
                );
            }
        }

        for (Integer i = 0; i < this.opportunityMap.values().size(); i++) {
            if (!opportunityResults[i].isSuccess()) {
                processError(
                    refundsGroupByOpps.get(this.opportunityMap.values()[i].Id),
                    opportunityResults[i].getErrors()[0].getMessage()
                );
            }
        }
    }

    private void processError(List<npe01__oppPayment__c> refunds, String errorMessage) {
        for (npe01__OppPayment__c refund : refunds ){
            ErrorRecord error = this.paymentIdToErrorRecord.get(refund.Id);
            if (error == null) {
                error = new ErrorRecord(refund);
                this.paymentIdToErrorRecord.put(refund.Id, error);
            }
            error.addError(errorMessage);
        }
    }

    private Map<Id, List<npe01__OppPayment__c>> groupRefundsByOpp() {
        Map<Id, List<npe01__OppPayment__c>> refundsGroupByOpp = new Map<Id, List<npe01__OppPayment__c>>();
        for (npe01__OppPayment__c refund : this.refundRecords) {
            List<npe01__OppPayment__c> oppRefunds = refundsGroupByOpp.get(refund.npe01__Opportunity__c);

            if (oppRefunds == null) {
                oppRefunds = new List<npe01__OppPayment__c>();
                refundsGroupByOpp.put(refund.npe01__Opportunity__c, oppRefunds);
            }
            oppRefunds.add(refund);
        }

        return refundsGroupByOpp;
    }

    private Map<Id, RefundInfo> getOriginalPaymentWithRefundInfo(List<npe01__OppPayment__c> originalPayments) {
        Map<Id, RefundInfo> paymentIdToRefundabInfo = new Map<Id, RefundInfo>();

        for (npe01__OppPayment__c originalPayment : originalPayments) {
            RefundInfo refundInfo = new refundInfo(originalPayment);

            paymentIdToRefundabInfo.put(originalPayment.Id, refundInfo);
        }

        return paymentIdToRefundabInfo;
    }

    private void processAllocations() {
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

    private void processOpportunities() {
        this.opportunityMap = new Map<Id, Opportunity>(
            opportunitySelector.getRefundOpportunities(
                UTIL_SObject.extractId(this.refundRecords, npe01__OppPayment__c.npe01__Opportunity__c))
        );

        for (Integer i = 0; i < this.refundRecords.size(); i++) {
            Opportunity parentOpp = this.opportunityMap.get(this.refundRecords[i].npe01__Opportunity__c);
            parentOpp.Amount = (parentOpp.Amount == null) ? 0 : parentOpp.Amount;
            parentOpp.Amount += getAdjustedRefundAmount(i);
        }

    }

    private Decimal getAdjustedRefundAmount(Integer index) {
       Decimal oldRefundAmount = (isUpdatingRefund()) ? this.oldRefundRecords[index].npe01__Payment_Amount__c : 0;
       return this.refundRecords[index].npe01__Payment_Amount__c - oldRefundAmount;
    }

    private Boolean isUpdatingRefund() {
        return !this.oldRefundRecords.isEmpty();
    }

    private void convertFixedAmountAllocationsToPercentage(List<Allocation__c> allocations) {
        if (allocations == null || allocations.isEmpty()) {
            return;
        }

        List<Allocation__c> toUpdate = new List<Allocation__c>();

        Decimal oppAmount = allocations[0].Opportunity__r.Amount;
        Double percentage = 0.0;
        for (Allocation__c allocation : allocations) {
            if (allocation.Percent__c == null) {
                allocation.Percent__c = allocation.Amount__c / oppAmount * 100;
                allocation.Amount__c = (oppAmount * allocation.Percent__c / 100).setScale(2);
                toUpdate.add(allocation);
            }

            percentage += allocation.Percent__c;
        }

        //There is a edge case where the total percentage will go over 100%. In this rare case,
        //the first adjusted allocation percentage will be deduct to match 100%
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
