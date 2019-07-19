/*
    Copyright (c) 2019, Salesforce.org
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
* @date 2019
* @group Allocations
* @group-content ../../ApexDocContent/Allocations.htm
* @description Utility class to support shared functionality for Allocations
*/
public class ALLO_AllocationsUtil {
    /** @description Allocations settings. */
    public static Allocations_Settings__c allocationSettings = UTIL_CustomSettingsFacade.getAllocationsSettings();

    public enum PROCESS_DEF {
        ALL,
        OPP_AMT_UPD,
        OPP_ALLOC_UPD,
        PMT_ALLOC,
        PMT_ALLOC_ZERO_OUT,
        PMT_ALLOC_RECALC,
        PMT_ALLOC_INITIALIZE,
        PMT_ALLOC_SYNC_TO_OPP_ALLOC,
        OPP_ALLOC_SYNC_FINALIZED,
        OPP_ALLOC_SYNC_NONFINALIZED
    }

    public class AllocationResults {
        public List<Allocation__c> allocationsForInsert;
        public List<Allocation__c> allocationsForUpdate;
        public List<Allocation__c> allocationsForDelete;
        public Map<String, String> errorsByRecordId;
    }

    public class RecordsForReview {
        List<Opportunity> opps = new List<Opportunity>();
        Map<Id, Opportunity> oppsById = new Map<Id, Opportunity>();
        Map<Id, List<Allocation__c>> oppsAllocations = new Map<Id, List<Allocation__c>>();
        Map<Id, List<Allocation__c>> paymentAllocations = new Map<Id, List<Allocation__c>>();

        Map<Id, List<Allocation__c>> recurringDonationAllocations = new Map<Id, List<Allocation__c>>();
        Map<Id, List<Allocation__c>> campaignAllocations = new Map<Id, List<Allocation__c>>();

        public void addAllocationByType(Allocation__c alloc) {
            if (alloc.Opportunity__c != null) { // This is an Opportunity Allocation
                ALLO_AllocationsUtil.add(oppsAllocations, alloc.Opportunity__c, alloc);
            } else if (alloc.Payment__c != null) { // This is a Payment Allocation
                ALLO_AllocationsUtil.add(paymentAllocations, alloc.Payment__c, alloc);
            } else if (alloc.Recurring_Donation__c != null) {
                ALLO_AllocationsUtil.add(recurringDonationAllocations, alloc.Recurring_Donation__c, alloc);
            } else if (alloc.Campaign__c != null) {
                ALLO_AllocationsUtil.add(campaignAllocations, alloc.Campaign__c, alloc);
            }
        }
    }

    public RecordsForReview determineRecordsRequiringReview(Set<Id> oppIds, DateTime boundary) {
        RecordsForReview recsForReview = new RecordsForReview();

        Map<Id, Opportunity> oppsById = retrieveOpportunities(oppIds);

        Set<Id> paymentsIds = new Set<Id>();
        Set<Id> recurringDonationIds = new Set<Id>();
        Set<Id> campaignIds = new Set<Id>();
        Map<Id, Id> rdIdsByOppIds = new Map<Id, Id>();
        for (Opportunity opp :oppsById.values()) {
            recsForReview.oppsAllocations.put(opp.Id, new List<Allocation__c>());

            if (boundary == null || opp.LastModifiedDate >= boundary) {
                recsForReview.oppsById.put(opp.Id, opp);
            }

            if (opp.npe03__Recurring_Donation__c != null) {
                recurringDonationIds.add(opp.npe03__Recurring_Donation__c);
                rdIdsByOppIds.put(opp.Id, opp.npe03__Recurring_Donation__c);
            }

            if (opp.CampaignId != null) {
                campaignIds.add(opp.CampaignId);
            }

            // Will only review Payments and Payment Allocations if Payment Allocations are enabled.
            // Note: This differs from the existing trigger, in that it will check and error if there are
            // Payment Allocations (inserts/updates) in the system and Payment Allocations is not enabled
            if (allocationSettings.Payment_Allocations_Enabled__c) {
                if (opp.npe01__OppPayment__r != null) {
                    for (npe01__OppPayment__c payment : opp.npe01__OppPayment__r) {
                        paymentsIds.add(payment.Id);
                        if (!recsForReview.oppsById.containsKey(payment.npe01__Opportunity__c) &&
                            (boundary == null || payment.LastModifiedDate >= boundary)) {
                                recsForReview.oppsById.put (opp.Id, opp);
                            }
                    }
                }
            }
        }

        List<Allocation__c> allocs = retrieveAllocations(oppIds, paymentsIds, recurringDonationIds, campaignIds);
        for (Allocation__c alloc : allocs) {
            recsForReview.addAllocationByType(alloc);
        }

        return recsForReview;
    }

    private static Map<Id, Opportunity> retrieveOpportunities(Set<Id> oppIds) {
        Set<String> oppPaymentFields = new Set<String> {
            'Id',
            'Name',
            'npe01__Payment_Amount__c',
            'npe01__Payment_Date__c',
            'npe01__Scheduled_Date__c',
            'npe01__Written_Off__c',
            'npe01__Paid__c',
            'npe01__Opportunity__c',
            'LastModifiedDate'
        };
        String paymentSubQueryString = + new UTIL_Query()
            .withSelectFields(oppPaymentFields)
            .withMultiCurrencyField()
            .withFrom('npe01__OppPayment__r')
            .build();

        Set<String> oppFields = new Set<String> {
            'Id',
            'Name',
            'Amount',
            'StageName',
            'CampaignId',
            'npe03__Recurring_Donation__c',
            'IsClosed',
            'LastModifiedDate',
            '(' + paymentSubQueryString + ')'
        };

        String oppQueryString = new UTIL_Query()
            .withSelectFields(oppFields)
            .withMultiCurrencyField()
            .withFrom(Opportunity.getSObjectType())
            .withWhere('Id IN :oppIds')
            .build();

        return new Map<Id, Opportunity>((List<Opportunity>)Database.query(oppQueryString));
    }

