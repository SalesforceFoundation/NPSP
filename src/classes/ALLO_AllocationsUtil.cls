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

    /** @description Used as a way to identify parts of Allocation Sync that may or may not be allowed to execute depending on earlier execution statuses */
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

    /** @description Envelope of Changes to Allocations, along with any functional errors by Opportunity or Payment Id */
    public class AllocationResults {
        public List<Allocation__c> allocationsForInsert;
        public List<Allocation__c> allocationsForUpdate;
        public List<Allocation__c> allocationsForDelete;
        public Map<String, String> errorsByRecordId;
    }

    /**
     * @description Records Identified as needing further review and/or updates based on the state of the records, as well as any recent changes.
     *  Opportunity Data with payments, as well as the allocations for the opportunity, payment, recurring donation (if needed), and campaign (if needed)
     *  are returned if flagged for further review/processing
     */
    public class RecordsForReview {
        public List<Opportunity> opps = new List<Opportunity>();
        public Map<Id, Opportunity> oppsById = new Map<Id, Opportunity>();
        public Map<Id, List<Allocation__c>> oppsAllocations = new Map<Id, List<Allocation__c>>();
        public Map<Id, List<Allocation__c>> paymentAllocations = new Map<Id, List<Allocation__c>>();

        public Map<Id, List<Allocation__c>> recurringDonationAllocations = new Map<Id, List<Allocation__c>>();
        public Map<Id, List<Allocation__c>> campaignAllocations = new Map<Id, List<Allocation__c>>();

        /**
          * @description Adds the Allocation to the appropriate map.  It picks the appropriate parent allocation
          * Map based on which lookup is populated.
          * @param alloc Allocation to add to the maps
          */
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

        /** @description Checks to see if the Opportunity requires review, based on it's payments, allocations, etc.
          * @param Opportunity opp The opportunity to check
          * @param Datetime boundary Represents a Datatime boundary.  Records newer than this boundary will require review
          * @return true if the Opportunity requires review
          */
        public boolean isOpportunityRequiresReview(Opportunity opp, Datetime boundary) {
            // Check Opportunity & Opportunity Allocations first
            if (isRequiresReview(opp, this.oppsAllocations.get(opp.Id), boundary)) {
                return true;
            }

            // Check Payments and Payment Allocations Next
            if (opp.npe01__OppPayment__r != null) {
                for (npe01__OppPayment__c payment : opp.npe01__OppPayment__r) {
                    if (isRequiresReview(payment, this.paymentAllocations.get(payment.Id), boundary)) {
                        return true;
                    }
                }
            }

            //TODO: Add checks for circumstances where Campaign Allocations and/or Recurring Donation Allocations differ from Opportunity Allocations, and thus need to update the Opportunity Allocations.
            // These checks will likely be fairly complex, and involve complex comparisons between the campaign or recurring donation allocations and the Opportunity.
            // Believe this to be out of scope for GA, but will confirm.

            return false;
        }
    }

    /**
     * @description Returns a list of configuration problems, if any.  If the List is empty, there are no configuration problems.
     * @return List<String> List of configuration problems, if any
     */
    public static List<String> validatePaymentAllocationsConfiguration() {
        List<String> problems = new List<String>();
        if (!allocationSettings.Payment_Allocations_Enabled__c) {
            problems.add(System.Label.alloPaymentNotEnabled);
        }
        if (!allocationSettings.Default_Allocations_Enabled__c) {
            problems.add(System.Label.alloDefaultNotEnabled);
        }

        if (allocationSettings.Default__c == null) {
            problems.add(System.Label.alloDefaultGAUMissing);
        } else {
            List<General_Accounting_Unit__c> defaultGAU = [select Id, Active__c, Name from General_Accounting_Unit__c where Id = :allocationSettings.Default__c];
            if (defaultGAU.size() < 1) {
                problems.add(System.Label.alloDefaultGAUDoesNotExist);
            } else if (!defaultGAU[0].Active__c) {
                problems.add(System.Label.alloDefaultGAUNotActive.replace('{0}', defaultGAU[0].Name));
            }
        }

        return problems;
    }

    /**
     * description Returns a populated RecordsForReview structure for the set of Opportunity Ids provided, and the boundary Datetime.  The
     * boundary is used to determine whether or not the records were updated based on whether the LastModified is >= boundary date.  If the boundary is
     * null, all records are considered to be updated.
     * @return RecordsForReview the Opportunity records requiring review and additional/processing
     */
    public static RecordsForReview determineRecordsRequiringReview(Set<Id> oppIds, Datetime boundary) {
        RecordsForReview recsForReview = new RecordsForReview();

        Map<Id, Opportunity> oppsById = retrieveOpportunities(oppIds);

        Set<Id> paymentsIds = new Set<Id>();
        Set<Id> recurringDonationIds = new Set<Id>();
        Set<Id> campaignIds = new Set<Id>();
        Map<Id, Id> rdIdsByOppIds = new Map<Id, Id>();
        Map<Id, Id> paymentIdToOppId = new Map<Id, Id>();
        Map<Id, Set<Id>> campaignIdToOppIds = new Map<Id, Set<Id>>();
        Map<Id, Set<Id>> rdIdToOppIds = new Map<Id, Set<Id>>();

        for (Opportunity opp :oppsById.values()) {
            recsForReview.oppsAllocations.put(opp.Id, new List<Allocation__c>());

            if (opp.npe03__Recurring_Donation__c != null) {
                recurringDonationIds.add(opp.npe03__Recurring_Donation__c);
                rdIdsByOppIds.put(opp.Id, opp.npe03__Recurring_Donation__c);
                add(rdIdToOppIds, opp.npe03__Recurring_Donation__c, opp.Id);
            }

            if (opp.CampaignId != null) {
                campaignIds.add(opp.CampaignId);
                add(campaignIdToOppIds, opp.CampaignId, opp.Id);
            }

            // Will only review Payments and Payment Allocations if Payment Allocations are enabled.
            // Note: This differs from the existing trigger, in that it will check and error if there are
            // Payment Allocations (inserts/updates) in the system and Payment Allocations is not enabled
            if (allocationSettings.Payment_Allocations_Enabled__c) {
                if (opp.npe01__OppPayment__r != null) {
                    for (npe01__OppPayment__c payment : opp.npe01__OppPayment__r) {
                        paymentsIds.add(payment.Id);
                        paymentIdToOppId.put(payment.Id, opp.Id);
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

        // Determine which Opportunities require review and add to the oppsById map
        for (Opportunity opp :oppsById.values()) {
            if (recsForReview.isOpportunityRequiresReview(opp, boundary)) { // Add to review map
                recsForReview.oppsById.put(opp.Id, opp);
            }
        }

        // Clear out allocations, etc. not flagged for review
        removeIfNotForReview(recsForReview.recurringDonationAllocations, rdIdToOppIds, recsForReview.oppsById);
        removeIfNotForReview(recsForReview.campaignAllocations, campaignIdToOppIds, recsForReview.oppsById);
        removeIfNotForReview(recsForReview.paymentAllocations, paymentIdToOppId, recsForReview.oppsById);
        removeIfNotForReview(recsForReview.oppsAllocations, recsForReview.oppsById);

        return recsForReview;
    }

    /**
     * @description Retrieves Opportunity and Payment Data into a Map by Opportunity Id for the Set of Opportunity
     * Ids requested.
     * @param Set<Id> oppIds The set of Opportunity Ids to retrieve Opportunity and Payment information for
     * @return Map<Id, Opportunity> Map of Opportunities by Opportunity Id
     */
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

    /**
     * @description Retrieves and returns a list of Allocations associated the requested Opportunities, Payments, Campaigns, and
     * Recurring Donation records.  It will return Allocations associated with any of the sets.
     * @param Set<Id> oppIds The set of Opportunity Ids to retrieve Allocations for
     * @param Set<Id> paymentIds The set of Payment Ids to retrieve Allocations for
     * @param Set<Id> campaignIds The set of Campaign Ids to retrieve Allocations for
     * @param Set<Id> recurringDonationIds The set of Recurring Donation Ids to retrieve Allocations for
     * @return List<Allocation__c> All allocations associated with any of the records specified
     */
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

    /**
     * @description Get a Map that indicates which processes an Opportunity should be excluded from
     * if an error occurs for that Opportunity in that process.  Recommend calling process cache map for further use.
     *@return  Map<PROCESS_DEFINITION, Set<PROCESS_DEFINITION>>
     */
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

    /**
     * @description Adds to the childId to a Map of a Set of Child Ids, but Parent Id.  This is used to
     * Keep track of which records are affected by changes to the Parent
     * @param Map<Id, Set<Id>> parentIdToChildIds The map of Set of Child Ids, by Parent Id
     * @param Id parentId The Id of the Parent record
     * @param Id childId The Id of the Child (to the Parent) record
     */
    private static void add(Map<Id, Set<Id>> parentIdToChildIds, Id parentId, Id childId) {
        if (parentIdToChildIds.containsKey(parentId)) {
            parentIdToChildIds.get(parentId).add(childId);
        } else {
            parentIdToChildIds.put(parentId, new Set<Id> { childId });
        }
    }

    /**
     * @description Generically adds an Allocation to a List of Allocations index by Parent Id in a Map.  If the
     * Parent Id is not yet in the Map, it will create a new list with the allocation in it, and add it to the Map.
     * Otherwise, it will add the Allocation to the List of Allocations associated with that Parent record
     * @param Map<Id, List<Allocation__c>> allocsByParentId List of Allocations Indexed By the Id of the Parent
     * @param Id parentId The Id of the Parent record
     * @param Allocation__c alloc The Allocation to add to the List of Allocations associated with the specified Parent
     */
    private static void add(Map<Id, List<Allocation__c>> allocsByParentId, Id parentId, Allocation__c alloc) {
        if (allocsByParentId.containsKey(parentId)) {
            allocsByParentId.get(parentId).add(alloc);
        } else {
            allocsByParentId.put (parentId, new List<Allocation__c> { alloc });
        }
    }

    /**
     * @description Initially, we added all the Allocations retrieved to the Maps.  After it is determined which Opportunities
     * require further review, some of the Allocations can be removed from the allocation Maps.  This method removes ones where
     * None of the related Opportunities are flagged for update (and so the Campaign/Recurring Donation Allocations are not needed)
     * @param Map<Id, List<Allocation__c>> allocsByParentId List of Allocations Indexed By the Id of the Parent
     * @param Map<Id, Set<Id>> parentIdToOppIds Set of Opportunities, Indexed By the Parent/Related Record's Id
     * @param Map<Id, Opportunity> oppsById Map of Opportunities by Opportunity Id
     */
    private static void removeIfNotForReview(Map<Id, List<Allocation__c>> allocationsByParentId, Map<Id, Set<Id>> parentIdToOppIds, Map<Id, Opportunity> oppsById) {
        // Clear out allocations by parent id, if they are not associated with at least one Opportunity tagged for review
        for (Id parentId :parentIdToOppIds.keySet()) {
            Set<Id> oppIds = parentIdToOppIds.get(parentId);
            Set<Id> oppsForReviewIds = oppsById.keySet();
            if (!set1ContainsAnyInSet2(oppsById.keySet(), oppIds)) {
                allocationsByParentId.remove(parentId);
            }
        }
    }

    /**
     * @description Determines whether set 1 contains any of the Ids in set 2.  If at least 1 Id found in set 2 is
     * also in set 1, this method returns true.  Otherwise, it returns false.
     * @param Set<Id> set1 The first set of Ids (we will see if any members of set2 are in this set)
     * @param Set<Id> set2 The second set of Ids
     */
    private static boolean set1ContainsAnyInSet2(Set<Id> set1, Set<Id> set2) {
        for (Id id :set2) {
            if (set1.contains(id)) {
                return true;
            }
        }
        return false;
    }

    /**
     * @description Removes List of Allocations from the allocationsByParentId map, if the Opportunity that is a parent of the allocation parent (E.g. The Payment) is not
     * flagged for review.
     * @param Map<Id, List<Allocation__c>> allocsByParentId List of Allocations Indexed By the Id of the Parent
     * @param Map<Id, Id> parentIdToOppId Opportunity, Indexed By the Parent/Related Record's Id
     * @param Map<Id, Opportunity> oppsById Map of Opportunities by Opportunity Id
     */
   private static void removeIfNotForReview(Map<Id, List<Allocation__c>> allocationsByParentId, Map<Id, Id> parentIdToOppId, Map<Id, Opportunity> oppsById) {
        // Clear out allocations by parent id, if they are not associated with at least one Opportunity tagged for review
        for (Id parentId :parentIdToOppId.keySet()) {
            Id oppId = parentIdToOppId.get(parentId);
            if (!oppsById.containsKey(oppId)) {
                allocationsByParentId.remove(parentId);
            }
        }
    }

    /**
     * @description Removes List of Allocations from the allocationsByParentId map, if the Opportunity that is a parent of the allocation is not
     * flagged for review.
     * @param Map<Id, List<Allocation__c>> allocsByParentId List of Allocations Indexed By the Id of the Parent
     * @param Map<Id, Opportunity> oppsById Map of Opportunities by Opportunity Id
     */
   private static void removeIfNotForReview(Map<Id, List<Allocation__c>> allocationsByParentId, Map<Id, Opportunity> oppsById) {
        // Clear out allocations by parent id, if they are not associated with at least one Opportunity tagged for review
        for (Id parentId :new Set<Id>(allocationsByParentId.keySet())) {
            if (!oppsById.containsKey(parentId)) {
                allocationsByParentId.remove(parentId);
            }
        }
    }

    /**
     * @description Determines whether a record requires review (based on it and it's associated allocations, and an associated boundary timestamp)
     * Rule 1 - If boundary is null, it will flag the record for review.  This will be null for records requiring reprocessing because they originally errored
     * Rule 2 - Record was Modified since "Boundary" timestamp. (LastModifiedDate >= Boundary)
     * Rule 3 - Default Allocations are enabled, but no allocations are present
     * Rule 4 - Allocations are present but Amount is null or 0 (Excluding ones associated with Payment)
     * Rule 5 - Any of the individual allocations are Modified since "Boundary" timestamp. (LastModifiedDate >= Boundary)
     * Rule 6 - If MultiCurrencyOrg, and Allocation CurrencyIsoCode and Parent CurrencyIsoCode are different
     * Rule 7 - Payment Allocations Only: Parent Amount is 0/null, and Allocation Amount is Not Equal to 0
     * Rule 8 - Payment Allocations Only: Parent Amount is not 0/null, but Allocation Amount equals 0
     * @param SObject parentSObj Parent of the Allocations
     * @param List<Allocation__c> allocations Allocations associated with the parentSObj that need to be checked to see if review is required
     * @param DateTime boundary Records older than this timestamp should not be considered modified since the last execution.  If null, will reprocess
     */
    private static boolean isRequiresReview(SObject parentSObj, List<Allocation__c> allocations, DateTime boundary) {
        // if boundary is null, it is assumed it must be validated.  Likeliest circumstance is from reprocessing an error
        if (boundary == null) {
            return true;
        }

        Decimal amount = null;
        Boolean forPayment = false;

        if (parentSObj instanceOf Opportunity) {
            amount = (Decimal) parentSObj.get('Amount');
        } else if (parentSObj instanceOf npe01__OppPayment__c) {
            amount = (Decimal) parentSObj.get('npe01__Payment_Amount__c');
            forPayment = true;
        } else { // invalid object passed to method
            return false;
        }

        DateTime lastModifiedDate = (DateTime) parentSObj.get('LastModifiedDate');
        String currencyIsoCode = null;
        if (UserInfo.isMultiCurrencyOrganization()) {
            currencyIsoCode = (String) parentSObj.get('CurrencyIsoCode');
        }

        // Data Modified since last execution
        if (lastModifiedDate >= boundary) {
            return true;
        }
        // If Default Allocations are enabled, Check for a non null/zero amount with no allocations.
        if (allocationSettings.Default_Allocations_Enabled__c && amount != null && amount != 0 && (allocations == null || allocations.size() == 0)) {
            return true;
        }

        // Check for a null/zero amount with allocations ( not associated with payment)
        if ((amount == null || amount == 0) && (allocations != null && allocations.size() > 0 && !forPayment)) {
            return true;
        }

        // Check individual allocations next
        for (Allocation__c alloc :allocations)  {
            // Modified since last execution
            if (alloc.LastModifiedDate >= boundary) {
                return true;
            }


            if (UserInfo.isMultiCurrencyOrganization()) { // Only check if CurrencyIsoCode is different if Multi Currency Organization
                String alloCurrencyIsoCode = (String) alloc.get('CurrencyIsoCode');
                if (alloCurrencyIsoCode != currencyIsoCode) {
                    return true;
                }
            }

            if (forPayment) { // These checks are only for Payment Allocations
                // Amount on allocation is present that needs to be cleared.
                if ((amount == null || amount == 0) && alloc.Amount__c != 0) {
                    return true;
                }
                // Amount is blank zero, but should not be if Parent is a non null/zero amount
                if (amount != null && amount != 0 && (alloc.Amount__c == null || alloc.Amount__c == 0)) {
                    return true;
                }
            }
        }

        // Positive checks exhausted.
        return false;
    }

}