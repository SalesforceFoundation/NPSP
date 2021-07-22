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
* @group Allocations
* @description Reviews the Allocations Passed to it, determining
*              which Opportunities/Payments Allocations require reprocessing,
*              and which ones are all set
*/
public inherited sharing class ALLO_AllocationsReviewService {

    /**
     * @description Determines if multi-currency is enabled for the org
     */
    private Boolean isMultiCurrencyEnabled {
        get {
            if (isMultiCurrencyEnabled == null) {
                isMultiCurrencyEnabled = UserInfo.isMultiCurrencyOrganization();
            }
            return isMultiCurrencyEnabled;
        }
        set;
    }

    /**
     * @description Allocations Wrapper Allocations Work
     */
    private ALLO_AllocationsWrapper allocationsWrapper {
        private get {
            if (allocationsWrapper == null) {
                allocationsWrapper = new ALLO_AllocationsWrapper();
            }
            return allocationsWrapper;
        }
        private set;
    }

    /**
     * @description Provides an allocations wrapper to the class for processing
     * @param allocationsWrapper Allocation Wrapper with DML to be processed
     * @return Class Instance
     */
    public ALLO_AllocationsReviewService withAllocationsWrapper(ALLO_AllocationsWrapper allocationsWrapper) {
        this.allocationsWrapper = allocationsWrapper;
        return this;
    }

    /**
     * @description Evaluates the data in the allocationsWrapper and returns a set consisting of any Opportunity Ids
     *              that require processing
     * @return Set<Id> Set of Opportunity Ids that requires further processing
     */
    public Set<Id> evaluateAllocations() {
        Set<Id> opportunityIds = new Set<Id>();

        for (Opportunity opp: allocationsWrapper.oppsById.values()) {

            if (checkOpportunity(opp)) {
                opportunityIds.add(opp.Id);
            }
        }

        return opportunityIds;
    }

    /**
     * @description Checks Opportunity and Related Allocations Information (including Payment Allocations and
     *              Defaults if enabled) and returns true if it needs processing
     * @param opp Opportunity to review
     * @return Boolean true if it requires processing
     */
    @testVisible private Boolean checkOpportunity(Opportunity opp) {
        Decimal amount = ALLO_AllocationsUtil.getAmountFor(opp);
        List<Allocation__c> oppAllocs = allocationsWrapper.getOpportunityAllocationsFor(opp);
        List<Allocation__c> campaignAllocs = allocationsWrapper.getCampaignAllocationsFor(opp);
        List<Allocation__c> recurringDonationAllocs = allocationsWrapper.getRecurringDonationAllocationsFor(opp);

        List<Allocation__c> parentAllocs = (!campaignAllocs.isEmpty()) ? campaignAllocs : recurringDonationAllocs;

        if (isRequiresReview(opp, oppAllocs, parentAllocs)) {
            // As soon as we find at least one reason to review we stop looking
            return true;
        }
        // Done with checks if Payment Allocations is not enabled, or no Payments are present.
        if (!ALLO_AllocationsSettings.getSettings().isPaymentAllocationsEnabled() ||
            opp.npe01__OppPayment__r == null) {
                return false;
        }

        // Review Payment Allocations
        for (npe01__OppPayment__c payment : opp.npe01__OppPayment__r) {
            List<Allocation__c> paymentAllocs = allocationsWrapper.getPaymentAllocationsFor(payment);
            if (isRequiresReview(payment, paymentAllocs, oppAllocs)) {
                return true;
            }
        }

        return false;
    }

    /**
     * @description Evaluations an object (either Opportunity or Payment) and its allocations to see if they
     *              potentially require reprocessing
     * @param  parentSObj The Opportunity or Payment record to be evaluated
     * @param  allocations       The Allocations associated with the Opportunity or Payment
     * @param  parentAllocations If present, the Parent Allocations
     * @return Boolean true if it should be reviewed, and false otherwise
     */
    @testVisible private Boolean isRequiresReview(SObject sObj, List<Allocation__c> allocations, List<Allocation__c> parentAllocations) {
        Decimal amount = null;

        if (sObj instanceOf Opportunity) {
            amount = (Decimal) sObj.get('Amount');
        } else if (sObj instanceOf npe01__OppPayment__c) {
            amount = (Decimal) sObj.get('npe01__Payment_Amount__c');
        } else { // invalid object passed to method
            return false;
        }

        // As soon as a positive reason is found, it is not necessary to look further.
        if (amount == null) { // If amount is null and allocations are present, allocations will be removed
            return (!allocations.isEmpty());
        } else if (amount == 0) {
            // Check for Parent Allocations and Default Allocations, if empty
            if (allocations.isEmpty()) {
                if (!parentAllocations.isEmpty()) { // Has Parent Allocations to Allocate from
                    return true;
                }

                if (ALLO_AllocationsSettings.getSettings().isDefaultAllocationsEnabled()) { // Has Default Allocations to Allocate from
                    return true;
                }
            }
            // Check for non zero Allocations.  If any are present, requires review
            for (Allocation__c alloc : allocations) {
                if (alloc.Amount__c != 0) {
                    return true;
                }
                if (isCurrencyDifference(sObj, alloc)) {
                    return true;
                }
            }
        } else {
            if (allocations.isEmpty()) {
                if (!parentAllocations.isEmpty()) { // Has Parent Allocations to Allocate from
                    return true;
                }

                if (ALLO_AllocationsSettings.getSettings().isDefaultAllocationsEnabled()) { // Has Default Allocations to Allocate from
                    return true;
                }
            }

            Boolean positiveAmount = (amount > 0);
            Decimal sumAllocAmount = 0;
            for (Allocation__c alloc :allocations) {
                if (alloc.Amount__c == null) {
                    return true;
                }
                if (isCurrencyDifference(sObj, alloc)) {
                    return true;
                }

                Decimal allocAmount = (alloc.Percent__c != null) ? (alloc.Percent__c * 0.01 * amount).setScale(2) : alloc.Amount__c;
                if (allocAmount != alloc.Amount__c) { // Calculated and stored Allocation Amounts differ
                    return true;
                }
                Boolean allocPositiveAmount = (allocAmount != null && allocAmount > 0);
                if (allocPositiveAmount != positiveAmount) { // Error condition, must be at least logged
                    return true;
                }
                sumAllocAmount += (allocAmount != null) ? allocAmount : 0;
            }
            if (ALLO_AllocationsSettings.getSettings().isDefaultAllocationsEnabled()) {
                if (sumAllocAmount != amount) {
                    return true;
                }
            } else {
                if (sumAllocAmount > amount) { // Possible error condition
                    return true;
                }
            }
        }
        return false;
    }

    /**
     * @description Returns true if the CurrencyIsoCode on the parent object is different than the one on
     *               the allocation.  Check always returns false if MultiCurrency is not enabled
     * @param parentObj Parent Obj to retrieve CurrencyIsoCode from
     * @param alloc Allocation to check
     * @return Boolean true if Currency Types do not match
     */
    @testVisible private Boolean isCurrencyDifference(SObject parentObj, Allocation__c alloc) {
        if (!isMultiCurrencyEnabled) {
            return false;
        }

        String parentCurrencyIsoCode = (String) parentObj.get(UTIL_Currency.CURRENCY_ISO_CODE_FIELD);
        String allocCurrencyIsoCode = (String) alloc.get(UTIL_Currency.CURRENCY_ISO_CODE_FIELD);

        return parentCurrencyIsoCode != allocCurrencyIsoCode;
    }
}