    private static List<Allocation__c> retrieveAllocations(Set<Id> oppIds, Set<Id> paymentIds, Set<Id>campaignIds, Set<Id> recurringDonationIds) {
        Set<String> allocationFields = new Set<String> {
            'Id',
            'Name',
            'Amount__c',
            'Campaign__c',
            'General_Accounting_Unit__c',
            'General_Accounting_Unit__r.Active__c',
            'General_Accounting_Unit__r.Name',
            'Opportunity__c',
            'Payment__c',
            'Payment__r.npe01__Opportunity__c',
            'Percent__c',
            'Recurring_Donation__c',
            'LastModifiedDate'
        };

        UTIL_Query allocQuery = new UTIL_Query()
            .withSelectFields(allocationFields)
            .withMultiCurrencyField()
            .withFrom(Allocation__c.getSObjectType());

        List<String> whereClauses = new List<String>();

        if (oppIds != null && !oppIds.isEmpty()) {
            whereClauses.add('Opportunity__c in :oppIds');
        }
        if (paymentIds != null && !paymentIds.isEmpty()) {
            whereClauses.add('Payment__c in :paymentIds');
        }
        if (campaignIds != null && !campaignIds.isEmpty()) {
            whereClauses.add('Campaign__c in :campaignIds');
        }
        if (recurringDonationIds != null && !recurringDonationIds.isEmpty()) {
            whereClauses.add('Recurring_Donation__c in :recurringDonationIds');
        }

        if (whereClauses.size() == 0) {
            return new List<Allocation__c>();
        } else {
            String allocationQueryString = allocQuery.withWhere(whereClauses).build();
            return new List<Allocation__c>((List<Allocation__c>) Database.query(allocationQueryString));
        }
    }

    /*******************************************************************************************************
    * @description Get a Map that indicates which processes an Opportunity should be excluded from
    * if an error occurs for that Opportunity in that process.  Recommend calling process cache map for further use.
    *@return  Map<PROCESS_DEFINITION, Set<PROCESS_DEFINITION>>
    ********************************************************************************************************/
    public static Map<PROCESS_DEF, Set<PROCESS_DEF>> getProcessExclusions() {
        return new Map<PROCESS_DEF, SET<PROCESS_DEF>> {
            PROCESS_DEF.OPP_AMT_UPD =>
                new Set<PROCESS_DEF>    {PROCESS_DEF.OPP_ALLOC_UPD,
                                        PROCESS_DEF.PMT_ALLOC_SYNC_TO_OPP_ALLOC,
                                        PROCESS_DEF.OPP_ALLOC_SYNC_FINALIZED,
                                        PROCESS_DEF.OPP_ALLOC_SYNC_NONFINALIZED},
            PROCESS_DEF.OPP_ALLOC_UPD =>
                new Set<PROCESS_DEF>    {PROCESS_DEF.PMT_ALLOC_INITIALIZE,
                                        PROCESS_DEF.PMT_ALLOC_SYNC_TO_OPP_ALLOC,
                                        PROCESS_DEF.OPP_ALLOC_SYNC_FINALIZED,
                                        PROCESS_DEF.OPP_ALLOC_SYNC_NONFINALIZED},
            PROCESS_DEF.PMT_ALLOC =>
                new Set<PROCESS_DEF>    {PROCESS_DEF.ALL},
            PROCESS_DEF.PMT_ALLOC_ZERO_OUT =>
                new Set<PROCESS_DEF>    {PROCESS_DEF.PMT_ALLOC_SYNC_TO_OPP_ALLOC,
                                        PROCESS_DEF.OPP_ALLOC_SYNC_FINALIZED,
                                        PROCESS_DEF.OPP_ALLOC_SYNC_NONFINALIZED},
            PROCESS_DEF.PMT_ALLOC_RECALC =>
                new Set<PROCESS_DEF>    {PROCESS_DEF.PMT_ALLOC_SYNC_TO_OPP_ALLOC,
                                        PROCESS_DEF.OPP_ALLOC_SYNC_FINALIZED},
            PROCESS_DEF.PMT_ALLOC_INITIALIZE =>
                new Set<PROCESS_DEF>    {PROCESS_DEF.PMT_ALLOC_SYNC_TO_OPP_ALLOC,
                                        PROCESS_DEF.OPP_ALLOC_SYNC_FINALIZED,
                                        PROCESS_DEF.OPP_ALLOC_SYNC_NONFINALIZED},
            PROCESS_DEF.PMT_ALLOC_SYNC_TO_OPP_ALLOC =>
                new Set<PROCESS_DEF>    {PROCESS_DEF.OPP_ALLOC_SYNC_FINALIZED,
                                        PROCESS_DEF.OPP_ALLOC_SYNC_NONFINALIZED}
        };
    }

    private static void add(Map<Id, List<Allocation__c>> allocsByParentId, Id parentId, Allocation__c alloc) {
        if (allocsByParentId.containsKey(parentId)) {
            allocsByParentId.get(parentId).add(alloc);
        } else {
            allocsByParentId.put (parentId, new List<Allocation__c> { alloc });
        }
    }

}